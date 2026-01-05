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
#include "math/damp.h"

#include "screenComponents/indicatorOverlays.h"
#include "screenComponents/scrollingBanner.h"
#include "screenComponents/helpOverlay.h"
#include "gui/gui2_button.h"
#include "gui/gui2_element.h"
#include "gui/gui2_panel.h"
#include "gui/gui2_progressbar.h"
#include "gui/gui2_selector.h"
#include "gui/gui2_togglebutton.h"
#include "gui/mouseRenderer.h"

CinematicViewScreen::CinematicViewScreen(RenderLayer* render_layer)
: GuiCanvas(render_layer)
{
    // Capture mouse_renderer so we can hide it in free camera.
    mouse_renderer = engine->getObject("mouseRenderer");
    invert_mouselook_y = (PreferencesManager::get("camera_mouse_inverted", "0") == "1"); // TODO: Replace with axis flip on hotkey
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
        // Use large delta to snap smoothed position to actual position on initialization
        if (auto target_transform = target.getComponent<sp::Transform>()) setTargetTransform(target_transform, 1000.0f);
        break;
    }

    // Initialize main()-defined camera parameters.
    camera_yaw = -90.0f;
    camera_pitch = 45.0f;
    camera_position = {0.0f, 0.0f, 200.0f};

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
        ->setSelectionIndex(camera_mode_flyby_int)
        ->setPosition(20.0f, -120.0f, sp::Alignment::BottomLeft)
        ->setSize(300.0f, 50.0f);

    // Auto-zoom toggle (works across all camera modes)
    camera_auto_zoom_toggle = new GuiToggleButton(camera_controls, "CAMERA_AUTO_ZOOM_TOGGLE", tr("button", "Auto-zoom camera"),
        [this](bool value) {
            // Functions check the button's state
        }
    );
    camera_auto_zoom_toggle
        ->setValue(false)
        ->setPosition(320.0f, -70.0f, sp::Alignment::BottomLeft)
        ->setSize(300.0f, 50.0f);

    // Mode-context option trigger
    camera_reset = new GuiToggleButton(camera_controls, "CAMERA_RESET", tr("button", "Reset camera"),
        [this](bool value)
        {
            switch (active_camera_mode)
            {
                case CameraMode::Flyby:
                    // Reset flyby camera
                    flyby_fov_modifier = viewport->modifyFoV(0.0f);
                    flyby_camera_pos = {0.0f, 0.0f};  // Force reposition on next update
                    camera_reset->setValue(false);
                    break;
                case CameraMode::Orbital:
                    // Toggle auto-rotate orbital camera
                    orbit_auto_rotate = value;
                    if (orbit_auto_rotate)
                    {
                        // Initialize auto-orbit state machine
                        orbit_is_lingering = false;
                        orbit_linger_timer = 0.0f;

                        // Store current positions as start positions
                        orbit_start_yaw = orbit_yaw;
                        orbit_start_pitch = orbit_pitch;
                        orbit_start_distance = orbit_distance;

                        // Generate first random target positions
                        orbit_target_yaw = random(0.0f, 360.0f);
                        orbit_target_pitch = random(-10.0f, 60.0f);
                        orbit_target_distance = random(orbit_distance_min, orbit_distance_max);
                    }
                    break;
                case CameraMode::Chase:
                    // Rotate camera
                    chase_direction = static_cast<ChaseAngle>((static_cast<int>(chase_direction) + 1) % 4);
                    camera_reset->setValue(false);
                    break;
                case CameraMode::Isometric:
                    // Rotate camera
                    isometric_direction = static_cast<IsometricAngle>((static_cast<int>(isometric_direction) + 1) % 4);
                    camera_reset->setValue(false);
                    break;
                case CameraMode::Topdown:
                    // Reset top-down camera to center on ship
                    topdown_offset = {0.0f, 0.0f};
                    topdown_zoom = 1000.0f;
                    camera_reset->setValue(false);
                    break;
                case CameraMode::Free:
                case CameraMode::Static:
                    // Teleport camera to selected target location
                    if (target)
                    {
                        if (auto target_transform = target.getComponent<sp::Transform>())
                        {
                            glm::vec2 target_pos = target_transform->getPosition();
                            camera_position = {target_pos.x, target_pos.y, 200.0f};
                            camera_yaw = target_transform->getRotation();
                            camera_pitch = 45.0f;
                        }
                    }
                    camera_reset->setValue(false);
                    break;
                default:
                    LOG(Warning, "Invalid case for camera mode in CinematicViewScreen camera_reset: ", static_cast<int>(active_camera_mode));
                    break;
            }
        }
    );
    camera_reset
        ->setValue(false)
        ->setPosition(320.0f, -120.0f, sp::Alignment::BottomLeft)
        ->setSize(300.0f, 50.0f);

    // Camera mode selector
    camera_mode_selector = new GuiSelector(camera_controls, "CAMERA_MODE_SELECTOR", [this](int index, string value) {});
    camera_mode_selector
        ->setPosition(20.0f, -70.0f, sp::Alignment::BottomLeft)
        ->setSize(300.0f, 50.0f);

    // Toggle whether to lock the camera onto a ship.
    camera_lock_toggle = new GuiToggleButton(camera_controls, "CAMERA_LOCK_TOGGLE", tr("button", "Lock camera on ship"),
        [this](bool value) {
            // Repopulate mode selector with appropriate modes for lock state
            updateCameraModeSelector(value);
        });
    camera_lock_toggle
        ->setValue(true)
        ->setPosition(20.0f, -20.0f, sp::Alignment::BottomLeft)
        ->setSize(300.0f, 50.0f);

    camera_lock_tot_toggle = new GuiToggleButton(camera_controls, "CAMERA_LOCK_TOT_TOGGLE", tr("button", "Point at ship's target"), [this](bool value) {});
    camera_lock_tot_toggle
        ->setValue(false)
        ->setPosition(320.0f, -20.0f, sp::Alignment::BottomLeft)
        ->setSize(300.0f, 50.0f);

    // Progress bar for cinematic cycle
    cycle_progress = new GuiProgressbar(camera_controls, "CYCLE_PROGRESS", 0.0f, cinematic_cycle_period, cinematic_cycle_period);
    cycle_progress
        ->setPosition(920.0f, -20.0f, sp::Alignment::BottomLeft)
        ->setSize(30.0f, 150.0f)
        ->hide();
    (new GuiLabel(cycle_progress, "", tr("button", "Time to next cycle"), 20.0f))
        ->setVertical()
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center);

    camera_lock_cycle_toggle = new GuiToggleButton(camera_controls, "CAMERA_LOCK_CYCLE_TOGGLE", tr("button", "Cycle through ships"), [this](bool value) {});
    camera_lock_cycle_toggle
        ->setValue(false)
        ->setPosition(620.0f, -20.0f, sp::Alignment::BottomLeft)
        ->setSize(300.0f, 50.0f);

    camera_mode_cycle_toggle = new GuiToggleButton(camera_controls, "CAMERA_MODE_CYCLE_TOGGLE", tr("button", "Cycle camera modes"), [this](bool value) {});
    camera_mode_cycle_toggle
        ->setValue(false)
        ->setPosition(620.0f, -70.0f, sp::Alignment::BottomLeft)
        ->setSize(300.0f, 50.0f);

    // Toggle callsign visibility.
    callsigns_toggle = new GuiToggleButton(camera_controls, "CAMERA_CALLSIGNS_TOGGLE", tr("button", "Show callsigns"),
        [this](bool value) {
            viewport->setCallsignVisibility(value);
        });
    callsigns_toggle
        ->setValue(viewport->areCallsignsVisible())
        ->setPosition(620.0f, -120.0f, sp::Alignment::BottomLeft)
        ->setSize(300.0f, 50.0f);

    // Toggle UI controls. Once invisible, the toggle_ui keybind or any mouse
    // click reveals them.
    ui_toggle = new GuiButton(camera_controls, "UI_TOGGLE", tr("button", "Toggle controls"),
        [this]()
        {
            setUIVisibility(false);
        }
    );
    ui_toggle->setPosition(-20, -20, sp::Alignment::BottomRight)->setSize(200, 50);

