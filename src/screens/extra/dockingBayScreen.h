#pragma once

#include "gui/gui2_overlay.h"

class GuiListbox;
class GuiKeyValueDisplay;
class GuiEntityInfoPanel;
class GuiEntityInfoPanelGrid;

class DockingBayScreen : public GuiOverlay
{
private:
    GuiElement* left_column;
    GuiElement* right_column;
    GuiListbox* docking_bay_controls;
    GuiEntityInfoPanelGrid* docking_bay_ships;
    GuiElement* docking_bay_info;

    GuiEntityInfoPanel* top_row_info;
    GuiKeyValueDisplay* entity_energy;
    GuiKeyValueDisplay* entity_hull;
    GuiKeyValueDisplay* entity_homing;
    GuiKeyValueDisplay* entity_nuke;
    GuiKeyValueDisplay* entity_emp;
    GuiKeyValueDisplay* entity_hvli;
    GuiKeyValueDisplay* entity_mine;

    std::vector<sp::ecs::Entity> entities;
public:
    DockingBayScreen(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;
};
