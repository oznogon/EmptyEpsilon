#include "droneOperationsScreen.h"
#include "main.h"
#include <i18n.h>
#include <limits>
#include "playerInfo.h"
#include "gameGlobalInfo.h"
#include "featureDefs.h"

#include "components/drone.h"
#include "components/beamweapon.h"
#include "components/coolant.h"
#include "components/collision.h"
#include "components/impulse.h"
#include "components/jumpdrive.h"
#include "components/maneuveringthrusters.h"
#include "components/missiletubes.h"
#include "components/name.h"
#include "components/player.h"
#include "components/radar.h"
#include "components/reactor.h"
#include "components/scanning.h"
#include "components/shields.h"
#include "components/target.h"
#include "components/ai.h"
#include "components/docking.h"
#include "components/warpdrive.h"
#include "systems/jumpsystem.h"
#include "systems/missilesystem.h"

#include "screenComponents/aimLock.h"
#include "screenComponents/alertOverlay.h"
#include "screenComponents/commsOverlay.h"
#include "screenComponents/customShipFunctions.h"
#include "screenComponents/droneDockingButton.h"
#include "screenComponents/radarView.h"
#include "screenComponents/radarZoomSlider.h"
#include "screenComponents/snapSlider.h"

#include "gui/theme.h"
#include "gui/gui2_button.h"
#include "gui/gui2_image.h"
#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_label.h"
#include "gui/gui2_progressbar.h"
#include "gui/gui2_selector.h"
#include "gui/gui2_slider.h"
#include "gui/gui2_togglebutton.h"


