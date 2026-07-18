#include "dynamicLight.h"
#include "preferenceManager.h"

std::vector<DynamicLight> DynamicLightManager::lights;

bool DynamicLightManager::isEnabled()
{
    return PreferencesManager::get("dynamic_nebula_lighting", "1") == "1";
}

void DynamicLightManager::add(const DynamicLight& light)
{
    if (lights.size() < 32)
        lights.push_back(light);
}

void DynamicLightManager::clear()
{
    lights.clear();
}

const std::vector<DynamicLight>& DynamicLightManager::getLights()
{
    return lights;
}

int DynamicLightManager::getCount()
{
    return static_cast<int>(lights.size());
}
