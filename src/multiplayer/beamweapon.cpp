#include "multiplayer/beamweapon.h"
#include "multiplayer.h"

BASIC_REPLICATION_IMPL(BeamWeaponSysReplication, BeamWeaponSys)
    BASIC_REPLICATION_FIELD(health);
    BASIC_REPLICATION_FIELD(health_max);
    BASIC_REPLICATION_FIELD_QUANTIZED(power_level, uint16_t, 0.0f, 3.0f);
    BASIC_REPLICATION_FIELD(power_request);
    BASIC_REPLICATION_FIELD_QUANTIZED(heat_level, uint8_t, 0.0f, 1.0f);
    BASIC_REPLICATION_FIELD_QUANTIZED(coolant_level, uint8_t, 0.0f, 10.0f);
    BASIC_REPLICATION_FIELD(coolant_request);
    BASIC_REPLICATION_FIELD(can_be_hacked);
    BASIC_REPLICATION_FIELD_QUANTIZED(hacked_level, uint8_t, 0.0f, 1.0f);
    BASIC_REPLICATION_FIELD(power_factor);
    BASIC_REPLICATION_FIELD(coolant_change_rate_per_second);
    BASIC_REPLICATION_FIELD(heat_add_rate_per_second);
    BASIC_REPLICATION_FIELD(power_change_rate_per_second);
    BASIC_REPLICATION_FIELD(auto_repair_per_second);
    BASIC_REPLICATION_FIELD(damage_per_second_on_overheat);

    BASIC_REPLICATION_FIELD(frequency);
    BASIC_REPLICATION_FIELD(system_target);
    BASIC_REPLICATION_FIELD(is_firing_enabled);
}


BASIC_REPLICATION_IMPL(BeamEffectReplication, BeamEffect)
    BASIC_REPLICATION_FIELD(lifetime);
    BASIC_REPLICATION_FIELD(source);
    BASIC_REPLICATION_FIELD(target);
    BASIC_REPLICATION_FIELD(source_offset);
    BASIC_REPLICATION_FIELD(target_offset);
    BASIC_REPLICATION_FIELD(target_location);
    BASIC_REPLICATION_FIELD(hit_normal);

    BASIC_REPLICATION_FIELD(fire_ring);
    BASIC_REPLICATION_FIELD(beam_texture);
}
