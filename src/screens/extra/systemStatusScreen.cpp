#include "systemStatusScreen.h"
#include "playerInfo.h"
#include "gameGlobalInfo.h"
#include "i18n.h"

#include "components/reactor.h"
#include "components/coolant.h"
#include "components/beamweapon.h"
#include "components/hull.h"
#include "components/jumpdrive.h"
#include "components/warpdrive.h"
#include "components/shields.h"
#include "components/missiletubes.h"
#include "components/probe.h"
#include "components/comms.h"
#include "components/scanning.h"
#include "components/selfdestruct.h"
#include "components/target.h"
#include "components/maneuveringthrusters.h"
#include "components/docking.h"
#include "systems/missilesystem.h"

#include "screenComponents/alertOverlay.h"

#include "gui/gui2_panel.h"
#include "gui/gui2_label.h"
#include "gui/gui2_indicatorlight.h"

#include <cmath>
#include <limits>
#include <map>

SystemStatusScreen::SystemStatusScreen(GuiContainer* owner)
: GuiOverlay(owner, "SYSTEM_STATUS_SCREEN", colorConfig.background)
{
    // Background
    background_crosses = new GuiOverlay(this, "BACKGROUND_CROSSES", glm::u8vec4{255,255,255,255});
    background_crosses->setTextureTiled("gui/background/crosses.png");

    // Alert overlay
    (new AlertLevelOverlay(this));

    // Create indicator panels
    createSystemIndicators();
    createHullShieldIndicators();
    createEnergyIndicators();
    createWeaponIndicators();
    createSpecialIndicators();
}

void SystemStatusScreen::createSystemIndicators()
{
    const glm::vec2 button_size{60.0f, 30.0f};

    systems_panel = new GuiPanel(this, "SYSTEMS_PANEL");
    systems_panel
        ->setPosition(20.0f, 80.0f, sp::Alignment::TopLeft)
        ->setSize(500.0f, 400.0f);

    auto systems_container = new GuiElement(systems_panel, "SYSTEMS_CONTAINER");
    systems_container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setMargins(10.0f)
        ->setAttribute("layout", "vertical");

    (new GuiLabel(systems_container, "", tr("Ship systems"), 20.0f))
        ->setSize(GuiElement::GuiSizeMax, 30.0f);

    for (int n = 0; n < ShipSystem::COUNT; n++)
    {
        SystemIndicatorGroup group;

        group.container = new GuiElement(systems_container, "SYSTEM_ROW_" + string(n));
        group.container
            ->setSize(GuiElement::GuiSizeMax, 35.0f)
            ->setAttribute("layout", "horizontal");

        // System name label
        auto name_label = new GuiLabel(group.container, "", getLocaleSystemName(ShipSystem::Type(n)), 14.0f);
        name_label
            ->setAlignment(sp::Alignment::CenterLeft)
            ->setSize(120.0f, GuiElement::GuiSizeMax);

        // Power/heat/damage/hack indicators
        group.power_indicator = new GuiIndicatorLight(group.container, "SYS_PWR_" + string(n), true);
        group.power_indicator
            ->setLabel(tr("abbreviation_power", "PWR"), IndicatorContentPosition::Inside())
            ->setSize(button_size.x, button_size.y);

        group.heat_indicator = new GuiIndicatorLight(group.container, "SYS_HEAT_" + string(n), true);
        group.heat_indicator
            ->setLabel(tr("abbreviation_heat", "HEAT"), IndicatorContentPosition::Inside())
            ->setSize(button_size.x, button_size.y);

        group.damage_indicator = new GuiIndicatorLight(group.container, "SYS_DMG_" + string(n), true);
        group.damage_indicator
            ->setLabel(tr("abbreviation_damage", "DMG"), IndicatorContentPosition::Inside())
            ->setSize(button_size.x, button_size.y);

        group.hacked_indicator = new GuiIndicatorLight(group.container, "SYS_HACK_" + string(n), true);
        group.hacked_indicator
            ->setLabel(tr("abbreviation_hacked", "HACK"), IndicatorContentPosition::Inside())
            ->setSize(button_size.x, button_size.y);

        system_indicators.push_back(group);
    }
}

void SystemStatusScreen::createHullShieldIndicators()
{
    hull_shields_panel = new GuiPanel(this, "HULL_SHIELDS_PANEL");
    hull_shields_panel
        ->setPosition(20.0f, 500.0f, sp::Alignment::TopLeft)
        ->setSize(280.0f, 250.0f);

    auto container = new GuiElement(hull_shields_panel, "HULL_SHIELDS_CONTAINER");
    container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setMargins(10.0f)
        ->setAttribute("layout", "vertical");

    (new GuiLabel(container, "", tr("Hull and shields"), 20.0f))
        ->setSize(GuiElement::GuiSizeMax, 30.0f);

    // Shield diamond container - using absolute positioning for diamond layout
    // Hull indicator will be placed in the center
    shield_diamond_container = new GuiElement(container, "SHIELD_DIAMOND");
    shield_diamond_container->setSize(200.0f, 160.0f);

    // Hull indicator in center of diamond
    float container_w = 200.0f;
    float container_h = 160.0f;
    float cx = container_w / 2.0f;
    float cy = container_h / 2.0f;

    hull_indicator = new GuiIndicatorLight(shield_diamond_container, "HULL_IND", true);
    hull_indicator
        ->setLabel(tr("abbreviation_hull", "HULL"), IndicatorContentPosition::Inside())
        ->setSize(60.0f, 30.0f);
    hull_indicator->setPosition(cx - 30.0f, cy - 15.0f, sp::Alignment::TopLeft);

    // Shield indicators will be created dynamically based on ship's shield count
    // Positions for diamond layout (relative to container center):
    // Front (0): top center
    // Right (1): middle right
    // Rear (2): bottom center
    // Left (3): middle left
}

