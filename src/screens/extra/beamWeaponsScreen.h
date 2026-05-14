#pragma once

#include "gui/gui2_overlay.h"
#include "screenComponents/targetsContainer.h"

class GuiKeyValueDisplay;
class GuiRadarView;

class BeamWeaponsScreen : public GuiOverlay
{
private:
    GuiOverlay* background_crosses;

    TargetsContainer targets;
    GuiKeyValueDisplay* energy_display;
    GuiRadarView* radar;
    GuiElement* beam_info_box;
public:
    BeamWeaponsScreen(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;
};
