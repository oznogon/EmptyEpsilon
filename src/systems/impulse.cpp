#include "systems/impulse.h"
#include "multiplayer_server.h"
#include "components/docking.h"
#include "components/collision.h"
#include "components/impulse.h"
#include "components/warpdrive.h"
#include "ecs/query.h"


void ImpulseSystem::update(float delta)
{
    if (!game_server) return;

    for (auto [entity, impulse, physics, transform, warp_drive] : sp::ecs::Query<ImpulseEngine, sp::Physics, sp::Transform, sp::ecs::optional<WarpDrive>>())
    {
        // Have max speed at 100% impulse, and max reverse speed at -100% impulse
        float cap_speed = impulse.max_speed_forward;

        if (impulse.actual < 0 && impulse.max_speed_reverse <= 0.01f)
            impulse.actual = 0; // We could have no reverse speed and be unable to accelerate
        if (impulse.actual < 0)
            cap_speed = impulse.max_speed_reverse;

        auto request = std::clamp(impulse.request, -1.0f, 1.0f);
        if (warp_drive && (warp_drive->request > 0 || warp_drive->current > 0))
            request = 0.0f;
        if (impulse.actual < request)
        {
            if (cap_speed > 0.0f)
                impulse.actual += delta * (impulse.acceleration_forward / cap_speed);
            if (impulse.actual > request)
                impulse.actual = request;
        }
        else if (impulse.actual > request)
        {
            if (cap_speed > 0.0f)
                impulse.actual -= delta * (impulse.acceleration_reverse / cap_speed);
            if (impulse.actual < request)
                impulse.actual = request;
        }

        // Determine forward direction and velocity.
        physics.setVelocity(vec2FromAngle(transform.getRotation()) * (impulse.actual * cap_speed * impulse.getSystemEffectiveness()));
    }
}
