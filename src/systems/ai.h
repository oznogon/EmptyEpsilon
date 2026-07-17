#pragma once

#include <cstddef>
#include "ecs/system.h"

class AISystem : public sp::ecs::System
{
    size_t next_heavy_index = 0;
    static constexpr int MAX_HEAVY_PER_FRAME = 4;

    float log_timer = 0.0f;
    float total_light_time = 0.0f;
    float total_heavy_time = 0.0f;
    int total_ai_count = 0;
    int frame_count = 0;
public:
    void update(float delta) override;
};
