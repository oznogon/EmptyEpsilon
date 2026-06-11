#include "systems/rendering.h"
#include "components/rendering.h"
#include "components/radarblock.h"
#include "textureManager.h"
#include "vectorUtils.h"
#include "shaderRegistry.h"
#include "engine.h"
#include <graphics/opengl.h>
#include <glm/gtc/type_ptr.hpp>
#include "tween.h"
#include "random.h"
#include "components/maneuveringthrusters.h"
#include "dynamicLight.h"
#include <algorithm>

std::vector<RenderSystem::RenderHandler> RenderSystem::render_handlers;
std::function<void()> RenderSystem::post_opaque_render;
std::vector<RenderSystem::NebulaOccluder> RenderSystem::nebula_occluder_cache;

void RenderSystem::refreshNebulaCache()
{
    nebula_occluder_cache.clear();
    glm::vec2 source{ camera_position.x, camera_position.y };

    for (auto [entity, radar_block, transform] : sp::ecs::Query<RadarBlock, sp::Transform>())
    {
        NebulaOccluder occ;
        occ.position = transform.getPosition();
        const float occlusion_radius = radar_block.range * 0.8f;

        if (auto nr = entity.getComponent<NebulaRenderer>())
        {
            const float fade_zone = nr->skybox_fade_distance > 0.0f
                ? nr->skybox_fade_distance
                : 1000.0f;
            const float camera_dist = glm::length(source - occ.position);
            const float transition_start = nr->radius + 1.5f * fade_zone;
            const float transition_end = std::max(0.0f, nr->radius - 0.5f * fade_zone);

            float t = (camera_dist - nr->radius) / (transition_start - nr->radius);
            t = std::clamp(t, 0.0f, 1.0f);
            t = t * t * (3.0f - 2.0f * t);
            occ.occlusion_radius = transition_end * t;
        }
        else
        {
            if (glm::length(source - occ.position) >= occlusion_radius)
                occ.occlusion_radius = occlusion_radius;
            else
                occ.occlusion_radius = 0.0f;
        }

        nebula_occluder_cache.push_back(occ);
    }
}

bool RenderSystem::isOccludedByNebula(glm::vec2 source, glm::vec2 target)
{
    refreshNebulaCache();
    return isOccludedByNebula(source, target, nebula_occluder_cache);
}

bool RenderSystem::isOccludedByNebula(glm::vec2 source, glm::vec2 target, const std::vector<NebulaOccluder>& occluders)
{
    for (const auto& occ : occluders)
    {
        // Target occluded due to being inside occlusion radius.
        if (glm::length2(target - occ.position) < occ.occlusion_radius * occ.occlusion_radius)
            return true;

        // Target occluded due to the line from camera to target passing through
        // the occlusion radius.
        const glm::vec2 diff = target - source;
        const float dist = glm::length(diff);
        if (dist < 0.01f) continue;

        const float f = std::clamp(glm::dot(diff, occ.position - source) / dist, 0.0f, dist);
        const glm::vec2 q = source + diff * (f / dist);

        if (glm::length2(q - occ.position) < occ.occlusion_radius * occ.occlusion_radius)
            return true;
    }

    return false;
}

