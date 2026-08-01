#include "weaponsScreen.h"
#include <i18n.h>
#include "playerInfo.h"
#include "gameGlobalInfo.h"
#include "preferenceManager.h"
#include "crewPositionRequirements.h"

#include "components/customshipfunction.h"
#include "components/utilityBeam.h"
#include "components/reactor.h"
#include "components/shields.h"
#include "components/target.h"
#include "components/radar.h"
#include "components/drone.h"
#include "components/beamweapon.h"
#include "components/beamWeaponTarget.h"
#include "components/collision.h"
#include "components/missiletubes.h"
#include "components/missileWeaponTarget.h"
#include "components/mounts.h"

#include "screenComponents/aimLock.h"
#include "screenComponents/alertOverlay.h"
#include "screenComponents/beamFrequencySelector.h"
#include "screenComponents/beamTargetSelector.h"
#include "screenComponents/customShipFunctions.h"
#include "screenComponents/missileTubeControls.h"
#include "screenComponents/powerDamageIndicator.h"
#include "screenComponents/radarView.h"
#include "screenComponents/shieldFreqencySelect.h"
#include "screenComponents/shieldsEnableButton.h"
#include "screenComponents/utilityBeamControls.h"
#include "screenComponents/utilityBeamRotationDial.h"

#include "gui/theme.h"
#include "gui/gui2_rotationdial.h"
#include "gui/gui2_selector.h"
#include "gui/gui2_label.h"
#include "gui/gui2_image.h"
#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_tooltip.h"

