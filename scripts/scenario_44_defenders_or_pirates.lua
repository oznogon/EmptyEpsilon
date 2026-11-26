-- Name: Defenders or Pirates
-- Description: Amass reputation by destroying enemies or grabbing and selling cargo
---
--- Designed for 1-32 player ships. Duration: 45 minutes. Features many non-standard player ships.
---
--- Version 1
---
--- USN Discord: https://discord.gg/PntGG3a where you can join a game online. There's usually one every weekend. All experience levels are welcome.
-- Type: Replayable
-- Author: Xansta
-- Setting[Playership]: Configure what player ship to start with. Default is random
-- Playership[Random|Default]: Select a player ship at random from the list of available starting player ships
-- Playership[Amalgam]: Corvette, jump, 4 front beams, broadside missiles, no HVLIs
-- Playership[Atlantis]: Corvette, jump, 2 front beams, broadside missiles
-- Playership[Atlantis II]: Corvette, jump, 2 front beams, angled missiles
-- Playership[Butler]: Corvette, warp, 2 wide front beams, front and rear missiles, no mines
-- Playership[Caretaker]: Corvette, jump, front missiles, 2 front beams
-- Playership[Crucible]: Corvette, warp, front and broadside missiles, 2 front beams
-- Playership[Vindicator]: Corvette, jump, 2 front beams, front slightly angled missiles, no HVLIs
-- Playership[Deimos]: Frigate, warp, 3 front beams, front and broadside missiles
-- Playership[Era]: Frigate, warp, 2 front beams, rear missile tube, no EMPs
-- Playership[Flavia]: Frigate (converted freighter), warp, 2 rear beams, rear missile tube, no EMPs
-- Playership[Flavia 2C]: Frigate (converted freighter), warp, 2 front beams, broadside and rear missiles
-- Playership[Hathcock]: Frigate, jump, 4 front beams, broadside missiles, no mines
-- Playership[Interlock]: Frigate, jump, 6 beams (5 front, 1 rear), broadside missiles
-- Playership[Mantis]: Corvette, jump, front and broadside missiles, 2 front beams
-- Playership[Maverick]: Corvette, warp, 6 beams (5 front, 1 rear), broadside missiles
-- Playership[Maverick XP]: Corvette, jump, 1 strong wide angle beam, broadside missiles
-- Playership[Midian]: Corvette, warp, 3 beams (2 front, 1 rear), front and broadside missiles
-- Playership[Avalanche]: Corvette, warp, broadside and front missiles, no beams
-- Playership[Moose]: Corvette, jump, front and broadside missiles, 4 beams (3 front, 1 rear), ships can dock to Moose
-- Playership[Mortar]: Corvette, jump, 6 front beams, broadside missiles
-- Playership[Nautilus]: Frigate, jump, 3 rear mine tubes, 2 front beams, only mines
-- Playership[Nusret]: Frigate, jump, angled missiles, 2 front beams, only homing and mines
-- Playership[Ogre]: Dreadnaught, jump, 12 beams, 12 missile tubes, only homing
-- Playership[Peacock]: Corvette, jump, 4 front beams, front and broadside missiles
-- Playership[Phobos M3P]: Frigate, warp, 2 front beams, front missiles
-- Playership[Piranha]: Frigate, jump, broadside missiles, no beams
-- Playership[Proto-Atlantis]: Corvette, jump, broadside and front missiles, 2 front beams
-- Playership[Raven]: Corvette, warp, 2 front beams, angled missiles
-- Playership[Repulse]: Frigate, jump, 2 wide broadside beams, 1 front and 1 rear tube, only HVLI and homing
-- Playership[Roc]: Frigate, warp, front and broadside missiles, 3 beams (2 front, 1 wide rear)
-- Playership[Rodent]: Frigate, jump, 4 beams (2 front, 2 short wide angled front/rear), front and broadside missiles
-- Playership[Saipan]: Corvette, jump, front and broadside missiles, 3 beams (2 front, 1 rear), ships can dock to Saipan
-- Playership[Scatter]: Frigate, jump, 4 beams (3 front, 1 rear), broadside missiles
-- Playership[Squid]: Frigate, jump, broadside and front missiles including two rear mine tubes, 1 front beam
-- Setting[Enemies]: Configures strength and/or number of enemies in this scenario
-- Enemies[Easy]: Fewer or weaker enemies
-- Enemies[Normal|Default]: Normal number or strength of enemies
-- Enemies[Hard]: More or stronger enemies
-- Enemies[Extreme]: Much stronger, many more enemies
-- Enemies[Quixotic]: Insanely strong and/or inordinately large numbers of enemies
-- Setting[Murphy]: Configures the perversity of the universe according to Murphy's law
-- Murphy[Easy]: Random factors are more in your favor
-- Murphy[Normal|Default]: Random factors are normal
-- Murphy[Hard]: Random factors are more against you
-- Murphy[Extreme]: Random factors are severely against you
-- Murphy[Quixotic]: No need for paranoia, the universe *is* out to get you
-- Setting[Respawn]: Configures whether the player ship or ships automatically respawn in game or not and how often if they do automatically respawn
-- Respawn[None|Default]: Player ships do not automatically respawn
-- Respawn[One]: Player ships will automatically respawn once
-- Respawn[Two]: Player ships will automatically respawn twice
-- Respawn[Three]: Player ships will automatically respawn thrice
-- Respawn[Infinite]: Player ships will automatically respawn forever

require("utils.lua")
require("place_station_scenario_utility.lua")
require("cpu_ship_diversification_scenario_utility.lua")
require("generate_call_sign_scenario_utility.lua")
require("comms_scenario_utility.lua")
local Fleet = require("spawn_ships_scenario_utility.lua")
local Stats = require("statistics_scenario_utility.lua")
local playerDestroyed = Fleet.noopDestroyed
local Environment = require("environment_scenario_utility.lua")
local defaults = require("defaults_scenario_utility.lua")
local ShipNames = require("player_ship_names_scenario_utility.lua")
local PlayerState = require("player_state_scenario_utility.lua")
local updateNameBanner = PlayerState.updateNameBanner
local updateTubeBanner = PlayerState.updateTubeBanner
local ShipComms = require("comms_ship_support.lua")
local Sensor = require("sensor_scenario_utility.lua")
local List = require("list_scenario_utility.lua")
local cleanList = List.clean

local GmSettings = require("gm_settings_scenario_utility.lua")
mainGMButtons = GmSettings.spawnMenu

local function queueProbeRespawn(self, instigator)
    probe_respawn = Sensor.queueProbeRespawn(self, probe_respawn, instigator)
end
probeExpired = queueProbeRespawn
probeDestroyed = queueProbeRespawn
local MissionMenu = require("comms_mission_menu.lua")
local Transport = require("transport_scenario_utility.lua")
local warpJammerMaintenance = Transport.warpJammerMaintenance(function() return transportCommerceMaintenance end)
local Supply = require("supply_scenario_utility.lua")
local supplyPickupProcess = Supply.supplyPickupProcess

local randomTransportType = Transport.randomTransportTypeBasic

local scenarioMissionsUndocked = MissionMenu.scenarioMissionsUndocked
local setOptionalOrders = MissionMenu.setOptionalOrders

local sensorJammer = Sensor.sensorJammerBasic
local sensorJammerPickupProcess = Sensor.sensorJammerPickupBasic
local updatePlayerLongRangeSensors = Sensor.updatePlayerLongRangeSensorsBasic

local availableForComms = ShipComms.availableForComms


local getTemplatePool = Fleet.templatePoolGetter({
    catalog = function() return ship_template end,
    selectivity = function() return pool_selectivity end,
    composition = function() return fleetComposition end,
    limit = function() return template_pool_size end,
    stock_template = function() return stockTemplate end,
    fleet_group = function() return fleet_group end,
})

local playerPower = Fleet.playerPower

local spawnRandomArmed = Fleet.relativeSpawner({
    catalog = function() return ship_template end,
    relative_strength = function() return relative_strength end,
    player_power = playerPower,
    enemy_power = function() return enemy_power end,
    pool = getTemplatePool,
    formation = function() return formation_delta end,
    prefix = generateCallSignPrefix,
    faction = function() return fleetSpawnFaction end,
    set_faction = function(faction) fleetSpawnFaction = faction end,
    callsign = generateCallSign,
})

function init()
    loot_button_diagnostic = false
    scenario_version = "1.0.1"
    ee_version = "2024.12.08"
    print(
        string.format(
            "    ----    Scenario: Defenders or Pirates    ----    Version %s    ----    Tested with EE version %s    ----",
            scenario_version,
            ee_version
        )
    )
    if _VERSION ~= nil then
        print("Lua version:", _VERSION)
    end
    setConstants()
    setGlobals()
    setVariations()
    mainGMButtons()
    onNewPlayerShip(setPlayers)
    constructEnvironment()
    PlayerSpaceship():setTemplate(ST.ATLANTIS)
end
function setConstants()
    ordnance_types = { "Homing", "Nuke", "Mine", "EMP", "HVLI" }
    pretty_system = defaults.systems().pretty_system
    pretty_short_system = defaults.systems().pretty_short_system
    system_types = defaults.systems().system_types
    center_x = 300000 + random(-180000, 180000)
    center_y = 150000 + random(-60000, 60000)
    max_repeat_loop = 100
    commonGoods = defaults.goods().commonGoods
    mineralGoods = defaults.goods().mineralGoods
    componentGoods = defaults.goods().componentGoods
    good_desc = defaults.goods().good_desc
    fleet_group = {
        ["adder"] = "Adders",
        ["Adders"] = "adder",
        ["missiler"] = "Missilers",
        ["Missilers"] = "missiler",
        ["beamer"] = "Beamers",
        ["Beamers"] = "beamer",
        ["frigate"] = "Frigates",
        ["Frigates"] = "frigate",
        ["chaser"] = "Chasers",
        ["Chasers"] = "chaser",
        ["fighter"] = "Fighters",
        ["Fighters"] = "fighter",
        ["drone"] = "Drones",
        ["Drones"] = "drone",
    }
    ship_template = { --ordered by relative strength
        -- normal ships that are part of the fleet spawn process
        ["Gnat"] = {
            strength = 2,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = true,
            drone = true,
            unusual = false,
            base = false,
            short_range_radar = 4500,
            hop_angle = 0,
            hop_range = 580,
            create = gnat,
        },
        ["Lite Drone"] = {
            strength = 3,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = true,
            drone = true,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 580,
            create = droneLite,
        },
        ["Jacket Drone"] = {
            strength = 4,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = true,
            drone = true,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 580,
            create = droneJacket,
        },
        [ST.KTLITAN_DRONE] = {
            strength = 4,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = true,
            drone = true,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 580,
            create = stockTemplate,
        },
        ["Heavy Drone"] = {
            strength = 5,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = true,
            drone = true,
            unusual = false,
            base = false,
            short_range_radar = 5500,
            hop_angle = 0,
            hop_range = 580,
            create = droneHeavy,
        },
        [ST.ADDER_MK3] = {
            strength = 5,
            adder = true,
            missiler = false,
            beamer = false,
            frigate = false,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 580,
            create = stockTemplate,
        },
        [ST.MT52_HORNET] = {
            strength = 5,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = true,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 680,
            create = stockTemplate,
        },
        [ST.MU52_HORNET] = {
            strength = 5,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = true,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 880,
            create = stockTemplate,
        },
        [ST.DAGGER] = {
            strength = 6,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = true,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 980,
            create = stockTemplate,
        },
        ["MV52 Hornet"] = {
            strength = 6,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = true,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 980,
            create = hornetMV52,
        },
        ["MT55 Hornet"] = {
            strength = 6,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = true,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 680,
            create = hornetMT55,
        },
        [ST.ADDER_MK4] = {
            strength = 6,
            adder = true,
            missiler = false,
            beamer = false,
            frigate = false,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 580,
            create = stockTemplate,
        },
        ["Fighter"] = {
            strength = 6,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = true,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 980,
            create = stockTemplate,
        },
        ["Shepherd"] = {
            strength = 6,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = true,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5500,
            hop_angle = 0,
            hop_range = 2880,
            create = shepherd,
        },
        [ST.KTLITAN_FIGHTER] = {
            strength = 6,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = true,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 1180,
            create = stockTemplate,
        },
        ["Touchy"] = {
            strength = 7,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = true,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 2000,
            create = touchy,
        },
        [ST.BLADE] = {
            strength = 7,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = true,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 980,
            create = stockTemplate,
        },
        [ST.GUNNER] = {
            strength = 7,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = false,
            chaser = false,
            fighter = true,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 980,
            create = stockTemplate,
        },
        ["K2 Fighter"] = {
            strength = 7,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = true,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 1180,
            create = k2fighter,
        },
        [ST.ADDER_MK5] = {
            strength = 7,
            adder = true,
            missiler = false,
            beamer = false,
            frigate = false,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 580,
            create = stockTemplate,
        },
        ["WX-Lindworm"] = {
            strength = 7,
            adder = false,
            missiler = true,
            beamer = false,
            frigate = false,
            chaser = false,
            fighter = true,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5500,
            hop_angle = 0,
            hop_range = 2500,
            create = stockTemplate,
        },
        ["K3 Fighter"] = {
            strength = 8,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = true,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 1180,
            create = k3fighter,
        },
        [ST.SHOOTER] = {
            strength = 8,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = false,
            chaser = false,
            fighter = true,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 980,
            create = stockTemplate,
        },
        [ST.JAGGER] = {
            strength = 8,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = false,
            chaser = false,
            fighter = true,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 980,
            create = stockTemplate,
        },
        [ST.ADDER_MK6] = {
            strength = 8,
            adder = true,
            missiler = false,
            beamer = false,
            frigate = false,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 580,
            create = stockTemplate,
        },
        [ST.KTLITAN_SCOUT] = {
            strength = 8,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 7000,
            hop_angle = 0,
            hop_range = 580,
            create = stockTemplate,
        },
        ["WZ-Lindworm"] = {
            strength = 9,
            adder = false,
            missiler = true,
            beamer = false,
            frigate = false,
            chaser = false,
            fighter = true,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5500,
            hop_angle = 0,
            hop_range = 2500,
            create = wzLindworm,
        },
        [ST.ADDER_MK7] = {
            strength = 9,
            adder = true,
            missiler = false,
            beamer = false,
            frigate = false,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 580,
            create = stockTemplate,
        },
        [ST.ADDER_MK8] = {
            strength = 10,
            adder = true,
            missiler = false,
            beamer = false,
            frigate = false,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5500,
            hop_angle = 0,
            hop_range = 580,
            create = stockTemplate,
        },
        [ST.ADDER_MK9] = {
            strength = 11,
            adder = true,
            missiler = false,
            beamer = false,
            frigate = false,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 6000,
            hop_angle = 0,
            hop_range = 580,
            create = stockTemplate,
        },
        [ST.NIRVANA_R3] = {
            strength = 12,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 980,
            create = stockTemplate,
        },
        ["Phobos R2"] = {
            strength = 13,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 1180,
            create = phobosR2,
        },
        [ST.POLARIS] = {
            strength = 14,
            adder = false,
            missiler = true,
            beamer = false,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 7000,
            hop_angle = 0,
            hop_range = 2500,
            create = stockTemplate,
        },
        ["Waddle 5"] = {
            strength = 15,
            adder = true,
            missiler = false,
            beamer = false,
            frigate = false,
            chaser = true,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 580,
            create = waddle5,
        },
        ["Jade 5"] = {
            strength = 15,
            adder = true,
            missiler = false,
            beamer = false,
            frigate = false,
            chaser = true,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 580,
            create = jade5,
        },
        [ST.PHOBOS_T3] = {
            strength = 15,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 1180,
            create = stockTemplate,
        },
        [ST.GUARD] = {
            strength = 15,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 1180,
            create = stockTemplate,
        },
        [ST.PIRANHA_F8] = {
            strength = 15,
            adder = false,
            missiler = true,
            beamer = false,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 6000,
            hop_angle = 90,
            hop_range = 2500,
            create = stockTemplate,
        },
        [ST.PIRANHA_F12] = {
            strength = 15,
            adder = false,
            missiler = true,
            beamer = false,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 6000,
            hop_angle = 90,
            hop_range = 2500,
            create = stockTemplate,
        },
        [ST.PIRANHA_F12M] = {
            strength = 16,
            adder = false,
            missiler = true,
            beamer = false,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 6000,
            hop_angle = 90,
            hop_range = 2500,
            create = stockTemplate,
        },
        [ST.PHOBOS_M3] = {
            strength = 16,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5500,
            hop_angle = 0,
            hop_range = 1180,
            create = stockTemplate,
        },
        ["Farco 3"] = {
            strength = 16,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 8000,
            hop_angle = 0,
            hop_range = 1480,
            create = farco3,
        },
        ["Farco 5"] = {
            strength = 16,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 8000,
            hop_angle = 0,
            hop_range = 1180,
            create = farco5,
        },
        ["Sweeper"] = {
            strength = 17,
            adder = true,
            missiler = false,
            beamer = false,
            frigate = false,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 580,
            create = sweeper,
        },
        [ST.KARNACK] = {
            strength = 17,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 980,
            create = stockTemplate,
        },
        [ST.GUNSHIP] = {
            strength = 17,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 980,
            create = stockTemplate,
        },
        ["Phobos T4"] = {
            strength = 18,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 1480,
            create = phobosT4,
        },
        [ST.NIRVANA_R5] = {
            strength = 19,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 1180,
            create = stockTemplate,
        },
        ["Farco 8"] = {
            strength = 19,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 8000,
            hop_angle = 0,
            hop_range = 1480,
            create = farco8,
        },
        [ST.NIRVANA_R5A] = {
            strength = 20,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 1180,
            create = stockTemplate,
        },
        [ST.ADV_GUNSHIP] = {
            strength = 20,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 7000,
            hop_angle = 0,
            hop_range = 980,
            create = stockTemplate,
        },
        [ST.KTLITAN_WORKER] = {
            strength = 20,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 90,
            hop_range = 580,
            create = stockTemplate,
        },
        ["Farco 11"] = {
            strength = 21,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 8000,
            hop_angle = 0,
            hop_range = 1480,
            create = farco11,
        },
        [ST.STORM] = {
            strength = 22,
            adder = false,
            missiler = true,
            beamer = false,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 6000,
            hop_angle = 0,
            hop_range = 1180,
            create = stockTemplate,
        },
        [ST.WARDEN] = {
            strength = 22,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 6000,
            hop_angle = 0,
            hop_range = 1180,
            create = stockTemplate,
        },
        [ST.RACER] = {
            strength = 22,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = true,
            chaser = true,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 980,
            create = stockTemplate,
        },
        [ST.STALKER_R5] = {
            strength = 22,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = true,
            chaser = true,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 980,
            create = stockTemplate,
        },
        [ST.STALKER_Q5] = {
            strength = 22,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = true,
            chaser = true,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 980,
            create = stockTemplate,
        },
        [ST.STRIKE] = {
            strength = 23,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = true,
            chaser = true,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5500,
            hop_angle = 0,
            hop_range = 980,
            create = stockTemplate,
        },
        [ST.DASH] = {
            strength = 23,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = true,
            chaser = true,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5500,
            hop_angle = 0,
            hop_range = 980,
            create = stockTemplate,
        },
        ["Farco 13"] = {
            strength = 24,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 1480,
            create = farco13,
        },
        [ST.SENTINEL] = {
            strength = 24,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 1180,
            create = stockTemplate,
        },
        [ST.RANUS_U] = {
            strength = 25,
            adder = false,
            missiler = true,
            beamer = false,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 6000,
            hop_angle = 0,
            hop_range = 2500,
            create = stockTemplate,
        },
        [ST.FLASH] = {
            strength = 25,
            adder = false,
            missiler = true,
            beamer = false,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 6000,
            hop_angle = 0,
            hop_range = 2500,
            create = stockTemplate,
        },
        [ST.RANGER] = {
            strength = 25,
            adder = false,
            missiler = true,
            beamer = false,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 6000,
            hop_angle = 0,
            hop_range = 2500,
            create = stockTemplate,
        },
        [ST.BUSTER] = {
            strength = 25,
            adder = false,
            missiler = true,
            beamer = false,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 6000,
            hop_angle = 0,
            hop_range = 2500,
            create = stockTemplate,
        },
        [ST.STALKER_Q7] = {
            strength = 25,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = true,
            chaser = true,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 980,
            create = stockTemplate,
        },
        [ST.STALKER_R7] = {
            strength = 25,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = true,
            chaser = true,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 980,
            create = stockTemplate,
        },
        ["Whirlwind"] = {
            strength = 26,
            adder = false,
            missiler = true,
            beamer = false,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 6000,
            hop_angle = 90,
            hop_range = 2500,
            create = whirlwind,
        },
        [ST.HUNTER] = {
            strength = 26,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = true,
            chaser = true,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5500,
            hop_angle = 0,
            hop_range = 980,
            create = stockTemplate,
        },
        [ST.MAGPIE] = {
            strength = 27,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = true,
            chaser = true,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 980,
            create = stockTemplate,
        },
        [ST.ELARA_P2] = {
            strength = 28,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = true,
            chaser = true,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 8000,
            hop_angle = 0,
            hop_range = 1480,
            create = stockTemplate,
        },
        ["Tempest"] = {
            strength = 30,
            adder = false,
            missiler = true,
            beamer = false,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 6000,
            hop_angle = 90,
            hop_range = 2500,
            create = tempest,
        },
        [ST.STRIX] = {
            strength = 30,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = true,
            chaser = true,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 980,
            create = stockTemplate,
        },
        [ST.FIEND_G3] = {
            strength = 33,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = true,
            chaser = true,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 6500,
            hop_angle = 0,
            hop_range = 980,
            create = stockTemplate,
        },
        ["Maniapak"] = {
            strength = 34,
            adder = true,
            missiler = false,
            beamer = false,
            frigate = false,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 6000,
            hop_angle = 0,
            hop_range = 580,
            create = maniapak,
        },
        [ST.FIEND_G4] = {
            strength = 35,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = true,
            chaser = true,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 6500,
            hop_angle = 0,
            hop_range = 980,
            create = stockTemplate,
        },
        ["Cucaracha"] = {
            strength = 36,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 1480,
            create = cucaracha,
        },
        [ST.FIEND_G5] = {
            strength = 37,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = true,
            chaser = true,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 6500,
            hop_angle = 0,
            hop_range = 980,
            create = stockTemplate,
        },
        ["Mikado"] = {
            strength = 38,
            adder = false,
            missiler = true,
            beamer = false,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 6000,
            hop_angle = 0,
            hop_range = 1180,
            create = mikado,
        },
        [ST.FIEND_G6] = {
            strength = 39,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = true,
            chaser = true,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 6500,
            hop_angle = 0,
            hop_range = 980,
            create = stockTemplate,
        },
        ["Barracuda"] = {
            strength = 40,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5500,
            hop_angle = 0,
            hop_range = 1180,
            create = barracuda,
        },
        [ST.RYDER] = {
            strength = 41,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 8000,
            hop_angle = 90,
            hop_range = 1180,
            create = stockTemplate,
        },
        ["Predator"] = {
            strength = 42,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = true,
            chaser = true,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 7500,
            hop_angle = 0,
            hop_range = 980,
            create = predator,
        },
        [ST.KTLITAN_BREAKER] = {
            strength = 45,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = false,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 780,
            create = stockTemplate,
        },
        ["Hurricane"] = {
            strength = 46,
            adder = false,
            missiler = true,
            beamer = false,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 6000,
            hop_angle = 15,
            hop_range = 2500,
            create = hurricane,
        },
        [ST.KTLITAN_FEEDER] = {
            strength = 48,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 580,
            create = stockTemplate,
        },
        [ST.ATLANTIS_X23] = {
            strength = 50,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = false,
            chaser = true,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 10000,
            hop_angle = 0,
            hop_range = 1480,
            create = stockTemplate,
        },
        [ST.KTLITAN_DESTROYER] = {
            strength = 50,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = false,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 9000,
            hop_angle = 0,
            hop_range = 980,
            create = stockTemplate,
        },
        ["K2 Breaker"] = {
            strength = 55,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = false,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5000,
            hop_angle = 0,
            hop_range = 780,
            create = k2breaker,
        },
        ["Atlantis Y42"] = {
            strength = 60,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = false,
            chaser = true,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 10000,
            hop_angle = 0,
            hop_range = 1480,
            create = atlantisY42,
        },
        [ST.BLOCKADE_RUNNER] = {
            strength = 63,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 5500,
            hop_angle = 0,
            hop_range = 980,
            create = stockTemplate,
        },
        [ST.STARHAMMER_II] = {
            strength = 70,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = false,
            chaser = true,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 10000,
            hop_angle = 0,
            hop_range = 1480,
            create = stockTemplate,
        },
        ["Enforcer"] = {
            strength = 75,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 9000,
            hop_angle = 0,
            hop_range = 1480,
            create = enforcer,
        },
        [ST.DREADNOUGHT] = {
            strength = 80,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 9000,
            hop_angle = 0,
            hop_range = 980,
            create = stockTemplate,
        },
        ["Starhammer III"] = {
            strength = 85,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = false,
            chaser = true,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 12000,
            hop_angle = 0,
            hop_range = 1480,
            create = starhammerIII,
        },
        ["Starhammer V"] = {
            strength = 90,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = false,
            chaser = true,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 15000,
            hop_angle = 0,
            hop_range = 1480,
            create = starhammerV,
        },
        [ST.BATTLESTATION] = {
            strength = 100,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 9000,
            hop_angle = 90,
            hop_range = 2480,
            create = stockTemplate,
        },
        [ST.FORTRESS] = {
            strength = 130,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 9000,
            hop_angle = 90,
            hop_range = 2380,
            create = stockTemplate,
        },
        ["Tyr"] = {
            strength = 150,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = true,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 9500,
            hop_angle = 90,
            hop_range = 2480,
            create = tyr,
        },
        [ST.ODIN] = {
            strength = 250,
            adder = false,
            missiler = false,
            beamer = false,
            frigate = false,
            chaser = true,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            short_range_radar = 20000,
            hop_angle = 0,
            hop_range = 3180,
            create = stockTemplate,
        },
    }
    formation_delta = {
        ["square"] = {
            x = {
                0,
                1,
                0,
                -1,
                0,
                1,
                -1,
                1,
                -1,
                2,
                0,
                -2,
                0,
                2,
                -2,
                2,
                -2,
                2,
                2,
                -2,
                -2,
                1,
                -1,
                1,
                -1,
                0,
                0,
                3,
                -3,
                1,
                1,
                3,
                -3,
                -1,
                -1,
                3,
                -3,
                2,
                2,
                3,
                -3,
                -2,
                -2,
                3,
                -3,
                3,
                3,
                -3,
                -3,
                4,
                0,
                -4,
                0,
                4,
                -4,
                4,
                -4,
                -4,
                -4,
                -4,
                -4,
                -4,
                -4,
                4,
                4,
                4,
                4,
                4,
                4,
                1,
                -1,
                2,
                -2,
                3,
                -3,
                1,
                -1,
                2,
                -2,
                3,
                -3,
                5,
                -5,
                0,
                0,
                5,
                5,
                -5,
                -5,
                -5,
                -5,
                -5,
                -5,
                -5,
                -5,
                -5,
                -5,
                5,
                5,
                5,
                5,
                5,
                5,
                5,
                5,
                1,
                -1,
                2,
                -2,
                3,
                -3,
                4,
                -4,
                1,
                -1,
                2,
                -2,
                3,
                -3,
                4,
                -4,
            },
            y = {
                0,
                0,
                1,
                0,
                -1,
                1,
                -1,
                -1,
                1,
                0,
                2,
                0,
                -2,
                2,
                -2,
                -2,
                2,
                1,
                -1,
                1,
                -1,
                2,
                2,
                -2,
                -2,
                3,
                -3,
                0,
                0,
                3,
                -3,
                1,
                1,
                3,
                -3,
                -1,
                -1,
                3,
                -3,
                2,
                2,
                3,
                -3,
                -2,
                -2,
                3,
                -3,
                3,
                -3,
                0,
                4,
                0,
                -4,
                4,
                -4,
                -4,
                4,
                1,
                -1,
                2,
                -2,
                3,
                -3,
                1,
                -1,
                2,
                -2,
                3,
                -3,
                -4,
                -4,
                -4,
                -4,
                -4,
                -4,
                4,
                4,
                4,
                4,
                4,
                4,
                0,
                0,
                5,
                -5,
                5,
                -5,
                5,
                -5,
                1,
                -1,
                2,
                -2,
                3,
                -3,
                4,
                -4,
                1,
                -1,
                2,
                -2,
                3,
                -3,
                4,
                -4,
                -5,
                -5,
                -5,
                -5,
                -5,
                -5,
                -5,
                -5,
                5,
                5,
                5,
                5,
                5,
                5,
                5,
                5,
            },
        },
        ["hexagonal"] = {
            x = {
                0,
                2,
                -2,
                1,
                -1,
                1,
                -1,
                4,
                -4,
                0,
                0,
                2,
                -2,
                -2,
                2,
                3,
                -3,
                3,
                -3,
                6,
                -6,
                1,
                -1,
                1,
                -1,
                3,
                -3,
                3,
                -3,
                4,
                -4,
                4,
                -4,
                5,
                -5,
                5,
                -5,
                8,
                -8,
                4,
                -4,
                4,
                -4,
                5,
                5,
                -5,
                -5,
                2,
                2,
                -2,
                -2,
                0,
                0,
                6,
                6,
                -6,
                -6,
                7,
                7,
                -7,
                -7,
                10,
                -10,
                5,
                5,
                -5,
                -5,
                6,
                6,
                -6,
                -6,
                7,
                7,
                -7,
                -7,
                8,
                8,
                -8,
                -8,
                9,
                9,
                -9,
                -9,
                3,
                3,
                -3,
                -3,
                1,
                1,
                -1,
                -1,
                12,
                -12,
                6,
                -6,
                6,
                -6,
                7,
                -7,
                7,
                -7,
                8,
                -8,
                8,
                -8,
                9,
                -9,
                9,
                -9,
                10,
                -10,
                10,
                -10,
                11,
                -11,
                11,
                -11,
                4,
                -4,
                4,
                -4,
                2,
                -2,
                2,
                -2,
                0,
                0,
            },
            y = {
                0,
                0,
                0,
                1,
                1,
                -1,
                -1,
                0,
                0,
                2,
                -2,
                2,
                -2,
                2,
                -2,
                1,
                -1,
                -1,
                1,
                0,
                0,
                3,
                3,
                -3,
                -3,
                3,
                -3,
                -3,
                3,
                2,
                -2,
                -2,
                2,
                1,
                -1,
                -1,
                1,
                0,
                0,
                4,
                -4,
                -4,
                4,
                3,
                -3,
                3,
                -3,
                4,
                -4,
                4,
                -4,
                4,
                -4,
                2,
                -2,
                2,
                -2,
                1,
                -1,
                1,
                -1,
                0,
                0,
                5,
                -5,
                5,
                -5,
                4,
                -4,
                4,
                -4,
                3,
                -3,
                3,
                -7,
                2,
                -2,
                2,
                -2,
                1,
                -1,
                1,
                -1,
                5,
                -5,
                5,
                -5,
                5,
                -5,
                5,
                -5,
                0,
                0,
                6,
                6,
                -6,
                -6,
                5,
                5,
                -5,
                -5,
                4,
                4,
                -4,
                -4,
                3,
                3,
                -3,
                -3,
                2,
                2,
                -2,
                -2,
                1,
                1,
                -1,
                -1,
                6,
                6,
                -6,
                -6,
                6,
                6,
                -6,
                -6,
                6,
                -6,
            },
        },
        ["pyramid"] = {
            [1] = {
                { angle = 0, distance = 0 },
            },
            [2] = {
                { angle = -1, distance = 1 },
                { angle = 1, distance = 1 },
            },
            [3] = {
                { angle = 0, distance = 0 },
                { angle = -1, distance = 1 },
                { angle = 1, distance = 1 },
            },
            [4] = {
                { angle = 0, distance = 0 },
                { angle = -1, distance = 1 },
                { angle = 1, distance = 1 },
                { angle = 0, distance = 2 },
            },
            [5] = {
                { angle = 0, distance = 0 },
                { angle = -1, distance = 1 },
                { angle = 1, distance = 1 },
                { angle = -2, distance = 2 },
                { angle = 2, distance = 2 },
            },
            [6] = {
                { angle = 0, distance = 0 },
                { angle = -1, distance = 1 },
                { angle = 1, distance = 1 },
                { angle = -2, distance = 2 },
                { angle = 2, distance = 2 },
                { angle = 0, distance = 2 },
            },
            [7] = {
                { angle = 0, distance = 0 },
                { angle = -1, distance = 1 },
                { angle = 1, distance = 1 },
                { angle = -2, distance = 2 },
                { angle = 2, distance = 2 },
                { angle = -3, distance = 3 },
                { angle = 3, distance = 3 },
            },
            [8] = {
                { angle = 0, distance = 0 },
                { angle = -1, distance = 1 },
                { angle = 1, distance = 1 },
                { angle = -2, distance = 2 },
                { angle = 2, distance = 2 },
                { angle = 0, distance = 2 },
                { angle = -3, distance = 3 },
                { angle = 3, distance = 3 },
            },
            [9] = {
                { angle = 0, distance = 0 },
                { angle = -1, distance = 1 },
                { angle = 1, distance = 1 },
                { angle = -2, distance = 2 },
                { angle = 2, distance = 2 },
                { angle = -3, distance = 3 },
                { angle = 3, distance = 3 },
                { angle = -4, distance = 4 },
                { angle = 4, distance = 4 },
            },
            [10] = {
                { angle = 0, distance = 0 },
                { angle = -1, distance = 1 },
                { angle = 1, distance = 1 },
                { angle = -2, distance = 2 },
                { angle = 2, distance = 2 },
                { angle = 0, distance = 2 },
                { angle = -3, distance = 3 },
                { angle = 3, distance = 3 },
                { angle = -2, distance = 3 },
                { angle = 2, distance = 3 },
            },
            [11] = {
                { angle = 0, distance = 0 },
                { angle = -1, distance = 1 },
                { angle = 1, distance = 1 },
                { angle = -2, distance = 2 },
                { angle = 2, distance = 2 },
                { angle = -3, distance = 3 },
                { angle = 3, distance = 3 },
                { angle = -4, distance = 4 },
                { angle = 4, distance = 4 },
                { angle = -3, distance = 4 },
                { angle = 3, distance = 4 },
            },
            [12] = {
                { angle = 0, distance = 0 },
                { angle = -1, distance = 1 },
                { angle = 1, distance = 1 },
                { angle = -2, distance = 2 },
                { angle = 2, distance = 2 },
                { angle = 0, distance = 2 },
                { angle = -3, distance = 3 },
                { angle = 3, distance = 3 },
                { angle = -2, distance = 3 },
                { angle = 2, distance = 3 },
                { angle = -1, distance = 3 },
                { angle = 1, distance = 3 },
            },
            [13] = {
                { angle = 0, distance = 0 },
                { angle = -1, distance = 1 },
                { angle = 1, distance = 1 },
                { angle = -2, distance = 2 },
                { angle = 2, distance = 2 },
                { angle = -3, distance = 3 },
                { angle = 3, distance = 3 },
                { angle = 0, distance = 3 },
                { angle = -2, distance = 4 },
                { angle = 2, distance = 4 },
                { angle = -1, distance = 5 },
                { angle = 1, distance = 5 },
                { angle = 0, distance = 6 },
            },
            [14] = {
                { angle = 0, distance = 0 },
                { angle = -1, distance = 1 },
                { angle = 1, distance = 1 },
                { angle = -2, distance = 2 },
                { angle = 2, distance = 2 },
                { angle = 0, distance = 2 },
                { angle = -3, distance = 3 },
                { angle = 3, distance = 3 },
                { angle = 0, distance = 4 },
                { angle = -2, distance = 4 },
                { angle = 2, distance = 4 },
                { angle = -1, distance = 5 },
                { angle = 1, distance = 5 },
                { angle = 0, distance = 6 },
            },
            [15] = {
                { angle = 0, distance = 0 },
                { angle = -1, distance = 1 },
                { angle = 1, distance = 1 },
                { angle = -2, distance = 2 },
                { angle = 2, distance = 2 },
                { angle = 0, distance = 2 },
                { angle = -3, distance = 3 },
                { angle = 3, distance = 3 },
                { angle = 0, distance = 3 },
                { angle = 0, distance = 4 },
                { angle = -2, distance = 4 },
                { angle = 2, distance = 4 },
                { angle = -1, distance = 5 },
                { angle = 1, distance = 5 },
                { angle = 0, distance = 6 },
            },
        },
    }
    station_spacing = {
        [ST.SMALL_STATION] = {
            neb = 9000,
            touch = 300,
            defend = 2600,
            platform = 1200,
            outer_platform = 7500,
        },
        [ST.MEDIUM_STATION] = {
            neb = 10800,
            touch = 1200,
            defend = 4000,
            platform = 2400,
            outer_platform = 9100,
        },
        [ST.LARGE_STATION] = {
            neb = 11600,
            touch = 1400,
            defend = 4600,
            platform = 2800,
            outer_platform = 9700,
        },
        [ST.HUGE_STATION] = {
            neb = 12300,
            touch = 2000,
            defend = 4960,
            platform = 3500,
            outer_platform = 10100,
        },
    }
    missile_types = { "Homing", "Nuke", "Mine", "EMP", "HVLI" }
