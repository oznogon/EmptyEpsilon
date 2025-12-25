#include "textureManager.h"
#include "vectorUtils.h"
#include "logging.h"
#include "theme.h"
#include "preferenceManager.h"

#include "gui2_rotationdial.h"

GuiRotationDial::GuiRotationDial(GuiContainer* owner, string id, float min_value, float max_value, float start_value, func_t func)
: GuiElement(owner, id), min_value(min_value), max_value(max_value), value(start_value), func(func)
{
    back_style = theme->getStyle("rotationdial.back");
    front_style = theme->getStyle("rotationdial.front");
}

void GuiRotationDial::onDraw(sp::RenderTarget& renderer)
{
    const auto& back = back_style->get(getState());
    const auto& front = front_style->get(getState());
    auto center = getCenterPoint();
    float diameter = std::min(rect.size.x, rect.size.y);

    renderer.drawCircleOutline(center, diameter * 0.5f, 16, back.color);
    renderer.drawRotatedSprite(front.texture, center, diameter, (value - min_value) / (max_value - min_value) * 360.0f, front.color);
}

bool GuiRotationDial::onMouseDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id)
{
    auto center = getCenterPoint();
    float diameter = std::min(rect.size.x, rect.size.y);
    auto diff = position - center;

    if (glm::length(diff) > diameter * 0.5f)
        return false;
    if (glm::length(diff) < diameter * 0.438f)
        return false;

    onMouseDrag(position, id);
    return true;
}

void GuiRotationDial::onMouseDrag(glm::vec2 position, sp::io::Pointer::ID id)
{
    auto center = getCenterPoint();
    auto diff = position - center;

    float new_value = (vec2ToAngle(diff) + 90.0f) / 360.0f;

    if (new_value < 0.0f) new_value += 1.0f;
    if (new_value > 1.0f) new_value -= 1.0f;

    new_value = min_value + (max_value - min_value) * new_value;

    if (value != new_value)
    {
        value = new_value;
        if (func) func(value);
    }
}

void GuiRotationDial::onMouseUp(glm::vec2 position, sp::io::Pointer::ID id)
{
}

GuiRotationDial* GuiRotationDial::setValue(float value)
{
    if (min_value < max_value)
    {
        while(value < min_value)
            value += (max_value - min_value);
        while(value > max_value)
            value -= (max_value - min_value);
    }else{
        while(value < max_value)
            value += (min_value - max_value);
        while(value > min_value)
            value -= (min_value - max_value);
    }
    this->value = value;
    return this;
}

GuiRotationDial* GuiRotationDial::setRange(float min_value, float max_value)
{
    while (min_value < 0.0f) min_value += 360.0f;
    while (max_value > 360.0f) max_value -= 360.0f;

    this->min_value = min_value;
    this->max_value = max_value;
    return this;
}

float GuiRotationDial::getValue() const
{
    return value;
}
