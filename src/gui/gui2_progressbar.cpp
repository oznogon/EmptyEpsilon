#include "gui2_progressbar.h"
#include "theme.h"

GuiProgressbar::GuiProgressbar(GuiContainer* owner, string id, float min_value, float max_value, float start_value)
: GuiElement(owner, id), min_value(min_value), max_value(max_value), value(start_value), color(glm::u8vec4(255, 255, 255, 64)), drawBackground(true)
{
    back_style = theme->getStyle("progressbar.back");
    front_style = theme->getStyle("progressbar.front");
}

void GuiProgressbar::onDraw(sp::RenderTarget& renderer)
{
    const auto& back = back_style->get(getState());
    const auto& front = front_style->get(getState());

    float f = (value - min_value) / (max_value - min_value);
    const float size = text_size > 0.0f ? text_size : front.size;
    sp::Rect fill_rect = rect;

    if (drawBackground)
        renderer.drawStretched(rect, back.texture, back.color);

    if (rect.size.x >= rect.size.y)
    {
        if (drawBackground)
        {
            renderer.drawStretchedHV(rect, 8.0f, back.texture, back.color, sp::RenderTarget::StretchedRotation::Rotate0);
            fill_rect.position.y += fill_rect.size.y * 0.125f;
            fill_rect.size.y *= 0.75f;
        }
        fill_rect.size.x *= f;
        if (max_value < min_value)
            fill_rect.position.x = rect.position.x + rect.size.x - fill_rect.size.x;
        renderer.drawStretchedHVClipped(rect, fill_rect, size, front.texture, color);
    }
    else
    {
        if (drawBackground)
        {
            renderer.drawStretchedHV(rect, 8.0f, back.texture, back.color, sp::RenderTarget::StretchedRotation::Rotate270);
            fill_rect.position.x += fill_rect.size.x * 0.125f;
            fill_rect.size.x *= 0.75f;
        }
        fill_rect.size.y *= f;
        fill_rect.position.y = rect.position.y + rect.size.y - fill_rect.size.y;
        renderer.drawStretchedHVClipped(rect, fill_rect, size, front.texture, color);
    }
    renderer.drawText(rect, text, sp::Alignment::Center, fill_rect.size.y * 0.9f);
}

GuiProgressbar* GuiProgressbar::setValue(float value)
{
    this->value = value;
    return this;
}

GuiProgressbar* GuiProgressbar::setRange(float min_value, float max_value)
{
    if (min_value == max_value)
    {
        LOG(Error, "GuiProgressbar passed a minimum value equal to its maximum value; ignoring.");
        return this;
    }

    if (min_value > max_value)
    {
        LOG(Warning, "GuiProgressbar passed a minimum value larger than its maximum value; swapping them.");
        this->min_value = max_value;
        this->max_value = min_value;
    }
    else
    {
        this->min_value = min_value;
        this->max_value = max_value;
    }

    return this;
}

GuiProgressbar* GuiProgressbar::setText(string text, float size)
{
    this->text_size = size > 0.0f ? size : front_style->get(getState()).size;
    this->text = text;
    return this;
}

GuiProgressbar* GuiProgressbar::setTextSize(float size)
{
    this->text_size = size > 0.0f ? size : front_style->get(getState()).size;
    return this;
}

GuiProgressbar* GuiProgressbar::setColor(glm::u8vec4 color)
{
    this->color = color;
    return this;
}

GuiProgressbar* GuiProgressbar::setDrawBackground(bool drawBackground)
{
    this->drawBackground = drawBackground;
    return this;
}
