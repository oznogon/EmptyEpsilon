#include "playerInfo.h"
#include "gameGlobalInfo.h"
#include "cinematicViewScreen.h"
#include "epsilonServer.h"
#include "main.h"
#include "preferenceManager.h"
#include "multiplayer_client.h"
#include "ecs/query.h"
#include "i18n.h"
#include "random.h"
#include "components/collision.h"
#include "components/target.h"
#include "components/player.h"
#include "components/name.h"

#include "screenComponents/indicatorOverlays.h"
#include "screenComponents/scrollingBanner.h"
#include "screenComponents/helpOverlay.h"
#include "gui/gui2_button.h"
#include "gui/gui2_element.h"
#include "gui/gui2_panel.h"
#include "gui/gui2_selector.h"
#include "gui/gui2_togglebutton.h"
#include "gui/mouseRenderer.h"

CinematicViewScreen::CinematicViewScreen(RenderLayer* render_layer)
: GuiCanvas(render_layer)
{
    // Capture mouse_renderer so we can hide it in mouselook.
    mouse_renderer = engine->getObject("mouseRenderer");
    invert_mouselook_y = (PreferencesManager::get("camera_mouse_inverted", "0") == "1");
    random_flyby_angle = (PreferencesManager::get("camera_flyby_randomized", "0") == "1");

    // Create a full-screen viewport.
    viewport = new GuiViewport3D(this, "VIEWPORT");
    viewport
        ->showCallsigns()
        ->setPosition(0.0f, 0.0f)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Lock onto player ship to start.
    for (auto [entity, pc] : sp::ecs::Query<PlayerControl>())
    {
        target = entity;
        if (auto target_transform = target.getComponent<sp::Transform>()) setTargetTransform(target_transform);
        break;
    }

    // Initialize main-defined camera.
    camera_yaw = -90.0f;
    camera_pitch = 45.0f;
    camera_position = {0.0f, 0.0f, 200.0f};
    camera_position += 0.1f;
    // Validate and apply camera control sensitivity pref.
    const float pref_sens = PreferencesManager::get("camera_mouse_sensitivity", "0.15").toFloat();
    if (pref_sens > 0.0f) camera_sensitivity = pref_sens;
    else LOG(Warning, "camera_mouse_sensitivity value invalid:", PreferencesManager::get("camera_mouse_sensitivity"));

    // Control GUI.
    camera_controls = new GuiElement(this, "CAMERA_CONTROLS");
    camera_controls->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Let the screen operator select a player ship to lock the camera onto.
    camera_lock_selector = new GuiSelector(camera_controls, "CAMERA_LOCK_SELECTOR", [this](int index, string value) {
        if (auto ship = sp::ecs::Entity::fromString(value)) target = ship;
    });
    camera_lock_selector
        ->setSelectionIndex(0)
        ->setPosition(20.0f, -140.0f, sp::Alignment::BottomLeft)
        ->setSize(300.0f, 50.0f);

    // Auto-zoom toggle (works across all camera modes)
    camera_auto_zoom_toggle = new GuiToggleButton(camera_controls, "CAMERA_AUTO_ZOOM_TOGGLE", tr("button", "Auto-zoom camera"),
        [this](bool value) {
            // Functions check the button's state
        }
    );
    camera_auto_zoom_toggle
        ->setValue(false)
        ->setPosition(320.0f, -80.0f, sp::Alignment::BottomLeft)
        ->setSize(300.0f, 50.0f);

    // Mode-context option trigger
    camera_reset = new GuiToggleButton(camera_controls, "CAMERA_RESET", tr("button", "Reset camera"),
        [this](bool value)
        {
            switch (camera_mode)
            {
                case CAMERA_MODE_FLYBY:
                    // Reset flyby camera
                    flyby_fov_modifier = viewport->modifyFoV(0.0f);
                    flyby_camera_pos = {0.0f, 0.0f};  // Force reposition on next update
                    camera_reset->setValue(false);
                    break;
                case CAMERA_MODE_ORBITAL:
                    // Toggle auto-rotate orbital camera
                    orbit_auto_rotate = value;
                    if (orbit_auto_rotate)
                    {
                        // Initialize auto-orbit with first random target
                        cinematic_cycle_timer = 0.0f;
                        orbit_target_yaw = random(0.0f, 360.0f);
                        orbit_target_pitch = random(-10.0f, 60.0f);
                        orbit_target_distance = random(orbit_distance_min, orbit_distance_max);
                    }
                    break;
                case CAMERA_MODE_CHASE:
                    // Rotate camera
                    chase_direction = static_cast<Angle>((static_cast<int>(chase_direction) + 1) % 4);
                    camera_reset->setValue(false);
                    break;
                case CAMERA_MODE_ISOMETRIC:
                    // Rotate camera
                    isometric_direction = static_cast<IsometricAngle>((static_cast<int>(isometric_direction) + 1) % 4);
                    camera_reset->setValue(false);
                    break;
                case CAMERA_MODE_TOPDOWN:
                    // Reset top-down camera to center on ship
                    topdown_offset = {0.0f, 0.0f};
                    topdown_zoom = 1000.0f;
                    camera_reset->setValue(false);
                    break;
                default: break;
            }
        }
    );
    camera_reset
        ->setValue(false)
        ->setPosition(320.0f, -140.0f, sp::Alignment::BottomLeft)
        ->setSize(300.0f, 50.0f);

    // Camera mode selector (only visible when camera is locked)
    camera_mode_selector = new GuiSelector(camera_controls, "CAMERA_MODE_SELECTOR",
        [this](int index, string value)
        {
            camera_mode = static_cast<CameraMode>(index);
            switch (camera_mode)
            {
                case CAMERA_MODE_FLYBY:
                    camera_reset
                        ->setValue(false)
                        ->setText(tr("button", "Reset camera"));
                    break;
                case CAMERA_MODE_ORBITAL:
                    camera_reset
                        ->setValue(orbit_auto_rotate)
                        ->setText(tr("button", "Auto-rotate orbit"));
                    break;
                case CAMERA_MODE_CHASE:
                    camera_reset
                        ->setValue(false)
                        ->setText(tr("button", "Rotate camera"));
                    chase_direction = static_cast<Angle>((static_cast<int>(chase_direction) + 1) % 4);
                    break;
                case CAMERA_MODE_ISOMETRIC:
                    camera_reset
                        ->setValue(false)
                        ->setText(tr("button", "Rotate camera"));
                    isometric_direction = static_cast<IsometricAngle>((static_cast<int>(isometric_direction) + 1) % 4);
                    // Disable mouselook for orthographic modes
                    setMouselook(false);
                    break;
                case CAMERA_MODE_TOPDOWN:
                    camera_reset
                        ->setValue(false)
                        ->setText(tr("button", "Reset camera"));
                    topdown_offset = {0.0f, 0.0f};
                    topdown_zoom = 1000.0f;
                    // Disable mouselook for orthographic modes
                    setMouselook(false);
                    break;
            }
        }
    );
    camera_mode_selector->addEntry(tr("button", "Fly-by camera"), "0");
    camera_mode_selector->addEntry(tr("button", "Orbital camera"), "1");
    camera_mode_selector->addEntry(tr("button", "Chase camera"), "2");
    camera_mode_selector->addEntry(tr("button", "Isometric camera"), "3");
    camera_mode_selector->addEntry(tr("button", "Top-down camera"), "4");
    camera_mode_selector
        ->setSelectionIndex(0)
        ->setPosition(20.0f, -80.0f, sp::Alignment::BottomLeft)
        ->setSize(300.0f, 50.0f);

    // Toggle whether to lock the camera onto a ship.
    camera_lock_toggle = new GuiToggleButton(camera_controls, "CAMERA_LOCK_TOGGLE", tr("button", "Lock camera on ship"), [](bool value) {});
    camera_lock_toggle
        ->setValue(true)
        ->setPosition(20.0f, -20.0f, sp::Alignment::BottomLeft)
        ->setSize(300.0f, 50.0f);

    camera_lock_tot_toggle = new GuiToggleButton(camera_controls, "CAMERA_LOCK_TOT_TOGGLE", tr("button", "Point at ship's target"), [this](bool value) {});
    camera_lock_tot_toggle
        ->setValue(false)
        ->setPosition(320.0f, -20.0f, sp::Alignment::BottomLeft)
        ->setSize(300.0f, 50.0f);

    camera_lock_cycle_toggle = new GuiToggleButton(camera_controls, "CAMERA_LOCK_CYCLE_TOGGLE", tr("button", "Cycle through ships"), [this](bool value) {});
    camera_lock_cycle_toggle
        ->setValue(false)
        ->setPosition(620.0f, -20.0f, sp::Alignment::BottomLeft)
        ->setSize(300.0f, 50.0f);

    // Toggle callsigns.
    callsigns_toggle = new GuiButton(camera_controls, "CAMERA_CALLSIGNS_TOGGLE", tr("button", "Toggle callsigns"),
        [this]() {
            viewport->toggleCallsigns();
        });
    callsigns_toggle->setPosition(20, -200, sp::Alignment::BottomLeft)->setSize(300, 50);

    // Toggle mouselook.
    mouselook_toggle = new GuiToggleButton(camera_controls, "CAMERA_MOUSELOOK_TOGGLE", tr("button", "Mouselook"),
        [this](bool value)
        {
            setMouselook(value);
            camera_controls->setVisible(!camera_controls->isVisible());
        }
    );
    mouselook_toggle->setValue(false)->setPosition(-20, -80, sp::Alignment::BottomRight)->setSize(200, 50)->disable();
    ui_toggle = new GuiButton(camera_controls, "UI_TOGGLE", tr("button", "Toggle controls"),
        [this]()
        {
            camera_controls->setVisible(!camera_controls->isVisible());
        }
    );
    ui_toggle->setPosition(-20, -20, sp::Alignment::BottomRight)->setSize(200, 50);

    new GuiIndicatorOverlays(this);

    (new GuiScrollingBanner(this))->setPosition(0, 0)->setSize(GuiElement::GuiSizeMax, 100);

    keyboard_help = new GuiHelpOverlay(viewport, tr("hotkey_F1", "Keyboard Shortcuts"));
    string keyboard_cinematic = "";

    for (auto binding : sp::io::Keybinding::listAllByCategory("Cinematic View"))
        keyboard_cinematic += tr("hotkey_F1", "{label}: {button}\n").format({{"label", binding->getLabel()}, {"button", binding->getHumanReadableKeyName(0)}});

    keyboard_help->setText(keyboard_cinematic);
    keyboard_help->moveToFront();
}