DroneOperationsScreen::DroneOperationsScreen(GuiContainer* owner)
: GuiOverlay(owner, "DRONE_OPERATOR_SCREEN", GuiTheme::getColor("background"))
{
    background_gradient = new GuiImage(this, "BACKGROUND_GRADIENT", "");
    background_gradient
        ->setTextureThemed("background.gradient_single")
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(1200.0f, 900.0f);

    auto background_crosses = new GuiOverlay(this, "BACKGROUND_CROSSES", glm::u8vec4{255,255,255,255});
    background_crosses->setTextureTiledThemed("background.crosses");

    (new AlertLevelOverlay(this));

    // Message if ship lacks DroneController.
    no_drone_controller_label = new GuiLabel(this, "NO_DRONE_CONTROLLER_LABEL", tr("drone", "No drone controller"), 50.0f);
    no_drone_controller_label
        ->setAlignment(sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide();

    // Radar initial distance matches the zoom slider so the label is accurate.
    float initial_control_range = 5000.0f;
    if (auto dc = my_spaceship.getComponent<DroneController>())
        initial_control_range = dc->control_range;

    radar_pane = new GuiElement(this, "");
    radar_pane->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Radar centered in left pane.
    radar = new GuiRadarView(radar_pane, "DRONE_OPERATOR_RADAR", initial_control_range, &targets);
    radar
        ->setRangeIndicatorStepSize(1000.0f)
        ->shortRange()
        ->enableGhostDots()
        ->enableWaypoints()
        ->enableCallsigns()
        ->enableHeadingIndicators()
        ->setStyle(GuiRadarView::Circular)
        ->enableMissileTubeIndicators()
        ->enableTargetProjections(
            [this]()
            {
                return use_manual_aim;
            },
            [this]()
            {
                return missile_aim->getValue();
            }
        )
        ->setCallbacks(
            // Down
            [this](sp::io::Pointer::Button button, glm::vec2 position)
            {
                auto drone = connectedDrone();
                bool connected = drone && isDroneConnected();
                if (!connected)
                {
                    // Disconnected: target selection only.
                    targets.setToClosestTo(position, 250.0f, TargetsContainer::Targetable);
                    if (targets.get())
                        my_player_info->commandSetTarget(targets.get());
                    drag_rotate = false;
                }
                else
                {
                    auto last_target = targets.get();
                    targets.setToClosestTo(position, 250.0f, TargetsContainer::Targetable);
                    if (targets.get() && targets.get() != last_target)
                    {
                        my_player_info->commandDroneSetTarget(targets.get());
                        drag_rotate = false;
                    }
                    else if (auto transform = drone.getComponent<sp::Transform>())
                    {
                        float angle = vec2ToAngle(position - transform->getPosition());
                        auto r = radar->getRect();
                        glm::vec2 pos_from_center = position - transform->getPosition();
                        glm::vec2 draw_position = rect.center() + pos_from_center / radar->getDistance() * std::min(r.size.x, r.size.y) * 0.5f;
                        heading_hint
                            ->setText(string(fmodf(angle + 90.0f + 360.0f, 360.0f), 1))
                            ->setPosition(draw_position - rect.position - glm::vec2(0.0f, 50.0f))
                            ->show();
                        my_player_info->commandDroneTargetRotation(angle);
                        drag_rotate = true;
                    }
                }
            },
            // Drag
            [this](glm::vec2 position)
            {
                auto drone = connectedDrone();
                bool connected = drone && isDroneConnected();
                if (connected && drag_rotate)
                {
                    if (auto transform = drone.getComponent<sp::Transform>())
                    {
                        float angle = vec2ToAngle(position - transform->getPosition());
                        auto r = radar->getRect();
                        glm::vec2 pos_from_center = position - transform->getPosition();
                        glm::vec2 draw_position = rect.center() + pos_from_center / radar->getDistance() * std::min(r.size.x, r.size.y) * 0.5f;
                        heading_hint
                            ->setText(string(fmodf(angle + 90.0f + 360.0f, 360.0f), 1))
                            ->setPosition(draw_position - rect.position - glm::vec2(0.0f, 50.0f))
                            ->show();
                        my_player_info->commandDroneTargetRotation(angle);
                    }
                }
            },
            // Up
            [this](glm::vec2 position)
            {
                drag_rotate = false;
                heading_hint->hide();
            },
            [this](float value, glm::vec2 position)
            {
                auto dc = my_spaceship.getComponent<DroneController>();
                float max_range = dc ? dc->control_range : 5000.0f;
                if (max_range <= 5000.0f) return;

                const float view_distance = std::clamp(
                    radar->getDistance() * (1.0f - value * 0.1f),
                    5000.0f,
                    max_range
                );

                const glm::vec2 world_position_before_zoom = radar->screenToWorld(position);
                zoom_slider->setValue(view_distance);
                radar
                    ->setDistance(view_distance)
                    ->setViewPosition(radar->getViewPosition() + world_position_before_zoom - radar->screenToWorld(position));
            }
        )
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMatchHeight, 650.0f);

    // Heading hint label positioned dynamically on radar click.
    heading_hint = new GuiLabel(radar_pane, "HEADING_HINT", "", 30.0f);
    heading_hint
        ->setAlignment(sp::Alignment::Center)
        ->setSize(0.0f, 0.0f)
        ->hide();

    // Radar zoom slider: shown only when disconnected and control range > 5000.
    zoom_slider = new GuiRadarZoomSlider(radar_pane, "DRONE_ZOOM_SLIDER", 5000.0f, initial_control_range, initial_control_range, radar);
    zoom_slider
        ->setPosition(20.0f, -70.0f, sp::Alignment::BottomLeft)
        ->setSize(250.0f, 50.0f)
        ->hide();

    // Aim lock dial.
    missile_aim = new AimLock(radar_pane, "MISSILE_AIM", radar, -90.0f, 270.0f /* 360 - 90 */, 0.0f,
        [this](float value)
        {
            // missile_target_angle is managed in onUpdate/fire callbacks
        }
    );
    missile_aim
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMatchHeight, 700.0f);

    // Drone selector at top-left.
    drone_selector = new GuiSelector(radar_pane, "DRONE_SELECTOR",
        [this](int index, string value)
        {
            // Deselect any current target to prevent targeting from overriding
            // the selector.
            auto drone = connectedDrone();
            bool connected = drone && isDroneConnected();

            if (!connected)
            {
                targets.set(sp::ecs::Entity{});
                my_player_info->commandSetTarget(sp::ecs::Entity{});
            }
        }
    );
    drone_selector->setPosition(20.0f, 20.0f, sp::Alignment::TopLeft)->setSize(300.0f, 50.0f);

    connect_button = new GuiToggleButton(radar_pane, "CONNECT_BUTTON", tr("drone", "Connect"),
        [this](bool value)
        {
            if (value)
            {
                const int idx = drone_selector->getSelectionIndex();
                if (idx >= 0 && idx < static_cast<int>(drone_list.size()))
                    my_player_info->commandSetDroneLink(drone_list[idx]);
                else
                    connect_button->setValue(false);
            }
            else my_player_info->commandSetDroneLink(sp::ecs::Entity{});
            applyConnectionState();
        }
    );
    connect_button
        ->setPosition(320.0f, 20.0f, sp::Alignment::TopLeft)
        ->setSize(150.0f, 50.0f);

    // drone_shields_button shown when connected.
    drone_shields_button = new GuiToggleButton(radar_pane, "DRONE_SHIELDS_BUTTON", tr("drone", "Shields: ON"),
        [this](bool value)
        {
            my_player_info->commandDroneSetShields(value);
        }
    );
    drone_shields_button
        ->setPosition(20.0f, 80.0f, sp::Alignment::TopLeft)
        ->setSize(250.0f, 50.0f)
        ->hide();

    // Drone docking button shown when connected.
    drone_docking_button = new GuiDroneDockingButton(radar_pane, "DRONE_DOCKING_BUTTON");
    drone_docking_button
        ->setPosition(280.0f, 80.0f, sp::Alignment::TopLeft)
        ->setSize(250.0f, 50.0f)
        ->hide();

    // Engine layout (shown when connected). Positioned below the button row.
    engine_layout = new GuiElement(radar_pane, "ENGINE_LAYOUT");
    engine_layout
        ->setPosition(20.0f, 140.0f, sp::Alignment::TopLeft)
        ->setSize(GuiElement::GuiSizeMax, 200.0f)
        ->setAttribute("layout", "horizontal");

    // Impulse slider.
    {
        auto impulse_controls = new GuiElement(engine_layout, "IMPULSE");
        impulse_controls->setSize(80.0f, GuiElement::GuiSizeMax);
        impulse_slider = new GuiSlider(impulse_controls, "IMPULSE_SLIDER", 1.0f, -1.0f, 0.0f,
            [this](float value)
            {
                my_player_info->commandDroneImpulse(value);
            }
        );
        impulse_slider
            ->addSnapValue(0.0f, 0.1f)
            ->setPosition(0.0f, 0.0f, sp::Alignment::TopLeft)
            ->setSize(40.0f, GuiElement::GuiSizeMax);
        impulse_label = new GuiKeyValueDisplay(impulse_controls, "IMPULSE_LABEL", 0.5f, tr("slider", "Impulse"), "0%");
        impulse_label
            ->setTextSize(20.0f)
            ->setPosition(40.0f, 0.0f, sp::Alignment::TopLeft)
            ->setSize(40.0f, GuiElement::GuiSizeMax);
    }

    // Warp slider (column hidden when drone has no warp drive).
    {
        warp_controls = new GuiElement(engine_layout, "WARP");
        warp_controls->setSize(80.0f, GuiElement::GuiSizeMax);
        warp_slider = new GuiSlider(warp_controls, "WARP_SLIDER", 4.0f, 0.0f, 0.0f,
            [this](float value)
            {
                int warp_level = static_cast<int>(value);
                my_player_info->commandDroneWarp(warp_level);
                warp_slider->setValue(warp_level);
            }
        );
        warp_slider
            ->addSnapValue(0.0f, 0.5f)
            ->addSnapValue(1.0f, 0.5f)
            ->setPosition(0.0f, 0.0f, sp::Alignment::TopLeft)
            ->setSize(40.0f, GuiElement::GuiSizeMax);
        warp_label = new GuiKeyValueDisplay(warp_controls, "WARP_LABEL", 0.5f, tr("slider", "Warp"), "0");
        warp_label
            ->setTextSize(20.0f)
            ->setPosition(40.0f, 0.0f, sp::Alignment::TopLeft)
            ->setSize(40.0f, GuiElement::GuiSizeMax);
    }

    // Jump controls.
    jump_controls = new GuiElement(engine_layout, "JUMP");
    jump_controls->setSize(80.0f, GuiElement::GuiSizeMax);

    jump_distance_slider = new GuiSlider(jump_controls, "JUMP_DISTANCE", 50000.0f, 5000.0f, 10000.0f, nullptr); // TODO: Variable
    jump_distance_slider
        ->setPosition(0.0f, -40.0f, sp::Alignment::BottomLeft)
        ->setSize(40.0f, GuiElement::GuiSizeMax);

    jump_charge_bar = new GuiProgressbar(jump_controls, "JUMP_CHARGE", 0.0, 50000.0, 0.0); // TODO: Variable
    jump_charge_bar
        ->setPosition(0.0f, -40.0f, sp::Alignment::BottomLeft)
        ->setSize(40.0f, GuiElement::GuiSizeMax)
        ->hide();

    jump_label = new GuiKeyValueDisplay(jump_controls, "JUMP_LABEL", 0.5f, tr("jumpcontrol", "Distance"), "10.0");
    jump_label
        ->setTextSize(20.0f)
        ->setPosition(40.0f, -50.0f, sp::Alignment::BottomLeft)
        ->setSize(40.0f, GuiElement::GuiSizeMax);

    jump_button = new GuiButton(jump_controls, "JUMP_BUTTON", tr("jumpcontrol", "Jump"),
        [this]()
        {
            auto drone = connectedDrone();
            bool connected = drone && isDroneConnected();
            if (!connected) return;

            if (auto jump = drone.getComponent<JumpDrive>())
            {
                if (jump->delay <= 0.0f)
                    my_player_info->commandDroneJump(jump_distance_slider->getValue());
                else my_player_info->commandDroneAbortJump();
            }
        }
    );
    jump_button
        ->setPosition(0.0f, 0.0f, sp::Alignment::BottomLeft)
        ->setSize(GuiElement::GuiSizeMax, 50.0f);

    // Stats at bottom right.
    drone_stats = new GuiElement(radar_pane, "DRONE_STATS");
    drone_stats
        ->setPosition(-20.0f, -20.0f, sp::Alignment::BottomRight)
        ->setSize(250.0f, 240.0f)
        ->setAttribute("layout", "verticalbottom");

    drone_distance_display = new GuiKeyValueDisplay(drone_stats, "DRONE_DISTANCE", 0.45f, tr("Distance"), "");
    drone_distance_display
        ->setIcon("gui/icons/station-relay")
        ->setSize(GuiElement::GuiSizeMax, 40.0f);

    drone_heat_display = new GuiKeyValueDisplay(drone_stats, "DRONE_HEAT", 0.45f, tr("Heat"), "");
    drone_heat_display
        ->setIcon("gui/icons/status_overheat")
        ->setSize(GuiElement::GuiSizeMax, 40.0f);

    drone_shields_display = new GuiKeyValueDisplay(drone_stats, "DRONE_SHIELDS", 0.45f, tr("Shields"), "");
    drone_shields_display
        ->setIcon("gui/icons/shields")
        ->setSize(GuiElement::GuiSizeMax, 40.0f);

    drone_velocity_display = new GuiKeyValueDisplay(drone_stats, "DRONE_VELOCITY", 0.45f, tr("Speed"), "");
    drone_velocity_display
        ->setIcon("gui/icons/speed")
        ->setSize(GuiElement::GuiSizeMax, 40.0f);

    drone_heading_display = new GuiKeyValueDisplay(drone_stats, "DRONE_HEADING", 0.45f, tr("Heading"), "");
    drone_heading_display
        ->setIcon("gui/icons/heading")
        ->setSize(GuiElement::GuiSizeMax, 40.0f);

    drone_energy_display = new GuiKeyValueDisplay(drone_stats, "DRONE_ENERGY", 0.45f, tr("Energy"), "");
    drone_energy_display
        ->setIcon("gui/icons/energy")
        ->setTextSize(20.0f)
        ->setSize(GuiElement::GuiSizeMax, 40.0f);

    drone_callsign_display = new GuiKeyValueDisplay(drone_stats, "DRONE_CALLSIGN", 0.45f, tr("Callsign"), "");
    drone_callsign_display->setSize(GuiElement::GuiSizeMax, 40.0f);

    // Orders menu (shown always; sends to targeted/selected/connected drone).
    orders_layout = new GuiElement(radar_pane, "ORDERS_LAYOUT");
    orders_layout
        ->setPosition(-280.0f, -20.0f, sp::Alignment::BottomRight)
        ->setSize(200.0f, 200.0f)
        ->setAttribute("layout", "verticalbottom");

    (new GuiButton(orders_layout, "ORDER_DOCK", tr("Return"),
        [this]()
        {
            if (auto target = getOrderTarget())
            {
                auto port = target.getComponent<DockingPort>();
                auto bay = my_spaceship.getComponent<DockingBay>();
                if (port && bay && port->canDockOn(*bay) != DockingStyle::None)
                    my_player_info->commandSetAIOrder(target, AIOrder::Dock, my_spaceship);
                else
                    my_player_info->commandSetAIOrder(target, AIOrder::DefendTarget, my_spaceship);
            }
        }
    ))
        ->setTextSize(20.0f)
        ->setSize(GuiElement::GuiSizeMax, 40.0f);
    (new GuiButton(orders_layout, "ORDER_DEFEND_LOCATION", tr("Defend location"),
        [this]()
        {
            if (auto target = getOrderTarget())
                my_player_info->commandSetAIOrder(target, AIOrder::DefendLocation);
        }
    ))
        ->setTextSize(20.0f)
        ->setSize(GuiElement::GuiSizeMax, 40.0f);
    (new GuiButton(orders_layout, "ORDER_STAND_GROUND", tr("Stand ground"),
        [this]()
        {
            if (auto target = getOrderTarget())
                my_player_info->commandSetAIOrder(target, AIOrder::StandGround);
        }
    ))
        ->setTextSize(20.0f)
        ->setSize(GuiElement::GuiSizeMax, 40.0f);
    (new GuiButton(orders_layout, "ORDER_IDLE", tr("Idle"),
        [this]()
        {
            if (auto target = getOrderTarget())
                my_player_info->commandSetAIOrder(target, AIOrder::Idle);
        }
    ))
        ->setTextSize(20.0f)
        ->setSize(GuiElement::GuiSizeMax, 40.0f);

    (new GuiLabel(orders_layout, "ORDERS_LABEL", tr("Issue drone orders"), 20.0f))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, 40.0f);

    // Combat maneuver (2D snap slider).
    combat_maneuver_layout = new GuiElement(radar_pane, "COMBAT_MANEUVER");
    combat_maneuver_layout
        ->setPosition(-20.0f, -300.0f, sp::Alignment::BottomRight)
        ->setSize(200.0f, 150.0f);

    auto combat_charge = new GuiProgressbar(combat_maneuver_layout, "COMBAT_CHARGE", 0.0f, 1.0f, 0.0f);
    combat_charge
        ->setColor(glm::u8vec4(192, 192, 192, 64))
        ->setPosition(0.0f, 0.0f, sp::Alignment::BottomCenter)
        ->setSize(GuiElement::GuiSizeMax, 50.0f);
    (new GuiLabel(combat_charge, "COMBAT_LABEL", tr("Combat maneuver"), 20.0f))
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopLeft)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    auto combat_slider = new GuiSnapSlider2D(combat_maneuver_layout, "COMBAT_SLIDER", glm::vec2(-1.0f, 1.0f), glm::vec2(1.0f, 0.0f), glm::vec2(0.0f, 0.0f),
        [this](glm::vec2 value)
        {
            my_player_info->commandDroneCombatManeuverBoost(value.y);
            my_player_info->commandDroneCombatManeuverStrafe(value.x);
        }
    );
    combat_slider
        ->setPosition(0.0f, -50.0f, sp::Alignment::BottomCenter)
        ->setSize(GuiElement::GuiSizeMax, 100.0f);

    player_stats = new GuiElement(radar_pane, "PLAYER_STATS");
    player_stats
        ->setPosition(-20.0f, -20.0f, sp::Alignment::BottomRight)
        ->setSize(250.0f, 200.0f)
        ->setAttribute("layout", "vertical");

    player_callsign_display = new GuiKeyValueDisplay(player_stats, "PLAYER_CALLSIGN", 0.45f, tr("Callsign"), "");
    player_callsign_display->setSize(GuiElement::GuiSizeMax, 40.0f);

    player_energy_display = new GuiKeyValueDisplay(player_stats, "PLAYER_ENERGY", 0.45f, tr("Energy"), "");
    player_energy_display
        ->setIcon("gui/icons/energy")
        ->setTextSize(20.0f)
        ->setSize(GuiElement::GuiSizeMax, 40.0f);

    player_heading_display = new GuiKeyValueDisplay(player_stats, "PLAYER_HEADING", 0.45f, tr("Heading"), "");
    player_heading_display
        ->setIcon("gui/icons/heading")
        ->setSize(GuiElement::GuiSizeMax, 40.0f);

    player_velocity_display = new GuiKeyValueDisplay(player_stats, "PLAYER_VELOCITY", 0.45f, tr("Speed"), "");
    player_velocity_display
        ->setIcon("gui/icons/speed")
        ->setSize(GuiElement::GuiSizeMax, 40.0f);

    player_shields_display = new GuiKeyValueDisplay(player_stats, "PLAYER_SHIELDS", 0.45f, tr("Shields"), "");
    player_shields_display
        ->setIcon("gui/icons/shields")
        ->setSize(GuiElement::GuiSizeMax, 40.0f);

    // Beam info box.
    beam_info_box = new GuiElement(radar_pane, "BEAM_INFO_BOX");
    beam_info_box
        ->setPosition(0.0f, -20.0f, sp::Alignment::BottomCenter)
        ->setSize(500.0f, 50.0f)
        ->hide();

    {
        (new GuiLabel(beam_info_box, "BEAM_LABEL", tr("Beams"), 30.0f))
            ->addBackground()
            ->setPosition(0.0f, 0.0f, sp::Alignment::BottomLeft)
            ->setSize(80.0f, 50.0f);

        beam_freq_selector = new GuiSelector(beam_info_box, "BEAM_FREQ",
            [this](int index, string value)
            {
                my_player_info->commandDroneSetBeamFrequency(index);
            }
        );

        for (int n = 0; n <= BeamWeaponSys::max_frequency; n++)
            beam_freq_selector->addEntry(frequencyToString(n), frequencyToString(n));
        beam_freq_selector
            ->setPosition(80.0f, 0.0f, sp::Alignment::BottomLeft)
            ->setSize(132.0f, 50.0f);

        if (gameGlobalInfo->use_system_damage)
        {
            beam_sys_selector = new GuiSelector(beam_info_box, "BEAM_SYS_TARGET",
                [this](int index, string value)
                {
                    my_player_info->commandDroneSetBeamSystemTarget(ShipSystem::Type(index + static_cast<int>(ShipSystem::Type::None)));
                }
            );
            beam_sys_selector->addEntry(tr("target", "Hull"), "-1");
            for (int n = 0; n < ShipSystem::COUNT; n++)
                beam_sys_selector->addEntry(getLocaleSystemName(ShipSystem::Type(n)), string(n));
            beam_sys_selector
                ->setSelectionIndex(0)
                ->setPosition(0.0f, 0.0f, sp::Alignment::BottomRight)
                ->setSize(288.0f, 50.0f);
        }
    }

    // Missile tube layout.
    tube_controls_layout = new GuiElement(radar_pane, "TUBE_CONTROLS");
    tube_controls_layout
        ->setPosition(20.0f, -20.0f, sp::Alignment::BottomLeft)
        ->setSize(350.0f, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "verticalbottom");
    tube_rows_layout = new GuiElement(tube_controls_layout, "TUBE_ROWS");
    tube_rows_layout->setAttribute("layout", "vertical");

    // Missile type selector (above tube rows).
    for (int n = MW_Count - 1; n >= 0; n--)
    {
        missile_type_rows[n].layout = new GuiElement(tube_controls_layout, "MISSILE_TYPE_ROW_" + string(n));
        missile_type_rows[n].layout->setSize(GuiElement::GuiSizeMax, 40.0f)->setAttribute("layout", "horizontal");
        missile_type_rows[n].button = new GuiToggleButton(missile_type_rows[n].layout, "MISSILE_TYPE_" + string(n), getLocaleMissileWeaponName(EMissileWeapons(n)),
            [this, n](bool value)
            {
                if (value) selected_missile_type = n;
                else selected_missile_type = -1;
                for (int idx = 0; idx < MW_Count; idx++)
                    missile_type_rows[idx].button->setValue(idx == selected_missile_type);
            }
        );
        missile_type_rows[n].button->setTextSize(28)->setSize(200.0f, 40.0f);
    }
    missile_type_rows[MW_Homing].button->setIcon("gui/icons/weapon-homing.png");
    missile_type_rows[MW_Mine].button->setIcon("gui/icons/weapon-mine.png");
    missile_type_rows[MW_EMP].button->setIcon("gui/icons/weapon-emp.png");
    missile_type_rows[MW_Nuke].button->setIcon("gui/icons/weapon-nuke.png");
    missile_type_rows[MW_HVLI].button->setIcon("gui/icons/weapon-hvli.png");

    // Manual aim toggle button near tube controls.
    manual_aim_button = new GuiToggleButton(radar_pane, "MANUAL_AIM", tr("missile", "Lock"),
        [this](bool value)
        {
            use_manual_aim = value;
            missile_aim->setVisible(value);
        }
    );
    manual_aim_button
        ->setValue(false)
        ->setIcon("gui/icons/lock")
        ->setPosition(250.0f, 70.0f, sp::Alignment::TopCenter)
        ->setSize(130.0f, 50.0f);

    // Player ship controls (shown when disconnected).
    player_controls = new GuiElement(radar_pane, "PLAYER_CONTROLS");
    player_controls->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Sidebar: custom ship functions.
    (new GuiCustomShipFunctions(radar_pane, CrewPosition::droneOperations, "CSF"))
        ->setPosition(-20.0f, 120.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, 250.0f);

    applyConnectionState();
}

