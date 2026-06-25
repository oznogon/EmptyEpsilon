#include "tacticalScreen.h"
#include <i18n.h>
#include "playerInfo.h"
#include "featureDefs.h"
#include "gameGlobalInfo.h"
#include "preferenceManager.h"

#include "components/customshipfunction.h"
#include "components/reactor.h"
#include "components/warpdrive.h"
#include "components/jumpdrive.h"
#include "components/collision.h"
#include "components/maneuveringthrusters.h"
#include "components/impulse.h"
#include "components/docking.h"
#include "components/shields.h"
#include "components/target.h"
#include "components/beamWeaponTarget.h"
#include "components/missileWeaponTarget.h"
#include "components/radar.h"
#include "components/drone.h"
#include "components/beamweapon.h"
#include "components/missiletubes.h"
#include "components/utilityBeam.h"

#include "screenComponents/aimLock.h"
#include "screenComponents/alertOverlay.h"
#include "screenComponents/beamFrequencySelector.h"
#include "screenComponents/beamTargetSelector.h"
#include "screenComponents/combatManeuver.h"
#include "screenComponents/customShipFunctions.h"
#include "screenComponents/dockingButton.h"
#include "screenComponents/impulseControls.h"
#include "screenComponents/infoDisplay.h"
#include "screenComponents/jumpControls.h"
#include "screenComponents/missileTubeControls.h"
#include "screenComponents/powerDamageIndicator.h"
#include "screenComponents/radarView.h"
#include "screenComponents/shieldsEnableButton.h"
#include "screenComponents/utilityBeamControls.h"
#include "screenComponents/utilityBeamRotationDial.h"
#include "screenComponents/warpControls.h"

#include "gui/theme.h"
#include "gui/gui2_image.h"
#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_label.h"
#include "gui/gui2_selector.h"

