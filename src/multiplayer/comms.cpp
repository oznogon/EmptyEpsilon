#include "multiplayer/comms.h"
#include "multiplayer.h"


namespace sp::io {
    static inline DataBuffer& operator << (DataBuffer& packet, const CommsTransmitter::ScriptReply& r) { return packet << r.message; } \
    static inline DataBuffer& operator >> (DataBuffer& packet, CommsTransmitter::ScriptReply& r) { packet >> r.message; return packet; }
}


EMPTY_REPLICATION_IMPL(CommsReceiverReplication, CommsReceiver)
BASIC_REPLICATION_IMPL(CommsTransmitterReplication, CommsTransmitter)
    // System fields: 5Hz
    SYSTEM_REPLICATION_FIELD(state);
    SYSTEM_REPLICATION_FIELD(target_name);

    // Fast fields: 20Hz with epsilon tolerance
    BASIC_REPLICATION_FIELD_EPSILON(open_delay, 0.01f);
    BASIC_REPLICATION_FIELD(incomming_message);
    REPLICATE_VECTOR_IF_DIRTY(script_replies, script_replies_dirty);
}
