#include "multiplayer/weaponstarget.h"
#include "multiplayer.h"


BASIC_REPLICATION_IMPL(WeaponsTargetReplication, WeaponsTarget)
    BASIC_REPLICATION_FIELD(entity);
}
