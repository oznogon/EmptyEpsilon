#include "multiplayer/mounts.h"
#include "multiplayer.h"

namespace sp::io
{
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
    packet << static_cast<uint32_t>(v.size());

    for (const auto& entry : v) packet << entry;

    return packet;
}

static inline DataBuffer& operator >> (DataBuffer& packet, std::vector<CustomBeamMode>& v)
{
    uint32_t size = 0;
    packet >> size;
    size = static_cast<uint32_t>(sp::io::boundReplicatedVectorSize(size, packet.available()));
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

BASIC_REPLICATION_IMPL(MountsReplication, Mounts)
    REPLICATE_VECTOR_IF_DIRTY(mounts, mounts_dirty);
}
