#pragma once

#include "gui/gui2_overlay.h"
#include "gui/joystickConfig.h"

class GuiLabel;
class GuiImage;
class GuiDockingButton;
class GuiCombatManeuver;
class GuiSelector;
class GuiCustomShipFunctions;
class GuiUtilityBeamControls;
class GuiUtilityBeamRotationDial;

class HelmsScreen : public GuiOverlay
{
private:
    GuiImage* background_gradient;
    GuiElement* helms_controls;
    GuiLabel* no_controls_label;
    GuiLabel* heading_hint;
    GuiCombatManeuver* combat_maneuver;
    GuiDockingButton* docking_button;
    GuiSelector* sidebar_selector;
    GuiCustomShipFunctions* custom_function_sidebar;
    GuiUtilityBeamControls* utility_beam_sidebar;
    GuiUtilityBeamRotationDial* utility_beam_dial;
    bool continuous_turning = false;
public:
    HelmsScreen(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;
};
