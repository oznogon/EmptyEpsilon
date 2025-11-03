#pragma once

#include "gui/gui2_overlay.h"

class GuiListbox;
class GuiEntityInfoPanel;
class GuiEntityInfoPanelGrid;

class DockingBayScreen : public GuiOverlay
{
private:
    GuiElement* left_column;
    GuiElement* right_column;
    GuiListbox* docking_bay_controls;
    GuiEntityInfoPanelGrid* docking_bay_info;
    std::vector<sp::ecs::Entity> entities;
public:
    DockingBayScreen(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;
};