void RenderSystem::render3D(float aspect, float camera_fov, ProjectionType projection_type, float far_plane)
{
    refreshNebulaCache();
    view_vector = vec2FromAngle(camera_yaw);
    if (camera_position.z <= 0.0f)
    {
        depth_cutoff_near = -std::numeric_limits<float>::infinity();
        depth_cutoff_far = std::numeric_limits<float>::infinity();
    }
    else
    {
        float near_angle = glm::radians(camera_pitch + camera_fov * 0.5f);
        float far_angle = glm::radians(camera_pitch - camera_fov * 0.5f);
        depth_cutoff_near = camera_position.z * glm::cos(near_angle) / glm::sin(near_angle);
        depth_cutoff_far = camera_position.z * glm::cos(far_angle) / glm::sin(far_angle);
        if (camera_pitch + camera_fov * 0.5f >= 180.f)
            depth_cutoff_near = -std::numeric_limits<float>::infinity();
        if (camera_pitch - camera_fov * 0.5f <= 0.0f)
            depth_cutoff_far = std::numeric_limits<float>::infinity();
    }
    for (auto& handler : render_handlers) (this->*(handler.func))(handler.rif);

    for (auto& render_list : render_lists)
    {
        for (auto it = render_list.begin(); it != render_list.end(); )
        {
            if (!it->entity.hasComponent<NeverRadarBlocked>()
                && !it->entity.hasComponent<RadarBlock>()
                && isOccludedByNebula(glm::vec2(camera_position.x, camera_position.y),
                                      it->transform->getPosition(),
                                      nebula_occluder_cache))
                it = render_list.erase(it);
            else ++it;
        }
    }

    // Sort all render lists back-to-front once
    for (int n = static_cast<int>(render_lists.size()) - 1; n >= 0; n--)
    {
        auto& render_list = render_lists[n];
        std::sort(render_list.begin(), render_list.end(),
            [](const RenderEntry& a, const RenderEntry& b)
            { return a.depth > b.depth; }
        );
    }

    // Opaque passes (back to front)
    for (int n = static_cast<int>(render_lists.size()) - 1; n >= 0; n--)
    {
        auto& render_list = render_lists[n];
        glm::mat4 projection;
        if (projection_type == ProjectionType::Orthographic)
        {
            // For orthographic projection, calculate view volume size based on FOV and reference distance
            // Use a reference distance to determine the viewport size that would be visible at that distance with perspective
            float reference_distance = std::max(100.0f, camera_position.z);
            float height = reference_distance * glm::tan(glm::radians(camera_fov / 2.0f));
            float width = height * aspect;
            projection = glm::ortho(-width, width, -height, height, 1.0f, far_plane * (n + 1));
        }
        else
            projection = glm::perspective(glm::radians(camera_fov), aspect, 1.f, far_plane * (n + 1));
        // Update projection matrix in shaders.
        ShaderRegistry::updateProjectionView(projection, {});

        glDepthMask(true);
        glDisable(GL_BLEND);
        for (auto info : render_list)
        {
            if (!info.transparent)
                info.call_rif(info.rif, info.entity, *info.transform, info.component_ptr);
        }
    }

    // Post-opaque render (particles).
    glEnable(GL_BLEND);
    glDepthMask(false);
    if (post_opaque_render) post_opaque_render();
    glDepthMask(true);

    // Transparent passes, non-nebula first, back to front
    for (int n = static_cast<int>(render_lists.size()) - 1; n >= 0; n--)
    {
        auto& render_list = render_lists[n];
        glm::mat4 projection;
        if (projection_type == ProjectionType::Orthographic)
        {
            const float reference_distance = std::max(100.0f, camera_position.z);
            const float height = reference_distance * glm::tan(glm::radians(camera_fov * 0.5f));
            const float width = height * aspect;
            projection = glm::ortho(-width, width, -height, height, 1.0f, far_plane * (n + 1));
        }
        else
            projection = glm::perspective(glm::radians(camera_fov), aspect, 1.0f, far_plane * (n + 1));
        ShaderRegistry::updateProjectionView(projection, {});

        glEnable(GL_BLEND);
        glBlendFunc(GL_ONE, GL_ONE);
        glDepthMask(false);
        for (auto info : render_list)
        {
            if (info.transparent && !info.entity.hasComponent<NebulaRenderer>())
                info.call_rif(info.rif, info.entity, *info.transform, info.component_ptr);
        }
    }

    // Nebula clouds rendered last so alpha blending occludes effects behind them.
    for (int n = static_cast<int>(render_lists.size()) - 1; n >= 0; n--)
    {
        auto& render_list = render_lists[n];
        glm::mat4 projection;
        if (projection_type == ProjectionType::Orthographic)
        {
            const float reference_distance = std::max(100.0f, camera_position.z);
            const float height = reference_distance * glm::tan(glm::radians(camera_fov * 0.5f));
            const float width = height * aspect;
            projection = glm::ortho(-width, width, -height, height, 1.0f, far_plane * (n + 1));
        }
        else
            projection = glm::perspective(glm::radians(camera_fov), aspect, 1.f, far_plane * (n + 1));
        ShaderRegistry::updateProjectionView(projection, {});

        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glDepthMask(false);
        for (auto info : render_list)
        {
            if (info.transparent && info.entity.hasComponent<NebulaRenderer>())
                info.call_rif(info.rif, info.entity, *info.transform, info.component_ptr);
        }
    }
}

glm::mat4 calculateModelMatrix(glm::vec2 position, float rotation, glm::vec3 mesh_offset, float scale)
{
    auto model_matrix = glm::translate(glm::identity<glm::mat4>(), glm::vec3{ position.x, position.y, 0.0f });
    model_matrix = glm::rotate(model_matrix, glm::pi<float>(), glm::vec3{ 0.0f, 0.0f, 1.0f });
    model_matrix = glm::rotate(model_matrix, glm::radians(rotation), glm::vec3{ 0.0f, 0.0f, 1.0f });
    model_matrix = glm::translate(model_matrix, mesh_offset);
    model_matrix = glm::scale(model_matrix, glm::vec3{scale});

    return model_matrix;
}

