#include "multiplayer/faction.h"
#include "multiplayer.h"


BASIC_REPLICATION_IMPL(FactionReplication, Faction)
    BASIC_REPLICATION_FIELD(entity);
}

namespace sp::io {
    static inline DataBuffer& operator << (DataBuffer& packet, const FactionInfo::Relation& r) { return packet << r.other_faction << r.relation; } \
    static inline DataBuffer& operator >> (DataBuffer& packet, FactionInfo::Relation& r) { packet >> r.other_faction >> r.relation; return packet; }
}

BASIC_REPLICATION_IMPL(FactionInfoReplication, FactionInfo)
    // Config fields: 1Hz
    CONFIG_REPLICATION_FIELD(gm_color);
    CONFIG_REPLICATION_FIELD(name);
    CONFIG_REPLICATION_FIELD(locale_name);
    CONFIG_REPLICATION_FIELD(description);

    // System field: 5Hz with epsilon tolerance
    SYSTEM_REPLICATION_FIELD_EPSILON(reputation_points, 0.5f);

    REPLICATE_VECTOR_IF_DIRTY(relations, relations_dirty);
}
