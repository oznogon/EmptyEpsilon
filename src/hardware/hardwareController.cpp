#include "hardwareController.h"
#include "serialDriver.h"
#include "logging.h"
#include "gameGlobalInfo.h"
#include "playerInfo.h"
#include "ecs/query.h"

#include "components/hull.h"
#include "components/shields.h"
#include "components/reactor.h"
#include "components/impulse.h"
#include "components/warpdrive.h"
#include "components/jumpdrive.h"
#include "components/docking.h"
#include "components/collision.h"
#include "components/player.h"
#include "components/selfdestruct.h"
#include "components/missiletubes.h"
#include "components/utilityBeam.h"

#include "systems/warpsystem.h"
#include "systems/radarblock.h"

#include "devices/dmx512SerialDevice.h"
#include "devices/enttecDMXProDevice.h"
#include "devices/virtualOutputDevice.h"
#include "devices/sACNDMXDevice.h"
#include "devices/uDMXDevice.h"
#include "devices/philipsHueV1Device.h"
#ifdef HAVE_OPENSSL
#include "devices/philipsHueV2Device.h"
#endif

#include "hardwareMappingEffects.h"

HardwareController::~HardwareController()
{
    for(HardwareOutputDevice* device : devices)
        delete device;
    for(HardwareMappingState& state : states)
        delete state.effect;
    for(HardwareMappingEvent& event : events)
        delete event.effect;
}

void HardwareController::loadConfiguration(string filename)
{
    FILE* f = fopen(filename.c_str(), "r");
    if (!f)
    {
        LOG(Info, "[hardware] ", filename, " not found. Not controlling external hardware.");
        return;
    }

    std::unordered_map<string, string> settings;
    string section = "";
    char buffer[512];
    while (fgets(buffer, sizeof(buffer), f))
    {
        string line = string(buffer).strip();
        if (line.find("#") > -1) line = line.substr(0, line.find("#")).strip();
        if (line.startswith("[") && line.endswith("]"))
        {
            if (section != "")
            {
                handleConfig(section, settings);
                settings.clear();
            }

            section = line;
        }
        else if (line.find("=") > -1)
        {
            string key = line.substr(0, line.find("=")).strip();
            string value = line.substr(line.find("=") + 1).strip();
            settings[key] = value;
        }
    }
    if (section != "") handleConfig(section, settings);

    fclose(f);

    channels.resize(0);
    for (HardwareOutputDevice* device : devices)
        channels.resize(channels.size() + device->getChannelCount(), 0.0f);

    LOG(Info, "[hardware] Subsystem initialized with: ", channels.size(), " channels");

    if (devices.size() < 1)
    {
        LOG(Info, "[hardware] List of available serial ports:");

        for (string port : SerialPort::getAvailablePorts())
            LOG(Info, "[hardware] ", port, " - ", SerialPort::getPseudoDriverName(port));
    }
}

