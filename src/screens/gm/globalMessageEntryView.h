#pragma once

#include "gui/gui2_panel.h"

class GuiTextEntry;
class GuiContainer;

class GuiGlobalMessageEntryView : public GuiPanel
{
private:
    GuiTextEntry* message_entry;
public:
    GuiGlobalMessageEntryView(GuiContainer* owner);

    virtual bool onMouseDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id) override;
};
