#include "gui2_indicatorlight.h"
#include "theme.h"
#include "soundManager.h"
// Avoid missing M_PI errors by using our own
#include "vectorUtils.h"
#include <cmath>

GuiIndicatorLight::GuiIndicatorLight(GuiContainer* owner, const string& id, bool initial_value)
: GuiElement(owner, id), value(initial_value)
{
    use_multi_state = false;
    back_style = theme->getStyle("indicator.back");
    front_style = theme->getStyle("indicator.front");
}

GuiIndicatorLight::GuiIndicatorLight(GuiContainer* owner, const string& id, const std::vector<GuiIndicatorState>& states, size_t initial_state)
: GuiElement(owner, id), states(states), current_state_index(initial_state)
{
    use_multi_state = true;
    back_style = theme->getStyle("indicator.back");
    front_style = theme->getStyle("indicator.front");

    if (current_state_index >= this->states.size() && !this->states.empty())
        current_state_index = 0;
}

void GuiIndicatorLight::onUpdate()
{
    if (blink_enabled)
    {
        // TODO: Actual delta
        blink_timer += 0.016f;
        if (blink_timer >= blink_interval)
        {
            blink_timer -= blink_interval;
            blink_state = !blink_state;
        }
    }
}

void GuiIndicatorLight::onDraw(sp::RenderTarget& renderer)
{
    drawBackground(renderer);
    drawContent(renderer);
}

bool GuiIndicatorLight::onMouseDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id)
{
    if (click_func) return true;
    return false;
}

void GuiIndicatorLight::onMouseUp(glm::vec2 position, sp::io::Pointer::ID id)
{
    if (rect.contains(position) && click_func)
    {
        soundManager->playSound("sfx/button.wav"); // TODO: Theme
        func_t f = click_func;
        f();
    }
}

GuiIndicatorLight* GuiIndicatorLight::setValue(bool new_value)
{
    value = new_value;
    return this;
}

GuiIndicatorLight* GuiIndicatorLight::setState(size_t index)
{
    if (index < states.size())
        current_state_index = index;
    return this;
}

GuiIndicatorLight* GuiIndicatorLight::setState(const string& id)
{
    for (size_t i = 0; i < states.size(); i++)
    {
        if (states[i].id == id)
        {
            current_state_index = i;
            break;
        }
    }
    return this;
}

string GuiIndicatorLight::getStateId() const
{
    if (use_multi_state && current_state_index < states.size())
        return states[current_state_index].id;
    return "";
}

GuiIndicatorLight* GuiIndicatorLight::addState(const GuiIndicatorState& state)
{
    states.push_back(state);
    use_multi_state = true;
    return this;
}

GuiIndicatorLight* GuiIndicatorLight::setStates(const std::vector<GuiIndicatorState>& new_states)
{
    states = new_states;
    use_multi_state = true;
    if (current_state_index >= states.size() && !states.empty())
        current_state_index = 0;
    return this;
}

GuiIndicatorLight* GuiIndicatorLight::setActiveColor(glm::u8vec4 color)
{
    active_color_override = color;
    return this;
}

GuiIndicatorLight* GuiIndicatorLight::setDisabledColor(glm::u8vec4 color)
{
    disabled_color_override = color;
    return this;
}

GuiIndicatorLight* GuiIndicatorLight::setLabel(const string& text, IndicatorContentPosition position, sp::Alignment alignment, sp::Font* font)
{
    label_text = text;
    label_position = position;
    label_alignment = alignment;
    label_font_override = font;
    return this;
}

GuiIndicatorLight* GuiIndicatorLight::setIcon(const string& icon, IndicatorContentPosition position)
{
    icon_name = icon;
    icon_position = position;
    return this;
}

GuiIndicatorLight* GuiIndicatorLight::setBlink(bool enabled, float interval)
{
    blink_enabled = enabled;
    blink_interval = interval;
    if (!enabled)
    {
        blink_timer = 0.0f;
        blink_state = false;
    }
    return this;
}

GuiIndicatorLight* GuiIndicatorLight::setBlinkAnimation(animation_func_t animation)
{
    blink_animation = animation;
    return this;
}

GuiIndicatorLight* GuiIndicatorLight::setOnClick(func_t func)
{
    click_func = func;
    return this;
}

