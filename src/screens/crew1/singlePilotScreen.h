#ifndef SINGLE_PILOT_SCREEN_H
#define SINGLE_PILOT_SCREEN_H

#include "gui/gui2_overlay.h"
#include "screenComponents/targetsContainer.h"
#include "gui/joystickConfig.h"

class GuiViewport3D;
class GuiMissileTubeControls;
class GuiRadarView;
class GuiKeyValueDisplay;
class GuiToggleButton;
class GuiRotationDial;
class GuiCombatManeuver;
class GuiLabel;
class GuiButton;

class SinglePilotScreen : public GuiOverlay
{
private:
    GuiOverlay* background_gradient;
    GuiOverlay* background_crosses;

    GuiKeyValueDisplay* energy_display;
    GuiKeyValueDisplay* heading_display;
    GuiKeyValueDisplay* velocity_display;
    GuiKeyValueDisplay* shields_display;
    GuiElement* warp_controls;
    GuiElement* jump_controls;
    GuiLabel* heading_hint;
    GuiCombatManeuver* combat_maneuver;

    TargetsContainer targets;
    GuiRadarView* radar;
    GuiRotationDial* missile_aim;
    GuiMissileTubeControls* tube_controls;
    GuiToggleButton* lock_aim;
    bool targeting_mode;
    GuiButton* targeting_mode_button;
public:
    SinglePilotScreen(GuiContainer* owner);

    virtual void onDraw(sf::RenderTarget& window) override;
    virtual void onHotkey(const HotkeyResult& key) override;
    virtual bool onJoystickAxis(const AxisAction& axisAction) override;
};

#endif//SINGLE_PILOT_SCREEN_H
