#ifndef HANGAR_VIEW_H
#define HANGAR_VIEW_H

#include "spaceObjects/shipTemplateBasedObject.h"
#include "gui/gui2_element.h"
#include "gui/gui2_listbox.h"
#include "gui/gui2_keyvaluedisplay.h"

class GuiListbox;
class GuiKeyValueDisplay;

class HangarViewComponent : public GuiElement
{
public:
    HangarViewComponent(GuiContainer* owner);
private:
    void fillListBox();
    void display();
    virtual void onDraw(sp::RenderTarget& window) override;

    P<ShipTemplateBasedObject> selected_entry;
    GuiListbox* item_list = nullptr;
    GuiElement* selection_container = nullptr;
    GuiElement* details_container = nullptr;
    GuiElement* keyvalue_container = nullptr;
    GuiKeyValueDisplay* selected_entry_weapons[MW_Count];
    GuiKeyValueDisplay* selected_entry_systems[SYS_COUNT];

    static constexpr int navigation_width = 400;
};

#endif // HANGAR_VIEW_H
