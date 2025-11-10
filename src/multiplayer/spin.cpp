#include "multiplayer/spin.h"
#include "multiplayer.h"


BASIC_REPLICATION_IMPL(SpinReplication, Spin)
    // Config field: 1Hz with epsilon tolerance
    CONFIG_REPLICATION_FIELD_EPSILON(rate, 0.01f);
}
