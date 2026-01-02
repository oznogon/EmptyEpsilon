#include "multiplayer/hacking.h"
#include "multiplayer.h"


BASIC_REPLICATION_IMPL(HackingDeviceReplication, HackingDevice)
    BASIC_REPLICATION_FIELD(effectiveness);
    BASIC_REPLICATION_FIELD(target);
}