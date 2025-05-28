#pragma once

#include "ecs/system.h"
#include "systems/rendering.h"
#include "systems/radar.h"
#include "components/tractorbeam.h"

class TractorBeamSystem : public sp::ecs::System, public Render3DInterface<TractorBeamEffect, true>, public RenderRadarInterface<TractorBeamSys, 21, RadarRenderSystem::FlagLongRange>
{
public:
    void update(float delta) override;

    void render3D(sp::ecs::Entity e, sp::Transform& transform, TractorBeamEffect& be) override;
    void renderOnRadar(sp::RenderTarget& renderer, sp::ecs::Entity entity, glm::vec2 screen_position, float scale, float rotation, TractorBeamSys& tractor_system) override;
};