sp::ecs::Entity DroneOperationsScreen::connectedDrone() const
{
    if (!my_spaceship) return {};

    if (auto dl = my_spaceship.getComponent<DroneLink>())
        return dl->linked_drone;

    return {};
}

bool DroneOperationsScreen::isDroneConnected() const
{
    if (!my_spaceship) return false;

    if (auto dl = my_spaceship.getComponent<DroneLink>())
    {
        if (dl->linked_drone != sp::ecs::Entity()) return true;
        else return false;
    }

    return false;
}

sp::ecs::Entity DroneOperationsScreen::getOrderTarget()
{
    // 1. If connected to a drone, send order to the connected drone.
    if (auto drone = connectedDrone())
        if (isDroneConnected())
            return drone;

    // 2. If a drone is targeted, send order to the target.
    if (auto target = targets.get())
        if (target.hasComponent<AllowDroneLink>())
            return target;

    // 3. If a drone is selected in the selector, send order to that drone.
    int idx = drone_selector->getSelectionIndex();
    if (idx >= 0 && idx < static_cast<int>(drone_list.size()))
        return drone_list[idx];

    return {};
}

void DroneOperationsScreen::applyConnectionState()
{
    auto drone = connectedDrone();
    bool connected = drone && isDroneConnected();

    connect_button->setValue(connected);
    drone_selector->setEnable(!connected);

    // Radar follows drone when connected, player ship when not.
    radar->setAutoCenterTarget(connected ? drone : my_spaceship);

    // Stats.
    player_stats->setVisible(!connected);
    drone_stats->setVisible(connected);

    // Shields buttons swap between player and drone.
    drone_shields_button->setVisible(connected);

    // Drone docking button.
    drone_docking_button->setVisible(connected);

    // Engine/weapon controls.
    engine_layout->setVisible(connected);
    combat_maneuver_layout->setVisible(connected);
    tube_controls_layout->setVisible(connected);
    orders_layout->setVisible(!connected);

    // Player-ship-only controls.
    player_controls->setVisible(!connected);

    // Reset beam system selector to Hull when connecting.
    if (connected && beam_sys_selector)
        beam_sys_selector->setSelectionIndex(0);

    // Hide heading hint on disconnect.
    if (!connected) heading_hint->hide();
}

