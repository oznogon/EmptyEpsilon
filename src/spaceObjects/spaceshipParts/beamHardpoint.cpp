#include "beamHardpoint.h"
#include "spaceObjects/spaceship.h"
#include "spaceObjects/beamEffect.h"
#include "spaceObjects/spaceObject.h"

BeamHardpoint::BeamHardpoint()
{
    arc = 0;
    direction = 0;
    range = 0;
    turret_arc = 0.0;
    turret_direction = 0.0;
    turret_rotation_rate = 0.0;
    cycle_time = 6.0;
    cooldown = 0.0;
    damage = 1.0;
    energy_per_beam_fire = 3.0;
    heat_per_beam_fire = 0.02;
    parent = nullptr;
}

void BeamHardpoint::setParent(SpaceShip* parent)
{
    assert(!this->parent);
    this->parent = parent;

    parent->registerMemberReplication(&arc);
    parent->registerMemberReplication(&direction);
    parent->registerMemberReplication(&range);
    parent->registerMemberReplication(&turret_arc);
    parent->registerMemberReplication(&turret_direction);
    parent->registerMemberReplication(&turret_rotation_rate);
    parent->registerMemberReplication(&cycle_time);
    parent->registerMemberReplication(&cooldown, 0.5);
}

void BeamHardpoint::setArc(float arc)
{
    this->arc = arc;
}

float BeamHardpoint::getArc()
{
    return arc;
}

void BeamHardpoint::setDirection(float direction)
{
    this->direction = direction;
}

float BeamHardpoint::getDirection()
{
    return direction;
}

void BeamHardpoint::setRange(float range)
{
    this->range = range;
}

float BeamHardpoint::getRange()
{
    return range;
}

void BeamHardpoint::setTurretArc(float arc)
{
    this->turret_arc = arc;
}

float BeamHardpoint::getTurretArc()
{
    return turret_arc;
}

void BeamHardpoint::setTurretDirection(float direction)
{
    this->turret_direction = direction;
}

float BeamHardpoint::getTurretDirection()
{
    return turret_direction;
}

void BeamHardpoint::setTurretRotationRate(float rotation_rate)
{
    this->turret_rotation_rate = rotation_rate;
}

float BeamHardpoint::getTurretRotationRate()
{
    return turret_rotation_rate;
}

void BeamHardpoint::setCycleTime(float cycle_time)
{
    this->cycle_time = cycle_time;
}

float BeamHardpoint::getCycleTime()
{
    return cycle_time;
}

void BeamHardpoint::setDamage(float damage)
{
    this->damage = damage;
}

float BeamHardpoint::getDamage()
{
    return damage;
}

float BeamHardpoint::getEnergyPerFire()
{
    return energy_per_beam_fire;
}

void BeamHardpoint::setEnergyPerFire(float energy)
{
    energy_per_beam_fire = energy;
}

float BeamHardpoint::getHeatPerFire()
{
    return heat_per_beam_fire;
}

void BeamHardpoint::setHeatPerFire(float heat)
{
    heat_per_beam_fire = heat;
}

void BeamHardpoint::setPosition(sf::Vector3f position)
{
    this->position = position;
}

sf::Vector3f BeamHardpoint::getPosition()
{
    return position;
}

void BeamHardpoint::setBeamTexture(string beam_texture)
{
    this->beam_texture = beam_texture;
}

string BeamHardpoint::getBeamTexture()
{
    return beam_texture;
}

float BeamHardpoint::getCooldown()
{
    return cooldown;
}

