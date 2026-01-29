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
#include "components/impulse.h"
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

/**
 * Color usage:
 *
 * BLACK - Normal operation, no attention needed
 * BLUE  - Manual operation in progress
 * GREEN - Automatic operation active
 * WHITE - System OFF when it should be ON
 * AMBER - CAUTION: Degraded operation (flashing 0.5s)
 * RED   - WARNING: Critical condition (flashing 0.25s)
 *
 * Status is communicated through COLOR and BLINKING only.
 * Text labels remain static.
 */

SystemStatusScreen::SystemStatusScreen(GuiContainer* owner)
: GuiOverlay(owner, "SYSTEM_STATUS_SCREEN", colorConfig.background)
{
    system_labels = {{
        tr("ship_system_abbreviation", "REACTOR"),
        tr("ship_system_abbreviation", "BEAM"),
        tr("ship_system_abbreviation", "MISSILE"),
        tr("ship_system_abbreviation", "MANUVR"),
        tr("ship_system_abbreviation", "IMPULSE"),
        tr("ship_system_abbreviation", "WARP"),
        tr("ship_system_abbreviation", "JUMP"),
        tr("ship_system_abbreviation", "SHIELD\nFORWARD"),
        tr("ship_system_abbreviation", "SHIELD\nREAR")
    }};

    weapon_labels = {{
        tr("missile_type_abbreviation", "HOMING"),
        tr("missile_type_abbreviation", "NUKE"),
        tr("missile_type_abbreviation", "MINE"),
        tr("missile_type_abbreviation", "EMP"),
        tr("missile_type_abbreviation", "HVLI")
    }};

    // Default padding
    setAttribute("padding", "20");

    // Background
    background_crosses = new GuiOverlay(this, "BACKGROUND_CROSSES", glm::u8vec4{255,255,255,255});
    background_crosses->setTextureTiled("gui/background/crosses.png");

    // Alert overlay
    (new AlertLevelOverlay(this));

    // Create panels
    createSystemsPanel();
    createDefensesPanel();
    createWeaponsPanel();
    createPropulsionPanel();
    createTransmitterPanel();
}

GuiIndicatorLight* SystemStatusScreen::createIndicator(GuiElement* parent, const string& id, const string& label)
{
    auto* indicator = new GuiIndicatorLight(parent, id, false);
    indicator->setSize(INDICATOR_WIDTH, INDICATOR_HEIGHT);
    KorryPresets::applyTypeS(indicator, label, KorryPresets::Color::Green, false);
    return indicator;
}

string SystemStatusScreen::formatAngle(float degrees)
{
    // Normalize to 0-360
    while (degrees < 0) degrees += 360.0f;
    while (degrees >= 360.0f) degrees -= 360.0f;

    // Always return degrees
    return string(static_cast<int>(degrees)) + "\xC2\xB0";  // UTF-8 degree symbol
}

void SystemStatusScreen::createSystemsPanel()
{
    systems_panel = new GuiPanel(this, "SYSTEMS_PANEL");
    systems_panel
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopLeft);

    auto* container = new GuiElement(systems_panel, "SYSTEMS_CONTAINER");
    container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setMargins(PANEL_PADDING)
        ->setAttribute("layout", "vertical");

    (new GuiLabel(container, "", tr("SHIP SYSTEMS"), 24.0f))
        ->setSize(GuiElement::GuiSizeMax, 35.0f);

    // Energy row (total energy and charge rate)
    energy_row = new GuiElement(container, "ENERGY_ROW");
    energy_row->setSize(GuiElement::GuiSizeMax, ROW_HEIGHT);
    energy_row->setAttribute("layout", "horizontal");

    energy_indicator = createIndicator(energy_row, "ENERGY_IND", tr("energy_property_abbreviation", "ENERGY\nTOTAL"));
    charge_indicator = createIndicator(energy_row, "CHARGE_IND", tr("energy_property_abbreviation", "CHARGE\nRATE"));

    // Column headers
    auto* header_row = new GuiElement(container, "SYS_HEADER");
    header_row->setSize(GuiElement::GuiSizeMax, 20.0f);
    header_row->setAttribute("layout", "horizontal");

    auto createHeaderLabel = [header_row](const string& text, float width) {
        auto* label = new GuiLabel(header_row, "", text, 12.0f);
        label->setSize(width, GuiElement::GuiSizeMax);
    };

    createHeaderLabel(tr("system_property_abbreviation", "SYSTEM"), INDICATOR_WIDTH);
    createHeaderLabel(tr("system_property_abbreviation", "POWER"), INDICATOR_WIDTH);
    createHeaderLabel(tr("system_property_abbreviation", "HEAT"), INDICATOR_WIDTH * 2);
    createHeaderLabel(tr("system_property_abbreviation", "HEALTH"), INDICATOR_WIDTH);
    createHeaderLabel(tr("system_property_abbreviation", "COOLANT"), INDICATOR_WIDTH);
    createHeaderLabel(tr("system_property_abbreviation", "HACKED"), INDICATOR_WIDTH);

    // System indicator grid
    systems_grid = new GuiElement(container, "SYSTEMS_GRID");
    systems_grid->setSize(GuiElement::GuiSizeMax, ROW_HEIGHT * ShipSystem::COUNT);
    systems_grid->setAttribute("layout", "vertical");

    // Create rows for each ship system
    for (int n = 0; n < ShipSystem::COUNT; n++)
    {
        SystemIndicatorRow sir;
        sir.system_type = ShipSystem::Type(n);

        sir.row = new GuiElement(systems_grid, "SYS_ROW_" + string(n));
        sir.row->setSize(GuiElement::GuiSizeMax, ROW_HEIGHT);
        sir.row->setAttribute("layout", "horizontal");

        sir.name_indicator = createIndicator(sir.row, "SYS_NAME_" + string(n), system_labels[n]);
        sir.power_indicator = createIndicator(sir.row, "SYS_PWR_" + string(n), tr("system_property_abbreviation", "POWER"));
        sir.heat_indicator = createIndicator(sir.row, "SYS_HEAT_" + string(n), tr("system_property_abbreviation", "HEAT\nTOTAL"));
        sir.heat_delta_indicator = createIndicator(sir.row, "SYS_DELTA_" + string(n), tr("system_property_abbreviation", "HEAT\nRATE"));
        sir.health_indicator = createIndicator(sir.row, "SYS_HLTH_" + string(n), tr("system_property_abbreviation", "HEALTH"));
        sir.coolant_indicator = createIndicator(sir.row, "SYS_COOL_" + string(n), tr("system_property_abbreviation", "COOLANT"));
        sir.hacked_indicator = createIndicator(sir.row, "SYS_HACK_" + string(n), tr("system_property_abbreviation", "HACKED"));

        system_rows.push_back(sir);
    }

    // Initial panel size (will be adjusted based on visible systems)
    float panel_width = INDICATOR_WIDTH * 7 + PANEL_PADDING * 2;
    float panel_height = PANEL_HEADER_HEIGHT + 20.0f + ROW_HEIGHT * (ShipSystem::COUNT + 1) + PANEL_PADDING * 2;
    systems_panel->setSize(panel_width, panel_height);
}