WeaponsScreen::WeaponsScreen(GuiContainer* owner)
: GuiOverlay(owner, "WEAPONS_SCREEN", GuiTheme::getColor("background"))
{
    // Render the radar shadow and background decorations.
    background_gradient = new GuiImage(this, "BACKGROUND_GRADIENT", "");
    background_gradient
        ->setTextureThemed("background.gradient_single")
        ->setPosition(glm::vec2(0.0f, 0.0f), sp::Alignment::Center)
        ->setSize(1200.0f, 900.0f);

    (new GuiOverlay(this, "BACKGROUND_CROSSES", glm::u8vec4{255, 255, 255, 255}))
        ->setTextureTiledThemed("background.crosses");

    // Render the alert level color overlay.
    new AlertLevelOverlay(this);

    // Message if entity lacks both weapons and shields.
    no_weapons_label = new GuiLabel(this, "NO_WEAPONS_LABEL", crewPositionRequirements::getMissingMessage(CrewPosition::weaponsOfficer), GuiElement::GuiSizeRow);
    no_weapons_label
        ->setAlignment(sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide();

    weapons_controls = new GuiElement(this, "");
    weapons_controls->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    radar = new GuiRadarView(weapons_controls, "WEAPONS_RADAR", &targets);
    radar
        ->setRangeIndicatorStepSize(1000.0f)
        ->shortRange()
        ->enableCallsigns()
        ->enableHeadingIndicators()
        ->enableMissileTubeIndicators()
        ->setStyle(GuiRadarView::Circular)
        ->setCallbacks(
            // Button down: Select combined weapons targets within 0.25U of the
            // click, or clear combined weapons targets if nothing's nearby.
            [this](sp::io::Pointer::Button button, glm::vec2 position)
            {
                targets.setToClosestTo(position, 250.0f, TargetsContainer::Targetable);
                if (my_spaceship && targets.get())
                {
                    my_player_info->commandSetBeamTarget(targets.get());
                    my_player_info->commandSetMissileTarget(targets.get());
                }
                else if (my_spaceship)
                {
                    my_player_info->commandSetBeamTarget({});
                    my_player_info->commandSetMissileTarget({});
                }
            }, nullptr, nullptr, nullptr
        )
        ->setAutoRotating(PreferencesManager::get("weapons_radar_lock", "0") == "1")
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMatchHeight, 750.0f);

    missile_aim = new AimLock(weapons_controls, "MISSILE_AIM", radar, -90.0f, 250.0f /* 360 - 90 */, 0.0f,
        [this](float value)
        {
            tube_controls->setMissileTargetAngle(value);
        }
    );
    missile_aim
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMatchHeight, 850.0f);
    // (new GuiTextTooltip(missile_aim, "MISSILE_AIM_TIP", tr("tooltips", "Drag to manually set the missile launch angle."), 20.0f))->setWidth(280.0f);

    tube_controls = new GuiMissileTubeControls(weapons_controls, "MISSILE_TUBES");
    tube_controls->setPosition(20.0f, -20.0f, sp::Alignment::BottomLeft);
    (new GuiTextTooltip(tube_controls, "MISSILE_TUBES_TIP", tr("tooltips", "Load, aim, and fire weapon tubes."), 20.0f))->setWidth(280.0f);
    radar->enableTargetProjections(tube_controls);

    lock_aim = new AimLockButton(weapons_controls, "LOCK_AIM", tube_controls, missile_aim);
    lock_aim
        ->setPosition(250.0f, 20.0f, sp::Alignment::TopCenter)
        ->setSize(150.0f, GuiElement::GuiSizeRow);
    (new GuiTextTooltip(lock_aim, "LOCK_AIM_TIP", tr("tooltips", "Toggle whether to lock missile aim to the current target or manually set the launch angle."), 20.0f))->setWidth(280.0f);

    // Beam controls beneath the radar.
    beam_info_box = new GuiElement(weapons_controls, "BEAM_INFO_BOX");
    beam_info_box
        ->setPosition(0.0f, -20.0f, sp::Alignment::BottomCenter)
        ->setSize(500.0f, GuiElement::GuiSizeRow)
        ->hide()
        ->setAttribute("layout", "horizontal");

    if (gameGlobalInfo->use_beam_shield_frequencies || gameGlobalInfo->use_system_damage)
    {
        beam_info_box->show();
        (new GuiLabel(beam_info_box, "BEAM_INFO_LABEL", tr("Beams"), GuiElement::GuiSizeLabel))
            ->addBackground()
            ->setSize(80.0f, GuiElement::GuiSizeMax);

        auto* beam_freq = new GuiBeamFrequencySelector(beam_info_box, "BEAM_FREQUENCY_SELECTOR");
        beam_freq->setSize(132.0f, GuiElement::GuiSizeMax);
        (new GuiTextTooltip(beam_freq, "BEAM_FREQ_TIP", tr("tooltips", "Set beam weapon frequency."), 20.0f))->setWidth(280.0f);

        auto* beam_target = new GuiBeamTargetSelector(beam_info_box, "BEAM_TARGET_SELECTOR");
        beam_target->setSize(288.0f, GuiElement::GuiSizeMax);
        (new GuiTextTooltip(beam_target, "BEAM_TARGET_TIP", tr("tooltips", "Select a ship system to target with beam weapons."), 20.0f))->setWidth(280.0f);

        auto* beam_power = new GuiPowerDamageIndicator(beam_info_box, "", ShipSystem::Type::BeamWeapons, sp::Alignment::CenterLeft);
        beam_power
            ->setPosition(0.0f, 0.0f, sp::Alignment::BottomLeft)
            ->setSize(212.0f, GuiElement::GuiSizeMax);
        (new GuiTextTooltip(beam_power, "BEAM_POWER_TIP", tr("tooltips", "Beam weapon system power and damage status."), 20.0f))->setWidth(280.0f);
    }

    // Beam weapons autofire safety toggle.
    beam_safety = new GuiToggleButton(weapons_controls, "BEAM_SAFETY", tr("Autofire"),
        [](bool active)
        {
            my_player_info->commandSetBeamFiringEnabled(active);
        }
    );
    beam_safety
        ->setIcon("gui/icons/lock-beams")
        ->setPosition(250.0f, 70.0f, sp::Alignment::TopCenter)
        ->setSize(150.0f, GuiElement::GuiSizeRow);
    (new GuiTextTooltip(beam_safety, "BEAM_SAFETY_TIP", tr("tooltips", "Toggle whether beam weapons automatically fire at the active target within their firing arc."), 20.0f))->setWidth(280.0f);

    auto stats = new GuiElement(weapons_controls, "WEAPONS_STATS");
    stats
        ->setPosition(20.0f, 100.0f, sp::Alignment::TopLeft)
        ->setSize(240.0f, 120.0f)
        ->setAttribute("layout", "vertical");

    energy_display = new GuiKeyValueDisplay(stats, "ENERGY_DISPLAY", 0.45f, tr("Energy"), "");
    energy_display
        ->setIcon("gui/icons/energy")
        ->setTextSize(20.0f)
        ->setSize(240.0f, 40.0f);

    front_shield_display = new GuiKeyValueDisplay(stats, "FRONT_SHIELD_DISPLAY", 0.45f, tr("shields", "Front"), "");
    front_shield_display
        ->setIcon("gui/icons/shields-fore")
        ->setTextSize(20.0f)
        ->setSize(240.0f, 40.0f);

    rear_shield_display = new GuiKeyValueDisplay(stats, "REAR_SHIELD_DISPLAY", 0.45f, tr("shields", "Rear"), "");
    rear_shield_display
        ->setIcon("gui/icons/shields-aft")
        ->setTextSize(20.0f)
        ->setSize(240.0f, 40.0f);

    // Shield frequency selection includes a shield enable button.
    if (gameGlobalInfo->use_beam_shield_frequencies)
    {
        auto* shield_freq = new GuiShieldFrequencySelect(weapons_controls, "SHIELD_FREQ");
        shield_freq
            ->setPosition(-20.0f, -20.0f, sp::Alignment::BottomRight)
            ->setSize(280.0f, 100.0f);
        (new GuiTextTooltip(shield_freq, "SHIELD_FREQ_TIP", tr("tooltips", "Calibrate the shield frequency. Calibration temporarily takes shields offline."), 20.0f))->setWidth(280.0f);
    }
    else
    {
        auto* shields_enable = new GuiShieldsEnableButton(weapons_controls, "SHIELDS_ENABLE");
        shields_enable
            ->setPosition(-20.0f, -20.0f, sp::Alignment::BottomRight)
            ->setSize(280.0f, 50.0f);
        (new GuiTextTooltip(shields_enable, "SHIELDS_ENABLE_TIP", tr("tooltips", "Toggle shields. Active shields deflect incoming damage."), 20.0f))->setWidth(280.0f);
    }

    const Mount* ub_mount = nullptr;
    if (auto mounts_comp = my_spaceship.getComponent<Mounts>())
    {
        for (auto& m : mounts_comp->mounts)
        {
            if (m.type == MountType::UtilityBeam)
            {
                ub_mount = &m;
                break;
            }
        }
    }

    sidebar_selector = new GuiSelector(weapons_controls, "WEAPONS_SIDEBAR_SELECTOR",
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
    (new GuiTextTooltip(sidebar_selector, "WEAPONS_SIDEBAR_TIP", tr("tooltips", "Switch between custom ship functions and utility beam controls."), 20.0f))->setWidth(280.0f);

    custom_function_sidebar = new GuiCustomShipFunctions(weapons_controls, CrewPosition::weaponsOfficer, "WEAPONS_CUSTOM_FUNCS");
    custom_function_sidebar
        ->setPosition(-20.0f, 170.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, 450.0f)
        ->hide();

    utility_beam_sidebar = new GuiUtilityBeamControls(weapons_controls, CrewPosition::weaponsOfficer, "UTILITY_BEAM_CONTROLS");
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

    if (ub_mount && ub_mount->crew_positions.has(CrewPosition::weaponsOfficer))
    {
        sidebar_selector->addEntry(tr("weaponsTab", "Utility beam"), "util");
        sidebar_selector->show();
    }

    // Set initial sidebar state by manually applying the first tab.
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

void WeaponsScreen::onDraw(sp::RenderTarget& renderer)
{
    if (my_spaceship)
    {
        if (auto beam_sys = my_spaceship.getComponent<BeamWeaponSys>())
            beam_safety->setValue(beam_sys->is_firing_enabled);

        auto shields = my_spaceship.getComponent<Shields>();

        const bool has_any_ability = crewPositionRequirements::hasRequirements(CrewPosition::weaponsOfficer, my_spaceship);
        if (!has_any_ability)
        {
            GuiOverlay::onDraw(renderer);
            return;
        }

        auto reactor = my_spaceship.getComponent<Reactor>();
        energy_display->setVisible(reactor);
        if (reactor)
            energy_display->setValue(string(static_cast<int>(reactor->energy)));

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

        sp::ecs::Entity target_entity;
        if (auto t = my_spaceship.getComponent<BeamWeaponTarget>())
            target_entity = t->entity;
        else if (auto t = my_spaceship.getComponent<MissileWeaponTarget>())
            target_entity = t->entity;
        else if (auto t = my_spaceship.getComponent<Target>())
            target_entity = t->entity;
        targets.set(target_entity);

        beam_info_box->setVisible(my_spaceship.hasComponent<BeamWeaponSys>() && (gameGlobalInfo->use_beam_shield_frequencies || gameGlobalInfo->use_system_damage));

        const bool has_tubes = my_spaceship.hasComponent<MissileTubes>();
        lock_aim->setVisible(has_tubes);
        missile_aim->setVisible(has_tubes && tube_controls->getManualAim());

        if (utility_beam_dial->isVisible())
            missile_aim->hide();
        else
            missile_aim->setVisible(has_tubes && tube_controls->getManualAim());
    }

    GuiOverlay::onDraw(renderer);
}

void WeaponsScreen::onUpdate()
{
    if (!my_spaceship || !isVisible()) return;

    const bool has_any_ability = crewPositionRequirements::hasRequirements(CrewPosition::weaponsOfficer, my_spaceship);

    background_gradient->setVisible(has_any_ability);
    weapons_controls->setVisible(has_any_ability);
    no_weapons_label->setVisible(!has_any_ability);

    if (!has_any_ability) return;

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
            my_player_info->commandSetMissileTarget(targets.get());
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
            my_player_info->commandSetMissileTarget(targets.get());
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
            my_player_info->commandSetMissileTarget(targets.get());
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
            my_player_info->commandSetMissileTarget(targets.get());
        }
    }

    const Mount* ub_mount = nullptr;
    if (auto mounts_comp = my_spaceship.getComponent<Mounts>())
    {
        for (auto& m : mounts_comp->mounts)
        {
            if (m.type == MountType::UtilityBeam)
            {
                ub_mount = &m;
                break;
            }
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
                sidebar_selector->setSelectionIndex(-1);
                sidebar_selector->hide();
            }
        }
        if (sidebar_selector->entryCount() == 0)
            sidebar_selector->hide();
    }

    // Synchronize the Utility Beam sidebar tab with the current crew_positions mask.
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
        if (sidebar_selector->entryCount() == 0)
            sidebar_selector->hide();
    }

    // Manual missile aiming keybinds.
    auto aim_adjust = (keys.weapons_aim_left.getContinuousValue() + keys.weapons_aim_left.getAxis0Value() + keys.weapons_aim_left.getAxis1Value())
        - (keys.weapons_aim_right.getContinuousValue() + keys.weapons_aim_right.getAxis0Value() + keys.weapons_aim_right.getAxis1Value());
    if (aim_adjust != 0.0f)
    {
        missile_aim->setValue(missile_aim->getValue() - 5.0f * aim_adjust);
        tube_controls->setMissileTargetAngle(missile_aim->getValue());
    }
    if (keys.weapons_aim_left.isDiscreteStepDown() || keys.weapons_aim_left.isRepeatReady())
    {
        missile_aim->setValue(missile_aim->getValue() - 5.0f);
        tube_controls->setMissileTargetAngle(missile_aim->getValue());
    }
    if (keys.weapons_aim_right.isDiscreteStepDown() || keys.weapons_aim_right.isRepeatReady())
    {
        missile_aim->setValue(missile_aim->getValue() + 5.0f);
        tube_controls->setMissileTargetAngle(missile_aim->getValue());
    }
}
