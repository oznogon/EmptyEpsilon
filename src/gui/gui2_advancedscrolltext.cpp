#include "gui2_advancedscrolltext.h"

GuiAdvancedScrollText::GuiAdvancedScrollText(GuiContainer* owner, string id)
: GuiElement(owner, id),
  rect_width(rect.size.x),
  scrollbar(new GuiScrollbar(this, id + "_SCROLL", 0, 1, 0, nullptr)),
  text_size(30.0F),
  max_prefix_width(0.0F),
  auto_scroll_down(false)
{
    scrollbar->setPosition(0, 0, sp::Alignment::TopRight)->setSize(50, GuiElement::GuiSizeMax);
}

GuiAdvancedScrollText* GuiAdvancedScrollText::addEntry(string prefix, string text, glm::u8vec4 color)
{
    Entry& entry = entries.emplace_back();
    entry.prefix = prefix;
    entry.text = text;
    entry.color = color;

    // Set the entry's height by preparing to render it.
    // This must be updated if the control is resized!
    entry.prepared_prefix = sp::RenderTarget::getDefaultFont()
        ->prepare(
            prefix,
            32,
            text_size,
            {rect.size.x, 800.0F},
            sp::Alignment::TopLeft
    );
    entry.prefix_width = entry.prepared_prefix.getUsedAreaSize().x;
    max_prefix_width = std::max(max_prefix_width, entry.prefix_width);

    entry.prepared_text = sp::RenderTarget::getDefaultFont()
        ->prepare(
            text,
            32,
            text_size,
            {rect.size.x - max_prefix_width - 50.0F, 800.0F},
            sp::Alignment::TopLeft,
            sp::Font::FlagLineWrap | sp::Font::FlagClip
    );
    entry.height = entry.prepared_text.getUsedAreaSize().y;

    return this;
}

unsigned int GuiAdvancedScrollText::getEntryCount() const
{
    return entries.size();
}

string GuiAdvancedScrollText::getEntryText(unsigned int index) const
{
    if (index >= getEntryCount())
    {
        return "";
    }

    return entries[index].text;
}

string GuiAdvancedScrollText::getEntryPrefix(unsigned int index) const
{
    if (index >= getEntryCount())
    {
        return "";
    }

    return entries[index].prefix;
}

GuiAdvancedScrollText* GuiAdvancedScrollText::removeEntry(unsigned int index)
{
    // Check if the max prefix width should change with this entry's removal.
    // If so, find the next-largest width.
    if (entries[index].prefix_width == max_prefix_width)
    {
        for (const Entry& entry : entries)
        {
            max_prefix_width = std::max(max_prefix_width, entry.prefix_width);
        }
    }

    // Erase this entry.
    if (index > getEntryCount())
    {
        return this;
    }

    entries.erase(entries.begin() + index);

    return this;
}

GuiAdvancedScrollText* GuiAdvancedScrollText::clearEntries()
{
    // Erase all entries and reset the max prefix width.
    entries.clear();
    max_prefix_width = 0.0F;
    return this;
}

void GuiAdvancedScrollText::onDraw(sp::RenderTarget& renderer)
{
    // If the window's been horizontally resized, recalculate prepared text for
    // wrapping and entry height by clearing and re-adding all entries.
    if (rect_width != rect.size.x)
    {
        rect_width = rect.size.x;
        const std::vector<Entry> cache_entries = entries;
        this->clearEntries();

        for (const Entry& entry : cache_entries)
        {
            addEntry(entry.prefix, entry.text, entry.color);
        }

        return;
    }

    // Draw the visible entries.
    float draw_offset = -scrollbar->getValue() + text_size + 10.0F;

    // Prepare the text for each entry, and use that to estimate the total
    // height of all entries.
    for (Entry& e : entries)
    {
        if (draw_offset + e.height > 0.0f
            && draw_offset < rect.size.y)
        {
            // Set the position of each character of each entry based on the
            // scrollbar offset.
            const float y_start = e.prepared_prefix.data[0].position.y;

            for (auto& g : e.prepared_prefix.data)
            {
                if (y_start != g.position.y)
                {
                    g.position.y = (g.position.y - y_start) + draw_offset;
                }
                else
                {
                    g.position.y = draw_offset;
                }
            }

            for (auto& g : e.prepared_text.data)
            {
                if (y_start != g.position.y)
                {
                    g.position.y = (g.position.y - y_start) + draw_offset;
                }
                else
                {
                    g.position.y = draw_offset;
                }
            }

            // Render each entry, clipping it if it's not visible in the scroll offset.
            renderer.drawText(
                rect,
                e.prepared_prefix,
                text_size,
                {255, 255, 255, 255},
                sp::Font::FlagClip
            );

            renderer.drawText(
                sp::Rect(
                    rect.position.x + max_prefix_width,
                    rect.position.y,
                    rect.size.x - 50.0f - max_prefix_width,
                    rect.size.y
                ),
                e.prepared_text,
                text_size,
                e.color,
                sp::Font::FlagClip
            );
        }

        draw_offset += e.height;
    }

    // Calculate how many lines we have to display in total.
    const int line_count = static_cast<int>(draw_offset) + scrollbar->getValue();

    // Check if we need to update the scroll bar.
    if (scrollbar->getMax() != line_count)
    {
        const int diff = line_count - scrollbar->getMax();
        scrollbar->setRange(0, line_count);
        scrollbar->setValueSize(rect.size.y);

        if (auto_scroll_down)
        {
            scrollbar->setValue(scrollbar->getValue() + diff);
        }
    }

    // Hide the scrollbar if the scroll is less than 100px.
    scrollbar->setVisible(rect.size.y > 100.0F);
}
