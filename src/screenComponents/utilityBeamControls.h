#pragma once

#include "gui/gui2_element.h"

class GuiToggleButton;
class GuiSelector;
class GuiSlider;

class GuiUtilityBeamControls : public GuiElement
{
private:
    GuiToggleButton* tractor_toggle;
    GuiSelector* tractor_mode;
    GuiSlider* tractor_bearing;
    GuiSlider* tractor_range;
    GuiSlider* tractor_arc;
public:
    GuiUtilityBeamControls(GuiContainer* owner, string id);

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;
};
