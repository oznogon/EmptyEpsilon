#pragma once

#include "ecs/entity.h"
#include "ecs/system.h"
#include "systems/collision.h"
#include <unordered_map>

class CollisionDamageSystem : public sp::ecs::System, public sp::CollisionHandler
{
public:
    CollisionDamageSystem();

    void update(float delta) override;
    void collision(sp::ecs::Entity a, sp::ecs::Entity b, float force) override;

private:
    // Box2D hit events fire when the approach speed exceeds the world's
    // hitEventThreshold produces a force of at least 1.0 * BOX2D_SCALE = 20.
    // Sensor overlaps and contact data always report force 0.
    static constexpr float DAMAGE_THRESHOLD = 1.0f;
    static constexpr float COOLDOWN_TIME = 1.0f;

    float last_cleanup = 0.0f;

    // Tracks last damage time per entity pair (combined key from entity indices).
    std::unordered_map<uint64_t, float> last_collision_time;
};
