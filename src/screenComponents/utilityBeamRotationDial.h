#pragma once

#include "gui/gui2_rotationdial.h"

class GuiRadarView;

class GuiUtilityBeamRotationDial : public GuiRotationDial
{
public:
    GuiUtilityBeamRotationDial(GuiContainer* owner, string id, GuiRadarView* radar);

    virtual void onDraw(sp::RenderTarget& renderer) override;
private:
    GuiRadarView* radar;
};
