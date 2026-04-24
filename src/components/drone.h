#pragma once

#include "shipsystem.h"


// Placed on a drone entity. Marks it as controllable by its owner.
class AllowDroneLink
{
public:
    sp::ecs::Entity owner;
};

// Placed on a ship entity. Configures drone control capability.
class DroneController
{
public:
    float control_range = 5000.0f;
    float energy_drain_per_sec = 0.0f;
};

// Placed on a ship entity at runtime when connected to a drone.
// Cleared by DroneControlSystem on auto-disconnect. Analogous to RadarLink.
class DroneLink
{
public:
    sp::ecs::Entity linked_drone;
};

// Ship system component that represents a Sensors array.
// When present, scales DroneController::control_range and energy_drain_per_sec
// by system effectiveness, and accumulates heat during drone operation.
class SensorsSystem : public ShipSystem {};
