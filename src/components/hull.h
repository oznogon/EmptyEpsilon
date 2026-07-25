#pragma once

#include "script/callback.h"
#include "systems/damage.h"

// Component to indicate that this entity has a hull and can take hull damage.
// Entities are typically destroyed once they reach zero hull, but you can
// disable this to prevent player ship destruction in LARP scenarios or
// tutorials.
class Hull
{
public:
    float current = 100.0f;
    float max = 100.0f;
    // Return the current hull value as an integer percentile.
    int percentage() const
    {
        if (max <= 0.0f) return 0;
        return static_cast<int>(100.0f * current / max);
    }

    bool allow_destruction = true;
    int damaged_by_flags = (1 << static_cast<int>(DamageType::Energy)) | (1 << static_cast<int>(DamageType::Kinetic));
    float damage_indicator = 0.0f;

    sp::script::Callback on_destruction;
    sp::script::Callback on_taking_damage;
};

// Component to indicate that this entity lacks a hull, but an explosion in the
// area will still destroy it.
class DestroyedByAreaDamage
{
public:
    int damaged_by_flags = (1 << static_cast<int>(DamageType::Energy)) | (1 << static_cast<int>(DamageType::Kinetic));
};