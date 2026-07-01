#pragma once

#include "ecs/system.h"
#include "ecs/entity.h"
#include <vector>
#include <glm/vec2.hpp>


struct Obstacle
{
    glm::vec2 position;
    float radius;
};

class PathFindingSystem : public sp::ecs::System
{
public:
    PathFindingSystem();
    void update(float delta) override;

    const std::vector<Obstacle>& getObstacles() const { return obstacles; }
    float getMaxObstacleRadius() const { return max_obstacle_radius; }

private:
    std::vector<Obstacle> obstacles;
    float max_obstacle_radius = 100.0f;
};


class PathPlanner
{
public:
    PathPlanner();

    std::vector<glm::vec2> route;

    void plan(float my_radius, glm::vec2 start, glm::vec2 end);
    void clear();

private:
    float my_size = 0.0f;

    bool lineOfSight(glm::vec2 a, glm::vec2 b, const std::vector<Obstacle>& obstacles, float my_radius) const;
    bool cellPassable(int cx, int cy, float cell_size, glm::vec2 grid_offset,
                      const std::vector<Obstacle>& obstacles, float my_radius) const;
    float segmentPointDistance2(glm::vec2 p, glm::vec2 a, glm::vec2 b) const;
};
