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
#include <limits>

/**
 * Color usage:
 *
 * BLACK - Normal operation, no attention needed
 *         System is working correctly in its expected state
 *
 * BLUE  - Manual operation in progress
 *         Pilot has manually engaged/selected something
 *
 * GREEN - Automatic operation active
 *         System is automatically running/managing itself
 *
 * WHITE - System OFF when it should be ON
 *         Something is not running that should be
 *
 * AMBER - CAUTION: Degraded operation, needs attention
 *         System has failed or is degraded (single chime, flashing)
 *
 * RED   - WARNING: Critical condition, immediate action required
 *         Serious failure requiring immediate response (continuous chime, flashing)
 *
 * Status is communicated through COLOR and BLINKING only.
 * Text labels remain static.
 */

SystemStatusScreen::SystemStatusScreen(GuiContainer* owner)
: GuiOverlay(owner, "SYSTEM_STATUS_SCREEN", colorConfig.background)
{
    // Background
    background_crosses = new GuiOverlay(this, "BACKGROUND_CROSSES", glm::u8vec4{255,255,255,255});
    background_crosses->setTextureTiled("gui/background/crosses.png");

    // Alert overlay
    (new AlertLevelOverlay(this));

    // Create panels
    createSystemsPanel();
    createDefensesPanel();
    createWeaponsPanel();
    createStatusPanel();
}

GuiIndicatorLight* SystemStatusScreen::createIndicator(GuiElement* parent, const string& id, const string& label)
{
    auto* indicator = new GuiIndicatorLight(parent, id, false);
    indicator->setSize(INDICATOR_WIDTH, INDICATOR_HEIGHT);

    // Start in dark cockpit state (Type S - hidden legend, non-energized)
    KorryPresets::applyTypeS(indicator, label, KorryPresets::Color::Green, false);

    return indicator;
}

void SystemStatusScreen::createSystemsPanel()
{
    // TODO: Use parent layout container and padding
    systems_panel = new GuiPanel(this, "SYSTEMS_PANEL");
    systems_panel
        ->setPosition(20.0f, 80.0f, sp::Alignment::TopLeft)
        ->setSize(520.0f, 450.0f);

    auto* container = new GuiElement(systems_panel, "SYSTEMS_CONTAINER");
    container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setMargins(10.0f)
        ->setAttribute("layout", "vertical");

    (new GuiLabel(container, "", tr("SHIP SYSTEMS"), 24.0f))
        ->setSize(GuiElement::GuiSizeMax, 35.0f);

    // Create system indicators in a grid
    auto* grid = new GuiElement(container, "SYSTEMS_GRID");
    grid
        ->setSize(GuiElement::GuiSizeMax, 380.0f)
        ->setAttribute("layout", "vertical");

    auto* row1 = new GuiElement(container, "SYS_ROW1");
    row1
        ->setSize(GuiElement::GuiSizeMax, INDICATOR_HEIGHT + INDICATOR_MARGIN)
        ->setAttribute("layout", "horizontal");

    // Energy indicators
    energy_indicator = createIndicator(row1, "ENERGY_IND", "ENERGY");
    charge_indicator = createIndicator(row1, "CHARGE_IND", "CHARGE");

    // System names for display (abbreviated for indicator)
    const string system_labels[] = {
        tr("REACTOR"),
        tr("BEAM\nWPN"),
        tr("MISSILE\nSYS"),
        tr("MANEUVER"),
        tr("IMPULSE"),
        tr("WARP"),
        tr("JUMP\nDRIVE"),
        tr("FWD\nSHLD"),
        tr("AFT\nSHLD")
    };

    system_rows.resize(ShipSystem::COUNT, nullptr);
    for (int n = 0; n < ShipSystem::COUNT; n++)
    {
        SystemIndicator si;
        si.system_type = ShipSystem::Type(n);
        system_rows[n] = new GuiElement(grid, "");
        system_rows[n]
            ->setSize(GuiElement::GuiSizeMax, INDICATOR_HEIGHT)
            ->setAttribute("layout", "horizontal");
        si.indicator = createIndicator(system_rows[n], "SYS_" + string(n), system_labels[n]);
        system_indicators.push_back(si);
    }
}

