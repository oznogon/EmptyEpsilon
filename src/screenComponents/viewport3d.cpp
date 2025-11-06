#include <graphics/opengl.h>
#include <ecs/query.h>

#include "main.h"
#include "playerInfo.h"
#include "gameGlobalInfo.h"
#include "viewport3d.h"
#include "tween.h"
#include "shaderManager.h"
#include "soundManager.h"
#include "textureManager.h"
#include "random.h"
#include "preferenceManager.h"
#include "particleEffect.h"
#include "glObjects.h"
#include "shaderRegistry.h"
#include "components/collision.h"
#include "components/target.h"
#include "components/hull.h"
#include "components/rendering.h"
#include "components/impulse.h"
#include "components/warpdrive.h"
#include "components/missile.h"
#include "components/name.h"
#include "components/zone.h"
#include "systems/rendering.h"
#include "math/centerOfMass.h"

#include <glm/glm.hpp>
#include <glm/ext/matrix_transform.hpp>
#include <glm/ext/matrix_clip_space.hpp>
#include <glm/gtc/type_ptr.hpp>


static std::unordered_map<string, std::unique_ptr<gl::CubemapTexture>> skybox_textures;


GuiViewport3D::GuiViewport3D(GuiContainer* owner, string id)
: GuiElement(owner, id), show_callsigns(false), show_headings(false), show_spacedust(false), use_particle_trails(false), camera_fov(PreferencesManager::get("main_screen_camera_fov", "60").toFloat())
{
    // Load up our starbox into a cubemap.
    // Setup shader.
    starbox_shader = ShaderManager::getShader("shaders/starbox");
    starbox_shader->bind();
    starbox_uniforms[static_cast<size_t>(Uniforms::Projection)] = starbox_shader->getUniformLocation("projection");
    starbox_uniforms[static_cast<size_t>(Uniforms::View)] = starbox_shader->getUniformLocation("view");
    starbox_uniforms[static_cast<size_t>(Uniforms::LocalBox)] = starbox_shader->getUniformLocation("local_starbox");
    starbox_uniforms[static_cast<size_t>(Uniforms::GlobalBox)] = starbox_shader->getUniformLocation("global_starbox");
    starbox_uniforms[static_cast<size_t>(Uniforms::BoxLerp)] = starbox_shader->getUniformLocation("starbox_lerp");

    starbox_vertex_attributes[static_cast<size_t>(VertexAttributes::Position)] = starbox_shader->getAttributeLocation("position");

    // Load up the ebo and vbo for the cube.
    /*   
           .2------6
         .' |    .'|
        3---+--7'  |
        |   |  |   |
        |  .0--+---4
        |.'    | .'
        1------5'
    */
    std::array<glm::vec3, 8> positions{
        // Left face
        glm::vec3{-1.f, -1.f, -1.f}, // 0
        glm::vec3{-1.f, -1.f, 1.f},  // 1
        glm::vec3{-1.f, 1.f, -1.f},  // 2
        glm::vec3{-1.f, 1.f, 1.f},   // 3

        // Right face
        glm::vec3{1.f, -1.f, -1.f},  // 4
        glm::vec3{1.f, -1.f, 1.f},   // 5
        glm::vec3{1.f, 1.f, -1.f},   // 6
        glm::vec3{1.f, 1.f, 1.f},    // 7
    };

    constexpr std::array<uint16_t, 6 * 6> elements{
        2, 6, 4, 4, 0, 2, // Back
        3, 2, 0, 0, 1, 3, // Left
        6, 7, 5, 5, 4, 6, // Right
        7, 3, 1, 1, 5, 7, // Front
        6, 2, 3, 3, 7, 6, // Top
        0, 4, 5, 5, 1, 0, // Bottom
    };

    // Upload to GPU.
    glBindBuffer(GL_ARRAY_BUFFER, starbox_buffers[static_cast<size_t>(Buffers::Vertex)]);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, starbox_buffers[static_cast<size_t>(Buffers::Element)]);

    glBufferData(GL_ARRAY_BUFFER, positions.size() * sizeof(glm::vec3), positions.data(), GL_STATIC_DRAW);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, elements.size() * sizeof(uint16_t), elements.data(), GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, GL_NONE);
    // Setup spacedust
    spacedust_shader = ShaderManager::getShader("shaders/spacedust");
    spacedust_shader->bind();
    spacedust_uniforms[static_cast<size_t>(Uniforms::Projection)] = spacedust_shader->getUniformLocation("projection");
    spacedust_uniforms[static_cast<size_t>(Uniforms::View)] = spacedust_shader->getUniformLocation("view");
    spacedust_uniforms[static_cast<size_t>(Uniforms::Rotation)] = spacedust_shader->getUniformLocation("rotation");

    spacedust_vertex_attributes[static_cast<size_t>(VertexAttributes::Position)] = spacedust_shader->getAttributeLocation("position");
    spacedust_vertex_attributes[static_cast<size_t>(VertexAttributes::Sign)] = spacedust_shader->getAttributeLocation("sign_value");

    // Reserve our GPU buffer.
    // Each dust particle consist of:
    // - a worldpace position (Vector3f)
    // - a sign value (single byte, passed as float).
    // Both "arrays" are maintained separate:
    // the signs are stable (they just tell us which "end" of the line we're on)
    // The positions will get updated more frequently.
    // It means each particle occupies 2*16B (assuming tight packing)
    glBindBuffer(GL_ARRAY_BUFFER, spacedust_buffer[0]);
    glBufferData(GL_ARRAY_BUFFER, 2 * spacedust_particle_count * (sizeof(glm::vec3) + sizeof(float)), nullptr, GL_DYNAMIC_DRAW);

    // Generate and update the alternating vertices signs.
    std::array<float, 2 * spacedust_particle_count> signs;
    
    for (auto n = 0U; n < signs.size(); n += 2)
    {
        signs[n] = -1.f;
        signs[n + 1] = 1.f;
    }

    // Update sign parts.
    glBufferSubData(GL_ARRAY_BUFFER, 2 * spacedust_particle_count * sizeof(glm::vec3), signs.size() * sizeof(float), signs.data());
    {
        // zero out positions.
        const std::vector<glm::vec3> zeroed_positions(2 * spacedust_particle_count);
        glBufferSubData(GL_ARRAY_BUFFER, 0, 2 * spacedust_particle_count * sizeof(glm::vec3), zeroed_positions.data());
    }
    glBindBuffer(GL_ARRAY_BUFFER, GL_NONE);

    // Setup engine trail shader
    trail_shader = ShaderManager::getShader("shaders/engineTrail");
    trail_shader->bind();
    trail_projection_uniform = trail_shader->getUniformLocation("projection");
    trail_view_uniform = trail_shader->getUniformLocation("view");
    trail_texture_uniform = trail_shader->getUniformLocation("texture");
    trail_position_attrib = trail_shader->getAttributeLocation("position");
    trail_color_attrib = trail_shader->getAttributeLocation("color");
    trail_texcoord_attrib = trail_shader->getAttributeLocation("texcoord");

    // Create and configure VAO for trail rendering to cache vertex attribute state
    glGenVertexArrays(1, &trail_vao);
    glBindVertexArray(trail_vao);

    // Bind buffers and configure vertex attributes
    glBindBuffer(GL_ARRAY_BUFFER, trail_buffers[0]);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, trail_buffers[1]);

    // Enable and configure vertex attributes
    glEnableVertexAttribArray(trail_position_attrib);
    glEnableVertexAttribArray(trail_color_attrib);
    glEnableVertexAttribArray(trail_texcoord_attrib);

    // Unbind VAO to avoid accidental modification
    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, GL_NONE);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, GL_NONE);
}

