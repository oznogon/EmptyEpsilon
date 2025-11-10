#include "multiplayer/maneuveringthrusters.h"
#include "multiplayer.h"


BASIC_REPLICATION_IMPL(ManeuveringThrustersReplication, ManeuveringThrusters)
    // Config fields: 1Hz with epsilon tolerance
    CONFIG_REPLICATION_FIELD_EPSILON(health_max, 0.001f);
    CONFIG_REPLICATION_FIELD(can_be_hacked);
    CONFIG_REPLICATION_FIELD_EPSILON(power_factor, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(coolant_change_rate_per_second, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(heat_add_rate_per_second, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(power_change_rate_per_second, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(auto_repair_per_second, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(damage_per_second_on_overheat, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(speed, 0.1f);

    // System fields: 5Hz with epsilon tolerance
    SYSTEM_REPLICATION_FIELD_EPSILON(power_request, 0.001f);
    SYSTEM_REPLICATION_FIELD_EPSILON(coolant_request, 0.001f);

    // Fast fields: 20Hz with epsilon tolerance
    BASIC_REPLICATION_FIELD_EPSILON(health, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(power_level, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(heat_level, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(coolant_level, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(hacked_level, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(target, 0.01f);
    BASIC_REPLICATION_FIELD_EPSILON(rotation_request, 0.01f);
}

BASIC_REPLICATION_IMPL(CombatManeuveringThrustersReplication, CombatManeuveringThrusters)
    // Config fields: 1Hz with epsilon tolerance
    CONFIG_REPLICATION_FIELD_EPSILON(charge_time, 0.01f);
    CONFIG_REPLICATION_FIELD_EPSILON(boost.speed, 0.1f);
    CONFIG_REPLICATION_FIELD_EPSILON(boost.max_time, 0.01f);
    CONFIG_REPLICATION_FIELD_EPSILON(boost.heat_per_second, 0.001f);
    CONFIG_REPLICATION_FIELD_EPSILON(strafe.speed, 0.1f);
    CONFIG_REPLICATION_FIELD_EPSILON(strafe.max_time, 0.01f);
    CONFIG_REPLICATION_FIELD_EPSILON(strafe.heat_per_second, 0.001f);

    // Fast fields: 20Hz with epsilon tolerance
    BASIC_REPLICATION_FIELD_EPSILON(charge, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(boost.request, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(boost.active, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(strafe.request, 0.001f);
    BASIC_REPLICATION_FIELD_EPSILON(strafe.active, 0.001f);
}
