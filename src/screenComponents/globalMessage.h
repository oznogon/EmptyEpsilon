#pragma once

#include "gui/gui2_element.h"

class GuiPanel;
class GuiLabel;

class GuiGlobalMessage : public GuiElement
{
private:
    GuiPanel* box;
    GuiLabel* label;
public:
    GuiGlobalMessage(GuiContainer* owner);

    virtual void onUpdate() override;
};
