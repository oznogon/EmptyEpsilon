#include "multiplayer/spin.h"
#include "multiplayer.h"


BASIC_REPLICATION_IMPL_DIRTY(SpinReplication, Spin, dirty)
    BASIC_REPLICATION_FIELD(rate);
}
