#include <i18n.h>
#include "menus/luaConsole.h"
#include "gameGlobalInfo.h"
#include "preferenceManager.h"
#include "scenarioInfo.h"
#include "multiplayer_client.h"
#include "soundManager.h"
#include "random.h"
#include "config.h"
#include "components/collision.h"
#include "systems/collision.h"
#include "ecs/query.h"
#include "menus/luaConsole.h"
#include "playerInfo.h"
#include <SDL_assert.h>

P<GameGlobalInfo> gameGlobalInfo;

REGISTER_MULTIPLAYER_CLASS(GameGlobalInfo, "GameGlobalInfo")
GameGlobalInfo::GameGlobalInfo()
: MultiplayerObject("GameGlobalInfo")
{
    SDL_assert(!gameGlobalInfo);

    callsign_counter = 0;
    gameGlobalInfo = this;

    global_message_timeout = 0.0;
    scanning_complexity = SC_Normal;
    hacking_difficulty = 2;
    hacking_games = HG_All;
    use_beam_shield_frequencies = true;
    use_system_damage = true;
    allow_main_screen_tactical_radar = true;
    allow_main_screen_long_range_radar = true;
    gm_control_code = "";
    elapsed_time = 0.0f;

    intercept_all_comms_to_gm = false;

    registerMemberReplication(&scanning_complexity);
    registerMemberReplication(&hacking_difficulty);
    registerMemberReplication(&hacking_games);
    registerMemberReplication(&global_message);
    registerMemberReplication(&global_message_timeout, 1.0);
    registerMemberReplication(&banner_string);
    registerMemberReplication(&victory_faction);
    registerMemberReplication(&use_beam_shield_frequencies);
    registerMemberReplication(&use_system_damage);
    registerMemberReplication(&allow_main_screen_tactical_radar);
    registerMemberReplication(&allow_main_screen_long_range_radar);
    registerMemberReplication(&gm_control_code);
    registerMemberReplication(&elapsed_time, 0.1);
    registerMemberReplication(&default_skybox);
}

//due to a suspected compiler bug this deconstructor needs to be explicitly defined
GameGlobalInfo::~GameGlobalInfo()
{
}

void GameGlobalInfo::onReceiveServerCommand(sp::io::DataBuffer& packet)
{
    int16_t command;
    packet >> command;
    switch(command)
    {
    case CMD_PLAY_CLIENT_SOUND:{
        CrewPosition position;
        string sound_name;
        sp::ecs::Entity entity;
        packet >> entity >> position >> sound_name;
        if (my_spaceship == entity && my_player_info)
        {
            if ((position == CrewPosition::MAX && my_player_info->main_screen) || my_player_info->hasPosition(position))
            {
                soundManager->playSound(sound_name);
            }
        }
        }break;
    }
}

void GameGlobalInfo::playSoundOnMainScreen(sp::ecs::Entity ship, string sound_name)
{
    sp::io::DataBuffer packet;
    packet << CMD_PLAY_CLIENT_SOUND << ship << CrewPosition::MAX << sound_name;
    broadcastServerCommand(packet);
}

void GameGlobalInfo::update(float delta)
{
    if (global_message_timeout > 0.0f)
    {
        global_message_timeout -= delta;
    }
    if (my_player_info)
    {
        //Set the my_spaceship variable based on the my_player_info->ship_id
        if (my_spaceship != my_player_info->ship)
            my_spaceship = my_player_info->ship;
    }
    elapsed_time += delta;

    if (main_scenario_script && main_script_error_count < max_repeated_script_errors) {
        auto res = main_scenario_script->call<void>("update", delta);
        if (res.isErr() && res.error() != "Not a function") {
            LuaConsole::checkResult(res);
            main_script_error_count += 1;
            if (main_script_error_count == max_repeated_script_errors) {
                LuaConsole::addLog("5 repeated script update errors, stopping updates.");
            }
        } else {
            main_script_error_count = 0;
        }
    }
    for(auto& as : additional_scripts) {
        auto res = as->call<void>("update", delta);
        if (res.isErr() && res.error() != "Not a function")
            LuaConsole::checkResult(res);
    }
}