end
function setGlobals()
    defender_pirate_state = _("msgMainscreen", "Noble Defenders")
    session_factions = {
        "Human Navy",
        "Kraylor",
        "Independent",
        "Ktlitans",
        "Ghosts",
        "Arlenians",
        "Exuari",
        "USN",
        "TSN",
        "CUF",
    }
    player_factions = { "Human Navy", "CUF", "USN", "TSN" }
    player_faction = tableSelectRandom(player_factions)
    friendly_factions = { "Human Navy", player_faction }
    if player_faction == "Human Navy" then
        friendly_factions = { "Human Navy", "CUF", "USN", "TSN" }
    end
    friendly_lookup_factions = {}
    for i, faction in ipairs(friendly_factions) do
        friendly_lookup_factions[faction] = true
    end
    local factions = {
        "Independent",
        "Human Navy",
        "CUF",
        "USN",
        "TSN",
        "Kraylor",
        "Exuari",
        "Ghosts",
        "Ktlitans",
        "Arlenians",
    }
    non_enemy_factions = {}
    enemy_factions = {}
    comprehensive_enemy_factions = {
        ["Human Navy"] = { "Kraylor", "Exuari", "Ghosts", "Ktlitans" },
        ["CUF"] = { "Kraylor", "Exuari", "Ghosts" },
        ["TSN"] = { "Kraylor", "Arlenians", "Exuari", "Ktlitans", "USN" },
        ["USN"] = { "Exuari", "Ghosts", "Ktlitans", "TSN" },
    }
    enemy_factions = comprehensive_enemy_factions[player_faction]
    enemy_lookup_factions = {}
    for i, faction in ipairs(enemy_factions) do
        enemy_lookup_factions[faction] = true
    end
    comprehensive_non_enemy_factions = {
        ["Human Navy"] = {
            "Human Navy",
            "Independent",
            "CUF",
            "USN",
            "TSN",
            "Arlenians",
        },
        ["CUF"] = {
            "Human Navy",
            "Independent",
            "CUF",
            "USN",
            "TSN",
            "Arlenians",
            "Ktlitans",
        },
        ["TSN"] = { "Human Navy", "Independent", "TSN", "CUF", "Ghosts" },
        ["USN"] = {
            "Human Navy",
            "Independent",
            "CUF",
            "USN",
            "Kraylor",
            "Arlenians",
        },
    }
    non_enemy_factions = comprehensive_non_enemy_factions[player_faction]
    non_enemy_lookup_factions = {}
    for i, faction in ipairs(non_enemy_factions) do
        non_enemy_lookup_factions[faction] = true
    end
    deployed_players = {}
    deployed_player_count = 0
    sensor_impact = 1 --normal
    player_starting_templates = {
        [ST.PHOBOS_M3P] = {
            base = "Phobos M3P",
            del = false,
            warp = { speed = 900 },
        },
        ["Deimos"] = {
            base = "Phobos M3P",
            del = false,
            warp = { speed = 400 },
            shields = { f = 150, b = 80 }, --original: f:100 b:100
            hull = 160, --original: 200
            spin = 15, --original: 10
            accel = { f = 30, b = 25 }, --original: f:20 b:20
            impulse = { f = 80, b = 72 }, --original: f:80 b:80
            beam = { --	0:y+	1:y-	original: arc:90 dir:-15,15 rng:1200 cyc:8 dmg:6 (no 3rd beam)
                {
                    idx = 0,
                    arc = 60,
                    dir = 20,
                    rng = 1200,
                    cyc = 4.5,
                    dmg = 5.5,
                },
                {
                    idx = 1,
                    arc = 60,
                    dir = -20,
                    rng = 1200,
                    cyc = 4.5,
                    dmg = 5.5,
                },
                {
                    idx = 2,
                    arc = 10,
                    dir = 0,
                    rng = 1500,
                    cyc = 6,
                    dmg = 2.5,
                    tarc = 160,
                    tur = 1,
                },
            },
            tube = { --	0:y+	1:y-	original: dir:-1,1 siz:m tim:10
                {
                    idx = 0,
                    dir = 4,
                    siz = "large",
                    tim = 20,
                    only = "Homing",
                },
                {
                    idx = 1,
                    dir = -4,
                    siz = "large",
                    tim = 20,
                    only = "Homing",
                },
                { idx = 2, dir = 0, siz = "small", tim = 8, only = "EMP" },
                { idx = 3, dir = 90, siz = "medium", tim = 10, exc = "Mine" },
                { idx = 4, dir = -90, siz = "medium", tim = 10, exc = "Mine" },
                {
                    idx = 5,
                    dir = 180,
                    siz = "medium",
                    tim = 15,
                    only = "Mine",
                },
            },
            missile = {
                { typ = "EMP", qty = 6 }, --original: 3
            },
        },
        ["Rodent"] = {
            base = "Phobos M3P",
            del = false,
            rcrew = 5, --original: 3
            jump = { s = 4, l = 37 },
            shields = { f = 100, b = 50 }, --original: f:100 b:100
            hull = 150, --original: 200
            beam = { --	0:y+	1:y-	original: arc:90 dir:-15,15 rng:1200 cyc:8 dmg:6 (no 3rd beam)
                {
                    idx = 0,
                    arc = 60,
                    dir = 15,
                    rng = 1200,
                    cyc = 7,
                    dmg = 5,
                },
                { idx = 1, arc = 60, dir = -15, rng = 1200, cyc = 7, dmg = 5 },
                {
                    idx = 2,
                    arc = 10,
                    dir = 0,
                    rng = 600,
                    cyc = 7,
                    dmg = 4,
                    tarc = 270,
                    tur = 0.4,
                },
                {
                    idx = 3,
                    arc = 10,
                    dir = 180,
                    rng = 500,
                    cyc = 7,
                    dmg = 4,
                    tarc = 270,
                    tur = 0.4,
                },
            },
            tube = { --	0:y+	1:y-	original: dir:-1,1 siz:m tim:10
                {
                    idx = 0,
                    dir = 0,
                    siz = "small",
                    tim = 8,
                    only = "HVLI",
                    inc = "Homing",
                },
                {
                    idx = 1,
                    dir = 0,
                    siz = "small",
                    tim = 8,
                    only = "HVLI",
                    inc = "Homing",
                },
                {
                    idx = 2,
                    dir = -90,
                    siz = "medium",
                    tim = 10,
                    only = "EMP",
                    inc = "Nuke",
                },
                {
                    idx = 3,
                    dir = 90,
                    siz = "large",
                    tim = 20,
                    only = "EMP",
                    inc = "Nuke",
                },
                {
                    idx = 4,
                    dir = 180,
                    siz = "medium",
                    tim = 15,
                    only = "Mine",
                },
            },
        },
        ["Roc"] = {
            base = "Phobos M3P",
            del = false,
            rcrew = 5, --original: 3
            warp = { speed = 480 },
            shields = { f = 150, b = 80 }, --original: f:100 b:100
            impulse = { f = 75, b = 72 }, --original: f:80 b:80
            spin = 9, --original: 10
            accel = { f = 15, b = 25 }, --original: f:20 b:20
            beam = { --	0:y+	1:y-	original: arc:90 dir:-15,15 rng:1200 cyc:8 dmg:6 (no 3rd beam)
                {
                    idx = 0,
                    arc = 30,
                    dir = 10,
                    rng = 1000,
                    cyc = 8,
                    dmg = 6,
                },
                { idx = 1, arc = 30, dir = -10, rng = 1000, cyc = 8, dmg = 6 },
                {
                    idx = 2,
                    arc = 10,
                    dir = 180,
                    rng = 1500,
                    cyc = 2,
                    dmg = 1,
                    tarc = 310,
                    tur = 1,
                },
            },
            tube = { --	0:y+	1:y-	original: dir:-1,1 siz:m tim:10
                {
                    idx = 0,
                    dir = 4,
                    siz = "small",
                    tim = 5,
                    only = "HVLI",
                    inc = "Homing",
                },
                {
                    idx = 1,
                    dir = -4,
                    siz = "small",
                    tim = 5,
                    only = "HVLI",
                    inc = "Homing",
                },
                { idx = 2, dir = 0, siz = "medium", tim = 10, only = "HVLI" },
                { idx = 3, dir = 90, siz = "medium", tim = 10, exc = "Mine" },
                { idx = 4, dir = 90, siz = "large", tim = 20, exc = "Mine" },
                { idx = 5, dir = -90, siz = "medium", tim = 10, exc = "Mine" },
                { idx = 6, dir = -90, siz = "large", tim = 20, exc = "Mine" },
                {
                    idx = 7,
                    dir = 180,
                    siz = "medium",
                    tim = 10,
                    only = "Mine",
                },
            },
            missile = {
                { typ = "HVLI", qty = 18 }, --original: 0
            },
        },
        [ST.ATLANTIS] = {
            base = "Atlantis",
            del = false,
            tube = { --	0:y-	1:y+	original: dir:-90,-90,90,90,180 siz:m tim:8
                { idx = 0, dir = -90, siz = "medium", tim = 8, exc = "Mine" },
                { idx = 1, dir = 90, siz = "medium", tim = 8, exc = "Mine" },
                { idx = 2, dir = -90, siz = "medium", tim = 8, exc = "Mine" },
                { idx = 3, dir = 90, siz = "medium", tim = 8, exc = "Mine" },
                { idx = 4, dir = 180, siz = "medium", tim = 8, only = "Mine" },
            },
        },
        ["Atlantis II"] = {
            base = "Atlantis",
            del = false,
            rcrew = 4, --original: 3
            impulse = { f = 80, b = 72 }, --original: f:90 b:90
            tube = { --	0:y-	1:y+	original: dir:-90,-90,90,90,180 siz:m tim:8
                { idx = 0, dir = -60, siz = "medium", tim = 8, exc = "Mine" },
                { idx = 1, dir = 60, siz = "medium", tim = 8, exc = "Mine" },
                { idx = 2, dir = -120, siz = "medium", tim = 8, exc = "Mine" },
                { idx = 3, dir = 120, siz = "medium", tim = 8, exc = "Mine" },
                {
                    idx = 4,
                    dir = 0,
                    siz = "medium",
                    tim = 6,
                    only = "HVLI",
                    inc = "Homing",
                },
                {
                    idx = 5,
                    dir = 180,
                    siz = "medium",
                    tim = 10,
                    only = "Mine",
                },
            },
        },
        ["Proto-Atlantis"] = {
            base = "Atlantis",
            del = false,
            rcrew = 4, --original: 3
            impulse = { f = 70, b = 72 }, --original: f:90 b:90
            spin = 14, --original: 10
            jump = { s = 0, l = 0 }, --original: s:5 l:50
            warp = { speed = 650 },
            hull = 200, --original: 250
            shields = { f = 150, b = 150 }, --original: f:200 b:200
            tube = { --	0:y-	1:y+	original: dir:-90,-90,90,90,180 siz:m tim:8
                { idx = 0, dir = -90, siz = "large", tim = 12, only = "HVLI" },
                { idx = 1, dir = 90, siz = "large", tim = 12, only = "HVLI" },
                { idx = 2, dir = 0, siz = "medium", tim = 8, only = "HVLI" },
                {
                    idx = 3,
                    dir = -90,
                    siz = "medium",
                    tim = 8,
                    only = "HVLI",
                    inc = "Homing",
                    inc2 = "EMP",
                    inc3 = "Nuke",
                },
                {
                    idx = 4,
                    dir = 90,
                    siz = "medium",
                    tim = 8,
                    only = "HVLI",
                    inc = "Homing",
                    inc2 = "EMP",
                    inc3 = "Nuke",
                },
                {
                    idx = 5,
                    dir = 180,
                    siz = "medium",
                    tim = 15,
                    only = "Mine",
                },
            },
        },
        ["Amalgam"] = {
            base = "Atlantis",
            del = false,
            rcrew = 5, --original: 3
            jump = { s = 4, l = 40 }, --original: s:5 l:50
            impulse = { f = 80, b = 75 }, --original: f:90 b:90
            spin = 8, --original: 10
            shields = { f = 150, b = 150 }, --original: f:200 b:200
            beam = { --	0:y+	1:y-	original: arc:90 dir:-15,15 rng:1200 cyc:8 dmg:6 (no 3rd beam)
                {
                    idx = 0,
                    arc = 90,
                    dir = -20,
                    rng = 1200,
                    cyc = 6,
                    dmg = 8,
                },
                {
                    idx = 1,
                    arc = 90,
                    dir = 20,
                    rng = 1200,
                    cyc = 6,
                    dmg = 8,
                },
                {
                    idx = 2,
                    arc = 10,
                    dir = -60,
                    rng = 1000,
                    cyc = 4,
                    dmg = 6,
                    tarc = 60,
                    tur = 0.6,
                },
                {
                    idx = 3,
                    arc = 10,
                    dir = 60,
                    rng = 1000,
                    cyc = 4,
                    dmg = 6,
                    tarc = 60,
                    tur = 0.6,
                },
            },
            tube = { --	0:y-	1:y+	original: dir:-90,-90,90,90,180 siz:m tim:8
                {
                    idx = 0,
                    dir = -90,
                    siz = "large",
                    tim = 8,
                    only = "Homing",
                },
                {
                    idx = 1,
                    dir = 90,
                    siz = "large",
                    tim = 8,
                    only = "Homing",
                },
                {
                    idx = 2,
                    dir = 180,
                    siz = "medium",
                    tim = 16,
                    only = "Mine",
                },
                {
                    idx = 3,
                    dir = 180,
                    siz = "medium",
                    tim = 16,
                    only = "Mine",
                },
            },
            missile = {
                { typ = "Homing", qty = 16 }, --original: 12
                { typ = "Mine", qty = 10 }, --original: 8
                { typ = "HVLI", qty = 0 }, --original: 0
                { typ = "EMP", qty = 0 }, --original: 6
                { typ = "Nuke", qty = 0 }, --original: 4
            },
        },
        [ST.MAVERICK] = { base = "Maverick", del = false },
        ["Maverick XP"] = {
            base = "Maverick",
            del = false,
            impulse = { f = 65, b = 65 }, --original: f:80 b:80
            warp = { speed = 0 }, --original:800
            jump = { s = 2, l = 20 },
            beam = { --original: arc:10,90,90,40,40,10 dir:0,-20,20,-70,70,180 rng:2,1.5,1.5,1,1,.8 cyc:6,6,6,4,4,6 dmg:6,8,8,6,6,4
                {
                    idx = 0,
                    arc = 10,
                    dir = 0,
                    rng = 1000,
                    cyc = 15,
                    dmg = 20,
                    tarc = 270,
                    tur = 0.2,
                },
                { idx = 1, arc = 0, dir = 0, rng = 0, cyc = 0, dmg = 0 },
                { idx = 2, arc = 0, dir = 0, rng = 0, cyc = 0, dmg = 0 },
                { idx = 3, arc = 0, dir = 0, rng = 0, cyc = 0, dmg = 0 },
                { idx = 4, arc = 0, dir = 0, rng = 0, cyc = 0, dmg = 0 },
                { idx = 5, arc = 0, dir = 0, rng = 0, cyc = 0, dmg = 0 },
            },
        },
        [ST.CRUCIBLE] = { base = ST.CRUCIBLE, del = false },
        ["Caretaker"] = {
            base = ST.CRUCIBLE,
            del = false,
            warp = { speed = 0 }, --original:750
            jump = { s = 4, l = 40 },
            beam = { --original: arc:70 dir:-30,30 rng:1 cyc:6 dmg:5
                {
                    idx = 0,
                    arc = 80,
                    dir = -90,
                    rng = 1000,
                    cyc = 5,
                    dmg = 6,
                },
                {
                    idx = 1,
                    arc = 80,
                    dir = 90,
                    rng = 1000,
                    cyc = 5,
                    dmg = 6,
                },
            },
            tube = { --original: dir:0,0,0,-90,90,180 siz:s,m,l,m,m,m tim:6
                { idx = 0, dir = 0, siz = "small", tim = 6 },
                {
                    idx = 1,
                    dir = 0,
                    siz = "medium",
                    tim = 6,
                    only = "EMP",
                    inc = "Nuke",
                },
                { idx = 2, dir = 0, siz = "large", tim = 6, only = "Homing" },
                { idx = 3, dir = 180, siz = "medium", tim = 6, only = "Mine" },
            },
        },
        ["Butler"] = {
            base = ST.CRUCIBLE,
            del = false,
            impulse = { f = 70, b = 65 }, --original: f:80 b:80
            warp = { speed = 450 }, --original:750
            hull = 120, --original: 160
            shields = { f = 120, b = 120 }, --original: f:160 b:160
            beam = { --original: arc:70 dir:-30,30 rng:1 cyc:6 dmg:5
                {
                    idx = 0,
                    arc = 10,
                    dir = -60,
                    rng = 900,
                    cyc = 6,
                    dmg = 6,
                    tarc = 140,
                    tur = 0.6,
                },
                {
                    idx = 1,
                    arc = 10,
                    dir = 60,
                    rng = 900,
                    cyc = 6,
                    dmg = 6,
                    tarc = 140,
                    tur = 0.6,
                },
            },
            tube = { --original: dir:0,0,0,-90,90,180 siz:s,m,l,m,m,m tim:6
                { idx = 0, dir = 0, siz = "small", tim = 6, only = "Nuke" },
                { idx = 1, dir = 0, siz = "medium", tim = 6, only = "EMP" },
                { idx = 2, dir = 0, siz = "large", tim = 6, only = "HVLI" },
                { idx = 3, dir = 180, siz = "large", tim = 6, only = "Homing" },
            },
            missile = {
                { typ = "Homing", qty = 5 }, --original: 8
                { typ = "EMP", qty = 5 }, --original: 6
                { typ = "Mine", qty = 0 }, --original: 6
            },
        },
        [ST.VINDICATOR] = { base = ST.VINDICATOR, del = false },
        ["Raven"] = {
            base = ST.VINDICATOR,
            del = false,
            warp = { speed = 400 },
            jump = { s = 0, l = 0 }, --original: s:5 l:50
            shields = { f = 120, b = 120 }, --original: f:80 b:80
            hull = 160, --original: 200
            beam = { --	0:y-	1:y+	original: arc:90 dir:-15,15 rng:1000 cyc=6 dmg=10
                {
                    idx = 0,
                    arc = 10,
                    dir = -90,
                    rng = 1000,
                    cyc = 6,
                    dmg = 10,
                    tarc = 90,
                    tur = 1,
                },
                {
                    idx = 1,
                    arc = 10,
                    dir = 90,
                    rng = 1000,
                    cyc = 6,
                    dmg = 10,
                    tarc = 90,
                    tur = 1,
                },
            },
            tube = { --	0,1:z-	original: dir:-5,5,180 siz:m tim:8
                { idx = 0, dir = -30, siz = "small", tim = 8, only = "Nuke" },
                { idx = 1, dir = 30, siz = "small", tim = 8, only = "Nuke" },
                { idx = 2, dir = -60, siz = "small", tim = 8, only = "EMP" },
                { idx = 3, dir = 60, siz = "small", tim = 8, only = "EMP" },
                {
                    idx = 4,
                    dir = 0,
                    siz = "large",
                    tim = 12,
                    only = "Homing",
                },
                {
                    idx = 5,
                    dir = 180,
                    siz = "medium",
                    tim = 10,
                    only = "Mine",
                },
            },
            missile = {
                { typ = "Homing", qty = 8 }, --original: 12
                { typ = "EMP", qty = 4 }, --original: 6
                { typ = "Mine", qty = 6 }, --original: 8
            },
        },
        ["Peacock"] = {
            base = ST.VINDICATOR,
            del = false,
            rcrew = 4, --original: 3
            impulse = { f = 75, b = 65 }, --original: f:90 b:90
            spin = 9, --original: 10
            shields = { f = 120, b = 100 }, --original: f:80 b:80
            jump = { s = 3, l = 30 }, --original: s:5 l:50
            beam = { --	0:y-	1:y+	original: arc:90 dir:-15,15 rng:1000 cyc=6 dmg=10
                {
                    idx = 0,
                    arc = 10,
                    dir = -45,
                    rng = 800,
                    cyc = 2,
                    dmg = 2,
                    tarc = 60,
                    tur = 0.4,
                },
                {
                    idx = 1,
                    arc = 10,
                    dir = 45,
                    rng = 800,
                    cyc = 2,
                    dmg = 2,
                    tarc = 60,
                    tur = 0.4,
                },
                {
                    idx = 2,
                    arc = 10,
                    dir = -15,
                    rng = 1000,
                    cyc = 2,
                    dmg = 2,
                    tarc = 60,
                    tur = 0.8,
                },
                {
                    idx = 3,
                    arc = 10,
                    dir = 15,
                    rng = 1000,
                    cyc = 2,
                    dmg = 2,
                    tarc = 60,
                    tur = 0.8,
                },
            },
            tube = { --	0,1:z-	original: dir:-5,5,180 siz:m tim:8
                {
                    idx = 0,
                    dir = -5,
                    siz = "small",
                    tim = 5,
                    only = "Homing",
                },
                { idx = 1, dir = 5, siz = "small", tim = 5, only = "Homing" },
                { idx = 2, dir = -90, siz = "medium", tim = 8, only = "EMP" },
                {
                    idx = 3,
                    dir = 90,
                    siz = "medium",
                    tim = 8,
                    only = "Nuke",
                },
                {
                    idx = 4,
                    dir = 180,
                    siz = "medium",
                    tim = 12,
                    only = "Mine",
                },
            },
            missile = {
                { typ = "Homing", qty = 16 }, --original: 12
                { typ = "EMP", qty = 5 }, --original: 6
                { typ = "Nuke", qty = 3 }, --original: 4
            },
        },
        [ST.AVALANCHE] = { base = ST.AVALANCHE, del = false },
        ["Mantis"] = {
            base = ST.AVALANCHE,
            del = false,
            beam = {
                {
                    idx = 0,
                    arc = 60,
                    dir = -15,
                    rng = 1000,
                    cyc = 6,
                    dmg = 4,
                },
                {
                    idx = 1,
                    arc = 60,
                    dir = 15,
                    rng = 1000,
                    cyc = 6,
                    dmg = 4,
                },
            },
            tube = { --	0:y-	1:y+	--original: dir:0,0,90,90,-90,-90,180 siz:m tim:8
                { idx = 0, dir = -2, siz = "small", tim = 5, only = "HVLI" },
                { idx = 1, dir = 2, siz = "small", tim = 5, only = "HVLI" },
                {
                    idx = 2,
                    dir = -90,
                    siz = "medium",
                    tim = 8,
                    inc = "EMP",
                    inc2 = "Nuke",
                },
                {
                    idx = 3,
                    dir = 90,
                    siz = "medium",
                    tim = 8,
                    inc = "EMP",
                    inc2 = "Nuke",
                },
                { idx = 4, dir = 180, siz = "medium", tim = 8, only = "Mine" },
            },
            missile = {
                { typ = "Homing", qty = 8 }, --original: 30
                { typ = "HVLI", qty = 12 }, --original: 0
                { typ = "EMP", qty = 6 }, --original: 10
                { typ = "Mine", qty = 3 }, --original: 12
                { typ = "Nuke", qty = 3 }, --original: 8
            },
        },
        ["Midian"] = {
            base = ST.AVALANCHE,
            del = false,
            warp = { speed = 350 }, --original:800
            beam = {
                {
                    idx = 0,
                    arc = 50,
                    dir = -20,
                    rng = 1000,
                    cyc = 6,
                    dmg = 4,
                },
                {
                    idx = 1,
                    arc = 50,
                    dir = 20,
                    rng = 1000,
                    cyc = 6,
                    dmg = 4,
                },
                {
                    idx = 2,
                    arc = 10,
                    dir = 180,
                    rng = 1000,
                    cyc = 6,
                    dmg = 3,
                    tarc = 220,
                    tur = 0.3,
                },
            },
            tube = { --	0:y-	1:y+	--original: dir:0,0,90,90,-90,-90,180 siz:m tim:8
                {
                    idx = 0,
                    dir = -2,
                    siz = "small",
                    tim = 5,
                    only = "Homing",
                },
                { idx = 1, dir = 2, siz = "small", tim = 5, only = "Homing" },
                {
                    idx = 2,
                    dir = -90,
                    siz = "medium",
                    tim = 12,
                    only = "HVLI",
                    inc = "EMP",
                    inc2 = "Nuke",
                },
                {
                    idx = 3,
                    dir = 90,
                    siz = "medium",
                    tim = 12,
                    only = "HVLI",
                    inc = "EMP",
                    inc2 = "Nuke",
                },
                {
                    idx = 4,
                    dir = 180,
                    siz = "medium",
                    tim = 15,
                    only = "Mine",
                },
            },
            missile = {
                { typ = "Homing", qty = 16 }, --original: 30
                { typ = "HVLI", qty = 16 }, --original: 0
                { typ = "EMP", qty = 5 }, --original: 10
                { typ = "Mine", qty = 8 }, --original: 12
                { typ = "Nuke", qty = 3 }, --original: 8
            },
        },
        ["Mortar"] = {
            base = ST.AVALANCHE,
            del = false,
            hull = 160, --original: 200
            shields = { f = 160, b = 160 }, --original: f:110 b:70
            impulse = { f = 80, b = 80 }, --original: f:60 b:60
            spin = 15, --original: 8
            accel = { f = 40, b = 40 }, --original: f:15 b:15
            cmbmov = { b = 400, s = 250 }, --original: b:450 s:200
            beam = {
                {
                    idx = 0,
                    arc = 60,
                    dir = -15,
                    rng = 1500,
                    cyc = 6,
                    dmg = 6,
                    bdt = "emp",
                },
                {
                    idx = 1,
                    arc = 60,
                    dir = 15,
                    rng = 1500,
                    cyc = 6,
                    dmg = 6,
                    bdt = "emp",
                },
                {
                    idx = 2,
                    arc = 60,
                    dir = -15,
                    rng = 1000,
                    cyc = 6,
                    dmg = 6,
                    bdt = "kinetic",
                },
                {
                    idx = 3,
                    arc = 60,
                    dir = 15,
                    rng = 1000,
                    cyc = 6,
                    dmg = 6,
                    bdt = "kinetic",
                },
                {
                    idx = 4,
                    arc = 60,
                    dir = -15,
                    rng = 500,
                    cyc = 6,
                    dmg = 6,
                },
                {
                    idx = 5,
                    arc = 60,
                    dir = 15,
                    rng = 500,
                    cyc = 6,
                    dmg = 6,
                },
            },
            tube = { --	0:y-	1:y+	--original: dir:0,0,90,90,-90,-90,180 siz:m tim:8
                { idx = 0, dir = -90, siz = "medium", tim = 8, exc = "Mine" },
                { idx = 1, dir = 90, siz = "medium", tim = 8, exc = "Mine" },
                { idx = 2, dir = 180, siz = "medium", tim = 8, only = "Mine" },
            },
            missile = {
                { typ = "Homing", qty = 6 }, --original: 30
                { typ = "HVLI", qty = 10 }, --original: 0
                { typ = "EMP", qty = 4 }, --original: 10
                { typ = "Mine", qty = 3 }, --original: 12
                { typ = "Nuke", qty = 2 }, --original: 8
            },
        },
        [ST.HATHCOCK] = { base = ST.HATHCOCK, del = false },
        ["Scatter"] = {
            base = ST.HATHCOCK,
            del = false,
            rcrew = 4, --original: 2
            impulse = { f = 65, b = 70 }, --original: f:50 b:50
            accel = { f = 12, b = 9 }, --original: f:8 b:8
            jump = { s = 2.5, l = 28 }, --original: s:5 l:50
            shields = { f = 150, b = 100 }, --original: f:70 b:70
            beam = { --original: arc:4,20,60,90 dir:0 rng:1.4,1.2,1,.8 cyc:6 dmg:4
                {
                    idx = 0,
                    arc = 10,
                    dir = 0,
                    rng = 1200,
                    cyc = 5,
                    dmg = 4,
                },
                {
                    idx = 1,
                    arc = 80,
                    dir = -20,
                    rng = 1000,
                    cyc = 5,
                    dmg = 5,
                },
                {
                    idx = 2,
                    arc = 80,
                    dir = 20,
                    rng = 1000,
                    cyc = 5,
                    dmg = 5,
                },
                {
                    idx = 3,
                    arc = 10,
                    dir = 180,
                    rng = 1000,
                    cyc = 5,
                    dmg = 5,
                    tarc = 90,
                    tur = 0.4,
                },
            },
            tube = { --original: dir:-90,90 siz:m tim:15
                { idx = 0, dir = -90, siz = "medium", tim = 15, exc = "Mine" },
                { idx = 1, dir = 90, siz = "medium", tim = 15, exc = "Mine" },
                {
                    idx = 2,
                    dir = 180,
                    siz = "medium",
                    tim = 30,
                    only = "Mine",
                },
            },
            missile = {
                { typ = "Mine", qty = 3 }, --original: 0
            },
        },
        [ST.NAUTILUS] = { base = ST.NAUTILUS, del = false },
        ["Nusret"] = {
            base = ST.NAUTILUS,
            del = false,
            jump = { s = 2.5, l = 25 }, --original: s:5 l:50
            shields = { f = 100, b = 100 }, --original: f:60 b:60
            tube = { --original: dir:180 siz:m tim:10
                {
                    idx = 0,
                    dir = -60,
                    siz = "medium",
                    tim = 10,
                    only = "Homing",
                },
                {
                    idx = 1,
                    dir = 60,
                    siz = "medium",
                    tim = 10,
                    only = "Homing",
                },
                {
                    idx = 2,
                    dir = 180,
                    siz = "medium",
                    tim = 10,
                    only = "Mine",
                },
            },
            missile = {
                { typ = "Homing", qty = 8 }, --original: 0
                { typ = "Mine", qty = 8 }, --original: 12
            },
        },
        [ST.FLAVIA] = { base = "Flavia P.Falcon", del = false },
        ["Era"] = {
            base = "Flavia P.Falcon",
            del = false,
            spin = 15, --original: 10
            shields = { f = 70, b = 100 }, --original: f:70 b:70
            beam = { --original: arc:40 dir:170,190 rng:1200 cyc:6 dmg:6
                {
                    idx = 0,
                    arc = 10,
                    dir = 0,
                    rng = 1200,
                    cyc = 6,
                    dmg = 6,
                    tarc = 300,
                    tur = 0.5,
                },
                {
                    idx = 1,
                    arc = 80,
                    dir = 180,
                    rng = 1200,
                    cyc = 6,
                    dmg = 6,
                },
            },
        },
        ["Flavia 2C"] = {
            base = "Flavia P.Falcon",
            del = false,
            spin = 20, --original: 10
            impulse = { f = 70, b = 65 }, --original: f:60 b:60
            shields = { f = 120, b = 120 }, --original: f:70 b:70
            beam = { --original: arc:40 dir:170,190 rng:1200 cyc:6 dmg:6
                {
                    idx = 0,
                    arc = 40,
                    dir = -10,
                    rng = 1200,
                    cyc = 5.5,
                    dmg = 6.5,
                },
                {
                    idx = 1,
                    arc = 40,
                    dir = 10,
                    rng = 1200,
                    cyc = 5.5,
                    dmg = 6.5,
                },
            },
            tube = { --original: dir:180 siz:m tim:20
                {
                    idx = 0,
                    dir = -90,
                    siz = "large",
                    tim = 20,
                    only = "Homing",
                },
                {
                    idx = 1,
                    dir = 90,
                    siz = "large",
                    tim = 20,
                    only = "Homing",
                },
                { idx = 2, dir = 180, siz = "medium", tim = 20 },
            },
            missile = {
                { typ = "Mine", qty = 2 }, --original: 1
                { typ = "EMP", qty = 2 }, --original: 0
                { typ = "Nuke", qty = 2 }, --original: 1
                { typ = "Homing", qty = 6 }, --original: 3
            },
        },
        [ST.PIRANHA] = { base = "Piranha", del = false },
        ["Squid"] = {
            base = "Piranha",
            del = false,
            rcrew = 5, --original: 2
            shields = { f = 100, b = 100 }, --original: f:70 b:70
            hull = 130, --original: 120
            jump = { s = 2, l = 20 }, --original: s:5 l:50
            beam = {
                {
                    idx = 0,
                    arc = 10,
                    dir = 0,
                    rng = 1000,
                    cyc = 4,
                    dmg = 4,
                    tarc = 80,
                    tur = 1,
                },
            },
            tube = { --original: dir:-90,-90,-90,90,90,90,170,190 siz:lmllmlmm tim:8
                { idx = 0, dir = 0, siz = "large", tim = 12, only = "HVLI" },
                { idx = 1, dir = -90, siz = "medium", tim = 8, exc = "Mine" },
                {
                    idx = 2,
                    dir = -90,
                    siz = "large",
                    tim = 10,
                    only = "Homing",
                },
                { idx = 3, dir = 0, siz = "large", tim = 12, only = "HVLI" },
                { idx = 4, dir = 90, siz = "medium", tim = 8, exc = "Mine" },
                { idx = 5, dir = 90, siz = "large", tim = 10, only = "Homing" },
                {
                    idx = 6,
                    dir = 170,
                    siz = "medium",
                    tim = 15,
                    only = "Mine",
                },
                {
                    idx = 7,
                    dir = 190,
                    siz = "medium",
                    tim = 15,
                    only = "Mine",
                },
            },
            missile = {
                { typ = "HVLI", qty = 10 }, --original: 20
                { typ = "Homing", qty = 10 }, --original: 12
                { typ = "Mine", qty = 6 }, --original: 8
                { typ = "EMP", qty = 4 }, --original: 0
                { typ = "Nuke", qty = 4 }, --original: 6
            },
        },
        [ST.REPULSE] = { base = "Repulse", del = false },
        ["Interlock"] = {
            base = "Repulse",
            del = false,
            hull = 250, --original: 120
            shields = { f = 120, b = 120 }, --original: f:80 b:80
            jump = { s = 3.5, l = 35 }, --original: s:5 l:50
            beam = { --original: arc:10 dir:90,-90 rng:1200 cyc:6 dmg:5 tarc:200 tur:5
                {
                    idx = 0,
                    arc = 10,
                    dir = 0,
                    rng = 900,
                    cyc = 6,
                    dmg = 6,
                    tarc = 100,
                    tur = 1,
                },
                {
                    idx = 1,
                    arc = 10,
                    dir = 180,
                    rng = 900,
                    cyc = 6,
                    dmg = 4,
                    tarc = 180,
                    tur = 1,
                },
                {
                    idx = 2,
                    arc = 110,
                    dir = -35,
                    rng = 300,
                    cyc = 6,
                    dmg = 10,
                },
                {
                    idx = 3,
                    arc = 110,
                    dir = 35,
                    rng = 300,
                    cyc = 6,
                    dmg = 10,
                },
                { idx = 4, arc = 60, dir = -20, rng = 600, cyc = 6, dmg = 8 },
                { idx = 5, arc = 60, dir = 20, rng = 600, cyc = 6, dmg = 8 },
            },
            tube = { --original: dir:0,180 siz:m tim:20
                { idx = 0, dir = -90, siz = "large", tim = 20, exc = "Mine" },
                { idx = 1, dir = 90, siz = "large", tim = 20, exc = "Mine" },
                {
                    idx = 2,
                    dir = 180,
                    siz = "medium",
                    tim = 20,
                    only = "Mine",
                },
            },
            missile = {
                { typ = "Mine", qty = 4 }, --original: 0
            },
        },
        [ST.SAIPAN] = { base = "Saipan", del = false },
        ["Moose"] = {
            base = "Saipan",
            del = false,
            hull = 200, --original: 180
            shields = { f = 220, b = 160 }, --original: f:90 b:90
            impulse = { f = 70, b = 80 }, --original: f:80 b:80
            accel = { f = 10, b = 8 }, --original: f:20 b:20
            cmbmov = { b = 350, s = 300 }, --original: b:400 s:250
            beam = { --	0:y-	1:y+	original: arc:120,120,10 dir:-40,40,180 rng:1,1,.8 cyc:6 dmg:6,6,4 tarc:60 tur:.5
                {
                    idx = 0,
                    arc = 120,
                    dir = -40,
                    rng = 1000,
                    cyc = 6,
                    dmg = 6,
                },
                {
                    idx = 1,
                    arc = 120,
                    dir = 40,
                    rng = 1000,
                    cyc = 6,
                    dmg = 6,
                },
                {
                    idx = 2,
                    arc = 10,
                    dir = 0,
                    rng = 1250,
                    cyc = 6,
                    dmg = 4,
                    tarc = 50,
                    tur = 0.5,
                    bdt = "emp",
                },
                {
                    idx = 3,
                    arc = 10,
                    dir = 180,
                    rng = 800,
                    cyc = 6,
                    dmg = 4,
                    tarc = 60,
                    tur = 0.5,
                },
            },
            missile = {
                { typ = "Nuke", qty = 2 }, --original: 4
                { typ = "EMP", qty = 4 }, --original: 6
                { typ = "Homing", qty = 12 }, --original: 8
                { typ = "HVLI", qty = 20 }, --original: 16
                { typ = "Mine", qty = 3 }, --original: 6
            },
        },
        ["Ogre"] = {
            base = "Ender",
            del = false,
            spin = 5, --original: 2
            impulse = { f = 40, b = 30 }, --original: f:30 b:30
            accel = { f = 7, b = 6 }, --original: f:6 b:6
            beam = { --0,1:y- 2,3:y+ 4,5:y- 6,7:y+ 8,9:y- 10,11:y+
                {
                    idx = 0,
                    arc = 10,
                    dir = -20,
                    rng = 2000,
                    cyc = 6,
                    dmg = 5,
                    tarc = 80,
                    tur = 1,
                },
                {
                    idx = 1,
                    arc = 10,
                    dir = -40,
                    rng = 2250,
                    cyc = 5.9,
                    dmg = 5,
                    tarc = 60,
                    tur = 1,
                },
                {
                    idx = 2,
                    arc = 10,
                    dir = 20,
                    rng = 2000,
                    cyc = 6,
                    dmg = 5,
                    tarc = 80,
                    tur = 1,
                },
                {
                    idx = 3,
                    arc = 10,
                    dir = 40,
                    rng = 2250,
                    cyc = 5.9,
                    dmg = 5,
                    tarc = 60,
                    tur = 1,
                },
                {
                    idx = 4,
                    arc = 10,
                    dir = -80,
                    rng = 2500,
                    cyc = 6,
                    dmg = 4,
                    tarc = 60,
                    tur = 1,
                },
                {
                    idx = 5,
                    arc = 10,
                    dir = -100,
                    rng = 2500,
                    cyc = 5.9,
                    dmg = 4,
                    tarc = 60,
                    tur = 1,
                },
                {
                    idx = 6,
                    arc = 10,
                    dir = 80,
                    rng = 2500,
                    cyc = 6,
                    dmg = 4,
                    tarc = 60,
                    tur = 1,
                },
                {
                    idx = 7,
                    arc = 10,
                    dir = 100,
                    rng = 2500,
                    cyc = 5.9,
                    dmg = 4,
                    tarc = 60,
                    tur = 1,
                },
                {
                    idx = 8,
                    arc = 10,
                    dir = 200,
                    rng = 2000,
                    cyc = 6,
                    dmg = 5,
                    tarc = 80,
                    tur = 1,
                },
                {
                    idx = 9,
                    arc = 10,
                    dir = 220,
                    rng = 2250,
                    cyc = 5.9,
                    dmg = 5,
                    tarc = 60,
                    tur = 1,
                },
                {
                    idx = 10,
                    arc = 10,
                    dir = 160,
                    rng = 2000,
                    cyc = 6,
                    dmg = 5,
                    tarc = 80,
                    tur = 1,
                },
                {
                    idx = 11,
                    arc = 10,
                    dir = 140,
                    rng = 2250,
                    cyc = 5.9,
                    dmg = 5,
                    tarc = 60,
                    tur = 1,
                },
            },
            tube = { --original: dir:0,180 siz:m tim:8
                { idx = 0, dir = 0, siz = "medium", tim = 8, only = "Homing" },
                {
                    idx = 1,
                    dir = 30,
                    siz = "medium",
                    tim = 8,
                    only = "Homing",
                },
                {
                    idx = 2,
                    dir = 60,
                    siz = "medium",
                    tim = 8,
                    only = "Homing",
                },
                {
                    idx = 3,
                    dir = 90,
                    siz = "medium",
                    tim = 8,
                    only = "Homing",
                },
                {
                    idx = 4,
                    dir = 120,
                    siz = "medium",
                    tim = 8,
                    only = "Homing",
                },
                {
                    idx = 5,
                    dir = 150,
                    siz = "medium",
                    tim = 8,
                    only = "Homing",
                },
                {
                    idx = 6,
                    dir = 180,
                    siz = "medium",
                    tim = 8,
                    only = "Homing",
                },
                {
                    idx = 7,
                    dir = 210,
                    siz = "medium",
                    tim = 8,
                    only = "Homing",
                },
                {
                    idx = 8,
                    dir = 240,
                    siz = "medium",
                    tim = 8,
                    only = "Homing",
                },
                {
                    idx = 9,
                    dir = 270,
                    siz = "medium",
                    tim = 8,
                    only = "Homing",
                },
                {
                    idx = 10,
                    dir = 300,
                    siz = "medium",
                    tim = 8,
                    only = "Homing",
                },
                {
                    idx = 11,
                    dir = 330,
                    siz = "medium",
                    tim = 8,
                    only = "Homing",
                },
            },
            missile = {
                { typ = "Homing", qty = 24 }, --original: 8
                { typ = "Mine", qty = 0 }, --original: 6
            },
        },
    }
    player_ship_stats = {
        ["Amalgam"] = {
            strength = 42,
            cargo = 7,
            distance = 400,
            long_range_radar = 36000,
            short_range_radar = 5000,
            probes = 11,
            tractor = false,
            mining = false,
        },
        [ST.ATLANTIS] = {
            strength = 52,
            cargo = 6,
            distance = 400,
            long_range_radar = 30000,
            short_range_radar = 5000,
            probes = 8,
            tractor = true,
            mining = true,
        },
        ["Atlantis II"] = {
            strength = 60,
            cargo = 6,
            distance = 400,
            long_range_radar = 30000,
            short_range_radar = 5000,
            probes = 8,
            tractor = true,
            mining = true,
        },
        [ST.BENEDICT] = {
            strength = 10,
            cargo = 9,
            distance = 400,
            long_range_radar = 30000,
            short_range_radar = 5000,
            probes = 8,
            tractor = true,
            mining = true,
        },
        ["Butler"] = {
            strength = 20,
            cargo = 6,
            distance = 200,
            long_range_radar = 30000,
            short_range_radar = 5500,
            probes = 8,
            tractor = true,
            mining = false,
        },
        ["Caretaker"] = {
            strength = 23,
            cargo = 6,
            distance = 200,
            long_range_radar = 35000,
            short_range_radar = 5000,
            probes = 9,
            tractor = true,
            mining = false,
        },
        [ST.CRUCIBLE] = {
            strength = 45,
            cargo = 5,
            distance = 200,
            long_range_radar = 20000,
            short_range_radar = 6000,
            probes = 8,
            tractor = false,
            mining = false,
        },
        [ST.VINDICATOR] = {
            strength = 40,
            cargo = 6,
            distance = 400,
            long_range_radar = 30000,
            short_range_radar = 5000,
            probes = 8,
            tractor = false,
            mining = false,
        },
        ["Deimos"] = {
            strength = 28,
            cargo = 8,
            distance = 200,
            long_range_radar = 25000,
            short_range_radar = 5000,
            probes = 11,
            tractor = false,
            mining = true,
        },
        ["Destroyer III"] = {
            strength = 25,
            cargo = 7,
            distance = 200,
            long_range_radar = 30000,
            short_range_radar = 5000,
            probes = 8,
            tractor = false,
            mining = false,
        },
        ["Destroyer IV"] = {
            strength = 25,
            cargo = 5,
            distance = 400,
            long_range_radar = 30000,
            short_range_radar = 5000,
            probes = 8,
            tractor = false,
            mining = false,
        },
        [ST.ENDER] = {
            strength = 100,
            cargo = 20,
            distance = 2000,
            long_range_radar = 45000,
            short_range_radar = 7000,
            probes = 8,
            tractor = true,
            mining = false,
        },
        ["Era"] = {
            strength = 14,
            cargo = 14,
            distance = 200,
            long_range_radar = 50000,
            short_range_radar = 5000,
            probes = 8,
            tractor = true,
            mining = true,
        },
        [ST.FLAVIA] = {
            strength = 13,
            cargo = 15,
            distance = 200,
            long_range_radar = 40000,
            short_range_radar = 5000,
            probes = 8,
            tractor = true,
            mining = true,
        },
        ["Flavia 2C"] = {
            strength = 25,
            cargo = 12,
            distance = 200,
            long_range_radar = 30000,
            short_range_radar = 5000,
            probes = 8,
            tractor = false,
            mining = true,
        },
        [ST.FLAVIA_PFALCON] = {
            strength = 13,
            cargo = 15,
            distance = 200,
            long_range_radar = 40000,
            short_range_radar = 5000,
            probes = 8,
            tractor = true,
            mining = true,
        },
        ["Focus"] = {
            strength = 35,
            cargo = 4,
            distance = 200,
            long_range_radar = 32000,
            short_range_radar = 5000,
            probes = 8,
            tractor = false,
            mining = true,
        },
        [ST.HATHCOCK] = {
            strength = 30,
            cargo = 6,
            distance = 200,
            long_range_radar = 35000,
            short_range_radar = 6000,
            probes = 8,
            tractor = false,
            mining = true,
        },
        ["Holmes"] = {
            strength = 35,
            cargo = 6,
            distance = 200,
            long_range_radar = 35000,
            short_range_radar = 4000,
            probes = 8,
            tractor = true,
            mining = false,
        },
        ["Interlock"] = {
            strength = 19,
            cargo = 12,
            distance = 200,
            long_range_radar = 35000,
            short_range_radar = 5500,
            probes = 13,
            tractor = false,
            mining = true,
        },
        [ST.KIRIYA] = {
            strength = 10,
            cargo = 9,
            distance = 400,
            long_range_radar = 35000,
            short_range_radar = 5000,
            probes = 8,
            tractor = true,
            mining = true,
        },
        ["Mantis"] = {
            strength = 30,
            cargo = 8,
            distance = 200,
            long_range_radar = 25000,
            short_range_radar = 6000,
            probes = 9,
            tractor = false,
            mining = false,
        },
        [ST.MAVERICK] = {
            strength = 45,
            cargo = 5,
            distance = 200,
            long_range_radar = 20000,
            short_range_radar = 4000,
            probes = 8,
            tractor = false,
            mining = true,
        },
        ["Maverick XP"] = {
            strength = 23,
            cargo = 5,
            distance = 200,
            long_range_radar = 25000,
            short_range_radar = 7000,
            probes = 8,
            tractor = true,
            mining = false,
        },
        ["Midian"] = {
            strength = 30,
            cargo = 9,
            distance = 200,
            long_range_radar = 25000,
            short_range_radar = 5500,
            probes = 9,
            tractor = false,
            mining = false,
        },
        [ST.POLARIS] = {
            strength = 45,
            cargo = 8,
            distance = 200,
            long_range_radar = 35000,
            short_range_radar = 6000,
            probes = 8,
            tractor = false,
            mining = false,
        },
        ["Moose"] = {
            strength = 30,
            cargo = 4,
            distance = 200,
            long_range_radar = 27000,
            short_range_radar = 5000,
            probes = 10,
            tractor = false,
            mining = false,
        },
        ["Mortar"] = {
            strength = 45,
            cargo = 5,
            distance = 200,
            long_range_radar = 25000,
            short_range_radar = 4500,
            probes = 9,
            tractor = false,
            mining = true,
        },
        ["MP44 Hornet"] = {
            strength = 7,
            cargo = 3,
            distance = 100,
            long_range_radar = 18000,
            short_range_radar = 4500,
            probes = 8,
            tractor = false,
            mining = false,
        },
        ["MP47 Hornet"] = {
            strength = 7,
            cargo = 3,
            distance = 100,
            long_range_radar = 19000,
            short_range_radar = 5000,
            probes = 10,
            tractor = false,
            mining = false,
        },
        [ST.MP52_HORNET] = {
            strength = 7,
            cargo = 3,
            distance = 100,
            long_range_radar = 18000,
            short_range_radar = 4000,
            probes = 8,
            tractor = false,
            mining = false,
        },
        ["MP53 Hornet"] = {
            strength = 7,
            cargo = 4,
            distance = 100,
            long_range_radar = 21000,
            short_range_radar = 4500,
            probes = 9,
            tractor = false,
            mining = false,
        },
        ["MP58 Hornet"] = {
            strength = 7,
            cargo = 4,
            distance = 100,
            long_range_radar = 22000,
            short_range_radar = 4000,
            probes = 9,
            tractor = false,
            mining = false,
        },
        ["MP61 Hornet"] = {
            strength = 7,
            cargo = 3,
            distance = 100,
            long_range_radar = 18000,
            short_range_radar = 4000,
            probes = 8,
            tractor = false,
            mining = false,
        },
        ["MP65 Hornet"] = {
            strength = 7,
            cargo = 3,
            distance = 100,
            long_range_radar = 17000,
            short_range_radar = 5000,
            probes = 9,
            tractor = false,
            mining = false,
        },
        ["MP66 Hornet"] = {
            strength = 7,
            cargo = 3,
            distance = 100,
            long_range_radar = 18000,
            short_range_radar = 5000,
            probes = 8,
            tractor = false,
            mining = false,
        },
        ["MX-Lindworm"] = {
            strength = 10,
            cargo = 3,
            distance = 100,
            long_range_radar = 30000,
            short_range_radar = 5000,
            probes = 8,
            tractor = false,
            mining = false,
        },
        [ST.NAUTILUS] = {
            strength = 12,
            cargo = 7,
            distance = 200,
            long_range_radar = 22000,
            short_range_radar = 4000,
            probes = 8,
            tractor = false,
            mining = false,
        },
        ["Nusret"] = {
            strength = 16,
            cargo = 7,
            distance = 200,
            long_range_radar = 25000,
            short_range_radar = 4000,
            probes = 10,
            tractor = false,
            mining = true,
        },
        ["Ogre"] = {
            strength = 100,
            cargo = 20,
            distance = 2000,
            long_range_radar = 45000,
            short_range_radar = 6500,
            probes = 25,
            tractor = true,
            mining = false,
        },
        ["Pacu"] = {
            strength = 18,
            cargo = 7,
            distance = 200,
            long_range_radar = 20000,
            short_range_radar = 6000,
            probes = 8,
            tractor = false,
            mining = false,
        },
        ["Peacock"] = {
            strength = 30,
            cargo = 9,
            distance = 400,
            long_range_radar = 25000,
            short_range_radar = 5000,
            probes = 10,
            tractor = false,
            mining = true,
        },
        ["PF24"] = {
            strength = 7,
            cargo = 3,
            distance = 100,
            long_range_radar = 15000,
            short_range_radar = 5000,
            probes = 8,
            tractor = false,
            mining = false,
        },
        ["PF25"] = {
            strength = 7,
            cargo = 4,
            distance = 100,
            long_range_radar = 16000,
            short_range_radar = 4500,
            probes = 9,
            tractor = false,
            mining = false,
        },
        ["PF26"] = {
            strength = 7,
            cargo = 3,
            distance = 100,
            long_range_radar = 15000,
            short_range_radar = 5000,
            probes = 7,
            tractor = false,
            mining = false,
        },
        ["PF29"] = {
            strength = 7,
            cargo = 3,
            distance = 100,
            long_range_radar = 17000,
            short_range_radar = 4500,
            probes = 8,
            tractor = false,
            mining = false,
        },
        ["PF32"] = {
            strength = 7,
            cargo = 4,
            distance = 100,
            long_range_radar = 15000,
            short_range_radar = 5000,
            probes = 9,
            tractor = false,
            mining = false,
        },
        ["PF33"] = {
            strength = 7,
            cargo = 4,
            distance = 100,
            long_range_radar = 18000,
            short_range_radar = 4500,
            probes = 10,
            tractor = false,
            mining = false,
        },
        ["PF37"] = {
            strength = 7,
            cargo = 3,
            distance = 100,
            long_range_radar = 15000,
            short_range_radar = 5000,
            probes = 8,
            tractor = false,
            mining = false,
        },
        ["PF38"] = {
            strength = 7,
            cargo = 3,
            distance = 100,
            long_range_radar = 19000,
            short_range_radar = 4500,
            probes = 9,
            tractor = false,
            mining = false,
        },
        [ST.PHOBOS_M3P] = {
            strength = 19,
            cargo = 10,
            distance = 200,
            long_range_radar = 25000,
            short_range_radar = 5000,
            probes = 8,
            tractor = true,
            mining = false,
        },
        ["Phobos T2"] = {
            strength = 19,
            cargo = 9,
            distance = 200,
            long_range_radar = 25000,
            short_range_radar = 5000,
            probes = 8,
            tractor = true,
            mining = false,
        },
        [ST.PIRANHA] = {
            strength = 16,
            cargo = 8,
            distance = 200,
            long_range_radar = 25000,
            short_range_radar = 6000,
            probes = 8,
            tractor = false,
            mining = false,
        },
        [ST.VINDICATOR] = {
            strength = 40,
            cargo = 6,
            distance = 400,
            long_range_radar = 30000,
            short_range_radar = 5000,
            probes = 8,
            tractor = false,
            mining = false,
        },
        [ST.AVALANCHE] = {
            strength = 45,
            cargo = 8,
            distance = 200,
            long_range_radar = 35000,
            short_range_radar = 6000,
            probes = 8,
            tractor = false,
            mining = false,
        },
        [ST.STINGRAY] = {
            strength = 7,
            cargo = 3,
            distance = 100,
            long_range_radar = 15000,
            short_range_radar = 4500,
            probes = 8,
            tractor = false,
            mining = false,
        },
        ["Proto-Atlantis"] = {
            strength = 40,
            cargo = 4,
            distance = 400,
            long_range_radar = 30000,
            short_range_radar = 4500,
            probes = 8,
            tractor = false,
            mining = true,
        },
        ["Raven"] = {
            strength = 33,
            cargo = 5,
            distance = 400,
            long_range_radar = 25000,
            short_range_radar = 6000,
            probes = 7,
            tractor = true,
            mining = false,
        },
        ["Redhook"] = {
            strength = 11,
            cargo = 8,
            distance = 200,
            long_range_radar = 20000,
            short_range_radar = 6000,
            probes = 8,
            tractor = false,
            mining = false,
        },
        [ST.REPULSE] = {
            strength = 14,
            cargo = 12,
            distance = 200,
            long_range_radar = 38000,
            short_range_radar = 5000,
            probes = 8,
            tractor = true,
            mining = false,
        },
        ["Roc"] = {
            strength = 25,
            cargo = 6,
            distance = 200,
            long_range_radar = 25000,
            short_range_radar = 5000,
            probes = 6,
            tractor = true,
            mining = false,
        },
        ["Rodent"] = {
            strength = 23,
            cargo = 8,
            distance = 200,
            long_range_radar = 40000,
            short_range_radar = 5500,
            probes = 9,
            tractor = false,
            mining = false,
        },
        [ST.SAIPAN] = {
            strength = 30,
            cargo = 4,
            distance = 200,
            long_range_radar = 25000,
            short_range_radar = 4500,
            probes = 10,
            tractor = false,
            mining = false,
        },
        ["Scatter"] = {
            strength = 30,
            cargo = 6,
            distance = 200,
            long_range_radar = 28000,
            short_range_radar = 5000,
            probes = 8,
            tractor = false,
            mining = true,
        },
        ["Squid"] = {
            strength = 14,
            cargo = 8,
            distance = 200,
            long_range_radar = 25000,
            short_range_radar = 5000,
            probes = 8,
            tractor = false,
            mining = false,
        },
        ["Stricken"] = {
            strength = 40,
            cargo = 4,
            distance = 200,
            long_range_radar = 20000,
            short_range_radar = 4000,
            probes = 8,
            tractor = false,
            mining = false,
        },
        [ST.CROW] = {
            strength = 8,
            cargo = 4,
            distance = 200,
            long_range_radar = 35000,
            short_range_radar = 5000,
            probes = 8,
            tractor = false,
            mining = false,
        },
        ["Striker B"] = {
            strength = 8,
            cargo = 4,
            distance = 200,
            long_range_radar = 34000,
            short_range_radar = 5000,
            probes = 9,
            tractor = false,
            mining = false,
        },
        ["Striker D"] = {
            strength = 8,
            cargo = 4,
            distance = 200,
            long_range_radar = 33000,
            short_range_radar = 5000,
            probes = 8,
            tractor = false,
            mining = false,
        },
        ["Striker H"] = {
            strength = 8,
            cargo = 4,
            distance = 200,
            long_range_radar = 32000,
            short_range_radar = 5000,
            probes = 10,
            tractor = false,
            mining = false,
        },
        ["Striker LX"] = {
            strength = 16,
            cargo = 4,
            distance = 200,
            long_range_radar = 20000,
            short_range_radar = 4000,
            probes = 8,
            tractor = false,
            mining = false,
        },
        ["Striker N"] = {
            strength = 8,
            cargo = 4,
            distance = 200,
            long_range_radar = 31000,
            short_range_radar = 5000,
            probes = 7,
            tractor = false,
            mining = false,
        },
        ["Striker NS"] = {
            strength = 8,
            cargo = 4,
            distance = 200,
            long_range_radar = 30000,
            short_range_radar = 5000,
            probes = 8,
            tractor = false,
            mining = false,
        },
        ["Striker R"] = {
            strength = 8,
            cargo = 4,
            distance = 200,
            long_range_radar = 29000,
            short_range_radar = 5000,
            probes = 7,
            tractor = false,
            mining = false,
        },
        ["Striker T"] = {
            strength = 8,
            cargo = 4,
            distance = 200,
            long_range_radar = 28000,
            short_range_radar = 5000,
            probes = 9,
            tractor = false,
            mining = false,
        },
        ["Surkov"] = {
            strength = 35,
            cargo = 6,
            distance = 200,
            long_range_radar = 35000,
            short_range_radar = 6000,
            probes = 8,
            tractor = false,
            mining = false,
        },
        ["QX-Lindworm"] = {
            strength = 8,
            cargo = 4,
            distance = 100,
            long_range_radar = 19000,
            short_range_radar = 5000,
            probes = 7,
            tractor = false,
            mining = false,
        },
        ["Wombat"] = {
            strength = 13,
            cargo = 3,
            distance = 100,
            long_range_radar = 18000,
            short_range_radar = 6000,
            probes = 8,
            tractor = false,
            mining = false,
        },
        ["WQ-Lindworm"] = {
            strength = 8,
            cargo = 3,
            distance = 100,
            long_range_radar = 21000,
            short_range_radar = 5500,
            probes = 10,
            tractor = false,
            mining = false,
        },
        ["YQ-Lindworm"] = {
            strength = 8,
            cargo = 3,
            distance = 100,
            long_range_radar = 17000,
            short_range_radar = 4500,
            probes = 8,
            tractor = false,
            mining = false,
        },
        ["YX-Lindworm"] = {
            strength = 8,
            cargo = 4,
            distance = 100,
            long_range_radar = 16000,
            short_range_radar = 5500,
            probes = 11,
            tractor = false,
            mining = false,
        },
        ["ZQ-Lindworm"] = {
            strength = 8,
            cargo = 5,
            distance = 100,
            long_range_radar = 20000,
            short_range_radar = 5000,
            probes = 6,
            tractor = false,
            mining = false,
        },
        [ST.ZX_LINDWORM] = {
            strength = 8,
            cargo = 3,
            distance = 100,
            long_range_radar = 18000,
            short_range_radar = 5500,
            probes = 9,
            tractor = false,
            mining = false,
        },
        ["ZY-Lindworm"] = {
            strength = 8,
            cargo = 3,
            distance = 100,
            long_range_radar = 15000,
            short_range_radar = 5000,
            probes = 9,
            tractor = false,
            mining = false,
        },
        ["ZZ-Lindworm"] = {
            strength = 8,
            cargo = 3,
            distance = 100,
            long_range_radar = 22000,
            short_range_radar = 5500,
            probes = 8,
            tractor = false,
            mining = false,
        },
    }
    player_ship_names_for = ShipNames.forScenario({
        ["Amalgam"] = { "Everyman", "Politico", "Comforter" },
        ["Butler"] = { "Merciless", "Imperturbable", "Aloof" },
        ["Caretaker"] = { "Confidence", "Inquisitorial", "Response" },
        ["Deimos"] = { "Dante", "Protector", "Staunch" },
        ["Destroyer III"] = { "Strand", "Isometric" },
        ["Destroyer IV"] = { "Bent", "Impenetrable", "Impervious" },
        ["Era"] = { "Mindful", "Peer", "Star Flow" },
        [ST.FLAVIA] = {
            "Ladyhawke",
            "Hunter",
            "Seeker",
            "Gyrefalcon",
            "Kestrel",
            "Magpie",
            "Bandit",
            "Buccaneer",
        },
        ["Flavia 2C"] = { "Trickle", "Retuned", "Insatiable" },
        ["Focus"] = { "Growth", "Scalar", "Justice" },
        ["Holmes"] = { "Yardstick", "Deer Hat", "Induction", "Watson" },
        ["Interlock"] = { "Traverse", "Jasper", "Intransigent" },
        ["Mantis"] = { "Ray", "Nemo", "Skelter" },
        ["Maverick XP"] = { "Condensed", "Impact", "Compound", "Rogue" },
        ["Midian"] = { "Ethereal", "Torn", "Zapper" },
        ["Moose"] = { "Antler", "Submerge" },
        ["Mortar"] = { "Galadriel", "Belinda", "Slippery" },
        ["MP44 Hornet"] = { "Maculata", "Mandarinia" },
        ["MP47 Hornet"] = { "Vespula", "Sphecidae" },
        ["MP53 Hornet"] = { "Mellifera", "Scutellata" },
        ["MP58 Hornet"] = { "Polistes", "Pepsis" },
        ["MP61 Hornet"] = { "Crabro", "Halictidae" },
        ["MP65 Hornet"] = { "Xylocopa", "Calliphora" },
        ["MP66 Hornet"] = { "Bombus", "Squamosa" },
        ["MX-Lindworm"] = { "Shimmer", "Taffy" },
        ["Nusret"] = { "Trembler", "Bright", "Terse" },
        ["Ogre"] = { "Gargantua", "Grawp", "Grug", "Ruknar" },
        ["Pacu"] = { "Energetic", "Ardent", "Frugal", "Arwine" },
        ["Peacock"] = { "Kaleidoscopic", "Redolent", "Extravagant" },
        ["PF24"] = { "Reference", "Seline" },
        ["PF25"] = { "Flank", "Hillary" },
        ["PF26"] = { "Effervescence", "Gillian" },
        ["PF29"] = { "Clang", "Dianne" },
        ["PF32"] = { "Jest", "Kelly" },
        ["PF33"] = { "Scorch", "Trudy" },
        ["PF37"] = { "Poke", "Olivia" },
        ["PF38"] = { "Trank", "Alissa" },
        ["Raven"] = { "Nevermore", "Blackened", "Reflective" },
        ["Roc"] = { "Bulk", "Roast", "Grimwald" },
        ["Rodent"] = { "Chirp", "Muskrat", "Ferret" },
        ["Scatter"] = { "Frisky", "Fraught", "Nimble" },
        ["Squid"] = { "Insidious", "Trampler", "Livid" },
        ["Striker B"] = { "Callous", "Heloise" },
        ["Striker D"] = { "Drachma", "Gail" },
        ["Striker H"] = { "Brand", "Rayanne" },
        ["Striker LX"] = { "Truncheon", "Tilly" },
        ["Striker N"] = { "Reaper", "Stella" },
        ["Striker NS"] = { "Flippant", "Gracie" },
        ["Striker R"] = { "Jasper", "Damon", "Delilah" },
        ["Striker T"] = { "Twin", "Pixel", "Resolute" },
        ["QX-Lindworm"] = { "Treatise", "Arch", "Fanny" },
        ["Wombat"] = { "Grotto", "Perch", "Pippi" },
        ["WQ-Lindworm"] = { "Swipe", "Marion", "Lielle" },
        ["YQ-Lindworm"] = { "Tang", "Lilly", "Flora" },
        ["YX-Lindworm"] = { "Fang", "Dixie", "Listra" },
        ["ZQ-Lindworm"] = { "Spine", "Trixie", "Dara" },
        ["ZY-Lindworm"] = { "Devereaux", "Porshe", "Portent" },
        ["ZZ-Lindworm"] = { "Bourne", "Fiona", "Dierdre" },
        ["Leftovers"] = { "Foregone", "Righteous", "Scandalous" },
    })
    fleetComposition = "Random"
    fleet_composition_labels = {
        ["Random"] = _("buttonGM", "Random"),
        ["Fighters"] = _("buttonGM", "Fighters"),
        ["Chasers"] = _("buttonGM", "Chasers"),
        ["Frigates"] = _("buttonGM", "Frigates"),
        ["Beamers"] = _("buttonGM", "Beamers"),
        ["Missilers"] = _("buttonGM", "Missilers"),
        ["Adders"] = _("buttonGM", "Adders"),
        ["Non-DB"] = _("buttonGM", "Non-DB"),
        ["Drones"] = _("buttonGM", "Drones"),
    }
    template_pool_size = 10
    advertising_billboards = {
        _(
            "scienceDescription-buoy",
            "Come to Billy Bob's for the best food in the sector"
        ),
        _(
            "scienceDescription-buoy",
            "It's never too late to buy life insurance"
        ),
        _("scienceDescription-buoy", "You'll feel better in an Adder Mark 9"),
        _(
            "scienceDescription-buoy",
            "Melinda's Mynock Management service: excellent rates, satisfaction guaranteed"
        ),
        _(
            "scienceDescription-buoy",
            "Visit Repulse shipyards for the best deals"
        ),
        _("scienceDescription-buoy", "Fresh fish! We catch, you buy!"),
        _("scienceDescription-buoy", "Get your fuel cells at Mariana's Market"),
        _(
            "scienceDescription-buoy",
            "Find a special companion. All species available"
        ),
        _(
            "scienceDescription-buoy",
            "Feeling down? Robotherapist is there for you"
        ),
        _("scienceDescription-buoy", "30 days, 30 kilograms, guaranteed"),
        _("scienceDescription-buoy", "Be sure to drink your Ovaltine"),
        _(
            "scienceDescription-buoy",
            "Need a personal upgrade? Contact Celine's Cybernetic Implants"
        ),
        _(
            "scienceDescription-buoy",
            "Try our asteroid dust diet weight loss program"
        ),
        _(
            "scienceDescription-buoy",
            "Best tasting water in the quadrant at Willy's Waterway"
        ),
        _(
            "scienceDescription-buoy",
            "Amazing shows every night at Lenny's Lounge"
        ),
        _(
            "scienceDescription-buoy",
            "Get all your vaccinations at Fred's Pharmacy. Pick up some snacks, too"
        ),
        _(
            "scienceDescription-buoy",
            "Tip: make lemons an integral part of your diet"
        ),
        _(
            "scienceDescription-buoy",
            "Visit the Proboscis shop for all your specialty probe needs"
        ),
    }
    artifact_number = 0
    sensor_jammer_list = {}
    warp_jammer_list = {}
    warp_jammer_info = {
        ["Human Navy"] = { id = "H", count = 0 },
        ["Independent"] = { id = "I", count = 0 },
        ["Kraylor"] = { id = "K", count = 0 },
        ["Arlenians"] = { id = "A", count = 0 },
        ["Exuari"] = { id = "E", count = 0 },
        ["Ghosts"] = { id = "G", count = 0 },
        ["Ktlitans"] = { id = "B", count = 0 },
        ["TSN"] = { id = "T", count = 0 },
        ["USN"] = { id = "U", count = 0 },
        ["CUF"] = { id = "C", count = 0 },
        ["Mehklar"] = { id = "M", count = 0 },
    }
    star_list = {
        {
            radius = random(600, 1400),
            distance = random(-2500, -1400),
            info = {
                {
                    name = "Gamma Piscium",
                    unscanned = _(
                        "scienceDescription-star",
                        "Yellow, spectral type G8 III"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Yellow, spectral type G8 III, giant, surface temperature 4,833 K, 11 solar radii"
                    ),
                },
                {
                    name = "Beta Leporis",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification G5 II"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification G5 II, bright giant, possible binary"
                    ),
                },
                {
                    name = "Sigma Draconis",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification K0 V or G9 V"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification K0 V or G9 V, main sequence dwarf, 84% of Sol mass"
                    ),
                },
                {
                    name = "Iota Carinae",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification A7 Ib"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification A7 Ib, supergiant, temperature 7,500 K, 7xSol mass"
                    ),
                },
                {
                    name = "Theta Arietis",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification A1 Vn"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification A1 Vn, type A main sequence, binary, nebulous"
                    ),
                },
                {
                    name = "Epsilon Indi",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification K5V"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification K5V, orange, temperature 4,649 K"
                    ),
                },
                {
                    name = "Beta Hydri",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification G2 IV"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification G2 IV, 113% of Sol mass, 185% Sol radius"
                    ),
                },
                {
                    name = "Acamar",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification A3 IV-V"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification A3 IV-V, binary, 2.6xSol mass"
                    ),
                },
                {
                    name = "Bellatrix",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification B2 III or B2 V"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification B2 III or B2 V, 8.6xSol mass, temperature 22,000 K"
                    ),
                },
                {
                    name = "Castula",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification G8 IIIb Fe-0.5"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification G8 IIIb Fe-0.5, yellow, red clump giant"
                    ),
                },
                {
                    name = "Dziban",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification F5 IV-V"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification F5 IV-V, binary, F-type subgiant and F-type main sequence"
                    ),
                },
                {
                    name = "Elnath",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification B7 III"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification B7 III, B-class giant, double star, 5xSol mass"
                    ),
                },
                {
                    name = "Flegetonte",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification K0"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification K0, orange-red, temperature ~4,000 K"
                    ),
                },
                {
                    name = "Geminga",
                    unscanned = _(
                        "scienceDescription-star",
                        "Pulsar or Neutron star"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Pulsar or Neutron star, gamma ray source"
                    ),
                },
                {
                    name = "Helvetios",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification G2V"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification G2V, yellow, temperature 5,571 K"
                    ),
                },
                {
                    name = "Inquill",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification G1V(w)"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification G1V(w), 1.24xSol mass, 7th magnitude G-type main sequence"
                    ),
                },
                {
                    name = "Jishui",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification F3 III"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification F3 III, F-type giant, temperature 6,309 K"
                    ),
                },
                {
                    name = "Kaus Borealis",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification K1 IIIb"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification K1 IIIb, giant, temperature 4,768 K"
                    ),
                },
                {
                    name = "Liesma",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification G0V"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification G0V, G-type giant, temperature 5,741 K"
                    ),
                },
                {
                    name = "Macondo",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification K2IV-V or K3V"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification K2IV-V or K3V, orange, K-type main sequence, temperature 5,030 K"
                    ),
                },
                {
                    name = "Nikawiy",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification G5"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification G5, yellow, luminosity 7.7"
                    ),
                },
                {
                    name = "Orkaria",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification M4.5"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification M4.5, Red Dwarf, luminosity .0035, temperature 3,111 K"
                    ),
                },
                {
                    name = "Poerava",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification F7V"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification F7V, yellow-white, luminosity 1.9, temperature 6,440 K"
                    ),
                },
                {
                    name = "Stribor",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification F8V"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification F8V, luminosity 2.9, temperature 6,122 K"
                    ),
                },
                {
                    name = "Taygeta",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification B"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification B-type subgiant, blue-white, luminosity 600, temperature 13,696 K"
                    ),
                },
                {
                    name = "Tuiren",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification G"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification G, magnitude 12.26, temperature 5,580 K"
                    ),
                },
                {
                    name = "Ukdah",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification K"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification K2.5 III, K-type giant, temperature 4,244 K"
                    ),
                },
                {
                    name = "Wouri",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification K"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification K5V, K-type main sequence, temperature 4,782 K"
                    ),
                },
                {
                    name = "Xihe",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification G"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification G8 III, evolved G-type giant, temperature 4,790 K"
                    ),
                },
                {
                    name = "Yildun",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification A"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification A1 Vn, white-hued, A-type main sequence, temperature 9,911 K"
                    ),
                },
                {
                    name = "Zosma",
                    unscanned = _(
                        "scienceDescription-star",
                        "Classification A"
                    ),
                    scanned = _(
                        "scienceDescription-star",
                        "Classification A4 V, white-hued, A-type main sequence, temperature 8,296 K"
                    ),
                },
            },
            color = {
                red = random(0.5, 1),
                green = random(0.5, 1),
                blue = random(0.5, 1),
            },
            texture = {
                atmosphere = "planets/star-1.png",
            },
        },
    }
    planet_list = {
        {
            name = { "Bespin", "Aldea", "Bersallis" },
            unscanned = _("scienceDescription-planet", "Class J"),
            scanned = _(
                "scienceDescription-planet",
                "Class J, Jovian, source of hydrogen, helium, and a large variety of exotic gases"
            ),
            texture = {
                surface = "planets/gas-1.png",
            },
            radius = random(4000, 7500),
        },
        {
            name = { "Farius Prime", "Deneb", "Mordan" },
            unscanned = _("scienceDescription-planet", "Class J"),
            scanned = _(
                "scienceDescription-planet",
                "Class J, Neptunian, source of hydrogen, helium, ammonia, methane, and water"
            ),
            texture = {
                surface = "planets/gas-2.png",
            },
            radius = random(4000, 7500),
        },
        {
            name = { "Kepler-7b", "Alpha Omicron", "Nelvana" },
            unscanned = _("scienceDescription-planet", "Class J"),
            scanned = _(
                "scienceDescription-planet",
                "Class J, Neptunian, composed of hydrogen, helium, methane, water"
            ),
            texture = {
                surface = "planets/gas-3.png",
            },
            radius = random(4000, 7500),
        },
        {
            name = { "Alderaan", "Dagobah", "Dantooine", "Rigel" },
            color = {
                red = random(0, 0.2),
                green = random(0, 0.2),
                blue = random(0.8, 1),
            },
            texture = {
                surface = "planets/planet-1.png",
                cloud = "planets/clouds-1.png",
                atmosphere = "planets/atmosphere.png",
            },
            radius = random(3000, 5000),
        },
        {
            name = { "Pahvo", "Penthara", "Scalos" },
            color = {
                red = random(0, 0.2),
                green = random(0, 0.2),
                blue = random(0.8, 1),
            },
            texture = {
                surface = "planets/planet-4.png",
                cloud = "planets/clouds-3.png",
                atmosphere = "planets/atmosphere.png",
            },
            radius = random(3000, 5000),
        },
        {
            name = { "Tanuga", "Vacca", "Terlina", "Timor" },
            color = {
                red = random(0, 0.2),
                green = random(0, 0.2),
                blue = random(0.8, 1),
            },
            texture = {
                surface = "planets/planet-5.png",
                cloud = "planets/clouds-2.png",
                atmosphere = "planets/atmosphere.png",
            },
            radius = random(3000, 5000),
        },
    }
    moon_list = {
        {
            name = { "Ganymede", "Europa", "Deimos", "Luna" },
            texture = {
                surface = "planets/moon-1.png",
            },
            radius = random(1000, 3000),
        },
        {
            name = { "Myopia", "Zapata", "Lichen", "Fandango" },
            texture = {
                surface = "planets/moon-2.png",
            },
            radius = random(1000, 3000),
        },
        {
            name = { "Scratmat", "Tipple", "Dranken", "Calypso" },
            texture = {
                surface = "planets/moon-3.png",
            },
            radius = random(1000, 3000),
        },
    }
    stations_improve_ships = true
    stations_sell_goods = true
    stations_buy_goods = true
    stations_trade_goods = true
    stations_support_transport_missions = true
    stations_support_cargo_missions = true
    current_orders_button = true
    current_orders_at_neutral_stations = true
    add_station_to_database = true
    include_major_systems_repair_in_status = true
    include_minor_systems_repair_in_status = true
    include_goods_for_sale_in_status = true
    include_goods_wanted_in_status = true
    stellar_cartography_button = true
    update_ship_manifest = true
    maintenancePlot = warpJammerMaintenance
    relative_strength = 1
    scenario_duration = 45