void GuiViewport3D::onDraw(sp::RenderTarget& renderer)
{
    if (rect.size.x == 0.f)
    {
        // The GUI ticks before Updatables.
        // When the 3D screen is on the side of a station,
        // and the window is resized in a way that will hide the main screen,
        // this leaves a *one frame* gap where the 3D gui element is 'visible' but will try to render
        // with a computed 0-width rect.
        // Since some gl calls don't really like an empty viewport, just ignore the draw.
        return;
    }
    renderer.finish();
   
    if (auto transform = my_spaceship.getComponent<sp::Transform>())
        soundManager->setListenerPosition(transform->getPosition(), transform->getRotation());
    else
        soundManager->setListenerPosition(glm::vec2(camera_position.x, camera_position.y), camera_yaw);
    
    glActiveTexture(GL_TEXTURE0);

    {
        auto p0 = renderer.virtualToPixelPosition(rect.position);
        auto p1 = renderer.virtualToPixelPosition(rect.position + rect.size);
        glViewport(p0.x, renderer.getPhysicalSize().y - p1.y, p1.x - p0.x, p1.y - p0.y);
    }
    if (GLAD_GL_ES_VERSION_2_0)
        glClearDepthf(1.f);
    else
        glClearDepth(1.f);

    glClear(GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    glFrontFace(GL_CCW);

    projection_matrix = glm::perspective(glm::radians(camera_fov), rect.size.x / rect.size.y, 1.f, 25000.f);

    // OpenGL standard: X across (left-to-right), Y up, Z "towards".
    view_matrix = glm::rotate(glm::identity<glm::mat4>(), glm::radians(90.0f), {1.f, 0.f, 0.f}); // -> X across (l-t-r), Y "towards", Z down 
    view_matrix = glm::scale(view_matrix, {1.f,1.f,-1.f});  // -> X across (l-t-r), Y "towards", Z up
    view_matrix = glm::rotate(view_matrix, glm::radians(-camera_pitch), {1.f, 0.f, 0.f});
    view_matrix = glm::rotate(view_matrix, glm::radians(-(camera_yaw + 90.f)), {0.f, 0.f, 1.f});

    // Translate camera
    view_matrix = glm::translate(view_matrix, -camera_position);

    // Draw starbox.
    glDepthMask(GL_FALSE);
    {
        starbox_shader->bind();
        glUniform1f(starbox_shader->getUniformLocation("scale"), 100.0f);

        string skybox_name = "skybox/default";
        if (gameGlobalInfo)
            skybox_name = "skybox/" + gameGlobalInfo->default_skybox;

        string local_skybox_name = skybox_name;
        float local_skybox_factor = 0.0f;
        for(auto [entity, zone, t] : sp::ecs::Query<Zone, sp::Transform>()) {
            if (zone.skybox.empty()) continue;

            auto pos = t.getPosition() - glm::vec2(camera_position.x, camera_position.y);
            if (insidePolygon(zone.outline, pos)) {
                local_skybox_name = "skybox/" + zone.skybox;
                if (zone.skybox_fade_distance <= 0)
                    local_skybox_factor = 1.0;
                else
                    local_skybox_factor = std::clamp(distanceToEdge(zone.outline, pos) / zone.skybox_fade_distance, 0.0f, 1.0f);
                break;
            }
        }

        auto skybox_texture = skybox_textures[skybox_name].get();
        if (!skybox_texture) {
            skybox_textures[skybox_name] = std::make_unique<gl::CubemapTexture>(skybox_name);
            skybox_texture = skybox_textures[skybox_name].get();
        }
        auto local_skybox_texture = skybox_textures[local_skybox_name].get();
        if (!local_skybox_texture) {
            skybox_textures[local_skybox_name] = std::make_unique<gl::CubemapTexture>(local_skybox_name);
            local_skybox_texture = skybox_textures[local_skybox_name].get();
        }

        // Setup shared state (uniforms)
        glUniform1i(starbox_uniforms[static_cast<size_t>(Uniforms::GlobalBox)], 0);
        glActiveTexture(GL_TEXTURE0);
        skybox_texture->bind();

        glUniform1i(starbox_uniforms[static_cast<size_t>(Uniforms::LocalBox)], 1);
        glActiveTexture(GL_TEXTURE1);
        local_skybox_texture->bind();

        glUniform1f(starbox_uniforms[static_cast<size_t>(Uniforms::BoxLerp)], local_skybox_factor);
        
        // Uniform
        // Upload matrices (only float 4x4 supported in es2)
        glUniformMatrix4fv(starbox_uniforms[static_cast<size_t>(Uniforms::Projection)], 1, GL_FALSE, glm::value_ptr(projection_matrix));
        glUniformMatrix4fv(starbox_uniforms[static_cast<size_t>(Uniforms::View)], 1, GL_FALSE, glm::value_ptr(view_matrix));
        
        // Bind our cube
        {
            gl::ScopedVertexAttribArray positions(starbox_vertex_attributes[static_cast<size_t>(VertexAttributes::Position)]);
            glBindBuffer(GL_ARRAY_BUFFER, starbox_buffers[static_cast<size_t>(Buffers::Vertex)]);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, starbox_buffers[static_cast<size_t>(Buffers::Element)]);

            // Vertex attributes.
            glVertexAttribPointer(positions.get(), 3, GL_FLOAT, GL_FALSE, sizeof(glm::vec3), (GLvoid*)0);

            glDrawElements(GL_TRIANGLES, 6 * 6, GL_UNSIGNED_SHORT, (GLvoid*)0);

            // Cleanup
            glBindBuffer(GL_ARRAY_BUFFER, GL_NONE);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, GL_NONE);
        }

        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_CUBE_MAP, GL_NONE);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_CUBE_MAP, GL_NONE);
    }
    glDepthMask(GL_TRUE);

    // Update view matrix in shaders.
    ShaderRegistry::updateProjectionView({}, view_matrix);

    RenderSystem render_system;
    render_system.render3D(rect.size.x / rect.size.y, camera_fov);

    if (PreferencesManager::get("use_particle_trails", "1") == "1")
    {
        // Emit engine particles.
        // TODO: DRY vs. polygonal
        for (auto [entity, ee, transform] : sp::ecs::Query<EngineEmitter, sp::Transform>())
        {
            auto warp = entity.getComponent<WarpDrive>();
            auto impulse = entity.getComponent<ImpulseEngine>();
            auto missile = entity.getComponent<MissileFlight>();
            if (!warp && !impulse && !missile) continue;

            const bool using_impulse = impulse && impulse->actual != 0.0f;
            const bool using_warp = warp && warp->current != 0.0f;
            float propulsion_actual = 0.0f;

            if (ee.velocity_override > 0.0f)
                propulsion_actual = ee.velocity_override;
            else if (using_impulse || using_warp)
            {
                if (using_impulse)
                    propulsion_actual = std::abs(impulse->actual) * impulse->getSystemEffectiveness();
                if (using_warp)
                    propulsion_actual = (warp->current / static_cast<float>(warp->max_level)) * warp->getSystemEffectiveness();
            }
            else if (missile)
                propulsion_actual = 1.0f;

            if (propulsion_actual != 0.0f && engine->getElapsedTime() - ee.last_engine_particle_time > 0.1f)
            {
                for (auto ed : ee.emitters)
                {
                    glm::vec3 offset = ed.position;
                    glm::vec2 pos2d = transform.getPosition() + rotateVec2(glm::vec2(offset.x, offset.y), transform.getRotation());
                    glm::vec3 color = ed.color;
                    glm::vec3 pos3d = glm::vec3(pos2d.x, pos2d.y, offset.z);
                    ParticleEngine::spawn(pos3d, pos3d, color, color, ed.scale, 0.0, 5.0);
                }

                ee.last_engine_particle_time = engine->getElapsedTime();
            }
        }

        // Render emitter particles
        ParticleEngine::render(projection_matrix, view_matrix);
    }
    else
    {
        // Prep EngineEmitter trail renderer
        std::vector<glm::vec3> all_vertices;
        std::vector<glm::vec3> all_colors;
        std::vector<glm::vec2> all_texcoords;
        std::vector<int> all_indices;

        // Extract camera position from view matrix for billboarding
        glm::mat4 inv_view = glm::inverse(view_matrix);
        glm::vec3 camera_world_pos = glm::vec3(inv_view[3]);

        const float current_time = engine->getElapsedTime();

        // TODO: DRY vs. particle
        for (auto [entity, ee, transform] : sp::ecs::Query<EngineEmitter, sp::Transform>())
        {
            auto warp = entity.getComponent<WarpDrive>();
            auto impulse = entity.getComponent<ImpulseEngine>();
            auto missile = entity.getComponent<MissileFlight>();
            if (!warp && !impulse && !missile) continue;

            const bool using_impulse = impulse && impulse->actual != 0.0f;
            const bool using_warp = warp && warp->current != 0.0f;
            float propulsion_actual = 0.0f;

            if (ee.velocity_override > 0.0f)
                propulsion_actual = ee.velocity_override;
            else if (using_impulse || using_warp)
            {
                if (using_impulse)
                    propulsion_actual = std::abs(impulse->actual) * impulse->getSystemEffectiveness();
                if (using_warp)
                    propulsion_actual = (warp->current / static_cast<float>(warp->max_level)) * warp->getSystemEffectiveness();
            }
            else if (missile)
                propulsion_actual = 1.0f;

            // Calculate distance-based sampling for smooth trails at all speeds
            bool should_add_point = false;

            if (ee.trail_history.empty())
                should_add_point = true;
            else
            {
                // Add point if moved at least 1 units
                const auto& last_point = ee.trail_history.back();
                float distance = glm::length(transform.getPosition() - last_point.position);
                if (distance > 1.0f) should_add_point = true;
            }

            // Update trail history
            if (should_add_point)
            {
                EngineEmitter::TrailPoint point;
                point.position = transform.getPosition();
                point.rotation = transform.getRotation();
                point.timestamp = current_time;
                ee.trail_history.push_back(point);
                ee.last_engine_particle_time = current_time;
            }

            // Remove old trail points based on time
            ee.trail_history.erase(
                std::remove_if(ee.trail_history.begin(), ee.trail_history.end(),
                    [current_time](const EngineEmitter::TrailPoint& p) {
                        return (current_time - p.timestamp) > EngineEmitter::trail_lifetime;
                    }),
                ee.trail_history.end()
            );

            // Build trail geometry for each emitter
            if (ee.trail_history.size() >= 2)
            {
                for (auto& ed : ee.emitters)
                {
                    // Whatever the emitter color is, the warp trail should be
                    // brighter.
                    glm::vec3 color = using_warp
                        ? ed.color * 1.2f
                        : ed.color;

                    // Render trail twice at different scales for bright center
                    // effect, if impulse is >80% engaged.
                    int exhaust_cones = propulsion_actual > 0.5f ? 2 : 1;

                    if (ed.trail_polygon.empty())
                    {
                        // Use billboarded quads for default trail (no polygon defined)
                        const float scale_multiplier = 1.0f;
                        const float scale_factor = ed.scale * std::min(1.0f, std::abs(propulsion_actual)) * scale_multiplier;

                        // Pre-calculate per-segment data that's shared across both axes
                        struct SegmentData {
                            glm::vec3 pos0, pos1;
                            glm::vec3 trail_color0, trail_color1;
                            float scale0, scale1;
                            glm::vec3 billboard_right_axis0;
                            glm::vec3 billboard_right_axis1;
                        };
                        std::vector<SegmentData> segment_cache;
                        segment_cache.reserve(ee.trail_history.size() - 1);

                        // Build segment cache with shared calculations
                        for (size_t i = 0; i < ee.trail_history.size() - 1; ++i)
                        {
                            const auto& point0 = ee.trail_history[i];
                            const auto& point1 = ee.trail_history[i + 1];

                            // Calculate age factors
                            const float age0 = current_time - point0.timestamp;
                            const float age1 = current_time - point1.timestamp;
                            const float age_factor0 = Tween<float>::easeInOutCubic(age0, 0.0f, EngineEmitter::trail_lifetime, 1.0f, 0.0f);
                            const float age_factor1 = Tween<float>::easeInOutCubic(age1, 0.0f, EngineEmitter::trail_lifetime, 1.0f, 0.0f);

                            // Calculate colors with temporal fade
                            glm::vec3 trail_color0 = Tween<glm::vec3>::easeOutCubic(age_factor0, 1.0f, 0.0f, color, glm::vec3{0.0f, 0.0f, 0.0f});
                            glm::vec3 trail_color1 = Tween<glm::vec3>::easeOutCubic(age_factor1, 1.0f, 0.0f, color, glm::vec3{0.0f, 0.0f, 0.0f});

                            // Calculate scales
                            float scale0 = scale_factor * age_factor0;
                            float scale1 = scale_factor * age_factor1;

                            // Apply emitter offset in entity space
                            glm::vec2 emitter_offset0 = rotateVec2(glm::vec2(ed.position.x, ed.position.y), point0.rotation);
                            glm::vec2 emitter_offset1 = rotateVec2(glm::vec2(ed.position.x, ed.position.y), point1.rotation);
                            glm::vec2 center0 = point0.position + emitter_offset0;
                            glm::vec2 center1 = point1.position + emitter_offset1;

                            glm::vec3 pos0 = glm::vec3(center0.x, center0.y, ed.position.z);
                            glm::vec3 pos1 = glm::vec3(center1.x, center1.y, ed.position.z);

                            // Calculate billboard directions once per segment
                            glm::vec3 segment_center = (pos0 + pos1) * 0.5f;
                            glm::vec3 to_camera = glm::normalize(camera_world_pos - segment_center);
                            glm::vec3 segment_dir = glm::normalize(pos1 - pos0);

                            // Pre-calculate both billboard axes
                            glm::vec3 billboard_right_axis0 = glm::normalize(glm::cross(segment_dir, to_camera));
                            glm::vec3 billboard_right_axis1 = glm::normalize(glm::cross(billboard_right_axis0, segment_dir));

                            segment_cache.push_back({pos0, pos1, trail_color0, trail_color1, scale0, scale1, billboard_right_axis0, billboard_right_axis1});
                        }

                        // Create two perpendicular billboarded trails using cached data
                        for (int trail_axis = 0; trail_axis < 2; ++trail_axis)
                        {
                            size_t vertex_base = all_vertices.size();

                            // Build billboarded quads along the trail
                            for (size_t i = 0; i < segment_cache.size(); ++i)
                            {
                                const auto& seg = segment_cache[i];

                                // Select the appropriate billboard direction for this axis
                                glm::vec3 billboard_right = (trail_axis == 0) ? seg.billboard_right_axis0 : seg.billboard_right_axis1;

                                // Create quad vertices (4 vertices per segment)
                                float half_width0 = seg.scale0 * 0.5f;
                                float half_width1 = seg.scale1 * 0.5f;

                                // Bottom-left
                                all_vertices.push_back(seg.pos0 - billboard_right * half_width0);
                                all_colors.push_back(seg.trail_color0);
                                all_texcoords.push_back(glm::vec2(0.0f, float(i) / segment_cache.size()));

                                // Bottom-right
                                all_vertices.push_back(seg.pos0 + billboard_right * half_width0);
                                all_colors.push_back(seg.trail_color0);
                                all_texcoords.push_back(glm::vec2(1.0f, float(i) / segment_cache.size()));

                                // Top-right
                                all_vertices.push_back(seg.pos1 + billboard_right * half_width1);
                                all_colors.push_back(seg.trail_color1);
                                all_texcoords.push_back(glm::vec2(1.0f, float(i + 1) / segment_cache.size()));

                                // Top-left
                                all_vertices.push_back(seg.pos1 - billboard_right * half_width1);
                                all_colors.push_back(seg.trail_color1);
                                all_texcoords.push_back(glm::vec2(0.0f, float(i + 1) / segment_cache.size()));

                                // Generate indices for this quad (two triangles)
                                int base = vertex_base + i * 4;
                                all_indices.push_back(base + 0);
                                all_indices.push_back(base + 1);
                                all_indices.push_back(base + 2);

                                all_indices.push_back(base + 0);
                                all_indices.push_back(base + 2);
                                all_indices.push_back(base + 3);
                            }
                        }
                    }
                    else
                    {
                        // Use polygon extrusion for custom trail shapes
                        const std::vector<glm::vec3>& polygon = ed.trail_polygon;
                        size_t points_per_segment = polygon.size();

                        // Pre-calculate per-point data shared across all scale passes
                        struct PointData {
                            glm::vec2 center;
                            glm::vec2 perp_dir;
                            glm::vec2 forward_dir;
                            glm::vec3 trail_color;
                            float age_factor;
                        };
                        std::vector<PointData> point_cache;
                        point_cache.reserve(ee.trail_history.size());

                        const float base_scale_factor = ed.scale * std::min(1.0f, std::abs(propulsion_actual));

                        // Build point cache
                        for (size_t i = 0; i < ee.trail_history.size(); ++i)
                        {
                            const auto& point = ee.trail_history[i];

                            // Calculate age factor
                            const float age = current_time - point.timestamp;
                            const float age_factor = Tween<float>::easeInOutCubic(age, 0.0f, EngineEmitter::trail_lifetime, 1.0f, 0.0f);

                            // Calculate color with temporal fade
                            glm::vec3 trail_color = Tween<glm::vec3>::easeOutCubic(age_factor, 1.0f, 0.0f, color, glm::vec3{0.0f, 0.0f, 0.0f});

                            // Apply emitter offset in entity space
                            glm::vec2 emitter_offset = rotateVec2(glm::vec2(ed.position.x, ed.position.y), point.rotation);
                            glm::vec2 center = point.position + emitter_offset;

                            // Pre-calculate rotation vectors
                            float perp_angle_rad = glm::radians(point.rotation + 90.0f);
                            glm::vec2 perp_dir = glm::vec2(cosf(perp_angle_rad), sinf(perp_angle_rad));
                            float forward_angle_rad = glm::radians(point.rotation);
                            glm::vec2 forward_dir = glm::vec2(cosf(forward_angle_rad), sinf(forward_angle_rad));

                            point_cache.push_back({center, perp_dir, forward_dir, trail_color, age_factor});
                        }

                        // Generate geometry for each scale pass using cached data
                        for (int scale_pass = 0; scale_pass < exhaust_cones; ++scale_pass)
                        {
                            float scale_multiplier = (scale_pass == 0) ? 1.0f : propulsion_actual - 0.5f;
                            size_t vertex_base = all_vertices.size();

                            // Extrude the polygon along the trail path using cached calculations
                            for (size_t i = 0; i < point_cache.size(); ++i)
                            {
                                const auto& pt = point_cache[i];

                                // Scale based on age factor and current pass multiplier
                                float scale = base_scale_factor * pt.age_factor * scale_multiplier;

                                // Transform each polygon point to world space
                                for (const auto& poly_point : polygon)
                                {
                                    glm::vec2 world_pos = pt.center +
                                                          pt.perp_dir * (poly_point.y * scale) +
                                                          pt.forward_dir * (poly_point.x * scale);

                                    float world_z = ed.position.z + poly_point.z * scale;

                                    all_vertices.push_back(glm::vec3(world_pos.x, world_pos.y, world_z));
                                    all_colors.push_back(pt.trail_color);
                                    // Hacky: For custom polygons, sample the
                                    // center of the texture, which should be
                                    // bright/opaque
                                    all_texcoords.push_back(glm::vec2(0.5f, 0.5f));
                                }
                            }

                            // Generate triangle indices for polygon extrusion
                            for (size_t i = 0; i < point_cache.size() - 1; ++i)
                            {
                                for (size_t j = 0; j < points_per_segment; ++j)
                                {
                                    size_t next_j = (j + 1) % points_per_segment;
                                    size_t base0 = vertex_base + i * points_per_segment;
                                    size_t base1 = vertex_base + (i + 1) * points_per_segment;

                                    // Two triangles per quad segment
                                    all_indices.push_back(base0 + j);
                                    all_indices.push_back(base1 + j);
                                    all_indices.push_back(base0 + next_j);

                                    all_indices.push_back(base0 + next_j);
                                    all_indices.push_back(base1 + j);
                                    all_indices.push_back(base1 + next_j);
                                }
                            }
                        }
                    }
                }
            }
        }

        // Render all trails in a single batched draw call
        if (!all_indices.empty())
        {
            // Setup OpenGL state for trail rendering
            glEnable(GL_DEPTH_TEST);
            glDisable(GL_CULL_FACE);
            glDepthMask(GL_FALSE);
            glEnable(GL_BLEND);
            // Additive blending
            glBlendFunc(GL_ONE, GL_ONE);
            // Alpha blending
            // glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

            trail_shader->bind();
            glUniformMatrix4fv(trail_projection_uniform, 1, GL_FALSE, glm::value_ptr(projection_matrix));
            glUniformMatrix4fv(trail_view_uniform, 1, GL_FALSE, glm::value_ptr(view_matrix));

            // Bind trail texture
            glActiveTexture(GL_TEXTURE0);
            textureManager.getTexture("particle.png")->bind();
            glUniform1i(trail_texture_uniform, 0);

            // Bind VAO - restores vertex attribute enabled state automatically
            glBindVertexArray(trail_vao);

            // Upload vertex data to GPU buffer
            glBindBuffer(GL_ARRAY_BUFFER, trail_buffers[0]);
            size_t vertex_size = all_vertices.size() * sizeof(glm::vec3);
            size_t color_size = all_colors.size() * sizeof(glm::vec3);
            size_t texcoord_size = all_texcoords.size() * sizeof(glm::vec2);
            glBufferData(GL_ARRAY_BUFFER, vertex_size + color_size + texcoord_size, nullptr, GL_STREAM_DRAW);
            glBufferSubData(GL_ARRAY_BUFFER, 0, vertex_size, all_vertices.data());
            glBufferSubData(GL_ARRAY_BUFFER, vertex_size, color_size, all_colors.data());
            glBufferSubData(GL_ARRAY_BUFFER, vertex_size + color_size, texcoord_size, all_texcoords.data());

            // Upload index data to element buffer
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, trail_buffers[1]);
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, all_indices.size() * sizeof(unsigned int), all_indices.data(), GL_STREAM_DRAW);

            // Update vertex attribute pointers (VAO already has attributes enabled)
            glVertexAttribPointer(trail_position_attrib, 3, GL_FLOAT, GL_FALSE, 0, (void*)0);
            glVertexAttribPointer(trail_color_attrib, 3, GL_FLOAT, GL_FALSE, 0, (void*)vertex_size);
            glVertexAttribPointer(trail_texcoord_attrib, 2, GL_FLOAT, GL_FALSE, 0, (void*)(vertex_size + color_size));

            glDrawElements(GL_TRIANGLES, all_indices.size(), GL_UNSIGNED_INT, (void*)0);

            // Unbind VAO
            glBindVertexArray(0);

            // Render emitter particles
            ParticleEngine::render(projection_matrix, view_matrix);

            // Restore OpenGL state
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            glDisable(GL_BLEND);
            glDepthMask(GL_TRUE);
        }
    }

    if (show_spacedust && my_spaceship)
    {
        auto transform = my_spaceship.getComponent<sp::Transform>();
        auto physics = my_spaceship.getComponent<sp::Physics>();
        static std::vector<glm::vec3> space_dust(2 * spacedust_particle_count);
        
        glm::vec2 dust_vector = physics ? (physics->getVelocity() / 100.f) : glm::vec2{0, 0};
        glm::vec3 dust_center = transform ? glm::vec3(transform->getPosition().x, transform->getPosition().y, 0.f) : camera_position;

        constexpr float maxDustDist = 500.f;
        constexpr float minDustDist = 100.f;
        
        bool update_required = false; // Do we need to update the GPU buffer?

        for (auto n = 0U; n < space_dust.size(); n += 2)
        {
            auto delta = space_dust[n] - dust_center;
            if (glm::length2(delta) > maxDustDist*maxDustDist || glm::length2(delta) < minDustDist*minDustDist)
            {
                update_required = true;
                space_dust[n] = dust_center + glm::vec3(random(-maxDustDist, maxDustDist), random(-maxDustDist, maxDustDist), random(-maxDustDist, maxDustDist));
                space_dust[n + 1] = space_dust[n];
            }
        }

        spacedust_shader->bind();

        // Upload matrices (only float 4x4 supported in es2)
        glUniformMatrix4fv(spacedust_uniforms[static_cast<size_t>(Uniforms::Projection)], 1, GL_FALSE, glm::value_ptr(projection_matrix));
        glUniformMatrix4fv(spacedust_uniforms[static_cast<size_t>(Uniforms::View)], 1, GL_FALSE, glm::value_ptr(view_matrix));

        // Ship information for flying particles
        glUniform2f(spacedust_shader->getUniformLocation("velocity"), dust_vector.x, dust_vector.y);
        
        {
            gl::ScopedVertexAttribArray positions(spacedust_vertex_attributes[static_cast<size_t>(VertexAttributes::Position)]);
            gl::ScopedVertexAttribArray signs(spacedust_vertex_attributes[static_cast<size_t>(VertexAttributes::Sign)]);
            glBindBuffer(GL_ARRAY_BUFFER, spacedust_buffer[0]);
            
            if (update_required)
                glBufferSubData(GL_ARRAY_BUFFER, 0, space_dust.size() * sizeof(glm::vec3), space_dust.data());

            glVertexAttribPointer(positions.get(), 3, GL_FLOAT, GL_FALSE, sizeof(glm::vec3), (GLvoid*)0);
            glVertexAttribPointer(signs.get(), 1, GL_FLOAT, GL_FALSE, 0, (GLvoid*)(2 * spacedust_particle_count * sizeof(glm::vec3)));
            
            glDrawArrays(GL_LINES, 0, 2 * spacedust_particle_count);
            glBindBuffer(GL_ARRAY_BUFFER, GL_NONE);
        }
    }

    auto target_comp = my_spaceship.getComponent<Target>();
    if (target_comp && target_comp->entity)
    {
        ShaderRegistry::ScopedShader billboard(ShaderRegistry::Shaders::Billboard);

        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glDisable(GL_DEPTH_TEST);
        glm::mat4 model_matrix = glm::identity<glm::mat4>();
        if (auto transform = target_comp->entity.getComponent<sp::Transform>())
            model_matrix = glm::translate(model_matrix, glm::vec3(transform->getPosition(), 0.f));

        textureManager.getTexture("redicule2.png")->bind();
        glUniformMatrix4fv(billboard.get().uniform(ShaderRegistry::Uniforms::Model), 1, GL_FALSE, glm::value_ptr(model_matrix));
        float radius = 300.0f;
        if (auto physics = target_comp->entity.getComponent<sp::Physics>())
            radius = physics->getSize().x;
        glUniform4f(billboard.get().uniform(ShaderRegistry::Uniforms::Color), .5f, .5f, .5f, radius * 2.5f);
        {
            gl::ScopedVertexAttribArray positions(billboard.get().attribute(ShaderRegistry::Attributes::Position));
            gl::ScopedVertexAttribArray texcoords(billboard.get().attribute(ShaderRegistry::Attributes::Texcoords));
            auto vertices = {
                0.f, 0.f, 0.f,
                0.f, 0.f, 0.f,
                0.f, 0.f, 0.f,
                0.f, 0.f, 0.f
            };
            glVertexAttribPointer(positions.get(), 3, GL_FLOAT, GL_FALSE, 0, (GLvoid*)vertices.begin());
            auto coords = {
                0.f, 1.f,
                1.f, 1.f,
                1.f, 0.f,
                0.f, 0.f
            };
            glVertexAttribPointer(texcoords.get(), 2, GL_FLOAT, GL_FALSE, 0, (GLvoid*)coords.begin());
            std::initializer_list<uint16_t> indices{ 0, 2, 1, 0, 3, 2 };
            glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, std::begin(indices));
        }
    }

    glDepthMask(true);
    glDisable(GL_BLEND);
    glEnable(GL_CULL_FACE);
