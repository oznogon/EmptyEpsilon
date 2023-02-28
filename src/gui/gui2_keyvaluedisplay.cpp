#include "textureManager.h"
#include "gui2_keyvaluedisplay.h"
#include "theme.h"

GuiKeyValueDisplay::GuiKeyValueDisplay(GuiContainer* owner, const string& id, float div_distance, const string& key, const string& value)
: GuiElement(owner, id), div_distance(div_distance), div_size(5.0f), key(key), value(value), text_size(20.f), color(glm::u8vec4{255,255,255,255}), custom_color_defined(false), icon_name(""), icon_alignment(sp::Alignment::CenterLeft), icon_rotation(0.0f)
{
    back_style = theme->getStyle("keyvalue.back");
    key_style = theme->getStyle("keyvalue.key");
    value_style = theme->getStyle("keyvalue.value");
}

void GuiKeyValueDisplay::onDraw(sp::RenderTarget& renderer)
{
    const auto& back = back_style->get(getState());
    const auto& key = key_style->get(getState());
    const auto& value = value_style->get(getState());

    // Draw background texture.
    renderer.drawStretched(rect, back.texture, custom_color_defined ? color : back.color);

    // If sized horizontally, also draw text horizontally.
    if (rect.size.x >= rect.size.y)
    {
        // Draw key text.
        renderer.drawText(
            sp::Rect(
                rect.position.x,
                rect.position.y,
                rect.size.x * div_distance - div_size,
                rect.size.y
            ),
            this->key,
            sp::Alignment::CenterRight,
            text_size,
            key.font,
            custom_color_defined ? color : key.color
        );

        // Draw value text.
        renderer.drawText(
            sp::Rect(
                rect.position.x + rect.size.x * div_distance + div_size,
                rect.position.y,
                rect.size.x * (1.f - div_distance),
                rect.size.y
            ),
            this->value,
            sp::Alignment::CenterLeft,
            text_size,
            value.font,
            custom_color_defined ? color : value.color
        );

        // Draw icon, if defined.
        if (icon_name != "")
        {
            float icon_x;

            // Align the icon to the right if given any non-left alignment.
            // Discard any specified vertical alignment - always center it.
            switch(icon_alignment)
            {
            case sp::Alignment::CenterLeft:
            case sp::Alignment::TopLeft:
            case sp::Alignment::BottomLeft:
                icon_x = rect.position.x + rect.size.y * 0.5f;
                break;
            default:
                icon_x = rect.position.x + rect.size.x - rect.size.y * 0.5f;
            }

            // Draw the icon, with the given rotation if defined.
            // - pad the left or right by half the k/v's height
            // - size the icon 80% of the k/v's height
            // - center it vertically within the k/v
            // - rotate it; 0.0f = up
            // - use the same color as the bg and text, custom if defined
            renderer.drawRotatedSprite(
                icon_name,
                glm::vec2(
                    icon_x,
                    rect.position.y + rect.size.y * 0.5f
                ),
                rect.size.y * 0.8f,
                icon_rotation,
                custom_color_defined ? color : key.color
            );
        }
    }
    else
    {
        // If sized vertically, also draw text vertically.
        renderer.drawText(
            sp::Rect(
                rect.position.x,
                rect.position.y + rect.size.y * (1.f - div_distance) + div_size,
                rect.size.x,
                rect.size.y * div_distance - div_size
            ),
            this->key,
            sp::Alignment::TopCenter,
            text_size,
            key.font,
            custom_color_defined ? color : key.color,
            sp::Font::FlagVertical
        );
        renderer.drawText(
            sp::Rect(
                rect.position.x,
                rect.position.y,
                rect.size.x,
                rect.size.y * (1.f - div_distance) - div_size
            ),
            this->value,
            sp::Alignment::BottomCenter,
            text_size,
            value.font,
            custom_color_defined ? color : value.color,
            sp::Font::FlagVertical
        );

        // If sized vertically and an icon's defined, draw it.
        if (icon_name != "")
        {
            float icon_y;

            // If given any non-bottom alignment, draw at the top.
            // Discard any specified horizontal alignment - always center it.
            switch(icon_alignment)
            {
            case sp::Alignment::BottomLeft:
            case sp::Alignment::BottomCenter:
            case sp::Alignment::BottomRight:
                icon_y = rect.position.y + rect.size.x * 0.5f;
                break;
            default:
                icon_y = rect.position.y + rect.size.y - rect.size.x * 0.5f;
            }

            renderer.drawRotatedSprite(
                icon_name,
                glm::vec2(
                    rect.position.x + rect.size.x * 0.5f,
                    icon_y
                ),
                rect.size.x * 0.8f,
                icon_rotation, // still 0.0f = up, unlike the text
                custom_color_defined ? color : key.color
            );
        }
    }
}

GuiKeyValueDisplay* GuiKeyValueDisplay::setKey(const string& key)
{
    this->key = key;
    return this;
}

GuiKeyValueDisplay* GuiKeyValueDisplay::setValue(const string& value)
{
    this->value = value;
    return this;
}

<<<<<<< HEAD
GuiKeyValueDisplay* GuiKeyValueDisplay::setDivDistance(const float div_distance)
=======
GuiKeyValueDisplay* GuiKeyValueDisplay::setDivDistance(float div_distance)
{
    this->div_distance = div_distance;
    return this;
}

GuiKeyValueDisplay* GuiKeyValueDisplay::setDivSize(float div_size)
{
    this->div_size = div_size;
    return this;
}

GuiKeyValueDisplay* GuiKeyValueDisplay::setTextSize(float text_size)
>>>>>>> 988ba132 ([GuiKeyValueDisplay] Make div_size, div_distance settable)
{
    this->div_distance = std::max(0.1f, div_distance);
    return this;
}

GuiKeyValueDisplay* GuiKeyValueDisplay::setDivSize(const float div_size)
{
    this->div_size = std::max(0.1f, div_size);
    return this;
}

GuiKeyValueDisplay* GuiKeyValueDisplay::setTextSize(const float text_size)
{
    this->text_size = std::max(0.1f, text_size);
    return this;
}

GuiKeyValueDisplay* GuiKeyValueDisplay::setColor(const glm::u8vec4 color)
{
    this->color = color;
    // Override theme colors if setColor is called.
    this->custom_color_defined = true;
    return this;
}

GuiKeyValueDisplay* GuiKeyValueDisplay::setIcon(const string& name, const sp::Alignment alignment, const float rotation)
{
    this->icon_name = name;
    this
        ->setIconAlignment(alignment)
        ->setIconRotation(rotation);
    return this;
}

GuiKeyValueDisplay* GuiKeyValueDisplay::setIconAlignment(const sp::Alignment alignment)
{
    this->icon_alignment = alignment;
    return this;
}

GuiKeyValueDisplay* GuiKeyValueDisplay::setIconRotation(const float rotation)
{
    this->icon_rotation = std::clamp(rotation, 0.0f, 360.0f);
    return this;
}

GuiKeyValueDisplay* GuiKeyValueDisplay::removeIcon()
{
    this->icon_name = "";
    // Reinitialize alignment, rotation
    this->icon_alignment = sp::Alignment::CenterLeft;
    this->icon_rotation = 0.0f;
    return this;
}
