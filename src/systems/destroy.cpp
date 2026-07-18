#include <systems/destroy.h>
#include <components/destroy.h>
#include "menus/luaConsole.h"

void OnDestroySystem::destroyCallback(sp::ecs::Entity e)
{
    if (e.hasComponent<Destroyed>()) return;

    auto od = e.getComponent<OnDestroyed>();
    if (od && od->callback)
    {
        // Prevent recursive calls
        e.addComponent<Destroyed>();
        LuaConsole::checkResult(od->callback.call<void>(e));
    }
}
