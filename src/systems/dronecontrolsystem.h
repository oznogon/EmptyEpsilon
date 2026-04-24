#pragma once

#include "ecs/system.h"


class DroneControlSystem : public sp::ecs::System
{
public:
    void update(float delta) override;
};
