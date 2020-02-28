#include "beamHardpoint.h"
#include "spaceObjects/beams/EMBeam.h"
#include "spaceObjects/beams/energyBeam.h"
#include "spaceObjects/spaceship.h"

BeamHardpoint::BeamHardpoint()
{
    parent = nullptr;
    
    config_time = 6.0;
    cycle_time = 6.0;
    cooldown = 0.0;
    delay = 0.0;

    arc = 0.0;
    direction = 0.0;
    range = 0.0;
    turret_arc = 0.0;
    turret_direction = 0.0;
    turret_rotation_rate = 0.0;

    type_allowed_mask = (1 << BW_Count) - 1;
    type_loaded = BW_Energy;
    state = BHS_Ready;

    hardpoint_index = 0;
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

    parent->registerMemberReplication(&config_time);
    parent->registerMemberReplication(&type_loaded);
    parent->registerMemberReplication(&state);
}

void BeamHardpoint::setIndex(int index)
{
    hardpoint_index = index;
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

void BeamHardpoint::setConfigTime(float config_time)
{
    this->config_time = config_time;
}

float BeamHardpoint::getConfigTime()
{
    return config_time;
}

void BeamHardpoint::setCycleTime(float cycle_time)
{
    this->cycle_time = cycle_time;
}

float BeamHardpoint::getCycleTime()
{
    return cycle_time;
}

void BeamHardpoint::configureBeam(EBeamWeapons type)
{
    if (!canConfigure(type))
        return;
    if (state == BHS_Ready || state == BHS_Empty)
    {
        state = BHS_Configuring;
        delay = config_time;
        type_loaded = type;
    }
}

void BeamHardpoint::startUnload()
{
    if (state == BHS_Ready)
    {
        state = BHS_Configuring;
        delay = config_time;
    }
}

void BeamHardpoint::fire(P<SpaceObject> target, ESystem system_target)
{
    if (parent->docking_state != DS_NotDocking) return;
    if (parent->current_warp > 0.0) return;

    // When we fire a beam, and we hit an enemy, check if we are not scanned
    // yet. If we are not, and we hit something that we know is hostile or
    // friendly, we now know if this ship is an enemy or friend.
    parent->didAnOffensiveAction();

    cooldown = cycle_time; // Reset weapon cooldown

    sf::Vector2f hit_location = target->getPosition() - sf::normalize(target->getPosition() - parent->getPosition()) * target->getRadius();
    // TODO: Continue here
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

void BeamHardpoint::fire(float target_angle)
{
    parent->didAnOffensiveAction();

    if (parent->docking_state != DS_NotDocking) return;
    if (parent->current_warp > 0.0) return;
    if (state == BHS_Ready)
    {
        spawnProjectile(target_angle);
        state = BHS_Empty;
        type_loaded = BW_None;
    }
}

float BeamHardpoint::getSizeCategoryModifier()
{
    switch(size)
    {
        case MS_Small:
            return 0.5;
        case MS_Medium:
            return 1.0;
        case MS_Large:
            return 2.0;
        default:
            return 1.0;
    }
}


void BeamHardpoint::spawnProjectile(float target_angle)
{
    sf::Vector2f fireLocation = parent->getPosition() + sf::rotateVector(parent->ship_template->model_data->getTubePosition2D(tube_index), parent->getRotation());
    switch(type_loaded)
    {
    case BW_Homing:
        {
            P<HomingMissile> missile = new HomingMissile();
            missile->owner = parent;
            missile->setFactionId(parent->getFactionId());
            missile->target_id = parent->target_id;
            missile->setPosition(fireLocation);
            missile->setRotation(parent->getRotation() + direction);
            missile->target_angle = target_angle;
            missile->category_modifier = getSizeCategoryModifier();
        }
        break;
    case BW_Nuke:
        {
            P<Nuke> missile = new Nuke();
            missile->owner = parent;
            missile->setFactionId(parent->getFactionId());
            missile->target_id = parent->target_id;
            missile->setPosition(fireLocation);
            missile->setRotation(parent->getRotation() + direction);
            missile->target_angle = target_angle;
            missile->category_modifier = getSizeCategoryModifier();
        }
        break;
    case BW_Mine:
        {
            P<Mine> missile = new Mine();
            missile->owner = parent;
            missile->setFactionId(parent->getFactionId());
            missile->setPosition(fireLocation);
            missile->setRotation(parent->getRotation() + direction);
            missile->eject();
        }
        break;
    case BW_HVLI:
        {
            P<HVLI> missile = new HVLI();
            missile->owner = parent;
            missile->setFactionId(parent->getFactionId());
            missile->setPosition(fireLocation);
            missile->setRotation(parent->getRotation() + direction);
            missile->target_angle = parent->getRotation() + direction;
            missile->category_modifier = getSizeCategoryModifier();
        }
        break;
    case BW_EMP:
        {
            P<EMPMissile> missile = new EMPMissile();
            missile->owner = parent;
            missile->setFactionId(parent->getFactionId());
            missile->target_id = parent->target_id;
            missile->setPosition(fireLocation);
            missile->setRotation(parent->getRotation() + direction);
            missile->target_angle = target_angle;
            missile->category_modifier = getSizeCategoryModifier();
        }
        break;
    default:
        break;
    }
}

bool BeamHardpoint::canLoad(EBeamWeapons type)
{
    if (type <= BW_None || type >= BW_Count)
        return false;
    if (type_allowed_mask & (1 << type))
        return true;
    return false;
}

bool BeamHardpoint::canOnlyLoad(EBeamWeapons type)
{
    if (type_allowed_mask == (1U << type))
        return true;
    return false;
}

void BeamHardpoint::allowLoadOf(EBeamWeapons type)
{
    type_allowed_mask |= (1 << type);
}

void BeamHardpoint::disallowLoadOf(EBeamWeapons type)
{
    type_allowed_mask &=~(1 << type);
}

void BeamHardpoint::forceUnload()
{
    if (state != BHS_Empty && type_loaded != BW_None)
    {
        state = BHS_Empty;
        if (parent->weapon_storage[type_loaded] < parent->weapon_storage_max[type_loaded])
            parent->weapon_storage[type_loaded] ++;
        type_loaded = BW_None;
    }
}

void BeamHardpoint::update(float delta)
{
    if (delay > 0.0)
    {
        delay -= delta * parent->getSystemEffectiveness(SYS_MissileSystem);
    }else{
        switch(state)
        {
        case BHS_Loading:
            state = BHS_Loaded;
            break;
        case BHS_Unloading:
            state = BHS_Empty;
            if (parent->weapon_storage[type_loaded] < parent->weapon_storage_max[type_loaded])
                parent->weapon_storage[type_loaded] ++;
            type_loaded = BW_None;
            break;
        case BHS_Firing:
            {
                spawnProjectile(0);
                
                fire_count -= 1;
                if (fire_count > 0)
                {
                    delay = 1.5;
                }
                else
                {
                    state = BHS_Empty;
                    type_loaded = BW_None;
                }
            }
            break;
        default:
            break;
        }
    }
}

bool BeamHardpoint::isEmpty()
{
    return state == BHS_Empty;
}

bool BeamHardpoint::isLoaded()
{
    return state == BHS_Loaded;
}

bool BeamHardpoint::isLoading()
{
    return state == BHS_Loading;
}

bool BeamHardpoint::isUnloading()
{
    return state == BHS_Unloading;
}

bool BeamHardpoint::isFiring()
{
    return state == BHS_Firing;
}

float BeamHardpoint::getLoadProgress()
{
    return 1.0 - delay / load_time;
}

float BeamHardpoint::getUnloadProgress()
{
    return delay / load_time;
}

EBeamWeapons BeamHardpoint::getLoadType()
{
    return type_loaded;
}

string BeamHardpoint::getTubeName()
{
    if (std::abs(sf::angleDifference(0.0f, direction)) <= 45)
        return "Front";
    if (std::abs(sf::angleDifference(90.0f, direction)) < 45)
        return "Right";
    if (std::abs(sf::angleDifference(-90.0f, direction)) < 45)
        return "Left";
    if (std::abs(sf::angleDifference(180.0f, direction)) <= 45)
        return "Rear";
    return "?" + string(direction);
}

float BeamHardpoint::calculateFiringSolution(P<SpaceObject> target)
{
    if (!target)
        return std::numeric_limits<float>::infinity();
    const MissileWeaponData& data = MissileWeaponData::getDataFor(type_loaded);
    if (data.turnrate == 0.0f)  //If the missile cannot turn, we cannot find a firing solution.
        return std::numeric_limits<float>::infinity();
    
    sf::Vector2f target_position = target->getPosition();
    sf::Vector2f target_velocity = target->getVelocity();
    float target_velocity_length = sf::length(target_velocity);
    float missile_angle = sf::vector2ToAngle(target_position - parent->getPosition());
    float turn_radius = ((360.0f / data.turnrate) * data.speed) / (2.0f * M_PI);
    float missile_exit_angle = parent->getRotation() + direction;
    
    for(int iterations=0; iterations<10; iterations++)
    {
        float angle_diff = sf::angleDifference(missile_angle, missile_exit_angle);

        float left_or_right = 90;
        if (angle_diff > 0)
            left_or_right = -90;

        sf::Vector2f turn_center = parent->getPosition() + sf::vector2FromAngle(missile_exit_angle + left_or_right) * turn_radius;
        sf::Vector2f turn_exit = turn_center + sf::vector2FromAngle(missile_angle - left_or_right) * turn_radius;
        if (target_velocity_length < 1.0f)
        {
            //If the target is almost standing still, just target the position directly instead of using the velocity of the target in the calculations.
            float time_missile = sf::length(turn_exit - target_position) / data.speed;
            sf::Vector2f interception = turn_exit + sf::vector2FromAngle(missile_angle) * data.speed * time_missile;
            if ((interception - target_position) < target->getRadius() / 2)
                return missile_angle;
            missile_angle = sf::vector2ToAngle(target_position - turn_exit);
        }
        else
        {
            sf::Vector2f missile_velocity = sf::vector2FromAngle(missile_angle) * data.speed;
            //Calculate the position where missile and the target will cross each others path.
            sf::Vector2f intersection = sf::lineLineIntersection(target_position, target_position + target_velocity, turn_exit, turn_exit + missile_velocity);
            //Calculate the time it will take for the target and missile to reach the intersection
            float turn_time = fabs(angle_diff) / data.turnrate;
            float time_target = sf::length((target_position - intersection)) / target_velocity_length;
            float time_missile = sf::length(turn_exit - intersection) / data.speed + turn_time;
            //Calculate the time in which the radius will be on the intersection, to know in which time range we need to hit.
            float time_radius = (target->getRadius() / 2.0) / target_velocity_length;//TODO: This value could be improved, as it is allowed to be bigger when the angle between the missile and the ship is low
            // When both the missile and the target are at the same position at the same time, we can take a shot!
            if (fabsf(time_target - time_missile) < time_radius)
                return missile_angle;

            //When we cannot hit the target with this setup yet. Calculate a new intersection target, and aim for that.
            float guessed_impact_time = (time_target * target_velocity_length / (target_velocity_length + data.speed)) + (time_missile * data.speed / (target_velocity_length + data.speed));
            sf::Vector2f new_target_position = target_position + target_velocity * guessed_impact_time;
            missile_angle = sf::vector2ToAngle(new_target_position - turn_exit);
        }
    }
    return std::numeric_limits<float>::infinity();
}

void BeamHardpoint::setSize(EMissileSizes size)
{
    this->size = size;
}

EMissileSizes BeamHardpoint::getSize()
{
    return size;
}
    
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

