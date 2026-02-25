#pragma once

#include "gui/gui2_overlay.h"
#include "gui/joystickConfig.h"

class GuiKeyValueDisplay;
class GuiLabel;
class GuiDockingButton;
class GuiCombatManeuver;
class GuiSelector;
class GuiCustomShipFunctions;
class GuiUtilityBeamControls;
class GuiUtilityBeamRotationDial;

class HelmsScreen : public GuiOverlay
{
private:
    GuiOverlay* background_crosses;

    GuiLabel* heading_hint;
    GuiCombatManeuver* combat_maneuver;
    GuiDockingButton* docking_button;
    GuiSelector* sidebar_selector;
    GuiCustomShipFunctions* custom_function_sidebar;
    GuiUtilityBeamControls* utility_beam_sidebar;
    GuiUtilityBeamRotationDial* utility_beam_dial;
public:
    HelmsScreen(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;
};