void SystemStatusScreen::createDefensesPanel()
{
    defenses_panel = new GuiPanel(this, "DEFENSES_PANEL");
    defenses_panel
        ->setPosition(0.0f, 0.0f, sp::Alignment::BottomLeft)
        ->setSize(INDICATOR_WIDTH * 10 + PANEL_PADDING * 2, PANEL_HEADER_HEIGHT + ROW_HEIGHT + PANEL_PADDING * 2);

    auto* container = new GuiElement(defenses_panel, "DEFENSES_CONTAINER");
    container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setMargins(PANEL_PADDING)
        ->setAttribute("layout", "vertical");

    (new GuiLabel(container, "", tr("DEFENSES"), 24.0f))
        ->setSize(GuiElement::GuiSizeMax, 35.0f);

    auto* row1 = new GuiElement(container, "DEF_ROW1");
    row1
        ->setSize(GuiElement::GuiSizeMax, ROW_HEIGHT)
        ->setAttribute("layout", "horizontal");

    hull_indicator = createIndicator(row1, "HULL_IND", "HULL");
    shields_status_indicator = createIndicator(row1, "SHLD_STATUS", tr("shield_abbreviation", "SHIELDS"));

    // Shield segment indicators (up to 8)
    for (int i = 0; i < 8; i++)
    {
        ShieldIndicator si;
        si.segment_index = i;
        si.indicator = createIndicator(row1, "SHLD_" + string(i), tr("shield_abbreviation", "SHIELD\n") + string(i + 1));
        si.indicator->hide();
        shield_indicators.push_back(si);
    }
}

void SystemStatusScreen::createWeaponsPanel()
{
    weapons_panel = new GuiPanel(this, "WEAPONS_PANEL");
    weapons_panel
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopRight);

    auto* container = new GuiElement(weapons_panel, "WEAPONS_CONTAINER");
    container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setMargins(PANEL_PADDING)
        ->setAttribute("layout", "vertical");

    (new GuiLabel(container, "", tr("WEAPONS"), 24.0f))
        ->setSize(GuiElement::GuiSizeMax, 35.0f);

    // Weapon storage row
    auto* storage_row = new GuiElement(container, "STORAGE_ROW");
    storage_row
        ->setSize(GuiElement::GuiSizeMax, ROW_HEIGHT)
        ->setAttribute("layout", "horizontal");

    (new GuiElement(storage_row, "SPACER"))
        ->setSize(INDICATOR_WIDTH, INDICATOR_HEIGHT);

    for (int n = 0; n < MW_Count; n++)
        weapon_storage_indicators[n] = createIndicator(storage_row, "WPN_" + string(n), weapon_labels[n] + "\n" + tr("weapon_storage_abbreviation", "STORE"));

    // Missile tubes grid
    (new GuiLabel(container, "", tr("TUBES"), 18.0f))
        ->setSize(GuiElement::GuiSizeMax, 25.0f);

    tubes_grid = new GuiElement(container, "TUBES_GRID");
    tubes_grid
        ->setSize(GuiElement::GuiSizeMax, ROW_HEIGHT * 16)
        ->setAttribute("layout", "vertical");

    // Create tube rows (up to 16)
    for (int i = 0; i < 16; i++)
    {
        TubeIndicatorRow tir;
        tir.row = new GuiElement(tubes_grid, "TUBE_ROW_" + string(i));
        tir.row->setSize(GuiElement::GuiSizeMax, ROW_HEIGHT);
        tir.row->setAttribute("layout", "horizontal");
        tir.row->hide();

        tir.tube_indicator = createIndicator(tir.row, "TUBE_" + string(i), "----");

        // Weapon type indicators for this tube
        for (int w = 0; w < MW_Count; w++)
        {
            tir.weapon_indicators[w] = createIndicator(tir.row, "TUBE_" + string(i) + "_WPN_" + string(w), weapon_labels[w]);
            tir.weapon_indicators[w]->hide();
        }

        tube_rows.push_back(tir);
    }

    // Beam weapons row
    (new GuiLabel(container, "", tr("BEAMS"), 18.0f))
        ->setSize(GuiElement::GuiSizeMax, 25.0f);

    beams_row = new GuiElement(container, "BEAMS_ROW");
    beams_row
        ->setSize(GuiElement::GuiSizeMax, ROW_HEIGHT)
        ->setAttribute("layout", "horizontal");

    // Create beam indicators (up to 16)
    for (int i = 0; i < 16; i++)
    {
        BeamIndicator bi;
        bi.indicator = createIndicator(beams_row, "BEAM_" + string(i), "---");
        bi.indicator->hide();
        beam_indicators.push_back(bi);
    }

    // Initial panel size
    float panel_width = INDICATOR_WIDTH * 6 + PANEL_PADDING * 2;
    float panel_height = 500.0f;
    weapons_panel->setSize(panel_width, panel_height);
}

