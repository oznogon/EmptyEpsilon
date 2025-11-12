#pragma once

#include "ecs/system.h"
#include "ecs/query.h"
#include "components/shipsystem.h"


class ShipSystemsSystem : public sp::ecs::System
{
public:
    // Seconds required for a system to recover from 100% hacked to 0%.
    constexpr static float unhack_time = 180.0f;

    void update(float delta) override;
private:
    void updateSystem(ShipSystem& system, float delta, bool has_coolant);
};
