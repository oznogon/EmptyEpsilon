#pragma once

#include "gui/gui2_overlay.h"
#include "screenComponents/targetsContainer.h"

class GuiCustomShipFunctions;
class GuiImage;
class GuiKeyValueDisplay;
class GuiLabel;
class GuiRadarView;
class GuiSelector;
class GuiToggleButton;
class GuiUtilityBeamControls;
class GuiUtilityBeamRotationDial;

class BeamWeaponsScreen : public GuiOverlay
{
private:
    GuiImage* background_gradient;
    GuiOverlay* background_crosses;
    GuiElement* beam_controls;
    GuiLabel* no_weapons_label;

    GuiRadarView* radar;
    TargetsContainer targets;
    GuiKeyValueDisplay* energy_display;
    GuiToggleButton* beam_safety;
    GuiElement* beam_info_box;
    GuiSelector* sidebar_selector;
    GuiCustomShipFunctions* custom_function_sidebar;
    GuiUtilityBeamControls* utility_beam_sidebar;
    GuiUtilityBeamRotationDial* utility_beam_dial;
public:
    BeamWeaponsScreen(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;
};