void SystemStatusScreen::createEnergyIndicators()
{
    const glm::vec2 button_size{100.0f, 30.0f};

    energy_panel = new GuiPanel(this, "ENERGY_PANEL");
    energy_panel
        ->setPosition(310.0f, 500.0f, sp::Alignment::TopLeft)
        ->setSize(200.0f, 180.0f);

    auto container = new GuiElement(energy_panel, "ENERGY_CONTAINER");
    container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setMargins(10.0f)
        ->setAttribute("layout", "vertical");

    (new GuiLabel(container, "", tr("Energy"), 20.0f))
        ->setSize(GuiElement::GuiSizeMax, 30.0f);

    auto row = new GuiElement(container, "");
    row
        ->setSize(GuiElement::GuiSizeMax, 40.0f)
        ->setAttribute("layout", "horizontal");

    energy_indicator = new GuiIndicatorLight(row, "ENERGY_IND", true);
    energy_indicator
        ->setLabel(tr("abbreviation_energy_storage", "STORE"), IndicatorContentPosition::Inside())
        ->setSize(button_size.x, button_size.y);

    auto row2 = new GuiElement(container, "");
    row2
        ->setSize(GuiElement::GuiSizeMax, 40.0f)
        ->setAttribute("layout", "horizontal");

    energy_rate_indicator = new GuiIndicatorLight(row2, "ENERGY_RATE_IND", true);
    energy_rate_indicator
        ->setLabel(tr("abbreviation_energy_delta", "RATE"), IndicatorContentPosition::Inside())
        ->setSize(button_size.x, button_size.y);
}

void SystemStatusScreen::createWeaponIndicators()
{
    const glm::vec2 button_size{50.0f, 30.0f};

    weapons_panel = new GuiPanel(this, "WEAPONS_PANEL");
    weapons_panel
        ->setPosition(540.0f, 80.0f, sp::Alignment::TopLeft)
        ->setSize(450.0f, 600.0f);

    auto container = new GuiElement(weapons_panel, "WEAPONS_CONTAINER");
    container->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    container->setAttribute("layout", "vertical");
    container->setMargins(10.0f);

    // Missile tubes section (includes storage as first row)
    missiles_section_label = new GuiLabel(container, "", tr("Missile Tubes"), 20);
    missiles_section_label->setSize(GuiElement::GuiSizeMax, 30);

    // Header row for tube indicators
    missiles_header_row = new GuiElement(container, "TUBES_HEADER");
    missiles_header_row
        ->setSize(GuiElement::GuiSizeMax, 25.0f)
        ->setAttribute("layout", "horizontal");

    auto angle_header = new GuiLabel(missiles_header_row, "", "", 12.0f);
    angle_header->setSize(50.0f, GuiElement::GuiSizeMax);
    angle_header->setAlignment(sp::Alignment::Center);

    string weapon_labels[] = {"HOM", "NUK", "MIN", "EMP", "HVL"};
    for (int n = 0; n < MW_Count; n++)
    {
        auto wpn_header = new GuiLabel(missiles_header_row, "", weapon_labels[n], 10.0f);
        wpn_header->setSize(button_size.x, GuiElement::GuiSizeMax);
        wpn_header->setAlignment(sp::Alignment::Center);
    }

    // Tubes container - storage row + dynamic tube rows
    tubes_container = new GuiElement(container, "TUBES_CONTAINER");
    tubes_container
        ->setSize(GuiElement::GuiSizeMax, 250.0f)
        ->setAttribute("layout", "vertical");

    // Storage row (first row of tubes section, labeled "STOCK")
    missiles_storage_row = new GuiElement(tubes_container, "STORAGE_ROW");
    missiles_storage_row
        ->setSize(GuiElement::GuiSizeMax, 32.0f)
        ->setAttribute("layout", "horizontal");

    auto stock_label = new GuiLabel(missiles_storage_row, "", tr("STOCK"), 12.0f);
    stock_label->setSize(50.0f, GuiElement::GuiSizeMax);
    stock_label->setAlignment(sp::Alignment::Center);

    for (int n = 0; n < MW_Count; n++)
    {
        WeaponStorageIndicator wsi;
        wsi.indicator = new GuiIndicatorLight(missiles_storage_row, "STORAGE_" + string(n), true);
        wsi.indicator
            ->setLabel(weapon_labels[n], IndicatorContentPosition::Inside())
            ->setSize(button_size.x, button_size.y);
        weapon_storage_indicators.push_back(wsi);
    }

    // Probe storage (separate row)
    auto probe_row = new GuiElement(container, "PROBE_ROW");
    probe_row
        ->setSize(GuiElement::GuiSizeMax, 40.0f)
        ->setAttribute("layout", "horizontal");

    probe_indicator = new GuiIndicatorLight(probe_row, "PROBE_IND", true);
    probe_indicator
        ->setLabel(tr("PROBE"), IndicatorContentPosition::Inside())
        ->setSize(button_size.x, button_size.y);

    // Beam indicators section
    beams_section_label = new GuiLabel(container, "", tr("Beams"), 16.0f);
    beams_section_label->setSize(GuiElement::GuiSizeMax, 25.0f);

    beams_container = new GuiElement(container, "BEAMS_CONTAINER");
    beams_container
        ->setSize(GuiElement::GuiSizeMax, 150.0f)
        ->setAttribute("layout", "vertical");
}

void SystemStatusScreen::createSpecialIndicators()
{
    const glm::vec2 button_size{70.0f, 30.0f};

    special_panel = new GuiPanel(this, "SPECIAL_PANEL");
    special_panel
        ->setPosition(520.0f, 700.0f, sp::Alignment::TopLeft)
        ->setSize(470.0f, 180.0f);

    auto container = new GuiElement(special_panel, "SPECIAL_CONTAINER");
    container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setMargins(10.0f)
        ->setAttribute("layout", "vertical");

    (new GuiLabel(container, "", tr("System activity"), 20.0f))
        ->setSize(GuiElement::GuiSizeMax, 30.0f);

    // Row 1: Jump, Warp, Comms, Scan
    auto row1 = new GuiElement(container, "SPECIAL_ROW1");
    row1
        ->setSize(GuiElement::GuiSizeMax, 35.0f)
        ->setAttribute("layout", "horizontal");

    jump_indicator = new GuiIndicatorLight(row1, "JUMP_IND", true);
    jump_indicator
        ->setLabel(tr("abbreviation_jump", "JUMP"), IndicatorContentPosition::Inside())
        ->setSize(button_size.x, button_size.y);

    warp_indicator = new GuiIndicatorLight(row1, "WARP_IND", true);
    warp_indicator
        ->setLabel(tr("abbreviation_warp", "WARP"), IndicatorContentPosition::Inside())
        ->setSize(button_size.x, button_size.y);

    comms_indicator = new GuiIndicatorLight(row1, "COMMS_IND", true);
    comms_indicator
        ->setLabel(tr("abbreviation_communications", "COMM"), IndicatorContentPosition::Inside())
        ->setSize(button_size.x, button_size.y);

    scan_indicator = new GuiIndicatorLight(row1, "SCAN_IND", true);
    scan_indicator
        ->setLabel(tr("abbreviation_scan", "SCAN"), IndicatorContentPosition::Inside())
        ->setSize(button_size.x, button_size.y);

    // Row 2: Self-destruct, Targeting, Combat Maneuver
    auto row2 = new GuiElement(container, "SPECIAL_ROW2");
    row2
        ->setSize(GuiElement::GuiSizeMax, 35.0f)
        ->setAttribute("layout", "horizontal");

    selfdestruct_indicator = new GuiIndicatorLight(row2, "SELF_DESTRUCT_IND", true);
    selfdestruct_indicator
        ->setLabel(tr("abbreviation_self_destruct", "SCUT"), IndicatorContentPosition::Inside())
        ->setSize(button_size.x, button_size.y);

    target_indicator = new GuiIndicatorLight(row2, "TARGET_IND", true);
    target_indicator
        ->setLabel(tr("abbreviation_target", "TGT"), IndicatorContentPosition::Inside())
        ->setSize(button_size.x, button_size.y);

    boost_indicator = new GuiIndicatorLight(row2, "BOOST_IND", true);
    boost_indicator
        ->setLabel(tr("abbreviation_combat_manuever", "BOOST"), IndicatorContentPosition::Inside())
        ->setSize(button_size.x, button_size.y);

    dock_indicator = new GuiIndicatorLight(row2, "DOCK_IND", true);
    dock_indicator
        ->setLabel(tr("abbreviation_docking", "DOCK"), IndicatorContentPosition::Inside())
        ->setSize(button_size.x, button_size.y);
}

