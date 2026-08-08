#include "script.h"
#include <i18n.h>
#include "gameGlobalInfo.h"
#include "soundManager.h"
#include "preferenceManager.h"
#include "resources.h"
#include "random.h"
#include "config.h"
#include "ecs/query.h"
#include "playerInfo.h"
#include "io/json.h"
#include "audio/sound.h"
#include "math/centerOfMass.h"

#include "script/component.h"
#include "script/crewPosition.h"
#include "script/damageInfo.h"
#include "script/dataStorage.h"
#include "script/enum.h"
#include "script/gm.h"
#include "script/scriptRandom.h"
#include "script/vector.h"

#include "components/beamweapon.h"
#include "components/briefing.h"
#include "components/collision.h"
#include "components/coolant.h"
#include "components/drone.h"
#include "components/faction.h"
#include "components/impulse.h"
#include "components/internalrooms.h"
#include "components/maneuveringthrusters.h"
#include "components/radar.h"
#include "components/selfdestruct.h"
#include "components/shields.h"
#include "components/shiplog.h"
#include "components/target.h"
#include "components/utilityBeam.h"
#include "components/mounts.h"
#include "components/warpdrive.h"
#include "components/zone.h"

#include "systems/collision.h"
#include "systems/comms.h"
#include "systems/docking.h"
#include "systems/jumpsystem.h"
#include "systems/missilesystem.h"
#include "components/pickup.h"
#include "systems/probe.h"
#include "systems/radarblock.h"
#include "systems/selfdestruct.h"

#include "menus/luaConsole.h"

/// void require(string filename)
/// Runs the Lua script with the given filename in the same context as the running Script.
/// Loads the localized file if it exists at locale/<FILENAME>.<LANGUAGE>.po.
static int luaRequire(lua_State* L)
{
    bool error = false;
    int old_top = lua_gettop(L);
    string filename = luaL_checkstring(L, 1);

    {
        // Start a new scope to ensure things are properly destroyed before we
        // call lua_error(), as lua_error doesn't properly call destructors.
        P<ResourceStream> stream = getResourceStream(filename);
        if (!stream)
        {
            lua_pushstring(L, ("Require: Script not found: " + filename).c_str());
            error = true;
        }

        if (!error)
        {
            // Load the locale file for this script.
            i18n::load("locale/" + filename.replace(".lua", "." + PreferencesManager::get("language", "en_US") + ".po"));

            string filecontents = stream->readAll();
            stream->destroy();
            stream = nullptr;

            if (luaL_loadbuffer(L, filecontents.c_str(), filecontents.length(), ("@" + filename).c_str()))
            {
                string error_string = luaL_checkstring(L, -1);
                lua_pushstring(L, ("require:" + error_string).c_str());
                error = true;
            }
        }
    }

    if (!error)
    {
        lua_pushvalue(L, lua_upvalueindex(1));
        lua_setupvalue(L, -2, 1);

        // Call the actual code.
        if (lua_pcall(L, 0, LUA_MULTRET, 0))
        {
            string error_string = luaL_checkstring(L, -1);
            lua_pushstring(L, ("require:" + error_string).c_str());
            error = true;
        }
    }

    if (error) return lua_error(L);

    return lua_gettop(L) - old_top;
}

static int luaTranslate(lua_State* L)
{
    if (lua_type(L, 1) == LUA_TNUMBER)
    {
        auto n = static_cast<int>(luaL_checkinteger(L, 1));
        auto str_1 = luaL_checkstring(L, 2);
        auto str_2 = luaL_checkstring(L, 3);
        auto str_3 = luaL_optstring(L, 4, nullptr);

        if (str_3)
            lua_pushstring(L, trn(n, str_1, str_2, str_3).c_str());
        else
            lua_pushstring(L, trn(n, str_1, str_2).c_str());

        return 1;
    }

    auto str_1 = luaL_checkstring(L, 1);
    auto str_2 = luaL_optstring(L, 2, nullptr);

    if (str_2)
        lua_pushstring(L, tr(str_1, str_2).c_str());
    else
        lua_pushstring(L, tr(str_1).c_str());

    return 1;
}

static sp::ecs::Entity luaCreateEntity()
{
    return sp::ecs::Entity::create();
}

// Move an entity into another entity's internal docking bay.
// This succeeds only if the carrier entity supports internal docking with the
// docking entity.
static bool luaMoveEntityToInternalBay(sp::ecs::Entity entity, sp::ecs::Entity carrier)
{
    return DockingSystem::moveEntityToInternalBay(entity, carrier);
}

static int luaQueryEntities(lua_State* L)
{
    auto key = luaL_checkstring(L, 1);
    auto it = sp::script::ComponentRegistry::components.find(key);

    if (it == sp::script::ComponentRegistry::components.end())
        return luaL_error(L, "Tried to query non-existing component %s", key);

    return it->second.query(L);
}

static int luaCreateObjectFunc(lua_State* L)
{
    lua_newtable(L);
    lua_pushvalue(L, lua_upvalueindex(1));
    lua_setmetatable(L, -2);

    lua_getfield(L, -1, "__init__");
    if (lua_isfunction(L, -1))
    {
        lua_pushvalue(L, -2);
        lua_call(L, 1, 0);
    }
    else lua_pop(L, 1);

    return 1;
}

static int luaCreateClass(lua_State* L)
{
    // Create a class. Returns 1 variable, which is a table containing the
    // functions for this class.

    lua_newtable(L); // Table to return
    lua_newtable(L); // Table to use as class table's metatable.
    lua_newtable(L); // Table to use as object table's metatable.
    lua_pushvalue(L, -3);
    lua_setfield(L, -2, "__index");
    lua_pushcclosure(L, luaCreateObjectFunc, 1);
    lua_setfield(L, -2, "__call");
    lua_setmetatable(L, -2);

    return 1;
}

static int luaPrintLog(lua_State* L, bool print)
{
    string message;
    // Number of arguments.
    int n = lua_gettop(L);

    for (int i = 1; i <= n; i++)
    {
        if (lua_istable(L, i))
        {
            if (i > 1) message += " ";

            message += "{";
            lua_pushnil(L);
            bool first = true;

            while (lua_next(L, i))
            {
                if (first) first = false;
                else message += ",";

                auto s = luaL_tolstring(L, -2, nullptr);
                if (s != nullptr) message += string(s) + "=";

                lua_pop(L, 1);
                s = luaL_tolstring(L, -1, nullptr);

                if (s != nullptr) message += s;

                lua_pop(L, 2);
            }

            message += "}";
        }
        else
        {
            auto s = luaL_tolstring(L, i, nullptr);

            if (s != nullptr)
            {
                if (i > 1) message += " ";
                message += s;
            }

            lua_pop(L, 1);
        }
    }

    LOG(Info, "[lua] ", message);

    if (print) LuaConsole::addLog(message);

    return 0;
}

static int luaPrint(lua_State* L)
{
    return luaPrintLog(L, true);
}

static int luaLog(lua_State* L)
{
    return luaPrintLog(L, false);
}

static int luaGetEntityFunctionTable(lua_State* L)
{
    lua_getfield(L, LUA_REGISTRYINDEX, "EFT");
    return 1;
}

static void luaVictory(string faction)
{
    gameGlobalInfo->setVictory(faction);

    if (engine->getObject("scenario"))
        engine->getObject("scenario")->destroy();

    // Pause game on victory.
    engine->setGameSpeed(0.0f);
}

static string luaGetSectorName(float x, float y)
{
    return getSectorName({x, y});
}

static string luaGetScenarioSetting(string key)
{
    if (gameGlobalInfo->scenario_settings.find(key) != gameGlobalInfo->scenario_settings.end())
        return gameGlobalInfo->scenario_settings[key];

    return "";
}

static string luaGetScenarioVariation()
{
    if (gameGlobalInfo->scenario_settings.find("variation") != gameGlobalInfo->scenario_settings.end())
        return gameGlobalInfo->scenario_settings["variation"];

    return "None";
}

static void luaGlobalMessage(string message, std::optional<float> timeout)
{
    gameGlobalInfo->global_message = message;
    gameGlobalInfo->global_message_timeout = timeout.has_value()
        ? timeout.value()
        : 5.0f;
}

static void luaAddGMFunction(string label, sp::script::Callback callback)
{
    gameGlobalInfo->gm_callback_functions.emplace_back(label);
    gameGlobalInfo->gm_callback_functions.back().callback = callback;
}

static void luaClearGMFunctions()
{
    gameGlobalInfo->gm_callback_functions.clear();
}

static int luaCreateAdditionalScript(lua_State* L)
{
    auto env = std::make_unique<sp::script::Environment>(gameGlobalInfo->script_environment_base.get());
    setupSubEnvironment(*env.get());
    auto ptr = reinterpret_cast<sp::script::Environment**>(lua_newuserdata(L, sizeof(sp::script::Environment*)));
    *ptr = env.get();

    luaL_getmetatable(L, "ScriptObject");

    if (lua_isnil(L, -1))
    {
        lua_pop(L, 1);
        luaL_newmetatable(L, "ScriptObject");
        lua_newtable(L);

        lua_pushcfunction(L,
            [](lua_State* LL)
            {
                auto ptr = reinterpret_cast<sp::script::Environment**>(luaL_checkudata(LL, 1, "ScriptObject"));
                if (!ptr) return 0;

                // Load script file.
                string filename = luaL_checkstring(LL, 2);
                // Load script's translation, if any.
                i18n::load("locale/" + filename.replace(".lua", "." + PreferencesManager::get("language", "en_US") + ".po"));

                auto res = (*ptr)->runFile<void>(filename);
                LuaConsole::checkResult(res);
                if (res.isOk())
                {
                    res = (*ptr)->call<void>("init");
                    LuaConsole::checkResult(res);
                }

                return 0;
            }
        );

        lua_setfield(L, -2, "run");
        lua_pushcfunction(L,
            [](lua_State* LL)
            {
                auto ptr = reinterpret_cast<sp::script::Environment**>(luaL_checkudata(LL, 1, "ScriptObject"));
                if (!ptr) return 0;

                string name = luaL_checkstring(LL, 2);
                auto ltype = lua_type(LL, 3);

                // Strings
                if (ltype == LUA_TSTRING)
                {
                    string value = lua_tostring(LL, 3);
                    (*ptr)->setGlobal(name, value);
                }

                // Entities, as light userdata
                else if (ltype == LUA_TLIGHTUSERDATA)
                {
                    sp::ecs::Entity entity = sp::script::Convert<sp::ecs::Entity>::fromLua(LL, 3);
                    if (entity) (*ptr)->setGlobal(name, entity);
                    else return luaL_error(LL, "Userdata was passed to setVariable, but it wasn't an entity");
                }

                // Numbers
                else if (ltype == LUA_TNUMBER)
                {
                    float value = static_cast<float>(lua_tonumber(LL, 3));
                    (*ptr)->setGlobal(name, value);
                }
                else
                    return luaL_error(LL, "setVariable expects a string, float, or entity as the second argument");

                lua_settop(LL, 1);
                return 1;
            }
        );

        lua_setfield(L, -2, "setVariable");
        lua_setfield(L, -2, "__index");
        lua_pushstring(L, "sandboxed");
        lua_setfield(L, -2, "__metatable");
    }

    lua_setmetatable(L, -2);

    gameGlobalInfo->additional_scripts.push_back(std::move(env));

    return 1;
}

static int luaSectorToXY(lua_State* L)
{
    string sector = luaL_checkstring(L, 1);
    constexpr float sector_size = 20000.0f;

    if (sector.length() < 5)
    {
        lua_pushnumber(L, 0);
        lua_pushnumber(L, 0);
        lua_pushboolean(L, false);
        return 3;
    }

    int pos = 0;
    int block_y = 0;

    if (pos < static_cast<int>(sector.length()) && sector[pos] >= 'A' && sector[pos] <= 'M')
    {
        while (pos < static_cast<int>(sector.length()) && sector[pos] >= 'A' && sector[pos] <= 'M')
        {
            block_y = block_y * 13 + (sector[pos] - 'A' + 1);
            pos++;
        }

        block_y = -block_y;
    }
    else if (pos < static_cast<int>(sector.length()) && sector[pos] >= 'N' && sector[pos] <= 'Z')
    {
        while (pos < static_cast<int>(sector.length()) && sector[pos] >= 'N' && sector[pos] <= 'Z')
        {
            block_y = block_y * 13 + (sector[pos] - 'N' + 1);
            pos++;
        }
    }

    if (pos + 2 > static_cast<int>(sector.length()))
    {
        lua_pushnumber(L, 0);
        lua_pushnumber(L, 0);
        lua_pushboolean(L, false);
        return 3;
    }

    string row_str = sector.substr(pos, pos + 2);
    int local_row = row_str.toInt();
    pos += 2;

    if (pos >= static_cast<int>(sector.length()))
    {
        lua_pushnumber(L, 0);
        lua_pushnumber(L, 0);
        lua_pushboolean(L, false);
        return 3;
    }

    int block_x = 0;

    if (sector[pos] == '-')
        pos++;
    else if (sector[pos] >= 'A' && sector[pos] <= 'M')
    {
        while (pos < static_cast<int>(sector.length()) && sector[pos] >= 'A' && sector[pos] <= 'M')
        {
            block_x = block_x * 13 + (sector[pos] - 'A' + 1);
            pos++;
        }

        block_x = -block_x;
    }
    else if (sector[pos] >= 'N' && sector[pos] <= 'Z')
    {
        while (pos < static_cast<int>(sector.length()) && sector[pos] >= 'N' && sector[pos] <= 'Z')
        {
            block_x = block_x * 13 + (sector[pos] - 'N' + 1);
            pos++;
        }
    }
    else
    {
        lua_pushnumber(L, 0);
        lua_pushnumber(L, 0);
        lua_pushboolean(L, false);
        return 3;
    }

    if (pos + 2 > static_cast<int>(sector.length())) {
        lua_pushnumber(L, 0);
        lua_pushnumber(L, 0);
        lua_pushboolean(L, false);
        return 3;
    }

    string col_str = sector.substr(pos, pos + 2);
    int local_col = col_str.toInt();

    int sector_x = block_x * 100 + local_col;
    int sector_y = block_y * 100 + local_row;

    float x = (sector_x - 50.0f) * sector_size;
    float y = (sector_y - 50.0f) * sector_size;

    lua_pushnumber(L, static_cast<lua_Number>(x));
    lua_pushnumber(L, static_cast<lua_Number>(y));
    lua_pushboolean(L, true);

    return 3;
}

static bool luaIsInsideZone(float x, float y, sp::ecs::Entity e)
{
    auto zone = e.getComponent<Zone>();
    if (!zone) return false;

    auto t = e.getComponent<sp::Transform>();
    if (!t) return false;

    return insidePolygon(zone->outline, glm::vec2(x, y) - t->getPosition());
}

static void luaSetBanner(string banner)
{
    gameGlobalInfo->banner_string = banner;
}

static void luaSetDefaultSkybox(string skybox)
{
    gameGlobalInfo->default_skybox = skybox;
}

static float getAudioDuration(const string& filename)
{
    int n = filename.rfind(".");

    if (n > -1)
    {
        // Get localized audio, if any.
        string filename_with_locale = filename.substr(0, n) + "." + PreferencesManager::get("language", "en_US") + filename.substr(n);
        if (getResourceStream(filename_with_locale))
        {
            sp::audio::Sound sound(filename_with_locale);
            return sound.getDuration();
        }
    }

    if (getResourceStream(filename))
    {
        sp::audio::Sound sound(filename);
        return sound.getDuration();
    }

    return 0.0f;
}