#ifdef DEBUG
    // Debug damping function selector
    damping_selector = new GuiSelector(camera_controls, "DAMPING_SELECTOR", [this](int index, string value) {
        current_damping_type = static_cast<DampingType>(index);
        // Reset velocity tracking when switching to critical spring damper
        if (current_damping_type == DampingType::CriticalSpring)
        {
            camera_velocity_2d = {0.0f, 0.0f};
            camera_velocity_angle = 0.0f;
            camera_velocity_zoom = 0.0f;
        }
    });
    damping_selector->addEntry("Exponential damp", "0");
    damping_selector->addEntry("Critical spring damp", "1");
    damping_selector
        ->setSelectionIndex(static_cast<int>(DampingType::Exponential))
        ->setPosition(-20.0f, -70.0f, sp::Alignment::BottomRight)
        ->setSize(250.0f, 50.0f);
#endif

    // Overlays
    new GuiIndicatorOverlays(this);

    (new GuiScrollingBanner(this))->setPosition(0, 0)->setSize(GuiElement::GuiSizeMax, 100);

    keyboard_help = new GuiHotkeyHelpOverlay(this, {"Cinematic View"});
    keyboard_help->moveToFront();

    // Keybind hint label - shown when UI is hidden
    keybind_hint_label = new GuiLabel(this, "KEYBIND_HINT", "", 30);
    keybind_hint_label
        ->setPosition(0, -100, sp::Alignment::BottomCenter)
        ->setSize(800, 100);
    keybind_hint_label->hide();

    // Initialize camera mode selector with modes for initial lock state (locked=true)
    updateCameraModeSelector(true);
}

CinematicViewScreen::~CinematicViewScreen()
{
    // Reset mouse visibility.
    mouse_renderer->should_be_visible = true;
    SDL_SetRelativeMouseMode(SDL_FALSE);
}

