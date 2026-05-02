#include "gui2_image.h"
#include "theme.h"

GuiImage::GuiImage(GuiContainer* owner, string id, string texture_name)
: GuiElement(owner, id), color(glm::u8vec4{255, 255, 255, 255}), texture_name(texture_name)
{
}

void GuiImage::onDraw(sp::RenderTarget& renderer)
{
    renderer.drawRotatedSprite(texture_name, getCenterPoint(), std::min(rect.size.x, rect.size.y), angle, color);
}

GuiImage* GuiImage::setTextureThemed(string theme_element, GuiElement::State state)
{
    this->texture_name = GuiTheme::getCurrentTheme()->getStyle(theme_element)->get(state).texture;
    return this;
}

GuiImageContain::GuiImageContain(GuiContainer* owner, string id, string texture_name)
: GuiImage(owner, id, texture_name)
{
}

void GuiImageContain::onDraw(sp::RenderTarget& renderer)
{
    if (texture_name == "") return;

    auto tex_size = renderer.getTextureSize(texture_name);
    if (tex_size.x == 0 || tex_size.y == 0) return;

    // Scale height to texture's aspect ratio.
    float draw_height = std::min(rect.size.y, rect.size.x * static_cast<float>(tex_size.y) / static_cast<float>(tex_size.x));

    renderer.drawRotatedSprite(texture_name, getCenterPoint(), draw_height, angle, color);
}
