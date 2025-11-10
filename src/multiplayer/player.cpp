#include "multiplayer/player.h"
#include "multiplayer.h"

namespace sp::io {
    static inline DataBuffer& operator << (DataBuffer& packet, const Waypoints::Point& p) { return packet << p.id << p.position; }
    static inline DataBuffer& operator >> (DataBuffer& packet, Waypoints::Point& p) { packet >> p.id >> p.position; return packet; }
}


BASIC_REPLICATION_IMPL(PlayerControlReplication, PlayerControl)
    // System fields: 5Hz
    SYSTEM_REPLICATION_FIELD(main_screen_setting);
    SYSTEM_REPLICATION_FIELD(main_screen_overlay);
    SYSTEM_REPLICATION_FIELD(alert_level);

    // Config fields: 1Hz
    // TODO: Instead of replicating control_code to clients, check it upon
    // receiving commandSetShip in playerinfo
    CONFIG_REPLICATION_FIELD(control_code);
    CONFIG_REPLICATION_FIELD(allowed_positions.mask);
}

BASIC_REPLICATION_IMPL(WaypointsReplication, Waypoints)
    REPLICATE_VECTOR_IF_DIRTY(waypoints, dirty);
}
