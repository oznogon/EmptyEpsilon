#include "multiplayer/moveto.h"
#include "multiplayer.h"


BASIC_REPLICATION_IMPL(MoveToReplication, MoveTo)
    // System fields: 5Hz with epsilon tolerance
    SYSTEM_REPLICATION_FIELD_EPSILON(speed, 0.1f);
    SYSTEM_REPLICATION_FIELD(target);
}
