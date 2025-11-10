#include "multiplayer/warp.h"
#include "multiplayer.h"


BASIC_REPLICATION_IMPL(WarpDriveReplication, WarpDrive)
    // Config fields: 1Hz with epsilon tolerance
    CONFIG_REPLICATION_FIELD_EPSILON(health_max, 0.001f);
    CONFIG_REPLICATION_FIELD(can_be_hacked);
    CONFIG_REPLICATION_FIELD_EPSILON(power_factor, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(coolant_change_rate_per_second, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(heat_add_rate_per_second, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(power_change_rate_per_second, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(auto_repair_per_second, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(damage_per_second_on_overheat, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(charge_time, 0.01f);
    CONFIG_REPLICATION_FIELD_EPSILON(decharge_time, 0.01f);
    CONFIG_REPLICATION_FIELD_EPSILON(heat_per_warp, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(max_level, 1.0f);
    CONFIG_REPLICATION_FIELD_EPSILON(speed_per_level, 0.1f);
    CONFIG_REPLICATION_FIELD_EPSILON(energy_warp_per_second, 0.001f);

    // System fields: 5Hz with epsilon tolerance
    SYSTEM_REPLICATION_FIELD_EPSILON(power_request, 0.001f);
    SYSTEM_REPLICATION_FIELD_EPSILON(coolant_request, 0.001f);
    SYSTEM_REPLICATION_FIELD_EPSILON(request, 0.5f);

    // Fast fields: 20Hz with epsilon tolerance
    BASIC_REPLICATION_FIELD_EPSILON(health, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(power_level, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(heat_level, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(coolant_level, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(hacked_level, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(current, 0.005f);
}

BASIC_REPLICATION_IMPL(WarpJammerReplication, WarpJammer)
    // Config fields: 1Hz with epsilon tolerance
    CONFIG_REPLICATION_FIELD_EPSILON(range, 1.0f);
}
