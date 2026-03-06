#include "gui2_rotationdial.h"

#include "textureManager.h"
#include "vectorUtils.h"
#include "logging.h"
#include "theme.h"
#include "preferenceManager.h"

GuiRotationDial::GuiRotationDial(GuiContainer* owner, string id, float min_value, float max_value, float start_value, func_t func)
: GuiElement(owner, id), min_value(min_value), max_value(max_value), value(start_value), func(func)
{
    back_style = theme->getStyle("rotationdial.back");
    front_style = theme->getStyle("rotationdial.front");
}

void GuiRotationDial::onDraw(sp::RenderTarget& renderer)
{
    auto center = getCenterPoint();
    float radius = std::min(rect.size.x, rect.size.y) * 0.5f;
    // Set ring thickness, or default to 1/6 radius.
    float ring_thickness = (thickness > 0.0f)
        ? thickness
        : radius * 0.125f;

    // Get theme properties.
    const auto& back = back_style->get(getState());
    const auto& front = front_style->get(getState());

    // Draw ring track using drawCircleOutline.
    // TODO: Sprites from legacy are ignored if defined in the theme!
    //       Warn if there's a sprite in the theme. AimLock is exempt (for now)
    //       until it's updated to not override onDraw.
    glm::u8vec4 ring_color{
        uint8_t(back.color.r * 0.33f),
        uint8_t(back.color.g * 0.33f),
        uint8_t(back.color.b * 0.33f),
        back.color.a
    };
    renderer.drawCircleOutline(center, radius, ring_thickness, ring_color);

    // Draw handle as an arc segment centered on the current value position.
    // TODO: Sprites from legacy also ignored here.
    float fraction = (value - min_value) / (max_value - min_value);
    float angle_rad = static_cast<float>(M_PI) - fraction * static_cast<float>(M_PI) * 2.0f;
    // Draw handle to 15 degrees on each side of the value.
    constexpr float handle_half_arc = static_cast<float>(M_PI) / 12.0f;
    constexpr int handle_segments = 8;
    float outer_r = radius;
    float inner_r = radius - ring_thickness;
    std::vector<glm::vec2> pts;
    // Could just reserve 18 points, but left parameterized in case
    // handle_segments needs tweaking.
    pts.reserve((handle_segments + 1) * 2);

    // Generate and draw handle triangles.
    for (int i = 0; i <= handle_segments; i++)
    {
        float f = angle_rad - handle_half_arc + handle_half_arc * 2.0f * static_cast<float>(i) / static_cast<float>(handle_segments);
        float s = sinf(f), c = cosf(f);
        pts.push_back(center + glm::vec2{s * outer_r, c * outer_r});
        pts.push_back(center + glm::vec2{s * inner_r, c * inner_r});
    }

    renderer.drawTriangleStrip(pts, front.color);
}

bool GuiRotationDial::onMouseDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id)
{
    // TODO: Can I just get/set these from onDraw to reuse here for the click
    // target?
    auto center = getCenterPoint();
    float radius = std::min(rect.size.x, rect.size.y) * 0.5f;
    // Set ring thickness, or default to 1/6 radius.
    float ring_thickness = (thickness > 0.0f)
        ? thickness
        : radius * 0.125f;

    auto diff = position - center;
    float dist = glm::length(diff);
    if (dist > radius) return false;
    if (dist < radius - ring_thickness) return false;

    onMouseDrag(position, id);
    return true;
}

void GuiRotationDial::onMouseDrag(glm::vec2 position, sp::io::Pointer::ID id)
{
    auto center = getCenterPoint();

    auto diff = position - center;

    float new_value = (vec2ToAngle(diff) + 90.0f) / 360.0f;
    if (new_value < 0.0f)
        new_value += 1.0f;
    new_value = min_value + (max_value - min_value) * new_value;
    if (min_value < max_value)
    {
        if (new_value < min_value)
            new_value = min_value;
        if (new_value > max_value)
            new_value = max_value;
    }else{
        if (new_value > min_value)
            new_value = min_value;
        if (new_value < max_value)
            new_value = max_value;
    }
    if (value != new_value)
    {
        value = new_value;
        if (func)
            func(value);
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

float GuiRotationDial::getValue() const
{
    return value;
}