end
function setVariations()
    random_starting_template = false
    if getScenarioSetting("Playership") == "Random" then
        random_starting_template = true
    end
    local enemy_config = {
        ["Easy"] = { number = 0.5 },
        ["Normal"] = { number = 1 },
        ["Hard"] = { number = 2 },
        ["Extreme"] = { number = 3 },
        ["Quixotic"] = { number = 5 },
    }
    enemy_power = enemy_config[getScenarioSetting("Enemies")].number
    local murphy_config = {
        ["Easy"] = { number = 0.5, rep = 90, bump = 20, gsm = 6 },
        ["Normal"] = { number = 1, rep = 50, bump = 10, gsm = 8 },
        ["Hard"] = { number = 2, rep = 30, bump = 5, gsm = 9 },
        ["Extreme"] = { number = 3, rep = 20, bump = 3, gsm = 10 },
        ["Quixotic"] = { number = 5, rep = 10, bump = 1, gsm = 12 },
    }
    difficulty = murphy_config[getScenarioSetting("Murphy")].number
    reputation_start_amount = murphy_config[getScenarioSetting("Murphy")].rep
    reputation_bump_amount = murphy_config[getScenarioSetting("Murphy")].bump --not used in this scenario
    goal_strength_multiplier = murphy_config[getScenarioSetting("Murphy")].gsm
    local respawn_config = {
        ["None"] = { respawn = false, max = 0 },
        ["One"] = { respawn = true, max = 1 },
        ["Two"] = { respawn = true, max = 2 },
        ["Three"] = { respawn = true, max = 3 },
        ["Infinite"] = { respawn = true, max = 999 }, --I know, it's not infinite, but after 999, it should stop
    }
    player_respawns = respawn_config[getScenarioSetting("Respawn")].respawn
    player_respawn_max = respawn_config[getScenarioSetting("Respawn")].max
    primary_orders = _("orders-comms", "Reach your reputation goal.")