CinematicViewScreen::~CinematicViewScreen()
{
    SDL_SetRelativeMouseMode(SDL_FALSE);
}

void CinematicViewScreen::update(float delta)
{
    // If this is a client and it is disconnected, exit.
    if (game_client && game_client->getStatus() == GameClient::Disconnected)
    {
        destroy();
        disconnectFromServer();
        returnToMainMenu(getRenderLayer());
        return;
    }

    // Toggle keyboard help.
    if (keys.help.getDown())
        keyboard_help->frame->setVisible(!keyboard_help->frame->isVisible());

    if (keys.cinematic.toggle_ui.getDown())
        camera_controls->setVisible(!camera_controls->isVisible());

    if (keys.cinematic.toggle_callsigns.getDown())
        viewport->toggleCallsigns();

    if (keys.cinematic.lock_camera.getDown())
        camera_lock_toggle->setValue(!camera_lock_toggle->getValue());

    if (keys.cinematic.cycle_camera.getDown())
        camera_lock_cycle_toggle->setValue(!camera_lock_cycle_toggle->getValue());

    if (keys.cinematic.previous_player_ship.getDown())
    {
        camera_lock_selector->setSelectionIndex(camera_lock_selector->getSelectionIndex() - 1);
        if (camera_lock_selector->getSelectionIndex() < 0)
            camera_lock_selector->setSelectionIndex(camera_lock_selector->entryCount() - 1);
        target = sp::ecs::Entity::fromString(camera_lock_selector->getEntryValue(camera_lock_selector->getSelectionIndex()));
    }

    if (keys.cinematic.next_player_ship.getDown())
    {
        camera_lock_selector->setSelectionIndex(camera_lock_selector->getSelectionIndex() + 1);
        if (camera_lock_selector->getSelectionIndex() >= camera_lock_selector->entryCount())
            camera_lock_selector->setSelectionIndex(0);
        target = sp::ecs::Entity::fromString(camera_lock_selector->getEntryValue(camera_lock_selector->getSelectionIndex()));
    }
    // TODO: X resets the camera to a default relative position and heading.
    if (keys.escape.getDown())
    {
        destroy();
        returnToShipSelection(getRenderLayer());
    }

    if (keys.pause.getDown())
        if (game_server && !gameGlobalInfo->getVictoryFaction()) engine->setGameSpeed(engine->getGameSpeed() > 0.0f ? 0.0f : 1.0f);

    bool is_camera_moving = false;

    // Handle mouse wheel input (same as W/S keys for zoom/distance)
    float mouse_wheel_delta = keys.zoom_in.getValue() - keys.zoom_out.getValue();

    // When camera is locked, WASD/RF/arrows control based on camera mode
    if (camera_lock_toggle->getValue() && target && !mouselook)
    {
        switch (camera_mode)
        {
        case CAMERA_MODE_FLYBY:
            if (keys.cinematic.move_forward.get() || keys.cinematic.tilt_up.get() || mouse_wheel_delta > 0.0f)
            {
                is_camera_moving = true;
                flyby_fov_modifier = viewport->modifyFoV(flyby_fov_modifier - delta * camera_zoom_speed);
            }
            if (keys.cinematic.move_backward.get() || keys.cinematic.tilt_down.get() || mouse_wheel_delta < 0.0f)
            {
                is_camera_moving = true;
                flyby_fov_modifier = viewport->modifyFoV(flyby_fov_modifier + delta * camera_zoom_speed);
            }

            // Up/down
            if (keys.cinematic.move_up.get())
            {
                is_camera_moving = true;
                flyby_height = std::min(flyby_height_max, flyby_height + camera_translation_speed);
            }
            if (keys.cinematic.move_down.get())
            {
                is_camera_moving = true;
                flyby_height = std::max(flyby_height_min, flyby_height - camera_translation_speed);
            }
            break;

        // Orbital camera fixed on target ship
        case CAMERA_MODE_ORBITAL:
            // Rotate left/right
            if (keys.cinematic.strafe_left.get() || keys.cinematic.rotate_left.get())
            {
                is_camera_moving = true;
                orbit_yaw += camera_rotation_speed;
            }
            if (keys.cinematic.strafe_right.get() || keys.cinematic.rotate_right.get())
            {
                is_camera_moving = true;
                orbit_yaw -= camera_rotation_speed;
            }

            // Over/under
            if (keys.cinematic.move_up.get())
            {
                is_camera_moving = true;
                orbit_pitch = std::min(89.0f, orbit_pitch + camera_rotation_speed);
            }
            if (keys.cinematic.move_down.get())
            {
                is_camera_moving = true;
                orbit_pitch = std::max(-89.0f, orbit_pitch - camera_rotation_speed);
            }

            // Closer/farther
            if (keys.cinematic.move_forward.get() || keys.cinematic.tilt_up.get() || mouse_wheel_delta > 0.0f)
            {
                is_camera_moving = true;
                orbit_distance = std::max(getScaledCameraDistance(orbit_distance_min), orbit_distance - camera_translation_speed);
            }
            if (keys.cinematic.move_backward.get() || keys.cinematic.tilt_down.get() || mouse_wheel_delta < 0.0f)
            {
                is_camera_moving = true;
                orbit_distance = std::min(getScaledCameraDistance(orbit_distance_max), orbit_distance + camera_translation_speed);
            }
            break;

        // Chase mode, similar to main screen view
        case CAMERA_MODE_CHASE:
            // Closer/farther
            if (keys.cinematic.move_forward.get() || keys.cinematic.tilt_up.get() || mouse_wheel_delta > 0.0f)
            {
                is_camera_moving = true;
                chase_distance = std::max(getScaledCameraDistance(chase_distance_min), chase_distance - camera_translation_speed);
            }
            if (keys.cinematic.move_backward.get() || keys.cinematic.tilt_down.get() || mouse_wheel_delta < 0.0f)
            {
                is_camera_moving = true;
                chase_distance = std::min(getScaledCameraDistance(chase_distance_max), chase_distance + camera_translation_speed);
            }

            // Orbit horizontally at snapped 90-degree increments
            if (keys.cinematic.strafe_left.getDown() || keys.cinematic.rotate_left.getDown())
                chase_direction = static_cast<Angle>((static_cast<int>(chase_direction) + 3) % 4);
            if (keys.cinematic.strafe_right.getDown() || keys.cinematic.rotate_right.getDown())
                chase_direction = static_cast<Angle>((static_cast<int>(chase_direction) + 1) % 4);

            // Up/down
            if (keys.cinematic.move_up.get())
            {
                is_camera_moving = true;
                chase_height = std::min(chase_height_max, chase_height + camera_translation_speed);
            }
            if (keys.cinematic.move_down.get())
            {
                is_camera_moving = true;
                chase_height = std::max(chase_height_min, chase_height - camera_translation_speed);
            }
            break;

        // Isometric
        case CAMERA_MODE_ISOMETRIC:
            // Closer/farther
            if (keys.cinematic.move_forward.get() || keys.cinematic.tilt_up.get() || mouse_wheel_delta > 0.0f)
            {
                is_camera_moving = true;
                isometric_distance = std::max(isometric_distance_min, isometric_distance - camera_translation_speed);
            }
            if (keys.cinematic.move_backward.get() || keys.cinematic.tilt_down.get() || mouse_wheel_delta < 0.0f)
            {
                is_camera_moving = true;
                isometric_distance = std::min(isometric_distance_max, isometric_distance + camera_translation_speed);
            }

            // Orbit horizontally at 90-degree increments
            if (keys.cinematic.strafe_left.getDown() || keys.cinematic.rotate_left.getDown())
                isometric_direction = static_cast<IsometricAngle>((static_cast<int>(isometric_direction) + 3) % 4);
            if (keys.cinematic.strafe_right.getDown() || keys.cinematic.rotate_right.getDown())
                isometric_direction = static_cast<IsometricAngle>((static_cast<int>(isometric_direction) + 1) % 4);
            break;

        case CAMERA_MODE_TOPDOWN:
            // Pan camera if unlocked
            /*
            if (keys.cinematic.move_forward.get() || keys.cinematic.tilt_up.get())
            {
                is_camera_moving = true;
                topdown_offset.y += camera_translation_speed;
            }
            if (keys.cinematic.move_backward.get() || keys.cinematic.tilt_down.get())
            {
                is_camera_moving = true;
                topdown_offset.y -= camera_translation_speed;
            }
            if (keys.cinematic.strafe_left.get() || keys.cinematic.rotate_left.get())
            {
                is_camera_moving = true;
                topdown_offset.x -= camera_translation_speed;
            }
            if (keys.cinematic.strafe_right.get() || keys.cinematic.rotate_right.get())
            {
                is_camera_moving = true;
                topdown_offset.x += camera_translation_speed;
            }
            */

            // R/F: Zoom out/in
            if (keys.cinematic.move_up.get() || mouse_wheel_delta < 0.0f)
            {
                is_camera_moving = true;
                topdown_zoom = std::min(topdown_zoom_max, topdown_zoom + camera_translation_speed);
            }
            if (keys.cinematic.move_down.get() || mouse_wheel_delta > 0.0f)
            {
                is_camera_moving = true;
                topdown_zoom = std::max(topdown_zoom_min, topdown_zoom - camera_translation_speed);
            }
            break;
        }
    }
    else
    {
        // Free camera
        if (keys.cinematic.move_forward.get())
        {
            is_camera_moving = true;
            glm::vec2 xy_vector = vec2FromAngle(camera_yaw) * camera_translation_speed;
            camera_position.x += xy_vector.x;
            camera_position.y += xy_vector.y;
        }

        if (keys.cinematic.move_backward.get())
        {
            is_camera_moving = true;
            glm::vec2 xy_vector = vec2FromAngle(camera_yaw) * camera_translation_speed;
            camera_position.x -= xy_vector.x;
            camera_position.y -= xy_vector.y;
        }

        if (keys.cinematic.strafe_left.get())
        {
            is_camera_moving = true;
            glm::vec2 xy_vector = vec2FromAngle(camera_yaw) * camera_translation_speed;
            camera_position.x += xy_vector.y;
            camera_position.y -= xy_vector.x;
        }

        if (keys.cinematic.strafe_right.get())
        {
            is_camera_moving = true;
            glm::vec2 xy_vector = vec2FromAngle(camera_yaw) * camera_translation_speed;
            camera_position.x -= xy_vector.y;
            camera_position.y += xy_vector.x;
        }

        if (keys.cinematic.move_up.get())
        {
            is_camera_moving = true;
            camera_position.z += camera_translation_speed;
        }

        if (keys.cinematic.move_down.get())
        {
            is_camera_moving = true;
            camera_position.z -= camera_translation_speed;
        }

        if (keys.cinematic.rotate_left.get())
        {
            is_camera_moving = true;
            camera_yaw -= camera_rotation_speed;
        }

        if (keys.cinematic.rotate_right.get())
        {
            is_camera_moving = true;
            camera_yaw += camera_rotation_speed;
        }

        if (keys.cinematic.tilt_up.get())
        {
            is_camera_moving = true;
            camera_pitch = std::max(-89.9f, camera_pitch - camera_rotation_speed);
        }

        if (keys.cinematic.tilt_down.get())
        {
            is_camera_moving = true;
            camera_pitch = std::min(89.9f, camera_pitch + camera_rotation_speed);
        }
    }

    if (keys.cinematic.move_faster.get())
    {
        if (camera_translation_speed < camera_translation_max)
            camera_translation_speed = std::min(camera_translation_max, camera_translation_speed + delta * camera_translation_max);
        if (camera_rotation_speed < camera_rotation_max)
            camera_rotation_speed = std::min(camera_rotation_max, camera_rotation_speed + delta * camera_rotation_max);
        if (camera_zoom_speed < camera_zoom_max)
            camera_zoom_speed = std::min(camera_zoom_max, camera_zoom_speed + delta * camera_zoom_max);
    }
    else if (is_camera_moving)
    {
        if (camera_translation_speed > camera_translation_min)
            camera_translation_speed = std::max(camera_translation_min, camera_translation_speed - delta * camera_translation_max * 2.0f);
        if (camera_rotation_speed > camera_rotation_min)
            camera_rotation_speed = std::max(camera_rotation_min, camera_rotation_speed - delta * camera_rotation_max * 2.0f);
        if (camera_zoom_speed > camera_zoom_min)
            camera_zoom_speed = std::max(camera_zoom_min, camera_zoom_speed - delta * camera_zoom_max * 2.0f);
    }
    else
    {
        camera_translation_speed = camera_translation_min;
        camera_rotation_speed = camera_rotation_min;
        camera_zoom_speed = camera_zoom_min;
    }

    if (keys.cinematic.toggle_mouselook.getDown())
        setMouselook(!mouselook);

    // Hide the mouse renderer while in mouselook.
    if (mouse_renderer) mouse_renderer->visible = !mouselook;

    // Add and remove entries from the player ship list.
    // TODO: Allow any ship or station to be the camera target.
    for (auto [entity, pc] : sp::ecs::Query<PlayerControl>())
    {
        if (camera_lock_selector->indexByValue(entity.toString()) == -1)
        {
            string label;
            if (auto tn = entity.getComponent<TypeName>())
                label = tn->type_name;
            if (auto cs = entity.getComponent<CallSign>())
                label += " " + cs->callsign;
            camera_lock_selector->addEntry(label, entity.toString());
        }
    }
    // Remove invalid entries by iterating backwards to avoid index invalidation
    for (int n = camera_lock_selector->entryCount() - 1; n >= 0; n--)
    {
        if (!sp::ecs::Entity::fromString(camera_lock_selector->getEntryValue(n)))
            camera_lock_selector->removeEntry(n);
    }

    // Update shared cinematic cycle timer
    cinematic_cycle_timer += delta;
    if (cinematic_cycle_timer >= cinematic_cycle_period)
    {
        cinematic_cycle_timer = 0.0f;

        // If cycle is enabled, switch target
        if (camera_lock_cycle_toggle->getValue())
        {
            camera_lock_selector->setSelectionIndex(camera_lock_selector->getSelectionIndex() + 1);
            if (camera_lock_selector->getSelectionIndex() >= camera_lock_selector->entryCount())
                camera_lock_selector->setSelectionIndex(0);
            target = sp::ecs::Entity::fromString(camera_lock_selector->getEntryValue(camera_lock_selector->getSelectionIndex()));
        }
    }

    // Plot headings from the camera to the locked player ship.
    // Set camera_yaw and camera_pitch to those values.

    // If lock is enabled and a ship is selected (but not in mouselook mode)...
    if (camera_lock_toggle->getValue() && target && !mouselook)
    {
        setMouselook(false);
        mouselook_toggle->setValue(false)->disable();

        // Set target position to target transform if available.
        // If the target lacks a transform, clear the target and disable target
        // lock controls.
        auto target_transform = target.getComponent<sp::Transform>();
        if (!target_transform)
        {
            camera_mode_selector->disable();
            camera_auto_zoom_toggle->setValue(false)->disable();
            camera_reset->disable();
            camera_lock_tot_toggle->setValue(false)->disable();
            camera_lock_cycle_toggle->setValue(false)->disable();
            if (camera_controls->isVisible()) mouselook_toggle->enable();
            target = sp::ecs::Entity();
            return;
        }

        // Enable target lock controls.
        camera_mode_selector->enable();
        camera_auto_zoom_toggle->enable();
        camera_reset->enable();
        camera_lock_tot_toggle->enable();
        camera_lock_cycle_toggle->enable();

        setTargetTransform(target_transform);

        // Check if our selected ship has a weapons target.
        target_of_target = target.getComponent<Target>() ? target.getComponent<Target>()->entity : sp::ecs::Entity();
        auto target_of_target_transform = target_of_target.getComponent<sp::Transform>();

        // Don't track ToTs > 10U away.
        if (target_of_target && target_of_target_transform && glm::length(target_of_target_transform->getPosition() - target_position_2D) > 10000.0f)
            target_of_target_transform = nullptr;

        updateCamera(target_transform, target_of_target_transform, delta);
    }
    else
    {
        // Disable target lock controls and enable the mouselook button.
        camera_mode_selector->disable();
        camera_auto_zoom_toggle->setValue(false)->disable();
        camera_reset->disable();
        camera_lock_tot_toggle->setValue(false)->disable();
        camera_lock_cycle_toggle->setValue(false)->disable();
        if (camera_controls->isVisible()) mouselook_toggle->enable();
    }
}

