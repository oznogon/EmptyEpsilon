#include "systems/docking.h"
#include "components/ai.h"
#include "components/coolant.h"
#include "components/collision.h"
#include "components/impulse.h"
#include "components/maneuveringthrusters.h"
#include "components/reactor.h"
#include "components/hull.h"
#include "components/warpdrive.h"
#include "components/jumpdrive.h"
#include "components/missiletubes.h"
#include "components/probe.h"
#include "components/reactor.h"
#include "ecs/query.h"
#include "multiplayer_server.h"

DockingSystem::DockingSystem()
{
    sp::CollisionSystem::addHandler(this);
}

void DockingSystem::update(float delta)
{
    if (!game_server) return;

    for (auto [entity, docking_port, transform] : sp::ecs::Query<DockingPort, sp::ecs::optional<sp::Transform>>()) {
        sp::Transform* target_transform;
        switch(docking_port.state) {
        case DockingPort::State::NotDocking:
            break;
        case DockingPort::State::Docking:
            if (!docking_port.target || !(target_transform = docking_port.target.getComponent<sp::Transform>())) {
                docking_port.state = DockingPort::State::NotDocking;
            } else {
                auto engine = entity.getComponent<ImpulseEngine>();
                auto thrusters = entity.getComponent<ManeuveringThrusters>();
                if (thrusters)
                    thrusters->target = vec2ToAngle(transform->getPosition() - target_transform->getPosition());
                if (engine) {
                    if (thrusters && fabs(angleDifference(thrusters->target, transform->getRotation())) < 10.0f)
                        engine->request = -1.f;
                    else
                        engine->request = 0.f;
                }
                if (auto warp = entity.getComponent<WarpDrive>())
                    warp->request = 0;
            }
            break;
        case DockingPort::State::Docked:
            auto& carrier_entity = docking_port.target;

            if (!carrier_entity || !(target_transform = carrier_entity.getComponent<sp::Transform>()))
            {
                docking_port.state = DockingPort::State::NotDocking;
                // We're internally docked and our bay was destroyed, so destroy
                // ourselves as well.
                if (!transform) entity.destroy();
            }
            else
            {
                // Manage our position if we're externally docked, indicated by
                // our ship still having a Transform.
                if (transform)
                {
                    transform->setPosition(target_transform->getPosition() + rotateVec2(docking_port.docked_offset, target_transform->getRotation()));
                    transform->setRotation(vec2ToAngle(transform->getPosition() - target_transform->getPosition()));
                    if (auto thrusters = entity.getComponent<ManeuveringThrusters>()) thrusters->stop();
                }

                if (auto bay = carrier_entity.getComponent<DockingBay>())
                {
                    // Determine whether we're in a docking bay berth.
                    DockingBay::Berth my_berth;
                    bool is_berthed = false;

                    for (auto berth : bay->berths)
                    {
                        if (berth.docked_entity == entity)
                        {
                            my_berth = berth;
                            is_berthed = true;
                        }
                    }

                    // Check if what we're docked to allows hull repairs, and if
                    // so, do it.
                    if (bay->flags & DockingBay::Repair)
                    {
                        auto hull = entity.getComponent<Hull>();
                        if (hull && hull->current < hull->max)
                        {
                            hull->current += delta;
                            if (hull->current > hull->max)
                                hull->current = hull->max;
                        }
                    }
                    // Otherwise, determine whether we're in a docking bay
                    // energy berth set to transfer energy and use that if so.
                    else if (is_berthed && my_berth.type == DockingBay::Berth::Type::Repair)
                    {
                        auto my_reactor = carrier_entity.getComponent<Reactor>();
                        auto docked_hull = entity.getComponent<Hull>();
                        const float energy_transfer = my_berth.transfer_rate * delta;

                        // The configured direction determine whether to repair
                        // the berthed ship's hull first (ToDocked) or systems
                        // first (ToCarrier).
                        if (docked_hull && my_berth.transfer_direction == DockingBay::Berth::TransferDirection::ToDocked)
                        {
                            float transfer_remaining = energy_transfer;

                            if (docked_hull->current < docked_hull->max)
                            {
                                float amount_repaired = std::min(transfer_remaining, docked_hull->max - docked_hull->current);
                                if (my_reactor && !my_reactor->useEnergy(amount_repaired)) continue;

                                transfer_remaining = std::max(0.0f, transfer_remaining - amount_repaired);

                                docked_hull->current = std::min(docked_hull->max, docked_hull->current + amount_repaired);
                            }

                            if (transfer_remaining > 0.0f)
                            {
                                // TODO: DRY
                                for (auto i = 0; i < static_cast<int>(ShipSystem::Type::COUNT); i++)
                                {
                                    if (auto docked_sys = ShipSystem::get(entity, static_cast<ShipSystem::Type>(i)))
                                    {
                                        if (docked_sys->health < docked_sys->health_max)
                                        {
                                            float amount_repaired = std::min(transfer_remaining, docked_sys->health_max - docked_sys->health);

                                            if (my_reactor && !my_reactor->useEnergy(amount_repaired)) continue;

                                            docked_sys->health = std::min(docked_sys->health_max, docked_sys->health + transfer_remaining);

                                            if (transfer_remaining <= 0.0f) continue;
                                        }
                                    }
                                }
                            }
                        }
                        else if (my_berth.transfer_direction == DockingBay::Berth::TransferDirection::ToCarrier)
                        {
                            // TODO: DRY
                            float transfer_remaining = energy_transfer;

                            for (auto i = 0; i < static_cast<int>(ShipSystem::Type::COUNT); i++)
                            {
                                if (auto docked_sys = ShipSystem::get(entity, static_cast<ShipSystem::Type>(i)))
                                {
                                    if (transfer_remaining > 0.0f && docked_sys->health < docked_sys->health_max)
                                    {
                                        float amount_repaired = std::min(transfer_remaining, docked_sys->health_max - docked_sys->health);

                                        if (my_reactor && !my_reactor->useEnergy(amount_repaired)) continue;

                                        transfer_remaining = std::max(0.0f, transfer_remaining - amount_repaired);
                                        
                                        docked_sys->health = std::min(docked_sys->health_max, docked_sys->health + energy_transfer);

                                        if (transfer_remaining <= 0.0f) continue;
                                    }
                                }
                            }

                            if (transfer_remaining > 0.0f && docked_hull->current < docked_hull->max)
                            {
                                float amount_repaired = std::min(transfer_remaining, docked_hull->max - docked_hull->current);

                                if (my_reactor && !my_reactor->useEnergy(amount_repaired)) continue;

                                docked_hull->current = std::min(docked_hull->max, docked_hull->current + amount_repaired);
                            }
                        }
                    }

                    // Use DockingBay flag for energy transfer if set.
                    // This should override energy docking bay berth behavior.
                    if (bay->flags & DockingBay::ShareEnergy)
                    {
                        auto docked_reactor = entity.getComponent<Reactor>();
                        if (docked_reactor)
                        {
                            auto carrier_reactor = carrier_entity.getComponent<Reactor>();
                            // Derive a base energy request rate from the player ship's maximum
                            // energy capacity.
                            float energy_request = std::min(delta * 10.0f, docked_reactor->max_energy - docked_reactor->energy);

                            // If we're docked with a shipTemplateBasedObject, and that object is
                            // set to share its energy with docked ships, transfer energy from the
                            // mothership to docked ships until the mothership runs out of energy
                            // or the docked ship doesn't require any.
                            if (!carrier_reactor || carrier_reactor->useEnergy(energy_request))
                                docked_reactor->energy += energy_request;
                        }
                    }
                    // Otherwise, determine whether we're in a docking bay
                    // energy berth set to transfer energy and use that if so.
                    else if (is_berthed && my_berth.type == DockingBay::Berth::Type::Energy)
                    {
                        auto my_reactor = carrier_entity.getComponent<Reactor>();
                        auto docked_reactor = entity.getComponent<Reactor>();
                        if (!my_reactor && !docked_reactor) continue;
                        const float energy_transfer = my_berth.transfer_rate * delta;

                        // Transfer energy in the configured direction if both
                        // the recipient has a reactor and the sender has energy.
                        // Reactorless ships are treated as if they have no
                        // energy. The berth's transfer_rate is in energy/sec.
                        if (docked_reactor && my_berth.transfer_direction == DockingBay::Berth::TransferDirection::ToDocked)
                        {
                            if (docked_reactor->energy + energy_transfer >= docked_reactor->max_energy) continue;
                            if (!my_reactor) continue;
                            if (!my_reactor->useEnergy(energy_transfer)) continue;
                            docked_reactor->energy = std::min(docked_reactor->max_energy, docked_reactor->energy + energy_transfer);
                        }
                        else if (my_reactor && my_berth.transfer_direction == DockingBay::Berth::TransferDirection::ToCarrier)
                        {
                            if (my_reactor->energy >= my_reactor->max_energy) continue;
                            if (!docked_reactor) continue;
                            if (!docked_reactor->useEnergy(energy_transfer)) continue;
                            my_reactor->energy = std::min(my_reactor->max_energy, my_reactor->energy + energy_transfer);
                        }
                    }

                    if (is_berthed && my_berth.type == DockingBay::Berth::Type::Thermal)
                    {
                        auto my_coolant = carrier_entity.getComponent<Coolant>();
                        auto docked_coolant = entity.getComponent<Coolant>();
                        if (!my_coolant && !docked_coolant) continue;
                        const float heat_transfer = my_berth.transfer_rate * delta;

                        // Transfer heat in the configured direction if both
                        // the recipient has coolant and the sender has heat.
                        // Ships without coolant are treated as if they have no
                        // heat. The berth's transfer_rate is in heat/sec.
                        auto transfer_heat = [&](sp::ecs::Entity source_entity, sp::ecs::Entity destination_entity, Coolant* source_coolant, Coolant* destination_coolant)
                        {
                            if (!source_coolant || !destination_coolant) return;

                            float transfer_remaining = heat_transfer;

                            // Extract heat from source systems.
                            for (auto i = 0; i < static_cast<int>(ShipSystem::Type::COUNT); i++)
                            {
                                if (transfer_remaining <= 0.0f) break;

                                if (auto source_system = ShipSystem::get(source_entity, static_cast<ShipSystem::Type>(i)))
                                {
                                    if (source_system->heat_level > 0.0f)
                                    {
                                        float amount_transferred = std::min(transfer_remaining, source_system->heat_level);

                                        transfer_remaining = std::max(0.0f, transfer_remaining - amount_transferred);
                                        source_system->heat_level = std::max(0.0f, source_system->heat_level - amount_transferred);
                                    }
                                }
                            }

                            // If no heat was extracted, nothing to distribute.
                            if (transfer_remaining == heat_transfer) return;

                            // Count destination systems.
                            float system_count = 0.0f;
                            for (auto i = 0; i < static_cast<int>(ShipSystem::Type::COUNT); i++)
                            {
                                auto destination_system = ShipSystem::get(destination_entity, static_cast<ShipSystem::Type>(i));
                                if (destination_system) system_count++;
                            }

                            if (system_count <= 0.0f) return;

                            // Distribute heat evenly across destination systems.
                            float amount_vented = (heat_transfer - transfer_remaining) / system_count;

                            for (auto i = 0; i < static_cast<int>(ShipSystem::Type::COUNT); i++)
                            {
                                if (auto destination_system = ShipSystem::get(destination_entity, static_cast<ShipSystem::Type>(i)))
                                    destination_system->addHeat(amount_vented);
                            }
                        };

                        if (my_berth.transfer_direction == DockingBay::Berth::TransferDirection::ToDocked)
                            transfer_heat(carrier_entity, entity, my_coolant, docked_coolant);
                        else if (my_berth.transfer_direction == DockingBay::Berth::TransferDirection::ToCarrier)
                            transfer_heat(entity, carrier_entity, docked_coolant, my_coolant);
                    }

                    // If a shipTemplateBasedObject and is allowed to restock
                    // scan probes with docked ships.
                    if (bay->flags & DockingBay::RestockProbes) {
                        if (auto spl = entity.getComponent<ScanProbeLauncher>()) {
                            if (spl->stock < spl->max)
                            {
                                spl->recharge += delta;

                                if (spl->recharge > spl->charge_time)
                                {
                                    spl->stock += 1;
                                    spl->recharge = 0.0;
                                }
                            }
                        }
                    }

                    // Recharge missiles of CPU ships docked to station. Can be disabled
                    if (docking_port.auto_reload_missiles && (bay->flags & DockingBay::RestockMissiles)) {
                        auto tubes = entity.getComponent<MissileTubes>();
                        if (tubes) {
                            bool needs_missile = false;
                            for(int n=0; n<MW_Count; n++)
                            {
                                if  (tubes->storage[n] < tubes->storage_max[n])
                                {
                                    if (docking_port.auto_reload_missile_delay <= 0.0f)
                                    {
                                        tubes->storage[n] += 1;
                                        docking_port.auto_reload_missile_delay = docking_port.auto_reload_missile_time;
                                        break;
                                    }
                                    else
                                        needs_missile = true;
                                }
                            }

                            if (needs_missile)
                                docking_port.auto_reload_missile_delay -= delta;
                        }
                    }
                }
            }

            if (auto engine = entity.getComponent<ImpulseEngine>())
            {
                engine->request = 0.0f;
                engine->actual = 0.0f;
            }
            if (auto warp = entity.getComponent<WarpDrive>())
            {
                warp->request = 0;
                warp->current = 0.0f;
            }
            break;
        }
    }
}

