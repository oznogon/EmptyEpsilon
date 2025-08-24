#ifndef WEAPONS_SCREEN_H
#define WEAPONS_SCREEN_H

#include "gui/gui2_overlay.h"
#include "screenComponents/radarView.h"
#include "screenComponents/targetsContainer.h"
#include "gui/joystickConfig.h"

class GuiMissileTubeControls;
class GuiKeyValueDisplay;
class GuiToggleButton;
class GuiRotationDial;
class GuiLabel;
class GuiButton;
class GuiToggleButton;
class GuiProgressbar;
class GuiSlider;
class GuiBeamFrequencySelector;

class WeaponsScreen : public GuiOverlay
{
private:
    GuiOverlay* background_crosses;

    TargetsContainer targets;
    GuiKeyValueDisplay* energy_display;
    GuiKeyValueDisplay* front_shield_display;
    GuiKeyValueDisplay* rear_shield_display;
    GuiRadarView* radar;
    GuiMissileTubeControls* tube_controls;
    GuiRotationDial* missile_aim;
    GuiToggleButton* lock_aim;
    GuiElement* beam_info_box;

    float elapsed_time;
    float timing_value;
    int timing_direction;
    GuiToggleButton* beam_manual_freq_toggle;
    GuiToggleButton* beam_manual_fire_toggle;
    GuiBeamFrequencySelector* beam_manual_frequency;
    GuiButton* beam_manual_fire;
    GuiProgressbar* beam_manual_cooldown;
    GuiLabel* beam_manual_cooldown_label;
public:
    WeaponsScreen(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;
};

#endif//WEAPONS_SCREEN_H
