#include "multiplayer/beamWeaponTarget.h"
#include "multiplayer.h"

BASIC_REPLICATION_IMPL(BeamWeaponTargetReplication, BeamWeaponTarget)
    BASIC_REPLICATION_FIELD(entity);
}
