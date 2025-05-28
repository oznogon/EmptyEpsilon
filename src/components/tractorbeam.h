#pragma once

#include "ecs/entity.h"
#include "shipsystem.h"
#include "systems/damage.h"
#include "glm/vec3.hpp"
#include "glm/gtc/type_precision.hpp"


class TractorBeamSys : public ShipSystem {
public:
    glm::vec3 position = glm::vec3(0, 0, 0);
    bool active = false;
    float arc = 18.0f;
    float bearing = 0.0f;
    float range = 1000.0f;
    float cycle_time = 6.0f;
    float strength = 1.0f;//Server side only
    float energy_per_tick = 3.0f;//Server side only
    float heat_per_tick = 0.02f;//Server side only
    glm::u8vec4 arc_color{0, 255, 255, 128};
    glm::u8vec4 arc_color_fire{255, 0, 255, 128};

    //Beam runtime state
    float cooldown = 0.0f;
    string texture = "texture/beam_orange.png";
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
