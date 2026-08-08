#include <SDL3/SDL_main.h>

#include <memory>
#include <set>
#include <filesystem>
#include <string.h>
#include <i18n.h>
#include <multiplayer_proxy.h>
#include <sys/types.h>
#include "textureManager.h"
#include "soundManager.h"
#include "gui/theme.h"
#include "menus/mainMenus.h"
#include "menus/autoConnectScreen.h"
#include "menus/shipSelectionScreen.h"
#include "main.h"
#include "epsilonServer.h"
#include "multiplayer_client.h"
#include "httpScriptAccess.h"
#include "prometheusMetrics.h"
#include "preferenceManager.h"
#include "networkRecorder.h"
#include "tutorialGame.h"
#include "windowManager.h"
#include "init/config.h"
#include "init/resources.h"
#include "init/displaywindows.h"
#include "init/ecs.h"
#include "stdinLuaConsole.h"

#include "graphics/opengl.h"
#include "graphics/renderTarget.h"

#include "hardware/hardwareController.h"
#if WITH_DISCORD
#include "discord.h"
#endif
#if STEAMSDK
#include "steam/steam_api.h"
#include "steamrichpresence.h"
#endif

#include "shaderRegistry.h"
#include "shaderManager.h"
#include "glObjects.h"
#include "particleEffect.h"
#include "script/environment.h"

// Global 3D camera properties.
glm::vec3 camera_position;
float camera_yaw;
float camera_pitch;
float camera_roll = 0.0f;

// Global font properties.
sp::Font* main_font;
sp::Font* bold_font;

// Global rendering properties.
RenderLayer* consoleRenderLayer;
RenderLayer* mouseLayer;
PostProcessor* glitchPostProcessor;
PostProcessor* warpPostProcessor;
PVector<Window> windows;
std::vector<RenderLayer*> window_render_layers;

// Global GUI layout modes' registration.
#include "gui/layout/vertical.h"
#include "gui/layout/horizontal.h"
GUI_REGISTER_LAYOUT("default", GuiLayout);
GUI_REGISTER_LAYOUT("vertical", GuiLayoutVertical);
GUI_REGISTER_LAYOUT("verticalbottom", GuiLayoutVerticalBottom);
GUI_REGISTER_LAYOUT("verticalcenter", GuiLayoutVerticalCenter);
GUI_REGISTER_LAYOUT("horizontal", GuiLayoutHorizontal);
GUI_REGISTER_LAYOUT("horizontalright", GuiLayoutHorizontalRight);
GUI_REGISTER_LAYOUT("horizontalcenter", GuiLayoutHorizontalCenter);

int runProxyServer()
{
    int port = DEFAULT_SERVER_PORT;
    string password = "";
    int listenPort = DEFAULT_SERVER_PORT;
    string proxy_name = "";
    auto parts = PreferencesManager::get("proxy").split(":");
    string host = parts[0];

    if (parts.size() > 1) port = parts[1].toInt();
    if (parts.size() > 2) password = parts[2].upper();
    if (parts.size() > 3) listenPort = parts[3].toInt();
    if (parts.size() > 4) proxy_name = parts[4];

    if (host == "listen")
        new GameServerProxy(password, listenPort, proxy_name);
    else
        new GameServerProxy(host, port, password, listenPort, proxy_name);

    engine->runMainLoop();
    return 0;
}

