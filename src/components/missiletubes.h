#pragma once

#include "ecs/entity.h"
#include "shipsystem.h"
#include "missileWeaponData.h"
#include <glm/vec3.hpp>


class MissileTubes : public ShipSystem {
public:
    std::vector<int> storage{std::vector<int>(MW_MaxTypes, 0)};
    std::vector<int> storage_max{std::vector<int>(MW_MaxTypes, 0)};

    int getStorage(const string& type_name) const
    {
        int idx = MissileWeaponDataRegistry::instance().getIndexForName(type_name);
        if (idx >= 0 && idx < MW_MaxTypes)
            return storage[idx];
        return 0;
    }

    void setStorage(const string& type_name, int amount)
    {
        int idx = MissileWeaponDataRegistry::instance().getIndexForName(type_name);
        if (idx >= 0 && idx < MW_MaxTypes)
            storage[idx] = std::max(0, amount);
    }

    int getStorageMax(const string& type_name) const
    {
        int idx = MissileWeaponDataRegistry::instance().getIndexForName(type_name);
        if (idx >= 0 && idx < MW_MaxTypes)
            return storage_max[idx];
        return 0;
    }

    void setStorageMax(const string& type_name, int amount)
    {
        int idx = MissileWeaponDataRegistry::instance().getIndexForName(type_name);
        if (idx >= 0 && idx < MW_MaxTypes)
            storage_max[idx] = std::max(0, amount);
    }
};
