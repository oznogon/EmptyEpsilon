#pragma once

#include "ecs/entity.h"
#include "shipsystem.h"
#include "glm/vec3.hpp"
#include <unordered_map>

static constexpr float UTILITY_BEAM_MIN_ARC = 6.0f;
static constexpr float UTILITY_BEAM_MIN_RANGE = 500.0f;

struct Mount;

bool utilityBeamSetArc(Mount& mount, float arc_request);
bool utilityBeamSetArcAndAdjustRange(Mount& mount, float arc_request);
bool utilityBeamSetRange(Mount& mount, float range_request);
bool utilityBeamSetRangeAndAdjustArc(Mount& mount, float range_request);

class UtilityBeam : public ShipSystem
{
public:
    UtilityBeam() = default;

    sp::ecs::Entity effect_target_entity;
    std::unordered_map<sp::ecs::Entity, sp::ecs::Entity> beam_effect_entities; // server only

    bool was_active = false;

    glm::vec2 utility_target_coordinates{0.0f, 0.0f};
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
