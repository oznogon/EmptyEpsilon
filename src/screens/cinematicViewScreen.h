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
public:
    enum CameraMode {
        CAMERA_MODE_FLYBY = 0,
        CAMERA_MODE_ORBITAL,
        CAMERA_MODE_CHASE,
        CAMERA_MODE_ISOMETRIC,
        CAMERA_MODE_TOPDOWN
    };

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
    GuiToggleButton* mouselook_toggle;
    GuiButton* ui_toggle;
    GuiHelpOverlay* keyboard_help;
    CameraMode camera_mode = CAMERA_MODE_FLYBY;

    float min_camera_distance = 300.0f;
    float max_camera_distance = 1000.0f;
    float camera_sensitivity = 0.15f;
    glm::vec2 camera_rotation_vector{0.0f, 0.0f};
    glm::vec2 camera_destination{0.0f, 0.0f};
    // camera_position, _yaw, _pitch are defined in main.
    float angle_yaw = -90.0f;
    float angle_pitch = 45.0f;
    const float camera_translation_min = 10.0f;
    const float camera_translation_max = 50.0f;
    float camera_translation_speed = camera_translation_min;
    const float camera_rotation_min = 1.0f;
    const float camera_rotation_max = 4.0f;
    float camera_rotation_speed = camera_rotation_min;
    const float camera_zoom_min = 20.0f;
    const float camera_zoom_max = 60.0f;
    float camera_zoom_speed = camera_zoom_min;
    P<MouseRenderer> mouse_renderer;
    bool mouselook = false;
    bool invert_mouselook_y = false;
    bool random_flyby_angle = false;

    glm::vec2 diff_2D{0.0f, 0.0f};
    glm::vec3 diff_3D{0.0f, 0.0f, 0.0f};
    float distance_2D = 0.0f;
    float distance_3D = 0.0f;

    glm::vec2 target_position_2D{0.0f, 0.0f};
    glm::vec3 target_position_3D{0.0f, 0.0f, 0.0f};
    glm::vec2 camera_position_2D{0.0f, 0.0f};
    float target_rotation = 0.0f;

    sp::ecs::Entity target_of_target;
    glm::vec2 tot_position_2D{0.0f, 0.0f};
    glm::vec3 tot_position_3D{0.0f, 0.0f, 0.0f};
    glm::vec2 tot_diff_2D{0.0f, 0.0f};
    glm::vec3 tot_diff_3D{0.0f, 0.0f, 0.0f};
    float tot_angle = 0.0f;
    float tot_distance_2D = 0.0f;
    float tot_distance_3D = 0.0f;

    // Shared cinematic cycle timer for auto-orbit, flyby, and target cycling
    float cinematic_cycle_timer = 0.0f;
    const float cinematic_cycle_period = 30.0f;

    // Orbital camera mode state
    float orbit_yaw = -90.0f;
    float orbit_pitch = 45.0f;
    float orbit_distance = 700.0f;
    glm::vec2 orbit_center{0.0f, 0.0f};
    bool orbit_auto_rotate = false;
    float orbit_target_yaw = -90.0f;
    float orbit_target_pitch = 45.0f;
    float orbit_target_distance = 700.0f;

    // Fly-by camera mode state
    float flyby_height = 200.0f;
    float flyby_distance = 1000.0f;
    float flyby_fov_modifier = 0.0f;
    glm::vec2 flyby_camera_pos{0.0f, 0.0f};

    // Chase camera mode state
    enum class Angle {
        Front = 0,
        Right,
        Back,
        Left
    };

    float chase_distance = 700.0f;
    float chase_height = 200.0f;
    Angle chase_direction = Angle::Back;

    // Isometric camera mode state
    enum class IsometricAngle {
        FrontRight = 0,
        BackRight,
        BackLeft,
        FrontLeft,
    };

    float isometric_distance = 1000.0f;
    IsometricAngle isometric_direction = IsometricAngle::FrontRight;

    // Camera option mode state
    enum class OptionState {
        None = 0,
        Force
    };

    // Top-down camera mode state
    glm::vec2 topdown_offset{0.0f, 0.0f};
    float topdown_zoom = 1000.0f;

    // Camera constraints
    const float orbit_distance_min = 300.0f;
    const float orbit_distance_max = 1200.0f;
    const float flyby_height_min = 50.0f;
    const float flyby_height_max = 500.0f;
    const float chase_distance_min = 300.0f;
    const float chase_distance_max = 2000.0f;
    const float chase_height_min = 50.0f;
    const float chase_height_max = 500.0f;
    const float isometric_distance_min = 500.0f;
    const float isometric_distance_max = 3000.0f;
    const float topdown_zoom_min = 500.0f;
    const float topdown_zoom_max = 5000.0f;

    // Max ToT tracking distance
    glm::vec2 tot_pos;
    const float tot_max_distance = 6000.0f;
    const float tot_linger_period = 5.0f;
    float tot_linger_timer = 0.0f;

public:
    explicit CinematicViewScreen(RenderLayer* render_layer);
    virtual ~CinematicViewScreen();

    void setTargetTransform(sp::Transform* transform);
    void setMouselook(bool value);
    void updateCamera(sp::Transform* main_transform, sp::Transform* tot_transform, float delta);
    void updateOrbitCamera(sp::Transform* main_transform, sp::Transform* tot_transform, float delta);
    void updateFlybyCamera(sp::Transform* main_transform, sp::Transform* tot_transform, float delta, OptionState reposition);
    void updateChaseCamera(sp::Transform* main_transform, sp::Transform* tot_transform, float delta);
    void updateIsometricCamera(sp::Transform* main_transform, sp::Transform* tot_transform, float delta);
    void updateTopdownCamera(sp::Transform* main_transform, sp::Transform* tot_transform, float delta);

private:
    // Helper function to scale camera distances based on ship size (defaults tuned for radius 200)
    float getScaledCameraDistance(float base_distance) const;

    // ToT (Target of Target) helper functions
    bool updateToTState(sp::Transform* tot_transform, float delta);
    bool isToTActive(sp::Transform* tot_transform) const;
    bool isToTInRange(sp::Transform* tot_transform) const;
    glm::vec2 getMedianPoint() const;
    float getToTDistance() const;

    virtual void update(float delta) override;
    virtual bool onPointerMove(glm::vec2 position, sp::io::Pointer::ID id) override;
    virtual void onPointerUp(glm::vec2 position, sp::io::Pointer::ID id) override;
};
