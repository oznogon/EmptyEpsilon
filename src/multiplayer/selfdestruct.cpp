#include "multiplayer/selfdestruct.h"
#include "multiplayer.h"


BASIC_REPLICATION_IMPL(SelfDestructReplication, SelfDestruct)
    // Config fields: 1Hz
    CONFIG_REPLICATION_FIELD(active);
    CONFIG_REPLICATION_FIELD(code[0]);
    CONFIG_REPLICATION_FIELD(code[1]);
    CONFIG_REPLICATION_FIELD(code[2]);
    CONFIG_REPLICATION_FIELD(confirmed[0]);
    CONFIG_REPLICATION_FIELD(confirmed[1]);
    CONFIG_REPLICATION_FIELD(confirmed[2]);
    CONFIG_REPLICATION_FIELD(entry_position[0]);
    CONFIG_REPLICATION_FIELD(entry_position[1]);
    CONFIG_REPLICATION_FIELD(entry_position[2]);
    CONFIG_REPLICATION_FIELD(show_position[0]);
    CONFIG_REPLICATION_FIELD(show_position[1]);
    CONFIG_REPLICATION_FIELD(show_position[2]);

    // System field: 5Hz
    SYSTEM_REPLICATION_FIELD(countdown);
}
