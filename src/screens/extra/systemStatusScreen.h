#pragma once

#include "gui/gui2_overlay.h"
#include "gui/korryIndicatorPresets.h"
#include "components/shipsystem.h"
#include "components/missiletubes.h"
#include "playerInfo.h"
#include <unordered_map>

class GuiPanel;
class GuiElement;
class GuiIndicatorLight;
class GuiLabel;

/**
 * Aviation-style System Status Screen
 *
 * Follows the "Dark Cockpit" philosophy:
 * - Black: Normal operation, no attention needed
 * - Blue: Manual operation in progress
 * - Green: Automatic operation active
 * - White: System OFF when it should be ON
 * - Amber: Caution - degraded system (flashing)
 * - Red: Warning - critical condition (flashing)
 *
 * All indicators use Korry Standard 389 presets with 4:3 aspect ratio.
 */

// Tracks previous value for delta calculation
struct TrackedValue
{
    float current = 1.0f;
    float previous = 1.0f;

    void update(float new_value) {
        previous = current;
        current = new_value;
    }

    float delta() const { return current - previous; }
    bool improving() const { return delta() > 0.001f; }
    bool declining() const { return delta() < -0.001f; }
    bool stable() const { return !improving() && !declining(); }
};

// System indicator for a single ship system
struct SystemIndicator
{
    GuiIndicatorLight* indicator = nullptr;
    TrackedValue health_value;
    TrackedValue heat_value;
    TrackedValue power_value;
    ShipSystem::Type system_type;
};

// Shield segment indicator
struct ShieldIndicator
{
    GuiIndicatorLight* indicator = nullptr;
    TrackedValue value;
    int segment_index = 0;
};

// Weapon tube indicator
struct TubeIndicator
{
    GuiIndicatorLight* indicator = nullptr;
    TrackedValue delay_value;
};

// Beam weapon indicator
struct BeamIndicator
{
    GuiIndicatorLight* indicator = nullptr;
    TrackedValue cooldown_value;
};

class SystemStatusScreen : public GuiOverlay
{
private:
    GuiOverlay* background_crosses;

    // Panels
    GuiPanel* systems_panel;
    GuiPanel* defenses_panel;
    GuiPanel* weapons_panel;
    GuiPanel* status_panel;

    // Standard indicator size (4:3 aspect ratio)
    static constexpr float INDICATOR_WIDTH = 80.0f;
    static constexpr float INDICATOR_HEIGHT = 60.0f;
    static constexpr float INDICATOR_MARGIN = 4.0f;

    // System indicators (one per ship system)
    std::vector<GuiElement*> system_rows;
    std::vector<SystemIndicator> system_indicators;

    // Hull indicator
    GuiIndicatorLight* hull_indicator = nullptr;
    TrackedValue hull_value;

    // Shield indicators
    std::vector<ShieldIndicator> shield_indicators;
    GuiIndicatorLight* shields_status_indicator = nullptr;

    // Energy indicators
    GuiIndicatorLight* energy_indicator = nullptr;
    GuiIndicatorLight* charge_indicator = nullptr;
    TrackedValue energy_value;

    // Weapon storage indicators
    GuiIndicatorLight* weapon_storage_indicators[MW_Count] = {nullptr};

    // Probe indicator
    GuiIndicatorLight* probe_indicator = nullptr;
    TrackedValue probe_value;

    // Tube indicators
    std::vector<TubeIndicator> tube_indicators;

    // Beam indicators
    std::vector<BeamIndicator> beam_indicators;

    // Special system indicators
    GuiIndicatorLight* jump_indicator = nullptr;
    GuiIndicatorLight* warp_indicator = nullptr;
    GuiIndicatorLight* impulse_indicator = nullptr;
    GuiIndicatorLight* comms_indicator = nullptr;
    GuiIndicatorLight* scan_indicator = nullptr;
    GuiIndicatorLight* selfdestruct_indicator = nullptr;
    GuiIndicatorLight* target_indicator = nullptr;
    GuiIndicatorLight* maneuver_indicator = nullptr;
    GuiIndicatorLight* dock_indicator = nullptr;

    // Update timing
    float update_timer = 0.0f;
    static constexpr float UPDATE_INTERVAL = 0.25f;  // Faster updates for responsiveness

    // Helper functions
    void createSystemsPanel();
    void createDefensesPanel();
    void createWeaponsPanel();
    void createStatusPanel();

    void updateSystemIndicators();
    void updateDefenseIndicators();
    void updateWeaponIndicators();
    void updateStatusIndicators();

    // Apply Korry styling based on system state
    // Uses dark cockpit philosophy: black=normal, blue=manual, green=auto, white=off, amber=caution, red=warning
    void applyDarkCockpitStyle(GuiIndicatorLight* indicator, const string& label,
                                float health_ratio, float threshold_caution = 0.8f,
                                float threshold_warning = 0.3f);

    // Create a standard 4:3 indicator
    GuiIndicatorLight* createIndicator(GuiElement* parent, const string& id, const string& label);

public:
    SystemStatusScreen(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;
};
