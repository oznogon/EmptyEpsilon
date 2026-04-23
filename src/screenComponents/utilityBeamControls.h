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
    GuiToggleButton* utility_toggle = nullptr;
    GuiSelector* custom_utility_mode = nullptr;
    GuiSlider* utility_bearing = nullptr;
    GuiKeyValueDisplay* utility_bearing_fixed = nullptr;
    GuiSlider* utility_range = nullptr;
    GuiKeyValueDisplay* utility_range_fixed = nullptr;
    GuiSlider* utility_arc = nullptr;
    GuiKeyValueDisplay* utility_arc_fixed = nullptr;
    GuiProgressbar* utility_progress_bar = nullptr;
};