void CinematicViewScreen::setMouselook(bool value)
{
    // Allow toggling of mouse capture and mouselook, but only if camera
    // lock is disabled or no camera lock target exists, and not in
    // orthographic camera modes (isometric, top-down).
    if (value && (!camera_lock_toggle->getValue() || !target) &&
        camera_mode != CAMERA_MODE_ISOMETRIC && camera_mode != CAMERA_MODE_TOPDOWN)
    {
        mouselook = true;
        mouselook_toggle->setValue(true);
        SDL_SetRelativeMouseMode(SDL_GetRelativeMouseMode() ? SDL_FALSE : SDL_TRUE);
    }
    else
    {
        mouselook = false;
        mouselook_toggle->setValue(false);
        SDL_SetRelativeMouseMode(SDL_FALSE);
    }
}

bool CinematicViewScreen::onPointerMove(glm::vec2 position, sp::io::Pointer::ID id)
{
    // Handle mouselook if enabled and the camera lock is off.
    // Mouselook enables SDL relative mouse mode, which reports movement
    // deltas instead of positions. This makes the position variable oddly
    // named for the moment.
    if (mouselook && !camera_lock_toggle->getValue())
    {
        // ORBIT MODE: Mouse rotates camera around target
        if (camera_lock_toggle->getValue() && target)
        {
            // Mouse X (horizontal) rotates camera left/right around target
            orbit_yaw += position.x * camera_sensitivity;

            // Mouse Y (vertical) rotates camera over/under target
            if (invert_mouselook_y)
                orbit_pitch += position.y * camera_sensitivity;
            else
                orbit_pitch -= position.y * camera_sensitivity;

            // Clamp pitch to prevent flipping
            orbit_pitch = std::clamp(orbit_pitch, -89.0f, 89.0f);
        }
        // FREE CAMERA: Mouse controls yaw and pitch
        else
        {
            // Yaw (mouse x, horizontal rotation normalized)
            camera_yaw += position.x * camera_sensitivity;
            camera_yaw = std::fmod(camera_yaw, 360.0f);
            if (camera_yaw < 0.0f) camera_yaw += 360.0f;

            // Pitch (mouse y, vertical rotation)
            // Clamp pitch to 90 degrees up/down prevent flipping upside down.
            if (invert_mouselook_y)
                camera_pitch += position.y * camera_sensitivity;
            else
                camera_pitch -= position.y * camera_sensitivity;
            camera_pitch = std::clamp(camera_pitch, -89.9f, 89.9f);
        }
    }

    return false;
}

