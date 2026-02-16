#pragma once

#include "script/environment.h"
#include <lua/lua.hpp>

class GuiContainer;
class GuiElement;

void registerGuiBindings(sp::script::Environment& env);
lua_State* getGuiLuaState();
GuiElement* createLuaHelmsScreenFromEnvironment(GuiContainer* container);