void SystemStatusScreen::createPropulsionPanel()
{
    propulsion_panel = new GuiPanel(this, "PROPULSION_PANEL");
    propulsion_panel
        ->setPosition(0.0f, -(PANEL_HEADER_HEIGHT + ROW_HEIGHT + PANEL_PADDING * 2), sp::Alignment::BottomRight)
        ->setSize(INDICATOR_WIDTH * 4 + PANEL_PADDING * 2, PANEL_HEADER_HEIGHT + ROW_HEIGHT + PANEL_PADDING * 2);

    auto* container = new GuiElement(propulsion_panel, "PROPULSION_CONTAINER");
    container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setMargins(PANEL_PADDING)
        ->setAttribute("layout", "vertical");

    (new GuiLabel(container, "", tr("PROPULSION"), 24.0f))
        ->setSize(GuiElement::GuiSizeMax, 35.0f);

    auto* row = new GuiElement(container, "PROP_ROW");
    row
        ->setSize(GuiElement::GuiSizeMax, ROW_HEIGHT)
        ->setAttribute("layout", "horizontal");

    impulse_indicator = createIndicator(row, "IMPULSE_IND", "IMPULSE");
    warp_indicator = createIndicator(row, "WARP_IND", "WARP");
    jump_indicator = createIndicator(row, "JUMP_IND", "JUMP");
    maneuver_indicator = createIndicator(row, "MANEUVER_IND", "MANUVR");
}

void SystemStatusScreen::createTransmitterPanel()
{
    transmitter_panel = new GuiPanel(this, "TRANSMITTER_PANEL");
    transmitter_panel
        ->setPosition(0.0f, 0.0f, sp::Alignment::BottomRight)
        ->setSize(INDICATOR_WIDTH * 5 + PANEL_PADDING * 2, PANEL_HEADER_HEIGHT + ROW_HEIGHT + PANEL_PADDING * 2);

    auto* container = new GuiElement(transmitter_panel, "TRANSMITTER_CONTAINER");
    container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setMargins(PANEL_PADDING)
        ->setAttribute("layout", "vertical");

    (new GuiLabel(container, "", tr("TRANSMITTER"), 24.0f))
        ->setSize(GuiElement::GuiSizeMax, 35.0f);

    auto* row = new GuiElement(container, "TRANS_ROW");
    row
        ->setSize(GuiElement::GuiSizeMax, ROW_HEIGHT)
        ->setAttribute("layout", "horizontal");

    comms_indicator = createIndicator(row, "COMMS_IND", tr("comms_abbreviation", "COMMS"));
    scan_indicator = createIndicator(row, "SCAN_IND", tr("scan_abbreviation", "SCAN"));
    dock_indicator = createIndicator(row, "DOCK_IND", tr("dock_abbreviation", "DOCK"));
    probe_indicator = createIndicator(row, "PROBE_IND", tr("probe_store_abbreviation", "PROBE\nSTORE"));
    selfdestruct_indicator = createIndicator(row, "SELF_DESTRUCT_IND", tr("self_destruct_abbreviation", "SELF-\nDESTRUCT"));
}

void SystemStatusScreen::onDraw(sp::RenderTarget& target)
{
    GuiOverlay::onDraw(target);
}

void SystemStatusScreen::onUpdate()
{
    if (!my_spaceship || !isVisible())
        return;

    update_timer += 0.016f;
    if (update_timer >= UPDATE_INTERVAL)
    {
        update_timer -= UPDATE_INTERVAL;

        updateSystemIndicators();
        updateDefenseIndicators();
        updateWeaponIndicators();
        updatePropulsionIndicators();
        updateTransmitterIndicators();
        updateSelfDestructIndicator();
    }
}