ShaderRegistry::ScopedShader lookUpShader(MeshRenderComponent& mrc)
{
    auto shader_id = ShaderRegistry::Shaders::Object;
    if (mrc.getNormalTexture())
    {
        if (mrc.getTexture() && mrc.getSpecularTexture() && mrc.getIlluminationTexture())
            shader_id = ShaderRegistry::Shaders::ObjectSpecularIlluminationNormal;
        else if (mrc.getTexture() && mrc.getSpecularTexture())
            shader_id = ShaderRegistry::Shaders::ObjectSpecularNormal;
        else if (mrc.getTexture() && mrc.getIlluminationTexture())
            shader_id = ShaderRegistry::Shaders::ObjectIlluminationNormal;
        else
            shader_id = ShaderRegistry::Shaders::ObjectNormal;
    }
    else
    {
        if (mrc.getTexture() && mrc.getSpecularTexture() && mrc.getIlluminationTexture())
            shader_id = ShaderRegistry::Shaders::ObjectSpecularIllumination;
        else if (mrc.getTexture() && mrc.getSpecularTexture())
            shader_id = ShaderRegistry::Shaders::ObjectSpecular;
        else if (mrc.getTexture() && mrc.getIlluminationTexture())
            shader_id = ShaderRegistry::Shaders::ObjectIllumination;
    }

    return ShaderRegistry::ScopedShader(shader_id);
}

void activateAndBindMeshTextures(MeshRenderComponent& mrc)
{
    if (mrc.getTexture()) mrc.getTexture()->bind();

    if (mrc.getSpecularTexture())
    {
        glActiveTexture(GL_TEXTURE0 + ShaderRegistry::textureIndex(ShaderRegistry::Textures::SpecularMap));
        mrc.getSpecularTexture()->bind();
    }

    if (mrc.getIlluminationTexture())
    {
        glActiveTexture(GL_TEXTURE0 + ShaderRegistry::textureIndex(ShaderRegistry::Textures::IlluminationMap));
        mrc.getIlluminationTexture()->bind();
    }

    if (mrc.getNormalTexture())
    {
        glActiveTexture(GL_TEXTURE0 + ShaderRegistry::textureIndex(ShaderRegistry::Textures::NormalMap));
        mrc.getNormalTexture()->bind();
    }
}

void drawMesh(MeshRenderComponent& mrc, ShaderRegistry::ScopedShader& shader)
{
    gl::ScopedVertexAttribArray positions(shader.get().attribute(ShaderRegistry::Attributes::Position));
    gl::ScopedVertexAttribArray texcoords(shader.get().attribute(ShaderRegistry::Attributes::Texcoords));
    gl::ScopedVertexAttribArray normals(shader.get().attribute(ShaderRegistry::Attributes::Normal));
    gl::ScopedVertexAttribArray tangent(shader.get().attribute(ShaderRegistry::Attributes::Tangent));

    mrc.getMesh()->render(positions.get(), texcoords.get(), normals.get(), tangent.get());

    // Restore the active unit so the next mesh binds its base texture to unit 0.
    if (mrc.getSpecularTexture() || mrc.getIlluminationTexture() || mrc.getNormalTexture())
        glActiveTexture(GL_TEXTURE0);
}

void MeshRenderSystem::update(float delta)
{
    // Update banking angle for all physics entities that have maneuvering
    // thrusters.
    for (auto [entity, mrc, transform, physics, maneuvering] : sp::ecs::Query<MeshRenderComponent, sp::Transform, sp::Physics, ManeuveringThrusters>())
    {
        float target_bank_angle = 0.0f;
        target_bank_angle = std::clamp(physics.getAngularVelocity(), -4.0f, 4.0f);
        mrc.bank_angle = mrc.bank_angle * 0.97f + target_bank_angle * 0.03f;
    }
}

void MeshRenderSystem::render3D(sp::ecs::Entity e, sp::Transform& transform, MeshRenderComponent& mrc)
{
    auto model_matrix = calculateModelMatrix(
        transform.getPosition(),
        transform.getRotation(),
        mrc.mesh_offset,
        mrc.scale
    );

    // Bank slightly around forward axis while rotating.
    if (mrc.bank_angle != 0.0f)
    {
        model_matrix = glm::rotate(
            model_matrix,
            glm::radians(mrc.bank_angle),
            glm::vec3{1.0f, 0.0f, 0.0f}
        );
    }

    auto shader = lookUpShader(mrc);
    glUniformMatrix4fv(shader.get().uniform(ShaderRegistry::Uniforms::Model), 1, GL_FALSE, glm::value_ptr(model_matrix));

    auto modeldata_matrix = glm::rotate(model_matrix, glm::radians(180.0f), {0.0f, 0.0f, 1.0f});
    modeldata_matrix = glm::scale(modeldata_matrix, glm::vec3{mrc.scale});

    // Lights setup.
    ShaderRegistry::setupLights(shader.get(), modeldata_matrix);

    // Set illumination modulation.
    glUniform4fv(shader.get().uniform(ShaderRegistry::Uniforms::IlluminationModulation), 1, glm::value_ptr(mrc.illumination_modulation));

    // Textures.
    activateAndBindMeshTextures(mrc);

    // Draw.
    drawMesh(mrc, shader);
}

