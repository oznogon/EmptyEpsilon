#include "epsilonServer.h"
#include "playerInfo.h"
#include "gameGlobalInfo.h"
#include "preferenceManager.h"
#include "GMActions.h"
#include "main.h"

EpsilonServer::EpsilonServer()
: GameServer("Server", VERSION_NUMBER)
{
    if (game_server)
    {
        new GameGlobalInfo();
        new GameMasterActions();
        PlayerInfo* info = new PlayerInfo();
        info->client_id = 0;
        my_player_info = info;
        engine->setGameSpeed(0.0);
        for(unsigned int n=0; n<factionInfo.size(); n++)
            factionInfo[n]->reset();

        for(auto proxy : PreferencesManager::get("serverproxy").split(":"))
        {
            if (proxy != "")
                connectToProxy(sf::IpAddress(proxy));
        }
    }
}

void EpsilonServer::onNewClient(int32_t client_id)
{
    LOG(INFO) << "New client: " << client_id;
    PlayerInfo* info = new PlayerInfo();
    info->client_id = client_id;
}

void EpsilonServer::onDisconnectClient(int32_t client_id)
{
    LOG(INFO) << "Client left: " << client_id;
    foreach(PlayerInfo, i, player_info_list)
        if (i->client_id == client_id)
            i->destroy();
    player_info_list.update();
}

void disconnectFromServer()
{
    soundManager->stopMusic();

    if (game_client)
        game_client->destroy();
    if (game_server)
        game_server->destroy();
    if (gameGlobalInfo)
        gameGlobalInfo->destroy();
    if (gameMasterActions)
        gameMasterActions->destroy();
    foreach(PlayerInfo, i, player_info_list)
        i->destroy();
    if (my_player_info)
        my_player_info->destroy();
}

std::unordered_set<int32_t> EpsilonServer::onVoiceChat(int32_t speaker_client_id, int32_t target_identifier)
{
    // Values:
    // 0: Same-ship chat
    // 1: Everyone chat
    // 2: Same-faction chat
    // These are set in main.cpp with the voice chat keybindings.
    if (target_identifier != 1)
    {
        LOG(INFO) << "---- START ----";
        LOG(INFO) << "Not broadcasting. Looking for client_id " << speaker_client_id;
        int32_t speaker_ship_id = -1;
        unsigned int speaker_faction_id = 9999;
        std::unordered_set<int32_t> result;
        std::string str;

        // Is this player speaking? If so, get their ship ID.
        foreach(PlayerInfo, i, player_info_list)
        {
            LOG(INFO) << "Does " << i->client_id << " match " << speaker_client_id << "?";
            if (i->client_id == speaker_client_id)
            {
                LOG(INFO) << "YES";
                // Set speaker ship ID to this ship's ID.
                speaker_ship_id = i->ship_id;
                LOG(INFO) << "Set speaker_ship_id to " << speaker_ship_id;
                // Get the speaker's ship object.
                P<PlayerSpaceship> speaker_player_ship = game_server->getObjectById(speaker_ship_id);

                LOG(INFO) << "Is this ship a player ship? It better be.";
                // Confirm that the speaker is in a PlayerShip.
                if (speaker_player_ship)
                {
                    LOG(INFO) << "YES";
                    // Get the speaker's ship's faction ID.
                    speaker_faction_id = speaker_player_ship->getFactionId();
                    LOG(INFO) << "Set speaker_faction_id to " << speaker_faction_id;
                }
                LOG(INFO) << "- speaker_client_id:   " << speaker_client_id;
                LOG(INFO) << "- speaker_ship_id:     " << speaker_ship_id;
                LOG(INFO) << "- speaker_faction_id:  " << speaker_faction_id;
            } else {
                LOG(INFO) << "NO";
            }
        }
        LOG(INFO) << "---- END SPEAKER IDENT ----";

        // Now find voice chat recipients.
        foreach(PlayerInfo, i, player_info_list)
        {
            LOG(INFO) << "Looking for voice chat recipients...";
            LOG(INFO) << "  ... who aren't the speaker...";
            LOG(INFO) << "- i->client_id:        " << i->client_id;
            if (i->client_id != speaker_client_id)
            {
                if (target_identifier == 0)
                {
                    LOG(INFO) << "  ... on the same ship as the speaker.";
                    // Same-ship communication
                    // If this player isn't the one speaking but is in the same
                    // ship as the speaker, receive voice data.
                    LOG(INFO) << "Does i->ship_id " << i->ship_id << " match speaker_ship_id " << speaker_ship_id << "?";
                    if (i->ship_id == speaker_ship_id)
                    {
                        LOG(INFO) << "TRUE";
                        // Add this ship to the result.
                        result.insert(i->client_id);
                        str.append(std::to_string(i->client_id));
                        str.append(" ");
                        LOG(INFO) << "- Adding i->client_id " << i->client_id << " to the list of recipients!";
                    } else {
                        LOG(INFO) << "FALSE";
                    }
                } else if (target_identifier == 2) {
                   LOG(INFO) << "  ... on ships with the same faction as the speaker's.";
                    // Same-faction communication
                    // If this player isn't the one speaking but is in the same
                    // faction as the speaker, receive voice data.
                    unsigned int receiver_faction_id = 8888;
                    int32_t receiver_ship_id = -1;
                    P<PlayerSpaceship> receiver_ship = game_server->getObjectById(i->ship_id);

                    LOG(INFO) << "Is i->ship_id " << i->ship_id << " a playership?";
                    if (receiver_ship)
                    {
                        LOG(INFO) << "TRUE";
                        receiver_ship_id = i->ship_id;
                        receiver_faction_id = receiver_ship->getFactionId();
                        LOG(INFO) << "- receiver_ship_id:    " << receiver_ship_id;
                        LOG(INFO) << "- receiver_faction_id: " << receiver_faction_id;
                    } else {
                        LOG(INFO) << "FALSE";
                    }

                    LOG(INFO) << "Does receiver_faction_id " << receiver_faction_id << " match speaker_faction_id " << speaker_faction_id << "?";
                    if (receiver_faction_id == speaker_faction_id)
                    {
                        LOG(INFO) << "TRUE";
                        result.insert(i->client_id);
                        str.append(std::to_string(i->client_id));
                        str.append(" ");
                    } else {
                        LOG(INFO) << "FALSE";
                    }
                }
            } else {
                LOG(INFO) << "  ... but i->client_id " << i->client_id << " matches speaker_client_id << " << speaker_client_id << ", so we'll skip you.";
            }
        }
        LOG(INFO) << "---- END RECIPIENT IDENT ----";

        // Return the collected result.
        LOG(INFO) << "Returning the result: " << str;
        LOG(INFO) << "---- END ----\n\n";
        return result;
    } else {
        // Else return everyone on the server.
        LOG(INFO) << "Broadcasting to everyone!";
        LOG(INFO) << "---- END ----\n\n";
        return GameServer::onVoiceChat(speaker_client_id, target_identifier);
    }
}

