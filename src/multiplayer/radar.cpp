#include "multiplayer/radar.h"
#include "multiplayer.h"


BASIC_REPLICATION_IMPL(RadarTraceReplication, RadarTrace)
    // System fields: 5Hz with epsilon tolerance
    SYSTEM_REPLICATION_FIELD(icon);
    SYSTEM_REPLICATION_FIELD_EPSILON(min_size, 0.1f);
    SYSTEM_REPLICATION_FIELD_EPSILON(max_size, 0.1f);
    SYSTEM_REPLICATION_FIELD_EPSILON(radius, 0.1f);
    SYSTEM_REPLICATION_FIELD(color);
    SYSTEM_REPLICATION_FIELD(flags);
}

BASIC_REPLICATION_IMPL(RawRadarSignatureInfoReplication, RawRadarSignatureInfo)
    // System fields: 5Hz with epsilon tolerance
    SYSTEM_REPLICATION_FIELD_EPSILON(gravity, 0.01f);
    SYSTEM_REPLICATION_FIELD_EPSILON(electrical, 0.01f);
    SYSTEM_REPLICATION_FIELD_EPSILON(biological, 0.01f);
}
BASIC_REPLICATION_IMPL(LongRangeRadarReplication, LongRangeRadar)
    // System fields: 5Hz with epsilon tolerance
    // TODO: Reconsider as fast field if radar range becomes tied to a system
    SYSTEM_REPLICATION_FIELD_EPSILON(short_range, 1.0f);
    SYSTEM_REPLICATION_FIELD_EPSILON(long_range, 1.0f);

    REPLICATE_VECTOR_IF_DIRTY(waypoints, waypoints_dirty);
}
BASIC_REPLICATION_IMPL(RadarLinkReplication, RadarLink)
    // System fields: 5Hz with epsilon tolerance
    SYSTEM_REPLICATION_FIELD(linked_entity);
}
EMPTY_REPLICATION_IMPL(ShareShortRangeRadarReplication, ShareShortRangeRadar);
BASIC_REPLICATION_IMPL(AllowRadarLinkReplication, AllowRadarLink)
    // System field: 5Hz
    SYSTEM_REPLICATION_FIELD(owner);
}