void NebulaRenderSystem::update(float delta)
{
}

void NebulaRenderSystem::render3D(sp::ecs::Entity e, sp::Transform& transform, NebulaRenderer& nr)
{
    nr.generateCloudsFromSeed();
    if (nr.clouds.empty()) return;

    glm::vec2 nebula_pos = transform.getPosition();
    float dist_to_center = glm::length(nebula_pos - glm::vec2{camera_position.x, camera_position.y});
    float shell_alpha = dist_to_center <= nr.radius
        ? 1.0f
        : nr.radius / dist_to_center;
    const float cloud_density = std::max(0.0f, nr.cloud_density);

    ShaderRegistry::ScopedShader shader(ShaderRegistry::Shaders::Billboard);

    // Fade billboards out as the visibility origin approaches them: 0 opacity
    // within 10% of visibility distance, ramping to full opacity by 33%.
    if (auto loc = shader.get().get()->getUniformLocation("u_proximityFade"); loc != -1)
        glUniform2f(loc, nr.visibility_distance * 0.1f, nr.visibility_distance * 0.33f);

    // Dynamic lights for nebula cloud illumination.
    // Only lights whose source is inside the nebula radius affect the clouds.
    const auto& lights = DynamicLightManager::getLights();

    struct VertexAndTexCoords
    {
        glm::vec3 vertex;
        glm::vec2 texcoords;
    };
    std::array<VertexAndTexCoords, 4> quad{
        VertexAndTexCoords{glm::vec3{}, {0.0f, 1.0f}},
        VertexAndTexCoords{glm::vec3{}, {1.0f, 1.0f}},
        VertexAndTexCoords{glm::vec3{}, {1.0f, 0.0f}},
        VertexAndTexCoords{glm::vec3{}, {0.0f, 0.0f}}
    };

    gl::ScopedVertexAttribArray positions(shader.get().attribute(ShaderRegistry::Attributes::Position));
    gl::ScopedVertexAttribArray texcoords(shader.get().attribute(ShaderRegistry::Attributes::Texcoords));

    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    // Batch pre-compute light contributions for all clouds.
    std::vector<float> cloud_lights(nr.clouds.size(), 0.0f);
    glm::vec3 ring_center = glm::vec3(nebula_pos.x, nebula_pos.y, 0.0f);
    for (int i = 0; i < static_cast<int>(nr.clouds.size()); i++)
    {
        glm::vec3 cloud_pos = ring_center + glm::vec3(nr.clouds[i].offset.x, nr.clouds[i].offset.y, 0);
        float total = 0.0f;
        for (const auto& light : lights)
        {
            glm::vec2 light_pos_2d{light.position.x, light.position.y};

            if (glm::length(light_pos_2d - nebula_pos) > nr.radius) continue;

            const float dist = glm::length(cloud_pos - light.position);
            if (dist < light.radius)
            {
                float atten = 1.0f - dist / light.radius;
                total += light.intensity * atten * atten;
            }
        }
        cloud_lights[i] = std::min(total, 1.0f);
    }

    // Pre-compute fog ring light contributions
    std::array<float, 6> ring_lights{};
    for (int v = 0; v < 6; v++)
    {
        float volume_size = nr.radius * (0.3f + v * 0.15f);
        float total = 0.0f;

        for (const auto& light : lights)
        {
            glm::vec2 light_pos_2d{light.position.x, light.position.y};
            if (glm::length(light_pos_2d - nebula_pos) > nr.radius)
                continue;
            float dist_to_ring_center = glm::length(light.position - ring_center);
            float dist_to_ring = std::abs(dist_to_ring_center - volume_size);
            if (dist_to_ring < light.radius)
            {
                float atten = 1.0f - dist_to_ring / light.radius;
                total += light.intensity * atten * atten;
            }
        }

        ring_lights[v] = std::min(total, 1.0f);
    }

    // Render fog volume billboards when camera is near or inside the nebula.
    if (shell_alpha > 0.001f)
    {
        for (int v = 0; v < 6; v++)
        {
            int tex_idx = v % nr.clouds.size();
            auto& cloud = nr.clouds[tex_idx];
            float volume_size = nr.radius * (0.3f + v * 0.15f);
            float volume_alpha = shell_alpha * 0.8f * (1.0f - v * 0.16f) * cloud_density;
            float volume_color_val = 0.25f + ring_lights[v] * 0.5f;

            if (!cloud.texture.ptr)
                cloud.texture.ptr = textureManager.getTexture(cloud.texture.name);
            if (cloud.texture.ptr) cloud.texture.ptr->bind();

            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

            float rotation = glm::mod(nebula_pos.x * 1.37f + nebula_pos.y * 2.71f + v * 59.0f, 360.0f);
            float cos_r = glm::cos(glm::radians(rotation));
            float sin_r = glm::sin(glm::radians(rotation));

            VertexAndTexCoords rquad[4];
            for (int vt = 0; vt < 4; vt++)
            {
                float u = quad[vt].texcoords.x - 0.5f;
                float tv = quad[vt].texcoords.y - 0.5f;
                rquad[vt].vertex = glm::vec3(nebula_pos.x, nebula_pos.y, 0);
                rquad[vt].texcoords = {
                    u * cos_r - tv * sin_r + 0.5f,
                    u * sin_r + tv * cos_r + 0.5f
                };
            }

            glUniform4f(shader.get().uniform(ShaderRegistry::Uniforms::Color), volume_color_val, volume_alpha, 0.0f, volume_size);
            {
                auto loc = shader.get().get()->getUniformLocation("u_lightIntensity");
                if (loc != -1) glUniform1f(loc, ring_lights[v]);
            }

            auto volume_model = glm::identity<glm::mat4>();
            glUniformMatrix4fv(shader.get().uniform(ShaderRegistry::Uniforms::Model), 1, GL_FALSE, glm::value_ptr(volume_model));

            glVertexAttribPointer(positions.get(), 3, GL_FLOAT, GL_FALSE, sizeof(VertexAndTexCoords), (GLvoid*)rquad);
            glVertexAttribPointer(texcoords.get(), 2, GL_FLOAT, GL_FALSE, sizeof(VertexAndTexCoords), (GLvoid*)((char*)rquad + sizeof(glm::vec3)));
            std::initializer_list<uint16_t> indices = { 0, 3, 2, 0, 2, 1 };
            glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, std::begin(indices));
        }
    }

    // Build sorted list of cloud indices (back to front)
    std::vector<int> sorted_indices;
    sorted_indices.reserve(nr.clouds.size());
    for (int i = 0; i < static_cast<int>(nr.clouds.size()); i++)
        sorted_indices.push_back(i);

    std::sort(sorted_indices.begin(), sorted_indices.end(),
        [&](int a, int b)
        {
            glm::vec3 pos_a = glm::vec3(nebula_pos.x, nebula_pos.y, 0) + glm::vec3(nr.clouds[a].offset.x, nr.clouds[a].offset.y, 0);
            glm::vec3 pos_b = glm::vec3(nebula_pos.x, nebula_pos.y, 0) + glm::vec3(nr.clouds[b].offset.x, nr.clouds[b].offset.y, 0);
            return glm::length2(camera_position - pos_a) > glm::length2(camera_position - pos_b);
        }
    );

    for (int idx : sorted_indices)
    {
        auto& cloud = nr.clouds[idx];
        glm::vec3 cloud_pos = ring_center + glm::vec3(cloud.offset.x, cloud.offset.y, 0.0f);

        float per_cloud_alpha = 0.6f * shell_alpha * cloud_density;

        if (per_cloud_alpha <= 0.0f) continue;

        // Per-cloud billboard rotation for visual variety.
        const float rotation = glm::mod(cloud.offset.x * 1.73f + cloud.offset.y * 3.14f, 360.0f);
        const float cos_r = glm::cos(glm::radians(rotation));
        const float sin_r = glm::sin(glm::radians(rotation));

        VertexAndTexCoords rquad[4];
        for (int v = 0; v < 4; v++)
        {
            const float u = quad[v].texcoords.x - 0.5f;
            const float vt = quad[v].texcoords.y - 0.5f;
            rquad[v].vertex = cloud_pos;
            rquad[v].texcoords = {
                u * cos_r - vt * sin_r + 0.5f,
                u * sin_r + vt * cos_r + 0.5f
            };
        }

        if (!cloud.texture.ptr)
            cloud.texture.ptr = textureManager.getTexture(cloud.texture.name);
        if (cloud.texture.ptr) cloud.texture.ptr->bind();

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

        float cloud_light = cloud_lights[idx];
        float color_val = std::min(0.8f + cloud_light * 0.3f, 1.0f);
        glUniform4f(shader.get().uniform(ShaderRegistry::Uniforms::Color), color_val, per_cloud_alpha, 0.0f, cloud.size);
        {
            auto loc = shader.get().get()->getUniformLocation("u_lightIntensity");
            if (loc != -1) glUniform1f(loc, cloud_light);
        }

        auto cloud_model_matrix = glm::identity<glm::mat4>();
        glUniformMatrix4fv(shader.get().uniform(ShaderRegistry::Uniforms::Model), 1, GL_FALSE, glm::value_ptr(cloud_model_matrix));

        glVertexAttribPointer(positions.get(), 3, GL_FLOAT, GL_FALSE, sizeof(VertexAndTexCoords), (GLvoid*)rquad);
        glVertexAttribPointer(texcoords.get(), 2, GL_FLOAT, GL_FALSE, sizeof(VertexAndTexCoords), (GLvoid*)((char*)rquad + sizeof(glm::vec3)));
        std::initializer_list<uint16_t> indices = { 0, 3, 2, 0, 2, 1 };
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, std::begin(indices));
    }

    // Restore additive blending
    glBlendFunc(GL_ONE, GL_ONE);
}

