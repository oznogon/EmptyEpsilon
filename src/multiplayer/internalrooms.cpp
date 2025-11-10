#include "multiplayer/internalrooms.h"
#include "multiplayer.h"

namespace sp::io {
    static inline DataBuffer& operator << (DataBuffer& packet, const InternalRooms::Room& r) {
        return packet << r.position << r.size << r.system;
    }
    static inline DataBuffer& operator >> (DataBuffer& packet, InternalRooms::Room& r) {
        return packet >> r.position >> r.size >> r.system;
    }
    static inline DataBuffer& operator << (DataBuffer& packet, const InternalRooms::Door& d) {
        return packet << d.position << d.horizontal;
    }
    static inline DataBuffer& operator >> (DataBuffer& packet, InternalRooms::Door& d) {
        return packet >> d.position >> d.horizontal;
    }
}

BASIC_REPLICATION_IMPL(InternalRoomsReplication, InternalRooms)
    // Config field: 1Hz
    CONFIG_REPLICATION_FIELD(auto_repair_enabled);

    REPLICATE_VECTOR_IF_DIRTY(rooms, rooms_dirty);
    REPLICATE_VECTOR_IF_DIRTY(doors, doors_dirty);
}

BASIC_REPLICATION_IMPL(InternalCrewReplication, InternalCrew)
    // Config fields: 1Hz with epsilon tolerance
    CONFIG_REPLICATION_FIELD_EPSILON(move_speed, 0.1f);

    // System fields: 5Hz
    SYSTEM_REPLICATION_FIELD(target_position);
    SYSTEM_REPLICATION_FIELD(ship);

    // Fast fields: 20Hz
    BASIC_REPLICATION_FIELD(action);
    BASIC_REPLICATION_FIELD(position);
    BASIC_REPLICATION_FIELD(direction);
}
