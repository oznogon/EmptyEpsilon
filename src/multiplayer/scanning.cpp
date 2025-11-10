#include "multiplayer/scanning.h"
#include "multiplayer.h"

namespace sp::io {
    static inline DataBuffer& operator << (DataBuffer& packet, const ScanState::Entry& kv) {
        return packet << kv.faction << kv.state;
    }
    static inline DataBuffer& operator >> (DataBuffer& packet, ScanState::Entry& kv) {
        return packet >> kv.faction >> kv.state;
    }
}


BASIC_REPLICATION_IMPL(ScanStateReplication, ScanState)
    // System fields: 5Hz
    SYSTEM_REPLICATION_FIELD(allow_simple_scan);
    SYSTEM_REPLICATION_FIELD(complexity);
    SYSTEM_REPLICATION_FIELD(depth);

    REPLICATE_VECTOR_IF_DIRTY(per_faction, per_faction_dirty);
}

BASIC_REPLICATION_IMPL(ScienceDescriptionReplication, ScienceDescription)
    // System fields: 5Hz
    SYSTEM_REPLICATION_FIELD(simple_scan);
    SYSTEM_REPLICATION_FIELD(full_scan);

    // Fast fields: 20Hz
    BASIC_REPLICATION_FIELD(not_scanned);
    BASIC_REPLICATION_FIELD(friend_or_foe_identified);
}

BASIC_REPLICATION_IMPL(ScienceScannerReplication, ScienceScanner)
    // Config field: 1Hz with epsilon tolerance
    CONFIG_REPLICATION_FIELD_EPSILON(max_scanning_delay, 0.1f);

    // Fast fields: 20Hz with epsilon tolerance
    BASIC_REPLICATION_FIELD_EPSILON(delay, 0.01f);
    BASIC_REPLICATION_FIELD(target);
}
