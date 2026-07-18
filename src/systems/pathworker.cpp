#include "systems/pathworker.h"
#include "systems/pathfinding.h"
#include "logging.h"

#include <queue>
#include <algorithm>
#include <limits>
#include <cmath>

#include <glm/gtx/norm.hpp>

static float segmentPointDistance2(glm::vec2 p, glm::vec2 a, glm::vec2 b)
{
    const glm::vec2 ab = b - a;
    const float l2 = glm::length2(ab);
    if (l2 < 1e-6f) return glm::length2(p - a);
    const float t = std::max(0.0f, std::min(1.0f, glm::dot(p - a, ab) / l2));
    const glm::vec2 projection = a + t * ab;
    return glm::length2(p - projection);
}

static bool isEntityExcluded(uint32_t obs_id, uint32_t exclude_id, const std::vector<uint32_t>& exclude_ids)
{
    if (obs_id == exclude_id) return true;
    for (auto id : exclude_ids)
        if (obs_id == id) return true;
    return false;
}

static bool threadLineOfSight(glm::vec2 a, glm::vec2 b, float my_radius,
    const std::vector<Obstacle>& obstacles, uint32_t exclude_entity_id,
    const std::vector<uint32_t>& exclude_entity_ids)
{
    for (const auto& obs : obstacles)
    {
        if (isEntityExcluded(obs.entity.getIndex(), exclude_entity_id, exclude_entity_ids))
            continue;

        const float r = obs.radius + my_radius;
        if (r <= 0.0f) continue;

        if (glm::length2(obs.position - a) < 100.0f) continue;
        if (glm::length2(obs.position - b) < 100.0f) continue;

        if (segmentPointDistance2(obs.position, a, b) < r * r)
            return false;
    }
    return true;
}