void SystemStatusScreen::createDefensesPanel()
{
    defenses_panel = new GuiPanel(this, "DEFENSES_PANEL");
    defenses_panel
        ->setPosition(20.0f, 550.0f, sp::Alignment::TopLeft)
        ->setSize(520.0f, 250.0f);

    auto* container = new GuiElement(defenses_panel, "DEFENSES_CONTAINER");
    container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setMargins(10.0f)
        ->setAttribute("layout", "vertical");

    (new GuiLabel(container, "", tr("DEFENSES"), 24.0f))
        ->setSize(GuiElement::GuiSizeMax, 35.0f);

    auto* row1 = new GuiElement(container, "DEF_ROW1");
    row1
        ->setSize(GuiElement::GuiSizeMax, INDICATOR_HEIGHT + INDICATOR_MARGIN)
        ->setAttribute("layout", "horizontal");

    // Hull indicator
    hull_indicator = createIndicator(row1, "HULL_IND", "HULL");

    // Shield status indicator (overall)
    shields_status_indicator = createIndicator(row1, "SHLD_STATUS", "SHIELDS");

    auto* row2 = new GuiElement(container, "DEF_ROW2");
    row2->setSize(GuiElement::GuiSizeMax, INDICATOR_HEIGHT + INDICATOR_MARGIN);
    row2->setAttribute("layout", "horizontal");

    // Shield segment indicators (created dynamically, up to 8)
    for (int i = 0; i < 8; i++)
    {
        ShieldIndicator si;
        si.segment_index = i;
        si.indicator = createIndicator(row2, "SHLD_" + string(i), "SHLD\n" + string(i + 1));
        si.indicator->hide();  // Hidden until we know how many shields exist
        shield_indicators.push_back(si);
    }
}

void SystemStatusScreen::createWeaponsPanel()
{
    weapons_panel = new GuiPanel(this, "WEAPONS_PANEL");
    weapons_panel->setPosition(560, 80, sp::Alignment::TopLeft)->setSize(440, 450);

    auto* container = new GuiElement(weapons_panel, "WEAPONS_CONTAINER");
    container->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    container->setMargins(10);
    container->setAttribute("layout", "vertical");

    (new GuiLabel(container, "", tr("WEAPONS"), 24))->setSize(GuiElement::GuiSizeMax, 35);

    // Weapon storage row
    auto* storage_row = new GuiElement(container, "STORAGE_ROW");
    storage_row->setSize(GuiElement::GuiSizeMax, INDICATOR_HEIGHT + INDICATOR_MARGIN);
    storage_row->setAttribute("layout", "horizontal");

    const char* weapon_labels[] = {"HOMING", "NUKE", "MINE", "EMP", "HVLI"};
    for (int n = 0; n < MW_Count; n++)
    {
        weapon_storage_indicators[n] = createIndicator(storage_row, "WPN_" + string(n), weapon_labels[n]);
    }

    // Probe indicator
    auto* probe_row = new GuiElement(container, "PROBE_ROW");
    probe_row->setSize(GuiElement::GuiSizeMax, INDICATOR_HEIGHT + INDICATOR_MARGIN);
    probe_row->setAttribute("layout", "horizontal");

    probe_indicator = createIndicator(probe_row, "PROBE_IND", "PROBES");

    // Tube indicators section
    (new GuiLabel(container, "", tr("Missile Tubes:"), 18))->setSize(GuiElement::GuiSizeMax, 25);

    auto* tubes_container = new GuiElement(container, "TUBES_CONTAINER");
    tubes_container->setSize(GuiElement::GuiSizeMax, INDICATOR_HEIGHT + INDICATOR_MARGIN);
    tubes_container->setAttribute("layout", "horizontal");

    // Create tube indicators (up to 16)
    for (int i = 0; i < 16; i++)
    {
        TubeIndicator ti;
        ti.indicator = createIndicator(tubes_container, "TUBE_" + string(i), "TUBE\n" + string(i + 1));
        ti.indicator->hide();  // Hidden until we know how many tubes exist
        tube_indicators.push_back(ti);
    }

    // Beam indicators section
    (new GuiLabel(container, "", tr("Beam Weapons:"), 18))->setSize(GuiElement::GuiSizeMax, 25);

    auto* beams_container = new GuiElement(container, "BEAMS_CONTAINER");
    beams_container->setSize(GuiElement::GuiSizeMax, INDICATOR_HEIGHT + INDICATOR_MARGIN);
    beams_container->setAttribute("layout", "horizontal");

    // Create beam indicators (up to 16)
    for (int i = 0; i < 16; i++)
    {
        BeamIndicator bi;
        bi.indicator = createIndicator(beams_container, "BEAM_" + string(i), "BEAM\n" + string(i + 1));
        bi.indicator->hide();  // Hidden until we know how many beams exist
        beam_indicators.push_back(bi);
    }
}

