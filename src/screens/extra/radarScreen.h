#pragma once

#include "gui/gui2_overlay.h"
#include "screenComponents/targetsContainer.h"

class GuiRadarView;

class RadarScreen : public GuiOverlay
{
private:
    TargetsContainer targets;
    GuiRadarView* radar;
    string radar_type;
public:
    RadarScreen(GuiContainer* owner, string type = "tactical");

    virtual void onDraw(sp::RenderTarget& target) override;
};
