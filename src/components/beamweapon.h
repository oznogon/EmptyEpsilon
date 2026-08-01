#pragma once

#include "ecs/entity.h"
#include "shipsystem.h"
#include "systems/damage.h"
#include "glm/vec3.hpp"
#include "glm/gtc/type_precision.hpp"

class BeamWeaponSys : public ShipSystem
{
public:
    constexpr static int max_frequency = 20;
    int frequency = 0;
    int getFrequency() const { return frequency; }
    void setFrequency(int freq) { frequency = std::clamp(freq, 0, max_frequency); }
    ShipSystem::Type system_target = ShipSystem::Type::None;
    bool is_firing_enabled = true;
};

class BeamEffect
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
    glm::u8vec4 beam_color{255, 200, 0, 255};
};

float frequencyVsFrequencyDamageFactor(int beam_frequency, int shield_frequency);
string frequencyToString(int frequency);