void SystemStatusScreen::createStatusPanel()
{
    status_panel = new GuiPanel(this, "STATUS_PANEL");
    status_panel->setPosition(560, 550, sp::Alignment::TopLeft)->setSize(440, 250);

    auto* container = new GuiElement(status_panel, "STATUS_CONTAINER");
    container->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    container->setMargins(10);
    container->setAttribute("layout", "vertical");

    (new GuiLabel(container, "", tr("STATUS"), 24))->setSize(GuiElement::GuiSizeMax, 35);

    // Row 1: Drive systems
    auto* row1 = new GuiElement(container, "STATUS_ROW1");
    row1->setSize(GuiElement::GuiSizeMax, INDICATOR_HEIGHT + INDICATOR_MARGIN);
    row1->setAttribute("layout", "horizontal");

    impulse_indicator = createIndicator(row1, "IMPULSE_IND", "IMPULSE");
    warp_indicator = createIndicator(row1, "WARP_IND", "WARP");
    jump_indicator = createIndicator(row1, "JUMP_IND", "JUMP");
    maneuver_indicator = createIndicator(row1, "MANEUVER_IND", "COMBAT\nMNVR");

    // Row 2: Communications and sensors
    auto* row2 = new GuiElement(container, "STATUS_ROW2");
    row2->setSize(GuiElement::GuiSizeMax, INDICATOR_HEIGHT + INDICATOR_MARGIN);
    row2->setAttribute("layout", "horizontal");

    comms_indicator = createIndicator(row2, "COMMS_IND", "COMMS");
    scan_indicator = createIndicator(row2, "SCAN_IND", "SCANNER");
    target_indicator = createIndicator(row2, "TARGET_IND", "TARGET");
    dock_indicator = createIndicator(row2, "DOCK_IND", "DOCKING");

    // Row 3: Emergency
    auto* row3 = new GuiElement(container, "STATUS_ROW3");
    row3->setSize(GuiElement::GuiSizeMax, INDICATOR_HEIGHT + INDICATOR_MARGIN);
    row3->setAttribute("layout", "horizontal");

    selfdestruct_indicator = createIndicator(row3, "SCUT_IND", "SELF\nDESTRUCT");
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
        updateStatusIndicators();
    }
}

void SystemStatusScreen::applyDarkCockpitStyle(GuiIndicatorLight* indicator, const string& label,
                                                float health_ratio, float threshold_caution,
                                                float threshold_warning)
{
    indicator->setBlink(false);

    if (health_ratio >= threshold_caution)
    {
        // Normal operation - BLACK (dark cockpit, hidden legend)
        KorryPresets::applyTypeS(indicator, label, KorryPresets::Color::Green, false);
    }
    else if (health_ratio >= threshold_warning)
    {
        // Caution - AMBER with flashing
        KorryPresets::applyTypeB(indicator, label, KorryPresets::Color::Amber, true);
        indicator->setBlink(true, 0.5f);
    }
    else if (health_ratio > 0.01f)
    {
        // Warning - RED with fast flashing
        KorryPresets::applyTypeB(indicator, label, KorryPresets::Color::Red, true);
        indicator->setBlink(true, 0.25f);
    }
    else
    {
        // Critical/Failed - RED solid
        KorryPresets::applyTypeB(indicator, label, KorryPresets::Color::Red, true);
    }
}

