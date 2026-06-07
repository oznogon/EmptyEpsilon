#pragma once

#include "multiplayer.h"

class GameMasterActions;
extern P<GameMasterActions> gameMasterActions;

class GameMasterActions : public MultiplayerObject
{

public:
    GameMasterActions();

    // Run arbitrary Lua API code.
    void commandRunScript(string code);
    // Send a global message to players.
    void commandSendGlobalMessage(string message);
    // Hail the target PlayerControl entity.
    void commandHailByGM(sp::ecs::Entity player, string target_name);
    // Send a comms message to the target PlayerControl entity.
    void commandAddCommsIncomingMessage(sp::ecs::Entity player, string message);
    // Close comms with the target PlayerControl entity.
    void commandCloseComms(sp::ecs::Entity player);
    // Callback to handle client commands.
    virtual void onReceiveClientCommand(int32_t client_id, sp::io::DataBuffer& packet) override;
};