string GameGlobalInfo::getNextShipCallsign()
{
    callsign_counter += 1;
    switch(irandom(0, 9))
    {
    case 0: return "S" + string(callsign_counter);
    case 1: return "NC" + string(callsign_counter);
    case 2: return "CV" + string(callsign_counter);
    case 3: return "SS" + string(callsign_counter);
    case 4: return "VS" + string(callsign_counter);
    case 5: return "BR" + string(callsign_counter);
    case 6: return "CSS" + string(callsign_counter);
    case 7: return "UTI" + string(callsign_counter);
    case 8: return "VK" + string(callsign_counter);
    case 9: return "CCN" + string(callsign_counter);
    }
    return "SS" + string(callsign_counter);
}

void GameGlobalInfo::execScriptCode(const string& code)
{
    if (main_scenario_script) {
        auto res = main_scenario_script->run<sp::script::CaptureAllResults>("return " + code);
        if (res.isErr() && res.error().find('\n') < 0) // Errors without a traceback are parse errors, so we can try without the return.
            res = main_scenario_script->run<sp::script::CaptureAllResults>(code);
        LuaConsole::checkResult(res);
        for(const auto& s : res.value().result)
            LuaConsole::addLog(s);
    }
}

bool GameGlobalInfo::allowNewPlayerShips()
{
    auto res = main_scenario_script->call<bool>("allowNewPlayerShips");
    LuaConsole::checkResult(res);
    return res.value();
}

namespace sp::script {
    template<> struct Convert<std::vector<GameGlobalInfo::ShipSpawnInfo>> {
        static std::vector<GameGlobalInfo::ShipSpawnInfo> fromLua(lua_State* L, int idx) {
            std::vector<GameGlobalInfo::ShipSpawnInfo> result{};
            if (lua_istable(L, idx)) {
                for(int index=1; lua_geti(L, idx, index) == LUA_TTABLE; index++) {
                    lua_geti(L, -1, 1); auto callback = Convert<sp::script::Callback>::fromLua(L, -1); lua_pop(L, 1);
                    lua_geti(L, -1, 2); auto label = lua_tostring(L, -1); lua_pop(L, 1);
                    lua_geti(L, -1, 3); auto description = lua_tostring(L, -1); lua_pop(L, 1);
                    lua_geti(L, -1, 4); auto icon = lua_tostring(L, -1); lua_pop(L, 1);
                    lua_pop(L, 1);
                    result.push_back({callback, label ? label : "", description ? description : "", icon ? icon : ""});
                }
                lua_pop(L, 1);
            }
            return result;
        }
    };
}
std::vector<GameGlobalInfo::ShipSpawnInfo> GameGlobalInfo::getSpawnablePlayerShips()
{
    std::vector<GameGlobalInfo::ShipSpawnInfo> info;
    if (main_scenario_script) {
        auto res = main_scenario_script->call<std::vector<GameGlobalInfo::ShipSpawnInfo>>("getSpawnablePlayerShips");
        LuaConsole::checkResult(res);
        if (res.isOk())
            info = res.value();
    }
    return info;
}
namespace sp::script {
    template<> struct Convert<std::vector<GameGlobalInfo::ObjectSpawnInfo>> {
        static std::vector<GameGlobalInfo::ObjectSpawnInfo> fromLua(lua_State* L, int idx) {
            std::vector<GameGlobalInfo::ObjectSpawnInfo> result{};
            if (lua_istable(L, idx)) {
                for(int index=1; lua_geti(L, idx, index) == LUA_TTABLE; index++) {
                    lua_geti(L, -1, 1); auto callback = Convert<sp::script::Callback>::fromLua(L, -1); lua_pop(L, 1);
                    lua_geti(L, -1, 2); auto label = lua_tostring(L, -1); lua_pop(L, 1);
                    lua_geti(L, -1, 3); auto category = lua_tostring(L, -1); lua_pop(L, 1);
                    lua_geti(L, -1, 4); auto description = lua_tostring(L, -1); lua_pop(L, 1);
                    lua_geti(L, -1, 5); auto icon = lua_tostring(L, -1); lua_pop(L, 1);
                    lua_pop(L, 1);
                    result.push_back({callback, label ? label : "", category ? category : "", description ? description : "", icon ? icon : ""});
                }
                lua_pop(L, 1);
            }
            return result;
        }
    };
}

