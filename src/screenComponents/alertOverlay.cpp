#include "alertOverlay.h"
#include "playerInfo.h"


AlertLevelOverlay::AlertLevelOverlay(GuiContainer* owner)
: GuiElement(owner, "")
{
    setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    alert_style = GuiTheme::getCurrentTheme()->getStyle("alert_overlay")->get(GuiElement::State::Normal);
    alert_sprite = alert_style.texture;
}

void AlertLevelOverlay::onDraw(sp::RenderTarget& renderer)
{
    if (!my_spaceship) return;
    auto pc = my_spaceship.getComponent<PlayerControl>();
    if (!pc) return;

    glm::u8vec4 color;

    switch(pc->alert_level)
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

    renderer.drawSprite(alert_sprite, getCenterPoint(), alert_style.size, color);
}
