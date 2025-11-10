#include "multiplayer/missiletubes.h"
#include "multiplayer.h"


BASIC_REPLICATION_IMPL(MissileTubesReplication, MissileTubes)
    // Config fields: 1Hz with epsilon tolerance
    CONFIG_REPLICATION_FIELD_EPSILON(health_max, 0.001f);
    CONFIG_REPLICATION_FIELD(can_be_hacked);
    CONFIG_REPLICATION_FIELD_EPSILON(power_factor, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(coolant_change_rate_per_second, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(heat_add_rate_per_second, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(power_change_rate_per_second, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(auto_repair_per_second, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(damage_per_second_on_overheat, 0.001f);

    CONFIG_REPLICATION_FIELD(storage_max[MW_Homing]);
    CONFIG_REPLICATION_FIELD(storage_max[MW_Nuke]);
    CONFIG_REPLICATION_FIELD(storage_max[MW_Mine]);
    CONFIG_REPLICATION_FIELD(storage_max[MW_EMP]);
    CONFIG_REPLICATION_FIELD(storage_max[MW_HVLI]);

    // System fields: 5Hz with epsilon tolerance
    SYSTEM_REPLICATION_FIELD_EPSILON(power_request, 0.001f);
    SYSTEM_REPLICATION_FIELD_EPSILON(coolant_request, 0.001f);

    // Fast fields: 20Hz with epsilon tolerance
    BASIC_REPLICATION_FIELD_EPSILON(health, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(power_level, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(coolant_level, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(heat_level, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(hacked_level, 0.001f);
    BASIC_REPLICATION_FIELD(storage[MW_Homing]);
    BASIC_REPLICATION_FIELD(storage[MW_Nuke]);
    BASIC_REPLICATION_FIELD(storage[MW_Mine]);
    BASIC_REPLICATION_FIELD(storage[MW_EMP]);
    BASIC_REPLICATION_FIELD(storage[MW_HVLI]);

    BASIC_REPLICATION_VECTOR(mounts)
        // Config fields: 1Hz with epsilon tolerance
        VECTOR_CONFIG_REPLICATION_FIELD(position);
        VECTOR_CONFIG_REPLICATION_FIELD_EPSILON(load_time, 0.1f);
        VECTOR_CONFIG_REPLICATION_FIELD(type_allowed_mask);
        VECTOR_CONFIG_REPLICATION_FIELD_EPSILON(direction, 0.1f);
        VECTOR_CONFIG_REPLICATION_FIELD(size);
        VECTOR_CONFIG_REPLICATION_FIELD(fire_count);

        // System fields: 5Hz
        VECTOR_SYSTEM_REPLICATION_FIELD(type_loaded);
        VECTOR_SYSTEM_REPLICATION_FIELD(state);

        // Fast fields: 20Hz
        VECTOR_REPLICATION_FIELD_EPSILON(delay, 0.01f);
    VECTOR_REPLICATION_END();
}
