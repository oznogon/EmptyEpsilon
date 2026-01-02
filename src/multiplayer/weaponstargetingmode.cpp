#include "multiplayer/weaponstargetingmode.h"
#include "multiplayer.h"

BASIC_REPLICATION_IMPL(WeaponsTargetingModeReplication, WeaponsTargetingMode)
    BASIC_REPLICATION_FIELD(mode);
}
