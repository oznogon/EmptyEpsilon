#include "systems/pathfinding.h"
#include "systems/pathworker.h"
#include "ecs/query.h"
#include "glm/gtx/norm.hpp"

#include "components/ai.h"
#include "components/avoidobject.h"
#include "components/collision.h"
#include "components/hull.h"

#include <math.h>
#include <queue>
#include <functional>
#include <limits>
#include <algorithm>

static PathFindingSystem* path_finding_system;

// Returns true if obstacle_entity and pathfinding_entity share a formation
// relationship (leader-subordinate or subordinate-leader), so the pathfinder
// can skip obstacles belonging to other entities in formation. This prevents
// collision-avoidance churn, at the cost of making wingmen more prone to
// ramming each other.
bool isFormationObstacle(sp::ecs::Entity obstacle_entity, sp::ecs::Entity pathfinding_entity)
{
    // If we shouldn't be in this functino, leave.
    if (!obstacle_entity || !pathfinding_entity) return false;

    // Always exclude the pathfinding entity's own obstacle.
    if (obstacle_entity == pathfinding_entity) return true;

    // obstacle_entity is a subordinate of pathfinding_entity.
    if (auto obs_ai = obstacle_entity.getComponent<AIController>())
    {
        if (obs_ai->orders == AIOrder::FlyFormation
            && obs_ai->order_target == pathfinding_entity)
            return true;
    }

    // pathfinding_entity is a subordinate of obstacle_entity.
    if (auto pf_ai = pathfinding_entity.getComponent<AIController>())
    {
        if (pf_ai->orders == AIOrder::FlyFormation
            && pf_ai->order_target == obstacle_entity)
            return true;
    }

    return false;
}

PathFindingSystem::PathFindingSystem()
{
    path_finding_system = this;
    PathWorker::instance = new PathWorker();
}

PathFindingSystem* PathFindingSystem::get()
{
    return path_finding_system;
}

PathFindingSystem::~PathFindingSystem()
{
    delete PathWorker::instance;
    PathWorker::instance = nullptr;
    path_finding_system = nullptr;
}

void PathFindingSystem::update(float delta)
{
    obstacles.clear();
    max_obstacle_radius = 100.0f;

    // Auto-add AvoidObject to all physical entities except sensors, so they're
    // considered obstacles by AI pathfinding. AI-controlled ships get a wider
    // avoidance radius so they keep a larger distance from each other.
    for (auto [entity, hull, physics, transform] : sp::ecs::Query<Hull, sp::Physics, sp::Transform>())
    {
        if (entity.hasComponent<AvoidObject>()) continue;
        if (physics.getType() == sp::Physics::Type::Sensor) continue;
        auto range = std::max(physics.getSize().x, physics.getSize().y);
        if (entity.hasComponent<AIController>())
            range *= 2.0f;
        entity.addComponent<AvoidObject>().setRange(range);
    }

    // Process delayed avoidance objects, such as launched mines.
    for (auto [entity, dao] : sp::ecs::Query<DelayedAvoidObject>())
    {
        dao.delay -= delta;
        if (dao.delay <= 0.0f)
        {
            entity.addComponent<AvoidObject>().setRange(dao.getRange());
            entity.removeComponent<DelayedAvoidObject>();
        }
    }

    // Build the flat obstacle list from all entities with AvoidObject. Each
    // entry stores position, avoidance radius, and the owning entity reference
    // so callers can filter specific entities during pathfinding.
    for (auto [entity, ao, transform] : sp::ecs::Query<AvoidObject, sp::Transform>())
    {
        Obstacle obs;
        obs.position = transform.getPosition();
        obs.radius = ao.getRange();
        obs.entity = entity;
        obstacles.push_back(obs);
        if (obs.radius > max_obstacle_radius) max_obstacle_radius = obs.radius;
    }

    rebuildSpatialHashGrid();
}

int PathFindingSystem::hashCell(int cx, int cy) const
{
    // Use Teschner's prime factors for uniform distribution:
    // https://matthias-research.github.io/pages/publications/tetraederCollision.pdf
    return (static_cast<unsigned int>(cx) * 73856093u + static_cast<unsigned int>(cy) * 19349663u) & (NUM_HASH_BUCKETS - 1);
}