void SystemStatusScreen::updateSystemIndicators()
{
    string label = tr("energy_abbreviation", "ENERGY\nSTORE");
    // Energy indicators
    if (auto reactor = my_spaceship.getComponent<Reactor>())
    {
        float ratio = reactor->energy / reactor->max_energy;
        energy_value.update(ratio);

        if (ratio > 0.8f)
        {
            KorryPresets::applyTypeS(energy_indicator, label, KorryPresets::Color::Green, false);
            energy_indicator->setBlink(false);
        }
        else if (ratio > 0.34f)
        {
            KorryPresets::applyTypeN(energy_indicator, label, KorryPresets::Color::Green, true);
            energy_indicator->setBlink(false);
        }
        else if (ratio > 0.1f)
        {
            KorryPresets::applyTypeB(energy_indicator, label, KorryPresets::Color::Amber, true);
            energy_indicator->setBlink(true, BLINK_CAUTION);
        }
        else
        {
            KorryPresets::applyTypeB(energy_indicator, label, KorryPresets::Color::Red, true);
            energy_indicator->setBlink(true, BLINK_WARNING);
        }
        energy_indicator->show();

        // Charge rate indicator with thresholds
        // Calculate rate per minute: delta is change in ratio per UPDATE_INTERVAL
        // rate_per_minute = delta * max_energy * (60 / UPDATE_INTERVAL)
        float rate_per_minute = energy_value.delta() * reactor->max_energy * (60.0f / UPDATE_INTERVAL);
        label = tr("energy_abbreviation", "CHARGE\nRATE");
        if (rate_per_minute >= 20.0f)
        {
            // Positive rate >= 20/min: black text on green background
            KorryPresets::applyTypeB(charge_indicator, label, KorryPresets::Color::Green, true);
            charge_indicator->setBlink(false);
        }
        else if (rate_per_minute > 3.0f)
        {
            // Positive rate < 20/min: green text on black background
            KorryPresets::applyTypeN(charge_indicator, label, KorryPresets::Color::Green, true);
            charge_indicator->setBlink(false);
        }
        else if (abs(rate_per_minute) <= 3.0f)
        {
            // Near zero: nominal (disabled)
            KorryPresets::applyTypeS(charge_indicator, label, KorryPresets::Color::Green, false);
            charge_indicator->setBlink(false);
        }
        else if (rate_per_minute >= -100.0f)
        {
            // Moderate negative rate (up to -100/min): amber text on black background
            KorryPresets::applyTypeN(charge_indicator, label, KorryPresets::Color::Amber, true);
            charge_indicator->setBlink(false);
        }
        else
        {
            // Severe negative rate (< -100/min): black text on red background
            KorryPresets::applyTypeB(charge_indicator, label, KorryPresets::Color::Red, true);
            charge_indicator->setBlink(false);
        }
        charge_indicator->show();

        energy_row->show();
    }
    else
    {
        energy_row->hide();
    }

    // System rows
    visible_system_count = 0;
    for (auto& sir : system_rows)
    {
        auto sys = ShipSystem::get(my_spaceship, sir.system_type);

        if (!sys)
        {
            sir.row->hide();
            continue;
        }

        sir.row->show();
        visible_system_count++;

        float health = sys->health;
        float heat = sys->heat_level;
        float power = sys->power_level;
        float coolant = sys->coolant_level;
        float hacked = sys->hacked_level;
        float heat_delta = sys->getHeatingDelta();

        sir.health_value.update(health);
        sir.heat_value.update(heat);
        sir.power_value.update(power);
        sir.coolant_value.update(coolant);
        sir.hacked_value.update(hacked);

        string label = system_labels[static_cast<int>(sir.system_type)];

        // Name indicator - overall system status
        if (power < 0.01f)
        {
            KorryPresets::applyTypeW(sir.name_indicator, label, KorryPresets::Color::White, true);
            sir.name_indicator->setBlink(false);
        }
        else if (health < 0.34f || heat > 0.9f)
        {
            KorryPresets::applyTypeB(sir.name_indicator, label, KorryPresets::Color::Red, true);
            if (health <= 0.0f || heat >= 1.0f)
                sir.name_indicator->setBlink(true, BLINK_WARNING);
            else
                sir.name_indicator->setBlink(false);
        }
        else if (health < 0.8f || heat > 0.7f)
        {
            KorryPresets::applyTypeB(sir.name_indicator, label, KorryPresets::Color::Amber, true);
            sir.name_indicator->setBlink(true, BLINK_CAUTION);
        }
        else
        {
            KorryPresets::applyTypeN(sir.name_indicator, label, KorryPresets::Color::Green, false);
            sir.name_indicator->setBlink(false);
        }

        // Power indicator
        // 0%: black text on white background
        // < 100%: black text on blue background
        // 100%: disabled (dark)
        // > 100%: blue text on black background
        label = tr("power_abbreviation", "POWER");
        if (power < 0.01f)
        {
            KorryPresets::applyTypeN(sir.power_indicator, label, KorryPresets::Color::White, true);
            sir.power_indicator->setBlink(false);
        }
        else if (power < 0.99f)
        {
            KorryPresets::applyTypeB(sir.power_indicator, label, KorryPresets::Color::Blue, true);
            sir.power_indicator->setBlink(false);
        }
        else if (power > 1.01f)
        {
            KorryPresets::applyTypeN(sir.power_indicator, label, KorryPresets::Color::Blue, true);
            sir.power_indicator->setBlink(false);
        }
        else
        {
            // 100% - disabled/dark
            KorryPresets::applyTypeS(sir.power_indicator, label, KorryPresets::Color::Green, false);
            sir.power_indicator->setBlink(false);
        }

        // Heat indicator
        label = tr("heat_abbreviation", "HEAT\nTOTAL");
        if (heat > 0.9f)
        {
            KorryPresets::applyTypeB(sir.heat_indicator, label, KorryPresets::Color::Red, true);
            sir.heat_indicator->setBlink(true, BLINK_WARNING);
        }
        else if (heat > 0.7f)
        {
            KorryPresets::applyTypeB(sir.heat_indicator, label, KorryPresets::Color::Amber, true);
            sir.heat_indicator->setBlink(true, BLINK_CAUTION);
        }
        else if (heat > 0.34f)
        {
            KorryPresets::applyTypeN(sir.heat_indicator, label, KorryPresets::Color::Amber, true);
            sir.heat_indicator->setBlink(false);
        }
        else
        {
            KorryPresets::applyTypeS(sir.heat_indicator, label, KorryPresets::Color::Green, false);
            sir.heat_indicator->setBlink(false);
        }

        // Heat delta indicator
        label = tr("heat_abbreviation", "HEAT\nRATE");
        if (heat > 0.01f)
        {
            if (heat_delta > 0.5f)
            {
                KorryPresets::applyTypeB(sir.heat_delta_indicator, label, KorryPresets::Color::Red, true);
                sir.heat_delta_indicator->setBlink(true, BLINK_WARNING);
            }
            else if (heat_delta > 0.1f)
            {
                KorryPresets::applyTypeN(sir.heat_delta_indicator, label, KorryPresets::Color::Amber, true);
                sir.heat_delta_indicator->setBlink(false);
            }
            else if (heat_delta < -0.1f)
            {
                KorryPresets::applyTypeN(sir.heat_delta_indicator, label, KorryPresets::Color::Blue, true);
                sir.heat_delta_indicator->setBlink(false);
            }
            else
            {
                KorryPresets::applyTypeS(sir.heat_delta_indicator, label, KorryPresets::Color::Green, false);
                sir.heat_delta_indicator->setBlink(false);
            }
        }
        else
        {
            KorryPresets::applyTypeS(sir.heat_delta_indicator, label, KorryPresets::Color::Green, false);
            sir.heat_delta_indicator->setBlink(false);
        }

        // Health indicator
        label = tr("damage_abbreviation", "DAMAGE");
        if (health < 0.34f)
        {
            KorryPresets::applyTypeB(sir.health_indicator, label, KorryPresets::Color::Red, true);
            sir.health_indicator->setBlink(true, BLINK_WARNING);
        }
        else if (health < 0.8f)
        {
            KorryPresets::applyTypeB(sir.health_indicator, label, KorryPresets::Color::Amber, true);
            if (sir.health_value.declining())
                sir.health_indicator->setBlink(true, BLINK_CAUTION);
            else
                sir.health_indicator->setBlink(false);
        }
        else
        {
            KorryPresets::applyTypeS(sir.health_indicator, label, KorryPresets::Color::Green, false);
            sir.health_indicator->setBlink(false);
        }

        // Coolant indicator - always blue if non-zero
        label = tr("coolant_abbreviation", "COOLANT");
        if (coolant > 0.1f)
        {
            KorryPresets::applyTypeN(sir.coolant_indicator, label, KorryPresets::Color::Blue, true);
            sir.coolant_indicator->setBlink(false);
        }
        else
        {
            KorryPresets::applyTypeS(sir.coolant_indicator, label, KorryPresets::Color::Green, false);
            sir.coolant_indicator->setBlink(false);
        }

        // Hacked indicator
        label = tr("hacked_abbreviation", "CPU");
        if (hacked > 0.5f)
        {
            KorryPresets::applyTypeB(sir.hacked_indicator, "CPU", KorryPresets::Color::Red, true);
            sir.hacked_indicator->setBlink(true, BLINK_WARNING);
        }
        else if (hacked > 0.01f)
        {
            KorryPresets::applyTypeB(sir.hacked_indicator, "CPU", KorryPresets::Color::Amber, true);
            sir.hacked_indicator->setBlink(true, BLINK_CAUTION);
        }
        else
        {
            KorryPresets::applyTypeS(sir.hacked_indicator, "CPU", KorryPresets::Color::Green, false);
            sir.hacked_indicator->setBlink(false);
        }
    }

    // Adjust panel height based on visible systems
    float panel_height = PANEL_HEADER_HEIGHT + 20.0f + ROW_HEIGHT + ROW_HEIGHT * visible_system_count + PANEL_PADDING * 2;
    systems_panel->setSize(INDICATOR_WIDTH * 7 + PANEL_PADDING * 2, panel_height);
}

