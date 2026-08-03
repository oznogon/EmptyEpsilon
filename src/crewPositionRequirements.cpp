#include "crewPositionRequirements.h"
#include <i18n.h>

#include "components/beamweapon.h"
#include "components/comms.h"
#include "components/docking.h"
#include "components/drone.h"
#include "components/impulse.h"
#include "components/jumpdrive.h"
#include "components/maneuveringthrusters.h"
#include "components/missiletubes.h"
#include "components/mounts.h"
#include "components/radar.h"
#include "components/shields.h"
#include "components/warpdrive.h"

namespace crewPositionRequirements
{

bool hasRequirements(CrewPosition cp, sp::ecs::Entity ship)
{
    if (!ship) return false;

    switch (cp)
    {
    case CrewPosition::helmsOfficer:
        return ship.hasComponent<ImpulseEngine>()
            || ship.hasComponent<JumpDrive>()
            || ship.hasComponent<WarpDrive>()
            || ship.hasComponent<ManeuveringThrusters>()
            || ship.hasComponent<DockingPort>();

    case CrewPosition::weaponsOfficer:
    {
        auto mounts = ship.getComponent<Mounts>();
        auto shields = ship.getComponent<Shields>();
        bool has_beam = false, has_missile = false;
        if (mounts)
        {
            for (auto& m : mounts->mounts)
            {
                if (m.type == MountType::BeamWeapon) has_beam = true;
                if (m.type == MountType::MissileWeapon) has_missile = true;
            }
        }
        return has_beam
            || has_missile
            || (shields && shields->entries.size() > 0);
    }

    case CrewPosition::scienceOfficer:
        return ship.hasComponent<LongRangeRadar>();

    case CrewPosition::tacticalOfficer:
    {
        auto mounts = ship.getComponent<Mounts>();
        bool has_beam = false, has_missile = false;
        if (mounts)
        {
            for (auto& m : mounts->mounts)
            {
                if (m.type == MountType::BeamWeapon) has_beam = true;
                if (m.type == MountType::MissileWeapon) has_missile = true;
            }
        }
        return ship.hasComponent<ImpulseEngine>()
            || ship.hasComponent<JumpDrive>()
            || ship.hasComponent<WarpDrive>()
            || ship.hasComponent<ManeuveringThrusters>()
            || ship.hasComponent<DockingPort>()
            || has_beam
            || has_missile;
    }

    case CrewPosition::beamWeaponsOfficer:
    {
        auto mounts = ship.getComponent<Mounts>();
        if (!mounts) return false;

        for (auto& m : mounts->mounts)
            if (m.type == MountType::BeamWeapon) return true;

        return false;
    }

    case CrewPosition::missileWeaponsOfficer:
    {
        auto mounts = ship.getComponent<Mounts>();
        if (!mounts) return false;

        for (auto& m : mounts->mounts)
            if (m.type == MountType::MissileWeapon) return true;

        return false;
    }

    case CrewPosition::commsOnly:
        return ship.hasComponent<CommsTransmitter>()
            || ship.hasComponent<CommsReceiver>();

    case CrewPosition::droneOperations:
        return ship.hasComponent<DroneController>();

    case CrewPosition::probeCamera:
        return ship.hasComponent<RadarLink>();

    case CrewPosition::dockingBay:
        return ship.hasComponent<DockingBay>();

    default:
        return true;
    }
}

string getMissingMessage(CrewPosition cp)
{
    switch (cp)
    {
    case CrewPosition::helmsOfficer:
        return tr("helms", "No helms controls");
    case CrewPosition::weaponsOfficer:
        return tr("weapons", "No weapons or shields");
    case CrewPosition::scienceOfficer:
        return tr("science", "No long-range radar");
    case CrewPosition::tacticalOfficer:
        return tr("tactical", "No tactical controls");
    case CrewPosition::beamWeaponsOfficer:
        return tr("beamWeapons", "No beam weapons");
    case CrewPosition::missileWeaponsOfficer:
        return tr("missileWeapons", "No missile weapons");
    case CrewPosition::commsOnly:
        return tr("comms", "No comms available");
    case CrewPosition::droneOperations:
        return tr("droneOperations", "No drone controller");
    case CrewPosition::probeCamera:
        return tr("probe", "No probe linked");
    case CrewPosition::dockingBay:
        return tr("dockingbay", "No docking bay");
    default:
        return "";
    }
}

} // namespace crewPositionRequirements
