#ifndef GUI_KEYVALUEDISPLAY_H
#define GUI_KEYVALUEDISPLAY_H

#include "gui2_element.h"

class GuiThemeStyle;
class GuiKeyValueDisplay : public GuiElement
{
public:
    GuiKeyValueDisplay(GuiContainer* owner, const string& id, float div_distance, const string& key, const string& value);

    virtual void onDraw(sp::RenderTarget& renderer) override;

    string getKey() const { return key; }
    GuiKeyValueDisplay* setKey(const string& key);
    string getValue() const { return value; }
    GuiKeyValueDisplay* setValue(const string& value);
    float getTextSize() const { return text_size; }
    GuiKeyValueDisplay* setTextSize(float text_size);
    float getDivDistance() const { return div_distance; }
    GuiKeyValueDisplay* setDivDistance(float div_distance);
    float getDivSize() const { return div_size; }
    GuiKeyValueDisplay* setDivSize(float div_size);
    glm::u8vec4 getColor() const { return color; }
    GuiKeyValueDisplay* setColor(glm::u8vec4 color);
    GuiKeyValueDisplay* setIcon(const string& name, const sp::Alignment alignment = sp::Alignment::CenterLeft, const float rotation = 0.0f);
    string getIconName() const { return icon_name; }
    sp::Alignment getIconAlignment() { return icon_alignment; }
    GuiKeyValueDisplay* setIconAlignment(const sp::Alignment alignment);
    float getIconRotation() const { return icon_rotation; }
    GuiKeyValueDisplay* setIconRotation(const float rotation);
    GuiKeyValueDisplay* removeIcon();

private:
    const GuiThemeStyle* back_style;
    const GuiThemeStyle* key_style;
    const GuiThemeStyle* value_style;

    float div_distance;
    float div_size;
    string key;
    string value;
    float text_size;
    glm::u8vec4 color;
    bool custom_color_defined;
    string icon_name;
    sp::Alignment icon_alignment;
    float icon_rotation;
};

#endif//GUI_KEYVALUEDISPLAY_H