TacticalScreen::TacticalScreen(GuiContainer* owner)
: GuiOverlay(owner, "TACTICAL_SCREEN", GuiTheme::getColor("background"))
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

    // Message if entity lacks all propulsion, maneuver, docking, and weapon
    // components.
    no_controls_label = new GuiLabel(this, "NO_CONTROLS_LABEL", tr("tactical", "No tactical controls"), GuiElement::GuiSizeRow);
    no_controls_label
        ->setAlignment(sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide();

    tactical_controls = new GuiElement(this, "");
    tactical_controls->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Short-range tactical radar with a 5U range.
    radar = new GuiRadarView(tactical_controls, "TACTICAL_RADAR", &targets);
    radar->setPosition(0, 0, sp::Alignment::Center)->setSize(GuiElement::GuiSizeMatchHeight, 750);
    radar->setRangeIndicatorStepSize(1000.0)->shortRange()->enableGhostDots()->enableWaypoints()->enableCallsigns()->enableHeadingIndicators()->setStyle(GuiRadarView::Circular);

    // Control targeting and piloting with radar interactions.
    radar->setCallbacks(
        [this](sp::io::Pointer::Button button, glm::vec2 position) {
            auto last_target = targets.get();
            targets.setToClosestTo(position, 250, TargetsContainer::Targetable);
            if (my_spaceship && targets.get() && (targets.get() != last_target)) {
                my_player_info->commandSetBeamTarget(targets.get());
                my_player_info->commandSetMissileTarget(targets.get());
                drag_rotate = false;
            } else if (auto transform = my_spaceship.getComponent<sp::Transform>()) {
                my_player_info->commandTargetRotation(vec2ToAngle(position - transform->getPosition()));
                drag_rotate = true;
            }
        },
        [this](glm::vec2 position) {
            if (drag_rotate) {
                if (auto transform = my_spaceship.getComponent<sp::Transform>())
                    my_player_info->commandTargetRotation(vec2ToAngle(position - transform->getPosition()));
            }
        },
        [this](glm::vec2 position) {
            drag_rotate=false;
        }, nullptr
    );
    radar->setAutoRotating(PreferencesManager::get("tactical_radar_lock","0")=="1");

    auto stats = new GuiElement(tactical_controls, "STATS");
    stats->setPosition(20, 100, sp::Alignment::TopLeft)->setSize(240, 160)->setAttribute("layout", "vertical");

    // Ship statistics in the top left corner.
    auto energy_display = new EnergyInfoDisplay(stats, "ENERGY_DISPLAY", 0.45);
    energy_display->setSize(240, 40);
    auto heading_display = new HeadingInfoDisplay(stats, "HEADING_DISPLAY", 0.45);
    heading_display->setSize(240, 40);
    auto velocity_display = new VelocityInfoDisplay(stats, "VELOCITY_DISPLAY", 0.45);
    velocity_display->setSize(240, 40);
    auto shields_display = new ShieldsInfoDisplay(stats, "SHIELDS_DISPLAY", 0.45);
    shields_display->setSize(240, 40);

    // Weapon tube loading controls in the bottom left corner.
    tube_controls = new GuiMissileTubeControls(tactical_controls, "MISSILE_TUBES");
    tube_controls->setPosition(20, -20, sp::Alignment::BottomLeft);
    radar->enableTargetProjections(tube_controls);

    beam_info_box = new GuiElement(tactical_controls, "BEAM_INFO_BOX");
    beam_info_box
        ->setPosition(0.0f, -20.0f, sp::Alignment::BottomCenter)
        ->setSize(500.0f, GuiElement::GuiSizeRow)
        ->hide();

    // Beam controls beneath the radar.
    if (gameGlobalInfo->use_beam_shield_frequencies || gameGlobalInfo->use_system_damage)
    {
        beam_info_box->show();
        (new GuiLabel(beam_info_box, "BEAM_INFO_LABEL", tr("Beams"), 30))->addBackground()->setPosition(0, 0, sp::Alignment::BottomLeft)->setSize(80, 50);
        (new GuiBeamFrequencySelector(beam_info_box, "BEAM_FREQUENCY_SELECTOR"))->setPosition(80, 0, sp::Alignment::BottomLeft)->setSize(132, 50);
        (new GuiPowerDamageIndicator(beam_info_box, "", ShipSystem::Type::BeamWeapons, sp::Alignment::CenterLeft))->setPosition(0, 0, sp::Alignment::BottomLeft)->setSize(212, 50);
        (new GuiBeamTargetSelector(beam_info_box, "BEAM_TARGET_SELECTOR"))->setPosition(0, 0, sp::Alignment::BottomRight)->setSize(288, 50);
    }

    // Weapon tube locking, and manual aiming controls.
    missile_aim = new AimLock(tactical_controls, "MISSILE_AIM", radar, -90, 360 - 90, 0, [this](float value){
        tube_controls->setMissileTargetAngle(value);
    });
    missile_aim
        ->hide()
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMatchHeight, 800.0f);
    lock_aim = new AimLockButton(tactical_controls, "LOCK_AIM", tube_controls, missile_aim);
    lock_aim
        ->setPosition(250.0f, 20.0f, sp::Alignment::TopCenter)
        ->setSize(150.0f, GuiElement::GuiSizeRow);

    // Beam weapons autofire safety toggle.
    beam_safety = new GuiToggleButton(tactical_controls, "BEAM_SAFETY", tr("Autofire"),
        [this](bool active)
        {
            my_player_info->commandSetBeamFiringEnabled(active);
        }
    );
    beam_safety
        ->setIcon("gui/icons/lock-beams")
        ->setPosition(250.0f, 70.0f, sp::Alignment::TopCenter)
        ->setSize(150.0f, GuiElement::GuiSizeRow);

    // Combat maneuver and propulsion controls in the bottom right corner.
    (new GuiCombatManeuver(tactical_controls, "COMBAT_MANEUVER"))->setPosition(-20, -390, sp::Alignment::BottomRight)->setSize(200, 150);
    GuiElement* engine_layout = new GuiElement(tactical_controls, "ENGINE_LAYOUT");
    engine_layout->setPosition(-20, -80, sp::Alignment::BottomRight)->setSize(GuiElement::GuiSizeMax, 300)->setAttribute("layout", "horizontalright");
    (new GuiImpulseControls(engine_layout, "IMPULSE"))->setSize(100, GuiElement::GuiSizeMax);
    warp_controls = (new GuiWarpControls(engine_layout, "WARP"))->setSize(100, GuiElement::GuiSizeMax);
    jump_controls = (new GuiJumpControls(engine_layout, "JUMP"))->setSize(100, GuiElement::GuiSizeMax);
    (new GuiDockingButton(tactical_controls, "DOCKING"))->setPosition(-20, -20, sp::Alignment::BottomRight)->setSize(280, 50);

    auto ub = my_spaceship.getComponent<UtilityBeam>();

    sidebar_selector = new GuiSelector(tactical_controls, "TACTICAL_SIDEBAR_SELECTOR", [this](int index, string value)
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
    });
    sidebar_selector->setPosition(-20, 120, sp::Alignment::TopRight)->setSize(250, 50)->hide();

    custom_function_sidebar = new GuiCustomShipFunctions(tactical_controls, CrewPosition::tacticalOfficer, "TACTICAL_CUSTOM_FUNCS");
    custom_function_sidebar
        ->setPosition(-20.0f, 170.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, 100.0f)
        ->hide();

    utility_beam_sidebar = new GuiUtilityBeamControls(tactical_controls, CrewPosition::tacticalOfficer, "UTILITY_BEAM_CONTROLS");
    utility_beam_sidebar->setPosition(-20, 170, sp::Alignment::TopRight)->setSize(250, GuiElement::GuiSizeMax)->setAttribute("layout", "vertical");
    utility_beam_sidebar->hide();

    utility_beam_dial = new GuiUtilityBeamRotationDial(radar, "UTILITY_BEAM_DIAL", radar);
    utility_beam_dial->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)->hide();

    if (custom_function_sidebar->hasEntries())
    {
        sidebar_selector->addEntry(tr("tacticalTab", "Functions"), "func");
        sidebar_selector->show();
    }
    if (ub && ub->crew_positions.has(CrewPosition::tacticalOfficer))
    {
        sidebar_selector->addEntry(tr("tacticalTab", "Utility Beam"), "util");
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

void TacticalScreen::onDraw(sp::RenderTarget& renderer)
{
    if (my_spaceship)
    {
        auto beam_sys = my_spaceship.getComponent<BeamWeaponSys>();
        if (beam_sys) beam_safety->setValue(beam_sys->is_firing_enabled);
        auto missile_tubes = my_spaceship.getComponent<MissileTubes>();
        const bool has_any_ability = my_spaceship.hasComponent<ImpulseEngine>()
            || my_spaceship.hasComponent<JumpDrive>()
            || my_spaceship.hasComponent<WarpDrive>()
            || my_spaceship.hasComponent<CombatManeuveringThrusters>()
            || my_spaceship.hasComponent<ManeuveringThrusters>()
            || my_spaceship.hasComponent<DockingPort>()
            || (beam_sys && beam_sys->mounts.size() > 0)
            || (missile_tubes && missile_tubes->mounts.size() > 0);
        if (!has_any_ability)
        {
            GuiOverlay::onDraw(renderer);
            return;
        }

        warp_controls->setVisible(my_spaceship.hasComponent<WarpDrive>());
        jump_controls->setVisible(my_spaceship.hasComponent<JumpDrive>());
        beam_info_box->setVisible(beam_sys && (gameGlobalInfo->use_beam_shield_frequencies || gameGlobalInfo->use_system_damage));

        lock_aim->setVisible(missile_tubes);
        missile_aim->setVisible(missile_tubes && tube_controls->getManualAim());

        sp::ecs::Entity target_entity;
        if (auto t = my_spaceship.getComponent<BeamWeaponTarget>()) target_entity = t->entity;
        else if (auto t = my_spaceship.getComponent<MissileWeaponTarget>()) target_entity = t->entity;
        else if (auto t = my_spaceship.getComponent<Target>()) target_entity = t->entity;
        targets.set(target_entity);

        if (utility_beam_dial->isVisible())
            missile_aim->hide();
        else
            missile_aim->setVisible(tube_controls->getManualAim());
    }
    GuiOverlay::onDraw(renderer);
}

void TacticalScreen::onUpdate()
{
    if (!my_spaceship || !isVisible()) return;

    auto beam_sys = my_spaceship.getComponent<BeamWeaponSys>();
    auto missile_tubes = my_spaceship.getComponent<MissileTubes>();
    const bool has_any_ability = my_spaceship.hasComponent<ImpulseEngine>()
        || my_spaceship.hasComponent<JumpDrive>()
        || my_spaceship.hasComponent<WarpDrive>()
        || my_spaceship.hasComponent<CombatManeuveringThrusters>()
        || my_spaceship.hasComponent<ManeuveringThrusters>()
        || my_spaceship.hasComponent<DockingPort>()
        || (beam_sys && beam_sys->mounts.size() > 0)
        || (missile_tubes && missile_tubes->mounts.size() > 0);

    background_gradient->setVisible(has_any_ability);
    tactical_controls->setVisible(has_any_ability);
    no_controls_label->setVisible(!has_any_ability);

    if (!has_any_ability) return;

    // Copied and pasted from Helms screen.
    auto thrusters = my_spaceship.getComponent<ManeuveringThrusters>();
    float turn_scale = thrusters ? thrusters->speed : 10.0f;
    auto continuous_angle = (keys.helms_turn_right.getContinuousValue() - keys.helms_turn_left.getContinuousValue()) * turn_scale;
    continuous_angle += (keys.helms_turn_right.getAxis0Value() - keys.helms_turn_left.getAxis0Value()) * turn_scale;
    continuous_angle += (keys.helms_turn_right.getAxis1Value() - keys.helms_turn_left.getAxis1Value()) * turn_scale;
    float discrete_angle = 0.0f;
    if (keys.helms_turn_right.isDiscreteStepDown() || keys.helms_turn_right.isRepeatReady()) discrete_angle += 5.0f;
    if (keys.helms_turn_left.isRepeatReady()) discrete_angle -= 5.0f;
    if (continuous_angle != 0.0f)
    {
        if (auto transform = my_spaceship.getComponent<sp::Transform>())
            my_player_info->commandTargetRotation(transform->getRotation() + continuous_angle + discrete_angle);
        continuous_turning = true;
    }
    else if (discrete_angle != 0.0f)
    {
        if (auto transform = my_spaceship.getComponent<sp::Transform>())
            my_player_info->commandTargetRotation(transform->getRotation() + discrete_angle);
        continuous_turning = false;
    }
    else if (continuous_turning)
    {
        my_player_info->commandTurnSpeed(0.0f);
        continuous_turning = false;
    }

    // Copied and pasted from Weapons screen.
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

    auto utility_beam = my_spaceship.getComponent<UtilityBeam>();

    // Synchronize the Functions sidebar tab with current custom ship functions.
    bool should_have_func_tab = custom_function_sidebar->hasEntries();
    bool has_func_tab = sidebar_selector->indexByValue("func") != -1;
    if (should_have_func_tab && !has_func_tab)
    {
        sidebar_selector->addEntry(tr("tacticalTab", "Functions"), "func");
        sidebar_selector->show();
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
    bool should_have_util_tab = utility_beam && utility_beam->crew_positions.has(CrewPosition::tacticalOfficer);
    bool has_util_tab = sidebar_selector->indexByValue("util") != -1;
    if (should_have_util_tab && !has_util_tab)
    {
        sidebar_selector->addEntry(tr("tacticalTab", "Utility Beam"), "util");
        sidebar_selector->show();
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
