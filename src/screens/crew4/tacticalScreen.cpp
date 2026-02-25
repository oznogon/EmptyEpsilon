#include "playerInfo.h"
#include "i18n.h"
#include "featureDefs.h"
#include "gameGlobalInfo.h"
#include "tacticalScreen.h"
#include "preferenceManager.h"

#include "components/reactor.h"
#include "components/warpdrive.h"
#include "components/jumpdrive.h"
#include "components/collision.h"
#include "components/shields.h"
#include "components/target.h"
#include "components/radar.h"

#include "screenComponents/combatManeuver.h"
#include "screenComponents/radarView.h"
#include "screenComponents/impulseControls.h"
#include "screenComponents/warpControls.h"
#include "screenComponents/jumpControls.h"
#include "screenComponents/dockingButton.h"
#include "screenComponents/alertOverlay.h"
#include "screenComponents/customShipFunctions.h"
#include "screenComponents/infoDisplay.h"
#include "screenComponents/utilityBeamControls.h"
#include "screenComponents/utilityBeamRotationDial.h"

#include "components/customshipfunction.h"
#include "components/utilityBeam.h"

#include "gui/gui2_selector.h"

#include "screenComponents/missileTubeControls.h"
#include "screenComponents/aimLock.h"
#include "screenComponents/shieldsEnableButton.h"
#include "screenComponents/beamFrequencySelector.h"
#include "screenComponents/beamTargetSelector.h"
#include "screenComponents/powerDamageIndicator.h"

#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_label.h"
#include "gui/gui2_image.h"
#include "gui/gui2_rotationdial.h"

