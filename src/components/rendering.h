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

    bool advanced_explosion = false;

    constexpr static float max_lifetime = 2.f;
    constexpr static int particle_count = 1000;

    float lifetime = max_lifetime;
    float size = 1.0;
    glm::vec3 color{1.0,0.6,0.3};
    glm::vec3 particle_directions[particle_count];
    bool radar = false;
    ExplosionType type = ExplosionType::LargeThermal;
    bool electrical = false;

    // Fit elements in a uint8 - at 4 vertices per quad, that's (256 / 4 =) 64 quads.
    static constexpr size_t max_quad_count = particle_count * 4;
    std::shared_ptr<gl::Buffers<2>> particles_buffers;
};

class BillboardExplosion
{
public:
    constexpr static float default_lifetime = 1.0f;
    constexpr static int default_columns = 8;
    constexpr static int default_rows = 8;

    float lifetime = default_lifetime;
    float max_lifetime = default_lifetime;
    float size = 100.0f;
    float fps = 64.0f; // Animation speed (frames per second)
    int sprite_columns = default_columns;
    int sprite_rows = default_rows;
    glm::vec3 color = glm::vec3(1.0f, 1.0f, 1.0f);
    string texture = "texture/explosion_sprite.png";
    string flash_texture = ""; // Random flash texture, empty means pick one
    bool radar = false;
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
