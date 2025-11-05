#pragma once

#include "gui/gui2_overlay.h"
#include "missileWeaponData.h"

class GuiKeyValueDisplay;
class GuiEntityInfoPanel;
class GuiEntityInfoPanelGrid;
class GuiSelector;
class GuiToggleButton;
class MissileTubes;

class DockingBayScreen : public GuiOverlay
{
private:
    static constexpr float kv_size = 40.0f;
    static constexpr float kv_split = 0.5f;

    GuiElement* left_column;
    GuiElement* right_column;
    GuiEntityInfoPanelGrid* docking_bay_berths;
    GuiElement* docking_bay_info;

    GuiEntityInfoPanel* top_row_info;
    GuiKeyValueDisplay* entity_energy;
    GuiKeyValueDisplay* entity_hull;
    GuiKeyValueDisplay* entity_missiles[MW_Count];

    GuiElement* bottom_row;
    GuiSelector* target_berth;
    GuiToggleButton* scramble;
    GuiElement* hangar_controls;
    GuiElement* energy_controls;
    GuiElement* thermal_controls;
    GuiElement* missile_controls;
    GuiElement* repair_controls;
    GuiElement* storage_controls;

    // State tracking
    sp::ecs::Entity selected_entity;
    int selected_berth_index = -1;
    std::vector<sp::ecs::Entity> cached_berth_entities;

    // Helper methods
    void selectBerth(int berth_index);
    void updateSelectedEntityDisplay();
    void updateBerthsList();
    void updateBerthsLabels();
    void updateMissileDisplay(GuiKeyValueDisplay* display, MissileTubes* tubes, EMissileWeapons type);

public:
    DockingBayScreen(GuiContainer* owner);

    virtual void onUpdate() override;
};