std::vector<GameGlobalInfo::ObjectSpawnInfo> GameGlobalInfo::getGMSpawnableObjects()
{
    std::vector<GameGlobalInfo::ObjectSpawnInfo> info;
    if (main_scenario_script) {
        auto res = main_scenario_script->call<std::vector<GameGlobalInfo::ObjectSpawnInfo>>("getSpawnableGMObjects");
        LuaConsole::checkResult(res);
        if (res.isOk())
            info = res.value();
    }
    return info;
}

string GameGlobalInfo::getEntityExportString(sp::ecs::Entity entity)
{
    if (main_scenario_script) {
        auto res = main_scenario_script->call<string>("getEntityExportString", entity);
        LuaConsole::checkResult(res);
        if (res.isOk())
            return res.value();
    }
    return "";
}

void GameGlobalInfo::reset()
{
    if (state_logger)
        state_logger->destroy();

    gm_callback_functions.clear();
    gm_messages.clear();
    on_gm_click = nullptr;
    on_gm_click_cursor = DEFAULT_ON_GM_CLICK_CURSOR;

    sp::ecs::Entity::destroyAllEntities();
    main_scenario_script = nullptr;
    additional_scripts.clear();
    script_environment_base = nullptr;

    elapsed_time = 0.0f;
    callsign_counter = 0;
    global_message = "";
    global_message_timeout = 0.0f;
    banner_string = "";
    default_skybox = "default";

    //Pause the game
    engine->setGameSpeed(0.0);

    foreach(PlayerInfo, p, player_info_list)
    {
        p->reset();
    }
}

void GameGlobalInfo::setScenarioSettings(const string filename, std::unordered_map<string, string> new_settings)
{
    // Use the parsed scenario metadata.
    ScenarioInfo info(filename);

    // Set the scenario name.
    gameGlobalInfo->scenario = info.name;
    LOG(INFO) << "Configuring settings for scenario " << gameGlobalInfo->scenario;

    // Set each scenario setting to either a matching passed new value, or the
    // default if there's no match (or no new value).
    for(auto& setting : info.settings)
    {
        // Initialize with defaults.
        gameGlobalInfo->scenario_settings[setting.key] = setting.default_option;

        // If new settings were passed ...
        if (!new_settings.empty())
        {
            // ... confirm that this setting key exists in the new settings.
            if (new_settings.find(setting.key) != new_settings.end())
            {
                if (new_settings[setting.key] != "")
                {
                    // If so, override the default with the new value.
                    gameGlobalInfo->scenario_settings[setting.key] = new_settings[setting.key];
                }
            }
        }

        // Log scenario setting confirmation.
        LOG(INFO) << setting.key << " scenario setting set to " << gameGlobalInfo->scenario_settings[setting.key];
    }
}