void CinematicViewScreen::update(float delta)
{
    // If this is a client and it is disconnected, exit.
    if (game_client && game_client->getStatus() == GameClient::Disconnected)
    {
        mouse_renderer->should_be_visible = true;
        SDL_SetRelativeMouseMode(SDL_FALSE); // Redundant with destructor?
        destroy();
        disconnectFromServer();
        returnToMainMenu(getRenderLayer());
        return;
    }

    // Toggle keyboard help.
    if (keys.help.getDown())
        keyboard_help->frame->setVisible(!keyboard_help->frame->isVisible());

    // Toggle UI visibility.
    if (keys.cinematic.toggle_ui.getDown())
        setUIVisibility(!camera_controls->isVisible());

    // Toggle callsign visibility.
    if (keys.cinematic.toggle_callsigns.getDown())
    {
        viewport->toggleCallsigns();
        callsigns_toggle->setValue(viewport->areCallsignsVisible());
    }

    // Toggle manual camera controls when UI is hidden.
    if (keys.cinematic.toggle_manual_controls.getDown())
        setManualCameraControl(!manual_camera_controls_enabled);

    // Update keybind hint label.
    if (!camera_controls->isVisible() && keybind_hint_timer > 0.0f)
    {
        // Build hint text from keybinds.
        string hint_text = "";

        const auto& toggle_ui_key = keys.cinematic.toggle_ui;
        string ui_key = toggle_ui_key.getHumanReadableKeyName(0);
        for (int n = 1; toggle_ui_key.getKeyType(n) != sp::io::Keybinding::Type::None; n++)
            ui_key += ", " + toggle_ui_key.getHumanReadableKeyName(n);
        if (!ui_key.empty() || active_camera_mode == CameraMode::Static)
            hint_text += tr("ui_hidden", "Click mouse or press {key} to display controls").format({{"key", ui_key}});

        const auto& toggle_manual_key = keys.cinematic.toggle_manual_controls;
        string manual_key = toggle_manual_key.getHumanReadableKeyName(0);
        for (int n = 1; toggle_manual_key.getKeyType(n) != sp::io::Keybinding::Type::None; n++)
            manual_key += ", " + toggle_manual_key.getHumanReadableKeyName(n);
        if (!manual_key.empty())
        {
            if (!hint_text.empty()) hint_text += "\n";
            hint_text += tr("ui_hidden", "Press {key} to toggle manual control of camera").format({{"key", manual_key}});
        }

        // Show label if we have any text.
        if (!hint_text.empty())
        {
            keybind_hint_label->setText(hint_text);
            keybind_hint_label->show();
            keybind_hint_timer -= delta;
        }
        else
            keybind_hint_label->hide();
    }
    // Reset timer when UI becomes visible or manual controls are enabled.
    else
    {
        keybind_hint_label->hide();

        if (camera_controls->isVisible() || manual_camera_controls_enabled)
            keybind_hint_timer = 5.0f;
    }

    // Toggle camera lock.
    if (keys.cinematic.lock_camera.getDown())
    {
        camera_lock_toggle->setValue(!camera_lock_toggle->getValue());
        updateCameraModeSelector(camera_lock_toggle->getValue());
    }

    if (keys.cinematic.cycle_camera.getDown())
        camera_lock_cycle_toggle->setValue(!camera_lock_cycle_toggle->getValue());

    if (keys.cinematic.cycle_camera_mode.getDown())
        camera_mode_cycle_toggle->setValue(!camera_mode_cycle_toggle->getValue());

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

    if (keys.cinematic.previous_camera_mode.getDown())
    {
        camera_mode_selector->setSelectionIndex(camera_mode_selector->getSelectionIndex() - 1);
        if (camera_mode_selector->getSelectionIndex() < 0)
            camera_mode_selector->setSelectionIndex(camera_mode_selector->entryCount() - 1);
    }

    if (keys.cinematic.next_camera_mode.getDown())
    {
        camera_mode_selector->setSelectionIndex(camera_mode_selector->getSelectionIndex() + 1);
        if (camera_mode_selector->getSelectionIndex() >= camera_mode_selector->entryCount())
            camera_mode_selector->setSelectionIndex(0);
    }

    if (keys.cinematic.toggle_auto_zoom.getDown())
        camera_auto_zoom_toggle->setValue(!camera_auto_zoom_toggle->getValue());

    if (keys.cinematic.toggle_target_lock.getDown())
        camera_lock_tot_toggle->setValue(!camera_lock_tot_toggle->getValue());

    if (keys.cinematic.camera_option.getDown())
        camera_reset->setValue(!camera_reset->getValue());

    if (keys.escape.getDown())
    {
        destroy();
        returnToShipSelection(getRenderLayer());
    }

    if (keys.pause.getDown())
        if (game_server && !gameGlobalInfo->getVictoryFaction()) engine->setGameSpeed(engine->getGameSpeed() > 0.0f ? 0.0f : 1.0f);

    // Sync selector with active camera mode.
    // If selector changed, update active mode.
    int selector_index = camera_mode_selector->getSelectionIndex();
    if (selector_index >= 0)
    {
        int selector_mode_value = std::stoi(camera_mode_selector->getEntryValue(selector_index));
        CameraMode selector_mode = static_cast<CameraMode>(selector_mode_value);

        // Selector changed, update active mode.
        if (selector_mode != active_camera_mode) active_camera_mode = selector_mode;
    }

    // If active mode changed programmatically, update selector.
    int active_mode_index = camera_mode_selector->indexByValue(std::to_string(static_cast<int>(active_camera_mode)));
    if (active_mode_index >= 0 && active_mode_index != selector_index)
        camera_mode_selector->setSelectionIndex(active_mode_index);

    switch (active_camera_mode)
    {
        case CameraMode::Flyby:
        case CameraMode::Topdown:
            camera_reset
                ->setValue(false)
                ->setText(tr("button", "Reset camera"));
            break;
        case CameraMode::Orbital:
            camera_reset
                ->setValue(orbit_auto_rotate)
                ->setText(tr("button", "Auto-rotate orbit"));
            break;
        case CameraMode::Chase:
        case CameraMode::Isometric:
            camera_reset
                ->setValue(false)
                ->setText(tr("button", "Rotate camera"));
            break;
        case CameraMode::Free:
        case CameraMode::Static:
            camera_reset
                ->setValue(false)
                ->setText(tr("button", "Go to target"));
            break;
        default:
            LOG(Warning, "Invalid case for camera mode in CinematicViewScreen update() mode_selector label assignment: ", static_cast<int>(active_camera_mode));
            break;
    }

    // Handle camera movement.
    bool is_camera_moving = false;

    // Map mouse wheel input to zoom in/out.
    // TODO: Enable keybind mapping of mouse wheel, which might be problematic
    // for other player screens.
    float mouse_wheel_delta = keys.zoom_in.getValue() - keys.zoom_out.getValue();

    // Detect axis vs. digital input.
    auto calculateAxis = [&](float pos, float neg, bool invert = false)
    {
        float value = 0.0f;

        // If one axis is bound to two inputs (i.e. left and right) and is
        // engaged, it returns the same non-zero value to both inputs, so
        // we can return a single value by averaging them.
        if (pos == neg && ((pos > 0.0f && neg > 0.0f) || (pos < 0.0f && neg < 0.0f)))
            value = (pos + neg) * 0.5f;
        else
            value = pos - neg;

        // TODO: Can I use Keybinding::inverted?
        if (invert) value = -value;

        // Apply normalized sensitivity to manual camera controls.
        return value * (camera_sensitivity / 0.15f);
    };

    // Determine if ToT tracking is active for the orbital camera, and disable
    // manual orbital adjustments if so.
    bool is_orbital_tot_tracking_active = false;
    if (active_camera_mode == CameraMode::Orbital && camera_lock_toggle->getValue() && camera_lock_tot_toggle->getValue())
    {
        // Check if target has a weapons target.
        auto target_entity_target_component = target.getComponent<Target>();
        if (target_entity_target_component && target_entity_target_component->entity)
        {
            auto tot_transform = target_entity_target_component->entity.getComponent<sp::Transform>();
            if (tot_transform)
            {
                // Check if ToT is in range or linger timer is active
                float tot_distance = glm::length(tot_transform->getPosition() - target_position_2D);
                is_orbital_tot_tracking_active = (tot_distance <= tot_max_distance) || (tot_linger_timer > 0.0f);
            }
        }
    }

    // Reset orbital camera to default when ToT tracking becomes inactive
    if (orbit_tot_tracking_was_active && !is_orbital_tot_tracking_active)
    {
        orbit_yaw = -90.0f;
        orbit_pitch = 45.0f;
        orbit_distance = 700.0f;
        orbit_auto_rotate = false;
    }

    // Store current state for next frame
    orbit_tot_tracking_was_active = is_orbital_tot_tracking_active;

    // When camera is locked, keybinds control camera position and angle based
    // on camera mode. Manual controls are toggled via hotkey.
    // Hide mouse if camera is manually controlled.
    mouse_renderer->should_be_visible = !manual_camera_controls_enabled;
    if (manual_camera_controls_enabled)
    {
        switch (active_camera_mode)
        {
        // Flyby camera tracking locked ship from fixed point
        case CameraMode::Flyby:
            if (keys.cinematic.move_forward.getValue() || keys.cinematic.move_backward.getValue()
                || mouse_wheel_delta != 0.0f)
            {
                is_camera_moving = true;
                flyby_fov_modifier = viewport->modifyFoV(flyby_fov_modifier - (delta * camera_zoom_speed * (
                    calculateAxis(keys.cinematic.move_forward.getValue(), keys.cinematic.move_backward.getValue())
                    + mouse_wheel_delta
                )));
            }

            // Up/down
            if (keys.cinematic.move_up.getValue() || keys.cinematic.tilt_down.getValue()
                || keys.cinematic.move_down.getValue() || keys.cinematic.tilt_up.getValue())
            {
                is_camera_moving = true;
                flyby_height = std::clamp(flyby_height + camera_translation_speed * (
                    calculateAxis(keys.cinematic.move_up.getValue(), keys.cinematic.move_down.getValue())
                    + calculateAxis(keys.cinematic.tilt_up.getValue(), keys.cinematic.tilt_down.getValue(), invert_mouselook_y)
                ), flyby_height_min, flyby_height_max);
            }
            break;

        // Orbital camera fixed on target ship
        case CameraMode::Orbital:
            // Don't allow manual adjustments when ToT tracking is active
            if (!is_orbital_tot_tracking_active)
            {
                // Rotate left/right
                if (keys.cinematic.strafe_left.getValue() || keys.cinematic.rotate_left.getValue()
                    || keys.cinematic.strafe_right.getValue() || keys.cinematic.rotate_right.getValue())
                {
                    is_camera_moving = true;
                    orbit_yaw += camera_rotation_speed * (
                        calculateAxis(keys.cinematic.strafe_left.getValue(), keys.cinematic.strafe_right.getValue())
                        + calculateAxis(keys.cinematic.rotate_left.getValue(), keys.cinematic.rotate_right.getValue())
                    );
                }

                // Over/under
                if (keys.cinematic.move_up.getValue() || keys.cinematic.tilt_down.getValue()
                    || keys.cinematic.move_down.getValue() || keys.cinematic.tilt_up.getValue())
                {
                    is_camera_moving = true;
                    // No full range because of culling issues viewing models from beneath.
                    orbit_pitch = std::clamp(orbit_pitch + camera_rotation_speed * (
                        calculateAxis(keys.cinematic.move_up.getValue(), keys.cinematic.move_down.getValue())
                        + calculateAxis(keys.cinematic.tilt_up.getValue(), keys.cinematic.tilt_down.getValue(), invert_mouselook_y)
                    ), -19.9f, 89.9f);
                }

                // Closer/farther
                if (keys.cinematic.move_forward.getValue() || keys.cinematic.move_backward.getValue() || mouse_wheel_delta != 0.0f)
                {
                    is_camera_moving = true;
                    orbit_distance = std::clamp(orbit_distance - camera_translation_speed * (
                        calculateAxis(keys.cinematic.move_forward.getValue(), keys.cinematic.move_backward.getValue())
                        + mouse_wheel_delta
                    ), getScaledCameraDistance(orbit_distance_min), getScaledCameraDistance(orbit_distance_max));
                }
            }
            break;

        // Chase mode, similar to main screen view
        case CameraMode::Chase:
            // Closer/farther
            if (keys.cinematic.move_forward.getValue() || keys.cinematic.move_backward.getValue()
                || mouse_wheel_delta != 0.0f)
            {
                is_camera_moving = true;
                chase_distance = std::clamp(chase_distance - camera_translation_speed * (
                    calculateAxis(keys.cinematic.move_forward.getValue(), keys.cinematic.move_backward.getValue())
                    + mouse_wheel_delta
                ), getScaledCameraDistance(chase_distance_min), getScaledCameraDistance(chase_distance_max));
            }

            // Up/down
            if (keys.cinematic.move_up.getValue() || keys.cinematic.move_down.getValue()
                || keys.cinematic.tilt_up.getValue() || keys.cinematic.tilt_down.getValue())
            {
                is_camera_moving = true;
                chase_height = std::clamp(chase_height + camera_rotation_speed * (
                    calculateAxis(keys.cinematic.move_up.getValue(), keys.cinematic.move_down.getValue())
                    + calculateAxis(keys.cinematic.tilt_up.getValue(), keys.cinematic.tilt_down.getValue(), invert_mouselook_y)
                ), chase_height_min, chase_height_max);
            }

            // Orbit horizontally at 90-degree increments.
            if (keys.cinematic.strafe_left.getDown() || keys.cinematic.rotate_right.getDown())
                chase_direction = static_cast<ChaseAngle>((static_cast<int>(chase_direction) + 1) % 4);
            else if (keys.cinematic.strafe_right.getDown() || keys.cinematic.rotate_left.getDown())
                chase_direction = static_cast<ChaseAngle>((static_cast<int>(chase_direction) + 3) % 4);

            break;

        // Isometric and axonometric angles with orthographic projection
        case CameraMode::Isometric:
            // Closer/farther
            if (keys.cinematic.move_forward.getValue() || keys.cinematic.move_backward.getValue()
                || mouse_wheel_delta != 0.0f)
            {
                is_camera_moving = true;
                isometric_distance = std::clamp(isometric_distance - camera_translation_speed * (
                    calculateAxis(keys.cinematic.move_forward.getValue(), keys.cinematic.move_backward.getValue())
                    + mouse_wheel_delta
                ), isometric_distance_min, isometric_distance_max);
            }

            // Orbit horizontally at 90-degree increments.
            if (keys.cinematic.strafe_left.getDown() || keys.cinematic.rotate_right.getDown())
                isometric_direction = static_cast<IsometricAngle>((static_cast<int>(isometric_direction) + 1) % 4);
            else if (keys.cinematic.strafe_right.getDown() || keys.cinematic.rotate_left.getDown())
                isometric_direction = static_cast<IsometricAngle>((static_cast<int>(isometric_direction) + 3) % 4);
            // Change axonometric elevation angle presets.
            else if (keys.cinematic.move_up.getDown() || keys.cinematic.tilt_down.getDown())
                elev = static_cast<AxonometricElevation>(std::min(static_cast<int>(elev) + 1, static_cast<int>(AxonometricElevation::Complement)));
            else if (keys.cinematic.move_down.getDown() || keys.cinematic.tilt_up.getDown())
                elev = static_cast<AxonometricElevation>(std::max(static_cast<int>(elev) - 1, static_cast<int>(AxonometricElevation::ArcTan12)));

            break;

        // Overhead angle with orthographic projection
        case CameraMode::Topdown:
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

            // W/S or R/F: Zoom out/in
            if (keys.cinematic.move_forward.getValue() || keys.cinematic.move_up.getValue()
                || keys.cinematic.move_backward.getValue() || keys.cinematic.move_down.getValue()
                || mouse_wheel_delta != 0.0f)
            {
                is_camera_moving = true;
                topdown_zoom = std::clamp(topdown_zoom - camera_translation_speed * (
                    calculateAxis(keys.cinematic.move_forward.getValue(), keys.cinematic.move_backward.getValue())
                    + calculateAxis(keys.cinematic.move_up.getValue(), keys.cinematic.move_down.getValue(), invert_mouselook_y)
                    + mouse_wheel_delta
                ), topdown_zoom_min, topdown_zoom_max);
            }
            break;

        // Free camera/mouselook
        case CameraMode::Free:
            // Free camera
            if (keys.cinematic.move_forward.getValue() || keys.cinematic.move_backward.getValue())
            {
                is_camera_moving = true;
                glm::vec2 xy_vector = vec2FromAngle(camera_yaw) * camera_translation_speed * calculateAxis(keys.cinematic.move_forward.getValue(), keys.cinematic.move_backward.getValue());
                camera_position.x += xy_vector.x;
                camera_position.y += xy_vector.y;
            }

            if (keys.cinematic.strafe_left.getValue() || keys.cinematic.strafe_right.getValue())
            {
                is_camera_moving = true;
                glm::vec2 xy_vector = vec2FromAngle(camera_yaw) * camera_translation_speed * calculateAxis(keys.cinematic.strafe_left.getValue(), keys.cinematic.strafe_right.getValue());
                camera_position.x += xy_vector.y;
                camera_position.y -= xy_vector.x;
            }

            if (keys.cinematic.move_up.getValue() || keys.cinematic.move_down.getValue())
            {
                is_camera_moving = true;
                camera_position.z += camera_translation_speed * calculateAxis(keys.cinematic.move_up.getValue(), keys.cinematic.move_down.getValue());
            }

            if (keys.cinematic.rotate_left.getValue() || keys.cinematic.rotate_right.getValue())
            {
                is_camera_moving = true;
                camera_yaw -= camera_rotation_speed * calculateAxis(keys.cinematic.rotate_left.getValue(), keys.cinematic.rotate_right.getValue());
            }

            if (keys.cinematic.tilt_down.getValue() || keys.cinematic.tilt_up.getValue())
            {
                is_camera_moving = true;
                camera_pitch = std::clamp(camera_pitch - camera_rotation_speed * calculateAxis(keys.cinematic.tilt_down.getValue(), keys.cinematic.tilt_up.getValue(), invert_mouselook_y), -89.9f, 89.9f);
            }
            break;

        case CameraMode::Static:
            // Do nothing.
            break;

        default:
            LOG(Warning, "Invalid case for camera mode in CinematicViewScreen update() when UI is not visible: ", static_cast<int>(active_camera_mode));
            break;
        }
    }

    // Boost speed ("run") for camera movement, -1.0 to 1.0.
    // Positive values speed up, negative values slow down.
    const float move_speed_factor = keys.cinematic.move_faster.getValue() - keys.cinematic.move_slower.getValue();

    // Translate axis to target speed value.
    // factor ranges from -1 (returns min), to 1 (returns max)
    auto targetValue = [&](const float min, const float max, const float factor)
    {
        return min + ((max - min) * ((factor + 1.0f) * 0.5f));
    };

    // Interpolate speed changes with framerate-independent damping
    if (is_camera_moving)
    {
        // Smoothly interpolate toward target speed based on boost input
        const float speed_interpolation = 10.0f;
        camera_translation_speed = applyDamping(camera_translation_speed, targetValue(camera_translation_speed_min, camera_translation_speed_max, move_speed_factor), speed_interpolation, delta);
        camera_rotation_speed = applyDamping(camera_rotation_speed, targetValue(camera_rotation_speed_min, camera_rotation_speed_max, move_speed_factor), speed_interpolation, delta);
        camera_zoom_speed = applyDamping(camera_zoom_speed, targetValue(camera_zoom_speed_min, camera_zoom_speed_max, move_speed_factor), speed_interpolation, delta);
    }
    else
    {
        // Reset to minimum speed when not moving
        camera_translation_speed = camera_translation_speed_min;
        camera_rotation_speed = camera_rotation_speed_min;
        camera_zoom_speed = camera_zoom_speed_min;
    }

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

    // If the list of selectable entities is empty, disable the selector.
    camera_lock_selector->setEnable(camera_lock_selector->entryCount() > 0);

    // Update shared cinematic cycle timer and progress bar.
    cinematic_cycle_timer += delta;
    if (camera_lock_cycle_toggle->getValue()
        || camera_mode_cycle_toggle->getValue()
        || (active_camera_mode == CameraMode::Orbital && camera_reset->getValue()))
    {
        cycle_progress->setValue(cinematic_cycle_period - cinematic_cycle_timer);
        cycle_progress->show();
    }
    else cycle_progress->hide();

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

        // If camera mode cycling is enabled, switch to a random mode
        if (camera_mode_cycle_toggle->getValue() && camera_lock_toggle->getValue())
        {
            // Select a random new CameraMode from the list of locked-mode
            // CameraModes.
            CameraMode new_mode = active_camera_mode;
            if (locked_modes.size() > 1)
            {
                do {
                    new_mode = locked_modes[irandom(0, locked_modes.size() - 1)];
                } while (new_mode == active_camera_mode);
            }

            active_camera_mode = new_mode;
            camera_mode_selector->setSelectionIndex(camera_mode_selector->indexByValue(std::to_string(static_cast<int>(new_mode))));
        }
    }

    // Plot headings from the camera to the locked player ship.
    // Set camera_yaw and camera_pitch to those values.

    // If lock is enabled and a ship is selected...
    if (camera_lock_toggle->getValue() && target)
    {
        // Set target position to target transform if available.
        // If the target lacks a transform, clear the target and disable target
        // lock controls.
        auto target_transform = target.getComponent<sp::Transform>();
        if (!target_transform)
        {
            // No target available. Disable lock controls, reset mode to free camera.
            active_camera_mode = CameraMode::Free;
            camera_mode_selector->disable();
            target = sp::ecs::Entity();

            const bool is_camera_lock_selector_populated = camera_lock_selector->entryCount() > 0;
            camera_lock_toggle->setValue(false)->setEnable(is_camera_lock_selector_populated);
            updateCameraModeSelector(false);
            camera_mode_selector->setEnable(is_camera_lock_selector_populated);
            camera_reset->setEnable(is_camera_lock_selector_populated);
            camera_auto_zoom_toggle->setValue(false)->setEnable(is_camera_lock_selector_populated);
            camera_lock_tot_toggle->setValue(false)->setEnable(is_camera_lock_selector_populated);
            camera_lock_cycle_toggle->setValue(false)->setEnable(camera_lock_selector->entryCount() > 1);
            camera_mode_cycle_toggle->setValue(false)->setEnable(false);
            return;
        }

        // Enable target lock controls.
        camera_mode_selector->enable();
        camera_reset->enable();
        camera_auto_zoom_toggle->enable();
        camera_lock_tot_toggle->enable();
        camera_lock_cycle_toggle->enable();
        camera_mode_cycle_toggle->enable();

        setTargetTransform(target_transform, delta);

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
        // No target available. Disable lock controls if camera_lock_selector isn't populated.
        const bool is_camera_lock_selector_populated = camera_lock_selector->entryCount() > 0;

        // Allow Free and Static modes to remain selectable when unlocked
        camera_mode_selector->setEnable(true);

        camera_lock_toggle->setValue(false)->setEnable(is_camera_lock_selector_populated);
        updateCameraModeSelector(false);
        camera_reset->setEnable(is_camera_lock_selector_populated);
        camera_auto_zoom_toggle->setValue(false)->setEnable(is_camera_lock_selector_populated);
        camera_lock_tot_toggle->setValue(false)->setEnable(is_camera_lock_selector_populated);
        camera_lock_cycle_toggle->setValue(false)->setEnable(camera_lock_selector->entryCount() > 1);
        camera_mode_cycle_toggle->setValue(false)->setEnable(false);

        updateCamera(nullptr, nullptr, delta);
    }

}

