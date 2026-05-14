#include "multiplayer/cinematicCamera.h"
#include "multiplayer.h"

BASIC_REPLICATION_IMPL(CinematicCameraReplication, CinematicCamera)
    // Note: yaw is stored in Transform component rotation (replicated separately)
    BASIC_REPLICATION_FIELD(pitch)
    BASIC_REPLICATION_FIELD(roll)
    BASIC_REPLICATION_FIELD(field_of_view)
    BASIC_REPLICATION_FIELD(z_position)
    BASIC_REPLICATION_FIELD(name)
    BASIC_REPLICATION_FIELD(assigned_entity)
    // Not replicated:
    // BASIC_REPLICATION_FIELD(radar_icon)
    // BASIC_REPLICATION_FIELD(use_velocity_fov_scaling)
    // BASIC_REPLICATION_FIELD(base_fov_for_velocity)
    // BASIC_REPLICATION_FIELD(fov_velocity_range)
}
