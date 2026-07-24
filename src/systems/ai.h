#pragma once

#include <cstddef>
#include <unordered_map>
#include "ecs/system.h"
#include "components/ai.h"

struct AIMetricsSnapshot {
    int ai_count = 0;
    float light_time_us = 0.0f;
    float heavy_time_us = 0.0f;
    float total_ms = 0.0f;
    int immediate_heavy_count = 0;
    int heavy_budget = 4;
};

class AISystem : public sp::ecs::System
{
    size_t next_heavy_index = 0;
    static constexpr int MAX_HEAVY_PER_FRAME = 4;
#ifdef DEBUG
    float log_timer = 0.0f;
    float total_light_time = 0.0f;
    float total_heavy_time = 0.0f;
    int total_ai_count = 0;
    int frame_count = 0;
    int immediate_heavy_count = 0;
#endif
    struct LastAIState {
        AIOrder orders = AIOrder::Idle;
        glm::vec2 order_target_location{};
        sp::ecs::Entity order_target;
    };
    std::unordered_map<uint32_t, LastAIState> last_ai_state;

public:
    void update(float delta) override;

    static AIMetricsSnapshot metrics_snapshot;
};
