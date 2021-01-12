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
#include "gui/gui2_button.h"


SinglePilotScreen::SinglePilotScreen(GuiContainer* owner)
: GuiOverlay(owner, "SINGLEPILOT_SCREEN", colorConfig.background)
{
    // Render the radar shadow and background decorations.
    background_gradient = new GuiOverlay(this, "BACKGROUND_GRADIENT", sf::Color::White);
    background_gradient->setTextureCenter("gui/BackgroundGradientSingle");

    background_crosses = new GuiOverlay(this, "BACKGROUND_CROSSES", sf::Color::White);
    background_crosses->setTextureTiled("gui/BackgroundCrosses");

    // Render the alert level color overlay.
    (new AlertLevelOverlay(this));

    // 5U tactical radar with piloting features.
    radar = new GuiRadarView(this, "TACTICAL_RADAR", &targets);
    radar->setPosition(0, 0, ACenter)->setSize(GuiElement::GuiSizeMatchHeight, 650);
    radar->setRangeIndicatorStepSize(1000.0)->shortRange()->enableGhostDots()->enableWaypoints()->enableCallsigns()->enableHeadingIndicators()->setStyle(GuiRadarView::Circular);
    radar->setCallbacks(
        [this](sf::Vector2f position) {
            // On single tap/click...
            if (my_spaceship)
            {
                // If we're in targeting mode...
                if (this->targeting_mode)
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
                else
                {
                    // Otherwise, turn toward the click/tap location.
                    my_spaceship->commandTargetRotation(sf::vector2ToAngle(position - my_spaceship->getPosition()));
                }
            }
        },
        [this](sf::Vector2f position) {
            // On tap/click and hold, show heading hint and turn toward heading.
            if (my_spaceship && !this->targeting_mode)
            {
                float angle = sf::vector2ToAngle(position - my_spaceship->getPosition());
                heading_hint->setText(string(fmodf(angle + 90.f + 360.f, 360.f), 1))->setPosition(InputHandler::getMousePos() - sf::Vector2f(0, 50))->show();
                my_spaceship->commandTargetRotation(sf::vector2ToAngle(position - my_spaceship->getPosition()));
            }
        },
        [this](sf::Vector2f position) {
            // On release of tap/click and hold, remove heading hint and turn toward heading.
            if (my_spaceship && !this->targeting_mode)
            {
                my_spaceship->commandTargetRotation(sf::vector2ToAngle(position - my_spaceship->getPosition()));
            }
            heading_hint->hide();
        }
    );
    radar->setAutoRotating(PreferencesManager::get("single_pilot_radar_lock","0")=="1");

    // Heading hint shown on radar on navigational click/tap.
    heading_hint = new GuiLabel(this, "HEADING_HINT", "", 30);
    heading_hint->setAlignment(ACenter)->setSize(0, 0);

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
    missile_aim = new AimLock(this, "MISSILE_AIM", radar, -90, 360 - 90, 0, [this](float value){
        tube_controls->setMissileTargetAngle(value);
    });
    missile_aim->setPosition(0, 0, ACenter)->setSize(GuiElement::GuiSizeMatchHeight, 700);

    // Weapon tube controls.
    tube_controls = new GuiMissileTubeControls(this, "MISSILE_TUBES");
    tube_controls->setPosition(20, -20, ABottomLeft);
    radar->enableTargetProjections(tube_controls);

    // Engine layout in top left corner of left panel.
    GuiAutoLayout* engine_layout = new GuiAutoLayout(this, "ENGINE_LAYOUT", GuiAutoLayout::LayoutHorizontalLeftToRight);
    engine_layout->setPosition(20, 80, ATopLeft)->setSize(GuiElement::GuiSizeMax, 250);
    (new GuiImpulseControls(engine_layout, "IMPULSE"))->setSize(100, GuiElement::GuiSizeMax);
    warp_controls = (new GuiWarpControls(engine_layout, "WARP"))->setSize(100, GuiElement::GuiSizeMax);
    jump_controls = (new GuiJumpControls(engine_layout, "JUMP"))->setSize(100, GuiElement::GuiSizeMax);

    // Docking, comms, and shields buttons across top.
    (new GuiDockingButton(this, "DOCKING"))->setPosition(20, 20, ATopLeft)->setSize(250, 50);
    (new GuiOpenCommsButton(this, "OPEN_COMMS_BUTTON", tr("Open Comms"), &targets))->setPosition(270, 20, ATopLeft)->setSize(250, 50);
    (new GuiCommsOverlay(this))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    (new GuiShieldsEnableButton(this, "SHIELDS_ENABLE"))->setPosition(520, 20, ATopLeft)->setSize(250, 50);

    // Missile lock button near top right of left panel.
    lock_aim = new AimLockButton(this, "LOCK_AIM", tube_controls, missile_aim);
    lock_aim->setPosition(250, 70, ATopCenter)->setSize(130, 50);

    // Targeting mode toggle; target on radar tap when enabled, navigate when disabled.
    targeting_mode = false;
    targeting_mode_button = new GuiButton(this, "TARGETING_MODE", tr("mode", "Maneuver"), [this]()
    {
        targeting_mode = !targeting_mode;
        this->targeting_mode_button->setText(targeting_mode ? tr("mode", "Target") : tr("mode", "Maneuver"));
        this->targeting_mode_button->setIcon(targeting_mode ? "gui/icons/station-weapons" : "gui/icons/station-helm");
    });
    targeting_mode_button->setIcon("gui/icons/station-helm")->setPosition(770, 20, ATopLeft)->setSize(160, 50);

    (new GuiCustomShipFunctions(this, singlePilot, ""))->setPosition(-20, 120, ATopRight)->setSize(250, GuiElement::GuiSizeMax);
}

