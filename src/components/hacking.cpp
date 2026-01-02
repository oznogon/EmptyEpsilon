#include "hacking.h"
#include "components/scanning.h"
#include "components/faction.h"
#include "components/shipsystem.h"

bool HackingDevice::canHack(sp::ecs::Entity player_ship, sp::ecs::Entity target)
{
    if (!player_ship) return false;
    if (player_ship == target || !player_ship.hasComponent<HackingDevice>()) return false;

    auto scanstate = target.getComponent<ScanState>();
    if (scanstate && scanstate->getStateFor(player_ship) == ScanState::State::NotScanned)
        return true;

    // Check for hackable ShipSystems.
    bool has_hackable_systems = false;
    for (int n = 0; n < static_cast<int>(ShipSystem::Type::COUNT); n++)
    {
        auto sys = ShipSystem::get(target, ShipSystem::Type(n));
        if (sys && sys->can_be_hacked) has_hackable_systems = true;
    };

    if (Faction::getRelation(target, player_ship) == FactionRelation::Friendly)
        return false;
    else
        return has_hackable_systems;
}