static std::vector<glm::vec2> computePath(
    float my_radius, glm::vec2 start, glm::vec2 end,
    uint32_t exclude_entity_id,
    const std::vector<uint32_t>& exclude_entity_ids,
    const std::vector<Obstacle>& obstacles, float max_or)
{
    static constexpr int MAX_EXPANSIONS = 5000;
    static constexpr float MIN_CELL_SIZE = 200.0f;
    static constexpr float MAX_CELL_SIZE = 500.0f;
    static constexpr float MAX_CELL_MARGIN = 3000.0f;
    static constexpr int64_t MAX_GRID_SIZE = 50000;

    // Destination is close, so just go there.
    if (glm::length2(end - start) < 10000.0f)
    {
        std::vector<glm::vec2> route;
        route.push_back(end);
        return route;
    }

    // We have direct line-of-sight to the destination.
    if (threadLineOfSight(start, end, my_radius, obstacles, exclude_entity_id, exclude_entity_ids))
    {
        std::vector<glm::vec2> route;
        route.push_back(end);
        return route;
    }

    // Compute cell size and grid bounds.
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

    if (grid_w <= 0 || grid_h <= 0
        || static_cast<int64_t>(grid_w) * static_cast<int64_t>(grid_h) > MAX_GRID_SIZE)
    {
        std::vector<glm::vec2> route;
        route.push_back(end);
        return route;
    }

    const int total_cells = grid_w * grid_h;
    std::vector<float> g_score(total_cells, std::numeric_limits<float>::infinity());
    std::vector<int> parent(total_cells, -1);
    std::vector<bool> closed(total_cells, false);
    std::vector<float> cell_penalty(total_cells, 0.0f);
    std::vector<bool> hard_blocked(total_cells, false);

    const glm::vec2 grid_offset(
        static_cast<float>(x_min) * cell_size + cell_size * 0.5f,
        static_cast<float>(y_min) * cell_size + cell_size * 0.5f
    );

    // Rasterise each obstacle onto the grid.
    for (const auto& obs : obstacles)
    {
        if (isEntityExcluded(obs.entity.getIndex(), exclude_entity_id, exclude_entity_ids))
            continue;

        const float r_hard = std::max(obs.radius * 0.2f, 100.0f);
        const float r_expanded = obs.radius + my_radius;
        if (r_expanded <= 0.0f) continue;

        if (glm::length2(obs.position - start) < 100.0f) continue;
        if (glm::length2(obs.position - end) < 100.0f) continue;

        int cx0 = static_cast<int>(std::floor((obs.position.x - r_expanded - grid_offset.x) / cell_size));
        int cx1 = static_cast<int>(std::ceil((obs.position.x + r_expanded - grid_offset.x) / cell_size));
        int cy0 = static_cast<int>(std::floor((obs.position.y - r_expanded - grid_offset.y) / cell_size));
        int cy1 = static_cast<int>(std::ceil((obs.position.y + r_expanded - grid_offset.y) / cell_size));
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

                if (dist < r_hard)
                {
                    if (!hard_blocked[idx])
                        hard_blocked[idx] = true;
                }
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

    auto heuristic = [&](int cx, int cy, glm::vec2 goal) -> float {
        return glm::length(cellCenter(cx, cy) - goal);
    };

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

    hard_blocked[start_key] = false;
    hard_blocked[end_key] = false;
    cell_penalty[start_key] = 0.0f;
    cell_penalty[end_key] = 0.0f;

    const int neighbor_dx[8] = {-1, 0, 1, -1, 1, -1, 0, 1};
    const int neighbor_dy[8] = {-1, -1, -1, 0, 0, 1, 1, 1};

    int expansions = 0;
    bool found = false;

    g_score[start_key] = 0.0f;
    const float start_f = heuristic(sx, sy, end);
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

            if (new_g < g_score[nkey])
            {
                g_score[nkey] = new_g;
                const float new_f = new_g + heuristic(nx, ny, end);
                parent[nkey] = key;
                open_set.push({new_f, nkey});
            }
        }
    }

    std::vector<glm::vec2> route;

    if (found)
    {
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

        std::vector<glm::vec2> smoothed;
        smoothed.push_back(raw_path[0]);

        for (size_t i = 1; i < raw_path.size(); )
        {
            size_t furthest = i;
            for (size_t j = i; j < raw_path.size(); j++)
            {
                if (threadLineOfSight(smoothed.back(), raw_path[j], my_radius, obstacles, exclude_entity_id, exclude_entity_ids))
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
    else
    {
        route.push_back(end);
    }

    return route;
}

PathWorker* PathWorker::instance = nullptr;

PathWorker::PathWorker()
{
    worker_thread = std::thread(&PathWorker::run, this);
}

PathWorker::~PathWorker()
{
    running = false;
    cv.notify_all();
    if (worker_thread.joinable())
        worker_thread.join();
}

void PathWorker::submit(PathJob job)
{
    {
        std::lock_guard<std::mutex> lock(mutex);
        pending_jobs.push_back(std::move(job));
        has_work = true;
    }
    cv.notify_one();
}

PathResult PathWorker::collect(uint32_t entity_id)
{
    std::lock_guard<std::mutex> lock(mutex);
    for (auto it = completed_results.begin(); it != completed_results.end(); ++it)
    {
        if (it->entity_id == entity_id)
        {
            PathResult result = std::move(*it);
            completed_results.erase(it);
            return result;
        }
    }
    return {entity_id, {}};
}

void PathWorker::run()
{
    while (running)
    {
        std::vector<PathJob> jobs;
        {
            std::unique_lock<std::mutex> lock(mutex);
            cv.wait(lock, [this] { return has_work.load() || !running.load(); });
            if (!running) break;
            jobs.swap(pending_jobs);
            has_work = false;
        }

        std::vector<PathResult> results;
        for (const auto& job : jobs)
        {
            PathResult result;
            result.entity_id = job.entity_id;
            result.route = computePath(job.my_radius, job.start, job.end,
                job.exclude_entity_id, job.exclude_entity_ids, job.obstacles, job.max_obstacle_radius);
            results.push_back(std::move(result));
        }

        {
            std::lock_guard<std::mutex> lock(mutex);
            for (auto& r : results)
                completed_results.push_back(std::move(r));
        }
    }
}
