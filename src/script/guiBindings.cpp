#include "guiBindings.h"
#include "script/environment.h"
#include "script.h"
#include "crewPosition.h"
#include <memory>

#include "gui/colorConfig.h"
#include "gui/gui2_element.h"
#include "gui/gui2_overlay.h"
#include "gui/gui2_overlay.h"
#include "gui/gui2_label.h"
#include "gui/gui2_slider.h"
#include "gui/gui2_button.h"
#include "gui/gui2_image.h"

#include "menus/luaConsole.h"

#include "screenComponents/combatManeuver.h"
#include "screenComponents/radarView.h"
#include "screenComponents/customShipFunctions.h"
#include "screenComponents/alertOverlay.h"
#include "screenComponents/infoDisplay.h"
#include "screenComponents/dockingButton.h"
#include "screenComponents/impulseControls.h"
#include "screenComponents/warpControls.h"
#include "screenComponents/jumpControls.h"

#include "components/collision.h"

using namespace sp::script;

static const char* GUI_ELEMENT_METATABLE = "GuiElement";
static lua_State* stored_lua_state = nullptr;
static sp::script::Environment* stored_environment = nullptr;
static std::unique_ptr<sp::script::Environment> client_gui_environment = nullptr;

// Print GUI binding errors to EE log.
static void handleLuaError(lua_State* L, const char* context)
{
    string error = lua_tostring(L, -1);
    string full_error = string("Lua GUI error in ") + context + ": " + error;
    LOG(Error, "%s", full_error.c_str());
    LuaConsole::addLog(full_error);
    lua_pop(L, 1);
}

// Transform userdata to GuiContainer
GuiContainer* getContainerFromLua(lua_State* L, int idx)
{
    if (lua_isuserdata(L, idx))
        return static_cast<GuiContainer*>(lua_touserdata(L, idx));

    return nullptr;
}

// Just push as light userdata without metatable, because all light userdata
// shares the same metatable in Lua, including entities :(
void pushGuiElementToLua(lua_State* L, GuiElement* el)
{
    lua_pushlightuserdata(L, el);
}

// Lua equivalents of C++ GuiElement member functions.
// All take the Lua object of the element being modified as the first argument.
// Example:
// guiSetSize(element, w, h) is equivalent to element->setSize(w, h)
static int guiElement_setSize(lua_State* L)
{
    GuiElement* el = static_cast<GuiElement*>(lua_touserdata(L, 1));
    float w = luaL_checknumber(L, 2);
    float h = luaL_checknumber(L, 3);
    el->setSize(w, h);
    lua_pushlightuserdata(L, el);
    return 1;
}

// guiSetPosition(element, x, y, alignment) is equivalent to element->setPosition(x, y, alignment)
// Alignment.TopLeft is equivalent to sp::Alignment::TopLeft
// See pushAlignmentEnum()
static int guiElement_setPosition(lua_State* L)
{
    GuiElement* el = static_cast<GuiElement*>(lua_touserdata(L, 1));
    float x = luaL_checknumber(L, 2);
    float y = luaL_checknumber(L, 3);
    int align = luaL_optinteger(L, 4, static_cast<int>(sp::Alignment::TopLeft));
    el->setPosition(glm::vec2(x, y), static_cast<sp::Alignment>(align));
    lua_pushlightuserdata(L, el);
    return 1;
}

// guiSetVisible(element, is_visible) is equivalent to element->setVisible(is_visible)
static int guiElement_setVisible(lua_State* L)
{
    GuiElement* el = static_cast<GuiElement*>(lua_touserdata(L, 1));
    bool visible = lua_toboolean(L, 2);
    el->setVisible(visible);
    lua_pushlightuserdata(L, el);
    return 1;
}

// guiSetAttribute(element, attribute_key, attribute_value) is equivalent to element->setAttribute(attribute_key, attribute_value)
static int guiElement_setAttribute(lua_State* L)
{
    GuiElement* el = static_cast<GuiElement*>(lua_touserdata(L, 1));
    string key = luaL_checkstring(L, 2);
    string value = luaL_checkstring(L, 3);
    el->setAttribute(key, value);
    lua_pushlightuserdata(L, el);
    return 1;
}

