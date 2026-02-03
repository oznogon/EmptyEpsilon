#include "systemStatusScreen.h"
#include "playerInfo.h"
#include "gameGlobalInfo.h"
#include "i18n.h"

#include "components/beamweapon.h"
#include "components/comms.h"
#include "components/coolant.h"
#include "components/docking.h"
#include "components/hull.h"
#include "components/impulse.h"
#include "components/internalrooms.h"
#include "components/jumpdrive.h"
#include "components/maneuveringthrusters.h"
#include "components/missiletubes.h"
#include "components/probe.h"
#include "components/reactor.h"
#include "components/scanning.h"
#include "components/selfdestruct.h"
#include "components/shields.h"
#include "components/target.h"
#include "components/warpdrive.h"
#include "systems/missilesystem.h"

#include "screenComponents/alertOverlay.h"

#include "gui/gui2_indicatorlight.h"
#include "gui/gui2_label.h"
#include "gui/gui2_panel.h"
#include "gui/gui2_selector.h"

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
        tr("ship_system_abbreviation", "SHIELD\nFWD GEN"),
        tr("ship_system_abbreviation", "SHIELD\nREAR GEN")
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

    tab_selector = new GuiSelector(this, "SYSTEMS_TAB_SELECTOR",
        [this](int index, string value)
        {
            if (value == "overview")
                overview_tab->show();
        }
    );

    // Create tabs
    createOverviewTab();

    tab_selector
        ->setSelectionIndex(0)
        ->setPosition(0.0f, 0.0f, sp::Alignment::BottomLeft)
        ->setSize(150.0f, 50.0f);
}

GuiIndicatorLight* SystemStatusScreen::createIndicator(GuiElement* parent, const string& id, const string& label)
{
    auto* indicator = new GuiIndicatorLight(parent, id, false);
    indicator->setSize(INDICATOR_WIDTH, INDICATOR_HEIGHT);
    AnnunciatorPresets::applyTypeS(indicator, label, AnnunciatorPresets::Color::Green, false);
    return indicator;
}

string SystemStatusScreen::formatAngle(float degrees)
{
    // Normalize to 0-360
    while (degrees < 0) degrees += 360.0f;
    while (degrees >= 360.0f) degrees -= 360.0f;

    // Always return degrees
    return string(static_cast<int>(degrees)) + "\xC2\xB0"; // UTF-8 degree symbol
}

void SystemStatusScreen::createOverviewTab()
{
    tab_selector->addEntry(tr("systems_status_tabs", "Overview"), "overview");
    overview_tab = new GuiElement(this, "");
    overview_tab
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Create panels
    createSystemsPanel();
    createDefensesPanel();
    createWeaponsPanel();
    createPropulsionPanel();
    createTransmitterPanel();
}

