#include "systems/gravity.h"
#include "components/gravity.h"
#include "components/collision.h"
#include "components/hull.h"
#include "systems/collision.h"
#include "systems/damage.h"
#include "multiplayer_server.h"
#include "ecs/query.h"
#include "menus/luaConsole.h"
#include <glm/gtx/norm.hpp>


void GravitySystem::update(float delta)
{
    static constexpr float max_force = 10000.0f;
    if (delta <= 0.0f) return;

    for(auto [source, grav, source_transform] : sp::ecs::Query<Gravity, sp::Transform>()) {
        for(auto target : sp::CollisionSystem::queryArea(source_transform.getPosition() - glm::vec2(grav.range, grav.range), source_transform.getPosition() + glm::vec2(grav.range, grav.range))) {
            if (target == source) continue;
            auto tt = target.getComponent<sp::Transform>();
            if (!tt) continue;
            auto diff = source_transform.getPosition() - tt->getPosition();
            float dist2 = std::max(1.0f, glm::length2(diff));
            if (dist2 > grav.range*grav.range)
                continue;
            float force = (grav.range * grav.range * grav.force) / dist2;
            if (force >= max_force)
                force = max_force;
            tt->setPosition(tt->getPosition() + diff / std::sqrt(dist2) * delta * force);

            // Trigger at the center of the gravity well. The callback can
            // teleport, destroy, or otherwise modify the target, so stop
            // processing if either entity is gone.
            if (force >= max_force && grav.on_singularity && game_server.isAlive())
            {
                LuaConsole::checkResult(grav.on_singularity.call<void>(source, target));
                if (!source) break;
                if (!target) continue;
            }

            // Damage at center
            if (grav.damage && game_server) {
                DamageInfo info({}, DamageType::Kinetic, source_transform.getPosition());
                if (force >= max_force)
                {
                    DamageSystem::applyDamage(target, 100000.0, info); //try to destroy the object by inflicting a huge amount of damage
                    if (target)
                    {
                        if (!target.hasComponent<Hull>() || target.getComponent<Hull>()->allow_destruction)
                            target.destroy();
                        return;
                    }
                }
                if (force > 100.0f)
                    DamageSystem::applyDamage(target, force * delta / 10.0f, info);
            }
        }
    }
}

void GravitySystem::renderOnRadar(sp::RenderTarget& renderer, sp::ecs::Entity e, glm::vec2 screen_position, float scale, float rotation, Gravity& component)
{
    renderer.drawCircleOutline(screen_position, component.range * scale, 2.0, glm::u8vec4(255, 255, 255, 32));
}