bool DockingSystem::moveEntityToInternalBay(sp::ecs::Entity entity, sp::ecs::Entity carrier)
{
    auto bay = carrier.getComponent<DockingBay>();
    if (!bay) return false;

    auto port = entity.getComponent<DockingPort>();
    if (!port || !(port->canDockOn(*bay) == DockingStyle::Internal)) return false;

    port->state = DockingPort::State::Docked;
    port->target = carrier;

    if (entity.hasComponent<sp::Transform>())
        entity.removeComponent<sp::Transform>();

    assignInternalEntityToBerth(entity);

    return true;
}

bool DockingSystem::assignInternalEntityToBerth(sp::ecs::Entity entity)
{
    auto port = entity.getComponent<DockingPort>();
    if (!port) return false;

    auto carrier = port->target;
    auto bay = carrier.getComponent<DockingBay>();
    if (!bay || !(port->canDockOn(*bay) == DockingStyle::Internal) || bay->berths.empty())
        return false;

    // Find first empty berth
    for (auto& berth : bay->berths)
    {
        if (berth.docked_entity == sp::ecs::Entity())
        {
            berth.docked_entity = entity;
            return true;
        }
    }

    // No empty berth found
    LOG(Debug, "No empty berth available for ", entity.toString(), ", undocking.");
    requestUndock(entity);
    port->state = DockingPort::State::NotDocking;
    // If the docking ship is AI-controlled, revert to roaming if denied docking.
    // Should this revert to defending the carrier instead?
    // Should AIs roaming for supplies ignore carriers with no unoccupied berths?
    if (auto ai = entity.getComponent<AIController>()) ai->orders = AIOrder::Roaming;
    return false;
}

