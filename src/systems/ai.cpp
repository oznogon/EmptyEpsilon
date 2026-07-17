#include "systems/ai.h"
#include "components/ai.h"
#include "components/drone.h"
#include "ecs/query.h"
#include "multiplayer_server.h"
#include "ai/ai.h"
#include "ai/aiFactory.h"
#include "timer.h"
#include "logging.h"
#include <vector>
#include <algorithm>


void AISystem::update(float delta)
{
    if (delta <= 0.0f) return;
    if (!game_server.isAlive())
        return;

    // Collect all AI entities into a stable list for round-robin scheduling.
    struct AIEntry { sp::ecs::Entity entity; AIController* controller; };
    std::vector<AIEntry> ai_list;

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
            ai_list.push_back({entity, &ai});
    }

    if (ai_list.empty()) return;

    // Perf tracking.
    sp::SystemStopwatch sw;

    int immediate_heavy_count = 0;

    // PASS 1: Light update — all entities, every frame.
    // Entities whose AI orders changed since last check get an immediate
    // heavy update so that GM-issued orders (via UI, Lua, or network)
    // take effect on the same frame instead of being deferred to the
    // round-robin schedule.
    for (auto& entry : ai_list) {
        auto entity_id = entry.entity.getIndex();
        auto& last = last_ai_state[entity_id];

        bool orders_changed = (last.orders != entry.controller->orders
            || last.order_target_location != entry.controller->order_target_location
            || last.order_target != entry.controller->order_target);

        if (orders_changed) {
            last.orders = entry.controller->orders;
            last.order_target_location = entry.controller->order_target_location;
            last.order_target = entry.controller->order_target;

            // Clear the stale route so the AI doesn't fly to the old
            // destination, then re-plan immediately with the new orders.
            entry.controller->ai->clearPath();
            entry.controller->ai->runHeavy(delta);
            immediate_heavy_count++;
        }

        entry.controller->ai->runLight(delta);
    }
    float light_time = sw.restart();

    // PASS 2: Heavy update — round-robin, MAX_HEAVY_PER_FRAME entities.
    int scheduled_heavy = 0;
    if (ai_list.size() <= static_cast<size_t>(MAX_HEAVY_PER_FRAME))
    {
        for (auto& entry : ai_list) {
            entry.controller->ai->runHeavy(delta);
            scheduled_heavy++;
        }
    }
    else
    {
        if (next_heavy_index >= ai_list.size()) next_heavy_index = 0;
        for (int i = 0; i < MAX_HEAVY_PER_FRAME; i++)
        {
            ai_list[next_heavy_index].controller->ai->runHeavy(delta);
            next_heavy_index = (next_heavy_index + 1) % ai_list.size();
            scheduled_heavy++;
        }
    }
    float heavy_time = sw.restart();

    total_light_time += light_time;
    total_heavy_time += heavy_time;
    total_ai_count = std::max(total_ai_count, static_cast<int>(ai_list.size()));
    frame_count++;

    log_timer += delta;
    if (log_timer >= 5.0f)
    {
        float light_per_frame_us = (frame_count > 0)
            ? (total_light_time / frame_count) * 1e6f : 0.0f;
        float heavy_per_frame_us = (frame_count > 0)
            ? (total_heavy_time / frame_count) * 1e6f : 0.0f;
        float total_ms = (light_per_frame_us + heavy_per_frame_us) / 1000.0f;
        LOG(INFO) << "[AISystem] " << total_ai_count << " AIs | "
                  << "light=" << light_per_frame_us << "us | "
                  << "heavy=" << heavy_per_frame_us << "us | "
                  << "total=" << total_ms << "ms/frame "
                  << "imm_heavy=" << immediate_heavy_count
                  << " (budget=" << MAX_HEAVY_PER_FRAME << "/frame)";
        immediate_heavy_count = 0;
        log_timer = 0.0f;
        total_light_time = 0.0f;
        total_heavy_time = 0.0f;
        total_ai_count = 0;
        frame_count = 0;
    }
}
