#pragma once

#include "gui/gui2_element.h"
#include "glObjects.h"
#include "graphics/shader.h"
#include "systems/rendering.h"

#include <glm/mat4x4.hpp>
#include <glm/vec3.hpp>
#include <glm/vec4.hpp>

#include <algorithm>
#include <array>

class GuiViewport3D : public GuiElement
{
    bool show_callsigns = false;
    bool show_headings = false;
    bool show_spacedust = false;

    glm::mat4 projection_matrix;
    glm::mat4 view_matrix;

    float base_fov; // set by main_screen_camera_fov preference on init
    float fov_modifier = 0.0f;

protected:

    enum class Uniforms : uint8_t
    {
        Projection = 0,
        View,
        GlobalBox,
        LocalBox,
        BoxLerp,

        StarboxCount
    };

    enum class SpacedustUniforms : uint8_t
    {
        Projection = 0,
        Rotation,
        RotationPrevious,
        CameraPosition,
        BoxSize,
        CameraDelta,
        PixelSize,
        MinStreak,
        MaxStreak,
        NearFade,
        FarFade,
        FogColor,
        FogDistance,

        Count
    };

    enum class Buffers : uint8_t
    {
        Vertex = 0,

        SpacedustCount,

        Element = SpacedustCount,
        StarboxCount
    };

    enum class VertexAttributes : uint8_t
    {
        Position = 0,
        StarboxCount,

        Sign = StarboxCount,
        SpacedustCount
    };

    // Starbox
    std::array<uint32_t, static_cast<size_t>(Uniforms::StarboxCount)> starbox_uniforms;
    std::array<uint32_t, static_cast<size_t>(VertexAttributes::StarboxCount)> starbox_vertex_attributes;
    gl::Buffers<static_cast<size_t>(Buffers::StarboxCount)> starbox_buffers;
    sp::Shader* starbox_shader = nullptr;

    // Spacedust
    static constexpr size_t spacedust_particle_count = 2048;
    std::array<uint32_t, static_cast<size_t>(SpacedustUniforms::Count)> spacedust_uniforms;
    std::array<uint32_t, static_cast<size_t>(VertexAttributes::SpacedustCount)> spacedust_vertex_attributes;
    gl::Buffers<static_cast<size_t>(Buffers::SpacedustCount)> spacedust_buffer;
    sp::Shader* spacedust_shader = nullptr;
    glm::vec3 spacedust_last_camera_position{0.0f};
    float spacedust_last_camera_time = 0.0f;
    glm::mat4 spacedust_last_rotation{1.0f};
    bool spacedust_camera_history_valid = false;

public:
    GuiViewport3D(GuiContainer* owner, string id);

    virtual void onDraw(sp::RenderTarget& target) override;

    GuiViewport3D* setCallsignVisibility(bool is_visible) { show_callsigns = is_visible; return this; }
    bool areCallsignsVisible() const { return show_callsigns; }
    GuiViewport3D* showCallsigns() { return setCallsignVisibility(true); }
    GuiViewport3D* toggleCallsigns() { return setCallsignVisibility(!areCallsignsVisible()); }
    GuiViewport3D* showHeadings() { show_headings = true; return this; }
    GuiViewport3D* hideHeadings() { show_headings = false; return this; }
    GuiViewport3D* showSpacedust() { show_spacedust = true; return this; }
    GuiViewport3D* hideSpacedust() { show_spacedust = false; return this; }

    float getModifiedFoV() { return base_fov + fov_modifier; }
    float getFoVModifier() { return fov_modifier; }
    float getBaseFoV() { return base_fov; }

    // base_fov set by main_screen_camera_fov preference on Viewport init
    float modifyFoV(float modifier) { fov_modifier = std::clamp(base_fov + modifier, 30.0f, 140.0f) - base_fov; return fov_modifier; }
    void setProjectionType(ProjectionType type) { projection_type = type; }
    // Explicit orthographic half-height. Overrides the value derived from the
    // camera distance and field of view when greater than zero.
    void setOrthographicViewHeight(float half_height) { orthographic_view_height = std::max(half_height, 0.0f); }
    void setFarPlaneOverride(float distance) { far_plane_override = std::max(distance, 0.0f); }
    void setStarboxEnabled(bool enabled) { starbox_enabled = enabled; }
    void setFogEnabled(bool enabled) { fog_enabled = enabled; }
    void setIgnoreNebulaOcclusion(bool ignore) { ignore_nebula_occlusion = ignore; }
    void setBackgroundColor(glm::u8vec4 color) { background_color = color; clear_background = true; }
private:
    glm::vec3 worldToScreen(sp::RenderTarget& window, glm::vec3 world);

    ProjectionType projection_type = ProjectionType::Perspective;
    float orthographic_view_height = 0.0f;
    float far_plane_override = 0.0f;
    bool starbox_enabled = true;
    bool fog_enabled = true;
    bool ignore_nebula_occlusion = false;
    bool clear_background = false;
    glm::u8vec4 background_color{0, 0, 0, 255};
};