int main(int argc, char** argv)
{
#ifdef DEBUG
    Logging::setLogLevel(LOGLEVEL_DEBUG);
#else
    Logging::setLogLevel(LOGLEVEL_INFO);
#endif

// Log to STDOUT unless on non-debug Windows builds, which won't have
// terminals for log output.
#if defined(_WIN32) && !defined(DEBUG)
    Logging::setLogFile("EmptyEpsilon.log");
#else
    Logging::setLogStdout();
#endif

    LOG(Info, "[main] Starting EmptyEpsilon...");
    auto configuration_path = initConfiguration(argc, argv);

    new Engine();
    initSystemsAndComponents();

#if !defined(DEBUG)
    // Allow overriding log level and output.
    if (PreferencesManager::get("log_level") == "debug")
        Logging::setLogLevel(LOGLEVEL_DEBUG);
    if (PreferencesManager::get("log_output") == "file")
        Logging::setLogFile("EmptyEpsilon.log");
#endif

    if (PreferencesManager::get("headless") == "")
    {
        std::error_code ec;
        std::filesystem::create_directories(std::filesystem::path(configuration_path.c_str()), ec);
        if (ec && !(ec == std::errc::file_exists || ec == std::errc::directory_not_empty))
            LOG(Error, "[main] Failed to create configuration directory: ", ec.message());
// On macOS non-debug builds, redirect the log to the configuration directory if
// invoked as an app bundle.
#ifdef __APPLE__
        const char* argv0 = *argv;
        std::string launch_path(argv0);

        // Check if the path ends with .app/Contents/MacOS/
        // If so, we're invoked as an app bundle. Write the log to file.
        size_t pos = launch_path.find(".app/Contents/MacOS/");
        if (pos != std::string::npos)
            Logging::setLogFile(configuration_path + "/EmptyEpsilon.log");
        // If not, we might be invoked as a binary and can log to STDOUT.
        else Logging::setLogStdout();
#endif // __APPLE__
    }

    if (PreferencesManager::get("proxy") != "") return runProxyServer();

    if (PreferencesManager::get("headless") != "")
    {
        textureManager.setDisabled(true);
        Logging::setLogStdout();
    }

    initResourcePaths();
    textureManager.setDefaultSmooth(true);
    textureManager.setDefaultRepeated(true);
    i18n::load("locale/main." + PreferencesManager::get("language", "en_US") + ".po");
    keys.init();

    if (PreferencesManager::get("httpserver").toInt() != 0)
    {
        int port_nr = PreferencesManager::get("httpserver").toInt();
        if (port_nr < 80) port_nr = 80;
        LOG(Info, "[main] Enabling HTTP script access on port: ", port_nr, "\nNOTE: This is potentially a risk!");
        new EEHttpServer(port_nr, PreferencesManager::get("www_directory", "www"));
    }

    if (PreferencesManager::get("headless") == "")
    {
        string theme_name = PreferencesManager::get("guitheme", "default");
        if (!GuiTheme::loadTheme(theme_name, "gui/" + theme_name + ".theme.txt"))
        {
            LOG(Error, "[main] Failed to load " + theme_name + " theme, trying default. Resources missing or contains errors? Check gui/" + theme_name + ".theme.txt");

            if (!GuiTheme::loadTheme("default", "gui/default.theme.txt"))
            {
                // We might try to load the default theme twice, but this should be
                // a rare error case which always exits.
                LOG(Error, "[main] Failed to load default theme, exiting. Check gui/default.theme.txt");
                SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "Error", "Failed to load gui theme, resources missing or contains errors? Check gui/default.theme.txt", nullptr);
                return 1;
            }

            GuiTheme::setCurrentTheme("default");
        }
        else GuiTheme::setCurrentTheme(theme_name);

        // Apply atlas size mode from preferences before window creation.
        {
            auto atlas_pref = PreferencesManager::get("atlas_size", "auto");
            if (atlas_pref == "4k")
                sp::RenderTarget::setAtlasSizeMode(sp::RenderTarget::AtlasSizeMode::Force4K);
            else if (atlas_pref == "2k")
                sp::RenderTarget::setAtlasSizeMode(sp::RenderTarget::AtlasSizeMode::Force2K);
            else
                sp::RenderTarget::setAtlasSizeMode(sp::RenderTarget::AtlasSizeMode::Automatic);
        }

        if (!createDisplayWindows()) return 1;

        const auto& active_theme = GuiTheme::getCurrentTheme();
        main_font = active_theme->getStyle("base")->get(GuiElement::State::Normal).font;
        bold_font = active_theme->getStyle("bold")->get(GuiElement::State::Normal).font;
        if (!main_font || !bold_font)
        {
            LOG(Error, "[main] Can't load UI beacuse either the main and/or bold fonts are missing from the theme.");
            SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "Error", "Failed to load main or bold font, resources missing?", nullptr);
            return 1;
        }

        sp::RenderTarget::setDefaultFont(main_font);
    }
    else new StdinLuaConsole();

    soundManager->setMusicVolume(PreferencesManager::get("music_volume", "50").toFloat());
    soundManager->setMasterSoundVolume(PreferencesManager::get("sound_volume", "50").toFloat());

    // On Android, this requires the 'record audio' permissions,
    // which is always a scary thing for users.
    // Since there is no way to access it (yet) via a touchscreen, compile out.
#if !defined(ANDROID)
    // Set up voice chat and key bindings.
    if (PreferencesManager::get("voice_chat_enabled", "0") == "1")
    {
        NetworkAudioRecorder* nar = new NetworkAudioRecorder();
        nar->addKeyActivation(&keys.voice_all, 0);
        nar->addKeyActivation(&keys.voice_ship, 1);
    }
#endif

    P<HardwareController> hardware_controller = new HardwareController();
    hardware_controller->loadConfiguration(configuration_path + "/hardware.ini");

