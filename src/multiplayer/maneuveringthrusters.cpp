#include "multiplayer/maneuveringthrusters.h"
#include "multiplayer.h"


BASIC_REPLICATION_IMPL(ManeuveringThrustersReplication, ManeuveringThrusters)
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

    BASIC_REPLICATION_FIELD(speed);
    // target uses numeric_limits<float>::min() as "no target" sentinel; reserved as 0xFFFF.
    // Valid angles [-360, 360] fit comfortably within the AI-produced range of [-180, 180].
    {
        auto encode = [](float v) -> uint16_t
        {
            if (v == std::numeric_limits<float>::min()) return std::numeric_limits<uint16_t>::max();
            return static_cast<uint16_t>(std::clamp((v + 360.0f) / 720.0f, 0.0f, 1.0f) * (std::numeric_limits<uint16_t>::max() - 1) + 0.5f);
        };
        switch(BRR) {
        case BasicReplicationRequest::SendAll: flags |= flag; tmp << encode(target.target); break;
        case BasicReplicationRequest::Update: {
            uint16_t qcur = encode(target.target), qbak = encode(backup->target);
            if (qcur != qbak) { flags |= flag; tmp << qcur; backup->target = target.target; }
            break;
        }
        case BasicReplicationRequest::Receive:
            if (flags & flag) {
                uint16_t q; packet >> q;
                target.target = (q == std::numeric_limits<uint16_t>::max())
                    ? std::numeric_limits<float>::min()
                    : static_cast<float>(q) / (std::numeric_limits<uint16_t>::max() - 1) * 720.0f - 360.0f;
            }
            break;
        }
        flag <<= 1;
    }
    BASIC_REPLICATION_FIELD(rotation_request);
}

BASIC_REPLICATION_IMPL(CombatManeuveringThrustersReplication, CombatManeuveringThrusters)
    BASIC_REPLICATION_FIELD(charge_time);
    BASIC_REPLICATION_FIELD(charge);
    BASIC_REPLICATION_FIELD(boost.request);
    BASIC_REPLICATION_FIELD(boost.active);
    BASIC_REPLICATION_FIELD(boost.speed);
    BASIC_REPLICATION_FIELD(boost.max_time);
    BASIC_REPLICATION_FIELD(boost.heat_per_second);
    BASIC_REPLICATION_FIELD(strafe.request);
    BASIC_REPLICATION_FIELD(strafe.active);
    BASIC_REPLICATION_FIELD(strafe.speed);
    BASIC_REPLICATION_FIELD(strafe.max_time);
    BASIC_REPLICATION_FIELD(strafe.heat_per_second);
}
