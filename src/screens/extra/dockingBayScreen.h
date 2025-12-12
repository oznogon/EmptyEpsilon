#pragma once

#include "gui/gui2_overlay.h"
#include "missileWeaponData.h"

class GuiArrow;
class GuiButton;
class GuiEntityInfoPanel;
class GuiEntityInfoPanelGrid;
class GuiImage;
class GuiKeyValueDisplay;
class GuiLabel;
class GuiProgressbar;
class GuiSelector;
class GuiSlider;
class GuiToggleButton;
class MissileTubes;
class PickupCallback;

class DockingBayScreen : public GuiOverlay
{
private:
    static constexpr float kv_size = 40.0f;
    static constexpr float kv_split = 0.5f;

    class SystemRow
    {
    public:
        GuiElement* row;
        GuiKeyValueDisplay* label;
        GuiProgressbar* damage_bar;
        GuiImage* damage_icon;
        GuiLabel* damage_label;
        GuiProgressbar* heat_bar;
        GuiArrow* heat_arrow;
        GuiImage* heat_icon;
    };
    std::vector<SystemRow> thermal_rows;
    std::vector<SystemRow> repair_rows;

    GuiElement* left_column;
    GuiElement* right_column;
    GuiEntityInfoPanelGrid* docking_bay_berths;
    GuiElement* docking_bay_info;

    GuiEntityInfoPanel* selected_entity_info;
    GuiKeyValueDisplay* entity_missiles[MW_Count];
    GuiKeyValueDisplay* entity_energy;
    GuiKeyValueDisplay* entity_hull;
    GuiKeyValueDisplay* entity_probes;

    GuiElement* move_controls_row;
    GuiSelector* target_berth;
    GuiToggleButton* scramble;
    GuiKeyValueDisplay* energy_carrier;

    GuiElement* move_progress_row;
    GuiProgressbar* move_progress_bar;
    GuiButton* cancel_move_button;

    GuiElement* hangar_controls;
    GuiElement* energy_controls;
    GuiSlider* energy_transfer_direction;
    GuiElement* thermal_controls;
    GuiSlider* thermal_venting_direction;
    GuiElement* heat_gauges_row;
    GuiElement* supply_controls;
    GuiKeyValueDisplay* berth_missiles[MW_Count];
    GuiKeyValueDisplay* carrier_missiles[MW_Count];
    GuiKeyValueDisplay* berth_scan_probes;
    GuiKeyValueDisplay* carrier_scan_probes;
    GuiButton* generate_supply_drop;
    GuiElement* repair_controls;
    GuiElement* damage_gauges_row;
    GuiElement* storage_controls;
    GuiSlider* repair_prioritization_direction;

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
    void updateMissileDisplay(GuiKeyValueDisplay* display, PickupCallback* pickup, EMissileWeapons type);

public:
    DockingBayScreen(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& renderer) override;
    virtual void onUpdate() override;
};