void SystemStatusScreen::updateSystemIndicators()
{
    // System names for display (abbreviated for indicator)
    const string system_labels[] = {
        "REACTOR",
        "BEAM\nWPN",
        "MISSILE\nSYS",
        "MANEUVER",
        "IMPULSE",
        "WARP",
        "JUMP\nDRIVE",
        "FWD\nSHLD",
        "AFT\nSHLD"
    };

    for (auto& si : system_indicators)
    {
        auto sys = ShipSystem::get(my_spaceship, si.system_type);

        if (!sys)
        {
            si.indicator->hide();
            continue;
        }

        si.indicator->show();

        float health = sys->health;
        float heat = sys->heat_level;
        float power = sys->power_level;

        si.health_value.update(health);
        si.heat_value.update(heat);
        si.power_value.update(power);

        // Get static system label
        string label = system_labels[static_cast<int>(si.system_type)];

        // Check power state
        if (power < 0.01f)
        {
            // System is OFF - WHITE indicates OFF when should be ON
            KorryPresets::applyTypeN(si.indicator, label, KorryPresets::Color::White, true);
            si.indicator->setBlink(false);
        }
        else if (heat > 0.9f)
        {
            // Overheating - RED WARNING
            KorryPresets::applyTypeB(si.indicator, label, KorryPresets::Color::Red, true);
            si.indicator->setBlink(true, 0.1f);
        }
        else if (health < 0.3f)
        {
            // Damaged - RED WARNING
            KorryPresets::applyTypeB(si.indicator, label, KorryPresets::Color::Red, true);
            si.indicator->setBlink(true, 0.25f);
        }
        else if (health < 0.8f || heat > 0.5f)
        {
            // Degraded - AMBER CAUTION
            KorryPresets::applyTypeB(si.indicator, label, KorryPresets::Color::Amber, true);
            if (si.health_value.declining() || si.heat_value.improving())
                si.indicator->setBlink(true, 0.5f);
        }
        else
        {
            // Normal - BLACK (dark cockpit)
            KorryPresets::applyTypeS(si.indicator, label, KorryPresets::Color::Green, false);
            si.indicator->setBlink(false);
        }
    }
}