bool GuiIndicatorLight::getEffectiveActiveState() const
{
    if (!isEnabled())
        return false;

    bool base_active;
    // In multi-state mode, consider "active" as having a valid state
    if (use_multi_state)
        base_active = !states.empty();
    else
        base_active = value;

    // Apply blink effect
    if (blink_enabled && base_active)
        return blink_state;

    return base_active;
}

glm::vec2 GuiIndicatorLight::calculateContentPosition(const IndicatorContentPosition& pos, float content_size) const
{
    glm::vec2 center = getCenterPoint();

    if (pos.inside)
        return center;
    else
    {
        // Calculate position outside the indicator
        float radius = std::min(rect.size.x, rect.size.y) * 0.5f;
        float angle_rad = pos.angle * static_cast<float>(M_PI) / 180.0f;
        float total_distance = radius + pos.distance + content_size * 0.5f;

        return glm::vec2(
            center.x + std::cos(angle_rad) * total_distance,
            center.y + std::sin(angle_rad) * total_distance
        );
    }
}

void GuiIndicatorLight::drawBackground(sp::RenderTarget& renderer)
{
    if (use_multi_state && !states.empty())
    {
        // Multi-state mode: use the current state's background
        const auto& current = states[current_state_index];

        // Apply blink animation if enabled
        glm::u8vec4 color = current.background_color;
        if (blink_enabled && blink_animation)
        {
            float t = blink_timer / blink_interval;
            float alpha = blink_animation(t);
            color.a = static_cast<uint8_t>(color.a * alpha);
        }

        if (!current.background_image.empty())
            renderer.drawStretchedHV(rect, back_style->get(getState()).size, current.background_image, color);
    }
    else
    {
        // Boolean mode: use theme styles based on active state
        bool active = getEffectiveActiveState();

        // Determine which state style to use
        GuiElement::State style_state;
        if (!isEnabled())
            style_state = GuiElement::State::Disabled;
        else if (active)
            style_state = GuiElement::State::Normal;  // Use "active" appearance
        else
            style_state = GuiElement::State::Disabled;  // Use "disabled" appearance for false value

        const auto& back = back_style->get(style_state);

        // Get color (with potential override)
        glm::u8vec4 color;
        if (active && active_color_override.has_value())
            color = active_color_override.value();
        else if (!active && disabled_color_override.has_value())
            color = disabled_color_override.value();
        else
            color = back.color;

        // Apply blink animation if enabled
        if (blink_enabled && blink_animation)
        {
            float t = blink_timer / blink_interval;
            float alpha = blink_animation(t);
            color.a = static_cast<uint8_t>(color.a * alpha);
        }

        renderer.drawStretchedHV(rect, back.size, back.texture, color);
    }
}

void GuiIndicatorLight::drawContent(sp::RenderTarget& renderer)
{
    // When blinking and in "off" phase, skip drawing content entirely
    // This makes text blink along with the indicator
    if (blink_enabled && !blink_state)
        return;

    if (use_multi_state && !states.empty())
    {
        // Multi-state mode: draw from current state
        const auto& current = states[current_state_index];

        // Draw icon if defined
        if (current.icon_image.has_value())
            drawIcon(renderer, current.icon_image.value(), current.icon_position, current.icon_color);

        // Draw label if defined
        if (current.label_text.has_value())
        {
            float size = front_style->get(getState()).size;
            sp::Font* font = current.label_font ? current.label_font : front_style->get(getState()).font;
            drawLabel(renderer, current.label_text.value(), current.label_position,
                      sp::Alignment::Center, font, size, current.label_color);
        }
    }
    else
    {
        // Boolean mode: use theme styles
        bool active = getEffectiveActiveState();

        GuiElement::State style_state;
        if (!isEnabled())
            style_state = GuiElement::State::Disabled;
        else if (active)
            style_state = GuiElement::State::Normal;
        else
            style_state = GuiElement::State::Disabled;

        const auto& front = front_style->get(style_state);

        // Calculate layout for icon and label
        bool has_icon = !icon_name.empty();
        bool has_label = !label_text.empty();
        bool both_inside = has_icon && has_label && icon_position.inside && label_position.inside;
        bool both_outside_same = has_icon && has_label && !icon_position.inside && !label_position.inside &&
                                  std::abs(icon_position.angle - label_position.angle) < 1.0f &&
                                  std::abs(icon_position.distance - label_position.distance) < 1.0f;

        // Draw icon. Offset handled in the draw function
        if (has_icon)
        {
            IndicatorContentPosition adjusted_icon_pos = icon_position;

            drawIcon(renderer, icon_name, adjusted_icon_pos, front.color);
        }

        // Draw label (supports formatted text with color tags)
        if (has_label)
        {
            drawLabel(renderer, label_text, label_position, label_alignment,
                      label_font_override ? label_font_override : front.font, front.size, front.color);
        }
    }
}

