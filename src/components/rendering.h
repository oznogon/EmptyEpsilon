#pragma once
#include <memory>

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
    float scale = 1.0;

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
    std::vector<Cloud> clouds;
    bool clouds_dirty = true;
};

class ExplosionEffect
{
public:
    enum class ExplosionType
    {
        SmallThermal,
        LargeThermal,
        Electric,
        Kinetic
    };

    // Bitwise mask for explosion rendering modes
    enum RenderMode : uint8_t
    {
        None = 0x00,
        Basic = 0x01,     // Original textured-sphere explosion
        Advanced = 0x02,  // Volumetric shader explosion
        Sprite = 0x04,    // Animated sprite sheet explosion
        Particles = 0x08, // Debris/spark particles
        Flash = 0x10      // Flash effect
    };

    constexpr static float max_lifetime = 2.f;
    constexpr static int particle_count = 1000;

    // Rendering mode mask
    uint8_t render_mode = Basic | Particles;

    // Generic properties
    float lifetime = max_lifetime;
    float size = 1.0f;
    glm::vec3 color{1.0f, 0.6f, 0.3f};
    glm::vec3 particle_directions[particle_count];
    bool radar = false;
    ExplosionType type = ExplosionType::LargeThermal;
    bool electrical = false;

    // Fit elements in a uint8 - at 4 vertices per quad, that's (256 / 4 =) 64 quads.
    static constexpr size_t max_quad_count = particle_count * 4;
    std::shared_ptr<gl::Buffers<2>> particles_buffers;

    // Sprite animation properties
    float fps = 64.0f;
    int sprite_columns = 8;
    int sprite_rows = 8;
    string sprite_texture = "texture/explosion_sprite.png";
    // Empty flash texture value results in random selection
    string flash_texture = "";
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