#if WITH_DISCORD
    {
        std::filesystem::path discord_sdk{
#ifdef RESOURCE_BASE_DIR
        RESOURCE_BASE_DIR
#endif
        };
        discord_sdk /= std::filesystem::path{ "plugins" } / DynamicLibrary::add_native_suffix("discord_game_sdk");
        new DiscordRichPresence(discord_sdk);
    }
#endif // WITH_DISCORD
#if STEAMSDK
    new SteamRichPresence();
#endif // STEAMSDK

    string tutorial = PreferencesManager::get("tutorial"); // use "00_all.lua" for all tutorials
    string server_scenario = PreferencesManager::get("server_scenario");

    if (!tutorial.empty())
    {
        bool repeat_tutorial = PreferencesManager::get("repeat_tutorial", "false") == "true";
        LOG(Debug, "[main] Starting tutorial: ", tutorial);
        new TutorialGame(repeat_tutorial, tutorial);
    }
    else if (server_scenario.empty())
        returnToMainMenu(defaultRenderLayer);
    else
    {
        // server_scenario creates a server running the specified scenario
        // using its defined default settings, and launches directly into
        // the ship selection screen instead of the main menu.

        // Create the server to listen on the assigned port.
        // Use the default port if server_port isn't set or has an invalid
        // value (toInt returns 0 if empty or not an int).
        int server_port = PreferencesManager::get("server_port").toInt();

        if (server_port == 0)
        {
            server_port = DEFAULT_SERVER_PORT;
            LOG(Warning, "[main] server_port is either not set or not an integer. Using default port ", string(DEFAULT_SERVER_PORT));
        }
        else if (server_port < 1024 || server_port > 65535)
        {
            server_port = DEFAULT_SERVER_PORT;
            LOG(Warning, "[main] server_port ", string(server_port), " is out of valid range (1024 to 65535). Using default port ", string(DEFAULT_SERVER_PORT));
        }

        LOG(Info, "[main] Launching server_scenario " + server_scenario + " on port " + string(server_port));
        new EpsilonServer(server_port);

        // Exit returning 1 if server is invalid.
        if(!gameGlobalInfo) return 1;

        if (PreferencesManager::get("server_name") != "") game_server->setServerName(PreferencesManager::get("server_name"));
        if (PreferencesManager::get("server_password") != "") game_server->setPassword(PreferencesManager::get("server_password").upper());
        if (PreferencesManager::get("server_internet") == "1") game_server->registerOnMasterServer(PreferencesManager::get("registry_registration_url", "http://daid.eu/ee/register.php"));
        if (PreferencesManager::get("proxy_registry_url") != "") game_server->registerOnProxyRegistry(PreferencesManager::get("proxy_registry_url"), PreferencesManager::get("proxy_registry_password", ""));

        // Load the scenario and open the ship selection screen.
        gameGlobalInfo->startScenario(server_scenario, loadScenarioSettingsFromPrefs());
        new ShipSelectionScreen();
    }

    engine->runMainLoop();

    // Set FSAA and fullscreen defaults from windowManager, and line drawing
    // defaults from renderTarget.
    if (windows.size() > 0)
    {
        PreferencesManager::set("fsaa", windows[0]->getFSAA());
        PreferencesManager::set("fullscreen", static_cast<int>(windows[0]->getMode()));

        if (PreferencesManager::get("line_drawing_mode", "quad") == "quad")
            sp::RenderTarget::setLineDrawingMode(sp::RenderTarget::LineDrawingMode::Quad);
        else
            sp::RenderTarget::setLineDrawingMode(sp::RenderTarget::LineDrawingMode::GL);
    }

    // Sync atlas size mode back to preferences.
    {
        auto mode = sp::RenderTarget::getAtlasSizeMode();
        switch (mode)
        {
        case sp::RenderTarget::AtlasSizeMode::Force4K:
            PreferencesManager::set("atlas_size", "4k");
            break;
        case sp::RenderTarget::AtlasSizeMode::Force2K:
            PreferencesManager::set("atlas_size", "2k");
            break;
        default:
            PreferencesManager::set("atlas_size", "auto");
            break;
        }
    }

    // Set the default music_, sound_, and engine_volume to the current volume.
    PreferencesManager::set("music_volume", soundManager->getMusicVolume());
    PreferencesManager::set("sound_volume", soundManager->getMasterSoundVolume());
    PreferencesManager::set("engine_volume", PreferencesManager::get("engine_volume", "50"));

    // Enable music and engine sounds on the main screen only by default.
    if (PreferencesManager::get("music_enabled").empty())
        PreferencesManager::set("music_enabled", "2");

    if (PreferencesManager::get("engine_enabled").empty())
        PreferencesManager::set("engine_enabled", "2");

    if (PreferencesManager::get("headless") == "")
    {
        PreferencesManager::save(configuration_path + "/options.ini");
        sp::io::Keybinding::saveKeybindings(configuration_path + "/keybindings.json");
    }
    ParticleEngine::cleanup();
    gl::shutdown();
    windows.clear();

    // gameGlobalInfo is null if no server was ever started.Reset it only if it
    // exists.
    if (gameGlobalInfo) gameGlobalInfo->reset();

    // Close Steam P2P sockets before the Steam API shuts down. If the server
    // or client is still alive, its Steam sockets remain open at shutdown and
    // SteamNetworkingSockets aborts. Destroy and release them here instead.
    if (game_server.isAlive()) game_server->destroy();
    delete engine;
    gameGlobalInfo = nullptr;
    game_client = nullptr;
    game_server = nullptr;
    ShaderManager::cleanup();
    sp::script::Environment::shutdown();