void GuiIndicatorLight::drawLabel(sp::RenderTarget& renderer, const string& text, const IndicatorContentPosition& pos, sp::Alignment alignment, sp::Font* font, float size, glm::u8vec4 default_color)
{
    if (text.empty()) return;

    // Determine the text rect based on position
    sp::Rect text_rect;
    if (pos.inside)
    {
        // Draw inside the indicator bounds
        text_rect = rect;

        // If there's an icon inside, offset the text
        if (!icon_name.empty() && icon_position.inside)
        {
            float icon_size = std::min(rect.size.x, rect.size.y) * 0.4f;
            text_rect.position.x += icon_size * 0.5f;
            text_rect.size.x -= icon_size * 0.5f;
        }
    }
    else
    {
        // Draw outside the indicator
        glm::vec2 text_pos = calculateContentPosition(pos, size);

        // Create a rect for the text; size approximated
        float text_width = size * text.length() * 0.6f;
        float text_height = size * 1.2f;

        text_rect.position = glm::vec2(text_pos.x - text_width * 0.5f, text_pos.y - text_height * 0.5f);
        text_rect.size = glm::vec2(text_width, text_height);
    }

    // Check if text contains format tags
    if (text.find('<') == -1)
    {
        // No formatting - use simple text drawing
        renderer.drawText(text_rect, text, alignment, size, font, default_color);
        return;
    }

    // Parse formatted text with color tags (similar to GuiScrollFormattedText)
    sp::Font* draw_font = font ? font : sp::RenderTarget::getDefaultFont();
    auto prepared = draw_font->start(32, text_rect.size, alignment, sp::Font::FlagClip);

    auto current_color = default_color;
    int last_end = 0;

    for (auto tag_start = text.find('<'); tag_start >= 0; tag_start = text.find('<', tag_start + 1))
    {
        // Append text before the tag
        prepared.append(text.substr(last_end, tag_start), size, current_color);

        auto tag_end = text.find('>', tag_start + 1);
        if (tag_end != -1)
        {
            last_end = tag_end + 1;
            auto tag = text.substr(tag_start + 1, tag_end);

            if (tag == "/")
            {
                // Reset to default color
                current_color = default_color;
            }
            else if (tag.startswith("color="))
            {
                // Parse color value
                current_color = GuiTheme::toColor(tag.substr(6));
            }
            else
            {
                // Unknown tag - treat as literal text
                last_end = tag_start;
            }
        }
        else
        {
            // No closing '>' - treat as literal text
            last_end = tag_start;
        }
    }

    // Append remaining text after last tag
    prepared.append(text.substr(last_end), size, current_color);
    prepared.finish();

    renderer.drawText(text_rect, prepared, sp::Font::FlagClip);
}

void GuiIndicatorLight::drawIcon(sp::RenderTarget& renderer, const string& icon, const IndicatorContentPosition& pos, glm::u8vec4 color)
{
    if (icon.empty()) return;

    float icon_size = std::min(rect.size.x, rect.size.y) * 0.6f;

    if (pos.inside)
    {
        glm::vec2 icon_center = getCenterPoint();

        // If there's also a label inside, offset the icon to the left
        if (!label_text.empty() && label_position.inside)
            icon_center.x = rect.position.x + icon_size * 0.6f;

        renderer.drawSprite(icon, icon_center, icon_size, color);
    }
    else
    {
        glm::vec2 icon_center = calculateContentPosition(pos, icon_size);

        // If both icon and label are outside at the same position, offset icon
        // toward indicator
        if (!label_text.empty() && !label_position.inside
            && std::abs(icon_position.angle - label_position.angle) < 1.0f
            && std::abs(icon_position.distance - label_position.distance) < 1.0f)
        {
            // Move icon closer to the indicator (toward center)
            glm::vec2 center = getCenterPoint();
            glm::vec2 direction = glm::normalize(center - icon_center);
            icon_center += direction * (icon_size * 0.5f + 5.0f);
        }

        renderer.drawSprite(icon, icon_center, icon_size, color);
    }
}
