#include "multiplayer/analysisTarget.h"
#include "multiplayer.h"

BASIC_REPLICATION_IMPL(AnalysisTargetReplication, AnalysisTarget)
    BASIC_REPLICATION_FIELD(entity);
}
