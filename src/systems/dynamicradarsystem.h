#pragma once

#include "ecs/system.h"


class DynamicRadarSystem : public sp::ecs::System
{
public:
    void update(float delta) override;
};
