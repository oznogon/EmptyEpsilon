#pragma once

#include "optionsMenu.h"
#include "gui/gui2_canvas.h"
#include "gui/gui2_scrollcontainer.h"
#include "gui/hotkeyBinder.h"
#include "Updatable.h"
#include <timer.h>

class GuiLabel;
class GuiSelector;

class HotkeyMenu : public GuiCanvas, public Updatable
{
private:
    const float FRAME_MARGIN = 50.0f;
    const float KEY_LABEL_WIDTH = 250.0f;
    const float KEY_BINDER_WIDTH = 250.0f;
    const float KEY_BINDER_MARGIN = 10.0f;
    const float KEY_LABEL_MARGIN = 25.0f;
    const float RESET_LABEL_TIMEOUT = 5.0f;

    const float KEY_COLUMN_WIDTH = KEY_LABEL_WIDTH + KEY_LABEL_MARGIN + 3.0f * KEY_BINDER_WIDTH + 4.0f * KEY_BINDER_MARGIN;
    const float KEY_ROW_HEIGHT = GuiElement::GuiSizeRow + GuiHotkeyBinder::SELECTOR_HEIGHT;

    GuiElement* container;
    GuiElement* top_row;
    GuiScrollContainer* rebinding_scroll;
    GuiElement* bottom_row;

    GuiElement* info_container;
    std::vector<GuiElement*> rebinding_rows;
    std::vector<GuiHotkeyBinder*> text_entries;
    std::vector<GuiLabel*> label_entries;
    GuiLabel* reset_label;

    string category = "";
    int category_index = 0;
    sp::SystemTimer reset_label_timer;
    std::vector<string> category_list;
    std::vector<sp::io::Keybinding*> hotkey_list;
    OptionsMenu::ReturnTo return_to;

    GuiSelector* category_selector;

    // Rebind dialog
    GuiRebindDialog* rebind_dialog;

    void setCategory(int cat);
public:
    HotkeyMenu(OptionsMenu::ReturnTo return_to=OptionsMenu::ReturnTo::Main);

    virtual void update(float delta) override;
};
