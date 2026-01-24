#pragma once

#include "gui2_element.h"
#include <functional>
#include <vector>
#include <optional>

class GuiThemeStyle;

// Position configuration for label/icon placement
struct IndicatorContentPosition
{
    bool inside = true;      // If true, content is inside the indicator; if false, outside
    float angle = 0.0f;      // Angle in degrees from center (only used when outside)
    float distance = 0.0f;   // Distance from edge (only used when outside)

    static IndicatorContentPosition Inside() { return {true, 0.0f, 0.0f}; }
    static IndicatorContentPosition Outside(float angle, float distance) { return {false, angle, distance}; }
};

// Configuration for a single indicator state (used in multi-state mode)
struct GuiIndicatorState
{
    string id;                              // Unique string identifier

    // Background
    string background_image;                // Background image path
    glm::u8vec4 background_color{255, 255, 255, 255};

    // Icon (optional)
    std::optional<string> icon_image;
    glm::u8vec4 icon_color{255, 255, 255, 255};
    IndicatorContentPosition icon_position;

    // Label (optional)
    std::optional<string> label_text;
    glm::u8vec4 label_color{255, 255, 255, 255};
    sp::Font* label_font = nullptr;
    IndicatorContentPosition label_position;
};

class GuiIndicatorLight : public GuiElement
{
public:
    typedef std::function<void()> func_t;
    typedef std::function<float(float t)> animation_func_t;  // Takes normalized time [0,1], returns alpha [0,1]

protected:
    // Mode: either boolean value or multi-state
    bool use_multi_state = false;

    // Boolean mode
    bool value = false;

    // Multi-state mode
    std::vector<GuiIndicatorState> states;
    size_t current_state_index = 0;

    // Theme styles
    const GuiThemeStyle* back_style;
    const GuiThemeStyle* front_style;

    // Color overrides (optional)
    std::optional<glm::u8vec4> active_color_override;
    std::optional<glm::u8vec4> disabled_color_override;

    // Label configuration
    string label_text;
    IndicatorContentPosition label_position;
    sp::Alignment label_alignment = sp::Alignment::Center;
    sp::Font* label_font_override = nullptr;

    // Icon configuration
    string icon_name;
    IndicatorContentPosition icon_position;

    // Blink configuration
    bool blink_enabled = false;
    float blink_interval = 0.5f;       // Seconds per blink step
    float blink_timer = 0.0f;
    bool blink_state = false;           // Current blink phase (true = active appearance)
    animation_func_t blink_animation;   // Optional custom animation function

    // Click callback
    func_t click_func;

public:
    GuiIndicatorLight(GuiContainer* owner, const string& id, bool initial_value = false);
    GuiIndicatorLight(GuiContainer* owner, const string& id, const std::vector<GuiIndicatorState>& states, size_t initial_state = 0);

    virtual void onUpdate() override;
    virtual void onDraw(sp::RenderTarget& renderer) override;
    virtual bool onMouseDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id) override;
    virtual void onMouseUp(glm::vec2 position, sp::io::Pointer::ID id) override;

    // Value setters (boolean mode)
    GuiIndicatorLight* setValue(bool value);
    bool getValue() const { return value; }

    // Value setters (multi-state mode)
    GuiIndicatorLight* setState(size_t index);
    GuiIndicatorLight* setState(const string& id);
    size_t getStateIndex() const { return current_state_index; }
    string getStateId() const;

    // Add states for multi-state mode
    GuiIndicatorLight* addState(const GuiIndicatorState& state);
    GuiIndicatorLight* setStates(const std::vector<GuiIndicatorState>& states);

    // Color overrides
    GuiIndicatorLight* setActiveColor(glm::u8vec4 color);
    GuiIndicatorLight* setDisabledColor(glm::u8vec4 color);

    // Label configuration
    GuiIndicatorLight* setLabel(const string& text,
                                 IndicatorContentPosition position = IndicatorContentPosition::Inside(),
                                 sp::Alignment alignment = sp::Alignment::Center,
                                 sp::Font* font = nullptr);

    // Icon configuration
    GuiIndicatorLight* setIcon(const string& icon_name,
                                IndicatorContentPosition position = IndicatorContentPosition::Inside());

    // Blink configuration
    GuiIndicatorLight* setBlink(bool enabled, float interval = 0.5f);
    GuiIndicatorLight* setBlinkAnimation(animation_func_t animation);

    // Click callback
    GuiIndicatorLight* setOnClick(func_t func);

private:
    // Helper to get the effective visual state for drawing
    bool getEffectiveActiveState() const;

    // Helper to calculate content position
    glm::vec2 calculateContentPosition(const IndicatorContentPosition& pos, float content_size) const;

    // Draw helpers
    void drawBackground(sp::RenderTarget& renderer);
    void drawContent(sp::RenderTarget& renderer);
    void drawLabel(sp::RenderTarget& renderer, const string& text, const IndicatorContentPosition& pos,
                   sp::Alignment alignment, sp::Font* font, float size, glm::u8vec4 color);
    void drawIcon(sp::RenderTarget& renderer, const string& icon, const IndicatorContentPosition& pos,
                  glm::u8vec4 color);
};