void CinematicViewScreen::onPointerUp(glm::vec2 position, sp::io::Pointer::ID id)
{
    // Disable mouselook and toggle UI on click.
    if (mouselook)
        setMouselook(false);
    else if (!camera_controls->isVisible())
        camera_controls->setVisible(!camera_controls->isVisible());
    GuiCanvas::onPointerUp(position, id);
}

void CinematicViewScreen::setTargetTransform(sp::Transform* transform)
{
    // Get the target transform's current position and heading.
    target_rotation = transform->getRotation();
    target_position_2D = transform->getPosition();

    // Copy the selected transform's position into a vec3 for camera angle
    // calculations.
    target_position_3D = {target_position_2D.x, target_position_2D.y, 0.0f};

    // Copy the camera position into a vec2 for camera angle
    // calculations.
    camera_position_2D = {camera_position.x, camera_position.y};

    // Calculate the distance from the camera to the selected transform.
    diff_2D = target_position_2D - camera_position_2D;
    diff_3D = target_position_3D - camera_position;

    distance_2D = glm::length(diff_2D);
    distance_3D = glm::length(diff_3D);

    // Always keep the camera less than 1U from the selected transform.
    // If it has a physics collider, factor that into the distance.
    float max_dimension = 0.0f;
    max_camera_distance = 1000.0f;

    if (auto physics = target.getComponent<sp::Physics>())
    {
        max_dimension = std::max(physics->getSize().x, physics->getSize().y);
        max_camera_distance = 1000.0f + max_dimension + glm::length(physics->getVelocity());
    }

    min_camera_distance = std::max(300.0f, max_dimension * 2.0f);
}

