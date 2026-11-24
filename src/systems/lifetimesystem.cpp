#include "systems/lifetimesystem.h"

#include "components/lifetime.h"
#include "components/missile.h"
#include "ecs/query.h"
#include "menus/luaConsole.h"
#include "multiplayer_server.h"
#include "systems/missilesystem.h"

void LifeTimeSystem::update(float delta)
{
    if (!game_server.isAlive())
        return;

    for (auto [entity, lifetime] : sp::ecs::Query<LifeTime>())
    {
        lifetime.alive_for += delta;

        if (lifetime.alive_for < lifetime.maximum)
            continue;

        if (lifetime.on_expire)
            LuaConsole::checkResult(lifetime.on_expire.call<void>(entity));

        // The callback might've destroyed the entity.
        if (!entity) continue;

        if (entity.hasComponent<ExplodeOnTimeout>())
        {
            if (auto eot = entity.getComponent<ExplodeOnTouch>())
                MissileSystem::explode(entity, {}, *eot);
        }

        entity.destroy();
    }
}
