#pragma once

#include "multiplayer/basic.h"
#include "components/utilityBeam.h"

// Macros don't allow us to destroy dependant entities, so implement replication manually
class UtilityBeamReplication : public sp::ecs::ComponentReplicationBase
{
    static constexpr float update_delay = 1.0f / 20.0f;
    struct Info
    {
        uint32_t version;
        float last_update = 0.0f;
        UtilityBeam data;
        sp::ecs::Entity tracked_effect_target; // Track for cleanup
    };
    sp::SparseSet<Info> info;

    void onEntityDestroyed(uint32_t index) override;
    void sendAll(sp::io::DataBuffer& packet) override;
    void update(sp::io::DataBuffer& packet) override;
    void receive(sp::ecs::Entity entity, sp::io::DataBuffer& packet) override;
    void remove(sp::ecs::Entity entity) override;
    template<BasicReplicationRequest> bool impl(sp::ecs::Entity entity, sp::io::DataBuffer& packet, UtilityBeam& c, UtilityBeam* backup);
    template<BasicReplicationRequest> void field_impl(sp::ecs::Entity entity, sp::io::DataBuffer& packet, UtilityBeam& c, UtilityBeam* backup, sp::io::DataBuffer& tmp, uint64_t& flags);
};

BASIC_REPLICATION_CLASS(UtilityBeamEffectReplication, UtilityBeamEffect);
