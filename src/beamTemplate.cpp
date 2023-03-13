#include "beamTemplate.h"

BeamTemplate::BeamTemplate()
: beam_texture("texture/beam_orange.png"),
  direction(0.0F),
  arc(0.0F),
  range(0.0F),
  turret_direction(0.0F),
  turret_arc(0.0F),
  turret_rotation_rate(0.0F),
  cycle_time(0.0F),
  damage(0.0F),
  energy_per_beam_fire(3.0F),
  heat_per_beam_fire(0.02F)
{
}

float BeamTemplate::clampDegrees(float value)
{
    // Clamp value to 0-360. If 360, set to 0.
    while (value < 0.0F)   { value += 360.0F; }
    while (value > 360.0F) { value -= 360.0F; }
    return value == 360.0F ? 0.0F : value;
}

string BeamTemplate::getBeamTexture() const
{
    return beam_texture;
}

void BeamTemplate::setBeamTexture(string texture)
{
    //TODO: Add some more inteligent input checking
    beam_texture = texture;
}

float BeamTemplate::getDirection() const
{
    return direction;
}

void BeamTemplate::setDirection(float direction)
{
    this->direction = clampDegrees(direction);
}

float BeamTemplate::getArc() const
{
    return arc;
}

void BeamTemplate::setArc(float arc)
{
    this->arc = clampDegrees(arc);
}

float BeamTemplate::getRange() const
{
    return range;
}

void BeamTemplate::setRange(float range)
{
    if(range <= 0)
        this->range = 0.1;
    else
        this->range = range;
}

float BeamTemplate::getTurretDirection() const
{
    return turret_direction;
}

void BeamTemplate::setTurretDirection(float direction)
{
    this->turret_direction = clampDegrees(direction);
}

float BeamTemplate::getTurretArc() const
{
    return turret_arc;
}

void BeamTemplate::setTurretArc(float arc)
{
    this->turret_arc = clampDegrees(arc);
}

float BeamTemplate::getTurretRotationRate() const
{
    return turret_rotation_rate;
}

void BeamTemplate::setTurretRotationRate(float rotation_rate)
{
    if (rotation_rate < 0.0f)
        this->turret_rotation_rate = 0.0f;
    // 25 is an arbitrary limit. Values greater than 25.0 are nearly
    // instantaneous.
    else if (rotation_rate > 25.0f)
        this->turret_rotation_rate = 25.0f;
    else
        this->turret_rotation_rate = rotation_rate;
}

float BeamTemplate::getCycleTime() const
{
    return cycle_time;
}

void BeamTemplate::setCycleTime(float cycle_time)
{
    if(cycle_time <= 0)
        this->cycle_time = 0.1;
    else
        this->cycle_time = cycle_time;
}

float BeamTemplate::getDamage() const
{
    return damage;
}

void BeamTemplate::setDamage(float damage)
{
    if(damage < 0)
        this->damage = 0;
    else
        this->damage = damage;
}

float BeamTemplate::getEnergyPerFire() const
{
    return energy_per_beam_fire;
}

void BeamTemplate::setEnergyPerFire(float energy)
{
    energy_per_beam_fire = energy;
}

float BeamTemplate::getHeatPerFire() const
{
    return heat_per_beam_fire;
}

void BeamTemplate::setHeatPerFire(float heat)
{
    heat_per_beam_fire = heat;
}

BeamTemplate& BeamTemplate::operator=(const BeamTemplate& other)
{
    beam_texture = other.beam_texture;
    direction = other.direction;
    arc = other.arc;
    range = other.range;
    turret_direction = other.turret_direction;
    turret_arc = other.turret_arc;
    turret_arc = other.turret_rotation_rate;
    cycle_time = other.cycle_time;
    damage = other.damage;
    energy_per_beam_fire = other.energy_per_beam_fire;
    heat_per_beam_fire = other.heat_per_beam_fire;
    return *this;
}
