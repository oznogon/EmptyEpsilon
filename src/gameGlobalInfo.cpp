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
    enable_multiple_waypoint_sets = false;
    enable_waypoint_routes = false;
    use_drone_energy_drain = false;
    missiles_on_long_range_radar = false;
    collision_damage_factor = 0.0f;
    allow_main_screen_tactical_radar = true;
    allow_main_screen_long_range_radar = true;
    allow_main_screen_strategic_map = true;
    gm_control_code = "";
    elapsed_time = 0.0f;
    elapsed_delta = 0.0f;

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
    registerMemberReplication(&enable_multiple_waypoint_sets);
    registerMemberReplication(&enable_waypoint_routes);
    registerMemberReplication(&use_drone_energy_drain);
    registerMemberReplication(&missiles_on_long_range_radar);
    registerMemberReplication(&collision_damage_factor);
    registerMemberReplication(&allow_main_screen_tactical_radar);
    registerMemberReplication(&allow_main_screen_long_range_radar);
    registerMemberReplication(&allow_main_screen_strategic_map);
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

/*!
 * \brief Set a faction to victorious.
 * \param string Name of the faction that won.
 */
void GameGlobalInfo::setVictory(string faction_name)
{
    victory_faction = Faction::find(faction_name);
    if (!victory_faction)
        LOG(Error, "Attempted to set victory faction to ", faction_name, ", but no faction name matched.");
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
    script_threads.insert(script_threads.end(), new_script_threads.begin(), new_script_threads.end());
    new_script_threads.clear();
    for(auto it = script_threads.begin(); it != script_threads.end(); )
    {
        auto res = (*it)->resume(delta);
        LuaConsole::checkResult(res);
        if (res.isErr() || !res.value()) {
            it = script_threads.erase(it);
        } else {
            ++it;
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
    if (main_scenario_script)
    {
        auto res = main_scenario_script->run<sp::script::CaptureAllResults>("return " + code);

        // Errors without a traceback are parse errors, so we can try without the return.
        if (res.isErr() && res.error().find('\n') < 0)
            res = main_scenario_script->run<sp::script::CaptureAllResults>(code);

        LuaConsole::checkResult(res);

        for (const auto& s : res.value().result)
        {
            if (PreferencesManager::get("headless").empty())
                LuaConsole::addLog(s);
            else
                printf("%s\n", s.c_str());
        }
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
    LOG(Info, "Configuring settings for scenario ", gameGlobalInfo->scenario);

    // Set each scenario setting to either a matching passed new value, or the
    // default if there's no match (or no new value).
    for (auto& setting : info.settings)
    {
        // Initialize with defaults.
        gameGlobalInfo->scenario_settings[setting.key] = setting.default_option;

        // If new settings were passed ...
        if (!new_settings.empty())
        {
            // ... confirm that this setting key exists in the new settings.
            if (new_settings.find(setting.key) != new_settings.end())
            {
                // If so, override the default with the new value.
                if (new_settings[setting.key] != "")
                    gameGlobalInfo->scenario_settings[setting.key] = new_settings[setting.key];
            }
        }

        // Log scenario setting confirmation.
        LOG(INFO) << setting.key << " scenario setting set to " << gameGlobalInfo->scenario_settings[setting.key];
    }
}

void GameGlobalInfo::startScenario(string filename, std::unordered_map<string, string> new_settings)
{
    bool same_scenario = (previous_scenario_filename == filename);

    reset();

    // Clear crew positions only if a new scenario is being started.
    if (!same_scenario)
        foreach (PlayerInfo, p, player_info_list) p->crew_positions.clear();

    i18n::reset();
    i18n::load("locale/main." + PreferencesManager::get("language", "en") + ".po");
    i18n::load("locale/comms_ship." + PreferencesManager::get("language", "en") + ".po");
    i18n::load("locale/comms_station." + PreferencesManager::get("language", "en") + ".po");
    i18n::load("locale/factionInfo." + PreferencesManager::get("language", "en") + ".po");
    i18n::load("locale/science_db." + PreferencesManager::get("language", "en") + ".po");
    i18n::load("locale/" + filename.replace(".lua", "." + PreferencesManager::get("language", "en") + ".po"));

    script_environment_base = std::make_unique<sp::script::Environment>();
    main_script_error_count = 0;

    // Load hardcoded scripts, and throw errors if they fail to load.
    if (setupScriptEnvironment(*script_environment_base.get()))
    {
        auto res = script_environment_base->runFile<void>("model_data.lua");
        LuaConsole::checkResult(res);
        if (!res.isErr())
        {
            res = script_environment_base->runFile<void>("factionInfo.lua");
            LuaConsole::checkResult(res);
        }

        if (!res.isErr())
        {
            res = script_environment_base->runFile<void>("shipTemplates.lua");
            LuaConsole::checkResult(res);
        }

        if (!res.isErr())
        {
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
    if (res.isOk() && main_scenario_script->isFunction("init"))
    {
        bool is_headless = !PreferencesManager::get("headless").empty();
        res = main_scenario_script->call<void>("init");
        LuaConsole::checkResult(res);
        if (res.isErr())
        {
            main_script_error_count = max_repeated_script_errors;
            const string error_message = "init() function failed, not going to call update()";
            if (is_headless)
                printf("%s", error_message.c_str());
            else
                LuaConsole::addLog(error_message);
        }

        // Announce StdinLuaConsole() on headless mode.
        if (is_headless)
        {
            LOG(Info, "\n=== EmptyEpsilon version ", string(VERSION_NUMBER), " - headless mode detected ===\nStandard input serves as the Lua console in headless mode.\nEnter Lua code in this running process to execute it. Enter !help for commands.\nFor line editing and history navigation on Linux, run EmptyEpsilon with rlwrap --remember EmptyEpsilon headless=...\n===\n\n");
            printf("EE> ");
            fflush(stdout);
        }
    }

    previous_scenario_filename = filename;
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

static string blockToLettersAM(int block_count)
{
    string result;
    while (block_count > 0) {
        block_count--;
        int idx = block_count % 13;
        result = char('A' + idx) + result;
        block_count /= 13;
    }
    return result;
}

static string blockToLettersNZ(int block_count)
{
    string result;
    while (block_count > 0) {
        block_count--;
        int idx = block_count % 13;
        result = char('N' + idx) + result;
        block_count /= 13;
    }
    return result;
}

static int lettersToBlockAM(const string& s, int& pos)
{
    int block = 0;
    while (pos < (int)s.length() && s[pos] >= 'A' && s[pos] <= 'M') {
        block = block * 13 + (s[pos] - 'A' + 1);
        pos++;
    }
    return block;
}

static int lettersToBlockNZ(const string& s, int& pos)
{
    int block = 0;
    while (pos < (int)s.length() && s[pos] >= 'N' && s[pos] <= 'Z') {
        block = block * 13 + (s[pos] - 'N' + 1);
        pos++;
    }
    return block;
}

string getSectorName(glm::vec2 position)
{
    constexpr float sector_size = 20000;
    int sector_x = floorf(position.x / sector_size) + 50;
    int sector_y = floorf(position.y / sector_size) + 50;

    int block_x = sector_x >= 0 ? sector_x / 100 : (sector_x - 99) / 100;
    int local_col = ((sector_x % 100) + 100) % 100;
    int block_y = sector_y >= 0 ? sector_y / 100 : (sector_y - 99) / 100;
    int local_row = ((sector_y % 100) + 100) % 100;

    char row_buf[3];
    snprintf(row_buf, sizeof(row_buf), "%02d", local_row);
    char col_buf[3];
    snprintf(col_buf, sizeof(col_buf), "%02d", local_col);

    string row_prefix;
    if (block_y < 0)
        row_prefix = blockToLettersAM(-block_y);
    else if (block_y > 0)
        row_prefix = blockToLettersNZ(block_y);

    string col_sep;
    if (block_x == 0)
        col_sep = "-";
    else if (block_x < 0)
        col_sep = blockToLettersAM(-block_x);
    else
        col_sep = blockToLettersNZ(block_x);

    return row_prefix + string(row_buf) + col_sep + string(col_buf);
}

glm::vec2 sectorToXY(string sector_name)
{
    constexpr float sector_size = 20000;
    if (sector_name.length() < 5) return {};

    int pos = 0;
    int block_y = 0;
    if (pos < (int)sector_name.length() && sector_name[pos] >= 'A' && sector_name[pos] <= 'M')
        block_y = -lettersToBlockAM(sector_name, pos);
    else if (pos < (int)sector_name.length() && sector_name[pos] >= 'N' && sector_name[pos] <= 'Z')
        block_y = lettersToBlockNZ(sector_name, pos);

    if (pos + 2 > (int)sector_name.length()) return {};
    string row_str = sector_name.substr(pos, pos + 2);
    int local_row = row_str.toInt();
    pos += 2;

    if (pos >= (int)sector_name.length()) return {};

    int block_x = 0;
    if (sector_name[pos] == '-') {
        pos++;
    } else if (sector_name[pos] >= 'A' && sector_name[pos] <= 'M') {
        block_x = -lettersToBlockAM(sector_name, pos);
    } else if (sector_name[pos] >= 'N' && sector_name[pos] <= 'Z') {
        block_x = lettersToBlockNZ(sector_name, pos);
    } else {
        return {};
    }

    if (pos + 2 > (int)sector_name.length()) return {};
    string col_str = sector_name.substr(pos, pos + 2);
    int local_col = col_str.toInt();

    int sector_x = block_x * 100 + local_col;
    int sector_y = block_y * 100 + local_row;

    float x = (sector_x - 50) * sector_size;
    float y = (sector_y - 50) * sector_size;

    return {x, y};
}
