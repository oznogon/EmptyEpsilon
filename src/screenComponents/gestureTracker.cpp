#include "gestureTracker.h"
#include <cmath>

void GestureTracker::fingerDown(sp::io::Pointer::ID id, glm::vec2 position)
{
    fingers[id] = position;
}

void GestureTracker::fingerMove(sp::io::Pointer::ID id, glm::vec2 position)
{
    auto it = fingers.find(id);
    if (it != fingers.end())
        it->second = position;
}

void GestureTracker::fingerUp(sp::io::Pointer::ID id)
{
    fingers.erase(id);
}

void GestureTracker::reset()
{
    fingers.clear();
}

glm::vec2 GestureTracker::getPosition(sp::io::Pointer::ID id) const
{
    auto it = fingers.find(id);
    if (it != fingers.end())
        return it->second;
    return glm::vec2(0.0f, 0.0f);
}

float GestureTracker::getPinchDistance() const
{
    if (fingers.size() < 2) return 0.0f;
    auto it = fingers.begin();
    glm::vec2 p0 = it->second;
    ++it;
    glm::vec2 p1 = it->second;
    return glm::length(p1 - p0);
}

float GestureTracker::getRotationAngle() const
{
    if (fingers.size() < 2) return 0.0f;
    auto it = fingers.begin();
    glm::vec2 p0 = it->second;
    ++it;
    glm::vec2 p1 = it->second;
    return std::atan2(p1.y - p0.y, p1.x - p0.x);
}

glm::vec2 GestureTracker::getCentroid() const
{
    if (fingers.size() < 2) return glm::vec2(0.0f, 0.0f);
    auto it = fingers.begin();
    glm::vec2 p0 = it->second;
    ++it;
    glm::vec2 p1 = it->second;
    return (p0 + p1) * 0.5f;
}
