#include "missileWeaponData.h"
#include "i18n.h"
#include "ecs/query.h"
#include "gui/theme.h"

MissileWeaponDataRegistry& MissileWeaponDataRegistry::instance()
{
    static MissileWeaponDataRegistry registry;
    return registry;
}

static MissileWeaponData* getComponent(sp::ecs::Entity entity)
{
    if (!entity) return nullptr;
    return entity.getComponent<MissileWeaponData>();
}

int MissileWeaponDataRegistry::registerEntity(sp::ecs::Entity entity, const string& name)
{
    if (type_count >= MW_MaxTypes) return -1;
    if (!entity) return -1;

    int idx = type_count;
    entries[idx].entity = entity;
    entries[idx].name = name;
    name_to_index[name] = idx;
    type_count++;

    if (auto* c = getComponent(entity)) c->index = idx;

    return idx;
}

void MissileWeaponDataRegistry::unregisterEntity(sp::ecs::Entity entity)
{
    if (!entity) return;

    auto* c = getComponent(entity);
    if (!c || c->index < 0 || c->index >= type_count) return;

    int idx = c->index;
    const string name = entries[idx].name;
    name_to_index.erase(name);

    for (int i = idx; i < type_count - 1; i++)
    {
        entries[i] = entries[i + 1];

        if (auto* comp = getComponent(entries[i].entity)) comp->index = i;

        name_to_index[entries[i].name] = i;
    }

    type_count--;
    c->index = -1;
}

void MissileWeaponDataRegistry::rebuild()
{
    name_to_index.clear();
    type_count = 0;

    std::vector<sp::ecs::Entity> sorted_entities;
    for (auto [entity, data] : sp::ecs::Query<MissileWeaponData>())
        if (!data.name.empty()) sorted_entities.push_back(entity);

    std::sort(sorted_entities.begin(), sorted_entities.end(),
        [](sp::ecs::Entity a, sp::ecs::Entity b)
        {
            auto* da = a.getComponent<MissileWeaponData>();
            auto* db = b.getComponent<MissileWeaponData>();

            if (!da || !db) return false;
            if (da->order != db->order) return da->order < db->order;
            return da->name < db->name;
        });

    for (size_t i = 0; i < sorted_entities.size() && i < MW_MaxTypes; i++)
    {
        auto entity = sorted_entities[i];
        auto* data = getComponent(entity);

        if (!data) continue;

        entries[i].entity = entity;
        entries[i].name = data->name;
        data->index = static_cast<int>(i);
        name_to_index[data->name] = static_cast<int>(i);
        type_count++;
    }
}

int MissileWeaponDataRegistry::getIndexForName(const string& name) const
{
    auto it = name_to_index.find(name);

    if (it != name_to_index.end()) return it->second;
    return MW_None;
}

sp::ecs::Entity MissileWeaponDataRegistry::getEntityForName(const string& name) const
{
    int idx = getIndexForName(name);

    if (idx >= 0 && idx < type_count) return entries[idx].entity;
    return {};
}

sp::ecs::Entity MissileWeaponDataRegistry::getEntityForIndex(int index) const
{
    if (index >= 0 && index < type_count) return entries[index].entity;
    return {};
}

const string& MissileWeaponDataRegistry::getNameForIndex(int index) const
{
    static const string empty;

    if (index >= 0 && index < type_count) return entries[index].name;
    return empty;
}

int MissileWeaponDataRegistry::getMissileWeaponName(int index) const
{
    return getIndexForName(getNameForIndex(index));
}

int MissileWeaponDataRegistry::getLocaleMissileWeaponName(int index) const
{
    return getIndexForName(getNameForIndex(index));
}

float MissileWeaponDataRegistry::getSpeed(int index) const
{
    if (auto* c = getComponent(getEntityForIndex(index))) return c->speed;
    return 200.0f;
}

float MissileWeaponDataRegistry::getTurnrate(int index) const
{
    if (auto* c = getComponent(getEntityForIndex(index))) return c->turnrate;
    return 10.0f;
}

float MissileWeaponDataRegistry::getLifetime(int index) const
{
    if (auto* c = getComponent(getEntityForIndex(index))) return c->lifetime;
    return 27.0f;
}

glm::u8vec4 MissileWeaponDataRegistry::getColor(int index) const
{
    if (auto* c = getComponent(getEntityForIndex(index))) return c->color;
    return {255, 255, 255, 255};
}

float MissileWeaponDataRegistry::getHomingRange(int index) const
{
    if (auto* c = getComponent(getEntityForIndex(index)))
        return c->homing_range;
    return 0.0f;
}

const string& MissileWeaponDataRegistry::getIcon(int index) const
{
    static const string empty;

    if (auto* c = getComponent(getEntityForIndex(index))) return c->icon;
    return empty;
}

const string& MissileWeaponDataRegistry::getFireSound(int index) const
{
    static const string empty;

    if (auto* c = getComponent(getEntityForIndex(index))) return c->fire_sound;
    return empty;
}

const string& MissileWeaponDataRegistry::getRadarTrace(int index) const
{
    static const string empty;

    if (auto* c = getComponent(getEntityForIndex(index))) return c->radar_trace;
    return empty;
}

