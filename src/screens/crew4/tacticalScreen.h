#pragma once

#include "gui/gui2_overlay.h"
#include "gui/joystickConfig.h"
#include "screenComponents/targetsContainer.h"

class AimLock;
class AimLockButton;
class GuiMissileTubeControls;
class GuiRadarView;
class GuiKeyValueDisplay;
class GuiToggleButton;
class GuiSelector;
class GuiCustomShipFunctions;
class GuiUtilityBeamControls;
class GuiUtilityBeamRotationDial;

class TacticalScreen : public GuiOverlay
{
private:
    GuiOverlay* background_crosses;

    GuiElement* warp_controls;
    GuiElement* jump_controls;

    TargetsContainer targets;
    GuiRadarView* radar;
    AimLock* missile_aim;
    AimLockButton* lock_aim;
    GuiMissileTubeControls* tube_controls;
    GuiElement* beam_info_box;
    GuiSelector* sidebar_selector;
    GuiCustomShipFunctions* custom_function_sidebar;
    GuiUtilityBeamControls* utility_beam_sidebar;
    GuiUtilityBeamRotationDial* utility_beam_dial;
    bool drag_rotate;
public:
    TacticalScreen(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;
};