void HardwareController::handleConfig(string section, std::unordered_map<string, string>& settings)
{
    if (section == "[hardware]")
    {
        HardwareOutputDevice* device = nullptr;

        if (settings["device"] == "")
            LOG(Error, "[hardware] No device definition in hardware.ini's [hardware] section");
        else if (settings["device"] == "DMX512SerialDevice")
            device = new DMX512SerialDevice();
        else if (settings["device"] == "EnttecDMXProDevice")
            device = new EnttecDMXProDevice();
        else if (settings["device"] == "VirtualOutputDevice")
            device = new VirtualOutputDevice();
        else if (settings["device"] == "sACNDevice")
            device = new StreamingAcnDMXDevice();
        else if (settings["device"] == "uDMXDevice")
            device = new UDMXDevice();
        else if (settings["device"] == "PhilipsHueV1Device")
            device = new PhilipsHueV1Device();
        else if (settings["device"] == "PhilipsHueV2Device")
#ifdef HAVE_OPENSSL
            device = new PhilipsHueV2Device();
#else
            LOG(Error, "[hardware] Philips Hue V2 hardware devices require SSL. Build EmptyEpsilon with the WITH_SSL=ON flag.");
#endif
        else
            LOG(Error, "[hardware] Unknown device definition in [hardware] section: ", settings["device"]);

        if (device)
        {
            if (!device->configure(settings))
            {
                LOG(Error, "[hardware] Failed to configure device: ", settings["device"]);
                delete device;
            }else{
                LOG(Info, "[hardware] New device: ", settings["device"], " with: ", device->getChannelCount(), " channels");
                devices.push_back(device);
            }
        }
    }
    else if(section == "[channel]")
    {
        if (settings["channel"] == "" || settings["name"] == "")
            LOG(Error, "[hardware] Incorrect properties in hardware.ini's [channel] section");
        else
        {
            channel_mapping[settings["name"]].clear();
            channel_mapping[settings["name"]].push_back((settings["channel"].toInt() - 1));
            LOG(Info, "[hardware] Channel #", settings["channel"], ": ", settings["name"]);
        }
    }
    else if(section == "[channels]")
    {
        for (std::pair<string, string> item : settings)
        {
            channel_mapping[item.first].clear();
            for (string number : item.second.split(","))
            {
                channel_mapping[item.first].push_back((number.strip().toInt() - 1));
                LOG(Info, "[hardware] Channel #", item.second, ": ", number);
            }
        }
    }
    else if(section == "[state]")
    {
        if (channel_mapping.find(settings["target"]) == channel_mapping.end())
            LOG(Error, "[hardware] Unknown target channel in hardware.ini: ", settings["target"]);
        else
        {
            std::vector<int> channel_numbers = channel_mapping[settings["target"]];
            for (unsigned int idx = 0; idx < channel_numbers.size(); idx++)
            {
                std::unordered_map<string, string> per_channel_settings;

                for (std::pair<string, string> item : settings)
                {
                    std::vector<string> values = item.second.split(",");
                    per_channel_settings[item.first] = values[idx % values.size()].strip();
                }

                createNewHardwareMappingState(channel_numbers[idx], per_channel_settings);
            }
        }
    }
    else if(section == "[event]")
    {
        if (channel_mapping.find(settings["target"]) == channel_mapping.end())
            LOG(Error, "[hardware] Unknown target channel in hardware.ini: ", settings["target"]);
        else
        {
            std::vector<int> channel_numbers = channel_mapping[settings["target"]];
            for (unsigned int idx = 0; idx < channel_numbers.size(); idx++)
            {
                std::unordered_map<string, string> per_channel_settings;

                for (std::pair<string, string> item : settings)
                {
                    std::vector<string> values = item.second.split(",");
                    per_channel_settings[item.first] = values[idx % values.size()].strip();
                }

                createNewHardwareMappingEvent(channel_numbers[idx], per_channel_settings);
            }
        }
    }
    else LOG(Error, "[hardware] Unknown section in hardware.ini: ", section);
}

void HardwareController::update(float delta)
{
    if (channels.size() < 1) return;
    for (float& value : channels) value = 0.0f;

    for (HardwareMappingState& state : states)
    {
        float value;
        bool active = false;
        if (getVariableValue(state.variable, value))
        {
            switch(state.compare_operator)
            {
            case HardwareMappingState::Less: active = value < state.compare_value; break;
            case HardwareMappingState::Greater: active = value > state.compare_value; break;
            case HardwareMappingState::Equal: active = value == state.compare_value; break;
            case HardwareMappingState::NotEqual: active = value != state.compare_value; break;
            }
        }

        if (active && state.channel_nr < static_cast<int>(channels.size()))
            channels[state.channel_nr] = state.effect->onActive();
        else state.effect->onInactive();
    }

    for (HardwareMappingEvent& event : events)
    {
        float value;
        bool trigger = false;

        if (getVariableValue(event.trigger_variable, value))
        {
            if (event.previous_valid)
            {
                switch(event.compare_operator)
                {
                case HardwareMappingEvent::Change:
                    if (fabs(event.previous_value - value) > 0.1f)
                        trigger = true;
                    break;
                case HardwareMappingEvent::Increase:
                    if (value > event.previous_value + 0.1f)
                        trigger = true;
                    break;
                case HardwareMappingEvent::Decrease:
                    if (value < event.previous_value - 0.1f)
                        trigger = true;
                    break;
                }
            }

            event.previous_value = value;
            event.previous_valid = true;
        }
        else event.previous_valid = false;

        if (trigger)
            event.timer.start(event.runtime);

        if (event.timer.isRunning() && event.channel_nr < static_cast<int>(channels.size()))
        {
            channels[event.channel_nr] = event.effect->onActive();
            // Reset the running state if it is expired.
            event.timer.isExpired();
        }
        else event.effect->onInactive();
    }

    int idx = 0;
    for (HardwareOutputDevice* device : devices)
    {
        for (int n = 0; n < device->getChannelCount(); n++)
            device->setChannelData(n, channels[idx++]);
    }
}

