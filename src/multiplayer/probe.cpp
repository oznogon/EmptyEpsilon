#include "multiplayer/probe.h"
#include "multiplayer.h"


BASIC_REPLICATION_IMPL(ScanProbeLauncherReplication, ScanProbeLauncher)
    // Config field: 1Hz
    CONFIG_REPLICATION_FIELD(max);
    // System field: 5Hz
    SYSTEM_REPLICATION_FIELD(stock);
}