#ifdef STEAMSDK
    SteamAPI_Shutdown();
#endif

    return 0;
}

void returnToMainMenu(RenderLayer* render_layer)
{
    // Handle secondary monitors
    if (render_layer != defaultRenderLayer)
    {
        returnToShipSelection(render_layer);
        return;
    }

    string headless = PreferencesManager::get("headless", "");
    if (!headless.empty())
    {
        // Create the server to listen on the assigned port.
        // Use the default port if server_port isn't set or has an invalid
        // value (toInt returns 0).
        int headless_port = PreferencesManager::get("server_port").toInt();

        // This is the same process as server_port and could be made DRY.
        if (headless_port == 0)
        {
            headless_port = DEFAULT_SERVER_PORT;
            LOG(Warning, "[main] server_port is either not set or not an integer. Using default port ", string(DEFAULT_SERVER_PORT));
        }
        else if (headless_port < 1024 || headless_port > 65535)
        {
            headless_port = DEFAULT_SERVER_PORT;
            LOG(Warning, "[main] server_port ", string(headless_port), " is out of valid range (1024 to 65535). Using default port ", string(DEFAULT_SERVER_PORT));
        }

        LOG(Info, "[main] Launching scenario " + headless + " as a headless server on port " + string(headless_port));
        new EpsilonServer(headless_port);

        if (PreferencesManager::get("headless_name") != "") game_server->setServerName(PreferencesManager::get("headless_name"));
        if (PreferencesManager::get("headless_password") != "") game_server->setPassword(PreferencesManager::get("headless_password").upper());
        if (PreferencesManager::get("headless_internet") == "1") game_server->registerOnMasterServer(PreferencesManager::get("registry_registration_url", "http://daid.eu/ee/register.php"));
        if (PreferencesManager::get("proxy_registry_url") != "") game_server->registerOnProxyRegistry(PreferencesManager::get("proxy_registry_url"), PreferencesManager::get("proxy_registry_password", ""));
        gameGlobalInfo->startScenario(headless, loadScenarioSettingsFromPrefs());

        if (PreferencesManager::get("startpaused") != "1")
            engine->setGameSpeed(1.0f);
    }
    else if (!PreferencesManager::get("autoconnect").empty())
    {
        auto value = PreferencesManager::get("autoconnect");

        std::vector<AutoConnectPosition> window_positions;
        for (auto part : value.split(";"))
            window_positions.push_back(AutoConnectPosition(part));

        new AutoConnectScreen(window_positions, PreferencesManager::get("autocontrolmainscreen").toInt(), PreferencesManager::get("autoconnectship", "solo"));
    }
    else new MainMenu();
}

void returnToShipSelection(RenderLayer* render_layer)
{
    if (render_layer != defaultRenderLayer)
    {
        for (size_t n = 0; n < window_render_layers.size(); n++)
        {
            if (window_render_layers[n] == render_layer)
                new SecondMonitorScreen(static_cast<int>(n));
        }
    }
    // If we're using autoconnect, return to the autoconnect screen instead
    // of ship selection. returnToMainMenu will handle this.
    else
    {
        if (PreferencesManager::get("autoconnect") != "")
            returnToMainMenu(render_layer);
        else
            new ShipSelectionScreen();
    }
}

void returnToOptionMenu(OptionsMenu::ReturnTo return_to)
{
    new OptionsMenu(return_to);
}

std::unordered_map<string, string> loadScenarioSettingsFromPrefs()
{
    string preferenceValue = PreferencesManager::get("scenario_settings");

    std::unordered_map<string, string> settings = {};
    if (preferenceValue == "") return settings;

    for (string setting : preferenceValue.split(";"))
    {
        auto [key, value] = setting.partition("=");
        if (!key.empty() && !value.empty())
            settings[key.strip()] = value.strip();
    }

    return settings;
}
