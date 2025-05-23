#pragma once

#include "gui/gui2_element.h"

class GuiProgressbar;
class GuiToggleButton;
class GuiSelector;
class GuiSlider;
class GuiKeyValueDisplay;
enum class CrewPosition;

class GuiUtilityBeamControls : public GuiElement
{
public:
    GuiUtilityBeamControls(GuiContainer* owner, CrewPosition position, string id);

    CrewPosition position;

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;
private:
    GuiToggleButton* utility_toggle;
    // GuiSelector* utility_mode;
    GuiSelector* custom_utility_mode;
    GuiSlider* utility_bearing;
    GuiKeyValueDisplay* utility_bearing_fixed;
    GuiSlider* utility_range;
    GuiKeyValueDisplay* utility_range_fixed;
    GuiSlider* utility_arc;
    GuiKeyValueDisplay* utility_arc_fixed;
    GuiProgressbar* utility_progress_bar;
};
