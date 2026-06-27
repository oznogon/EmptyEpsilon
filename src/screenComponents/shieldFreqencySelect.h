#pragma once

#include "gui/gui2_element.h"

class GuiKeyValueDisplay;
class GuiSelector;
class GuiButton;
class GuiProgressbar;

class GuiShieldFrequencySelect : public GuiElement
{
private:
    GuiSelector* new_frequency;
    GuiButton* calibrate_button;
public:
    GuiShieldFrequencySelect(GuiContainer* owner, string id);

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;
};