TacticalScreen::TacticalScreen(GuiContainer* owner)
: GuiOverlay(owner, "TACTICAL_SCREEN", colorConfig.background)
{
    // Render the radar shadow and background decorations.
    (new GuiImage(this, "BACKGROUND_GRADIENT", "gui/background/gradientSingle.png"))->setPosition(glm::vec2(0, 0), sp::Alignment::Center)->setSize(1200, 900);

    background_crosses = new GuiOverlay(this, "BACKGROUND_CROSSES", glm::u8vec4{255,255,255,255});
    background_crosses->setTextureTiled("gui/background/crosses.png");

    // Render the alert level color overlay.
    (new AlertLevelOverlay(this));

    // Short-range tactical radar with a 5U range.
    radar = new GuiRadarView(this, "TACTICAL_RADAR", &targets);
    radar->setPosition(0, 0, sp::Alignment::Center)->setSize(GuiElement::GuiSizeMatchHeight, 750);
    radar->setRangeIndicatorStepSize(1000.0)->shortRange()->enableGhostDots()->enableWaypoints()->enableCallsigns()->enableHeadingIndicators()->setStyle(GuiRadarView::Circular);

    // Control targeting and piloting with radar interactions.
    radar->setCallbacks(
        [this](sp::io::Pointer::Button button, glm::vec2 position) {
            auto last_target = targets.get();
            targets.setToClosestTo(position, 250, TargetsContainer::Targetable);
            if (my_spaceship && targets.get() && (targets.get() != last_target)) {
                my_player_info->commandSetTarget(targets.get());
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
        }
    );
    radar->setAutoRotating(PreferencesManager::get("tactical_radar_lock","0")=="1");

    auto stats = new GuiElement(this, "STATS");
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
    tube_controls = new GuiMissileTubeControls(this, "MISSILE_TUBES");
    tube_controls->setPosition(20, -20, sp::Alignment::BottomLeft);
    radar->enableTargetProjections(tube_controls);

    // Beam controls beneath the radar.
    if (gameGlobalInfo->use_beam_shield_frequencies || gameGlobalInfo->use_system_damage)
    {
        GuiElement* beam_info_box = new GuiElement(this, "BEAM_INFO_BOX");
        beam_info_box->setPosition(0, -20, sp::Alignment::BottomCenter)->setSize(500, 50);
        (new GuiLabel(beam_info_box, "BEAM_INFO_LABEL", tr("Beams"), 30))->addBackground()->setPosition(0, 0, sp::Alignment::BottomLeft)->setSize(80, 50);
        (new GuiBeamFrequencySelector(beam_info_box, "BEAM_FREQUENCY_SELECTOR"))->setPosition(80, 0, sp::Alignment::BottomLeft)->setSize(132, 50);
        (new GuiPowerDamageIndicator(beam_info_box, "", ShipSystem::Type::BeamWeapons, sp::Alignment::CenterLeft))->setPosition(0, 0, sp::Alignment::BottomLeft)->setSize(212, 50);
        (new GuiBeamTargetSelector(beam_info_box, "BEAM_TARGET_SELECTOR"))->setPosition(0, 0, sp::Alignment::BottomRight)->setSize(288, 50);
    }

    // Weapon tube locking, and manual aiming controls.
    missile_aim = new AimLock(this, "MISSILE_AIM", radar, -90, 360 - 90, 0, [this](float value){
        tube_controls->setMissileTargetAngle(value);
    });
    missile_aim->hide()->setPosition(0, 0, sp::Alignment::Center)->setSize(GuiElement::GuiSizeMatchHeight, 800);
    lock_aim = new AimLockButton(this, "LOCK_AIM", tube_controls, missile_aim);
    lock_aim->setPosition(250, 20, sp::Alignment::TopCenter)->setSize(110, 50);

    // Combat maneuver and propulsion controls in the bottom right corner.
    (new GuiCombatManeuver(this, "COMBAT_MANEUVER"))->setPosition(-20, -390, sp::Alignment::BottomRight)->setSize(200, 150);
    GuiElement* engine_layout = new GuiElement(this, "ENGINE_LAYOUT");
    engine_layout->setPosition(-20, -80, sp::Alignment::BottomRight)->setSize(GuiElement::GuiSizeMax, 300)->setAttribute("layout", "horizontalright");
    (new GuiImpulseControls(engine_layout, "IMPULSE"))->setSize(100, GuiElement::GuiSizeMax);
    warp_controls = (new GuiWarpControls(engine_layout, "WARP"))->setSize(100, GuiElement::GuiSizeMax);
    jump_controls = (new GuiJumpControls(engine_layout, "JUMP"))->setSize(100, GuiElement::GuiSizeMax);
    (new GuiDockingButton(this, "DOCKING"))->setPosition(-20, -20, sp::Alignment::BottomRight)->setSize(280, 50);

    auto ub = my_spaceship.getComponent<UtilityBeam>();

    sidebar_selector = new GuiSelector(this, "TACTICAL_SIDEBAR_SELECTOR", [this](int index, string value)
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

    custom_function_sidebar = new GuiCustomShipFunctions(this, CrewPosition::tacticalOfficer, "TACTICAL_CUSTOM_FUNCS");
    custom_function_sidebar->setPosition(-20, 170, sp::Alignment::TopRight)->setSize(250, GuiElement::GuiSizeMax)->hide();

    utility_beam_sidebar = new GuiUtilityBeamControls(this, CrewPosition::tacticalOfficer, "UTILITY_BEAM_CONTROLS");
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
        warp_controls->setVisible(my_spaceship.hasComponent<WarpDrive>());
        jump_controls->setVisible(my_spaceship.hasComponent<JumpDrive>());

        auto target = my_spaceship.getComponent<Target>();
        targets.set(target ? target->entity : sp::ecs::Entity{});

        if (utility_beam_dial->isVisible())
            missile_aim->hide();
        else
            missile_aim->setVisible(tube_controls->getManualAim());
    }
    GuiOverlay::onDraw(renderer);
}

void TacticalScreen::onUpdate()
{
    if (my_spaceship && isVisible())
    {
        auto angle = (keys.helms_turn_right.getValue() - keys.helms_turn_left.getValue()) * 5.0f;
        if (angle != 0.0f)
        {
            if (auto transform = my_spaceship.getComponent<sp::Transform>())
                my_player_info->commandTargetRotation(transform->getRotation() + angle);
        }

        if (keys.weapons_enemy_next_target.getDown())
        {
            if (auto transform = my_spaceship.getComponent<sp::Transform>()) {
                auto lrr = my_spaceship.getComponent<LongRangeRadar>();
                targets.setNext(transform->getPosition(), lrr ? lrr->short_range : 5000.0f, TargetsContainer::Targetable, FactionRelation::Enemy);
                my_player_info->commandSetTarget(targets.get());
            }
        }
        if (keys.weapons_next_target.getDown())
        {
            if (auto transform = my_spaceship.getComponent<sp::Transform>()) {
                auto lrr = my_spaceship.getComponent<LongRangeRadar>();
                targets.setNext(transform->getPosition(), lrr ? lrr->short_range : 5000.0f, TargetsContainer::Targetable);
                my_player_info->commandSetTarget(targets.get());
            }
        }

        auto aim_adjust = keys.weapons_aim_left.getValue() - keys.weapons_aim_right.getValue();
        if (aim_adjust != 0.0f)
        {
            missile_aim->setValue(missile_aim->getValue() - 5.0f * aim_adjust);
            tube_controls->setMissileTargetAngle(missile_aim->getValue());
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
    }
}
