#pragma once

#include "ecs/entity.h"
#include "shipsystem.h"
#include "systems/damage.h"
#include "glm/vec3.hpp"
#include "glm/gtc/type_precision.hpp"


class TractorBeamSys : public ShipSystem {
public:
    class MountPoint {
    public:
        glm::vec3 position;//Visual position on the 3D model where this beam is fired from.

        //Beam configuration
        float arc = 0.0f;
        float direction = 0.0f;
        float range = 0.0f;
        float turret_arc = 0.0f;
        float turret_direction = 0.0f;
        float turret_rotation_rate = 0.0f;
        float cycle_time = 6.0f;
        float damage = 1.0f;//Server side only
        float energy_per_beam_fire = 3.0f;//Server side only
        float heat_per_beam_fire = 0.02f;//Server side only
        glm::u8vec4 arc_color{255, 0, 0, 128};
        glm::u8vec4 arc_color_fire{255, 255, 0, 128};
        DamageType damage_type = DamageType::Energy;

        //Beam runtime state
        float cooldown = 0.0f;
        string texture = "texture/beam_orange.png";
    };

    constexpr static int max_frequency = 20;
    int frequency = 0;
    ShipSystem::Type system_target = ShipSystem::Type::None;

    std::vector<MountPoint> mounts;

    glm::vec3 tractor_position = glm::vec3(0, 0, 0);
    float tractor_arc = 18.0f;
    float tractor_direction = 0.0f;
    float tractor_range = 1000.0f;
    float tractor_cycle_time = 6.0f;
    float tractor_damage = 1.0f;//Server side only
    float tractor_energy_per_tick = 3.0f;//Server side only
    float tractor_heat_per_tick = 0.02f;//Server side only
    glm::u8vec4 tractor_arc_color{0, 255, 255, 128};
    glm::u8vec4 tractor_arc_color_fire{255, 0, 255, 128};

    //Beam runtime state
    float tractor_cooldown = 0.0f;
    string tractor_texture = "texture/beam_orange.png";
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
