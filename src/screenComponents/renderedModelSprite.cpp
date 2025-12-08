#include <graphics/opengl.h>

#include "engine.h"
#include "featureDefs.h"
#include "renderedModelSprite.h"

#include "textureManager.h"

#include "glObjects.h"
#include "shaderRegistry.h"
#include "systems/rendering.h"

#include <array>

#include <glm/glm.hpp>
#include <glm/ext/matrix_transform.hpp>
#include <glm/ext/matrix_clip_space.hpp>
#include <glm/gtc/type_ptr.hpp>

GuiRenderedModelSprite::GuiRenderedModelSprite(GuiContainer* owner, string id, sp::ecs::Entity& entity)
: GuiElement(owner, id), entity(entity), zoom_factor(1.0f), height(-1.f), angle(90.f), needs_rerender(true), last_render_size(0, 0)
{
}

bool GuiRenderedModelSprite::renderToTexture(glm::ivec2 size)
{
    if (rect.size.x <= 0) return false;
    if (rect.size.y <= 0) return false;

    auto mrc = entity.getComponent<MeshRenderComponent>();
    if (!mrc) return false;

    // Create or resize render texture if needed
    if (!render_texture || render_texture->getSize() != size)
    {
        render_texture = std::make_unique<sp::RenderTexture>(size);

        // Set texture parameters to prevent edge artifacts
        render_texture->bind();
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }

    // Activate the render texture
    if (!render_texture->activateRenderTarget())
    {
        LOG(Error, "Failed to activate render texture");
        return false;
    }

    // Set up viewport for the render texture size
    glViewport(0, 0, size.x, size.y);

    // Configure OpenGL state for 3D rendering with transparent background
    if (GLAD_GL_ES_VERSION_2_0)
        glClearDepthf(1.f);
    else
        glClearDepth(1.0);

    // Clear with transparent background - important to clear the entire buffer
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    glFrontFace(GL_CCW);

    auto mesh_radius = mrc->getMesh()->greatest_distance_from_center * mrc->scale;
    float mesh_diameter = mesh_radius * 2.f;
    float near_clip_boundary = 1.f;

    float camera_fov = 60.0f;
    auto projection_matrix = glm::perspective(glm::radians(camera_fov), float(size.x) / float(size.y), near_clip_boundary, 25000.f);
    float view_distance = zoom_factor * (mesh_diameter / glm::tan(glm::radians(camera_fov / 2.f)));

    // OpenGL standard: X across (left-to-right), Y up, Z "towards".
    auto view_matrix = glm::rotate(glm::identity<glm::mat4>(), glm::radians(90.f), glm::vec3(1.f, 0.f, 0.f));
    view_matrix = glm::scale(view_matrix, glm::vec3(1.f, 1.f, -1.f));
    // TODO: This could be better
    if (height)
        view_matrix = glm::translate(view_matrix, glm::vec3(0.f, height, height));
    view_matrix = glm::translate(view_matrix, glm::vec3(0.f, -1.f * view_distance - near_clip_boundary, 0.f));
    view_matrix = glm::rotate(view_matrix, glm::radians(-30.f), glm::vec3(1.f, 0.f, 0.f));
    if (angle)
        view_matrix = glm::rotate(view_matrix, glm::radians(angle), glm::vec3(0.f, 0.f, 1.f));

    glDisable(GL_BLEND);
    glBindTexture(GL_TEXTURE_2D, 0);
    glEnable(GL_DEPTH_TEST);

    ShaderRegistry::updateProjectionView(projection_matrix, view_matrix);

    auto model_matrix = calculateModelMatrix(glm::vec2{}, 0.f, mrc->mesh_offset, mrc->scale);

    auto shader = lookUpShader(*mrc);
    glUniformMatrix4fv(shader.get().uniform(ShaderRegistry::Uniforms::Model), 1, GL_FALSE, glm::value_ptr(model_matrix));

    auto modeldata_matrix = glm::rotate(model_matrix, glm::radians(180.f), {0.f, 0.f, 1.f});
    modeldata_matrix = glm::scale(modeldata_matrix, glm::vec3{mrc->scale});

    // Lights setup.
    ShaderRegistry::setupLights(shader.get(), modeldata_matrix);

    // Textures
    activateAndBindMeshTextures(*mrc);

    // Draw
    drawMesh(*mrc, shader);

    // Restore OpenGL state to what the 2D renderer expects
    glDisable(GL_CULL_FACE);
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_STENCIL_TEST);
    glDisable(GL_SCISSOR_TEST);
    glDepthMask(GL_TRUE);
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    // Restore clear color to default
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);

    // Deactivate render target (return to default framebuffer)
    glBindFramebuffer(GL_FRAMEBUFFER, 0);

    // Unbind any textures we might have bound, and reset all texture units
    for (int i = 0; i < 8; i++) {
        glActiveTexture(GL_TEXTURE0 + i);
        glBindTexture(GL_TEXTURE_2D, 0);
    }
    glActiveTexture(GL_TEXTURE0);

    // Reset ShaderRegistry to 2D state (empty matrices for 2D rendering)
    ShaderRegistry::updateProjectionView({}, {});

    return true;
}

