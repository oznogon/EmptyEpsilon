#pragma once

#include "ecs/system.h"
#include "ecs/entity.h"

class InternalCrewSystem : public sp::ecs::System
{
public:
    void update(float delta) override;
};

// Returns true when the given internal room coordinates are already claimed by
// a repair crew on the given entity, either as that crew's current position or
// as its target position.
bool internalCrewIsCellOccupied(sp::ecs::Entity ship, glm::ivec2 cell, sp::ecs::Entity self);