void SystemStatusScreen::onDraw(sp::RenderTarget& target)
{
    GuiOverlay::onDraw(target);
}

void SystemStatusScreen::onUpdate()
{
    if (!my_spaceship || !isVisible())
        return;

    update_timer += 0.016f; // Approximate frame time
    if (update_timer >= UPDATE_INTERVAL)
    {
        update_timer -= UPDATE_INTERVAL;

        updateSystemIndicators();
        updateHullShieldIndicators();
        updateEnergyIndicators();
        updateWeaponIndicators();
        updateSpecialIndicators();
    }
}

IndicatorStatusLevel SystemStatusScreen::calculateStatusLevel(float value, float max_value, const TrackedValue& tracked, bool invert_direction)
{
    if (max_value <= 0.0f) max_value = 1.0f;
    float ratio = value / max_value;
    float degradation = 1.0f - ratio;

    bool improving = invert_direction ? tracked.declining() : tracked.improving();
    bool declining = invert_direction ? tracked.improving() : tracked.declining();

    if (ratio >= 0.9999f)
        return IndicatorStatusLevel::Nominal;
    else if (ratio <= 0.0001f)
        return IndicatorStatusLevel::Critical;
    else if (degradation >= 0.50f)
    {
        if (declining) return IndicatorStatusLevel::SevereDeclining;
        else if (improving) return IndicatorStatusLevel::SevereImproving;
        else return IndicatorStatusLevel::SevereStable;
    }
    else if (degradation >= 0.20f)
    {
        if (declining) return IndicatorStatusLevel::SignificantDeclining;
        else if (improving) return IndicatorStatusLevel::SignificantImproving;
        else return IndicatorStatusLevel::SignificantStable;
    }
    else
    {
        if (declining) return IndicatorStatusLevel::DegradedDeclining;
        else if (improving) return IndicatorStatusLevel::DegradedImproving;
        else return IndicatorStatusLevel::DegradedStable;
    }
}

void SystemStatusScreen::applyIndicatorStyle(GuiIndicatorLight* indicator, IndicatorStatusLevel level, const string& label)
{
    indicator->setLabel(label, IndicatorContentPosition::Inside());
    indicator->clearTextColor();  // Clear any previous text color override

    switch (level)
    {
    case IndicatorStatusLevel::Nominal:
        indicator->setValue(true);
        indicator->setActiveColor(colorGreen());
        indicator->setBlink(false);
        break;
    case IndicatorStatusLevel::DegradedImproving:
        indicator->setValue(true);
        indicator->setActiveColor(colorGreen());
        indicator->setBlink(true, 0.5f);
        break;
    case IndicatorStatusLevel::DegradedStable:
        indicator->setValue(true);
        indicator->setActiveColor(colorYellow());
        indicator->setBlink(false);
        break;
    case IndicatorStatusLevel::DegradedDeclining:
        indicator->setValue(true);
        indicator->setActiveColor(colorYellow());
        indicator->setBlink(true, 0.25f);
        break;
    case IndicatorStatusLevel::SignificantStable:
        indicator->setValue(true);
        indicator->setActiveColor(colorOrange());
        indicator->setBlink(false);
        break;
    case IndicatorStatusLevel::SignificantDeclining:
        indicator->setValue(true);
        indicator->setActiveColor(colorOrange());
        indicator->setBlink(true, 0.25f);
        break;
    case IndicatorStatusLevel::SignificantImproving:
        indicator->setValue(true);
        indicator->setActiveColor(colorOrange());
        indicator->setBlink(true, 0.5f);
        break;
    case IndicatorStatusLevel::SevereStable:
        indicator->setValue(true);
        indicator->setActiveColor(colorDarkRed());
        indicator->setBlink(false);
        break;
    case IndicatorStatusLevel::SevereDeclining:
        indicator->setValue(true);
        indicator->setActiveColor(colorDarkRed());
        indicator->setBlink(true, 0.25f);
        break;
    case IndicatorStatusLevel::SevereImproving:
        indicator->setValue(true);
        indicator->setActiveColor(colorDarkRed());
        indicator->setBlink(true, 0.5f);
        break;
    case IndicatorStatusLevel::Critical:
        indicator->setValue(true);
        indicator->setActiveColor(colorBrightRed());
        indicator->setBlink(true, 0.1f);
        break;
    case IndicatorStatusLevel::Unpowered:
        // Black background, red text, blinking
        indicator->setValue(true);
        indicator->setActiveColor(colorBlack());
        indicator->setTextColor(textOrange());
        indicator->setBlink(true, 0.5f);
        break;
    case IndicatorStatusLevel::UnpoweredNoEnergy:
        // Black background, gray text, no blink
        indicator->setValue(true);
        indicator->setActiveColor(colorBlack());
        indicator->setTextColor(textGray());
        indicator->setBlink(false);
        break;
    case IndicatorStatusLevel::Empty:
        indicator->setValue(true);
        indicator->setActiveColor(colorBlack());
        indicator->setBlink(false);
        break;
    }
}

