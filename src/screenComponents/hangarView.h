#ifndef HANGAR_VIEW_H
#define HANGAR_VIEW_H

#include "spaceObjects/shipTemplateBasedObject.h"

#include "gui/gui2_element.h"
#include "gui/gui2_listbox.h"
#include "gui/gui2_keyvaluedisplay.h"
#include "screenComponents/rotatingModelView.h"

class GuiListbox;
class GuiKeyValueDisplay;
class GuiRotatingModelView;

class HangarViewComponent : public GuiElement
{
public:
    HangarViewComponent(GuiContainer* owner);
private:
    const float keyvalue_left_divider = 0.4f;
    const float keyvalue_right_divider = 0.75f;

    void fillListBox();
    void destroyContainers();
    void display();
    virtual void onDraw(sp::RenderTarget& window) override;

    P<ShipTemplateBasedObject> selected_entry;
    GuiListbox* item_list = nullptr;
    GuiElement* selection_container = nullptr;
    GuiElement* controls_container = nullptr;
    GuiElement* keyvalue_container = nullptr;
    GuiElement* keyvalue_left_container = nullptr;
    GuiElement* keyvalue_right_container = nullptr;

    GuiRotatingModelView* selected_entry_model;
    GuiKeyValueDisplay* selected_entry_dockstyle;
    GuiButton* launch_button;
    GuiKeyValueDisplay* selected_entry_hull;
    GuiKeyValueDisplay* selected_entry_front_shield;
    GuiKeyValueDisplay* selected_entry_rear_shield;
    GuiKeyValueDisplay* selected_entry_energy;
    GuiKeyValueDisplay* selected_entry_repair_crew;
    GuiKeyValueDisplay* selected_entry_scan_probes;
    GuiKeyValueDisplay* selected_entry_weapons[MW_Count];
    GuiKeyValueDisplay* selected_entry_systems[SYS_COUNT];

    static constexpr int navigation_width = 400;
};

#endif // HANGAR_VIEW_H