static string getTubeName(float direction)
{
    if (std::abs(angleDifference(0.0f, direction)) <= 45.0f)
        return tr("tube", "Front");
    if (std::abs(angleDifference(90.0f, direction)) < 45.0f)
        return tr("tube", "Right");
    if (std::abs(angleDifference(-90.0f, direction)) < 45.0f)
        return tr("tube", "Left");
    if (std::abs(angleDifference(180.0f, direction)) <= 45.0f)
        return tr("tube", "Rear");
    return "?" + string(direction);
}

void DroneOperationsScreen::updateTubeRows(sp::ecs::Entity drone_entity)
{
    auto missiletubes = drone_entity ? drone_entity.getComponent<MissileTubes>() : nullptr;

    tube_controls_layout->setVisible(missiletubes != nullptr);
    if (!missiletubes) return;

    // Grow the row vector as needed.
    while (tube_rows.size() < missiletubes->mounts.size())
    {
        uint32_t row_idx = tube_rows.size();
        TubeRow row;
        row.layout = new GuiElement(tube_rows_layout, "TUBE_ROW_" + string(row_idx));
        row.layout->setAttribute("layout", "horizontal");

        row.load_button = new GuiButton(row.layout, "TUBE_LOAD_" + string(row_idx), tr("missile", "Load"),
            [this, row_idx]()
            {
                if (!isDroneConnected()) return;
                auto drone = connectedDrone();
                if (!drone) return;

                auto tubes = drone.getComponent<MissileTubes>();
                if (!tubes || row_idx >= tubes->mounts.size()) return;
                auto& tube = tubes->mounts[row_idx];
                if (tube.state == MissileTubes::MountPoint::State::Empty)
                {
                    if (selected_missile_type >= 0)
                        my_player_info->commandDroneLoadTube(row_idx, static_cast<EMissileWeapons>(selected_missile_type));
                }
                else
                {
                    my_player_info->commandDroneUnloadTube(row_idx);
                }
            }
        );
        row.load_button->setSize(130.0f, 50.0f);

        row.fire_button = new GuiButton(row.layout, "TUBE_FIRE_" + string(row_idx), tr("missile", "Fire"),
            [this, row_idx]()
            {
                if (!isDroneConnected()) return;
                auto drone = connectedDrone();
                if (!drone) return;

                auto tubes = drone.getComponent<MissileTubes>();
                if (!tubes || row_idx >= tubes->mounts.size()) return;
                auto& tube = tubes->mounts[row_idx];
                if (tube.state == MissileTubes::MountPoint::State::Loaded)
                {
                    float target_angle = missile_aim->getValue();

                    if (!use_manual_aim)
                    {
                        auto target = drone.getComponent<Target>();
                        target_angle = MissileSystem::calculateFiringSolution(drone, tube, target ? target->entity : sp::ecs::Entity{});
                        if (target_angle == std::numeric_limits<float>::infinity())
                        {
                            auto transform = drone.getComponent<sp::Transform>();
                            target_angle = (transform ? transform->getRotation() : 0.0f) + tube.direction;
                        }
                    }
                    my_player_info->commandDroneFireTube(row_idx, target_angle);
                }
            }
        );
        row.fire_button->setSize(200.0f, 50.0f);

        row.loading_bar = new GuiProgressbar(row.layout, "TUBE_BAR_" + string(row_idx), 0.0f, 1.0f, 0.0f);
        row.loading_bar
            ->setColor(glm::u8vec4(128, 128, 128, 255))
            ->setSize(200.0f, 50.0f)
            ->hide();
        row.loading_label = new GuiLabel(row.loading_bar, "TUBE_BAR_LABEL_" + string(row_idx), tr("missile", "Loading"), 35.0f);
        row.loading_label->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

        tube_rows.push_back(row);
    }

    auto sys = ShipSystem::get(drone_entity, ShipSystem::Type::MissileSystem);
    float health = sys ? sys->health : 1.0f;
    float power_level = sys ? sys->power_level : 1.0f;

    auto warp = drone_entity.getComponent<WarpDrive>();
    bool warp_active = warp && warp->current > 0.0f;

    // Update row visibility and labels.
    for (size_t n = 0; n < tube_rows.size(); n++)
    {
        if (n >= missiletubes->mounts.size())
        {
            tube_rows[n].layout->hide();
            continue;
        }
        tube_rows[n].layout->show();
        auto& tube = missiletubes->mounts[n];

        if (tube.canOnlyLoad(MW_Mine))
            tube_rows[n].fire_button->setIcon("gui/icons/weapon-mine", sp::Alignment::CenterLeft);
        else
            tube_rows[n].fire_button->setIcon("gui/icons/missile", sp::Alignment::CenterLeft, tube.direction);

        switch(tube.state)
        {
        case MissileTubes::MountPoint::State::Empty:
            tube_rows[n].load_button
                ->setText(tr("missile", "Load"))
                ->setEnable(selected_missile_type >= 0 && tube.canLoad(static_cast<EMissileWeapons>(selected_missile_type)));
            if (health <= 0.0f)
                tube_rows[n].load_button->disable();
            tube_rows[n].fire_button
                ->setText(getTubeName(tube.direction) + ": " + tr("missile", "Empty"))
                ->disable()
                ->show();
            tube_rows[n].loading_bar->hide();
            break;
        case MissileTubes::MountPoint::State::Loaded:
            tube_rows[n].load_button->setText(tr("missile", "Unload"));
            if (health <= 0.0f || power_level <= 0.0f)
            {
                tube_rows[n].fire_button
                    ->disable()
                    ->show();
                tube_rows[n].load_button
                    ->disable()
                    ->show();
            }
            else
            {
                tube_rows[n].fire_button
                    ->enable()
                    ->show();
                tube_rows[n].load_button
                    ->enable()
                    ->show();
            }
            tube_rows[n].fire_button->setText(getTubeName(tube.direction) + ": " + getLocaleMissileWeaponName(tube.type_loaded));
            tube_rows[n].loading_bar->hide();
            break;
        case MissileTubes::MountPoint::State::Loading:
            tube_rows[n].load_button
                ->setText(tr("missile", "Load"))
                ->disable();
            tube_rows[n].fire_button
                ->setText(getTubeName(tube.direction) + ": " + getLocaleMissileWeaponName(tube.type_loaded))
                ->hide();
            tube_rows[n].loading_bar
                ->setValue(1.0f - tube.delay / tube.load_time)
                ->show();
            tube_rows[n].loading_label->setText(tr("missile", "Loading"));
            break;
        case MissileTubes::MountPoint::State::Unloading:
            tube_rows[n].load_button
                ->setText(tr("missile", "Unload"))
                ->disable();
            tube_rows[n].fire_button
                ->setText(getLocaleMissileWeaponName(tube.type_loaded))
                ->hide();
            tube_rows[n].loading_bar
                ->setValue(tube.delay / tube.load_time)
                ->show();
            tube_rows[n].loading_label->setText(tr("missile", "Unloading"));
            break;
        case MissileTubes::MountPoint::State::Firing:
            tube_rows[n].load_button
                ->setText(tr("missile", "Load"))
                ->disable();
            tube_rows[n].fire_button
                ->setText(tr("missile", "Firing"))
                ->disable()
                ->show();
            tube_rows[n].loading_bar->hide();
            break;
        }

        if (warp_active) tube_rows[n].fire_button->disable();
    }
}

