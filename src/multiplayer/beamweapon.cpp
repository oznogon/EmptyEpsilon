#include "multiplayer/beamweapon.h"
#include "multiplayer.h"

BASIC_REPLICATION_IMPL(BeamWeaponSysReplication, BeamWeaponSys)
    // Config fields: 1Hz with epsilon tolerance
    CONFIG_REPLICATION_FIELD_EPSILON(health_max, 0.001f);
    CONFIG_REPLICATION_FIELD(can_be_hacked);
    CONFIG_REPLICATION_FIELD_EPSILON(power_factor, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(coolant_change_rate_per_second, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(heat_add_rate_per_second, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(power_change_rate_per_second, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(auto_repair_per_second, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(damage_per_second_on_overheat, 0.001f);

    // System fields: 5Hz with epsilon tolerance
    SYSTEM_REPLICATION_FIELD_EPSILON(power_request, 0.001f);
    SYSTEM_REPLICATION_FIELD_EPSILON(coolant_request, 0.001f);

    // Fast fields: 20Hz with epsilon tolerance
    BASIC_REPLICATION_FIELD_EPSILON(health, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(power_level, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(coolant_level, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(heat_level, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(hacked_level, 0.001f);
    BASIC_REPLICATION_FIELD(frequency);
    BASIC_REPLICATION_FIELD(system_target);

    BASIC_REPLICATION_VECTOR(mounts)
        // Config fields: 1Hz with epsilon tolerance
        VECTOR_CONFIG_REPLICATION_FIELD(position);
        VECTOR_CONFIG_REPLICATION_FIELD_EPSILON(arc, 0.1f);
        VECTOR_CONFIG_REPLICATION_FIELD_EPSILON(range, 1.0f);
        VECTOR_CONFIG_REPLICATION_FIELD_EPSILON(turret_arc, 0.1f);
        VECTOR_CONFIG_REPLICATION_FIELD_EPSILON(turret_direction, 0.5f);
        VECTOR_CONFIG_REPLICATION_FIELD_EPSILON(turret_rotation_rate, 0.01f);
        VECTOR_CONFIG_REPLICATION_FIELD_EPSILON(cycle_time, 0.01f);
        VECTOR_CONFIG_REPLICATION_FIELD_EPSILON(damage, 0.1f);
        VECTOR_CONFIG_REPLICATION_FIELD_EPSILON(energy_per_beam_fire, 0.1f);
        VECTOR_CONFIG_REPLICATION_FIELD_EPSILON(heat_per_beam_fire, 0.01f);
        VECTOR_CONFIG_REPLICATION_FIELD(arc_color);
        VECTOR_CONFIG_REPLICATION_FIELD(arc_color_fire);
        VECTOR_CONFIG_REPLICATION_FIELD(damage_type);
        VECTOR_CONFIG_REPLICATION_FIELD(texture);

        // Fast fields: 20Hz with epsilon tolerance
        VECTOR_REPLICATION_FIELD_EPSILON(direction, 0.1f);
        VECTOR_REPLICATION_FIELD_EPSILON(cooldown, 0.01f);
    VECTOR_REPLICATION_END();
}


BASIC_REPLICATION_IMPL(BeamEffectReplication, BeamEffect)
    // Config fields: 1Hz
    CONFIG_REPLICATION_FIELD(lifetime);
    CONFIG_REPLICATION_FIELD(source);
    CONFIG_REPLICATION_FIELD(target);
    CONFIG_REPLICATION_FIELD(source_offset);
    CONFIG_REPLICATION_FIELD(target_offset);
    CONFIG_REPLICATION_FIELD(target_location);
    CONFIG_REPLICATION_FIELD(hit_normal);

    CONFIG_REPLICATION_FIELD(fire_ring);
    CONFIG_REPLICATION_FIELD(beam_texture);
}
