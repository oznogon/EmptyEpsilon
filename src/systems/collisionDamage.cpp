#include "systems/collisionDamage.h"
#include "gameGlobalInfo.h"
#include "multiplayer_server.h"
#include "engine.h"

#include "components/collision.h"
#include "components/hull.h"

#include "systems/damage.h"

CollisionDamageSystem::CollisionDamageSystem()
{
    sp::CollisionSystem::addHandler(this);
}

void CollisionDamageSystem::update(float delta)
{
    // Periodically clean up stale cooldowns to prevent unbounded growth.
    if (engine->getElapsedTime() - last_cleanup > COOLDOWN_TIME * 10.0f)
    {
        last_cleanup = engine->getElapsedTime();
        const float cutoff = engine->getElapsedTime() - COOLDOWN_TIME * 2.0f;

        for (auto it = last_collision_time.begin(); it != last_collision_time.end(); )
        {
            if (it->second < cutoff) it = last_collision_time.erase(it);
            else ++it;
        }
    }
}

void CollisionDamageSystem::collision(sp::ecs::Entity a, sp::ecs::Entity b, float force)
{
    // Deal damage only on the server.
    if (!game_server.isAlive()) return;

    // Ignore damage and don't trigger a collision event if collision force
    // fails to exceed a threshold.
    if (force < DAMAGE_THRESHOLD) return;

    // Don't trigger unless both colliding entities have a Hull.
    auto hull_a = a.getComponent<Hull>();
    auto hull_b = b.getComponent<Hull>();
    if (!hull_a || !hull_b) return;

    // Abuse getIndex to build a mask of colliding entities.
    uint32_t idx_a = a.getIndex();
    uint32_t idx_b = b.getIndex();
    uint64_t key = (uint64_t)std::min(idx_a, idx_b) << 32 | (uint64_t)std::max(idx_a, idx_b);

    const float now = engine->getElapsedTime();
    auto it = last_collision_time.find(key);
    // Apply damage only if the cooldown has expired.
    if (it != last_collision_time.end() && now - it->second < COOLDOWN_TIME) return;
    last_collision_time[key] = now;

    // Apply only the damage that exceeds the damage threshold, scaled by the
    // collision damage factor setting.
    float damage = (force - DAMAGE_THRESHOLD) * gameGlobalInfo->collision_damage_factor;

    // Use the entities' transforms to damage the shield segment that covers
    // the collision point.
    auto transform_a = a.getComponent<sp::Transform>();
    auto transform_b = b.getComponent<sp::Transform>();

    if (transform_a && transform_b)
    {
        DamageInfo info_a(b, DamageType::Kinetic, transform_b->getPosition());
        DamageSystem::applyDamage(a, damage, info_a);
        DamageInfo info_b(a, DamageType::Kinetic, transform_a->getPosition());
        DamageSystem::applyDamage(b, damage, info_b);
    }
}
