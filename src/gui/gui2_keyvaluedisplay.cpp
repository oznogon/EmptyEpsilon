#include "textureManager.h"
#include "gui2_keyvaluedisplay.h"
#include "theme.h"

GuiKeyValueDisplay::GuiKeyValueDisplay(GuiContainer* owner, const string& id, float div_distance, const string& key, const string& value)
: GuiElement(owner, id), div_distance(div_distance), key(key), value(value), text_size(20.f), color(glm::u8vec4{255,255,255,255})
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

    float div_size = 5.f;

    renderer.drawStretched(rect, back.texture, custom_color_defined ? color : back.color);
    if (rect.size.x >= rect.size.y)
    {
        renderer.drawText(sp::Rect(rect.position.x, rect.position.y, rect.size.x * div_distance - div_size, rect.size.y), this->key, sp::Alignment::CenterRight, text_size, key.font, custom_color_defined ? color : key.color);
        renderer.drawText(sp::Rect(rect.position.x + rect.size.x * div_distance + div_size, rect.position.y, rect.size.x * (1.f - div_distance), rect.size.y), this->value, sp::Alignment::CenterLeft, text_size, value.font, custom_color_defined ? color : value.color);

        if (icon_name != "")
        {
            float icon_x;

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

            renderer.drawRotatedSprite(icon_name, glm::vec2(icon_x, rect.position.y + rect.size.y * 0.5f), rect.size.y * 0.8f, icon_rotation, custom_color_defined ? color : key.color);
        }
    }
    else
    {
        renderer.drawText(sp::Rect(rect.position.x, rect.position.y + rect.size.y * (1.f - div_distance) + div_size, rect.size.x, rect.size.y * div_distance - div_size), this->key, sp::Alignment::TopCenter, text_size, key.font, custom_color_defined ? color : key.color, sp::Font::FlagVertical);
        renderer.drawText(sp::Rect(rect.position.x, rect.position.y, rect.size.x, rect.size.y * (1.f - div_distance) - div_size), this->value, sp::Alignment::BottomCenter, text_size, value.font, custom_color_defined ? color : value.color, sp::Font::FlagVertical);
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

GuiKeyValueDisplay* GuiKeyValueDisplay::setTextSize(float text_size)
{
    this->text_size = text_size;
    return this;
}

GuiKeyValueDisplay* GuiKeyValueDisplay::setColor(glm::u8vec4 color)
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
