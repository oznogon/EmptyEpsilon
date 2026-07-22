#pragma once

#include <glm/glm.hpp>
#include <unordered_map>
#include "io/pointer.h"

class GestureTracker
{
public:
    GestureTracker() = default;

    void fingerDown(sp::io::Pointer::ID id, glm::vec2 position);
    void fingerMove(sp::io::Pointer::ID id, glm::vec2 position);
    void fingerUp(sp::io::Pointer::ID id);
    void reset();

    int getFingerCount() const { return static_cast<int>(fingers.size()); }
    bool isGestureActive() const { return fingers.size() >= 2; }

    float getPinchDistance() const;
    float getRotationAngle() const;
    glm::vec2 getCentroid() const;

    glm::vec2 getPosition(sp::io::Pointer::ID id) const;
    bool hasFinger(sp::io::Pointer::ID id) const { return fingers.find(id) != fingers.end(); }

private:
    std::unordered_map<sp::io::Pointer::ID, glm::vec2> fingers;
};
