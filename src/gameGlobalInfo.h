#pragma once

#include "script.h"
#include "script/gm.h"
#include "Updatable.h"
#include "multiplayer.h"
#include "timer.h"
#include <list>
#include <functional>
#include <optional>
#include <unordered_map>

#include "components/faction.h"
#include "components/radar.h"

class GameGlobalInfo;
extern P<GameGlobalInfo> gameGlobalInfo;

enum EPlayerWarpJumpDrive
{
    PWJ_ShipDefault = 0,
    PWJ_WarpDrive,
    PWJ_JumpDrive,
    PWJ_WarpAndJumpDrive,
    PWJ_None,
    PWJ_MAX,
};

enum EScanningComplexity
{
    SC_None = 0,
    SC_Simple,
    SC_Normal,
    SC_Advanced,
};

enum EHackingGames
{
    HG_Mine,
    HG_Lights,
    HG_All
};

class GameGlobalInfo : public MultiplayerObject, public Updatable
{
public:
    string global_message;
    float global_message_timeout = 0.0f;

    string banner_string;

    EScanningComplexity scanning_complexity = SC_Normal;
    // Hacking difficulty ranges from 0 to 3.
    int hacking_difficulty = 2;
    EHackingGames hacking_games = HG_All;
    bool use_beam_shield_frequencies = true;
    bool use_system_damage = true;
    bool enable_multiple_waypoint_sets = false;
    bool enable_waypoint_routes = false;
    bool use_drone_energy_drain = false;
    bool missiles_on_long_range_radar = false;
    float collision_damage_factor = 0.0f;
    bool allow_main_screen_tactical_radar = true;
    bool allow_main_screen_long_range_radar = true;
    bool allow_main_screen_strategic_map = true;
    string default_skybox = "default";
    string gm_control_code = "";
    float elapsed_time = 0.0f;
    float elapsed_delta = 0.0f;
    sp::SystemStopwatch wall_time;
    string scenario;
    std::unordered_map<string, string> scenario_settings;
    string previous_scenario_filename;

    // List of script functions that can be called from the GM interface.
    // (Server only.)
    std::list<GMScriptCallback> gm_callback_functions;
    std::list<string> gm_messages;
    // When true, all comms requests go to the GM as chat, and normal scripted
    // converstations require GM intervention to enable. This doesn't disallow
    // player-to-player chat comms.
    bool intercept_all_comms_to_gm = false;

    std::function<void(glm::vec2, std::optional<float>)> on_gm_click;
    std::optional<RadarTrace> on_gm_preview_trace;
    glm::u8vec4 on_gm_preview_faction_color{255, 255, 255, 255};
    const string DEFAULT_ON_GM_CLICK_CURSOR = "cursors/mouse_create.png";
    string on_gm_click_cursor = DEFAULT_ON_GM_CLICK_CURSOR;

    GameGlobalInfo();
    virtual ~GameGlobalInfo();

    void onReceiveServerCommand(sp::io::DataBuffer& packet) override;
    void playSoundOnMainScreen(sp::ecs::Entity ship, string sound_name);
    void setVictory(string faction_name);
    /*!
     * \brief Get ID of faction that won.
     * \param int
     */
    FactionInfo* getVictoryFaction() { if (!victory_faction) return nullptr; return victory_faction.getComponent<FactionInfo>(); }

    //Reset the global game state (called when we want to load a new scenario, and clear out this one)
    void reset();
    void setScenarioSettings(const string filename, std::unordered_map<string, string> new_settings);
    void startScenario(string filename, std::unordered_map<string, string> new_settings = {});

    virtual void update(float delta) override;
    virtual void destroy() override;
    string getMissionTime();

    string getNextShipCallsign();

    struct ShipSpawnInfo {
        sp::script::Callback create_callback;
        string label;
        string description;
        string icon;
    };
    std::vector<ShipSpawnInfo> getSpawnablePlayerShips();
    struct ObjectSpawnInfo {
        sp::script::Callback create_callback;
        string label;
        string category;
        string description;
        string icon;
    };
    std::vector<ObjectSpawnInfo> getGMSpawnableObjects();
    string getEntityExportString(sp::ecs::Entity entity);
    void execScriptCode(const string& code);
    bool allowNewPlayerShips();

    //List of extra scripts that run next to the main script.
    std::vector<std::unique_ptr<sp::script::Environment>> additional_scripts;
    std::unique_ptr<sp::script::Environment> script_environment_base;
    std::unique_ptr<sp::script::Environment> main_scenario_script;
    std::vector<sp::script::CoroutinePtr> script_threads;
    std::vector<sp::script::CoroutinePtr> new_script_threads;
private:
    sp::ecs::Entity victory_faction;
    int callsign_counter = 0;

    int main_script_error_count = 0;
    static constexpr int max_repeated_script_errors = 5;

    constexpr static int16_t CMD_PLAY_CLIENT_SOUND = 0x0001;
};

string getSectorName(glm::vec2 position);
glm::vec2 sectorToXY(string sectorName);