void SystemStatusScreen::applyHeatIndicatorStyle(GuiIndicatorLight* indicator, float heat, float heat_delta)
{
    indicator->clearTextColor();  // Clear any previous text color override

    if (heat <= 0.001f)
    {
        indicator->setValue(true);
        indicator->setActiveColor(colorGreen());
        indicator->setBlink(false);
        return;
    }

    bool is_critical = heat >= 0.99f;
    bool is_severe = heat >= 0.80f;
    bool is_significant = heat >= 0.50f;
    bool is_degraded = heat >= 0.20f;

    bool is_improving = heat_delta < -0.001f;
    bool is_declining = heat_delta > 0.001f;

    if (is_critical && is_declining)
    {
        indicator->setValue(true);
        indicator->setActiveColor(colorBrightRed());
        indicator->setBlink(true, 0.1f);
        return;
    }

    if (is_severe)
    {
        indicator->setValue(true);
        indicator->setActiveColor(colorDarkRed());
        if (is_declining) indicator->setBlink(true, 0.25f);
        else if (is_improving) indicator->setBlink(true, 0.5f);
        else indicator->setBlink(false);
    }
    else if (is_significant)
    {
        indicator->setValue(true);
        indicator->setActiveColor(colorOrange());
        if (is_declining) indicator->setBlink(true, 0.25f);
        else if (is_improving) indicator->setBlink(true, 0.5f);
        else indicator->setBlink(false);
    }
    else if (is_degraded)
    {
        indicator->setValue(true);
        indicator->setActiveColor(colorYellow());
        if (is_declining) indicator->setBlink(true, 0.25f);
        else if (is_improving) indicator->setBlink(true, 0.5f);
        else indicator->setBlink(false);
    }
    else
    {
        indicator->setValue(true);
        indicator->setActiveColor(colorGreen());
        if (is_declining) indicator->setBlink(true, 0.5f);
        else indicator->setBlink(false);
    }
}

void SystemStatusScreen::applyShieldIndicatorStyle(GuiIndicatorLight* indicator, float level, float max_level, bool shields_up, const TrackedValue& tracked)
{
    if (max_level <= 0.0f) max_level = 1.0f;
    float ratio = level / max_level;

    // Determine color based on shield percentage
    glm::u8vec4 status_color;
    if (ratio >= 0.80f)
        status_color = colorGreen();
    else if (ratio >= 0.50f)
        status_color = colorYellow();
    else if (ratio >= 0.20f)
        status_color = colorOrange();
    else
        status_color = colorBrightRed();

    // Determine blink based on change
    bool blink = false;
    float blink_interval = 0.5f;
    if (tracked.declining())
    {
        blink = true;
        blink_interval = 0.25f;
    }
    else if (tracked.improving())
    {
        blink = true;
        blink_interval = 0.5f;
    }

    if (shields_up)
    {
        // Shields up: colored background, white text
        indicator->setValue(true);
        indicator->setActiveColor(status_color);
        indicator->clearTextColor();
        indicator->setBlink(blink, blink_interval);
    }
    else
    {
        // Shields down: black background, colored text
        indicator->setValue(true);
        indicator->setActiveColor(colorBlack());
        indicator->setTextColor(status_color);
        indicator->setBlink(blink, blink_interval);
    }
}

void SystemStatusScreen::applyTubeTypeIndicatorStyle(GuiIndicatorLight* indicator, bool is_loaded, MissileTubes::MountPoint::State tube_state, bool can_fire, const string& label)
{
    indicator->setLabel(label, IndicatorContentPosition::Inside());
    indicator->clearTextColor();  // Clear any previous text color override

    if (!is_loaded)
    {
        // Not loaded: black background, white text
        indicator->setValue(true);
        indicator->setActiveColor(colorBlack());
        indicator->setBlink(false);
        return;
    }

    // This type is loaded
    switch (tube_state)
    {
    case MissileTubes::MountPoint::State::Loaded:
        if (can_fire)
        {
            // Ready to fire: green, white text
            indicator->setValue(true);
            indicator->setActiveColor(colorGreen());
            indicator->setBlink(false);
        }
        else
        {
            // Loaded but cannot fire: red, flashing
            indicator->setValue(true);
            indicator->setActiveColor(colorBrightRed());
            indicator->setBlink(true, 0.25f);
        }
        break;

    case MissileTubes::MountPoint::State::Loading:
        // Loading: yellow, white text
        indicator->setValue(true);
        indicator->setActiveColor(colorYellow());
        indicator->setBlink(false);
        break;

    case MissileTubes::MountPoint::State::Firing:
        // Firing (HVLI): yellow, flashing
        indicator->setValue(true);
        indicator->setActiveColor(colorYellow());
        indicator->setBlink(true, 0.25f);
        break;

    case MissileTubes::MountPoint::State::Unloading:
        // Unloading: orange, flashing
        indicator->setValue(true);
        indicator->setActiveColor(colorOrange());
        indicator->setBlink(true, 0.25f);
        break;

    case MissileTubes::MountPoint::State::Empty:
    default:
        indicator->setValue(true);
        indicator->setActiveColor(colorBlack());
        indicator->setBlink(false);
        break;
    }
}

void SystemStatusScreen::updateSystemIndicators()
{
    for (int n = 0; n < ShipSystem::COUNT && n < static_cast<int>(system_indicators.size()); n++)
    {
        auto& group = system_indicators[n];
        auto sys = ShipSystem::get(my_spaceship, ShipSystem::Type(n));

        if (!sys)
        {
            group.container->hide();
            continue;
        }

        group.container->show();

        // Power indicator - only values < 100% are considered degraded
        float power = sys->power_level;
        group.power_value.update(power);

        IndicatorStatusLevel power_level;
        if (power < 0.01f)
        {
            auto reactor = my_spaceship.getComponent<Reactor>();
            float energy_ratio = reactor ? (reactor->energy / reactor->max_energy) : 0.0f;
            power_level = (energy_ratio < 0.05f) ? IndicatorStatusLevel::UnpoweredNoEnergy : IndicatorStatusLevel::Unpowered;
        }
        else if (power >= 1.0f)
        {
            // 100% or higher is nominal
            power_level = IndicatorStatusLevel::Nominal;
        }
        else
        {
            // Below 100% - calculate degradation level
            power_level = calculateStatusLevel(power, 1.0f, group.power_value);
        }
        applyIndicatorStyle(group.power_indicator, power_level, tr("PWR"));

        // Heat indicator (inverted - high is bad)
        float heat = sys->heat_level;
        float prev_heat = group.heat_value.current;
        group.heat_value.update(heat);
        applyHeatIndicatorStyle(group.heat_indicator, heat, heat - prev_heat);

        // Damage indicator
        float health = sys->health;
        group.damage_value.update(health);
        auto damage_level = calculateStatusLevel(health, 1.0f, group.damage_value);
        applyIndicatorStyle(group.damage_indicator, damage_level, tr("DMG"));

        // Hacked indicator
        float hacked = sys->hacked_level;
        group.hacked_value.update(1.0f - hacked);
        if (hacked < 0.01f)
        {
            group.hacked_indicator->setValue(true);
            group.hacked_indicator->setActiveColor(colorGreen());
            group.hacked_indicator->setBlink(false);
        }
        else
        {
            auto hack_level = calculateStatusLevel(1.0f - hacked, 1.0f, group.hacked_value);
            applyIndicatorStyle(group.hacked_indicator, hack_level, tr("HACK"));
        }
    }
}