void SystemStatusScreen::createSystemsPanel()
{
    systems_panel = new GuiElement(overview_tab, "SYSTEMS_PANEL");
    systems_panel
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setMargins(PANEL_PADDING)
        ->setAttribute("layout", "vertical");

    (new GuiLabel(systems_panel, "", tr("SHIP SYSTEMS"), 24.0f))
        ->setSize(GuiElement::GuiSizeMax, 35.0f);

        // Energy row (total energy and charge rate)
    energy_row = new GuiElement(systems_panel, "ENERGY_ROW");
    energy_row
        ->setSize(GuiElement::GuiSizeMax, ROW_HEIGHT)
        ->setAttribute("layout", "horizontal");

    energy_indicator = createIndicator(energy_row, "ENERGY_IND", tr("energy_property_abbreviation", "ENERGY\nTOTAL"));
    charge_indicator = createIndicator(energy_row, "CHARGE_IND", tr("energy_property_abbreviation", "CHARGE\nRATE"));

    // Column headers
    auto* header_row = new GuiElement(systems_panel, "SYS_HEADER");
    header_row->setSize(GuiElement::GuiSizeMax, 20.0f);
    header_row->setAttribute("layout", "horizontal");

    auto createHeaderLabel = [header_row](const string& text, float width) {
        auto* label = new GuiLabel(header_row, "", text, 12.0f);
        label->setSize(width, GuiElement::GuiSizeMax);
    };

    createHeaderLabel(tr("system_property_abbreviation", "SYSTEM"), INDICATOR_WIDTH);
    createHeaderLabel(tr("system_property_abbreviation", "POWER"), INDICATOR_WIDTH);
    createHeaderLabel(tr("system_property_abbreviation", "HEAT"), INDICATOR_WIDTH * 3);
    createHeaderLabel(tr("system_property_abbreviation", "DAMAGE"), INDICATOR_WIDTH * 2);

    // System indicator grid
    systems_grid = new GuiElement(systems_panel, "SYSTEMS_GRID");
    systems_grid
        ->setSize(GuiElement::GuiSizeMax, ROW_HEIGHT * ShipSystem::COUNT)
        ->setAttribute("layout", "vertical");

    // Create rows for each ship system
    for (int n = 0; n < ShipSystem::COUNT; n++)
    {
        SystemIndicatorRow sir;
        sir.system_type = ShipSystem::Type(n);

        sir.row = new GuiElement(systems_grid, "SYS_ROW_" + string(n));
        sir.row
            ->setSize(GuiElement::GuiSizeMax, ROW_HEIGHT)
            ->setAttribute("layout", "horizontal");

        sir.name_indicator = createIndicator(sir.row, "SYS_NAME_" + string(n), system_labels[n]);
        sir.power_indicator = createIndicator(sir.row, "SYS_POWER_" + string(n), tr("system_property_abbreviation", "POWER"));
        sir.heat_indicator = createIndicator(sir.row, "SYS_HEAT_" + string(n), tr("system_property_abbreviation", "HEAT\nTOTAL"));
        sir.heat_delta_indicator = createIndicator(sir.row, "SYS_HEAT_RATE_" + string(n), tr("system_property_abbreviation", "HEAT\nRATE"));
        sir.coolant_indicator = createIndicator(sir.row, "SYS_COOLANT_" + string(n), tr("system_property_abbreviation", "COOLANT"));
        sir.damage_indicator = createIndicator(sir.row, "SYS_DAMAGE_" + string(n), tr("system_property_abbreviation", "DAMAGE"));
        sir.repair_indicator = createIndicator(sir.row, "SYS_REPAIR_" + string(n), tr("system_property_abbreviation", "REPAIR"));

        system_rows.push_back(sir);
    }

    // Initial panel size (will be adjusted based on visible systems)
    float panel_width = INDICATOR_WIDTH * 7 + PANEL_PADDING * 2;
    float panel_height = PANEL_HEADER_HEIGHT + 20.0f + ROW_HEIGHT * (ShipSystem::COUNT + 1) + PANEL_PADDING * 2;
    systems_panel->setSize(panel_width, panel_height);
}

void SystemStatusScreen::createDefensesPanel()
{
    defenses_panel = new GuiElement(overview_tab, "DEFENSES_PANEL");
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
    weapons_panel = new GuiElement(overview_tab, "WEAPONS_PANEL");
    weapons_panel
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopRight)
        ->setAttribute("layout", "vertical");

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
        tir.row
            ->setSize(GuiElement::GuiSizeMax, ROW_HEIGHT)
            ->hide()
            ->setAttribute("layout", "horizontal");

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
    propulsion_panel = new GuiElement(overview_tab, "PROPULSION_PANEL");
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
    // warp_speed_indicator = createIndicator(row, "WARP_SPEED_IND", "WARP");
    jump_indicator = createIndicator(row, "JUMP_IND", "JUMP");
    maneuver_indicator = createIndicator(row, "MANEUVER_IND", "MANUVR");
}