void GameGlobalInfo::startScenario(string filename, std::unordered_map<string, string> new_settings)
{
    reset();

    i18n::reset();
    i18n::load("locale/main." + PreferencesManager::get("language", "en") + ".po");
    i18n::load("locale/comms_ship." + PreferencesManager::get("language", "en") + ".po");
    i18n::load("locale/comms_station." + PreferencesManager::get("language", "en") + ".po");
    i18n::load("locale/factionInfo." + PreferencesManager::get("language", "en") + ".po");
    i18n::load("locale/science_db." + PreferencesManager::get("language", "en") + ".po");
    i18n::load("locale/" + filename.replace(".lua", "." + PreferencesManager::get("language", "en") + ".po"));

    script_environment_base = std::make_unique<sp::script::Environment>();
    main_script_error_count = 0;
    if (setupScriptEnvironment(*script_environment_base.get())) {
        auto res = script_environment_base->runFile<void>("model_data.lua");
        LuaConsole::checkResult(res);
        if (!res.isErr()) {
            res = script_environment_base->runFile<void>("factionInfo.lua");
            LuaConsole::checkResult(res);
        }
        if (!res.isErr()) {
            res = script_environment_base->runFile<void>("shipTemplates.lua");
            LuaConsole::checkResult(res);
        }
        if (!res.isErr()) {
            res = script_environment_base->runFile<void>("science_db.lua");
            LuaConsole::checkResult(res);
        }
    }

    main_scenario_script = std::make_unique<sp::script::Environment>(script_environment_base.get());
    setupSubEnvironment(*main_scenario_script.get());
    //TODO: int max_cycles = PreferencesManager::get("script_cycle_limit", "0").toInt();
    //TODO: if (max_cycles > 0)
    //TODO:     script->setMaxRunCycles(max_cycles);

    // Initialize scenario settings.
    setScenarioSettings(filename, new_settings);

    auto res = main_scenario_script->runFile<void>(filename);
    LuaConsole::checkResult(res);
    if (res.isOk() && main_scenario_script->isFunction("init")) {
        res = main_scenario_script->call<void>("init");
        LuaConsole::checkResult(res);
        if (res.isErr()) {
            main_script_error_count = max_repeated_script_errors;
            LuaConsole::addLog("init() function failed, not going to call update()");
        }
    }

    if (PreferencesManager::get("game_logs", "1").toInt())
    {
        state_logger = new GameStateLogger();
        state_logger->start();
    }
}

void GameGlobalInfo::destroy()
{
    reset();
    MultiplayerObject::destroy();
}

string GameGlobalInfo::getMissionTime() {
    unsigned int seconds = gameGlobalInfo->elapsed_time;
    unsigned int minutes = (seconds / 60) % 60;
    unsigned int hours = (seconds / 60 / 60) % 24;
    seconds = seconds % 60;
    char buf[9];
    std::snprintf(buf, 9, "%02d:%02d:%02d", hours, minutes, seconds);
    return string(buf);
}

