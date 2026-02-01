#pragma once

#include "playerInfo.h"
#include "components/shipsystem.h"
#include "components/missiletubes.h"
#include "gui/gui2_overlay.h"
#include "gui/annunciatorIndicatorPresets.h"
#include <array>
#include <vector>

class GuiPanel;
class GuiElement;
class GuiIndicatorLight;
class GuiLabel;

/**
 * Aviation-style System Status Screen
 *
 * Color usage:
 * - Black: Normal operation, no attention needed
 * - Blue: Manual operation in progress
 * - Green: Automatic operation active
 * - White: System OFF when it should be ON
 * - Amber: Caution - degraded system (flashing 0.5s)
 * - Red: Warning - critical condition (flashing 0.25s)
 *
 * All indicators use Annunciator Standard 389 presets with 4:3 aspect ratio.
 * Blink intervals: 0.25s (warning) to 0.5s (caution), equal on/off.
 */

// Tracks previous value for delta calculation
struct TrackedValue
{
    float current = 1.0f;
    float previous = 1.0f;

    void update(float new_value)
    {
        previous = current;
        current = new_value;
    }

    float delta() const { return current - previous; }
    bool improving() const { return delta() > 0.001f; }
    bool declining() const { return delta() < -0.001f; }
    bool stable() const { return !improving() && !declining(); }
};

// System indicator row with separate indicators for each metric
struct SystemIndicatorRow
{
    GuiElement* row = nullptr;
    GuiIndicatorLight* name_indicator = nullptr;
    GuiIndicatorLight* power_indicator = nullptr;
    GuiIndicatorLight* heat_indicator = nullptr;
    GuiIndicatorLight* heat_delta_indicator = nullptr;
    GuiIndicatorLight* damage_indicator = nullptr;
    GuiIndicatorLight* repair_indicator = nullptr;
    GuiIndicatorLight* coolant_indicator = nullptr;

    TrackedValue health_value;
    TrackedValue heat_value;
    TrackedValue power_value;
    TrackedValue coolant_value;
    TrackedValue hacked_value;

    ShipSystem::Type system_type;
};

// Shield segment indicator
struct ShieldIndicator
{
    GuiIndicatorLight* indicator = nullptr;
    TrackedValue value;
    int segment_index = 0;
};

// Missile tube row with tube indicator and weapon type indicators
struct TubeIndicatorRow
{
    GuiElement* row = nullptr;
    GuiIndicatorLight* tube_indicator = nullptr;
    GuiIndicatorLight* weapon_indicators[MW_Count] = {nullptr};
    TrackedValue delay_value;
    float direction = 0.0f;
    uint32_t type_allowed_mask = 0;
};

// Beam weapon indicator
struct BeamIndicator
{
    GuiIndicatorLight* indicator = nullptr;
    TrackedValue cooldown_value;
    float direction = 0.0f;
};

class SystemStatusScreen : public GuiOverlay
{
private:
    GuiOverlay* background_crosses;

    // Panels
    GuiPanel* systems_panel;
    GuiPanel* defenses_panel;
    GuiPanel* weapons_panel;
    GuiPanel* propulsion_panel;
    GuiPanel* transmitter_panel;

    // Standard indicator size (4:3 aspect ratio)
    static constexpr float INDICATOR_WIDTH = 80.0f;
    static constexpr float INDICATOR_HEIGHT = 60.0f;
    static constexpr float INDICATOR_MARGIN = 4.0f;
    static constexpr float ROW_HEIGHT = INDICATOR_HEIGHT + INDICATOR_MARGIN;
    static constexpr float PANEL_HEADER_HEIGHT = 45.0f;
    static constexpr float PANEL_PADDING = 10.0f;

    // Blink intervals (equal on/off time)
    static constexpr float BLINK_CAUTION = 0.5f;
    static constexpr float BLINK_WARNING = 0.25f;

    // System names for indicator display
    std::array<string, ShipSystem::COUNT> system_labels;

    // Energy row
    GuiElement* energy_row = nullptr;
    GuiIndicatorLight* energy_indicator = nullptr;
    GuiIndicatorLight* charge_indicator = nullptr;
    TrackedValue energy_value;

    // System indicator rows (one per ship system)
    GuiElement* systems_grid = nullptr;
    std::vector<SystemIndicatorRow> system_rows;
    int visible_system_count = 0;

    // Hull indicator
    GuiIndicatorLight* hull_indicator = nullptr;
    TrackedValue hull_value;

    // Shield indicators
    std::vector<ShieldIndicator> shield_indicators;
    GuiIndicatorLight* shields_status_indicator = nullptr;

    // Weapon storage indicators
    GuiIndicatorLight* weapon_storage_indicators[MW_Count] = {nullptr};

    // Probe indicator
    GuiIndicatorLight* probe_indicator = nullptr;
    TrackedValue probe_value;

    // Tube indicator rows
    std::array<string, EMissileWeapons::MW_Count> weapon_labels;
    GuiElement* tubes_grid = nullptr;
    std::vector<TubeIndicatorRow> tube_rows;
    int visible_tube_count = 0;

    // Beam indicators
    GuiElement* beams_row = nullptr;
    std::vector<BeamIndicator> beam_indicators;

    // Propulsion indicators
    GuiIndicatorLight* impulse_indicator = nullptr;
    GuiIndicatorLight* warp_indicator = nullptr;
    GuiIndicatorLight* jump_indicator = nullptr;
    GuiIndicatorLight* maneuver_indicator = nullptr;

    // Transmitter indicators
    GuiIndicatorLight* comms_indicator = nullptr;
    GuiIndicatorLight* scan_indicator = nullptr;
    GuiIndicatorLight* dock_indicator = nullptr;

    // Self-destruct (standalone)
    GuiIndicatorLight* selfdestruct_indicator = nullptr;

    // Update timing
    float update_timer = 0.0f;
    static constexpr float UPDATE_INTERVAL = 0.25f;

    // Helper functions
    void createSystemsPanel();
    void createDefensesPanel();
    void createWeaponsPanel();
    void createPropulsionPanel();
    void createTransmitterPanel();

    void updateSystemIndicators();
    void updateDefenseIndicators();
    void updateWeaponIndicators();
    void updatePropulsionIndicators();
    void updateTransmitterIndicators();
    void updateSelfDestructIndicator();

    // Create a standard 4:3 indicator
    GuiIndicatorLight* createIndicator(GuiElement* parent, const string& id, const string& label);

    // Format angle for display (always in degrees)
    string formatAngle(float degrees);

public:
    SystemStatusScreen(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;
};
