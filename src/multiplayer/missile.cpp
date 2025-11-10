#include "multiplayer/missile.h"
#include "multiplayer.h"


BASIC_REPLICATION_IMPL(MissileFlightReplication, MissileFlight)
    // Config field: 1Hz with epsilon tolerance
    CONFIG_REPLICATION_FIELD_EPSILON(speed, 0.1f);
}

BASIC_REPLICATION_IMPL(MissileHomingReplication, MissileHoming)
    // Config fields: 1Hz with epsilon tolerance
    CONFIG_REPLICATION_FIELD_EPSILON(turn_rate, 0.1f);
    CONFIG_REPLICATION_FIELD_EPSILON(range, 1.0f);
    CONFIG_REPLICATION_FIELD(target);
    // Fast field: 20Hz with epsilon tolerance
    BASIC_REPLICATION_FIELD_EPSILON(target_angle, 0.01f);
}

BASIC_REPLICATION_IMPL(ConstantParticleEmitterReplication, ConstantParticleEmitter)
    // Config fields: 1Hz with epsilon tolerance
    CONFIG_REPLICATION_FIELD_EPSILON(interval, 0.1f);
    CONFIG_REPLICATION_FIELD_EPSILON(travel_random_range, 0.1f);
    CONFIG_REPLICATION_FIELD(start_color);
    CONFIG_REPLICATION_FIELD(end_color);
    CONFIG_REPLICATION_FIELD_EPSILON(start_size, 0.1f);
    CONFIG_REPLICATION_FIELD_EPSILON(end_size, 0.1f);
    CONFIG_REPLICATION_FIELD_EPSILON(life_time, 0.1f);
}
