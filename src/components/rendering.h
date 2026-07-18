#pragma once
#include <memory>
#include <random>

#include "io/dataBuffer.h"
#include "graphics/texture.h"
#include "mesh.h"
#include "shaderRegistry.h"

struct MeshRef
{
    string name;
    Mesh* ptr = nullptr;
};
struct TextureRef
{
    string name;
    sp::Texture* ptr = nullptr;
};

class MeshRenderComponent
{
public:
    MeshRef mesh;
    TextureRef texture;
    TextureRef specular_texture;
    TextureRef illumination_texture;
    TextureRef normal_texture;
    glm::vec3 mesh_offset{};
    float scale = 1.0f;
    float bank_angle = 0.0f;
    glm::vec4 illumination_modulation{1.0f, 1.0f, 1.0f, 1.0f};

    Mesh* getMesh();
    sp::Texture* getTexture();
    sp::Texture* getSpecularTexture();
    sp::Texture* getIlluminationTexture();
    sp::Texture* getNormalTexture();
};

class EngineEmitter
{
public:
    float last_engine_particle_time = 0.0f;

    struct Emitter {
        glm::vec3 position{};
        glm::vec3 color{};
        float scale;
    };
    std::vector<Emitter> emitters;
    bool emitters_dirty = true;
};

class BillboardRenderer
{
public:
    string texture;
    float size = 512.0f;
};

class NebulaRenderer
{
public:
    struct Cloud
    {
        glm::vec2 offset{0, 0};
        TextureRef texture;
        float size = 512.0f;
    };

    float render_range = 10000.0f;
    float radius = 5000.0f;
    string skybox;
    float skybox_fade_distance = 1000.0f;
    glm::vec3 fog_color{0.02f, 0.01f, 0.03f};
    // Multiplier on cloud/fog volume alpha. 0.0 = invisible clouds, 1.0 = baseline, >1.0 = thicker.
    float cloud_density = 1.0f;
    // In-nebula visibility distance: the fog draw distance used when the camera is fully inside
    // the nebula. Lower values make objects fade out sooner while inside the cloud.
    float visibility_distance = 1000.0f;
    // Randomization seed for deterministic cloud generation.
    // When non-zero, clouds are generated locally from this seed whenever the seed
    // changes. Changing the seed in GM Tweaks immediately regenerates the clouds.
    // When seed is 0, no seed-based generation occurs; clouds must be set explicitly.
    uint32_t seed = 0;
    uint32_t last_generated_seed = 0;
    std::vector<Cloud> clouds;
    bool clouds_dirty = false;

    void generateCloudsFromSeed()
    {
        if (seed == 0 || seed == last_generated_seed) return;

        last_generated_seed = seed;
        clouds_dirty = false;
        std::mt19937_64 rng(seed);
        clouds.resize(900);

        for (auto& cloud : clouds)
        {
            const float size = std::uniform_real_distribution<float>(256.0f, 2048.0f)(rng);
            const float angle_deg = std::uniform_real_distribution<float>(0.0f, 360.0f)(rng);
            const float sqrt_factor = std::sqrt(std::uniform_real_distribution<float>(0.0f, 1.0f)(rng));
            const int tex_idx = std::uniform_int_distribution<>(1, 3)(rng);
            cloud.size = size;
            cloud.texture.name = "Nebula" + std::to_string(tex_idx) + ".png";
            const float angle_rad = angle_deg / 180.0f * glm::pi<float>();
            const float dist = sqrt_factor * (radius - size * 0.75f);
            cloud.offset = glm::vec2(std::cos(angle_rad) * dist, std::sin(angle_rad) * dist);
        }
    }
};

class ExplosionEffect
{
public:
    constexpr static float max_lifetime = 2.0f;
    constexpr static int particle_count = 1000;

    float lifetime = max_lifetime;
    float size = 1.0;
    glm::vec3 particle_directions[particle_count];
    bool radar = false;
    bool electrical = false;

    // Fit elements in a uint8 - at 4 vertices per quad, that's (256 / 4 =) 64 quads.
    static constexpr size_t max_quad_count = particle_count * 4;
    std::shared_ptr<gl::Buffers<2>> particles_buffers;
};


class PlanetRender
{
public:
    float size;
    float cloud_size;
    float atmosphere_size;
    string texture;
    string cloud_texture;
    string atmosphere_texture;
    glm::vec3 atmosphere_color{};
    float distance_from_movement_plane;
};