float MissileWeaponDataRegistry::getDamageAtCenter(int index) const
{
    if (auto* c = getComponent(getEntityForIndex(index)))
        return c->damage_at_center;
    return 35.0f;
}

float MissileWeaponDataRegistry::getDamageAtEdge(int index) const
{
    if (auto* c = getComponent(getEntityForIndex(index)))
        return c->damage_at_edge;
    return 5.0f;
}

float MissileWeaponDataRegistry::getBlastRange(int index) const
{
    if (auto* c = getComponent(getEntityForIndex(index))) return c->blast_range;
    return 30.0f;
}

const string& MissileWeaponDataRegistry::getExplosionSfx(int index) const
{
    static const string empty;

    if (auto* c = getComponent(getEntityForIndex(index)))
        return c->explosion_sfx;
    return empty;
}

float MissileWeaponDataRegistry::getRadarR(int index) const
{
    if (auto* c = getComponent(getEntityForIndex(index))) return c->radar_r;
    return 0.0f;
}

float MissileWeaponDataRegistry::getRadarG(int index) const
{
    if (auto* c = getComponent(getEntityForIndex(index))) return c->radar_g;
    return 0.0f;
}

float MissileWeaponDataRegistry::getRadarB(int index) const
{
    if (auto* c = getComponent(getEntityForIndex(index))) return c->radar_b;
    return 0.0f;
}

bool MissileWeaponDataRegistry::getExplodesOnTimeout(int index) const
{
    if (auto* c = getComponent(getEntityForIndex(index)))
        return c->explodes_on_timeout;
    return false;
}

bool MissileWeaponDataRegistry::getIsDelayedExplode(int index) const
{
    if (auto* c = getComponent(getEntityForIndex(index)))
        return c->is_delayed_explode;
    return false;
}

int MissileWeaponDataRegistry::getFireCount(int index) const
{
    if (auto* c = getComponent(getEntityForIndex(index))) return c->fire_count;
    return 1;
}

DamageType MissileWeaponDataRegistry::getDamageType(int index) const
{
    if (auto* c = getComponent(getEntityForIndex(index)))
        return c->damage_type;
    return DamageType::Kinetic;
}

int MissileWeaponDataRegistry::getAvoidObjectDelay(int index) const
{
    if (auto* c = getComponent(getEntityForIndex(index)))
        return c->avoid_object_delay;
    return 0;
}

bool MissileWeaponDataRegistry::getCircleCollision(int index) const
{
    if (auto* c = getComponent(getEntityForIndex(index)))
        return c->circle_collision;
    return false;
}

bool MissileWeaponDataRegistry::getNoLifetimeOnMissile(int index) const
{
    if (auto* c = getComponent(getEntityForIndex(index)))
        return c->no_lifetime_on_missile;
    return false;
}

sp::script::Callback& MissileWeaponDataRegistry::getOnSpawn(int index)
{
    static sp::script::Callback empty;
    if (auto* c = getComponent(getEntityForIndex(index)))
        return c->on_spawn;
    return empty;
}

sp::script::Callback& MissileWeaponDataRegistry::getOnCollision(int index)
{
    static sp::script::Callback empty;
    if (auto* c = getComponent(getEntityForIndex(index)))
        return c->on_collision;
    return empty;
}

sp::script::Callback& MissileWeaponDataRegistry::getOnLifetimeExpire(int index)
{
    static sp::script::Callback empty;
    if (auto* c = getComponent(getEntityForIndex(index)))
        return c->on_lifetime_expire;
    return empty;
}

sp::script::Callback& MissileWeaponDataRegistry::getOnExplode(int index)
{
    static sp::script::Callback empty;
    if (auto* c = getComponent(getEntityForIndex(index)))
        return c->on_explode;
    return empty;
}

std::vector<string> MissileWeaponDataRegistry::getTypeNames() const
{
    std::vector<string> names;
    for (int i = 0; i < type_count; i++) names.push_back(entries[i].name);

    return names;
}

std::vector<int> MissileWeaponDataRegistry::getTypeIndices() const
{
    std::vector<int> indices;
    for (int i = 0; i < type_count; i++) indices.push_back(i);

    return indices;
}

string getMissileSizeString(EMissileSizes size)
{
    switch (size)
    {
        case MS_Small: return "small";
        case MS_Medium: return "medium";
        case MS_Large: return "large";
        default:
            return string("Unknown size: ") + string(size);
    }
}

float MissileWeaponData::convertSizeToCategoryModifier(EMissileSizes size)
{
    switch (size)
    {
        case MS_Small: return 0.5f;
        case MS_Medium: return 1.0f;
        case MS_Large: return 2.0f;
        default: return 1.0f;
    }
}

EMissileSizes MissileWeaponData::convertCategoryModifierToSize(float size)
{
    if (std::abs(size - 0.5f) < 0.1f) return MS_Small;
    if (std::abs(size - 1.0f) < 0.1f) return MS_Medium;
    if (std::abs(size - 2.0f) < 0.1f) return MS_Large;
    return MS_Medium;
}