// guiSetMargins(element, margins) is equivalent to element->setMargins(margins)
// TODO: Handle left-right/top-down as 2 to 4 separate arguments.
// For now, use setAttribute("margin", "...").
static int guiElement_setMargins(lua_State* L)
{
    GuiElement* el = static_cast<GuiElement*>(lua_touserdata(L, 1));
    float m = luaL_checknumber(L, 2);
    el->setMargins(m);
    lua_pushlightuserdata(L, el);
    return 1;
}

// Destroy the passed GuiElement.
static int guiElement_destroy(lua_State* L)
{
    GuiElement* el = static_cast<GuiElement*>(lua_touserdata(L, 1));
    el->destroy();
    return 0;
}

// Lua equivalents of C++ GuiLabel member functions.
// guiSetText(element, text) is equivalent to label->setText(text)
static int guiLabel_setText(lua_State* L)
{
    GuiLabel* label = static_cast<GuiLabel*>(lua_touserdata(L, 1));
    if (!label) return luaL_error(L, "Invalid label element");
    string text = luaL_checkstring(L, 2);
    label->setText(text);
    lua_pushlightuserdata(L, label);
    return 1;
}

// guiSetAlignment(element, alignment) is equivalent to label->setAlignment(alignment)
// Sets text alignment, not entity positioning.
static int guiLabel_setAlignment(lua_State* L)
{
    GuiLabel* label = static_cast<GuiLabel*>(lua_touserdata(L, 1));
    if (!label) return luaL_error(L, "Invalid label element");
    int alignment = luaL_checkinteger(L, 2);
    label->setAlignment(static_cast<sp::Alignment>(alignment));
    lua_pushlightuserdata(L, label);
    return 1;
}

// guiAddBackground(element) is equivalent to label->addBackground()
static int guiElement_addBackground(lua_State* L)
{
    GuiLabel* el = static_cast<GuiLabel*>(lua_touserdata(L, 1));
    el->addBackground();
    lua_pushlightuserdata(L, el);
    return 1;
}

// createOverlay(parent_container, id, {r, g, b, a}) is equivalent to new GuiContainer(...))
// Example:
// local crosses = createOverlay(self.container, "BACKGROUND_CROSSES", {r=255, g=255, b=255, a=255})
static int createOverlay(lua_State* L)
{
    GuiContainer* parent = getContainerFromLua(L, 1);
    if (!parent) return luaL_error(L, "Invalid container");
    
    string id = luaL_checkstring(L, 2);
    
    glm::u8vec4 color{0, 0, 0, 255};
    if (lua_istable(L, 3))
    {
        lua_getfield(L, 3, "r");
        color.r = luaL_optinteger(L, -1, 0);
        lua_pop(L, 1);
        
        lua_getfield(L, 3, "g");
        color.g = luaL_optinteger(L, -1, 0);
        lua_pop(L, 1);
        
        lua_getfield(L, 3, "b");
        color.b = luaL_optinteger(L, -1, 0);
        lua_pop(L, 1);
        
        lua_getfield(L, 3, "a");
        color.a = luaL_optinteger(L, -1, 255);
        lua_pop(L, 1);
    }
    
    GuiOverlay* overlay = new GuiOverlay(parent, id, color);
    pushGuiElementToLua(L, overlay);
    return 1;
}

// createLabel(parent_container, id, text, size) is equivalent to new GuiLabel(...)
static int createLabel(lua_State* L)
{
    GuiContainer* parent = getContainerFromLua(L, 1);
    if (!parent) return luaL_error(L, "Invalid container");
    
    string id = luaL_checkstring(L, 2);
    string text = luaL_checkstring(L, 3);
    float size = luaL_checknumber(L, 4);
    
    GuiLabel* label = new GuiLabel(parent, id, text, size);
    pushGuiElementToLua(L, label);
    return 1;
}

