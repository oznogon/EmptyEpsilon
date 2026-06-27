#pragma once

#include "gui/gui2_element.h"

class GuiPanel;
class GuiLabel;

class GuiSelfDestructIndicator : public GuiElement
{
private:
    GuiPanel* box;
    GuiLabel* label;
public:
    GuiSelfDestructIndicator(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& target) override;
};