void PathFindingSystem::rebuildSpatialHashGrid()
{
    // Clear all buckets and reset query_gen.
    for (auto& bucket : hash_grid) bucket.clear();

    obstacle_query_gen.assign(obstacles.size(), 0);
    current_query_id = 0;

    // Insert each obstacle into every hash cell it overlaps by radius.
    for (size_t i = 0; i < obstacles.size(); i++)
    {
        const auto& obs = obstacles[i];
        const float r = obs.radius;
        const int cx0 = static_cast<int>(std::floor((obs.position.x - r) / HASH_CELL_SIZE));
        const int cx1 = static_cast<int>(std::floor((obs.position.x + r) / HASH_CELL_SIZE));
        const int cy0 = static_cast<int>(std::floor((obs.position.y - r) / HASH_CELL_SIZE));
        const int cy1 = static_cast<int>(std::floor((obs.position.y + r) / HASH_CELL_SIZE));

        for (int cy = cy0; cy <= cy1; cy++)
        {
            for (int cx = cx0; cx <= cx1; cx++)
                hash_grid[hashCell(cx, cy)].push_back(i);
        }
    }
}

void PathFindingSystem::queryObstaclesAlongLine(glm::vec2 a, glm::vec2 b, float my_radius, std::function<bool(const Obstacle&)> callback) const
{
    // Exit early if there aren't any obstacles.
    if (obstacles.empty()) return;

    // Measure the line size and coordinates.
    const float margin = max_obstacle_radius + my_radius;
    const float min_x = std::min(a.x, b.x) - margin;
    const float max_x = std::max(a.x, b.x) + margin;
    const float min_y = std::min(a.y, b.y) - margin;
    const float max_y = std::max(a.y, b.y) + margin;

    const int cx0 = static_cast<int>(std::floor(min_x / HASH_CELL_SIZE));
    const int cx1 = static_cast<int>(std::floor(max_x / HASH_CELL_SIZE));
    const int cy0 = static_cast<int>(std::floor(min_y / HASH_CELL_SIZE));
    const int cy1 = static_cast<int>(std::floor(max_y / HASH_CELL_SIZE));

    // Bump the generation counter. Explicitly handle wraparound to avoid stale
    // comparisons against zero-initialised query_gen.
    current_query_id++;
    if (current_query_id == 0)
    {
        current_query_id = 1;
        std::fill(obstacle_query_gen.begin(), obstacle_query_gen.end(), 0);
    }

    // Iterate over each cell on the line to search for obstacles.
    for (int cy = cy0; cy <= cy1; cy++)
    {
        for (int cx = cx0; cx <= cx1; cx++)
        {
            const int bucket = hashCell(cx, cy);

            for (size_t idx : hash_grid[bucket])
            {
                // If we've already seen this obstacle, skip it.
                if (obstacle_query_gen[idx] == current_query_id) continue;

                obstacle_query_gen[idx] = current_query_id;

                // If blocked, exit early.
                if (!callback(obstacles[idx])) return;
            }
        }
    }
}

PathPlanner::PathPlanner()
{
}

void PathPlanner::clear()
{
    route.clear();
}

float PathPlanner::segmentPointDistance2(glm::vec2 p, glm::vec2 a, glm::vec2 b) const
{
    const glm::vec2 ab = b - a;
    const glm::vec2 ap = p - a;
    const float t = glm::dot(ap, ab);

    // p projects before a for distance to endpoint a.
    if (t <= 0.0f) return glm::length2(ap);
    const float d2 = glm::length2(ab);

    // p projects after b for distance to endpoint b.
    if (t >= d2) return glm::length2(p - b);

    // p projects inside the segment for perpendicular distance.
    glm::vec2 proj = a + ab * (t / d2);
    return glm::length2(p - proj);
}

bool PathPlanner::lineOfSight(glm::vec2 a, glm::vec2 b, float my_radius, sp::ecs::Entity exclude_entity) const
{
    bool blocked = false;

    path_finding_system->queryObstaclesAlongLine(a, b, my_radius,
        [&](const Obstacle& obs) -> bool
        {
            // Skip formation-mates so leaders don't avoid their own wingmen.
            if (exclude_entity && isFormationObstacle(obs.entity, exclude_entity))
                return true;

            const float r = obs.radius + my_radius;
            if (r <= 0.0f) return true;

            // Ignore obstacles very close to the endpoints.
            if (glm::length2(obs.position - a) < 100.0f) return true;
            if (glm::length2(obs.position - b) < 100.0f) return true;

            // True line-of-sight test: is the segment clear of this obstacle?
            if (segmentPointDistance2(obs.position, a, b) < r * r)
            {
                blocked = true;
                return false;
            }

            return true;
        });

    return !blocked;
}

