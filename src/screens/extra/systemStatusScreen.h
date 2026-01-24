#pragma once

#include "gui/gui2_overlay.h"
#include "components/shipsystem.h"
#include "components/missiletubes.h"
#include "playerInfo.h"
#include <unordered_map>

class GuiPanel;
class GuiElement;
class GuiIndicatorLight;
class GuiLabel;

// Represents the status level of an indicator based on degradation
enum class IndicatorStatusLevel
{
    Nominal,           // Full/100%
    DegradedImproving, // <20% degraded, improving
    DegradedStable,    // <20% degraded, stable
    DegradedDeclining, // <20% degraded, declining
    SignificantStable, // >=20% degraded, stable
    SignificantDeclining, // >=20% degraded and <50%, declining
    SignificantImproving, // >=20% degraded, improving
    SevereStable,      // >=50% degraded, stable
    SevereDeclining,   // >=50% degraded, declining
    SevereImproving,   // >=50% degraded, improving
    Critical,          // 100% degraded (flashing pattern)
    Unpowered,         // System unpowered but has health, ship has energy
    UnpoweredNoEnergy, // System unpowered, ship low on energy
    Empty              // Weapon/probe stock empty
};

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

// System indicator group for a single ship system
struct SystemIndicatorGroup
{
    GuiElement* container = nullptr;
    GuiIndicatorLight* power_indicator = nullptr;
    GuiIndicatorLight* heat_indicator = nullptr;
    GuiIndicatorLight* damage_indicator = nullptr;
    GuiIndicatorLight* hacked_indicator = nullptr;

    TrackedValue power_value;
    TrackedValue heat_value;
    TrackedValue damage_value;
    TrackedValue hacked_value;
};

// Beam indicator for individual beam weapons
struct BeamIndicator
{
    GuiIndicatorLight* indicator = nullptr;
    TrackedValue cooldown_value;
};

// Missile tube indicator row - one row per tube with 5 type indicators
struct TubeIndicatorRow
{
    GuiElement* container = nullptr;
    GuiLabel* angle_label = nullptr;
    GuiIndicatorLight* type_indicators[MW_Count] = {nullptr};
    TrackedValue delay_value;
};

// Shield segment indicator
struct ShieldSegmentIndicator
{
    GuiIndicatorLight* indicator = nullptr;
    TrackedValue value;
    int segment_index = 0;
};

// Weapon storage indicator with count
struct WeaponStorageIndicator
{
    GuiIndicatorLight* indicator = nullptr;
    TrackedValue value;
};

class SystemStatusScreen : public GuiOverlay
{
private:
    GuiOverlay* background_crosses;

    // Panels for different indicator groups
    GuiPanel* systems_panel;
    GuiPanel* hull_shields_panel;
    GuiPanel* energy_panel;
    GuiPanel* weapons_panel;
    GuiPanel* special_panel;

    // System indicators (one per ship system)
    std::vector<SystemIndicatorGroup> system_indicators;

    // Hull indicator
    GuiIndicatorLight* hull_indicator;
    TrackedValue hull_value;

    // Shield segment indicators (diamond layout)
    std::vector<ShieldSegmentIndicator> shield_indicators;
    GuiElement* shield_diamond_container = nullptr;

    // Energy
    GuiIndicatorLight* energy_indicator;
    GuiIndicatorLight* energy_rate_indicator;
    TrackedValue energy_value;
    TrackedValue energy_rate_value;

    // Weapon storage indicators (section label + icon with count)
    std::vector<WeaponStorageIndicator> weapon_storage_indicators;

    // Probe storage
    GuiIndicatorLight* probe_indicator;
    TrackedValue probe_value;

    // Missile tube indicators (1 row per tube)
    std::vector<TubeIndicatorRow> tube_indicators;
    GuiElement* tubes_container = nullptr;
    GuiLabel* missiles_section_label = nullptr;
    GuiElement* missiles_header_row = nullptr;
    GuiElement* missiles_storage_row = nullptr;

    // Beam weapons (organized by angle, similar to missiles)
    std::vector<BeamIndicator> beam_indicators;
    GuiElement* beams_container = nullptr;
    GuiLabel* beams_section_label = nullptr;

    // Jump drive
    GuiIndicatorLight* jump_indicator;
    TrackedValue jump_charge_value;

    // Warp drive
    GuiIndicatorLight* warp_indicator;
    int last_warp_level = -1;

    // Comms state
    GuiIndicatorLight* comms_indicator;
    int last_comms_state = -1;

    // Scan indicator
    GuiIndicatorLight* scan_indicator;

    // Self-destruct indicator
    GuiIndicatorLight* selfdestruct_indicator;

    // Target indicator
    GuiIndicatorLight* target_indicator;

    // Combat maneuver indicator (consolidated boost and strafe)
    GuiIndicatorLight* boost_indicator;

    // Docking indicator
    GuiIndicatorLight* dock_indicator;

    // Update timing
    float update_timer = 0.0f;
    static constexpr float UPDATE_INTERVAL = 1.0f;

    // Helper functions
    void createSystemIndicators();
    void createHullShieldIndicators();
    void createEnergyIndicators();
    void createWeaponIndicators();
    void createSpecialIndicators();

    void updateSystemIndicators();
    void updateHullShieldIndicators();
    void updateEnergyIndicators();
    void updateWeaponIndicators();
    void updateSpecialIndicators();

    IndicatorStatusLevel calculateStatusLevel(float value, float max_value, const TrackedValue& tracked, bool invert_direction = false);
    void applyIndicatorStyle(GuiIndicatorLight* indicator, IndicatorStatusLevel level, const string& label);
    void applyHeatIndicatorStyle(GuiIndicatorLight* indicator, float heat, float heat_delta);

    // Shield-specific styling (different for shields up/down)
    void applyShieldIndicatorStyle(GuiIndicatorLight* indicator, float level, float max_level, bool shields_up, const TrackedValue& tracked);

    // Tube indicator styling
    void applyTubeTypeIndicatorStyle(GuiIndicatorLight* indicator, bool is_loaded, MissileTubes::MountPoint::State tube_state, bool can_fire, const string& label);

    // Color constants
    static glm::u8vec4 colorGreen() { return {0, 200, 0, 255}; }
    static glm::u8vec4 colorYellow() { return {220, 200, 0, 255}; }
    static glm::u8vec4 colorOrange() { return {255, 140, 0, 255}; }
    static glm::u8vec4 colorDarkRed() { return {180, 0, 0, 255}; }
    static glm::u8vec4 colorBrightRed() { return {255, 50, 50, 255}; }
    static glm::u8vec4 colorBlack() { return {20, 20, 20, 255}; }
    static glm::u8vec4 textBlack() { return {0, 0, 0, 255}; }
    static glm::u8vec4 textWhite() { return {255, 255, 255, 255}; }
    static glm::u8vec4 textOrange() { return {255, 140, 0, 255}; }
    static glm::u8vec4 textRed() { return {255, 50, 50, 255}; }
    static glm::u8vec4 textGray() { return {128, 128, 128, 255}; }

public:
    SystemStatusScreen(GuiContainer* owner);

    virtual void onDraw(sp::RenderTarget& target) override;
    virtual void onUpdate() override;
};
