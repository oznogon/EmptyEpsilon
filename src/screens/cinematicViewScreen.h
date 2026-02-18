#pragma once

#include "engine.h"
#include "components/collision.h"

#include "gui/gui2_canvas.h"
#include "gui/gui2_label.h"
#include "screenComponents/viewport3d.h"

class GuiButton;
class GuiElement;
class GuiHelpOverlay;
class GuiSelector;
class GuiToggleButton;
class MouseRenderer;

class CinematicViewScreen : public GuiCanvas, public Updatable
{
private:
    GuiViewport3D* viewport;
    sp::ecs::Entity target;

    GuiElement* camera_controls;
    GuiSelector* camera_lock_selector;
    GuiSelector* camera_mode_selector;
    GuiToggleButton* camera_reset;
    GuiToggleButton* camera_auto_zoom_toggle;
    GuiToggleButton* camera_lock_toggle;
    GuiToggleButton* camera_lock_tot_toggle;
    GuiToggleButton* camera_lock_cycle_toggle;
    GuiButton* callsigns_toggle;
    GuiButton* ui_toggle;
    GuiHelpOverlay* keyboard_help;
    GuiLabel* keybind_hint_label;

#ifdef DEBUG
    // Debug-only damping function selector
    enum class DampingType {
        Exponential = 0,
        CriticalSpring
    };
    GuiSelector* damping_selector;
    DampingType current_damping_type = DampingType::Exponential;

    // Velocity tracking for critical spring damper
    glm::vec2 camera_velocity_2d{0.0f, 0.0f};
    float camera_velocity_angle = 0.0f;
    float camera_velocity_zoom = 0.0f;
#endif

    // Camera modes and convenience conversions
    enum class CameraMode {
        Flyby = 0,
        Orbital,
        Chase,
        Isometric,
        Topdown,
        Free,
        Static
    };
    const int camera_mode_flyby_int = static_cast<int>(CameraMode::Flyby);
    const int camera_mode_free_int = static_cast<int>(CameraMode::Free);
    const int camera_mode_static_int = static_cast<int>(CameraMode::Static);

    // Active camera mode - the source of truth for which mode is currently active
    CameraMode active_camera_mode = CameraMode::Flyby;

    // Camera constraints
    // Movement rates
    const float camera_translation_speed_min = 5.0f;
    const float camera_translation_speed_max = 50.0f;
    const float camera_rotation_speed_min = 1.0f;
    const float camera_rotation_speed_max = 4.0f;
    const float camera_zoom_speed_min = 20.0f;
    const float camera_zoom_speed_max = 60.0f;
    // Per-mode distance
    const float orbit_distance_min = 300.0f;
    const float orbit_distance_max = 1200.0f;
    const float flyby_height_min = 50.0f;
    const float flyby_height_max = 500.0f;
    const float chase_distance_min = 300.0f;
    const float chase_distance_max = 2000.0f;
    const float chase_height_min = 50.0f;
    const float chase_height_max = 500.0f;
    const float isometric_elevation = 35.264f;
    const float isometric_distance_min = 500.0f;
    const float isometric_distance_max = 3000.0f;
    const float topdown_zoom_min = 500.0f;
    const float topdown_zoom_max = 5000.0f;

    // Initialize camera properties
    float camera_translation_speed = camera_translation_speed_min;
    float camera_rotation_speed = camera_rotation_speed_min;
    float camera_zoom_speed = camera_zoom_speed_min;
    float min_camera_distance = 300.0f;
    float max_camera_distance = 1000.0f;
    float camera_sensitivity = 0.15f;
    glm::vec2 camera_rotation_vector{0.0f, 0.0f};
    glm::vec2 camera_destination{0.0f, 0.0f};
    // camera_position, _yaw, _pitch are intiialized in main()
    float angle_yaw = -90.0f;
    float angle_pitch = 45.0f;
    P<MouseRenderer> mouse_renderer;

    // Initialize pref-defined options
    bool invert_mouselook_y = false; // TODO: Rename
    bool random_flyby_angle = false;
    bool manual_camera_controls_enabled = false; // Toggled by hotkey
    float keybind_hint_timer = 5.0f; // Show keybind hint for 5 seconds when UI is hidden

    // Initialize measurement caches
    glm::vec2 diff_2D{0.0f, 0.0f};
    glm::vec3 diff_3D{0.0f, 0.0f, 0.0f};
    float distance_2D = 0.0f;
    float distance_3D = 0.0f;

    glm::vec2 target_position_2D{0.0f, 0.0f};
    glm::vec2 target_position_smoothed{0.0f, 0.0f}; // Damped version to smooth high-speed/network jitter
    glm::vec3 target_position_3D{0.0f, 0.0f, 0.0f};
    glm::vec2 camera_position_2D{0.0f, 0.0f};
    float target_rotation = 0.0f;

    // Shared cinematic cycle timer for auto-orbit, flyby, and target cycling
    float cinematic_cycle_timer = 0.0f;
    const float cinematic_cycle_period = 30.0f;

    // Per-mode properties

