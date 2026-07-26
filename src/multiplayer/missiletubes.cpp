#include "multiplayer/missiletubes.h"
#include "multiplayer.h"


BASIC_REPLICATION_IMPL(MissileTubesReplication, MissileTubes)
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

    BASIC_REPLICATION_FIELD(storage);
    BASIC_REPLICATION_FIELD(storage_max);

    BASIC_REPLICATION_VECTOR(mounts)
        VECTOR_REPLICATION_FIELD(position);
        VECTOR_REPLICATION_FIELD(load_time);
        VECTOR_REPLICATION_FIELD(type_allowed_mask);
        VECTOR_REPLICATION_FIELD(direction);
        VECTOR_REPLICATION_FIELD(size);

        VECTOR_REPLICATION_FIELD(type_loaded);
        VECTOR_REPLICATION_FIELD(state);
        VECTOR_REPLICATION_FIELD_QUANTIZED(delay, uint8_t, 0.0f, 300.0f);
        VECTOR_REPLICATION_FIELD(fire_count);
        VECTOR_REPLICATION_FIELD(target_angle);
    VECTOR_REPLICATION_END();
}