bool DockingSystem::assignInternalEntityToBerth(sp::ecs::Entity entity, DockingBay::Berth::Type berth_type)
{
    auto port = entity.getComponent<DockingPort>();
    if (!port || !port->target) return false;

    auto carrier = port->target;
    auto bay = carrier.getComponent<DockingBay>();
    if (!bay || !(port->canDockOn(*bay) == DockingStyle::Internal) || bay->berths.empty()) return false;

    // First, clear entity from any berth it's currently in
    for (auto& berth : bay->berths)
    {
        if (berth.docked_entity == entity)
            berth.docked_entity = sp::ecs::Entity();
    }

    // Find an empty berth of the requested type
    for (auto& berth : bay->berths)
    {
        // TODO: move_time delay
        if (berth.type == berth_type && !berth.docked_entity)
        {
            berth.docked_entity = entity;
            return true;
        }
    }

    return false;
}

bool DockingSystem::assignInternalEntityToBerth(sp::ecs::Entity entity, int index)
{
    auto port = entity.getComponent<DockingPort>();
    if (!port || !port->target) return false;

    auto carrier = port->target;
    auto bay = carrier.getComponent<DockingBay>();
    if (!bay || !(port->canDockOn(*bay) == DockingStyle::Internal) || bay->berths.empty() || index < 0 || index >= int(bay->berths.size())) return false;

    auto& berth = bay->berths[index];

    // If the berth is occupied by a different entity, can't assign
    if (berth.docked_entity && berth.docked_entity != entity) return false;

    // Clear entity from any other berth it's currently in
    for (size_t i = 0; i < bay->berths.size(); i++)
    {
        if (int(i) != index && bay->berths[i].docked_entity == entity)
            bay->berths[i].docked_entity = sp::ecs::Entity();
    }

    // Assign to the requested berth
    berth.docked_entity = entity;
    return true;
}

