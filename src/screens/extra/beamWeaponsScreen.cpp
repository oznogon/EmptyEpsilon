#include "beamWeaponsScreen.h"
#include <i18n.h>
#include "playerInfo.h"
#include "gameGlobalInfo.h"
#include "preferenceManager.h"
#include "crewPositionRequirements.h"

#include "components/beamweapon.h"
#include "components/beamWeaponTarget.h"
#include "components/collision.h"
#include "components/drone.h"
#include "components/radar.h"
#include "components/reactor.h"
#include "components/shields.h"
#include "components/target.h"
#include "components/utilityBeam.h"
#include "components/mounts.h"

#include "screenComponents/alertOverlay.h"
#include "screenComponents/beamFrequencySelector.h"
#include "screenComponents/beamTargetSelector.h"
#include "screenComponents/customShipFunctions.h"
#include "screenComponents/powerDamageIndicator.h"
#include "screenComponents/radarView.h"
#include "screenComponents/utilityBeamControls.h"
#include "screenComponents/utilityBeamRotationDial.h"

#include "gui/theme.h"
#include "gui/gui2_image.h"
#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_label.h"
#include "gui/gui2_selector.h"
#include "gui/gui2_togglebutton.h"

BeamWeaponsScreen::BeamWeaponsScreen(GuiContainer* owner)
: GuiOverlay(owner, "BEAM_WEAPONS_SCREEN", GuiTheme::getColor("background"))
{
    // Draw background decorations.
    background_gradient = new GuiImage(this, "BACKGROUND_GRADIENT", "");
    background_gradient
        ->setTextureThemed("background.gradient")
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(1200.0f, 900.0f);

    background_crosses = new GuiOverlay(this, "BACKGROUND_CROSSES", glm::u8vec4{255, 255, 255, 255});
    background_crosses->setTextureTiledThemed("background.crosses");

    (new AlertLevelOverlay(this));

    // Message if entity lacks the DroneController component.
    no_weapons_label = new GuiLabel(this, "NO_WEAPONS_LABEL", crewPositionRequirements::getMissingMessage(CrewPosition::beamWeaponsOfficer), GuiElement::GuiSizeRow);
    no_weapons_label
        ->setAlignment(sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide();

    beam_controls = new GuiElement(this, "");
    beam_controls
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    radar = new GuiRadarView(beam_controls, "BEAM_WEAPONS_RADAR", &targets);
    radar
        ->setAutoRotating(PreferencesManager::get("weapons_radar_lock","0") == "1")
        ->setRangeIndicatorStepSize(1000.0f)
        ->shortRange()
        ->enableCallsigns()
        ->enableHeadingIndicators()
        ->setStyle(GuiRadarView::Circular)
        ->setCallbacks(
            [this](sp::io::Pointer::Button button, glm::vec2 position)
            {
                if (!my_spaceship) return;
                targets.setToClosestTo(position, 250.0f, TargetsContainer::Targetable);

                if (targets.get())
                    my_player_info->commandSetBeamTarget(targets.get());
                else
                    my_player_info->commandSetBeamTarget({});
            }, nullptr, nullptr, nullptr
        )
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMatchHeight, 800.0f);

    beam_safety = new GuiToggleButton(beam_controls, "BEAM_SAFETY", tr("Autofire"),
        [](bool active)
        {
            my_player_info->commandSetBeamFiringEnabled(active);
        }
    );
    beam_safety
        ->setIcon("gui/icons/lock-beams")
        ->setPosition(250.0f, 20.0f, sp::Alignment::TopCenter)
        ->setSize(150.0f, GuiElement::GuiSizeRow);

    beam_info_box = new GuiElement(beam_controls, "BEAM_INFO_BOX");
    beam_info_box
        ->setPosition(20.0f, -20.0f, sp::Alignment::BottomLeft)
        ->setSize(280.0f, 230.0f)
        ->hide()
        ->setAttribute("layout", "vertical");

    if (gameGlobalInfo->use_beam_shield_frequencies || gameGlobalInfo->use_system_damage)
    {
        (new GuiLabel(beam_info_box, "BEAM_INFO_LABEL", tr("Beam targeting")))
            ->addBackground()
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);
        (new GuiLabel(beam_info_box, "BEAM_INFO_LABEL", tr("Frequency"), 25.0f))
            ->setSize(GuiElement::GuiSizeMax, 40.0f);
        (new GuiBeamFrequencySelector(beam_info_box, "BEAM_FREQUENCY_SELECTOR"))
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);
        (new GuiLabel(beam_info_box, "BEAM_INFO_LABEL", tr("Target system"), 25.0f))
            ->setSize(GuiElement::GuiSizeMax, 40.0f);
        (new GuiBeamTargetSelector(beam_info_box, "BEAM_TARGET_SELECTOR"))
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);
        (new GuiPowerDamageIndicator(beam_info_box, "", ShipSystem::Type::BeamWeapons, sp::Alignment::CenterLeft))
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
            ->setPosition(0.0f, GuiElement::GuiSizeRow, sp::Alignment::TopLeft);
    }

    auto stats = new GuiElement(beam_controls, "WEAPONS_STATS");
    stats
        ->setPosition(20.0f, 100.0f, sp::Alignment::TopLeft)
        ->setSize(240.0f, 120.0f)
        ->setAttribute("layout", "vertical");

    energy_display = new GuiKeyValueDisplay(stats, "ENERGY_DISPLAY", 0.45f, tr("Energy"), "");
    energy_display
        ->setIcon("gui/icons/energy")
        ->setTextSize(20.0f)
        ->setSize(240.0f, 40.0f);
    front_shield_display = new GuiKeyValueDisplay(stats, "FRONT_SHIELD_DISPLAY", 0.45f, tr("shields","Front"), "");
    front_shield_display
        ->setIcon("gui/icons/shields-fore")
        ->setTextSize(20.0f)
        ->setSize(240.0f, 40.0f);
    rear_shield_display = new GuiKeyValueDisplay(stats, "REAR_SHIELD_DISPLAY", 0.45f, tr("shields", "Rear"), "");
    rear_shield_display
        ->setIcon("gui/icons/shields-aft")
        ->setTextSize(20.0f)
        ->setSize(240.0f, 40.0f);

    sidebar_selector = new GuiSelector(beam_controls, "BEAM_WEAPONS_SIDEBAR_SELECTOR",
        [this](int index, string value)
        {
            if (value == "func")
            {
                custom_function_sidebar->setVisible(custom_function_sidebar->hasEntries());
                utility_beam_sidebar->hide();
                utility_beam_dial->hide();
            }
            else if (value == "util")
            {
                custom_function_sidebar->hide();
                utility_beam_sidebar->show();
                utility_beam_dial->show();
            }
        }
    );
    sidebar_selector
        ->setPosition(-20.0f, 120.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, GuiElement::GuiSizeRow)
        ->hide();

    custom_function_sidebar = new GuiCustomShipFunctions(beam_controls, CrewPosition::beamWeaponsOfficer, "BEAM_WEAPONS_CUSTOM_FUNCS");
    custom_function_sidebar
        ->setPosition(-20.0f, 170.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, 450.0f)
        ->hide();

    utility_beam_sidebar = new GuiUtilityBeamControls(beam_controls, CrewPosition::weaponsOfficer, "UTILITY_BEAM_CONTROLS");
    utility_beam_sidebar
        ->setPosition(-20.0f, 170.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, 500.0f)
        ->hide()
        ->setAttribute("layout", "vertical");

    utility_beam_dial = new GuiUtilityBeamRotationDial(radar, "UTILITY_BEAM_DIAL", radar);
    utility_beam_dial
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide();

    if (custom_function_sidebar->hasEntries())
    {
        sidebar_selector->addEntry(tr("weaponsTab", "Functions"), "func");
        sidebar_selector->show();
    }

    auto mounts_comp = my_spaceship.getComponent<Mounts>();
    const Mount* ub_mount = nullptr;
    if (mounts_comp) {
        for (auto& m : mounts_comp->mounts) {
            if (m.type == MountType::UtilityBeam) { ub_mount = &m; break; }
        }
    }
    if (ub_mount && ub_mount->crew_positions.has(CrewPosition::weaponsOfficer))
    {
        sidebar_selector->addEntry(tr("weaponsTab", "Utility beam"), "util");
        sidebar_selector->show();
    }

    if (sidebar_selector->entryCount() > 0)
    {
        sidebar_selector->setSelectionIndex(0);
        if (sidebar_selector->getSelectionValue() == "func")
            custom_function_sidebar->setVisible(custom_function_sidebar->hasEntries());
        else if (sidebar_selector->getSelectionValue() == "util")
        {
            utility_beam_sidebar->show();
            utility_beam_dial->show();
        }
    }
}