float CinematicViewScreen::getScaledCameraDistance(float base_distance) const
{
    // Scale camera distances based on ship size (defaults tuned for radius 200)
    // Uses square root scaling to provide more balanced values across ship sizes
    float ship_radius = 200.0f;
    if (target)
    {
        if (auto physics = target.getComponent<sp::Physics>())
            ship_radius = std::max(physics->getSize().x, physics->getSize().y) / 2.0f;
    }

    float size_scale = sqrtf(ship_radius / 200.0f);
    return base_distance * size_scale;
}

void CinematicViewScreen::updateCamera(sp::Transform* main_transform, sp::Transform* tot_transform, float delta)
{
    // Route to appropriate camera mode
    switch (camera_mode)
    {
    case CAMERA_MODE_FLYBY:
        updateFlybyCamera(main_transform, tot_transform, delta, OptionState::None);
        break;
    case CAMERA_MODE_ORBITAL:
        updateOrbitCamera(main_transform, tot_transform, delta);
        break;
    case CAMERA_MODE_CHASE:
        updateChaseCamera(main_transform, tot_transform, delta);
        break;
    case CAMERA_MODE_ISOMETRIC:
        updateIsometricCamera(main_transform, tot_transform, delta);
        break;
    case CAMERA_MODE_TOPDOWN:
        updateTopdownCamera(main_transform, tot_transform, delta);
        break;
    }
}

