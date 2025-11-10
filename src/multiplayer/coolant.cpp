#include "multiplayer/coolant.h"
#include "multiplayer.h"


BASIC_REPLICATION_IMPL(CoolantReplication, Coolant)
    // Config fields: 1Hz
    CONFIG_REPLICATION_FIELD_EPSILON(max, 0.01f);
    CONFIG_REPLICATION_FIELD_EPSILON(max_coolant_per_system, 0.01f);
    CONFIG_REPLICATION_FIELD(auto_levels);
}