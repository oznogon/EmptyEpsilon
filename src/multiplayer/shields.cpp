#include "multiplayer/shields.h"
#include "multiplayer.h"

BASIC_REPLICATION_IMPL(ShieldsReplication, Shields)
    BASIC_REPLICATION_FIELD(active);

    BASIC_REPLICATION_FIELD(front_system.health);
    BASIC_REPLICATION_FIELD(front_system.health_max);
    BASIC_REPLICATION_FIELD_QUANTIZED(front_system.power_level, uint16_t, 0.0f, 3.0f);
    BASIC_REPLICATION_FIELD(front_system.power_request);
    BASIC_REPLICATION_FIELD_QUANTIZED(front_system.heat_level, uint8_t, 0.0f, 1.0f);
    BASIC_REPLICATION_FIELD_QUANTIZED(front_system.coolant_level, uint8_t, 0.0f, 10.0f);
    BASIC_REPLICATION_FIELD(front_system.coolant_request);
    BASIC_REPLICATION_FIELD(front_system.can_be_hacked);
    BASIC_REPLICATION_FIELD_QUANTIZED(front_system.hacked_level, uint8_t, 0.0f, 1.0f);
    BASIC_REPLICATION_FIELD(front_system.power_factor);
    BASIC_REPLICATION_FIELD(front_system.coolant_change_rate_per_second);
    BASIC_REPLICATION_FIELD(front_system.heat_add_rate_per_second);
    BASIC_REPLICATION_FIELD(front_system.power_change_rate_per_second);
    BASIC_REPLICATION_FIELD(front_system.auto_repair_per_second);
    BASIC_REPLICATION_FIELD(front_system.damage_per_second_on_overheat);

    BASIC_REPLICATION_FIELD(rear_system.health);
    BASIC_REPLICATION_FIELD(rear_system.health_max);
    BASIC_REPLICATION_FIELD_QUANTIZED(rear_system.power_level, uint16_t, 0.0f, 3.0f);
    BASIC_REPLICATION_FIELD(rear_system.power_request);
    BASIC_REPLICATION_FIELD_QUANTIZED(rear_system.heat_level, uint8_t, 0.0f, 1.0f);
    BASIC_REPLICATION_FIELD_QUANTIZED(rear_system.coolant_level, uint8_t, 0.0f, 10.0f);
    BASIC_REPLICATION_FIELD(rear_system.coolant_request);
    BASIC_REPLICATION_FIELD(rear_system.can_be_hacked);
    BASIC_REPLICATION_FIELD_QUANTIZED(rear_system.hacked_level, uint8_t, 0.0f, 1.0f);
    BASIC_REPLICATION_FIELD(rear_system.power_factor);
    BASIC_REPLICATION_FIELD(rear_system.coolant_change_rate_per_second);
    BASIC_REPLICATION_FIELD(rear_system.heat_add_rate_per_second);
    BASIC_REPLICATION_FIELD(rear_system.power_change_rate_per_second);
    BASIC_REPLICATION_FIELD(rear_system.auto_repair_per_second);
    BASIC_REPLICATION_FIELD(rear_system.damage_per_second_on_overheat);

    BASIC_REPLICATION_FIELD(calibration_time);
    BASIC_REPLICATION_FIELD(calibration_delay);
    BASIC_REPLICATION_FIELD(frequency);

    BASIC_REPLICATION_FIELD(energy_use_per_second);

    BASIC_REPLICATION_VECTOR(entries)
        VECTOR_REPLICATION_FIELD(max);
        // level encoded as fraction of max; max must precede level so decode has the correct max.
        {
            switch(BRR) {
            case BasicReplicationRequest::SendAll:
                vector_flags |= vector_flag;
                vector_tmp << sp::multiplayer::quantize<uint16_t>(
                    vector_target->max > 0.0f ? vector_target->level / vector_target->max : 0.0f, 0.0f, 1.0f);
                break;
            case BasicReplicationRequest::Update: {
                auto _qcur = sp::multiplayer::quantize<uint16_t>(
                    vector_target->max > 0.0f ? vector_target->level / vector_target->max : 0.0f, 0.0f, 1.0f);
                auto _qbak = sp::multiplayer::quantize<uint16_t>(
                    vector_backup->max > 0.0f ? vector_backup->level / vector_backup->max : 0.0f, 0.0f, 1.0f);
                if (_qcur != _qbak) { vector_flags |= vector_flag; vector_tmp << _qcur; vector_backup->level = vector_target->level; }
                break;
            }
            case BasicReplicationRequest::Receive:
                if (vector_flags & vector_flag) {
                    uint16_t _q; packet >> _q;
                    vector_target->level = sp::multiplayer::dequantize(_q, 0.0f, 1.0f) * vector_target->max;
                }
                break;
            }
            vector_flag <<= 1;
        }
        VECTOR_REPLICATION_FIELD_QUANTIZED(hit_effect, uint8_t, 0.0f, 1.0f);
    VECTOR_REPLICATION_END();
}
