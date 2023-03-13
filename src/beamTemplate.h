#ifndef BEAM_TEMPLATE_H
#define BEAM_TEMPLATE_H

#include "nonCopyable.h"
#include "stringImproved.h"

class BeamTemplate : sp::NonCopyable
{
    static float clampDegrees(float value);

public:
    BeamTemplate();

    string getBeamTexture() const;
    void setBeamTexture(string texture);

    /**
     * Beam weapons are 'arc-ed' weapons, the direction is the center of the arc.
     * Always sets values in degrees between 0 and 360.
     */
    float getDirection() const;
    void setDirection(float direction);

    float getArc() const;
    void setArc(float arc);

    float getRange() const;
    void setRange(float range);

    float getTurretDirection() const;
    void setTurretDirection(float direction);

    float getTurretArc() const;
    void setTurretArc(float arc);

    float getTurretRotationRate() const;
    void setTurretRotationRate(float rotation_rate);

    float getCycleTime() const;
    void setCycleTime(float cycle_time);

    float getDamage() const;
    void setDamage(float damage);

    void setEnergyPerFire(float energy);
    float getEnergyPerFire() const;

    void setHeatPerFire(float heat);
    float getHeatPerFire() const;

    BeamTemplate& operator=(const BeamTemplate& other);

protected:
    string beam_texture;
    float direction; // Value between 0 and 360 (degrees)
    float arc; // Value between 0 and 360
    float range; // Value greater than 0
    float turret_direction; // Value between 0 and 360 (degrees)
    float turret_arc; // Value between 0 and 360 (degrees)
    float turret_rotation_rate; // Value between 0 and 25 (degrees/tick)
    float cycle_time; // Value greater than 0
    float damage; // Value greater than or equal to 0
    float energy_per_beam_fire;
    float heat_per_beam_fire;
};

#endif//BEAM_TEMPLATE_H