end
--	Player functions
function setPlayers()
    PlayerState.recordDeployments(getActivePlayerShips(), deployed_players, {
        include_template = true,
        on_existing = function(p, deployment)
            p:setPosition(deployment.spawn_x, deployment.spawn_y)
        end,
        prepare = function(p)
            if p.shipScore == nil then
                local template = nil
                if not random_starting_template then
                    if deployed_player_count == 0 then
                        template = getScenarioSetting("Playership")
                    end
                else
                    template = "Random"
                end
                updatePlayerSoftTemplate(p, template)
                deployed_player_count = deployed_player_count + 1
            end
        end,
        on_record = function(p, deployment)
            deployment.spawn_x = player_spawn_points[#deployed_players].x
            deployment.spawn_y = player_spawn_points[#deployed_players].y
            p:setPosition(deployment.spawn_x, deployment.spawn_y)
        end,
        after = function(p)
            local label = string.format("%s %s", p:getCallSign(), p:getTypeName())
            for _, position in ipairs({ "Engineering", "Engineering+" }) do
                local key = position == "Engineering"
                    and "name_template_eng"
                    or "name_template_epl"
                p[key] = key
                p:addCustomInfo(position, key, label, 1)
            end
        end,
    })
end
function transformPlayerShip(p, template)
    local selected_template = player_starting_templates[template].base
    p:setTemplate(selected_template)
    p:setFaction(player_faction)
    p:setTypeName(template)
    local tweak = player_starting_templates[template]
    if tweak.shields ~= nil then
        if tweak.shields.b == nil then
            p:setShieldsMax(tweak.shields.f):setShields(tweak.shields.f)
        else
            p:setShieldsMax(tweak.shields.f, tweak.shields.b)
                :setShields(tweak.shields.f, tweak.shields.b)
        end
    end
    if tweak.hull ~= nil then
        p:setHullMax(tweak.hull):setHull(tweak.hull)
    end
    if tweak.warp ~= nil then
        if tweak.warp.speed == 0 then
            p:setWarpDrive(false)
        else
            p:setWarpDrive(true):setWarpSpeed(tweak.warp.speed)
        end
    end
    if tweak.jump ~= nil then
        if tweak.jump.l == 0 then
            p:setJumpDrive(false)
        else
            p.min_jump_range = tweak.jump.s * 1000
            p.max_jump_range = tweak.jump.l * 1000
            p:setJumpDrive(true)
                :setJumpDriveRange(p.min_jump_range, p.max_jump_range)
                :setJumpDriveCharge(p.max_jump_range)
        end
    end
    if tweak.impulse ~= nil then
        p:setImpulseMaxSpeed(tweak.impulse.f, tweak.impulse.b)
    end
    if tweak.accel ~= nil then
        p:setAcceleration(tweak.accel.f, tweak.accel.b)
    end
    if tweak.spin ~= nil then
        p:setRotationMaxSpeed(tweak.spin)
    end
    if tweak.cmbmov ~= nil then
        p:setCombatManeuver(tweak.cmbmov.b, tweak.cmbmov.s)
    end
    if tweak.rcrew ~= nil then
        p:setRepairCrewCount(tweak.rcrew)
    end
    if tweak.beam ~= nil then
        for i, b in ipairs(tweak.beam) do
            p:setBeamWeapon(b.idx, b.arc, b.dir, b.rng, b.cyc, b.dmg)
            if b.tarc ~= nil then
                p:setBeamWeaponTurret(b.idx, b.tarc, b.dir, b.tur)
            end
            if b.heat ~= nil then
                p:setBeamWeaponHeatPerFire(b.idx, b.heat)
            end
            if b.pwr ~= nil then
                p:setBeamWeaponEnergyPerFire(b.idx, b.pwr)
            end
            if b.bdt ~= nil then
                p:setBeamWeaponDamageType(b.idx, b.bdt)
            end
        end
    end
    if tweak.tube ~= nil then
        p:setWeaponTubeCount(#tweak.tube)
        for i, t in ipairs(tweak.tube) do
            p:setWeaponTubeDirection(t.idx, t.dir)
                :setTubeSize(t.idx, t.siz)
                :setTubeLoadTime(t.idx, t.tim)
            if t.only ~= nil then
                p:setWeaponTubeExclusiveFor(t.idx, t.only)
            end
            if t.inc ~= nil then
                p:weaponTubeAllowMissle(t.idx, t.inc)
            end
            if t.inc2 ~= nil then
                p:weaponTubeAllowMissle(t.idx, t.inc2)
            end
            if t.inc3 ~= nil then
                p:weaponTubeAllowMissle(t.idx, t.inc3)
            end
            if t.exc ~= nil then
                p:weaponTubeDisallowMissle(t.idx, t.exc)
            end
        end
    end
    if tweak.missile ~= nil then
        for i, m in ipairs(tweak.missile) do
            p:setWeaponStorageMax(m.typ, m.qty):setWeaponStorage(m.typ, m.qty)
        end
    end
    if tweak.coolrate ~= nil then
        for sys, rate in pairs(tweak.coolrate) do
            p:setSystemCoolantRate(sys, rate)
        end
    end
    return p
end
function updatePlayerSoftTemplate(p, template)
    local temp_type_name = p:getTypeName()
    if template == nil or template == "Random" then
        local template_pool = {}
        for template, details in pairs(player_starting_templates) do
            if not details.del then
                table.insert(template_pool, template)
            end
        end
        template = tableSelectRandom(template_pool)
        p = transformPlayerShip(p, template)
        temp_type_name = p:getTypeName()
        player_starting_templates[template].del = true
    else
        p = transformPlayerShip(p, template)
        temp_type_name = p:getTypeName()
        player_starting_templates[template].del = true
    end
    --set defaults for those ships not found in the list
    p.shipScore = 24
    p.maxCargo = 5
    p.cargo = p.maxCargo
    p.tractor = false
    p.tractor_target_lock = false
    p.mining = false
    p.goods = {}
    p:setFaction(player_faction)
    p.command_log = {}
    p:onDestroyed(playerDestroyed)
    p:onDestruction(playerDestruction)
    if p:getReputationPoints() == 0 then
        p:setReputationPoints(reputation_start_amount)
    end
    if p.probe_type_list == nil then
        p.probe_type_list = {}
        table.insert(p.probe_type_list, { name = "standard", count = -1 })
    end
    if temp_type_name ~= nil then
        local p_stat = player_ship_stats[temp_type_name]
        if p_stat ~= nil then
            p.shipScore = player_ship_stats[temp_type_name].strength
            p.maxCargo = p_stat.cargo
            p.cargo = p.maxCargo
            p:setMaxScanProbeCount(p_stat.probes)
            p:setScanProbeCount(p:getMaxScanProbeCount())
            p:setLongRangeRadarRange(
                player_ship_stats[temp_type_name].long_range_radar
            )
            p:setShortRangeRadarRange(
                player_ship_stats[temp_type_name].short_range_radar
            )
            p.normal_long_range_radar =
                player_ship_stats[temp_type_name].long_range_radar
            p.tractor = p_stat.tractor
            p.tractor_target_lock = false
            p.mining = p_stat.mining
            if p.name_set == nil then
                local player_ship_name_list =
                    player_ship_names_for[temp_type_name]
                local player_ship_name = nil
                if player_ship_name_list ~= nil then
                    player_ship_name = tableRemoveRandom(player_ship_name_list)
                end
                if player_ship_name == nil then
                    player_ship_name =
                        tableSelectRandom(player_ship_names_for["Leftovers"])
                end
                if player_ship_name ~= nil then
                    p:setCallSign(player_ship_name)
                end
                p.name_set = true
            end
            p.score_settings_source = temp_type_name
        else
            addGMMessage(
                string.format(
                    "Player ship %s's template type (%s) could not be found in table player_ship_stats",
                    p:getCallSign(),
                    temp_type_name
                )
            )
        end
    end
    PlayerState.resetBaseline(p, {})
end
function playerDestruction(self, instigator)
    string.format("")
    for i, dp in ipairs(deployed_players) do
        if self == dp.p then
            if dp.count > player_respawn_max then
                globalMessage(
                    string.format(
                        _("msgMainscreen", "%s has been destroyed."),
                        self:getCallSign()
                    )
                )
            else
                local base_template =
                    player_starting_templates[self:getTypeName()].base
                local respawned_player = PlayerSpaceship()
                    :setTemplate(base_template)
                    :setFaction(player_faction)
                dp.p = respawned_player
                dp.count = dp.count + 1
                respawned_player:setCallSign(
                    string.format("%s %i", dp.name, dp.count)
                )
                respawned_player.name_set = true
                updatePlayerSoftTemplate(respawned_player, self:getTypeName())
                globalMessage(
                    string.format(
                        _(
                            "msgMainscreen",
                            "The %s has respawned %s to replace %s."
                        ),
                        player_faction,
                        respawned_player:getCallSign(),
                        self:getCallSign()
                    )
                )
                self:transferPlayersToShip(respawned_player)
            end
            break
        end
    end
end
--	Construct environment functions
function constructEnvironment()
    local markers = {}
    local function setRegionalPlayerSpawnPoints(
        radius,
        obj,
        space_array,
        region
    )
        --passed parameter region used during test. Left in case it's needed again
        local central_spawn_angle = random(0, 360)
        local central_player_spawn_deltas = {
            { angle = central_spawn_angle, dist = radius + 2000 },
            { angle = central_spawn_angle + 180, dist = radius + 2000 },
            { angle = central_spawn_angle + 90, dist = radius + 2000 },
            { angle = central_spawn_angle + 270, dist = radius + 2000 },
            { angle = central_spawn_angle + 45, dist = radius + 2000 },
            { angle = central_spawn_angle + 225, dist = radius + 2000 },
            { angle = central_spawn_angle + 135, dist = radius + 2000 },
            { angle = central_spawn_angle + 315, dist = radius + 2000 },
        }
        local region_center_x, region_center_y = obj:getPosition()
        for i, delta in ipairs(central_player_spawn_deltas) do
            local spawn_x, spawn_y =
                vectorFromAngle(delta.angle, delta.dist, true)
            spawn_x = spawn_x + region_center_x
            spawn_y = spawn_y + region_center_y
            table.insert(player_spawn_points, { x = spawn_x, y = spawn_y })
            local marker = VisualAsteroid():setPosition(spawn_x, spawn_y)
            table.insert(markers, marker)
            table.insert(
                space_array,
                { obj = marker, dist = 500, shape = "circle" }
            )
        end
    end
    local function setStationsInRegion(
        center_object,
        start_radius,
        count,
        region_space,
        stations_list,
        station_angle
    )
        if station_angle == nil then
            station_angle = random(0, 360)
        end
        local region_center_x, region_center_y = center_object:getPosition()
        for i = 1, count do
            station_angle = station_angle + (360 / 5)
            local faction = tableRemoveRandom(faction_pool)
            psx, psy = vectorFromAngle(
                station_angle,
                random(start_radius, 50000),
                true
            )
            local station_name = "RandomHumanNeutral"
            if enemy_factions[faction] ~= nil then
                station_name = "Sinister"
            end
            p_station = placeStation(
                psx + region_center_x,
                psy + region_center_y,
                station_name,
                faction
            )
            table.insert(
                region_space,
                {
                    obj = p_station,
                    dist = station_spacing[p_station:getTypeName()].outer_platform,
                    shape = "circle",
                }
            )
            table.insert(stations, p_station)
            table.insert(stations_list, p_station)
            local ship, ship_size = randomTransportType()
            local sx, sy = vectorFromAngle(station_angle, 50000, true)
            ship:setPosition(sx + region_center_x, sy + region_center_y)
                :setFaction(faction)
                :orderDock(p_station)
            ship:setCallSign(generateCallSign(nil, ship:getFaction()))
            table.insert(transports, ship)
        end
    end
    faction_pool = {}
    for i, faction in ipairs(session_factions) do
        if faction ~= player_faction then
            table.insert(faction_pool, faction)
        end
    end
    inner_space = {}
    --	central star
    local radius = random(600, 1400)
    central_star = Planet()
        :setPlanetRadius(radius)
        :setDistanceFromMovementPlane(-radius * 0.5)
        :setPosition(center_x, center_y)
    if random(1, 100) < 43 then
        central_star:setDistanceFromMovementPlane(radius * 0.5)
    end
    local star_item = tableRemoveRandom(star_list[1].info)
    central_star:setCallSign(star_item.name)
    if star_item.unscanned ~= nil then
        central_star:setDescriptions(star_item.unscanned, star_item.scanned)
        central_star:setScanningParameters(1, 2)
    end
    central_star
        :setPlanetAtmosphereTexture(star_list[1].texture.atmosphere)
        :setPlanetAtmosphereColor(
            random(0.5, 1),
            random(0.5, 1),
            random(0.5, 1)
        )
    table.insert(
        inner_space,
        { obj = central_star, dist = radius, shape = "circle" }
    )
    player_spawn_points = {}
    setRegionalPlayerSpawnPoints(radius, central_star, inner_space, "1")
    --	Region 2 planet
    local region_two_spawn_angle = random(0, 360)
    center_region_two_x, center_region_two_y =
        vectorFromAngle(region_two_spawn_angle, 150000, true)
    center_region_two_x = center_region_two_x + center_x
    center_region_two_y = center_region_two_y + center_y
    local region_two_planet_item = tableRemoveRandom(planet_list)
    local region_two_planet_radius = region_two_planet_item.radius
    region_two_planet = Planet()
        :setPosition(center_region_two_x, center_region_two_y)
        :setPlanetRadius(region_two_planet_radius)
    region_two_planet:setDistanceFromMovementPlane(
        region_two_planet_radius * -0.25
    )
    region_two_planet:setCallSign(
        tableSelectRandom(region_two_planet_item.name)
    )
    region_two_planet:setPlanetSurfaceTexture(
        region_two_planet_item.texture.surface
    )
    local rotation_time = random(500, 700)
    if region_two_planet_item.texture.atmosphere ~= nil then
        rotation_time = rotation_time * 0.65
        region_two_planet:setPlanetAtmosphereTexture(
            region_two_planet_item.texture.atmosphere
        )
    end
    if region_two_planet_item.texture.cloud ~= nil then
        region_two_planet:setPlanetCloudTexture(
            region_two_planet_item.texture.cloud
        )
    end
    if region_two_planet_item.color ~= nil then
        region_two_planet:setPlanetAtmosphereColor(
            region_two_planet_item.color.red,
            region_two_planet_item.color.green,
            region_two_planet_item.color.blue
        )
    end
    region_two_planet:setAxialRotationTime(rotation_time)
    region_two_space = {}
    table.insert(
        region_two_space,
        {
            obj = region_two_planet,
            dist = region_two_planet_radius * 1.5 + 1000,
            shape = "circle",
        }
    )
    setRegionalPlayerSpawnPoints(
        region_two_planet_radius,
        region_two_planet,
        region_two_space,
        "2"
    )
    --	Region 3 moon
    local region_three_spawn_angle = region_two_spawn_angle + random(90, 150)
    center_region_three_x, center_region_three_y =
        vectorFromAngle(region_three_spawn_angle, random(150000, 200000), true)
    center_region_three_x = center_region_three_x + center_x
    center_region_three_y = center_region_three_y + center_y
    local region_three_moon_item = tableRemoveRandom(moon_list)
    local region_three_moon_radius = region_three_moon_item.radius
    region_three_moon = Planet():setPosition(
        center_region_three_x,
        center_region_three_y
    ):setPlanetRadius(region_three_moon_radius)
    region_three_moon:setDistanceFromMovementPlane(
        region_three_moon_radius * 0.25
    )
    region_three_moon:setCallSign(
        tableSelectRandom(region_three_moon_item.name)
    )
    region_three_moon:setPlanetSurfaceTexture(
        region_three_moon_item.texture.surface
    )
    region_three_moon:setAxialRotationTime(random(400, 600))
    region_three_space = {}
    table.insert(
        region_three_space,
        {
            obj = region_three_moon,
            dist = region_three_moon_radius * 1.5 + 1000,
            shape = "circle",
        }
    )
    setRegionalPlayerSpawnPoints(
        region_three_moon_radius,
        region_three_moon,
        region_three_space,
        "3"
    )
    --	Region 4 planet
    local region_four_spawn_angle = (
        region_three_spawn_angle
        + region_two_spawn_angle
        + 360
    ) / 2
    center_region_four_x, center_region_four_y =
        vectorFromAngle(region_four_spawn_angle, random(150000, 200000), true)
    center_region_four_x = center_region_four_x + center_x
    center_region_four_y = center_region_four_y + center_y
    local region_four_planet_item = tableRemoveRandom(planet_list)
    local region_four_planet_radius = region_four_planet_item.radius
    region_four_planet = Planet():setPosition(
        center_region_four_x,
        center_region_four_y
    ):setPlanetRadius(region_four_planet_radius)
    region_four_planet:setDistanceFromMovementPlane(
        region_four_planet_radius * -0.3
    )
    region_four_planet:setCallSign(
        tableSelectRandom(region_four_planet_item.name)
    )
    region_four_planet:setPlanetSurfaceTexture(
        region_four_planet_item.texture.surface
    )
    rotation_time = random(500, 700)
    if region_four_planet_item.texture.atmosphere ~= nil then
        rotation_time = rotation_time * 0.65
        region_four_planet:setPlanetAtmosphereTexture(
            region_four_planet_item.texture.atmosphere
        )
    end
    if region_four_planet_item.texture.cloud ~= nil then
        region_four_planet:setPlanetCloudTexture(
            region_four_planet_item.texture.cloud
        )
    end
    if region_four_planet_item.color ~= nil then
        region_four_planet:setPlanetAtmosphereColor(
            region_four_planet_item.color.red,
            region_four_planet_item.color.green,
            region_four_planet_item.color.blue
        )
    end
    region_four_planet:setAxialRotationTime(rotation_time)
    region_four_space = {}
    table.insert(
        region_four_space,
        {
            obj = region_four_planet,
            dist = region_four_planet_radius * 1.5 + 1000,
            shape = "circle",
        }
    )
    setRegionalPlayerSpawnPoints(
        region_four_planet_radius,
        region_four_planet,
        region_four_space,
        "4"
    )
    --	set stations and transports
    inner_stations = {}
    stations = {}
    local station_angle = random(0, 360)
    local psx, psy = vectorFromAngle(station_angle, random(4000, 50000), true)
    local p_station = placeStation(
        psx + center_x,
        psy + center_y,
        "RandomHumanNeutral",
        player_faction
    )
    table.insert(
        inner_space,
        {
            obj = p_station,
            dist = station_spacing[p_station:getTypeName()].outer_platform,
            shape = "circle",
        }
    )
    table.insert(stations, p_station)
    table.insert(inner_stations, p_station)
    transports = {}
    local ship, ship_size = randomTransportType()
    local sx, sy = vectorFromAngle(station_angle, 50000, true)
    ship:setPosition(sx + center_x, sy + center_y)
        :setFaction(player_faction)
        :orderDock(p_station)
    table.insert(transports, ship)
    setStationsInRegion(
        central_star,
        radius + 4000,
        4,
        inner_space,
        inner_stations,
        station_angle
    )
    outer_stations = {}
    region_two_stations = {}
    setStationsInRegion(
        region_two_planet,
        region_two_planet_radius + 4000,
        5,
        region_two_space,
        region_two_stations
    )
    for i, faction in ipairs(session_factions) do
        table.insert(faction_pool, faction)
    end
    region_three_stations = {}
    setStationsInRegion(
        region_three_moon,
        region_three_moon_radius + 4000,
        5,
        region_three_space,
        region_three_stations
    )
    region_four_stations = {}
    setStationsInRegion(
        region_four_planet,
        region_four_planet_radius + 4000,
        5,
        region_four_space,
        region_four_stations
    )
    for i, station in ipairs(region_two_stations) do
        table.insert(outer_stations, station)
    end
    for i, station in ipairs(region_three_stations) do
        table.insert(outer_stations, station)
    end
    for i, station in ipairs(region_four_stations) do
        table.insert(outer_stations, station)
    end
    friendly_spike_stations = {}
    for i, station in ipairs(outer_stations) do
        if non_enemy_lookup_factions[station:getFaction()] then
            table.insert(friendly_spike_stations, station)
        end
    end
    station_list = {}
    for i, station in ipairs(stations) do
        table.insert(station_list, station)
    end
    --	spread the goods (buy, sell, trade) around the stations
    local station_sell_goods_pool = {}
    local station_buy_goods_pool = {}
    local stations_with_no_goods_for_sale = {}
    local stations_that_do_not_buy_goods = {}
    for i, station in ipairs(stations) do
        if station.comms_data == nil then
            station.comms_data = {}
        end
        if station.comms_data.goods == nil then
            station.comms_data.goods = {}
        end
        if station.comms_data.buy == nil then
            station.comms_data.buy = {}
        end
        if station.comms_data.trade == nil then
            station.comms_data.trade = {
                food = random(1, 100) <= 18,
                medicine = random(1, 100) <= 23,
                luxury = random(1, 100) <= 35,
            }
        end
        local good_sell_count = 0
        for good, details in pairs(station.comms_data.goods) do
            if details.quantity ~= nil and details.quantity > 0 then
                good_sell_count = good_sell_count + 1
                station_sell_goods_pool[good] = true
            end
        end
        if good_sell_count == 0 then
            table.insert(stations_with_no_goods_for_sale, station)
        end
        local good_buy_count = 0
        for good, price in pairs(station.comms_data.buy) do
            good_buy_count = good_buy_count + 1
            station_buy_goods_pool[good] = true
        end
        if good_buy_count == 0 then
            table.insert(stations_that_do_not_buy_goods, station)
        end
    end
    local station_available_sell_goods_pool = {}
    local station_available_buy_goods_pool = {}
    for i, good in ipairs(commonGoods) do
        if
            station_sell_goods_pool[good] == nil
            or not station_sell_goods_pool[good]
        then
            table.insert(station_available_sell_goods_pool, good)
        end
        if
            station_buy_goods_pool[good] == nil
            or not station_buy_goods_pool[good]
        then
            table.insert(station_available_buy_goods_pool, good)
        end
    end
    for i, station in ipairs(stations_with_no_goods_for_sale) do
        local good = tableRemoveRandom(station_available_sell_goods_pool)
        if good ~= nil then
            if good == "food" then
                station.comms_data.goods[good] =
                    { quantity = math.random(5, 9), cost = 1 }
            elseif good == "medicine" then
                station.comms_data.goods[good] =
                    { quantity = math.random(5, 9), cost = 5 }
            elseif good == "luxury" then
                station.comms_data.goods[good] =
                    { quantity = math.random(5, 9), cost = math.random(20, 40) }
            else
                station.comms_data.goods[good] = {
                    quantity = math.random(5, 9),
                    cost = math.random(60, 120),
                }
            end
        end
    end
    for i, station in ipairs(stations_that_do_not_buy_goods) do
        local good = tableRemoveRandom(station_available_buy_goods_pool)
        if good ~= nil then
            if station.comms_data.goods[good] == nil then
                if good == "food" then
                    station.comms_data.buy[good] = math.random(2, 4)
                elseif good == "medicine" then
                    station.comms_data.buy[good] = math.random(7, 20)
                elseif good == "luxury" then
                    station.comms_data.buy[good] = math.random(45, 80)
                else
                    station.comms_data.buy[good] = math.random(60, 200)
                end
            else
                local second_good =
                    tableRemoveRandom(station_available_buy_goods_pool)
                if second_good ~= nil then
                    if station.comms_data.goods[second_good] == nil then
                        if second_good == "food" then
                            station.comms_data.buy[second_good] =
                                math.random(2, 4)
                        elseif second_good == "medicine" then
                            station.comms_data.buy[second_good] =
                                math.random(7, 20)
                        elseif second_good == "luxury" then
                            station.comms_data.buy[second_good] =
                                math.random(45, 80)
                        else
                            station.comms_data.buy[second_good] =
                                math.random(60, 200)
                        end
                    else
                        local third_good =
                            tableRemoveRandom(station_available_buy_goods_pool)
                        if third_good ~= nil then
                            if third_good == "food" then
                                station.comms_data.buy[third_good] =
                                    math.random(2, 4)
                            elseif third_good == "medicine" then
                                station.comms_data.buy[third_good] =
                                    math.random(7, 20)
                            elseif third_good == "luxury" then
                                station.comms_data.buy[third_good] =
                                    math.random(45, 80)
                            else
                                station.comms_data.buy[third_good] =
                                    math.random(60, 200)
                            end
                        end
                        table.insert(
                            station_available_buy_goods_pool,
                            second_good
                        )
                    end
                end
                table.insert(station_available_buy_goods_pool, good)
            end
        end
    end
    good_spread = {}
    for i, ship in ipairs(transports) do
        ship.comms_data = { friendlyness = random(0, 100) }
        goodsOnShip(ship, ship.comms_data)
    end
    --	band planet
    local band_angle = random(0, 360)
    local bp_x, bp_y = vectorFromAngle(band_angle, 75000, true)
    local band_planet_item = tableRemoveRandom(planet_list)
    local band_planet_radius = band_planet_item.radius
    band_planet = Planet()
        :setPosition(bp_x + center_x, bp_y + center_y)
        :setPlanetRadius(band_planet_radius)
    band_planet:setDistanceFromMovementPlane(band_planet_radius * -0.3)
    band_planet:setCallSign(tableSelectRandom(band_planet_item.name))
    band_planet:setPlanetSurfaceTexture(band_planet_item.texture.surface)
    rotation_time = random(300, 500)
    if band_planet_item.texture.atmosphere ~= nil then
        rotation_time = rotation_time * 0.65
        band_planet:setPlanetAtmosphereTexture(
            band_planet_item.texture.atmosphere
        )
    end
    if band_planet_item.texture.cloud ~= nil then
        band_planet:setPlanetCloudTexture(band_planet_item.texture.cloud)
    end
    if band_planet_item.color ~= nil then
        band_planet:setPlanetAtmosphereColor(
            band_planet_item.color.red,
            band_planet_item.color.green,
            band_planet_item.color.blue
        )
    end
    band_planet:setAxialRotationTime(rotation_time)
    band_planet:setOrbit(central_star, 2300)
    band_angle = random(0, 360)
    local bm_x, bm_y = vectorFromAngle(band_angle, band_planet_radius + 6000)
    local band_moon_item = tableRemoveRandom(moon_list)
    local band_moon_radius = band_moon_item.radius
    band_moon = Planet()
        :setPosition(bm_x + bp_x + center_x, bm_y + bp_y + center_y)
        :setPlanetRadius(band_moon_radius)
    band_moon:setDistanceFromMovementPlane(band_moon_radius * 0.25)
    band_moon:setCallSign(tableSelectRandom(band_moon_item.name))
    band_moon:setPlanetSurfaceTexture(band_moon_item.texture.surface)
    band_moon:setAxialRotationTime(random(400, 600))
    band_moon:setOrbit(band_planet, random(100, 300))
    distort_bell = {
        { lo = 1000, hi = 2250 },
        { lo = 1000, hi = 2250 },
        { lo = 1000, hi = 2250 },
        { lo = 1000, hi = 2250 },
        { lo = 1000, hi = 2250 },
        { lo = 1000, hi = 2250 },
        { lo = 1000, hi = 2250 },
        { lo = 1000, hi = 2250 },
    }
    placement_areas = {
        ["Inner Torus"] = {
            stations = inner_stations,
            transports = transports,
            space = inner_space,
            shape = "torus",
            center_x = center_x,
            center_y = center_y,
            inner_radius = radius + 4000,
            outer_radius = 50000,
        },
        ["Region 2 Torus"] = {
            stations = region_two_stations,
            transports = transports,
            space = region_two_space,
            shape = "torus",
            center_x = center_region_two_x,
            center_y = center_region_two_y,
            inner_radius = region_two_planet_radius + 4000,
            outer_radius = 50000,
        },
        ["Region 3 Torus"] = {
            stations = region_three_stations,
            transports = transports,
            space = region_three_space,
            shape = "torus",
            center_x = center_region_three_x,
            center_y = center_region_three_y,
            inner_radius = region_three_moon_radius + 4000,
            outer_radius = 50000,
        },
        ["Region 4 Torus"] = {
            stations = region_four_stations,
            transports = transports,
            space = region_four_space,
            shape = "torus",
            center_x = center_region_four_x,
            center_y = center_region_four_y,
            inner_radius = region_four_planet_radius + 4000,
            outer_radius = 50000,
        },
    }
    local terrain = {
        --		{chance = 4,	count = 0,	max = math.random(1,2),		radius = "Star",	obj = Planet,		desc = "Star",		},
        --		{chance = 4,	count = 0,	max = math.random(1,2),		radius = "Hole",	obj = BlackHole,						},
        {
            chance = 7,
            count = 0,
            max = -1,
            radius = "Tiny",
            obj = ScanProbe,
        },
        {
            chance = 4,
            count = 0,
            max = math.random(7, 15),
            radius = "Tiny",
            obj = WarpJammer,
        },
        {
            chance = 6,
            count = 0,
            max = math.random(3, 9),
            radius = "Tiny",
            obj = Artifact,
            desc = "Jammer",
        },
        --		{chance = 3,	count = 0,	max = math.random(1,3),		radius = "Hole",	obj = WormHole,							},
        {
            chance = 6,
            count = 0,
            max = math.random(2, 5),
            radius = "Tiny",
            obj = Artifact,
            desc = "Sensor",
        },
        {
            chance = 8,
            count = 0,
            max = -1,
            radius = "Tiny",
            obj = Artifact,
            desc = "Ad",
        },
        {
            chance = 8,
            count = 0,
            max = -1,
            radius = "Neb",
            obj = Nebula,
        },
        {
            chance = 5,
            count = 0,
            max = -1,
            radius = "Mine",
            obj = Mine,
        },
        {
            chance = 5,
            count = 0,
            max = math.random(3, 7),
            radius = "Circ",
            obj = Mine,
            desc = "Circle",
        },
        {
            chance = 5,
            count = 0,
            max = math.random(3, 9),
            radius = "Rect",
            obj = Mine,
            desc = "Rectangle",
        },
        {
            chance = 5,
            count = 0,
            max = math.random(2, 7),
            radius = "Field",
            obj = Asteroid,
            desc = "Field",
        },
        {
            chance = 6,
            count = 0,
            max = math.random(3, 9),
            radius = "Blob",
            obj = Asteroid,
            desc = "Blob",
        },
        {
            chance = 6,
            count = 0,
            max = math.random(3, 9),
            radius = "Blob",
            obj = Mine,
            desc = "Blob",
        },
        --		{chance = 4,	count = 0,	max = 10,					radius = "Trans",	obj = CpuShip,		desc = "Transport",	},
        {
            chance = 4,
            count = 0,
            max = 10,
            radius = "Tiny",
            obj = SupplyDrop,
        },
    }
    local objects_placed_count = 0
    repeat
        local roll = random(0, 100)
        local object_chance = 0
        for i, terrain_object in ipairs(terrain) do
            object_chance = object_chance + terrain_object.chance
            local placement_result = false
            if roll <= object_chance then
                if
                    terrain_object.max < 0
                    or terrain_object.count < terrain_object.max
                then
                    placement_result =
                        placeTerrain("Inner Torus", terrain_object)
                else
                    placement_result = placeTerrain(
                        "Inner Torus",
                        { obj = Asteroid, desc = "Lone", radius = "Tiny" }
                    )
                end
                if placement_result then
                    terrain_object.count = terrain_object.count + 1
                end
                break
            elseif i == #terrain then
                placement_result = placeTerrain(
                    "Inner Torus",
                    { obj = Asteroid, desc = "Lone", radius = "Tiny" }
                )
                if placement_result then
                    terrain_object.count = terrain_object.count + 1
                end
            end
        end
        objects_placed_count = objects_placed_count + 1
    until objects_placed_count >= 75
    terrain = {
        --		{chance = 4,	count = 0,	max = math.random(1,2),		radius = "Star",	obj = Planet,		desc = "Star",		},
        {
            chance = 4,
            count = 0,
            max = math.random(1, 2),
            radius = "Hole",
            obj = BlackHole,
        },
        {
            chance = 7,
            count = 0,
            max = -1,
            radius = "Tiny",
            obj = ScanProbe,
        },
        {
            chance = 4,
            count = 0,
            max = math.random(7, 15),
            radius = "Tiny",
            obj = WarpJammer,
        },
        {
            chance = 6,
            count = 0,
            max = math.random(3, 9),
            radius = "Tiny",
            obj = Artifact,
            desc = "Jammer",
        },
        --		{chance = 3,	count = 0,	max = math.random(1,3),		radius = "Hole",	obj = WormHole,							},
        {
            chance = 6,
            count = 0,
            max = math.random(2, 5),
            radius = "Tiny",
            obj = Artifact,
            desc = "Sensor",
        },
        {
            chance = 8,
            count = 0,
            max = -1,
            radius = "Tiny",
            obj = Artifact,
            desc = "Ad",
        },
        {
            chance = 8,
            count = 0,
            max = -1,
            radius = "Neb",
            obj = Nebula,
        },
        {
            chance = 5,
            count = 0,
            max = -1,
            radius = "Mine",
            obj = Mine,
        },
        {
            chance = 5,
            count = 0,
            max = math.random(3, 7),
            radius = "Circ",
            obj = Mine,
            desc = "Circle",
        },
        {
            chance = 5,
            count = 0,
            max = math.random(3, 9),
            radius = "Rect",
            obj = Mine,
            desc = "Rectangle",
        },
        {
            chance = 5,
            count = 0,
            max = math.random(2, 7),
            radius = "Field",
            obj = Asteroid,
            desc = "Field",
        },
        {
            chance = 6,
            count = 0,
            max = math.random(3, 9),
            radius = "Blob",
            obj = Asteroid,
            desc = "Blob",
        },
        {
            chance = 6,
            count = 0,
            max = math.random(3, 9),
            radius = "Blob",
            obj = Mine,
            desc = "Blob",
        },
        --		{chance = 4,	count = 0,	max = 10,					radius = "Trans",	obj = CpuShip,		desc = "Transport",	},
        {
            chance = 4,
            count = 0,
            max = 10,
            radius = "Tiny",
            obj = SupplyDrop,
        },
    }
    objects_placed_count = 0
    repeat
        local roll = random(0, 100)
        local object_chance = 0
        for i, terrain_object in ipairs(terrain) do
            object_chance = object_chance + terrain_object.chance
            local placement_result = false
            if roll <= object_chance then
                if
                    terrain_object.max < 0
                    or terrain_object.count < terrain_object.max
                then
                    placement_result =
                        placeTerrain("Region 2 Torus", terrain_object)
                else
                    placement_result = placeTerrain(
                        "Region 2 Torus",
                        { obj = Asteroid, desc = "Lone", radius = "Tiny" }
                    )
                end
                if placement_result then
                    terrain_object.count = terrain_object.count + 1
                end
                break
            elseif i == #terrain then
                placement_result = placeTerrain(
                    "Region 2 Torus",
                    { obj = Asteroid, desc = "Lone", radius = "Tiny" }
                )
                if placement_result then
                    terrain_object.count = terrain_object.count + 1
                end
            end
        end
        objects_placed_count = objects_placed_count + 1
    until objects_placed_count >= 75
    terrain = {
        --		{chance = 4,	count = 0,	max = math.random(1,2),		radius = "Star",	obj = Planet,		desc = "Star",		},
        {
            chance = 4,
            count = 0,
            max = math.random(1, 2),
            radius = "Hole",
            obj = BlackHole,
        },
        {
            chance = 7,
            count = 0,
            max = -1,
            radius = "Tiny",
            obj = ScanProbe,
        },
        {
            chance = 4,
            count = 0,
            max = math.random(7, 15),
            radius = "Tiny",
            obj = WarpJammer,
        },
        {
            chance = 6,
            count = 0,
            max = math.random(3, 9),
            radius = "Tiny",
            obj = Artifact,
            desc = "Jammer",
        },
        --		{chance = 3,	count = 0,	max = math.random(1,3),		radius = "Hole",	obj = WormHole,							},
        {
            chance = 6,
            count = 0,
            max = math.random(2, 5),
            radius = "Tiny",
            obj = Artifact,
            desc = "Sensor",
        },
        {
            chance = 8,
            count = 0,
            max = -1,
            radius = "Tiny",
            obj = Artifact,
            desc = "Ad",
        },
        {
            chance = 8,
            count = 0,
            max = -1,
            radius = "Neb",
            obj = Nebula,
        },
        {
            chance = 5,
            count = 0,
            max = -1,
            radius = "Mine",
            obj = Mine,
        },
        {
            chance = 5,
            count = 0,
            max = math.random(3, 7),
            radius = "Circ",
            obj = Mine,
            desc = "Circle",
        },
        {
            chance = 5,
            count = 0,
            max = math.random(3, 9),
            radius = "Rect",
            obj = Mine,
            desc = "Rectangle",
        },
        {
            chance = 5,
            count = 0,
            max = math.random(2, 7),
            radius = "Field",
            obj = Asteroid,
            desc = "Field",
        },
        {
            chance = 6,
            count = 0,
            max = math.random(3, 9),
            radius = "Blob",
            obj = Asteroid,
            desc = "Blob",
        },
        {
            chance = 6,
            count = 0,
            max = math.random(3, 9),
            radius = "Blob",
            obj = Mine,
            desc = "Blob",
        },
        --		{chance = 4,	count = 0,	max = 10,					radius = "Trans",	obj = CpuShip,		desc = "Transport",	},
        {
            chance = 4,
            count = 0,
            max = 10,
            radius = "Tiny",
            obj = SupplyDrop,
        },
    }
    objects_placed_count = 0
    repeat
        local roll = random(0, 100)
        local object_chance = 0
        for i, terrain_object in ipairs(terrain) do
            object_chance = object_chance + terrain_object.chance
            local placement_result = false
            if roll <= object_chance then
                if
                    terrain_object.max < 0
                    or terrain_object.count < terrain_object.max
                then
                    placement_result =
                        placeTerrain("Region 3 Torus", terrain_object)
                else
                    placement_result = placeTerrain(
                        "Region 3 Torus",
                        { obj = Asteroid, desc = "Lone", radius = "Tiny" }
                    )
                end
                if placement_result then
                    terrain_object.count = terrain_object.count + 1
                end
                break
            elseif i == #terrain then
                placement_result = placeTerrain(
                    "Region 3 Torus",
                    { obj = Asteroid, desc = "Lone", radius = "Tiny" }
                )
                if placement_result then
                    terrain_object.count = terrain_object.count + 1
                end
            end
        end
        objects_placed_count = objects_placed_count + 1
    until objects_placed_count >= 75
    terrain = {
        --		{chance = 4,	count = 0,	max = math.random(1,2),		radius = "Star",	obj = Planet,		desc = "Star",		},
        {
            chance = 4,
            count = 0,
            max = math.random(1, 2),
            radius = "Hole",
            obj = BlackHole,
        },
        {
            chance = 7,
            count = 0,
            max = -1,
            radius = "Tiny",
            obj = ScanProbe,
        },
        {
            chance = 4,
            count = 0,
            max = math.random(7, 15),
            radius = "Tiny",
            obj = WarpJammer,
        },
        {
            chance = 6,
            count = 0,
            max = math.random(3, 9),
            radius = "Tiny",
            obj = Artifact,
            desc = "Jammer",
        },
        --		{chance = 3,	count = 0,	max = math.random(1,3),		radius = "Hole",	obj = WormHole,							},
        {
            chance = 6,
            count = 0,
            max = math.random(2, 5),
            radius = "Tiny",
            obj = Artifact,
            desc = "Sensor",
        },
        {
            chance = 8,
            count = 0,
            max = -1,
            radius = "Tiny",
            obj = Artifact,
            desc = "Ad",
        },
        {
            chance = 8,
            count = 0,
            max = -1,
            radius = "Neb",
            obj = Nebula,
        },
        {
            chance = 5,
            count = 0,
            max = -1,
            radius = "Mine",
            obj = Mine,
        },
        {
            chance = 5,
            count = 0,
            max = math.random(3, 7),
            radius = "Circ",
            obj = Mine,
            desc = "Circle",
        },
        {
            chance = 5,
            count = 0,
            max = math.random(3, 9),
            radius = "Rect",
            obj = Mine,
            desc = "Rectangle",
        },
        {
            chance = 5,
            count = 0,
            max = math.random(2, 7),
            radius = "Field",
            obj = Asteroid,
            desc = "Field",
        },
        {
            chance = 6,
            count = 0,
            max = math.random(3, 9),
            radius = "Blob",
            obj = Asteroid,
            desc = "Blob",
        },
        {
            chance = 6,
            count = 0,
            max = math.random(3, 9),
            radius = "Blob",
            obj = Mine,
            desc = "Blob",
        },
        --		{chance = 4,	count = 0,	max = 10,					radius = "Trans",	obj = CpuShip,		desc = "Transport",	},
        {
            chance = 4,
            count = 0,
            max = 10,
            radius = "Tiny",
            obj = SupplyDrop,
        },
    }
    objects_placed_count = 0
    repeat
        local roll = random(0, 100)
        local object_chance = 0
        for i, terrain_object in ipairs(terrain) do
            object_chance = object_chance + terrain_object.chance
            local placement_result = false
            if roll <= object_chance then
                if
                    terrain_object.max < 0
                    or terrain_object.count < terrain_object.max
                then
                    placement_result =
                        placeTerrain("Region 4 Torus", terrain_object)
                else
                    placement_result = placeTerrain(
                        "Region 4 Torus",
                        { obj = Asteroid, desc = "Lone", radius = "Tiny" }
                    )
                end
                if placement_result then
                    terrain_object.count = terrain_object.count + 1
                end
                break
            elseif i == #terrain then
                placement_result = placeTerrain(
                    "Region 4 Torus",
                    { obj = Asteroid, desc = "Lone", radius = "Tiny" }
                )
                if placement_result then
                    terrain_object.count = terrain_object.count + 1
                end
            end
        end
        objects_placed_count = objects_placed_count + 1
    until objects_placed_count >= 75

    --after done building terrain, delete markers
    for i, marker in ipairs(markers) do
        marker:destroy()
    end
end
function placeTerrain(placement_area, terrain)
    local function getStationPool(placement_area)
        local station_pool = {}
        if
            placement_areas[placement_area].stations ~= nil
            and #placement_areas[placement_area].stations > 0
        then
            for i, station in ipairs(placement_areas[placement_area].stations) do
                if station:isValid() then
                    table.insert(station_pool, station)
                end
            end
        end
        return station_pool
    end
    local function placeAsteroid(placement_area)
        local asteroid_size = random(2, 200)
            + random(2, 200)
            + random(2, 200)
            + random(2, 200)
        local area = placement_areas[placement_area]
        local eo_x, eo_y = nil
        if
            placement_area == "Inner Torus"
            or placement_area == "Region 2 Torus"
            or placement_area == "Region 3 Torus"
            or placement_area == "Region 4 Torus"
        then
            eo_x, eo_y = Environment.findClearSpot(
                area.space,
                area.shape,
                area.center_x,
                area.center_y,
                area.inner_radius,
                area.outer_radius,
                nil,
                asteroid_size
            )
        end
        if eo_x ~= nil then
            local ta = Asteroid():setPosition(eo_x, eo_y):setSize(asteroid_size)
            table.insert(
                area.space,
                { obj = ta, dist = asteroid_size, shape = "circle" }
            )
            local tether = random(asteroid_size + 10, 800)
            local v_angle = random(0, 360)
            local vx, vy = vectorFromAngle(v_angle, tether, true)
            vx = vx + eo_x
            vy = vy + eo_y
            local vast =
                VisualAsteroid():setPosition(vx, vy):setSize(random(10, tether))
            tether = random(asteroid_size + 10, asteroid_size + 800)
            v_angle = (v_angle + random(120, 240)) % 360
            local vx, vy = vectorFromAngle(v_angle, tether, true)
            vx = vx + eo_x
            vy = vy + eo_x
            vast =
                VisualAsteroid():setPosition(vx, vy):setSize(random(10, tether))
            return true
        else
            return false
        end
    end
    local radii = {
        ["Blob"] = random(1500, 4500),
        ["Star"] = random(600, 1400),
        ["Hole"] = 6000,
        ["Tiny"] = 200,
        ["Neb"] = 3000,
        ["Mine"] = 1000,
        ["Rect"] = random(4000, 10000),
        ["Circ"] = 4000,
        ["Field"] = random(2000, 8000),
        ["Trans"] = 600,
    }
    local area = placement_areas[placement_area]
    local radius = radii[terrain.radius]
    if radius == nil then
        radius = 200
    end
    local eo_x, eo_y = nil
    --	exceptions to a simple radius for findClearSpot
    local field_size = 0
    if terrain.desc == "Circle" then
        field_size = math.random(1, 3)
        radius = radius + (field_size * 1500)
    elseif terrain.desc == "Field" then
        field_size = radius
        radius = radius + 500
    end
    if
        placement_area == "Inner Torus"
        or placement_area == "Region 2 Torus"
        or placement_area == "Region 3 Torus"
        or placement_area == "Region 4 Torus"
    then
        eo_x, eo_y = Environment.findClearSpot(
            area.space,
            area.shape,
            area.center_x,
            area.center_y,
            area.inner_radius,
            area.outer_radius,
            nil,
            radius
        )
    end
    if eo_x ~= nil then
        if terrain.obj == WormHole then
            local we_x, we_y = nil
            local count_repeat_loop = 0
            repeat
                if
                    placement_area == "Region 2 Torus"
                    or placement_area == "Region 3 Torus"
                    or placement_area == "Region 4 Torus"
                then
                    we_x, we_y = Environment.findClearSpot(
                        area.space,
                        area.shape,
                        area.center_x,
                        area.center_y,
                        area.inner_radius,
                        area.outer_radius,
                        nil,
                        500
                    )
                end
                count_repeat_loop = count_repeat_loop + 1
                if distance_diagnostic then
                    print(
                        "distance_diagnostic 6: eo_x, eo_y, we_x, we_y: place terrain, wormhole",
                        eo_x,
                        eo_y,
                        we_x,
                        we_y
                    )
                end
            until (we_x ~= nil and distance(eo_x, eo_y, we_x, we_y) > 50000)
                or count_repeat_loop > max_repeat_loop
            if count_repeat_loop > max_repeat_loop then
                print("repeated too many times while placing a wormhole")
                print(
                    "eo_x:",
                    eo_x,
                    "eo_y:",
                    eo_y,
                    "we_x:",
                    we_x,
                    "we_y:",
                    we_y
                )
            end
            if we_x ~= nil then
                local wh = WormHole()
                    :setPosition(eo_x, eo_y)
                    :setTargetPosition(we_x, we_y)
                wh:onTeleportation(function(self, transportee)
                    string.format("")
                    if transportee ~= nil then
                        if transportee:isValid() then
                            if isObjectType(transportee, "PlayerSpaceship") then
                                transportee:setEnergy(
                                    transportee:getMaxEnergy() / 2
                                ) --reduces if more than half, increases if less than half
                            end
                        end
                    end
                end)
                local va_exit = VisualAsteroid():setPosition(we_x, we_y)
                table.insert(
                    area.space,
                    { obj = wh, dist = 6000, shape = "circle" }
                )
                table.insert(
                    area.space,
                    { obj = va_exit, dist = 500, shape = "circle" }
                )
                return true
            else
                placeAsteroid(placement_area)
                return false
            end
        elseif terrain.desc == "Jammer" then
            local lo_range = 10000
            local hi_range = 50000
            local lo_impact = 10000
            local hi_impact = 40000
            local range_increment = (hi_range - lo_range) / 8
            local impact_increment = (hi_impact - lo_impact) / 4
            --	local mix = math.random(2,10 - (4 - (2*math.floor(difficulty))))	--	2-6, 2-8, 2-10
            local mix = math.random(2, 10 - (4 - 2)) --	2-8
            sensor_jammer_scan_complexity = 1
            sensor_jammer_scan_depth = 1
            if mix > 5 then
                sensor_jammer_scan_depth =
                    math.min(math.random(mix - 4, mix), 8)
                sensor_jammer_scan_complexity =
                    math.max(mix - sensor_jammer_scan_depth, 1)
            else
                sensor_jammer_scan_depth = math.random(1, mix)
                sensor_jammer_scan_complexity =
                    math.max(mix - sensor_jammer_scan_depth, 1)
            end
            sensor_jammer_range = lo_range
                + (sensor_jammer_scan_depth * range_increment)
            sensor_jammer_impact = lo_impact
                + (sensor_jammer_scan_complexity * impact_increment)
            local sj = sensorJammer(eo_x, eo_y)
            table.insert(
                area.space,
                { obj = sj, dist = radius, shape = "circle" }
            )
            return true
        elseif terrain.desc == "Circle" then
            local mine_circle = {
                { inner_count = 4, mid_count = 10, outer_count = 15 }, --1
                { inner_count = 9, mid_count = 15, outer_count = 20 }, --2
                { inner_count = 15, mid_count = 20, outer_count = 25 }, --3
            }
            --	field_size randomized earlier (1 to 3)
            local angle = random(0, 360)
            local mine_x, mine_y = 0
            for i = 1, mine_circle[field_size].inner_count do
                mine_x, mine_y = vectorFromAngle(angle, field_size * 1000)
                local m = Mine():setPosition(eo_x + mine_x, eo_y + mine_y)
                table.insert(
                    area.space,
                    { obj = m, dist = 1000, shape = "circle" }
                )
                angle = (angle + (360 / mine_circle[field_size].inner_count))
                    % 360
            end
            for i = 1, mine_circle[field_size].mid_count do
                mine_x, mine_y =
                    vectorFromAngle(angle, field_size * 1000 + 1200)
                local m = Mine():setPosition(eo_x + mine_x, eo_y + mine_y)
                table.insert(
                    area.space,
                    { obj = m, dist = 1000, shape = "circle" }
                )
                angle = (angle + (360 / mine_circle[field_size].mid_count))
                    % 360
            end
            if random(1, 100) < 50 then
                local n_x, n_y =
                    vectorFromAngle(random(0, 360), random(50, 2000))
                local neb = Nebula():setPosition(eo_x + n_x, eo_y + n_y)
                neb:setDescriptions(
                    _("scienceDescription-nebula", "Nebula"),
                    _("scienceDescription-nebula", "Nebula")
                )
                neb:setScanningParameters(2, 1)
            end
            return true
        elseif terrain.desc == "Field" then --asteroid field
            local asteroid_field = {}
            for n = 1, math.floor(field_size / random(300, 500)) do
                local asteroid_size = 0
                for s = 1, 4 do
                    asteroid_size = asteroid_size + random(2, 200)
                end
                local dist = random(100, field_size)
                local x, y = Environment.findClearSpot(
                    asteroid_field,
                    "bell torus",
                    eo_x,
                    eo_y,
                    field_size,
                    distort_bell,
                    nil,
                    asteroid_size
                )
                if x ~= nil then
                    local ast =
                        Asteroid():setPosition(x, y):setSize(asteroid_size)
                    table.insert(
                        area.space,
                        { obj = ast, dist = asteroid_size, shape = "circle" }
                    )
                    table.insert(
                        asteroid_field,
                        { obj = ast, dist = asteroid_size, shape = "circle" }
                    )
                    local tether = random(asteroid_size + 10, 800)
                    local v_angle = random(0, 360)
                    local vx, vy = vectorFromAngle(v_angle, tether, true)
                    vx = vx + x
                    vy = vy + y
                    local vast = VisualAsteroid()
                        :setPosition(vx, vy)
                        :setSize(random(10, tether))
                    tether = random(asteroid_size + 10, asteroid_size + 800)
                    v_angle = (v_angle + random(120, 240)) % 360
                    local vx, vy = vectorFromAngle(v_angle, tether, true)
                    vx = vx + x
                    vy = vy + y
                    vast = VisualAsteroid()
                        :setPosition(vx, vy)
                        :setSize(random(10, tether))
                else
                    break
                end
            end
            return true
        elseif terrain.desc == "Transport" then
            local ship, ship_size = randomTransportType()
            if
                transport_faction_list == nil
                or #transport_faction_list == 0
            then
                transport_faction_list = {}
                for i, faction in pairs(transport_factions) do
                    table.insert(transport_faction_list, faction)
                end
            end
            ship:setPosition(eo_x, eo_y)
                :setFaction(tableRemoveRandom(transport_faction_list))
            ship:setCallSign(generateCallSign(nil, ship:getFaction()))
            table.insert(
                area.space,
                { obj = ship, dist = 600, shape = "circle" }
            )
            table.insert(transport_list, ship)
            return true
        else
            local object = terrain.obj():setPosition(eo_x, eo_y)
            local dist = radius
            if terrain.desc == "Blob" or terrain.desc == "Rectangle" then
                local objects = {}
                table.insert(objects, object)
                local reached_the_edge = false
                local object_space = 1400
                if terrain.desc == "Blob" then
                    local asteroid_size = 0
                    if terrain.obj == Asteroid then
                        asteroid_size = random(2, 180)
                            + random(2, 180)
                            + random(2, 180)
                            + random(2, 180)
                        object:setSize(asteroid_size)
                    end
                    repeat
                        local overlay = false
                        local new_obj_x, new_obj_y = nil
                        repeat
                            overlay = false
                            local base_obj_index = math.random(1, #objects)
                            local base_object = objects[base_obj_index]
                            local base_obj_x, base_obj_y =
                                base_object:getPosition()
                            local angle = random(0, 360)
                            if terrain.obj == Asteroid then
                                asteroid_size = random(2, 180)
                                    + random(2, 180)
                                    + random(2, 180)
                                    + random(2, 180)
                                object_space = (
                                    base_object:getSize() + asteroid_size
                                )
                                    * random(1.05, 1.25)
                            end
                            new_obj_x, new_obj_y =
                                vectorFromAngle(angle, object_space, true)
                            new_obj_x = new_obj_x + base_obj_x
                            new_obj_y = new_obj_y + base_obj_y
                            for i, obj in ipairs(objects) do
                                if i ~= base_obj_index then
                                    local compare_obj_x, compare_obj_y =
                                        obj:getPosition()
                                    if distance_diagnostic then
                                        print(
                                            "distance_diagnostic 7: compare_obj_x, compare_obj_y, new_obj_x, new_obj_y: place terrain, blob:",
                                            compare_obj_x,
                                            compare_obj_y,
                                            new_obj_x,
                                            new_obj_y
                                        )
                                    end
                                    local obj_dist = distance(
                                        compare_obj_x,
                                        compare_obj_y,
                                        new_obj_x,
                                        new_obj_y
                                    )
                                    if obj_dist < object_space then
                                        overlay = true
                                        break
                                    end
                                end
                            end
                        until not overlay
                        object = terrain.obj():setPosition(new_obj_x, new_obj_y)
                        if terrain.obj == Asteroid then
                            object:setSize(asteroid_size)
                        end
                        table.insert(objects, object)
                        if distance_diagnostic then
                            print(
                                "distance_diagnostic 8: eo_x, eo_y, new_obj_x, new_obj_y: place terrain, blob:",
                                eo_x,
                                eo_y,
                                new_obj_x,
                                new_obj_y
                            )
                        end
                        if
                            distance(eo_x, eo_y, new_obj_x, new_obj_y) > radius
                        then
                            reached_the_edge = true
                        end
                    until reached_the_edge
                elseif terrain.desc == "Rectangle" then
                    local long_axis = random(0, 360)
                    local reach_index = 0
                    local new_mine_x, new_mine_y = 0
                    repeat
                        reach_index = reach_index + 1
                        new_obj_x, new_obj_y = vectorFromAngle(
                            long_axis,
                            object_space * reach_index,
                            true
                        )
                        new_obj_x = new_obj_x + eo_x
                        new_obj_y = new_obj_y + eo_y
                        if distance_diagnostic then
                            print(
                                "distance_diagnostic 9: new_obj_x,new_obj_y,eo_x,eo_y: place terrain, rectangle:",
                                new_obj_x,
                                new_obj_y,
                                eo_x,
                                eo_y
                            )
                        end
                        if
                            distance(new_obj_x, new_obj_y, eo_x, eo_y) > radius
                        then
                            reached_the_edge = true
                        else
                            if random(1, 100) < 77 then
                                table.insert(
                                    objects,
                                    Mine():setPosition(new_obj_x, new_obj_y)
                                )
                            end
                            new_obj_x, new_obj_y = vectorFromAngle(
                                (long_axis + 180) % 360,
                                object_space * reach_index,
                                true
                            )
                            new_obj_x = new_obj_x + eo_x
                            new_obj_y = new_obj_y + eo_y
                            if random(1, 100) < 77 then
                                table.insert(
                                    objects,
                                    Mine():setPosition(new_obj_x, new_obj_y)
                                )
                            end
                        end
                    until reached_the_edge
                    if random(1, 100) < 69 then
                        reach_index = 0
                        reached_the_edge = false
                        local new_line_x, new_line_y = vectorFromAngle(
                            (long_axis + 90) % 360,
                            object_space,
                            true
                        )
                        new_line_x = new_line_x + eo_x
                        new_line_y = new_line_y + eo_y
                        table.insert(
                            objects,
                            Mine():setPosition(new_line_x, new_line_y)
                        )
                        repeat
                            reach_index = reach_index + 1
                            new_obj_x, new_obj_y = vectorFromAngle(
                                long_axis,
                                object_space * reach_index,
                                true
                            )
                            new_obj_x = new_obj_x + new_line_x
                            new_obj_y = new_obj_y + new_line_y
                            if distance_diagnostic then
                                print(
                                    "distance_diagnostic 10: new_obj_x,new_obj_y,eo_x,eo_y: place terrain, rectangle:",
                                    new_obj_x,
                                    new_obj_y,
                                    eo_x,
                                    eo_y
                                )
                            end
                            if
                                distance(new_obj_x, new_obj_y, eo_x, eo_y)
                                > radius
                            then
                                reached_the_edge = true
                            else
                                if random(1, 100) < 77 then
                                    table.insert(
                                        objects,
                                        Mine():setPosition(new_obj_x, new_obj_y)
                                    )
                                end
                                new_obj_x, new_obj_y = vectorFromAngle(
                                    (long_axis + 180) % 360,
                                    object_space * reach_index,
                                    true
                                )
                                new_obj_x = new_obj_x + new_line_x
                                new_obj_y = new_obj_y + new_line_y
                                if random(1, 100) < 77 then
                                    table.insert(
                                        objects,
                                        Mine():setPosition(new_obj_x, new_obj_y)
                                    )
                                end
                            end
                        until reached_the_edge
                        if random(1, 100) < 28 then
                            reach_index = 0
                            reached_the_edge = false
                            new_line_x, new_line_y = vectorFromAngle(
                                (long_axis + 270) % 360,
                                object_space,
                                true
                            )
                            new_line_x = new_line_x + eo_x
                            new_line_y = new_line_y + eo_y
                            table.insert(
                                objects,
                                Mine():setPosition(new_line_x, new_line_y)
                            )
                            repeat
                                reach_index = reach_index + 1
                                new_obj_x, new_obj_y = vectorFromAngle(
                                    long_axis,
                                    object_space * reach_index,
                                    true
                                )
                                new_obj_x = new_obj_x + new_line_x
                                new_obj_y = new_obj_y + new_line_y
                                if distance_diagnostic then
                                    print(
                                        "distance_diagnostic 11: new_obj_x,new_obj_y,eo_x,eo_y: place terrain, rectangle:",
                                        new_obj_x,
                                        new_obj_y,
                                        eo_x,
                                        eo_y
                                    )
                                end
                                if
                                    distance(new_obj_x, new_obj_y, eo_x, eo_y)
                                    > radius
                                then
                                    reached_the_edge = true
                                else
                                    if random(1, 100) < 77 then
                                        table.insert(
                                            objects,
                                            Mine():setPosition(
                                                new_obj_x,
                                                new_obj_y
                                            )
                                        )
                                    end
                                    new_obj_x, new_obj_y = vectorFromAngle(
                                        (long_axis + 180) % 360,
                                        object_space * reach_index,
                                        true
                                    )
                                    new_obj_x = new_obj_x + new_line_x
                                    new_obj_y = new_obj_y + new_line_y
                                    if random(1, 100) < 77 then
                                        table.insert(
                                            objects,
                                            Mine():setPosition(
                                                new_obj_x,
                                                new_obj_y
                                            )
                                        )
                                    end
                                end
                            until reached_the_edge
                        end
                    end
                end
                for i, object in ipairs(objects) do
                    dist = object_space
                    if isObjectType(object, "Asteroid") then
                        dist = object:getSize()
                        local tether_x, tether_y = object:getPosition()
                        local tether_length = random(dist + 10, 800)
                        local vis_ast_angle = random(0, 360)
                        local vx, vy =
                            vectorFromAngle(vis_ast_angle, tether_length, true)
                        vx = vx + tether_x
                        vy = vy + tether_y
                        VisualAsteroid()
                            :setPosition(vx, vy)
                            :setSize(random(10, tether_length))
                        tether_length = random(dist + 10, dist + 800)
                        vis_ast_angle = (vis_ast_angle + random(120, 240)) % 360
                        vx, vy =
                            vectorFromAngle(vis_ast_angle, tether_length, true)
                        vx = vx + tether_x
                        vy = vy + tether_y
                        VisualAsteroid()
                            :setPosition(vx, vy)
                            :setSize(random(10, tether_length))
                    end
                    table.insert(
                        area.space,
                        { obj = object, dist = dist, shape = "circle" }
                    )
                end
                return true
            else --not blob or rectangle
                if terrain.desc == "Star" then
                    object
                        :setPlanetRadius(radius)
                        :setDistanceFromMovementPlane(-radius * 0.5)
                    if random(1, 100) < 43 then
                        object:setDistanceFromMovementPlane(radius * 0.5)
                    end
                    local star_item = tableRemoveRandom(star_list[1].info)
                    object:setCallSign(star_item.name)
                    if star_item.unscanned ~= nil then
                        object:setDescriptions(
                            star_item.unscanned,
                            star_item.scanned
                        )
                        object:setScanningParameters(1, 2)
                    end
                    object
                        :setPlanetAtmosphereTexture(
                            star_list[1].texture.atmosphere
                        )
                        :setPlanetAtmosphereColor(
                            random(0.5, 1),
                            random(0.5, 1),
                            random(0.5, 1)
                        )
                    dist = radius + 1000
                elseif terrain.obj == SupplyDrop then
                    local supply_types = {
                        "energy",
                        "ordnance",
                        "coolant",
                        "repair crew",
                        "probes",
                        "hull",
                        "jump charge",
                    }
                    local supply_type = tableSelectRandom(supply_types)
                    object
                        :setScanningParameters(
                            math.random(1, 2),
                            math.random(1, 2)
                        )
                        :setFaction(player_faction)
                    if supply_type == "energy" then
                        local energy_boost = random(300, 800)
                        object:setEnergy(energy_boost)
                        object:setDescriptions(
                            _("scienceDescription-supplyDrop", "Supply Drop"),
                            string.format(
                                _(
                                    "scienceDescription-supplyDrop",
                                    "%i energy boost supply drop."
                                ),
                                math.floor(energy_boost)
                            )
                        )
                    elseif supply_type == "ordnance" then
                        local restock_ranges = {
                            ["Homing"] = { lo = 4, hi = 12 },
                            ["Nuke"] = { lo = 1, hi = 5 },
                            ["Mine"] = { lo = 3, hi = 8 },
                            ["EMP"] = { lo = 2, hi = 8 },
                            ["HVLI"] = { lo = 8, hi = 20 },
                        }
                        local ordnance_type = tableSelectRandom(ordnance_types)
                        local restock_amount = math.random(
                            restock_ranges[ordnance_type].lo,
                            restock_ranges[ordnance_type].hi
                        )
                        object:setWeaponStorage(ordnance_type, restock_amount)
                        object:setDescriptions(
                            _("scienceDescription-supplyDrop", "Supply Drop"),
                            string.format(
                                _(
                                    "scienceDescription-supplyDrop",
                                    "%i %s supply drop."
                                ),
                                restock_amount,
                                ordnance_type
                            )
                        )
                    else
                        object:onPickUp(supplyPickupProcess)
                        if supply_type == "coolant" then
                            object.coolant = random(1, 5)
                            object:setDescriptions(
                                _(
                                    "scienceDescription-supplyDrop",
                                    "Supply Drop"
                                ),
                                string.format(
                                    _(
                                        "scienceDescription-supplyDrop",
                                        "%.1f%% coolant supply drop."
                                    ),
                                    object.coolant * 10
                                )
                            )
                        elseif supply_type == "repair crew" then
                            object.repairCrew = 1
                            object:setDescriptions(
                                _(
                                    "scienceDescription-supplyDrop",
                                    "Supply Drop"
                                ),
                                _(
                                    "scienceDescription-supplyDrop",
                                    "Robotic repair crew supply drop."
                                )
                            )
                        elseif supply_type == "probes" then
                            object.probes = math.random(4, 12)
                            object:setDescriptions(
                                _(
                                    "scienceDescription-supplyDrop",
                                    "Supply Drop"
                                ),
                                string.format(
                                    _(
                                        "scienceDescription-supplyDrop",
                                        "%i probes supply drop."
                                    ),
                                    object.probes
                                )
                            )
                        elseif supply_type == "hull" then
                            object.armor = random(20, 80)
                            object:setDescriptions(
                                _(
                                    "scienceDescription-supplyDrop",
                                    "Supply Drop"
                                ),
                                string.format(
                                    _(
                                        "scienceDescription-supplyDrop",
                                        "%.1f hull repair points supply drop."
                                    ),
                                    object.armor
                                )
                            )
                        elseif supply_type == "jump charge" then
                            object.jump_charge = random(20000, 40000)
                            object:setDescriptions(
                                _(
                                    "scienceDescription-supplyDrop",
                                    "Supply Drop"
                                ),
                                string.format(
                                    _(
                                        "scienceDescription-supplyDrop",
                                        "%.1fK jump drive charge supply drop."
                                    ),
                                    object.jump_charge / 1000
                                )
                            )
                        end
                    end
                elseif terrain.obj == ScanProbe then
                    local station_pool = getStationPool(placement_area)
                    local owner = tableSelectRandom(station_pool)
                    local s_x, s_y = owner:getPosition()
                    object
                        :setLifetime(20 * 60)
                        :setOwner(owner)
                        :setTarget(eo_x, eo_y)
                        :setPosition(s_x, s_y)
                    object:onExpiration(probeExpired)
                    object:onDestruction(probeDestroyed)
                    object = VisualAsteroid():setPosition(eo_x, eo_y)
                elseif terrain.obj == WarpJammer then
                    local closest_station_distance = 999999
                    local closest_station = nil
                    local station_pool = getStationPool(placement_area)
                    for i, station in ipairs(station_pool) do
                        if distance_diagnostic then
                            print(
                                "distance_diagnostic 12: station, eo_x, eo_y, place terrain, warp jammer:",
                                station:getCallSign(),
                                eo_x,
                                eo_y
                            )
                        end
                        local current_distance = distance(station, eo_x, eo_y)
                        if current_distance < closest_station_distance then
                            closest_station_distance = current_distance
                            closest_station = station
                        end
                    end
                    local selected_faction = closest_station:getFaction()
                    local warp_jammer_range = 0
                    for i = 1, 5 do
                        warp_jammer_range = warp_jammer_range
                            + random(1000, 4000)
                    end
                    object
                        :setRange(warp_jammer_range)
                        :setFaction(selected_faction)
                    warp_jammer_info[selected_faction].count = warp_jammer_info[selected_faction].count
                        + 1
                    local wj_id = string.format(
                        "%sWJ%i",
                        warp_jammer_info[selected_faction].id,
                        warp_jammer_info[selected_faction].count
                    )
                    object.identifier = wj_id
                    object.range = warp_jammer_range
                    object:setDescriptions(
                        _("scienceDescription-warpJammer", "Warp jammer"),
                        string.format(
                            _(
                                "scienceDescription-warpJammer",
                                "Warp jammer. Operated by %s. Placed by station %s. Identifier: %s"
                            ),
                            selected_faction,
                            closest_station:getCallSign(),
                            wj_id
                        )
                    )
                    object:setScanningParameters(1, 1)
                    table.insert(warp_jammer_list, object)
                elseif terrain.desc == "Sensor" then
                    object
                        :setScanningParameters(
                            math.random(1, 2),
                            math.random(1, 2)
                        )
                        :setRadarSignatureInfo(
                            random(0, 1),
                            random(0, 1),
                            random(0, 1)
                        )
                        :setModel("SensorBuoyMKIII")
                    local buoy_type_list = {}
                    local buoy_type = ""
                    local station_pool = getStationPool(placement_area)
                    local out = ""
                    if #station_pool > 0 then
                        table.insert(buoy_type_list, "station")
                    end
                    if transport_list ~= nil and #transport_list > 0 then
                        table.insert(buoy_type_list, "transport")
                    end
                    if #buoy_type_list > 0 then
                        buoy_type = tableSelectRandom(buoy_type_list)
                        if buoy_type == "station" then
                            local selected_stations = {}
                            for i, station in ipairs(station_pool) do
                                table.insert(selected_stations, station)
                            end
                            for i = 1, 3 do
                                if #selected_stations > 0 then
                                    local station =
                                        tableRemoveRandom(selected_stations)
                                    if out == "" then
                                        out = string.format(
                                            _(
                                                "scienceDescription-buoy",
                                                "Sensor Record: %s station %s in %s"
                                            ),
                                            station:getFaction(),
                                            station:getCallSign(),
                                            station:getSectorName()
                                        )
                                    else
                                        out = string.format(
                                            _(
                                                "scienceDescription-buoy",
                                                "%s, %s station %s in %s"
                                            ),
                                            out,
                                            station:getFaction(),
                                            station:getCallSign(),
                                            station:getSectorName()
                                        )
                                    end
                                else
                                    break
                                end
                            end
                        end
                        if buoy_type == "transport" then
                            local selected_transports = {}
                            for i, transport in ipairs(transport_list) do
                                table.insert(selected_transports, transport)
                            end
                            for i = 1, 3 do
                                if #selected_transports > 0 then
                                    local transport =
                                        tableRemoveRandom(selected_transports)
                                    if transport.comms_data == nil then
                                        transport.comms_data = {
                                            friendlyness = random(0.0, 100.0),
                                        }
                                    end
                                    if transport.comms_data.goods == nil then
                                        goodsOnShip(
                                            transport,
                                            transport.comms_data
                                        )
                                    end
                                    local goods_carrying = ""
                                    for good, goodData in
                                        pairs(transport.comms_data.goods)
                                    do
                                        if goods_carrying == "" then
                                            goods_carrying = good
                                        else
                                            goods_carrying = string.format(
                                                "%s, %s",
                                                goods_carrying,
                                                good
                                            )
                                        end
                                    end
                                    if out == "" then
                                        out = string.format(
                                            _(
                                                "scienceDescription-buoy",
                                                "Sensor Record: %s %s %s in %s carrying %s"
                                            ),
                                            transport:getFaction(),
                                            transport:getTypeName(),
                                            transport:getCallSign(),
                                            transport:getSectorName(),
                                            goods_carrying
                                        )
                                    else
                                        out = string.format(
                                            _(
                                                "scienceDescription-buoy",
                                                "%s; %s %s %s in %s carrying %s"
                                            ),
                                            out,
                                            transport:getFaction(),
                                            transport:getTypeName(),
                                            transport:getCallSign(),
                                            transport:getSectorName(),
                                            goods_carrying
                                        )
                                    end
                                else
                                    break
                                end
                            end
                        end
                    else
                        out = _("scienceDescription-buoy", "No data recorded")
                    end
                    object:setDescriptions(
                        _(
                            "scienceDescription-buoy",
                            "Automated data gathering device"
                        ),
                        out
                    )
                elseif terrain.desc == "Ad" then
                    object
                        :setScanningParameters(2, 1)
                        :setRadarSignatureInfo(
                            random(0, 1),
                            random(0, 1),
                            random(0, 1)
                        )
                        :setModel("SensorBuoyMKIII")
                    if billboards == nil then
                        billboards = {}
                    end
                    if #billboards < 1 then
                        for i, ad in ipairs(advertising_billboards) do
                            table.insert(billboards, ad)
                        end
                    end
                    object:setDescriptions(
                        _(
                            "scienceDescription-buoy",
                            "Automated data gathering device"
                        ),
                        tableRemoveRandom(billboards)
                    )
                elseif terrain.obj == Nebula then
                    dist = 1500
                    if random(1, 100) < 77 then
                        local n_angle = random(0, 360)
                        local n_x, n_y =
                            vectorFromAngle(n_angle, random(5000, 10000))
                        local neb = Nebula():setPosition(eo_x + n_x, eo_y + n_y)
                        neb:setDescriptions(
                            _("scienceDescription-nebula", "Nebula"),
                            _("scienceDescription-nebula", "Nebula")
                        )
                        neb:setScanningParameters(2, 1)
                        if random(1, 100) < 37 then
                            local n2_angle = (n_angle + random(120, 240)) % 360
                            n_x, n_y =
                                vectorFromAngle(n2_angle, random(5000, 10000))
                            eo_x = eo_x + n_x
                            eo_y = eo_y + n_y
                            neb = Nebula():setPosition(eo_x, eo_y)
                            neb:setDescriptions(
                                _("scienceDescription-nebula", "Nebula"),
                                _("scienceDescription-nebula", "Nebula")
                            )
                            neb:setScanningParameters(2, 1)
                            if random(1, 100) < 22 then
                                local n3_angle = (n2_angle + random(120, 240))
                                    % 360
                                n_x, n_y = vectorFromAngle(
                                    n3_angle,
                                    random(5000, 10000)
                                )
                                neb =
                                    Nebula():setPosition(eo_x + n_x, eo_y + n_y)
                                neb:setDescriptions(
                                    _("scienceDescription-nebula", "Nebula"),
                                    _("scienceDescription-nebula", "Nebula")
                                )
                                neb:setScanningParameters(2, 1)
                            end
                        end
                    end
                elseif terrain.obj == BlackHole or terrain.obj == Mine then
                    --black hole, mine; no more action needed
                else --default to asteroid
                    placeAsteroid(placement_area)
                    return false
                end
                table.insert(
                    area.space,
                    { obj = object, dist = dist, shape = "circle" }
                )
                return true
            end
        end
    else
        placeAsteroid(placement_area)
        return false
    end
end
--	Dynamic terrain probe functions
--	Sensor jammer functions
--	Communication functions
function getCurrentOrders()
    local current_orders_prompts = {
        _("orders-comms", "Current orders?"),
        _("orders-comms", "What are my current orders?"),
        string.format(
            _("orders-comms", "Current orders for %s?"),
            comms_source:getCallSign()
        ),
        _("orders-comms", "Remind me of our current orders, please"),
    }
    addCommsReply(tableRemoveRandom(current_orders_prompts), function()
        setOptionalOrders()
        ordMsg = primary_orders .. "\n" .. optional_orders
        setCommsMessage(ordMsg)
        if comms_source.met_pirate == nil then
            if comms_source:getDockedWith() == comms_target then
                addCommsReply(_("orders-comms", "Visit lounge"), function()
                    setCommsMessage(
                        _(
                            "orders-comms",
                            "When you enter the lounge, you see a guy sitting at the bar with an eye patch, a peg leg, a cutlass at his belt, a three-cornered hat and a green bird on his shoulder."
                        )
                    )
                    addCommsReply(
                        _(
                            "orders-comms",
                            "Ask about the eye patch, hat, peg leg and bird"
                        ),
                        function()
                            setCommsMessage(
                                string.format(
                                    _(
                                        "pirate-comms",
                                        "Why, I'm a pirate, matey! Marcus the pirate! Actually, I'm just playing the part of a pirate in the live production of 'Caribbean Pirates' here on %s. I'm on a ten-minute rehearsal break. This stuff I'm wearing is my costume. The peg leg is a hologram and the bird is a robot. I think the bird has better lines than I do.\n\nIf you want to talk to real modern pirates, that couple over there at that table are the real deal. They recently retired from a successful career as pirates, or so I hear. This will probably be the only time you can talk to them."
                                    ),
                                    comms_target:getCallSign()
                                )
                            )
                            comms_source.met_pirate = "met"
                            addCommsReply(
                                _("pirate-comms", "Talk to pirate couple"),
                                function()
                                    setCommsMessage(
                                        _(
                                            "pirate-comms",
                                            "Hi there, take a seat with us. Marcus signaled us that you've got some kind of interest in pirates. Is that right?"
                                        )
                                    )
                                    addCommsReply(
                                        _(
                                            "pirate-comms",
                                            "Yes, I want to know about pirates"
                                        ),
                                        function()
                                            setCommsMessage(
                                                _(
                                                    "pirate-comms",
                                                    "Well, we can tell you about it. Not that we would ever engage in such practices ourselves."
                                                )
                                            )
                                            addCommsReply(
                                                _(
                                                    "pirate-comms",
                                                    "Of course. How would one get loot from another ship?"
                                                ),
                                                function()
                                                    setCommsMessage(
                                                        _(
                                                            "pirate-comms",
                                                            "Loot?! We'd prefer to call that excess cargo. [they laugh at their own joke]\n\nSeveral things have to come together in order to relieve them of their excess cargo."
                                                        )
                                                    )
                                                    addCommsReply(
                                                        _(
                                                            "pirate-comms",
                                                            "What things have to come together?"
                                                        ),
                                                        function()
                                                            setCommsMessage(
                                                                _(
                                                                    "pirate-comms",
                                                                    "Things your ship has to do and things that have to happen on the ship you're liberating excess cargo from. Your ship has to be within 3 units of the other ship, it has to be at a complete stop, it has to have the shields down, it has to have room in the cargo bay, and it has to have at least 50 units of energy per cargo item to operate the transporters that grab the cargo."
                                                                )
                                                            )
                                                            addCommsReply(
                                                                _(
                                                                    "pirate-comms",
                                                                    "What about the other ship?"
                                                                ),
                                                                function()
                                                                    setCommsMessage(
                                                                        _(
                                                                            "pirate-comms",
                                                                            "Assuming you haven't destroyed it (a common mistake with inexperienced pirates), the other ship has to be completely immobile and their shields have to be down. It also helps if they actually have excess cargo to liberate."
                                                                        )
                                                                    )
                                                                    addCommsReply(
                                                                        _(
                                                                            "pirate-comms",
                                                                            "How do we know if they have any cargo?"
                                                                        ),
                                                                        function()
                                                                            setCommsMessage(
                                                                                _(
                                                                                    "pirate-comms",
                                                                                    "Sometimes you can just ask them. Otherwise you can double scan them. You should see the cargo manifest in the ship description. You may have to click the tactical widget or the systems widget on the science console to see the description."
                                                                                )
                                                                            )
                                                                            addCommsReply(
                                                                                _(
                                                                                    "pirate-comms",
                                                                                    "How do we get them to stop?"
                                                                                ),
                                                                                function()
                                                                                    setCommsMessage(
                                                                                        _(
                                                                                            "pirate-comms",
                                                                                            "Your weapons officer can focus beams on their impulse engines. Once they're in the negatives for their impulse engines, they won't be able to move. If you've double scanned them, your science officer can check the status of their impulse engines by clicking the tactical or description widget and selecting systems.\n\nNow, some freighters have jump drives. You may need to disable those, too. If you don't have beams, you have to use your missiles very carefully to keep from destroying them altogether. You can't get cargo once they're destroyed."
                                                                                        )
                                                                                    )
                                                                                    addCommsReply(
                                                                                        _(
                                                                                            "pirate-comms",
                                                                                            "How do we get their shields down?"
                                                                                        ),
                                                                                        function()
                                                                                            setCommsMessage(
                                                                                                _(
                                                                                                    "pirate-comms",
                                                                                                    "First, shoot them down, then target the applicable shield generator to keep them down."
                                                                                                )
                                                                                            )
                                                                                            addCommsReply(
                                                                                                _(
                                                                                                    "pirate-comms",
                                                                                                    "Is that it?"
                                                                                                ),
                                                                                                function()
                                                                                                    setCommsMessage(
                                                                                                        string.format(
                                                                                                            _(
                                                                                                                "pirate-comms",
                                                                                                                "Once you meet all those requirements, your Relay or Operations officer should see buttons to get cargo from the ship.\n\nOnce you go down this path, there's no going back. If you stick to liberating cargo from enemies of the %s, you'll only be called Licensed Privateers. Loot neutrals or friendlies and you'll be labeled Pirates."
                                                                                                            ),
                                                                                                            player_faction
                                                                                                        )
                                                                                                    )
                                                                                                    addCommsReply(
                                                                                                        _(
                                                                                                            "pirate-comms",
                                                                                                            "What do we do with the excess cargo?"
                                                                                                        ),
                                                                                                        function()
                                                                                                            setCommsMessage(
                                                                                                                _(
                                                                                                                    "pirate-comms",
                                                                                                                    "Sell it to stations that want to buy it. In fact, you should identify what stations want what goods before you start liberating excess cargo from innocent freighters."
                                                                                                                )
                                                                                                            )
                                                                                                            addCommsReply(
                                                                                                                _(
                                                                                                                    "pirate-comms",
                                                                                                                    "How do we find out what stations want goods?"
                                                                                                                ),
                                                                                                                function()
                                                                                                                    setCommsMessage(
                                                                                                                        _(
                                                                                                                            "pirate-comms",
                                                                                                                            "Talk to them. Near the end of their status report, they'll say what goods they sell and what goods they'll buy."
                                                                                                                        )
                                                                                                                    )
                                                                                                                    addCommsReply(
                                                                                                                        _(
                                                                                                                            "pirate-comms",
                                                                                                                            "Thanks for your help"
                                                                                                                        ),
                                                                                                                        function()
                                                                                                                            setCommsMessage(
                                                                                                                                _(
                                                                                                                                    "pirate-comms",
                                                                                                                                    "Don't mention it\n\n...to anyone...\n\n\n   ---EVER---"
                                                                                                                                )
                                                                                                                            )
                                                                                                                        end
                                                                                                                    )
                                                                                                                end
                                                                                                            )
                                                                                                        end
                                                                                                    )
                                                                                                end
                                                                                            )
                                                                                        end
                                                                                    )
                                                                                end
                                                                            )
                                                                        end
                                                                    )
                                                                end
                                                            )
                                                        end
                                                    )
                                                end
                                            )
                                        end
                                    )
                                    addCommsReply(
                                        _(
                                            "pirate-comms",
                                            "No, I'm not interested in pirates"
                                        ),
                                        function()
                                            setCommsMessage(
                                                _(
                                                    "pirate-comms",
                                                    "Suit yourself. Good luck."
                                                )
                                            )
                                        end
                                    )
                                end
                            )
                        end
                    )
                end)
            end
        end
        addCommsReply(_("Back"), commsStation)
    end)
end
function scenarioShipEnhancements()
    if comms_target.improve_long_range_sensors == nil then
        if random(1, 100) < 43 then
            comms_target.improve_long_range_sensors = {
                [comms_source] = false,
            }
        else
            comms_target.improve_long_range_sensors = "unavailable"
        end
    end
    if comms_target.improve_long_range_sensors ~= "unavailable" then
        if comms_target.improve_long_range_sensors[comms_source] == nil then
            comms_target.improve_long_range_sensors[comms_source] = false
        end
        if not comms_target.improve_long_range_sensors[comms_source] then
            if comms_source.improve_long_range_sensors_count == nil then
                comms_source.improve_long_range_sensors_count = 0
            end
            addCommsReply(
                string.format(
                    _(
                        "upgrade-comms",
                        "Increase long range sensors by 5 units (%i rep)"
                    ),
                    comms_source.improve_long_range_sensors_count * 10 + 10
                ),
                function()
                    if
                        comms_source:takeReputationPoints(
                            comms_source.improve_long_range_sensors_count * 10
                                + 10
                        )
                    then
                        comms_source.improve_long_range_sensors_count = comms_source.improve_long_range_sensors_count
                            + 1
                        comms_source.normal_long_range_radar = comms_source.normal_long_range_radar
                            + 5000
                        comms_target.improve_long_range_sensors[comms_source] =
                            true
                        setCommsMessage(
                            _(
                                "upgrade-comms",
                                "Sensor range improved by five units"
                            )
                        )
                    else
                        setCommsMessage(
                            _("needRep-comms", "Insufficient reputation")
                        )
                    end
                    addCommsReply(_("Back"), commsStation)
                end
            )
        end
    end
    if comms_target.smee_upgrade == nil then
        if random(1, 100) < 78 then
            comms_target.smee_upgrade = true
            comms_target.smee_cost = math.random(5, 15)
        else
            comms_target.smee_upgrade = false
        end
    end
    if comms_target.smee_upgrade and comms_source.smee_upgrade == nil then
        addCommsReply(
            _("upgrade-comms", "Investigate pirate assistant AI"),
            function()
                setCommsMessage(
                    _(
                        "upgrade-comms",
                        "There's an AI assistant available called Mr. Smee that is supposed to advise a ship's communication officer about the basic requirements of pirating things from other ships. It looks a bit shady. It probably won't be offered for long. Is this something you are interested in?"
                    )
                )
                addCommsReply(
                    string.format(
                        _(
                            "upgrade-comms",
                            "Yes, I'd like Mr. Smee (%i reputation)"
                        ),
                        comms_target.smee_cost
                    ),
                    function()
                        if
                            comms_source:takeReputationPoints(
                                comms_target.smee_cost
                            )
                        then
                            setCommsMessage("Mr. Smee is now available")
                            comms_source.smee_upgrade = true
                            comms_source.smee_button_rel = "smee_button_rel"
                            comms_source:addCustomButton(
                                "Relay",
                                comms_source.smee_button_rel,
                                "Mr. Smee",
                                function()
                                    string.format("")
                                    smeeMessage("Relay", comms_source)
                                end
                            )
                            comms_source.smee_upgrade = true
                            comms_source.smee_button_ops = "smee_button_ops"
                            comms_source:addCustomButton(
                                "Operations",
                                comms_source.smee_button_ops,
                                "Mr. Smee",
                                function()
                                    string.format("")
                                    smeeMessage("Operations", comms_source)
                                end
                            )
                            addCommsReply(_("Back"), commsStation)
                        else
                            setCommsMessage(
                                _("needRep-comms", "Insufficient reputation")
                            )
                            comms_target.smee_upgrade = false
                            addCommsReply(_("Back"), commsStation)
                        end
                    end
                )
                addCommsReply(
                    _(
                        "upgrade-comms",
                        "No. I've heard bad things about Mr. Smee"
                    ),
                    function()
                        comms_target.smee_upgrade = false
                        setCommsMessage("Ok, your loss.")
                        addCommsReply(_("Back"), commsStation)
                    end
                )
            end
        )
    end
    if comms_target.jump_upgrade_station == nil then
        if random(1, 100) < 27 then
            comms_target.jump_upgrade_station = true
        else
            comms_target.jump_upgrade_station = false
        end
    end
    if
        comms_target.jump_upgrade_station
        and comms_source.jump_upgrade == nil
        and not comms_source:hasJumpDrive()
    then
        addCommsReply(
            _("upgrade-comms", "Check on jump drive availability"),
            function()
                setCommsMessage(
                    _(
                        "upgrade-comms",
                        "Jonathan Rogers, our resident engine systems specialist, has three jump drives not being used. He could install one of them on your ship. One is a Repulse Rabbit XR5, one is a Vesta UK41, and the third is a Ketrik Presence D8."
                    )
                )
                if comms_target.jump_upgrades == nil then
                    comms_target.jump_upgrades = {
                        {
                            long = 50000,
                            short = 5000,
                            adjacent = true,
                            charged = true,
                        },
                        {
                            long = 100000,
                            short = 5000,
                            adjacent = false,
                            charged = true,
                        },
                        {
                            long = 150000,
                            short = 10000,
                            adjacent = false,
                            charged = false,
                        },
                    }
                end
                addCommsReply(
                    _("upgrade-comms", "Tell me about the Repulse Rabbit XR5"),
                    function()
                        if comms_target.repulse == nil then
                            comms_target.repulse =
                                tableRemoveRandom(comms_target.jump_upgrades)
                        end
                        local charge = _("upgrade-comms", "comes fully")
                        if not comms_target.repulse.charged then
                            charge = _("upgrade-comms", "is not")
                        end
                        local adjacent = _("upgrade-comms", "but cannot be")
                        if comms_target.repulse.adjacent then
                            adjacent = _("upgrade-comms", "and can be")
                        end
                        setCommsMessage(
                            string.format(
                                _(
                                    "upgrade-comms",
                                    "The Repulse Rabbit XR5 has a long jump range of up to %i units, minimum jump range of %i units, %s charged, %s installed alongside your warp drive."
                                ),
                                comms_target.repulse.long / 1000,
                                comms_target.repulse.short / 1000,
                                charge,
                                adjacent
                            )
                        )
                        addCommsReply(
                            _(
                                "upgrade-comms",
                                "Install the Repulse Rabbit XR5 jump drive"
                            ),
                            function()
                                comms_source.jump_upgrade = true
                                comms_source
                                    :setJumpDrive(true)
                                    :setJumpDriveRange(
                                        comms_target.repulse.short,
                                        comms_target.repulse.long
                                    )
                                if comms_target.repulse.charged then
                                    comms_source:setJumpDriveCharge(
                                        comms_target.repulse.long
                                    )
                                else
                                    comms_source:setJumpDriveCharge(0)
                                end
                                if not comms_target.repulse.adjacent then
                                    comms_source:setWarpDrive(false)
                                end
                                setCommsMessage(
                                    _(
                                        "upgrade-comms",
                                        "Jonathan Rogers has installed a Repulse Rabbit XR5 jump drive"
                                    )
                                )
                                addCommsReply(_("Back"), commsStation)
                            end
                        )
                        addCommsReply(_("Back"), commsStation)
                    end
                )
                addCommsReply(
                    _("upgrade-comms", "The Vesta UK41 sounds interesting"),
                    function()
                        if comms_target.vesta == nil then
                            comms_target.vesta =
                                tableRemoveRandom(comms_target.jump_upgrades)
                        end
                        local charge = _("upgrade-comms", "comes fully")
                        if not comms_target.vesta.charged then
                            charge = _("upgrade-comms", "is not")
                        end
                        local adjacent = _("upgrade-comms", "but cannot be")
                        if comms_target.vesta.adjacent then
                            adjacent = _("upgrade-comms", "and can be")
                        end
                        setCommsMessage(
                            string.format(
                                _(
                                    "upgrade-comms",
                                    "The Vesta UK41 has a long jump range of up to %i units, minimum jump range of %i units, %s charged, %s installed alongside your warp drive."
                                ),
                                comms_target.vesta.long / 1000,
                                comms_target.vesta.short / 1000,
                                charge,
                                adjacent
                            )
                        )
                        addCommsReply(
                            _(
                                "upgrade-comms",
                                "Install the Vesta UK41 jump drive"
                            ),
                            function()
                                comms_source.jump_upgrade = true
                                comms_source
                                    :setJumpDrive(true)
                                    :setJumpDriveRange(
                                        comms_target.vesta.short,
                                        comms_target.vesta.long
                                    )
                                if comms_target.vesta.charged then
                                    comms_source:setJumpDriveCharge(
                                        comms_target.vesta.long
                                    )
                                else
                                    comms_source:setJumpDriveCharge(0)
                                end
                                if not comms_target.vesta.adjacent then
                                    comms_source:setWarpDrive(false)
                                end
                                setCommsMessage(
                                    _(
                                        "upgrade-comms",
                                        "Jonathan Rogers has installed a Vesta UK41 jump drive"
                                    )
                                )
                                addCommsReply(_("Back"), commsStation)
                            end
                        )
                        addCommsReply(_("Back"), commsStation)
                    end
                )
                addCommsReply(
                    _(
                        "upgrade-comms",
                        "What do you know of the Ketrik Presence D8?"
                    ),
                    function()
                        if comms_target.ketrik == nil then
                            comms_target.ketrik =
                                tableRemoveRandom(comms_target.jump_upgrades)
                        end
                        local charge = _("upgrade-comms", "comes fully")
                        if not comms_target.ketrik.charged then
                            charge = _("upgrade-comms", "is not")
                        end
                        local adjacent = _("upgrade-comms", "but cannot be")
                        if comms_target.ketrik.adjacent then
                            adjacent = _("upgrade-comms", "and can be")
                        end
                        setCommsMessage(
                            string.format(
                                _(
                                    "upgrade-comms",
                                    "The Ketrik Presence D8 has a long jump range of up to %i units, minimum jump range of %i units, %s charged, %s installed alongside your warp drive."
                                ),
                                comms_target.ketrik.long / 1000,
                                comms_target.ketrik.short / 1000,
                                charge,
                                adjacent
                            )
                        )
                        addCommsReply(
                            _(
                                "upgrade-comms",
                                "Install the Ketrik Presence D8 jump drive"
                            ),
                            function()
                                comms_source.jump_upgrade = true
                                comms_source
                                    :setJumpDrive(true)
                                    :setJumpDriveRange(
                                        comms_target.ketrik.short,
                                        comms_target.ketrik.long
                                    )
                                if comms_target.ketrik.charged then
                                    comms_source:setJumpDriveCharge(
                                        comms_target.ketrik.long
                                    )
                                else
                                    comms_source:setJumpDriveCharge(0)
                                end
                                if not comms_target.ketrik.adjacent then
                                    comms_source:setWarpDrive(false)
                                end
                                setCommsMessage(
                                    _(
                                        "upgrade-comms",
                                        "Jonathan Rogers has installed a Ketrik Presence D8 jump drive"
                                    )
                                )
                                addCommsReply(_("Back"), commsStation)
                            end
                        )
                        addCommsReply(_("Back"), commsStation)
                    end
                )
                addCommsReply(_("Back"), commsStation)
            end
        )
    end
end
--	Freighter or transport functions
function goodsOnShip(transport, comms_data)
    comms_data.goods = {}
    if #good_spread < 1 then
        for i, good in ipairs(commonGoods) do
            table.insert(good_spread, good)
        end
    end
    comms_data.goods[tableRemoveRandom(good_spread)] =
        { quantity = 1, cost = random(20, 80) }
    local shipType = transport:getTypeName()
    if shipType:find("Freighter") ~= nil then
        if
            shipType:find("Goods") ~= nil
            or shipType:find("Equipment") ~= nil
        then
            local count_repeat_loop = 0
            repeat
                if #good_spread < 1 then
                    for i, good in ipairs(commonGoods) do
                        table.insert(good_spread, good)
                    end
                end
                comms_data.goods[tableRemoveRandom(good_spread)] =
                    { quantity = 1, cost = random(20, 80) }
                local goodCount = 0
                for good, goodData in pairs(comms_data.goods) do
                    goodCount = goodCount + 1
                end
                count_repeat_loop = count_repeat_loop + 1
            until goodCount >= 3 or count_repeat_loop > max_repeat_loop
            if count_repeat_loop > max_repeat_loop then
                print(
                    "repeated too many times when setting up goods for freighter"
                )
            end
        end
    end
    updateShipManifest(transport)
end
--	Called from update functions
function lootButtons(p)
    local function showPlayerLootButtons(p) --diagnostic
        print(p:getCallSign(), "loot buttons: (del, ship, good, label, ord)")
        for i, loot_button in ipairs(p.loot_buttons) do
            print(
                loot_button.del,
                loot_button.ship:getCallSign(),
                loot_button.good,
                loot_button.label,
                loot_button.ord
            )
        end
    end
    if not p:getShieldsActive() and p.cargo > 0 then
        local pvx, pvy = p:getVelocity()
        if pvx == 0 and pvy == 0 then
            local objects_in_3u = p:getObjectsInRange(3000)
            local ships_in_3u = {}
            for i, obj in ipairs(objects_in_3u) do
                if p ~= obj then
                    local cvx, cvy = obj:getVelocity()
                    if cvx == 0 and cvy == 0 then
                        if isObjectType(obj, "CpuShip") then
                            local shield_up = true
                            for j = 1, obj:getShieldCount() do
                                local shield_level = obj:getShieldLevel(j - 1)
                                if obj:getShieldLevel(j - 1) <= 0 then
                                    shield_up = false
                                    break
                                end
                            end
                            if not shield_up then
                                table.insert(ships_in_3u, obj)
                            end
                        end
                    end
                end
            end
            local check_loot_buttons = {}
            for i, ship in ipairs(ships_in_3u) do
                if ship.comms_data ~= nil and ship.comms_data.goods ~= nil then
                    for good, details in pairs(ship.comms_data.goods) do
                        if details.quantity > 0 then
                            table.insert(
                                check_loot_buttons,
                                { ship = ship, good = good, ord = false }
                            )
                        end
                    end
                end
                for j, ordnance_type in ipairs(ordnance_types) do
                    if
                        p:getWeaponStorage(ordnance_type)
                        < p:getWeaponStorageMax(ordnance_type)
                    then
                        if ship:getWeaponStorage(ordnance_type) > 0 then
                            table.insert(
                                check_loot_buttons,
                                { ship = ship, good = ordnance_type, ord = true }
                            )
                        end
                    end
                end
            end
            if p.loot_buttons == nil then
                p.loot_buttons = {}
            end
            for i, loot_button in ipairs(p.loot_buttons) do
                loot_button.del = true
            end
            if loot_button_diagnostic then
                print("loot buttons marked for deletion")
                showPlayerLootButtons(p)
            end
            if loot_button_index == nil or #p.loot_buttons == 0 then
                loot_button_index = 500
            end
            for i, check_loot_button in ipairs(check_loot_buttons) do
                local check_match = false
                for j, loot_button in ipairs(p.loot_buttons) do
                    if
                        loot_button.ship == check_loot_button.ship
                        and loot_button.good == check_loot_button.good
                    then
                        loot_button.del = false
                        check_match = true
                        break
                    end
                end
                if loot_button_diagnostic then
                    print(
                        "check i:",
                        i,
                        "check item:",
                        check_loot_button.ship:getCallSign(),
                        check_loot_button.good,
                        "check match:",
                        check_match
                    )
                    showPlayerLootButtons(p)
                end
                if not check_match then
                    if loot_button_index >= 600 then
                        loot_button_index = 500
                    end
                    loot_button_index = loot_button_index + 1
                    local loot_button_rel = string.format(
                        "rel%s%s",
                        check_loot_button.ship:getCallSign(),
                        check_loot_button.good
                    )
                    p:addCustomButton(
                        "Relay",
                        loot_button_rel,
                        string.format(
                            "Get %s:%s",
                            check_loot_button.ship:getCallSign(),
                            check_loot_button.good
                        ),
                        function()
                            string.format("")
                            getLoot(
                                p,
                                check_loot_button.ship,
                                check_loot_button.good,
                                check_loot_button.ord
                            )
                        end,
                        loot_button_index
                    )
                    table.insert(
                        p.loot_buttons,
                        {
                            ship = check_loot_button.ship,
                            good = check_loot_button.good,
                            label = loot_button_rel,
                            del = false,
                        }
                    )
                    local loot_button_ops = string.format(
                        "ops%s%s",
                        check_loot_button.ship:getCallSign(),
                        check_loot_button.good
                    )
                    p:addCustomButton(
                        "Operations",
                        loot_button_ops,
                        string.format(
                            "Get %s:%s",
                            check_loot_button.ship:getCallSign(),
                            check_loot_button.good
                        ),
                        function()
                            string.format("")
                            getLoot(
                                p,
                                check_loot_button.ship,
                                check_loot_button.good,
                                check_loot_button.ord
                            )
                        end,
                        loot_button_index
                    )
                    table.insert(
                        p.loot_buttons,
                        {
                            ship = check_loot_button.ship,
                            good = check_loot_button.good,
                            label = loot_button_ops,
                            del = false,
                        }
                    )
                end
            end
            if loot_button_diagnostic then
                print("after check, before delete")
                showPlayerLootButtons(p)
            end
            for i = #p.loot_buttons, 1, -1 do
                local loot_button = p.loot_buttons[i]
                if loot_button.del then
                    p:removeCustom(loot_button.label)
                    p.loot_buttons[i] = p.loot_buttons[#p.loot_buttons]
                    p.loot_buttons[#p.loot_buttons] = nil
                end
            end
        end
    end
end
--	Maintenance
function transportCommerceMaintenance()
    local function swapGoods(transport, docked_with)
        local transport_goods_pool = {}
        if
            transport.comms_data ~= nil
            and transport.comms_data.goods ~= nil
        then
            for good, details in pairs(transport.comms_data.goods) do
                if details.quantity > 0 then
                    table.insert(transport_goods_pool, good)
                end
            end
        end
        if #transport_goods_pool > 0 then
            local station_goods_pool = {}
            if
                docked_with.comms_data ~= nil
                and docked_with.comms_data.goods ~= nil
            then
                for good, details in pairs(docked_with.comms_data.goods) do
                    if details.quantity > 0 then
                        table.insert(station_goods_pool, good)
                    end
                end
            end
            if #station_goods_pool > 0 then
                local swap_transport_good =
                    tableSelectRandom(transport_goods_pool)
                local swap_station_good = tableSelectRandom(station_goods_pool)
                if transport.comms_data.goods[swap_station_good] == nil then
                    transport.comms_data.goods[swap_station_good] =
                        { quantity = 1, cost = math.random(30, 90) }
                else
                    transport.comms_data.goods[swap_station_good].quantity = transport.comms_data.goods[swap_station_good].quantity
                        + 1
                end
                transport.comms_data.goods[swap_transport_good].quantity = transport.comms_data.goods[swap_transport_good].quantity
                    - 1
                if docked_with.comms_data.goods[swap_transport_good] == nil then
                    docked_with.comms_data.goods[swap_transport_good] =
                        { quantity = 1, cost = math.random(20, 80) }
                else
                    docked_with.comms_data.goods[swap_transport_good].quantity = docked_with.comms_data.goods[swap_transport_good].quantity
                        + 1
                end
                docked_with.comms_data.goods[swap_station_good].quantity = docked_with.comms_data.goods[swap_station_good].quantity
                    - 1
                updateShipManifest(transport)
            end
        end
    end
    local function pickTransportTarget(transport)
        local transport_target = nil
        if cleanList(stations) then
            local station_pool = {}
            for i, station in ipairs(stations) do
                if not station:isEnemy(transport) then
                    table.insert(station_pool, station)
                end
            end
            transport_target = tableSelectRandom(station_pool)
        end
        return transport_target
    end
    if cleanList(transports) then
        for i, transport in ipairs(transports) do
            local temp_faction = transport:getFaction()
            local transport_target = nil
            local docked_with = transport:getDockedWith()
            if docked_with then
                if transport.undock_timer == nil then
                    transport.undock_timer = getScenarioTime() + random(10, 25)
                elseif getScenarioTime() > transport.undock_timer then
                    transport.undock_timer = nil
                    transport_target = pickTransportTarget(transport)
                    if transport_target ~= nil then
                        transport:setFaction("Independent")
                        transport:orderDock(transport_target)
                        transport:setFaction(temp_faction)
                        swapGoods(transport, docked_with)
                    end
                end
            else
                if string.find("Dock", transport:getOrder()) then
                    transport_target = transport:getOrderTarget()
                    if
                        transport_target == nil
                        or not transport_target:isValid()
                    then
                        transport_target = pickTransportTarget(transport)
                        if transport_target ~= nil then
                            transport:setFaction("Independent")
                            transport:orderDock(transport_target)
                            transport:setFaction(temp_faction)
                        end
                    end
                else
                    transport_target = pickTransportTarget(transport)
                    if transport_target ~= nil then
                        transport:setFaction("Independent")
                        transport:orderDock(transport_target)
                        transport:setFaction(temp_faction)
                    end
                end
            end
        end
        if transport_population_time == nil then
            transport_population_time = getScenarioTime() + random(30, 150)
        else
            if getScenarioTime() > transport_population_time then
                if cleanList(stations) then
                    transport_population_time = nil
                    if #stations > #transports then
                        local ship, ship_size = randomTransportType()
                        local faction_list = {}
                        for i, station in ipairs(stations) do
                            local station_faction = station:getFaction()
                            local already_recorded = false
                            for j, faction in ipairs(faction_list) do
                                if faction == station_faction then
                                    already_recorded = true
                                    break
                                end
                            end
                            if not already_recorded then
                                table.insert(faction_list, station_faction)
                            end
                        end
                        ship:setFaction(tableSelectRandom(faction_list))
                        local t_x, t_y = vectorFromAngle(random(0, 360), 75000)
                        ship:setPosition(t_x + center_x, t_y + center_y)
                        ship:setCallSign(
                            generateCallSign(nil, ship:getFaction())
                        )
                        table.insert(transports, ship)
                        ship.comms_data = { friendlyness = random(0, 100) }
                        goodsOnShip(ship, ship.comms_data)
                    end
                end
            end
        end
    end
    maintenancePlot = respawnProbe
end
function respawnProbe()
    if probe_respawn ~= nil then
        if #probe_respawn > 0 then
            for i, info in ipairs(probe_respawn) do
                if getScenarioTime() > info.time then
                    if info.instigator ~= nil and info.instigator:isValid() then
                        if info.owner ~= nil and info.owner:isValid() then
                            local s_x, s_y = info.owner:getPosition()
                            local t_x, t_y = info.instigator:getPosition()
                            local probe = ScanProbe()
                                :setLifetime(random(10, 30) * 60)
                                :setOwner(info.owner)
                                :setTarget(t_x, t_y)
                                :setPosition(s_x, s_y)
                            probe:onExpiration(probeExpired)
                            probe:onDestruction(probeDestroyed)
                        end
                    else
                        if info.owner ~= nil and info.owner:isValid() then
                            local s_x, s_y = info.owner:getPosition()
                            local probe = ScanProbe()
                                :setLifetime(random(10, 30) * 60)
                                :setOwner(info.owner)
                                :setTarget(info.x, info.y)
                                :setPosition(s_x, s_y)
                            probe:onExpiration(probeExpired)
                            probe:onDestruction(probeDestroyed)
                        end
                    end
                    probe_respawn[i] = probe_respawn[#probe_respawn]
                    probe_respawn[#probe_respawn] = nil
                    break
                end
            end
        end
    end
    maintenancePlot = stationDefense
end
function stationDefense()
    if cleanList(stations) then
        for i, station in ipairs(stations) do
            object_list = station:getObjectsInRange(5000)
            for j, obj in ipairs(object_list) do
                if obj ~= station then
                    if
                        isObjectType(obj, "CpuShip")
                        or isObjectType(obj, "PlayerSpaceship")
                    then
                        if station:isEnemy(obj) then
                            local create_defense_fleet = false
                            if station.defense_fleet == nil then
                                create_defense_fleet = true
                            elseif #station.defense_fleet < 1 then
                                if station.defense_reaction_time == nil then
                                    station.defense_reaction_time = getScenarioTime()
                                        + random(60, 120)
                                end
                                if
                                    getScenarioTime()
                                    > station.defense_reaction_time
                                then
                                    station.defense_reaction_time = nil
                                    create_defense_fleet = true
                                end
                            end
                            if create_defense_fleet then
                                fleetSpawnFaction = station:getFaction()
                                local sx, sy = station:getPosition()
                                local fleet = spawnRandomArmed(sx, sy)
                                if station.defense_fleet == nil then
                                    station.defense_fleet = {}
                                end
                                for k, ship in ipairs(fleet) do
                                    ship:orderDefendTarget(station)
                                    table.insert(station.defense_fleet, ship)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    maintenancePlot = periodicTaskForce
end
function periodicTaskForce()
    if task_force_time == nil then
        task_force_time = getScenarioTime() + 150
    end
    if getScenarioTime() > task_force_time then
        task_force_time = nil
        local player_list = getActivePlayerShips()
        local player = tableSelectRandom(player_list)
        if tasks_to_do == nil or #tasks_to_do < 1 then
            tasks_to_do = {
                { origin = "enemy", destination = "roaming" },
                { origin = "enemy", destination = "nearest" },
                { origin = "enemy", destination = "random" },
                { origin = "neutral", destination = "roaming" },
                { origin = "friendly", destination = "roaming" },
                { origin = "neutral", destination = "nearest" },
            }
        end
        local task = tableRemoveRandom(tasks_to_do)
        if task.origin == "enemy" then
            local closest_dist = 999999
            local closest_station = nil
            for i, station in ipairs(stations) do
                if
                    station ~= nil
                    and station:isValid()
                    and station:isEnemy(player)
                then
                    local dist = distance(station, player)
                    if dist < closest_dist then
                        closest_dist = dist
                        closest_station = station
                    end
                end
            end
            if closest_station ~= nil then
                fleetSpawnFaction = closest_station:getFaction()
                local sx, sy = closest_station:getPosition()
                local fleet = spawnRandomArmed(sx, sy)
                if task.destination == "roaming" then
                    for i, ship in ipairs(fleet) do
                        ship:orderRoaming()
                    end
                elseif task.destination == "nearest" then
                    closest_dist = 999999
                    local closest_target_station = nil
                    for i, station in ipairs(stations) do
                        if
                            station ~= nil
                            and station:isValid()
                            and station:isEnemy(closest_station)
                        then
                            local dist = distance(closest_station, station)
                            if dist < closest_dist then
                                closest_dist = dist
                                closest_target_station = station
                            end
                        end
                    end
                    if closest_target_station ~= nil then
                        local tx, ty = closest_target_station:getPosition()
                        for i, ship in ipairs(fleet) do
                            ship:orderFlyTowards(tx, ty)
                        end
                    else
                        for i, ship in ipairs(fleet) do
                            ship:orderRoaming()
                        end
                    end
                elseif task.destination == "random" then
                    local station_target_pool = {}
                    for i, station in ipairs(stations) do
                        if
                            station ~= nil
                            and station:isValid()
                            and station:isEnemy(closest_station)
                        then
                            table.insert(station_target_pool, station)
                        end
                    end
                    local target_station =
                        tableSelectRandom(station_target_pool)
                    local tx, ty = target_station:getPosition()
                    for i, ship in ipairs(fleet) do
                        ship:orderFlyTowards(tx, ty)
                    end
                end
            end
        elseif task.origin == "neutral" then
            local closest_dist = 999999
            local closest_station = nil
            for i, station in ipairs(stations) do
                if
                    station ~= nil
                    and station:isValid()
                    and not station:isEnemy(player)
                    and not station:isFriendly(player)
                then
                    local dist = distance(station, player)
                    if dist < closest_dist then
                        closest_dist = dist
                        closest_station = station
                    end
                end
            end
            if closest_station ~= nil then
                fleetSpawnFaction = closest_station:getFaction()
                local sx, sy = closest_station:getPosition()
                local fleet = spawnRandomArmed(sx, sy)
                if task.destination == "roaming" then
                    for i, ship in ipairs(fleet) do
                        ship:orderRoaming()
                    end
                elseif task.destination == "nearest" then
                    closest_dist = 999999
                    local closest_target_station = nil
                    for i, station in ipairs(stations) do
                        if
                            station ~= nil
                            and station:isValid()
                            and station:isEnemy(closest_station)
                        then
                            local dist = distance(closest_station, station)
                            if dist < closest_dist then
                                closest_dist = dist
                                closest_target_station = station
                            end
                        end
                    end
                    if closest_target_station ~= nil then
                        local tx, ty = closest_target_station:getPosition()
                        for i, ship in ipairs(fleet) do
                            ship:orderFlyTowards(tx, ty)
                        end
                    else
                        for i, ship in ipairs(fleet) do
                            ship:orderRoaming()
                        end
                    end
                end
            end
        elseif task.origin == "friendly" then
            local closest_dist = 999999
            local closest_station = nil
            for i, station in ipairs(stations) do
                if
                    station ~= nil
                    and station:isValid()
                    and station:isEnemy(player)
                then
                    local dist = distance(station, player)
                    if dist < closest_dist then
                        closest_dist = dist
                        closest_station = station
                    end
                end
            end
            if closest_station ~= nil then
                fleetSpawnFaction = closest_station:getFaction()
                local sx, sy = closest_station:getPosition()
                local fleet = spawnRandomArmed(sx, sy)
                for i, ship in ipairs(fleet) do
                    ship:orderRoaming()
                end
            end
        end
    end
    maintenancePlot = warpJammerMaintenance
end
--	Spawning ships
--	Pirate functions
function smeeMessage(console, p)
    string.format("")
    p.smee_message = "smee_message"
    p:addCustomMessage(console, p.smee_message, smee(p))
end
function smee(p)
    local function advisePlayer(out, threshold)
        local good_conditions = {}
        local fail_conditions = {}
        if smee_color == nil or #smee_color == 0 then
            smee_color = {
                _("smee-msgRelay", "Avast, me hearties."),
                _(
                    "smee-msgRelay",
                    "The pirate code's more like guidelines than actual rules."
                ),
                _("smee-msgRelay", "Where aarrrr they going?"),
                _(
                    "smee-msgRelay",
                    "It's bad form to shoot a man in the middle of his cadenza."
                ),
                _(
                    "smee-msgRelay",
                    "There's a bit of bravery in everyone, even if they don't know it."
                ),
                _(
                    "smee-msgRelay",
                    "A good pirate never shows his true colors."
                ),
                _(
                    "smee-msgRelay",
                    "It's not the size of the ship, but the captain's heart that matters."
                ),
                _(
                    "smee-msgRelay",
                    "Always remember, laughter is the best medicine, especially when you're sailing through tough times."
                ),
                _("smee-msgRelay", "Not all treasure is silver and gold."),
                _("smee-msgRelay", "Why join the navy if you can be a pirate?"),
                _("smee-msgRelay", "Work like a captain, play like a pirate."),
                _(
                    "smee-msgRelay",
                    "May your blade always be wet and your powder dry."
                ),
                _("smee-msgRelay", "Ahoy matey! Let's trouble the water!"),
                _("smee-msgRelay", "Shiver me timbers."),
                _("smee-msgRelay", "Avast, ye scurvy dog."),
                _("smee-msgRelay", "Batten down the hatches."),
                _("smee-msgRelay", "Here be treasure, matey."),
                _("smee-msgRelay", "Yo ho ho and a bottle of coolant."),
                _(
                    "smee-msgRelay",
                    "A merry life and a short one shall be my motto."
                ),
                _(
                    "smee-msgRelay",
                    "Every generation welcomes the pirates from the last."
                ),
                _(
                    "smee-msgRelay",
                    "When a pirate grows rich enough, they make him a prince."
                ),
                _(
                    "smee-msgRelay",
                    "It is when pirates count their booty that they become mere thieves."
                ),
                _("smee-msgRelay", "Take what you can, give nothing back."),
                _(
                    "smee-msgRelay",
                    "In politics and trade, bruisers and pirates are of better promise than talkers and clerks."
                ),
                _(
                    "smee-msgRelay",
                    "I am a man of fortune and must seek my fortune."
                ),
                _(
                    "smee-msgRelay",
                    "In an honest service, there is thin commons, low wages, and hard labor."
                ),
                _(
                    "smee-msgRelay",
                    "Revenge may sate your being, but don't misunderstand me. It's an end, not a beginning."
                ),
                _(
                    "smee-msgRelay",
                    "Betrayin's all part of piratin'. If you don't know that, you're not even close to being a pirate."
                ),
                _(
                    "smee-msgRelay",
                    "Aye, the sea whispers secrets only the brave dare to listen."
                ),
                _(
                    "smee-msgRelay",
                    "Ye have the heart of a sea serpent - cold and deep as the abyss itself."
                ),
                _(
                    "smee-msgRelay",
                    "Weigh anchor! The dawn's light brings promise of plunder and glory."
                ),
                _(
                    "smee-msgRelay",
                    "Let the sea's song guide us to untold riches, hidden where X marks the spot."
                ),
                _(
                    "smee-msgRelay",
                    "Marooned by fate, saved by wit and will - such is the pirate's plight."
                ),
                _(
                    "smee-msgRelay",
                    "A chest of gold, a bottle of rum, and a sky alight with stars - pirate's paradise."
                ),
                _(
                    "smee-msgRelay",
                    "Coolant's the fuel that stirs the soul and emboldens the spirit of adventure."
                ),
                _(
                    "smee-msgRelay",
                    "A sword's edge and a cunning mind carve the path to treasures untold."
                ),
                _(
                    "smee-msgRelay",
                    "Let no man be called a landlubber when the call of the ocean beckons his heart."
                ),
                _(
                    "smee-msgRelay",
                    "The code of the sea is written in the blood of those who dare to defy it."
                ),
                _(
                    "smee-msgRelay",
                    "Only in the dead of night, under the moon's watchful eye, do true pirates ply their trade."
                ),
                _(
                    "smee-msgRelay",
                    "The call of the deep is a siren's song, luring the unwary to their doom or glory."
                ),
                _(
                    "smee-msgRelay",
                    "In the shadow of the mast, we find solace in the brotherhood of outcasts."
                ),
                _(
                    "smee-msgRelay",
                    "The gleam of treasure is not in its worth, but in the adventure it promises."
                ),
                _(
                    "smee-msgRelay",
                    "Gold and glory, the twin sirens that lead us through peril to paradise."
                ),
                _(
                    "smee-msgRelay",
                    "Let our laughter echo across the waves, a testament to the joy found in lawlessness."
                ),
                _(
                    "smee-msgRelay",
                    "We are the shadows that slip through the night, the whisper of danger on the wind."
                ),
            }
        end
        local smee_color_position = math.random(1, 3)
        for i, msg in ipairs(out) do
            if msg.continue then
                table.insert(good_conditions, msg.msg)
            else
                table.insert(fail_conditions, msg.msg)
            end
        end
        good_msg_count = 1
        if #good_conditions > 1 then
            good_msg_count = math.random(1, math.min(3, #good_conditions))
        end
        local msg = ""
        if smee_color_position == 1 then
            msg = tableRemoveRandom(smee_color)
        end
        if #good_conditions > 0 then
            for i = 1, good_msg_count do
                local selected_message = tableRemoveRandom(good_conditions)
                if selected_message ~= nil then
                    msg = string.format("%s %s", msg, selected_message)
                end
            end
        end
        if smee_color_position == 2 then
            msg = string.format("%s %s", msg, tableRemoveRandom(smee_color))
        end
        if #fail_conditions > 0 then
            if threshold > #fail_conditions then
                for i, fail in ipairs(fail_conditions) do
                    msg = string.format("%s %s", msg, fail)
                end
            else
                for i = 1, threshold do
                    local sel_msg = tableRemoveRandom(fail_conditions)
                    if sel_msg ~= nil then
                        msg = string.format("%s %s", msg, sel_msg)
                    end
                end
            end
        end
        if smee_color_position == 3 then
            msg = string.format("%s %s", msg, tableRemoveRandom(smee_color))
        end
        return msg
    end
    local objects_in_3u = p:getObjectsInRange(3000)
    local ships_in_3u = {}
    for i, obj in ipairs(objects_in_3u) do
        if obj ~= p then
            if isObjectType(obj, "CpuShip") then
                table.insert(ships_in_3u, obj)
            end
        end
    end
    local out = {}
    if #ships_in_3u > 0 then
        local pvx, pvy = p:getVelocity()
        local svx, svy = 0
        local stopped_count = 0
        local victim = nil
        local loot_fail_reason_count = 0
        local smee_threshold = math.random(1, 3)
        if #ships_in_3u > 1 then
            closest_dist = 5000
            closest_victim = nil
            for i, ship in ipairs(ships_in_3u) do
                svx, svy = ship:getVelocity()
                if svx == 0 and svy == 0 then
                    stopped_count = stopped_count + 1
                end
                local dist = distance(ship, p)
                if dist < closest_dist then
                    closest_dist = dist
                    closest_victim = ship
                end
            end
            victim = closest_victim
        else
            victim = ships_in_3u[1]
            svx, svy = victim:getVelocity()
            if svx == 0 and svy == 0 then
                stopped_count = 1
            end
        end
        svx, svy = victim:getVelocity()
        if stopped_count == #ships_in_3u then
            if pvx == 0 and pvy == 0 then
                if svx == 0 and svy == 0 then
                    table.insert(
                        out,
                        {
                            msg = string.format(
                                _(
                                    "smee-msgRelay",
                                    "We've stopped and %s has stopped."
                                ),
                                victim:getCallSign()
                            ),
                            continue = true,
                        }
                    )
                else
                    table.insert(
                        out,
                        {
                            msg = string.format(
                                _(
                                    "smee-msgRelay",
                                    "We've stopped but %s hasn't. We can't get loot while they're moving. Shoot out their engines to make them stop."
                                ),
                                victim:getCallSign()
                            ),
                            continue = false,
                        }
                    )
                    loot_fail_reason_count = loot_fail_reason_count + 1
                end
            else
                if svx == 0 and svy == 0 then
                    table.insert(
                        out,
                        {
                            msg = string.format(
                                _(
                                    "smee-msgRelay",
                                    "%s has stopped. We have to stop, too, if we're going to get some loot."
                                ),
                                victim:getCallSign()
                            ),
                            continue = false,
                        }
                    )
                    loot_fail_reason_count = loot_fail_reason_count + 1
                else
                    table.insert(
                        out,
                        {
                            msg = string.format(
                                _(
                                    "smee-msgRelay",
                                    "%s and %s both have to be stopped if we're going to get loot from %s."
                                ),
                                p:getCallSign(),
                                victim:getCallSign(),
                                victim:getCallSign()
                            ),
                            continue = false,
                        }
                    )
                    loot_fail_reason_count = loot_fail_reason_count + 1
                end
            end
        else
            if stopped_count == 0 then
                table.insert(
                    out,
                    {
                        msg = string.format(
                            "We have to stop %s if we're going to loot it. You might want to disable the engines without destroying it.",
                            victim:getCallSign()
                        ),
                        continue = false,
                    }
                )
                loot_fail_reason_count = loot_fail_reason_count + 1
            else
                if pvx == 0 and pvy == 0 then
                    if svx == 0 and svy == 0 then
                        table.insert(
                            out,
                            {
                                msg = string.format(
                                    _(
                                        "smee-msgRelay",
                                        "%s and %s have both stopped."
                                    ),
                                    p:getCallSign(),
                                    victim:getCallSign()
                                ),
                                continue = true,
                            }
                        )
                    else
                        table.insert(
                            out,
                            {
                                msg = string.format(
                                    _(
                                        "smee-msgRelay",
                                        "We're stopped and another ship has stopped, but %s, the closest cherry to be picked, has not stopped."
                                    ),
                                    victim:getCallSign()
                                ),
                                continue = false,
                            }
                        )
                        loot_fail_reason_count = loot_fail_reason_count + 1
                    end
                else
                    table.insert(
                        out,
                        {
                            msg = _(
                                "smee-msgRelay",
                                "We need to stop too if we want to get any loot."
                            ),
                            continue = false,
                        }
                    )
                end
            end
        end
        if loot_fail_reason_count >= smee_threshold then
            return advisePlayer(out, smee_threshold)
        end
        if p.cargo == 0 then
            table.insert(
                out,
                {
                    msg = _(
                        "smee-msgRelay",
                        "We can't loot any cargo because we have no room in our cargo hold."
                    ),
                    continue = false,
                }
            )
            loot_fail_reason_count = loot_fail_reason_count + 1
        else
            table.insert(
                out,
                {
                    msg = _(
                        "smee-msgRelay",
                        "We've got room in our cargo hold for some loot."
                    ),
                    continue = true,
                }
            )
        end
        if loot_fail_reason_count >= smee_threshold then
            return advisePlayer(out, smee_threshold)
        end
        local shield_up = true
        if victim ~= nil and victim:isValid() then
            for j = 1, victim:getShieldCount() do
                local shield_level = victim:getShieldLevel(j - 1)
                if victim:getShieldLevel(j - 1) <= 0 then
                    shield_up = false
                    break
                end
            end
        end
        if shield_up then
            table.insert(
                out,
                {
                    msg = _(
                        "smee-msgRelay",
                        "We have to take down at least one of their shields to get loot."
                    ),
                    continue = false,
                }
            )
            loot_fail_reason_count = loot_fail_reason_count + 1
        else
            if victim:getShieldCount() > 0 then
                if victim:getShieldCount() > 1 then
                    table.insert(
                        out,
                        {
                            msg = string.format(
                                _(
                                    "smee-msgRelay",
                                    "At least one of %s's shield arcs is down."
                                ),
                                victim:getCallSign()
                            ),
                            continue = true,
                        }
                    )
                else
                    table.insert(
                        out,
                        {
                            msg = string.format(
                                _("smee-msgRelay", "%s's shield is down."),
                                victim:getCallSign()
                            ),
                            continue = true,
                        }
                    )
                end
            else
                table.insert(
                    out,
                    {
                        msg = string.format(
                            _("smee-msgRelay", "%s does not have any shields."),
                            victim:getCallSign()
                        ),
                        continue = true,
                    }
                )
            end
        end
        if loot_fail_reason_count >= smee_threshold then
            return advisePlayer(out, smee_threshold)
        end
        if p:getShieldsActive() then
            table.insert(
                out,
                {
                    msg = _(
                        "smee-msgRelay",
                        "We can't get loot if our shields are up."
                    ),
                    continue = false,
                }
            )
            loot_fail_reason_count = loot_fail_reason_count + 1
        else
            table.insert(
                out,
                { msg = _("smee-msgRelay", "Our shields are down."), continue = true }
            )
        end
        if loot_fail_reason_count >= smee_threshold then
            return advisePlayer(out, smee_threshold)
        end
        local loot_list = {}
        local ord_count = 0
        local good_count = 0
        if victim ~= nil and victim:isValid() then
            if victim.comms_data ~= nil and victim.comms_data.goods ~= nil then
                for good, details in pairs(victim.comms_data.goods) do
                    table.insert(
                        loot_list,
                        { loot = good_desc[good], ord = false }
                    )
                    good_count = good_count + 1
                end
            end
            for j, ordnance_type in ipairs(ordnance_types) do
                if
                    p:getWeaponStorage(ordnance_type)
                    < p:getWeaponStorageMax(ordnance_type)
                then
                    if victim:getWeaponStorage(ordnance_type) > 0 then
                        table.insert(
                            loot_list,
                            { loot = ordnance_type, ord = true }
                        )
                        ord_count = ord_count + 1
                    end
                end
            end
        end
        if
            victim ~= nil
            and victim:isValid()
            and victim:isFullyScannedBy(p)
        then
            if #loot_list > 0 then
                loot_list_msg = ""
                for i, loot_list_item in ipairs(loot_list) do
                    loot_list_msg = string.format(
                        "%s %s",
                        loot_list_msg,
                        loot_list_item.loot
                    )
                end
                if good_count > 0 and ord_count > 0 then
                    loot_list_msg = string.format(
                        _(
                            "smee-msgRelay",
                            "%s has cargo and ordnance we could get:%s."
                        ),
                        victim:getCallSign(),
                        loot_list_msg
                    )
                elseif good_count > 0 then
                    loot_list_msg = string.format(
                        _("smee-msgRelay", "%s has cargo we could get:%s."),
                        victim:getCallSign(),
                        loot_list_msg
                    )
                else
                    loot_list_msg = string.format(
                        _("smee-msgRelay", "%s has ordnance we could get:%s."),
                        victim:getCallSign(),
                        loot_list_msg
                    )
                end
                table.insert(out, { msg = loot_list_msg, continue = true })
            else
                table.insert(
                    out,
                    {
                        msg = string.format(
                            _(
                                "smee-msgRelay",
                                "%s has nothing we need or want."
                            ),
                            victim:getCallSign()
                        ),
                        continue = false,
                    }
                )
                loot_fail_reason_count = loot_fail_reason_count + 1
            end
        end
        if loot_fail_reason_count >= smee_threshold then
            return advisePlayer(out, smee_threshold)
        end
        if p:getEnergy() < 50 then
            table.insert(
                out,
                {
                    msg = _(
                        "smee-msgRelay",
                        "We need 50 energy per item of loot we want. Looting may fail."
                    ),
                    continue = false,
                }
            )
        else
            table.insert(
                out,
                {
                    msg = _(
                        "smee-msgRelay",
                        "We've got 50 or more energy. We need 50 per item. Looting will probably succeed."
                    ),
                    continue = true,
                }
            )
        end
        return advisePlayer(out, smee_threshold)
    else
        --No victims in 3U. Analyze sensor readings
        table.insert(
            out,
            {
                msg = _(
                    "smee-msgRelay",
                    "There are no ships we can loot within three units."
                ),
                continue = false,
            }
        )
        return advisePlayer(out, 1)
    end
end
function piracy(player_name, victim_name)
    local player = nil
    for i, p in ipairs(getActivePlayerShips()) do
        if p:getCallSign() == player_name then
            player = p
            break
        end
    end
    if player == nil then
        print("Invalid player name:", player_name)
        return
    end
    if player:getShieldsActive() then
        print(string.format("%s shields are up - piracy failed", player_name))
        return
    else
        print(string.format("%s shields are down - check", player_name))
    end
    if player.cargo > 0 then
        print(string.format("%s has room for cargo - check", player_name))
    else
        print(
            string.format("%s has no cargo space - piracy failed", player_name)
        )
        return
    end
    local pvx, pvy = player:getVelocity()
    if pvx == 0 and pvy == 0 then
        print(string.format("%s has stopped - check", player_name))
    else
        print(
            string.format("%s is still in motion - piracy failed", player_name)
        )
        return
    end
    local victim = nil
    local objects_in_3u = player:getObjectsInRange(3000)
    for i, ship in ipairs(objects_in_3u) do
        if isObjectType(ship, "CpuShip") then
            if victim_name ~= nil and ship:getCallSign() == victim_name then
                victim = ship
            end
        end
    end
    if victim == nil then
        print(
            string.format(
                "Invalid victim, %s (nil, invalid or not within 3U of %s)",
                victim_name,
                player_name
            )
        )
        return
    end
    local cvx, cvy = victim:getVelocity()
    if cvx == 0 and cvy == 0 then
        print(string.format("%s has stopped - check", victim_name))
    else
        print(
            string.format("%s is still in motion - piracy failed", victim_name)
        )
        return
    end
    local shield_up = true
    for j = 1, victim:getShieldCount() do
        local shield_level = victim:getShieldLevel(j - 1)
        if victim:getShieldLevel(j - 1) <= 0 then
            shield_up = false
            break
        end
    end
    if shield_up then
        print(
            string.format(
                "%s still has shields up - piracy failed",
                victim_name
            )
        )
        return
    else
        print(
            string.format(
                "%s has at least one shield arc down - check",
                victim_name
            )
        )
    end
    local loot = {}
    if victim.comms_data ~= nil and victim.comms_data.goods ~= nil then
        for good, details in pairs(victim.comms_data.goods) do
            if details.quantity > 0 then
                table.insert(loot, good)
            end
        end
    end
    for j, ordnance_type in ipairs(ordnance_types) do
        if
            player:getWeaponStorage(ordnance_type)
            < player:getWeaponStorageMax(ordnance_type)
        then
            if victim:getWeaponStorage(ordnance_type) > 0 then
                table.insert(loot, ordnance_type)
            end
        end
    end
    if #loot > 0 then
        local loot_string = ""
        for i, loot_item in ipairs(loot) do
            loot_string = string.format("%s %s", loot_string, loot_item)
        end
        print(
            string.format(
                "%s has loot for %s:%s - check",
                victim_name,
                player_name,
                loot_string
            )
        )
    else
        print(
            string.format(
                "%s does not have loot for %s - piracy failed",
                victim_name,
                player_name
            )
        )
        return
    end
    if player:getEnergy() < 50 then
        print(
            string.format(
                "%s has less than 50 energy - piracy will probably fail",
                player_name
            )
        )
    else
        print(
            string.format(
                "%s has 50 energy or more - piracy will probably succeed",
                player_name
            )
        )
    end
end
function getLoot(p, ship, good, ord)
    if ship:isValid() then
        if ord then
            local avail = ship:getWeaponStorage(good)
            if avail > 0 then
                if p:getWeaponStorage(good) < p:getWeaponStorageMax(good) then
                    if p:getEnergy() < 50 then
                        p.insufficient_energy_rel = "insufficient_energy_rel"
                        p.insufficient_energy_ops = "insufficient_energy_ops"
                        p:addCustomMessage(
                            "Relay",
                            p.insufficient_energy_rel,
                            _(
                                "msgRelay",
                                "Cannot get munitions because there is not enough energy to power the transporters. You need at least 50 energy."
                            )
                        )
                        p:addCustomMessage(
                            "Operations",
                            p.insufficient_energy_ops,
                            _(
                                "msgOperations",
                                "Cannot get munitions because there is not enough energy to power the transporters. You need at least 50 energy."
                            )
                        )
                    else
                        if
                            avail
                            > (
                                p:getWeaponStorageMax(good)
                                - p:getWeaponStorage(good)
                            )
                        then
                            ship:setWeaponStorage(
                                good,
                                (
                                    p:getWeaponStorageMax(good)
                                    - p:getWeaponStorage(good)
                                )
                            )
                            p:setWeaponStorage(
                                good,
                                p:getWeaponStorageMax(good)
                            )
                        else
                            ship:setWeaponStorage(
                                good,
                                (p:getWeaponStorage(good) - avail)
                            )
                            p:setWeaponStorage(
                                good,
                                (p:getWeaponStorage(good) + avail)
                            )
                        end
                        p:setEnergy(p:getEnergy() - 50)
                    end
                end
            end
        else
            if ship.comms_data ~= nil then
                if ship.comms_data.goods ~= nil then
                    if ship.comms_data.goods[good] ~= nil then
                        if ship.comms_data.goods[good].quantity > 0 then
                            if p.cargo > 0 then
                                if p:getEnergy() < 50 then
                                    p.insufficient_energy_rel =
                                        "insufficient_energy_rel"
                                    p.insufficient_energy_ops =
                                        "insufficient_energy_ops"
                                    p:addCustomMessage(
                                        "Relay",
                                        p.insufficient_energy_rel,
                                        _(
                                            "msgRelay",
                                            "Cannot get cargo because there is not enough energy to power the transporters. You need at least 50 energy."
                                        )
                                    )
                                    p:addCustomMessage(
                                        "Operations",
                                        p.insufficient_energy_ops,
                                        _(
                                            "msgOperations",
                                            "Cannot get cargo because there is not enough energy to power the transporters. You need at least 50 energy."
                                        )
                                    )
                                else
                                    if p.goods == nil then
                                        p.goods = {}
                                    end
                                    if p.goods[good] == nil then
                                        p.goods[good] = 0
                                    end
                                    p.goods[good] = p.goods[good] + 1
                                    p.cargo = p.cargo - 1
                                    p:setEnergy(p:getEnergy() - 50)
                                    ship.comms_data.goods[good].quantity = ship.comms_data.goods[good].quantity
                                        - 1
                                    local farthest_dist = 0
                                    local farthest_transport = nil
                                    for i, transport in ipairs(transports) do
                                        if
                                            transport ~= nil
                                            and transport:isValid()
                                            and transport ~= ship
                                        then
                                            local dist = distance(p, transport)
                                            if dist > farthest_dist then
                                                farthest_transport = transport
                                                farthest_dist = dist
                                            end
                                        end
                                    end
                                    if farthest_transport ~= nil then
                                        if
                                            farthest_transport.comms_data ~= nil
                                        then
                                            if
                                                farthest_transport.comms_data.goods
                                                ~= nil
                                            then
                                                if
                                                    farthest_transport.comms_data.goods[good]
                                                    ~= nil
                                                then
                                                    farthest_transport.comms_data.goods[good].quantity = farthest_transport.comms_data.goods[good].quantity
                                                        + 1
                                                else
                                                    farthest_transport.comms_data.goods[good] =
                                                        {
                                                            quantity = 1,
                                                            cost = math.random(
                                                                20,
                                                                80
                                                            ),
                                                        }
                                                    updateShipManifest(
                                                        farthest_transport
                                                    )
                                                end
                                            else
                                                farthest_transport.comms_data.goods =
                                                    {}
                                                farthest_transport.comms_data.goods[good] =
                                                    {
                                                        quantity = 1,
                                                        cost = math.random(
                                                            20,
                                                            80
                                                        ),
                                                    }
                                                updateShipManifest(
                                                    farthest_transport
                                                )
                                            end
                                        end
                                    end
                                    updateShipManifest(ship)
                                    if
                                        defender_pirate_state
                                        ~= _("msgMainscreen", "Pirates")
                                    then
                                        if p:isEnemy(ship) then
                                            defender_pirate_state = _(
                                                "msgMainscreen",
                                                "Licensed Privateers"
                                            )
                                        else
                                            defender_pirate_state =
                                                _("msgMainscreen", "Pirates")
                                        end
                                    end
                                    if ship.defenders == nil then
                                        local nearest_dist = 999999
                                        local nearest_station = nil
                                        for i, station in ipairs(stations) do
                                            if
                                                station ~= nil
                                                and station:isValid()
                                            then
                                                if
                                                    not station:isEnemy(ship)
                                                    and station:isEnemy(p)
                                                then
                                                    local dist =
                                                        distance(ship, station)
                                                    if dist < nearest_dist then
                                                        nearest_station =
                                                            station
                                                        nearest_dist = dist
                                                    end
                                                end
                                            end
                                        end
                                        if nearest_station ~= nil then
                                            local sx, sy =
                                                nearest_station:getPosition()
                                            fleetSpawnFaction =
                                                nearest_station:getFaction()
                                            if nearest_dist > 15000 then
                                                fleetComposition = "Chasers"
                                            end
                                            ship.defenders =
                                                spawnRandomArmed(sx, sy)
                                            for i, defender in
                                                ipairs(ship.defenders)
                                            do
                                                defender:orderDefendTarget(ship)
                                            end
                                            fleetComposition = "Random"
                                        end
                                    end
                                end
                            else
                                p.cargo_bay_full_rel = "cargo_bay_full_rel"
                                p.cargo_bay_full_ops = "cargo_bay_full_ops"
                                p:addCustomMessage(
                                    "Relay",
                                    p.cargo_bay_full_rel,
                                    _(
                                        "msgRelay",
                                        "Cannot get cargo because the cargo bay is full."
                                    )
                                )
                                p:addCustomMessage(
                                    "Operations",
                                    p.cargo_bay_full_ops,
                                    _(
                                        "msgOperations",
                                        "Cannot get cargo because the cargo bay is full."
                                    )
                                )
                            end
                        end
                    end
                end
            end
        end
    end
end
function updateShipManifest(ship)
    local manifest = _("scienceDescription", "Manifest:")
    for good, details in pairs(ship.comms_data.goods) do
        if details.quantity ~= nil and details.quantity > 0 then
            manifest = string.format("%s %s", manifest, good_desc[good])
        end
    end
    if manifest == _("scienceDescription", "Manifest:") then
        manifest = _("scienceDescription", "Manifest: empty")
    end
    ship:setDescriptionForScanState("notscanned", "")
    ship:setDescriptionForScanState(
        "friendorfoeidentified",
        _("scienceDescription", "Commercial Freighter")
    )
    ship:setDescriptionForScanState(
        "simplescan",
        _("scienceDescription", "Commercial Freighter")
    )
    ship:setDescriptionForScanState("fullscan", manifest)
end

function closestFriendlyNeutralStation(obj)
    local dist = 999999
    local closest = nil
    if obj ~= nil and obj:isValid() then
        for i, station in ipairs(stations) do
            if
                station ~= nil
                and station:isValid()
                and not station:isEnemy(obj)
            then
                local cur_dist = distance(obj, station)
                if cur_dist < dist then
                    dist = cur_dist
                    closest = station
                end
            end
        end
        return closest
    else
        return nil
    end
end
function finalStats()
    local a_player = getPlayerShip(-1)
    local final_message = string.format(
        _("msgMainscreen", "Reputation point goal: %s"),
        reputation_goal
    )
    if a_player ~= nil and a_player:isValid() then
        final_message = string.format(
            _("msgMainscreen", "%s\nThe %s ended with %s reputation points."),
            final_message,
            player_faction,
            a_player:getReputationPoints()
        )
    else
        final_message = string.format(
            _(
                "msgMainscreen",
                "%s\nThe %s did not quite make it.",
                final_message,
                player_faction
            )
        )
    end
    final_message = string.format(
        _("msgMainscreen", "%s\nYou have been labeled %s."),
        final_message,
        defender_pirate_state
    )
    final_message = Stats.appendDeployed(final_message, deployed_player_count)
    final_message = Stats.appendDuration(final_message, "%s\nTime spent: %s.")
    final_message = Stats.appendSettings(final_message, "%s\nEnemies:%s Murphy:%s Respawn:%s", "Enemies", "Murphy", "Respawn")
    return final_message
end
function update(delta)
    if delta == 0 then
        return
    end
    --	game is no longer paused
    allowNewPlayerShips(false)
    if reputation_goal == nil then
        reputation_goal = playerPower() * goal_strength_multiplier + 50 --normal difficulty gives you 50 rep to start
        primary_orders = string.format(
            _(
                "orders-comms",
                "Goal: Reach your reputation goal of %s reputation points. You're only loosely affiliated with the %s, so you don't have orders per se."
            ),
            reputation_goal,
            player_faction
        )
    end
    for i, p in ipairs(getActivePlayerShips()) do
        if p:getReputationPoints() >= reputation_goal then
            globalMessage(finalStats())
            victory(player_faction)
        end
        if p.mission_message_one == nil then
            if availableForComms(p) then
                local message_station = closestFriendlyNeutralStation(p)
                if message_station ~= nil then
                    local mission_message = string.format(
                        _(
                            "goal-incCall",
                            "Your goal is to accumulate %s reputation points in %s minutes or less. You get reputation by killing enemies, completing missions or selling goods to stations. You can accumulate goods by trading or by taking (like pirates). Your call. Your reputation goal is set based on the number and capability of the player ships spawned along with the configuration options selected at the start by the game host."
                        ),
                        reputation_goal,
                        scenario_duration
                    )
                    if not message_station:isFriendly(p) then
                        mission_message = string.format(
                            _(
                                "goal-incCall",
                                "%s Visit us anytime in sector %s."
                            ),
                            mission_message,
                            message_station:getSectorName()
                        )
                    end
                    message_station:sendCommsMessage(p, mission_message)
                    p.mission_message_one = "sent"
                end
            end
        end
        lootButtons(p)
        updatePlayerInventoryButtonUtility(p)
        updatePlayerLongRangeSensors(delta, p)
        updateTubeBanner(p)
        updateNameBanner(p)
    end
    if maintenancePlot ~= nil then
        maintenancePlot()
    end
    if getScenarioTime() > scenario_duration * 60 then
        globalMessage(finalStats())
        victory("Exuari")
    end
end