void SystemStatusScreen::updateDefenseIndicators()
{
    // Hull indicator
    if (auto hull = my_spaceship.getComponent<Hull>())
    {
        float ratio = hull->current / hull->max;
        hull_value.update(ratio);

        if (ratio > 0.8f)
        {
            // Normal - dark
            KorryPresets::applyTypeS(hull_indicator, "HULL", KorryPresets::Color::Green, false);
            hull_indicator->setBlink(false);
        }
        else if (ratio > 0.3f)
        {
            // Caution - AMBER
            KorryPresets::applyTypeB(hull_indicator, "HULL", KorryPresets::Color::Amber, true);
            if (hull_value.declining())
                hull_indicator->setBlink(true, 0.5f);
        }
        else
        {
            // Warning - RED
            KorryPresets::applyTypeB(hull_indicator, "HULL", KorryPresets::Color::Red, true);
            hull_indicator->setBlink(true, 0.25f);
        }
        hull_indicator->show();
    }
    else
    {
        hull_indicator->hide();
    }

    // Shields
    auto shields = my_spaceship.getComponent<Shields>();
    if (shields && !shields->entries.empty())
    {
        bool shields_up = shields->active;
        float total_shield = 0.0f;
        float total_max = 0.0f;

        for (size_t i = 0; i < shields->entries.size(); i++)
        {
            auto& entry = shields->entries[i];
            total_shield += entry.level;
            total_max += entry.max;

            // Update individual shield segment indicators
            if (i < shield_indicators.size())
            {
                auto& si = shield_indicators[i];
                float seg_ratio = entry.max > 0.0f ? entry.level / entry.max : 0.0f;
                si.value.update(seg_ratio);

                if (!shields_up)
                {
                    // Shields down - WHITE
                    KorryPresets::applyTypeN(si.indicator, "SHLD\n" + string(static_cast<int>(i + 1)), KorryPresets::Color::White, true);
                    si.indicator->setBlink(false);
                }
                else if (seg_ratio > 0.8f)
                {
                    // Normal - dark
                    KorryPresets::applyTypeS(si.indicator, "SHLD\n" + string(static_cast<int>(i + 1)), KorryPresets::Color::Green, false);
                    si.indicator->setBlink(false);
                }
                else if (seg_ratio > 0.3f)
                {
                    // Degraded - AMBER
                    KorryPresets::applyTypeB(si.indicator, "SHLD\n" + string(static_cast<int>(i + 1)), KorryPresets::Color::Amber, true);
                    if (si.value.declining())
                        si.indicator->setBlink(true, 0.5f);
                }
                else
                {
                    // Critical - RED
                    KorryPresets::applyTypeB(si.indicator, "SHLD\n" + string(static_cast<int>(i + 1)), KorryPresets::Color::Red, true);
                    si.indicator->setBlink(true, 0.25f);
                }
                si.indicator->show();
            }
        }

        // Hide unused shield indicators
        for (size_t i = shields->entries.size(); i < shield_indicators.size(); i++)
            shield_indicators[i].indicator->hide();

        float ratio = total_max > 0.0f ? total_shield / total_max : 0.0f;

        if (!shields_up)
        {
            // Shields DOWN - WHITE (OFF when should be ON)
            KorryPresets::applyTypeN(shields_status_indicator, "SHIELDS", KorryPresets::Color::White, true);
            shields_status_indicator->setBlink(false);
        }
        else if (ratio > 0.8f)
        {
            // Shields normal - GREEN (automatic operation)
            KorryPresets::applyTypeN(shields_status_indicator, "SHIELDS", KorryPresets::Color::Green, true);
            shields_status_indicator->setBlink(false);
        }
        else if (ratio > 0.3f)
        {
            // Shields degraded - AMBER
            KorryPresets::applyTypeB(shields_status_indicator, "SHIELDS", KorryPresets::Color::Amber, true);
            shields_status_indicator->setBlink(true, 0.5f);
        }
        else
        {
            // Shields critical - RED
            KorryPresets::applyTypeB(shields_status_indicator, "SHIELDS", KorryPresets::Color::Red, true);
            shields_status_indicator->setBlink(true, 0.25f);
        }
        shields_status_indicator->show();
    }
    else
    {
        shields_status_indicator->hide();
        for (auto& si : shield_indicators)
            si.indicator->hide();
    }

    // Energy
    if (auto reactor = my_spaceship.getComponent<Reactor>())
    {
        float ratio = reactor->energy / reactor->max_energy;
        energy_value.update(ratio);

        if (ratio > 0.3f)
        {
            // Normal - dark or green
            if (ratio > 0.8f)
            {
                KorryPresets::applyTypeS(energy_indicator, "ENERGY", KorryPresets::Color::Green, false);
                energy_indicator->setBlink(false);
            }
            else
            {
                KorryPresets::applyTypeN(energy_indicator, "ENERGY", KorryPresets::Color::Green, true);
                energy_indicator->setBlink(false);
            }
        }
        else if (ratio > 0.1f)
        {
            // Low - AMBER
            KorryPresets::applyTypeB(energy_indicator, "ENERGY", KorryPresets::Color::Amber, true);
            energy_indicator->setBlink(true, 0.5f);
        }
        else
        {
            // Critical - RED
            KorryPresets::applyTypeB(energy_indicator, "ENERGY", KorryPresets::Color::Red, true);
            energy_indicator->setBlink(true, 0.25f);
        }
        energy_indicator->show();

        // Reactor output indicator
        if (energy_value.improving())
        {
            // Charging - GREEN auto
            KorryPresets::applyTypeN(charge_indicator, "REACTOR", KorryPresets::Color::Green, true);
            charge_indicator->setBlink(false);
        }
        else if (energy_value.declining())
        {
            // Draining - AMBER
            KorryPresets::applyTypeB(charge_indicator, "REACTOR", KorryPresets::Color::Amber, true);
            charge_indicator->setBlink(true, 0.5f);
        }
        else
        {
            // Stable - dark
            KorryPresets::applyTypeS(charge_indicator, "REACTOR", KorryPresets::Color::Green, false);
            charge_indicator->setBlink(false);
        }
        charge_indicator->show();
    }
    else
    {
        energy_indicator->hide();
        charge_indicator->hide();
    }
}