void SinglePilotScreen::onDraw(sf::RenderTarget& window)
{
    if (my_spaceship)
    {
        energy_display->setValue(string(int(my_spaceship->energy_level)));
        heading_display->setValue(string(fmodf(my_spaceship->getRotation() + 360.0 + 360.0 - 270.0, 360.0), 1));
        float velocity = sf::length(my_spaceship->getVelocity()) / 1000 * 60;
        velocity_display->setValue(string(velocity, 1) + DISTANCE_UNIT_1K + "/min");

        warp_controls->setVisible(my_spaceship->has_warp_drive);
        jump_controls->setVisible(my_spaceship->has_jump_drive);

        string shields_value = string(my_spaceship->getShieldPercentage(0)) + "%";
        if (my_spaceship->hasSystem(SYS_RearShield))
        {
            shields_value += " " + string(my_spaceship->getShieldPercentage(1)) + "%";
        }
        shields_display->setValue(shields_value);
        if (my_spaceship->hasSystem(SYS_FrontShield) || my_spaceship->hasSystem(SYS_RearShield))
        {
            shields_display->show();
        } else {
            shields_display->hide();
        }

        missile_aim->setVisible(tube_controls->getManualAim());

        targets.set(my_spaceship->getTarget());
    }
    GuiOverlay::onDraw(window);
}

bool SinglePilotScreen::onJoystickAxis(const AxisAction& axisAction)
{
    if(my_spaceship)
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
                my_spaceship->commandTargetRotation(my_spaceship->getRotation() - 5.0f);
            else if (key.hotkey == "TURN_RIGHT")
                my_spaceship->commandTargetRotation(my_spaceship->getRotation() + 5.0f);
        }

        if (key.category == "WEAPONS")
        {
            if (key.hotkey == "NEXT_ENEMY_TARGET")
            {
                bool current_found = false;
                foreach(SpaceObject, obj, space_object_list)
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
                foreach(SpaceObject, obj, space_object_list)
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
                foreach(SpaceObject, obj, space_object_list)
                {
                    if (obj == targets.get())
                    {
                        current_found = true;
                        continue;
                    }
                    if (obj == my_spaceship)
                        continue;
                    if (current_found && sf::length(obj->getPosition() - my_spaceship->getPosition()) < my_spaceship->getShortRangeRadarRange() && obj->canBeTargetedBy(my_spaceship))
                    {
                        targets.set(obj);
                        my_spaceship->commandSetTarget(targets.get());
                        return;
                    }
                }
                foreach(SpaceObject, obj, space_object_list)
                {
                    if (obj == targets.get() || obj == my_spaceship)
                        continue;
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

        if (key.category == "TACTICAL")
        {
            if (key.hotkey == "TOGGLE_TARGETING_MODE")
            {
                targeting_mode = !targeting_mode;
                this->targeting_mode_button->setText(targeting_mode ? tr("mode", "Target") : tr("mode", "Maneuver"));
                this->targeting_mode_button->setIcon(targeting_mode ? "gui/icons/station-weapons" : "gui/icons/station-helm");
            }
            if (key.hotkey == "ENABLE_TARGETING_MODE")
            {
                targeting_mode = true;
                this->targeting_mode_button->setText(tr("mode", "Target"));
                this->targeting_mode_button->setIcon("gui/icons/station-weapons");
            }
            if (key.hotkey == "DISABLE_TARGETING_MODE")
            {
                targeting_mode = false;
                this->targeting_mode_button->setText(tr("mode", "Maneuver"));
                this->targeting_mode_button->setIcon("gui/icons/station-helm");
            }
        }
    }
}
