#include <graphics/opengl.h>
#include <ecs/query.h>

#include "main.h"
#include "playerInfo.h"
#include "gameGlobalInfo.h"
#include "viewport3d.h"
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
#include "components/name.h"
#include "components/zone.h"
#include "components/beamweapon.h"
#include "components/utilityBeam.h"
#include "components/shields.h"
#include "systems/rendering.h"
#include "math/centerOfMass.h"
#include "tween.h"
#include "dynamicLight.h"

#include <glm/glm.hpp>
#include <glm/ext/matrix_transform.hpp>
#include <glm/ext/matrix_clip_space.hpp>
#include <glm/gtc/type_ptr.hpp>
#include <algorithm>


static std::unordered_map<string, std::unique_ptr<gl::CubemapTexture>> skybox_textures;


GuiViewport3D::GuiViewport3D(GuiContainer* owner, string id)
: GuiElement(owner, id)
{
    base_fov = PreferencesManager::get("main_screen_camera_fov", "60").toFloat();
    // Guard against invalid pref values.
    if (base_fov == 0.0f) base_fov = 60.0f;
    // Clamp base field of vision to 30-140 deg. range.
    base_fov = std::clamp(base_fov, 30.0f, 140.0f);

    // Load up our starbox into a cubemap.
    // Setup shader.
    starbox_shader = ShaderManager::getShader("shaders/starbox");
    starbox_shader->bind();
    starbox_uniforms[static_cast<size_t>(Uniforms::Projection)] = starbox_shader->getUniformLocation("u_projection");
    starbox_uniforms[static_cast<size_t>(Uniforms::View)] = starbox_shader->getUniformLocation("u_view");
    starbox_uniforms[static_cast<size_t>(Uniforms::LocalBox)] = starbox_shader->getUniformLocation("u_local_starbox");
    starbox_uniforms[static_cast<size_t>(Uniforms::GlobalBox)] = starbox_shader->getUniformLocation("u_global_starbox");
    starbox_uniforms[static_cast<size_t>(Uniforms::BoxLerp)] = starbox_shader->getUniformLocation("u_starbox_lerp");

    starbox_vertex_attributes[static_cast<size_t>(VertexAttributes::Position)] = starbox_shader->getAttributeLocation("a_position");

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
    spacedust_uniforms[static_cast<size_t>(Uniforms::Projection)] = spacedust_shader->getUniformLocation("u_projection");
    spacedust_uniforms[static_cast<size_t>(Uniforms::View)] = spacedust_shader->getUniformLocation("u_view");
    spacedust_uniforms[static_cast<size_t>(Uniforms::Rotation)] = spacedust_shader->getUniformLocation("u_rotation");

    spacedust_vertex_attributes[static_cast<size_t>(VertexAttributes::Position)] = spacedust_shader->getAttributeLocation("a_position");
    spacedust_vertex_attributes[static_cast<size_t>(VertexAttributes::Sign)] = spacedust_shader->getAttributeLocation("a_sign_value");

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

    float camera_fov = std::clamp(base_fov + fov_modifier, 30.0f, 140.0f);
    {
        auto p0 = renderer.virtualToPixelPosition(rect.position);
        auto p1 = renderer.virtualToPixelPosition(rect.position + rect.size);
        glViewport(p0.x, renderer.getPhysicalSize().y - p1.y, p1.x - p0.x, p1.y - p0.y);
    }
    if (GLAD_GL_ES_VERSION_2_0)
        glClearDepthf(1.f);
    else
        glClearDepth(1.0);

    glClear(GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

    // Collect all nebula data in a single pass for fog + skybox computation
    struct NebulaInfo {
        glm::vec2 position;
        float radius;
        float skybox_fade_distance;
        string skybox;
        glm::vec3 fog_color;
        float visibility_distance;
    };
    std::vector<NebulaInfo> nebula_infos;
    glm::vec2 camera_pos2{ camera_position.x, camera_position.y };
    for (auto [entity, nr, t] : sp::ecs::Query<NebulaRenderer, sp::Transform>())
    {
        nebula_infos.push_back({
            t.getPosition(),
            nr.radius,
            nr.skybox_fade_distance,
            nr.skybox,
            nr.fog_color,
            nr.visibility_distance
        });
    }

    // Compute nebula fog factor for smooth draw distance and fog transitions
    float default_draw_distance = PreferencesManager::get("default_draw_distance", "25000").toFloat();
    float nebula_fog_factor = 0.0f;
    glm::vec3 nebula_fog_color = glm::vec3{0.0f};
    float in_nebula_visibility_distance = default_draw_distance;
    float effective_fog_distance = 0.0f;
    if (PreferencesManager::get("nebula_fog", "1") == "1")
    {
        for (const auto& info : nebula_infos)
        {
            float dist = glm::length(info.position - camera_pos2);
            float fade_zone = info.skybox_fade_distance > 0.0f ? info.skybox_fade_distance : 1000.0f;
            float transition_start = info.radius + 1.5f * fade_zone;
            float transition_end = info.radius - 0.5f * fade_zone;
            float transition_range = transition_start - transition_end;
            if (dist <= transition_start)
            {
                float influence = std::clamp((transition_start - dist) / transition_range, 0.0f, 1.0f);
                if (influence > nebula_fog_factor)
                {
                    nebula_fog_factor = influence;
                    nebula_fog_color = info.fog_color;
                    in_nebula_visibility_distance = std::max(0.0f, info.visibility_distance);
                }
            }
        }
        effective_fog_distance = glm::mix(default_draw_distance, in_nebula_visibility_distance, nebula_fog_factor);
    }
    float far_plane = glm::mix(default_draw_distance, in_nebula_visibility_distance, nebula_fog_factor);

    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    glFrontFace(GL_CCW);

    if (projection_type == ProjectionType::Orthographic)
    {
        // Calculate orthographic bounds based on camera height and FOV
        float reference_distance = std::max(100.0f, camera_position.z);
        float height = reference_distance * glm::tan(glm::radians(camera_fov / 2.0f));
        float width = height * (rect.size.x / rect.size.y);
        projection_matrix = glm::ortho(-width, width, -height, height, 1.f, far_plane);
    }
    else
        projection_matrix = glm::perspective(glm::radians(camera_fov), rect.size.x / rect.size.y, 1.f, far_plane);

    // OpenGL standard: X across (left-to-right), Y up, Z "towards".
    view_matrix = glm::rotate(glm::identity<glm::mat4>(), glm::radians(90.0f), {1.f, 0.f, 0.f}); // -> X across (l-t-r), Y "towards", Z down
    view_matrix = glm::scale(view_matrix, {1.f,1.f,-1.f});  // -> X across (l-t-r), Y "towards", Z up
    view_matrix = glm::rotate(view_matrix, glm::radians(-camera_roll), {0.f, 1.f, 0.f}); // Roll first, around Y (forward)
    view_matrix = glm::rotate(view_matrix, glm::radians(-camera_pitch), {1.f, 0.f, 0.f}); // Then pitch around X
    view_matrix = glm::rotate(view_matrix, glm::radians(-(camera_yaw + 90.f)), {0.f, 0.f, 1.f}); // Finally yaw around Z

    // Translate camera
    view_matrix = glm::translate(view_matrix, -camera_position);

    // Draw starbox.
    glDepthMask(GL_FALSE);
    {
        starbox_shader->bind();
        // Scale skybox appropriately for orthographic vs perspective projection
        float skybox_scale = (projection_type == ProjectionType::Orthographic)
            ? std::max(100.0f, camera_position.z * 2.0f)  // Scale with camera distance for ortho
            : 100.0f;                                      // Fixed scale for perspective
        glUniform1f(starbox_shader->getUniformLocation("u_scale"), skybox_scale);

        string skybox_name = "skybox/default";
        if (gameGlobalInfo)
            skybox_name = "skybox/" + gameGlobalInfo->default_skybox;

        string local_skybox_name = skybox_name;
        float local_skybox_factor = 0.0f;
        float best_skybox_depth = 0.0f;

        // Check Zone-based skybox transitions (polygon zones)
        for(auto [entity, zone, t] : sp::ecs::Query<Zone, sp::Transform>()) {
            if (zone.skybox.empty()) continue;

            auto pos = t.getPosition() - glm::vec2(camera_position.x, camera_position.y);
            float factor = 0.0f;
            if (insidePolygon(zone.outline, pos))
            {
                if (zone.skybox_fade_distance <= 0.0f)
                    factor = 1.0f;
                else
                    factor = std::clamp(distanceToEdge(zone.outline, pos) / zone.skybox_fade_distance, 0.0f, 1.0f);
            }
            if (factor > best_skybox_depth)
            {
                best_skybox_depth = factor;
                local_skybox_name = "skybox/" + zone.skybox;
                local_skybox_factor = factor;
            }
        }

        // Check NebulaRenderer-based skybox transitions (circular nebulae)
        for (const auto& info : nebula_infos) {
            if (info.skybox.empty() || info.radius <= 0.0f) continue;

            auto pos = info.position - camera_pos2;
            float dist = glm::length(pos);
            if (dist < info.radius)
            {
                float factor;
                if (info.skybox_fade_distance <= 0.0f)
                    factor = 1.0f;
                else
                    factor = std::clamp((info.radius - dist) / info.skybox_fade_distance, 0.0f, 1.0f);
                if (factor > best_skybox_depth)
                {
                    best_skybox_depth = factor;
                    local_skybox_name = "skybox/" + info.skybox;
                    local_skybox_factor = factor;
                }
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
        // For skybox, remove translation from view matrix to make it appear infinitely far away
        glm::mat4 skybox_view = glm::mat4(glm::mat3(view_matrix));
        glUniformMatrix4fv(starbox_uniforms[static_cast<size_t>(Uniforms::Projection)], 1, GL_FALSE, glm::value_ptr(projection_matrix));
        glUniformMatrix4fv(starbox_uniforms[static_cast<size_t>(Uniforms::View)], 1, GL_FALSE, glm::value_ptr(skybox_view));
        
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

    // Emit engine particles.
    for (auto [entity, mrc, ee, transform, impulse] : sp::ecs::Query<MeshRenderComponent, EngineEmitter, sp::Transform, ImpulseEngine>())
    {
        if (impulse.actual != 0.0f)
        {
            if (engine->getElapsedTime() - ee.last_engine_particle_time > 0.1f)
            {
                // Skip if ship is occluded by a nebula
                if (!entity.hasComponent<NeverRadarBlocked>()
                    && !entity.hasComponent<RadarBlock>()
                    && RenderSystem::isOccludedByNebula(glm::vec2(camera_position.x, camera_position.y), transform.getPosition()))
                {
                    ee.last_engine_particle_time = engine->getElapsedTime();
                    continue;
                }

                for (auto ed : ee.emitters)
                {
                    // Apply banking rotation in local space. Flip the banking
                    // angle since the emitters effectively face the opposite
                    // direction.
                    glm::vec3 local_offset = ed.position;

                    if (mrc.bank_angle != 0.0f)
                    {
                        glm::mat4 bank_matrix = glm::rotate(
                            glm::mat4(1.0f),
                            glm::radians(-mrc.bank_angle),
                            glm::vec3(1.0f, 0.0f, 0.0f)
                        );
                        local_offset = glm::vec3(bank_matrix * glm::vec4(local_offset, 1.0f));
                    }

                    // Rotate by ship's heading and translate to world position.
                    const glm::vec3 pos3d = glm::vec3(transform.getPosition() + rotateVec2(glm::vec2(local_offset.x, local_offset.y), transform.getRotation()), local_offset.z);

                    const float scale = ed.scale * std::abs(impulse.actual);
                    ParticleEngine::spawn(pos3d, pos3d, ed.color, ed.color, scale, 0.0f, 5.0f);
                }
                ee.last_engine_particle_time = engine->getElapsedTime();
            }
        }
    }

    // Collect dynamic lights for nebula cloud illumination.
    DynamicLightManager::clear();

    if (DynamicLightManager::isEnabled())
    {
        // From weapon beam effects (multiple lights along the beam path).
        for (auto [entity, be, transform] : sp::ecs::Query<BeamEffect, sp::Transform>())
        {
            if (be.lifetime <= 0.0f) continue;
            glm::vec3 start_point(transform.getPosition().x, transform.getPosition().y, be.source_offset.z);
            glm::vec3 end_point(be.target_location.x, be.target_location.y, be.target_offset.z);
            float beam_length = glm::length(end_point - start_point);
            glm::vec3 color = glm::vec3(be.beam_color.r, be.beam_color.g, be.beam_color.b) / 255.0f;
            float intensity = std::min(be.lifetime * 2.0f, 1.0f);
            int num_lights = std::max(1, int(beam_length / 800.0f));
            for (int i = 0; i <= num_lights; i++)
            {
                float t = float(i) / float(num_lights);
                DynamicLightManager::add({
                    glm::mix(start_point, end_point, t),
                    color,
                    250.0f,
                    intensity
                });
            }
        }

        // From utility beam effects.
        for (auto [entity, ube, transform] : sp::ecs::Query<UtilityBeamEffect, sp::Transform>())
        {
            if (ube.lifetime <= 0.0f) continue;
            glm::vec3 start_point(transform.getPosition().x, transform.getPosition().y, ube.source_offset.z);
            glm::vec3 end_point(ube.target_location.x, ube.target_location.y, ube.target_offset.z);
            float beam_length = glm::length(end_point - start_point);
            float intensity = std::min(ube.lifetime * 2.0f, 1.0f);
            int num_lights = std::max(1, int(beam_length / 800.0f));
            for (int i = 0; i <= num_lights; i++)
            {
                float t = float(i) / float(num_lights);
                DynamicLightManager::add({
                    glm::mix(start_point, end_point, t),
                    glm::vec3(0.6f, 0.4f, 0.8f),
                    250.0f,
                    intensity
                });
            }
        }

        // From explosions (center of the sphere, radius scales with visual size).
        for (auto [entity, ee, transform] : sp::ecs::Query<ExplosionEffect, sp::Transform>())
        {
            float progress = ee.lifetime / ee.max_lifetime;
            if (progress <= 0.0f) continue;

            float f = 1.0f - progress;
            float explosion_scale;
            if (f < 0.2f)
                explosion_scale = f / 0.2f;
            else if (ee.electrical)
                explosion_scale = Tween<float>::easeOutQuad(f, 0.2f, 1.0f, 0.8f, 1.0f);
            else
                explosion_scale = Tween<float>::easeOutQuad(f, 0.2f, 1.0f, 1.0f, 1.3f);

            float radius = explosion_scale * ee.size * 2.0f;

            glm::vec3 color;
            if (ee.electrical)
                color = random(0, 1) > 0.5f
                    ? glm::vec3(0.3f, 0.5f, 1.0f)
                    : glm::vec3(1.0f, 1.0f, 1.0f);
            else
                color = glm::vec3(1.0f, 0.5f, 0.15f);

            float intensity = std::min((1.0f - progress) * 2.0f, 1.0f);
            DynamicLightManager::add({
                glm::vec3(transform.getPosition(), 0.0f),
                color,
                radius,
                intensity
            });
        }

        // From engine emitters (one light per emitter, radius = emitter span * 2).
        for (auto [entity, mrc, ee, transform, impulse] : sp::ecs::Query<MeshRenderComponent, EngineEmitter, sp::Transform, ImpulseEngine>())
        {
            if (impulse.actual == 0.0f) continue;

            // Find the span of emitter positions in local space.
            float min_x = std::numeric_limits<float>::max();
            float max_x = std::numeric_limits<float>::lowest();
            for (auto& ed : ee.emitters)
            {
                float ex = ed.position.x;
                if (ex < min_x) min_x = ex;
                if (ex > max_x) max_x = ex;
            }
            float emitter_span = max_x - min_x;
            float light_radius = std::max(emitter_span * 2.0f, 500.0f);

            for (auto ed : ee.emitters)
            {
                glm::vec3 local_offset = ed.position;
                if (mrc.bank_angle != 0.0f)
                {
                    glm::mat4 bank_matrix = glm::rotate(
                        glm::mat4(1.0f), glm::radians(-mrc.bank_angle), glm::vec3(1.0f, 0.0f, 0.0f));
                    local_offset = glm::vec3(bank_matrix * glm::vec4(local_offset, 1.0f));
                }
                glm::vec3 pos3d = glm::vec3(
                    transform.getPosition()
                    + rotateVec2(glm::vec2(local_offset.x, local_offset.y), transform.getRotation()),
                    local_offset.z);
                DynamicLightManager::add({
                    pos3d,
                    ed.color,
                    light_radius,
                    std::abs(impulse.actual)
                });
            }
        }

        // From shield hits (at ship position when hit_effect > 0).
        for (auto [entity, shields, transform] : sp::ecs::Query<Shields, sp::Transform>())
        {
            float max_hit = 0.0f;
            for (auto& shield : shields.entries)
                max_hit = std::max(max_hit, shield.hit_effect);
            if (max_hit <= 0.0f) continue;
            float ship_radius = 1000.0f;
            if (auto physics = entity.getComponent<sp::Physics>())
                ship_radius = physics->getSize().x;
            DynamicLightManager::add({
                glm::vec3(transform.getPosition(), 0.0f),
                glm::vec3(0.5f, 0.7f, 1.0f),
                ship_radius * 3.0f,
                std::min(max_hit * 2.0f, 1.0f)
            });
        }
    }

    // Apply pre-computed nebula fog
    if (PreferencesManager::get("nebula_fog", "1") == "1")
        ShaderRegistry::setFog(nebula_fog_color, effective_fog_distance);
    else
        ShaderRegistry::setFog(glm::vec3{0.0f}, 0.0f);

    // Update view matrix in shaders.
    ShaderRegistry::updateProjectionView({}, view_matrix, engine->getElapsedTime());

    RenderSystem::post_opaque_render = [this]() {
        ParticleEngine::render(this->projection_matrix, this->view_matrix);
    };
    RenderSystem render_system;
    render_system.render3D(rect.size.x / rect.size.y, camera_fov, projection_type, far_plane);
    RenderSystem::post_opaque_render = nullptr;

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
            //
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
        glUniform2f(spacedust_shader->getUniformLocation("u_velocity"), dust_vector.x, dust_vector.y);
        
        {
            gl::ScopedVertexAttribArray positions(spacedust_vertex_attributes[static_cast<size_t>(VertexAttributes::Position)]);
            gl::ScopedVertexAttribArray signs(spacedust_vertex_attributes[static_cast<size_t>(VertexAttributes::Sign)]);
            glBindBuffer(GL_ARRAY_BUFFER, spacedust_buffer[0]);
            
            if (update_required)
            {
                glBufferSubData(GL_ARRAY_BUFFER, 0, space_dust.size() * sizeof(glm::vec3), space_dust.data());
            }
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
            // Skip callsigns of entities radar-obscured by nebula.
            if (!entity.hasComponent<NeverRadarBlocked>()
                && !entity.hasComponent<RadarBlock>()
                && RenderSystem::isOccludedByNebula(glm::vec2(camera_position.x, camera_position.y), transform.getPosition()))
            {
                continue;
            }
            float radius = 300.0f;
            if (auto physics = entity.getComponent<sp::Physics>())
                radius = std::min(physics->getSize().x, physics->getSize().y);
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
