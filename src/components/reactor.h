#pragma once

#include "shipsystem.h"

// The Reactor component stores and generates energy. Any other ShipSystem can
// consume energy, but the Reactor only generates energy.
class Reactor : public ShipSystem
{
public:
    Reactor() { can_be_hacked = false; }

    // Config
    float max_energy = 1000.0f;
    bool overload_explode = true;

    // Runtime
    float energy = 1000.0f;

    // Return the current energy value as an integer percentile.
    int energyPercentage()
    {
        if (max_energy <= 0.0f) return 0;
        return static_cast<int>(100.0f * energy / max_energy);
    }
    // Consume the given amount of energy. Returns false if the request is
    // larger than the available energy.
    bool useEnergy(float amount)
    {
        if (amount > energy) return false;
        energy -= amount;
        return true;
    }
};
