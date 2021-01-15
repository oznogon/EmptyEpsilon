#include "main.h"
#include "playerInfo.h"
#include "spaceObjects/playerSpaceship.h"
#include "singlePilotScreen.h"
#include "preferenceManager.h"

#include "screenComponents/viewport3d.h"

#include "screenComponents/alertOverlay.h"
#include "screenComponents/combatManeuver.h"
#include "screenComponents/radarView.h"
#include "screenComponents/impulseControls.h"
#include "screenComponents/warpControls.h"
#include "screenComponents/jumpControls.h"
#include "screenComponents/dockingButton.h"

#include "screenComponents/missileTubeControls.h"
#include "screenComponents/aimLock.h"
#include "screenComponents/shieldsEnableButton.h"
#include "screenComponents/beamFrequencySelector.h"
#include "screenComponents/beamTargetSelector.h"

#include "screenComponents/openCommsButton.h"
#include "screenComponents/commsOverlay.h"

#include "screenComponents/customShipFunctions.h"

#include "gui/gui2_label.h"
#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_rotationdial.h"
#include "gui/gui2_togglebutton.h"
#include "gui/gui2_image.h"

SinglePilotScreen::SinglePilotScreen(GuiContainer* owner)
: GuiOverlay(owner, "SINGLEPILOT_SCREEN", colorConfig.background)
{
/*
    // Render the radar shadow and background decorations.
    background_gradient = new GuiOverlay(this, "BACKGROUND_GRADIENT", sf::Color::White);
    background_gradient->setTextureCenter("gui/BackgroundGradient");

    background_crosses = new GuiOverlay(this, "BACKGROUND_CROSSES", sf::Color::White);
    background_crosses->setTextureTiled("gui/BackgroundCrosses");
*/
    targeting_mode = false;
    first_person = PreferencesManager::get("first_person") == "1" ? true : false;
    view_rotation = 0.0f;
    target_rotation = 0.0f;

    // Render the 3D viewport across the entire window
    viewport = new GuiViewport3D(this, "3D_VIEW");
    viewport->setPosition(0, 0, ACenter)->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    viewport->showCallsigns()->showHeadings()->showSpacedust();
    viewport->show();

    // Render the alert level color overlay.
    (new AlertLevelOverlay(this));

    // 5U tactical radar with piloting features.
    radar = new GuiRadarView(this, "TACTICAL_RADAR", &targets);
    radar->setPosition(0, -20, ABottomCenter)->setSize(GuiElement::GuiSizeMatchHeight, 300);
    radar->setRangeIndicatorStepSize(1000.0)->shortRange()->enableGhostDots()->enableWaypoints()->enableCallsigns()->enableHeadingIndicators()->setStyle(GuiRadarView::Circular);
    radar->enableMissileTubeIndicators();
    radar->setCallbacks(
        [this](sf::Vector2f position) {
            // On single tap/click...
            if (my_spaceship)
            {
                // If a target is near the tap location, select it.
                targets.setToClosestTo(position, 250, TargetsContainer::Targetable);

                if (targets.get())
                {
                    // Set the target if we have one now.
                    my_spaceship->commandSetTarget(targets.get());
                }
                else
                {
                    // Otherwise, deselect target.
                    my_spaceship->commandSetTarget(NULL);
                }
            }
        },
        [this](sf::Vector2f position) {},
        [this](sf::Vector2f position) {}
    );
    radar->setAutoRotating(PreferencesManager::get("single_pilot_radar_lock", "0") == "1");

    // Ship stats and combat maneuver at bottom right corner of left panel.
    combat_maneuver = new GuiCombatManeuver(this, "COMBAT_MANEUVER");
    combat_maneuver->setPosition(-20, -180, ABottomRight)->setSize(200, 150)->setVisible(my_spaceship && my_spaceship->getCanCombatManeuver());

    GuiAutoLayout* stats = new GuiAutoLayout(this, "STATS", GuiAutoLayout::LayoutVerticalTopToBottom);
    stats->setPosition(-20, -20, ABottomRight)->setSize(240, 160);
    energy_display = new GuiKeyValueDisplay(stats, "ENERGY_DISPLAY", 0.45, tr("Energy"), "");
    energy_display->setIcon("gui/icons/energy")->setTextSize(20)->setSize(240, 40);
    heading_display = new GuiKeyValueDisplay(stats, "HEADING_DISPLAY", 0.45, tr("Heading"), "");
    heading_display->setIcon("gui/icons/heading")->setTextSize(20)->setSize(240, 40);
    velocity_display = new GuiKeyValueDisplay(stats, "VELOCITY_DISPLAY", 0.45, tr("Speed"), "");
    velocity_display->setIcon("gui/icons/speed")->setTextSize(20)->setSize(240, 40);
    shields_display = new GuiKeyValueDisplay(stats, "SHIELDS_DISPLAY", 0.45, tr("Shields"), "");
    shields_display->setIcon("gui/icons/shields")->setTextSize(20)->setSize(240, 40);

    // Unlocked missile aim dial and lock controls.
    missile_aim = new AimLock(this, "MISSILE_AIM", radar, -90, 360 - 90, 0, [this](float value)
    {
        tube_controls->setMissileTargetAngle(value);
    });
    missile_aim->setPosition(0, 0, ABottomCenter)->setSize(GuiElement::GuiSizeMatchHeight, 340);

    steering_wheel = new GuiRotationDial(this, "STEERING_WHEEL", -90, 360 - 90, 0, [this](float value)
    {
        target_rotation = (value - 270.0f) + (view_rotation - 90.0f);
        my_spaceship->commandTargetRotation(target_rotation);
    });
    steering_wheel->setPosition(0, -20, ABottomCenter)->setSize(GuiElement::GuiSizeMatchHeight, 300);

    missile_aim_icon = new GuiImage(missile_aim, "MISSILE_AIM_ICON", "gui/icons/lock");
    missile_aim_icon->setColor(sf::Color::Red)->setPosition(0, 0, ATopCenter)->setSize(GuiElement::GuiSizeMatchHeight, 20);

    steering_wheel_icon = new GuiImage(steering_wheel, "STEERING_WHEEL_ICON", "gui/icons/system_maneuver");
    steering_wheel_icon->setColor(sf::Color::Black)->setPosition(0, 0, ATopCenter)->setSize(GuiElement::GuiSizeMatchHeight, 20);

    // Weapon tube controls.
    tube_controls = new GuiMissileTubeControls(this, "MISSILE_TUBES");
    tube_controls->setPosition(20, -20, ABottomLeft);
    radar->enableTargetProjections(tube_controls);

    // Engine layout in top left corner of left panel.
    GuiAutoLayout* engine_layout = new GuiAutoLayout(this, "ENGINE_LAYOUT", GuiAutoLayout::LayoutHorizontalLeftToRight);
    engine_layout->setPosition(255, -80, ABottomCenter)->setSize(200, 240);
    warp_controls = (new GuiWarpControls(engine_layout, "WARP"))->setSize(90, GuiElement::GuiSizeMax);
    jump_controls = (new GuiJumpControls(engine_layout, "JUMP"))->setSize(90, GuiElement::GuiSizeMax);

    (new GuiImpulseControls(this, "IMPULSE"))->setPosition(-190, -80, ABottomCenter)->setSize(110, 240);

    // Docking, comms, and shields buttons across top.
    (new GuiDockingButton(this, "DOCKING"))->setPosition(20, 20, ATopLeft)->setSize(250, 50);
    (new GuiOpenCommsButton(this, "OPEN_COMMS_BUTTON", tr("Open Comms"), &targets))->setPosition(270, 20, ATopLeft)->setSize(250, 50);
    (new GuiCommsOverlay(this))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    (new GuiShieldsEnableButton(this, "SHIELDS_ENABLE"))->setPosition(520, 20, ATopLeft)->setSize(250, 50);

    // Missile lock toggle; auto-aim at target when enabled, manually aim when disabled.
    lock_aim = new AimLockButton(this, "LOCK_AIM", tube_controls, missile_aim);
    lock_aim->setPosition(-180, -20, ABottomCenter)->setSize(110, 50);

    // Targeting mode toggle; target on radar tap when enabled, navigate when disabled.
    targeting_mode_button = new GuiToggleButton(this, "TARGETING_MODE", tr("target", "TGT"), [this](bool value)
        {
            this->setTargetingMode(value);
        });
    targeting_mode_button->setValue(targeting_mode)->setIcon("gui/icons/station-weapons")->setPosition(180, -20, ABottomCenter)->setSize(110, 50);
    setTargetingMode(targeting_mode);

    // Initialize steering wheel rotation to initial rotation.
    if (my_spaceship)
    {
        view_rotation = radar->getViewRotation();
        target_rotation = my_spaceship->getRotation();
        steering_wheel->setValue(270.0f + (target_rotation - view_rotation));
    }

    (new GuiCustomShipFunctions(this, singlePilot, ""))->setPosition(-20, 120, ATopRight)->setSize(250, GuiElement::GuiSizeMax);
}

