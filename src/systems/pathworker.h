#pragma once

#include <vector>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <atomic>
#include <cstdint>
#include <glm/vec2.hpp>
#include "ecs/entity.h"

struct Obstacle;

struct PathJob {
    uint32_t entity_id;
    float my_radius;
    glm::vec2 start;
    glm::vec2 end;
    uint32_t exclude_entity_id;
    std::vector<uint32_t> exclude_entity_ids;
    std::vector<Obstacle> obstacles;
    float max_obstacle_radius;
};

struct PathResult {
    uint32_t entity_id;
    std::vector<glm::vec2> route;
};


class PathWorker : sp::NonCopyable
{
public:
    PathWorker();
    ~PathWorker();

    void submit(PathJob job);
    PathResult collect(uint32_t entity_id);

    static PathWorker* instance;

private:
    void run();

    std::thread worker_thread;
    std::mutex mutex;
    std::condition_variable cv;
    std::vector<PathJob> pending_jobs;
    std::vector<PathResult> completed_results;
    std::atomic<bool> running{true};
    std::atomic<bool> has_work{false};
};
