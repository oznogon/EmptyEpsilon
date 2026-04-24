#pragma once

#include "gui/gui2_overlay.h"
#include "screenComponents/targetsContainer.h"
#include "ecs/entity.h"
#include "missileWeaponData.h"
#include <vector>

class AimLock;
class GuiButton;
class GuiDroneDockingButton;
class GuiElement;
class GuiKeyValueDisplay;
class GuiLabel;
class GuiProgressbar;
class GuiRadarView;
class GuiRadarZoomSlider;
class GuiSelector;
class GuiSlider;
class GuiToggleButton;

class DroneOperatorScreen : public GuiOverlay
{
public:
    explicit DroneOperatorScreen(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;

private:
    // Drone selector and connection controls
    GuiSelector* drone_selector;
    GuiToggleButton* connect_button;

    // Radar
    GuiRadarView* radar;
    GuiRadarZoomSlider* zoom_slider;
    TargetsContainer targets;
    bool drag_rotate = false;

    // Heading hint (shown on radar click when connected)
    GuiLabel* heading_hint;

    // Aim lock
    AimLock* missile_aim;
    GuiToggleButton* manual_aim_button;
    bool use_manual_aim = false;

    // Engine controls (shown when connected)
    GuiElement* engine_layout;
    GuiSlider* impulse_slider;
    GuiKeyValueDisplay* impulse_label;
    GuiElement* warp_controls;
    GuiSlider* warp_slider;
    GuiKeyValueDisplay* warp_label;
    GuiElement* jump_controls;
    GuiButton* jump_button;
    GuiSlider* jump_distance_slider;
    GuiProgressbar* jump_charge_bar;
    GuiKeyValueDisplay* jump_label;

    // Orders menu (shown when connected and drone has AIController)
    GuiElement* orders_layout;

    // Combat maneuver (shown when connected)
    GuiElement* combat_maneuver_layout;

    // Beam info box (shown when connected and drone has beams)
    GuiElement* beam_info_box;
    GuiSelector* beam_freq_selector = nullptr;
    GuiSelector* beam_sys_selector = nullptr;

    // Missile tube controls (shown when connected and drone has tubes)
    GuiElement* tube_controls_layout;
    GuiElement* tube_rows_layout;
    struct TubeRow {
        GuiElement* layout;
        GuiButton* load_button;
        GuiButton* fire_button;
        GuiProgressbar* loading_bar;
        GuiLabel* loading_label;
    };
    std::vector<TubeRow> tube_rows;
    int selected_missile_type = -1; // MW_None
    struct MissileTypeRow {
        GuiElement* layout;
        GuiToggleButton* button;
    };
    MissileTypeRow missile_type_rows[MW_Count];

    // Stats display
    GuiElement* player_stats;
    GuiKeyValueDisplay* player_callsign_display;
    GuiKeyValueDisplay* player_energy_display;
    GuiKeyValueDisplay* player_heading_display;
    GuiKeyValueDisplay* player_velocity_display;
    GuiKeyValueDisplay* player_shields_display;

    GuiElement* drone_stats;
    GuiKeyValueDisplay* drone_callsign_display;
    GuiKeyValueDisplay* drone_energy_display;
    GuiKeyValueDisplay* drone_heading_display;
    GuiKeyValueDisplay* drone_velocity_display;
    GuiKeyValueDisplay* drone_shields_display;
    GuiKeyValueDisplay* drone_heat_display;
    GuiKeyValueDisplay* drone_distance_display;

    // drone_shields_button shown when connected
    GuiToggleButton* drone_shields_button;

    // Drone docking button shown when connected
    GuiDroneDockingButton* drone_docking_button;

    // Player ship controls (shown when disconnected)
    GuiElement* player_controls;

    // Cached drone list for selector sync
    std::vector<sp::ecs::Entity> drone_list;

    // Cached control range to avoid re-clamping the slider every frame
    float previous_control_range = 0.0f;

    sp::ecs::Entity connectedDrone() const;
    bool isDroneConnected() const;
    sp::ecs::Entity getOrderTarget();
    void applyConnectionState();
    void updateTubeRows(sp::ecs::Entity drone_entity);
    void rebuildDroneSelector();
};
