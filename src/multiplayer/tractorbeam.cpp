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

    BASIC_REPLICATION_FIELD(position);
    BASIC_REPLICATION_FIELD(arc);
    BASIC_REPLICATION_FIELD(bearing);
    BASIC_REPLICATION_FIELD(range);
    BASIC_REPLICATION_FIELD(cycle_time);
    BASIC_REPLICATION_FIELD(strength);
    BASIC_REPLICATION_FIELD(energy_per_tick);
    BASIC_REPLICATION_FIELD(heat_per_tick);
    BASIC_REPLICATION_FIELD(arc_color);
    BASIC_REPLICATION_FIELD(arc_color_fire);
    BASIC_REPLICATION_FIELD(cooldown);
    BASIC_REPLICATION_FIELD(texture);
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