bool CinematicViewScreen::onPointerMove(glm::vec2 position, sp::io::Pointer::ID id)
{
    return false;
}

void CinematicViewScreen::onPointerUp(glm::vec2 position, sp::io::Pointer::ID id)
{
    // Restore GUI on any mouse click.
    if (!camera_controls->isVisible()) setUIVisibility(true);
    GuiCanvas::onPointerUp(position, id);
}

void CinematicViewScreen::setTargetTransform(sp::Transform* transform, float delta)
{
    // Get the target transform's current position and heading.
    target_rotation = transform->getRotation();
    target_position_2D = transform->getPosition();

    // Smooth the target position to reduce stuttering from high-speed movement
    // or network interpolation jitter. Use aggressive damping to follow quickly
    // while smoothing discrete jumps.
    target_position_smoothed = applyDamping(target_position_smoothed, target_position_2D, 10.0f, delta);

    // Copy the selected transform's position into a vec3 and camera position
    // into a vec2 for camera angle calculations.
    target_position_3D = {target_position_smoothed.x, target_position_smoothed.y, 0.0f};
    camera_position_2D = {camera_position.x, camera_position.y};

    // Calculate the 2D and 3D distances from the camera to the target.
    diff_2D = target_position_smoothed - camera_position_2D;
    diff_3D = target_position_3D - camera_position;
    distance_2D = glm::length(diff_2D);
    distance_3D = glm::length(diff_3D);

    // Always keep the camera less than 1U from the lock target transform.
    // If it has a physics collider and velocity, factor that into the distance.
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
    // Scale camera distances based on ship size, defaulting to for radius 200
    // (Atlantis default mesh radius).
    float ship_radius = 200.0f;
    if (target)
    {
        if (auto physics = target.getComponent<sp::Physics>())
            ship_radius = std::max(physics->getSize().x, physics->getSize().y) * 0.5f;
    }

    float size_scale = sqrtf(ship_radius / 200.0f);
    return base_distance * size_scale;
}