static int luaSetBriefingPage(lua_State* L)
{
    auto entity = sp::script::Convert<sp::ecs::Entity>::fromLua(L, 1);
    if (!entity)
        return luaL_error(L, "setBriefingPage() requires a valid entity");

    auto* briefing = entity.getComponent<Briefing>();
    if (!briefing)
        briefing = &entity.getOrAddComponent<Briefing>();

    int index = static_cast<int>(luaL_checkinteger(L, 2));

    int zero_index = index - 1;
    if (zero_index >= static_cast<int>(briefing->pages.size()))
        briefing->pages.resize(zero_index + 1);

    bool audio_set = false;
    bool duration_set = false;

    if (lua_gettop(L) >= 3 && !lua_isnil(L, 3))
        briefing->pages[zero_index].caption = luaL_checkstring(L, 3);

    if (lua_gettop(L) >= 4 && !lua_isnil(L, 4))
        briefing->pages[zero_index].image = luaL_checkstring(L, 4);

    if (lua_gettop(L) >= 5 && !lua_isnil(L, 5))
    {
        briefing->pages[zero_index].audio = luaL_checkstring(L, 5);
        audio_set = true;
    }

    if (lua_gettop(L) >= 6 && !lua_isnil(L, 6))
    {
        briefing->pages[zero_index].duration = static_cast<float>(luaL_checknumber(L, 6));
        duration_set = true;
    }

    if (audio_set && !duration_set)
    {
        float duration = getAudioDuration(briefing->pages[zero_index].audio);

        if (duration > 0.0f)
            briefing->pages[zero_index].duration = duration;
        else
            LOG(Warning, "[lua] Invalid briefing audio file: ", briefing->pages[zero_index].audio);
    }

    return 0;
}

static void luaClearBriefing(sp::ecs::Entity entity)
{
    if (!entity) return;

    auto* briefing = entity.getComponent<Briefing>();

    if (briefing) briefing->pages.clear();
}

static void luaRemoveBriefingPage(sp::ecs::Entity entity, int index)
{
    if (!entity || index < 1) return;

    auto* briefing = entity.getComponent<Briefing>();

    if (!briefing) return;

    int zero_index = index - 1;
    if (zero_index < static_cast<int>(briefing->pages.size()))
        briefing->pages.erase(briefing->pages.begin() + zero_index);
}

static int luaSetBriefingMapPage(lua_State* L)
{
    auto entity = sp::script::Convert<sp::ecs::Entity>::fromLua(L, 1);
    if (!entity)
        return luaL_error(L, "setBriefingMapPage() requires a valid entity");

    auto* briefing = entity.getComponent<Briefing>();
    if (!briefing)
        briefing = &entity.getOrAddComponent<Briefing>();

    int index = static_cast<int>(luaL_checkinteger(L, 2));
    if (index < 1)
        return luaL_error(L, "setBriefingMapPage() index must be >= 1");

    int zero_index = index - 1;
    if (zero_index >= static_cast<int>(briefing->pages.size()))
        briefing->pages.resize(zero_index + 1);

    if (lua_gettop(L) >= 3 && !lua_isnil(L, 3))
        briefing->pages[zero_index].map_data.duration = static_cast<float>(luaL_checknumber(L, 3));

    return 0;
}

static int luaAddBriefingMapKeyframe(lua_State* L)
{
    auto entity = sp::script::Convert<sp::ecs::Entity>::fromLua(L, 1);
    if (!entity)
        return luaL_error(L, "addBriefingMapKeyframe() requires a valid entity");

    auto* briefing = entity.getComponent<Briefing>();
    if (!briefing)
        return luaL_error(L, "addBriefingMapKeyframe() requires a briefing component");

    int page_idx = static_cast<int>(luaL_checkinteger(L, 2));
    if (page_idx < 1)
        return luaL_error(L, "addBriefingMapKeyframe() page index must be >= 1");

    int zero_page = page_idx - 1;
    if (zero_page >= static_cast<int>(briefing->pages.size()))
        return luaL_error(L, "addBriefingMapKeyframe() page index out of range");

    int kf_idx = static_cast<int>(luaL_checkinteger(L, 3));
    if (kf_idx < 1)
        return luaL_error(L, "addBriefingMapKeyframe() keyframe index must be >= 1");

    int zero_kf = kf_idx - 1;
    auto& keyframes = briefing->pages[zero_page].map_data.keyframes;
    if (zero_kf >= static_cast<int>(keyframes.size()))
        keyframes.resize(zero_kf + 1);

    if (lua_gettop(L) >= 4 && !lua_isnil(L, 4))
        keyframes[zero_kf].timestamp = static_cast<float>(luaL_checknumber(L, 4));

    if (lua_gettop(L) >= 5 && !lua_isnil(L, 5))
        keyframes[zero_kf].camera_position.x = static_cast<float>(luaL_checknumber(L, 5));

    if (lua_gettop(L) >= 6 && !lua_isnil(L, 6))
        keyframes[zero_kf].camera_position.y = static_cast<float>(luaL_checknumber(L, 6));

    if (lua_gettop(L) >= 7 && !lua_isnil(L, 7))
        keyframes[zero_kf].zoom = static_cast<float>(luaL_checknumber(L, 7));

    return 0;
}

static int luaAddBriefingMapEntity(lua_State* L)
{
    auto entity = sp::script::Convert<sp::ecs::Entity>::fromLua(L, 1);
    if (!entity)
        return luaL_error(L, "addBriefingMapEntity() requires a valid entity");

    auto* briefing = entity.getComponent<Briefing>();
    if (!briefing)
        return luaL_error(L, "addBriefingMapEntity() requires a briefing component");

    int page_idx = static_cast<int>(luaL_checkinteger(L, 2));
    if (page_idx < 1)
        return luaL_error(L, "addBriefingMapEntity() page index must be >= 1");

    int zero_page = page_idx - 1;
    if (zero_page >= static_cast<int>(briefing->pages.size()))
        return luaL_error(L, "addBriefingMapEntity() page index out of range");

    int kf_idx = static_cast<int>(luaL_checkinteger(L, 3));
    if (kf_idx < 1)
        return luaL_error(L, "addBriefingMapEntity() keyframe index must be >= 1");

    int zero_kf = kf_idx - 1;
    auto& keyframes = briefing->pages[zero_page].map_data.keyframes;
    if (zero_kf >= static_cast<int>(keyframes.size()))
        return luaL_error(L, "addBriefingMapEntity() keyframe index out of range");

    BriefingMapEntity ent;

    if (lua_gettop(L) >= 4 && !lua_isnil(L, 4))
        ent.id = static_cast<int32_t>(luaL_checkinteger(L, 4));

    if (lua_gettop(L) >= 5 && !lua_isnil(L, 5))
        ent.position.x = static_cast<float>(luaL_checknumber(L, 5));

    if (lua_gettop(L) >= 6 && !lua_isnil(L, 6))
        ent.position.y = static_cast<float>(luaL_checknumber(L, 6));

    if (lua_gettop(L) >= 7 && !lua_isnil(L, 7))
        ent.rotation = static_cast<float>(luaL_checknumber(L, 7));

    if (lua_gettop(L) >= 8 && !lua_isnil(L, 8))
        ent.world_size = static_cast<float>(luaL_checknumber(L, 8));

    if (lua_gettop(L) >= 9 && !lua_isnil(L, 9))
        ent.radar_trace_image = luaL_checkstring(L, 9);

    if (lua_gettop(L) >= 10 && !lua_isnil(L, 10))
        ent.color.r = static_cast<uint8_t>(luaL_checkinteger(L, 10));

    if (lua_gettop(L) >= 11 && !lua_isnil(L, 11))
        ent.color.g = static_cast<uint8_t>(luaL_checkinteger(L, 11));

    if (lua_gettop(L) >= 12 && !lua_isnil(L, 12))
        ent.color.b = static_cast<uint8_t>(luaL_checkinteger(L, 12));

    if (lua_gettop(L) >= 13 && !lua_isnil(L, 13))
        ent.color.a = static_cast<uint8_t>(luaL_checkinteger(L, 13));

    if (lua_gettop(L) >= 14 && !lua_isnil(L, 14))
        ent.visible = lua_toboolean(L, 14);

    if (lua_gettop(L) >= 15 && !lua_isnil(L, 15))
        ent.label = luaL_checkstring(L, 15);

    keyframes[zero_kf].entities.push_back(ent);

    return 0;
}

static void luaClearBriefingMapPage(sp::ecs::Entity entity, int page_index)
{
    if (!entity || page_index < 1) return;

    auto* briefing = entity.getComponent<Briefing>();
    if (!briefing) return;

    int zero_index = page_index - 1;
    if (zero_index < static_cast<int>(briefing->pages.size()))
        briefing->pages[zero_index].map_data = BriefingMapPage();
}

static BriefingMapEntity* findBriefingMapEntity(lua_State* L, int entity_arg, int page_arg, int kf_arg, int id_arg)
{
    auto entity = sp::script::Convert<sp::ecs::Entity>::fromLua(L, entity_arg);
    if (!entity)
    {
        luaL_error(L, "requires a valid entity");
        return nullptr;
    }

    auto* briefing = entity.getComponent<Briefing>();
    if (!briefing)
    {
        luaL_error(L, "requires a briefing component");
        return nullptr;
    }

    int page_idx = static_cast<int>(luaL_checkinteger(L, page_arg));
    if (page_idx < 1)
    {
        luaL_error(L, "page index must be >= 1");
        return nullptr;
    }

    int zero_page = page_idx - 1;
    if (zero_page >= static_cast<int>(briefing->pages.size()))
    {
        luaL_error(L, "page index out of range");
        return nullptr;
    }

    int kf_idx = static_cast<int>(luaL_checkinteger(L, kf_arg));
    if (kf_idx < 1)
    {
        luaL_error(L, "keyframe index must be >= 1");
        return nullptr;
    }

    int zero_kf = kf_idx - 1;
    auto& keyframes = briefing->pages[zero_page].map_data.keyframes;
    if (zero_kf >= static_cast<int>(keyframes.size()))
    {
        luaL_error(L, "keyframe index out of range");
        return nullptr;
    }

    int32_t ent_id = static_cast<int32_t>(luaL_checkinteger(L, id_arg));

    auto& entities = keyframes[zero_kf].entities;
    for (auto& e : entities)
    {
        if (e.id == ent_id)
            return &e;
    }

    entities.emplace_back();
    auto* target = &entities.back();
    target->id = ent_id;
    return target;
}

static int luaSetBriefingMapEntityPosition(lua_State* L)
{
    auto* target = findBriefingMapEntity(L, 1, 2, 3, 4);
    if (!target) return 0;

    target->position.x = static_cast<float>(luaL_checknumber(L, 5));
    target->position.y = static_cast<float>(luaL_checknumber(L, 6));
    return 0;
}

static int luaSetBriefingMapEntityRotation(lua_State* L)
{
    auto* target = findBriefingMapEntity(L, 1, 2, 3, 4);
    if (!target) return 0;

    target->rotation = static_cast<float>(luaL_checknumber(L, 5));
    return 0;
}

static int luaSetBriefingMapEntitySize(lua_State* L)
{
    auto* target = findBriefingMapEntity(L, 1, 2, 3, 4);
    if (!target) return 0;

    target->world_size = static_cast<float>(luaL_checknumber(L, 5));
    return 0;
}

static int luaSetBriefingMapEntityImage(lua_State* L)
{
    auto* target = findBriefingMapEntity(L, 1, 2, 3, 4);
    if (!target) return 0;

    target->radar_trace_image = luaL_checkstring(L, 5);
    return 0;
}

static int luaSetBriefingMapEntityColor(lua_State* L)
{
    auto* target = findBriefingMapEntity(L, 1, 2, 3, 4);
    if (!target) return 0;

    target->color.r = static_cast<uint8_t>(luaL_checkinteger(L, 5));
    target->color.g = static_cast<uint8_t>(luaL_checkinteger(L, 6));
    target->color.b = static_cast<uint8_t>(luaL_checkinteger(L, 7));
    target->color.a = static_cast<uint8_t>(luaL_checkinteger(L, 8));
    return 0;
}

static int luaSetBriefingMapEntityVisible(lua_State* L)
{
    auto* target = findBriefingMapEntity(L, 1, 2, 3, 4);
    if (!target) return 0;

    target->visible = lua_toboolean(L, 5);
    return 0;
}

static int luaSetBriefingMapEntityLabel(lua_State* L)
{
    auto* target = findBriefingMapEntity(L, 1, 2, 3, 4);
    if (!target) return 0;

    target->label = luaL_checkstring(L, 5);
    return 0;
}

static float luaGetScenarioTime()
{
    return gameGlobalInfo->elapsed_time;
}

static float luaGetWallTime()
{
    return gameGlobalInfo->wall_time.get();
}

static int luaGetAllObjects(lua_State* L)
{
    lua_newtable(L);
    int idx = 1;

    for (auto [e, t] : sp::ecs::Query<sp::Transform>())
    {
        sp::script::Convert<sp::ecs::Entity>::toLua(L, e);
        lua_rawseti(L, -2, idx++);
    }

    return 1;
}

static int luaGetObjectsInRadius(lua_State* L)
{
    float x = static_cast<float>(luaL_checknumber(L, 1));
    float y = static_cast<float>(luaL_checknumber(L, 2));
    float r = static_cast<float>(luaL_checknumber(L, 3));

    glm::vec2 position(x, y);
    lua_newtable(L);
    int idx = 1;

    for (auto entity : sp::TransformQuery::queryArea(position - glm::vec2(r, r), position + glm::vec2(r, r)))
    {
        if (auto entity_transform = entity.getComponent<sp::Transform>())
        {
            if (glm::length2(entity_transform->getPosition() - position) < r * r)
            {
                sp::script::Convert<sp::ecs::Entity>::toLua(L, entity);
                lua_rawseti(L, -2, idx++);
            }
        }
    }

    return 1;
}

static int luaGetEnemiesInRadiusFor(lua_State* L)
{
    lua_newtable(L);
    int idx = 1;
    auto source = sp::script::Convert<sp::ecs::Entity>::fromLua(L, 1);

    if (!source) return 1;

    float r = static_cast<float>(luaL_checknumber(L, 2));
    auto source_transform = source.getComponent<sp::Transform>();
    if (!source_transform) return 1;

    auto position = source_transform->getPosition();
    for (auto entity : sp::TransformQuery::queryArea(position - glm::vec2(r, r), position + glm::vec2(r, r)))
    {
        if (auto entity_transform = entity.getComponent<sp::Transform>())
        {
            if (glm::length2(entity_transform->getPosition() - position) < r*r)
            {
                if (Faction::getRelation(entity, source) == FactionRelation::Enemy)
                {
                    sp::script::Convert<sp::ecs::Entity>::toLua(L, entity);
                    lua_rawseti(L, -2, idx++);
                }
            }
        }
    }

    return 1;
}

static void luaTransferPlayers(sp::ecs::Entity source, sp::ecs::Entity target, std::optional<CrewPosition> station)
{
    // Relevant only to player-controlled entities.
    auto target_pc = target.getComponent<PlayerControl>();

    if (!target_pc)
    {
        LOG(Error, "[lua] transferPlayersToShip: Destination ship has no PlayerControl component.");
        return;
    }

    if (!target_pc->allowed_positions.mask)
    {
        LOG(Error, "[lua] transferPlayersToShip: Destination ship has no allowed crew positions.");
        return;
    }

    // For each matching player, reassign their ship, filter crew positions
    // against the new ship's allowed positions, and clear their cached ship
    // password.
    for (auto i : player_info_list)
    {
        if (i->ship != source || (station.has_value() && !i->hasPosition(station.value())))
            continue;

        // Move player to new ship.
        i->ship = target;

        // Check against the destination's allowed crew positions. If a player's
        // in a position prohibited by the new ship, log a warning for the
        // scenario author and drop the player into the next allowed position.
        for (auto& cps : i->crew_positions)
        {
            CrewPositions lost{cps.mask & ~target_pc->allowed_positions.mask};
            if (lost.mask)
            {
                // This is probably not what the script user intended, so log
                // it.
                for (auto cp : lost)
                    LOG(Warning, "[lua] transferPlayersToShip: Player ", i->name, " held the ", crewPositionToString(cp), " crew position, which is prohibited on the destination ship. Reassigning to next allowed position.");

                // Assign the first allowed position not already held on this
                // monitor.
                for (int n = 0; n < static_cast<int>(CrewPosition::MAX); n++)
                {
                    auto cp = static_cast<CrewPosition>(n);

                    if (target_pc->allowed_positions.has(cp) && !cps.has(cp))
                    {
                        cps.add(cp);
                        break;
                    }
                }
            }

            cps.mask &= target_pc->allowed_positions.mask;
        }

        // Clear last ship password.
        i->last_ship_password = "";
    }
}

