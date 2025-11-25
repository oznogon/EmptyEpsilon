#pragma once

#include "gui/gui2_overlay.h"
#include "missileWeaponData.h"

class GuiKeyValueDisplay;
class GuiEntityInfoPanel;
class GuiEntityInfoPanelGrid;
class GuiSelector;
class GuiSlider;
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

    GuiEntityInfoPanel* selected_entity_info;
    GuiKeyValueDisplay* entity_missiles[MW_Count];
    GuiKeyValueDisplay* entity_energy;
    GuiKeyValueDisplay* entity_hull;

    GuiElement* bottom_row;
    GuiKeyValueDisplay* energy_carrier;
    GuiSelector* target_berth;
    GuiToggleButton* scramble;
    GuiElement* hangar_controls;
    GuiElement* energy_controls;
    GuiSlider* energy_transfer_direction;
    GuiKeyValueDisplay* energy_docked;
    GuiElement* thermal_controls;
    GuiElement* missile_controls;
    GuiElement* repair_controls;
    GuiElement* storage_controls;
    GuiSlider* repair_prioritization_direction;
    GuiKeyValueDisplay* hull_docked;

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