string getSectorName(glm::vec2 position)
{
    constexpr float subsector_size = 20000.0f;
    constexpr float sector_size = subsector_size * 5.0f;
    constexpr float supersector_size = sector_size * 5.0f;

    /*  Subsectors are 20000 by 20000 square.
        Sectors are 5 subsectors by 5 subsectors square.
        Supersectors are 5 sectors by 5 sectors square.
        Subsectors are 1-indexed, row-first.
        Sectors are alphabetically indexed, row-first.
        Supersectors are alphabetically indexed, row-first.

        if position.x = 1000 and position.y = 10000
            subsector index should be 1 (top-left)
            sector index should be A (top-left subsector in sector)
            supersector index should be A (sector A is top-left sector in supersector)
            label should be A:A1

        if position.x = 21000 and position.y = 21000
            subsector index should be 7 (1 right and 1 down from top-left)
            sector index should be A (same sector as A:A1)
            supersector index should be A (same supersector A:A1)
            label should be A:A7

        if position.x = 501000 and position.y = 501000
            subsector index should be 1 (top-left subsector)
            sector index should be A (subsector 1 is top-left subsector in sector)
            supersector index should be B (1 right and 0 down from top-left)
            label should be B:A1

        ------------------------- 500000 wide ------------------------- | -- next supersector starts
        -------- 100000 wide --------
        A:A01 A:A02 A:A03 A:A04 A:A05 ... A:E01 A:E02 A:E03 A:E04 A:E05 | B:A01 ...
        A:A06 A:A07 A:A08 A:A09 A:A10 ... A:E06 A:E07 A:E08 A:E09 A:E10 | B:A06 ...
        A:A11 A:A12 A:A13 A:A14 A:A15 ... A:E11 A:E12 A:E13 A:E14 A:E15 | B:A11 ...
        A:A16 A:A17 A:A18 A:A19 A:A20 ... A:E16 A:E17 A:E18 A:E19 A:E20 | B:A16 ...
        A:A21 A:A22 A:A23 A:A24 A:A25 ... A:E21 A:E22 A:E23 A:E24 A:E25 | B:A21 ...
        ...                          A:M13                          ... | ...
        A:U01 A:U02 A:U03 A:U04 A:U05 ... A:Y01 A:Y02 A:Y03 A:Y04 A:Y05 | B:U01 ...
        A:U06 A:U07 A:U08 A:U09 A:U10 ... A:Y06 A:Y07 A:Y08 A:Y09 A:Y10 | B:U06 ...
        A:U11 A:U12 A:U13 A:U14 A:U15 ... A:Y11 A:Y12 A:Y13 A:Y14 A:Y15 | B:U11 ...
        A:U16 A:U17 A:U18 A:U19 A:U20 ... A:Y16 A:Y17 A:Y18 A:Y19 A:Y20 | B:U16 ...
        A:U21 A:U22 A:U23 A:U24 A:U25 ... A:Y21 A:Y22 A:Y23 A:Y24 A:Y25 | B:U21 ...

        equivalent to integer supersector indices:

        -------------------- 500000 wide --------------------- | -- next supersector starts
        ----- 100000 wide ------ .... ----- 100000 wide ------ |
        0001 0002 0003 0004 0005 .... 0021 0022 0023 0024 0025 | 0626 
        0026 0027 0028 0029 0030 .... 0046 0047 0048 0049 0050 | ...
row 1   0051 0052 0053 0054 0055 .... 0071 0072 0073 0074 0075 | ...
        0076 0077 0078 0079 0080 .... 0096 0097 0098 0099 0100 | ...
        0101 0102 0103 0104 0105 .... 0121 0122 0123 0124 0125 | ...
rows 2-4 ...                     0313                          | ... 
        0501 0502 0503 0504 0505 .... 0521 0522 0523 0524 0025 | ...
        0526 0527 0528 0529 0530 .... 0546 0547 0548 0549 0050 | ...
row 5   0551 0552 0553 0554 0555 .... 0571 0572 0573 0574 0075 | ...
        0576 0577 0578 0579 0580 .... 0596 0597 0598 0599 0600 | ...
        0601 0602 0603 0604 0605 .... 0621 0622 0623 0624 0625 | ... 1250

        Supersectors (M is "home" and typically lacks prefix)
        ---------------------------- 12.5m wide -----------------------------
                                     |2.5m wide|
rows 1-2                                 ...
        KA KB KC KD KE|LA LB LC LD LE|A B C D E|NA NB NC ND NE|OA OB OC OD OE
        KF KG KH KI KJ|LF LG LH LI LJ|F G H I J|NF NG NH NI NJ|OF OG OH OI OJ
row 3   KK KL KM KN KO|LK LL LM LN LO|K L(M)N O|NK NL NM NN NO|OK OL OM ON OO
        KP KQ KR KS KT|LP LQ LR LS LT|P Q R S T|NP NQ NR NS NT|OP OQ OR OS OT
        KU KV KW KX KY|LU LV LW LX LY|U V W X Y|NU NV NW NX NY|OU OV OW OX OY
rows 4-5                                 ...

(top-left of A:A1 should be engine -6250000,-6250000; further prepends lower-z backwards)
(center of M:M13 should be engine 0,0)
(bottom-right of Y:Y25 should be engine +6250000,+6250000; further prepends upper-Z backwards)

*/
    // return supersector_index + ":" + sector_index + string(subsector_index);
    return "";
}