bool PathPlanner::cellPassable(int cx, int cy, float cell_size, glm::vec2 grid_offset, const std::vector<Obstacle>& obstacles, float my_radius) const
{
    const glm::vec2 center = grid_offset + glm::vec2(static_cast<float>(cx) * cell_size, static_cast<float>(cy) * cell_size);

    for (const auto& obs : obstacles)
    {
        const float r = obs.radius + my_radius;
        if (r <= 0.0f) continue;
        if (glm::length2(center - obs.position) < r * r) return false;
    }

    return true;
}

void PathPlanner::plan(float my_radius, glm::vec2 start, glm::vec2 end, sp::ecs::Entity exclude_entity)
{
    my_size = my_radius;

    // Cache multi-waypoint routes for at least 1 second to prevent churning on
    // recalculations.
    if (route.size() > 1)
    {
        auto now = std::chrono::steady_clock::now();
        auto elapsed = std::chrono::duration<float>(now - cached_time).count();
        if (elapsed < 1.0f)
        {
            if (glm::length2(start - cached_start) < 1000000.0f
                && glm::length2(end - cached_end) < 1000000.0f)
                return;
        }
    }

    const auto& obstacles = path_finding_system->getObstacles();
    const float max_or = path_finding_system->getMaxObstacleRadius();

    // Destination is close, so just go there.
    if (glm::length2(end - start) < 10000.0f)
    {
        route.clear();
        route.push_back(end);
        return;
    }

    // We have direct line-of-sight to the destination, so just go there.
    if (lineOfSight(start, end, my_radius, exclude_entity))
    {
        route.clear();
        route.push_back(end);
        return;
    }

    // Compute the A* search grid. Cell size scales with the largest obstacle
    // radius to clamped limits, and the grid bounds are centered on the
    // destination with a margin that grows with obstacle size.
    const float cell_size = std::max(std::min(max_or / 4.0f, MAX_CELL_SIZE), MIN_CELL_SIZE);
    const float margin = std::max(max_or * 4.0f, MAX_CELL_MARGIN);

    const float half_x = std::max(margin, std::abs(end.x - start.x) + cell_size * 2.0f);
    const float half_y = std::max(margin, std::abs(end.y - start.y) + cell_size * 2.0f);
    const float bb_min_x = end.x - half_x;
    const float bb_min_y = end.y - half_y;
    const float bb_max_x = end.x + half_x;
    const float bb_max_y = end.y + half_y;

    const int x_min = static_cast<int>(std::floor(bb_min_x / cell_size));
    const int y_min = static_cast<int>(std::floor(bb_min_y / cell_size));
    const int x_max = static_cast<int>(std::ceil(bb_max_x / cell_size));
    const int y_max = static_cast<int>(std::ceil(bb_max_y / cell_size));
    const int grid_w = x_max - x_min + 1;
    const int grid_h = y_max - y_min + 1;

    // Safety cap to prevent pathological grid sizes.
    if (grid_w <= 0
        || grid_h <= 0
        || static_cast<int64_t>(grid_w) * static_cast<int64_t>(grid_h) > MAX_GRID_SIZE)
    {
        route.clear();
        route.push_back(end);
        return;
    }

    const int total_cells = grid_w * grid_h;
    // A* per-cell states.
    std::vector<float> g_score(total_cells, std::numeric_limits<float>::infinity());
    std::vector<int> parent(total_cells, -1);
    std::vector<bool> closed(total_cells, false);

    // Add a penalty cost for cells near, but not inside, obstacles.
    std::vector<float> cell_penalty(total_cells, 0.0f);
    // Hardblock cells that are inside of obstacles.
    std::vector<bool> hard_blocked(total_cells, false);

    const glm::vec2 grid_offset(
        static_cast<float>(x_min) * cell_size + cell_size * 0.5f,
        static_cast<float>(y_min) * cell_size + cell_size * 0.5f
    );

    // Rasterise each obstacle onto the grid. Mark hard-blocked cells and
    // compute distance-based penalties for cells near obstacle boundaries.
    for (const auto& obs : obstacles)
    {
        if (exclude_entity && isFormationObstacle(obs.entity, exclude_entity))
            continue;

        const float r_hard = std::max(obs.radius * 0.2f, 100.0f);
        const float r_expanded = obs.radius + my_radius;
        if (r_expanded <= 0.0f) continue;

        // Don't block cells at the start or end positions.
        if (glm::length2(obs.position - start) < 100.0f)
            continue;
        if (glm::length2(obs.position - end) < 100.0f)
            continue;

        int cx0 = static_cast<int>(std::floor((obs.position.x - r_expanded - grid_offset.x) / cell_size));
        int cx1 = static_cast<int>(std::ceil( (obs.position.x + r_expanded - grid_offset.x) / cell_size));
        int cy0 = static_cast<int>(std::floor((obs.position.y - r_expanded - grid_offset.y) / cell_size));
        int cy1 = static_cast<int>(std::ceil( (obs.position.y + r_expanded - grid_offset.y) / cell_size));
        cx0 = std::max(0, std::min(cx0, grid_w - 1));
        cx1 = std::max(0, std::min(cx1, grid_w - 1));
        cy0 = std::max(0, std::min(cy0, grid_h - 1));
        cy1 = std::max(0, std::min(cy1, grid_h - 1));

        for (int cy = cy0; cy <= cy1; cy++)
        {
            for (int cx = cx0; cx <= cx1; cx++)
            {
                const int idx = cx + cy * grid_w;
                const glm::vec2 center = grid_offset + glm::vec2(static_cast<float>(cx) * cell_size, static_cast<float>(cy) * cell_size);
                const float dist = std::sqrt(glm::length2(center - obs.position));

                // Cell center is within the inner core of the obstacle, so it's
                // hardblocked.
                if (dist < r_hard)
                {
                    if (!hard_blocked[idx])
                        hard_blocked[idx] = true;
                }
                // Cell is between the inner core and the full radius. Increase
                // cost while approaching the obstacle.
                else if (dist < r_expanded)
                {
                    const float ratio = (r_expanded - dist) / (r_expanded - r_hard);
                    const float penalty = ratio * ratio * cell_size * 20.0f;
                    float& cp = cell_penalty[idx];
                    if (penalty > cp) cp = penalty;
                }
            }
        }
    }

    auto cellCenter = [&](int cx, int cy) -> glm::vec2 {
        return grid_offset + glm::vec2(static_cast<float>(cx) * cell_size, static_cast<float>(cy) * cell_size);
    };

    auto cellKey = [&](int cx, int cy) -> int {
        return cx + cy * grid_w;
    };

    // Straight-line distance to the goal, as the A* heuristic.
    auto heuristic = [&](int cx, int cy) -> float {
        return glm::length(cellCenter(cx, cy) - end);
    };

    // Map start and end positions to cell coordinates.
    int sx = static_cast<int>(std::floor(start.x / cell_size)) - x_min;
    int sy = static_cast<int>(std::floor(start.y / cell_size)) - y_min;
    int ex = static_cast<int>(std::floor(end.x / cell_size)) - x_min;
    int ey = static_cast<int>(std::floor(end.y / cell_size)) - y_min;
    sx = std::max(0, std::min(sx, grid_w - 1));
    sy = std::max(0, std::min(sy, grid_h - 1));
    ex = std::max(0, std::min(ex, grid_w - 1));
    ey = std::max(0, std::min(ey, grid_h - 1));

    const int start_key = cellKey(sx, sy);
    const int end_key = cellKey(ex, ey);

    // Ensure the start and end cells are always passable.
    hard_blocked[start_key] = false;
    hard_blocked[end_key] = false;
    cell_penalty[start_key] = 0.0f;
    cell_penalty[end_key] = 0.0f;

    // Cardinal and diagonal directional neighbor offsets.
    const int neighbor_dx[8] = {-1, 0, 1, -1, 1, -1, 0, 1};
    const int neighbor_dy[8] = {-1, -1, -1, 0, 0, 1, 1, 1};

    int expansions = 0;
    bool found = false;

    // Standard A* open set ordered by f = g + h.
    g_score[start_key] = 0.0f;
    const float start_f = heuristic(sx, sy);
    using PQEntry = std::pair<float, int>;
    std::priority_queue<PQEntry, std::vector<PQEntry>, std::greater<PQEntry>> open_set;
    open_set.push({start_f, start_key});

    while (!open_set.empty() && expansions < MAX_EXPANSIONS)
    {
        auto [f, key] = open_set.top();
        open_set.pop();
        if (closed[key]) continue;
        closed[key] = true;

        int cx = key % grid_w;
        int cy = key / grid_w;

        if (cx == ex && cy == ey)
        {
            found = true;
            break;
        }

        expansions++;
        glm::vec2 pos = cellCenter(cx, cy);

        for (int n = 0; n < 8; n++)
        {
            int nx = cx + neighbor_dx[n];
            int ny = cy + neighbor_dy[n];
            if (nx < 0 || nx >= grid_w || ny < 0 || ny >= grid_h)
                continue;

            int nkey = cellKey(nx, ny);
            if (closed[nkey] || hard_blocked[nkey])
                continue;

            const glm::vec2 npos = cellCenter(nx, ny);
            const float dist = glm::length(npos - pos);
            const float new_g = g_score[key] + dist + cell_penalty[nkey];

            // Found a better path to this neighbor, so relax.
            if (new_g < g_score[nkey])
            {
                g_score[nkey] = new_g;
                const float new_f = new_g + heuristic(nx, ny);
                parent[nkey] = key;
                open_set.push({new_f, nkey});
            }
        }
    }

    route.clear();

    if (found)
    {
        // Reconstruct the path from the parent pointers.
        std::vector<glm::vec2> raw_path;
        int key = end_key;
        while (key != -1)
        {
            int kx = key % grid_w;
            int ky = key / grid_w;
            raw_path.push_back(cellCenter(kx, ky));
            key = parent[key];
        }
        std::reverse(raw_path.begin(), raw_path.end());

        if (!raw_path.empty()) raw_path[0] = start;
        if (raw_path.back() != end) raw_path.push_back(end);

        // Smooth line-of-sight by removing unnecessary intermediate waypoints.
        // Skip to the most distant visible point on the path.
        std::vector<glm::vec2> smoothed;
        smoothed.push_back(raw_path[0]);

        for (size_t i = 1; i < raw_path.size(); /* */)
        {
            size_t furthest = i;
            for (size_t j = i; j < raw_path.size(); j++)
            {
                if (lineOfSight(smoothed.back(), raw_path[j], my_radius, exclude_entity))
                    furthest = j;
            }

            if (furthest > i)
            {
                smoothed.push_back(raw_path[furthest]);
                i = furthest;
            }
            else
            {
                smoothed.push_back(raw_path[i]);
                i++;
            }
        }

        for (size_t i = 1; i < smoothed.size(); i++)
            route.push_back(smoothed[i]);
    }
    // No path found; fall back to flying directly to the destination.
    else route.push_back(end);

    // Cache multi-waypoint paths for reuse.
    if (route.size() > 1)
    {
        cached_start = start;
        cached_end = end;
        cached_time = std::chrono::steady_clock::now();
    }
}