    // Orbital camera mode state
    float orbit_yaw = -90.0f;
    float orbit_pitch = 45.0f;
    float orbit_distance = 700.0f;
    glm::vec2 orbit_center{0.0f, 0.0f};
    bool orbit_auto_rotate = false;
    bool orbit_tot_tracking_was_active = false; // Tracks previous frame's ToT state for reset detection
    float orbit_target_yaw = -90.0f;
    float orbit_target_pitch = 45.0f;
    float orbit_target_distance = 700.0f;
    // Auto-orbit movement state
    float orbit_start_yaw = -90.0f;
    float orbit_start_pitch = 45.0f;
    float orbit_start_distance = 700.0f;
    float orbit_linger_timer = 0.0f;
    const float orbit_linger_duration = 1.0f;
    bool orbit_is_lingering = false;
    // Cached orbital transform values
    float orbit_horizontal_distance_cached = 0.0f;
    float orbit_vertical_offset_cached = 0.0f;
    // Invalid value forces initial computation
    float orbit_last_computed_pitch = -999.0f;
    float orbit_last_computed_distance = -999.0f;

    // Fly-by camera mode state
    float flyby_height = 200.0f;
    float flyby_distance = 1000.0f;
    float flyby_fov_modifier = 0.0f;
    glm::vec2 flyby_camera_pos{0.0f, 0.0f};

    // Chase camera mode state
    enum class ChaseAngle {
        Front = 0,
        Right,
        Back,
        Left
    } chase_direction = ChaseAngle::Back;

    float chase_distance = 700.0f;
    float chase_height = 200.0f;

    // Isometric mode camera angle increments, all 45°
    enum class IsometricAngle {
        FrontRight = 0,
        BackRight,
        BackLeft,
        FrontLeft,
    } isometric_direction = IsometricAngle::FrontRight;

    // Isometric mode camera elevations
    enum class AxonometricElevation {
        ArcTan12 = 0, // 26.565°; arctan(1/2) or arctan(sin(30°))
        Thirty,       // 30°
        Isometric,    // 35.264°; arctan(sin(45°))
        Cabinet,      // 45°
        ArcTan43,     // 53.13°; arctan(4/3)
        Complement    // 63.435°; 90° - arctan(1/2)
    } elev = AxonometricElevation::Isometric;
    const float isometric_elevations[6] = {26.565f, 30.0f, 35.264f, 45.0f, 53.13f, 63.435f};

    float isometric_distance = 1000.0f;
    IsometricAngle isometric_direction = IsometricAngle::FrontRight;

    // Top-down camera mode state
    glm::vec2 topdown_offset{0.0f, 0.0f};
    float topdown_zoom = 1000.0f;

    // Max target-of-target tracking distance
    sp::ecs::Entity target_of_target;
    glm::vec2 tot_cached_position_2D;
    const float tot_max_distance = 6000.0f;
    const float tot_linger_period = 5.0f;
    float tot_linger_timer = 0.0f;

public:
    explicit CinematicViewScreen(RenderLayer* render_layer);
    virtual ~CinematicViewScreen();

    void setTargetTransform(sp::Transform* transform, float delta);
    void updateCamera(sp::Transform* main_transform, sp::Transform* tot_transform, float delta);
    void updateOrbitCamera(sp::Transform* main_transform, sp::Transform* tot_transform, float delta);
    void updateFlybyCamera(sp::Transform* main_transform, sp::Transform* tot_transform, float delta);
    void updateChaseCamera(sp::Transform* main_transform, sp::Transform* tot_transform, float delta);
    void updateIsometricCamera(sp::Transform* main_transform, sp::Transform* tot_transform, float delta);
    void updateTopdownCamera(sp::Transform* main_transform, sp::Transform* tot_transform, float delta);
    void updateFreeCamera(float delta);

private:
    // Scale camera distances based on ship size relative to radius 200
    float getScaledCameraDistance(float base_distance) const;

    // Camera aiming function
    void pointCameraAt(const glm::vec2& aim_point, float fallback_yaw = 0.0f);

    // Target-of-target functions
    bool updateToTState(sp::Transform* tot_transform, float delta);
    bool isToTActive(sp::Transform* tot_transform) const;
    bool isToTInRange(sp::Transform* tot_transform) const;
    glm::vec2 getMedianPoint() const;
    float getToTDistance() const;

    // Auto-zoom helper functions
    float getShipRadius(sp::ecs::Entity entity) const;
    float calculatePerspectiveAutoZoomFoV(float camera_to_target_distance, float total_span, float delta);
    float calculateOrthographicAutoZoomDistance(float horizontal_span);

    // UI toggle
    void setUIVisibility(bool is_visible);

    // Populate camera mode selector based on lock state
    void updateCameraModeSelector(bool is_locked);

    // Damping dispatch functions (debug-switchable in DEBUG builds, direct calls in release)
    float applyDamping(float source, float target, float speed, float delta);
    glm::vec2 applyDamping(const glm::vec2& source, const glm::vec2& target, float speed, float delta);
    float applyAngleDamping(float source, float target, float speed, float delta);

    virtual void update(float delta) override;
    virtual bool onPointerMove(glm::vec2 position, sp::io::Pointer::ID id) override;
    virtual void onPointerUp(glm::vec2 position, sp::io::Pointer::ID id) override;
};
