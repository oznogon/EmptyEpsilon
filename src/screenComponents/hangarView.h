#ifndef HANGAR_VIEW_H
#define HANGAR_VIEW_H

#include "gui/gui2_element.h"

class GuiListbox;

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
    GuiElement* keyvalue_container = nullptr;
    GuiElement* details_container = nullptr;

    static constexpr int navigation_width = 400;
};

#endif // HANGAR_VIEW_H
