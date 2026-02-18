#pragma once
#include <glm/vec3.hpp>
#include <stringImproved.h>
#include <ecs/entity.h>

class CinematicCamera
{
public:
    // Camera state (replicated to clients)
    float yaw = -90.0f;
    float pitch = 45.0f;
    float roll = 0.0f;
    float field_of_view = 60.0f;
    float z_position = 200.0f;

    // GM-visible metadata (NOT using separate RadarTrace/CallSign components)
    string name = "Camera";
    string radar_icon = "radar/blip.png";

    // Optional entity assignment for dynamic behavior
    sp::ecs::Entity assigned_entity;

    // Velocity-based FoV scaling config
    bool use_velocity_fov_scaling = false;
    float base_fov_for_velocity = 60.0f;
    float fov_velocity_range = 10.0f; // +/- degrees from base
};
