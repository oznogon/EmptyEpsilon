#include "multiplayer/shields.h"
#include "multiplayer.h"

BASIC_REPLICATION_IMPL(ShieldsReplication, Shields)
    // System-wide config fields: 1Hz with epsilon tolerance
    CONFIG_REPLICATION_FIELD_EPSILON(calibration_time, 0.1f);
    CONFIG_REPLICATION_FIELD_EPSILON(energy_use_per_second, 0.001f);

    // System-wide system fields: 5Hz
    SYSTEM_REPLICATION_FIELD(frequency);

    // System-wide fast fields: 20Hz with epsilon tolerance
    BASIC_REPLICATION_FIELD_EPSILON(calibration_delay, 0.001f);

    // Front shields subsystem
    // Config fields: 1Hz with epsilon tolerance
    CONFIG_REPLICATION_FIELD_EPSILON(front_system.health_max, 0.001f);
    CONFIG_REPLICATION_FIELD(front_system.can_be_hacked);
    CONFIG_REPLICATION_FIELD_EPSILON(front_system.power_factor, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(front_system.coolant_change_rate_per_second, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(front_system.heat_add_rate_per_second, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(front_system.power_change_rate_per_second, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(front_system.auto_repair_per_second, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(front_system.damage_per_second_on_overheat, 0.001f);

    // System fields: 5Hz with epsilon tolerance
    SYSTEM_REPLICATION_FIELD_EPSILON(front_system.power_request, 0.001f);
    SYSTEM_REPLICATION_FIELD_EPSILON(front_system.coolant_request, 0.001f);

    // Fast fields: 20Hz with epsilon tolerance
    BASIC_REPLICATION_FIELD_EPSILON(front_system.health, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(front_system.power_level, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(front_system.heat_level, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(front_system.coolant_level, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(front_system.hacked_level, 0.001f);

    // Rear shields subsystem
    // Config fields: 1Hz with epsilon tolerance
    CONFIG_REPLICATION_FIELD_EPSILON(rear_system.health_max, 0.001f);
    CONFIG_REPLICATION_FIELD(rear_system.can_be_hacked);
    CONFIG_REPLICATION_FIELD_EPSILON(rear_system.power_factor, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(rear_system.coolant_change_rate_per_second, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(rear_system.heat_add_rate_per_second, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(rear_system.power_change_rate_per_second, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(rear_system.auto_repair_per_second, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(rear_system.damage_per_second_on_overheat, 0.001f);

    // System fields: 5Hz with epsilon tolerance
    SYSTEM_REPLICATION_FIELD_EPSILON(rear_system.power_request, 0.001f);
    SYSTEM_REPLICATION_FIELD_EPSILON(rear_system.coolant_request, 0.001f);

    // Fast fields: 20Hz with epsilon tolerance
    BASIC_REPLICATION_FIELD_EPSILON(rear_system.health, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(rear_system.power_level, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(rear_system.heat_level, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(rear_system.coolant_level, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(rear_system.hacked_level, 0.001f);
    BASIC_REPLICATION_FIELD(active);

    BASIC_REPLICATION_VECTOR(entries)
        // Config fields: 1Hz with epsilon tolerance
        VECTOR_CONFIG_REPLICATION_FIELD_EPSILON(max, 0.1f);

        // Fast fields: 20Hz with epsilon tolerance
        VECTOR_REPLICATION_FIELD_EPSILON(level, 0.01f);
        VECTOR_REPLICATION_FIELD_EPSILON(hit_effect, 0.01f);
    VECTOR_REPLICATION_END();
}
