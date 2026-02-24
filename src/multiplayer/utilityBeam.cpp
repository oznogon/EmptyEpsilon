#include "multiplayer/utilityBeam.h"
#include "multiplayer.h"
#include "ecs/query.h"
#include "engine.h"

void UtilityBeamReplication::onEntityDestroyed(uint32_t index)
{
    // Clean up the tracked effect_target_entity when the parent entity is destroyed
    if (info.has(index))
    {
        auto& entity_info = info.get(index);

        if (entity_info.tracked_effect_target)
            entity_info.tracked_effect_target.destroy();
    }

    info.remove(index);
}

void UtilityBeamReplication::sendAll(sp::io::DataBuffer& packet)
{
    for (auto [entity, data] : sp::ecs::Query<UtilityBeam>())
        impl<BasicReplicationRequest::SendAll>(entity, packet, data, nullptr);
}

void UtilityBeamReplication::update(sp::io::DataBuffer& packet)
{
    auto now = engine->getElapsedTime();
    for (auto [entity, data] : sp::ecs::Query<UtilityBeam>())
    {
        if (!info.has(entity.getIndex()))
        {
            info.set(entity.getIndex(), {entity.getVersion(), now, data, data.effect_target_entity});
            impl<BasicReplicationRequest::SendAll>(entity, packet, data, nullptr);
        }
        else
        {
            auto& entity_info = info.get(entity.getIndex());
            // Update the tracked effect_target_entity
            entity_info.tracked_effect_target = data.effect_target_entity;

            if (entity_info.version != entity.getVersion())
            {
                entity_info.data = data;
                entity_info.version = entity.getVersion();
                entity_info.last_update = now;
                impl<BasicReplicationRequest::SendAll>(entity, packet, data, nullptr);
            }
            else if (entity_info.last_update + update_delay <= now)
            {
                if (impl<BasicReplicationRequest::Update>(entity, packet, data, &entity_info.data))
                    entity_info.last_update = now;
            }
        }
    }

    for (auto [index, entity_info] : info)
    {
        if (!sp::ecs::Entity::forced(index, entity_info.version).hasComponent<UtilityBeam>())
        {
            // Clean up tracked effect_target_entity when component is removed
            if (entity_info.tracked_effect_target)
                entity_info.tracked_effect_target.destroy();

            info.remove(index);
            packet << CMD_ECS_DEL_COMPONENT << component_index << index;
        }
    }
}

void UtilityBeamReplication::receive(sp::ecs::Entity entity, sp::io::DataBuffer& packet)
{
    impl<BasicReplicationRequest::Receive>(entity, packet, entity.getOrAddComponent<UtilityBeam>(), nullptr);
}

void UtilityBeamReplication::remove(sp::ecs::Entity entity)
{
    entity.removeComponent<UtilityBeam>();
}

template<BasicReplicationRequest BRR> bool UtilityBeamReplication::impl(sp::ecs::Entity entity, sp::io::DataBuffer& packet, UtilityBeam& target, UtilityBeam* backup)
{
    sp::io::DataBuffer tmp;
    uint64_t flags = 0;
    if (BRR == BasicReplicationRequest::Receive) packet >> flags;
    field_impl<BRR>(entity, packet, target, backup, tmp, flags);
    if (tmp.getDataSize() > 0) packet.write(CMD_ECS_SET_COMPONENT, component_index, entity.getIndex(), flags, tmp);
    return tmp.getDataSize() > 0;
}

template<BasicReplicationRequest BRR> void UtilityBeamReplication::field_impl(sp::ecs::Entity entity, sp::io::DataBuffer& packet, UtilityBeam& target, UtilityBeam* backup, sp::io::DataBuffer& tmp, uint64_t& flags)
{
    uint64_t flag = 1;
    BASIC_REPLICATION_FIELD(health);
    BASIC_REPLICATION_FIELD(health_max);
    BASIC_REPLICATION_FIELD(power_level);
    BASIC_REPLICATION_FIELD(power_request);
    BASIC_REPLICATION_FIELD(heat_level);
    BASIC_REPLICATION_FIELD(coolant_level);
    BASIC_REPLICATION_FIELD(coolant_request);
    BASIC_REPLICATION_FIELD(can_be_hacked);
    BASIC_REPLICATION_FIELD(hacked_level);
    BASIC_REPLICATION_FIELD(power_factor);
    BASIC_REPLICATION_FIELD(coolant_change_rate_per_second);
    BASIC_REPLICATION_FIELD(heat_add_rate_per_second);
    BASIC_REPLICATION_FIELD(power_change_rate_per_second);
    BASIC_REPLICATION_FIELD(auto_repair_per_second);
    BASIC_REPLICATION_FIELD(damage_per_second_on_overheat);

    BASIC_REPLICATION_FIELD(active);
    BASIC_REPLICATION_FIELD(is_firing);
    BASIC_REPLICATION_FIELD(position);
    BASIC_REPLICATION_FIELD(arc);
    BASIC_REPLICATION_FIELD(max_arc);
    BASIC_REPLICATION_FIELD(bearing);
    BASIC_REPLICATION_FIELD(fixed_bearing);
    BASIC_REPLICATION_FIELD(range);
    BASIC_REPLICATION_FIELD(max_range);
    BASIC_REPLICATION_FIELD(cycle_time);
    BASIC_REPLICATION_FIELD(strength);
    BASIC_REPLICATION_FIELD(energy_use_per_second);
    BASIC_REPLICATION_FIELD(heat_per_second);
    BASIC_REPLICATION_FIELD(arc_color);
    BASIC_REPLICATION_FIELD(arc_color_fire);
    BASIC_REPLICATION_FIELD(cooldown);
    BASIC_REPLICATION_FIELD(texture);
    BASIC_REPLICATION_FIELD(custom_beam_mode);
    BASIC_REPLICATION_VECTOR(custom_beam_modes)
        VECTOR_REPLICATION_FIELD(name)
        VECTOR_REPLICATION_FIELD(order)
        VECTOR_REPLICATION_FIELD(energy_per_sec)
        VECTOR_REPLICATION_FIELD(heat_per_sec)
        VECTOR_REPLICATION_FIELD(requires_target)
        VECTOR_REPLICATION_FIELD(progress)
    VECTOR_REPLICATION_END();
}

BASIC_REPLICATION_IMPL(UtilityBeamEffectReplication, UtilityBeamEffect)
    BASIC_REPLICATION_FIELD(lifetime);
    BASIC_REPLICATION_FIELD(source);
    BASIC_REPLICATION_FIELD(target);
    BASIC_REPLICATION_FIELD(source_offset);
    BASIC_REPLICATION_FIELD(target_offset);
    BASIC_REPLICATION_FIELD(target_location);
    BASIC_REPLICATION_FIELD(hit_normal);

    BASIC_REPLICATION_FIELD(fire_ring);
    BASIC_REPLICATION_FIELD(beam_texture);
}