void BeamHardpoint::update(float delta)
{
    if (cooldown > 0.0)
        cooldown -= delta * parent->getSystemEffectiveness(SYS_BeamWeapons);

    P<SpaceObject> target = parent->getTarget();

    // Check on beam weapons only if we are on the server, have a target, and
    // not paused, and if the beams are cooled down or have a turret arc.
    if (game_server && range > 0.0 && target && parent->isEnemy(target) && delta > 0 && parent->current_warp == 0.0 && parent->docking_state == DS_NotDocking)
    {
        // Get the angle to the target.
        sf::Vector2f diff = target->getPosition() - (parent->getPosition() + sf::rotateVector(sf::Vector2f(position.x, position.y), parent->getRotation()));
        float distance = sf::length(diff) - target->getRadius() / 2.0;

        // We also only care if the target is within no more than its
        // range * 1.3, which is when we want to start rotating the turret.
        // TODO: Add a manual aim override similar to weapon tubes.
        if (distance < range * 1.3)
        {
            float angle = sf::vector2ToAngle(diff);
            float angle_diff = sf::angleDifference(direction + parent->getRotation(), angle);

            if (turret_arc > 0)
            {
                // Get the target's angle relative to the turret's direction.
                float turret_angle_diff = sf::angleDifference(turret_direction + parent->getRotation(), angle);

                // If the turret can rotate ...
                if (turret_rotation_rate > 0)
                {
                    // ... and if the target is within the turret's arc ...
                    if (fabsf(turret_angle_diff) < turret_arc / 2.0)
                    {
                        // ... rotate the turret's beam toward the target.
                        if (fabsf(angle_diff) > 0)
                        {
                            direction += (angle_diff / fabsf(angle_diff)) * std::min(turret_rotation_rate * parent->getSystemEffectiveness(SYS_BeamWeapons), fabsf(angle_diff));
                        }
                    // If the target is outside of the turret's arc ...
                    } else {
                        // ... rotate the turret's beam toward the turret's
                        // direction to reset it.
                        float reset_angle_diff = sf::angleDifference(direction, turret_direction);

                        if (fabsf(reset_angle_diff) > 0)
                        {
                            direction += (reset_angle_diff / fabsf(reset_angle_diff)) * std::min(turret_rotation_rate * parent->getSystemEffectiveness(SYS_BeamWeapons), fabsf(reset_angle_diff));
                        }
                    }
                }
            }

            // If the target is in the beam's arc and range, the beam has cooled
            // down, and the beam can consume enough energy to fire ...
            if (distance < range && cooldown <= 0.0 && fabsf(angle_diff) < arc / 2.0 && parent->useEnergy(energy_per_beam_fire))
            {
                // ... add heat to the beam and zap the target.
                parent->addHeat(SYS_BeamWeapons, heat_per_beam_fire);
                fire(target, parent->beam_system_target);
            }
        }
    // If the beam is turreted and can move, but doesn't have a target, reset it
    // if necessary.
    } else if (game_server && range > 0.0 && delta > 0 && turret_arc > 0.0 && direction != turret_direction && turret_rotation_rate > 0) {
        float reset_angle_diff = sf::angleDifference(direction, turret_direction);

        if (fabsf(reset_angle_diff) > 0)
        {
            direction += (reset_angle_diff / fabsf(reset_angle_diff)) * std::min(turret_rotation_rate * parent->getSystemEffectiveness(SYS_BeamWeapons), fabsf(reset_angle_diff));
        }
    }
}

void BeamHardpoint::fire(P<SpaceObject> target, ESystem system_target)
{
    //When we fire a beam, and we hit an enemy, check if we are not scanned yet, if we are not, and we hit something that we know is an enemy or friendly,
    //  we now know if this ship is an enemy or friend.
    parent->didAnOffensiveAction();

    cooldown = cycle_time; // Reset time of weapon

    sf::Vector2f hit_location = target->getPosition() - sf::normalize(target->getPosition() - parent->getPosition()) * target->getRadius();
    P<BeamEffect> effect = new BeamEffect();
    effect->setSource(parent, position);
    effect->setTarget(target, hit_location);
    effect->beam_texture = beam_texture;
    effect->beam_fire_sound = "sfx/laser_fire.wav";
    effect->beam_fire_sound_power = damage / 6.0f;

    DamageInfo info(parent, DT_Energy, hit_location);
    info.frequency = parent->beam_frequency; // Beam weapons now always use frequency of the ship.
    info.system_target = system_target;
    target->takeDamage(damage, info);
}
