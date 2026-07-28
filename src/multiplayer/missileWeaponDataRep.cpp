#include "multiplayer/missileWeaponDataRep.h"
#include "multiplayer.h"

BASIC_REPLICATION_IMPL(MissileWeaponDataReplication, MissileWeaponData)
    BASIC_REPLICATION_FIELD(index);
    BASIC_REPLICATION_FIELD(name);
    BASIC_REPLICATION_FIELD(locale_name);
    BASIC_REPLICATION_FIELD(icon);
    BASIC_REPLICATION_FIELD(order);
    BASIC_REPLICATION_FIELD(speed);
    BASIC_REPLICATION_FIELD(turnrate);
    BASIC_REPLICATION_FIELD(lifetime);
    BASIC_REPLICATION_FIELD(color);
    BASIC_REPLICATION_FIELD(homing_range);
    BASIC_REPLICATION_FIELD(fire_sound);
    BASIC_REPLICATION_FIELD(radar_trace);
    BASIC_REPLICATION_FIELD(damage_at_center);
    BASIC_REPLICATION_FIELD(damage_at_edge);
    BASIC_REPLICATION_FIELD(blast_range);
    BASIC_REPLICATION_FIELD(explosion_sfx);
    BASIC_REPLICATION_FIELD(radar_electrical);
    BASIC_REPLICATION_FIELD(radar_thermal);
    BASIC_REPLICATION_FIELD(radar_gravitational);
    BASIC_REPLICATION_FIELD(explodes_on_timeout);
    BASIC_REPLICATION_FIELD(is_delayed_explode);
    BASIC_REPLICATION_FIELD(fire_count);
    BASIC_REPLICATION_FIELD(damage_type);
    BASIC_REPLICATION_FIELD(avoid_object_delay);
    BASIC_REPLICATION_FIELD(circle_collision);
    BASIC_REPLICATION_FIELD(no_lifetime_on_missile);
    BASIC_REPLICATION_FIELD(player);

    if constexpr (BRR == BasicReplicationRequest::Receive)
        MissileWeaponDataRegistry::instance().rebuild();
}
