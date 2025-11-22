#pragma once

#include "optionsMenu.h"
#include "gui/gui2_arrowbutton.h"
#include "gui/gui2_entrylist.h"
#include "gui/gui2_canvas.h"
#include "gui/gui2_scrollbar.h"
#include "gui/gui2_scrolltext.h"
#include "gui/hotkeyBinder.h"
#include "Updatable.h"

class GuiArrowButton;
class GuiOverlay;
class GuiSlider;
class GuiLabel;
class GuiCanvas;
class GuiPanel;
class GuiScrollText;
class GuiHotkeyBinder;

class HotkeyMenu : public GuiCanvas, public Updatable
{
private:
    static constexpr float ROW_HEIGHT = 50.0f;
    static constexpr float FRAME_MARGIN = 50.0f;
    static constexpr float KEY_LABEL_WIDTH = 375.0f;
    static constexpr float KEY_FIELD_WIDTH = 150.0f;
    static constexpr float KEY_LABEL_MARGIN = 25.0f;
    static constexpr float KEY_COLUMN_TOP = ROW_HEIGHT * 1.5f;
    static constexpr int KEY_ROW_COUNT = 10;
    static constexpr float KEY_COLUMN_WIDTH = KEY_LABEL_WIDTH + KEY_LABEL_MARGIN + KEY_FIELD_WIDTH;
    static constexpr float KEY_COLUMN_HEIGHT = ROW_HEIGHT * KEY_ROW_COUNT + FRAME_MARGIN * 2.0f;
    static constexpr float PAGER_BREAKPOINT = KEY_COLUMN_WIDTH * 2.0f + FRAME_MARGIN * 2.0f;

    GuiScrollText* help_text;
    GuiElement* container;
    GuiElement* top_row;
    GuiPanel* rebinding_ui;
    GuiElement* bottom_row;

    GuiElement* rebinding_container;
    GuiElement* info_container;
    std::vector<GuiElement*> rebinding_columns;
    std::vector<GuiElement*> rebinding_rows;
    std::vector<GuiHotkeyBinder*> text_entries;
    std::vector<GuiLabel*> label_entries;
    GuiArrowButton* previous_page;
    GuiArrowButton* next_page;
    GuiOverlay* error_window;

    string category = "";
    int category_index = 1;
    std::vector<string> category_list;
    std::vector<sp::io::Keybinding*> hotkey_list;
    OptionsMenu::ReturnTo return_to;

    void setCategory(int cat);
    void pageHotkeys(int direction);
public:
    HotkeyMenu(OptionsMenu::ReturnTo return_to=OptionsMenu::ReturnTo::Main);

    virtual void update(float delta) override;
};
