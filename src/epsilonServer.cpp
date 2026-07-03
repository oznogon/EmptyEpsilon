#include "epsilonServer.h"
#include "playerInfo.h"
#include "gameGlobalInfo.h"
#include "soundManager.h"
#include "multiplayer_client.h"
#include "preferenceManager.h"
#include "prometheusMetrics.h"
#include "GMActions.h"
#include "main.h"
#include "config.h"

static PrometheusMetricsServer* metrics_server = nullptr;


EpsilonServer::EpsilonServer(int server_port)
: GameServer("Server", VERSION_NUMBER, server_port)
{
    if (!game_server.isAlive()) return;

    int metrics_port = PreferencesManager::get("metrics_server").toInt();
    // Initialize metrics server if defined on a valid port.
    if (metrics_port > 1024
        && metrics_port < 65535
        && !metrics_server)
    {
        metrics_server = new PrometheusMetricsServer(metrics_port);
        setCollectNetworkStats(true);
    }
    else
        LOG(Warning, "Invalid metrics server port ", string(metrics_port), ". Network stats collection not enabled.");

    new GameGlobalInfo();
    new GameMasterActions();
    PlayerInfo* info = new PlayerInfo();
    info->client_id = 0;
    my_player_info = info;
    engine->setGameSpeed(0.0f);

    for (auto proxy : PreferencesManager::get("serverproxy").split(":"))
        if (proxy != "") connectToProxy(sp::io::network::Address(proxy));
}

void EpsilonServer::onNewClient(int32_t client_id)
{
    LOG(Info, "New client: ", client_id);
    // Assign the connected client's PlayerInfo.
    PlayerInfo* info = new PlayerInfo();
    info->client_id = client_id;
}

void EpsilonServer::onDisconnectClient(int32_t client_id)
{
    LOG(Info, "Client left: ", client_id);

    // Destroy the disconnected client's PlayerInfo.
    foreach (PlayerInfo, i, player_info_list)
        if (i->client_id == client_id) i->destroy();

    player_info_list.update();
}

void disconnectFromServer()
{
    soundManager->stopMusic();

    if (game_client) game_client->destroy();
    if (game_server.isAlive()) game_server->destroy();
    if (gameGlobalInfo) gameGlobalInfo->destroy();
    if (gameMasterActions) gameMasterActions->destroy();
    foreach (PlayerInfo, i, player_info_list) i->destroy();
    if (my_player_info) my_player_info->destroy();
}

std::unordered_set<int32_t> EpsilonServer::onVoiceChat(int32_t client_id, int32_t target_identifier)
{
    // Broadcast voice to the player's ship only.
    if (target_identifier == 0)
    {
        sp::ecs::Entity ship;
        foreach (PlayerInfo, i, player_info_list)
            if (i->client_id == client_id) ship = i->ship;

        std::unordered_set<int32_t> result;
        foreach (PlayerInfo, i, player_info_list)
        {
            if (i->ship == ship && i->client_id != client_id)
                result.insert(i->client_id);
        }

        return result;
    }

    // Otherwise, broadcast voice to everyone.
    return GameServer::onVoiceChat(client_id, target_identifier);
}