void CinematicViewScreen::updateCamera(sp::Transform* main_transform, sp::Transform* tot_transform, float delta)
{
    // Route to appropriate camera mode.
    switch (active_camera_mode)
    {
    case CameraMode::Flyby:
        updateFlybyCamera(main_transform, tot_transform, delta);
        break;
    case CameraMode::Orbital:
        updateOrbitCamera(main_transform, tot_transform, delta);
        break;
    case CameraMode::Chase:
        updateChaseCamera(main_transform, tot_transform, delta);
        break;
    case CameraMode::Isometric:
        updateIsometricCamera(main_transform, tot_transform, delta);
        break;
    case CameraMode::Topdown:
        updateTopdownCamera(main_transform, tot_transform, delta);
        break;
    case CameraMode::Free:
        updateFreeCamera(delta);
        break;
    case CameraMode::Static:
        // Do nothing.
        break;
    default:
        LOG(Warning, "Invalid case for camera mode in CinematicViewScreen updateCamera(): ", static_cast<int>(active_camera_mode));
        break;
    }
}

void CinematicViewScreen::updateOrbitCamera(sp::Transform* main_transform, sp::Transform* tot_transform, float delta)
{
    // Orbit camera: Position using spherical coordinates.
    viewport->setProjectionType(ProjectionType::Perspective);

    // Clamp orbit_distance to valid scaled range for current ship size.
    const float scaled_min = getScaledCameraDistance(orbit_distance_min);
    const float scaled_max = getScaledCameraDistance(orbit_distance_max);
    orbit_distance = std::clamp(orbit_distance, scaled_min, scaled_max);

    // Always orbit around the player ship (the camera lock target).
    orbit_center = target_position_smoothed;

    // Check if we should track the target-of-target.
    bool is_tracking_tot = updateToTState(tot_transform, delta) && (isToTInRange(tot_transform) || tot_linger_timer > 0.0f);

    // Manage transitions to and from lingering and auto-rotation.
    if (orbit_auto_rotate)
    {
        if (orbit_is_lingering)
        {
            // Linger phase: hold position and count down.
            orbit_linger_timer += delta;

            if (orbit_linger_timer >= orbit_linger_duration)
            {
                // Linger complete, start new movement.
                orbit_is_lingering = false;
                orbit_linger_timer = 0.0f;

                // Store current positions as start positions.
                orbit_start_yaw = orbit_yaw;
                orbit_start_pitch = orbit_pitch;
                orbit_start_distance = orbit_distance;

                // Generate new random target positions.
                orbit_target_yaw = random(0.0f, 360.0f);
                orbit_target_pitch = random(-10.0f, 60.0f); // Cap underside pitch until culling issues are resolved.
                orbit_target_distance = random(scaled_min, scaled_max);
            }
        }
        else
        {
            // Movement phase: interpolate from start to target
            // When timer resets, enter linger instead of snapping back
            if (cinematic_cycle_timer < 0.1f && orbit_linger_timer == 0.0f)
            {
                orbit_yaw = orbit_target_yaw;
                orbit_pitch = orbit_target_pitch;
                orbit_distance = orbit_target_distance;
                orbit_is_lingering = true;
            }
            else
            {
                // Calculate smootherstep interpolation factor.
                // TODO: Replace with SP tween.h smootherstep if merged.
                const float eased_t = glm::smoothstep(0.0f, 1.0f, std::clamp(cinematic_cycle_timer / cinematic_cycle_period, 0.0f, 1.0f));

                // Interpolate using eased factor.
                // For yaw, handle angle wrapping normalized to -180,180.
                float yaw_diff = orbit_target_yaw - orbit_start_yaw;
                while (yaw_diff > 180.0f) yaw_diff -= 360.0f;
                while (yaw_diff < -180.0f) yaw_diff += 360.0f;
                orbit_yaw = orbit_start_yaw + yaw_diff * eased_t;

                // Linear interpolation for pitch and distance.
                orbit_pitch = orbit_start_pitch + (orbit_target_pitch - orbit_start_pitch) * eased_t;
                orbit_distance = orbit_start_distance + (orbit_target_distance - orbit_start_distance) * eased_t;
            }
        }
    }
    // Damp distance changes.
    else
        orbit_distance = applyDamping(orbit_distance, orbit_target_distance, 5.0f, delta);

    // When tracking ToT, position camera so that the locked camera target is
    // between the camera and ToT.
    if (is_tracking_tot)
    {
        // Calculate direction from ToT toward player ship and beyond.
        glm::vec2 tot_to_ship = target_position_smoothed - tot_cached_position_2D;
        float ship_to_tot_distance = glm::length(tot_to_ship);

        if (ship_to_tot_distance > 0.1f)
        {
            // Calculate total span including ship sizes with padding.
            const float padding_factor = 1.2f;
            float total_span = (ship_to_tot_distance + getShipRadius(target) + getShipRadius(target_of_target)) * padding_factor;

            // Use current orbit_distance for camera positioning.
            float effective_distance = orbit_distance;

            // If auto-zoom is enabled, adjust FoV to fit both ships.
            if (camera_auto_zoom_toggle->getValue())
                viewport->modifyFoV(calculatePerspectiveAutoZoomFoV(effective_distance, total_span, delta));

            // Position camera with player ship between camera and target-of-target.
            camera_position = {
                target_position_smoothed + (tot_to_ship / ship_to_tot_distance) * effective_distance, // x,y
                effective_distance * glm::tan(glm::radians(orbit_pitch)) // z
            };
        }
    }
    // Otherwise, use manual orbital positioning.
    else
    {
        // Reset FoV modifier when not tracking ToT.
        if (camera_auto_zoom_toggle->getValue())
            viewport->modifyFoV(applyDamping(viewport->getFoVModifier(), 0.0f, 2.0f, delta));

        if (orbit_pitch != orbit_last_computed_pitch || orbit_distance != orbit_last_computed_distance)
        {
            orbit_horizontal_distance_cached = orbit_distance * cos(glm::radians(orbit_pitch));
            orbit_vertical_offset_cached = orbit_distance * sin(glm::radians(orbit_pitch));
            orbit_last_computed_pitch = orbit_pitch;
            orbit_last_computed_distance = orbit_distance;
        }

        glm::vec2 horizontal_offset = vec2FromAngle(orbit_yaw) * orbit_horizontal_distance_cached;
        camera_position = {orbit_center.x + horizontal_offset.x, orbit_center.y + horizontal_offset.y, orbit_vertical_offset_cached};
    }

    // Point camera at target-of-target if tracking, otherwise at the ship
    glm::vec2 camera_look_target = is_tracking_tot ? tot_cached_position_2D : orbit_center;
    pointCameraAt(camera_look_target, orbit_yaw);
}

