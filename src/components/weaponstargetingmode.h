#pragma once

#include "gameGlobalInfo.h"

// Define which FactionRelations that the given player ship's weapons crew can
// target.
class WeaponsTargetingMode
{
public:
    TargetingMode mode = TargetingMode::EnemyAndUnknown;
};
