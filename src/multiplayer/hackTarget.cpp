#include "multiplayer/hackTarget.h"
#include "multiplayer.h"

BASIC_REPLICATION_IMPL(HackTargetReplication, HackTarget)
    BASIC_REPLICATION_FIELD(entity);
}
