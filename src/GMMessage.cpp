#include "GMMessage.h"
#include "gameGlobalInfo.h"

GMMessage::GMMessage(string text)
: text(text)
{
}

static int addGMMessage(lua_State* L)
{
    string text = luaL_checkstring(L, 1);

    gameGlobalInfo->gm_messages.emplace_back(text);

    return 0;
}

/// void addGMMessage(string message)
/// Displays a message on the GM console.
REGISTER_SCRIPT_FUNCTION(addGMMessage);
