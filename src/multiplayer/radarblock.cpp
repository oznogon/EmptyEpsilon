#include "multiplayer/radarblock.h"
#include "multiplayer.h"


BASIC_REPLICATION_IMPL(RadarBlockReplication, RadarBlock)
    // Config field: 1Hz with epsilon tolerance
    CONFIG_REPLICATION_FIELD_EPSILON(range, 1.0f);

    // System field: 5Hz
    SYSTEM_REPLICATION_FIELD(behind);
}

EMPTY_REPLICATION_IMPL(NeverRadarBlockedReplication, NeverRadarBlocked)
