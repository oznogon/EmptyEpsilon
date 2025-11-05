#include "systems/docking.h"
#include "components/ai.h"
#include "components/collision.h"
#include "components/impulse.h"
#include "components/maneuveringthrusters.h"
#include "components/reactor.h"
#include "components/hull.h"
#include "components/warpdrive.h"
#include "components/jumpdrive.h"
#include "components/missiletubes.h"
#include "components/probe.h"
#include "ecs/query.h"
#include "multiplayer_server.h"

DockingSystem::DockingSystem()
{
    sp::CollisionSystem::addHandler(this);
}

void DockingSystem::update(float delta)
{
    if (!game_server) return;

    for(auto [entity, docking_port, transform] : sp::ecs::Query<DockingPort, sp::ecs::optional<sp::Transform>>()) {
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
            if (!docking_port.target || !(target_transform = docking_port.target.getComponent<sp::Transform>()))
            {
                docking_port.state = DockingPort::State::NotDocking;
                if (!transform) { // Internal docking and our bay is destroyed. So, destroy ourselves as well.
                    entity.destroy();
                }
            }else{
                if (transform) {
                    transform->setPosition(target_transform->getPosition() + rotateVec2(docking_port.docked_offset, target_transform->getRotation()));
                    transform->setRotation(vec2ToAngle(transform->getPosition() - target_transform->getPosition()));
                    auto thrusters = entity.getComponent<ManeuveringThrusters>();
                    if (thrusters) thrusters->stop();
                }

                auto bay = docking_port.target.getComponent<DockingBay>();
                if (bay && (bay->flags & DockingBay::Repair))  //Check if what we are docked to allows hull repairs, and if so, do it.
                {
                    auto hull = entity.getComponent<Hull>();
                    if (hull && hull->current < hull->max)
                    {
                        hull->current += delta;
                        if (hull->current > hull->max)
                            hull->current = hull->max;
                    }
                }

                if (bay && (bay->flags & DockingBay::ShareEnergy)) {
                    auto my_reactor = entity.getComponent<Reactor>();
                    if (my_reactor) {
                        auto other_reactor = docking_port.target.getComponent<Reactor>();
                        // Derive a base energy request rate from the player ship's maximum
                        // energy capacity.
                        float energy_request = std::min(delta * 10.0f, my_reactor->max_energy - my_reactor->energy);

                        // If we're docked with a shipTemplateBasedObject, and that object is
                        // set to share its energy with docked ships, transfer energy from the
                        // mothership to docked ships until the mothership runs out of energy
                        // or the docked ship doesn't require any.
                        if (!other_reactor || other_reactor->useEnergy(energy_request))
                            my_reactor->energy += energy_request;
                    }
                }

                if (bay && (bay->flags & DockingBay::RestockProbes)) {
                    // If a shipTemplateBasedObject and is allowed to restock
                    // scan probes with docked ships.
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

                //recharge missiles of CPU ships docked to station. Can be disabled
                if (docking_port.auto_reload_missiles && bay && (bay->flags & DockingBay::RestockMissiles)) {
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

            auto engine = entity.getComponent<ImpulseEngine>();
            if (engine)
            {
                engine->request = 0.f;
                engine->actual = 0.f;
            }
            auto warp = entity.getComponent<WarpDrive>();
            if (warp)
            {
                warp->request = 0;
                warp->current = 0;
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

bool DockingSystem::assignInternalEntityToBerth(sp::ecs::Entity entity, DockingBay::BerthType berth_type)
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
