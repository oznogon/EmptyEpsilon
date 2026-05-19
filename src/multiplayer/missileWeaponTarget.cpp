#include "multiplayer/missileWeaponTarget.h"
#include "multiplayer.h"

BASIC_REPLICATION_IMPL(MissileWeaponTargetReplication, MissileWeaponTarget)
    BASIC_REPLICATION_FIELD(entity);
}
