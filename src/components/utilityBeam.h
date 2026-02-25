#pragma once

#include "ecs/entity.h"
#include "script/callback.h"
#include "shipsystem.h"
#include "crewPosition.h"
#include "glm/vec3.hpp"
#include "glm/gtc/type_precision.hpp"
#include <unordered_map>


class UtilityBeam : public ShipSystem
{
public:
    // Definitions
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

    // Beam modes
    string custom_beam_mode = "";
    std::vector<CustomBeamMode> custom_beam_modes;
    sp::ecs::Entity effect_target_entity;
    std::unordered_map<sp::ecs::Entity, sp::ecs::Entity> beam_effect_entities; // server only

    // Crew positions whose screens display the utility beam controls.
    // Defaults to science officer and operations officer.
    CrewPositions crew_positions = [] { CrewPositions cp; cp.add(CrewPosition::scienceOfficer); cp.add(CrewPosition::operationsOfficer); return cp; }();

    // State
    bool active = false;
    bool is_firing = false;

    // Position and direction
    glm::vec3 position = glm::vec3(0.01f, 0.01f, 0.01f); // hack
    float bearing = 0.0f;
    bool fixed_bearing = false;

    // Arc/range setters
    bool setArc(float arc_request);
    bool setArcAndAdjustRange(float arc_request);
    bool setRange(float range_request);
    bool setRangeAndAdjustArc(float range_request);

    // Arc/range and constraints
    static constexpr float MIN_ARC = 6.0f;
    float max_arc = 90.0f;
    float arc = 90.0f;
    bool fixed_arc = false;

    static constexpr float MIN_RANGE = 500.0f;
    float max_range = 2000.0f;
    float range = 1000.0f;
    bool fixed_range = false;

    // Resource consumption
    float cycle_time = 6.0f;
    float strength = 500.0f;
    float energy_use_per_second = 6.0f;
    float heat_per_second = 0.02f;

    glm::vec2 utility_target_coordinates{0.0f, 0.0f};

    // Beam effect appearance
    glm::u8vec4 arc_color{0, 255, 255, 128};
    glm::u8vec4 arc_color_fire{255, 0, 255, 128};
    string texture = "texture/beam_purple.png";

    // Beam runtime state
    float cooldown = 0.0f;
};

class UtilityBeamEffect
{
public:
    // Same params as BeamEffect, different presentation
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