void CinematicViewScreen::updateOrbitCamera(sp::Transform* main_transform, sp::Transform* tot_transform, float delta)
{
    // Orbit camera: Position using spherical coordinates.
    viewport->setProjectionType(GuiViewport3D::ProjectionType::Perspective);

    // Clamp orbit_distance to valid scaled range for current ship size
    float scaled_min = getScaledCameraDistance(orbit_distance_min);
    float scaled_max = getScaledCameraDistance(orbit_distance_max);
    orbit_distance = std::clamp(orbit_distance, scaled_min, scaled_max);

    // Auto-rotate mode: smoothly transition camera to random positions
    if (orbit_auto_rotate && cinematic_cycle_timer == 0.0f)
    {
        // Randomize on cycle (cycle timer reset happens in update())
        orbit_target_yaw = random(0.0f, 360.0f);
        orbit_target_pitch = random(-10.0f, 60.0f);
        orbit_target_distance = random(scaled_min, scaled_max);
    }

    // Smoothly interpolate toward target values.
    if (orbit_auto_rotate)
    {
        float blend_factor = delta * 0.1f;

        // Handle yaw wrapping.
        float yaw_diff = orbit_target_yaw - orbit_yaw;
        if (yaw_diff > 180.0f) yaw_diff -= 360.0f; 
        else if (yaw_diff < -180.0f) yaw_diff += 360.0f;
        orbit_yaw += yaw_diff * blend_factor;
        orbit_yaw = fmod(orbit_yaw + 360.0f, 360.0f);

        orbit_pitch += (orbit_target_pitch - orbit_pitch) * blend_factor;
        orbit_distance += (orbit_target_distance - orbit_distance) * blend_factor;
    }

    // Determine orbit center based on ToT mode
    bool is_orbiting_tot = updateToTState(tot_transform, delta) && (isToTInRange(tot_transform) || tot_linger_timer > 0.0f);
    if (is_orbiting_tot)
    {
        // Orbit around the midpoint between ship and its target
        orbit_center = getMedianPoint();

        // Auto-zoom: adjust orbit distance to keep both ships visible
        if (camera_auto_zoom_toggle->getValue())
        {
            float ship_to_tot_distance = getToTDistance();
            // Calculate required distance to fit both ships with some padding (1.5x)
            float required_distance = (ship_to_tot_distance * 0.75f) / glm::tan(glm::radians(viewport->getFoV() * 0.5f));
            orbit_target_distance = std::clamp(required_distance, scaled_min, scaled_max);

            // Smoothly interpolate to target distance
            if (!orbit_auto_rotate)
                orbit_distance += (orbit_target_distance - orbit_distance) * delta * 0.5f;
        }
    }
    else
    {
        // Orbit around the locked ship
        orbit_center = target_position_2D;
    }

    // Convert orbit angles to 3D position around the target.
    // Cache trigonometric calculations - only recompute when angles change
    if (orbit_pitch != orbit_last_computed_pitch || orbit_distance != orbit_last_computed_distance)
    {
        orbit_horizontal_distance_cached = orbit_distance * cos(glm::radians(orbit_pitch));
        orbit_vertical_offset_cached = orbit_distance * sin(glm::radians(orbit_pitch));
        orbit_last_computed_pitch = orbit_pitch;
        orbit_last_computed_distance = orbit_distance;
    }

    // Horizontal component (XY plane) - yaw still needs to be computed each frame due to vec2FromAngle
    glm::vec2 horizontal_offset = vec2FromAngle(orbit_yaw) * orbit_horizontal_distance_cached;

    // Update camera 3D position
    camera_position.x = orbit_center.x + horizontal_offset.x;
    camera_position.y = orbit_center.y + horizontal_offset.y;
    camera_position.z = orbit_vertical_offset_cached;

    // Point camera at orbit center
    pointCameraAt(orbit_center, orbit_yaw);
}

