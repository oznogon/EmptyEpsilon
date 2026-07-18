#pragma once

#include "gui/gui2_element.h"

class GuiToggleButton;
class GuiProgressbar;

class GuiShieldsEnableButton : public GuiElement
{
private:
    GuiToggleButton* button;
    GuiProgressbar* bar;
public:
    GuiShieldsEnableButton(GuiContainer* owner, string id);

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;
};
