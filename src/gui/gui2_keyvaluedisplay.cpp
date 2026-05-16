#include "textureManager.h"
#include "gui2_keyvaluedisplay.h"
#include "theme.h"


GuiKeyValueDisplay::GuiKeyValueDisplay(GuiContainer* owner, const string& id, float div_distance, const string& key, const string& value)
: GuiElement(owner, id), div_distance(div_distance), key(key), value(value)
{
    back_style = theme->getStyle("keyvalue.back");
    key_style = theme->getStyle("keyvalue.key");
    value_style = theme->getStyle("keyvalue.value");
    useThemeColors();
}

void GuiKeyValueDisplay::onDraw(sp::RenderTarget& renderer)
{
    const auto& back = back_style->get(getState());
    const auto& key = key_style->get(getState());
    const auto& value = value_style->get(getState());

    const float div_size = 5.0f;

    if (rect.size.x >= rect.size.y)
    {
        renderer.drawStretchedHV(rect, 8.0f, back.texture, back_color, sp::RenderTarget::StretchedRotation::Rotate0);
        renderer.drawText(sp::Rect(rect.position.x, rect.position.y, rect.size.x * div_distance - div_size, rect.size.y), this->key, sp::Alignment::CenterRight, text_size, key.font, key_color);
        renderer.drawText(sp::Rect(rect.position.x + rect.size.x * div_distance + div_size, rect.position.y, rect.size.x * (1.f - div_distance), rect.size.y), this->value, sp::Alignment::CenterLeft, text_size, value.font, value_color);
        if (icon_texture != "")
        {
            renderer.drawSprite(icon_texture, glm::vec2(rect.position.x + rect.size.y * 0.5f, rect.position.y + rect.size.y * 0.5f), rect.size.y * 0.8f, key_color);
        }
    }
    else
    {
        renderer.drawStretchedHV(rect, 8.0f, back.texture, back_color, sp::RenderTarget::StretchedRotation::Rotate270);
        renderer.drawText(sp::Rect(rect.position.x, rect.position.y + rect.size.y * (1.f - div_distance) + div_size, rect.size.x, rect.size.y * div_distance - div_size), this->key, sp::Alignment::TopCenter, text_size, key.font, key_color, sp::Font::FlagVertical);
        renderer.drawText(sp::Rect(rect.position.x, rect.position.y, rect.size.x, rect.size.y * (1.f - div_distance) - div_size), this->value, sp::Alignment::BottomCenter, text_size, value.font, value_color, sp::Font::FlagVertical);
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

GuiKeyValueDisplay* GuiKeyValueDisplay::setDivDistance(float div_distance)
{
    this->div_distance = div_distance;
    return this;
}

GuiKeyValueDisplay* GuiKeyValueDisplay::setColor(glm::u8vec4 color)
{
    this->back_color = color;
    this->key_color = color;
    this->value_color = color;
    return this;
}

GuiKeyValueDisplay* GuiKeyValueDisplay::setBackColor(glm::u8vec4 color)
{
    this->back_color = color;
    return this;
}

GuiKeyValueDisplay* GuiKeyValueDisplay::setKeyColor(glm::u8vec4 color)
{
    this->key_color = color;
    return this;
}

GuiKeyValueDisplay* GuiKeyValueDisplay::setValueColor(glm::u8vec4 color)
{
    this->value_color = color;
    return this;
}

GuiKeyValueDisplay* GuiKeyValueDisplay::useThemeColors()
{
    this->back_color = this->back_style->get(getState()).color;
    this->key_color = this->key_style->get(getState()).color;
    this->value_color = this->value_style->get(getState()).color;
    return this;
}

GuiKeyValueDisplay* GuiKeyValueDisplay::setIcon(const string& icon_texture)
{
    this->icon_texture = icon_texture;
    return this;
}
