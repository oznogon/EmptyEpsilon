#include "dronecontrolsystem.h"
#include "ecs/query.h"
#include "components/collision.h"
#include "components/drone.h"
#include "components/reactor.h"
#include "gameGlobalInfo.h"
#include "multiplayer_server.h"


void DroneControlSystem::update(float delta)
{
    if (!game_server)
        return;

    for (auto [entity, dc, dl] : sp::ecs::Query<DroneController, DroneLink>())
    {
        if (!dl.linked_drone)
            continue;

        auto ship_transform = entity.getComponent<sp::Transform>();
        auto drone_transform = dl.linked_drone.getComponent<sp::Transform>();

        // Auto-disconnect if drone is destroyed or out of range.
        bool disconnected = false;
        if (!drone_transform)
        {
            disconnected = true;
        }
        else
        {
            float range = dc.control_range;
            if (auto sensors = entity.getComponent<SensorsSystem>())
                range *= sensors->getSystemEffectiveness();

            if (ship_transform && glm::length(drone_transform->getPosition() - ship_transform->getPosition()) > range)
                disconnected = true;
        }

        if (disconnected)
        {
            dl.linked_drone = sp::ecs::Entity{};
            continue;
        }

        // Drain energy while connected.
        if (gameGlobalInfo->use_drone_energy_drain && dc.energy_drain_per_sec > 0.0f)
        {
            auto reactor = entity.getComponent<Reactor>();
            if (reactor)
            {
                float drain_rate = dc.energy_drain_per_sec;
                auto sensors = entity.getComponent<SensorsSystem>();
                if (sensors)
                {
                    float effectiveness = sensors->getSystemEffectiveness();
                    drain_rate *= effectiveness;
                    sensors->addHeat(drain_rate / 10.0f * delta);
                }
                reactor->useEnergy(drain_rate * delta);
            }
        }
    }
}
