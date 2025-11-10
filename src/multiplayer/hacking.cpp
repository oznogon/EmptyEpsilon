#include "multiplayer/hacking.h"
#include "multiplayer.h"


BASIC_REPLICATION_IMPL(HackingDeviceReplication, HackingDevice)
    // Config field: 1Hz with epsilon tolerance
    CONFIG_REPLICATION_FIELD_EPSILON(effectiveness, 0.01f);
}