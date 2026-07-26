#pragma once

#include "nonCopyable.h"
#include "graphics/renderTarget.h"
#include "systems/pathfinding.h"
#include "components/missiletubes.h"

// Base for all ship AIs. This base class handles basic AI which just follows
// orders straight on and attacks head on. ShipAI objects are created only on
// the server.
class ShipAI : sp::NonCopyable
{
protected:
    // Artificial delay between missile fires. The AI missile fire is 'faked'
    // with this value.
    float missile_fire_delay = 0.0f;
    bool has_missiles = false;
    bool has_beams = false;
    float beam_weapon_range = 0.0f;
    // Fake radar ranges, if the target lacks the necessary systems.
    float short_range = 5000.0f;
    float long_range = 30000.0f;
    float relay_range = 60000.0f;

    enum class EWeaponDirection
    {
        Front,
        Left,
        Right,
        Side,
        Rear
    };
    EWeaponDirection weapon_direction = EWeaponDirection::Front;
    int best_missile_type = 0;

    float update_target_delay = 0.0f;
    float pathfind_cooldown = 0.0f;
    bool had_target_last_frame = false;

    // When false, flyTowards/flyFormation skip path re-planning even if
    // cooldowns have expired. Used by runLight to defer A* to runHeavy.
    bool m_allow_path_planning = true;

    PathPlanner pathPlanner;
public:
    sp::ecs::Entity owner;

    ShipAI(sp::ecs::Entity owner);
    virtual ~ShipAI() = default;

    // Run is called every frame to update the AI state and let the AI take actions.
    virtual void run(float delta);

    // Lightweight per-frame execution: issues movement/fire commands from
    // cached state. Does NOT run expensive pathfinding or target search.
    virtual void runLight(float delta);

    // Heavy strategic update: weapon analysis, target selection, path
    // planning. Called on a staggered schedule, not every frame.
    virtual void runHeavy(float delta);

    // Are we allowed to switch to a different AI right now?
    // When true is returned and the CpuShip wants to change their AI, this AI
    // object will be destroyed and a new one will be created.
    virtual bool canSwitchAI();

    // Clear the current path planning route. Called when GM issues new orders
    // so the AI doesn't continue flying toward a stale destination.
    void clearPath() { pathPlanner.clear(); }

    // Force an immediate target re-evaluation on the next runHeavy call.
    void resetTargetDelay() { update_target_delay = 0.0f; }

    // Visualize AI behaviors on the GM screen.
    virtual void drawOnGMRadar(sp::RenderTarget& renderer, glm::vec2 draw_position, float scale);
protected:
    virtual void updateWeaponState(float delta);
    virtual void updateTarget();
    virtual void runOrders();
    virtual void runAttack(sp::ecs::Entity target);
    virtual void flyTowards(glm::vec2 target, float keep_distance = 0.0f);
    virtual void flyFormation(sp::ecs::Entity target, glm::vec2 offset);

    sp::ecs::Entity findBestTarget(glm::vec2 position, float radius);
    float targetScore(sp::ecs::Entity target);

    /**!
     * Check if new target is better than old target.
     * \param new_target
     * \param current_target
     * \return bool True if the new target is 'better'
     */
    bool betterTarget(sp::ecs::Entity new_target, sp::ecs::Entity current_target);

    // Used for missiles, which require some planning to fire.
    float calculateFiringSolution(sp::ecs::Entity target, const MissileTubes::MountPoint& tube);
    sp::ecs::Entity findBestMissileRestockTarget(glm::vec2 position, float radius);

    // Return scoring estimates for missile types.
    static float getMissileWeaponStrength(int type_index)
    {
        auto& registry = MissileWeaponDataRegistry::instance();
        float dmg = registry.getDamageAtCenter(type_index);
        float blast = registry.getBlastRange(type_index);
        return dmg + blast * 0.1f;
    }
};
