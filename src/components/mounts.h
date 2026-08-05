#pragma once

#include "ecs/entity.h"
#include "systems/damage.h"
#include "missileWeaponData.h"
#include "crewPosition.h"
#include "script/callback.h"
#include "io/dataBuffer.h"
#include "multiplayer/basic.h"
#include "vectorUtils.h"
#include <glm/vec3.hpp>
#include <glm/gtc/type_precision.hpp>
#include <algorithm>
#include <vector>
#include <string>

enum class MountType : uint8_t
{
    BeamWeapon = 0,
    MissileWeapon = 1,
    UtilityBeam = 2
};

enum class MountState
{
    Empty,
    Loading,
    Loaded,
    Unloading,
    Firing
};

class CustomBeamMode
{
public:
    string name;
    sp::script::Callback callback;
    sp::script::Callback deactivate_callback;
    int order = 0;
    bool requires_target = true;
    float energy_per_sec = 0.0f;
    float heat_per_sec = 0.0f;
    float progress = -1.0f;

    bool operator!=(const CustomBeamMode& ubf) { return name != ubf.name; }
    bool operator<(const CustomBeamMode& other) const { return (order < other.order); }
};

struct Mount
{
    MountType type = MountType::BeamWeapon;

    // Common (all types)
    glm::vec3 position{};
    float direction = 0.0f;
    float cycle_time = 6.0f;
    float turret_arc = 0.0f;
    float turret_direction = 0.0f;
    float turret_rotation_rate = 0.0f;
    bool turret_locked = false;

    // Common to beams (BeamWeapon, UtilityBeam)
    float arc = 0.0f;
    float range = 0.0f;
    float energy_per_beam_fire = 3.0f;
    float heat_per_beam_fire = 0.02f;
    glm::u8vec4 arc_color{255, 0, 0, 128};
    glm::u8vec4 arc_color_fire{255, 255, 0, 128};
    string texture = "texture/beam_orange.png";
    float cooldown = 0.0f;

    // BeamWeapon-specific
    float damage = 1.0f;
    DamageType damage_type = DamageType::Energy;

    // UtilityBeam-specific
    float max_arc = 90.0f;
    bool fixed_arc = false;
    float max_range = 2000.0f;
    bool fixed_range = false;
    float strength = 500.0f;
    float energy_use_per_second = 6.0f;
    float heat_per_second = 0.02f;
    bool active = false;
    bool is_firing = false;
    string custom_beam_mode = "";
    CrewPositions crew_positions = []
    {
        CrewPositions cp;
        cp.add(CrewPosition::scienceOfficer);
        cp.add(CrewPosition::operationsOfficer);
        return cp;
    }();
    std::vector<CustomBeamMode> custom_beam_modes;

    // MissileWeapon-specific
    float load_time = 8.0f;
    uint32_t type_allowed_mask = (1 << MW_MaxTypes) - 1;
    EMissileSizes missile_size = MS_Medium;
    int type_loaded = MW_None;
    MountState state = MountState::Empty;
    float delay = 0.0f;
    int fire_count = 0;
    float target_angle = 0.0f;

    bool canLoad(int type_index) const
    {
        if (type_index < 0) return false;
        return (type_allowed_mask & (1 << type_index));
    }

    bool canOnlyLoad(int type_index) const
    {
        if (type_index < 0) return false;
        return (type_allowed_mask == (1U << type_index));
    }

    // Rotate a turreted mount's aim angle toward a target angle within the mount's
    // turret arc, at the given rotation rate. If the target is outside of the
    // turret arc, rotate the aim angle back toward the mount's default turret
    // direction instead.
    float rotateMountTurretTowards(float aim_angle, float ship_rotation, float target_angle, float turret_direction, float turret_arc, float rotation_rate)
    {
        const float turret_angle_diff = angleDifference(turret_direction + ship_rotation, target_angle);

        // The target is outside of the turret arc, so rotate back toward the
        // mount's default turret direction.
        if (fabsf(turret_angle_diff) >= turret_arc * 0.5f)
            return resetMountTurret(aim_angle, turret_direction, rotation_rate);

        // Rotate the aim angle toward the target.
        const float angle_diff = angleDifference(aim_angle + ship_rotation, target_angle);

        if (fabsf(angle_diff) <= 0.0f) return aim_angle;

        return aim_angle + (angle_diff / fabsf(angle_diff)) * std::min(rotation_rate, fabsf(angle_diff));
    }

