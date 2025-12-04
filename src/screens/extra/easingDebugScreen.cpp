#include "easingDebugScreen.h"

#include "tween.h"
#include "engine.h"
#include <stringImproved.h>
#include <i18n.h>

#include "gui/gui2_label.h"
#include "gui/gui2_slider.h"
#include "gui/gui2_progressbar.h"
#include "gui/gui2_togglebutton.h"

// List of all easing functions for testing
struct EasingFunction {
    const char* name;
    std::function<float(float, float, float, float, float)> func;
};

static const std::vector<EasingFunction> easing_functions = {
    {"Linear", Tween<float>::linear},

    {"Sine: EaseIn", Tween<float>::easeInSine},
    {"Sine: EaseOut", Tween<float>::easeOutSine},
    {"Sine: EaseInOut", Tween<float>::easeInOutSine},

    {"Quad: EaseIn", Tween<float>::easeInQuad},
    {"Quad: EaseOut", Tween<float>::easeOutQuad},
    {"Quad: EaseInOut", Tween<float>::easeInOutQuad},

    {"Cubic: EaseIn", Tween<float>::easeInCubic},
    {"Cubic: EaseOut", Tween<float>::easeOutCubic},
    {"Cubic: EaseInOut", Tween<float>::easeInOutCubic},

    {"Quartic: EaseIn", Tween<float>::easeInQuartic},
    {"Quartic: EaseOut", Tween<float>::easeOutQuartic},
    {"Quartic: EaseInOut", Tween<float>::easeInOutQuartic},

    {"Quintic: EaseIn", Tween<float>::easeInQuintic},
    {"Quintic: EaseOut", Tween<float>::easeOutQuintic},
    {"Quintic: EaseInOut", Tween<float>::easeInOutQuintic},

    {"Exponential: EaseIn", Tween<float>::easeInExponential},
    {"Exponential: EaseOut", Tween<float>::easeOutExponential},
    {"Exponential: EaseInOut", Tween<float>::easeInOutExponential},

    {"Circular: EaseIn", Tween<float>::easeInCircular},
    {"Circular: EaseOut", Tween<float>::easeOutCircular},
    {"Circular: EaseInOut", Tween<float>::easeInOutCircular},

    {"Elastic: EaseIn", Tween<float>::easeInElastic},
    {"Elastic: EaseOut", Tween<float>::easeOutElastic},
    {"Elastic: EaseInOut", Tween<float>::easeInOutElastic},

    {"Back: EaseIn", Tween<float>::easeInBack},
    {"Back: EaseOut", Tween<float>::easeOutBack},
    {"Back: EaseInOut", Tween<float>::easeInOutBack},
};

EasingDebugScreen::EasingDebugScreen(GuiContainer* owner)
: GuiOverlay(owner, "EASING_DEBUG_SCREEN", colorConfig.background), prior_time(0.0f), animation_time(0.0f), auto_animate(true)
{
    LOG(Info, "Opening EasingDebug screen");

    GuiElement* layout = new GuiElement(this, "LAYOUT");
    layout
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    // Title
    (new GuiLabel(layout, "TITLE", "Easing Function Debugger", 30))
        ->setSize(GuiElement::GuiSizeMax, 50);

    // Auto-animate toggle
    (new GuiToggleButton(layout, "AUTO_ANIMATE", "Auto Animate", [this](bool value) {
        auto_animate = value;
        if (!auto_animate) animation_time = 0.0f;
    }))
        ->setValue(auto_animate)
        ->setSize(GuiElement::GuiSizeMax, 40);

    // Info text
    (new GuiLabel(layout, "INFO", "Each row shows: manual slider, animated progress bar, and computed value", 15))
        ->setSize(GuiElement::GuiSizeMax, 30);

    // Create a demo row for each easing function
    for (size_t i = 0; i < easing_functions.size(); i++)
    {
        EasingDemo demo;
        demo.easing_index = i;

        // Container for this row
        GuiElement* row = new GuiElement(layout, "ROW_");
        row
            ->setSize(GuiElement::GuiSizeMax, 60)
            ->setAttribute("layout", "horizontal");

        // Function name label
        demo.name_label = new GuiLabel(row, "NAME_", easing_functions[i].name, 18);
        demo.name_label->setSize(250, 40);

        // Manual time slider (0-1)
        demo.time_slider = new GuiSlider(row, "SLIDER_", 1.0f, 0.0f, 0.0f, nullptr);
        demo.time_slider->setSize(300, 40);

        // Progress bar showing the eased value
        demo.progress_bar = new GuiProgressbar(row, "PROGRESS_", 0.0f, 1.0f, 0.0f);
        demo.progress_bar
            ->setColor(glm::u8vec4(128, 200, 255, 255))
            ->setSize(400, 40);

        // Value label showing exact number
        demo.value_label = new GuiLabel(row, "VALUE_", "0.000", 15);
        demo.value_label->setSize(100, 40);

        easing_demos.push_back(demo);
    }

    // Legend at bottom
    GuiLabel* legend = new GuiLabel(layout, "LEGEND",
        "Usage: Toggle 'Auto Animate' to see animations, or manually adjust sliders. "
        "Progress bars show eased output values.", 12);
    legend->setPosition(0, -20, sp::Alignment::BottomCenter)
          ->setSize(GuiElement::GuiSizeMax, 30);
}

void EasingDebugScreen::onUpdate()
{
    GuiOverlay::onUpdate();
    const float animation_cycle_secs = 30.0f;
    float t = 0.0f;
    float delta = engine->getElapsedTime() - prior_time;

    // Update animation time if auto-animating
    if (auto_animate)
    {
        animation_time += delta;
        // Loop every 3 seconds
        if (animation_time > animation_cycle_secs)
            animation_time = 0.0f;
    }

    // Update each easing demo
    for (auto& demo : easing_demos)
    {
        if (auto_animate)
        {
            // Use normalized animation time
            t = animation_time / animation_cycle_secs;
            demo.time_slider->setValue(t);
        }
        else
        {
            // Use manual slider value
            t = demo.time_slider->getValue();
        }

        // Compute eased value using the easing function
        const auto& easing = easing_functions[demo.easing_index];
        float eased_value = easing.func(t, 0.0f, 1.0f, 0.0f, 1.0f);

        // Clamp to valid range for display (some functions like elastic can overshoot)
        float display_value = std::clamp(eased_value, 0.0f, 1.0f);

        // Update progress bar and value label
        demo.progress_bar->setValue(display_value);
        demo.value_label->setText(string(eased_value, 3));

        // Color code based on whether value is in normal range
        if (eased_value < -0.01f || eased_value > 1.01f)
        {
            // Out of range - color it differently
            demo.progress_bar->setColor(glm::u8vec4(255, 100, 100, 255));
        }
        else
        {
            // Normal range
            demo.progress_bar->setColor(glm::u8vec4(128, 200, 255, 255));
        }
    }

    prior_time = engine->getElapsedTime();
}