void SystemStatusScreen::updateDefenseIndicators()
{
    // Hull - any damage is degraded
    string label = tr("hull_abbreviation", "HULL\nINTEG");
    if (auto hull = my_spaceship.getComponent<Hull>())
    {
        float ratio = hull->current / hull->max;
        hull_value.update(ratio);

        if (ratio > 0.99f)
        {
            // Full health - nominal
            KorryPresets::applyTypeS(hull_indicator, label, KorryPresets::Color::Green, false);
            hull_indicator->setBlink(false);
        }
        else if (ratio > 0.34f)
        {
            // Any damage - degraded (amber)
            KorryPresets::applyTypeB(hull_indicator, label, KorryPresets::Color::Amber, true);
            if (hull_value.declining())
                hull_indicator->setBlink(true, BLINK_CAUTION);
            else
                hull_indicator->setBlink(false);
        }
        else
        {
            // Critical damage (red)
            KorryPresets::applyTypeB(hull_indicator, label, KorryPresets::Color::Red, true);
            hull_indicator->setBlink(true, BLINK_WARNING);
        }
        hull_indicator->show();
    }
    else
        hull_indicator->hide();

    // Shields
    // Shields down: text colors on black background (nominal or degraded)
    // Shields up: black text on colored backgrounds
    // Changing values should blink, any damage = degraded
    auto shields = my_spaceship.getComponent<Shields>();
    if (shields && !shields->entries.empty())
    {
        bool shields_up = shields->active;
        float total_shield = 0.0f;
        float total_max = 0.0f;

        for (size_t i = 0; i < shields->entries.size() && i < shield_indicators.size(); i++)
        {
            auto& entry = shields->entries[i];
            total_shield += entry.level;
            total_max += entry.max;

            auto& si = shield_indicators[i];
            float seg_ratio = entry.max > 0.0f ? entry.level / entry.max : 0.0f;
            si.value.update(seg_ratio);

            float segment_direction = 360.0f;
            if (shield_indicators.size() > 1)
            {
                if (i == 0)
                    segment_direction = 0.0f;
                else
                    segment_direction = (360.0f / shields->entries.size()) * i;
            }

            label = tr("shield_abbreviation", "SHIELD") + "\n" + formatAngle(segment_direction);
            bool is_changing = !si.value.stable();
            bool is_damaged = seg_ratio < 0.99f;
            bool is_critical = seg_ratio < 0.34f;

            if (!shields_up)
            {
                // Shields down: text colors on black background
                if (is_critical)
                {
                    KorryPresets::applyTypeN(si.indicator, label, KorryPresets::Color::Red, true);
                    if (is_changing)
                        si.indicator->setBlink(true, BLINK_WARNING);
                    else
                        si.indicator->setBlink(false);
                }
                else if (is_damaged)
                {
                    KorryPresets::applyTypeN(si.indicator, label, KorryPresets::Color::Amber, true);
                    if (is_changing)
                        si.indicator->setBlink(true, BLINK_CAUTION);
                    else
                        si.indicator->setBlink(false);
                }
                else
                {
                    KorryPresets::applyTypeN(si.indicator, label, KorryPresets::Color::Green, true);
                    if (is_changing)
                        si.indicator->setBlink(true, BLINK_CAUTION);
                    else
                        si.indicator->setBlink(false);
                }
            }
            else
            {
                // Shields up: black text on colored backgrounds
                if (is_critical)
                {
                    KorryPresets::applyTypeB(si.indicator, label, KorryPresets::Color::Red, true);
                    if (is_changing)
                        si.indicator->setBlink(true, BLINK_WARNING);
                    else
                        si.indicator->setBlink(false);
                }
                else if (is_damaged)
                {
                    KorryPresets::applyTypeB(si.indicator, label, KorryPresets::Color::Amber, true);
                    if (is_changing)
                        si.indicator->setBlink(true, BLINK_CAUTION);
                    else
                        si.indicator->setBlink(false);
                }
                else
                {
                    KorryPresets::applyTypeB(si.indicator, label, KorryPresets::Color::Green, true);
                    if (is_changing)
                        si.indicator->setBlink(true, BLINK_CAUTION);
                    else
                        si.indicator->setBlink(false);
                }
            }
            si.indicator->show();
        }

        for (size_t i = shields->entries.size(); i < shield_indicators.size(); i++)
            shield_indicators[i].indicator->hide();

        float ratio = total_max > 0.0f ? total_shield / total_max : 0.0f;

        label = tr("shield_abbreviation", "SHIELDS");
        if (!shields_up)
        {
            KorryPresets::applyTypeN(shields_status_indicator, label, KorryPresets::Color::White, true);
            shields_status_indicator->setBlink(false);
        }
        else if (ratio > 0.99f)
        {
            KorryPresets::applyTypeN(shields_status_indicator, label, KorryPresets::Color::Green, true);
            shields_status_indicator->setBlink(false);
        }
        else if (ratio > 0.34f)
        {
            KorryPresets::applyTypeB(shields_status_indicator, label, KorryPresets::Color::Amber, true);
            shields_status_indicator->setBlink(true, BLINK_CAUTION);
        }
        else
        {
            KorryPresets::applyTypeB(shields_status_indicator, label, KorryPresets::Color::Red, true);
            shields_status_indicator->setBlink(true, BLINK_WARNING);
        }
        shields_status_indicator->show();
    }
    else
    {
        shields_status_indicator->hide();
        for (auto& si : shield_indicators)
            si.indicator->hide();
    }
}