void SystemStatusScreen::updateHullShieldIndicators()
{
    // Hull indicator
    if (auto hull = my_spaceship.getComponent<Hull>())
    {
        float ratio = hull->current / hull->max;
        hull_value.update(ratio);
        auto level = calculateStatusLevel(hull->current, hull->max, hull_value);
        applyIndicatorStyle(hull_indicator, level, tr("HULL"));
        hull_indicator->show();
    }
    else
    {
        hull_indicator->hide();
    }

    // Shield indicators
    auto shields = my_spaceship.getComponent<Shields>();
    if (!shields || shields->entries.empty())
    {
        for (auto& si : shield_indicators)
        {
            if (si.indicator) si.indicator->hide();
        }
        return;
    }

    bool shields_up = shields->active;
    size_t num_shields = shields->entries.size();

    // Create shield indicators if needed
    while (shield_indicators.size() < num_shields)
    {
        ShieldSegmentIndicator ssi;
        ssi.segment_index = static_cast<int>(shield_indicators.size());
        ssi.indicator = new GuiIndicatorLight(shield_diamond_container, "SHIELD_" + string(ssi.segment_index), true);
        ssi.indicator->setSize(60.0f, 30.0f);

        // Position in diamond layout around center (where hull indicator is)
        // For 2 shields: front at top, rear at bottom
        // For 4 shields: front top, right right, rear bottom, left left
        float container_w = 200.0f;
        float container_h = 160.0f;
        float cx = container_w / 2.0f;
        float cy = container_h / 2.0f;

        if (num_shields == 2)
        {
            if (ssi.segment_index == 0) // Front
                ssi.indicator->setPosition(cx - 30.0f, 5.0f, sp::Alignment::TopLeft);
            else // Rear
                ssi.indicator->setPosition(cx - 30.0f, container_h - 35.0f, sp::Alignment::TopLeft);
        }
        else if (num_shields >= 4)
        {
            switch (ssi.segment_index)
            {
            case 0: // Front
                ssi.indicator->setPosition(cx - 30.0f, 5.0f, sp::Alignment::TopLeft);
                break;
            case 1: // Right
                ssi.indicator->setPosition(container_w - 65.0f, cy - 15.0f, sp::Alignment::TopLeft);
                break;
            case 2: // Rear
                ssi.indicator->setPosition(cx - 30.0f, container_h - 35.0f, sp::Alignment::TopLeft);
                break;
            case 3: // Left
                ssi.indicator->setPosition(5.0f, cy - 15.0f, sp::Alignment::TopLeft);
                break;
            default:
                ssi.indicator->setPosition(cx - 30.0f, cy - 15.0f, sp::Alignment::TopLeft);
                break;
            }
        }

        shield_indicators.push_back(ssi);
    }

    // Update shield indicators
    // Labels depend on shield count: 2 shields = front/rear, 4+ = front/starboard/aft/port
    for (size_t i = 0; i < num_shields && i < shield_indicators.size(); i++)
    {
        auto& ssi = shield_indicators[i];
        auto& entry = shields->entries[i];

        float ratio = entry.max > 0.0f ? entry.level / entry.max : 0.0f;
        ssi.value.update(ratio);

        string label;
        if (num_shields == 2)
        {
            // 2-shield config: front and rear
            const char* labels_2[] = {"FWD", "AFT"};
            label = (i < 2) ? labels_2[i] : ("S" + string(int(i)));
        }
        else
        {
            // 4+ shield config: front, starboard, aft, port
            const char* labels_4[] = {"FWD", "STBD", "AFT", "PORT"};
            label = (i < 4) ? labels_4[i] : ("S" + string(int(i)));
        }
        ssi.indicator->setLabel(label, IndicatorContentPosition::Inside());

        applyShieldIndicatorStyle(ssi.indicator, entry.level, entry.max, shields_up, ssi.value);
        ssi.indicator->show();
    }

    // Hide extra indicators
    for (size_t i = num_shields; i < shield_indicators.size(); i++)
    {
        shield_indicators[i].indicator->hide();
    }
}

void SystemStatusScreen::updateEnergyIndicators()
{
    auto reactor = my_spaceship.getComponent<Reactor>();
    if (!reactor)
    {
        energy_indicator->hide();
        energy_rate_indicator->hide();
        return;
    }

    // Energy storage level
    float ratio = reactor->energy / reactor->max_energy;
    energy_value.update(ratio);
    auto level = calculateStatusLevel(reactor->energy, reactor->max_energy, energy_value);
    applyIndicatorStyle(energy_indicator, level, tr("STORE"));
    energy_indicator->show();

    // Energy rate - show generation vs consumption
    // Green solid if rate >= 0 (charging or stable)
    // Black with red text if rate = 0 and energy = 0
    // Black with green text if rate = 0 and energy = max
    energy_rate_value.update(ratio);
    energy_rate_indicator->clearTextColor();

    if (energy_rate_value.improving())
    {
        // Charging - green solid
        energy_rate_indicator->setValue(true);
        energy_rate_indicator->setActiveColor(colorGreen());
        energy_rate_indicator->setBlink(false);
    }
    else if (energy_rate_value.declining())
    {
        // Draining - orange with blink
        energy_rate_indicator->setValue(true);
        energy_rate_indicator->setActiveColor(colorOrange());
        energy_rate_indicator->setBlink(true, 0.5f);
    }
    else
    {
        // Stable - check if at extremes
        if (ratio <= 0.01f)
        {
            // Empty and stable - black with red text
            energy_rate_indicator->setValue(true);
            energy_rate_indicator->setActiveColor(colorBlack());
            energy_rate_indicator->setTextColor(textRed());
            energy_rate_indicator->setBlink(false);
        }
        else if (ratio >= 0.99f)
        {
            // Full and stable - black with green text
            energy_rate_indicator->setValue(true);
            energy_rate_indicator->setActiveColor(colorBlack());
            energy_rate_indicator->setTextColor(colorGreen());
            energy_rate_indicator->setBlink(false);
        }
        else
        {
            // Stable in middle - green solid
            energy_rate_indicator->setValue(true);
            energy_rate_indicator->setActiveColor(colorGreen());
            energy_rate_indicator->setBlink(false);
        }
    }
    energy_rate_indicator->setLabel(tr("RATE"), IndicatorContentPosition::Inside());
    energy_rate_indicator->show();
}

