#pragma once

#include "ecs/system.h"
#include "ecs/entity.h"
#include <vector>
#include <array>
#include <functional>
#include <chrono>
#include <glm/vec2.hpp>

struct Obstacle
{
    glm::vec2 position;
    float radius;
    sp::ecs::Entity entity;
};

class PathFindingSystem : public sp::ecs::System
{
public:
    PathFindingSystem();
    void update(float delta) override;

    const std::vector<Obstacle>& getObstacles() const { return obstacles; }
    float getMaxObstacleRadius() const { return max_obstacle_radius; }

    // Queries all obstacles that could intersect the line segment a-b, expanded
    // by max_obstacle_radius + my_radius. Each candidate is presented to the
    // callback; if the callback returns false the search stops immediately.
    // Uses a generation counter for per-query deduplication since an obstacle may
    // span multiple hash cells.
    void queryObstaclesAlongLine(glm::vec2 a, glm::vec2 b, float my_radius, std::function<bool(const Obstacle&)> callback) const;

private:
    // Rebuilds the spatial hash grid from the current obstacle list so that
    // line-of-sight queries only test obstacles in cells near the query segment.
    void rebuildSpatialHashGrid();
    // Spatial hash function maps a grid cell to one of NUM_HASH_BUCKETS.
    int hashCell(int cx, int cy) const;

    std::vector<Obstacle> obstacles;
    float max_obstacle_radius = 100.0f;

    // Cap hash cell size.
    static constexpr float HASH_CELL_SIZE = 500.0f;
    static constexpr int NUM_HASH_BUCKETS = 512;
    std::array<std::vector<size_t>, NUM_HASH_BUCKETS> hash_grid;
    mutable std::vector<int> obstacle_query_gen;
    mutable int current_query_id = 0;
};


class PathPlanner
{
public:
    PathPlanner();

    std::vector<glm::vec2> route;

    void plan(float my_radius, glm::vec2 start, glm::vec2 end, sp::ecs::Entity exclude_entity = {});
    void clear();

private:
    // Cap expansions, cell dimensions, and grid sizes.
    static constexpr int MAX_EXPANSIONS = 5000;
    static constexpr float MIN_CELL_SIZE = 200.0f;
    static constexpr float MAX_CELL_SIZE = 500.0f;
    static constexpr float MAX_CELL_MARGIN = 3000.0f;
    static constexpr int64_t MAX_GRID_SIZE = 50000;

    float my_size = 0.0f;

    // Cache state to avoid replanning identical routes.
    glm::vec2 cached_start;
    glm::vec2 cached_end;
    std::chrono::steady_clock::time_point cached_time;

    // Checks whether the line segment is free of obstacles that would block an
    // entity of radius my_radius. Uses the spatial hash grid to test only
    // obstacles near the segment.
    bool lineOfSight(glm::vec2 a, glm::vec2 b, float my_radius, sp::ecs::Entity exclude_entity = {}) const;
    // Returns true if the grid cell isn't within range of any obstacle.
    // (Unused; cell passability is computed inline in plan() via
    // hard_blocked[] / cell_penalty[].)
    bool cellPassable(int cx, int cy, float cell_size, glm::vec2 grid_offset, const std::vector<Obstacle>& obstacles, float my_radius) const;
    // Returns the squared distance from point p to the line segment a-b.
    float segmentPointDistance2(glm::vec2 p, glm::vec2 a, glm::vec2 b) const;
};