void SystemStatusScreen::updateWeaponIndicators()
{
    auto tubes = my_spaceship.getComponent<MissileTubes>();
    string label = "";

    // Weapon storage
    for (int n = 0; n < MW_Count; n++)
    {
        label = weapon_labels[n] + "\n" + tr("weapon_storage_abbreviation", "STORE");
        if (!weapon_storage_indicators[n]) continue;

        if (tubes && tubes->storage_max[n] > 0)
        {
            int count = tubes->storage[n];
            int max_count = tubes->storage_max[n];
            float ratio = static_cast<float>(count) / static_cast<float>(max_count);

            if (count == 0)
            {
                KorryPresets::applyTypeB(weapon_storage_indicators[n], label, KorryPresets::Color::Red, true);
                weapon_storage_indicators[n]->setBlink(false);
            }
            else if (count == 1)
            {
                KorryPresets::applyTypeN(weapon_storage_indicators[n], label, KorryPresets::Color::Red, true);
                weapon_storage_indicators[n]->setBlink(false);
            }
            else if (ratio < 0.5f)
            {
                KorryPresets::applyTypeN(weapon_storage_indicators[n], label, KorryPresets::Color::Amber, true);
                weapon_storage_indicators[n]->setBlink(false);
            }
            else
            {
                KorryPresets::applyTypeS(weapon_storage_indicators[n], label, KorryPresets::Color::Green, false);
                weapon_storage_indicators[n]->setBlink(false);
            }

            weapon_storage_indicators[n]->show();
        }
        else
            weapon_storage_indicators[n]->hide();
    }

    // Missile tubes
    visible_tube_count = 0;
    if (tubes)
    {
        for (size_t i = 0; i < tubes->mounts.size() && i < tube_rows.size(); i++)
        {
            auto& mount = tubes->mounts[i];
            auto& tir = tube_rows[i];

            tir.direction = mount.direction;
            tir.type_allowed_mask = mount.type_allowed_mask;

            label = tr("tube_abbreviation", "TUBE") + "\n" + formatAngle(mount.direction);

            // Update tube indicator label with direction
            switch (mount.state)
            {
            case MissileTubes::MountPoint::State::Empty:
                KorryPresets::applyTypeS(tir.tube_indicator, label, KorryPresets::Color::Green, false);
                tir.tube_indicator->setBlink(false);
                break;
            case MissileTubes::MountPoint::State::Loading:
                KorryPresets::applyTypeN(tir.tube_indicator, label, KorryPresets::Color::Blue, true);
                tir.tube_indicator->setBlink(true, BLINK_CAUTION);
                break;
            case MissileTubes::MountPoint::State::Loaded:
                KorryPresets::applyTypeN(tir.tube_indicator, label, KorryPresets::Color::Blue, true);
                tir.tube_indicator->setBlink(false);
                break;
            case MissileTubes::MountPoint::State::Unloading:
                KorryPresets::applyTypeN(tir.tube_indicator, label, KorryPresets::Color::Blue, true);
                tir.tube_indicator->setBlink(true, BLINK_CAUTION);
                break;
            case MissileTubes::MountPoint::State::Firing:
                KorryPresets::applyTypeB(tir.tube_indicator, label, KorryPresets::Color::Blue, true);
                tir.tube_indicator->setBlink(true, BLINK_WARNING);
                break;
            }

            // Update weapon type indicators - always show in fixed columns
            for (int w = 0; w < MW_Count; w++)
            {
                bool can_load = mount.canLoad(static_cast<EMissileWeapons>(w));
                bool is_this_type = mount.type_loaded == static_cast<EMissileWeapons>(w);
                bool is_loaded = (mount.state == MissileTubes::MountPoint::State::Loaded ||
                                  mount.state == MissileTubes::MountPoint::State::Firing) && is_this_type;
                bool is_loading = mount.state == MissileTubes::MountPoint::State::Loading && is_this_type;
                bool is_unloading = mount.state == MissileTubes::MountPoint::State::Unloading && is_this_type;

                // Always show indicator in fixed column position
                tir.weapon_indicators[w]->show();

                if (!can_load)
                {
                    // Tube doesn't support this weapon type - show disabled/hidden
                    KorryPresets::applyTypeS(tir.weapon_indicators[w], "----", KorryPresets::Color::Green, false);
                    tir.weapon_indicators[w]->setBlink(false);
                }
                else if (is_loading)
                {
                    // Loading: blue text on black background, blinking
                    KorryPresets::applyTypeN(tir.weapon_indicators[w], weapon_labels[w], KorryPresets::Color::Blue, true);
                    tir.weapon_indicators[w]->setBlink(true, BLINK_CAUTION);
                }
                else if (is_unloading)
                {
                    // Unloading: black text on blue background, blinking
                    KorryPresets::applyTypeB(tir.weapon_indicators[w], weapon_labels[w], KorryPresets::Color::Blue, true);
                    tir.weapon_indicators[w]->setBlink(true, BLINK_CAUTION);
                }
                else if (is_loaded)
                {
                    // Loaded: blue text on black background, solid
                    KorryPresets::applyTypeN(tir.weapon_indicators[w], weapon_labels[w], KorryPresets::Color::Blue, true);
                    tir.weapon_indicators[w]->setBlink(false);
                }
                else
                {
                    // Available but not loaded
                    KorryPresets::applyTypeS(tir.weapon_indicators[w], weapon_labels[w], KorryPresets::Color::Green, false);
                    tir.weapon_indicators[w]->setBlink(false);
                }
            }

            tir.row->show();
            visible_tube_count++;
        }

        for (size_t i = tubes->mounts.size(); i < tube_rows.size(); i++)
            tube_rows[i].row->hide();
    }
    else
    {
        for (auto& tir : tube_rows)
            tir.row->hide();
    }

    // Beam weapons
    if (auto beams = my_spaceship.getComponent<BeamWeaponSys>())
    {
        for (size_t i = 0; i < beams->mounts.size() && i < beam_indicators.size(); i++)
        {
            auto& mount = beams->mounts[i];
            auto& bi = beam_indicators[i];

            bi.direction = mount.direction;
            string angle_label = tr("beam_abbreviation", "BEAM") + "\n" + formatAngle(mount.direction);

            float cooldown_ratio = mount.cycle_time > 0.0f ? mount.cooldown / mount.cycle_time : 0.0f;
            bi.cooldown_value.update(1.0f - cooldown_ratio);

            if (cooldown_ratio > 0.8f)
            {
                KorryPresets::applyTypeN(bi.indicator, angle_label, KorryPresets::Color::Blue, true);
                bi.indicator->setBlink(true, BLINK_WARNING);
            }
            else if (cooldown_ratio > 0.01f)
            {
                KorryPresets::applyTypeN(bi.indicator, angle_label, KorryPresets::Color::Blue, true);
                bi.indicator->setBlink(false);
            }
            else
            {
                KorryPresets::applyTypeS(bi.indicator, angle_label, KorryPresets::Color::Green, false);
                bi.indicator->setBlink(false);
            }

            bi.indicator->show();
        }

        for (size_t i = beams->mounts.size(); i < beam_indicators.size(); i++)
            beam_indicators[i].indicator->hide();

        beams_row->show();
    }
    else
    {
        for (auto& bi : beam_indicators)
            bi.indicator->hide();
        beams_row->hide();
    }

    // Adjust weapons panel height
    float panel_height = PANEL_HEADER_HEIGHT + ROW_HEIGHT + 25.0f + ROW_HEIGHT * visible_tube_count + 25.0f + ROW_HEIGHT + PANEL_PADDING * 2;
    weapons_panel->setSize(INDICATOR_WIDTH * 6 + PANEL_PADDING * 2, panel_height);
}

