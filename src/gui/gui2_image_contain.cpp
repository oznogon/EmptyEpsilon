#include "gui2_image_contain.h"
#include "graphics/renderTarget.h"

GuiImageContain::GuiImageContain(GuiContainer* owner, string id, string texture_name)
: GuiImage(owner, id, texture_name)
{
}

void GuiImageContain::onDraw(sp::RenderTarget& renderer)
{
    if (texture_name == "")
        return;

    auto tex_size = renderer.getTextureSize(texture_name);
    if (tex_size.x == 0 || tex_size.y == 0)
        return;

    float aspect = float(tex_size.x) / float(tex_size.y);
    float draw_height = std::min(rect.size.y, rect.size.x / aspect);

    if (angle == 0.0f)
        renderer.drawSprite(texture_name, getCenterPoint(), draw_height, color);
    else
        renderer.drawRotatedSprite(texture_name, getCenterPoint(), draw_height, angle, color);
}