void SystemStatusScreen::createTransmitterPanel()
{
    transmitter_panel = new GuiElement(overview_tab, "TRANSMITTER_PANEL");
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
    string label = "";
    // Energy indicators
    if (auto reactor = my_spaceship.getComponent<Reactor>())
    {
        float ratio = reactor->energy / reactor->max_energy;
        energy_value.update(ratio);
        energy_indicator->show();
        label = tr("energy_abbreviation", "ENERGY\nSTORE");
        if (ratio > 0.8f)
        {
            AnnunciatorPresets::applyTypeS(energy_indicator, label, AnnunciatorPresets::Color::Green, false);
            energy_indicator->setBlink(false);
        }
        else if (ratio > 0.34f)
        {
            AnnunciatorPresets::applyTypeN(energy_indicator, label, AnnunciatorPresets::Color::Green, true);
            energy_indicator->setBlink(false);
        }
        else if (ratio > 0.1f)
        {
            AnnunciatorPresets::applyTypeB(energy_indicator, label, AnnunciatorPresets::Color::Amber, true);
            energy_indicator->setBlink(true, BLINK_CAUTION);
        }
        else
        {
            AnnunciatorPresets::applyTypeB(energy_indicator, label, AnnunciatorPresets::Color::Red, true);
            energy_indicator->setBlink(true, BLINK_WARNING);
        }

        // Charge rate indicator with thresholds
        float rate_per_minute = energy_value.delta() * reactor->max_energy * (60.0f / UPDATE_INTERVAL);
        charge_indicator->show();
        label = tr("energy_abbreviation", "CHARGE\nRATE");
        if (rate_per_minute >= 20.0f)
        {
            // Positive rate >= 20/min: black text on green background
            AnnunciatorPresets::applyTypeB(charge_indicator, label, AnnunciatorPresets::Color::Green, true);
            charge_indicator->setBlink(false);
        }
        else if (rate_per_minute > 3.0f)
        {
            // Positive rate < 20/min: green text on black background
            AnnunciatorPresets::applyTypeN(charge_indicator, label, AnnunciatorPresets::Color::Green, true);
            charge_indicator->setBlink(false);
        }
        else if (abs(rate_per_minute) <= 3.0f)
        {
            // Near zero: nominal (disabled)
            AnnunciatorPresets::applyTypeS(charge_indicator, label, AnnunciatorPresets::Color::Green, false);
            charge_indicator->setBlink(false);
        }
        else if (rate_per_minute >= -100.0f)
        {
            // Moderate negative rate (up to -100/min): amber text on black background
            AnnunciatorPresets::applyTypeN(charge_indicator, label, AnnunciatorPresets::Color::Amber, true);
            charge_indicator->setBlink(false);
        }
        else
        {
            // Severe negative rate (< -100/min): black text on red background
            AnnunciatorPresets::applyTypeB(charge_indicator, label, AnnunciatorPresets::Color::Red, true);
            charge_indicator->setBlink(false);
        }

        energy_row->show();
    }
    else energy_row->hide();

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

        // Get ship system properties
        // Power level
        float power = sys->power_level;
        sir.power_value.update(power);

        // System health/damage (if enabled)
        float health = 0.0f;
        bool auto_repair = false;
        bool uses_system_damage = gameGlobalInfo->use_system_damage;
        if (uses_system_damage)
        {
            health = sys->health;
            if (auto ir = my_spaceship.getComponent<InternalRooms>())
                auto_repair = ir->auto_repair_enabled;
            sir.health_value.update(health);
        }

        // Heat/coolant (if Coolant component is present)
        float heat = 0.0f;
        float coolant = 0.0f;
        float heat_delta = 0.0f;
        bool auto_coolant = false;
        auto coolant_component = my_spaceship.getComponent<Coolant>();
        if (coolant_component)
        {
            heat = sys->heat_level;
            coolant = sys->coolant_level;
            if (coolant_component->auto_levels) auto_coolant = true;
            sir.heat_value.update(heat);
            sir.coolant_value.update(coolant);
            // Use actual heat delta instead of system heating delta to capture
            // other heat sources.
            // Override heat_delta if heat is maxed out but the system reports a
            // heating delta.
            heat_delta = sir.heat_value.delta() * (60.0f / UPDATE_INTERVAL);
            if (heat >= 0.99f && sys->getHeatingDelta() > 0.01f)
                heat_delta = sys->getHeatingDelta();
        }

        string label = system_labels[static_cast<int>(sir.system_type)];

        // Name indicator - overall system status
        if (power < 0.01f)
        {
            AnnunciatorPresets::applyTypeW(sir.name_indicator, label, AnnunciatorPresets::Color::White, true);
            sir.name_indicator->setBlink(false);
        }
        else if (uses_system_damage)
        {
            if (health <= 0.0f)
            {
                AnnunciatorPresets::applyTypeB(sir.name_indicator, label, AnnunciatorPresets::Color::Red, true);
                if (coolant_component && heat >= 0.99f && heat_delta >= 0.01f)
                    sir.name_indicator->setBlink(true, BLINK_WARNING);
                else
                    sir.name_indicator->setBlink(false);
            }
            else if (health < 0.1f)
            {
                AnnunciatorPresets::applyTypeS(sir.name_indicator, label, AnnunciatorPresets::Color::Red, true);
                sir.name_indicator->setBlink(false);
            }
            else if (health < 0.95f)
            {
                AnnunciatorPresets::applyTypeS(sir.name_indicator, label, AnnunciatorPresets::Color::Amber, true);
                sir.name_indicator->setBlink(false);
            }
            else
            {
                AnnunciatorPresets::applyTypeN(sir.name_indicator, label, AnnunciatorPresets::Color::Green, true);
                sir.name_indicator->setBlink(false);
            }
        }
        else
        {
            AnnunciatorPresets::applyTypeN(sir.name_indicator, label, AnnunciatorPresets::Color::Green, true);
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
            AnnunciatorPresets::applyTypeN(sir.power_indicator, label, AnnunciatorPresets::Color::White, true);
            sir.power_indicator->setBlink(false);
        }
        else if (power < 0.99f)
        {
            AnnunciatorPresets::applyTypeB(sir.power_indicator, label, AnnunciatorPresets::Color::Blue, true);
            sir.power_indicator->setBlink(false);
        }
        else if (power > 1.01f)
        {
            AnnunciatorPresets::applyTypeN(sir.power_indicator, label, AnnunciatorPresets::Color::Blue, true);
            sir.power_indicator->setBlink(false);
        }
        else
        {
            // 100% - disabled/dark
            AnnunciatorPresets::applyTypeS(sir.power_indicator, label, AnnunciatorPresets::Color::Green, false);
            sir.power_indicator->setBlink(false);
        }

        // Heat and coolant indicators (if Coolant component is present)
        if (coolant_component)
        {
            label = tr("heat_abbreviation", "HEAT\nTOTAL");
            sir.heat_indicator->show();
            if (heat > 0.9f)
            {
                AnnunciatorPresets::applyTypeB(sir.heat_indicator, label, AnnunciatorPresets::Color::Red, true);
                sir.heat_indicator->setBlink(true, BLINK_WARNING);
            }
            else if (heat > 0.7f)
            {
                AnnunciatorPresets::applyTypeB(sir.heat_indicator, label, AnnunciatorPresets::Color::Amber, true);
                sir.heat_indicator->setBlink(true, BLINK_CAUTION);
            }
            else if (heat > 0.34f)
            {
                AnnunciatorPresets::applyTypeN(sir.heat_indicator, label, AnnunciatorPresets::Color::Amber, true);
                sir.heat_indicator->setBlink(false);
            }
            else
            {
                AnnunciatorPresets::applyTypeS(sir.heat_indicator, label, AnnunciatorPresets::Color::Green, false);
                sir.heat_indicator->setBlink(false);
            }

            label = tr("heat_abbreviation", "HEAT\nRATE");
            sir.heat_delta_indicator->show();
            if (heat > 0.01f)
            {
                if (heat_delta > 5.0f || (heat >= 1.0f && heat_delta > 0.01f))
                {
                    AnnunciatorPresets::applyTypeB(sir.heat_delta_indicator, label, AnnunciatorPresets::Color::Red, true);
                    if (heat >= 1.0f)
                        sir.heat_delta_indicator->setBlink(true, BLINK_WARNING);
                    else
                        sir.heat_delta_indicator->setBlink(false);
                }
                else if (heat_delta > 3.0f)
                {
                    AnnunciatorPresets::applyTypeN(sir.heat_delta_indicator, label, AnnunciatorPresets::Color::Red, true);
                    sir.heat_delta_indicator->setBlink(false);
                }
                else if (heat_delta > 0.1f)
                {
                    AnnunciatorPresets::applyTypeN(sir.heat_delta_indicator, label, AnnunciatorPresets::Color::Amber, true);
                    sir.heat_delta_indicator->setBlink(false);
                }
                else if (heat_delta < -0.1f)
                {
                    AnnunciatorPresets::applyTypeN(sir.heat_delta_indicator, label, AnnunciatorPresets::Color::Green, true);
                    sir.heat_delta_indicator->setBlink(false);
                }
                else
                {
                    AnnunciatorPresets::applyTypeS(sir.heat_delta_indicator, label, AnnunciatorPresets::Color::Green, false);
                    sir.heat_delta_indicator->setBlink(false);
                }
            }
            else
            {
                AnnunciatorPresets::applyTypeS(sir.heat_delta_indicator, label, AnnunciatorPresets::Color::Green, false);
                sir.heat_delta_indicator->setBlink(false);
            }

            label = tr("coolant_abbreviation", "COOLANT");
            sir.coolant_indicator->show();
            if (coolant > 0.1f)
            {
                AnnunciatorPresets::applyTypeN(sir.coolant_indicator, label, auto_coolant ? AnnunciatorPresets::Color::Green : AnnunciatorPresets::Color::Blue, true);
                sir.coolant_indicator->setBlink(false);
            }
            else
            {
                AnnunciatorPresets::applyTypeS(sir.coolant_indicator, label, AnnunciatorPresets::Color::Green, false);
                sir.coolant_indicator->setBlink(false);
            }
        }
        else
        {
            sir.heat_indicator->hide();
            sir.heat_delta_indicator->hide();
            sir.coolant_indicator->hide();
        }

        // Health indicator if ship system damage is enabled
        if (uses_system_damage)
        {
            label = tr("damage_abbreviation", "DAMAGE");
            sir.damage_indicator->show();
            if (health < 0.34f)
            {
                AnnunciatorPresets::applyTypeB(sir.damage_indicator, label, AnnunciatorPresets::Color::Red, true);
                if (sir.health_value.declining() || health <= 0.0f)
                    sir.damage_indicator->setBlink(true, BLINK_WARNING);
                else
                    sir.damage_indicator->setBlink(false);
            }
            else if (health < 0.8f)
            {
                AnnunciatorPresets::applyTypeB(sir.damage_indicator, label, AnnunciatorPresets::Color::Amber, true);
                if (sir.health_value.declining())
                    sir.damage_indicator->setBlink(true, BLINK_CAUTION);
                else
                    sir.damage_indicator->setBlink(false);
            }
            else if (health < 0.99f)
            {
                AnnunciatorPresets::applyTypeS(sir.damage_indicator, label, AnnunciatorPresets::Color::Amber, true);
                sir.damage_indicator->setBlink(false);
            }
            else
            {
                AnnunciatorPresets::applyTypeS(sir.damage_indicator, label, AnnunciatorPresets::Color::Green, false);
                sir.damage_indicator->setBlink(false);
            }

            // Repair indicator
            label = tr("repair_abbreviation", "REPAIR");
            sir.repair_indicator->show();
            if (health < 1.0f && sir.health_value.improving())
            {
                AnnunciatorPresets::applyTypeS(sir.repair_indicator, label, auto_repair ? AnnunciatorPresets::Color::Green : AnnunciatorPresets::Color::Blue, true);
                sir.repair_indicator->setBlink(false);
            }
            else
            {
                AnnunciatorPresets::applyTypeS(sir.repair_indicator, label, AnnunciatorPresets::Color::Green, false);
                sir.repair_indicator->setBlink(false);
            }
        }
        else
        {
            sir.damage_indicator->hide();
            sir.repair_indicator->hide();
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
            AnnunciatorPresets::applyTypeS(hull_indicator, label, AnnunciatorPresets::Color::Green, false);
            hull_indicator->setBlink(false);
        }
        else if (ratio > 0.34f)
        {
            // Any damage - degraded (amber)
            AnnunciatorPresets::applyTypeB(hull_indicator, label, AnnunciatorPresets::Color::Amber, true);
            if (hull_value.declining())
                hull_indicator->setBlink(true, BLINK_CAUTION);
            else
                hull_indicator->setBlink(false);
        }
        else
        {
            // Critical damage (red)
            AnnunciatorPresets::applyTypeB(hull_indicator, label, AnnunciatorPresets::Color::Red, true);
            hull_indicator->setBlink(true, BLINK_WARNING);
        }
        hull_indicator->show();
    }
    else
        hull_indicator->hide();

    // Shields
    // Shields down: text colors on black background
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
            bool is_critical = seg_ratio < 0.25f;

            if (!shields_up)
            {
                // Shields down: text colors on black background
                // Red: Inactive shield charge is critically low (<25%)
                if (is_critical)
                {
                    AnnunciatorPresets::applyTypeN(si.indicator, label, AnnunciatorPresets::Color::Red, true);
                    if (is_changing)
                        si.indicator->setBlink(true, BLINK_WARNING);
                    else
                        si.indicator->setBlink(false);
                }
                // Amber: Inactive shield charge is <99% but not critical
                else if (is_damaged)
                {
                    AnnunciatorPresets::applyTypeN(si.indicator, label, AnnunciatorPresets::Color::Amber, true);
                    if (is_changing)
                        si.indicator->setBlink(true, BLINK_CAUTION);
                    else
                        si.indicator->setBlink(false);
                }
                // Off: Inactive shield charge is >99% (nominal and automatic)
                else
                {
                    AnnunciatorPresets::applyTypeN(si.indicator, label, AnnunciatorPresets::Color::White, false);
                    si.indicator->setBlink(false);
                }
            }
            else
            {
                // Shields up: Black text on colored backgrounds
                // Red: Active shield charge is critically low (<25%)
                if (is_critical)
                {
                    AnnunciatorPresets::applyTypeB(si.indicator, label, AnnunciatorPresets::Color::Red, true);
                    if (is_changing)
                        si.indicator->setBlink(true, BLINK_WARNING);
                    else
                        si.indicator->setBlink(false);
                }
                // Amber: Active shield charge is <99% but not critical
                else if (is_damaged)
                {
                    AnnunciatorPresets::applyTypeB(si.indicator, label, AnnunciatorPresets::Color::Amber, true);
                    if (is_changing)
                        si.indicator->setBlink(true, BLINK_CAUTION);
                    else
                        si.indicator->setBlink(false);
                }
                // Blue: Active shield charge is >99% (nominal but manual)
                else
                {
                    AnnunciatorPresets::applyTypeB(si.indicator, label, AnnunciatorPresets::Color::Blue, true);
                    si.indicator->setBlink(false);
                }
            }
            si.indicator->show();
        }

        for (size_t i = shields->entries.size(); i < shield_indicators.size(); i++)
            shield_indicators[i].indicator->hide();

        float ratio = total_max > 0.0f ? total_shield / total_max : 0.0f;
    }
    else
    {
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
                AnnunciatorPresets::applyTypeB(weapon_storage_indicators[n], label, AnnunciatorPresets::Color::Red, true);
                weapon_storage_indicators[n]->setBlink(false);
            }
            else if (count == 1)
            {
                AnnunciatorPresets::applyTypeN(weapon_storage_indicators[n], label, AnnunciatorPresets::Color::Red, true);
                weapon_storage_indicators[n]->setBlink(false);
            }
            else if (ratio < 0.5f)
            {
                AnnunciatorPresets::applyTypeN(weapon_storage_indicators[n], label, AnnunciatorPresets::Color::Amber, true);
                weapon_storage_indicators[n]->setBlink(false);
            }
            else
            {
                AnnunciatorPresets::applyTypeS(weapon_storage_indicators[n], label, AnnunciatorPresets::Color::Green, false);
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
                {
                    auto missile_sys = ShipSystem::get(my_spaceship, ShipSystem::Type::MissileSystem);
                    float missile_power = missile_sys ? missile_sys->power_level : 1.0f;
                    float missile_health = missile_sys ? missile_sys->health : 1.0f;

                    if (missile_health <= 0.0f)
                    {
                        AnnunciatorPresets::applyTypeB(tir.tube_indicator, label, AnnunciatorPresets::Color::Red, true);
                        tir.tube_indicator->setBlink(true, BLINK_WARNING);
                    }
                    else if (missile_power < 0.01f)
                    {
                        AnnunciatorPresets::applyTypeB(tir.tube_indicator, label, AnnunciatorPresets::Color::White, true);
                        tir.tube_indicator->setBlink(false);
                    }
                    else if (missile_power < 1.0f || missile_health < 1.0f)
                    {
                        AnnunciatorPresets::applyTypeN(tir.tube_indicator, label, AnnunciatorPresets::Color::Amber, true);
                        tir.tube_indicator->setBlink(false);
                    }
                    else
                    {
                        AnnunciatorPresets::applyTypeS(tir.tube_indicator, label, AnnunciatorPresets::Color::Green, false);
                        tir.tube_indicator->setBlink(false);
                    }
                }
                break;
            case MissileTubes::MountPoint::State::Loading:
                AnnunciatorPresets::applyTypeN(tir.tube_indicator, label, AnnunciatorPresets::Color::Blue, true);
                tir.tube_indicator->setBlink(true, BLINK_CAUTION);
                break;
            case MissileTubes::MountPoint::State::Loaded:
                AnnunciatorPresets::applyTypeN(tir.tube_indicator, label, AnnunciatorPresets::Color::Blue, true);
                tir.tube_indicator->setBlink(false);
                break;
            case MissileTubes::MountPoint::State::Unloading:
                AnnunciatorPresets::applyTypeN(tir.tube_indicator, label, AnnunciatorPresets::Color::Blue, true);
                tir.tube_indicator->setBlink(true, BLINK_CAUTION);
                break;
            case MissileTubes::MountPoint::State::Firing:
                AnnunciatorPresets::applyTypeB(tir.tube_indicator, label, AnnunciatorPresets::Color::Blue, true);
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
                    // Tube doesn't support this weapon type, so indicate as much
                    AnnunciatorPresets::applyTypeS(tir.weapon_indicators[w], "----", AnnunciatorPresets::Color::Green, false);
                    tir.weapon_indicators[w]->setBlink(false);
                }
                else if (is_loading)
                {
                    // Loading: Blue text on black background, blinking (manual, active progress)
                    AnnunciatorPresets::applyTypeN(tir.weapon_indicators[w], weapon_labels[w], AnnunciatorPresets::Color::Blue, true);
                    tir.weapon_indicators[w]->setBlink(true, BLINK_CAUTION);
                }
                else if (is_unloading)
                {
                    // Unloading: Black text on blue background, blinking (manual, active regress)
                    AnnunciatorPresets::applyTypeB(tir.weapon_indicators[w], weapon_labels[w], AnnunciatorPresets::Color::Blue, true);
                    tir.weapon_indicators[w]->setBlink(true, BLINK_CAUTION);
                }
                else if (is_loaded)
                {
                    // Loaded: Blue text on black background, solid (manual, passive)
                    AnnunciatorPresets::applyTypeN(tir.weapon_indicators[w], weapon_labels[w], AnnunciatorPresets::Color::Blue, true);
                    tir.weapon_indicators[w]->setBlink(false);
                }
                else
                {
                    // Available but not loaded (nominal)
                    AnnunciatorPresets::applyTypeS(tir.weapon_indicators[w], weapon_labels[w], AnnunciatorPresets::Color::Green, false);
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

    tubes_grid
        ->setSize(GuiElement::GuiSizeMax, ROW_HEIGHT * visible_tube_count);

    // Beam weapons
    if (auto beams = my_spaceship.getComponent<BeamWeaponSys>())
    {
        for (size_t i = 0; i < beams->mounts.size() && i < beam_indicators.size(); i++)
        {
            auto& mount = beams->mounts[i];
            auto& bi = beam_indicators[i];
            bool valid_target = false;
            auto target = my_spaceship.getComponent<Target>();
            if (target && target->entity != sp::ecs::Entity()) valid_target = true;

            bi.direction = mount.direction;
            string angle_label = tr("beam_abbreviation", "BEAM") + "\n" + formatAngle(mount.direction);

            float cooldown_ratio = mount.cycle_time > 0.0f ? mount.cooldown / mount.cycle_time : 0.0f;
            bi.cooldown_value.update(1.0f - cooldown_ratio);

            if (cooldown_ratio > 0.8f)
            {
                AnnunciatorPresets::applyTypeN(bi.indicator, angle_label, AnnunciatorPresets::Color::Blue, true);
                bi.indicator->setBlink(true, BLINK_CAUTION);
            }
            else if (cooldown_ratio > 0.01f)
            {
                AnnunciatorPresets::applyTypeN(bi.indicator, angle_label, AnnunciatorPresets::Color::Blue, true);
                bi.indicator->setBlink(false);
            }
            else if (beams->health <= 0.0f)
            {
                AnnunciatorPresets::applyTypeB(bi.indicator, angle_label, AnnunciatorPresets::Color::Red, true);
                bi.indicator->setBlink(true, BLINK_WARNING);
            }
            else if (beams->power_level <= 0.0f)
            {
                AnnunciatorPresets::applyTypeN(bi.indicator, angle_label, AnnunciatorPresets::Color::White, true);
                bi.indicator->setBlink(false);
            }
            else if (beams->health < 0.99f || beams->power_level < 0.99f)
            {
                AnnunciatorPresets::applyTypeN(bi.indicator, angle_label, AnnunciatorPresets::Color::Amber, true);
                bi.indicator->setBlink(false);
            }
            else if (valid_target)
            {
                AnnunciatorPresets::applyTypeS(bi.indicator, angle_label, AnnunciatorPresets::Color::Green, true);
                bi.indicator->setBlink(false);
            }
            else
            {
                AnnunciatorPresets::applyTypeS(bi.indicator, angle_label, AnnunciatorPresets::Color::Green, false);
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
            AnnunciatorPresets::applyTypeN(impulse_indicator, "IMPULSE", AnnunciatorPresets::Color::Blue, true);
            impulse_indicator->setBlink(false);
        }
        else
        {
            AnnunciatorPresets::applyTypeS(impulse_indicator, "IMPULSE", AnnunciatorPresets::Color::Green, false);
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
            AnnunciatorPresets::applyTypeN(warp_indicator, "WARP", AnnunciatorPresets::Color::Blue, true);
            warp_indicator->setBlink(false);
        }
        else
        {
            AnnunciatorPresets::applyTypeS(warp_indicator, "WARP", AnnunciatorPresets::Color::Green, false);
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
            AnnunciatorPresets::applyTypeB(jump_indicator, label, AnnunciatorPresets::Color::Red, true);
            jump_indicator->setBlink(false);
        }
        else if (delay > 0)
        {
            AnnunciatorPresets::applyTypeB(jump_indicator, label, AnnunciatorPresets::Color::Blue, true);
            jump_indicator->setBlink(true, delay / 10.0f);
        }
        else if (charge_ratio < 0.99f)
        {
            AnnunciatorPresets::applyTypeN(jump_indicator, label, AnnunciatorPresets::Color::Amber, true);
            jump_indicator->setBlink(false);
        }
        else
        {
            AnnunciatorPresets::applyTypeS(jump_indicator, label, AnnunciatorPresets::Color::Green, false);
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
            AnnunciatorPresets::applyTypeN(maneuver_indicator, label, AnnunciatorPresets::Color::Blue, true);
            maneuver_indicator->setBlink(true, BLINK_WARNING);
        }
        else if (cm->charge < 0.99f)
        {
            AnnunciatorPresets::applyTypeN(maneuver_indicator, label, AnnunciatorPresets::Color::Amber, true);
            maneuver_indicator->setBlink(false);
        }
        else
        {
            AnnunciatorPresets::applyTypeS(maneuver_indicator, label, AnnunciatorPresets::Color::Green, false);
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
            AnnunciatorPresets::applyTypeS(comms_indicator, label, AnnunciatorPresets::Color::Green, false);
            comms_indicator->setBlink(false);
            break;
        case CommsTransmitter::State::OpeningChannel:
            AnnunciatorPresets::applyTypeN(comms_indicator, label, AnnunciatorPresets::Color::Blue, true);
            comms_indicator->setBlink(true, BLINK_CAUTION);
            break;
        case CommsTransmitter::State::BeingHailed:
        case CommsTransmitter::State::BeingHailedByGM:
            AnnunciatorPresets::applyTypeB(comms_indicator, label, AnnunciatorPresets::Color::Blue, true);
            comms_indicator->setBlink(true, BLINK_CAUTION);
            break;
        case CommsTransmitter::State::ChannelOpen:
        case CommsTransmitter::State::ChannelOpenGM:
        case CommsTransmitter::State::ChannelOpenPlayer:
            AnnunciatorPresets::applyTypeN(comms_indicator, label, AnnunciatorPresets::Color::Blue, true);
            comms_indicator->setBlink(false);
            break;
        case CommsTransmitter::State::ChannelFailed:
        case CommsTransmitter::State::ChannelBroken:
            AnnunciatorPresets::applyTypeB(comms_indicator, label, AnnunciatorPresets::Color::Red, true);
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
            AnnunciatorPresets::applyTypeN(scan_indicator, label, AnnunciatorPresets::Color::Blue, true);
            scan_indicator->setBlink(false);  // No blink
        }
        else
        {
            AnnunciatorPresets::applyTypeS(scan_indicator, label, AnnunciatorPresets::Color::Green, false);
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
            AnnunciatorPresets::applyTypeS(dock_indicator, label, AnnunciatorPresets::Color::Green, false);
            dock_indicator->setBlink(false);
            break;
        case DockingPort::State::Docking:
            AnnunciatorPresets::applyTypeN(dock_indicator, label, AnnunciatorPresets::Color::Blue, true);
            dock_indicator->setBlink(false);  // No blink
            break;
        case DockingPort::State::Docked:
            AnnunciatorPresets::applyTypeN(dock_indicator, label, AnnunciatorPresets::Color::Green, true);
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
            AnnunciatorPresets::applyTypeN(probe_indicator, label, AnnunciatorPresets::Color::Red, true);
            probe_indicator->setBlink(false);
        }
        else if (count == 0)
        {
            AnnunciatorPresets::applyTypeB(probe_indicator, label, AnnunciatorPresets::Color::Red, true);
            probe_indicator->setBlink(false);
        }
        else if (ratio < 0.34f)
        {
            AnnunciatorPresets::applyTypeB(probe_indicator, label, AnnunciatorPresets::Color::Amber, true);
            probe_indicator->setBlink(false);
        }
        else
        {
            AnnunciatorPresets::applyTypeS(probe_indicator, label, AnnunciatorPresets::Color::Green, false);
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
            AnnunciatorPresets::applyTypeS(selfdestruct_indicator, label, AnnunciatorPresets::Color::Red, false);
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
                AnnunciatorPresets::applyTypeB(selfdestruct_indicator, label, AnnunciatorPresets::Color::Red, true);
                selfdestruct_indicator->setBlink(true, BLINK_WARNING);
            }
            else
            {
                AnnunciatorPresets::applyTypeB(selfdestruct_indicator, label, AnnunciatorPresets::Color::Amber, true);
                selfdestruct_indicator->setBlink(true, BLINK_CAUTION);
            }
        }
        selfdestruct_indicator->show();
    }
    else
        selfdestruct_indicator->hide();
}