void SystemStatusScreen::updatePropulsionIndicators()
{
    // Impulse
    if (auto impulse = my_spaceship.getComponent<ImpulseEngine>())
    {
        float request = std::abs(impulse->request);

        if (request > 0.01f)
        {
            KorryPresets::applyTypeN(impulse_indicator, "IMPULSE", KorryPresets::Color::Blue, true);
            impulse_indicator->setBlink(false);
        }
        else
        {
            KorryPresets::applyTypeS(impulse_indicator, "IMPULSE", KorryPresets::Color::Green, false);
            impulse_indicator->setBlink(false);
        }
        impulse_indicator->show();
    }
    else
        impulse_indicator->hide();

    // Warp
    if (auto warp = my_spaceship.getComponent<WarpDrive>())
    {
        int level = static_cast<int>(warp->current);

        if (level > 0)
        {
            KorryPresets::applyTypeN(warp_indicator, "WARP", KorryPresets::Color::Blue, true);
            warp_indicator->setBlink(false);
        }
        else
        {
            KorryPresets::applyTypeS(warp_indicator, "WARP", KorryPresets::Color::Green, false);
            warp_indicator->setBlink(false);
        }
        warp_indicator->show();
    }
    else
        warp_indicator->hide();

    // Jump
    if (auto jump = my_spaceship.getComponent<JumpDrive>())
    {
        float effectiveness = jump->getSystemEffectiveness();
        float charge_ratio = jump->max_distance > 0.0f ? jump->charge / jump->max_distance : 0.0f;
        int delay = static_cast<int>(jump->delay);
        const string label = tr("jump_abbreviation", "JUMP");

        if (effectiveness <= 0.0f)
        {
            KorryPresets::applyTypeB(jump_indicator, label, KorryPresets::Color::Red, true);
            jump_indicator->setBlink(false);
        }
        else if (delay > 0)
        {
            KorryPresets::applyTypeB(jump_indicator, label, KorryPresets::Color::Blue, true);
            jump_indicator->setBlink(true, delay / 10.0f);
        }
        else if (charge_ratio < 0.99f)
        {
            KorryPresets::applyTypeN(jump_indicator, label, KorryPresets::Color::Amber, true);
            jump_indicator->setBlink(false);
        }
        else
        {
            KorryPresets::applyTypeS(jump_indicator, label, KorryPresets::Color::Green, false);
            jump_indicator->setBlink(false);
        }
        jump_indicator->show();
    }
    else
        jump_indicator->hide();

    // Combat maneuver
    if (auto cm = my_spaceship.getComponent<CombatManeuveringThrusters>())
    {
        bool active = (cm->boost.active > 0.01f) || (std::abs(cm->strafe.active) > 0.01f);
        const string label = tr("maneuver_abbreviation", "COMBAT\nMANUVR");

        if (active)
        {
            KorryPresets::applyTypeN(maneuver_indicator, label, KorryPresets::Color::Blue, true);
            maneuver_indicator->setBlink(true, BLINK_WARNING);
        }
        else if (cm->charge < 0.99f)
        {
            KorryPresets::applyTypeN(maneuver_indicator, label, KorryPresets::Color::Amber, true);
            maneuver_indicator->setBlink(false);
        }
        else
        {
            KorryPresets::applyTypeS(maneuver_indicator, label, KorryPresets::Color::Green, false);
            maneuver_indicator->setBlink(false);
        }
        maneuver_indicator->show();
    }
    else
        maneuver_indicator->hide();
}

