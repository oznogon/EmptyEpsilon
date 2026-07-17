#pragma once

#include <cstddef>
#include <unordered_map>
#include "ecs/system.h"
#include "components/ai.h"

class AISystem : public sp::ecs::System
{
    size_t next_heavy_index = 0;
    static constexpr int MAX_HEAVY_PER_FRAME = 4;

    float log_timer = 0.0f;
    float total_light_time = 0.0f;
    float total_heavy_time = 0.0f;
    int total_ai_count = 0;
    int frame_count = 0;

    struct LastAIState {
        AIOrder orders = AIOrder::Idle;
        glm::vec2 order_target_location{};
        sp::ecs::Entity order_target;
    };
    std::unordered_map<uint32_t, LastAIState> last_ai_state;
public:
    void update(float delta) override;
};
