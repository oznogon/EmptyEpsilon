#pragma once

#include "ecs/system.h"

#include "components/missile.h"
#include "components/missiletubes.h"
#include "components/mounts.h"

#include "systems/collision.h"
#include "systems/radar.h"

class MissileSystem
: public sp::ecs::System
, public sp::CollisionHandler
, public RenderRadarInterface<DelayedExplodeOnTouch, 10, RadarRenderSystem::FlagGM>
, public RenderRadarInterface<MissileTubes, 22, RadarRenderSystem::FlagShortRange>
{
public:
    MissileSystem();

    void update(float delta) override;
    void collision(sp::ecs::Entity a, sp::ecs::Entity b, float force) override;
    void renderOnRadar(sp::RenderTarget& renderer, sp::ecs::Entity e, glm::vec2 screen_position, float scale, float rotation, DelayedExplodeOnTouch& component) override;
    void renderOnRadar(sp::RenderTarget& renderer, sp::ecs::Entity e, glm::vec2 screen_position, float scale, float rotation, MissileTubes& tubes) override;

    static void startLoad(sp::ecs::Entity source, Mount& tube, int type_index);
    static void startUnload(sp::ecs::Entity source, Mount& tube);
    static void fire(sp::ecs::Entity source, Mount& tube, float target_angle, sp::ecs::Entity target);
    static float calculateFiringSolution(sp::ecs::Entity source, const Mount& tube, sp::ecs::Entity target);
private:
    static void explode(sp::ecs::Entity source, sp::ecs::Entity target, ExplodeOnTouch& eot);
    static void spawnProjectile(sp::ecs::Entity source, Mount& tube, float angle, sp::ecs::Entity target);
};