void SinglePilotScreen::onDraw(sf::RenderTarget& window)
{
    if (my_spaceship)
    {
        // Update energy and navigation stats.
        energy_display->setValue(string(int(my_spaceship->energy_level)));
        heading_display->setValue(string(fmodf(my_spaceship->getRotation() + 360.0 + 360.0 - 270.0, 360.0), 1));
        float velocity = sf::length(my_spaceship->getVelocity()) / 1000 * 60;
        velocity_display->setValue(string(velocity, 1) + DISTANCE_UNIT_1K + "/min");

        // Update warp/jump control visibility if it's changed.
        warp_controls->setVisible(my_spaceship->has_warp_drive);
        jump_controls->setVisible(my_spaceship->has_jump_drive);

        // Third-person view settings.
        float ship_rotation = my_spaceship->getRotation();
        float target_camera_yaw = ship_rotation;
        float camera_ship_distance = 420.0f;
        float camera_ship_height = 420.0f;

        // Set camera angle and position.
        camera_pitch = 30.0f;

        // Get view state.
        switch (view_state)
        {
            case SPV_Back:
            {
                target_camera_yaw += 180;
                break;
            }
            case SPV_Left:
            {
                target_camera_yaw -= 90;
                break;
            }
            case SPV_Right:
            {
                target_camera_yaw += 90;
                break;
            }
            case SPV_Target:
            {
                // Don't allow target tracking mode in first person.
                // It's not very useful and makes it difficult to tell if your ship is rotating.
                if (first_person)
                {
                    view_state = SPV_Forward;
                }
                else
                {
                    // Point camera at target.
                    P<SpaceObject> target_ship = my_spaceship->getTarget();

                    if (target_ship)
                    {
                        sf::Vector2f target_camera_diff = my_spaceship->getPosition() - target_ship->getPosition();
                        target_camera_yaw = sf::vector2ToAngle(target_camera_diff) + 180;
                    }
                }

                break;
            }
            default:
            {
                break;
            }
        }

        // Move camera if first person.
        if (first_person)
        {
            camera_ship_distance = -(my_spaceship->getRadius() * 1.5);
            camera_ship_height = my_spaceship->getRadius() / 10.f;
            camera_pitch = 0;
        }

        // Place and aim camera.
        sf::Vector2f cameraPosition2D = my_spaceship->getPosition() + sf::vector2FromAngle(target_camera_yaw) * -camera_ship_distance;
        sf::Vector3f targetCameraPosition(cameraPosition2D.x, cameraPosition2D.y, camera_ship_height);

#ifdef DEBUG
        // Allow top-down view in debug mode on Z key.
        if (sf::Keyboard::isKeyPressed(sf::Keyboard::Z))
        {
            targetCameraPosition.x = my_spaceship->getPosition().x;
            targetCameraPosition.y = my_spaceship->getPosition().y;
            targetCameraPosition.z = 3000.0;
            camera_pitch = 90.0f;
        }
#endif

        // Display first person perspective if enabled.
        if (first_person)
        {
            camera_position = targetCameraPosition;
            camera_yaw = target_camera_yaw;
        }
        else
        {
            camera_position = camera_position * 0.9f + targetCameraPosition * 0.1f;
            camera_yaw += sf::angleDifference(camera_yaw, target_camera_yaw) * 0.1f;
        }

        // Update shield indicators.
        string shields_value = string(my_spaceship->getShieldPercentage(0)) + "%";

        if (my_spaceship->hasSystem(SYS_RearShield))
        {
            shields_value += " " + string(my_spaceship->getShieldPercentage(1)) + "%";
        }

        shields_display->setValue(shields_value);

        if (my_spaceship->hasSystem(SYS_FrontShield) || my_spaceship->hasSystem(SYS_RearShield))
        {
            shields_display->show();
        }
        else
        {
            shields_display->hide();
        }

        // Set missile aim if tube controls are unlocked.
        missile_aim->setVisible(tube_controls->getManualAim());

        // Rotate steering wheel if radar rotation is enabled.
        view_rotation = radar->getViewRotation();
        steering_wheel->setValue(target_rotation - view_rotation);

        // Indicate our selected target.
        targets.set(my_spaceship->getTarget());
    }

    // Draw the view.
    GuiOverlay::onDraw(window);
}

