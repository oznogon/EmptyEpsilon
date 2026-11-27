#include "systems/teleporter.h"
#include "components/collision.h"
#include "components/zone.h"
#include "ecs/query.h"
#include "math/centerOfMass.h"
#include "menus/luaConsole.h"
#include "multiplayer_server.h"
#include "script/vector.h"


TeleporterSystem::TeleporterSystem()
{
    sp::CollisionSystem::addHandler(this);
}

void TeleporterSystem::update(float delta)
{
    if (!game_server.isAlive())
    {
        entities_in_zone.clear();
        return;
    }

    std::unordered_set<sp::ecs::Entity> active_zones;

    for (auto [zone_entity, teleporter, zone, transform] : sp::ecs::Query<Teleporter, Zone, sp::Transform>())
    {
        active_zones.insert(zone_entity);

        // Track entities entering the zone so the callback fires once per entry.
        auto& previously_inside = entities_in_zone[zone_entity];
        std::unordered_set<sp::ecs::Entity> now_inside;

        glm::vec2 lower_bound = transform.getPosition();
        glm::vec2 upper_bound = transform.getPosition();
        for (auto point : zone.outline)
        {
            lower_bound = glm::min(lower_bound, transform.getPosition() + point);
            upper_bound = glm::max(upper_bound, transform.getPosition() + point);
        }

        for (auto other : sp::TransformQuery::queryArea(lower_bound, upper_bound))
        {
            if (other == zone_entity) continue;

            auto other_transform = other.getComponent<sp::Transform>();
            if (!other_transform) continue;
            if (!insidePolygon(zone.outline, other_transform->getPosition() - transform.getPosition())) continue;

            now_inside.insert(other);

            if (teleporter.teleport_on_collision && previously_inside.find(other) == previously_inside.end())
            {
                trigger(zone_entity, other);
                if (!zone_entity || !zone_entity.hasComponent<Teleporter>())
                    break;
            }
        }

        entities_in_zone[zone_entity] = std::move(now_inside);
    }

    for (auto it = entities_in_zone.begin(); it != entities_in_zone.end();)
    {
        if (active_zones.find(it->first) == active_zones.end())
            it = entities_in_zone.erase(it);
        else
            ++it;
    }
}

void TeleporterSystem::collision(sp::ecs::Entity a, sp::ecs::Entity b, float force)
{
    if (!game_server.isAlive()) return;

    auto teleporter = a.getComponent<Teleporter>();
    if (!teleporter || !teleporter->teleport_on_collision) return;

    // Zones handle their own entry detection instead of Physics collisions.
    if (a.hasComponent<Zone>()) return;
    if (!a.hasComponent<sp::Physics>()) return;

    trigger(a, b);
}

void TeleporterSystem::trigger(sp::ecs::Entity teleporter_entity, sp::ecs::Entity teleportee)
{
    auto teleporter = teleporter_entity.getComponent<Teleporter>();
    if (!teleporter) return;

    const glm::vec2 target_coordinates = teleporter->target_coordinates;
    const bool is_single_use = teleporter->is_single_use;

    if (teleporter->on_teleportation)
        LuaConsole::checkResult(teleporter->on_teleportation.call<void>(target_coordinates, is_single_use, teleportee));
    else if (auto transform = teleportee.getComponent<sp::Transform>())
        transform->setPosition(target_coordinates);

    if (is_single_use && teleporter_entity)
        teleporter_entity.removeComponent<Teleporter>();
}

void TeleporterSystem::renderOnRadar(sp::RenderTarget& renderer, sp::ecs::Entity e, glm::vec2 screen_position, float scale, float rotation, Teleporter& component)
{
    if (component.target_coordinates.x != 0.0f || component.target_coordinates.y != 0.0f)
    {
        if (auto transform = e.getComponent<sp::Transform>())
            renderer.drawLine(screen_position, screen_position + (component.target_coordinates - transform->getPosition()) * scale, 1.0f, glm::u8vec4(255, 255, 255, 32));
    }
}
