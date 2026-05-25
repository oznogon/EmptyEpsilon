#pragma once

#include "gui2_element.h"

class GuiThemeStyle;
class GuiScrollContainer;

class GuiScrollFormattedText : public GuiElement
{
    class TextContent : public GuiElement
    {
    public:
        sp::Font::PreparedFontString prepared_text;

        TextContent(GuiContainer* owner, string id)
        : GuiElement(owner, id) {}

        virtual void onDraw(sp::RenderTarget& renderer) override
        {
            if (prepared_text.data.empty()) return;
            renderer.drawText(rect, prepared_text, sp::Font::FlagClip | sp::Font::FlagLineWrap);
        }
    };

    GuiScrollContainer* scroll_container;
    TextContent* text_content;

    string text;
    float text_size = 30.0f;
    bool auto_scroll_down = false;
    float scrollbar_width = 50.0f;
    const GuiThemeStyle* text_theme;
    sp::Alignment alignment = sp::Alignment::TopLeft;
    float last_text_height = 0.0f;

public:
    GuiScrollFormattedText(GuiContainer* owner, string id, string text);

    GuiScrollFormattedText* setText(string text);
    string getText() const;
    GuiScrollFormattedText* setTextSize(float text_size);
    GuiScrollFormattedText* enableAutoScrollDown();
    GuiScrollFormattedText* disableAutoScrollDown();
    GuiScrollFormattedText* setScrollbarWidth(float width);
    GuiScrollFormattedText* setAlignment(sp::Alignment alignment);

    virtual void updateLayout(const sp::Rect& bounds) override;
};
