#include "crewPositionRequirements.h"

#include <i18n.h>

#include "components/impulse.h"
#include "components/warpdrive.h"
#include "components/jumpdrive.h"
#include "components/maneuveringthrusters.h"
#include "components/docking.h"
#include "components/beamweapon.h"
#include "components/missiletubes.h"
#include "components/shields.h"
#include "components/radar.h"
#include "components/comms.h"
#include "components/drone.h"

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
            || ship.hasComponent<CombatManeuveringThrusters>()
            || ship.hasComponent<ManeuveringThrusters>()
            || ship.hasComponent<DockingPort>();

    case CrewPosition::weaponsOfficer:
    {
        auto beam_sys = ship.getComponent<BeamWeaponSys>();
        auto missile_tubes = ship.getComponent<MissileTubes>();
        auto shields = ship.getComponent<Shields>();
        return (beam_sys && beam_sys->mounts.size() > 0)
            || (missile_tubes && missile_tubes->mounts.size() > 0)
            || (shields && shields->entries.size() > 0);
    }

    case CrewPosition::scienceOfficer:
        return ship.hasComponent<LongRangeRadar>();

    case CrewPosition::tacticalOfficer:
    {
        auto beam_sys = ship.getComponent<BeamWeaponSys>();
        auto missile_tubes = ship.getComponent<MissileTubes>();
        return ship.hasComponent<ImpulseEngine>()
            || ship.hasComponent<JumpDrive>()
            || ship.hasComponent<WarpDrive>()
            || ship.hasComponent<CombatManeuveringThrusters>()
            || ship.hasComponent<ManeuveringThrusters>()
            || ship.hasComponent<DockingPort>()
            || (beam_sys && beam_sys->mounts.size() > 0)
            || (missile_tubes && missile_tubes->mounts.size() > 0);
    }

    case CrewPosition::beamWeaponsOfficer:
    {
        auto beam_sys = ship.getComponent<BeamWeaponSys>();
        return beam_sys && beam_sys->mounts.size() > 0;
    }

    case CrewPosition::missileWeaponsOfficer:
    {
        auto missile_tubes = ship.getComponent<MissileTubes>();
        return missile_tubes && missile_tubes->mounts.size() > 0;
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