/*
#ifdef DEBUG
    glDisable(GL_DEPTH_TEST);
    
    {
        ShaderRegistry::ScopedShader debug_shader(ShaderRegistry::Shaders::BasicColor);
        // Common state: color, projection matrix.
        glUniform4f(debug_shader.get().uniform(ShaderRegistry::Uniforms::Color), 1.f, 1.f, 1.f, 1.f);

        std::array<float, 16> matrix;
        glUniformMatrix4fv(debug_shader.get().uniform(ShaderRegistry::Uniforms::Projection), 1, GL_FALSE, glm::value_ptr(projection_matrix));

        std::vector<glm::vec3> points;
        gl::ScopedVertexAttribArray positions(debug_shader.get().attribute(ShaderRegistry::Attributes::Position));

        foreach(SpaceObject, obj, space_object_list)
        {
            glPushMatrix();
            glTranslatef(-camera_position.x, -camera_position.y, -camera_position.z);
            glTranslatef(obj->getPosition().x, obj->getPosition().y, 0);
            glRotatef(obj->getRotation(), 0, 0, 1);

            glGetFloatv(GL_MODELVIEW_MATRIX, matrix.data());
            glUniformMatrix4fv(debug_shader.get().uniform(ShaderRegistry::Uniforms::ModelView), 1, GL_FALSE, matrix.data());

            auto collisionShape = obj->getCollisionShape();

            if (collisionShape.size() > points.size())
            {
                points.resize(collisionShape.size());
                glVertexAttribPointer(positions.get(), 3, GL_FLOAT, GL_FALSE, sizeof(glm::vec3), points.data());
            }

            for (unsigned int n = 0; n < collisionShape.size(); n++)
                points[n] = glm::vec3(collisionShape[n].x, collisionShape[n].y, 0.f);
            
            glDrawArrays(GL_LINE_LOOP, 0, collisionShape.size());
            glPopMatrix();
        }
    }
#endif
*/
    glDisable(GL_CULL_FACE);
    glDisable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    if (show_callsigns)
    {
        for(auto [entity, callsign, transform] : sp::ecs::Query<CallSign, sp::Transform>())
        {
            if (entity == my_spaceship)
                continue;
            float radius = 300.0f;
            if (auto physics = entity.getComponent<sp::Physics>())
                radius = physics->getSize().x;
            glm::vec3 screen_position = worldToScreen(renderer, glm::vec3(transform.getPosition().x, transform.getPosition().y, radius));
            if (screen_position.z < 0.0f)
                continue;
            if (screen_position.z > 10000.0f)
                continue;
            float distance_factor = 1.0f - (screen_position.z / 10000.0f);
            renderer.drawText(sp::Rect(screen_position.x, screen_position.y, 0, 0), callsign.callsign, sp::Alignment::Center, 20 * distance_factor, bold_font, glm::u8vec4(255, 255, 255, 128 * distance_factor));
        }
    }

    if (show_headings && my_spaceship)
    {
        float distance = 2500.f;
        auto transform = my_spaceship.getComponent<sp::Transform>();

        if (transform) {
            for(int angle = 0; angle < 360; angle += 30)
            {
                glm::vec2 world_pos = transform->getPosition() + vec2FromAngle(angle - 90.f) * distance;
                glm::vec3 screen_pos = worldToScreen(renderer, glm::vec3(world_pos.x, world_pos.y, 0.0f));
                if (screen_pos.z > 0.0f)
                    renderer.drawText(sp::Rect(screen_pos.x, screen_pos.y, 0, 0), string(angle), sp::Alignment::Center, 30, bold_font, glm::u8vec4(255, 255, 255, 128));
            }
        }
    }

    glViewport(0, 0, renderer.getPhysicalSize().x, renderer.getPhysicalSize().y);
}

glm::vec3 GuiViewport3D::worldToScreen(sp::RenderTarget& renderer, glm::vec3 world)
{
    auto view_pos = view_matrix * glm::vec4(world, 1.f);
    auto pos = projection_matrix * view_pos;

    // Perspective division
    pos /= pos.w;

    //Window coordinates
    //Map x, y to range 0-1
    glm::vec3 ret;
    ret.x = pos.x * .5f + .5f;
    ret.y = pos.y * .5f + .5f;
    //This is only correct when glDepthRange(0.0, 1.0)
    //ret.z = (1.0+fTempo[6])*0.5;  //Between 0 and 1
    //Set Z to distance into the screen (negative is behind the screen)
    ret.z = -view_pos.z;

    ret.x = rect.position.x + rect.size.x * ret.x;
    ret.y = rect.position.y + rect.size.y * (1.0f - ret.y);
    return ret;
}
