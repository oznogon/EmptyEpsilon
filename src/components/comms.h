#pragma once

#include "script/environment.h"
#include "script/callback.h"

class CommsReceiver
{
public:
    string script; // "comms_ship.lua" / "comms_station.lua"
    sp::script::Callback callback;
    string outgoing_image = "comms/placeholder.png";
};

class CommsTransmitter
{
public:
    enum class State
    {
        Inactive,          // No active comms
        OpeningChannel,    // Opening a comms channel
        BeingHailed,       // Receiving a hail from an object
        BeingHailedByGM,   //                   ... the GM
        ChannelOpen,       // Comms open to an object
        ChannelOpenPlayer, //           ... another player
        ChannelOpenGM,     //           ... the GM
        ChannelFailed,     // Comms failed to connect
        ChannelBroken,     // Comms broken by other side
        ChannelClosed      // Comms manually closed
    };
    struct ScriptReply
    {
        string message;
        sp::script::Callback callback;
    };

    State state = State::Inactive;
    float open_delay = 0.0f;
    string incoming_image = "comms/placeholder.png";
    string target_name;
    string incomming_message;
    sp::ecs::Entity target; // Server only
    bool script_replies_dirty = true;
    std::vector<ScriptReply> script_replies;
};
class CommsTransmitterEnvironment
{
public:    
    std::unique_ptr<sp::script::Environment> script_environment;
};