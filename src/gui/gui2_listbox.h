#pragma once

#include "gui2_entrylist.h"

class GuiScrollContainer;
class GuiToggleButton;

class GuiListbox : public GuiEntryList
{
protected:
    float icon_size = 0.6f;
    float text_size = 30.0f;
    float button_height = 50.0f;
public:
    GuiListbox(GuiContainer* owner, string id, func_t func);

    GuiListbox* setTextSize(float size);
    // GuiListbox* setIconSize(float size);
    GuiListbox* setButtonHeight(float height);

    GuiListbox* scrollTo(int index);

private:
    GuiScrollContainer* scroll_container;
    std::vector<GuiToggleButton*> buttons;

    virtual void entriesChanged() override;
    void updateButtonStates();
};
