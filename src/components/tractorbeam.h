#pragma once

#include "ecs/entity.h"
#include "shipsystem.h"
#include "glm/vec3.hpp"
#include "glm/gtc/type_precision.hpp"


enum class TractorMode
{
    Hold,
    Pull,
    Push,
    Reposition
};

class TractorBeamSys : public ShipSystem {
public:
    glm::vec3 position = glm::vec3(0.01f, 0.01f, 0.01f); // hack
    bool active = false;
    TractorMode mode = TractorMode::Hold;
    float bearing = 0.0f;
    static constexpr float MIN_ARC = 6.0f;
    float max_arc = 90.0f;
    float arc = 90.0f;
    static constexpr float MIN_RANGE = 500.0f;
    float max_range = 2000.0f;
    float range = 500.0f;
    float cycle_time = 6.0f;
    // TODOs
    glm::vec2 tractor_target_coordinates{0.0f, 0.0f};
    glm::u8vec4 arc_color{0, 255, 255, 128};
    glm::u8vec4 arc_color_fire{255, 0, 255, 128};

    // Server-side only
    float strength = 500.0f;
    float energy_use_per_second = 6.0f;
    float heat_per_second = 0.02f;

    // Beam runtime state
    float cooldown = 0.0f;
    string texture = "texture/beam_orange.png";

    void setArcAndAdjustRange(float arc_request);
    void setRangeAndAdjustArc(float range_request);
};

class TractorBeamEffect
{
public:
    float lifetime = 1.0f;
    float fade_speed = 1.0f;
    sp::ecs::Entity source;
    sp::ecs::Entity target;
    glm::vec3 source_offset{};
    glm::vec3 target_offset{};
    glm::vec2 target_location{};
    glm::vec3 hit_normal{};

    bool fire_ring = true;
    string beam_texture;
};