void SystemStatusScreen::updateWeaponIndicators()
{
    auto tubes = my_spaceship.getComponent<MissileTubes>();

    // Weapon storage
    const char* weapon_labels[] = {"HOMING", "NUKE", "MINE", "EMP", "HVLI"};

    for (int n = 0; n < MW_Count; n++)
    {
        if (!weapon_storage_indicators[n]) continue;

        weapon_storage_indicators[n]->setBlink(false);

        if (tubes && tubes->storage_max[n] > 0)
        {
            int count = tubes->storage[n];
            int max_count = tubes->storage_max[n];
            float ratio = static_cast<float>(count) / static_cast<float>(max_count);

            if (count == 0)
            {
                // Empty - WHITE (OFF/depleted)
                KorryPresets::applyTypeN(weapon_storage_indicators[n], weapon_labels[n], KorryPresets::Color::White, true);
            }
            else if (ratio < 0.3f)
            {
                // Low - AMBER
                KorryPresets::applyTypeB(weapon_storage_indicators[n], weapon_labels[n], KorryPresets::Color::Amber, true);
            }
            else
            {
                // Normal - dark
                KorryPresets::applyTypeS(weapon_storage_indicators[n], weapon_labels[n], KorryPresets::Color::Green, false);
            }
            weapon_storage_indicators[n]->show();
        }
        else
        {
            weapon_storage_indicators[n]->hide();
        }
    }

    // Probes
    if (auto probes = my_spaceship.getComponent<ScanProbeLauncher>())
    {
        int count = probes->stock;
        int max_count = probes->max;
        float ratio = max_count > 0 ? static_cast<float>(count) / static_cast<float>(max_count) : 0.0f;

        probe_indicator->setBlink(false);

        if (count == 0)
            KorryPresets::applyTypeN(probe_indicator, "PROBES", KorryPresets::Color::White, true);
        else if (ratio < 0.3f)
            KorryPresets::applyTypeB(probe_indicator, "PROBES", KorryPresets::Color::Amber, true);
        else
            KorryPresets::applyTypeS(probe_indicator, "PROBES", KorryPresets::Color::Green, false);

        probe_indicator->show();
    }
    else
        probe_indicator->hide();

    // Missile tubes
    if (tubes)
    {
        for (size_t i = 0; i < tubes->mounts.size() && i < tube_indicators.size(); i++)
        {
            auto& mount = tubes->mounts[i];
            auto& ti = tube_indicators[i];

            string label = "TUBE\n" + string(static_cast<int>(i + 1));

            switch (mount.state)
            {
            case MissileTubes::MountPoint::State::Empty:
                // Empty - dark (normal idle state)
                KorryPresets::applyTypeS(ti.indicator, label, KorryPresets::Color::Green, false);
                ti.indicator->setBlink(false);
                break;

            case MissileTubes::MountPoint::State::Loading:
                // Loading - BLUE (manual operation in progress)
                KorryPresets::applyTypeN(ti.indicator, label, KorryPresets::Color::Blue, true);
                ti.indicator->setBlink(true, 0.5f);
                break;

            case MissileTubes::MountPoint::State::Loaded:
                // Loaded - GREEN (ready)
                KorryPresets::applyTypeN(ti.indicator, label, KorryPresets::Color::Green, true);
                ti.indicator->setBlink(false);
                break;

            case MissileTubes::MountPoint::State::Unloading:
                // Unloading - BLUE (manual operation)
                KorryPresets::applyTypeN(ti.indicator, label, KorryPresets::Color::Blue, true);
                ti.indicator->setBlink(true, 0.5f);
                break;

            case MissileTubes::MountPoint::State::Firing:
                // Firing - RED (action)
                KorryPresets::applyTypeB(ti.indicator, label, KorryPresets::Color::Red, true);
                ti.indicator->setBlink(true, 0.1f);
                break;
            }

            ti.indicator->show();
        }

        // Hide unused tube indicators
        for (size_t i = tubes->mounts.size(); i < tube_indicators.size(); i++)
            tube_indicators[i].indicator->hide();
    }
    else
    {
        for (auto& ti : tube_indicators)
            ti.indicator->hide();
    }

    // Beam weapons
    if (auto beams = my_spaceship.getComponent<BeamWeaponSys>())
    {
        for (size_t i = 0; i < beams->mounts.size() && i < beam_indicators.size(); i++)
        {
            auto& mount = beams->mounts[i];
            auto& bi = beam_indicators[i];

            string label = "BEAM\n" + string(static_cast<int>(i + 1));

            float cooldown_ratio = mount.cooldown > 0.0f ? mount.cooldown / mount.cycle_time : 0.0f;
            bi.cooldown_value.update(1.0f - cooldown_ratio);

            if (cooldown_ratio > 0.01f)
            {
                // Cooling down / recently fired - BLUE
                KorryPresets::applyTypeN(bi.indicator, label, KorryPresets::Color::Blue, true);
                if (cooldown_ratio > 0.8f)
                    bi.indicator->setBlink(true, 0.1f);  // Just fired
            }
            else
            {
                // Ready - dark
                KorryPresets::applyTypeS(bi.indicator, label, KorryPresets::Color::Green, false);
                bi.indicator->setBlink(false);
            }

            bi.indicator->show();
        }

        // Hide unused beam indicators
        for (size_t i = beams->mounts.size(); i < beam_indicators.size(); i++)
            beam_indicators[i].indicator->hide();
    }
    else
    {
        for (auto& bi : beam_indicators)
            bi.indicator->hide();
    }
}

