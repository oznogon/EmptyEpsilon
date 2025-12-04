#pragma once

#include "gui/gui2_overlay.h"

class GuiSlider;
class GuiProgressbar;
class GuiLabel;

class EasingDebugScreen : public GuiOverlay
{
private:
    struct EasingDemo {
        GuiLabel* name_label;
        GuiSlider* time_slider;
        GuiProgressbar* progress_bar;
        GuiLabel* value_label;
        int easing_index;
    };

    std::vector<EasingDemo> easing_demos;
    float prior_time;
    float animation_time;
    bool auto_animate;

public:
    EasingDebugScreen(GuiContainer* owner);

    virtual void onUpdate() override;
};
