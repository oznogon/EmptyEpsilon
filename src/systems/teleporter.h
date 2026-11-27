#pragma once

#include <unordered_map>
#include <unordered_set>

#include "ecs/system.h"
#include "systems/collision.h"
#include "systems/radar.h"
#include "components/teleporter.h"


class TeleporterSystem : public sp::ecs::System, public sp::CollisionHandler, public RenderRadarInterface<Teleporter, 13, RadarRenderSystem::FlagGM>
{
public:
    TeleporterSystem();

    void update(float delta) override;
    void collision(sp::ecs::Entity a, sp::ecs::Entity b, float force) override;
    void renderOnRadar(sp::RenderTarget& renderer, sp::ecs::Entity e, glm::vec2 screen_position, float scale, float rotation, Teleporter& component) override;

private:
    void trigger(sp::ecs::Entity teleporter_entity, sp::ecs::Entity teleportee);

    // Server-only tracking of entities currently inside each Teleporter zone.
    std::unordered_map<sp::ecs::Entity, std::unordered_set<sp::ecs::Entity>> entities_in_zone;
};
