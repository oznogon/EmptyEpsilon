#pragma once

#include "gui/gui2_element.h"
#include "glObjects.h"
#include "graphics/shader.h"

#include <glm/mat4x4.hpp>
#include <glm/vec4.hpp>

class GuiViewport3D : public GuiElement
{
    bool show_callsigns;
    bool show_headings;
    bool show_spacedust;
    bool use_particle_trails;
    float camera_fov;

    glm::mat4 projection_matrix;
    glm::mat4 view_matrix;

    enum class Uniforms : uint8_t
    {
        Projection = 0,
        View,
        GlobalBox,
        LocalBox,
        BoxLerp,

        StarboxCount,

        Rotation = StarboxCount,

        SpacedustCount
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
    static constexpr size_t spacedust_particle_count = 1024;
    std::array<uint32_t, static_cast<size_t>(Uniforms::SpacedustCount)> spacedust_uniforms;
    std::array<uint32_t, static_cast<size_t>(VertexAttributes::SpacedustCount)> spacedust_vertex_attributes;
    gl::Buffers<static_cast<size_t>(Buffers::SpacedustCount)> spacedust_buffer;
    sp::Shader* spacedust_shader = nullptr;

    // Engine trail
    sp::Shader* trail_shader = nullptr;
    uint32_t trail_projection_uniform;
    uint32_t trail_view_uniform;
    uint32_t trail_texture_uniform;
    uint32_t trail_position_attrib;
    uint32_t trail_color_attrib;
    uint32_t trail_texcoord_attrib;
    gl::Buffers<2> trail_buffers; // [0] = vertex/color/texcoord data, [1] = element indices
    uint32_t trail_vao = 0; // Vertex Array Object to cache attribute state
    inline static const std::vector<glm::vec3> default_trail_polygon = {{0.0f, -0.5f, 0.0f}, {0.0f, 0.5f, 0.0f}};

public:
    GuiViewport3D(GuiContainer* owner, string id);

    virtual void onDraw(sp::RenderTarget& target) override;

    GuiViewport3D* showCallsigns() { show_callsigns = true; return this; }
    GuiViewport3D* toggleCallsigns() { show_callsigns = !show_callsigns; return this; }
    GuiViewport3D* showHeadings() { show_headings = true; return this; }
    GuiViewport3D* showSpacedust() { show_spacedust = true; return this; }
private:
    glm::vec3 worldToScreen(sp::RenderTarget& window, glm::vec3 world);
};
