#include "multiplayer/gravity.h"
#include "multiplayer.h"


BASIC_REPLICATION_IMPL(GravityReplication, Gravity)
    // Config fields: 1Hz with epsilon tolerance
    CONFIG_REPLICATION_FIELD_EPSILON(range, 1.0f);
    CONFIG_REPLICATION_FIELD_EPSILON(force, 0.1f);
}