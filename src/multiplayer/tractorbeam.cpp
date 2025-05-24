#include "multiplayer/tractorbeam.h"
#include "multiplayer.h"

BASIC_REPLICATION_IMPL(TractorBeamSysReplication, TractorBeamSys)
    BASIC_REPLICATION_FIELD(health);
    BASIC_REPLICATION_FIELD(health_max);
    BASIC_REPLICATION_FIELD(power_level);
    BASIC_REPLICATION_FIELD(power_request);
    BASIC_REPLICATION_FIELD(heat_level);
    BASIC_REPLICATION_FIELD(coolant_level);
    BASIC_REPLICATION_FIELD(coolant_request);
    BASIC_REPLICATION_FIELD(can_be_hacked);
    BASIC_REPLICATION_FIELD(hacked_level);
    BASIC_REPLICATION_FIELD(power_factor);
    BASIC_REPLICATION_FIELD(coolant_change_rate_per_second);
    BASIC_REPLICATION_FIELD(heat_add_rate_per_second);
    BASIC_REPLICATION_FIELD(power_change_rate_per_second);
    BASIC_REPLICATION_FIELD(auto_repair_per_second);
    BASIC_REPLICATION_FIELD(damage_per_second_on_overheat);

    BASIC_REPLICATION_FIELD(frequency);
    BASIC_REPLICATION_FIELD(system_target);

    BASIC_REPLICATION_FIELD(tractor_position);
    BASIC_REPLICATION_FIELD(tractor_arc);
    BASIC_REPLICATION_FIELD(tractor_direction);
    BASIC_REPLICATION_FIELD(tractor_range);
    BASIC_REPLICATION_FIELD(tractor_cycle_time);
    BASIC_REPLICATION_FIELD(tractor_damage);
    BASIC_REPLICATION_FIELD(tractor_energy_per_tick);
    BASIC_REPLICATION_FIELD(tractor_heat_per_tick);
    BASIC_REPLICATION_FIELD(tractor_arc_color);
    BASIC_REPLICATION_FIELD(tractor_arc_color_fire);
    BASIC_REPLICATION_FIELD(tractor_cooldown);
    BASIC_REPLICATION_FIELD(tractor_texture);
}


BASIC_REPLICATION_IMPL(TractorBeamEffectReplication, TractorBeamEffect)
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
