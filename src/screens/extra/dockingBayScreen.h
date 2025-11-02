#pragma once

#include "gui/gui2_overlay.h"

class GuiListbox;

class DockingBayScreen : public GuiOverlay
{
private:
    GuiElement* left_column;
    GuiElement* right_column;
    GuiListbox* docking_bay_controls;
    GuiListbox* docking_bay_ships;
public:
    DockingBayScreen(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;
};
