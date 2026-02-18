#include "cinematiccamera.h"
#include "components/maneuveringthrusters.h"
#include "gameGlobalInfo.h"
#include "main.h"
#include "multiplayer_server.h"
#include <ecs/query.h>

void CinematicCameraSystem::update(float delta)
{
    if (!game_server) return; // Server-only

    for (auto [entity, camera, transform] : sp::ecs::Query<CinematicCamera, sp::Transform>())
    {
        if (!camera.assigned_entity) continue;

        // Sync yaw from ManeuveringThrusters forward vector
        if (auto assigned_transform = camera.assigned_entity.getComponent<sp::Transform>())
        {
            if (camera.assigned_entity.hasComponent<ManeuveringThrusters>())
            {
                camera.yaw = assigned_transform->getRotation();
            }
        }

        // Scale FoV based on Physics velocity
        if (camera.use_velocity_fov_scaling)
        {
            if (auto physics = camera.assigned_entity.getComponent<sp::Physics>())
            {
                float speed = glm::length(physics->getVelocity());
                float speed_normalized = std::clamp(speed / 1000.0f, 0.0f, 1.0f);
                float fov_modifier = (speed_normalized * 2.0f - 1.0f) * camera.fov_velocity_range;
                camera.field_of_view = std::clamp(
                    camera.base_fov_for_velocity + fov_modifier,
                    camera.base_fov_for_velocity - camera.fov_velocity_range,
                    camera.base_fov_for_velocity + camera.fov_velocity_range
                );
            }
        }
    }
}

void CinematicCameraSystem::renderOnRadar(sp::RenderTarget& renderer, sp::ecs::Entity e,
                                          glm::vec2 screen_position, float scale,
                                          float rotation, CinematicCamera& component)
{
    // Draw camera icon
    renderer.drawRotatedSprite(component.radar_icon, screen_position, 32.0f, rotation);

    // Draw camera name below icon
    auto label_pos = screen_position + glm::vec2(0, 20);
    renderer.drawText(sp::Rect(label_pos.x, label_pos.y, 0, 0), component.name,
                     sp::Alignment::Center, 16, main_font,
                     glm::u8vec4(255, 255, 255, 255));
}
