#include "systems/rendering.h"
#include "components/rendering.h"
#include "textureManager.h"
#include "vectorUtils.h"
#include "shaderRegistry.h"
#include <graphics/opengl.h>
#include <glm/gtc/type_ptr.hpp>
#include "tween.h"
#include "random.h"
#include "gameGlobalInfo.h"


std::vector<RenderSystem::RenderHandler> RenderSystem::render_handlers;

void RenderSystem::render3D(float aspect, float camera_fov)
{
    view_vector = vec2FromAngle(camera_yaw);
    depth_cutoff_back = camera_position.z * -tanf(glm::radians(90+camera_pitch + camera_fov/2.f));
    depth_cutoff_front = camera_position.z * -tanf(glm::radians(90+camera_pitch - camera_fov/2.f));
    if (camera_pitch - camera_fov/2.f <= 0.f)
        depth_cutoff_front = std::numeric_limits<float>::infinity();
    if (camera_pitch + camera_fov/2.f >= 180.f)
        depth_cutoff_back = -std::numeric_limits<float>::infinity();
    for(auto& handler : render_handlers)
        (this->*(handler.func))(handler.rif);

    for(int n=render_lists.size() - 1; n >= 0; n--)
    {
        auto& render_list = render_lists[n];
        std::sort(render_list.begin(), render_list.end(), [](const RenderEntry& a, const RenderEntry& b) { return a.depth > b.depth; });

        auto projection = glm::perspective(glm::radians(camera_fov), aspect, 1.f, 25000.f * (n + 1));
        // Update projection matrix in shaders.
        ShaderRegistry::updateProjectionView(projection, {});

        glDepthMask(true);
        glDisable(GL_BLEND);
        for(auto info : render_list)
            if (!info.transparent)
                info.call_rif(info.rif, info.entity, *info.transform, info.component_ptr);
        glEnable(GL_BLEND);
        glBlendFunc(GL_ONE, GL_ONE);
        glDepthMask(false);
        for(auto info : render_list)
            if (info.transparent)
                info.call_rif(info.rif, info.entity, *info.transform, info.component_ptr);
    }
}

glm::mat4 calculateModelMatrix(glm::vec2 position, float rotation, glm::vec3 mesh_offset, float scale) {
    auto model_matrix = glm::translate(glm::identity<glm::mat4>(), glm::vec3{ position.x, position.y, 0.f });
    model_matrix = glm::rotate(model_matrix, glm::pi<float>(), glm::vec3{ 0.f, 0.f, 1.f });
    model_matrix = glm::rotate(model_matrix, glm::radians(rotation), glm::vec3{ 0.f, 0.f, 1.f });
    model_matrix = glm::translate(model_matrix, mesh_offset);
    model_matrix = glm::scale(model_matrix, glm::vec3{scale});

    return model_matrix;
}

