#include "gui2_listbox.h"
#include "gui2_scrollcontainer.h"
#include "gui2_togglebutton.h"

GuiListbox::GuiListbox(GuiContainer* owner, string id, func_t func)
: GuiEntryList(owner, id, func)
{
    scroll_container = new GuiScrollContainer(this, id + "_SCROLL");
    scroll_container
        ->setScrollbarWidth(button_height)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");
}

GuiListbox* GuiListbox::setTextSize(float size)
{
    text_size = size;
    for (auto* button : buttons) button->setTextSize(size);
    return this;
}

GuiListbox* GuiListbox::setButtonHeight(float height)
{
    button_height = height;
    scroll_container->setScrollbarWidth(height);
    for (auto* button : buttons)
    {
        button->setSize(GuiElement::GuiSizeMax, height);
    }
    return this;
}

GuiListbox* GuiListbox::scrollTo(int index)
{
    scroll_container->scrollToOffset(static_cast<float>(index) * button_height);
    return this;
}

void GuiListbox::entriesChanged()
{
    // Create new buttons for entries that don't have one yet.
    for (int n = static_cast<int>(buttons.size()); n < static_cast<int>(entries.size()); n++)
    {
        auto* btn = new GuiToggleButton(scroll_container, id + "_ENTRY_" + string(n), entries[n].name,
            [this, n](bool)
            {
                setSelectionIndex(n);
                callback();
            }
        );
        btn
            ->setTextSize(text_size)
            ->setIconSize(icon_size)
            ->setSize(GuiSizeMax, button_height);
        buttons.push_back(btn);
    }

    updateButtonStates();
}

void GuiListbox::updateButtonStates()
{
    // Select only one button in the list.
    for (int n = 0; n < static_cast<int>(buttons.size()); n++)
    {
        if (n < static_cast<int>(entries.size()))
        {
            buttons[n]
                ->setValue(n == selection_index)
                ->setText(entries[n].name)
                ->setIcon(entries[n].icon_name)
                ->show();
        }
        else
            buttons[n]->hide();
    }
}