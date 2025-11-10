#include "multiplayer/zone.h"
#include "multiplayer.h"


BASIC_REPLICATION_IMPL(ZoneReplication, Zone)
    // Config fields: 1Hz
    CONFIG_REPLICATION_FIELD(color);
    CONFIG_REPLICATION_FIELD(label);
    CONFIG_REPLICATION_FIELD(label_offset);
    CONFIG_REPLICATION_FIELD(skybox);
    CONFIG_REPLICATION_FIELD(skybox_fade_distance);
    REPLICATE_VECTOR_IF_DIRTY(outline, zone_dirty);
    if (BRR == BasicReplicationRequest::Receive && (flags & (flag >> 1))) target.updateTriangles();
}