// createSlider(parent_container, id, min, max, initial, callback) is equivalent to new GuiSlider(...)
static int createSlider(lua_State* L)
{
    GuiContainer* parent = getContainerFromLua(L, 1);
    if (!parent) return luaL_error(L, "Invalid container");
    
    string id = luaL_checkstring(L, 2);
    float min = luaL_checknumber(L, 3);
    float max = luaL_checknumber(L, 4);
    float initial = luaL_checknumber(L, 5);
    
    int callback_ref = LUA_NOREF;
    if (lua_isfunction(L, 6))
    {
        lua_pushvalue(L, 6);
        callback_ref = luaL_ref(L, LUA_REGISTRYINDEX);
    }
    
    GuiSlider* slider = new GuiSlider(parent, id, min, max, initial, [L, callback_ref, id](float value) {
        if (callback_ref == LUA_NOREF) return;
        lua_rawgeti(L, LUA_REGISTRYINDEX, callback_ref);
        lua_pushnumber(L, value);
        if (lua_pcall(L, 1, 0, 0) != LUA_OK)
        {
            handleLuaError(L, (string("slider '") + id + "' callback").c_str());
        }
    });
    pushGuiElementToLua(L, slider);
    return 1;
}

// createButton(parent_container, id, text, callback) is equivalent to new GuiButton(...)
static int createButton(lua_State* L)
{
    GuiContainer* parent = getContainerFromLua(L, 1);
    if (!parent) return luaL_error(L, "Invalid container");
    
    string id = luaL_checkstring(L, 2);
    string text = luaL_checkstring(L, 3);
    
    int callback_ref = LUA_NOREF;
    if (lua_isfunction(L, 4))
    {
        lua_pushvalue(L, 4);
        callback_ref = luaL_ref(L, LUA_REGISTRYINDEX);
    }
    
    GuiButton* button = new GuiButton(parent, id, text, [L, callback_ref, id]() {
        if (callback_ref == LUA_NOREF) return;
        lua_rawgeti(L, LUA_REGISTRYINDEX, callback_ref);
        if (lua_pcall(L, 0, 0, 0) != LUA_OK)
        {
            handleLuaError(L, (string("button '") + id + "' callback").c_str());
        }
    });
    pushGuiElementToLua(L, button);
    return 1;
}

// createImage(parent_container, id, texture) is equivalent to new GuiImage(...)
static int createImage(lua_State* L)
{
    GuiContainer* parent = getContainerFromLua(L, 1);
    if (!parent) return luaL_error(L, "Invalid container");
    
    string id = luaL_checkstring(L, 2);
    string texture = luaL_checkstring(L, 3);
    
    GuiImage* image = new GuiImage(parent, id, texture);
    pushGuiElementToLua(L, image);
    return 1;
}

// createCombatManeuver(parent_container, id) is equivalent to new GuiCombatManeuver(...)
static int createCombatManeuver(lua_State* L)
{
    GuiContainer* parent = getContainerFromLua(L, 1);
    if (!parent) return luaL_error(L, "Invalid container");
    
    string id = luaL_checkstring(L, 2);
    
    GuiCombatManeuver* cm = new GuiCombatManeuver(parent, id);
    pushGuiElementToLua(L, cm);
    return 1;
}

// createRadar(parent_container, id)
// TODO: Helms-only behavior; handle changing default behaviors
static int createRadar(lua_State* L)
{
    GuiContainer* parent = getContainerFromLua(L, 1);
    if (!parent) return luaL_error(L, "Invalid container");

    string id = luaL_checkstring(L, 2);

    GuiRadarView* radar = new GuiRadarView(parent, id, nullptr);

    // Apply default Helms radar configuration
    radar->setRangeIndicatorStepSize(1000.0f)
          ->shortRange()
          ->enableGhostDots()
          ->enableWaypoints()
          ->enableCallsigns()
          ->enableHeadingIndicators()
          ->setStyle(GuiRadarView::Circular);
    radar->enableMissileTubeIndicators();

    pushGuiElementToLua(L, radar);
    return 1;
}