void BeamWeaponsScreen::onDraw(sp::RenderTarget& renderer)
{
    if (my_spaceship)
    {
        auto beam_sys = my_spaceship.getComponent<BeamWeaponSys>();
        if (beam_sys) beam_safety->setValue(beam_sys->is_firing_enabled);
        const bool bw = crewPositionRequirements::hasRequirements(CrewPosition::beamWeaponsOfficer, my_spaceship);
        background_gradient->setVisible(bw);
        beam_controls->setVisible(bw);
        no_weapons_label->setVisible(!bw);
        if (!bw)
        {
            GuiOverlay::onDraw(renderer);
            return;
        }

        auto reactor = my_spaceship.getComponent<Reactor>();
        energy_display->setVisible(reactor);
        if (reactor)
            energy_display->setValue(string(static_cast<int>(reactor->energy)));

        auto shields = my_spaceship.getComponent<Shields>();
        if (shields && shields->entries.size() > 0)
        {
            front_shield_display
                ->setValue(string(shields->entries[0].percentage()) + "%")
                ->show();
        }
        else front_shield_display->hide();

        if (shields && shields->entries.size() > 1)
        {
            rear_shield_display
                ->setValue(string(shields->entries[1].percentage()) + "%")
                ->show();
        }
        else rear_shield_display->hide();

        // Get the beam weapons target. If none, check for a legacy target.
        if (auto tg = my_spaceship.getComponent<BeamWeaponTarget>())
            targets.set(tg->entity);
        else if (auto tg = my_spaceship.getComponent<Target>())
            targets.set(tg->entity);
        else
            targets.set(sp::ecs::Entity{});

        beam_info_box->setVisible(beam_sys && (gameGlobalInfo->use_beam_shield_frequencies || gameGlobalInfo->use_system_damage));
    }

    GuiOverlay::onDraw(renderer);
}

