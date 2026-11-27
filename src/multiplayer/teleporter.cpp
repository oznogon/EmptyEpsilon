#include "multiplayer/teleporter.h"
#include "multiplayer.h"


BASIC_REPLICATION_IMPL(TeleporterReplication, Teleporter)
    BASIC_REPLICATION_FIELD(target_coordinates);
    BASIC_REPLICATION_FIELD(teleport_on_collision);
    BASIC_REPLICATION_FIELD(is_single_use);
}
