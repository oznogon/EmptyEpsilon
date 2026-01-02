#pragma once

#include "ecs/entity.h"

// ScienceTarget represents the entity selected on the Science/Operations radar.
// This is separate from ScienceScanner.target, which is the entity being actively scanned.
class ScienceTarget
{
public:
    sp::ecs::Entity entity;
};