void CinematicViewScreen::updateFlybyCamera(sp::Transform* main_transform, sp::Transform* tot_transform, float delta)
{
    // Fly-by camera: Stationary camera positioned at various points.
    // Camera pans to follow the moving ship as it passes.
    viewport->setProjectionType(ProjectionType::Perspective);

    // Get target's velocity for distance calculation.
    glm::vec2 target_velocity{0.0f, 0.0f};

    if (auto target_physics = target.getComponent<sp::Physics>())
        target_velocity = target_physics->getVelocity();

    // Get ship size for scaling transition distance
    float ship_half_width = 250.0f;
    if (auto physics = target.getComponent<sp::Physics>())
        ship_half_width = std::max(physics->getSize().x, physics->getSize().y) * 0.5f;

    // Lambda to reposition camera at a new flyby point.
    auto repositionCamera = [this, ship_half_width, target_velocity]()
    {
        // Calculate lead point: midpoint of where ship will be in 20 seconds
        glm::vec2 forward = vec2FromAngle(target_rotation);
        glm::vec2 ship_front = target_position_smoothed + forward * ship_half_width;
        glm::vec2 lead_point = ship_front + target_velocity * 10.0f;

        // Position camera perpendicular to forward direction
        // Scale distance from ship edge based on ship size for consistent visual framing
        float distance_from_edge = ship_half_width * 2.0f;
        float perpendicular_angle = target_rotation + 90.0f + (random_flyby_angle ? random(-20.0f, 20.0f) : 0.0f);
        glm::vec2 perpendicular_offset = vec2FromAngle(perpendicular_angle) * (distance_from_edge + ship_half_width);

        flyby_camera_pos = lead_point + perpendicular_offset;
    };

    // Set initial position or explicitly reset.
    if (flyby_camera_pos == glm::vec2{0.0f, 0.0f})
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
    glm::vec2 camera_to_ship = target_position_smoothed - flyby_camera_pos;
    float horizontal_dist = glm::length(camera_to_ship);

    if (horizontal_dist > distance_threshold && cinematic_cycle_timer >= 5.0f)
    {
        repositionCamera();
        cinematic_cycle_timer = 0.0f;
        camera_to_ship = target_position_smoothed - flyby_camera_pos;
        horizontal_dist = glm::length(camera_to_ship);
    }

    // Move camera to flyby position.
    camera_position = {flyby_camera_pos, flyby_height};

    // Check if ship has a weapons target and ToT lock is enabled.
    glm::vec2 aim_point = target_position_smoothed;
    float frame_distance = horizontal_dist;

    bool is_tracking_tot = updateToTState(tot_transform, delta);
    if (is_tracking_tot)
    {
        // Aim at median point between ship and its target.
        aim_point = getMedianPoint();

        // Calculate total span including ship sizes for auto-zoom.
        if (camera_auto_zoom_toggle->getValue())
        {
            const float padding_factor = 1.2f;
            frame_distance = (getToTDistance() + getShipRadius(target) + getShipRadius(target_of_target)) * padding_factor;
        }
    }

    // Pan and zoom camera at aim point.
    glm::vec2 camera_to_aim = aim_point - flyby_camera_pos;
    float aim_horizontal_dist = glm::length(camera_to_aim);

    if (aim_horizontal_dist > 0.1f)
    {
        // Auto-zoom adjust FoV to fit ship or ship and ToT in frame.
        if (camera_auto_zoom_toggle->getValue())
        {
            float fov_goal;

            if (is_tracking_tot && frame_distance > horizontal_dist)
            {
                // Use helper function to calculate FoV for fitting both ships.
                fov_goal = calculatePerspectiveAutoZoomFoV(aim_horizontal_dist, frame_distance, delta);
                flyby_fov_modifier = viewport->modifyFoV(fov_goal);
            }
            else
            {
                // Standard zoom based on distance to single ship.
                fov_goal = ((1.0f - (std::clamp(horizontal_dist, 500.0f, 2000.0f) / std::clamp(distance_after_travel, 500.0f, 2000.0f))) * 60.0f) - 20.0f;
                flyby_fov_modifier = viewport->modifyFoV(applyDamping(viewport->getFoVModifier(), fov_goal, 1.0f, delta));
            }
        }

        // Point camera at aim point.
        pointCameraAt(aim_point, target_rotation);
    }
    else
    {
        // Move camera to aim point and point straight down.
        camera_yaw = target_rotation;
        camera_pitch = 90.0f;
    }
}