// Set callbacks on specified radar, as onClick, onDrag, onRelease.
static int __radarSetCallbacks(lua_State* L)
{
    GuiRadarView* radar = static_cast<GuiRadarView*>(lua_touserdata(L, 1));
    if (!radar) return luaL_error(L, "Invalid radar element");

    // Store references to the Lua callback functions in the registry
    int onClick_ref = LUA_NOREF;
    int onDrag_ref = LUA_NOREF;
    int onRelease_ref = LUA_NOREF;

    if (lua_isfunction(L, 2))
    {
        lua_pushvalue(L, 2);
        onClick_ref = luaL_ref(L, LUA_REGISTRYINDEX);
    }

    if (lua_isfunction(L, 3))
    {
        lua_pushvalue(L, 3);
        onDrag_ref = luaL_ref(L, LUA_REGISTRYINDEX);
    }

    if (lua_isfunction(L, 4))
    {
        lua_pushvalue(L, 4);
        onRelease_ref = luaL_ref(L, LUA_REGISTRYINDEX);
    }

    radar->setCallbacks(
        [L, onClick_ref](sp::io::Pointer::Button button, glm::vec2 position) {
            if (onClick_ref != LUA_NOREF)
            {
                lua_rawgeti(L, LUA_REGISTRYINDEX, onClick_ref);
                lua_pushnumber(L, position.x);
                lua_pushnumber(L, position.y);
                if (lua_pcall(L, 2, 0, 0) != LUA_OK)
                {
                    handleLuaError(L, "radar onClick callback");
                }
            }
        },
        [L, onDrag_ref](glm::vec2 position) {
            if (onDrag_ref != LUA_NOREF)
            {
                lua_rawgeti(L, LUA_REGISTRYINDEX, onDrag_ref);
                lua_pushnumber(L, position.x);
                lua_pushnumber(L, position.y);
                if (lua_pcall(L, 2, 0, 0) != LUA_OK)
                {
                    handleLuaError(L, "radar onDrag callback");
                }
            }
        },
        [L, onRelease_ref](glm::vec2 position) {
            if (onRelease_ref != LUA_NOREF)
            {
                lua_rawgeti(L, LUA_REGISTRYINDEX, onRelease_ref);
                lua_pushnumber(L, position.x);
                lua_pushnumber(L, position.y);
                if (lua_pcall(L, 2, 0, 0) != LUA_OK)
                {
                    handleLuaError(L, "radar onRelease callback");
                }
            }
        }
    );

    return 0;
}

// Attempt to convert radar world coordinates to screen coordinates.
static int radarWorldToScreen(lua_State* L)
{
    GuiRadarView* radar = static_cast<GuiRadarView*>(lua_touserdata(L, 1));
    if (!radar) return luaL_error(L, "Invalid radar element");

    float world_x = luaL_checknumber(L, 2);
    float world_y = luaL_checknumber(L, 3);
    glm::vec2 position(world_x, world_y);

    // Replicate the exact C++ helms screen calculation for heading hint positioning
    auto rect = radar->getRect();

    // Use radar's view position instead of ship position
    // The radar might not be centered on the ship!
    glm::vec2 view_position = radar->getViewPosition();

    // Calculate position relative to radar's view center
    glm::vec2 position_from_center = position - view_position;
    glm::vec2 draw_position;

    bool auto_rotating = radar->getAutoRotating();
    float view_rotation = radar->getViewRotation();

    if (auto_rotating)
    {
        auto rotation = -view_rotation;
        draw_position.x = position_from_center.x * cosf(glm::radians(rotation)) - position_from_center.y * sinf(glm::radians(rotation));
        draw_position.y = position_from_center.x * sinf(glm::radians(rotation)) + position_from_center.y * cosf(glm::radians(rotation));
    }
    else
    {
        draw_position = position_from_center;
    }

    float distance = radar->getDistance();
    float scale = std::min(rect.size.x, rect.size.y) * 0.5f / distance;
    glm::vec2 scaled_pos = draw_position * scale;
    glm::vec2 screen_pos = rect.center() + scaled_pos;

    lua_pushnumber(L, screen_pos.x);
    lua_pushnumber(L, screen_pos.y);
    return 2;
}

