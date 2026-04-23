#pragma once

#include "gui2_element.h"

class GuiImage : public GuiElement
{
protected:
    glm::u8vec4 color{255,255,255,255};
    string texture_name;
    float angle = 0.0f;
public:
    GuiImage(GuiContainer* owner, string id, string texture_name);

    virtual void onDraw(sp::RenderTarget& renderer) override;

    GuiImage* setColor(glm::u8vec4 color) { this->color = color; return this; }
    GuiImage* setAngle(float angle) { this->angle = angle; return this; }
    GuiImage* setTexture(string texture_name) { this->texture_name = texture_name; return this; }
    GuiImage* setTextureThemed(string theme_element, GuiElement::State state = GuiElement::State::Normal);
};

class GuiImageContain : public GuiImage
{
public:
    GuiImageContain(GuiContainer* owner, string id, string texture_name);

    virtual void onDraw(sp::RenderTarget& renderer) override;
};
