#pragma once

#include "ecs/entity.h"

// Component to indicate that we can hack other ships.
class HackingDevice
{
public:
    float effectiveness = 0.5f;
    sp::ecs::Entity target; // The entity currently being hacked

    // Check if the player ship can hack the given target entity.
    // Returns true if the target is hackable by the player.
    static bool canHack(sp::ecs::Entity player_ship, sp::ecs::Entity target);
};