void SystemStatusScreen::updateTransmitterIndicators()
{
    // Comms
    if (auto comms = my_spaceship.getComponent<CommsTransmitter>())
    {
        const string label = tr("comms_abbreviation", "COMMS");
        switch (comms->state)
        {
        case CommsTransmitter::State::Inactive:
        case CommsTransmitter::State::ChannelClosed:
            KorryPresets::applyTypeS(comms_indicator, label, KorryPresets::Color::Green, false);
            comms_indicator->setBlink(false);
            break;
        case CommsTransmitter::State::OpeningChannel:
            KorryPresets::applyTypeN(comms_indicator, label, KorryPresets::Color::Blue, true);
            comms_indicator->setBlink(true, BLINK_CAUTION);
            break;
        case CommsTransmitter::State::BeingHailed:
            KorryPresets::applyTypeB(comms_indicator, label, KorryPresets::Color::Green, true);
            comms_indicator->setBlink(true, BLINK_CAUTION);
            break;
        case CommsTransmitter::State::ChannelOpen:
        case CommsTransmitter::State::ChannelOpenPlayer:
            KorryPresets::applyTypeN(comms_indicator, label, KorryPresets::Color::Green, true);
            comms_indicator->setBlink(false);
            break;
        case CommsTransmitter::State::ChannelFailed:
        case CommsTransmitter::State::ChannelBroken:
            KorryPresets::applyTypeB(comms_indicator, label, KorryPresets::Color::Red, true);
            comms_indicator->setBlink(false);
            break;
        }
        comms_indicator->show();
    }
    else
        comms_indicator->hide();

    // Scanner - no blink, solid only
    if (auto scanner = my_spaceship.getComponent<ScienceScanner>())
    {
        const string label = tr("scan_abbreviation", "SCAN");
        if (scanner->target && scanner->delay > 0.0f)
        {
            KorryPresets::applyTypeN(scan_indicator, label, KorryPresets::Color::Blue, true);
            scan_indicator->setBlink(false);  // No blink
        }
        else
        {
            KorryPresets::applyTypeS(scan_indicator, label, KorryPresets::Color::Green, false);
            scan_indicator->setBlink(false);
        }
        scan_indicator->show();
    }
    else
        scan_indicator->hide();

    // Docking - no blink, solid only
    if (auto dock_port = my_spaceship.getComponent<DockingPort>())
    {
        const string label = tr("docking_abbreviation", "DOCK");

        switch (dock_port->state)
        {
        case DockingPort::State::NotDocking:
            KorryPresets::applyTypeS(dock_indicator, label, KorryPresets::Color::Green, false);
            dock_indicator->setBlink(false);
            break;
        case DockingPort::State::Docking:
            KorryPresets::applyTypeN(dock_indicator, label, KorryPresets::Color::Blue, true);
            dock_indicator->setBlink(false);  // No blink
            break;
        case DockingPort::State::Docked:
            KorryPresets::applyTypeN(dock_indicator, label, KorryPresets::Color::Green, true);
            dock_indicator->setBlink(false);
            break;
        }
        dock_indicator->show();
    }
    else
        dock_indicator->hide();

    // Probes
    if (auto probes = my_spaceship.getComponent<ScanProbeLauncher>())
    {
        int count = probes->stock;
        int max_count = probes->max;
        float ratio = max_count > 0 ? static_cast<float>(count) / static_cast<float>(max_count) : 0.0f;
        const string label = tr("probe_abbreviation", "PROBE\nSTORE");

        if (count == 0)
        {
            KorryPresets::applyTypeN(probe_indicator, label, KorryPresets::Color::Red, true);
            probe_indicator->setBlink(false);
        }
        else if (count == 0)
        {
            KorryPresets::applyTypeB(probe_indicator, label, KorryPresets::Color::Red, true);
            probe_indicator->setBlink(false);
        }
        else if (ratio < 0.34f)
        {
            KorryPresets::applyTypeB(probe_indicator, label, KorryPresets::Color::Amber, true);
            probe_indicator->setBlink(false);
        }
        else
        {
            KorryPresets::applyTypeS(probe_indicator, label, KorryPresets::Color::Green, false);
            probe_indicator->setBlink(false);
        }
        probe_indicator->show();
    }
    else
        probe_indicator->hide();
}

void SystemStatusScreen::updateSelfDestructIndicator()
{
    if (auto sd = my_spaceship.getComponent<SelfDestruct>())
    {
        const string label = tr("self_destruct_abbreviation", "SELF-\nDESTRUCT");

        if (!sd->active)
        {
            KorryPresets::applyTypeS(selfdestruct_indicator, label, KorryPresets::Color::Red, false);
            selfdestruct_indicator->setBlink(false);
        }
        else
        {
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
                KorryPresets::applyTypeB(selfdestruct_indicator, label, KorryPresets::Color::Red, true);
                selfdestruct_indicator->setBlink(true, BLINK_WARNING);
            }
            else
            {
                KorryPresets::applyTypeB(selfdestruct_indicator, label, KorryPresets::Color::Amber, true);
                selfdestruct_indicator->setBlink(true, BLINK_CAUTION);
            }
        }
        selfdestruct_indicator->show();
    }
    else
        selfdestruct_indicator->hide();
}
