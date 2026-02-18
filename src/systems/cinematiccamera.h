#pragma once
#include <ecs/system.h>
#include "components/cinematiccamera.h"
#include "systems/radar.h"

class CinematicCameraSystem : public sp::ecs::System,
    public RenderRadarInterface<CinematicCamera, 11, RadarRenderSystem::FlagGM>
{
public:
    void update(float delta) override;
    void renderOnRadar(sp::RenderTarget& renderer, sp::ecs::Entity e, glm::vec2 screen_position,
                       float scale, float rotation, CinematicCamera& component) override;
};
