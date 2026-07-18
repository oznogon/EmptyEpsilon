#pragma once

#include "gui2_entrylist.h"

class GuiScrollContainer;
class GuiToggleButton;
class GuiTextEntry;

// Creates a scrolling list of buttons to represent an entry list. Clicking a
// button selects that value in the list. Supports only one selection at a time.
class GuiListbox : public GuiEntryList
{
public:
    // Text filter search callback function.
    using search_func_t = std::function<void(string)>;
protected:
    // The font size for the buttons' text, in virtual pixels.
    float text_size = 30.0f;
    // The buttons' icon size, as a normalized factor of button height
    // (0.0-1.0 = 0-100%).
    float icon_size = 0.6f;
    // The buttons' height, in virtual pixels.
    float button_height = GuiElement::GuiSizeRow;

    // Text entry field for text filter search.
    GuiTextEntry* search_entry = nullptr;
    // Callback run when text is entered in the text filter search.
    search_func_t search_callback;
    // Master list of all entries, used to rebuild the visible list on each filter change.
    std::vector<GuiEntry> all_entries;
    // Boolean indicator of whether filtering is active.
    bool search_filtering = false;
    // Text entered into the text filter search, to be matched against entries.
    string search_text;
public:
    GuiListbox(GuiContainer* owner, string id, func_t func);

    // Set the font size for the buttons' text, in virtual pixels.
    GuiListbox* setTextSize(float size);
    // Set the buttons' icon size, as a normalized factor of button height
    // (0.0-1.0 = 0-100%).
    GuiListbox* setIconSize(float size);
    // Set the buttons' height, in virtual pixels.
    GuiListbox* setButtonHeight(float height);
    // Scroll the listbox to the item with the given index.
    GuiListbox* scrollTo(int index);
    // Adds the text filter search field. Takes an optional callback that
    // receives the lowercased search text and runs each time the field is
    // edited. When no callback is provided, the listbox filters itself.
    // Has no effect if called more than once.
    GuiListbox* addSearch(search_func_t search_callback = nullptr);
    // Clears the search field. For the built-in filter, also resets the
    // visible list to all entries.
    GuiListbox* clearSearch();

    // Returns the current text in the search field, or "" if no search field exists.
    string getSearchText() const;

    virtual int addEntry(string name, string value) override;
    virtual void clear() override;
    virtual void setEntryName(int index, string name) override;
    virtual void setEntryValue(int index, string value) override;
    virtual void setEntryIcon(int index, string icon_name) override;
    virtual void setEntry(int index, string name, string value) override;
    virtual void removeEntry(int index) override;

private:
    // Scrolling container wrapping the button list.
    GuiScrollContainer* scroll_container;
    // Vector of toggle buttons representing list items.
    std::vector<GuiToggleButton*> buttons;

    // Update the listbox when its entries change.
    virtual void entriesChanged() override;
    // Update listbox button selection states.
    void updateButtonStates();
    // Default search filter callback. Builds an entry list from matches.
    void applyFilter();

    static constexpr float search_bar_height = 30.0f;
};