ShaderRegistry::ScopedShader lookUpShader(MeshRenderComponent& mrc)
{
    auto shader_id = ShaderRegistry::Shaders::Object;
    if (mrc.getNormalTexture()) {
        if (mrc.getTexture() && mrc.getSpecularTexture() && mrc.getIlluminationTexture())
            shader_id = ShaderRegistry::Shaders::ObjectSpecularIlluminationNormal;
        else if (mrc.getTexture() && mrc.getSpecularTexture())
            shader_id = ShaderRegistry::Shaders::ObjectSpecularNormal;
        else if (mrc.getTexture() && mrc.getIlluminationTexture())
            shader_id = ShaderRegistry::Shaders::ObjectIlluminationNormal;
        else
            shader_id = ShaderRegistry::Shaders::ObjectNormal;
    } else {
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
    if (mrc.getTexture())
        mrc.getTexture()->bind();

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

    // wut iz?
    if (mrc.getSpecularTexture() || mrc.getIlluminationTexture())
        glActiveTexture(GL_TEXTURE0);
}

void MeshRenderSystem::update(float delta)
{
}

void MeshRenderSystem::render3D(sp::ecs::Entity e, sp::Transform& transform, MeshRenderComponent& mrc)
{
    auto model_matrix = calculateModelMatrix(
            transform.getPosition(),
            transform.getRotation(),
            mrc.mesh_offset,
            mrc.scale);

    auto shader = lookUpShader(mrc);
    glUniformMatrix4fv(shader.get().uniform(ShaderRegistry::Uniforms::Model), 1, GL_FALSE, glm::value_ptr(model_matrix));

    auto modeldata_matrix = glm::rotate(model_matrix, glm::radians(180.f), {0.f, 0.f, 1.f});
    modeldata_matrix = glm::scale(modeldata_matrix, glm::vec3{mrc.scale});

    // Lights setup.
    ShaderRegistry::setupLights(shader.get(), modeldata_matrix);

    // Textures
    activateAndBindMeshTextures(mrc);

    // Draw
    drawMesh(mrc, shader);

}

void NebulaRenderSystem::update(float delta)
{
}

void NebulaRenderSystem::render3D(sp::ecs::Entity e, sp::Transform& transform, NebulaRenderer& nr)
{
    ShaderRegistry::ScopedShader shader(ShaderRegistry::Shaders::Billboard);

    struct VertexAndTexCoords
    {
        glm::vec3 vertex;
        glm::vec2 texcoords;
    };
    std::array<VertexAndTexCoords, 4> quad{
        glm::vec3{}, {0.f, 1.f},
        glm::vec3{}, {1.f, 1.f},
        glm::vec3{}, {1.f, 0.f},
        glm::vec3{}, {0.f, 0.f}
    };

    gl::ScopedVertexAttribArray positions(shader.get().attribute(ShaderRegistry::Attributes::Position));
    gl::ScopedVertexAttribArray texcoords(shader.get().attribute(ShaderRegistry::Attributes::Texcoords));

    for(auto& cloud : nr.clouds)
    {
        glm::vec3 position = glm::vec3(transform.getPosition().x, transform.getPosition().y, 0) + glm::vec3(cloud.offset.x, cloud.offset.y, 0);
        float size = cloud.size;

        float distance = glm::length(camera_position - position);
        float alpha = 1.0f - (distance / nr.render_range);
        if (alpha < 0.0f)
            continue;

        // setup our quad.
        for (auto& point : quad)
        {
            point.vertex = position;
        }

        if (!cloud.texture.ptr)
            cloud.texture.ptr = textureManager.getTexture(cloud.texture.name);
        if (cloud.texture.ptr)
            cloud.texture.ptr->bind();
        glUniform4f(shader.get().uniform(ShaderRegistry::Uniforms::Color), alpha * 0.8f, alpha * 0.8f, alpha * 0.8f, size);
        auto cloud_model_matrix = glm::translate(glm::identity<glm::mat4>(), {cloud.offset.x, cloud.offset.y, 0});
        glUniformMatrix4fv(shader.get().uniform(ShaderRegistry::Uniforms::Model), 1, GL_FALSE, glm::value_ptr(cloud_model_matrix));

        glVertexAttribPointer(positions.get(), 3, GL_FLOAT, GL_FALSE, sizeof(VertexAndTexCoords), (GLvoid*)quad.data());
        glVertexAttribPointer(texcoords.get(), 2, GL_FLOAT, GL_FALSE, sizeof(VertexAndTexCoords), (GLvoid*)((char*)quad.data() + sizeof(glm::vec3)));
        std::initializer_list<uint16_t> indices = { 0, 3, 2, 0, 2, 1 };
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, std::begin(indices));
    }
}

void ExplosionRenderSystem::update(float delta)
{
    for (auto [entity, ee] : sp::ecs::Query<ExplosionEffect>())
    {
        ee.lifetime -= delta;
        if (ee.lifetime < 0.0f) entity.destroy();
    }
}