void GuiRenderedModelSprite::onDraw(sp::RenderTarget& renderer)
{
    if (rect.size.x <= 0) return;
    if (rect.size.y <= 0) return;

    auto mrc = entity.getComponent<MeshRenderComponent>();
    if (!mrc) return;

    // Calculate desired texture size based on rect size in pixels
    auto p0 = renderer.virtualToPixelPosition(rect.position);
    auto p1 = renderer.virtualToPixelPosition(rect.position + rect.size);
    glm::ivec2 pixel_size(p1.x - p0.x, p1.y - p0.y);

    // Clamp to reasonable size
    pixel_size.x = std::max(1, std::min(pixel_size.x, 2048));
    pixel_size.y = std::max(1, std::min(pixel_size.y, 2048));

    // Re-render if size changed or flagged for rerender
    if (needs_rerender || pixel_size != last_render_size)
    {
        renderer.finish(); // Flush any pending 2D rendering
        bool render_success = renderToTexture(pixel_size);
        last_render_size = pixel_size;

        // Restore viewport after rendering to texture
        glViewport(0, 0, renderer.getPhysicalSize().x, renderer.getPhysicalSize().y);

        // If render failed, don't try to draw
        if (!render_success)
            return;
    }

    // Draw the rendered texture as a sprite
    if (render_texture)
    {
        // Flush any pending 2D rendering before drawing our custom buffer
        renderer.finish();

        // Create vertex data for a textured quad
        std::vector<sp::RenderTarget::VertexData> vertex_data;
        std::vector<uint16_t> index_data;

        glm::u8vec4 color(255, 255, 255, 255);

        // Define the quad vertices (two triangles)
        // Note: UV coordinates are flipped vertically (1.0 - v) because framebuffer Y is inverted
        vertex_data.push_back({rect.position, color, {0.0f, 1.0f}});                                  // Top-left
        vertex_data.push_back({{rect.position.x + rect.size.x, rect.position.y}, color, {1.0f, 1.0f}}); // Top-right
        vertex_data.push_back({{rect.position.x, rect.position.y + rect.size.y}, color, {0.0f, 0.0f}}); // Bottom-left
        vertex_data.push_back({rect.position + rect.size, color, {1.0f, 0.0f}});                      // Bottom-right

        // Define indices for two triangles forming a quad
        index_data = {0, 1, 2, 1, 3, 2};

        // Use applyBuffer to draw with our RenderTexture
        renderer.applyBuffer(render_texture.get(), vertex_data, index_data, GL_TRIANGLES);

        // Ensure buffers are unbound to not affect subsequent rendering
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        glBindTexture(GL_TEXTURE_2D, 0);
    }
}

void GuiRenderedModelSprite::setCameraZoomFactor(float new_factor)
{
    float new_zoom = std::max(0.1f, new_factor);
    if (zoom_factor != new_zoom)
    {
        zoom_factor = new_zoom;
        needs_rerender = true;
    }
}

void GuiRenderedModelSprite::setCameraRotation(float new_angle)
{
    // Validate angle
    float normalized_angle = std::fmod(new_angle, 360.0f);
    if (normalized_angle < 0.0f) normalized_angle += 360.0f;

    if (angle != normalized_angle)
    {
        angle = normalized_angle;
        needs_rerender = true;
    }
}

void GuiRenderedModelSprite::setCameraHeight(float new_height)
{
    if (height != new_height)
    {
        height = new_height;
        needs_rerender = true;
    }
}
