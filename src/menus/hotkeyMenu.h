#pragma once

#include "optionsMenu.h"
#include "gui/hotkeyBinder.h"
#include "Updatable.h"
#include <timer.h>

class GuiButton;
class GuiCanvas;
class GuiHotkeyBinder;
class GuiLabel;
class GuiPanel;
class GuiScrollContainer;
class GuiScrollText;
class GuiSelector;
class GuiSlider;
class GuiToggleButton;

class HotkeyMenu : public GuiCanvas, public Updatable
{
private:
    const float ROW_HEIGHT = 50.0f;
    const float ROW_MARGIN = 50.0f;
    const float FRAME_MARGIN = 50.0f;
    const float KEY_LABEL_WIDTH = 250.0f;
    const float KEY_BINDER_MARGIN = 12.5f;
    const float RESET_LABEL_TIMEOUT = 5.0f;

    GuiElement* container;
    GuiElement* top_row;
    GuiPanel* rebinding_ui;
    GuiElement* info_container;
    GuiElement* bottom_row;

    GuiScrollContainer* scroll_container;
    std::vector<GuiElement*> rebinding_rows;
    std::vector<GuiHotkeyBinder*> text_entries;
    std::vector<GuiLabel*> label_entries;
    GuiLabel* reset_label;

    string category = "";
    int category_index = 1;
    sp::SystemTimer reset_label_timer;
    std::vector<string> category_list;
    std::vector<sp::io::Keybinding*> hotkey_list;
    OptionsMenu::ReturnTo return_to;

    // Dialog mode toggle
    bool use_dialog_mode = true;
    GuiToggleButton* dialog_mode_toggle;

    // Rebind dialog
    GuiRebindDialog* rebind_dialog = nullptr;

    void setCategory(int cat);
public:
    HotkeyMenu(OptionsMenu::ReturnTo return_to=OptionsMenu::ReturnTo::Main);

    virtual void update(float delta) override;
};
