#pragma once

#include "gui/gui2_element.h"

class GuiPanel;
class GuiLabel;

class GuiJumpIndicator : public GuiElement
{
private:
    GuiPanel* box;
    GuiLabel* label;
public:
    GuiJumpIndicator(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& target) override;
};
