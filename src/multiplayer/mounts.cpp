#include "multiplayer/mounts.h"
#include "multiplayer.h"

BASIC_REPLICATION_IMPL(MountsReplication, Mounts)
    REPLICATE_VECTOR_IF_DIRTY(mounts, mounts_dirty);
}
