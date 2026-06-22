#include "dynamicLight.h"

std::vector<DynamicLight> DynamicLightManager::lights;

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
