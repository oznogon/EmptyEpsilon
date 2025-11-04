#pragma once

#include "gui/gui2_overlay.h"
#include "missileWeaponData.h"

class GuiButton;
class GuiListbox;
class GuiKeyValueDisplay;
class GuiEntityInfoPanel;
class GuiEntityInfoPanelGrid;
class MissileTubes;

class DockingBayScreen : public GuiOverlay
{
private:
    static constexpr float kv_size = 40.0f;
    static constexpr float kv_split = 0.5f;

    GuiElement* left_column;
    GuiElement* right_column;
    GuiEntityInfoPanelGrid* docking_bay_ships;
    GuiButton* docking_bay_scramble;
    GuiElement* docking_bay_info;

    GuiEntityInfoPanel* top_row_info;
    GuiKeyValueDisplay* entity_energy;
    GuiKeyValueDisplay* entity_hull;
    GuiKeyValueDisplay* entity_homing;
    GuiKeyValueDisplay* entity_nuke;
    GuiKeyValueDisplay* entity_emp;
    GuiKeyValueDisplay* entity_hvli;
    GuiKeyValueDisplay* entity_mine;

    // State tracking
    sp::ecs::Entity selected_entity;
    std::vector<sp::ecs::Entity> cached_docked_entities;

    // Helper methods
    void selectEntity(sp::ecs::Entity entity);
    void updateSelectedEntityDisplay();
    void updateDockedEntitiesList();
    void updateMissileDisplay(GuiKeyValueDisplay* display, MissileTubes* tubes, EMissileWeapons type);

public:
    DockingBayScreen(GuiContainer* owner);

    virtual void onUpdate() override;
};
