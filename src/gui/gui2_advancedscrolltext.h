#pragma once

#include "gui2_element.h"
#include "gui2_scrollbar.h"

class GuiThemeStyle;

class GuiAdvancedScrollText : public GuiElement
{
protected:
    class Entry
    {
    public:
        string prefix;
        sp::Font::PreparedFontString prepared_prefix;
        string text;
        sp::Font::PreparedFontString prepared_text;
        glm::u8vec4 color;
        unsigned int seq;
    };

    std::vector<Entry> entries;
    GuiScrollbar* scrollbar;
    float text_size = 30.0f;
    sp::Font* font;
    glm::u8vec4 default_text_color = {255, 255, 255, 255};
    float rect_width;
    float max_prefix_width = 0.0f;
    std::map<float, int> prefix_widths;
    bool auto_scroll_down;
    Entry prepEntry(Entry& e);
    int mouse_scroll_steps = 25;
    const GuiThemeStyle* text_theme;

public:
    GuiAdvancedScrollText(GuiContainer* owner, string id);

    GuiAdvancedScrollText* enableAutoScrollDown() { auto_scroll_down = true; return this; }
    GuiAdvancedScrollText* disableAutoScrollDown() { auto_scroll_down = false; return this; }

    GuiAdvancedScrollText* addEntry(string prefix, string text, glm::u8vec4 color, unsigned int seq);
    GuiAdvancedScrollText* setTextSize(float text_size);

    unsigned int getEntryCount() const;
    string getEntryText(int index) const;
    unsigned int getEntrySeq(int index) const;
    GuiAdvancedScrollText* removeEntry(int index);
    GuiAdvancedScrollText* clearEntries();

    virtual void onDraw(sp::RenderTarget& renderer) override;
    virtual bool onMouseWheelScroll(glm::vec2 position, float value) override;
};
