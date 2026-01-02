#include "playerInfo.h"
#include "gameGlobalInfo.h"
#include "weaponsTargetingModeSelector.h"
#include "components/weaponstargetingmode.h"
#include "gui/gui2_label.h"
#include <i18n.h>

GuiWeaponsTargetingModeSelector::GuiWeaponsTargetingModeSelector(GuiContainer* owner, string id)
: GuiToggleSlider(owner, id,
    [](int index, string value)
    {
        if (my_spaceship) my_player_info->commandSetWeaponsTargetingMode(TargetingMode(index));
    }
)
{
    // Overlay label on slider.
    mode_label = new GuiLabel(this, id + "_LABEL", tr("targeting", "All but confirmed friendly"), 20.0f);
    mode_label
        ->setAlignment(sp::Alignment::Center)
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Add entries.
    addEntry(tr("targeting", "Confirmed hostiles only"), "0");
    addEntry(tr("targeting", "Hostiles + unknown"), "1");
    addEntry(tr("targeting", "All but confirmed friendly"), "2");
    addEntry(tr("targeting", "All"), "3");

    if (my_spaceship)
    {
        if (auto mode = my_spaceship.getComponent<WeaponsTargetingMode>())
            setSelectionIndex(static_cast<int>(mode->mode));
        else if (gameGlobalInfo)
            setSelectionIndex(static_cast<int>(gameGlobalInfo->default_weapons_targeting_mode));
        else
            setSelectionIndex(static_cast<int>(TargetingMode::EnemyAndUnknown)); // Fallback default
    }
}

void GuiWeaponsTargetingModeSelector::onUpdate()
{
    if (my_spaceship && isVisible())
    {
        TargetingMode current_mode = TargetingMode::EnemyAndUnknown;

        if (auto mode = my_spaceship.getComponent<WeaponsTargetingMode>())
            current_mode = mode->mode;
        else if (gameGlobalInfo)
            current_mode = gameGlobalInfo->default_weapons_targeting_mode;

        setSelectionIndex(static_cast<int>(current_mode));

        // Update label to current mode.
        switch (current_mode)
        {
            case TargetingMode::WeaponsTight:
                mode_label->setText(tr("targeting", "Confirmed hostiles only"));
                break;
            case TargetingMode::EnemyAndUnknown:
                mode_label->setText(tr("targeting", "Hostiles + unknown"));
                break;
            case TargetingMode::WeaponsFree:
                mode_label->setText(tr("targeting", "All but confirmed friendly"));
                break;
            case TargetingMode::All:
                mode_label->setText(tr("targeting", "All"));
                break;
        }
    }
}
