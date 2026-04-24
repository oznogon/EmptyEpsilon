#include "systems/ai.h"
#include "components/ai.h"
#include "components/drone.h"
#include "ecs/query.h"
#include "multiplayer_server.h"
#include "ai/ai.h"
#include "ai/aiFactory.h"


void AISystem::update(float delta)
{
    if (delta <= 0.0f) return;
    if (!game_server)
        return;

    for(auto [entity, ai] : sp::ecs::Query<AIController>()) {
        // Skip AI for drones actively controlled by a player ship.
        if (auto adl = entity.getComponent<AllowDroneLink>())
            if (auto dl = adl->owner.getComponent<DroneLink>())
                if (dl->linked_drone == entity)
                    continue;

        if (ai.new_name.length() && (!ai.ai || ai.ai->canSwitchAI()))
        {
            auto f = ShipAIFactory::getAIFactory(ai.new_name);
            ai.ai = nullptr;
            if (f)
                ai.ai = f(entity);
            ai.new_name = "";
        }
        if (ai.ai)
            ai.ai->run(delta);
    }
}