    // Rotate a turreted mount's aim angle back toward its default turret direction,
    // at the given rotation rate.
    float resetMountTurret(float aim_angle, float turret_direction, float rotation_rate)
    {
        const float reset_angle_diff = angleDifference(aim_angle, turret_direction);

        if (fabsf(reset_angle_diff) <= 0.0f) return aim_angle;

        return aim_angle + (reset_angle_diff / fabsf(reset_angle_diff)) * std::min(rotation_rate, fabsf(reset_angle_diff));
    }
};

namespace sp::io {
    static inline DataBuffer& operator << (DataBuffer& packet, const CustomBeamMode& m)
    {
        return packet << m.name << m.order << m.energy_per_sec << m.heat_per_sec << m.requires_target << m.progress;
    }
    static inline DataBuffer& operator >> (DataBuffer& packet, CustomBeamMode& m)
    {
        return packet >> m.name >> m.order >> m.energy_per_sec >> m.heat_per_sec >> m.requires_target >> m.progress;
    }

    static inline DataBuffer& operator << (DataBuffer& packet, const std::vector<CustomBeamMode>& v)
    {
        packet << uint32_t(v.size());
        for (const auto& entry : v)
            packet << entry;
        return packet;
    }
    static inline DataBuffer& operator >> (DataBuffer& packet, std::vector<CustomBeamMode>& v)
    {
        uint32_t size = 0;
        packet >> size;
        size = uint32_t(sp::io::boundReplicatedVectorSize(size, packet.available()));
        v.clear();
        v.reserve(size);
        for (uint32_t n = 0; n < size; n++)
        {
            v.emplace_back();
            packet >> v.back();
        }
        return packet;
    }

    static inline DataBuffer& operator << (DataBuffer& packet, const Mount& m)
    {
        packet << static_cast<uint8_t>(m.type)
               << m.position.x << m.position.y << m.position.z
               << m.direction << m.turret_arc << m.turret_direction
               << m.turret_rotation_rate << m.cycle_time
               << m.arc << m.range << m.damage << m.energy_per_beam_fire
               << m.heat_per_beam_fire
               << m.arc_color.r << m.arc_color.g << m.arc_color.b << m.arc_color.a
               << m.arc_color_fire.r << m.arc_color_fire.g << m.arc_color_fire.b << m.arc_color_fire.a
               << static_cast<uint16_t>(m.damage_type) << m.texture << m.cooldown
               << m.load_time << m.type_allowed_mask << m.missile_size
               << m.type_loaded << static_cast<uint8_t>(m.state) << m.delay
               << m.fire_count << m.target_angle
               << m.max_arc << m.fixed_arc << m.max_range << m.fixed_range
               << m.strength
               << m.energy_use_per_second << m.heat_per_second
               << m.active << m.is_firing << m.custom_beam_mode << m.crew_positions.mask
               << m.custom_beam_modes << m.turret_locked;
        return packet;
    }
    static inline DataBuffer& operator >> (DataBuffer& packet, Mount& m)
    {
        uint8_t type_val;
        packet >> type_val;
        m.type = static_cast<MountType>(type_val);

        packet >> m.position.x >> m.position.y >> m.position.z
               >> m.direction >> m.turret_arc >> m.turret_direction
               >> m.turret_rotation_rate >> m.cycle_time
               >> m.arc >> m.range >> m.damage >> m.energy_per_beam_fire
               >> m.heat_per_beam_fire
               >> m.arc_color.r >> m.arc_color.g >> m.arc_color.b >> m.arc_color.a
               >> m.arc_color_fire.r >> m.arc_color_fire.g >> m.arc_color_fire.b >> m.arc_color_fire.a;
        {
            uint16_t v;
            packet >> v;
            m.damage_type = static_cast<DamageType>(v);
        }
        packet >> m.texture >> m.cooldown
               >> m.load_time >> m.type_allowed_mask >> m.missile_size
               >> m.type_loaded;
        {
            uint8_t v;
            packet >> v;
            m.state = static_cast<MountState>(v);
        }
        packet >> m.delay >> m.fire_count >> m.target_angle
               >> m.max_arc >> m.fixed_arc >> m.max_range >> m.fixed_range
               >> m.strength
               >> m.energy_use_per_second >> m.heat_per_second
               >> m.active >> m.is_firing >> m.custom_beam_mode >> m.crew_positions.mask
               >> m.custom_beam_modes >> m.turret_locked;

        return packet;
    }
}

class Mounts
{
public:
    std::vector<Mount> mounts;
    bool mounts_dirty = true;
};