void DockingSystem::assignInternalEntitiesToBerths(std::vector<sp::ecs::Entity> entities, sp::ecs::Entity carrier)
{
    auto bay = carrier.getComponent<DockingBay>();
    if (!bay || bay->berths.empty()) return;

    for (auto& entity : entities)
    {
        auto port = entity.getComponent<DockingPort>();
        if (!port || !(port->canDockOn(*bay) == DockingStyle::Internal)) continue;

        // First, clear entity from any berth it's currently in
        for (auto& berth : bay->berths)
        {
            if (berth.docked_entity == entity)
                berth.docked_entity = sp::ecs::Entity();
        }

        // Then try to assign it to an empty berth
        bool was_assigned = false;
        for (auto& berth : bay->berths)
        {
            if (!berth.docked_entity)
            {
                berth.docked_entity = entity;
                was_assigned = true;
                break;
            }
        }

        if (!was_assigned)
        {
            LOG(Debug, "More ships than berths, undocking.");
            if (port->target == carrier) requestUndock(entity);
        }
    }
}

bool DockingSystem::canStartDocking(sp::ecs::Entity entity)
{
    auto port = entity.getComponent<DockingPort>();
    if (!port) return false;
    if (port->state != DockingPort::State::NotDocking) return false;
    auto warp = entity.getComponent<WarpDrive>();
    if (warp && warp->current > 0.0f) return false;
    auto jump = entity.getComponent<JumpDrive>();
    if (jump && jump->delay > 0.0f) return false;
    return true;
}

