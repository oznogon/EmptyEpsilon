#pragma once

#include "ecs/entity.h"
#include "systems/damage.h"
#include <glm/gtc/type_precision.hpp>
#include <array>
#include <unordered_map>

static constexpr int16_t MW_None = -1;
static constexpr int MW_MaxTypes = 16;

class MissileWeaponDataRegistry
{
public:
    static MissileWeaponDataRegistry& instance();

    int registerEntity(sp::ecs::Entity entity, const string& name);
    void unregisterEntity(sp::ecs::Entity entity);
    void rebuild();

    int getTypeCount() const { return type_count; }

    int getIndexForName(const string& name) const;
    sp::ecs::Entity getEntityForName(const string& name) const;
    sp::ecs::Entity getEntityForIndex(int index) const;
    const string& getNameForIndex(int index) const;

    int getMissileWeaponName(int index) const;
    int getLocaleMissileWeaponName(int index) const;

    float getSpeed(int index) const;
    float getTurnrate(int index) const;
    float getLifetime(int index) const;
    glm::u8vec4 getColor(int index) const;
    float getHomingRange(int index) const;
    const string& getFireSound(int index) const;
    const string& getRadarTrace(int index) const;

    float getDamageAtCenter(int index) const;
    float getDamageAtEdge(int index) const;
    float getBlastRange(int index) const;
    const string& getExplosionSfx(int index) const;
    float getRadarR(int index) const;
    float getRadarG(int index) const;
    float getRadarB(int index) const;
    bool getExplodesOnTimeout(int index) const;
    bool getIsDelayedExplode(int index) const;
    int getFireCount(int index) const;
    DamageType getDamageType(int index) const;
    int getAvoidObjectDelay(int index) const;
    bool getCircleCollision(int index) const;
    bool getNoLifetimeOnMissile(int index) const;

    std::vector<string> getTypeNames() const;
    std::vector<int> getTypeIndices() const;

private:
    MissileWeaponDataRegistry() = default;

    struct Entry
    {
        sp::ecs::Entity entity;
        string name;
    };

    std::array<Entry, MW_MaxTypes> entries;
    int type_count = 0;
    std::unordered_map<string, int> name_to_index;
};

enum EMissileSizes
{
    MS_Small = 0,
    MS_Medium = 1,
    MS_Large = 2,
};

string getMissileSizeString(EMissileSizes size);

class MissileWeaponData
{
public:
    MissileWeaponData() = default;

    int index = -1;
    string name;
    string locale_name;
    int order = 0;
    float speed = 200.0f;
    float turnrate = 10.0f;
    float lifetime = 27.0f;
    glm::u8vec4 color = {255, 255, 255, 255};
    float homing_range = 0.0f;
    string fire_sound = "sfx/rlaunch.wav";
    string radar_trace = "radar/missile.png";

    float damage_at_center = 35.0f;
    float damage_at_edge = 5.0f;
    float blast_range = 30.0f;
    string explosion_sfx = "sfx/explosion.wav";
    float radar_r = 0.0f;
    float radar_g = 0.1f;
    float radar_b = 0.2f;
    bool explodes_on_timeout = false;
    bool is_delayed_explode = false;
    int fire_count = 1;
    DamageType damage_type = DamageType::Kinetic;
    int avoid_object_delay = 0;
    bool circle_collision = false;
    bool no_lifetime_on_missile = false;

    static float convertSizeToCategoryModifier(EMissileSizes size);
    static EMissileSizes convertCategoryModifierToSize(float size);
};
