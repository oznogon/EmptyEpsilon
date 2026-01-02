#include "multiplayer/relaytarget.h"
#include "multiplayer.h"

BASIC_REPLICATION_IMPL(RelayTargetReplication, RelayTarget)
    BASIC_REPLICATION_FIELD(entity);
}