void DockingSystem::collision(sp::ecs::Entity carried, sp::ecs::Entity carrier, float force)
{
    auto port = carried.getComponent<DockingPort>();
    if (port && port->state == DockingPort::State::Docking && port->target == carrier)
    {
        auto position = carried.getComponent<sp::Transform>();
        auto other_position = carrier.getComponent<sp::Transform>();
        auto thrusters = carried.getComponent<ManeuveringThrusters>();

        if (position && other_position && thrusters && fabs(angleDifference(thrusters->target, position->getRotation())) < 10.0f)
        {
            port->state = DockingPort::State::Docked;
            port->docked_offset = rotateVec2(position->getPosition() - other_position->getPosition(), -other_position->getRotation());
            float length = glm::length(port->docked_offset);
            port->docked_offset = port->docked_offset / length * (length + 2.0f);

            if (auto bay = carrier.getComponent<DockingBay>())
            {
                if (port->canDockOn(*bay) == DockingStyle::Internal)
                {
                    carried.removeComponent<sp::Transform>();
                    assignInternalEntityToBerth(carried);
                }
            }
        }
    }
}

void DockingSystem::requestDock(sp::ecs::Entity entity, sp::ecs::Entity target)
{
    if (!canStartDocking(entity))
        return;

    auto docking_port = entity.getComponent<DockingPort>();
    if (!docking_port || docking_port->state != DockingPort::State::NotDocking) return;
    if (!target) return;
    auto bay = target.getComponent<DockingBay>();
    if (!bay || docking_port->canDockOn(*bay) == DockingStyle::None) return;
    auto position = entity.getComponent<sp::Transform>();
    if (!position) return;
    auto target_position = target.getComponent<sp::Transform>();
    if (!target_position) return;
    auto target_physics = target.getComponent<sp::Physics>();
    if (!target_physics) return;

    if (glm::length(position->getPosition() - target_position->getPosition()) > 1000.0f + target_physics->getSize().x)
        return;

    docking_port->state = DockingPort::State::Docking;
    docking_port->target = target;

    if (auto warp = entity.getComponent<WarpDrive>())
        warp->request = 0;
}

void DockingSystem::requestUndock(sp::ecs::Entity entity)
{
    auto docking_port = entity.getComponent<DockingPort>();
    if (!docking_port || docking_port->state != DockingPort::State::Docked) return;
    auto impulse = entity.getComponent<ImpulseEngine>();
    if (impulse && impulse->getSystemEffectiveness() < 0.1f) return;

    if (!entity.hasComponent<sp::Transform>())
    {
        auto& t = entity.addComponent<sp::Transform>();
        auto target_transform = docking_port->target.getComponent<sp::Transform>();
        t.setPosition(target_transform->getPosition() + rotateVec2(docking_port->docked_offset, target_transform->getRotation()));
        t.setRotation(target_transform->getRotation() + vec2ToAngle(docking_port->docked_offset));
    }

    auto thrusters = entity.getComponent<ManeuveringThrusters>();
    if (thrusters) thrusters->stop();

    docking_port->state = DockingPort::State::NotDocking;
    if (auto bay = docking_port->target.getComponent<DockingBay>())
    {
        for (auto& berth : bay->berths)
            if (berth.docked_entity == entity) berth.docked_entity = sp::ecs::Entity();
    }

    if (impulse) impulse->request = 0.5f;
}

void DockingSystem::abortDock(sp::ecs::Entity entity)
{
    auto docking_port = entity.getComponent<DockingPort>();
    if (!docking_port || docking_port->state != DockingPort::State::Docking) return;

    docking_port->state = DockingPort::State::NotDocking;
    auto engine = entity.getComponent<ImpulseEngine>();
    if (engine) engine->request = 0.f;
    auto warp = entity.getComponent<WarpDrive>();
    if (warp) warp->request = 0;
    auto thrusters = entity.getComponent<ManeuveringThrusters>();
    if (thrusters) thrusters->stop();
}