void CinematicViewScreen::updateFlybyCamera(sp::Transform* main_transform, sp::Transform* tot_transform, float delta, OptionState reposition)
{
    // Fly-by camera: Stationary camera positioned at various points.
    // Camera pans to follow the moving ship as it passes.
    viewport->setProjectionType(GuiViewport3D::ProjectionType::Perspective);

    // Get target's velocity for distance calculation.
    glm::vec2 target_velocity{0.0f, 0.0f};
    float target_speed = 0.0f;

    if (auto target_physics = target.getComponent<sp::Physics>())
    {
        target_velocity = target_physics->getVelocity();
        target_speed = glm::length(target_velocity);
    }

    // Get ship size for scaling transition distance
    float ship_half_width = 250.0f;
    if (auto physics = target.getComponent<sp::Physics>())
        ship_half_width = std::max(physics->getSize().x, physics->getSize().y) * 0.5f;

    // Lambda to reposition camera at a new flyby point.
    auto repositionCamera = [this, ship_half_width, target_velocity]()
    {
        // Calculate lead point: midpoint of where ship will be in 20 seconds
        glm::vec2 forward = vec2FromAngle(target_rotation);
        glm::vec2 ship_front = target_position_2D + forward * ship_half_width;
        glm::vec2 lead_point = ship_front + target_velocity * 10.0f;

        // Position camera perpendicular to forward direction
        // Scale distance from ship edge based on ship size for consistent visual framing
        float distance_from_edge = ship_half_width * 2.0f;
        float perpendicular_angle = target_rotation + 90.0f + (random_flyby_angle ? random(-20.0f, 20.0f) : 0.0f);
        glm::vec2 perpendicular_offset = vec2FromAngle(perpendicular_angle) * (distance_from_edge + ship_half_width);

        flyby_camera_pos = lead_point + perpendicular_offset;
    };

    // Set initial position or explicitly reset.
    if (flyby_camera_pos == glm::vec2{0.0f, 0.0f} || reposition == OptionState::Force)
    {
        cinematic_cycle_timer = 0.0f;
        flyby_fov_modifier = viewport->modifyFoV(0.0f);
        repositionCamera();
    }

    // Calculate velocity-based distance threshold and place camera at lead point.
    // As ship moves forward, calculate the expected distance after desired travel time.
    float forward_lead = ship_half_width + glm::length(target_velocity) * 10.0f;
    float perpendicular_dist = ship_half_width * 3.0f;

    // Calculate distance after ship travels the desired amount.
    float forward_velocity = std::abs(glm::dot(target_velocity, vec2FromAngle(target_rotation)));
    float desired_travel_time = 20.0f; // Reposition every 20 seconds
    float forward_travel = forward_velocity * desired_travel_time;
    float remaining_forward_offset = forward_lead - forward_travel;  // Can be negative if ship passes lead point
    float distance_after_travel = sqrtf(remaining_forward_offset * remaining_forward_offset + perpendicular_dist * perpendicular_dist);

    // Threshold is the greater of distance after desired travel, or a minimum
    // based on ship size.
    float distance_threshold = std::max(distance_after_travel, perpendicular_dist + 500.0f);

    // Check if ship has moved beyond velocity-scaled threshold.
    // Enforce minimum 5-second cooldown using shared timer.
    glm::vec2 camera_to_ship = target_position_2D - flyby_camera_pos;
    float horizontal_dist = glm::length(camera_to_ship);

    if (horizontal_dist > distance_threshold && cinematic_cycle_timer >= 5.0f)
    {
        repositionCamera();
        cinematic_cycle_timer = 0.0f;
        camera_to_ship = target_position_2D - flyby_camera_pos;
        horizontal_dist = glm::length(camera_to_ship);
    }

    // Position camera at flyby position
    camera_position = {flyby_camera_pos, flyby_height};

    // Check if ship has a weapons target and ToT lock is enabled
    glm::vec2 aim_point = target_position_2D;
    float frame_distance = horizontal_dist;

    if (updateToTState(tot_transform, delta))
    {
        // Aim at median point between ship and its target
        aim_point = getMedianPoint();

        // For auto-zoom, calculate distance between the two ships
        if (camera_auto_zoom_toggle->getValue())
        {
            frame_distance = getToTDistance();
        }
    }

    // Pan and zoom camera at aim point
    glm::vec2 camera_to_aim = aim_point - flyby_camera_pos;
    float aim_horizontal_dist = glm::length(camera_to_aim);

    if (aim_horizontal_dist > 0.1f)
    {
        // Auto-zoom: adjust FoV to fit both ships in frame
        if (camera_auto_zoom_toggle->getValue() && frame_distance > horizontal_dist)
        {
            // Calculate FoV needed to fit both ships from camera position
            float camera_to_median = aim_horizontal_dist;
            // Use atan to calculate required half-FOV angle, then convert to full FOV modifier
            float required_half_fov = glm::degrees(atan((frame_distance * 0.5f) / camera_to_median));
            float fov_goal = (required_half_fov * 2.0f) - viewport->getBaseFoV();
            fov_goal = std::clamp(fov_goal, -30.0f, 60.0f);  // Limit FoV adjustment range
            flyby_fov_modifier = viewport->modifyFoV(flyby_fov_modifier + ((fov_goal - viewport->getFoVModifier()) * delta * 2.0f));
        }
        else
        {
            if (camera_auto_zoom_toggle->getValue())
            {
                // Standard zoom based on distance
                float fov_goal = ((1 - (std::clamp(horizontal_dist, 500.0f, 2000.0f) / std::clamp(distance_after_travel, 500.0f, 2000.0f))) * 60.0f) - 30.0f;
                flyby_fov_modifier = viewport->modifyFoV(flyby_fov_modifier + ((fov_goal - viewport->getFoVModifier()) * delta));
            }
        }

        // Point camera at aim point
        pointCameraAt(aim_point, target_rotation);
    }
    else
    {
        // Camera at aim point, point straight down
        camera_yaw = target_rotation;
        camera_pitch = 90.0f;
    }
}

void CinematicViewScreen::updateChaseCamera(sp::Transform* main_transform, sp::Transform* tot_transform, float delta)
{
    // Chase camera: Follow ship like main screen camera.
    viewport->setProjectionType(GuiViewport3D::ProjectionType::Perspective);

    // Clamp chase_distance to a valid scaled range for the current ship size.
    chase_distance = std::clamp(chase_distance, getScaledCameraDistance(chase_distance_min), getScaledCameraDistance(chase_distance_max));

    // Get ship dimensions for focal point calculation.
    float ship_half_width = 250.0f;
    float ship_half_length = 250.0f;
    if (auto physics = target.getComponent<sp::Physics>())
    {
        ship_half_width = physics->getSize().y * 0.5f;
        ship_half_length = physics->getSize().x * 0.5f;
    }

    // Calculate focal point based on chase direction.
    const float focal_lead_distance = 500.0f;
    glm::vec2 front = vec2FromAngle(target_rotation - 180.0f) * (ship_half_length + focal_lead_distance);
    glm::vec2 right = vec2FromAngle(target_rotation + 90.0f) * (ship_half_width + focal_lead_distance);
    glm::vec2 focal_point;
    glm::vec2 camera_offset;
    float camera_angle = 0.0f;

    // Determine at what to point the camera.
    glm::vec2 camera_target;
    bool should_use_tot_target = updateToTState(tot_transform, delta);

    // Only use ToT if in range or lingering
    if (should_use_tot_target)
    {
        if (isToTActive(tot_transform))
        {
            // Active tracking: only use ToT if in range
            should_use_tot_target = isToTInRange(tot_transform);
        }
        // else: lingering - always use cached tot_cached_position_2D
    }

    // Set camera target based on ToT state
    if (should_use_tot_target)
    {
        camera_angle = vec2ToAngle(target_position_2D - tot_cached_position_2D) + 180.0f;
        camera_target = tot_cached_position_2D;
    }
    else
    {
        switch (chase_direction)
        {
        case Angle::Front:  // Camera behind ship, looking ahead of ship
            focal_point = target_position_2D + front;
            break;
        case Angle::Back:   // Camera in front, looking behind
            focal_point = target_position_2D - front;
            break;
        case Angle::Right:  // Camera on left side, looking off right side
            focal_point = target_position_2D + right;
            break;
        case Angle::Left:   // Camera on right side, looking off left side
            focal_point = target_position_2D - right;
            break;
        }

        // Position camera at chase_distance from ship
        camera_angle = target_rotation - (static_cast<int>(chase_direction) * 90.0f);
        camera_target = focal_point;
    }

    camera_offset = vec2FromAngle(camera_angle) * chase_distance * (should_use_tot_target ? -1.0f : 1.0f);
    camera_position = {target_position_2D + camera_offset, chase_height};

    // Point camera at target
    pointCameraAt(camera_target, target_rotation);
}

