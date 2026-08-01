#include "components/impulse.h"
#include "components/shields.h"
#include "components/missiletubes.h"
#include "components/maneuveringthrusters.h"
#include "components/collision.h"
#include "components/target.h"
#include "components/beamweapon.h"
#include "components/mounts.h"
#include "systems/missilesystem.h"
#include "ai/fighterAI.h"
#include "ai/aiFactory.h"
#include "random.h"


REGISTER_SHIP_AI(FighterAI, "fighter");

FighterAI::FighterAI(sp::ecs::Entity owner)
: ShipAI(owner)
{
    attack_state = State::Dive;
    timeout = 0.0;
    aggression = random(0.0, 0.25);
}

bool FighterAI::canSwitchAI()
{
    if (owner.hasComponent<Target>() && (has_missiles || has_beams))
    {
        if (attack_state == State::Dive)
            return false;
    }
    return true;
}

void FighterAI::runLight(float delta)
{
    if (timeout > 0.0f)
        timeout -= delta;

    // Evade state sets rotation/impulse directly (no route). These
    // perishable commands must be re-applied every frame since
    // ShipAI::runLight resets them. runAttack() only runs on heavy
    // frames (~117ms apart), so without this the fighter coasts.
    if (attack_state == State::Evade)
    {
        // Do the essential light work manually to avoid ShipAI::runLight
        // resetting thrusters/impulse or firing missiles during evade.
        pathPlanner.tryCollectResult();

        if (missile_fire_delay > 0.0f) missile_fire_delay -= delta;
        if (pathfind_cooldown > 0.0f) pathfind_cooldown -= delta;
        if (update_target_delay > 0.0f) update_target_delay -= delta;

        auto thrusters = owner.getComponent<ManeuveringThrusters>();
        if (thrusters) thrusters->target = evade_direction;
        auto impulse = owner.getComponent<ImpulseEngine>();
        if (impulse) impulse->request = 1.0f;
        return;
    }

    ShipAI::runLight(delta);
}

void FighterAI::runHeavy(float delta)
{
    ShipAI::runHeavy(delta);
}

void FighterAI::runOrders()
{
    if (aggression > 0.5f)
        aggression -= random(0.0, 0.25);
    ShipAI::runOrders();
}

void FighterAI::runAttack(sp::ecs::Entity target)
{
    auto transform = owner.getComponent<sp::Transform>();
    if (!transform) return;
    auto tt = target.getComponent<sp::Transform>();
    if (!tt) return;
    auto position_diff = tt->getPosition() - transform->getPosition();
    float distance = glm::length(position_diff);
    auto shields = owner.getComponent<Shields>();
    auto target_physics = target.getComponent<sp::Physics>();

    switch(attack_state)
    {
    case State::Dive:
        if (distance < 2500 + (target_physics ? target_physics->getSize().x : 0.0f) && has_missiles)
        {
            auto mounts = owner.getComponent<Mounts>();
            if (mounts) {
                size_t missile_mount_count = 0;
                for (auto& m : mounts->mounts)
                    if (m.type == MountType::MissileWeapon) missile_mount_count++;

                for(auto& tube : mounts->mounts)
                {
                    if (tube.type != MountType::MissileWeapon) continue;
                    if (tube.state == MountState::Loaded && missile_fire_delay <= 0.0f)
                    {
                        float target_angle = calculateFiringSolution(target, tube);
                        if (target_angle != std::numeric_limits<float>::infinity())
                        {
                            MissileSystem::fire(owner, tube, target_angle, target);
                            missile_fire_delay = tube.load_time / missile_mount_count / 2.0f;
                            strafing_fired = true;
                        }
                    }
                }
            }
        }

        if (!strafing_fired)
        {
            float target_angle = vec2ToAngle(position_diff);

            if (has_beams && distance < beam_weapon_range * 0.9f)
            {
                float rotation_diff = fabs(angleDifference(target_angle, transform->getRotation()));
                if (rotation_diff < 45.0f)
                    strafing_fired = true;
            }
            else if (!has_beams && distance < 500 + (target_physics ? target_physics->getSize().x : 0.0f))
            {
                strafing_fired = true;
            }
        }

        flyTowards(tt->getPosition(), 500.0);

        if (distance < 500 + (target_physics ? target_physics->getSize().x : 0.0f))
        {
            aggression += random(0.0f, 0.05f);

            attack_state = State::Evade;
            timeout = 30.0f - std::min(aggression, 1.0f) * 20.0f;

            float target_dir = vec2ToAngle(position_diff);
            float a_diff = angleDifference(target_dir, transform->getRotation());
            if (a_diff < 0)
                evade_direction = target_dir - random(25.0f, 40.0f);
            else
                evade_direction = target_dir + random(25.0f, 40.0f);
        }
        if (shields && !shields->entries.empty() && shields->entries[0].level < shields->entries[0].max * (1.0f - aggression))
        {
            attack_state = State::Recharge;
            aggression += random(0.1f, 0.25f);
            timeout = 60.0f - std::min(aggression, 1.0f) * 20.0f;
        }
        break;
    case State::Evade:
        if (distance > 2500 || timeout <= 0.0f)
        {
            attack_state = State::Dive;
            strafing_fired = false;
        }
        else
        {
            auto thrusters = owner.getComponent<ManeuveringThrusters>();
            if (thrusters) thrusters->target = evade_direction;
            auto impulse = owner.getComponent<ImpulseEngine>();
            if (impulse)
                impulse->request = 1.0;
        }
        break;
    case State::Recharge:
        if ((shields && !shields->entries.empty() && shields->entries[0].level < shields->entries[0].max * 0.9f) || timeout <= 0.0f)
        {
            attack_state = State::Dive;
            strafing_fired = false;
        }else{
            auto target_position = tt->getPosition();
            float circle_distance = 3000.0f;
            target_position += vec2FromAngle(vec2ToAngle(target_position - transform->getPosition()) + 170.0f) * circle_distance;
            flyTowards(target_position);
        }
        break;
    }
}