void HardwareController::createNewHardwareMappingState(int channel_number, std::unordered_map<string, string>& settings)
{
    string condition = settings["condition"];

    HardwareMappingState state;
    state.variable = condition;
    state.compare_operator = HardwareMappingState::Greater;
    state.compare_value = 0.0f;
    state.channel_nr = channel_number;

    for (HardwareMappingState::EOperator compare_operator : {HardwareMappingState::Less, HardwareMappingState::Greater, HardwareMappingState::Equal, HardwareMappingState::NotEqual})
    {
        string compare_string = "<";

        switch(compare_operator)
        {
        case HardwareMappingState::Less: compare_string = "<"; break;
        case HardwareMappingState::Greater: compare_string = ">"; break;
        case HardwareMappingState::Equal: compare_string = "=="; break;
        case HardwareMappingState::NotEqual: compare_string = "!="; break;
        }

        if (condition.find(compare_string) > -1)
        {
            state.variable = condition.substr(0, condition.find(compare_string)).strip();
            state.compare_operator = compare_operator;
            state.compare_value = condition.substr(static_cast<int>(condition.find(compare_string) + compare_string.length())).strip().toFloat();
        }
    }

    state.effect = createEffect(settings);

    if (state.effect)
    {
        LOG(Debug, "[hardware] New hardware state: ", state.channel_nr, ":", state.variable, " ", state.compare_operator, " ", state.compare_value);
        states.push_back(state);
    }
}

void HardwareController::createNewHardwareMappingEvent(int channel_number, std::unordered_map<string, string>& settings)
{
    string trigger = settings["trigger"];

    HardwareMappingEvent event;
    event.compare_operator = HardwareMappingEvent::Change;

    if (trigger.startswith("<"))
    {
        event.compare_operator = HardwareMappingEvent::Decrease;
        trigger = trigger.substr(1).strip();
    }

    if (trigger.startswith(">"))
    {
        event.compare_operator = HardwareMappingEvent::Increase;
        trigger = trigger.substr(1).strip();
    }

    event.trigger_variable = trigger;
    event.channel_nr = channel_number;
    event.runtime = settings["runtime"].toFloat();
    event.previous_value = 0.0f;

    event.effect = createEffect(settings);
    if (event.effect)
    {
        LOG(Debug, "[hardware] New event: ", event.channel_nr, ":", event.trigger_variable, " ", event.compare_operator);
        events.push_back(event);
    }
}

