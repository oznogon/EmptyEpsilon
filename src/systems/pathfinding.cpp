#include "systems/pathfinding.h"
#include "components/avoidobject.h"
#include "components/collision.h"
#include "components/hull.h"
#include "ecs/query.h"
#include "glm/gtx/norm.hpp"
#include <math.h>
#include <queue>
#include <functional>
#include <limits>
#include <algorithm>


static PathFindingSystem* path_finding_system;

PathFindingSystem::PathFindingSystem()
{
    path_finding_system = this;
}

void PathFindingSystem::update(float delta)
{
    obstacles.clear();
    max_obstacle_radius = 100.0f;

    for (auto [entity, hull, physics, transform] : sp::ecs::Query<Hull, sp::Physics, sp::Transform>())
    {
        if (entity.hasComponent<AvoidObject>())
            continue;
        if (physics.getType() == sp::Physics::Type::Sensor)
            continue;
        entity.addComponent<AvoidObject>().setRange(physics.getSize().x);
    }

    for(auto [entity, dao] : sp::ecs::Query<DelayedAvoidObject>())
    {
        dao.delay -= delta;
        if (dao.delay <= 0.0f)
        {
            entity.addComponent<AvoidObject>().setRange(dao.getRange());
            entity.removeComponent<DelayedAvoidObject>();
        }
    }

    for(auto [entity, ao, transform] : sp::ecs::Query<AvoidObject, sp::Transform>())
    {
        Obstacle obs;
        obs.position = transform.getPosition();
        obs.radius = ao.getRange();
        obstacles.push_back(obs);
        if (obs.radius > max_obstacle_radius)
            max_obstacle_radius = obs.radius;
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
    glm::vec2 ab = b - a;
    glm::vec2 ap = p - a;
    float t = glm::dot(ap, ab);
    if (t <= 0.0f)
        return glm::length2(ap);
    float d2 = glm::length2(ab);
    if (t >= d2)
        return glm::length2(p - b);
    glm::vec2 proj = a + ab * (t / d2);
    return glm::length2(p - proj);
}

bool PathPlanner::lineOfSight(glm::vec2 a, glm::vec2 b, const std::vector<Obstacle>& obstacles, float my_radius) const
{
    float min_x = std::min(a.x, b.x);
    float max_x = std::max(a.x, b.x);
    float min_y = std::min(a.y, b.y);
    float max_y = std::max(a.y, b.y);

    for (const auto& obs : obstacles)
    {
        float r = obs.radius + my_radius;
        if (r <= 0.0f) continue;
        if (obs.position.x + r < min_x || obs.position.x - r > max_x)
            continue;
        if (obs.position.y + r < min_y || obs.position.y - r > max_y)
            continue;
        if (glm::length2(obs.position - a) < 100.0f)
            continue;
        if (glm::length2(obs.position - b) < 100.0f)
            continue;
        if (segmentPointDistance2(obs.position, a, b) < r * r)
            return false;
    }
    return true;
}

bool PathPlanner::cellPassable(int cx, int cy, float cell_size, glm::vec2 grid_offset,
                               const std::vector<Obstacle>& obstacles, float my_radius) const
{
    glm::vec2 center = grid_offset + glm::vec2(float(cx) * cell_size, float(cy) * cell_size);
    for (const auto& obs : obstacles)
    {
        float r = obs.radius + my_radius;
        if (r <= 0.0f) continue;
        if (glm::length2(center - obs.position) < r * r)
            return false;
    }
    return true;
}

void PathPlanner::plan(float my_radius, glm::vec2 start, glm::vec2 end)
{
    my_size = my_radius;
    const auto& obstacles = path_finding_system->getObstacles();
    float max_or = path_finding_system->getMaxObstacleRadius();

    if (glm::length2(end - start) < 100.0f * 100.0f)
    {
        route.clear();
        route.push_back(end);
        return;
    }

    if (lineOfSight(start, end, obstacles, my_radius))
    {
        route.clear();
        route.push_back(end);
        return;
    }

    float cell_size = std::max(std::min(max_or / 4.0f, 500.0f), 200.0f);
    float margin = std::max(max_or * 4.0f, 3000.0f);

    float half_x = std::max(margin, std::abs(end.x - start.x) + cell_size * 2.0f);
    float half_y = std::max(margin, std::abs(end.y - start.y) + cell_size * 2.0f);
    float bb_min_x = end.x - half_x;
    float bb_min_y = end.y - half_y;
    float bb_max_x = end.x + half_x;
    float bb_max_y = end.y + half_y;

    int x_min = int(std::floor(bb_min_x / cell_size));
    int y_min = int(std::floor(bb_min_y / cell_size));
    int x_max = int(std::ceil(bb_max_x / cell_size));
    int y_max = int(std::ceil(bb_max_y / cell_size));
    int grid_w = x_max - x_min + 1;
    int grid_h = y_max - y_min + 1;

    if (grid_w <= 0 || grid_h <= 0 || int64_t(grid_w) * int64_t(grid_h) > 50000)
    {
        route.clear();
        route.push_back(end);
        return;
    }

    int total_cells = grid_w * grid_h;
    std::vector<float> g_score(total_cells, std::numeric_limits<float>::infinity());
    std::vector<int> parent(total_cells, -1);
    std::vector<bool> closed(total_cells, false);
    std::vector<float> cell_penalty(total_cells, 0.0f);
    std::vector<bool> hard_blocked(total_cells, false);

    glm::vec2 grid_offset(float(x_min) * cell_size + cell_size * 0.5f,
                          float(y_min) * cell_size + cell_size * 0.5f);

    for (const auto& obs : obstacles)
    {
        float r_hard = std::max(obs.radius * 0.2f, 100.0f);
        float r_expanded = obs.radius + my_radius;
        if (r_expanded <= 0.0f) continue;
        if (glm::length2(obs.position - start) < 100.0f)
            continue;
        if (glm::length2(obs.position - end) < 100.0f)
            continue;
        int cx0 = int(std::floor((obs.position.x - r_expanded - grid_offset.x) / cell_size));
        int cx1 = int(std::ceil((obs.position.x + r_expanded - grid_offset.x) / cell_size));
        int cy0 = int(std::floor((obs.position.y - r_expanded - grid_offset.y) / cell_size));
        int cy1 = int(std::ceil((obs.position.y + r_expanded - grid_offset.y) / cell_size));
        cx0 = std::max(0, std::min(cx0, grid_w - 1));
        cx1 = std::max(0, std::min(cx1, grid_w - 1));
        cy0 = std::max(0, std::min(cy0, grid_h - 1));
        cy1 = std::max(0, std::min(cy1, grid_h - 1));
        for (int cy = cy0; cy <= cy1; cy++)
        {
            for (int cx = cx0; cx <= cx1; cx++)
            {
                int idx = cx + cy * grid_w;
                glm::vec2 center = grid_offset + glm::vec2(float(cx) * cell_size, float(cy) * cell_size);
                float dist = std::sqrt(glm::length2(center - obs.position));
                if (dist < r_hard)
                {
                    if (!hard_blocked[idx])
                    {
                        hard_blocked[idx] = true;
                    }
                }
                else if (dist < r_expanded)
                {
                    float ratio = (r_expanded - dist) / (r_expanded - r_hard);
                    float penalty = ratio * ratio * cell_size * 20.0f;
                    float& cp = cell_penalty[idx];
                    if (penalty > cp)
                        cp = penalty;
                }
            }
        }
    }

    auto cellCenter = [&](int cx, int cy) -> glm::vec2 {
        return grid_offset + glm::vec2(float(cx) * cell_size, float(cy) * cell_size);
    };

    auto cellKey = [&](int cx, int cy) -> int {
        return cx + cy * grid_w;
    };

    auto heuristic = [&](int cx, int cy) -> float {
        return glm::length(cellCenter(cx, cy) - end);
    };

    int sx = int(std::floor(start.x / cell_size)) - x_min;
    int sy = int(std::floor(start.y / cell_size)) - y_min;
    int ex = int(std::floor(end.x / cell_size)) - x_min;
    int ey = int(std::floor(end.y / cell_size)) - y_min;
    sx = std::max(0, std::min(sx, grid_w - 1));
    sy = std::max(0, std::min(sy, grid_h - 1));
    ex = std::max(0, std::min(ex, grid_w - 1));
    ey = std::max(0, std::min(ey, grid_h - 1));

    int start_key = cellKey(sx, sy);
    int end_key = cellKey(ex, ey);

    hard_blocked[start_key] = false;
    hard_blocked[end_key] = false;
    cell_penalty[start_key] = 0.0f;
    cell_penalty[end_key] = 0.0f;

    const int neighbor_dx[8] = {-1, 0, 1, -1, 1, -1, 0, 1};
    const int neighbor_dy[8] = {-1, -1, -1, 0, 0, 1, 1, 1};

    int expansions = 0;
    const int max_expansions = 5000;
    bool found = false;

    g_score[start_key] = 0.0f;
    float start_f = heuristic(sx, sy);
    using PQEntry = std::pair<float, int>;
    std::priority_queue<PQEntry, std::vector<PQEntry>, std::greater<PQEntry>> open_set;
    open_set.push({start_f, start_key});

    while (!open_set.empty() && expansions < max_expansions)
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

            glm::vec2 npos = cellCenter(nx, ny);
            float dist = glm::length(npos - pos);
            float new_g = g_score[key] + dist + cell_penalty[nkey];

            if (new_g < g_score[nkey])
            {
                g_score[nkey] = new_g;
                float new_f = new_g + heuristic(nx, ny);
                parent[nkey] = key;
                open_set.push({new_f, nkey});
            }
        }
    }

    route.clear();

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

        if (!raw_path.empty())
            raw_path[0] = start;
        if (raw_path.back() != end)
            raw_path.push_back(end);

        std::vector<glm::vec2> smoothed;
        smoothed.push_back(raw_path[0]);
        for (size_t i = 1; i < raw_path.size(); )
        {
            size_t furthest = i;
            for (size_t j = i; j < raw_path.size(); j++)
            {
                if (lineOfSight(smoothed.back(), raw_path[j], obstacles, my_radius))
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
}
