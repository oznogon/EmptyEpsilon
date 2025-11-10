#include "multiplayer/rendering.h"
#include "multiplayer.h"

namespace sp::io {
    static inline DataBuffer& operator << (DataBuffer& packet, const EngineEmitter::Emitter& e) { return packet << e.position << e.color << e.scale; } \
    static inline DataBuffer& operator >> (DataBuffer& packet, EngineEmitter::Emitter& e) { packet >> e.position >> e.color >> e.scale; return packet; }
    static inline DataBuffer& operator << (DataBuffer& packet, const NebulaRenderer::Cloud& c) { return packet << c.offset << c.texture.name << c.size; } \
    static inline DataBuffer& operator >> (DataBuffer& packet, NebulaRenderer::Cloud& c) { packet >> c.offset >> c.texture.name >> c.size; return packet; }
}

BASIC_REPLICATION_IMPL(MeshRenderComponentReplication, MeshRenderComponent)
    // Config fields: 1Hz
    CONFIG_REPLICATION_FIELD(mesh.name);
    CONFIG_REPLICATION_FIELD(texture.name);
    CONFIG_REPLICATION_FIELD(specular_texture.name);
    CONFIG_REPLICATION_FIELD(illumination_texture.name);
    CONFIG_REPLICATION_FIELD(mesh_offset);

    // System field: 5Hz with epsilon tolerance
    SYSTEM_REPLICATION_FIELD_EPSILON(scale, 0.01f);
}

BASIC_REPLICATION_IMPL(EngineEmitterReplication, EngineEmitter)
    REPLICATE_VECTOR_IF_DIRTY(emitters, emitters_dirty);
}
BASIC_REPLICATION_IMPL(NebulaRendererReplication, NebulaRenderer)
    // Config fields: 1Hz with epsilon tolerance
    CONFIG_REPLICATION_FIELD_EPSILON(render_range, 1.0f);

    REPLICATE_VECTOR_IF_DIRTY(clouds, clouds_dirty);
}
BASIC_REPLICATION_IMPL(ExplosionEffectReplication, ExplosionEffect)
    // Config fields: 1Hz with epsilon tolerance
    CONFIG_REPLICATION_FIELD_EPSILON(size, 1.0f);
    CONFIG_REPLICATION_FIELD(radar);
    CONFIG_REPLICATION_FIELD(electrical);
}
BASIC_REPLICATION_IMPL(PlanetRenderReplication, PlanetRender)
    // Config fields: 1Hz with epsilon tolerance
    CONFIG_REPLICATION_FIELD_EPSILON(size, 1.0f);
    CONFIG_REPLICATION_FIELD_EPSILON(cloud_size, 1.0f);
    CONFIG_REPLICATION_FIELD_EPSILON(atmosphere_size, 1.0f);
    CONFIG_REPLICATION_FIELD(texture);
    CONFIG_REPLICATION_FIELD(cloud_texture);
    CONFIG_REPLICATION_FIELD(atmosphere_texture);
    CONFIG_REPLICATION_FIELD(atmosphere_color);
    CONFIG_REPLICATION_FIELD_EPSILON(distance_from_movement_plane, 1.0f);
}