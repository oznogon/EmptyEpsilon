#include "multiplayer/sciencetarget.h"
#include "multiplayer.h"

BASIC_REPLICATION_IMPL(ScienceTargetReplication, ScienceTarget)
    BASIC_REPLICATION_FIELD(entity);
}