// Handle GuiCustomShipFunctions for backward compatibility.
static int createCustomShipFunctions(lua_State* L)
{
    GuiContainer* parent = getContainerFromLua(L, 1);
    if (!parent) return luaL_error(L, "Invalid container");
    
    string position = luaL_checkstring(L, 2);
    string name = luaL_optstring(L, 3, "");
    
    auto cp_opt = tryParseCrewPosition(position);
    CrewPosition cp = cp_opt.value_or(CrewPosition::MAX);
    GuiCustomShipFunctions* custom = new GuiCustomShipFunctions(parent, cp, name);
    pushGuiElementToLua(L, custom);
    return 1;
}

// AlertLevelOverlay equivalent
static int createAlertLevelOverlay(lua_State* L)
{
    GuiContainer* parent = getContainerFromLua(L, 1);
    if (!parent) return luaL_error(L, "Invalid container");
    
    AlertLevelOverlay* overlay = new AlertLevelOverlay(parent);
    pushGuiElementToLua(L, overlay);
    return 1;
}

static int createKeyValueDisplay(lua_State* L)
{
    GuiContainer* parent = getContainerFromLua(L, 1);
    if (!parent) return luaL_error(L, "Invalid container");

    string id = luaL_checkstring(L, 2);
    float scale = luaL_checknumber(L, 3);
    string key = luaL_checkstring(L, 4);
    string value = luaL_optstring(L, 5, "");

    GuiKeyValueDisplay* display = new GuiKeyValueDisplay(parent, id, scale, key, value);
    pushGuiElementToLua(L, display);
    return 1;
}

static int createEnergyDisplay(lua_State* L)
{
    GuiContainer* parent = getContainerFromLua(L, 1);
    if (!parent) return luaL_error(L, "Invalid container");

    string id = luaL_checkstring(L, 2);
    float scale = luaL_checknumber(L, 3);

    EnergyInfoDisplay* display = new EnergyInfoDisplay(parent, id, scale);
    pushGuiElementToLua(L, display);
    return 1;
}

static int createHeadingDisplay(lua_State* L)
{
    GuiContainer* parent = getContainerFromLua(L, 1);
    if (!parent) return luaL_error(L, "Invalid container");

    string id = luaL_checkstring(L, 2);
    float scale = luaL_checknumber(L, 3);

    HeadingInfoDisplay* display = new HeadingInfoDisplay(parent, id, scale);
    pushGuiElementToLua(L, display);
    return 1;
}

static int createVelocityDisplay(lua_State* L)
{
    GuiContainer* parent = getContainerFromLua(L, 1);
    if (!parent) return luaL_error(L, "Invalid container");

    string id = luaL_checkstring(L, 2);
    float scale = luaL_checknumber(L, 3);

    VelocityInfoDisplay* display = new VelocityInfoDisplay(parent, id, scale);
    pushGuiElementToLua(L, display);
    return 1;
}

static int createDockingButton(lua_State* L)
{
    GuiContainer* parent = getContainerFromLua(L, 1);
    if (!parent) return luaL_error(L, "Invalid container");

    string id = luaL_checkstring(L, 2);

    GuiDockingButton* button = new GuiDockingButton(parent, id);
    pushGuiElementToLua(L, button);
    return 1;
}

static int createImpulseControls(lua_State* L)
{
    GuiContainer* parent = getContainerFromLua(L, 1);
    if (!parent) return luaL_error(L, "Invalid container");

    string id = luaL_checkstring(L, 2);

    GuiImpulseControls* controls = new GuiImpulseControls(parent, id);
    pushGuiElementToLua(L, controls);
    return 1;
}

