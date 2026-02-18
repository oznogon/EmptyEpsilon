#pragma once

#include <glm/vec3.hpp>
#include <stringImproved.h>
#include <ecs/entity.h>

class CinematicCamera
{
public:
    // Replicated values
    // Camera state
    // Note: Yaw is stored in the entity's Transform component rotation
    float pitch = 45.0f;
    float roll = 0.0f;
    float field_of_view = 60.0f;
    float z_position = 200.0f;

    // Optional entity assignment for dynamic behavior
    sp::ecs::Entity assigned_entity;

    // Server-only values
    // GM-visible metadata
    string name = "Camera";
    string radar_icon = "radar/blip.png";

    // Velocity-based FoV scaling config
    bool use_velocity_fov_scaling = false;
    float base_fov_for_velocity = 60.0f;
    float fov_velocity_range = 10.0f;
};