void CinematicViewScreen::updateChaseCamera(sp::Transform* main_transform, sp::Transform* tot_transform, float delta)
{
    // Chase camera: Follow ship like main screen camera.
    viewport->setProjectionType(ProjectionType::Perspective);

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

    // Use ToT only if in range or lingering.
    if (should_use_tot_target)
    {
        if (isToTActive(tot_transform))
            should_use_tot_target = isToTInRange(tot_transform);
        // else use cached tot_cached_position_2D
    }

    // Set camera target based on ToT state.
    if (should_use_tot_target)
    {
        camera_angle = vec2ToAngle(target_position_smoothed - tot_cached_position_2D) + 180.0f;
        camera_target = tot_cached_position_2D;
    }
    else
    {
        switch (chase_direction)
        {
        case ChaseAngle::Front: // Camera behind ship, looking ahead of ship
            focal_point = target_position_smoothed + front;
            break;
        case ChaseAngle::Back:  // Camera in front, looking behind
            focal_point = target_position_smoothed - front;
            break;
        case ChaseAngle::Right: // Camera on left side, looking off right side
            focal_point = target_position_smoothed + right;
            break;
        case ChaseAngle::Left:  // Camera on right side, looking off left side
            focal_point = target_position_smoothed - right;
            break;
        }

        // Position camera at chase_distance from ship.
        camera_angle = target_rotation - (static_cast<int>(chase_direction) * 90.0f);
        camera_target = focal_point;
    }

    camera_offset = vec2FromAngle(camera_angle) * chase_distance * (should_use_tot_target ? -1.0f : 1.0f);
    camera_position = {target_position_smoothed + camera_offset, chase_height};

    // Apply aspect-ratio aware auto-zoom when tracking ToT.
    if (should_use_tot_target && camera_auto_zoom_toggle->getValue())
    {
        // Calculate distance from camera to median point between ship and ToT.
        glm::vec2 median_point = getMedianPoint();
        glm::vec2 camera_to_median = median_point - glm::vec2(camera_position.x, camera_position.y);
        float camera_to_median_dist = glm::length(camera_to_median);

        if (camera_to_median_dist > 0.1f)
        {
            // Calculate total span including ship sizes with padding.
            const float padding_factor = 1.2f;
            float total_span = (getToTDistance() + getShipRadius(target) + getShipRadius(target_of_target)) * padding_factor;

            // Adjust FoV to fit both ships.
            viewport->modifyFoV(calculatePerspectiveAutoZoomFoV(camera_to_median_dist, total_span, delta));
        }
    }
    else if (camera_auto_zoom_toggle->getValue())
    {
        // Reset FoV modifier when not tracking ToT.
        viewport->modifyFoV(applyDamping(viewport->getFoVModifier(), 0.0f, 2.0f, delta));
    }

    // Point camera at target.
    pointCameraAt(camera_target, target_rotation);
}

void CinematicViewScreen::updateIsometricCamera(sp::Transform* main_transform, sp::Transform* tot_transform, float delta)
{
    // Isometric camera: Diagonal view from above at fixed elevation
    viewport->setProjectionType(ProjectionType::Orthographic);
    float horizontal_angle = target_rotation + ((static_cast<int>(isometric_direction) * 90.0f) + 45.0f);

    // Auto-zoom: adjust distance to keep both ships visible when ToT is active
    float target_distance = isometric_distance;
    glm::vec2 camera_aim_point = target_position_smoothed;

    if (updateToTState(tot_transform, delta) && (isToTInRange(tot_transform) || tot_linger_timer > 0.0f))
    {
        camera_aim_point = getMedianPoint();

        if (camera_auto_zoom_toggle->getValue())
        {
            // Calculate total horizontal span including ship sizes with padding.
            const float padding_factor = 1.2f;
            float horizontal_span = (getToTDistance() + getShipRadius(target) + getShipRadius(target_of_target)) * padding_factor;

            // Calculate required distance for orthographic projection.
            float required_distance = calculateOrthographicAutoZoomDistance(horizontal_span);
            target_distance = std::clamp(required_distance, isometric_distance_min, isometric_distance_max);
        }
    }

    // Smoothly interpolate to target distance with framerate-independent damping
    if (camera_auto_zoom_toggle->getValue())
        isometric_distance = applyDamping(isometric_distance, target_distance, 0.5f, delta);

    // Calculate camera position using spherical coordinates
    const float elevation_rad = glm::radians(isometric_elevations[static_cast<int>(elev)]);
    float horizontal_distance = isometric_distance * cos(elevation_rad);
    glm::vec2 horizontal_offset = vec2FromAngle(horizontal_angle) * horizontal_distance;
    float vertical_offset = isometric_distance * sin(elevation_rad);

    camera_position = {camera_aim_point + horizontal_offset, vertical_offset};

    // Point at aim point (ship or median)
    pointCameraAt(camera_aim_point, target_rotation);
}

// Update orthographic top-down camera to follow ship from above.
void CinematicViewScreen::updateTopdownCamera(sp::Transform* main_transform, sp::Transform* tot_transform, float delta)
{
    viewport->setProjectionType(ProjectionType::Orthographic);

    // Auto-zoom adjusts camera position and zoom to keep both camera lock
    // target and ToT visible in the same frame.
    float target_zoom = topdown_zoom;
    glm::vec2 camera_aim_point = target_position_smoothed;

    if (updateToTState(tot_transform, delta) && (isToTInRange(tot_transform) || tot_linger_timer > 0.0f))
    {
        camera_aim_point = getMedianPoint();

        if (camera_auto_zoom_toggle->getValue())
        {
            // Calculate total horizontal span including ship sizes with padding.
            const float padding_factor = 1.2f;
            float horizontal_span = (getToTDistance() + getShipRadius(target) + getShipRadius(target_of_target)) * padding_factor;

            // Calculate required camera height (Z) for orthographic top-down view.
            float required_z = calculateOrthographicAutoZoomDistance(horizontal_span);
            target_zoom = std::clamp(required_z, topdown_zoom_min, topdown_zoom_max);
        }
    }

    // Smoothly interpolate to target zoom.
    if (camera_auto_zoom_toggle->getValue())
        topdown_zoom = applyDamping(topdown_zoom, target_zoom, 0.5f, delta);

    // Position camera above aim point and point straight down.
    camera_position = {camera_aim_point, topdown_zoom};
    pointCameraAt(camera_aim_point, target_rotation);
}