static int createWarpControls(lua_State* L)
{
    GuiContainer* parent = getContainerFromLua(L, 1);
    if (!parent) return luaL_error(L, "Invalid container");

    string id = luaL_checkstring(L, 2);

    GuiWarpControls* controls = new GuiWarpControls(parent, id);
    pushGuiElementToLua(L, controls);
    return 1;
}

static int createJumpControls(lua_State* L)
{
    GuiContainer* parent = getContainerFromLua(L, 1);
    if (!parent) return luaL_error(L, "Invalid container");

    string id = luaL_checkstring(L, 2);

    GuiJumpControls* controls = new GuiJumpControls(parent, id);
    pushGuiElementToLua(L, controls);
    return 1;
}

static int pushAlignmentEnum(lua_State* L)
{
    lua_newtable(L);
    
    lua_pushinteger(L, static_cast<int>(sp::Alignment::TopLeft));
    lua_setfield(L, -2, "TopLeft");
    
    lua_pushinteger(L, static_cast<int>(sp::Alignment::TopCenter));
    lua_setfield(L, -2, "TopCenter");
    
    lua_pushinteger(L, static_cast<int>(sp::Alignment::TopRight));
    lua_setfield(L, -2, "TopRight");
    
    lua_pushinteger(L, static_cast<int>(sp::Alignment::CenterLeft));
    lua_setfield(L, -2, "CenterLeft");
    
    lua_pushinteger(L, static_cast<int>(sp::Alignment::Center));
    lua_setfield(L, -2, "Center");
    
    lua_pushinteger(L, static_cast<int>(sp::Alignment::CenterRight));
    lua_setfield(L, -2, "CenterRight");
    
    lua_pushinteger(L, static_cast<int>(sp::Alignment::BottomLeft));
    lua_setfield(L, -2, "BottomLeft");
    
    lua_pushinteger(L, static_cast<int>(sp::Alignment::BottomCenter));
    lua_setfield(L, -2, "BottomCenter");
    
    lua_pushinteger(L, static_cast<int>(sp::Alignment::BottomRight));
    lua_setfield(L, -2, "BottomRight");
    
    return 1;
}

static int pushSizeConstants(lua_State* L)
{
    lua_newtable(L);
    
    lua_pushnumber(L, GuiElement::GuiSizeMax);
    lua_setfield(L, -2, "SizeMax");
    
    lua_pushnumber(L, GuiElement::GuiSizeMatchHeight);
    lua_setfield(L, -2, "SizeMatchHeight");
    
    lua_pushnumber(L, GuiElement::GuiSizeMatchWidth);
    lua_setfield(L, -2, "SizeMatchWidth");
    
    return 1;
}

static int createElement(lua_State* L)
{
    GuiContainer* parent = getContainerFromLua(L, 1);
    if (!parent) return luaL_error(L, "Invalid container");
    
    string id = luaL_checkstring(L, 2);
    
    GuiElement* el = new GuiElement(parent, id);
    pushGuiElementToLua(L, el);
    return 1;
}

static void setupGuiElementMetatable(lua_State* L)
{
    luaL_newmetatable(L, GUI_ELEMENT_METATABLE);

    lua_pushstring(L, "__index");
    lua_newtable(L);

    lua_pushcfunction(L, guiElement_setSize);
    lua_setfield(L, -2, "setSize");

    lua_pushcfunction(L, guiElement_setPosition);
    lua_setfield(L, -2, "setPosition");

    lua_pushcfunction(L, guiElement_setVisible);
    lua_setfield(L, -2, "setVisible");

    lua_pushcfunction(L, guiElement_setAttribute);
    lua_setfield(L, -2, "setAttribute");

    lua_pushcfunction(L, guiElement_setMargins);
    lua_setfield(L, -2, "setMargins");

    lua_pushcfunction(L, guiElement_destroy);
    lua_setfield(L, -2, "destroy");

    lua_pushcfunction(L, guiElement_addBackground);
    lua_setfield(L, -2, "addBackground");

    lua_settable(L, -3);

    lua_pop(L, 1);
}