static bool luaHasPlayerAtPosition(sp::ecs::Entity source, CrewPosition station)
{
    for (auto i : player_info_list)
        if (i->ship == source && i->hasPosition(station)) return true;

    return false;
}

static int luaGetPlayersInfo(lua_State* L)
{
    auto source = sp::script::Convert<sp::ecs::Entity>::fromLua(L, 1);
    lua_newtable(L);

    int index = 1;
    for (auto i : player_info_list)
    {
        if (i->ship != source) continue;

        lua_newtable(L);
        lua_pushstring(L, i->name.c_str());
        lua_setfield(L, -2, "name");

        CrewPositions positions;

        for (auto cp : i->crew_positions) positions.mask |= cp.mask;

        sp::script::Convert<CrewPositions>::toLua(L, positions);
        lua_setfield(L, -2, "positions");
        lua_seti(L, -2, index);

        index++;
    }

    return 1;
}

void luaSetPlayerShipCustomFunction(sp::ecs::Entity entity, CustomShipFunctions::Function::Type type, string name, string caption, CrewPositions positions, sp::script::Callback callback, int order)
{
    auto csf = entity.getComponent<CustomShipFunctions>();
    if (!csf) return;

    int idx = -1;
    for (int n = 0; n < static_cast<int>(csf->functions.size()); n++)
        if (csf->functions[n].name == name) idx = n;

    if (idx == -1)
    {
        idx = static_cast<int>(csf->functions.size());
        csf->functions.emplace_back();
    }

    auto& f = csf->functions[idx];
    f.type = type;
    f.name = name;
    f.caption = caption;
    f.crew_positions = positions;
    f.callback = callback;
    f.order = order;

    std::stable_sort(csf->functions.begin(), csf->functions.end());
    csf->functions_dirty = true;
}

void luaRemovePlayerShipCustomFunction(sp::ecs::Entity entity, string name)
{
    auto csf = entity.getComponent<CustomShipFunctions>();
    if (!csf) return;

    auto it = std::remove_if(csf->functions.begin(), csf->functions.end(),
        [name](const CustomShipFunctions::Function& f) {
            return f.name == name;
        }
    );

    if (it != csf->functions.end())
    {
        csf->functions.erase(it, csf->functions.end());
        csf->functions_dirty = true;
    }
}

void luaAddEntryToShipsLog(sp::ecs::Entity entity, string entry, glm::u8vec4 color)
{
    auto sl = entity.getComponent<ShipLog>();
    if (!sl) return;
    sl->add(entry, color);
}

static sp::ecs::Entity luaGetPlayerShip(int index)
{
    if (index == -1)
    {
        for (auto [entity, pc] : sp::ecs::Query<PlayerControl>()) return entity;
        return {};
    }

    if (index == -2) return my_spaceship;

    for (auto [entity, pc] : sp::ecs::Query<PlayerControl>())
        if (--index == 0) return entity;

    return {};
}

static int luaGetActivePlayerShips(lua_State* L)
{
    lua_newtable(L);
    int index = 1;

    for (auto [entity, pc] : sp::ecs::Query<PlayerControl>())
    {
        sp::script::Convert<sp::ecs::Entity>::toLua(L, entity);
        lua_rawseti(L, -2, index++);
    }

    return 1;
}

static string luaGetGameLanguage()
{
    return PreferencesManager::get("language", "en_US").c_str();
}

// Short lived object to do a scenario change on the update loop. See
// "setScenario" for details.
class ScenarioChanger : public Updatable
{
public:
    ScenarioChanger(string script_name, std::unordered_map<string, string>&& settings)
    : script_name(script_name), settings(std::move(settings))
    {
    }

    virtual void update(float delta) override
    {
        gameGlobalInfo->startScenario(script_name, settings);
        destroy();
    }
private:
    string script_name;
    std::unordered_map<string, string> settings;
};

static int luaSetScenario(lua_State* L)
{
    string script_name = luaL_checkstring(L, 1);
    std::unordered_map<string, string> settings;

    // Script filename must not be an empty string.
    if (script_name == "")
    {
        LOG(Error, "[lua] setScenario() requires a non-empty value.");
        return 1;
    }

    if (lua_type(L, 2) == LUA_TSTRING)
    {
        LOG(Warning, "[lua] Deprecated setScenario() called with scenario variation. Passing the value as the \"variation\" scenario setting instead.");
        string variation = lua_tostring(L, 2);
        settings["variation"] = variation;
    }

    if (lua_istable(L, 2))
    {
        lua_pushnil(L);
        while (lua_next(L, 2))
        {
            settings[lua_tostring(L, -2)] = lua_tostring(L, -1);
            lua_pop(L, 1);
        }
    }

    new ScenarioChanger(script_name, std::move(settings));

    // This could be called from a currently active scenario script.
    // Calling GameGlobalInfo::startScenario is unsafe at this point,
    // as this will destroy the lua state that this function is running in.
    // So use the ScenarioChanger object which will do the change in the update
    // loop. Which is safe.
    return 0;
}


static void luaShutdownGame()
{
    engine->shutdown();
}

static void luaPauseGame()
{
    engine->setGameSpeed(0.0f);
}

static void luaUnpauseGame()
{
    if (engine->getGameSpeed() == 0.0f) engine->setGameSpeed(1.0f);
}

static void luaSetGameSpeed(float game_speed)
{
    static constexpr float valid_speeds[] = {0.1f, 0.25f, 0.5f, 1.0f, 2.0f, 4.0f, 8.0f};
    bool valid = game_speed == 0.0f;
    if (!valid)
    {
        for (float v : valid_speeds)
        {
            if (fabsf(game_speed - v) < 0.001f)
            {
                valid = true;
                break;
            }
        }
    }

    if (valid) engine->setGameSpeed(game_speed);
    else
        LOG(Warning, "[lua] setGameSpeed: Invalid value ", game_speed, "; must be 0, 0.1, 0.25, 0.5, 1, 2, 4, or 8");
}

static float luaGetGameSpeed()
{
    return engine->getGameSpeed();
}

static bool luaIsGamePaused()
{
    return engine->getGameSpeed() == 0.0f;
}

static void luaPlaySoundFile(string filename)
{
    int n = filename.rfind(".");
    if (n > -1)
    {
        string filename_with_locale = filename.substr(0, n) + "." + PreferencesManager::get("language", "en_US") + filename.substr(n);
        if (getResourceStream(filename_with_locale))
        {
            soundManager->playSound(filename_with_locale);
            return;
        }
    }

    soundManager->playSound(filename);

    return;
}

static void luaApplyDamageToEntity(sp::ecs::Entity e, float amount, DamageInfo info)
{
    DamageSystem::applyDamage(e, amount, info);
}

static int luaGetEEVersion()
{
    return VERSION_NUMBER;
}

static nlohmann::json luaToJSONImpl(lua_State* L, int lua_index)
{
    LOG(Debug, "[lua] Lua to JSON index: ", lua_index);

    auto ltype = lua_type(L, lua_index);
    if (ltype == LUA_TBOOLEAN)
        return bool(lua_toboolean(L, lua_index));
    else if (ltype == LUA_TNUMBER)
    {
        if (lua_isinteger(L, lua_index))
            return lua_tointeger(L, lua_index);

        return lua_tonumber(L, lua_index);
    }
    else if (ltype == LUA_TSTRING)
        return lua_tostring(L, lua_index);
    else if (lua_istable(L, lua_index))
    {
        // Determine whether the table is a list.
        bool is_array = true;
        int index_max = std::numeric_limits<int>::min();
        int index_min = std::numeric_limits<int>::max();
        lua_pushnil(L);

        while (is_array && lua_next(L, lua_index))
        {
            if (!lua_isinteger(L, -2))
            {
                is_array = false;
                lua_pop(L, 1);
            }
            else
            {
                int idx = static_cast<int>(lua_tointeger(L, -2));
                index_max = std::max(idx, index_max);
                index_min = std::min(idx, index_min);
            }

            lua_pop(L, 1);
        }

        if (is_array && index_min == 1 && index_max < 0x10000)
        {
            auto json = nlohmann::json::array();
            for (int idx = 1; idx <= index_max; idx++)
            {
                lua_rawgeti(L, lua_index, idx);
                json.push_back(luaToJSONImpl(L, lua_gettop(L)));
                lua_pop(L, 1);
            }

            return json;
        }
        else
        {
            auto json = nlohmann::json::object();
            lua_pushnil(L);
            while (lua_next(L, lua_index))
            {
                std::string key = "?";
                ltype = lua_type(L, -2);

                if (ltype == LUA_TBOOLEAN)
                    key = lua_toboolean(L, -2) ? "true" : "false";
                else if (ltype == LUA_TNUMBER)
                {
                    if (lua_isinteger(L, -2))
                        key = std::to_string(lua_tointeger(L, -2));
                    else
                        key = std::to_string(lua_tonumber(L, -2));
                }
                else if (ltype == LUA_TSTRING) key = lua_tostring(L, -2);

                json[key] = luaToJSONImpl(L, lua_gettop(L));

                lua_pop(L, 1);
            }

            return json;
        }
    }

    return {};
}

static int luaToJSON(lua_State* L)
{
    auto argc = lua_gettop(L);
    for (int n = 1; n <= argc; n++)
    {
        auto json = luaToJSONImpl(L, n);
        auto res = json.dump(-1, ' ', false, nlohmann::json::error_handler_t::replace);
        lua_pushstring(L, res.c_str());
    }

    return argc;
}

static void luaFromJSONImpl(lua_State* L, const nlohmann::json& json)
{
    if (json.is_boolean())
        lua_pushboolean(L, static_cast<bool>(json));
    else if (json.is_string())
    {
        auto s = static_cast<std::string>(json);
        lua_pushlstring(L, s.c_str(), s.size());
    }
    else if (json.is_number_integer())
        lua_pushinteger(L, static_cast<int>(json));
    else if (json.is_number())
        lua_pushnumber(L, json);
    else if (json.is_array())
    {
        lua_newtable(L);
        int idx = 1;
        for (const auto& v : json)
        {
            luaFromJSONImpl(L, v);
            lua_rawseti(L, -2, idx++);
        }
    }
    else if (json.is_object())
    {
        lua_newtable(L);
        for (const auto& v : json.items())
        {
            lua_pushstring(L, v.key().c_str());
            luaFromJSONImpl(L, v.value());
            lua_rawset(L, -3);
        }
    } else lua_pushnil(L);
}

static int luaFromJSON(lua_State* L)
{
    bool error = false;
    auto argc = lua_gettop(L);

    for (int n = 1; n <= argc; n++)
    {
        auto str = lua_tostring(L, n);
        std::string err;
        auto res = sp::json::parse(str, err);

        if (res.has_value())
            luaFromJSONImpl(L, res.value());
        else
        {
            lua_pushstring(L, err.c_str());
            error = true;
            break;
        }
    }

    if (error) return lua_error(L);

    return argc;
}

namespace sp::script
{
template<> struct Convert<EScanningComplexity>
{
    static int toLua(lua_State* L, EScanningComplexity value)
    {
        switch(value)
        {
        default:
        case SC_None: lua_pushstring(L, "none"); break;
        case SC_Simple: lua_pushstring(L, "simple"); break;
        case SC_Normal: lua_pushstring(L, "normal"); break;
        case SC_Advanced: lua_pushstring(L, "advanced"); break;
        }

        return 1;
    }
};
}

static EScanningComplexity luaGetScanningComplexity()
{
    return gameGlobalInfo->scanning_complexity;
}

static int luaGetHackingDifficulty()
{
    return gameGlobalInfo->hacking_difficulty;
}

namespace sp::script
{
template<> struct Convert<EHackingGames>
{
    static int toLua(lua_State* L, EHackingGames value)
    {
        switch(value)
        {
        case HG_Mine: lua_pushstring(L, "mines"); break;
        case HG_Lights: lua_pushstring(L, "lights"); break;
        default:
        case HG_All: lua_pushstring(L, "all"); break;
        }

        return 1;
    }
};
}

static EHackingGames luaGetHackingGames()
{
    return gameGlobalInfo->hacking_games;
}

static bool luaAreBeamShieldFrequenciesUsed()
{
    return gameGlobalInfo->use_beam_shield_frequencies;
}

static bool luaIsPerSystemDamageUsed()
{
    return gameGlobalInfo->use_system_damage;
}

static bool luaIsTacticalRadarAllowed()
{
    return gameGlobalInfo->allow_main_screen_tactical_radar;
}

static bool luaIsLongRangeRadarAllowed()
{
    return gameGlobalInfo->allow_main_screen_long_range_radar;
}

static bool luaIsStrategicMapAllowed()
{
    return gameGlobalInfo->allow_main_screen_strategic_map;
}

static bool luaAreMissilesOnLongRangeRadar()
{
    return gameGlobalInfo->missiles_on_long_range_radar;
}

void luaCommandTargetRotation(sp::ecs::Entity ship, float rotation)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandTargetRotation(rotation);
        return;
    }

    if (auto thrusters = ship.getComponent<ManeuveringThrusters>())
    {
        thrusters->stop();
        thrusters->target = rotation;
    }
}

void luaCommandImpulse(sp::ecs::Entity ship, float target)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandImpulse(target);
        return;
    }

    if (auto engine = ship.getComponent<ImpulseEngine>())
        engine->request = target;
}

void luaCommandWarp(sp::ecs::Entity ship, int target)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandWarp(target);
        return;
    }

    if (auto warp = ship.getComponent<WarpDrive>())
        warp->request = target;
}

void luaCommandJump(sp::ecs::Entity ship, float distance)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandJump(distance);
        return;
    }

    JumpSystem::initializeJump(ship, distance);
}

void luaCommandAbortJump(sp::ecs::Entity ship)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandAbortJump();
        return;
    }

    JumpSystem::abortJump(ship);
}

void luaCommandSetTarget(sp::ecs::Entity ship, sp::ecs::Entity target)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandSetTarget(target);
        return;
    }

    ship.getOrAddComponent<Target>().entity = target;
}

void luaCommandSetScienceTarget(sp::ecs::Entity ship, sp::ecs::Entity target)
{
    luaCommandSetTarget(ship, target);
}

void luaCommandLoadTube(sp::ecs::Entity ship, int tube_nr, string type_name)
{
    int type_index = MissileWeaponDataRegistry::instance().getIndexForName(type_name);
    if (type_index < 0)
        return;
    if (my_player_info && my_player_info->ship == ship) { my_player_info->commandLoadTube(tube_nr, type_index); return; }
    auto mounts = ship.getComponent<Mounts>();
    if (mounts && tube_nr >= 0)
    {
        for (auto& mount : mounts->mounts)
        {
            if (mount.type == MountType::MissileWeapon)
            {
                if (tube_nr == 0)
                {
                    MissileSystem::startLoad(ship, mount, type_index);
                    return;
                }
                tube_nr--;
            }
        }
    }
}