void SystemStatusScreen::updateWeaponIndicators()
{
    auto tubes = my_spaceship.getComponent<MissileTubes>();
    bool has_tubes = tubes && !tubes->mounts.empty();

    // Show/hide entire missile section based on whether ship has tubes
    if (missiles_section_label) missiles_section_label->setVisible(has_tubes);
    if (missiles_header_row) missiles_header_row->setVisible(has_tubes);
    if (missiles_storage_row) missiles_storage_row->setVisible(has_tubes);
    if (tubes_container) tubes_container->setVisible(has_tubes);

    // Update weapon storage indicators
    if (has_tubes)
    {
        for (int n = 0; n < MW_Count && n < static_cast<int>(weapon_storage_indicators.size()); n++)
        {
            auto& wsi = weapon_storage_indicators[n];
            int count = tubes->storage[n];
            int max_count = tubes->storage_max[n];

            if (max_count <= 0)
            {
                wsi.indicator->hide();
                continue;
            }

            float ratio = static_cast<float>(count) / static_cast<float>(max_count);
            wsi.value.update(ratio);

            string label = string(count);
            if (count == 0)
            {
                applyIndicatorStyle(wsi.indicator, IndicatorStatusLevel::Empty, label);
            }
            else
            {
                auto level = calculateStatusLevel(static_cast<float>(count), static_cast<float>(max_count), wsi.value);
                applyIndicatorStyle(wsi.indicator, level, label);
            }
            wsi.indicator->show();
        }

        // Update tube indicators
        auto missile_sys = ShipSystem::get(my_spaceship, ShipSystem::Type::MissileSystem);
        bool system_can_fire = missile_sys && missile_sys->getSystemEffectiveness() > 0.0f;

        auto reactor = my_spaceship.getComponent<Reactor>();
        bool has_energy = reactor && (reactor->energy / reactor->max_energy) > 0.01f;

        // Create tube rows if needed
        while (tube_indicators.size() < tubes->mounts.size())
        {
            TubeIndicatorRow row;
            row.container = new GuiElement(tubes_container, "TUBE_ROW_" + string(int(tube_indicators.size())));
            row.container
                ->setSize(GuiElement::GuiSizeMax, 32.0f)
                ->setAttribute("layout", "horizontal");

            row.angle_label = new GuiLabel(row.container, "", "", 12.0f);
            row.angle_label->setSize(50.0f, GuiElement::GuiSizeMax);
            row.angle_label->setAlignment(sp::Alignment::Center);

            string weapon_labels[] = {"HOM", "NUK", "MIN", "EMP", "HVL"};
            for (int n = 0; n < MW_Count; n++)
            {
                row.type_indicators[n] = new GuiIndicatorLight(row.container, "TUBE_" + string(int(tube_indicators.size())) + "_" + string(n), true);
                row.type_indicators[n]
                    ->setLabel(weapon_labels[n], IndicatorContentPosition::Inside())
                    ->setSize(50.0f, 28.0f);
            }

            tube_indicators.push_back(row);
        }

        // Update each tube row
        for (size_t i = 0; i < tubes->mounts.size() && i < tube_indicators.size(); i++)
        {
            auto& mount = tubes->mounts[i];
            auto& row = tube_indicators[i];

            // Angle label
            int angle_deg = static_cast<int>(mount.direction);
            row.angle_label->setText(string(angle_deg) + "°");

            // Determine if tube can fire
            bool can_fire = system_can_fire && has_energy && mount.state == MissileTubes::MountPoint::State::Loaded;

            // Update each type indicator
            string weapon_labels[] = {"HOM", "NUK", "MIN", "EMP", "HVL"};
            for (int n = 0; n < MW_Count; n++)
            {
                bool is_loaded = (mount.type_loaded == static_cast<EMissileWeapons>(n));
                applyTubeTypeIndicatorStyle(row.type_indicators[n], is_loaded, mount.state, can_fire, weapon_labels[n]);
            }

            row.container->show();
        }

        // Hide extra tube rows
        for (size_t i = tubes->mounts.size(); i < tube_indicators.size(); i++)
        {
            tube_indicators[i].container->hide();
        }
    }
    else
    {
        for (auto& wsi : weapon_storage_indicators)
            wsi.indicator->hide();
        for (auto& row : tube_indicators)
            row.container->hide();
    }

    // Update probe indicator
    if (auto probes = my_spaceship.getComponent<ScanProbeLauncher>())
    {
        float ratio = static_cast<float>(probes->stock) / static_cast<float>(probes->max);
        probe_value.update(ratio);

        string label = string(probes->stock);
        if (probes->stock == 0)
        {
            applyIndicatorStyle(probe_indicator, IndicatorStatusLevel::Empty, label);
        }
        else
        {
            auto level = calculateStatusLevel(static_cast<float>(probes->stock), static_cast<float>(probes->max), probe_value);
            applyIndicatorStyle(probe_indicator, level, label);
        }
        probe_indicator->show();
    }
    else
    {
        probe_indicator->hide();
    }

    // Update beam indicators - organized by angle similar to missiles
    auto beams = my_spaceship.getComponent<BeamWeaponSys>();
    bool has_beams = beams && !beams->mounts.empty();

    // Show/hide entire beam section based on whether ship has beams
    if (beams_section_label) beams_section_label->setVisible(has_beams);
    if (beams_container) beams_container->setVisible(has_beams);

    if (has_beams && beams_container)
    {
        auto reactor = my_spaceship.getComponent<Reactor>();
        float ship_energy_ratio = reactor ? (reactor->energy / reactor->max_energy) : 0.0f;
        float beam_effectiveness = beams->getSystemEffectiveness();

        // Group beams by angle (rounded to nearest 10 degrees for grouping)
        std::map<int, std::vector<size_t>> beams_by_angle;
        for (size_t i = 0; i < beams->mounts.size(); i++)
        {
            int angle = static_cast<int>(beams->mounts[i].direction);
            // Round to nearest 10 degrees for grouping similar angles
            int angle_group = ((angle + 5) / 10) * 10;
            beams_by_angle[angle_group].push_back(i);
        }

        // Create beam indicators if needed (one per beam mount)
        while (beam_indicators.size() < beams->mounts.size())
        {
            BeamIndicator bi;
            bi.indicator = new GuiIndicatorLight(beams_container,
                "BEAM_" + string(int(beam_indicators.size())), true);
            bi.indicator->setSize(40, 30);
            beam_indicators.push_back(bi);
        }

        // Clear existing layout - we'll rebuild based on angle groups
        // First, collect all beam indicators that need to be repositioned
        size_t indicator_idx = 0;

        // Create/update rows for each angle group
        for (auto& [angle, beam_indices] : beams_by_angle)
        {
            for (size_t local_idx = 0; local_idx < beam_indices.size(); local_idx++)
            {
                size_t mount_idx = beam_indices[local_idx];
                if (indicator_idx >= beam_indicators.size()) break;

                auto& mount = beams->mounts[mount_idx];
                auto& bi = beam_indicators[indicator_idx];

                bi.cooldown_value.update(mount.cooldown);

                bool can_fire = beam_effectiveness > 0.0f && ship_energy_ratio > 0.01f;

                if (!can_fire)
                {
                    bi.indicator->setValue(true);
                    bi.indicator->setActiveColor(colorBrightRed());
                    bi.indicator->setBlink(false);
                }
                else if (mount.cooldown > 0.01f)
                {
                    bi.indicator->setValue(true);
                    bi.indicator->setActiveColor(colorOrange());
                    bi.indicator->setBlink(true, 0.25f);
                }
                else
                {
                    bi.indicator->setValue(true);
                    bi.indicator->setActiveColor(colorGreen());
                    bi.indicator->setBlink(false);
                }

                // Label shows angle and beam number within that angle group
                string label = string(static_cast<int>(mount.direction)) + "°";
                if (beam_indices.size() > 1)
                {
                    label = string(int(local_idx + 1));
                }
                bi.indicator->setLabel(label, IndicatorContentPosition::Inside());
                bi.indicator->show();

                indicator_idx++;
            }
        }

        // Hide unused indicators
        for (size_t i = indicator_idx; i < beam_indicators.size(); i++)
            beam_indicators[i].indicator->hide();
    }
    else
    {
        for (auto& bi : beam_indicators)
            bi.indicator->hide();
    }
}

