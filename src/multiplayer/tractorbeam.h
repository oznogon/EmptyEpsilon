#pragma once

#include "multiplayer/basic.h"
#include "components/tractorbeam.h"

BASIC_REPLICATION_CLASS_RATE(TractorBeamSysReplication, TractorBeamSys, 20.0f);
BASIC_REPLICATION_CLASS(TractorBeamEffectReplication, TractorBeamEffect);
