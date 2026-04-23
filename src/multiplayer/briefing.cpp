#include "multiplayer/briefing.h"
#include "multiplayer.h"

BASIC_REPLICATION_IMPL(BriefingReplication, Briefing)
    BASIC_REPLICATION_VECTOR(pages)
        VECTOR_REPLICATION_FIELD(caption);
        VECTOR_REPLICATION_FIELD(image);
        VECTOR_REPLICATION_FIELD(audio);
        VECTOR_REPLICATION_FIELD(duration);
    VECTOR_REPLICATION_END();
}