void luaCommandUnloadTube(sp::ecs::Entity ship, int tube_nr)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandUnloadTube(tube_nr);
        return;
    }

    auto mounts = ship.getComponent<Mounts>();
    if (mounts && tube_nr >= 0)
    {
        for (auto& mount : mounts->mounts)
        {
            if (mount.type == MountType::MissileWeapon)
            {
                if (tube_nr == 0)
                {
                    MissileSystem::startUnload(ship, mount);
                    return;
                }
                tube_nr--;
            }
        }
    }
}

void luaCommandFireTube(sp::ecs::Entity ship, int tube_nr, float missile_target_angle)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandFireTube(tube_nr, missile_target_angle);
        return;
    }

    auto mounts = ship.getComponent<Mounts>();
    if (mounts && tube_nr >= 0)
    {
        for (auto& mount : mounts->mounts)
        {
            if (mount.type == MountType::MissileWeapon)
            {
                if (tube_nr == 0)
                {
                    sp::ecs::Entity target;
                    if (auto t = ship.getComponent<Target>()) target = t->entity;
                    MissileSystem::fire(ship, mount, missile_target_angle, target);
                    return;
                }
                tube_nr--;
            }
        }
    }
}

void luaCommandFireTubeAtTarget(sp::ecs::Entity ship, int tube_nr, sp::ecs::Entity target)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandFireTubeAtTarget(tube_nr, target);
        return;
    }

    float targetAngle = 0.0f;
    auto mounts = ship.getComponent<Mounts>();

    if (!target || !mounts)
        return;

    for (auto& mount : mounts->mounts)
    {
        if (mount.type == MountType::MissileWeapon)
        {
            if (tube_nr == 0)
            {
                targetAngle = MissileSystem::calculateFiringSolution(ship, mount, target);
                if (targetAngle == std::numeric_limits<float>::infinity())
                {
                    if (auto transform = ship.getComponent<sp::Transform>())
                        targetAngle = transform->getRotation() + mount.direction;
                }
                MissileSystem::fire(ship, mount, targetAngle, target);
                return;
            }
            tube_nr--;
        }
    }
}

static void luaCommandSetAlertLevel(sp::ecs::Entity ship, AlertLevel level)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandSetAlertLevel(level);
        return;
    }

    if (auto player_control = ship.getComponent<PlayerControl>())
        player_control->alert_level = level;
}

void luaCommandSetShields(sp::ecs::Entity ship, bool active)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandSetShields(active);
        return;
    }

    if (auto shields = ship.getComponent<Shields>())
    {
        if (shields->calibration_delay <= 0.0f && active != shields->active)
        {
            shields->active = active;
            if (active)
                gameGlobalInfo->playSoundOnMainScreen(ship, "sfx/shield_up.wav");
            else
                gameGlobalInfo->playSoundOnMainScreen(ship, "sfx/shield_down.wav");
        }
    }
}

void luaCommandMainScreenSetting(sp::ecs::Entity ship, MainScreenSetting mainScreen)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandMainScreenSetting(mainScreen);
        return;
    }

    if (auto pc = ship.getComponent<PlayerControl>())
        pc->main_screen_setting = mainScreen;
}

void luaCommandMainScreenOverlay(sp::ecs::Entity ship, MainScreenOverlay mainScreen)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandMainScreenOverlay(mainScreen);
        return;
    }

    if (auto pc = ship.getComponent<PlayerControl>())
        pc->main_screen_overlay = mainScreen;
}

void luaCommandScan(sp::ecs::Entity ship, sp::ecs::Entity target)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandScan(target);
        return;
    }

    if (auto scanner = ship.getComponent<ScienceScanner>())
    {
        scanner->delay = scanner->max_scanning_delay;
        scanner->target = target;
        scanner->scan_target = target;
    }
}

void luaCommandSetSystemPowerRequest(sp::ecs::Entity ship, ShipSystem::Type system, float power_level) {
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandSetSystemPowerRequest(system, power_level);
        return;
    }

    if (auto sys = ShipSystem::get(ship, system))
        sys->power_request = std::clamp(power_level, 0.0f, 3.0f);
}

void luaCommandSetSystemCoolantRequest(sp::ecs::Entity ship, ShipSystem::Type system, float coolant_level) {
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandSetSystemCoolantRequest(system, coolant_level);
        return;
    }

    if (auto coolant = ship.getComponent<Coolant>())
    {
        if (auto sys = ShipSystem::get(ship, system))
            sys->coolant_request = std::clamp(coolant_level, 0.0f, std::min(coolant->max_coolant_per_system, coolant->max));
    }
}

void luaCommandDock(sp::ecs::Entity ship, sp::ecs::Entity station)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandDock(station);
        return;
    }

    DockingSystem::requestDock(ship, station);
}

void luaCommandUndock(sp::ecs::Entity ship)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandUndock();
        return;
    }

    DockingSystem::requestUndock(ship);
}

void luaCommandAbortDock(sp::ecs::Entity ship)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandAbortDock();
        return;
    }

    DockingSystem::abortDock(ship);
}

void luaCommandOpenTextComm(sp::ecs::Entity ship, sp::ecs::Entity obj)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandOpenTextComm(obj);
        return;
    }

    CommsSystem::openTo(ship, obj);
}

void luaCommandCloseTextComm(sp::ecs::Entity ship)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandCloseTextComm();
        return;
    }

    CommsSystem::close(ship);
}

void luaCommandAnswerCommHail(sp::ecs::Entity ship, bool awnser)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandAnswerCommHail(awnser);
        return;
    }

    CommsSystem::answer(ship, awnser);
}

void luaCommandSendComm(sp::ecs::Entity ship, int index)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandSendComm(index);
        return;
    }

    CommsSystem::selectScriptReply(ship, index);
}

void luaCommandSendCommPlayer(sp::ecs::Entity ship, string message)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandSendCommPlayer(message);
        return;
    }

    CommsSystem::textReply(ship, message);
}

void luaCommandSetAutoRepair(sp::ecs::Entity ship, bool enabled)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandSetAutoRepair(enabled);
        return;
    }

    if (auto ir = ship.getComponent<InternalRooms>())
        ir->auto_repair_enabled = enabled;
}

void luaCommandSetBeamFrequency(sp::ecs::Entity ship, int frequency)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandSetBeamFrequency(frequency);
        return;
    }

    if (auto beamweapons = ship.getComponent<BeamWeaponSys>())
        beamweapons->setFrequency(frequency);
}

void luaCommandSetBeamSystemTarget(sp::ecs::Entity ship, ShipSystem::Type type)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandSetBeamSystemTarget(type);
        return;
    }

    if (auto beamweapons = ship.getComponent<BeamWeaponSys>())
        beamweapons->system_target = type;
}

void luaCommandSetUtilityBeam(sp::ecs::Entity ship, bool active)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandSetUtilityBeam(active);
        return;
    }

    if (auto mounts = ship.getComponent<Mounts>())
    {
        for (auto& mount : mounts->mounts)
        {
            if (mount.type == MountType::UtilityBeam)
            {
                if (active != mount.active)
                {
                    mount.active = active;

                    if (active)
                        gameGlobalInfo->playSoundOnMainScreen(ship, "sfx/shield_up.wav");
                    else
                        gameGlobalInfo->playSoundOnMainScreen(ship, "sfx/shield_down.wav");
                }
                return;
            }
        }
    }
}

void luaCommandSetUtilityBeamDirection(sp::ecs::Entity ship, float direction)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandSetUtilityBeamDirection(direction);
        return;
    }

    if (auto mounts = ship.getComponent<Mounts>())
    {
        for (auto& mount : mounts->mounts)
        {
            if (mount.type == MountType::UtilityBeam)
            {
                if (mount.turret_arc > 0.0f)
                {
                    const float aim_swing = std::max(0.0f, (mount.turret_arc - mount.arc) * 0.5f);
                    direction = std::clamp(direction, mount.turret_direction - aim_swing, mount.turret_direction + aim_swing);
                }
                mount.direction = direction;
                return;
            }
        }
    }
}

void luaCommandSetUtilityBeamArc(sp::ecs::Entity ship, float arc)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandSetUtilityBeamArc(arc);
        return;
    }

    if (auto mounts = ship.getComponent<Mounts>())
    {
        for (auto& mount : mounts->mounts)
        {
            if (mount.type == MountType::UtilityBeam)
            {
                utilityBeamSetArc(mount, arc);
                return;
            }
        }
    }
}

void luaCommandSetUtilityBeamRange(sp::ecs::Entity ship, float range)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandSetUtilityBeamRange(range);
        return;
    }

    if (auto mounts = ship.getComponent<Mounts>())
    {
        for (auto& mount : mounts->mounts)
        {
            if (mount.type == MountType::UtilityBeam)
            {
                utilityBeamSetRange(mount, range);
                return;
            }
        }
    }
}

void luaSetCustomUtilityBeamMode(sp::ecs::Entity ship, string name, int order, float energy_per_sec, float heat_per_sec, bool requires_target, sp::script::Callback callback, sp::script::Callback deactivate_callback)
{
    ship.getOrAddComponent<UtilityBeam>();
    auto mounts = ship.getComponent<Mounts>();
    if (!mounts) return;

    for (auto& mount : mounts->mounts)
    {
        if (mount.type == MountType::UtilityBeam)
        {
            auto& cbm = mount.custom_beam_modes;

            int idx = -1;
            for (int n = 0; n < static_cast<int>(cbm.size()); n++)
                if (cbm[n].name == name) idx = n;

            if (idx == -1)
            {
                idx = static_cast<int>(cbm.size());
                cbm.emplace_back();
            }

            auto& f = cbm[idx];
            f.name = name;
            f.energy_per_sec = energy_per_sec;
            f.heat_per_sec = heat_per_sec;
            f.callback = callback;
            f.deactivate_callback = deactivate_callback;
            f.order = order;
            f.requires_target = requires_target;

            std::stable_sort(cbm.begin(), cbm.end());
            mounts->mounts_dirty = true;
            return;
        }
    }
}

void luaSetCustomUtilityBeamModeProgress(sp::ecs::Entity ship, string name, float progress)
{
    ship.getOrAddComponent<UtilityBeam>();
    auto mounts = ship.getComponent<Mounts>();
    if (!mounts) return;

    for (auto& mount : mounts->mounts)
    {
        if (mount.type == MountType::UtilityBeam)
        {
            auto& cbm = mount.custom_beam_modes;

            int idx = -1;
            for (int n = 0; n < static_cast<int>(cbm.size()); n++)
                if (cbm[n].name == name) idx = n;

            if (idx == -1) return;

            auto& f = cbm[idx];
            f.progress = progress;
            mounts->mounts_dirty = true;
            return;
        }
    }
}

void luaRemoveCustomUtilityBeamMode(sp::ecs::Entity ship, string name)
{
    ship.getOrAddComponent<UtilityBeam>();
    auto mounts = ship.getComponent<Mounts>();
    if (!mounts) return;

    for (auto& mount : mounts->mounts)
    {
        if (mount.type == MountType::UtilityBeam)
        {
            auto& cbm = mount.custom_beam_modes;
            if (cbm.size() < 1) return;

            auto it = std::remove_if(cbm.begin(), cbm.end(),
                [name](const CustomBeamMode& f)
                {
                    return f.name == name;
                }
            );

            if (it != cbm.end()) cbm.erase(it, cbm.end());
            mounts->mounts_dirty = true;
            return;
        }
    }
}

void luaCommandSetShieldFrequency(sp::ecs::Entity ship, int frequency)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandSetShieldFrequency(frequency);
        return;
    }

    auto shields = ship.getComponent<Shields>();
    if (shields && shields->calibration_delay <= 0.0f && frequency != shields->frequency)
    {
        shields->frequency = std::clamp(frequency, 0, BeamWeaponSys::max_frequency);
        shields->calibration_delay = shields->calibration_time;
        shields->active = false;
    }
}

static void luaCommandAddWaypoint(sp::ecs::Entity ship, float x, float y, int set_id = 1)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandAddWaypoint({x, y}, set_id);
        return;
    }

    if (auto wp = ship.getComponent<Waypoints>()) wp->addNew({x, y}, set_id);
}

static void luaCommandRemoveWaypoint(sp::ecs::Entity ship, int index, int set_id = 1)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandRemoveWaypoint(index, set_id);
        return;
    }

    if (auto wp = ship.getComponent<Waypoints>()) wp->remove(index, set_id);
}

static void luaCommandMoveWaypoint(sp::ecs::Entity ship, int index, float x, float y, int set_id = 1)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandMoveWaypoint(index, {x, y}, set_id);
        return;
    }

    if (auto wp = ship.getComponent<Waypoints>())
        wp->move(index, {x, y}, set_id);
}

static void luaCommandSetWaypointRoute(sp::ecs::Entity ship, bool is_route, int set_id = 1)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandSetWaypointRoute(is_route, set_id);
        return;
    }

    if (auto wp = ship.getComponent<Waypoints>())
        wp->setRoute(is_route, set_id);
}

static void luaCommandActivateSelfDestruct(sp::ecs::Entity ship)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandActivateSelfDestruct();
        return;
    }

    SelfDestructSystem::activate(ship);
}

static void luaCommandCancelSelfDestruct(sp::ecs::Entity ship)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandCancelSelfDestruct();
        return;
    }

    if (auto self_destruct = ship.getComponent<SelfDestruct>())
        if (self_destruct->countdown <= 0.0f) self_destruct->active = false;
}

static void luaCommandConfirmDestructCode(sp::ecs::Entity ship, int index, int code)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandConfirmDestructCode(index, code);
        return;
    }

    if (auto self_destruct = ship.getComponent<SelfDestruct>())
    {
        if (index >= 0 && index < SelfDestruct::max_codes && static_cast<int>(self_destruct->code[index]) == code && self_destruct->active)
            self_destruct->confirmed[index] = true;
    }
}

static void luaCommandCombatManeuverBoost(sp::ecs::Entity ship, float amount)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandCombatManeuverBoost(amount);
        return;
    }

    if (auto combat = ship.getComponent<CombatManeuveringThrusters>())
        combat->boost.request = amount;
}

static void luaCommandCombatManeuverStrafe(sp::ecs::Entity ship, float amount)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandCombatManeuverStrafe(amount);
        return;
    }

    if (auto combat = ship.getComponent<CombatManeuveringThrusters>())
        combat->strafe.request = amount;
}

static void luaCommandLaunchProbe(sp::ecs::Entity ship, float x, float y)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandLaunchProbe({x, y});
        return;
    }

    ProbeSystem::launch(ship, {x, y});
}

static void luaCommandSetScienceLink(sp::ecs::Entity ship, sp::ecs::Entity probe)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandSetScienceLink(probe);
        return;
    }

    if (auto radar_link = ship.getComponent<RadarLink>())
    {
        auto existing_link = radar_link->linked_entity;

        // Run on_link callback if present.
        if (radar_link->on_link && probe)
            LuaConsole::checkResult(radar_link->on_link.call<void>(ship, probe));

        // Update radar link.
        radar_link->linked_entity = probe;

        // Run on_unlink callback if this caused an existing link to be broken.
        if (radar_link->on_unlink && existing_link)
            LuaConsole::checkResult(radar_link->on_unlink.call<void>(ship, existing_link));
    }
}

static void luaCommandClearScienceLink(sp::ecs::Entity ship)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandClearScienceLink();
        return;
    }

    if (auto radar_link = ship.getComponent<RadarLink>())
    {
        auto existing_link = radar_link->linked_entity;

        // Clear radar link.
        radar_link->linked_entity = {};

        // Run on_unlink callback if this caused an existing link to be broken.
        if (radar_link->on_unlink && existing_link)
            LuaConsole::checkResult(radar_link->on_unlink.call<void>(ship, existing_link));
    }
}

