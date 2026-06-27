#pragma once

#include "gui/gui2_element.h"

class GuiButton;

class GuiSelfDestructButton : public GuiElement
{
private:
    GuiButton* activate_button;
    GuiButton* confirm_button;
    GuiButton* cancel_button;
public:
    GuiSelfDestructButton(GuiContainer* owner, string id);

    virtual void onUpdate() override;
    virtual void onDraw(sp::RenderTarget& target) override;
};