void CinematicViewScreen::updateIsometricCamera(sp::Transform* main_transform, sp::Transform* tot_transform, float delta)
{
    // Isometric camera: Diagonal view from above at fixed 45-degree elevation
    viewport->setProjectionType(GuiViewport3D::ProjectionType::Ortho);
    const float isometric_elevation = 35.264f;
    float horizontal_angle = target_rotation + ((static_cast<int>(isometric_direction) * 90.0f) + 45.0f);

    // Auto-zoom: adjust distance to keep both ships visible when ToT is active
    float target_distance = isometric_distance;
    glm::vec2 camera_aim_point = target_position_2D;

    if (updateToTState(tot_transform, delta) && (isToTInRange(tot_transform) || tot_linger_timer > 0.0f))
    {
        camera_aim_point = getMedianPoint();

        if (camera_auto_zoom_toggle->getValue())
        {
            float ship_to_tot_distance = getToTDistance();
            // For orthographic projection, distance determines visible area
            // Need distance large enough that both ships fit in frame with padding (1.5x)
            target_distance = std::clamp(ship_to_tot_distance * 0.75f, isometric_distance_min, isometric_distance_max);
        }
    }

    // Smoothly interpolate to target distance
    if (camera_auto_zoom_toggle->getValue())
        isometric_distance += (target_distance - isometric_distance) * delta * 0.5f;

    // Calculate camera position using spherical coordinates
    float horizontal_distance = isometric_distance * cos(glm::radians(isometric_elevation));
    glm::vec2 horizontal_offset = vec2FromAngle(horizontal_angle) * horizontal_distance;
    float vertical_offset = isometric_distance * sin(glm::radians(isometric_elevation));

    camera_position = {camera_aim_point + horizontal_offset, vertical_offset};

    // Point at aim point (ship or median)
    pointCameraAt(camera_aim_point, target_rotation);
}

void CinematicViewScreen::updateTopdownCamera(sp::Transform* main_transform, sp::Transform* tot_transform, float delta)
{
    // Top-down camera: Follow ship from directly above.
    viewport->setProjectionType(GuiViewport3D::ProjectionType::Ortho);

    // Auto-zoom: adjust zoom to keep both ships visible when ToT is active
    float target_zoom = topdown_zoom;
    glm::vec2 camera_aim_point = target_position_2D;

    if (updateToTState(tot_transform, delta) && (isToTInRange(tot_transform) || tot_linger_timer > 0.0f))
    {
        camera_aim_point = getMedianPoint();

        if (camera_auto_zoom_toggle->getValue())
        {
            float ship_to_tot_distance = getToTDistance();
            // For orthographic top-down view, zoom determines visible area
            // Need zoom large enough that both ships fit in frame with padding (1.5x)
            target_zoom = std::clamp(ship_to_tot_distance * 0.75f, topdown_zoom_min, topdown_zoom_max);
        }
    }

    // Smoothly interpolate to target zoom
    if (camera_auto_zoom_toggle->getValue())
        topdown_zoom += (target_zoom - topdown_zoom) * delta * 0.5f;

    // Position camera above aim point
    camera_position = {camera_aim_point, topdown_zoom};

    // Point camera straight down at aim point
    pointCameraAt(camera_aim_point, target_rotation);
}

// Camera aiming helper function
void CinematicViewScreen::pointCameraAt(const glm::vec2& aim_point, float fallback_yaw)
{
    glm::vec2 camera_to_aim = aim_point - glm::vec2(camera_position.x, camera_position.y);
    float horizontal_dist = glm::length(camera_to_aim);

    if (horizontal_dist > 0.1f)
    {
        camera_yaw = vec2ToAngle(camera_to_aim);
        camera_pitch = glm::degrees(atan(camera_position.z / horizontal_dist));
    }
    else
    {
        camera_yaw = fallback_yaw;
        camera_pitch = 90.0f;
    }
}

// ToT (Target of Target) helper functions

// Updates ToT state and returns true if we should use ToT data
bool CinematicViewScreen::updateToTState(sp::Transform* tot_transform, float delta)
{
    const bool is_tracking_active_target = isToTActive(tot_transform);
    const bool is_lingering_on_inactive_target = tot_linger_timer > 0.0f;

    if (is_tracking_active_target || is_lingering_on_inactive_target)
    {
        if (is_tracking_active_target)
        {
            // Update cached position from active target
            tot_cached_position_2D = tot_transform->getPosition();
            tot_linger_timer = tot_linger_period;
            return true;
        }
        else  // lingering
        {
            // Use cached position, decrement linger timer
            tot_linger_timer -= delta;
            return true;
        }
    }

    return false;
}

bool CinematicViewScreen::isToTActive(sp::Transform* tot_transform) const
{
    return camera_lock_tot_toggle->getValue() && tot_transform;
}

bool CinematicViewScreen::isToTInRange(sp::Transform* tot_transform) const
{
    if (!tot_transform) return false;
    return getToTDistance() <= tot_max_distance;
}

glm::vec2 CinematicViewScreen::getMedianPoint() const
{
    return (target_position_2D + tot_cached_position_2D) * 0.5f;
}

float CinematicViewScreen::getToTDistance() const
{
    return glm::length(tot_cached_position_2D - target_position_2D);
}