HardwareMappingEffect* HardwareController::createEffect(std::unordered_map<string, string>& settings)
{
    HardwareMappingEffect* effect = nullptr;
    string effect_name = settings["effect"].lower();

    /// static: Effect permanently stays at its value.
    /// value: Required. The effect's value.
    if (effect_name == "static" || effect_name == "")
        effect = new HardwareMappingEffectStatic();
    /// glow: Effect gradually pulses on and off on a period.
    /// min_value: Optional. The effect's minimum value, default 0.0.
    /// max_value: Optional. The effect's maximum value, default 1.0.
    /// time: Required. The effect's half-cycle period (from off to on, or vice
    /// versa, but not both) in seconds.
    else if (effect_name == "glow")
        effect = new HardwareMappingEffectGlow();
    /// blink: Effect blinks on and off on a period.
    /// on_value: Optional. The effect's value for the "on" cycle, default 1.0.
    /// off_value: Optional. The effect's value for the "off" cycle, default
    /// 0.0.
    /// on_time: Required. The effect's "on" cycle period, in seconds.
    /// off_time: Required. The effect's "off" cycle period, in seconds.
    else if (effect_name == "blink")
        effect = new HardwareMappingEffectBlink();
    /// noise: Effect constantly transitions between randomly selected values.
    /// min_value: Optional. The effect's minimum value, default 0.0.
    /// max_value: Optional. The effect's maximum value, default 1.0.
    /// smoothness: Optional. The effect's cycle period between values, in
    /// seconds. The value transitions linearly across this period. Default 0.0.
    else if (effect_name == "noise")
        effect = new HardwareMappingEffectNoise();
    /// variable: Effect is defined in hardware.ini. At least one of condition,
    /// trigger, or input must be provided.
    /// condition: The value of a state on this player ship required for the
    /// effect to fire. Takes a variable (such as Always, HasShip, Hull, etc.),
    /// and optionally an operator (< for less than, > for greater than, == for
    /// equation, != for inequation) and comparison value. For example, "Always"
    /// is a valid condition value by itself (always fire), as is "Hull < 50"
    /// (fire only while Hull < 50, and stop firing when Hull >= 50).
    /// trigger: An event on this player ship that causes the effect to fire.
    /// Takes a variable that has a value that can change (such as Hull,
    /// Shield0, etc.) and optionally a change indicator prefix (i.e. "<Hull"
    /// triggers when Hull decreases, ">Hull" triggers when Hull increases).
    /// input: The input value to transform into the effect value.
    /// min_input: Optional. Minimum input clamp value, default 0.0.
    /// max_input: Optional. Maximum input clamp value, default 1.0.
    /// min_output: Optional. Maximum output clamp value, default 0.0.
    /// max_output: Optional. Maximum output clamp value, default 1.0.
    else if (effect_name == "variable")
        effect = new HardwareMappingEffectVariable(this);

    if (!effect)
    {
        LOG(Error, "[hardware] Unknown effect: ", settings["effect"]);
        return nullptr;
    }

    if (effect->configure(settings)) return effect;
    delete effect;
    return nullptr;
}

