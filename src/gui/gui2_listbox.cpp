#include "gui2_listbox.h"
#include "gui2_scrollcontainer.h"
#include "gui2_textentry.h"
#include "gui2_togglebutton.h"

GuiListbox::GuiListbox(GuiContainer* owner, string id, func_t func)
: GuiEntryList(owner, id, func)
{
    intercepts_pointer = true;
    // Wrap the Listbox in a scrolling container.
    scroll_container = new GuiScrollContainer(this, id + "_SCROLL");
    scroll_container
        ->setScrollbarWidth(button_height)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    // Listbox theme isn't declared here because it's applied by
    // button->setStyle in entriesChanged().
}

GuiListbox* GuiListbox::setTextSize(float size)
{
    text_size = std::max(0.0f, size);
    for (auto* button : buttons) button->setTextSize(size);
    return this;
}

GuiListbox* GuiListbox::setIconSize(float size)
{
    icon_size = std::max(0.0f, size);
    for (auto* button : buttons) button->setIconSize(size);
    return this;
}

GuiListbox* GuiListbox::setButtonHeight(float height)
{
    button_height = std::max(0.0f, height);
    scroll_container->setScrollbarWidth(height);
    for (auto* button : buttons) button->setSize(GuiElement::GuiSizeMax, height);
    return this;
}

GuiListbox* GuiListbox::scrollTo(int index)
{
    scroll_container->scrollToOffset(static_cast<float>(index) * button_height);
    return this;
}

GuiListbox* GuiListbox::addSearch(search_func_t callback)
{
    if (search_entry) return this;

    // Set the search callback.
    search_callback = callback;
    if (!search_callback)
    {
        all_entries = {};
        for (int i = 0; i < entryCount(); i++)
            all_entries.emplace_back(getEntryName(i), getEntryValue(i), getEntryIcon(i));
    }

    // Build search entry field.
    search_entry = new GuiTextEntry(this, id + "_SEARCH", "");
    search_entry
        ->setTextSize(20.0f)
        ->setSize(GuiElement::GuiSizeMax, search_bar_height)
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopLeft);
    search_entry->callback(
        [this](string value)
        {
            search_text = value.lower();
            if (search_callback) search_callback(search_text);
            else applyFilter();
        }
    );

    // Adjust scroll container to be below the search entry.
    scroll_container->setPosition(0.0f, search_bar_height, sp::Alignment::TopLeft);

    return this;
}

GuiListbox* GuiListbox::clearSearch()
{
    if (!search_entry) return this;
    search_text = "";
    search_entry->setText("");
    if (!search_callback) applyFilter();
    return this;
}

int GuiListbox::addEntry(string name, string value)
{
    if (search_entry && !search_filtering && !search_callback)
    {
        all_entries.emplace_back(name, value, "");
        if (name.lower().find(search_text) >= 0)
            return GuiEntryList::addEntry(name, value);
        return -1;
    }
    return GuiEntryList::addEntry(name, value);
}

void GuiListbox::clear()
{
    if (search_entry && !search_filtering && !search_callback)
    {
        all_entries.clear();
        search_text = "";
        search_entry->setText("");
    }
    GuiEntryList::clear();
}

void GuiListbox::setEntryName(int index, string name)
{
    if (search_entry && !search_filtering && !search_callback && index >= 0)
    {
        string val = getEntryValue(index);
        for (auto& e : all_entries)
        {
            if (e.value == val)
            {
                e.name = name;
                break;
            }
        }
    }
    GuiEntryList::setEntryName(index, name);
}

void GuiListbox::setEntryValue(int index, string value)
{
    if (search_entry && !search_filtering && !search_callback && index >= 0)
    {
        string old_val = getEntryValue(index);
        for (auto& e : all_entries)
        {
            if (e.value == old_val)
            {
                e.value = value;
                break;
            }
        }
    }
    GuiEntryList::setEntryValue(index, value);
}

void GuiListbox::setEntryIcon(int index, string icon_name)
{
    if (search_entry && !search_filtering && !search_callback && index >= 0)
    {
        string val = getEntryValue(index);
        for (auto& e : all_entries)
        {
            if (e.value == val)
            {
                e.icon_name = icon_name;
                break;
            }
        }
    }
    GuiEntryList::setEntryIcon(index, icon_name);
}

void GuiListbox::setEntry(int index, string name, string value)
{
    if (search_entry && !search_filtering && !search_callback && index >= 0)
    {
        string old_val = getEntryValue(index);
        for (auto& e : all_entries)
        {
            if (e.value == old_val)
            {
                e.name = name;
                e.value = value;
                break;
            }
        }
    }
    GuiEntryList::setEntry(index, name, value);
}

void GuiListbox::removeEntry(int index)
{
    if (search_entry && !search_filtering && !search_callback && index >= 0)
    {
        string val = getEntryValue(index);
        for (auto it = all_entries.begin(); it != all_entries.end(); ++it)
        {
            if (it->value == val)
            {
                all_entries.erase(it);
                break;
            }
        }
    }
    GuiEntryList::removeEntry(index);
}

string GuiListbox::getSearchText() const
{
    return search_text;
}

void GuiListbox::applyFilter()
{
    search_filtering = true;
    // Capture previous selection.
    int prev_index = getSelectionIndex();
    string prev_value = getSelectionValue();

    // Clear the list and rebuild it with matches.
    GuiEntryList::clear();
    for (const auto& e : all_entries)
    {
        if (e.name.lower().find(search_text) >= 0)
        {
            int idx = GuiEntryList::addEntry(e.name, e.value);
            GuiEntryList::setEntryIcon(idx, e.icon_name);
        }
    }

    // Select the previous value, if present.
    int restored = indexByValue(prev_value);
    if (prev_index >= 0 && restored >= 0) setSelectionIndex(restored);
    search_filtering = false;
}

void GuiListbox::entriesChanged()
{
    // Create new buttons for entries that don't have one yet.
    for (auto n = buttons.size(); n < entries.size(); n++)
    {
        auto* btn = new GuiToggleButton(scroll_container, id + "_ENTRY_" + string(static_cast<int>(n)), entries[n].name,
            [this, n](bool)
            {
                setSelectionIndex(static_cast<int>(n));
                callback();
            }
        );
        btn
            ->setStyle("listbox") // Use listbox-specific theme styles.
            ->setTextSize(text_size)
            ->setIconSize(icon_size)
            ->setSize(GuiElement::GuiSizeMax, button_height);
        buttons.push_back(btn);
    }

    updateButtonStates();
}

void GuiListbox::updateButtonStates()
{
    // Select only one button in the list.
    for (size_t n = 0; n < buttons.size(); n++)
    {
        if (n < entries.size())
        {
            buttons[n]
                ->setValue(static_cast<int>(n) == selection_index)
                ->setText(entries[n].name)
                ->setIcon(entries[n].icon_name)
                ->show();
        }
        else buttons[n]->hide();
    }
}