void PathPlanner::planAsync(float my_radius, glm::vec2 start, glm::vec2 end, sp::ecs::Entity exclude_entity,
                             const std::vector<uint32_t>& extra_exclude_ids)
{
    if (!PathWorker::instance)
    {
        plan(my_radius, start, end, exclude_entity);
        return;
    }

    // Skip if a job is already in-flight for this entity.
    if (pending_async_job)
        return;

    // Skip if identical to the cached route (same dest, very close start).
    if (route.size() > 1)
    {
        auto now = std::chrono::steady_clock::now();
        auto elapsed = std::chrono::duration<float>(now - cached_time).count();
        if (elapsed < 1.0f
            && glm::length2(start - cached_start) < 1000000.0f
            && glm::length2(end - cached_end) < 1000000.0f)
            return;
    }

    // Close target: just set the direct route synchronously.
    if (glm::length2(end - start) < 10000.0f)
    {
        route.clear();
        route.push_back(end);
        pending_async_job = false;
        return;
    }

    // Compute the initial path on the worker thread.
    if (route.empty()) pending_async_job = false;

    // Submit an async job and keep the existing route.
    PathJob job;
    job.entity_id = exclude_entity ? exclude_entity.getIndex() : 0;
    job.my_radius = my_radius;
    job.start = start;
    job.end = end;
    job.exclude_entity_id = exclude_entity ? exclude_entity.getIndex() : 0;
    job.exclude_entity_ids = extra_exclude_ids;
    job.obstacles = path_finding_system->getObstacles();
    job.max_obstacle_radius = path_finding_system->getMaxObstacleRadius();

    my_size = my_radius;
    pending_async_job = true;
    async_entity_id = job.entity_id;

    cached_start = start;
    cached_end = end;
    cached_time = std::chrono::steady_clock::now();

    PathWorker::instance->submit(std::move(job));
}

bool PathPlanner::tryCollectResult()
{
    if (!pending_async_job) return false;
    if (!PathWorker::instance) return false;

    PathResult result = PathWorker::instance->collect(async_entity_id);
    if (result.entity_id == async_entity_id && !result.route.empty())
    {
        route = std::move(result.route);
        pending_async_job = false;
        return true;
    }

    return false;
}
