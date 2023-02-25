#ifndef HANGAR_VIEW_H
#define HANGAR_VIEW_H

#include "gui/gui2_element.h"

class GuiListbox;

class HangarViewComponent : public GuiElement
{
public:
    HangarViewComponent(GuiContainer* owner);

    bool findAndDisplayEntry(string name);

private:
    // P<ScienceDatabase> findEntryById(int32_t id);
    //Fill the selection listbox with options from the selected_entry, or the main database list if selected_entry is nullptr
    void fillListBox();
    void display();
    virtual void onDraw(sp::RenderTarget& window) override;

    // P<ScienceDatabase> selected_entry;
    GuiListbox* item_list = nullptr;
    GuiElement* keyvalue_container = nullptr;
    GuiElement* details_container = nullptr;

    static constexpr int navigation_width = 400;
};

#endif // HANGAR_VIEW_H
