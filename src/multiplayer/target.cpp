#include "multiplayer/target.h"
#include "multiplayer.h"


BASIC_REPLICATION_IMPL(TargetReplication, Target)
    // Fast field: 20Hz
    BASIC_REPLICATION_FIELD(entity);
}
