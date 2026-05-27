#include "gui2_scrolltextcontainer.h"
#include "theme.h"
#include "gui/layout/layout.h"
#include "gui2_scrollcontainer.h"

GuiScrollFormattedText::GuiScrollFormattedText(GuiContainer* owner, string id, string text)
: GuiElement(owner, id), text(text)
{
    layout.match_content_size = false;
    text_theme = theme->getStyle("textbox.front");

    scroll_container = new GuiScrollContainer(this, id + "_SCROLL_CONTAINER");
    scroll_container
        ->setScrollbarWidth(scrollbar_width)
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopLeft)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    text_content = new TextContent(scroll_container, id + "_TEXT_CONTENT");
    text_content->setPosition(0.0f, 0.0f, sp::Alignment::TopLeft);
}

GuiScrollFormattedText* GuiScrollFormattedText::setText(string text)
{
    this->text = text;
    return this;
}

string GuiScrollFormattedText::getText() const
{
    return text;
}

GuiScrollFormattedText* GuiScrollFormattedText::setTextSize(float text_size)
{
    this->text_size = std::max(1.0f, text_size);
    return this;
}

GuiScrollFormattedText* GuiScrollFormattedText::enableAutoScrollDown()
{
    auto_scroll_down = true;
    return this;
}

GuiScrollFormattedText* GuiScrollFormattedText::disableAutoScrollDown()
{
    auto_scroll_down = false;
    return this;
}

GuiScrollFormattedText* GuiScrollFormattedText::setScrollbarWidth(float width)
{
    scrollbar_width = width;
    scroll_container->setScrollbarWidth(width);
    return this;
}

GuiScrollFormattedText* GuiScrollFormattedText::setAlignment(sp::Alignment alignment)
{
    this->alignment = alignment;
    return this;
}

void GuiScrollFormattedText::updateLayout(const sp::Rect& bounds)
{
    this->rect = bounds;

    const auto& text_style = text_theme->get(getState());
    auto main_color = text_style.color;
    auto current_color = main_color;
    float text_width = std::max(0.0f, bounds.size.x - scrollbar_width);

    auto prepared = sp::RenderTarget::getDefaultFont()->start(32, {text_width, bounds.size.y}, alignment, sp::Font::FlagClip | sp::Font::FlagLineWrap);
    int last_end = 0;
    float size_mod = 1.0f;

    for (auto tag_start = text.find('<'); tag_start >= 0; tag_start = text.find('<', tag_start + 1))
    {
        prepared.append(text.substr(last_end, tag_start), text_size * size_mod, current_color);
        auto tag_end = text.find('>', tag_start + 1);

        if (tag_end != -1)
        {
            last_end = tag_end + 1;
            auto tag = text.substr(tag_start + 1, tag_end);
            if (tag == "/")
            {
                size_mod = 1.0f;
                current_color = main_color;
            }
            else if (tag == "h1")
                size_mod = 2.0f;
            else if (tag == "h2")
                size_mod = 1.5f;
            else if (tag == "h3")
                size_mod = 1.17f;
            else if (tag == "h4")
                size_mod = 1.0f;
            else if (tag == "h5")
                size_mod = 0.83f;
            else if (tag == "h6")
                size_mod = 0.67f;
            else if (tag == "small")
                size_mod = 0.89f;
            else if (tag == "large")
                size_mod = 1.2f;
            else if (tag.startswith("color="))
                current_color = GuiTheme::toColor(tag.substr(6));
            else last_end = tag_start;
        }
        else last_end = tag_start;
    }

    prepared.append(text.substr(last_end), text_size * size_mod, current_color);
    prepared.finish();

    auto text_draw_size = prepared.getUsedAreaSize();
    text_content->prepared_text = std::move(prepared);

    float line_spacing = text_content->prepared_text.getFont()->getLineSpacing(32);
    float descent_padding = line_spacing * text_size / 32.0f;

    text_content->setSize(text_draw_size.x, text_draw_size.y + descent_padding);

    if (!layout_manager) layout_manager = std::make_unique<GuiLayout>();

    glm::vec2 padding_size(layout.padding.left + layout.padding.right, layout.padding.top + layout.padding.bottom);
    layout_manager->updateLoop(*this, sp::Rect(rect.position + glm::vec2{layout.padding.left, layout.padding.top}, rect.size - padding_size));

    if (auto_scroll_down) scroll_container->scrollToFraction(1.0f);

    last_text_height = text_draw_size.y;
}
