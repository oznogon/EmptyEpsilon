#include "multiplayer/jumpdrive.h"
#include "multiplayer.h"


BASIC_REPLICATION_IMPL(JumpDriveReplication, JumpDrive)
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
    CONFIG_REPLICATION_FIELD_EPSILON(energy_per_km_charge, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(heat_per_jump, 0.01f);
    CONFIG_REPLICATION_FIELD_EPSILON(min_distance, 1.0f);
    CONFIG_REPLICATION_FIELD_EPSILON(max_distance, 1.0f);
    CONFIG_REPLICATION_FIELD_EPSILON(activation_delay, 0.01f);

    // System fields: 5Hz with epsilon tolerance
    SYSTEM_REPLICATION_FIELD_EPSILON(power_request, 0.001f);
    SYSTEM_REPLICATION_FIELD_EPSILON(coolant_request, 0.001f);

    // Fast fields: 20Hz with epsilon tolerance
    BASIC_REPLICATION_FIELD_EPSILON(health, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(power_level, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(heat_level, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(coolant_level, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(hacked_level, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(charge, 0.01f);
    BASIC_REPLICATION_FIELD_EPSILON(distance, 1.0f);
    BASIC_REPLICATION_FIELD(delay);
    BASIC_REPLICATION_FIELD(just_jumped);
}