void ExplosionRenderSystem::update(float delta)
{
    for (auto [entity, ee] : sp::ecs::Query<ExplosionEffect>())
    {
        ee.lifetime -= delta;
        if (ee.lifetime < 0.0f) entity.destroy();
    }
}

void ExplosionRenderSystem::renderOnRadar(sp::RenderTarget& renderer, sp::ecs::Entity entity, glm::vec2 screen_position, float scale, float rotation, ExplosionEffect& explosion)
{
    if (!explosion.radar) return;

    // Fade alpha over lifetime
    uint8_t alpha = static_cast<uint8_t>(64.0f * explosion.lifetime / ExplosionEffect::max_lifetime);

    // Draw electrical/EMP explosions blue, rest red
    renderer.fillCircle(screen_position, explosion.size * scale, explosion.electrical ? glm::u8vec4(0, 0, 255, alpha) : glm::u8vec4(255, 0, 0, alpha));
}

void ExplosionRenderSystem::render3D(sp::ecs::Entity e, sp::Transform& transform, ExplosionEffect& ee)
{
    float f = (1.0f - (ee.lifetime / ee.max_lifetime));
    float scale;

    if (f < 0.2f)
    {
        scale = (f / 0.2f);
        if (ee.electrical) scale *= 0.8f;
    }
    else
    {
        if (ee.electrical)
            scale = Tween<float>::easeOutQuad(f, 0.2f, 1.0f, 0.8f, 1.0f);
        else scale = Tween<float>::easeOutQuad(f, 0.2f, 1.0f, 1.0f, 1.3f);
    }

    auto position = transform.getPosition();
    auto rotation = transform.getRotation();
    auto model_matrix = glm::translate(glm::identity<glm::mat4>(), glm::vec3{ position.x, position.y, 0.f });
    model_matrix = glm::rotate(model_matrix, glm::radians(rotation), glm::vec3{ 0.f, 0.f, 1.f });

    auto explosion_matrix = glm::scale(model_matrix, glm::vec3(scale * ee.size));
    ShaderRegistry::ScopedShader shader(ShaderRegistry::Shaders::Basic);
    {
        // Render sphere mesh opaque with depth writes.
        glDisable(GL_BLEND);
        glDepthMask(GL_TRUE);

        ShaderRegistry::ScopedShader explosion_shader(ShaderRegistry::Shaders::Explosion);
        glUniformMatrix4fv(explosion_shader.get().uniform(ShaderRegistry::Uniforms::Model), 1, GL_FALSE, glm::value_ptr(explosion_matrix));
        glUniform4f(explosion_shader.get().uniform(ShaderRegistry::Uniforms::Color), 1.0f, 1.0f, 1.0f, f);
        glUniform1f(explosion_shader.get().uniform(ShaderRegistry::Uniforms::Time), engine->getElapsedTime() + e.getIndex() * 1.771f);

        if (ee.electrical)
            textureManager.getTexture("texture/electric_sphere_texture.png")->bind();
        else textureManager.getTexture("texture/explosion.png")->bind();

        gl::ScopedVertexAttribArray positions(explosion_shader.get().attribute(ShaderRegistry::Attributes::Position));
        gl::ScopedVertexAttribArray texcoords(explosion_shader.get().attribute(ShaderRegistry::Attributes::Texcoords));
        gl::ScopedVertexAttribArray normals(explosion_shader.get().attribute(ShaderRegistry::Attributes::Normal));
        gl::ScopedVertexAttribArray tangents(explosion_shader.get().attribute(ShaderRegistry::Attributes::Tangent));

        Mesh* m = Mesh::getMesh("mesh/sphere.obj");
        m->render(positions.get(), texcoords.get(), normals.get(), tangents.get());

        if (ee.electrical)
        {
            glUniformMatrix4fv(explosion_shader.get().uniform(ShaderRegistry::Uniforms::Model), 1, GL_FALSE, glm::value_ptr(glm::scale(explosion_matrix, glm::vec3(.5f))));
            m->render(positions.get(), texcoords.get(), normals.get(), tangents.get());
        }

        // Restore transparent state for fire ring and particles.
        glEnable(GL_BLEND);
        glDepthMask(GL_FALSE);
    }
    shader.get().get()->bind();
    std::vector<glm::vec3> vertices(4 * ee.max_quad_count);

    if (!ee.particles_buffers) {
        for(int n=0; n<ee.particle_count; n++)
            ee.particle_directions[n] = glm::normalize(glm::vec3(random(-1, 1), random(-1, 1), random(-1, 1))) * random(0.8f, 1.2f);

        ee.particles_buffers = std::make_shared<gl::Buffers<2>>();

        // Each vertex is a position and a texcoords.
        // The two arrays are maintained separately (texcoords are fixed, vertices position change).
        constexpr size_t vertex_size = sizeof(glm::vec3) + sizeof(glm::vec2);
        gl::ScopedBufferBinding vbo(GL_ARRAY_BUFFER, (*ee.particles_buffers)[0]);
        gl::ScopedBufferBinding ebo(GL_ELEMENT_ARRAY_BUFFER, (*ee.particles_buffers)[1]);

        // VBO
        glBufferData(GL_ARRAY_BUFFER, ee.max_quad_count * 4 * vertex_size, nullptr, GL_STREAM_DRAW);

        // Create initial data.
        std::vector<uint16_t> indices(6 * ee.max_quad_count);
        std::vector<glm::vec2> texcoords(4 * ee.max_quad_count);
        for (auto i = 0U; i < ee.max_quad_count; ++i)
        {
            auto quad_offset = 4 * i;
            texcoords[quad_offset + 0] = { 0.f, 1.f };
            texcoords[quad_offset + 1] = { 1.f, 1.f };
            texcoords[quad_offset + 2] = { 1.f, 0.f };
            texcoords[quad_offset + 3] = { 0.f, 0.f };

            indices[6 * i + 0] = quad_offset + 0;
            indices[6 * i + 1] = quad_offset + 2;
            indices[6 * i + 2] = quad_offset + 1;
            indices[6 * i + 3] = quad_offset + 0;
            indices[6 * i + 4] = quad_offset + 3;
            indices[6 * i + 5] = quad_offset + 2;
        }

        // Update texcoords
        glBufferSubData(GL_ARRAY_BUFFER, ee.max_quad_count * 4 * sizeof(glm::vec3), texcoords.size() * sizeof(glm::vec2), texcoords.data());
        // Upload indices
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.size() * sizeof(uint16_t), indices.data(), GL_STATIC_DRAW);
    }

    gl::ScopedBufferBinding vbo(GL_ARRAY_BUFFER, (*ee.particles_buffers)[0]);
    gl::ScopedBufferBinding ebo(GL_ELEMENT_ARRAY_BUFFER, (*ee.particles_buffers)[1]);

    // Fire ring
    if (!ee.electrical)
    {
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        {
            float fire_val = Tween<float>::easeInQuartic(f, 0.0f, 1.0f, 1.0f, 0.0f);
            glUniform4f(shader.get().uniform(ShaderRegistry::Uniforms::Color), fire_val, fire_val, fire_val, fire_val);
        }

        textureManager.getTexture("texture/fire_ring.png")->bind();

        explosion_matrix = glm::scale(explosion_matrix, glm::vec3(1.5f));
        glUniformMatrix4fv(shader.get().uniform(ShaderRegistry::Uniforms::Model), 1, GL_FALSE, glm::value_ptr(explosion_matrix));

        vertices[0] = glm::vec3(-1, -1, 0);
        vertices[1] = glm::vec3( 1, -1, 0);
        vertices[2] = glm::vec3( 1,  1, 0);
        vertices[3] = glm::vec3(-1,  1, 0);
        {
            gl::ScopedVertexAttribArray positions(shader.get().attribute(ShaderRegistry::Attributes::Position));
            gl::ScopedVertexAttribArray texcoords(shader.get().attribute(ShaderRegistry::Attributes::Texcoords));

            glVertexAttribPointer(positions.get(), 3, GL_FLOAT, GL_FALSE, sizeof(glm::vec3), (GLvoid*)0);
            glVertexAttribPointer(texcoords.get(), 2, GL_FLOAT, GL_FALSE, sizeof(glm::vec2), (GLvoid*)(vertices.size() * sizeof(glm::vec3)));

            // Upload single vertex.
            glBufferSubData(GL_ARRAY_BUFFER, 0, 4 * sizeof(glm::vec3), vertices.data());

            glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, nullptr);
        }

        glBlendFunc(GL_ONE, GL_ONE);
    }

    shader = ShaderRegistry::ScopedShader(ShaderRegistry::Shaders::Billboard);
    // Don't fade nearby billboard visibility. To change this behavior, set
    // min/max fade distance range values in u_proximityFade.
    if (auto loc = shader.get().get()->getUniformLocation("u_proximityFade"); loc != -1)
        glUniform2f(loc, 0.0f, 0.0f);
    glUniformMatrix4fv(shader.get().uniform(ShaderRegistry::Uniforms::Model), 1, GL_FALSE, glm::value_ptr(model_matrix));

    gl::ScopedVertexAttribArray positions(shader.get().attribute(ShaderRegistry::Attributes::Position));
    gl::ScopedVertexAttribArray texcoords(shader.get().attribute(ShaderRegistry::Attributes::Texcoords));

    textureManager.getTexture("particle.png")->bind();

    scale = Tween<float>::easeInCubic(f, 0.f, 1.f, 0.3f, 5.0f);
    float r = Tween<float>::easeInQuad(f, 0.f, 1.f, 1.0f, 0.0f);
    float g = Tween<float>::easeOutQuad(f, 0.f, 1.f, 1.0f, 0.0f);
    float b = Tween<float>::easeOutQuad(f, 0.f, 1.f, 1.0f, 0.0f);

    if (ee.electrical)
    {
        scale = Tween<float>::easeInCubic(f, 0.f, 1.f, 0.3f, 3.0f);
        r = Tween<float>::easeOutQuad(f, 0.f, 1.f, 1.0f, 0.0f);
        g = Tween<float>::easeOutQuad(f, 0.f, 1.f, 1.0f, 0.0f);
        b = Tween<float>::easeInQuad(f, 0.f, 1.f, 1.0f, 0.0f);
    }

    glUniform4f(shader.get().uniform(ShaderRegistry::Uniforms::Color), r, g, b, ee.size / 32.0f);

    glVertexAttribPointer(positions.get(), 3, GL_FLOAT, GL_FALSE, sizeof(glm::vec3), (GLvoid*)0);
    glVertexAttribPointer(texcoords.get(), 2, GL_FLOAT, GL_FALSE, sizeof(glm::vec2), (GLvoid*)(vertices.size() * sizeof(glm::vec3)));

    const size_t quad_count = ee.max_quad_count;
    // Draw particles `quad_count` at a time.
    for (size_t n = 0; n < ee.particle_count;)
    {
        auto active_quads = std::min(quad_count, ee.particle_count - n);
        // Setup quads.
        for (auto p = 0U; p < active_quads; ++p)
        {
            glm::vec3 v = ee.particle_directions[n + p] * scale * ee.size;
            vertices[4 * p + 0] = v;
            vertices[4 * p + 1] = v;
            vertices[4 * p + 2] = v;
            vertices[4 * p + 3] = v;
        }

        // Upload.
        glBufferSubData(GL_ARRAY_BUFFER, 0, vertices.size() * sizeof(glm::vec3), vertices.data());

        glDrawElements(GL_TRIANGLES, static_cast<GLsizei>(6 * active_quads), GL_UNSIGNED_SHORT, nullptr);
        n += active_quads;
    }
}

