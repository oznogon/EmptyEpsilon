#ifndef GUI_KEYVALUEDISPLAY_H
#define GUI_KEYVALUEDISPLAY_H

#include "gui2_element.h"


class GuiThemeStyle;
class GuiKeyValueDisplay : public GuiElement
{
public:
    GuiKeyValueDisplay(GuiContainer* owner, const string& id, float div_distance, const string& key, const string& value);

    virtual void onDraw(sp::RenderTarget& target) override;

    string getKey() { return key; }
    GuiKeyValueDisplay* setKey(const string& key);
    string getValue() { return value; }
    GuiKeyValueDisplay* setValue(const string& value);
    float getTextSize() { return text_size; }
    GuiKeyValueDisplay* setTextSize(float text_size);
    glm::u8vec4 getColor() { return color; }
    GuiKeyValueDisplay* setColor(glm::u8vec4 color);
    GuiKeyValueDisplay* setIcon(const string& name, const sp::Alignment alignment = sp::Alignment::CenterLeft, const float rotation = 0.0f);
    string getIconName() { return icon_name; }
    sp::Alignment getIconAlignment() { return icon_alignment; }
    GuiKeyValueDisplay* setIconAlignment(const sp::Alignment alignment);
    float getIconRotation() { return icon_rotation; }
    GuiKeyValueDisplay* setIconRotation(const float rotation);
    GuiKeyValueDisplay* removeIcon();

private:
    const GuiThemeStyle* back_style;
    const GuiThemeStyle* key_style;
    const GuiThemeStyle* value_style;

    float div_distance{};
    string key;
    string value;
    float text_size{};
    glm::u8vec4 color{255,255,255,255};
    bool custom_color_defined = false;
    string icon_name;
    sp::Alignment icon_alignment = sp::Alignment::CenterLeft;
    float icon_rotation = 0.0f;
};

#endif//GUI_KEYVALUEDISPLAY_H