bool SinglePilotScreen::onJoystickAxis(const AxisAction& axisAction)
{
    if (my_spaceship)
    {
        if (axisAction.category == "HELMS")
        {
            if (axisAction.action == "IMPULSE")
            {
                my_spaceship->commandImpulse(axisAction.value);
                return true;
            }
            if (axisAction.action == "ROTATE")
            {
                my_spaceship->commandTurnSpeed(axisAction.value);
                return true;
            }
            if (axisAction.action == "STRAFE")
            {
                my_spaceship->commandCombatManeuverStrafe(axisAction.value);
                return true;
            }
            if (axisAction.action == "BOOST")
            {
                my_spaceship->commandCombatManeuverBoost(axisAction.value);
                return true;
            }
        }
    }

    return false;
}

void SinglePilotScreen::onHotkey(const HotkeyResult& key)
{
    if (my_spaceship)
    {
        if (key.category == "HELMS")
        {
            if (key.hotkey == "TURN_LEFT")
            {
                float target_angle = my_spaceship->getRotation() - 5.0f;
                my_spaceship->commandTargetRotation(target_angle);
                steering_wheel->setValue(target_angle + view_rotation);
            }
            else if (key.hotkey == "TURN_RIGHT")
            {
                float target_angle = my_spaceship->getRotation() + 5.0f;
                my_spaceship->commandTargetRotation(target_angle);
                steering_wheel->setValue(target_angle + view_rotation);
            }
        }

        if (key.category == "WEAPONS")
        {
            if (key.hotkey == "NEXT_ENEMY_TARGET")
            {
                bool current_found = false;

                for (P<SpaceObject> obj : space_object_list)
                {
                    if (obj == targets.get())
                    {
                        current_found = true;
                        continue;
                    }

                    if (current_found && sf::length(obj->getPosition() - my_spaceship->getPosition()) < my_spaceship->getShortRangeRadarRange() && my_spaceship->isEnemy(obj) && my_spaceship->getScannedStateFor(obj) >= SS_FriendOrFoeIdentified && obj->canBeTargetedBy(my_spaceship))
                    {
                        targets.set(obj);
                        my_spaceship->commandSetTarget(targets.get());
                        return;
                    }
                }

                for (P<SpaceObject> obj : space_object_list)
                {
                    if (obj == targets.get())
                    {
                        continue;
                    }

                    if (my_spaceship->isEnemy(obj) && sf::length(obj->getPosition() - my_spaceship->getPosition()) < my_spaceship->getShortRangeRadarRange() && my_spaceship->getScannedStateFor(obj) >= SS_FriendOrFoeIdentified && obj->canBeTargetedBy(my_spaceship))
                    {
                        targets.set(obj);
                        my_spaceship->commandSetTarget(targets.get());
                        return;
                    }
                }
            }

            if (key.hotkey == "NEXT_TARGET")
            {
                bool current_found = false;

                for(P<SpaceObject> obj : space_object_list)
                {
                    if (obj == targets.get())
                    {
                        current_found = true;
                        continue;
                    }

                    if (obj == my_spaceship)
                    {
                        continue;
                    }

                    if (current_found && sf::length(obj->getPosition() - my_spaceship->getPosition()) < my_spaceship->getShortRangeRadarRange() && obj->canBeTargetedBy(my_spaceship))
                    {
                        targets.set(obj);
                        my_spaceship->commandSetTarget(targets.get());
                        return;
                    }
                }

                for(P<SpaceObject> obj : space_object_list)
                {
                    if (obj == targets.get() || obj == my_spaceship)
                    {
                        continue;
                    }

                    if (sf::length(obj->getPosition() - my_spaceship->getPosition()) < my_spaceship->getShortRangeRadarRange() && obj->canBeTargetedBy(my_spaceship))
                    {
                        targets.set(obj);
                        my_spaceship->commandSetTarget(targets.get());
                        return;
                    }
                }
            }

            if (key.hotkey == "AIM_MISSILE_LEFT")
            {
                missile_aim->setValue(missile_aim->getValue() - 5.0f);
                tube_controls->setMissileTargetAngle(missile_aim->getValue());
            }

            if (key.hotkey == "AIM_MISSILE_RIGHT")
            {
                missile_aim->setValue(missile_aim->getValue() + 5.0f);
                tube_controls->setMissileTargetAngle(missile_aim->getValue());
            }
        }

        if (key.category == "SINGLE_PILOT")
        {
            if (key.hotkey == "VIEW_FORWARD")
            {
                view_state = SPV_Forward;
            }
            else if (key.hotkey == "VIEW_LEFT")
            {
                view_state = SPV_Left;
            }
            else if (key.hotkey == "VIEW_RIGHT")
            {
                view_state = SPV_Right;
            }
            else if (key.hotkey == "VIEW_BACK")
            {
                view_state = SPV_Back;
            }
            else if (key.hotkey == "VIEW_TARGET")
            {
                view_state = SPV_Target;
            }
            else if (key.hotkey == "FIRST_PERSON")
            {
                first_person = !first_person;
            }
            else if (key.hotkey == "TOGGLE_TARGETING_MODE")
            {
                setTargetingMode(!targeting_mode);
            }
        }
    }
}

void SinglePilotScreen::setTargetingMode(bool new_mode)
{
    // Toggle target camera mode.
    targeting_mode = new_mode;
    targeting_mode_button->setValue(targeting_mode);
    view_state = targeting_mode ? SPV_Target : SPV_Forward;
}