void BillboardRenderSystem::update(float delta)
{
}

void BillboardRenderSystem::render3D(sp::ecs::Entity e, sp::Transform& transform, BillboardRenderer& bbr)
{
    struct VertexAndTexCoords
    {
        glm::vec3 vertex;
        glm::vec2 texcoords;
    };
    static std::array<VertexAndTexCoords, 4> quad{
        VertexAndTexCoords{glm::vec3{}, {0.0f, 1.0f}},
        VertexAndTexCoords{glm::vec3{}, {1.0f, 1.0f}},
        VertexAndTexCoords{glm::vec3{}, {1.0f, 0.0f}},
        VertexAndTexCoords{glm::vec3{}, {0.0f, 0.0f}}
    };

    textureManager.getTexture(bbr.texture)->bind();
    ShaderRegistry::ScopedShader shader(ShaderRegistry::Shaders::Billboard);
    // Don't fade nearby billboard visibility. To change this behavior, set
    // min/max fade distance range values in u_proximityFade.
    if (auto loc = shader.get().get()->getUniformLocation("u_proximityFade"); loc != -1)
        glUniform2f(loc, 0.0f, 0.0f);

    auto position = transform.getPosition();
    auto rotation = transform.getRotation();
    auto model_matrix = glm::translate(glm::identity<glm::mat4>(), glm::vec3{ position.x, position.y, 0.f });
    model_matrix = glm::rotate(model_matrix, glm::radians(rotation), glm::vec3{0.0f, 0.0f, 1.f });

    glUniformMatrix4fv(shader.get().uniform(ShaderRegistry::Uniforms::Model), 1, GL_FALSE, glm::value_ptr(model_matrix));
    glUniform4f(shader.get().uniform(ShaderRegistry::Uniforms::Color), 1.f, 1.f, 1.f, bbr.size);
    gl::ScopedVertexAttribArray positions(shader.get().attribute(ShaderRegistry::Attributes::Position));
    gl::ScopedVertexAttribArray texcoords(shader.get().attribute(ShaderRegistry::Attributes::Texcoords));

    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glVertexAttribPointer(positions.get(), 3, GL_FLOAT, GL_FALSE, sizeof(VertexAndTexCoords), (GLvoid*)quad.data());
    glVertexAttribPointer(texcoords.get(), 2, GL_FLOAT, GL_FALSE, sizeof(VertexAndTexCoords), (GLvoid*)((char*)quad.data() + sizeof(glm::vec3)));

    std::initializer_list<uint16_t> indices = { 0, 2, 1, 0, 3, 2 };
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, std::begin(indices));
    glBlendFunc(GL_ONE, GL_ONE);
}
