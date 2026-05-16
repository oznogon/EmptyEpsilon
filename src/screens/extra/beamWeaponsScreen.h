#pragma once

#include "gui/gui2_overlay.h"
#include "screenComponents/targetsContainer.h"

class GuiKeyValueDisplay;
class GuiRadarView;
class GuiSelector;
class GuiCustomShipFunctions;
class GuiUtilityBeamControls;
class GuiUtilityBeamRotationDial;

class BeamWeaponsScreen : public GuiOverlay
{
private:
    GuiOverlay* background_crosses;

    TargetsContainer targets;
    GuiKeyValueDisplay* energy_display;
    GuiRadarView* radar;
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
