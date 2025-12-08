#pragma once

#include "ecs/system.h"
#include "systems/collision.h"
#include "components/docking.h"

class DockingSystem : public sp::ecs::System, public sp::CollisionHandler
{
public:
    DockingSystem();

    void update(float delta) override;

    static bool canStartDocking(sp::ecs::Entity entity);
    static void requestDock(sp::ecs::Entity entity, sp::ecs::Entity target);
    static void requestUndock(sp::ecs::Entity entity);
    static void abortDock(sp::ecs::Entity entity);

    static bool moveEntityToInternalBay(sp::ecs::Entity entity, sp::ecs::Entity carrier);
    static bool assignInternalEntityToBerth(sp::ecs::Entity entity);
    static bool assignInternalEntityToBerth(sp::ecs::Entity entity, DockingBay::Berth::Type berth_type);
    static bool assignInternalEntityToBerth(sp::ecs::Entity entity, int index);
    static void assignInternalEntitiesToBerths(std::vector<sp::ecs::Entity> entities, sp::ecs::Entity carrier);

    void collision(sp::ecs::Entity a, sp::ecs::Entity b, float force) override;
};