void SystemStatusScreen::updateSpecialIndicators()
{
    // Jump drive
    if (auto jump = my_spaceship.getComponent<JumpDrive>())
    {
        float effectiveness = jump->getSystemEffectiveness();
        float charge_ratio = jump->max_distance > 0.0f ? jump->charge / jump->max_distance : 0.0f;
        int delay = static_cast<int>(jump->delay);

        if (effectiveness <= 0.0f)
        {
            // Cannot jump - system damaged
            jump_indicator->setValue(true);
            jump_indicator->setActiveColor(colorBrightRed());
            jump_indicator->setBlink(false);
            jump_indicator->setLabel(tr("JUMP"), IndicatorContentPosition::Inside());
        }
        else if (delay > 0)
        {
            // Preparing to jump - flash rate proportional to time remaining
            // 10 seconds = slowest (1.0s period), approaching 0 = fastest (0.1s period)
            float period = 0.1f + (static_cast<float>(delay) / 10.0f) * 0.9f;
            if (period > 1.0f) period = 1.0f;

            jump_indicator->setValue(true);
            jump_indicator->setActiveColor(colorYellow());
            jump_indicator->setBlink(true, period);
            jump_indicator->setLabel(tr("JUMP"), IndicatorContentPosition::Inside());
        }
        else if (charge_ratio < 0.99f)
        {
            // Recharging - use orange with slow blink, no percentage
            jump_indicator->setValue(true);
            jump_indicator->setActiveColor(colorOrange());
            jump_indicator->setBlink(true, 1.0f);
            jump_indicator->setLabel(tr("JUMP"), IndicatorContentPosition::Inside());
        }
        else
        {
            // Ready to jump
            jump_indicator->setValue(true);
            jump_indicator->setActiveColor(colorGreen());
            jump_indicator->setBlink(false);
            jump_indicator->setLabel(tr("JUMP"), IndicatorContentPosition::Inside());
        }
        jump_indicator->show();
    }
    else
    {
        jump_indicator->hide();
    }

    // Warp drive
    if (auto warp = my_spaceship.getComponent<WarpDrive>())
    {
        int warp_level = static_cast<int>(warp->current);

        switch (warp_level)
        {
        case 0:
            warp_indicator->setValue(true);
            warp_indicator->setActiveColor(colorGreen());
            warp_indicator->setLabel("W0", IndicatorContentPosition::Inside());
            break;
        case 1:
            warp_indicator->setValue(true);
            warp_indicator->setActiveColor(colorYellow());
            warp_indicator->setLabel("W1", IndicatorContentPosition::Inside());
            break;
        case 2:
            warp_indicator->setValue(true);
            warp_indicator->setActiveColor(colorOrange());
            warp_indicator->setLabel("W2", IndicatorContentPosition::Inside());
            break;
        default:
            warp_indicator->setValue(true);
            warp_indicator->setActiveColor(colorBrightRed());
            warp_indicator->setLabel("W" + string(warp_level), IndicatorContentPosition::Inside());
            break;
        }
        warp_indicator->setBlink(false);
        warp_indicator->show();
    }
    else
    {
        warp_indicator->hide();
    }

    // Comms
    if (auto comms = my_spaceship.getComponent<CommsTransmitter>())
    {
        comms_indicator->setLabel(tr("COMM"), IndicatorContentPosition::Inside());
        switch (comms->state)
        {
        case CommsTransmitter::State::Inactive:
        case CommsTransmitter::State::ChannelClosed:
            // Black when inactive or closed
            comms_indicator->setValue(true);
            comms_indicator->setActiveColor(colorBlack());
            comms_indicator->setBlink(false);
            break;
        case CommsTransmitter::State::OpeningChannel:
        case CommsTransmitter::State::BeingHailed:
            // Flashing yellow when hailing or being hailed
            comms_indicator->setValue(true);
            comms_indicator->setActiveColor(colorYellow());
            comms_indicator->setBlink(true, 0.5f);
            break;
        case CommsTransmitter::State::ChannelOpen:
        case CommsTransmitter::State::ChannelOpenPlayer:
            // Solid green when channel is open
            comms_indicator->setValue(true);
            comms_indicator->setActiveColor(colorGreen());
            comms_indicator->setBlink(false);
            break;
        case CommsTransmitter::State::ChannelFailed:
        case CommsTransmitter::State::ChannelBroken:
            comms_indicator->setValue(true);
            comms_indicator->setActiveColor(colorBrightRed());
            comms_indicator->setBlink(true, 0.25f);
            break;
        }
        comms_indicator->show();
    }
    else
    {
        comms_indicator->hide();
    }

    // Scan indicator
    if (auto scanner = my_spaceship.getComponent<ScienceScanner>())
    {
        if (scanner->target && scanner->delay > 0.0f)
        {
            // Actively scanning
            scan_indicator->setValue(true);
            scan_indicator->setActiveColor(colorGreen());
            scan_indicator->setBlink(true, 0.5f);
        }
        else
        {
            // Ready to scan
            scan_indicator->setValue(true);
            scan_indicator->setActiveColor(colorBlack());
            scan_indicator->setBlink(false);
        }
        scan_indicator->setLabel(tr("SCAN"), IndicatorContentPosition::Inside());
        scan_indicator->show();
    }
    else
    {
        scan_indicator->hide();
    }

    // Self-destruct indicator - always shows "SCUT" label
    if (auto sd = my_spaceship.getComponent<SelfDestruct>())
    {
        selfdestruct_indicator->setLabel(tr("SCUT"), IndicatorContentPosition::Inside());

        if (!sd->active)
        {
            // Inactive
            selfdestruct_indicator->setValue(true);
            selfdestruct_indicator->setActiveColor(colorBlack());
            selfdestruct_indicator->setBlink(false);
        }
        else
        {
            // Check if all codes confirmed
            bool all_confirmed = true;
            for (int i = 0; i < SelfDestruct::max_codes; i++)
            {
                if (!sd->confirmed[i])
                {
                    all_confirmed = false;
                    break;
                }
            }

            if (all_confirmed && sd->countdown > 0.0f)
            {
                // Counting down - rapid blink
                selfdestruct_indicator->setValue(true);
                selfdestruct_indicator->setActiveColor(colorBrightRed());
                selfdestruct_indicator->setBlink(true, 0.1f);
            }
            else
            {
                // Arming (waiting for codes)
                selfdestruct_indicator->setValue(true);
                selfdestruct_indicator->setActiveColor(colorOrange());
                selfdestruct_indicator->setBlink(true, 0.5f);
            }
        }
        selfdestruct_indicator->show();
    }
    else
    {
        selfdestruct_indicator->hide();
    }

    // Target indicator
    auto target = my_spaceship.getComponent<Target>();
    auto tubes = my_spaceship.getComponent<MissileTubes>();

    if (target && target->entity)
    {
        // Has a target
        bool has_firing_solution = false;

        if (tubes && !tubes->mounts.empty())
        {
            // Check if any tube has a firing solution
            for (auto& mount : tubes->mounts)
            {
                if (mount.state == MissileTubes::MountPoint::State::Loaded)
                {
                    float angle = MissileSystem::calculateFiringSolution(my_spaceship, mount, target->entity);
                    if (angle != std::numeric_limits<float>::infinity())
                    {
                        has_firing_solution = true;
                        break;
                    }
                }
            }
        }

        if (has_firing_solution)
        {
            // Target with firing solution
            target_indicator->setValue(true);
            target_indicator->setActiveColor(colorGreen());
            target_indicator->setBlink(true, 0.5f);
        }
        else
        {
            // Target without firing solution
            target_indicator->setValue(true);
            target_indicator->setActiveColor(colorGreen());
            target_indicator->setBlink(false);
        }
    }
    else
    {
        // No target
        target_indicator->setValue(true);
        target_indicator->setActiveColor(colorBlack());
        target_indicator->setBlink(false);
    }
    target_indicator->setLabel(tr("TGT"), IndicatorContentPosition::Inside());
    target_indicator->show();

    // Combat maneuver indicator (consolidated boost and strafe)
    if (auto cm = my_spaceship.getComponent<CombatManeuveringThrusters>())
    {
        float boost_active = cm->boost.active;
        float strafe_active = std::abs(cm->strafe.active);
        bool is_maneuvering = (boost_active > 0.01f) || (strafe_active > 0.01f);

        boost_indicator->setLabel(tr("BOOST"), IndicatorContentPosition::Inside());

        if (is_maneuvering)
        {
            // Boosting or strafing - orange with fast blink
            boost_indicator->setValue(true);
            boost_indicator->setActiveColor(colorOrange());
            boost_indicator->setBlink(true, 0.25f);
        }
        else if (cm->charge < 0.99f)
        {
            // Recharging - yellow with slow blink
            boost_indicator->setValue(true);
            boost_indicator->setActiveColor(colorYellow());
            boost_indicator->setBlink(true, 1.0f);
        }
        else
        {
            // Ready - solid green
            boost_indicator->setValue(true);
            boost_indicator->setActiveColor(colorGreen());
            boost_indicator->setBlink(false);
        }
        boost_indicator->show();
    }
    else
    {
        boost_indicator->hide();
    }

    // Docking indicator
    if (auto dock_port = my_spaceship.getComponent<DockingPort>())
    {
        dock_indicator->setLabel(tr("DOCK"), IndicatorContentPosition::Inside());

        switch (dock_port->state)
        {
        case DockingPort::State::NotDocking:
            // Not docking - black background
            dock_indicator->setValue(true);
            dock_indicator->setActiveColor(colorBlack());
            dock_indicator->setBlink(false);
            dock_indicator->clearTextColor();
            break;

        case DockingPort::State::Docking:
            // Docking in progress - orange, blinking
            dock_indicator->setValue(true);
            dock_indicator->setActiveColor(colorOrange());
            dock_indicator->setBlink(true, 0.5f);
            dock_indicator->clearTextColor();
            break;

        case DockingPort::State::Docked:
            {
                // Determine if external or internal dock
                DockingStyle style = DockingStyle::External;  // Default to external
                if (dock_port->target)
                {
                    if (auto bay = dock_port->target.getComponent<DockingBay>())
                    {
                        style = dock_port->canDockOn(*bay);
                    }
                }

                if (style == DockingStyle::Internal)
                {
                    // Internally docked - red
                    dock_indicator->setValue(true);
                    dock_indicator->setActiveColor(colorBrightRed());
                    dock_indicator->setBlink(false);
                    dock_indicator->clearTextColor();
                }
                else
                {
                    // Externally docked - green
                    dock_indicator->setValue(true);
                    dock_indicator->setActiveColor(colorGreen());
                    dock_indicator->setBlink(false);
                    dock_indicator->clearTextColor();
                }
            }
            break;
        }
        dock_indicator->show();
    }
    else
    {
        dock_indicator->hide();
    }
}