void ExplosionRenderSystem::render3D(sp::ecs::Entity e, sp::Transform& transform, ExplosionEffect& ee)
{
    float f = (1.0f - (ee.lifetime / ee.max_lifetime));

    // Different scale rates for each element
    float particles_scale = f * 3.0f;
    float sphere_scale = f * 1.2f;
    float fire_ring_scale = f * 1.5f;

    if (ee.type == ExplosionEffect::ExplosionType::Electric)
    {
        sphere_scale = f;
        particles_scale = f * 2.0f;
    }

    if (ee.type == ExplosionEffect::ExplosionType::Kinetic)
        particles_scale = f;

    // Different fade rates for each element (particles fade first, then sphere, then fire ring)
    // Particles: start fading at 40% progress, fully faded by 70%
    float particles_alpha = 1.0f - glm::clamp((f - 0.4f) / 0.3f, 0.0f, 1.0f);

    // Sphere/Sprite: start fading at 60% progress, fully faded by 90%
    float sphere_alpha = 1.0f - glm::clamp((f - 0.6f) / 0.3f, 0.0f, 1.0f);

    // Fire ring: start fading at 70% progress, fully faded by 100%
    float fire_ring_alpha = 1.0f - glm::clamp((f - 0.7f) / 0.3f, 0.0f, 1.0f);

    auto position = transform.getPosition();
    auto rotation = transform.getRotation();
    auto model_matrix = glm::translate(glm::identity<glm::mat4>(), glm::vec3{ position.x, position.y, 0.f });
    model_matrix = glm::rotate(model_matrix, glm::radians(rotation), glm::vec3{ 0.f, 0.f, 1.f });

    // Create separate matrices for each element with different scales
    auto sphere_matrix = glm::scale(model_matrix, glm::vec3(sphere_scale * ee.size));
    auto particles_matrix = glm::scale(model_matrix, glm::vec3(particles_scale * ee.size));
    auto fire_ring_matrix = glm::scale(model_matrix, glm::vec3(fire_ring_scale * ee.size));

    // Render animated sprite billboard explosion
    if (ee.render_mode & ExplosionEffect::Sprite)
    {
        struct VertexAndTexCoords
        {
            glm::vec3 vertex;
            glm::vec2 texcoords;
        };
        static std::array<VertexAndTexCoords, 4> quad{
            glm::vec3{}, {0.f, 1.f},
            glm::vec3{}, {1.f, 1.f},
            glm::vec3{}, {1.f, 0.f},
            glm::vec3{}, {0.f, 0.f}
        };

        // Bind texture
        textureManager.getTexture(ee.sprite_texture)->bind();

        // Use the animated billboard shader
        ShaderRegistry::ScopedShader shader(ShaderRegistry::Shaders::BillboardAnimated);

        // Set uniforms (sprite scales at same rate as sphere)
        glUniformMatrix4fv(shader.get().uniform(ShaderRegistry::Uniforms::Model), 1, GL_FALSE, glm::value_ptr(model_matrix));
        glUniform4f(shader.get().uniform(ShaderRegistry::Uniforms::Color), ee.color.r, ee.color.g, ee.color.b, ee.size * sphere_scale * 3.0f);

        // Calculate current frame based on lifetime and FPS
        float time_elapsed = ee.max_lifetime - ee.lifetime;
        int total_frames = ee.sprite_columns * ee.sprite_rows;
        int current_frame = static_cast<int>(time_elapsed * ee.fps);
        // Clamp to last frame instead of wrapping (explosions play once)
        if (current_frame >= total_frames)
            current_frame = total_frames - 1;

        // Set sprite sheet parameters (columns, rows, current frame, unused)
        glUniform4f(shader.get().uniform(ShaderRegistry::Uniforms::SpriteSheetParams),
            static_cast<float>(ee.sprite_columns),
            static_cast<float>(ee.sprite_rows),
            static_cast<float>(current_frame),
            0.0f);

        // Set up vertex attributes
        gl::ScopedVertexAttribArray positions(shader.get().attribute(ShaderRegistry::Attributes::Position));
        gl::ScopedVertexAttribArray texcoords(shader.get().attribute(ShaderRegistry::Attributes::Texcoords));

        // Use alpha blending for smooth edges
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        glVertexAttribPointer(positions.get(), 3, GL_FLOAT, GL_FALSE, sizeof(VertexAndTexCoords), (GLvoid*)quad.data());
        glVertexAttribPointer(texcoords.get(), 2, GL_FLOAT, GL_FALSE, sizeof(VertexAndTexCoords), (GLvoid*)((char*)quad.data() + sizeof(glm::vec3)));

        std::initializer_list<uint16_t> indices = { 0, 2, 1, 0, 3, 2 };
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, std::begin(indices));

        // Render flash effect if enabled
        if (ee.render_mode & ExplosionEffect::Flash)
        {
            // Pick random flash texture if not already set
            if (ee.flash_texture.empty())
            {
                int flash_index = rand() % 9; // 0-8
                ee.flash_texture = "texture/kenney_smoke-particles/PNG/Flash/flash0" + std::to_string(flash_index) + ".png";
            }

            // Calculate animation progress (0.0 to 1.0)
            float progress = (ee.max_lifetime - ee.lifetime) / ee.max_lifetime;

            // Linear scaling
            float flash_scale = Tween<float>::easeInOutExponential(progress, 0.0f, 0.5f, 0.0f, 0.15f);

            // Fade out
            float flash_alpha = Tween<float>::easeInOutExponential(progress, 0.0f, 0.5f, 1.0f, 0.0f);

            // Use additive blending for the flash
            glBlendFunc(GL_ONE, GL_ONE);

            // Use basic billboard shader
            ShaderRegistry::ScopedShader flash_shader(ShaderRegistry::Shaders::Billboard);

            // Bind flash texture
            textureManager.getTexture(ee.flash_texture)->bind();

            // Set uniforms - size in alpha channel, RGB for color/intensity
            glUniformMatrix4fv(flash_shader.get().uniform(ShaderRegistry::Uniforms::Model), 1, GL_FALSE, glm::value_ptr(model_matrix));
            glUniform4f(flash_shader.get().uniform(ShaderRegistry::Uniforms::Color),
                        flash_alpha, flash_alpha, flash_alpha, ee.size * flash_scale * 2.0f);

            // Set up vertex attributes
            gl::ScopedVertexAttribArray flash_positions(flash_shader.get().attribute(ShaderRegistry::Attributes::Position));
            gl::ScopedVertexAttribArray flash_texcoords(flash_shader.get().attribute(ShaderRegistry::Attributes::Texcoords));

            glVertexAttribPointer(flash_positions.get(), 3, GL_FLOAT, GL_FALSE, sizeof(VertexAndTexCoords), (GLvoid*)quad.data());
            glVertexAttribPointer(flash_texcoords.get(), 2, GL_FLOAT, GL_FALSE, sizeof(VertexAndTexCoords), (GLvoid*)((char*)quad.data() + sizeof(glm::vec3)));

            glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, std::begin(indices));
        }

        // Restore additive blending for other effects
        glBlendFunc(GL_ONE, GL_ONE);
    }

    // Render volumetric explosion shader (Advanced mode only)
    if ((ee.render_mode & ExplosionEffect::Advanced) && ee.type != ExplosionEffect::ExplosionType::Kinetic)
    {
        struct VertexAndTexCoords
        {
            glm::vec3 vertex;
            glm::vec2 texcoords;
        };
        static std::array<VertexAndTexCoords, 4> quad{
            glm::vec3{}, {0.f, 1.f},
            glm::vec3{}, {1.f, 1.f},
            glm::vec3{}, {1.f, 0.f},
            glm::vec3{}, {0.f, 0.f}
        };

        ShaderRegistry::ScopedShader shader(ShaderRegistry::Shaders::VolumetricExplosion);

        if (ee.type == ExplosionEffect::ExplosionType::Electric)
            glUniform3f(shader.get().uniform(ShaderRegistry::Uniforms::StartColor), 0.6f, 0.6f, 1.0f);
        else
            glUniform3f(shader.get().uniform(ShaderRegistry::Uniforms::StartColor), ee.color.r, ee.color.g, ee.color.b);

        // Set model matrix (position only, billboard handles rotation and scale)
        glUniformMatrix4fv(shader.get().uniform(ShaderRegistry::Uniforms::Model), 1, GL_FALSE, glm::value_ptr(model_matrix));

        // Set billboard size (scale of the explosion) based on sphere scale
        float billboardSize = sphere_scale * ee.size * 3.0f;
        glUniform1f(shader.get().uniform(ShaderRegistry::Uniforms::BillboardSize), billboardSize);

        // Get viewport dimensions
        GLint viewport[4];
        glGetIntegerv(GL_VIEWPORT, viewport);
        float viewportWidth = static_cast<float>(viewport[2]);
        float viewportHeight = static_cast<float>(viewport[3]);
        glUniform2f(shader.get().uniform(ShaderRegistry::Uniforms::Resolution),
                    viewportWidth, viewportHeight);

        // Calculate quality factor based on screen-space coverage
        // Small on screen (far) = high quality (1.0), Large (close) = low quality (0.3)
        // Quality ranges from 1.0 (< 1% coverage) to 0.3 (> 20% coverage)
        float qualityFactor = glm::clamp(1.0f - ((billboardSize * billboardSize) / (viewportWidth * viewportHeight) - 0.01f) / 0.19f, 0.3f, 1.0f);
        glUniform1f(shader.get().uniform(ShaderRegistry::Uniforms::QualityFactor), qualityFactor);

        // Set time uniform based on explosion progress (0 to max_lifetime)
        // Multiply by speed factor to complete animation within lifetime
        float explosion_time = (ee.max_lifetime - ee.lifetime) * 10.0f;
        if (ee.type != ExplosionEffect::ExplosionType::Electric) explosion_time /= 2.0f;

        glUniform1f(shader.get().uniform(ShaderRegistry::Uniforms::Time), explosion_time);

        // Set alpha for fade effect
        glUniform1f(shader.get().uniform(ShaderRegistry::Uniforms::ExplosionAlpha), sphere_alpha);

        // Bind noise texture for volumetric effect
        textureManager.getTexture("texture/rgbnoise.png")->bind();

        gl::ScopedVertexAttribArray positions(shader.get().attribute(ShaderRegistry::Attributes::Position));
        gl::ScopedVertexAttribArray texcoords(shader.get().attribute(ShaderRegistry::Attributes::Texcoords));
        gl::ScopedVertexAttribArray normals(shader.get().attribute(ShaderRegistry::Attributes::Normal));
        gl::ScopedVertexAttribArray tangents(shader.get().attribute(ShaderRegistry::Attributes::Tangent));

        // Use additive blending for bloom effect
        glBlendFunc(GL_SRC_ALPHA, GL_ONE);

        glVertexAttribPointer(positions.get(), 3, GL_FLOAT, GL_FALSE, sizeof(VertexAndTexCoords), (GLvoid*)quad.data());
        glVertexAttribPointer(texcoords.get(), 2, GL_FLOAT, GL_FALSE, sizeof(VertexAndTexCoords), (GLvoid*)((char*)quad.data() + sizeof(glm::vec3)));

        std::initializer_list<uint16_t> indices = { 0, 2, 1, 0, 3, 2 };
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, std::begin(indices));

        // Restore default blending
        glBlendFunc(GL_ONE, GL_ONE);
    }

    // Render textured sphere explosion with vertex noise (basic mode)
    if ((ee.render_mode & ExplosionEffect::Basic) && ee.type != ExplosionEffect::ExplosionType::Kinetic)
    {
        ShaderRegistry::ScopedShader shader(ShaderRegistry::Shaders::ExplosionSphere);

        glUniformMatrix4fv(shader.get().uniform(ShaderRegistry::Uniforms::Model), 1, GL_FALSE, glm::value_ptr(sphere_matrix));
        glUniform4f(shader.get().uniform(ShaderRegistry::Uniforms::Color), sphere_alpha, sphere_alpha, sphere_alpha, 1.f);

        // Scroll texture over time based on explosion progress
        float scrollSpeed = ee.type == ExplosionEffect::ExplosionType::Electric ? 0.5f : 1.0f;
        float scrollOffset = (ee.max_lifetime - ee.lifetime) * scrollSpeed;
        glUniform1f(shader.get().uniform(ShaderRegistry::Uniforms::ScrollOffset), scrollOffset);

        // Time for noise animation (0 to max_lifetime)
        float explosion_time = (ee.max_lifetime - ee.lifetime);
        glUniform1f(shader.get().uniform(ShaderRegistry::Uniforms::Time), explosion_time);

        // Sphere vertex noise scales up over time
        glUniform1f(shader.get().uniform(ShaderRegistry::Uniforms::NoiseScale), f * 0.12f);

        if (ee.type == ExplosionEffect::ExplosionType::Electric)
            textureManager.getTexture("texture/electric_sphere_texture.png")->bind();
        else
            textureManager.getTexture("texture/fire_sphere_texture.png")->bind();

        gl::ScopedVertexAttribArray positions(shader.get().attribute(ShaderRegistry::Attributes::Position));
        gl::ScopedVertexAttribArray texcoords(shader.get().attribute(ShaderRegistry::Attributes::Texcoords));
        gl::ScopedVertexAttribArray normals(shader.get().attribute(ShaderRegistry::Attributes::Normal));
        gl::ScopedVertexAttribArray tangents(shader.get().attribute(ShaderRegistry::Attributes::Tangent));

        Mesh* m = Mesh::getMesh("mesh/sphere.obj");
        m->render(positions.get(), texcoords.get(), normals.get(), tangents.get());

        if (ee.type == ExplosionEffect::ExplosionType::Electric)
        {
            glUniformMatrix4fv(shader.get().uniform(ShaderRegistry::Uniforms::Model), 1, GL_FALSE, glm::value_ptr(glm::scale(sphere_matrix, glm::vec3(.5f))));
            m->render(positions.get(), texcoords.get(), normals.get(), tangents.get());
        }
    }
    std::vector<glm::vec3> vertices(4 * ee.max_quad_count);
    std::vector<glm::vec3> normals(4 * ee.max_quad_count);

    if (!ee.particles_buffers)
    {
        for (int n = 0; n < ee.particle_count; n++)
            ee.particle_directions[n] = glm::normalize(glm::vec3(random(-1, 1), random(-1, 1), random(-1, 1))) * random(0.8f, 1.2f);

        ee.particles_buffers = std::make_shared<gl::Buffers<2>>();

        // Each vertex is a position, texcoords, and normal (direction).
        // The arrays are maintained separately (texcoords are fixed, vertices and normals change).
        constexpr size_t vertex_size = sizeof(glm::vec3) + sizeof(glm::vec2) + sizeof(glm::vec3);
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

    // Fire ring with basic shader
    if (ee.type == ExplosionEffect::ExplosionType::LargeThermal)
    {
        ShaderRegistry::ScopedShader shader(ShaderRegistry::Shaders::Basic);
        textureManager.getTexture("texture/fire_ring.png")->bind();

        glUniformMatrix4fv(shader.get().uniform(ShaderRegistry::Uniforms::Model), 1, GL_FALSE, glm::value_ptr(fire_ring_matrix));
        glUniform4f(shader.get().uniform(ShaderRegistry::Uniforms::Color), fire_ring_alpha, fire_ring_alpha, fire_ring_alpha, 1.f);

        vertices[0] = glm::vec3(-1, -1, 0);
        vertices[1] = glm::vec3( 1, -1, 0);
        vertices[2] = glm::vec3( 1,  1, 0);
        vertices[3] = glm::vec3(-1,  1, 0);

        {
            gl::ScopedVertexAttribArray positions(shader.get().attribute(ShaderRegistry::Attributes::Position));
            gl::ScopedVertexAttribArray texcoords(shader.get().attribute(ShaderRegistry::Attributes::Texcoords));

            glVertexAttribPointer(positions.get(), 3, GL_FLOAT, GL_FALSE, sizeof(glm::vec3), (GLvoid*)0);
            glVertexAttribPointer(texcoords.get(), 2, GL_FLOAT, GL_FALSE, sizeof(glm::vec2), (GLvoid*)(vertices.size() * sizeof(glm::vec3)));

            // upload single vertex
            glBufferSubData(GL_ARRAY_BUFFER, 0, 4 * sizeof(glm::vec3), vertices.data());

            glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, nullptr);
        }
    }

    // Debris/spark particles
    if ((ee.render_mode & ExplosionEffect::Particles) && ee.type != ExplosionEffect::ExplosionType::SmallThermal)
    {
        ShaderRegistry::ScopedShader shader(ShaderRegistry::Shaders::Billboard);
        glUniformMatrix4fv(shader.get().uniform(ShaderRegistry::Uniforms::Model), 1, GL_FALSE, glm::value_ptr(model_matrix));

        gl::ScopedVertexAttribArray positions(shader.get().attribute(ShaderRegistry::Attributes::Position));
        gl::ScopedVertexAttribArray texcoords(shader.get().attribute(ShaderRegistry::Attributes::Texcoords));
        gl::ScopedVertexAttribArray normals_attrib(shader.get().attribute(ShaderRegistry::Attributes::Normal));

        // textureManager.getTexture("particle.png")->bind();
        textureManager.getTexture("texture/trace_01.png")->bind();

        float r = 0.0f;
        float g = 0.0f;
        float b = 0.0f;

        if (ee.type == ExplosionEffect::ExplosionType::Electric)
        {
            r = Tween<float>::easeOutSine(f, 0.f, 1.f, 1.0f, 0.0f) * particles_alpha;
            g = Tween<float>::easeOutSine(f, 0.f, 1.f, 1.0f, 0.0f) * particles_alpha;
            b = Tween<float>::easeOutSine(f, 0.f, 1.f, 1.0f, 0.5f) * particles_alpha;
        }
        else if (ee.type == ExplosionEffect::ExplosionType::Kinetic)
        {
            r = Tween<float>::easeOutSine(f, 0.f, 1.f, 1.0f, 0.0f) * particles_alpha;
            g = Tween<float>::easeOutSine(f, 0.f, 1.f, 1.0f, 0.0f) * particles_alpha;
            b = Tween<float>::easeOutSine(f, 0.f, 1.f, 1.0f, 0.0f) * particles_alpha;
        }
        else
        {
            r = Tween<float>::easeOutSine(f, 0.f, 1.f, 1.0f, 0.5f) * particles_alpha;
            g = Tween<float>::easeOutSine(f, 0.f, 1.f, 1.0f, 0.0f) * particles_alpha;
            b = Tween<float>::easeOutSine(f, 0.f, 1.f, 1.0f, 0.0f) * particles_alpha;
        }

        // Size and color each individual particle.
        glUniform4f(shader.get().uniform(ShaderRegistry::Uniforms::Color), r, g, b, ee.size / 8.0f);

        // Set up vertex attribute pointers
        // Layout: positions, texcoords, normals
        size_t texcoords_offset = vertices.size() * sizeof(glm::vec3);
        size_t normals_offset = texcoords_offset + (vertices.size() * sizeof(glm::vec2));

        glVertexAttribPointer(positions.get(), 3, GL_FLOAT, GL_FALSE, sizeof(glm::vec3), (GLvoid*)0);
        glVertexAttribPointer(texcoords.get(), 2, GL_FLOAT, GL_FALSE, sizeof(glm::vec2), (GLvoid*)texcoords_offset);
        glVertexAttribPointer(normals_attrib.get(), 3, GL_FLOAT, GL_FALSE, sizeof(glm::vec3), (GLvoid*)normals_offset);

        const size_t quad_count = ee.max_quad_count;
        // We're drawing particles `quad_count` at a time.
        for (size_t n = 0; n < ee.particle_count;)
        {
            auto active_quads = std::min(quad_count, ee.particle_count - n);
            // setup quads
            for (auto p = 0U; p < active_quads; ++p)
            {
                glm::vec3 v = ee.particle_directions[n + p] * particles_scale * ee.size;
                glm::vec3 dir = ee.particle_directions[n + p];

                // All 4 vertices of the quad share the same position and direction
                vertices[4 * p + 0] = v;
                vertices[4 * p + 1] = v;
                vertices[4 * p + 2] = v;
                vertices[4 * p + 3] = v;

                normals[4 * p + 0] = dir;
                normals[4 * p + 1] = dir;
                normals[4 * p + 2] = dir;
                normals[4 * p + 3] = dir;
            }
            // upload positions and normals
            glBufferSubData(GL_ARRAY_BUFFER, 0, vertices.size() * sizeof(glm::vec3), vertices.data());
            glBufferSubData(GL_ARRAY_BUFFER, normals_offset, normals.size() * sizeof(glm::vec3), normals.data());

            glDrawElements(GL_TRIANGLES, static_cast<GLsizei>(6 * active_quads), GL_UNSIGNED_SHORT, nullptr);
            n += active_quads;
        }
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
        glm::vec3{}, {0.f, 1.f},
        glm::vec3{}, {1.f, 1.f},
        glm::vec3{}, {1.f, 0.f},
        glm::vec3{}, {0.f, 0.f}
    };

    textureManager.getTexture(bbr.texture)->bind();
    ShaderRegistry::ScopedShader shader(ShaderRegistry::Shaders::Billboard);

    auto position = transform.getPosition();
    auto rotation = transform.getRotation();
    auto model_matrix = glm::translate(glm::identity<glm::mat4>(), glm::vec3{ position.x, position.y, 0.f });
    model_matrix = glm::rotate(model_matrix, glm::radians(rotation), glm::vec3{ 0.f, 0.f, 1.f });

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
