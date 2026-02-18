#include "cinematicCamera.h"
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

        // Sync rotation from assigned entity's ManeuveringThrusters
        if (auto assigned_transform = camera.assigned_entity.getComponent<sp::Transform>())
        {
            if (camera.assigned_entity.hasComponent<ManeuveringThrusters>())
            {
                // Copy rotation from assigned entity to camera's transform
                transform.setRotation(assigned_transform->getRotation());
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
    // Get yaw from entity's Transform rotation
    auto transform = e.getComponent<sp::Transform>();
    if (!transform) return; // Camera must have Transform

    float camera_yaw = transform->getRotation();

    // Draw camera frustum/view cone
    // Base perpendicular depth (constant regardless of FoV)
    float base_depth = 2000.0f * scale;

    // Adjust depth based on pitch (near 0 = longer, far from 0 = shorter)
    // Pitch of 0 = looking horizontally (max depth)
    // Pitch of ±90 = looking straight up/down (min depth)
    float pitch_factor = std::cos(glm::radians(component.pitch));
    float frustum_depth = base_depth * std::max(0.3f, pitch_factor); // Min 30% of base depth

    // Calculate frustum edges based on FoV
    // To keep perpendicular depth constant, edge length must increase as FoV increases
    float half_fov = component.field_of_view / 2.0f;
    float half_fov_rad = glm::radians(half_fov);
    float edge_length = frustum_depth / std::cos(half_fov_rad); // Perpendicular depth / cos(half_angle)

    float yaw_rad = glm::radians(camera_yaw);
    float left_angle = yaw_rad - half_fov_rad;
    float right_angle = yaw_rad + half_fov_rad;

    glm::vec2 left_point = screen_position + glm::vec2(
        std::cos(left_angle) * edge_length,
        std::sin(left_angle) * edge_length
    );
    glm::vec2 right_point = screen_position + glm::vec2(
        std::cos(right_angle) * edge_length,
        std::sin(right_angle) * edge_length
    );

    // Draw frustum lines
    glm::u8vec4 frustum_color(100, 200, 255, 128); // Light blue, semi-transparent
    renderer.drawLine(screen_position, left_point, frustum_color);
    renderer.drawLine(screen_position, right_point, frustum_color);
    renderer.drawLine(left_point, right_point, frustum_color);

    // Draw camera icon
    renderer.drawRotatedSprite(component.radar_icon, screen_position, 32.0f, rotation);

    // Draw camera name below icon
    auto label_pos = screen_position + glm::vec2(0, 20);
    renderer.drawText(sp::Rect(label_pos.x, label_pos.y, 0, 0), component.name,
                     sp::Alignment::Center, 16, main_font,
                     glm::u8vec4(255, 255, 255, 255));
}