static int initializeGuiBindings(lua_State* L)
{
    stored_lua_state = L;
    setupGuiElementMetatable(L);

    // Get the environment table (passed as upvalue)
    lua_pushvalue(L, lua_upvalueindex(1));
    int env_idx = lua_gettop(L);

    // Register Alignment enum
    pushAlignmentEnum(L);
    lua_setfield(L, env_idx, "Alignment");

    // Register GuiSize constants
    pushSizeConstants(L);
    lua_setfield(L, env_idx, "GuiSize");

    // Register all create functions in the environment table
    lua_pushcfunction(L, createOverlay);
    lua_setfield(L, env_idx, "createOverlay");

    lua_pushcfunction(L, createLabel);
    lua_setfield(L, env_idx, "createLabel");

    lua_pushcfunction(L, createSlider);
    lua_setfield(L, env_idx, "createSlider");

    lua_pushcfunction(L, createButton);
    lua_setfield(L, env_idx, "createButton");

    lua_pushcfunction(L, createImage);
    lua_setfield(L, env_idx, "createImage");

    lua_pushcfunction(L, createCombatManeuver);
    lua_setfield(L, env_idx, "createCombatManeuver");

    lua_pushcfunction(L, createRadar);
    lua_setfield(L, env_idx, "createRadar");

    lua_pushcfunction(L, createCustomShipFunctions);
    lua_setfield(L, env_idx, "createCustomShipFunctions");

    lua_pushcfunction(L, createAlertLevelOverlay);
    lua_setfield(L, env_idx, "createAlertLevelOverlay");

    lua_pushcfunction(L, createKeyValueDisplay);
    lua_setfield(L, env_idx, "createKeyValueDisplay");

    lua_pushcfunction(L, createEnergyDisplay);
    lua_setfield(L, env_idx, "createEnergyDisplay");

    lua_pushcfunction(L, createHeadingDisplay);
    lua_setfield(L, env_idx, "createHeadingDisplay");

    lua_pushcfunction(L, createVelocityDisplay);
    lua_setfield(L, env_idx, "createVelocityDisplay");

    lua_pushcfunction(L, createDockingButton);
    lua_setfield(L, env_idx, "createDockingButton");

    lua_pushcfunction(L, createImpulseControls);
    lua_setfield(L, env_idx, "createImpulseControls");

    lua_pushcfunction(L, createWarpControls);
    lua_setfield(L, env_idx, "createWarpControls");

    lua_pushcfunction(L, createJumpControls);
    lua_setfield(L, env_idx, "createJumpControls");

    lua_pushcfunction(L, createElement);
    lua_setfield(L, env_idx, "createElement");

    // Register element manipulation functions (with __ prefix for internal use)
    lua_pushcfunction(L, guiElement_setSize);
    lua_setfield(L, env_idx, "__guiSetSize");

    lua_pushcfunction(L, guiElement_setPosition);
    lua_setfield(L, env_idx, "__guiSetPosition");

    lua_pushcfunction(L, guiElement_setVisible);
    lua_setfield(L, env_idx, "__guiSetVisible");

    lua_pushcfunction(L, guiElement_setMargins);
    lua_setfield(L, env_idx, "__guiSetMargins");

    lua_pushcfunction(L, guiElement_destroy);
    lua_setfield(L, env_idx, "__guiDestroy");

    lua_pushcfunction(L, guiElement_setAttribute);
    lua_setfield(L, env_idx, "__guiSetAttribute");

    lua_pushcfunction(L, __radarSetCallbacks);
    lua_setfield(L, env_idx, "__radarSetCallbacks");

    lua_pushcfunction(L, radarWorldToScreen);
    lua_setfield(L, env_idx, "__radarWorldToScreen");

    lua_pushcfunction(L, guiLabel_setText);
    lua_setfield(L, env_idx, "__guiSetText");

    lua_pushcfunction(L, guiLabel_setAlignment);
    lua_setfield(L, env_idx, "__guiSetLabelAlignment");

    lua_pop(L, 1); // Pop environment table

    return 0;
}