void DroneOperationsScreen::rebuildDroneSelector()
{
    drone_selector->clear();

    for (auto& drone : drone_list)
    {
        string label = "Drone";
        if (auto n = drone.getComponent<CallSign>()) label = n->callsign;
        drone_selector->addEntry(label, "");
    }

    if (drone_selector->getSelectionIndex() < 0 && !drone_list.empty())
        drone_selector->setSelectionIndex(0);
}

void DroneOperationsScreen::onUpdate()
{
    if (!my_spaceship || !isVisible()) return;

    // Don't show controls if this entity lacks a DroneController.
    auto dc = my_spaceship.getComponent<DroneController>();
    if (!dc)
    {
        background_gradient->hide();
        no_drone_controller_label->show();
        radar_pane->hide();
        return;
    }

    // Enforce visibility if component state changes.
    background_gradient->show();
    no_drone_controller_label->hide();
    radar_pane->show();

    // Rebuild drone selector if available drones changed.
    auto ship_transform = my_spaceship.getComponent<sp::Transform>();
    float range = dc ? dc->control_range : 5000.0f;

    std::vector<sp::ecs::Entity> new_list;
    if (ship_transform)
    {
        for (auto [entity, adl, transform] : sp::ecs::Query<AllowDroneLink, sp::Transform>())
        {
            if (adl.owner != my_spaceship) continue;
            if (glm::length(transform.getPosition() - ship_transform->getPosition()) > range) continue;

            // Require at least friend-or-foe identification before allowing
            // link.
            if (auto scan = entity.getComponent<ScanState>())
            {
                if (scan->getStateFor(my_spaceship) == ScanState::State::NotScanned)
                    continue;
            }

            new_list.push_back(entity);
        }
    }

    if (new_list != drone_list)
    {
        drone_list = new_list;
        rebuildDroneSelector();
    }

    // Auto-select the currently targeted entity if it's an owned drone.
    if (auto target_comp = my_spaceship.getComponent<Target>())
    {
        for (int i = 0; i < static_cast<int>(drone_list.size()); i++)
        {
            if (drone_list[i] == target_comp->entity)
            {
                drone_selector->setSelectionIndex(i);
                break;
            }
        }
    }

    // Detect server-side state changes (connect or disconnect).
    if (connect_button->getValue() != isDroneConnected())
        applyConnectionState();

    // Moved from onDraw
    auto drone = connectedDrone();
    bool connected = drone && isDroneConnected();

    // Sync radar target entity every frame.
    radar->setAutoCenterTarget(connected ? drone : my_spaceship);
    radar->setTargetProjectionEntity(connected ? drone : sp::ecs::Entity{});

    if (connected)
    {
        // Drone stats.
        if (auto cs = drone.getComponent<CallSign>())
            drone_callsign_display->setValue(cs->callsign);
        else
            drone_callsign_display->setValue("");

        auto lrr = drone.getComponent<LongRangeRadar>();
        radar->setDistance(lrr ? lrr->short_range : 5000.0f);
        zoom_slider->hide();

        auto reactor = drone.getComponent<Reactor>();
        drone_energy_display->setVisible(reactor);
        if (reactor)
        {
            drone_energy_display->setValue(string(static_cast<int>(reactor->energy)) + "/" + string(static_cast<int>(reactor->max_energy)));
        }

        if (auto transform = drone.getComponent<sp::Transform>())
        {
            float rotation = transform->getRotation() - 270.0f;
            while (rotation < 0) rotation += 360.0f;
            while (rotation > 360.0f) rotation -= 360.0f;
            drone_heading_display->setValue(string(static_cast<int>(rotation)));
            auto physics = drone.getComponent<sp::Physics>();
            drone_velocity_display->setVisible(physics);

            if (physics)
            {
                drone_velocity_display->setValue(tr("{value} {unit}/min").format({
                    {"value", string(glm::length(physics->getVelocity()) / 1000.0f * 60.0f, 1)},
                    {"unit", DISTANCE_UNIT_1K}
                }));
            }
        }
        if (auto shields = drone.getComponent<Shields>())
        {
            float total = 0.0f;
            float max_total = 0.0f;

            for (size_t n = 0; n < shields->entries.size(); n++)
            {
                total += shields->entries[n].level;
                max_total += shields->entries[n].max;
            }

            if (max_total > 0.0f)
                drone_shields_display->setValue(string(static_cast<int>(total / max_total * 100.0f)) + "%");
        }
        // Total heat: sum all ShipSystem heat_level from the drone.
        // Only show heat if the drone has a Coolant system (and thus the
        // capacity to manage heat).
        auto coolant = drone.getComponent<Coolant>();
        drone_heat_display->setVisible(coolant);
        if (coolant)
        {
            float total_heat = 0.0f;

            for (int sys_idx = 0; sys_idx < ShipSystem::COUNT; sys_idx++)
            {
                auto sys = ShipSystem::get(drone, ShipSystem::Type(sys_idx));
                if (sys) total_heat += sys->heat_level;
            }

            drone_heat_display->setValue(string(static_cast<int>(total_heat / ShipSystem::COUNT * 100.0f)) + "%");
        }

        // Drone distance / max control range.
        auto ship_transform = my_spaceship.getComponent<sp::Transform>();
        auto drone_transform = drone.getComponent<sp::Transform>();
        if (ship_transform && drone_transform)
        {
            float dist = glm::length(drone_transform->getPosition() - ship_transform->getPosition());
            float range = dc->control_range;
            if (auto sensors = my_spaceship.getComponent<SensorsSystem>())
                range *= sensors->getSystemEffectiveness();
            drone_distance_display->setValue(tr("{current} / {max} {unit}").format({
                {"current", string((dist / 1000.0f), 1)},
                {"max", string(static_cast<int>(range / 1000.0f))},
                {"unit", DISTANCE_UNIT_1K}
            }));
        }

        // Drone shields button: sync state and label.
        if (auto shields = drone.getComponent<Shields>())
        {
            drone_shields_button
                ->setValue(shields->active)
                ->show();
            string status = shields->active ? tr("shields", "ON") : tr("shields", "OFF");
            if (gameGlobalInfo->use_beam_shield_frequencies && shields->frequency != -1)
            {
                drone_shields_button->setText(tr("{frequency} Shields: {status}").format({
                    {"frequency", frequencyToString(shields->frequency)},
                    {"status", status}
                }));
            }
            else
            {
                drone_shields_button->setText(tr("Shields: {status}").format({
                    {"status", status}
                }));
            }
        }
        else drone_shields_button->hide();

        // Beam info visibility.
        auto beams = drone.getComponent<BeamWeaponSys>();
        beam_info_box->setVisible(beams && (gameGlobalInfo->use_beam_shield_frequencies || gameGlobalInfo->use_system_damage));

        if (beams)
        {
            if (beam_freq_selector)
                beam_freq_selector->setSelectionIndex(beams->frequency);
        }

        // Warp/jump visibility.
        engine_layout->setVisible(true);
        warp_controls->setVisible(drone.hasComponent<WarpDrive>());

        // Combat maneuver visibility.
        combat_maneuver_layout->setVisible(drone.hasComponent<CombatManeuveringThrusters>());

        // Missile tube controls.
        updateTubeRows(drone);

        // Update missile type selector visibility and storage counts.
        auto tubes = drone.getComponent<MissileTubes>();
        for (int n = 0; n < MW_Count; n++)
        {
            if (tubes)
            {
                missile_type_rows[n].button->setText(getLocaleMissileWeaponName(EMissileWeapons(n)) + " [" + string(tubes->storage[n]) + "/" + string(tubes->storage_max[n]) + "]");
                missile_type_rows[n].layout->setVisible(tubes->storage_max[n] > 0);
            }
            else missile_type_rows[n].layout->hide();
        }

        // Weapon hotkeys.
        if (keys.weapons_select_homing.getDown())
        {
            selected_missile_type = MW_Homing;
            for (int idx = 0; idx < MW_Count; idx++)
                missile_type_rows[idx].button->setValue(idx == selected_missile_type);
        }
        if (keys.weapons_select_nuke.getDown())
        {
            selected_missile_type = MW_Nuke;
            for (int idx = 0; idx < MW_Count; idx++)
                missile_type_rows[idx].button->setValue(idx == selected_missile_type);
        }
        if (keys.weapons_select_mine.getDown())
        {
            selected_missile_type = MW_Mine;
            for (int idx = 0; idx < MW_Count; idx++)
                missile_type_rows[idx].button->setValue(idx == selected_missile_type);
        }
        if (keys.weapons_select_emp.getDown())
        {
            selected_missile_type = MW_EMP;
            for (int idx = 0; idx < MW_Count; idx++)
                missile_type_rows[idx].button->setValue(idx == selected_missile_type);
        }
        if (keys.weapons_select_hvli.getDown())
        {
            selected_missile_type = MW_HVLI;
            for (int idx = 0; idx < MW_Count; idx++)
                missile_type_rows[idx].button->setValue(idx == selected_missile_type);
        }

        if (tubes)
        {
            for (unsigned int n = 0; n < std::min(tubes->mounts.size(), static_cast<size_t>(16)); n++)
            {
                if (keys.weapons_load_tube[n].getDown())
                {
                    if (tubes->mounts[n].state == MissileTubes::MountPoint::State::Empty && selected_missile_type >= 0)
                        my_player_info->commandDroneLoadTube(n, static_cast<EMissileWeapons>(selected_missile_type));
                }

                if (keys.weapons_unload_tube[n].getDown())
                    my_player_info->commandDroneUnloadTube(n);

                if (keys.weapons_fire_tube[n].getDown())
                {
                    if (tubes->mounts[n].state == MissileTubes::MountPoint::State::Loaded)
                    {
                        float target_angle = missile_aim->getValue();

                        if (!use_manual_aim)
                        {
                            auto target = drone.getComponent<Target>();
                            target_angle = MissileSystem::calculateFiringSolution(drone, tubes->mounts[n], target ? target->entity : sp::ecs::Entity{});

                            if (target_angle == std::numeric_limits<float>::infinity())
                            {
                                auto transform = drone.getComponent<sp::Transform>();
                                target_angle = (transform ? transform->getRotation() : 0.0f) + tubes->mounts[n].direction;
                            }
                        }

                        my_player_info->commandDroneFireTube(n, target_angle);
                    }
                }
            }
        }

        // Aim lock.
        bool has_tubes = drone.hasComponent<MissileTubes>();
        manual_aim_button->setVisible(has_tubes);
        missile_aim->setVisible(has_tubes && use_manual_aim);

        // Impulse sync and label update.
        if (auto engine = drone.getComponent<ImpulseEngine>())
        {
            impulse_slider->setValue(engine->request);
            impulse_label->setValue(string(static_cast<int>(std::round(engine->actual * 100.0f))) + "%");
        }

        if (auto warp = drone.getComponent<WarpDrive>())
        {
            warp_slider->setValue(warp->request);
            warp_label->setValue(string(warp->current, 1));

            if (warp_slider->getRangeMin() != warp->max_level)
            {
                warp_slider
                    ->clearSnapValues()
                    ->setRange(warp->max_level, 0.0f);
                for (int n = 0; n <= warp->max_level; n++)
                    warp_slider->addSnapValue(static_cast<float>(n), 0.5f);
            }
        }

        jump_controls->setVisible(drone.hasComponent<JumpDrive>());

        if (auto jump = drone.getComponent<JumpDrive>())
        {
            if (jump->delay > 0.0f)
            {
                if (jump->get_seconds_to_jump() == std::numeric_limits<int>::max())
                {
                    jump_label
                        ->setKey(tr("jumpcontrol", "Jump"))
                        ->setValue(tr("jumpcontrol", "delayed"));
                }
                else
                {
                    jump_label
                        ->setKey(tr("jumpcontrol", "Jump"))
                        ->setValue(tr("jumpcontrol", "{delay} sec.").format({
                            {"delay", string(jump->get_seconds_to_jump())}
                        }));
                }

                jump_distance_slider
                    ->disable()
                    ->show();
                jump_button
                    ->setText(tr("jumpcontrol", "Abort"))
                    ->setStyle("button.jump_abort")
                    ->enable();
                jump_charge_bar->hide();
            }
            else if (jump->charge < jump->max_distance)
            {
                jump_label
                    ->setKey(tr("jumpcontrol", "Charging"))
                    ->setValue("...");
                jump_distance_slider
                    ->disable()
                    ->hide();
                jump_button
                    ->setText(tr("jumpcontrol", "Jump"))
                    ->setStyle("button")
                    ->disable();
                jump_charge_bar
                    ->setRange(0.0f, jump->max_distance)
                    ->setValue(jump->charge)
                    ->show();
            }
            else
            {
                jump_label
                    ->setKey(tr("jumpcontrol_distance", "Distance"))
                    ->setValue(string(jump_distance_slider->getValue() / 1000.0f, 1) + DISTANCE_UNIT_1K);
                jump_distance_slider
                    ->setRange(jump->max_distance, jump->min_distance)
                    ->enable()
                    ->show();
                jump_button
                    ->setText(tr("jumpcontrol", "Jump"))
                    ->setStyle("button")
                    ->enable();
                jump_charge_bar->hide();
            }
        }

        // Target sync.
        if (auto target_comp = drone.getComponent<Target>())
            targets.set(target_comp->entity);
        else targets.set(sp::ecs::Entity{});
    }
    else
    {
        // Player-ship stats.
        if (auto cs = my_spaceship.getComponent<CallSign>())
            player_callsign_display->setValue(cs->callsign);
        else
            player_callsign_display->setValue("");

        float control_range = dc ? dc->control_range : 5000.0f;
        if (control_range > 5000.0f)
        {
            if (control_range != previous_control_range)
            {
                zoom_slider->setRange(control_range, 5000.0f);
                previous_control_range = control_range;
            }

            float key_zoom_delta = keys.zoom_in.getValue() - keys.zoom_out.getValue();
            if (key_zoom_delta != 0.0f)
            {
                float view_distance = std::clamp(
                    radar->getDistance() * (1.0f - (key_zoom_delta * 0.1f)),
                    5000.0f,
                    control_range
                );
                radar->setDistance(view_distance);
                zoom_slider->setValue(view_distance);
            }

            zoom_slider->show();
        }
        else
        {
            zoom_slider->hide();
            radar->setDistance(control_range);
            previous_control_range = 0.0f;
        }

        if (auto reactor = my_spaceship.getComponent<Reactor>())
            player_energy_display->setValue(string(static_cast<int>(reactor->energy)) + "/" + string(static_cast<int>(reactor->max_energy)));

        if (auto transform = my_spaceship.getComponent<sp::Transform>())
        {
            float rotation = transform->getRotation() - 270.0f;
            while (rotation < 0) rotation += 360.0f;
            while (rotation > 360.0f) rotation -= 360.0f;
            player_heading_display->setValue(string(static_cast<int>(rotation)));

            if (auto physics = my_spaceship.getComponent<sp::Physics>())
                player_velocity_display->setValue(string(static_cast<int>(glm::length(physics->getVelocity()) / 1000.0f * 60.0f)) + " u/min");
        }
        if (auto shields = my_spaceship.getComponent<Shields>())
        {
            player_shields_display->show();
            float total = 0.0f;
            float max_total = 0.0f;

            for (size_t n = 0; n < shields->entries.size(); n++)
            {
                total += shields->entries[n].level;
                max_total += shields->entries[n].max;
            }

            if (max_total > 0)
                player_shields_display->setValue(string(static_cast<int>(total / max_total * 100.0f)) + "%");
        }
        else player_shields_display->hide();

        beam_info_box->hide();
        engine_layout->hide();
        combat_maneuver_layout->hide();
        tube_controls_layout->hide();
        manual_aim_button->hide();
        missile_aim->hide();

        if (auto target_comp = my_spaceship.getComponent<Target>())
            targets.set(target_comp->entity);
        else targets.set(sp::ecs::Entity{});
    }
}

void DroneOperationsScreen::onDraw(sp::RenderTarget& renderer)
{
    GuiOverlay::onDraw(renderer);
    if (!my_spaceship || !isVisible()) return;
}