static void luaCommandSetDroneLink(sp::ecs::Entity ship, sp::ecs::Entity drone)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandSetDroneLink(drone);
        return;
    }

    if (ship.getComponent<DroneController>())
    {
        if (!drone)
        {
            ship.removeComponent<DroneLink>();
            return;
        }

        auto adl = drone.getComponent<AllowDroneLink>();
        if (!adl || adl->owner != ship) return;

        ship.getOrAddComponent<DroneLink>().linked_drone = drone;
    }
}

static void luaCommandClearDroneLink(sp::ecs::Entity ship)
{
    if (my_player_info && my_player_info->ship == ship)
    {
        my_player_info->commandSetDroneLink(sp::ecs::Entity{});
        return;
    }

    ship.removeComponent<DroneLink>();
}

static void luaStartThread(sp::script::Callback callback)
{
    auto res = callback.callCoroutine();
    LuaConsole::checkResult(res);

    if (res.isOk() && res.value())
        gameGlobalInfo->new_script_threads.push_back(res.value());
}

static int luaYield(lua_State* lua)
{
    return lua_yield(lua, 0);
}

static sp::ecs::Entity luaEntityFromString(string s)
{
    return sp::ecs::Entity::fromString(s);
}

static sp::ecs::Entity luaFindFaction(string name)
{
    return Faction::find(name);
}

static sp::ecs::Entity luaFindMissileWeaponData(string name)
{
    return MissileWeaponDataRegistry::instance().getEntityForName(name);
}

static void luaRebuildMissileWeaponData()
{
    MissileWeaponDataRegistry::instance().rebuild();
}

static int luaGetWeaponStorageImpl(sp::ecs::Entity entity, string type_name)
{
    if (auto tubes = entity.getComponent<MissileTubes>())
        return tubes->getStorage(type_name);
    if (auto pickup = entity.getComponent<PickupCallback>())
        return pickup->getGiveMissile(type_name);
    return 0;
}

static void luaSetWeaponStorageImpl(sp::ecs::Entity entity, string type_name, int amount)
{
    if (auto tubes = entity.getComponent<MissileTubes>())
        tubes->setStorage(type_name, amount);
    else if (auto pickup = entity.getComponent<PickupCallback>())
        pickup->setGiveMissile(type_name, amount);
}

static int luaGetWeaponStorageMaxImpl(sp::ecs::Entity entity, string type_name)
{
    if (auto tubes = entity.getComponent<MissileTubes>())
        return tubes->getStorageMax(type_name);
    return 0;
}

static void luaSetWeaponStorageMaxImpl(sp::ecs::Entity entity, string type_name, int amount)
{
    if (auto tubes = entity.getComponent<MissileTubes>())
        tubes->setStorageMax(type_name, amount);
}

static bool luaWeaponTubeAllowMissileImpl(sp::ecs::Entity entity, int mount_index, string type_name)
{
    int type_index = MissileWeaponDataRegistry::instance().getIndexForName(type_name);
    if (type_index < 0) return false;
    if (auto mounts = entity.getComponent<Mounts>())
    {
        for (auto& mount : mounts->mounts)
        {
            if (mount.type == MountType::MissileWeapon)
            {
                if (mount_index == 0)
                    return mount.canLoad(type_index);
                mount_index--;
            }
        }
    }
    return false;
}

static void luaSetWeaponTubeAllowMissileImpl(sp::ecs::Entity entity, int mount_index, string type_name, bool allowed)
{
    int type_index = MissileWeaponDataRegistry::instance().getIndexForName(type_name);
    if (type_index < 0) return;
    if (auto mounts = entity.getComponent<Mounts>())
    {
        for (auto& mount : mounts->mounts)
        {
            if (mount.type == MountType::MissileWeapon)
            {
                if (mount_index == 0)
                {
                    if (allowed)
                        mount.type_allowed_mask |= (1U << type_index);
                    else
                        mount.type_allowed_mask &= ~(1U << type_index);
                    return;
                }
                mount_index--;
            }
        }
    }
}

static void luaSetWeaponTubeExclusiveImpl(sp::ecs::Entity entity, int mount_index, string type_name)
{
    auto& registry = MissileWeaponDataRegistry::instance();
    int mwi = registry.getIndexForName(type_name);
    if (mwi < 0) return;
    if (auto mounts = entity.getComponent<Mounts>())
    {
        for (auto& mount : mounts->mounts)
        {
            if (mount.type == MountType::MissileWeapon)
            {
                if (mount_index == 0)
                {
                    mount.type_allowed_mask = 1U << mwi;
                    return;
                }
                mount_index--;
            }
        }
    }
}

void setupSubEnvironment(sp::script::Environment& env)
{
    env.setGlobalFuncWithEnvUpvalue("require", &luaRequire);
}