// Update directly controlled Free camera mode. Might be redundant?
void CinematicViewScreen::updateFreeCamera(float delta)
{
    viewport->setProjectionType(ProjectionType::Perspective);
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

// Target-of-target functions

// Update ToT state and return true if we should use ToT data.
bool CinematicViewScreen::updateToTState(sp::Transform* tot_transform, float delta)
{
    if (isToTActive(tot_transform))
    {
        // Update cached position from active target
        tot_cached_position_2D = tot_transform->getPosition();
        tot_linger_timer = tot_linger_period;
        return true;
    }
    // Linger. Use cached position, decrement linger timer.
    else if (tot_linger_timer > 0.0f)
    {
        tot_linger_timer -= delta;
        return true;
    }

    return false;
}

// Check if the ToT toggle is active and a ToT transform is available.
bool CinematicViewScreen::isToTActive(sp::Transform* tot_transform) const
{
    return camera_lock_tot_toggle->getValue() && tot_transform;
}

// Check if the selected ToT is within tracking range.
bool CinematicViewScreen::isToTInRange(sp::Transform* tot_transform) const
{
    if (!tot_transform) return false;
    return getToTDistance() <= tot_max_distance;
}

// Return a median point between the camera lock target and the ToT position to
// serve as the camera's focal point.
glm::vec2 CinematicViewScreen::getMedianPoint() const
{
    return (target_position_smoothed + tot_cached_position_2D) * 0.5f;
}

// Return the distance from the camera lock target to the ToT.
float CinematicViewScreen::getToTDistance() const
{
    return glm::length(tot_cached_position_2D - target_position_smoothed);
}

// Auto-zoom helper functions

// Get the radius (half of longest dimension) of a ship entity.
float CinematicViewScreen::getShipRadius(sp::ecs::Entity entity) const
{
    // Default radius = Atlantis mesh radius
    float radius = 200.0f;
    if (auto physics = entity.getComponent<sp::Physics>())
        radius = std::max(physics->getSize().x, physics->getSize().y) * 0.5f;
    return radius;
}

// Calculate aspect-ratio aware FoV modifier for perspective cameras to fit a given span.
float CinematicViewScreen::calculatePerspectiveAutoZoomFoV(float camera_to_target_distance, float total_span, float delta)
{
    // Get viewport aspect ratio.
    float aspect_ratio = viewport->getAspectRatio();
    if (aspect_ratio <= 0.0f)
    {
        LOG(Error, "Viewport has non-positive aspect ratio in auto-zoom, falling back to 4:3");
        aspect_ratio = 4.0f / 3.0f;
    }

    // Calculate horizontal FoV needed to fit the span at the given distance.
    float horizontal_fov_rad = 2.0f * atan((total_span * 0.5f) / camera_to_target_distance);

    // Convert to vertical FoV using aspect ratio.
    float vertical_fov_rad = 2.0f * atan(tan(horizontal_fov_rad * 0.5f) / aspect_ratio);
    float fov_modifier_needed = glm::degrees(vertical_fov_rad) - viewport->getBaseFoV();

    // Clamp FoV modifier to reasonable range.
    fov_modifier_needed = std::clamp(fov_modifier_needed, -30.0f, 60.0f);

    // Smoothly adjust FoV and return the new modifier.
    return applyDamping(viewport->getFoVModifier(), fov_modifier_needed, 2.0f, delta);
}

// Calculate distance needed for orthographic cameras to fit a horizontal span.
float CinematicViewScreen::calculateOrthographicAutoZoomDistance(float horizontal_span)
{
    // Get viewport aspect ratio.
    float aspect_ratio = viewport->getAspectRatio();
    if (aspect_ratio <= 0.0f)
    {
        LOG(Error, "Viewport has non-positive aspect ratio in orthographic auto-zoom, falling back to 4:3");
        aspect_ratio = 4.0f / 3.0f;
    }

    // Convert horizontal span to required vertical half-height using aspect ratio.
    float required_half_height = (horizontal_span * 0.5f) / aspect_ratio;

    // Convert half-height to required distance using vertical FoV.
    float vertical_fov_rad = glm::radians(viewport->getFoV() * 0.5f);
    return required_half_height / tan(vertical_fov_rad);
}

// Set the visibility of UI camera controls.
void CinematicViewScreen::setUIVisibility(bool is_visible)
{
    camera_controls->setVisible(is_visible);

    // UI visible and manual control are mutually exclusive.
    if (is_visible && manual_camera_controls_enabled)
    {
        // Disable manual control when showing UI.
        manual_camera_controls_enabled = false;
        SDL_SetRelativeMouseMode(SDL_FALSE);
    }

    // Bind mouse visibility.
    mouse_renderer->should_be_visible = !manual_camera_controls_enabled;
}

void CinematicViewScreen::setManualCameraControl(bool is_manual)
{
    if (manual_camera_controls_enabled != is_manual)
    {
        manual_camera_controls_enabled = is_manual;

        // UI visible and manual control are mutually exclusive.
        if (is_manual && camera_controls->isVisible())
        {
            // Hide UI when enabling manual control
            camera_controls->setVisible(false);
        }

        // Bind relative mouse state and visibility.
        SDL_SetRelativeMouseMode(is_manual ? SDL_TRUE : SDL_FALSE);
        mouse_renderer->should_be_visible = !is_manual;
    }
}

// Manage the state of camera mode selector options between locked and unlocked
// modes.
void CinematicViewScreen::updateCameraModeSelector(bool is_locked)
{
    camera_mode_selector->clear();

    // If locked, list all CameraModes except Free and Static.
    if (is_locked)
    {
        camera_mode_selector->addEntry(tr("button", "Fly-by camera"), static_cast<string>(static_cast<int>(CameraMode::Flyby)));
        camera_mode_selector->addEntry(tr("button", "Orbital camera"), static_cast<string>(static_cast<int>(CameraMode::Orbital)));
        camera_mode_selector->addEntry(tr("button", "Chase camera"), static_cast<string>(static_cast<int>(CameraMode::Chase)));
        camera_mode_selector->addEntry(tr("button", "Isometric camera"), static_cast<string>(static_cast<int>(CameraMode::Isometric)));
        camera_mode_selector->addEntry(tr("button", "Top-down camera"), static_cast<string>(static_cast<int>(CameraMode::Topdown)));

        // If active mode is Free or Static, default to Flyby.
        if (active_camera_mode == CameraMode::Free || active_camera_mode == CameraMode::Static)
            active_camera_mode = CameraMode::Flyby;
    }
    // If unlocked, list only Free and Static CameraModes.
    else
    {
        camera_mode_selector->addEntry(tr("button", "Free camera"), static_cast<string>(static_cast<int>(CameraMode::Free)));
        camera_mode_selector->addEntry(tr("button", "Static camera"), static_cast<string>(static_cast<int>(CameraMode::Static)));

        // If active mode is not Free or Static, switch to Free.
        if (active_camera_mode != CameraMode::Free && active_camera_mode != CameraMode::Static)
            active_camera_mode = CameraMode::Free;
    }

    // Set selector to match active mode. Fallback to first option in selector.
    const int active_mode_index = camera_mode_selector->indexByValue(std::to_string(static_cast<int>(active_camera_mode)));
    if (active_mode_index >= 0) camera_mode_selector->setSelectionIndex(active_mode_index);
    else camera_mode_selector->setSelectionIndex(0);
}

#ifdef DEBUG
// Select damping type to apply.
float CinematicViewScreen::applyDamping(float source, float target, float speed, float delta)
{
    switch (current_damping_type)
    {
    case DampingType::Exponential:
        return exponentialDamp(source, target, speed, delta);
    case DampingType::CriticalSpring:
        {
            float position = source;
            criticalSpringDamp(position, camera_velocity_zoom, target, delta);
            return position;
        }
    default:
        return exponentialDamp(source, target, speed, delta);
    }
}

glm::vec2 CinematicViewScreen::applyDamping(const glm::vec2& source, const glm::vec2& target, float speed, float delta)
{
    switch (current_damping_type)
    {
    case DampingType::Exponential:
        return exponentialDamp(source, target, speed, delta);
    case DampingType::CriticalSpring:
        {
            glm::vec2 position = source;
            criticalSpringDamp(position, camera_velocity_2d, target, delta);
            return position;
        }
    default:
        return exponentialDamp(source, target, speed, delta);
    }
}

float CinematicViewScreen::applyAngleDamping(float source, float target, float speed, float delta)
{
    switch (current_damping_type)
    {
    case DampingType::Exponential:
        return exponentialAngleDamp(source, target, speed, delta);
    case DampingType::CriticalSpring:
        {
            float position = source;
            criticalSpringAngleDamp(position, camera_velocity_angle, target, delta);
            return position;
        }
    default:
        return exponentialAngleDamp(source, target, speed, delta);
    }
}
#else
// Apply exponential damping.
float CinematicViewScreen::applyDamping(float source, float target, float speed, float delta)
{
    return exponentialDamp(source, target, speed, delta);
}

glm::vec2 CinematicViewScreen::applyDamping(const glm::vec2& source, const glm::vec2& target, float speed, float delta)
{
    return exponentialDamp(source, target, speed, delta);
}

float CinematicViewScreen::applyAngleDamping(float source, float target, float speed, float delta)
{
    return exponentialAngleDamp(source, target, speed, delta);
}
#endif