void BeamWeaponsScreen::onUpdate()
{
    if (!my_spaceship || !isVisible()) return;

    // Target selection cycle keybinds.
    // Select hostile targets.
    if (keys.weapons_enemy_next_target.getDown())
    {
        if (auto transform = my_spaceship.getComponent<sp::Transform>())
        {
            auto lrr = my_spaceship.getComponent<LongRangeRadar>();
            float radar_range = lrr ? lrr->short_range : 5000.0f;
            if (auto sensors = my_spaceship.getComponent<SensorsSystem>())
                radar_range = sensorsScaleShortRange(radar_range, sensors->getSystemEffectiveness());
            targets.setNextTarget(
                transform->getPosition(),
                radar_range,
                TargetsContainer::ESelectionType::Targetable,
                TargetsContainer::KnownFriendOrFoe::KnownHostile
            );
            my_player_info->commandSetBeamTarget(targets.get());
        }
    }
    if (keys.weapons_enemy_prev_target.getDown())
    {
        if (auto transform = my_spaceship.getComponent<sp::Transform>())
        {
            auto lrr = my_spaceship.getComponent<LongRangeRadar>();
            float radar_range = lrr ? lrr->short_range : 5000.0f;
            if (auto sensors = my_spaceship.getComponent<SensorsSystem>())
                radar_range = sensorsScaleShortRange(radar_range, sensors->getSystemEffectiveness());
            targets.setPrevTarget(
                transform->getPosition(),
                radar_range,
                TargetsContainer::ESelectionType::Targetable,
                TargetsContainer::KnownFriendOrFoe::KnownHostile
            );
            my_player_info->commandSetBeamTarget(targets.get());
        }
    }

    // Select any non-friendly target.
    if (keys.weapons_next_target.getDown())
    {
        if (auto transform = my_spaceship.getComponent<sp::Transform>())
        {
            auto lrr = my_spaceship.getComponent<LongRangeRadar>();
            float radar_range = lrr ? lrr->short_range : 5000.0f;
            if (auto sensors = my_spaceship.getComponent<SensorsSystem>())
                radar_range = sensorsScaleShortRange(radar_range, sensors->getSystemEffectiveness());
            targets.setNextTarget(
                transform->getPosition(),
                radar_range,
                TargetsContainer::ESelectionType::Targetable,
                TargetsContainer::KnownFriendOrFoe::NotKnownFriendly
            );
            my_player_info->commandSetBeamTarget(targets.get());
        }
    }
    if (keys.weapons_prev_target.getDown())
    {
        if (auto transform = my_spaceship.getComponent<sp::Transform>())
        {
            auto lrr = my_spaceship.getComponent<LongRangeRadar>();
            float radar_range = lrr ? lrr->short_range : 5000.0f;
            if (auto sensors = my_spaceship.getComponent<SensorsSystem>())
                radar_range = sensorsScaleShortRange(radar_range, sensors->getSystemEffectiveness());
            targets.setPrevTarget(
                transform->getPosition(),
                radar_range,
                TargetsContainer::ESelectionType::Targetable,
                TargetsContainer::KnownFriendOrFoe::NotKnownFriendly
            );
            my_player_info->commandSetBeamTarget(targets.get());
        }
    }

    // Synchronize the Functions sidebar tab with current custom ship functions.
    bool should_have_func_tab = custom_function_sidebar->hasEntries();
    bool has_func_tab = sidebar_selector->indexByValue("func") != -1;
    if (should_have_func_tab && !has_func_tab)
    {
        sidebar_selector->addEntry(tr("weaponsTab", "Functions"), "func");
        sidebar_selector->show();
        if (sidebar_selector->getSelectionIndex() == -1)
        {
            int func_idx = sidebar_selector->indexByValue("func");
            if (func_idx != -1)
            {
                sidebar_selector->setSelectionIndex(func_idx);
                custom_function_sidebar->show();
            }
        }
    }
    else if (!should_have_func_tab && has_func_tab)
    {
        bool func_was_selected = sidebar_selector->getSelectionValue() == "func";
        sidebar_selector->removeEntry(sidebar_selector->indexByValue("func"));
        custom_function_sidebar->hide();

        if (func_was_selected)
        {
            int util_idx = sidebar_selector->indexByValue("util");
            if (util_idx != -1)
            {
                sidebar_selector->setSelectionIndex(util_idx);
                utility_beam_sidebar->show();
                utility_beam_dial->show();
            }
            else
            {
                sidebar_selector
                    ->setSelectionIndex(-1)
                    ->hide();
            }
        }

        if (sidebar_selector->entryCount() == 0) sidebar_selector->hide();
    }

    // Synchronize the Utility Beam sidebar tab with the current crew_positions mask.
    auto mounts_comp = my_spaceship.getComponent<Mounts>();
    const Mount* ub_mount = nullptr;
    if (mounts_comp) {
        for (auto& m : mounts_comp->mounts) {
            if (m.type == MountType::UtilityBeam) { ub_mount = &m; break; }
        }
    }
    bool should_have_util_tab = ub_mount && ub_mount->crew_positions.has(CrewPosition::weaponsOfficer);
    bool has_util_tab = sidebar_selector->indexByValue("util") != -1;
    if (should_have_util_tab && !has_util_tab)
    {
        sidebar_selector->addEntry(tr("weaponsTab", "Utility beam"), "util");
        sidebar_selector->show();
        if (sidebar_selector->getSelectionIndex() == -1)
        {
            int util_idx = sidebar_selector->indexByValue("util");
            if (util_idx != -1)
            {
                sidebar_selector->setSelectionIndex(util_idx);
                utility_beam_sidebar->show();
                utility_beam_dial->show();
            }
        }
    }
    else if (!should_have_util_tab && has_util_tab)
    {
        bool util_was_selected = sidebar_selector->getSelectionValue() == "util";
        sidebar_selector->removeEntry(sidebar_selector->indexByValue("util"));
        utility_beam_sidebar->hide();
        utility_beam_dial->hide();

        if (util_was_selected)
        {
            int func_idx = sidebar_selector->indexByValue("func");
            if (func_idx != -1)
            {
                sidebar_selector->setSelectionIndex(func_idx);
                custom_function_sidebar->setVisible(custom_function_sidebar->hasEntries());
            }
            else
            {
                sidebar_selector->setSelectionIndex(-1);
                sidebar_selector->hide();
            }
        }

        if (sidebar_selector->entryCount() == 0) sidebar_selector->hide();
    }
}