bool setupScriptEnvironment(sp::script::Environment& env)
{
    // Load core global functions.

    /// void print(..)
    /// Print values to the Lua console. Also writes them to EmptyEpsilon.log or STDOUT, depending on your configuration.
    /// Accepts one or more values of any parseable type, such as strings, numbers, tables, entities, etc.
    /// The log lines are severity Info, and the log text is prefixed with [lua].
    /// This is the same as log(...) and also prints the value on the Lua console.
    /// Examples:
    /// print("This is a message") -- prints "This is a message" to the Lua console and logs it
    /// print("This", "is", "a", "message") -- prints "This is a message" to the Lua console and logs it
    /// print(getPlayerShip(-1)) -- prints "entity: 00000000000000CE" to the Lua console and logs it
    /// print(getGMSelection()) -- prints all selected entities as "{1=entity: 00000000000002ED,2=entity: 00000000000002EE, ...}"
    env.setGlobal("print", &luaPrint);
    /// void log(...)
    /// Log values to EmptyEpsilon.log or STDOUT, depending on your configuration.
    /// This is the same as print(...) but doesn't print the value on the Lua console.
    /// Examples:
    /// log("This is a log line") -- logs "[INFO    ]: [lua] This is a log line"
    /// See print(...) for more examples.
    env.setGlobal("log", &luaLog);
    env.setGlobalFuncWithEnvUpvalue("require", &luaRequire);
    /// void _(...)
    /// Define a string for internationalization. The string is added to the lists of those that can be translated for a given language.
    /// The function takes up to four arguments, and its behavior depends on the number and type of arguments.
    /// - If only one argument is passed, the string is defined without context.
    /// - If only two arguments are passed and the first is a string, the first argument defines a context for the string, and the second argument defines the string being translated.
    /// - If the first value is a number, the number defines the number of subjects in the translatable string for variable pluralization translations. For example, 1 is singular and 2+ is typically plural.
    ///   This is necessary only for strings that change depending on a numeric value interpolated into the string, especially for languages that have different pluralization forms for different quantities.
    ///   The remaining arguments define an optional context, followed by the singular and plural forms of the translatable string.
    /// Examples:
    /// comms = _("Atlantis, you are cleared for launch.") -- defines the string for translation
    /// comms = _("comms", "Atlantis, you are cleared for launch.") -- defines the string with the context of "comms"
    /// -- Defines strings for singular and plural forms, depending on the value of the minutes variable:
    /// minutes = 5; comms = string.format(_(minutes, "comms-timer", [[Atlantis, you have 1 minute remaining.]], [[Atlantis, you have %d minutes remaining.]]), minutes))
    env.setGlobal("_", &luaTranslate);

    /// entity createEntity()
    /// Creates an entity with no components.
    /// Example:
    /// new_entity = createEntity()
    env.setGlobal("createEntity", &luaCreateEntity);
    /// table getEntitiesWithComponent(string component_name)
    /// Returns a table of entities that have the given component type.
    /// Component names are typically lowercased versions of their C++ equivalents with words separated by underscores instead of by case.
    /// These names do not necessarily match their ShipSystem equivalents. For example, "beam_weapons" is the Lua component name to be used here, but "beamweapons" is the separate Lua ShipSystem name.
    /// Examples:
    ///   getEntitiesWithComponent("beam_weapons") -- returns a table of all entities with the BeamWeapons component.
    ///   getEntitiesWithComponent("beam_weapons")[1]:getCallSign() -- returns the callsign of the first identified entity with beam weapons
    env.setGlobal("getEntitiesWithComponent", &luaQueryEntities);
    /// bool moveEntityToInternalBay(entity target, entity carrier)
    /// Moves an entity into another entity's internal docking bay.
    /// Returns true if successful, false if the carrier does not support internal docking with the target.
    /// Example:
    /// success = moveEntityToInternalBay(drone, carrier) -- moves the drone entity into the carrier's internal bay
    env.setGlobal("moveEntityToInternalBay", &luaMoveEntityToInternalBay);
    /// table getLuaEntityFunctionTable()
    /// Returns a table containing Lua entity functions.
    /// Example:
    /// functions = getLuaEntityFunctionTable() -- returns {getSystemHeatRate=function: 0000020464069A10,setCommsFunction=function: ...}
    env.setGlobal("getLuaEntityFunctionTable", &luaGetEntityFunctionTable);
    // TODO: Add threading examples
    /// void startThread(function callback)
    /// Starts a background thread and runs the given callback function in it.
    /// See also yield().
    env.setGlobal("startThread", &luaStartThread);
    env.setGlobal("yield", &luaYield);
    /// table createClass()
    /// Returns a class table onto which you can define methods. The table can be called as a function to instantiate a new object of that class.
    /// Used by ShipTemplate and ModelData to define themselves as Lua-native classes.
    /// If you define an optional member function named __init__(), that function is run upon instantiation of a new object with this class. The __init__() function is passed only self and should define default values for this instance.
    /// Examples:
    /// NewClass = createClass() -- define a class named NewClass
    /// function NewClass:__init__() ... end -- define an initialization method for NewClass
    /// function NewClass:setName(name) ... end -- define a NewClass method named setName
    /// new_object = NewClass():setName("Rookie") -- creates a NewClass-type object with name "Rookie"
    env.setGlobal("createClass", &luaCreateClass);

    /// string getScenarioSetting(string key)
    /// Returns the given scenario setting's value, or an empty string if the setting is not found.
    /// Warning: Headless server modes might load scenarios without default setting values.
    /// Example: getScenarioSetting("Difficulty") -- if a scenario has Setting[Difficulty], returns its value, such as "Easy" or "Normal"
    env.setGlobal("getScenarioSetting", &luaGetScenarioSetting);
    // this returns the "variation" scenario setting for backwards compatibility
    /// string getScenarioVariation()
    /// [DEPRECATED]
    /// As getScenarioSetting("variation").
    env.setGlobal("getScenarioVariation", &luaGetScenarioVariation);
    /// void globalMessage(string message, std::optional<float> timeout)
    /// Displays a message on the main screens of all active player ships.
    /// The message appears for 5 seconds, but new messages immediately replace any displayed message.
    /// Example: globalMessage("You will soon die!")
    env.setGlobal("globalMessage", &luaGlobalMessage);
    /// void victory(string faction_name)
    /// Sets the given faction as the scenario's victor and ends the scenario.
    /// (The GM can unpause the game, but the scenario with its update function is destroyed.)
    /// Example: victory("Exuari") -- ends the scenario, Exuari win
    env.setGlobal("victory", &luaVictory);
    /// string getSectorName(float x, float y)
    /// Returns the name of the sector containing the given x/y coordinates.
    /// Sectors are 20U square zones defined in a 100x100 grid centered on the origin point 0,0.
    /// Sector names are in the format `RR-CC`, where RR is the row (00-99) and CC is the column (00-99).
    /// Sector 00-00 is at the top-left (northwest) corner, 50 sectors west and north of origin.
    /// For columns east of 99, the dash is replaced with letters from N to Z. For columns west of 00, the dash is replaced with letters from M to A.
    /// For rows north of 00, sector names are prefixed with letters from M to A. For rows south of 99, sector names are prefixed with letters from N to Z.
    /// See also SpaceObject:getSectorName().
    /// Example: getSectorName(20000,-40000) -- returns "48-51"
    env.setGlobal("getSectorName", &luaGetSectorName);
    /// glm::vec2 sectorToXY(string sector_name)
    /// Returns the top-left ("northwest") x/y coordinates for the given sector name.
    /// If the sector name is invalid, this returns coordinates 0, 0. This function also returns a third optional Boolean value that indicates whether the sector name was valid.
    /// Examples:
    /// x, y = sectorToXY("50-50") -- x = 0, y = 0
    /// x, y = sectorToXY("00-00") -- x = -1000000, y = -1000000
    /// x, y = sectorToXY("50-63") -- x = 260000, y = 0
    /// x, y, valid = sectorToXY("50N00") -- x = 2800000, y = 0, valid = true
    /// x, y, valid = sectorToXY("A00-00") -- x = -1000000, y = -3000000, valid = true
    /// x, y, valid = sectorToXY("FOOBAR9000") -- x = 0, y = 0, valid = false
    env.setGlobal("sectorToXY", &luaSectorToXY);
    /// bool isInsideZone(x, y, zone_entity)
    /// Checks whether the given x/y coordinates are within the specified zone.
    /// Example:
    /// square_zone = Zone():setPoints(-2000, 2000, 2000, 2000, 2000, -2000, -2000, -2000) -- draw a 4U square zone around coordinates 0, 0
    /// local inside_zone = isInsideZone(1000, 1000, square_zone) -- true, because coordinates 1000, 1000 are inside of the zone
    /// local outside_zone = isInsideZone(10000, 10000, square_zone) -- false, because coordinates 10000, 10000 are outside of the zone
    env.setGlobal("isInsideZone", &luaIsInsideZone);
    /// void setBanner(string banner)
    /// Displays a scrolling banner containing the given text on the cinematic and top-down views.
    /// Example: setBanner("You will soon die!")
    env.setGlobal("setBanner", &luaSetBanner);
    /// void setDefaultSkybox(string skybox)
    /// Sets the default skybox image set to use in 3D viewports. Each image set is a directory in resources/skybox containing top.png, right.png, left.png, front.png, bottom.png, and back.png images. Defaults to "default".
    /// Example: setDefaultSkybox("simulation")
    env.setGlobal("setDefaultSkybox", &luaSetDefaultSkybox);
    /// void setBriefingPage(entity ship, int index, string page_caption, string page_image, string page_audio, float page_duration)
    /// Sets or overwrites the briefing page at the given 1-based index on the specified entity.
    /// If the index is beyond the current page count, intermediate pages are created.
    /// Optional arguments should be passed as nil to skip them. If a page already exists but an optional parameter is nil, that parameter's value is not changed.
    /// If page_audio is provided but page_duration is not, the duration is automatically calculated from the audio file length.
    /// If page_audio is invalid, a warning is logged.
    /// Example:
    /// setBriefingPage(player, 1, "Welcome", "briefing/page1.png", "audio/page1.ogg")
    /// setBriefingPage(player, 2, nil, "briefing/page2.png", nil, 10) -- keeps caption and audio from existing page 2, updates image and duration
    env.setGlobal("setBriefingPage", &luaSetBriefingPage);
    /// void clearBriefing(entity ship)
    /// Removes all pages from the briefing on the specified entity, resetting it to an empty state.
    /// If the briefing is currently playing, playback stops and resets to page 1.
    /// Example: clearBriefing(player)
    env.setGlobal("clearBriefing", &luaClearBriefing);
    /// void removeBriefingPage(entity ship, int index)
    /// Removes the briefing page at the given 1-based index from the specified entity.
    /// If the briefing is currently playing, playback stops and resets to page 1.
    /// Example: removeBriefingPage(player, 2)
    env.setGlobal("removeBriefingPage", &luaRemoveBriefingPage);
    /// void setBriefingMapPage(entity ship, int index, float map_duration)
    /// Sets the map page at the given 1-based index on the specified entity.
    /// Replaces the page image, which will be ignored.
    /// If the index is beyond the current page count, intermediate pages are created.
    /// Example: setBriefingMapPage(player, 1, 10)
    env.setGlobal("setBriefingMapPage", &luaSetBriefingMapPage);
    /// void addBriefingMapKeyframe(entity ship, int page_index, int keyframe_index, float timestamp, float cam_x, float cam_y, float zoom)
    /// Adds a keyframe to the map page at the given 1-based page index.
    /// keyframe_index is 1-based. If the keyframe already exists, its values are updated.
    /// zoom is the visible world distance (like radar distance), e.g. 5000.0.
    /// Example: addBriefingMapKeyframe(player, 1, 1, 0.0, 0.0, 0.0, 5000.0)
    env.setGlobal("addBriefingMapKeyframe", &luaAddBriefingMapKeyframe);
    /// void addBriefingMapEntity(entity ship, int page_index, int keyframe_index, int entity_id, float x, float y, float rotation, float world_size, string radar_trace, int r, int g, int b, int a, bool visible, string label)
    /// Adds a pseudoentity to a keyframe on a briefing map page.
    /// Pseudoentities with the same id across keyframes will be tweened between keyframes.
    /// All parameters after entity_id are optional; pass nil to use defaults.
    /// Example: addBriefingMapEntity(player, 1, 1, 1, 5000.0, -3000.0, 45.0, 1000.0, "radar/blip.png", 255, 0, 0, 255, true, "Enemy")
    env.setGlobal("addBriefingMapEntity", &luaAddBriefingMapEntity);
    /// void clearBriefingMapPage(entity ship, int page_index)
    /// Removes all map data from the briefing page at the given 1-based index.
    /// The page reverts to displaying its image, if set.
    /// Example: clearBriefingMapPage(player, 2)
    env.setGlobal("clearBriefingMapPage", &luaClearBriefingMapPage);
    /// void setBriefingMapEntityPosition(entity ship, int page_index, int keyframe_index, int entity_id, float x, float y)
    /// Sets the world position of a pseudoentity on a briefing map keyframe.
    /// If the entity doesn't exist, it is created with the given id.
    /// Example: setBriefingMapEntityPosition(player, 1, 2, 1, 15000.0, 5000.0)
    env.setGlobal("setBriefingMapEntityPosition", &luaSetBriefingMapEntityPosition);
    /// void setBriefingMapEntityRotation(entity ship, int page_index, int keyframe_index, int entity_id, float rotation)
    /// Sets the rotation (degrees) of a pseudoentity on a briefing map keyframe.
    /// Example: setBriefingMapEntityRotation(player, 1, 2, 1, 45.0)
    env.setGlobal("setBriefingMapEntityRotation", &luaSetBriefingMapEntityRotation);
    /// void setBriefingMapEntitySize(entity ship, int page_index, int keyframe_index, int entity_id, float world_size)
    /// Sets the world-unit size of a pseudoentity on a briefing map keyframe.
    /// Example: setBriefingMapEntitySize(player, 1, 2, 1, 1500.0)
    env.setGlobal("setBriefingMapEntitySize", &luaSetBriefingMapEntitySize);
    /// void setBriefingMapEntityImage(entity ship, int page_index, int keyframe_index, int entity_id, string radar_trace)
    /// Sets the radar trace image path of a pseudoentity on a briefing map keyframe.
    /// Example: setBriefingMapEntityImage(player, 1, 2, 1, "radar/adv_gunship.png")
    env.setGlobal("setBriefingMapEntityImage", &luaSetBriefingMapEntityImage);
    /// void setBriefingMapEntityColor(entity ship, int page_index, int keyframe_index, int entity_id, int r, int g, int b, int a)
    /// Sets the RGBA color of a pseudoentity on a briefing map keyframe. Values are 0-255.
    /// Example: setBriefingMapEntityColor(player, 1, 2, 1, 255, 0, 0, 255)
    env.setGlobal("setBriefingMapEntityColor", &luaSetBriefingMapEntityColor);
    /// void setBriefingMapEntityVisible(entity ship, int page_index, int keyframe_index, int entity_id, bool visible)
    /// Sets the visibility flag of a pseudoentity on a briefing map keyframe.
    /// Example: setBriefingMapEntityVisible(player, 1, 2, 1, false)
    env.setGlobal("setBriefingMapEntityVisible", &luaSetBriefingMapEntityVisible);
    /// void setBriefingMapEntityLabel(entity ship, int page_index, int keyframe_index, int entity_id, string label)
    /// Sets the label text of a pseudoentity on a briefing map keyframe.
    /// Example: setBriefingMapEntityLabel(player, 1, 2, 1, "Enemy Fleet")
    env.setGlobal("setBriefingMapEntityLabel", &luaSetBriefingMapEntityLabel);
    /// float getScenarioTime()
    /// Returns the elapsed time of the scenario, in seconds.
    /// This timer stops when the game is paused.
    /// Example: getScenarioTime() -- after 1 minute of the game being paused and 2 minutes of the game running, returns 120.0 (2 minutes)
    env.setGlobal("getScenarioTime", &luaGetScenarioTime);
    /// float getWallTime()
    /// Returns the elapsed wall time since scenario start, in seconds.
    /// This timer does *not* stop when the game is paused.
    /// Example: getWallTime() -- after 1 minute of the game being paused and 2 minutes of the game running, returns 180.0 (3 minutes)
    env.setGlobal("getWallTime", &luaGetWallTime);

    /// std::vector<sp::ecs::Entity> getAllObjects()
    /// Returns a list of all objects that have a position in the world.
    /// This can return a very long list and could slow down the game if called every tick.
    /// Example: getAllObjects()
    env.setGlobal("getAllObjects", &luaGetAllObjects);
    /// PVector<SpaceObject> getObjectsInRadius(float x, float y, float radius)
    /// Returns a list of all SpaceObjects within the given radius of the given x/y coordinates.
    /// Example: getObjectsInRadius(0,0,5000) -- returns all objects within 5U of 0,0
    env.setGlobal("getObjectsInRadius", &luaGetObjectsInRadius);
    /// PVector<SpaceObject> getEnemiesInRadiusFor(sp::ecs::Entity entity, float radius)
    /// Returns a list of all entities within the given radius that are enemies of the given entity
    /// Example: getEnemiesInRadiusFor(obj, 5000) -- returns all enemies within 5U of 0,0
    env.setGlobal("getEnemiesInRadiusFor", &luaGetEnemiesInRadiusFor);
    /// P<PlayerSpaceship> getPlayerShip(int index)
    /// Returns the PlayerSpaceship with the given index.
    /// PlayerSpaceships are 1-indexed.
    /// A new ship is assigned the lowest available index, and a destroyed ship leaves its index vacant.
    /// Pass -1 to return the first active player ship.
    /// Pass -2 to return the current player ship.
    /// Example: getPlayerShip(2) -- returns the second-indexed ship, if it exists
    env.setGlobal("getPlayerShip", &luaGetPlayerShip);
    /// PVector<PlayerSpaceship> getActivePlayerShips()
    /// Returns a 1-indexed list of active PlayerSpaceships.
    /// Unlike getPlayerShip()'s index, destroyed ships don't leave gaps.
    /// Example: getActivePlayerShips()[2] -- returns the second-indexed active ship
    env.setGlobal("getActivePlayerShips", &luaGetActivePlayerShips);
    /// string getGameLanguage()
    /// Returns the language as the string value of the language key in game preferences.
    /// Example: getGameLanguage() -- returns "en_US" if the game language is set to English (US)
    env.setGlobal("getGameLanguage", &luaGetGameLanguage);
    /// void setScenario(string script_name, std::optional<string> variation_name)
    /// Launches the given scenario, even if another scenario is running.
    /// Paths are relative to the scripts/ directory.
    /// Example: setScenario("scenario_03_waves.lua") -- launches the scenario at scripts/scenario_03_waves.lua
    env.setGlobal("setScenario", &luaSetScenario);
    /// void shutdownGame()
    /// Shuts down the server.
    /// Use to gracefully shut down a headless server.
    /// Example: shutdownGame()
    env.setGlobal("shutdownGame", &luaShutdownGame);
    /// void pauseGame()
    /// Pauses the game. Equivalent to setGameSpeed(0).
    /// Use to pause a headless server, which doesn't have access to the GM screen.
    /// Example: pauseGame() -- Sets the game speed to 0
    env.setGlobal("pauseGame", &luaPauseGame);
    /// void unpauseGame()
    /// Unpauses the game and sets the game speed to 1x.
    /// Use to unpause a headless server, which doesn't have access to the GM screen.
    /// Equivalent to if getGameSpeed() == 0 then setGameSpeed(1) end.
    /// Example: unpauseGame() -- Sets the game speed to 1x if paused
    env.setGlobal("unpauseGame", &luaUnpauseGame);
    /// void setGameSpeed(number speed)
    /// Sets the game speed multiplier. Valid values are 0 (paused), 0.1, 0.25, 0.5, 1, 2, 4, or 8.
    /// Use to set the game speed on a headless server, which doesn't have access to the GM screen.
    /// Example: setGameSpeed(4) -- Sets the game speed to 4x
    env.setGlobal("setGameSpeed", &luaSetGameSpeed);
    /// number getGameSpeed()
    /// Returns the game speed as a multiplier.
    /// Example: getGameSpeed() -- Returns 4 at 4x
    env.setGlobal("getGameSpeed", &luaGetGameSpeed);
    /// bool isGamePaused()
    /// Returns true if the game is paused. Equivalent to getGameSpeed() == 0.
    /// Example: local is_paused = isGamePaused()
    env.setGlobal("isGamePaused", &luaIsGamePaused);
    /// void playSoundFile(string filename)
    /// Plays the given audio file on the server.
    /// Paths are relative to the resources/ directory.
    /// Works with any file format supported by SDL, including .wav, .ogg, .flac.
    /// The sound is played only on the server, and not on any clients.
    /// Example: playSoundFile("sfx/laser.wav")
    env.setGlobal("playSoundFile", &luaPlaySoundFile);

    /// void applyDamageToEntity(entity target, number amount, table damage_info)
    /// Applies amount of damage to the target entity using the parameters in damage_info.
    /// damage_info is a table with optional fields:
    /// - instigator (entity; no default)
    /// - type (string "energy", "kinetic", or "emp"; no default)
    /// - x and y (world position of the hit; 0, 0 default)
    /// - frequency (integer energy beam frequency for shield matching, with 0 to 20 representing 400THz up at 20THz increments; no default)
    /// - system_target (string ESystem ship system name, no default)
    /// Example:
    /// -- Apply 50 energy damage at frequency 460THz to target's beam_weapons system, caused by player, at coordinates 1000,-500
    /// applyDamageToEntity(target, 50, {instigator = player, type = "energy", x = 1000, y = -500, frequency = 3, system_target = "beam_weapons"})
    env.setGlobal("applyDamageToEntity", &luaApplyDamageToEntity);

    /// void commandTargetRotation(entity ship, number rotation)
    /// Sets the target heading for the given ship's maneuvering thrusters, in degrees of rotation. (Rotation is heading + 90; 0 is east.)
    /// This is equivalent to clicking on the Helms screen's radar.
    /// Example:
    /// commandTargetRotation(getPlayerShip(-1), 90) -- turn the ship to face south (90 degrees clockwise from 0 rotation)
    env.setGlobal("commandTargetRotation", &luaCommandTargetRotation);
    /// void commandImpulse(entity ship, number request)
    /// Sets the impulse engine throttle for the given ship.
    /// Target is clamped to -1.0 (full reverse) to 1.0 (full ahead), with 0.0 stopping the engines.
    /// This is equivalent to clicking on the Helms screen's impulse control slider.
    /// Example:
    /// commandImpulse(getPlayerShip(-1), 1.0) -- set impulse to full ahead
    env.setGlobal("commandImpulse", &luaCommandImpulse);
    /// void commandWarp(entity ship, integer request)
    /// Sets the warp drive level for the given ship.
    /// Target is an integer from 0 (stopped) to the ship's maximum warp level (default 4).
    /// This is equivalent to clicking on the Helms screen's warp control slider.
    /// Example:
    /// commandWarp(getPlayerShip(-1), 2) -- engage warp factor 2
    env.setGlobal("commandWarp", &luaCommandWarp);
    /// void commandJump(entity ship, number distance)
    /// Initiates a jump drive jump of the given distance in world units (1000 = 1U).
    /// This is equivalent to setting a value on the Helms screen's jump control slider and clicking the Jump button.
    /// Example:
    /// commandJump(getPlayerShip(-1), 25000) -- initiate a 25U jump
    env.setGlobal("commandJump", &luaCommandJump);
    /// void commandAbortJump(entity ship)
    /// Aborts an active jump.
    /// This is equivalent to clicking the Helms screen's jump control Abort button.
    /// Example:
    /// commandAbortJump(getPlayerShip(-1))
    env.setGlobal("commandAbortJump", &luaCommandAbortJump);
    /// void commandSetTarget(entity ship, entity target)
    /// Sets the combat target for the given ship.
    /// This is equivalent to clicking a target on the Weapons screen's radar.
    /// Example:
    /// commandSetTarget(getPlayerShip(-1), enemy_ship)
    env.setGlobal("commandSetTarget", &luaCommandSetTarget);
    /// void commandSetScienceTarget(entity ship, entity target)
    /// Links the given entity to the science target analysis screen for the given ship.
    /// This is equivalent to selecting a target on the Science screen and clicking the Link to Analysis button.
    /// Example:
    /// commandSetScienceTarget(getPlayerShip(-1), enemy_ship)
    env.setGlobal("commandSetScienceTarget", &luaCommandSetScienceTarget);
    /// void commandLoadTube(entity ship, integer tube_index, string missile_type)
    /// Loads a missile of the given type into the given tube.
    /// tube_index is 0-based. The missile_type is the missile's name (e.g. "homing", "nuke").
    /// See the scripts/missileWeaponData.lua file for available missile types.
    /// This is equivalent to clicking a missile type on the Weapons screen's missile tubes control, and then click an empty tube.
    /// Example:
    /// commandLoadTube(getPlayerShip(-1), 0, "homing") -- load a homing missile into tube 0
    env.setGlobal("commandLoadTube", &luaCommandLoadTube);
    /// void commandUnloadTube(entity ship, integer tube_index)
    /// Unloads the missile from the given tube.
    /// tube_index is 0-based.
    /// This is equivalent to clicking the Unload button for a loaded tube on the Weapons screen's missile tubes control.
    /// Example:
    /// commandUnloadTube(getPlayerShip(-1), 0) -- unload tube 0
    env.setGlobal("commandUnloadTube", &luaCommandUnloadTube);
    /// void commandFireTube(entity ship, integer tube_index, number missile_target_angle)
    /// Fires the missile loaded in the given tube at the given angle, in degrees.
    /// tube_index is 0-based.
    /// If the ship has a combat target set, missiles with homing properties can acquire it.
    /// This is equivalent to disabling missile aim lock, selecting an angle, and then clicking a loaded tube on the Weapons screen's missile tubes control.
    /// Example:
    /// commandFireTube(getPlayerShip(-1), 0, 45.0) -- fire tube 0 toward 45 degrees
    env.setGlobal("commandFireTube", &luaCommandFireTube);
    /// void commandFireTubeAtTarget(entity ship, integer tube_index, entity target)
    /// Fires the missile loaded in the given tube, calculating the optimal intercept angle for the given target.
    /// tube_index is 0-based.
    /// If no intercept solution is found, fires in the tube's default direction instead.
    /// This is equivalent to clicking a loaded tube on the Weapons screen's missile tubes control.
    /// Example:
    /// commandFireTubeAtTarget(getPlayerShip(-1), 0, enemy_ship) -- fire tube 0 at enemy_ship
    env.setGlobal("commandFireTubeAtTarget", &luaCommandFireTubeAtTarget);
    /// void commandSetShields(entity ship, boolean active)
    /// Activates or deactivates the shields on the given ship.
    /// Has no effect if the shields are currently calibrating.
    /// This is equivalent to clicking the Weapons screen's Shields button.
    /// Example:
    /// commandSetShields(getPlayerShip(-1), true) -- raise shields
    env.setGlobal("commandSetShields", &luaCommandSetShields);
    /// void commandMainScreenSetting(entity ship, string setting)
    /// Sets the main screen view mode for the given ship.
    /// See EMainScreenSetting for valid setting values.
    /// This is equivalent to clicking a setting in the main screen controls selector.
    /// Example:
    /// commandMainScreenSetting(getPlayerShip(-1), "tactical") -- switch to tactical radar view
    env.setGlobal("commandMainScreenSetting", &luaCommandMainScreenSetting);
    /// void commandMainScreenOverlay(entity ship, string overlay)
    /// Sets the overlay displayed on top of the main screen view for the given ship.
    /// See EMainScreenOverlay for valid setting values.
    /// This is equivalent to clicking an overlay in the main screen controls selector.
    /// Example:
    /// commandMainScreenOverlay(getPlayerShip(-1), "showcomms") -- show comms overlay on main screen
    env.setGlobal("commandMainScreenOverlay", &luaCommandMainScreenOverlay);
    /// void commandScan(entity ship, entity target)
    /// Initiates a science scan of the given target by the given ship and resets the scanning delay timer to maximum.
    /// This is equivalent to clicking the Scan button on the Science screen.
    /// Example:
    /// commandScan(getPlayerShip(-1), unknown_station) -- begin scanning an entity assigned to unknown_station
    env.setGlobal("commandScan", &luaCommandScan);
    /// void commandSetSystemPowerRequest(entity ship, string system, number power_level)
    /// Sets the requested power level for the given system on the given ship.
    /// power_level is typically clamped to 0.0 to 3.0, where 1.0 is nominal. See ESystem for valid system values.
    /// This is equivalent to selecting a system on the Engineering screen and then clicking its power slider.
    /// Example:
    /// commandSetSystemPowerRequest(getPlayerShip(-1), "impulse", 1.5) -- overpower impulse engines to 150%
    env.setGlobal("commandSetSystemPowerRequest", &luaCommandSetSystemPowerRequest);
    /// void commandSetSystemCoolantRequest(entity ship, string system, number coolant_level)
    /// Sets the requested coolant level for the given system on the given ship.
    /// coolant_level is clamped to 0.0 and the ship's maximum coolant per system (typically 10.0). See ESystem for valid system values.
    /// Example:
    /// commandSetSystemCoolantRequest(getPlayerShip(-1), "reactor", 10.0) -- direct max coolant to reactor
    env.setGlobal("commandSetSystemCoolantRequest", &luaCommandSetSystemCoolantRequest);
    /// void commandDock(entity ship, entity station)
    /// Initiates docking the given ship with the given target, if the ship is within docking range.
    /// This is equivalent to clicking the Helms screen's request dock button.
    /// Example:
    /// commandDock(getPlayerShip(-1), friendly_station) -- docks with the entity assigned to friendly-station
    env.setGlobal("commandDock", &luaCommandDock);
    /// void commandUndock(entity ship)
    /// Requests the given ship to undock from its current docking target.
    /// This is equivalent to clicking the Helms screen's undock button.
    /// Example:
    /// commandUndock(getPlayerShip(-1))
    env.setGlobal("commandUndock", &luaCommandUndock);
    /// void commandAbortDock(entity ship)
    /// Aborts an in-progress docking approach for the given ship.
    /// This is equivalent to clicking the Helms screen's cancel docking button.
    /// Example:
    /// commandAbortDock(getPlayerShip(-1))
    env.setGlobal("commandAbortDock", &luaCommandAbortDock);
    /// void commandOpenTextComm(entity ship, entity target)
    /// Opens text communications from the given ship to the given entity.
    /// This is equivalent to selecting a target on the Relay screen and then clicking the open comms button.
    /// Example:
    /// commandOpenTextComm(getPlayerShip(-1), nearby_station)
    env.setGlobal("commandOpenTextComm", &luaCommandOpenTextComm);
    /// void commandCloseTextComm(entity ship)
    /// Closes any active text communications for the given ship.
    /// This is equivalent to clicking the close button on a comms panel on the Relay screen.
    /// Example:
    /// commandCloseTextComm(getPlayerShip(-1))
    env.setGlobal("commandCloseTextComm", &luaCommandCloseTextComm);
    /// void commandAnswerCommHail(entity ship, boolean answer)
    /// Accepts or declines an incoming communications hail for the given ship.
    /// Pass true to accept the hail, false to ignore it.
    /// This is equivalent to clicking the equivalent buttons in an incoming communications panel on the Relay screen.
    /// Example:
    /// commandAnswerCommHail(getPlayerShip(-1), true) -- accept the incoming hail
    env.setGlobal("commandAnswerCommHail", &luaCommandAnswerCommHail);
    /// void commandSendComm(entity ship, integer index)
    /// Selects a reply option by index in an active script-based communications dialogue for the given ship. If the ship has no active scripted comms, this does nothing.
    /// The index corresponds to the order in which reply options were added with addCommsReply().
    /// This is equivalent to clicking the equivalent buttons in a scripted comms panel on the Relay screen.
    /// Example:
    /// commandSendComm(getPlayerShip(-1), 0) -- select the first comms reply option
    env.setGlobal("commandSendComm", &luaCommandSendComm);
    /// void commandSendCommPlayer(entity ship, string message)
    /// Sends a free-form text message in an active player-to-player communications dialogue for the given ship. If the ship has no active chat comms, this does nothing.
    /// This is equivalent to entering a message into an active chat comms window on the Relay screen.
    /// Example:
    /// commandSendCommPlayer(getPlayerShip(-1), "Requesting permission to dock.")
    env.setGlobal("commandSendCommPlayer", &luaCommandSendCommPlayer);
    /// void commandSetAutoRepair(entity ship, boolean enabled)
    /// Enables or disables automatic repair crew assignment for the given ship.
    /// When enabled, repair crew are automatically sent to damaged systems.
    /// Example:
    /// commandSetAutoRepair(getPlayerShip(-1), true) -- enable auto-repair
    env.setGlobal("commandSetAutoRepair", &luaCommandSetAutoRepair);
    /// void commandSetBeamFrequency(entity ship, integer frequency)
    /// Sets the beam weapon frequency for the given ship.
    /// frequency is clamped to a value from 0 to 20.
    /// This is equivalent to selecting a frequency on the Weapons screen.
    /// Example:
    /// commandSetBeamFrequency(getPlayerShip(-1), 10) -- set beam frequency to 10
    env.setGlobal("commandSetBeamFrequency", &luaCommandSetBeamFrequency);
    /// void commandSetBeamSystemTarget(entity ship, string system)
    /// Sets the enemy ship system that beam weapons will preferentially target for the given ship. See ESystem for valid system values.
    /// This is equivalent to selecting a target ship system on the Weapons screen.
    /// Example:
    /// commandSetBeamSystemTarget(getPlayerShip(-1), "impulse") -- target enemy impulse engines with beams
    env.setGlobal("commandSetBeamSystemTarget", &luaCommandSetBeamSystemTarget);
    /// void commandSetShieldFrequency(entity ship, integer frequency)
    /// Sets the shield frequency for the given ship and begins shield recalibration.
    /// frequency is clamped to a value from 0 to 20. Shields are deactivated and cannot be raised until calibration completes. This has no effect if shields are already calibrating.
    /// This is equivalent to selecting a shield frequency on the Weapons screen and then clicking the calibrate button.
    /// Example:
    /// commandSetShieldFrequency(getPlayerShip(-1), 10) -- recalibrate shields to frequency 10
    env.setGlobal("commandSetShieldFrequency", &luaCommandSetShieldFrequency);
    /// void commandAddWaypoint(entity ship, number x, number y)
    /// Adds a new navigation waypoint at the given coordinates for the given ship.
    /// This has no effect if the ship already has a maximum number of waypoints defined (default 9).
    /// This is equivalent to clicking the Relay screen's create waypoint button and then clicking a location.
    /// Example:
    /// commandAddWaypoint(getPlayerShip(-1), 10000, -5000)
    env.setGlobal("commandAddWaypoint", &luaCommandAddWaypoint);
    /// void commandRemoveWaypoint(entity ship, integer index)
    /// Removes the waypoint at the given 0-based index (waypoint 1 = index 0) for the given ship.
    /// This is equivalent to selecting a waypoint on the Relay screen and then clicking the delete waypoint button.
    /// Example:
    /// commandRemoveWaypoint(getPlayerShip(-1), 0) -- remove the first waypoint
    env.setGlobal("commandRemoveWaypoint", &luaCommandRemoveWaypoint);
    /// void commandMoveWaypoint(entity ship, integer index, number x, number y)
    /// Moves the waypoint at the given 0-based index (waypoint 1 = index 0) to the given coordinates for the given ship.
    /// This is equivalent to clicking a waypoint on the Relay screen and dragging it to a new location.
    /// Example:
    /// commandMoveWaypoint(getPlayerShip(-1), 0, 15000, -5000) -- move the first waypoint to 15000, -5000
    env.setGlobal("commandMoveWaypoint", &luaCommandMoveWaypoint);
    /// void commandSetWaypointRoute(entity ship, bool is_route [, int set_id])
    /// Sets whether the given waypoint set is a route (waypoints connected as a path) or individual points.
    /// set_id defaults to 1 if not provided.
    /// Example:
    /// commandSetWaypointRoute(getPlayerShip(-1), true) -- connect waypoints as a route
    env.setGlobal("commandSetWaypointRoute", &luaCommandSetWaypointRoute);
    /// void commandActivateSelfDestruct(entity ship)
    /// Activates the self-destruct sequence for the given ship.
    /// Crew members must confirm the sequence with commandConfirmDestructCode() before it proceeds.
    /// This is equivalent to activating the self-destruction control on the Engineering screen.
    /// Example:
    /// commandActivateSelfDestruct(getPlayerShip(-1))
    env.setGlobal("commandActivateSelfDestruct", &luaCommandActivateSelfDestruct);
    /// void commandCancelSelfDestruct(entity ship)
    /// Cancels an active self-destruct sequence for the given ship before the countdown begins. Has no effect once the countdown has started.
    /// This is equivalent to cancelling the self-destruction control on the Engineering screen.
    /// Example:
    /// commandCancelSelfDestruct(getPlayerShip(-1))
    env.setGlobal("commandCancelSelfDestruct", &luaCommandCancelSelfDestruct);
    /// void commandConfirmDestructCode(entity ship, integer code_index, integer code)
    /// Submits a confirmation code for the self-destruct sequence on the given ship.
    /// code_index is 0-based (0 to 2). Has no effect if the code is incorrect or the sequence is not active.
    /// This is equivalent to entering the code on one of the crew screens.
    /// Example:
    /// commandConfirmDestructCode(getPlayerShip(-1), 0, 1234) -- submit code 1234 for confirmation slot 0
    env.setGlobal("commandConfirmDestructCode", &luaCommandConfirmDestructCode);
    /// void commandCombatManeuverBoost(entity ship, number amount)
    /// Triggers a combat maneuver boost for the given ship.
    /// amount is a value from 0.0 to 1.0.
    /// This is equivalent to pushing the Helms screen's combat maneuver control forward.
    /// Example:
    /// commandCombatManeuverBoost(getPlayerShip(-1), 1.0) -- full combat boost forward
    env.setGlobal("commandCombatManeuverBoost", &luaCommandCombatManeuverBoost);
    /// void commandCombatManeuverStrafe(entity ship, number amount)
    /// Triggers a combat maneuver strafe for the given ship.
    /// amount is a value from 0.0 to 1.0.
    /// This is equivalent to pushing the Helms screen's combat maneuver control left (-1.0) or right (1.0).
    /// Example:
    /// commandCombatManeuverStrafe(getPlayerShip(-1), 1.0) -- full combat boost right
    env.setGlobal("commandCombatManeuverStrafe", &luaCommandCombatManeuverStrafe);
    /// void commandLaunchProbe(entity ship, number x, number y)
    /// Launches a scan probe from the given ship toward the given coordinates.
    /// This is equivalent to clicking the Relay screen's launch probe button and then clicking a location.
    /// Example:
    /// commandLaunchProbe(getPlayerShip(-1), 30000, 10000)
    env.setGlobal("commandLaunchProbe", &luaCommandLaunchProbe);
    /// void commandSetScienceLink(entity ship, entity probe)
    /// Links the science station of the given ship to the given scan probe for extended radar range.
    /// This is equivalent to selecting a probe on the Relay screen and then clicking the link to science button.
    /// Example:
    /// commandSetScienceLink(getPlayerShip(-1), launched_probe) -- link the probe assigned to launched_probe
    env.setGlobal("commandSetScienceLink", &luaCommandSetScienceLink);
    /// void commandClearScienceLink(entity ship)
    /// Clears the science station's link to a scan probe for the given ship.
    /// This is equivalent to selecting the linked probe on the Relay screen and then clicking the link to science button.
    /// Example:
    /// commandClearScienceLink(getPlayerShip(-1)) -- clear any science link on this ship
    env.setGlobal("commandClearScienceLink", &luaCommandClearScienceLink);
    /// void commandSetDroneLink(entity ship, entity drone)
    /// Connects the given ship to the given entity as a drone.
    /// The drone entity must have the allow_drone_link component with this ship as its owner.
    /// For the local player ship, this sends a multiplayer command.
    /// For other ships, this modifies the component directly.
    /// This is equivalent to selecting a drone on the Drone Operations screen and clicking Connect.
    /// Example:
    /// commandSetDroneLink(getPlayerShip(-1), drone) -- connect drone to this ship
    env.setGlobal("commandSetDroneLink", &luaCommandSetDroneLink);
    /// void commandClearDroneLink(entity ship)
    /// Clears any active drone connection for the given ship.
    /// For the local player ship, this sends a multiplayer command.
    /// For other ships, this modifies the component directly.
    /// This is equivalent to clicking Disconnect on the Drone Operations screen.
    /// Example:
    /// commandClearDroneLink(getPlayerShip(-1)) -- disconnect any drone from this ship
    env.setGlobal("commandClearDroneLink", &luaCommandClearDroneLink);
    /// void commandSetAlertLevel(entity ship, string level)
    /// Sets the alert level for the given ship. See EAlertLevel for valid values.
    /// This is equivalent to clicking the Relay screen's alert level button and then selecting a level.
    /// Example:
    /// commandSetAlertLevel(getPlayerShip(-1), "Red alert") -- set red alert
    env.setGlobal("commandSetAlertLevel", &luaCommandSetAlertLevel);

    /// void setCustomUtilityBeamMode(entity ship, string name, int order, float energy_per_sec, float heat_per_sec, bool requires_target, function callback, function deactivate_callback)
    /// Defines or updates a custom utility beam mode for the given ship.
    /// If a mode with the same name already exists, its settings are updated; otherwise a new mode is added.
    /// Modes are sorted by the order value.
    ///
    /// callback signature: function callback(entity firing_entity, entity target_entity, float distance, float angle_diff)
    ///   Called every frame while the beam is actively firing. The callback should set is_firing to true on the firing entity if the beam hit something, so the beam effect is rendered.
    ///
    /// deactivate_callback signature: function deactivate_callback(entity firing_entity, entity target_entity)
    ///   Called once when the beam is deactivated. When requires_target is true, this is called once per entity in range of the firing entity.
    /// Example:
    /// setCustomUtilityBeamMode(ship, "Mining", 1, 10.0, 0.5, true, miningCallback, deactivateMiningCallback)
    env.setGlobal("setCustomUtilityBeamMode", &luaSetCustomUtilityBeamMode);
    /// void setCustomUtilityBeamModeProgress(entity ship, string name, float progress)
    /// Updates the progress value (0.0 to 1.0) for a named custom utility beam mode.
    /// Has no effect if no mode with the given name exists on the ship.
    /// Example:
    /// setCustomUtilityBeamModeProgress(ship, "Mining", 0.75) -- set progress to 75%
    env.setGlobal("setCustomUtilityBeamModeProgress", &luaSetCustomUtilityBeamModeProgress);
    /// void removeCustomUtilityBeamMode(entity ship, string name)
    /// Removes a named custom utility beam mode from the given ship.
    /// Has no effect if no mode with the given name exists on the ship.
    /// Example:
    /// removeCustomUtilityBeamMode(ship, "Mining") -- remove the mining beam mode
    env.setGlobal("removeCustomUtilityBeamMode", &luaRemoveCustomUtilityBeamMode);

    /// void transferPlayersFromShipToShip(entity source, entity target [, string station])
    /// Moves all connected player clients from source to target entities.
    /// If station is given, transfers only players at that crew position. See ECrewPosition for valid values.
    /// Has no effect if target is not a player-controlled ship.
    /// Example:
    /// transferPlayersFromShipToShip(old_ship, new_ship) -- move all crew to new_ship
    /// transferPlayersFromShipToShip(old_ship, new_ship, "helms") -- move only Helms players to new_ship's Helms
    env.setGlobal("transferPlayersFromShipToShip", &luaTransferPlayers);
    /// boolean hasPlayerCrewAtPosition(entity source, string station)
    /// Returns true if any connected player client is currently manning the given crew position on source.
    /// See ECrewPosition for valid station values.
    /// Example:
    /// if hasPlayerCrewAtPosition(getPlayerShip(-1), "weapons") then ... end
    env.setGlobal("hasPlayerCrewAtPosition", &luaHasPlayerAtPosition);
    /// table getPlayersInfo(entity source)
    /// Returns a table of connected player clients for source. Each entry has a "name" string and a
    /// "positions" table (an array of crew position strings). See ECrewPosition for position values.
    /// Example:
    /// for _, p in ipairs(getPlayersInfo(getPlayerShip(-1))) do print(p.name) end -- print the name of each player
    env.setGlobal("getPlayersInfo", &luaGetPlayersInfo);
    /// void setPlayerShipCustomFunction(entity ship, string type, string name, string caption, string|table positions, function callback, integer order)
    /// Adds or updates a custom function visible on crew screens for ship.
    /// type is "info", "button", or "message".
    /// name is a unique identifier. If a function with the same name exists, it's updated in place.
    /// positions is an ECrewPosition string or table of those strings.
    /// callback is called when the crew interacts with the function. Functions are displayed in ascending order.
    /// Example:
    /// setPlayerShipCustomFunction(ship, "button", "mine_asteroid", _("Mine asteroid"), "science", function() ... end, 1)
    env.setGlobal("setPlayerShipCustomFunction", &luaSetPlayerShipCustomFunction);
    /// void removePlayerShipCustomFunction(entity ship, string name)
    /// Removes the custom function with the given name from ship's crew screens. Has no effect if a function with the given name doesn't exist.
    /// Example:
    /// removePlayerShipCustomFunction(getPlayerShip(-1), "mine_asteroid") -- removes the mine asteroid button
    env.setGlobal("removePlayerShipCustomFunction", &luaRemovePlayerShipCustomFunction);
    /// void addEntryToShipsLog(entity ship, string entry, table color)
    /// Appends an entry to ship's relay log with the given color, which is an RGBA table {r, g, b, a} with component values from 0 to 255.
    /// Example:
    /// addEntryToShipsLog(getPlayerShip(-1), "Docking complete.", {0, 255, 0, 255}) -- adds the message with an opaque green color
    env.setGlobal("addEntryToShipsLog", &luaAddEntryToShipsLog);

    /// boolean isRadarBlockedFrom(table source, entity target, number short_range)
    /// Returns true if target is hidden from radar at the source coordinates due to the effect of a radar-blocking entity, such as a nebula.
    /// source is a world-position table {x, y}. Targets within short_range of source are never blocked.
    /// Targets with the NeverRadarBlocked component always return false.
    /// Example:
    /// -- Returns true if enemy can't be seen on a radar with 5U short range from coordinates px, py
    /// if isRadarBlockedFrom({px, py}, enemy, 5000) then ... end
    env.setGlobal("isRadarBlockedFrom", &RadarBlockSystem::isRadarBlockedFrom);
    /// number beamVsShieldFrequencyDamageFactor(integer beam_frequency, integer shield_frequency)
    /// Returns a damage multiplier for a beam at beam_frequency striking a shield at shield_frequency.
    /// The result ranges from about 0.5 to 1.5. Returns 1.0 if either frequency is unexpectedly negative.
    /// Example:
    /// local factor = beamVsShieldFrequencyDamageFactor(3, 5) -- 0.551..., the factor for beam freq 3 (460THz) vs. shield freq 5 (500THz)
    env.setGlobal("beamVsShieldFrequencyDamageFactor", &frequencyVsFrequencyDamageFactor);

    /// EScanningComplexity getScanningComplexity()
    /// Returns the running scenario's scanning complexity setting.
    /// Example: getScanningComplexity() -- returns "normal" by default
    env.setGlobal("getScanningComplexity", &luaGetScanningComplexity);
    /// int getHackingDifficulty()
    /// Returns the running scenario's hacking difficulty setting.
    /// The returned value is an integer between 0 and 3:
    /// 0 = Simple
    /// 1 = Normal
    /// 2 = Difficult (default)
    /// 3 = Fiendish
    /// Example: getHackingDifficulty() -- returns 2 by default
    env.setGlobal("getHackingDifficulty", &luaGetHackingDifficulty);
    /// EHackingGames getHackingGames()
    /// Returns the running scenario's hacking difficulty setting.
    /// Example: getHackingGames() -- returns "all" by default
    env.setGlobal("getHackingGames", &luaGetHackingGames);
    /// bool areBeamShieldFrequenciesUsed()
    /// Returns whether the "Beam/Shield Frequencies" setting is enabled in the running scenario.
    /// Example: areBeamShieldFrequenciesUsed() -- returns true by default
    env.setGlobal("areBeamShieldFrequenciesUsed", &luaAreBeamShieldFrequenciesUsed);
    /// bool isPerSystemDamageUsed()
    /// Returns whether the "Per-System Damage" setting is enabled in the running scenario.
    /// Example: isPerSystemDamageUsed() -- returns true by default
    env.setGlobal("isPerSystemDamageUsed", &luaIsPerSystemDamageUsed);
    /// bool isTacticalRadarAllowed()
    /// Returns whether the "Tactical Radar" setting for main screens is enabled in the running scenario.
    /// Example: isTacticalRadarAllowed() -- returns true by default
    env.setGlobal("isTacticalRadarAllowed", &luaIsTacticalRadarAllowed);
    /// bool isLongRangeRadarAllowed()
    /// Returns whether the "Long Range Radar" setting for main screens is enabled in the running scenario.
    /// Example: isLongRangeRadarAllowed() -- returns true by default
    env.setGlobal("isLongRangeRadarAllowed", &luaIsLongRangeRadarAllowed);
    /// bool isStrategicMapAllowed()
    /// Returns whether the "Strategic Map" setting for main screens is enabled in the running scenario.
    /// Example: isStrategicMapAllowed() -- returns true by default
    env.setGlobal("isStrategicMapAllowed", &luaIsStrategicMapAllowed);
    /// bool areMissilesOnLongRangeRadar()
    /// Returns whether the "Long-range missile visibility" setting is enabled in the running scenario.
    /// Example: areMissilesOnLongRangeRadar() -- returns false by default
    env.setGlobal("areMissilesOnLongRangeRadar", &luaAreMissilesOnLongRangeRadar);

    /// void addGMFunction(string label, function callback)
    /// Adds a button with the given label to the GM screen. Clicking it calls the callback function.
    /// Example:
    /// addGMFunction("Spawn enemy", function() CpuShip():setFaction("Kraylor"):... end) -- adds a GM screen button to spawn a Kraylor-faction ship
    env.setGlobal("addGMFunction", &luaAddGMFunction);
    /// void clearGMFunctions()
    /// Removes all buttons previously added to the GM screen via addGMFunction().
    /// Example:
    /// clearGMFunctions()
    env.setGlobal("clearGMFunctions", &luaClearGMFunctions);

    /// ScriptObject Script()
    /// Creates a new independent Lua script environment as a child of the current one.
    /// The returned ScriptObject has two methods:
    /// - run(filename) loads and executes the given script file, then calls its init() function if it exists.
    /// - setVariable(name, value) sets a global in that environment. Value can be a string, number, or entity.
    /// Example:
    /// -- Run my_subscript.lua, assigning and passing the first player ship to the subscript's variable player
    /// local sub = Script()
    /// sub:setVariable("player", getPlayerShip(-1))
    /// sub:run("my_subscript.lua")
    env.setGlobal("Script", &luaCreateAdditionalScript);

    /// void setCommsMessage(string message)
    /// Sets the content of an accepted hail, or in a comms reply.
    /// If no message is set, attempting to open comms results in "no reply", or a dialogue with the message "?" in a reply.
    /// Use this only in replies (addCommsReply()), comms scripts (SpaceObject:setCommsScript()), or comms functions (SpaceObject:setCommsFunction()).
    /// When used in the callback function of addCommsReply(), this clears all existing replies.
    /// Example:
    /// -- Send a greeting upon hail if the player is friendly with the comms target
    /// function friendlyComms()
    ///   if comms_source:isFriendly(comms_target) then
    ///     setCommsMessage("Hello, friend!")
    ///   else
    ///     setCommsMessage("Who are you?")
    ///   end
    /// end
    /// -- When some_ship is hailed, run friendlyComms() with some_ship as the comms_target and the player as the comms_source
    /// some_ship:setCommsFunction(friendlyComms)
    env.setGlobal("setCommsMessage", &CommsSystem::luaSetCommsMessage);
    /// void addCommsReply(string message, ScriptSimpleCallback callback)
    /// Adds a selectable reply option to a communications dialogue as a button with the given text.
    /// When clicked, the button calls the given function.
    /// Use this only after comms messages (setCommsMessage() in comms scripts (SpaceObject:setCommsScript()), or comms functions (SpaceObject:setCommsFunction()).
    /// Comms scripts pass global variables `comms_target` and `comms_source`. See SpaceObject:setCommsScript().
    /// Comms functions pass only `comms_source`. See SpaceObject:setCommsFunction().
    /// Instead of using these globals, the callback function can take two parameters.
    /// To present multiple options in one comms message, call addCommsReply() for each option.
    /// To create a dialogue tree, run setCommsMessage() inside the addCommsReply() callback, then add new comms replies.
    /// Example:
    /// if comms_source:isFriendly(comms_target) then
    ///   setCommsMessage("Hello, friend!")
    ///   addCommsReply("Can you send a supply drop?", function(comms_source, comms_target) ... end) -- runs the given function when selected
    ///   ...
    /// Deprecated: In a comms script, `player` can also be used for `comms_source`.
    env.setGlobal("addCommsReply", &CommsSystem::luaAddCommsReply);
    /// void commsSwitchToGM()
    /// Switches a PlayerSpaceship communications dialogue from a comms script/function to interactive chat with the GM.
    /// When triggered, this opens a comms chat window on both the player crew's screen and GM console.
    /// Use this in a communication callback function, such as addCommsReply() or SpaceObject:setCommsFunction().
    /// Example:
    /// if comms_source:isFriendly(comms_target) then
    ///   setCommsMessage("Hello, friend!")
    ///   addCommsReply("I want to speak to your manager!", function() commsSwitchToGM() end) -- launches a GM chat when selected
    ///   ...
    env.setGlobal("commsSwitchToGM", &CommsSystem::luaCommsSwitchToGM);

    /// string toJSON(data)
    /// Returns a json string with the input data converted to json.
    env.setGlobal("toJSON", &luaToJSON);
    /// table/value fromJSON(data)
    /// Returns a table/value converted from a json string
    env.setGlobal("fromJSON", &luaFromJSON);

    /// integer getEEVersion()
    /// Returns the running EmptyEpsilon build version as an integer.
    /// Example:
    /// local ver = getEEVersion() -- returns 20241208 if the EmptyEpsilon version is 2024.12.08
    env.setGlobal("getEEVersion", &luaGetEEVersion);
    registerScriptDataStorageFunctions(env);
    registerScriptGMFunctions(env);
    registerScriptRandomFunctions(env);

    /// entity entityFromString(string id)
    /// Converts a string entity ID (from entity:toString()) back to an entity reference.
    /// Useful when passing entity references through CMD_RUN_SCRIPT.
    env.setGlobal("entityFromString", &luaEntityFromString);

    /// entity findFaction(string name)
    /// Returns the FactionInfo entity for the given faction name (e.g. "Human Navy", "Exuari").
    /// Useful when changing an entity's faction via CMD_RUN_SCRIPT.
    env.setGlobal("findFaction", &luaFindFaction);

    /// entity findMissileWeaponData(string name)
    /// Returns the MissileWeaponData entity for the given missile type name (e.g. "Homing", "Nuke").
    /// Useful when querying or modifying missile weapon data via CMD_RUN_SCRIPT.
    env.setGlobal("findMissileWeaponData", &luaFindMissileWeaponData);

    /// void rebuildMissileWeaponData()
    /// Rebuilds the internal missile weapon data registry index.
    /// Call this after adding or removing MissileWeaponData entities mid-game to update the type list.
    env.setGlobal("rebuildMissileWeaponData", &luaRebuildMissileWeaponData);

    /// int getWeaponStorage(entity entity, string type_name)
    /// Returns the current stock of the given missile type on the given entity.
    /// Works with entities that have MissileTubes or PickupCallback components.
    env.setGlobal("getWeaponStorage", &luaGetWeaponStorageImpl);

    /// void setWeaponStorage(entity entity, string type_name, int amount)
    /// Sets the stock of the given missile type on the given entity.
    /// Clamps to the entity's storage_max for that type. Works with MissileTubes and PickupCallback.
    env.setGlobal("setWeaponStorage", &luaSetWeaponStorageImpl);

    /// int getWeaponStorageMax(entity entity, string type_name)
    /// Returns the maximum stock capacity for the given missile type on the given entity.
    env.setGlobal("getWeaponStorageMax", &luaGetWeaponStorageMaxImpl);

    /// void setWeaponStorageMax(entity entity, string type_name, int amount)
    /// Sets the maximum stock capacity for the given missile type. Caps current stock if it exceeds the new max.
    env.setGlobal("setWeaponStorageMax", &luaSetWeaponStorageMaxImpl);

    /// bool weaponTubeAllowMissile(entity entity, int mount_index, string type_name)
    /// Returns whether the given missile type is allowed in the specified tube mount.
    env.setGlobal("weaponTubeAllowMissile", &luaWeaponTubeAllowMissileImpl);

    /// void setWeaponTubeAllowMissile(entity entity, int mount_index, string type_name, bool allowed)
    /// Sets whether the given missile type is allowed in the specified tube mount.
    env.setGlobal("setWeaponTubeAllowMissile", &luaSetWeaponTubeAllowMissileImpl);

    /// void setWeaponTubeExclusive(entity entity, int mount_index, string type_name)
    /// Clears all allowed types for the mount, then allows only the specified type.
    env.setGlobal("setWeaponTubeExclusive", &luaSetWeaponTubeExclusiveImpl);

    // Load hardcoded script files.
    // Lua standard library extensions.
    auto res = env.runFile<void>("luax.lua");
    LuaConsole::checkResult(res);
    if (res.isErr()) return false;

    // EmptyEpsilon Lua APIs.
    res = env.runFile<void>("api/all.lua");
    LuaConsole::checkResult(res);
    if (res.isErr()) return false;

    return true;
}
