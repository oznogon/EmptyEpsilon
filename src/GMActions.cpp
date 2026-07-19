#include "GMActions.h"

#include "engine.h"
#include "gameGlobalInfo.h"
#include "systems/comms.h"
#include <SDL3/SDL.h>

const static int16_t CMD_RUN_SCRIPT = 0x0000;
const static int16_t CMD_SEND_GLOBAL_MESSAGE = 0x0001;
const static int16_t CMD_HAIL_BY_GM = 0x0002;
const static int16_t CMD_ADD_COMMS_INCOMING_MESSAGE = 0x0003;
const static int16_t CMD_CLOSE_COMMS = 0x0004;

P<GameMasterActions> gameMasterActions;

REGISTER_MULTIPLAYER_CLASS(GameMasterActions, "GameMasterActions")
GameMasterActions::GameMasterActions()
: MultiplayerObject("GameMasterActions")
{
    SDL_assert(!gameMasterActions);
    gameMasterActions = this;
}

void GameMasterActions::onReceiveClientCommand(int32_t client_id, sp::io::DataBuffer& packet)
{
    int16_t command;
    packet >> command;
    switch(command)
    {
    case CMD_RUN_SCRIPT:
        {
            string code;
            packet >> code;
            if (code.length() > 0)
            {
                gameGlobalInfo->execScriptCode(code);
            }
        }
        break;
    case CMD_SEND_GLOBAL_MESSAGE:
        {
            string message;
            packet >> message;
            if (message.length() > 0)
            {
                gameGlobalInfo->global_message = message;
                gameGlobalInfo->global_message_timeout = 5.0;
            }
        }
        break;
    case CMD_HAIL_BY_GM:
        {
            sp::ecs::Entity player;
            string target_name;
            packet >> player >> target_name;
            CommsSystem::hailByGM(player, target_name);
        }
        break;
    case CMD_ADD_COMMS_INCOMING_MESSAGE:
        {
            sp::ecs::Entity player;
            string message;
            packet >> player >> message;
            if (message.length() > 0)
                CommsSystem::addCommsIncommingMessage(player, message);
        }
        break;
    case CMD_CLOSE_COMMS:
        {
            sp::ecs::Entity player;
            packet >> player;
            CommsSystem::close(player);
        }
        break;
    }
}

void GameMasterActions::commandRunScript(string code)
{
    sp::io::DataBuffer packet;
    packet << CMD_RUN_SCRIPT << code;
    sendClientCommand(packet);
}

void GameMasterActions::commandSendGlobalMessage(string message)
{
    sp::io::DataBuffer packet;
    packet << CMD_SEND_GLOBAL_MESSAGE << message;
    sendClientCommand(packet);
}

void GameMasterActions::commandHailByGM(sp::ecs::Entity player, string target_name)
{
    sp::io::DataBuffer packet;
    packet << CMD_HAIL_BY_GM << player << target_name;
    sendClientCommand(packet);
}

void GameMasterActions::commandAddCommsIncomingMessage(sp::ecs::Entity player, string message)
{
    sp::io::DataBuffer packet;
    packet << CMD_ADD_COMMS_INCOMING_MESSAGE << player << message;
    sendClientCommand(packet);
}

void GameMasterActions::commandCloseComms(sp::ecs::Entity player)
{
    sp::io::DataBuffer packet;
    packet << CMD_CLOSE_COMMS << player;
    sendClientCommand(packet);
}