void SystemStatusScreen::updateStatusIndicators()
{
    // Impulse
    if (auto impulse = my_spaceship.getComponent<ImpulseEngine>())
    {
        float request = std::abs(impulse->request);

        impulse_indicator->setBlink(false);

        if (request > 0.01f)
        {
            // Active - BLUE (manual operation)
            KorryPresets::applyTypeN(impulse_indicator, "IMPULSE", KorryPresets::Color::Blue, true);
        }
        else
        {
            // Idle - dark
            KorryPresets::applyTypeS(impulse_indicator, "IMPULSE", KorryPresets::Color::Green, false);
        }
        impulse_indicator->show();
    }
    else
    {
        impulse_indicator->hide();
    }

    // Warp
    if (auto warp = my_spaceship.getComponent<WarpDrive>())
    {
        int level = static_cast<int>(warp->current);

        warp_indicator->setBlink(false);

        if (level > 0)
        {
            // Active - BLUE (manual operation)
            KorryPresets::applyTypeN(warp_indicator, "WARP", KorryPresets::Color::Blue, true);
        }
        else
        {
            // Idle - dark
            KorryPresets::applyTypeS(warp_indicator, "WARP", KorryPresets::Color::Green, false);
        }
        warp_indicator->show();
    }
    else
    {
        warp_indicator->hide();
    }

    // Jump drive
    if (auto jump = my_spaceship.getComponent<JumpDrive>())
    {
        float effectiveness = jump->getSystemEffectiveness();
        float charge_ratio = jump->max_distance > 0.0f ? jump->charge / jump->max_distance : 0.0f;
        int delay = static_cast<int>(jump->delay);

        if (effectiveness <= 0.0f)
        {
            // Damaged - RED
            KorryPresets::applyTypeB(jump_indicator, "JUMP", KorryPresets::Color::Red, true);
            jump_indicator->setBlink(false);
        }
        else if (delay > 0)
        {
            // Jumping - BLUE with fast blink
            KorryPresets::applyTypeB(jump_indicator, "JUMP", KorryPresets::Color::Blue, true);
            float blink_rate = 0.1f + (delay / 10.0f) * 0.4f;
            jump_indicator->setBlink(true, blink_rate);
        }
        else if (charge_ratio < 0.99f)
        {
            // Charging - AMBER (not ready)
            KorryPresets::applyTypeN(jump_indicator, "JUMP", KorryPresets::Color::Amber, true);
            jump_indicator->setBlink(false);
        }
        else
        {
            // Ready - GREEN
            KorryPresets::applyTypeN(jump_indicator, "JUMP", KorryPresets::Color::Green, true);
            jump_indicator->setBlink(false);
        }

        jump_indicator->show();
    }
    else
    {
        jump_indicator->hide();
    }

    // Combat maneuver
    if (auto cm = my_spaceship.getComponent<CombatManeuveringThrusters>())
    {
        bool active = (cm->boost.active > 0.01f) || (std::abs(cm->strafe.active) > 0.01f);

        if (active)
        {
            // Active - BLUE
            KorryPresets::applyTypeN(maneuver_indicator, "COMBAT\nMNVR", KorryPresets::Color::Blue, true);
            maneuver_indicator->setBlink(true, 0.25f);
        }
        else if (cm->charge < 0.99f)
        {
            // Recharging - AMBER
            KorryPresets::applyTypeN(maneuver_indicator, "COMBAT\nMNVR", KorryPresets::Color::Amber, true);
            maneuver_indicator->setBlink(false);
        }
        else
        {
            // Ready - dark
            KorryPresets::applyTypeS(maneuver_indicator, "COMBAT\nMNVR", KorryPresets::Color::Green, false);
            maneuver_indicator->setBlink(false);
        }

        maneuver_indicator->show();
    }
    else
    {
        maneuver_indicator->hide();
    }

    // Communications
    if (auto comms = my_spaceship.getComponent<CommsTransmitter>())
    {
        switch (comms->state)
        {
        case CommsTransmitter::State::Inactive:
        case CommsTransmitter::State::ChannelClosed:
            // Idle - dark
            KorryPresets::applyTypeS(comms_indicator, "COMMS", KorryPresets::Color::Green, false);
            comms_indicator->setBlink(false);
            break;

        case CommsTransmitter::State::OpeningChannel:
            // Hailing - BLUE (manual)
            KorryPresets::applyTypeN(comms_indicator, "COMMS", KorryPresets::Color::Blue, true);
            comms_indicator->setBlink(true, 0.5f);
            break;

        case CommsTransmitter::State::BeingHailed:
            // Being hailed - AMBER (attention needed)
            KorryPresets::applyTypeB(comms_indicator, "COMMS", KorryPresets::Color::Amber, true);
            comms_indicator->setBlink(true, 0.5f);
            break;

        case CommsTransmitter::State::ChannelOpen:
        case CommsTransmitter::State::ChannelOpenPlayer:
            // Open - GREEN (active)
            KorryPresets::applyTypeN(comms_indicator, "COMMS", KorryPresets::Color::Green, true);
            comms_indicator->setBlink(false);
            break;

        case CommsTransmitter::State::ChannelFailed:
        case CommsTransmitter::State::ChannelBroken:
            // Failed - RED
            KorryPresets::applyTypeB(comms_indicator, "COMMS", KorryPresets::Color::Red, true);
            comms_indicator->setBlink(true, 0.25f);
            break;
        }
        comms_indicator->show();
    }
    else
    {
        comms_indicator->hide();
    }

    // Scanner
    if (auto scanner = my_spaceship.getComponent<ScienceScanner>())
    {
        if (scanner->target && scanner->delay > 0.0f)
        {
            // Scanning - BLUE (manual operation)
            KorryPresets::applyTypeN(scan_indicator, "SCANNER", KorryPresets::Color::Blue, true);
            scan_indicator->setBlink(true, 0.5f);
        }
        else
        {
            // Ready - dark
            KorryPresets::applyTypeS(scan_indicator, "SCANNER", KorryPresets::Color::Green, false);
            scan_indicator->setBlink(false);
        }

        scan_indicator->show();
    }
    else
    {
        scan_indicator->hide();
    }

    // Target
    auto target = my_spaceship.getComponent<Target>();
    target_indicator->setBlink(false);
    if (target && target->entity)
    {
        // Target acquired - GREEN
        KorryPresets::applyTypeN(target_indicator, "TARGET", KorryPresets::Color::Green, true);
    }
    else
    {
        // No target - dark
        KorryPresets::applyTypeS(target_indicator, "TARGET", KorryPresets::Color::Green, false);
    }
    target_indicator->show();

    // Docking
    if (auto dock_port = my_spaceship.getComponent<DockingPort>())
    {
        switch (dock_port->state)
        {
        case DockingPort::State::NotDocking:
            // Not docking - dark
            KorryPresets::applyTypeS(dock_indicator, "DOCKING", KorryPresets::Color::Green, false);
            dock_indicator->setBlink(false);
            break;

        case DockingPort::State::Docking:
            // Docking in progress - BLUE
            KorryPresets::applyTypeN(dock_indicator, "DOCKING", KorryPresets::Color::Blue, true);
            dock_indicator->setBlink(true, 0.5f);
            break;

        case DockingPort::State::Docked:
            // Docked - GREEN
            KorryPresets::applyTypeN(dock_indicator, "DOCKING", KorryPresets::Color::Green, true);
            dock_indicator->setBlink(false);
            break;
        }

        dock_indicator->show();
    }
    else
    {
        dock_indicator->hide();
    }

    // Self-destruct
    if (auto sd = my_spaceship.getComponent<SelfDestruct>())
    {
        if (!sd->active)
        {
            // Inactive - dark
            KorryPresets::applyTypeS(selfdestruct_indicator, "SELF\nDESTRUCT", KorryPresets::Color::Red, false);
            selfdestruct_indicator->setBlink(false);
        }
        else
        {
            // Check confirmation status
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
                // Countdown active - RED WARNING
                KorryPresets::applyTypeB(selfdestruct_indicator, "SELF\nDESTRUCT", KorryPresets::Color::Red, true);
                selfdestruct_indicator->setBlink(true, 0.25f);
            }
            else
            {
                // Arming - AMBER
                KorryPresets::applyTypeB(selfdestruct_indicator, "SELF\nDESTRUCT", KorryPresets::Color::Amber, true);
                selfdestruct_indicator->setBlink(true, 0.5f);
            }
        }

        selfdestruct_indicator->show();
    }
    else
    {
        selfdestruct_indicator->hide();
    }
}
