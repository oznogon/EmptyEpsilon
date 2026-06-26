#include "alertOverlay.h"
#include "playerInfo.h"
#include "gui/theme.h"
#include "engine.h"
#include "tween.h"

AlertLevelOverlay::AlertLevelOverlay(GuiContainer* owner)
: GuiElement(owner, "")
{
    setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    alert_sprite = GuiTheme::getCurrentTheme()->getStyle("alert_overlay")->get(GuiElement::State::Normal).texture;
}

void AlertLevelOverlay::onDraw(sp::RenderTarget& renderer)
{
    if (!my_spaceship) return;

    auto pc = my_spaceship.getComponent<PlayerControl>();
    if (!pc) return;

    glm::u8vec4 color;
    switch (pc->alert_level)
    {
    case AlertLevel::RedAlert:
        color = glm::u8vec4(255, 0, 0, 255);
        break;
    case AlertLevel::YellowAlert:
        color = glm::u8vec4(255, 255, 0, 255);
        break;
    case AlertLevel::Normal:
    default:
        return;
    }

    // Pulse alert background transparency.
    const float t = fmodf(engine->getElapsedTime(), PULSE_PERIOD);
    const float half_period = PULSE_PERIOD * 0.5f;
    float progress;

    if (t < half_period)
        progress = Tween<float>::easeInOutSine(t, 0.0f, half_period, 0.0f, 1.0f);
    else
        progress = 1.0f - Tween<float>::easeInOutSine(t - half_period, 0.0f, half_period, 0.0f, 1.0f);

    color.a = static_cast<uint8_t>((0.25f + progress * 0.5f) * 255.0f);

    renderer.drawStretched(rect, alert_sprite, color);
}
