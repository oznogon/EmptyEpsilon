#pragma once

#include <unordered_map>

#include "ecs/entity.h"
#include "ecs/system.h"
#include "systems/collision.h"


class CollisionDamageSystem : public sp::ecs::System, public sp::CollisionHandler
{
public:
    CollisionDamageSystem();

    void update(float delta) override;
    void collision(sp::ecs::Entity a, sp::ecs::Entity b, float force) override;

private:
    static constexpr float DAMAGE_THRESHOLD = 1000.0f;
    static constexpr float COOLDOWN_TIME = 1.0f;

    float last_cleanup = 0.0f;

    // Tracks last damage time per entity pair (combined key from entity indices).
    std::unordered_map<uint64_t, float> last_collision_time;
};
