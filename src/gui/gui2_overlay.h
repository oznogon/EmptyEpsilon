#pragma once

#include "gui2_element.h"

class GuiOverlay : public GuiElement
{
private:
    glm::u8vec4 color;
    enum ETextureMode
    {
        TM_None,
        TM_Tiled,
    } texture_mode;
    string texture;
public:
    GuiOverlay(GuiContainer* owner, string id, glm::u8vec4 color);

    virtual void onDraw(sp::RenderTarget& renderer) override;

    GuiOverlay* setColor(glm::u8vec4 color);
    GuiOverlay* setAlpha(int alpha);
    GuiOverlay* setTextureTiled(string texture);
    GuiOverlay* setTextureTiledThemed(string theme_element, GuiElement::State state = GuiElement::State::Normal);
    GuiOverlay* setTextureNone();
};
