#pragma once

#include "ecs/entity.h"
#include "script/callback.h"
#include "shipsystem.h"
#include "glm/vec3.hpp"
#include "glm/gtc/type_precision.hpp"


class UtilityBeam : public ShipSystem
{
public:
    class CustomBeamMode
    {
    public:
        string name;
        sp::script::Callback callback;
        int order;
        bool requires_target = true;
        float energy_per_sec = 0.0f;
        float heat_per_sec = 0.0f;
        float progress = -1.0f;

        bool operator!=(const CustomBeamMode& ubf) { return name != ubf.name; }
        bool operator<(const CustomBeamMode& other) const { return (order < other.order); }
    };

    UtilityBeam() = default;

    string custom_beam_mode = "";
    std::vector<CustomBeamMode> custom_beam_modes;
    bool custom_beam_modes_dirty = true;
    sp::ecs::Entity effect_target_entity;

    bool active = false;
    bool is_firing = false;

    glm::vec3 position = glm::vec3(0.01f, 0.01f, 0.01f); // hack
    float bearing = 0.0f;
    bool fixed_bearing = false;

    bool setArc(float arc_request);
    bool setArcAndAdjustRange(float arc_request);
    bool setRange(float range_request);
    bool setRangeAndAdjustArc(float range_request);

    static constexpr float MIN_ARC = 6.0f;
    float max_arc = 90.0f;
    float arc = 90.0f;
    bool fixed_arc = false;

    static constexpr float MIN_RANGE = 500.0f;
    float max_range = 2000.0f;
    float range = 1000.0f;
    bool fixed_range = false;

    float cycle_time = 6.0f;
    float strength = 500.0f;
    float energy_use_per_second = 6.0f;
    float heat_per_second = 0.02f;

    // TODOs
    glm::vec2 utility_target_coordinates{0.0f, 0.0f};
    glm::u8vec4 arc_color{0, 255, 255, 128};
    glm::u8vec4 arc_color_fire{255, 0, 255, 128};
    string texture = "texture/beam_purple.png";

    // Beam runtime state
    float cooldown = 0.0f;
};

class UtilityBeamEffect
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
