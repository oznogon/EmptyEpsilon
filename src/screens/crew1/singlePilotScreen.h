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
class GuiImage;

class SinglePilotScreen : public GuiOverlay
{
private:
    enum ESinglePilotView
    {
        SPV_Forward = 0,
        SPV_Right,
        SPV_Back,
        SPV_Left,
        SPV_Target
    };

    ESinglePilotView view_state;
    bool first_person;
    GuiViewport3D* viewport;

    GuiKeyValueDisplay* energy_display;
    GuiKeyValueDisplay* heading_display;
    GuiKeyValueDisplay* velocity_display;
    GuiKeyValueDisplay* shields_display;
    GuiElement* warp_controls;
    GuiElement* jump_controls;
    GuiCombatManeuver* combat_maneuver;

    TargetsContainer targets;
    GuiRadarView* radar;
    float view_rotation;
    float target_rotation;
    GuiRotationDial* missile_aim;
    GuiRotationDial* steering_wheel;
    GuiImage* missile_aim_icon;
    GuiImage* steering_wheel_icon;
    GuiMissileTubeControls* tube_controls;
    GuiToggleButton* lock_aim;
    bool targeting_mode;
    GuiToggleButton* targeting_mode_button;
public:
    SinglePilotScreen(GuiContainer* owner);

    virtual void onDraw(sf::RenderTarget& window) override;
    virtual void onHotkey(const HotkeyResult& key) override;
    virtual bool onJoystickAxis(const AxisAction& axisAction) override;

    void setTargetingMode(bool new_mode);
};

#endif//SINGLE_PILOT_SCREEN_H
