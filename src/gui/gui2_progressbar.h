#pragma once

#include "gui2_element.h"

class GuiThemeStyle;

class GuiProgressbar : public GuiElement
{
protected:
    float min_value;
    float max_value;
    float value;
    float text_size = 0.0f;
    glm::u8vec4 color;
    bool drawBackground;
    const GuiThemeStyle* back_style;
    const GuiThemeStyle* front_style;

    string text;
public:
    GuiProgressbar(GuiContainer* owner, string id, float min_value, float max_value, float start_value);

    virtual void onDraw(sp::RenderTarget& renderer) override;

    GuiProgressbar* setValue(float value);
    GuiProgressbar* setRange(float min_value, float max_value);
    GuiProgressbar* setText(string text, float size = 0.0f);
    GuiProgressbar* setTextSize(float size);
    GuiProgressbar* setColor(glm::u8vec4 color);
    GuiProgressbar* setDrawBackground(bool drawBackground);
};
