#include "multiplayer/drone.h"
#include "multiplayer.h"


BASIC_REPLICATION_IMPL(AllowDroneLinkReplication, AllowDroneLink)
    BASIC_REPLICATION_FIELD(owner);
}

BASIC_REPLICATION_IMPL(DroneControllerReplication, DroneController)
    BASIC_REPLICATION_FIELD(control_range);
    BASIC_REPLICATION_FIELD(energy_drain_per_sec);
}

BASIC_REPLICATION_IMPL(DroneLinkReplication, DroneLink)
    BASIC_REPLICATION_FIELD(linked_drone);
}
