#pragma once

#include "ecs/system.h"
#include "systems/rendering.h"
#include "systems/radar.h"
#include "components/utilityBeam.h"

class UtilityBeamSystem : public sp::ecs::System, public Render3DInterface<UtilityBeamEffect, true>, public RenderRadarInterface<UtilityBeam, 21, RadarRenderSystem::FlagNone>
{
public:
    void update(float delta) override;

    void render3D(sp::ecs::Entity entity, sp::Transform& transform, UtilityBeamEffect& beam_effect) override;
    void renderOnRadar(sp::RenderTarget& renderer, sp::ecs::Entity entity, glm::vec2 screen_position, float scale, float rotation, UtilityBeam& utility_beam) override;

    void fire(sp::ecs::Entity firing_entity, UtilityBeam& utility_beam, UtilityBeam::CustomBeamMode& beam_mode, sp::Transform& transform, sp::ecs::Entity target_entity, float distance, float angle_diff);
    void setArcAndAdjustRange(float arc_request, UtilityBeam& utility_beam);
    void setRangeAndAdjustArc(float range_request, UtilityBeam& utility_beam);
};
