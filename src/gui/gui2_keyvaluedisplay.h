#ifndef GUI_KEYVALUEDISPLAY_H
#define GUI_KEYVALUEDISPLAY_H

#include "gui2_element.h"


class GuiThemeStyle;
class GuiKeyValueDisplay : public GuiElement
{
public:
    GuiKeyValueDisplay(GuiContainer* owner, const string& id, float div_distance, const string& key, const string& value);

    virtual void onDraw(sp::RenderTarget& renderer) override;

    GuiKeyValueDisplay* setKey(const string& key);
    GuiKeyValueDisplay* setValue(const string& value);
    GuiKeyValueDisplay* setTextSize(float text_size);
    GuiKeyValueDisplay* setColor(glm::u8vec4 color);
    GuiKeyValueDisplay* setIcon(const string& icon_name, const sp::Alignment icon_alignment = sp::Alignment::CenterLeft, const float rotation = 0.0f);

private:
    const GuiThemeStyle* back_style;
    const GuiThemeStyle* key_style;
    const GuiThemeStyle* value_style;

    string key;
    string value;
    string icon_name;
    sp::Alignment icon_alignment = sp::Alignment::CenterLeft;
    float icon_rotation = 0.0f;
    float text_size{};
    float div_distance{};
    glm::u8vec4 color{255,255,255,255};
    bool custom_color_defined = false;
};

#endif//GUI_KEYVALUEDISPLAY_H
