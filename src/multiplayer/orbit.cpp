#include "multiplayer/orbit.h"
#include "multiplayer.h"


BASIC_REPLICATION_IMPL(OrbitReplication, Orbit)
    // System fields: 5Hz with epsilon tolerance
    SYSTEM_REPLICATION_FIELD(target);
    SYSTEM_REPLICATION_FIELD(center);
    SYSTEM_REPLICATION_FIELD_EPSILON(distance, 1.0f);
    SYSTEM_REPLICATION_FIELD_EPSILON(time, 0.01f);
}
