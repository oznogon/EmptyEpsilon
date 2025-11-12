#include <i18n.h>
#include "playerInfo.h"
#include "gameGlobalInfo.h"
#include "beamTargetSelector.h"

#include "components/beamweapon.h"

GuiBeamTargetSelector::GuiBeamTargetSelector(GuiContainer* owner, string id)
: GuiSelector(owner, id, [](int index, string value) { if (my_spaceship) my_player_info->commandSetBeamSystemTarget(ShipSystem::Type(index + int(ShipSystem::Type::None))); })
{
    setVisible(gameGlobalInfo->use_system_damage);
    addEntry(tr("target", "Hull"), "-1");
    for (int n = 0; n < ShipSystem::COUNT; n++)
        addEntry(getLocaleSystemName(ShipSystem::Type(n)), string(n));
}

void GuiBeamTargetSelector::onUpdate()
{
    if (my_spaceship && gameGlobalInfo->use_system_damage && isVisible())
    {
        if (keys.weapons_beam_subsystem_target_next.getDown())
        {
            if (getSelectionIndex() >= (int)entries.size() - 1)
                setSelectionIndex(0);
            else
                setSelectionIndex(getSelectionIndex() + 1);
            callback();
        }

        if (keys.weapons_beam_subsystem_target_previous.getDown())
        {
            if (getSelectionIndex() <= 0)
                setSelectionIndex(entries.size() - 1);
            else
                setSelectionIndex(getSelectionIndex() - 1);
        }

        if (auto beamweapons = my_spaceship.getComponent<BeamWeaponSys>())
            setSelectionIndex(static_cast<int>(beamweapons->system_target) - static_cast<int>(ShipSystem::Type::None));
    }
}
