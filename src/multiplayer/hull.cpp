#include "multiplayer/hull.h"
#include "multiplayer.h"


BASIC_REPLICATION_IMPL(HullReplication, Hull)
    // Config field: 1Hz with epsilon tolerance
    CONFIG_REPLICATION_FIELD_EPSILON(max, 0.1f);
    // System field: 5Hz with epsilon tolerance
    SYSTEM_REPLICATION_FIELD_EPSILON(damage_indicator, 0.1f);
    // Fast field: 20Hz with epsilon tolerance
    BASIC_REPLICATION_FIELD_EPSILON(current, 0.1f);
}