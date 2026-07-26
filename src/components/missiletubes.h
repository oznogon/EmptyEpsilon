#pragma once

#include "ecs/entity.h"
#include "shipsystem.h"
#include "missileWeaponData.h"
#include <glm/vec3.hpp>


class MissileTubes : public ShipSystem {
public:
    class MountPoint {
    public:
        enum class State
        {
            Empty,
            Loading,
            Loaded,
            Unloading,
            Firing
        };

        glm::vec3 position{};
        float load_time = 8.0f;
        uint32_t type_allowed_mask = (1 << MW_MaxTypes) - 1;
        float direction = 0.0f;
        EMissileSizes size = MS_Medium;

        int type_loaded = MW_None;
        State state = State::Empty;
        float delay = 0.0f;
        int fire_count = 0;
        float target_angle = 0.0f;

        bool canLoad(int type_index) {
            if (type_index < 0) return false;
            return (type_allowed_mask & (1 << type_index));
        }
        bool canOnlyLoad(int type_index) {
            if (type_index < 0) return false;
            return (type_allowed_mask == (1U << type_index));
        }
    };

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

    bool isMountAllowed(int mount_index, const string& type_name) const
    {
        if (mount_index < 0 || mount_index >= static_cast<int>(mounts.size()))
            return false;
        int idx = MissileWeaponDataRegistry::instance().getIndexForName(type_name);
        if (idx < 0)
            return false;
        return (mounts[mount_index].type_allowed_mask & (1 << idx));
    }

    void setMountAllowed(int mount_index, const string& type_name, bool allowed)
    {
        if (mount_index < 0 || mount_index >= static_cast<int>(mounts.size()))
            return;
        int idx = MissileWeaponDataRegistry::instance().getIndexForName(type_name);
        if (idx < 0)
            return;
        if (allowed)
            mounts[mount_index].type_allowed_mask |= (1 << idx);
        else
            mounts[mount_index].type_allowed_mask &= ~(1U << idx);
    }

    int getTypeLoaded(int mount_index) const
    {
        if (mount_index < 0 || mount_index >= static_cast<int>(mounts.size()))
            return MW_None;
        return mounts[mount_index].type_loaded;
    }

    string getTypeLoadedName(int mount_index) const
    {
        int idx = getTypeLoaded(mount_index);
        if (idx < 0)
            return "";
        return MissileWeaponDataRegistry::instance().getNameForIndex(idx);
    }

    std::vector<MountPoint> mounts;
};
