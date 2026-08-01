#pragma once

#include "gui/gui2_rotationdial.h"

class GuiRadarView;

class GuiUtilityBeamRotationDial : public GuiRotationDial
{
public:
    GuiUtilityBeamRotationDial(GuiContainer* owner, string id, GuiRadarView* radar);

    virtual void onDraw(sp::RenderTarget& renderer) override;
    virtual bool onMouseDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id) override;
private:
    GuiRadarView* radar;
};
