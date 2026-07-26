#pragma once

#include "script/callback.h"
#include "missileWeaponData.h"


class PickupCallback
{
public:
    bool player = true;
    sp::script::Callback callback;
    float give_energy = 0;
    std::vector<int> give_missile{std::vector<int>(MW_MaxTypes, 0)};
    int give_probe = 0;

    int getGiveMissile(const string& type_name) const
    {
        int idx = MissileWeaponDataRegistry::instance().getIndexForName(type_name);
        if (idx >= 0 && idx < MW_MaxTypes)
            return give_missile[idx];
        return 0;
    }

    void setGiveMissile(const string& type_name, int amount)
    {
        int idx = MissileWeaponDataRegistry::instance().getIndexForName(type_name);
        if (idx >= 0 && idx < MW_MaxTypes)
            give_missile[idx] = std::max(0, amount);
    }
};

class CollisionCallback
{
public:
    bool player = true;
    sp::script::Callback callback;
};