void registerGuiBindings(sp::script::Environment& env)
{
    stored_environment = &env;
    env.setGlobalFuncWithEnvUpvalue("__initializeGuiBindings", &initializeGuiBindings);
    auto res = env.run<void>("__initializeGuiBindings()");
    if (res.isErr())
    {
        LOG(Error, "Failed to initialize GUI bindings:");
        LOG(Error, "%s", res.error().c_str());
    }
}

lua_State* getGuiLuaState()
{
    return stored_lua_state;
}

GuiElement* createLuaHelmsScreenFromEnvironment(GuiContainer* container)
{
    // If no environment exists (client-only mode), create a minimal GUI-only environment
    if (!stored_environment)
    {
        if (!client_gui_environment)
        {
            LOG(Info, "Creating client-side GUI environment");
            client_gui_environment = std::make_unique<sp::script::Environment>();

            // Set up require() function for loading Lua modules
            setupSubEnvironment(*client_gui_environment);

            // Register GUI bindings
            registerGuiBindings(*client_gui_environment);

            // Load the GUI API wrapper
            auto api_result = client_gui_environment->runFile<void>("api/gui.lua");
            if (api_result.isErr())
            {
                LOG(Error, "Failed to load GUI API on client:");
                LOG(Error, "%s", api_result.error().c_str());
                client_gui_environment = nullptr;
                return nullptr;
            }
        }
        stored_environment = client_gui_environment.get();
    }

    // Create a GuiOverlay as the base container for the Lua screen
    GuiOverlay* screen_container = new GuiOverlay(container, "HELMS_SCREEN", colorConfig.background);

    // Load the Helms screen Lua module using the environment
    auto load_result = stored_environment->run<void>(R"(
        helmsScreenModule = require("screens/helmsScreen.lua")
    )");

    if (load_result.isErr())
    {
        LOG(Error, "Failed to load Helms screen Lua module:");
        LOG(Error, "%s", load_result.error().c_str());
        LuaConsole::addLog("Failed to load Helms screen: " + load_result.error());
        delete screen_container;
        return nullptr;
    }

    // Initialize the Lua screen with the container
    // We need to call helmsScreenModule:init(container)
    lua_State* L = stored_lua_state;
    int stack_top = lua_gettop(L);

    // Get the environment table
    lua_rawgetp(L, LUA_REGISTRYINDEX, stored_environment);

    // Get helmsScreenModule from environment
    lua_getfield(L, -1, "helmsScreenModule");
    if (!lua_istable(L, -1))
    {
        LOG(Error, "helmsScreenModule is not a table");
        lua_settop(L, stack_top);
        delete screen_container;
        return nullptr;
    }

    // Get the init method
    lua_getfield(L, -1, "init");
    if (!lua_isfunction(L, -1))
    {
        LOG(Error, "helmsScreenModule.init is not a function");
        lua_settop(L, stack_top);
        delete screen_container;
        return nullptr;
    }

    // Call helmsScreenModule:init(container)
    lua_pushvalue(L, -2); // Push the module table (self)
    lua_pushlightuserdata(L, screen_container);

    if (lua_pcall(L, 2, 0, 0) != LUA_OK)
    {
        string error = lua_tostring(L, -1);
        LOG(Error, "Failed to initialize Helms screen:");
        LOG(Error, "%s", error.c_str());
        LuaConsole::addLog("Failed to initialize Helms screen: " + error);
        lua_settop(L, stack_top);
        delete screen_container;
        return nullptr;
    }

    lua_settop(L, stack_top);
    LOG(Info, "Lua Helms screen loaded successfully");
    return screen_container;
}