#define SHIP_VARIABLE(name, COMP, formula) if (variable_name == name) { if (auto c = ship.getComponent<COMP>()) { value = (formula); return true; } return false; }
#define SHIP_VARIABLE2(name, formula) if (variable_name == name) { if (c) { value = (formula); return true; } return false; }
bool HardwareController::getVariableValue(string variable_name, float& value)
{
    auto ship = my_spaceship;
    if (!ship)
    {
        for (auto [entity, pc] : sp::ecs::Query<PlayerControl>())
        {
            ship = entity;
            break;
        }
    }

    /// Always: Always returns 1.0.
    if (variable_name == "Always")
    {
        value = 1.0f;
        return true;
    }

    /// HasShip: Returns 1.0 if a player ship is active.
    if (variable_name == "HasShip")
    {
        value = static_cast<bool>(ship) ? 1.0f : 0.0f;
        return true;
    }

    /// Hull: Remaining hull percentage.
    SHIP_VARIABLE("Hull", Hull, c->percentage());
    /// Energy: Reactor energy percentage.
    SHIP_VARIABLE("Energy", Reactor, c->energyPercentage());
    /// FrontShield: Alias for Shield0.
    SHIP_VARIABLE("FrontShield", Shields, c->entries.size() > 0 ? c->entries[0].percentage() : 0.0f);
    /// Shield0: First shield segment percentage. On ships with 2 segments, this
    /// is the front shield. Returns 0 if no shield segments exist.
    SHIP_VARIABLE("Shield0", Shields, c->entries.size() > 0 ? c->entries[0].percentage() : 0.0f);
    /// RearShield: Alias of Shield1.
    SHIP_VARIABLE("RearShield", Shields, c->entries.size() > 1 ? c->entries[1].percentage() : 0.0f);
    /// Shield1: Second shield segment percentage. On ships with 2 segments, this
    /// is the rear shield. Returns 0 if this shield segments doesn't exist.
    SHIP_VARIABLE("Shield1", Shields, c->entries.size() > 1 ? c->entries[1].percentage() : 0.0f);
    /// Shield2: Third shield segment percentage. Returns 0 if this shield
    /// segments doesn't exist.
    SHIP_VARIABLE("Shield2", Shields, c->entries.size() > 2 ? c->entries[2].percentage() : 0.0f);
    /// Shield3: Fourth shield segment percentage. Returns 0 if this shield
    /// segments doesn't exist.
    SHIP_VARIABLE("Shield3", Shields, c->entries.size() > 3 ? c->entries[3].percentage() : 0.0f);
    /// Shield4: Fifth shield segment percentage. Returns 0 if this shield
    /// segments doesn't exist.
    SHIP_VARIABLE("Shield4", Shields, c->entries.size() > 4 ? c->entries[4].percentage() : 0.0f);
    /// Shield5: Sixth shield segment percentage. Returns 0 if this shield
    /// segments doesn't exist.
    SHIP_VARIABLE("Shield5", Shields, c->entries.size() > 5 ? c->entries[5].percentage() : 0.0f);
    /// Shield6: Seventh shield segment percentage. Returns 0 if this shield
    /// segments doesn't exist.
    SHIP_VARIABLE("Shield6", Shields, c->entries.size() > 6 ? c->entries[6].percentage() : 0.0f);
    /// Shield7: Eighth shield segment percentage. Returns 0 if this shield
    /// segments doesn't exist.
    SHIP_VARIABLE("Shield7", Shields, c->entries.size() > 7 ? c->entries[7].percentage() : 0.0f);
    /// ShieldsUp: Returns 1 if shields are active.
    SHIP_VARIABLE("ShieldsUp", Shields, c->active ? 1.0f : 0.0f);
    /// ShieldsCalibrating: Remaining shield calibration delay as a percentage.
    SHIP_VARIABLE("ShieldsCalibrating", Shields, c->calibration_delay / c->calibration_time);
    /// Impulse: Impulse engine active state, factored by its ShipSystem
    /// effectiveness (damage, energy).
    SHIP_VARIABLE("Impulse", ImpulseEngine, c->actual * c->getSystemEffectiveness());
    /// Warp: Warp drive active state, factored by its ShipSystem effectiveness
    /// (damage, energy).
    SHIP_VARIABLE("Warp", WarpDrive, c->current * c->getSystemEffectiveness());
    /// Docking: Returns 1.0 if the ship is in the process of docking, but
    /// hasn't docked yet.
    SHIP_VARIABLE("Docking", DockingPort, c->state == DockingPort::State::Docking ? 1.0f : 0.0f);
    /// Docked: Returns 1.0 if the ship is docked.
    SHIP_VARIABLE("Docked", DockingPort, c->state == DockingPort::State::Docked ? 1.0f : 0.0f);
    /// IsNebula: Returns 1.0 if the ship is inside of a radar block radius,
    /// such as a nebula.
    SHIP_VARIABLE("InNebula", sp::Transform, RadarBlockSystem::inRadarBlock(c->getPosition()) ? 1.0f : 0.0f);
    /// IsJammed: Returns 1.0 if the ship is inside of a warp jammer's radius.
    SHIP_VARIABLE("IsJammed", sp::Transform, c && WarpSystem::isWarpJammed(ship) ? 1.0f : 0.0f);
    /// Jumping: Returns 1.0 if the ship is in the process of jumping, but
    /// hasn't jumped yet.
    SHIP_VARIABLE("Jumping", JumpDrive, c->delay > 0.0f ? 1.0f : 0.0f);
    /// Jumped: Returns 1.0 if the ship has just jumped.
    SHIP_VARIABLE("Jumped", JumpDrive, c->just_jumped > 0.0f ? 1.0f : 0.0f);
    /// Alert: Returns 1.0 if the ship's alert system is not "Normal".
    SHIP_VARIABLE("Alert", PlayerControl, c->alert_level != AlertLevel::Normal ? 1.0f : 0.0f);
    /// YellowAlert: Returns 1.0 if the ship's alert system is "Yellow alert".
    SHIP_VARIABLE("YellowAlert", PlayerControl, c->alert_level == AlertLevel::YellowAlert ? 1.0f : 0.0f);
    /// RedAlert: Returns 1.0 if the ship's alert system is "Red alert".
    SHIP_VARIABLE("RedAlert", PlayerControl, c->alert_level == AlertLevel::RedAlert ? 1.0f : 0.0f);
    /// SelfDestruct: Returns 1.0 if the ship's self-destruct system has been
    /// activated and is prompting officers for authorization codes.
    SHIP_VARIABLE("SelfDestruct", SelfDestruct, c->active ? 1.0f : 0.0f);
    /// SelfDestructCountdown: Returns the percentage of the remaining countdown
    /// if the ship's self-destruct system has been authorized.
    SHIP_VARIABLE("SelfDestructCountdown", SelfDestruct, c->countdown / 10.0f);
    /// UtilityBeamActive: Returns 1.0 if the Utility Beam is active.
    SHIP_VARIABLE("UtilityBeamActive", UtilityBeam, c->active ? 1.0f : 0.0f);
    /// UtilityBeamFiring: Returns 1.0 if the Utility Beam is active and also
    /// firing at a target.
    SHIP_VARIABLE("UtilityBeamFiring", UtilityBeam, c->is_firing ? 1.0f : 0.0f);
    /// UtilityBeamCooldown: Returns the percentage of the remaining
    /// Utility Beam cooldown.
    SHIP_VARIABLE("UtilityBeamCooldown", UtilityBeam, c->cycle_time > 0.0f ? c->cooldown / c->cycle_time : 0.0f);

    for (unsigned int n = 0; n < 16; n++)
    {
        /// TubeLoaded0 to TubeLoaded15: Returns 1 if the given weapon tube's
        /// state is Loaded.
        SHIP_VARIABLE("TubeLoaded" + string(n), MissileTubes, c->mounts.size() > n && c->mounts[n].state == MissileTubes::MountPoint::State::Loaded ? 1.0f : 0.0f);
        /// TubeLoading0 to TubeLoading15: Returns 1 if the given weapon tube's
        /// state is Loading.
        SHIP_VARIABLE("TubeLoading" + string(n), MissileTubes, c->mounts.size() > n && c->mounts[n].state == MissileTubes::MountPoint::State::Loading ? 1.0f : 0.0f);
        /// TubeUnloading0 to TubeUnloading15: Returns 1 if the given weapon
        /// tube's state is Unloading.
        SHIP_VARIABLE("TubeUnloading" + string(n), MissileTubes, c->mounts.size() > n && c->mounts[n].state == MissileTubes::MountPoint::State::Unloading ? 1.0f : 0.0f);
        /// TubeFiring0 to TubeFiring15: Returns 1 if the given weapon tube's
        /// state is Firing.
        SHIP_VARIABLE("TubeFiring" + string(n), MissileTubes, c->mounts.size() > n && c->mounts[n].state == MissileTubes::MountPoint::State::Firing ? 1.0f : 0.0f);
    }

    for (int n = 0; n < ShipSystem::COUNT; n++)
    {
        auto c = ShipSystem::get(ship, static_cast<ShipSystem::Type>(n));
        /// <shipsystem>Health (reactorHealth, etc.): The ShipSystem's health
        /// value, from -1 to 1.
        SHIP_VARIABLE2(getSystemName(ShipSystem::Type(n)).replace(" ", "") + "Health", c->health);
        /// <shipsystem>Power (reactorPower, etc.): The ShipSystem's power level
        /// value, from 0 to 1. 100% power level is returned as 33%, 200% as 66%, 300% as 100%.
        SHIP_VARIABLE2(getSystemName(ShipSystem::Type(n)).replace(" ", "") + "Power", c->power_level / 3.0f);
        /// <shipsystem>Heat (reactorHeat, etc.): The ShipSystem's heat level
        /// value, from 0 to 1.
        SHIP_VARIABLE2(getSystemName(ShipSystem::Type(n)).replace(" ", "") + "Heat", c->heat_level);
        /// <shipsystem>Coolant (reactorCoolant, etc.): The ShipSystem's coolant
        /// level value, from 0 to 1.
        SHIP_VARIABLE2(getSystemName(ShipSystem::Type(n)).replace(" ", "") + "Coolant", c->coolant_level);
        /// <shipsystem>Hacked (reactorHacked, etc.): The ShipSystem's hacked
        /// level value, from 0 to 1.
        SHIP_VARIABLE2(getSystemName(ShipSystem::Type(n)).replace(" ", "") + "Hacked", c->hacked_level);
    }

    LOG(Warning, "[hardware] Unknown variable: ", variable_name);
    value = 0.0f;
    return false;
}
