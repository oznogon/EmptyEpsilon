#pragma once

#include "gui/gui2_overlay.h"
#include "screenComponents/targetsContainer.h"

class GuiImage;
class GuiKeyValueDisplay;
class GuiLabel;
class GuiRadarView;

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
    GuiElement* beam_info_box;
public:
    BeamWeaponsScreen(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;
};
