#pragma once

#include <glm/vec3.hpp>
#include <vector>

struct DynamicLight
{
    glm::vec3 position;
    glm::vec3 color;
    float radius;
    float intensity;
};

class DynamicLightManager
{
public:
    static bool isEnabled();
    static void add(const DynamicLight& light);
    static void clear();
    static const std::vector<DynamicLight>& getLights();
    static int getCount();
private:
    static std::vector<DynamicLight> lights;
};
