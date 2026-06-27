#pragma once

#include "gui/gui2_element.h"

class GuiNoiseOverlay : public GuiElement
{
public:
    GuiNoiseOverlay(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& target) override;
};
