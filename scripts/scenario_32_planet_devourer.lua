-- Name: Planet Devourer
-- Description: Stop the Planet Devourer before all the planets are gone
---
--- Written for EE games on May 4th, 2023 = "May the 4th be with you"
---
--- Version 1
---
--- USN Discord: https://discord.gg/PntGG3a where you can join a game online. There's one every weekend. All experience levels are welcome.
-- Type: Replayable
-- Author: Xansta
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
-- Setting[Reputation]: Amount of reputation to start with
-- Reputation[Unknown]: Zero reputation - nobody knows anything about you
-- Reputation[Nice|Default]: 20 reputation - you've had a small positive influence on the local community
-- Reputation[Hero]: 50 reputation - you helped important people or lots of people
-- Reputation[Major Hero]: 100 reputation - you're well known by nearly everyone as a force for good
-- Reputation[Super Hero]: 200 reputation - everyone knows you and relies on you for help

require("utils.lua")
require("place_station_scenario_utility.lua")
require("generate_call_sign_scenario_utility.lua")
require("cpu_ship_diversification_scenario_utility.lua")
local Environment = require("environment_scenario_utility.lua")
local placeAsteroid = Environment.placeAsteroid
local placeAsteroidField = Environment.placeAsteroidField
local placeBlackHole = Environment.placeBlackHole
local placeMine = Environment.placeMine
local placeMineField = Environment.placeMineField
local placeNebula = Environment.placeNebula
local placeProbe = Environment.placeProbe
local placeWormHole = Environment.placeWormHole
local placeRandomAsteroidsAroundPoint = Environment.asteroidsAroundPointCoarse
local createRandomAlongArc = Environment.createRandomAlongArcNorth
local createRandomAsteroidAlongArc = Environment.createRandomAsteroidAlongArc
local defaults = require("defaults_scenario_utility.lua")
local ShipNames = require("player_ship_names_scenario_utility.lua")
local PlayerState = require("player_state_scenario_utility.lua")
local ShipStatus = require("ship_status_scenario_utility.lua")
local ServiceOptions = require("comms_service_options.lua")
local ShipComms = require("comms_ship_support.lua")
local Fleet = require("spawn_ships_scenario_utility.lua")
local friendlyVesselDestroyed = Fleet.noopDestroyed
local StationCore = require("comms_station_core.lua")
local StationMenu = require("comms_station_menu.lua")
local Inventory = require("inventory_scenario_utility.lua")
local playerShipCargoInventory = Inventory.renderer(function() return good_desc end)
local cargoInventory = Inventory.buttons(32, playerShipCargoInventory)
local Sensor = require("sensor_scenario_utility.lua")
local Continuum = require("continuum_scenario_utility.lua")
local Transport = require("transport_scenario_utility.lua")
local pickTransportTarget = Transport.pickTransportTarget
local randomTransportType = Transport.randomTransportTypeExtended
local transportCommerceMaintenance = Transport.transportCommerceMaintenance
local warpJammerMaintenance = Transport.warpJammerMaintenance(function() return transportCommerceMaintenance end)

local checkContinuum = Continuum.checkContinuum
local resetContinuum = Continuum.resetContinuum
local revertCheck = Continuum.revertCheckAlternate
local revertWait = Continuum.revertWait

local sensorJammer = Sensor.sensorJammerExtended
local GmSettings = require("gm_settings_scenario_utility.lua")
local setEnemyPower = GmSettings.numeric({
    back_label = function() return _("buttonGM", "-From Enemy Power") end,
    back = function() mainGMButtons() end,
    values = GmSettings.powerValues,
    format = "%s %.1f",
    get = function() return enemy_power end,
    set = function(value) enemy_power = value end,
})
local setDifficulty = GmSettings.numeric({
    back_label = function() return _("buttonGM", "-From Difficulty") end,
    back = function() mainGMButtons() end,
    values = GmSettings.difficultyValues,
    format = "%s %.1f",
    get = function() return difficulty end,
    set = function(value) difficulty = value end,
})
local setInitialReputation = GmSettings.numeric({
    back_label = function() return _("buttonGM", "-From Reputation") end,
    back = function() mainGMButtons() end,
    values = GmSettings.reputationValues,
    format = "%s %i",
    get = function() return reputation_start_amount end,
    set = function(value) reputation_start_amount = value end,
})

local Runtime = require("runtime_scenario_utility.lua")

local MissionMenu = require("comms_mission_menu.lua")

local function placeSensorJammer(axis)
    return Environment.placeSensorJammer(axis, sensorJammer)
end
local sensorJammerPickupProcess = Sensor.sensorJammerPickupExtended
local updatePlayerLongRangeSensors = Sensor.updatePlayerLongRangeSensorsExtended


local station_profile
commsStation = StationMenu.entrypoint(function() return station_profile end)
local getCoolantFromStation = StationCore.getCoolantFromStation
local getFriendStatus = StationCore.getFriendStatus
local getRepairCrewFromStation = StationCore.getRepairCrewFromStation
local getServiceCost = StationCore.getServiceCost
local getWeaponCost = StationCore.getWeaponCost
local handleWeaponRestock = StationCore.handleWeaponRestock
local isAllowedTo = StationCore.isAllowedTo


local getTemplatePool = Fleet.templatePoolGetter({
    catalog = function() return ship_template end,
    selectivity = function() return pool_selectivity end,
    composition = function() return fleetComposition end,
    limit = function() return template_pool_size end,
    stock_template = function() return stockTemplate end,
    fleet_group = function() return fleet_group end,
})

local playerPower = Fleet.playerPowerGetter({
    player = function(index) return getPlayerShip(index) end,
    limit = 32,
})
local availableForComms = ShipComms.availableForComms
local enemyComms = ShipComms.enemyComms
local getEnemyHealth = ShipComms.getEnemyHealth
local goodsOnShip = ShipComms.goodsOnShip

local commonServiceOptions = ServiceOptions.commonServiceOptions
local friendlyServiceJonqueComms = ServiceOptions.friendlyServiceJonqueComms
local neutralServiceJonqueComms = ServiceOptions.neutralServiceJonqueComms

local ship_profile
commsShip = ShipComms.commsShipGetter(function() return ship_profile end)
function commsServiceJonque()
    return ShipComms.serviceJonqueComms({
        friendly = friendlyServiceJonqueComms,
        neutral = neutralServiceJonqueComms,
        enemy = ShipComms.enemyComms,
    })
end

local ship_status = ShipStatus.new({
    player_limit = 32,
    interval = function()
        return healthCheckTimerInterval
    end,
    recovery = function()
        return 4 - difficulty
    end,
})
local resetPreviousSystemHealth = ShipStatus.resetCallback(ship_status)
local crewFate = ShipStatus.fateCallback(ship_status)

local function healthCheck(delta)
    healthCheckTimer = ship_status:update(delta, healthCheckTimer)
end



-- also uses supply_drop.lua

--------------------
-- Initialization --
--------------------
function init()
    scenario_version = "1.0.4"
    ee_version = "2024.12.08"
    print(
        string.format(
            "    ----    Scenario: Planet Devourer    ----    Version %s    ----    Tested with EE version %s    ----",
            scenario_version,
            ee_version
        )
    )
    if _VERSION ~= nil then
        print("Lua version:", _VERSION)
    end
    spawn_enemy_diagnostic = false
    setVariations() --numeric difficulty, Kraylor fortress size
    setConstants() --missle type names, template names and scores, deployment directions, player ship names, etc.
    constructEnvironment()
    setGMButtons()
    mainGMButtons()
    onNewPlayerShip(setPlayers)
end
function setVariations()
    if getScenarioSetting == nil then
        enemy_power = 1
        difficulty = 1
        adverseEffect = 0.995
        coolant_loss = 0.99995
        coolant_gain = 0.001
        danger_pace = 300
        reputation_start_amount = 0
    else
        local enemy_config = {
            ["Easy"] = { number = 0.5 },
            ["Normal"] = { number = 1 },
            ["Hard"] = { number = 2 },
            ["Extreme"] = { number = 3 },
            ["Quixotic"] = { number = 5 },
        }
        enemy_power = enemy_config[getScenarioSetting("Enemies")].number
        local murphy_config = {
            ["Easy"] = {
                number = 0.5,
                adverse = 0.999,
                lose_coolant = 0.99999,
                gain_coolant = 0.005,
            },
            ["Normal"] = {
                number = 1,
                adverse = 0.995,
                lose_coolant = 0.99995,
                gain_coolant = 0.001,
            },
            ["Hard"] = {
                number = 2,
                adverse = 0.99,
                lose_coolant = 0.9999,
                gain_coolant = 0.0001,
            },
        }
        difficulty = murphy_config[getScenarioSetting("Murphy")].number
        -- affects:
        -- sensor buoy scan complexity and depth (ads, transport info, station info)
        -- sensor jammer scan complexity and depth
        -- nebula concealment of mine fields
        -- availability of gossip
        -- repair crew availability
        -- coolant availability
        -- named character availability
        -- taunted enemy retaliation choice possibilities
        -- revival of repair crew chance when zero repair crew present
        adverseEffect = murphy_config[getScenarioSetting("Murphy")].adverse
        coolant_loss = murphy_config[getScenarioSetting("Murphy")].lose_coolant
        coolant_gain = murphy_config[getScenarioSetting("Murphy")].gain_coolant
        local reputation_config = {
            ["Unknown"] = 0,
            ["Nice"] = 20,
            ["Hero"] = 50,
            ["Major Hero"] = 100,
            ["Super Hero"] = 200,
        }
        reputation_start_amount =
            reputation_config[getScenarioSetting("Reputation")]
        danger_pace = 300
    end
end
function setConstants()
    far_enough_fail = false
    distance_diagnostic = false
    stationCommsDiagnostic = false
    change_enemy_order_diagnostic = false
    healthDiagnostic = false
    sensor_jammer_diagnostic = false
    sj_diagnostic = false --short sensor jammer diagnostic, once at env create
    enforce_end = false
    player_ship_spawn_count = 0
    player_ship_death_count = 0
    max_repeat_loop = 300
    primary_orders = _("orders-comms", "Save the planets from destruction")
    plotCI = cargoInventory
    plotH = healthCheck --Damage to ship can kill repair crew members
    healthCheckTimerInterval = 8
    healthCheckTimer = healthCheckTimerInterval
    prefix_length = 0
    suffix_index = 0
    cpu_ships = {}
    station_defend_dist = {
        [ST.SMALL_STATION] = 2800,
        [ST.MEDIUM_STATION] = 4200,
        [ST.LARGE_STATION] = 4800,
        [ST.HUGE_STATION] = 5200,
    }
    system_list = {
        "reactor",
        "beamweapons",
        "missilesystem",
        "maneuver",
        "impulse",
        "warp",
        "jumpdrive",
        "frontshield",
        "rearshield",
    }
    character_names = {
        "Frank Brown",
        "Joyce Miller",
        "Harry Jones",
        "Emma Davis",
        "Zhang Wei Chen",
        "Yu Yan Li",
        "Li Wei Wang",
        "Li Na Zhao",
        "Sai Laghari",
        "Anaya Khatri",
        "Vihaan Reddy",
        "Trisha Varma",
        "Henry Gunawan",
        "Putri Febrian",
        "Stanley Hartono",
        "Citra Mulyadi",
        "Bashir Pitafi",
        "Hania Kohli",
        "Gohar Lehri",
        "Sohelia Lau",
        "Gabriel Santos",
        "Ana Melo",
        "Lucas Barbosa",
        "Juliana Rocha",
        "Habib Oni",
        "Chinara Adebayo",
        "Tanimu Ali",
        "Naija Bello",
        "Shamim Khan",
        "Barsha Tripura",
        "Sumon Das",
        "Farah Munsi",
        "Denis Popov",
        "Pasha Sokolov",
        "Burian Ivanov",
        "Radka Vasiliev",
        "Jose Hernandez",
        "Victoria Garcia",
        "Miguel Lopez",
        "Renata Rodriguez",
    }
    --Player ship name lists to supplant standard randomized call sign generation
    player_ship_names_for = ShipNames.shared()
    player_ship_names_for["Amalgam"] = { "Mixer", "Igor", "Ronco", "Ginsu" }
    player_ship_names_for["Atlantis MK2"] =
        { "Katana", "Forthright", "Expedition", "Golden Era", "Devestator" }
    player_ship_names_for["Corsair"] =
        { "Vamanos", "Cougar", "Parthos", "Trifecta", "Light Mind" }
    player_ship_names_for["Destroyer III"] =
        { "Trebuchet", "Pitcher", "Mutant", "Gronk", "Methuselah" }
    player_ship_names_for["Midian"] =
        { "Flipper", "Feint", "Dolphin", "Joker", "Trickster" }
    player_ship_names_for["Raven"] =
        { "Claw", "Bethel", "Cicero", "Da Vinci", "Skaats" }
    player_ship_names_for["Squid"] =
        { "Ink", "Tentacle", "Pierce", "Writhe", "Bogey" }
    player_ship_names_for["Leftovers"] = { "Foregone", "Righteous", "Masher" }
    missile_types = { "Homing", "Nuke", "Mine", "EMP", "HVLI" }
    pool_selectivity = "full"
    template_pool_size = 15
    ship_template = { --ordered by relative strength
        ["Gnat"] = { strength = 2, create = gnat },
        ["Lite Drone"] = { strength = 3, create = droneLite },
        ["Jacket Drone"] = { strength = 4, create = droneJacket },
        [ST.KTLITAN_DRONE] = { strength = 4, create = stockTemplate },
        ["Heavy Drone"] = { strength = 5, create = droneHeavy },
        [ST.MT52_HORNET] = { strength = 5, create = stockTemplate },
        [ST.MU52_HORNET] = { strength = 5, create = stockTemplate },
        ["MV52 Hornet"] = { strength = 6, create = hornetMV52 },
        [ST.ADDER_MK3] = { strength = 5, create = stockTemplate },
        [ST.ADDER_MK4] = { strength = 6, create = stockTemplate },
        [ST.FIGHTER] = { strength = 6, create = stockTemplate },
        [ST.KTLITAN_FIGHTER] = { strength = 6, create = stockTemplate },
        ["K2 Fighter"] = { strength = 7, create = k2fighter },
        [ST.ADDER_MK5] = { strength = 7, create = stockTemplate },
        ["WX-Lindworm"] = { strength = 7, create = stockTemplate },
        ["K3 Fighter"] = { strength = 8, create = k3fighter },
        [ST.ADDER_MK6] = { strength = 8, create = stockTemplate },
        [ST.KTLITAN_SCOUT] = { strength = 8, create = stockTemplate },
        ["WZ-Lindworm"] = { strength = 9, create = wzLindworm },
        [ST.ADDER_MK7] = { strength = 9, create = stockTemplate },
        [ST.ADDER_MK8] = { strength = 10, create = stockTemplate },
        [ST.ADDER_MK9] = { strength = 11, create = stockTemplate },
        [ST.NIRVANA_R3] = { strength = 12, create = stockTemplate },
        ["Phobos R2"] = { strength = 13, create = phobosR2 },
        [ST.MISSILE_CRUISER] = { strength = 14, create = stockTemplate },
        ["Waddle 5"] = { strength = 15, create = waddle5 },
        ["Jade 5"] = { strength = 15, create = jade5 },
        [ST.PHOBOS_T3] = { strength = 15, create = stockTemplate },
        [ST.PIRANHA_F8] = { strength = 15, create = stockTemplate },
        [ST.PIRANHA_F12] = { strength = 15, create = stockTemplate },
        [ST.PIRANHA_F12M] = { strength = 16, create = stockTemplate },
        [ST.PHOBOS_M3] = { strength = 16, create = stockTemplate },
        ["Farco 3"] = { strength = 16, create = farco3 },
        ["Farco 5"] = { strength = 16, create = farco5 },
        [ST.KARNACK] = { strength = 17, create = stockTemplate },
        [ST.GUNSHIP] = { strength = 17, create = stockTemplate },
        ["Phobos T4"] = { strength = 18, create = phobosT4 },
        [ST.CRUISER] = { strength = 18, create = stockTemplate },
        [ST.NIRVANA_R5] = { strength = 19, create = stockTemplate },
        ["Farco 8"] = { strength = 19, create = farco8 },
        [ST.NIRVANA_R5A] = { strength = 20, create = stockTemplate },
        [ST.ADV_GUNSHIP] = { strength = 20, create = stockTemplate },
        [ST.KTLITAN_WORKER] = { strength = 21, create = stockTemplate },
        ["Farco 11"] = { strength = 21, create = farco11 },
        [ST.STORM] = { strength = 22, create = stockTemplate },
        [ST.STALKER_R5] = { strength = 22, create = stockTemplate },
        [ST.STALKER_Q5] = { strength = 22, create = stockTemplate },
        ["Farco 13"] = { strength = 24, create = farco13 },
        [ST.RANUS_U] = { strength = 25, create = stockTemplate },
        [ST.STALKER_Q7] = { strength = 25, create = stockTemplate },
        [ST.STALKER_R7] = { strength = 25, create = stockTemplate },
        ["Whirlwind"] = { strength = 26, create = whirlwind },
        [ST.MAGPIE] = { strength = 27, create = stockTemplate },
        [ST.ELARA_P2] = { strength = 28, create = stockTemplate },
        ["Tempest"] = { strength = 30, create = tempest },
        [ST.STRIX] = { strength = 30, create = stockTemplate },
        [ST.FIEND_G3] = { strength = 33, create = stockTemplate },
        ["Maniapak"] = { strength = 34, create = maniapak },
        [ST.FIEND_G4] = { strength = 35, create = stockTemplate },
        ["Cucaracha"] = { strength = 36, create = cucaracha },
        [ST.FIEND_G5] = { strength = 37, create = stockTemplate },
        [ST.FIEND_G6] = { strength = 39, create = stockTemplate },
        ["Barracuda"] = { strength = 40, create = barracuda },
        ["Predator"] = { strength = 42, create = predator },
        [ST.KTLITAN_BREAKER] = { strength = 45, create = stockTemplate },
        ["Hurricane"] = { strength = 46, create = hurricane },
        [ST.KTLITAN_FEEDER] = { strength = 48, create = stockTemplate },
        [ST.ATLANTIS_X23] = { strength = 50, create = stockTemplate },
        ["K2 Breaker"] = { strength = 55, create = k2breaker },
        [ST.KTLITAN_DESTROYER] = { strength = 50, create = stockTemplate },
        ["Atlantis Y42"] = { strength = 60, create = atlantisY42 },
        [ST.BLOCKADE_RUNNER] = { strength = 65, create = stockTemplate },
        [ST.STARHAMMER_II] = { strength = 70, create = stockTemplate },
        ["Enforcer"] = { strength = 75, create = enforcer },
        [ST.DREADNOUGHT] = { strength = 80, create = stockTemplate },
        ["Starhammer III"] = { strength = 85, create = starhammerIII },
        ["Starhammer V"] = { strength = 90, create = starhammerV },
        [ST.BATTLESTATION] = { strength = 100, create = stockTemplate },
        ["Tyr"] = { strength = 150, create = tyr },
        [ST.ODIN] = { strength = 250, create = stockTemplate },
    }
    shipTemplateDistance = {
        [ST.ADDER_MK3] = 100,
        [ST.ADDER_MK4] = 100,
        [ST.ADDER_MK5] = 100,
        [ST.ADDER_MK6] = 100,
        [ST.ADDER_MK7] = 100,
        [ST.ADDER_MK8] = 100,
        [ST.ADDER_MK9] = 100,
        [ST.ADV_GUNSHIP] = 400,
        [ST.MAGPIE] = 300,
        [ST.ATLANTIS_X23] = 400,
        ["Atlantis Y42"] = 400,
        ["Barracuda"] = 200,
        [ST.BATTLESTATION] = 2000,
        [ST.BLOCKADE_RUNNER] = 400,
        [ST.BLADE] = 300,
        [ST.BUSTER] = 100,
        ["Courier"] = 600,
        [ST.CRUISER] = 200,
        ["Cucaracha"] = 200,
        [ST.DAGGER] = 100,
        [ST.DASH] = 200,
        [ST.DEFENSE_PLATFORM] = 800,
        ["Diva"] = 350,
        ["Dread No More"] = 400,
        [ST.DREADNOUGHT] = 400,
        [ST.ELARA_P2] = 200,
        ["Enforcer"] = 400,
        ["Enforcer V2"] = 400,
        [ST.EQUIPMENT_FREIGHTER_1] = 600,
        [ST.EQUIPMENT_FREIGHTER_2] = 600,
        [ST.EQUIPMENT_FREIGHTER_3] = 600,
        [ST.EQUIPMENT_FREIGHTER_4] = 800,
        [ST.EQUIPMENT_FREIGHTER_5] = 800,
        [ST.EQUIPMENT_JUMP_FREIGHTER_3] = 600,
        [ST.EQUIPMENT_JUMP_FREIGHTER_4] = 800,
        [ST.EQUIPMENT_JUMP_FREIGHTER_5] = 800,
        ["Farco 3"] = 200,
        ["Farco 5"] = 200,
        ["Farco 8"] = 200,
        ["Farco 11"] = 200,
        ["Farco 13"] = 200,
        [ST.FIEND_G3] = 400,
        [ST.FIEND_G4] = 400,
        [ST.FIEND_G5] = 400,
        [ST.FIEND_G6] = 400,
        [ST.FIGHTER] = 100,
        [ST.FLASH] = 100,
        [ST.FLAVIA] = 200,
        [ST.FLAVIA_FALCON] = 200,
        [ST.FORTRESS] = 2000,
        [ST.FUEL_FREIGHTER_1] = 600,
        [ST.FUEL_FREIGHTER_2] = 600,
        [ST.FUEL_FREIGHTER_3] = 600,
        [ST.FUEL_FREIGHTER_4] = 800,
        [ST.FUEL_FREIGHTER_5] = 800,
        [ST.FUEL_JUMP_FREIGHTER_3] = 600,
        [ST.FUEL_JUMP_FREIGHTER_4] = 800,
        [ST.FUEL_JUMP_FREIGHTER_5] = 800,
        [ST.GARBAGE_FREIGHTER_1] = 600,
        [ST.GARBAGE_FREIGHTER_2] = 600,
        [ST.GARBAGE_FREIGHTER_3] = 600,
        [ST.GARBAGE_FREIGHTER_4] = 800,
        [ST.GARBAGE_FREIGHTER_5] = 800,
        [ST.GARBAGE_JUMP_FREIGHTER_3] = 600,
        [ST.GARBAGE_JUMP_FREIGHTER_4] = 800,
        [ST.GARBAGE_JUMP_FREIGHTER_5] = 800,
        ["Gnat"] = 300,
        [ST.GOODS_FREIGHTER_1] = 600,
        [ST.GOODS_FREIGHTER_2] = 600,
        [ST.GOODS_FREIGHTER_3] = 600,
        [ST.GOODS_FREIGHTER_4] = 800,
        [ST.GOODS_FREIGHTER_5] = 800,
        [ST.GOODS_JUMP_FREIGHTER_3] = 600,
        [ST.GOODS_JUMP_FREIGHTER_4] = 800,
        [ST.GOODS_JUMP_FREIGHTER_5] = 800,
        [ST.GUARD] = 600, --transport_1_1
        ["Gulper"] = 400,
        [ST.GUNNER] = 100,
        [ST.GUNSHIP] = 400,
        ["Heavy Drone"] = 300,
        [ST.HUNTER] = 200,
        ["Jacket Drone"] = 300,
        ["Jade 5"] = 100,
        [ST.JAGGER] = 100,
        ["Jump Carrier"] = 800,
        [ST.KARNACK] = 200,
        ["K2 Fighter"] = 300,
        ["K3 Fighter"] = 300,
        [ST.KTLITAN_BREAKER] = 300,
        [ST.KTLITAN_DESTROYER] = 500,
        [ST.KTLITAN_DRONE] = 300,
        [ST.KTLITAN_FEEDER] = 300,
        [ST.KTLITAN_FIGHTER] = 300,
        [ST.KTLITAN_QUEEN] = 500,
        [ST.KTLITAN_SCOUT] = 300,
        [ST.KTLITAN_WORKER] = 300,
        ["Laden Lorry"] = 600,
        ["Lite Drone"] = 300,
        ["Loki"] = 1500,
        ["Maniapak"] = 100,
        [ST.MISSILE_CRUISER] = 200,
        [ST.MT52_HORNET] = 100,
        ["MT55 Hornet"] = 100,
        [ST.MU52_HORNET] = 100,
        ["MU55 Hornet"] = 100,
        ["Munemi"] = 100,
        ["MV52 Hornet"] = 100,
        [ST.NIRVANA_R3] = 200,
        [ST.NIRVANA_R5] = 200,
        [ST.NIRVANA_R5A] = 200,
        [ST.ODIN] = 1500,
        ["Omnibus"] = 800,
        [ST.PERSONNEL_FREIGHTER_1] = 600,
        [ST.PERSONNEL_FREIGHTER_2] = 600,
        [ST.PERSONNEL_FREIGHTER_3] = 600,
        [ST.PERSONNEL_FREIGHTER_4] = 800,
        [ST.PERSONNEL_FREIGHTER_5] = 800,
        [ST.PERSONNEL_JUMP_FREIGHTER_3] = 600,
        [ST.PERSONNEL_JUMP_FREIGHTER_4] = 800,
        [ST.PERSONNEL_JUMP_FREIGHTER_5] = 800,
        [ST.PHOBOS_M3] = 200,
        ["Phobos R2"] = 200,
        [ST.PHOBOS_T3] = 200,
        ["Phobos T4"] = 200,
        ["Physics Research"] = 600,
        ["Piranha F10"] = 200,
        [ST.PIRANHA_F12] = 200,
        [ST.PIRANHA_F12M] = 200,
        [ST.PIRANHA_F8] = 200,
        ["Prador"] = 2000,
        ["Predator"] = 200,
        ["Predator V2"] = 200,
        [ST.RACER] = 200,
        [ST.RANGER] = 100,
        [ST.RANUS_U] = 200,
        ["Roc"] = 200,
        [ST.RYDER] = 2000,
        [ST.SENTINEL] = 600,
        ["Service Jonque"] = 800,
        [ST.SHOOTER] = 100,
        ["Sloop"] = 200,
        ["Space Sedan"] = 600,
        [ST.STALKER_Q5] = 200,
        [ST.STALKER_Q7] = 200,
        [ST.STALKER_R5] = 200,
        [ST.STALKER_R7] = 200,
        [ST.STARHAMMER_II] = 400,
        ["Starhammer V"] = 400,
        [ST.STORM] = 200,
        [ST.STRIKE] = 200,
        [ST.STRIX] = 200,
        ["Tempest"] = 200,
        [ST.TRANSPORT1X1] = 600,
        [ST.TRANSPORT1X2] = 600,
        [ST.TRANSPORT1X3] = 600,
        [ST.TRANSPORT1X4] = 800,
        [ST.TRANSPORT1X5] = 800,
        [ST.TRANSPORT2X1] = 600,
        [ST.TRANSPORT2X2] = 600,
        [ST.TRANSPORT2X3] = 600,
        [ST.TRANSPORT2X4] = 800,
        [ST.TRANSPORT2X5] = 800,
        [ST.TRANSPORT3X1] = 600,
        [ST.TRANSPORT3X2] = 600,
        [ST.TRANSPORT3X3] = 600,
        [ST.TRANSPORT3X4] = 800,
        [ST.TRANSPORT3X5] = 800,
        [ST.TRANSPORT4X1] = 600,
        [ST.TRANSPORT4X2] = 600,
        [ST.TRANSPORT4X3] = 600,
        [ST.TRANSPORT4X4] = 800,
        [ST.TRANSPORT4X5] = 800,
        [ST.TRANSPORT5X1] = 600,
        [ST.TRANSPORT5X2] = 600,
        [ST.TRANSPORT5X3] = 600,
        [ST.TRANSPORT5X4] = 800,
        [ST.TRANSPORT5X5] = 800,
        [ST.APIS] = 200,
        ["Tyr"] = 2000,
        ["Waddle 5"] = 100,
        [ST.WARDEN] = 600,
        [ST.WEAPONS_PLATFORM] = 200,
        ["Work Wagon"] = 600,
        ["WX-Lindworm"] = 100,
        ["WZ-Lindworm"] = 100,
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
    max_pyramid_tier = 15
    playerShipStats =
        { --taken from sandbox. Not all are used. Not all characteristics are used.
            [ST.ATLANTIS] = {
                strength = 52,
                cargo = 6,
                distance = 400,
                long_range_radar = 30000,
                short_range_radar = 5000,
                tractor = true,
                mining = true,
                probes = 10,
                pods = 2,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Atlantis MK2"] = {
                strength = 55,
                cargo = 6,
                distance = 400,
                long_range_radar = 30000,
                short_range_radar = 5000,
                tractor = true,
                mining = true,
                probes = 10,
                pods = 2,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Corsair"] = {
                strength = 50,
                cargo = 6,
                distance = 400,
                long_range_radar = 30000,
                short_range_radar = 5000,
                tractor = true,
                mining = true,
                probes = 10,
                pods = 2,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            [ST.BENEDICT] = {
                strength = 10,
                cargo = 9,
                distance = 400,
                long_range_radar = 30000,
                short_range_radar = 5000,
                tractor = true,
                mining = true,
                probes = 10,
                pods = 3,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            [ST.CRUCIBLE] = {
                strength = 45,
                cargo = 5,
                distance = 200,
                long_range_radar = 20000,
                short_range_radar = 6000,
                tractor = false,
                mining = false,
                probes = 9,
                pods = 1,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 1,
                epjam = 0,
            },
            [ST.ENDER] = {
                strength = 100,
                cargo = 20,
                distance = 2000,
                long_range_radar = 45000,
                short_range_radar = 7000,
                tractor = true,
                mining = false,
                probes = 12,
                pods = 6,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 2,
                epjam = 0,
            },
            [ST.FLAVIA_PFALCON] = {
                strength = 13,
                cargo = 15,
                distance = 200,
                long_range_radar = 40000,
                short_range_radar = 5000,
                tractor = true,
                mining = true,
                probes = 8,
                pods = 4,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            [ST.HATHCOCK] = {
                strength = 30,
                cargo = 6,
                distance = 200,
                long_range_radar = 35000,
                short_range_radar = 6000,
                tractor = false,
                mining = true,
                probes = 8,
                pods = 2,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 1,
                epjam = 0,
            },
            [ST.KIRIYA] = {
                strength = 10,
                cargo = 9,
                distance = 400,
                long_range_radar = 35000,
                short_range_radar = 5000,
                tractor = true,
                mining = true,
                probes = 10,
                pods = 3,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            [ST.MAVERICK] = {
                strength = 45,
                cargo = 5,
                distance = 200,
                long_range_radar = 20000,
                short_range_radar = 4000,
                tractor = false,
                mining = true,
                probes = 9,
                pods = 1,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            [ST.MP52_HORNET] = {
                strength = 7,
                cargo = 3,
                distance = 100,
                long_range_radar = 18000,
                short_range_radar = 4000,
                tractor = false,
                mining = false,
                probes = 5,
                pods = 1,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            [ST.NAUTILUS] = {
                strength = 12,
                cargo = 7,
                distance = 200,
                long_range_radar = 22000,
                short_range_radar = 4000,
                tractor = false,
                mining = false,
                probes = 10,
                pods = 2,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            [ST.PHOBOS_M3P] = {
                strength = 19,
                cargo = 10,
                distance = 200,
                long_range_radar = 25000,
                short_range_radar = 5000,
                tractor = true,
                mining = false,
                probes = 6,
                pods = 3,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            [ST.PIRANHA] = {
                strength = 16,
                cargo = 8,
                distance = 200,
                long_range_radar = 25000,
                short_range_radar = 6000,
                tractor = false,
                mining = false,
                probes = 6,
                pods = 2,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 1,
                epjam = 0,
            },
            [ST.VINDICATOR] = {
                strength = 40,
                cargo = 6,
                distance = 400,
                long_range_radar = 30000,
                short_range_radar = 5000,
                tractor = false,
                mining = false,
                probes = 10,
                pods = 2,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            [ST.AVALANCHE] = {
                strength = 45,
                cargo = 8,
                distance = 200,
                long_range_radar = 35000,
                short_range_radar = 6000,
                tractor = false,
                mining = false,
                probes = 9,
                pods = 2,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 1,
                epjam = 0,
            },
            [ST.STINGRAY] = {
                strength = 7,
                cargo = 3,
                distance = 100,
                long_range_radar = 15000,
                short_range_radar = 4500,
                tractor = false,
                mining = false,
                probes = 4,
                pods = 1,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            [ST.REPULSE] = {
                strength = 14,
                cargo = 12,
                distance = 200,
                long_range_radar = 38000,
                short_range_radar = 5000,
                tractor = true,
                mining = false,
                probes = 8,
                pods = 5,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            [ST.CROW] = {
                strength = 8,
                cargo = 4,
                distance = 200,
                long_range_radar = 35000,
                short_range_radar = 5000,
                tractor = false,
                mining = false,
                probes = 6,
                pods = 1,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["ZX-Lindworm"] = {
                strength = 8,
                cargo = 3,
                distance = 100,
                long_range_radar = 18000,
                short_range_radar = 5500,
                tractor = false,
                mining = false,
                probes = 4,
                pods = 1,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 1,
                epjam = 0,
            },
            -- Custom player ships
            ["Amalgam"] = {
                strength = 42,
                cargo = 7,
                distance = 400,
                long_range_radar = 36000,
                short_range_radar = 5000,
                tractor = false,
                mining = false,
                probes = 11,
                pods = 3,
                turbo_torp = true,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Atlantis II"] = {
                strength = 60,
                cargo = 6,
                distance = 400,
                long_range_radar = 30000,
                short_range_radar = 5000,
                tractor = true,
                mining = true,
                probes = 11,
                pods = 3,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Barrow"] = {
                strength = 9,
                cargo = 9,
                distance = 400,
                long_range_radar = 35000,
                short_range_radar = 5000,
                tractor = true,
                mining = true,
                probes = 12,
                pods = 3,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 2,
            },
            ["Bermuda"] = {
                strength = 30,
                cargo = 4,
                distance = 400,
                long_range_radar = 30000,
                short_range_radar = 4500,
                tractor = true,
                mining = false,
                probes = 14,
                pods = 3,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Butler"] = {
                strength = 20,
                cargo = 6,
                distance = 200,
                long_range_radar = 30000,
                short_range_radar = 5500,
                tractor = true,
                mining = false,
                probes = 8,
                pods = 2,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Caretaker"] = {
                strength = 23,
                cargo = 6,
                distance = 200,
                long_range_radar = 35000,
                short_range_radar = 5000,
                tractor = true,
                mining = false,
                probes = 9,
                pods = 2,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Chavez"] = {
                strength = 21,
                cargo = 6,
                distance = 200,
                long_range_radar = 25000,
                short_range_radar = 5000,
                tractor = true,
                mining = true,
                probes = 8,
                pods = 2,
                turbo_torp = false,
                patrol_probe = 2.5,
                prox_scan = 0,
                epjam = 1,
            },
            ["Crab"] = {
                strength = 20,
                cargo = 6,
                distance = 200,
                long_range_radar = 30000,
                short_range_radar = 5500,
                tractor = false,
                mining = true,
                probes = 13,
                pods = 1,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Destroyer III"] = {
                strength = 25,
                cargo = 7,
                distance = 200,
                long_range_radar = 32000,
                short_range_radar = 5000,
                tractor = false,
                mining = false,
                probes = 8,
                pods = 2,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Destroyer IV"] = {
                strength = 22,
                cargo = 5,
                distance = 400,
                long_range_radar = 30000,
                short_range_radar = 5000,
                tractor = false,
                mining = true,
                probes = 8,
                pods = 1,
                turbo_torp = true,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Eldridge"] = {
                strength = 20,
                cargo = 7,
                distance = 200,
                long_range_radar = 24000,
                short_range_radar = 8000,
                tractor = false,
                mining = true,
                probes = 10,
                pods = 2,
                turbo_torp = false,
                patrol_probe = 3,
                prox_scan = 3,
                epjam = 0,
            },
            ["Era"] = {
                strength = 14,
                cargo = 14,
                distance = 200,
                long_range_radar = 50000,
                short_range_radar = 5000,
                tractor = true,
                mining = true,
                probes = 8,
                pods = 4,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 9,
                epjam = 3,
            },
            ["Flavia 2C"] = {
                strength = 25,
                cargo = 12,
                distance = 200,
                long_range_radar = 30000,
                short_range_radar = 5000,
                tractor = false,
                mining = true,
                probes = 9,
                pods = 3,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Focus"] = {
                strength = 35,
                cargo = 4,
                distance = 200,
                long_range_radar = 32000,
                short_range_radar = 5000,
                tractor = false,
                mining = true,
                probes = 8,
                pods = 1,
                turbo_torp = true,
                patrol_probe = 1.25,
                prox_scan = 0,
                epjam = 0,
            },
            ["Fowl"] = {
                strength = 8,
                cargo = 3,
                distance = 100,
                long_range_radar = 15000,
                short_range_radar = 4500,
                tractor = false,
                mining = false,
                probes = 4,
                pods = 1,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 3,
            },
            ["Fray"] = {
                strength = 22,
                cargo = 5,
                distance = 200,
                long_range_radar = 23000,
                short_range_radar = 4500,
                tractor = true,
                mining = false,
                probes = 7,
                pods = 1,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Fresnel"] = {
                strength = 8,
                cargo = 3,
                distance = 100,
                long_range_radar = 15000,
                short_range_radar = 4500,
                tractor = false,
                mining = false,
                probes = 4,
                pods = 1,
                turbo_torp = true,
                patrol_probe = 0,
                prox_scan = 9,
                epjam = 0,
            },
            ["Gadfly"] = {
                strength = 9,
                cargo = 3,
                distance = 100,
                long_range_radar = 15000,
                short_range_radar = 4500,
                tractor = false,
                mining = false,
                probes = 4,
                pods = 1,
                turbo_torp = false,
                patrol_probe = 3.6,
                prox_scan = 9,
                epjam = 0,
            },
            ["Glass Cannon"] = {
                strength = 15,
                cargo = 3,
                distance = 100,
                long_range_radar = 30000,
                short_range_radar = 5000,
                tractor = false,
                mining = false,
                probes = 8,
                pods = 1,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Gull"] = {
                strength = 14,
                cargo = 14,
                distance = 200,
                long_range_radar = 40000,
                short_range_radar = 5000,
                tractor = true,
                mining = true,
                probes = 8,
                pods = 4,
                turbo_torp = false,
                patrol_probe = 4,
                prox_scan = 0,
                epjam = 0,
            },
            ["Holmes"] = {
                strength = 35,
                cargo = 6,
                distance = 200,
                long_range_radar = 35000,
                short_range_radar = 4000,
                tractor = true,
                mining = false,
                probes = 8,
                pods = 2,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Interlock"] = {
                strength = 19,
                cargo = 12,
                distance = 200,
                long_range_radar = 35000,
                short_range_radar = 5500,
                tractor = false,
                mining = true,
                probes = 13,
                pods = 3,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 1,
                epjam = 0,
            },
            ["Kludge"] = {
                strength = 22,
                cargo = 9,
                distance = 200,
                long_range_radar = 35000,
                short_range_radar = 3500,
                tractor = false,
                mining = true,
                probes = 20,
                pods = 5,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Lurker"] = {
                strength = 18,
                cargo = 3,
                distance = 100,
                long_range_radar = 21000,
                short_range_radar = 6000,
                tractor = false,
                mining = false,
                probes = 4,
                pods = 1,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 1,
                epjam = 0,
            },
            ["Mantis"] = {
                strength = 30,
                cargo = 8,
                distance = 200,
                long_range_radar = 25000,
                short_range_radar = 6000,
                tractor = false,
                mining = false,
                probes = 9,
                pods = 2,
                turbo_torp = true,
                patrol_probe = 0,
                prox_scan = 1,
                epjam = 0,
            },
            ["Maverick XP"] = {
                strength = 23,
                cargo = 5,
                distance = 200,
                long_range_radar = 25000,
                short_range_radar = 7000,
                tractor = true,
                mining = false,
                probes = 10,
                pods = 1,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 2,
                epjam = 0,
            },
            ["Midian"] = {
                strength = 30,
                cargo = 9,
                distance = 200,
                long_range_radar = 25000,
                short_range_radar = 5500,
                tractor = false,
                mining = false,
                probes = 9,
                pods = 3,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["MX-Lindworm"] = {
                strength = 10,
                cargo = 3,
                distance = 100,
                long_range_radar = 30000,
                short_range_radar = 6000,
                tractor = false,
                mining = false,
                probes = 5,
                pods = 1,
                turbo_torp = false,
                patrol_probe = 3,
                prox_scan = 9,
                epjam = 0,
            },
            ["Noble"] = {
                strength = 33,
                cargo = 6,
                distance = 400,
                long_range_radar = 27000,
                short_range_radar = 5000,
                tractor = true,
                mining = false,
                probes = 8,
                pods = 2,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Nusret"] = {
                strength = 16,
                cargo = 7,
                distance = 200,
                long_range_radar = 25000,
                short_range_radar = 4000,
                tractor = false,
                mining = true,
                probes = 10,
                pods = 1,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 3,
            },
            ["Orca"] = {
                strength = 19,
                cargo = 6,
                distance = 200,
                long_range_radar = 25000,
                short_range_radar = 5000,
                tractor = true,
                mining = false,
                probes = 6,
                pods = 3,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 1,
                epjam = 1,
            },
            ["Pacu"] = {
                strength = 18,
                cargo = 7,
                distance = 200,
                long_range_radar = 20000,
                short_range_radar = 6000,
                tractor = false,
                mining = false,
                probes = 6,
                pods = 2,
                turbo_torp = false,
                patrol_probe = 2.5,
                prox_scan = 1,
                epjam = 0,
            },
            ["Peacock"] = {
                strength = 30,
                cargo = 9,
                distance = 400,
                long_range_radar = 25000,
                short_range_radar = 5000,
                tractor = false,
                mining = true,
                probes = 10,
                pods = 3,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Phargus"] = {
                strength = 15,
                cargo = 6,
                distance = 200,
                long_range_radar = 20000,
                short_range_radar = 5500,
                tractor = false,
                mining = false,
                probes = 6,
                pods = 2,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Phobos T2"] = {
                strength = 19,
                cargo = 9,
                distance = 200,
                long_range_radar = 25000,
                short_range_radar = 5000,
                tractor = true,
                mining = false,
                probes = 5,
                pods = 3,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Phobos T2.2"] = {
                strength = 19,
                cargo = 9,
                distance = 200,
                long_range_radar = 25000,
                short_range_radar = 5000,
                tractor = true,
                mining = false,
                probes = 5,
                pods = 3,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Phoenix"] = {
                strength = 40,
                cargo = 6,
                distance = 400,
                long_range_radar = 25000,
                short_range_radar = 5000,
                tractor = true,
                mining = false,
                probes = 6,
                pods = 2,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Porcupine"] = {
                strength = 30,
                cargo = 6,
                distance = 400,
                long_range_radar = 25000,
                short_range_radar = 5000,
                tractor = false,
                mining = false,
                probes = 10,
                pods = 2,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Proto-Atlantis"] = {
                strength = 40,
                cargo = 4,
                distance = 400,
                long_range_radar = 30000,
                short_range_radar = 4500,
                tractor = false,
                mining = true,
                probes = 8,
                pods = 1,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Proto-Atlantis 2"] = {
                strength = 40,
                cargo = 4,
                distance = 400,
                long_range_radar = 30000,
                short_range_radar = 4500,
                tractor = false,
                mining = true,
                probes = 8,
                pods = 1,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Raven"] = {
                strength = 30,
                cargo = 5,
                distance = 400,
                long_range_radar = 25000,
                short_range_radar = 6000,
                tractor = true,
                mining = false,
                probes = 7,
                pods = 2,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 1,
                epjam = 0,
            },
            ["Redhook"] = {
                strength = 12,
                cargo = 8,
                distance = 200,
                long_range_radar = 20000,
                short_range_radar = 6000,
                tractor = false,
                mining = false,
                probes = 6,
                pods = 2,
                turbo_torp = false,
                patrol_probe = 2.5,
                prox_scan = 9,
                epjam = 0,
            },
            ["Roc"] = {
                strength = 25,
                cargo = 6,
                distance = 200,
                long_range_radar = 25000,
                short_range_radar = 5000,
                tractor = true,
                mining = false,
                probes = 6,
                pods = 3,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 1,
                epjam = 1,
            },
            ["Rodent"] = {
                strength = 23,
                cargo = 8,
                distance = 200,
                long_range_radar = 40000,
                short_range_radar = 5500,
                tractor = false,
                mining = false,
                probes = 9,
                pods = 3,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 1,
                epjam = 0,
            },
            ["Rook"] = {
                strength = 15,
                cargo = 12,
                distance = 200,
                long_range_radar = 41000,
                short_range_radar = 5500,
                tractor = false,
                mining = true,
                probes = 13,
                pods = 3,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 1,
                epjam = 0,
            },
            ["Rotor"] = {
                strength = 35,
                cargo = 5,
                distance = 200,
                long_range_radar = 25000,
                short_range_radar = 4000,
                tractor = true,
                mining = false,
                probes = 10,
                pods = 2,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Safari"] = {
                strength = 15,
                cargo = 10,
                distance = 200,
                long_range_radar = 33000,
                short_range_radar = 4500,
                tractor = true,
                mining = false,
                probes = 9,
                pods = 3,
                turbo_torp = false,
                patrol_probe = 3.5,
                prox_scan = 0,
                epjam = 0,
            },
            ["Scatter"] = {
                strength = 30,
                cargo = 6,
                distance = 200,
                long_range_radar = 28000,
                short_range_radar = 5000,
                tractor = false,
                mining = true,
                probes = 8,
                pods = 1,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Skray"] = {
                strength = 15,
                cargo = 3,
                distance = 200,
                long_range_radar = 30000,
                short_range_radar = 7500,
                tractor = false,
                mining = false,
                probes = 25,
                pods = 1,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 3,
                epjam = 0,
            },
            ["Sloop"] = {
                strength = 20,
                cargo = 8,
                distance = 200,
                long_range_radar = 35000,
                short_range_radar = 4500,
                tractor = true,
                mining = true,
                probes = 9,
                pods = 2,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 2,
                epjam = 2,
            },
            ["Squid"] = {
                strength = 14,
                cargo = 8,
                distance = 200,
                long_range_radar = 25000,
                short_range_radar = 5000,
                tractor = false,
                mining = false,
                probes = 7,
                pods = 2,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 9,
                epjam = 0,
            },
            ["Striker LX"] = {
                strength = 16,
                cargo = 4,
                distance = 200,
                long_range_radar = 20000,
                short_range_radar = 4000,
                tractor = false,
                mining = false,
                probes = 7,
                pods = 1,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Surkov"] = {
                strength = 35,
                cargo = 6,
                distance = 200,
                long_range_radar = 35000,
                short_range_radar = 6000,
                tractor = false,
                mining = false,
                probes = 8,
                pods = 2,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 1,
                epjam = 0,
            },
            ["Twister"] = {
                strength = 30,
                cargo = 6,
                distance = 200,
                long_range_radar = 23000,
                short_range_radar = 5500,
                tractor = false,
                mining = true,
                probes = 15,
                pods = 2,
                turbo_torp = false,
                patrol_probe = 3,
                prox_scan = 1,
                epjam = 0,
            },
            ["Torch"] = {
                strength = 9,
                cargo = 3,
                distance = 100,
                long_range_radar = 15000,
                short_range_radar = 4000,
                tractor = false,
                mining = false,
                probes = 4,
                pods = 1,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Vermin"] = {
                strength = 10,
                cargo = 3,
                distance = 100,
                long_range_radar = 22000,
                short_range_radar = 4000,
                tractor = false,
                mining = true,
                probes = 4,
                pods = 1,
                turbo_torp = false,
                patrol_probe = 3.6,
                prox_scan = 0,
                epjam = 1,
            },
            ["Windmill"] = {
                strength = 19,
                cargo = 11,
                distance = 200,
                long_range_radar = 33000,
                short_range_radar = 5000,
                tractor = false,
                mining = true,
                probes = 8,
                pods = 4,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 0,
                epjam = 0,
            },
            ["Wombat"] = {
                strength = 18,
                cargo = 3,
                distance = 100,
                long_range_radar = 18000,
                short_range_radar = 6000,
                tractor = false,
                mining = false,
                probes = 5,
                pods = 1,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 1,
                epjam = 2,
            },
            ["Wrocket"] = {
                strength = 19,
                cargo = 8,
                distance = 200,
                long_range_radar = 32000,
                short_range_radar = 5500,
                tractor = false,
                mining = false,
                probes = 10,
                pods = 2,
                turbo_torp = false,
                patrol_probe = 0,
                prox_scan = 1,
                epjam = 0,
            },
            ["XR-Lindworm"] = {
                strength = 12,
                cargo = 3,
                distance = 100,
                long_range_radar = 20000,
                short_range_radar = 6000,
                tractor = false,
                mining = false,
                probes = 5,
                pods = 1,
                turbo_torp = false,
                patrol_probe = 3.9,
                prox_scan = 9,
                epjam = 0,
            },
        }
    commonGoods = defaults.goods().commonGoods
    componentGoods = defaults.goods().componentGoods
    mineralGoods = defaults.goods().mineralGoods
    vapor_goods =
        { "gold pressed latinum", "unobtanium", "eludium", "impossibrium" }
    good_desc = {
        ["food"] = _("trade-comms", "food"),
        ["medicine"] = _("trade-comms", "medicine"),
        ["luxury"] = _("trade-comms", "luxury"),
        ["cobalt"] = _("trade-comms", "cobalt"),
        ["dilithium"] = _("trade-comms", "dilithium"),
        ["gold"] = _("trade-comms", "gold"),
        ["nickel"] = _("trade-comms", "nickel"),
        ["platinum"] = _("trade-comms", "platinum"),
        ["tritanium"] = _("trade-comms", "tritanium"),
        ["autodoc"] = _("trade-comms", "autodoc"),
        ["android"] = _("trade-comms", "android"),
        ["battery"] = _("trade-comms", "battery"),
        ["beam"] = _("trade-comms", "beam"),
        ["circuit"] = _("trade-comms", "circuit"),
        ["communication"] = _("trade-comms", "communication"),
        ["filament"] = _("trade-comms", "filament"),
        ["impulse"] = _("trade-comms", "impulse"),
        ["lifter"] = _("trade-comms", "lifter"),
        ["nanites"] = _("trade-comms", "nanites"),
        ["optic"] = _("trade-comms", "optic"),
        ["repulsor"] = _("trade-comms", "repulsor"),
        ["robotic"] = _("trade-comms", "robotic"),
        ["sensor"] = _("trade-comms", "sensor"),
        ["shield"] = _("trade-comms", "shield"),
        ["software"] = _("trade-comms", "software"),
        ["tractor"] = _("trade-comms", "tractor"),
        ["transporter"] = _("trade-comms", "transporter"),
        ["warp"] = _("trade-comms", "warp"),
        ["gold pressed latinum"] = _("trade-comms", "gold pressed latinum"),
        ["unobtanium"] = _("trade-comms", "unobtanium"),
        ["eludium"] = _("trade-comms", "eludium"),
        ["impossibrium"] = _("trade-comms", "impossibrium"),
    }
    artifact_counter = 0
    artifact_number = 0
    sensor_impact = 1 --normal
    sensor_jammer_list = {}
    sensor_jammer_range = 60000
    sensor_jammer_impact = 40000
    sensor_jammer_scan_complexity = 3
    sensor_jammer_scan_depth = 3
    sensor_jammer_power_units = true --false means percentage, true is units
    continuous_spawn_diagnostic = true
    --pace: number of seconds between launching from each station in the pool
    --respite: number of seconds before the next round of launches begins
    spawn_intervals = {
        { pace = 5, respite = 150 },
        { pace = 12, respite = 120 },
        { pace = 25, respite = 100 },
        { pace = 15, respite = 250 },
        { pace = 35, respite = 150 },
        { pace = 10, respite = 180 },
    }
    spawn_interval_index = 0
    spawn_variance = 10
    spawn_source_pool = {}
    target_station_pool = {}
    clarifyExistingScience()
    approached_devourer = false
end
-- Game Master functions --
setGMButtons = Runtime.setGMButtons
function mainGMButtons()
    clearGMFunctions()
    addGMFunction(
        string.format(_("buttonGM", "Version %s"), scenario_version),
        function()
            local version_message = string.format(
                _("msgGM", "Scenario version %s\n LUA version %s"),
                scenario_version,
                _VERSION
            )
            addGMMessage(version_message)
        end
    )
    addGMFunction(_("buttonGM", "+Station Reports"), stationReports)
end
function mainGMButtonsDuringPause()
    clearGMFunctions()
    addGMFunction(
        string.format(_("buttonGM", "Version %s"), scenario_version),
        function()
            local version_message = string.format(
                _("msgGM", "Scenario version %s\n LUA version %s"),
                scenario_version,
                _VERSION
            )
            addGMMessage(version_message)
        end
    )
    addGMFunction(_("buttonGM", "+Station Reports"), stationReports)
    addGMFunction(_("buttonGM", "+Difficulty"), setDifficulty)
    addGMFunction(_("buttonGM", "+Enemy Power"), setEnemyPower)
    addGMFunction(_("buttonGM", "+Reputation"), setInitialReputation)
end
function mainGMButtonsAfterPause()
    clearGMFunctions()
    addGMFunction(
        string.format(_("buttonGM", "Version %s"), scenario_version),
        function()
            local version_message = string.format(
                _("msgGM", "Scenario version %s\n LUA version %s"),
                scenario_version,
                _VERSION
            )
            addGMMessage(version_message)
        end
    )
    addGMFunction(_("buttonGM", "+Station Reports"), stationReports)
    addGMFunction(_("buttonGM", "Nerf Devourer"), nerfDevourer)
    addGMFunction(_("buttonGM", "Un-nerf Devourer"), function()
        --  Arc, Dir, Range, Cycle, Damage
        devourer:setBeamWeapon(0, 90, 0, 3200, 3, 10)
        devourer:setBeamWeapon(1, 90, 22.5, 3200, 3, 10)
        devourer:setBeamWeapon(2, 90, 45, 3200, 3, 10)
        devourer:setBeamWeapon(3, 90, 67.5, 3200, 3, 10)
        devourer:setTubeLoadTime(0, 3)
        devourer:setTubeLoadTime(1, 3)
        devourer:setTubeLoadTime(2, 3)
    end)
    addGMFunction(_("buttonGM", "Protector End"), enforcerEnd)
end
function stationReports()
    clearGMFunctions()
    addGMFunction(_("buttonGM", "-Main"), mainGMButtons)
    if station_list ~= nil and #station_list > 0 then
        local applicable_station_count = 0
        for index, station in ipairs(station_list) do
            if
                station ~= nil
                and station:isValid()
                and station.comms_data ~= nil
            then
                local tpa = Artifact():setFaction(player_faction)
                if station:isFriendly(tpa) or not station:isEnemy(tpa) then
                    applicable_station_count = applicable_station_count + 1
                    addGMFunction(
                        string.format(
                            _("stationReport-msgGM", "%s %s"),
                            station:getCallSign(),
                            station:getSectorName()
                        ),
                        function()
                            local out = string.format(
                                _(
                                    "stationReport-msgGM",
                                    "%s %s  %s  %s  Friendliness:%s"
                                ),
                                station:getSectorName(),
                                station:getCallSign(),
                                station:getTypeName(),
                                station:getFaction(),
                                station.comms_data.friendlyness
                            )
                            out = string.format(
                                _(
                                    "stationReport-msgGM",
                                    "%s\nShares Energy: %s,  Repairs Hull: %s,  Restocks Scan Probes: %s"
                                ),
                                out,
                                station:getSharesEnergyWithDocked(),
                                station:getRepairDocked(),
                                station:getRestocksScanProbes()
                            )
                            out = string.format(
                                _(
                                    "stationReport-msgGM",
                                    "%s\nFix Probes: %s,  Fix Hack: %s,  Fix Scan: %s,  Fix Combat Maneuver: %s,  Fix Destruct: %s, Fix Slow Tube: %s"
                                ),
                                out,
                                station.comms_data.probe_launch_repair,
                                station.comms_data.hack_repair,
                                station.comms_data.scan_repair,
                                station.comms_data.combat_maneuver_repair,
                                station.comms_data.self_destruct_repair,
                                station.comms_data.self_destruct_repair,
                                station.comms_data.tube_slow_down_repair
                            )
                            if station.comms_data.weapon_cost == nil then
                                station.comms_data.weapon_cost = {
                                    Homing = math.random(1, 4),
                                    HVLI = math.random(1, 3),
                                    Mine = math.random(2, 5),
                                    Nuke = math.random(12, 18),
                                    EMP = math.random(7, 13),
                                }
                            else
                                if
                                    station.comms_data.weapon_cost.Homing == nil
                                then
                                    station.comms_data.weapon_cost.Homing =
                                        math.random(1, 4)
                                end
                                if
                                    station.comms_data.weapon_cost.HVLI == nil
                                then
                                    station.comms_data.weapon_cost.HVLI =
                                        math.random(1, 3)
                                end
                                if
                                    station.comms_data.weapon_cost.Nuke == nil
                                then
                                    station.comms_data.weapon_cost.Nuke =
                                        math.random(12, 18)
                                end
                                if
                                    station.comms_data.weapon_cost.Mine == nil
                                then
                                    station.comms_data.weapon_cost.Mine =
                                        math.random(2, 5)
                                end
                                if
                                    station.comms_data.weapon_cost.EMP == nil
                                then
                                    station.comms_data.weapon_cost.EMP =
                                        math.random(7, 13)
                                end
                            end
                            out = string.format(
                                _(
                                    "stationReport-msgGM",
                                    "%s\nHoming: %s %s,   Nuke: %s %s,   Mine: %s %s,   EMP: %s %s,   HVLI: %s %s"
                                ),
                                out,
                                station.comms_data.weapon_available.Homing,
                                station.comms_data.weapon_cost.Homing,
                                station.comms_data.weapon_available.Nuke,
                                station.comms_data.weapon_cost.Nuke,
                                station.comms_data.weapon_available.Mine,
                                station.comms_data.weapon_cost.Mine,
                                station.comms_data.weapon_available.EMP,
                                station.comms_data.weapon_cost.EMP,
                                station.comms_data.weapon_available.HVLI,
                                station.comms_data.weapon_cost.HVLI
                            )
                            -- out = string.format(_("stationReport-msgGM", "%s\n      Cost multipliers and Max Refill:   Friend: %.1f %.1f,   Neutral: %.1f %.1f"),out,station.comms_data.reputation_cost_multipliers.friend,station.comms_data.max_weapon_refill_amount.friend,station.comms_data.reputation_cost_multipliers.neutral,station.comms_data.max_weapon_refill_amount.neutral)
                            out = string.format(
                                _(
                                    "stationReport-msgGM",
                                    "%s\nServices and their costs and availability:"
                                ),
                                out
                            )
                            for service, cost in
                                pairs(station.comms_data.service_cost)
                            do
                                out = string.format(
                                    _("stationReport-msgGM", "%s\n      %s: %s"),
                                    out,
                                    service,
                                    cost
                                )
                                -- out = string.format(_("stationReport-msgGM", "%s\n      %s: %s %s"),out,service,cost,station.comms_data.service_available[service])
                            end
                            if station.comms_data.jump_overcharge then
                                out = string.format(
                                    _(
                                        "stationReport-msgGM",
                                        "%s\n      jump overcharge: 10"
                                    ),
                                    out
                                )
                            end
                            if station.comms_data.upgrade_path ~= nil then
                                out = string.format(
                                    _(
                                        "stationReport-msgGM",
                                        "%s\nUpgrade paths for player ship types and their max level:"
                                    ),
                                    out
                                )
                                for ship_type, upgrade in
                                    pairs(station.comms_data.upgrade_path)
                                do
                                    out = string.format(
                                        _(
                                            "stationReport-msgGM",
                                            "%s\n      Ship template type: %s"
                                        ),
                                        out,
                                        ship_type
                                    )
                                    for upgrade_type, max_level in
                                        pairs(upgrade)
                                    do
                                        out = string.format(
                                            _(
                                                "stationReport-msgGM",
                                                "%s\n            %s: %s"
                                            ),
                                            out,
                                            upgrade_type,
                                            max_level
                                        )
                                    end
                                end
                            end
                            if
                                station.comms_data.goods ~= nil
                                or station.comms_data.trade ~= nil
                                or station.comms_data.buy ~= nil
                            then
                                out = string.format(
                                    _("stationReport-msgGM", "%s\nGoods:"),
                                    out
                                )
                                if station.comms_data.goods ~= nil then
                                    out = string.format(
                                        _(
                                            "stationReport-msgGM",
                                            "%s\n    Sell:"
                                        ),
                                        out
                                    )
                                    for good, good_detail in
                                        pairs(station.comms_data.goods)
                                    do
                                        out = string.format(
                                            _(
                                                "stationReport-msgGM",
                                                "%s\n        %s: Cost:%s   Quantity:%s"
                                            ),
                                            out,
                                            good,
                                            good_detail.cost,
                                            good_detail.quantity
                                        )
                                    end
                                end
                                if station.comms_data.trade ~= nil then
                                    out = string.format(
                                        _(
                                            "stationReport-msgGM",
                                            "%s\n    Trade:"
                                        ),
                                        out
                                    )
                                    for good, trade in
                                        pairs(station.comms_data.trade)
                                    do
                                        out = string.format(
                                            _(
                                                "stationReport-msgGM",
                                                "%s\n        %s: %s"
                                            ),
                                            out,
                                            good,
                                            trade
                                        )
                                    end
                                end
                                if station.comms_data.buy ~= nil then
                                    out = string.format(
                                        _("stationReport-msgGM", "%s\n    Buy:"),
                                        out
                                    )
                                    for good, amount in
                                        pairs(station.comms_data.buy)
                                    do
                                        out = string.format(
                                            _(
                                                "stationReport-msgGM",
                                                "%s\n        %s: %s"
                                            ),
                                            out,
                                            good,
                                            amount
                                        )
                                    end
                                end
                            end
                            addGMMessage(out)
                            stationReports()
                        end
                    )
                end
                tpa:destroy()
            end
        end
        if applicable_station_count == 0 then
            addGMMessage(
                _(
                    "stationReport-msgGM",
                    "No applicable stations. Reports useless. No action taken"
                )
            )
            mainGMButtons()
        end
    else
        addGMMessage(
            _(
                "stationReport-msgGM",
                "No applicable stations. Reports useless. No action taken"
            )
        )
        mainGMButtons()
    end
end
-- Player ship functions
function updatePlayerSoftTemplate(p)
    local tempTypeName = p:getTypeName()
    if tempTypeName ~= nil then
        if playerShipStats[tempTypeName] ~= nil then
            --set values from list
            p.shipScore = playerShipStats[tempTypeName].strength
            p.maxCargo = playerShipStats[tempTypeName].cargo
            p.cargo = p.maxCargo
            p:setLongRangeRadarRange(
                playerShipStats[tempTypeName].long_range_radar
            )
            p:setShortRangeRadarRange(
                playerShipStats[tempTypeName].short_range_radar
            )
            p.tractor = playerShipStats[tempTypeName].tractor
            p.tractor_target_lock = false
            p.mining = playerShipStats[tempTypeName].mining
            p:setMaxScanProbeCount(playerShipStats[tempTypeName].probes)
            p:setScanProbeCount(p:getMaxScanProbeCount())
            p.prox_scan = playerShipStats[tempTypeName].prox_scan
            local player_ship_name_list = player_ship_names_for[tempTypeName]
            local player_ship_name = nil
            if player_ship_name_list ~= nil then
                player_ship_name = tableRemoveRandom(player_ship_name_list)
            end
            if player_ship_name == nil then
                player_ship_name =
                    tableRemoveRandom(player_ship_names_for["Leftovers"])
            end
            if player_ship_name ~= nil then
                p:setCallSign(player_ship_name)
            end
            p.score_settings_source = tempTypeName
        else
            addGMMessage(
                string.format(
                    _(
                        "stationReport-msgGM",
                        "Player ship %s's template type (%s) could not be found in table PlayerShipStats"
                    ),
                    p:getCallSign(),
                    tempTypeName
                )
            )
        end
    end
    PlayerState.resetBaseline(p, { localize_tube_size = true })
end
function setPlayers(p)
    if p == nil then
        return
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
    updatePlayerSoftTemplate(p)
    player_ship_spawn_count = player_ship_spawn_count + 1
    -- p:onDestroyed(playerDestroyed)
    -- p:onDestruction(playerDestruction)
    if p:getReputationPoints() == 0 then
        p:setReputationPoints(reputation_start_amount)
    end
end
-- Construct environment and related functions
function environmentObject(ref_x, ref_y, dist, axis)
    if ref_x == nil or ref_y == nil or dist == nil then
        print(
            "function environmentObject expects ref_x, ref_y and dist to be provided"
        )
        return
    end
    if axis == nil then --circular environment object placement
        local inner_count_repeat_loop = 0
        local outer_count_repeat_loop = 0
        local outer_circle_buffer = 500
        repeat
            repeat
                radius = 100000
                local o_x, o_y =
                    vectorFromAngleNorth(random(0, 360), random(10000, radius))
                ref_x = ref_x + o_x
                ref_y = ref_y + o_y
                inner_count_repeat_loop = inner_count_repeat_loop + 1
            until farEnough(ref_x, ref_y, dist)
                or inner_count_repeat_loop > max_repeat_loop
            if inner_count_repeat_loop > max_repeat_loop then
                outer_count_repeat_loop = outer_count_repeat_loop + 1
                outer_circle_buffer = outer_circle_buffer + 1000
                inner_count_repeat_loop = 0
            else
                break
            end
        until outer_count_repeat_loop > max_repeat_loop
        if outer_count_repeat_loop > max_repeat_loop then
            print(
                "repeated too many times when trying to get far enough away 1"
            )
            print("last ref_x:", ref_x, "last ref_y:", ref_y)
            far_enough_fail = true
            return nil
        else
            return ref_x, ref_y
        end
    else --linear environment object placement
        local count_repeat_loop = 0
        if base_point_x == nil then
            base_distance = average_station_circle_distance
            base_point_x, base_point_y =
                vectorFromAngleNorth(axis, base_distance)
        end
        repeat
            local par_x, par_y = vectorFromAngleNorth(axis, random(0, 40000))
            local perp_x, perp_y =
                vectorFromAngleNorth(axis + 90, random(0, 40000))
            local pos_x, pos_y = vectorFromAngleNorth(axis + 270, 20000)
            ref_x = ref_x + base_point_x + pos_x + par_x + perp_x
            ref_y = ref_y + base_point_y + pos_y + par_y + perp_y
            base_distance = base_distance + random(20, 200)
            if base_distance > average_station_circle_distance + 80000 then
                base_distance = average_station_circle_distance
            end
            base_point_x, base_point_y =
                vectorFromAngleNorth(axis, base_distance)
            count_repeat_loop = count_repeat_loop + 1
        until farEnough(ref_x, ref_y, dist)
            or count_repeat_loop > max_repeat_loop
        if count_repeat_loop > max_repeat_loop then
            print(
                "repeated too many times when trying to get far enough away 2"
            )
            print("last ref_x:", ref_x, "last ref_y:", ref_y)
            far_enough_fail = true
            return nil
        else
            return ref_x, ref_y
        end
    end
end
function constructEnvironment()
    place_space = {}
    local faction_circle = {
        -- player faction:        Hum    USN    TSN    CUF
        "Exuari", --              Ene    Ene    Ene    Ene
        "Ghosts", --              Ene    Ene    Neu    Ene
        "TSN", --                 Frn    Ene    Frn    Neu
        "Independent", --         Neu    Neu    Neu    Neu
        "Human Navy", --          Frn    Frn    Frn    Frn
        "Arlenians", --           Neu    Neu    Ene    Neu
        "Ktlitans", --            Ene    Ene    Ene    Neu
        "CUF", --                 Frn    Neu    Neu    Frn
        "USN", --                 Frn    Frn    Ene    Neu
        "Kraylor", --             Ene    Neu    Ene    Ene
        "Ghosts", --              Ene    Ene    Neu    Ene
        -- enemy count:            5      5      5      4
        -- neutral/friendly count: 6      6      6      7
    }
    local faction_letter = {
        ["Human Navy"] = "H",
        ["Independent"] = "I",
        ["Kraylor"] = "K",
        ["Ktlitans"] = "B",
        ["Exuari"] = "E",
        ["Ghosts"] = "G",
        ["Arlenians"] = "A",
        ["TSN"] = "T",
        ["CUF"] = "C",
        ["USN"] = "U",
    }
    local station_defend_dist = {
        [ST.SMALL_STATION] = 2800, --2620
        [ST.MEDIUM_STATION] = 4200, --4000
        [ST.LARGE_STATION] = 4800, --4590
        [ST.HUGE_STATION] = 5200, --4985
    }
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
    station_list = {}
    -- player_factions = {"Human Navy","CUF","USN","TSN"}
    -- player_faction = player_factions[math.random(1,#player_factions)]
    -- ir_faction = {player_faction,"Human Navy"} --inner ring faction list
    -- if player_faction == "Human Navy" then
    -- ir_faction = {"Human Navy","CUF","USN","TSN"}
    -- end
    player_faction = "Human Navy"
    dev_x = random(100000, 130000)
    dev_y = random(100000, 130000)
    center_x = dev_x
    center_y = dev_y
    devourer = CpuShip()
        :setTemplate(ST.ODIN)
        :setFaction("Kraylor")
        :setPosition(dev_x, dev_y)
    devourer:setTypeName(_("scienceDB", "Planet Devourer"))
    local devourer_names = {
        "Ravenous",
        "Ouroboros",
        "Jormungandr",
        "Pygglor",
        "Azrael",
        "Reaper",
        "Anubis",
        "Yama",
        "Freyja",
        "Thanatos",
        "Hecate",
        "Meng Po",
        "Hel",
        "Morrighan",
        "Osiris",
        "Whiro",
        "Chernobog",
        "Coatlicue",
        "Sekhmet",
        "Ahriman",
        "Adro",
    }
    devourer:setCallSign(devourer_names[math.random(1, #devourer_names)])
    devourer:setJumpDrive(false)
    devourer:setImpulseMaxSpeed(90) --faster (vs 0)
    devourer:setRotationMaxSpeed(5) --faster (vs 1)
    devourer:setAcceleration(5) --faster acceleration (vs 0)
    devourer:setWeaponTubeCount(15) --fewer (vs 16)
    devourer:onDestruction(prepareDevourerExplosion)
    for i = 0, 4 do
        devourer
            :setWeaponTubeDirection(i * 3 + 0, (i * 3 + 0) * 24)
            :setTubeSize(i * 3 + 0, "small")
        devourer
            :setWeaponTubeDirection(i * 3 + 1, (i * 3 + 1) * 24)
            :setTubeSize(i * 3 + 1, "medium")
        devourer
            :setWeaponTubeDirection(i * 3 + 2, (i * 3 + 2) * 24)
            :setTubeSize(i * 3 + 2, "large")
    end
    devourer:setWeaponStorageMax("Homing", 15000) --more (vs 1000)
    devourer:setWeaponStorage("Homing", 15000)
    local ships_key = _("scienceDB", "Ships")
    local dreadnought_key = _("scienceDB", "Dreadnought")
    local devourer_key = _("scienceDB", "Planet Devourer")
    local odin_key = _("scienceDB", "Odin")
    local devourer_db =
        queryScienceDatabase(ships_key, dreadnought_key, devourer_key)
    if devourer_db == nil then
        local dreadnought_db = queryScienceDatabase(ships_key, dreadnought_key)
        if dreadnought_db ~= nil then --added for translation issues
            dreadnought_db:addEntry(devourer_key)
            devourer_db =
                queryScienceDatabase(ships_key, dreadnought_key, devourer_key)
            addShipToDatabase(
                queryScienceDatabase(ships_key, dreadnought_key, odin_key), --base ship database entry
                devourer_db, --modified ship database entry
                devourer, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "The Planet Devourer is a modified Odin. The jump drive was removed in favor of massive impulse engines and beefed up maneuvering thrusters. The tubes were diversified: five small tubes, five medium tubes and five large tubes. The store of missiles was increased at least tenfold. Fighter hangars as well as automated fighter maintenance and construction facilities were added.\n\nAs the name implies, it's got some kind of specialized weaponry designed around engaging planets. At the time of this database entry update, details on this weaponry are largely unknown.\n\nIntercepted communications related to the Planet Devourer refer to it as LDS. We are accustomed to the ubiquity of acronyms in the military, but we can't quite decipher this one. We know there is a predominance of late 20th century movie fans amongst the crew, maintenance techs and construction personnel. So, our two leading theories are Little Death Star and an intentionally mangled reference to LSD (lysergic acid diethylamide). Both of these theories are based on late 20th century space themed movie franchises (Star Wars and Star Trek respectively)."
                ),
                nil,
                nil,
                "space_station_2"
            )
        end
    end
    table.insert(place_space, { obj = devourer, dist = 2000, shape = "circle" })
    local px, py = vectorFromAngleNorth(315, 50000)
    local planet_radius = random(3000, 8000)
    local planet_fodder = Planet()
        :setPosition(dev_x + px, dev_y + py)
        :setPlanetRadius(planet_radius)
    planet_fodder:setDistanceFromMovementPlane(-planet_radius * 0.2)
    local planet_list = {
        {
            name = { "Bespin", "Aldea", "Bersallis" },
            texture = {
                surface = "planets/gas-1.png",
            },
        },
        {
            name = { "Farius Prime", "Deneb", "Mordan" },
            texture = {
                surface = "planets/gas-2.png",
            },
        },
        {
            name = { "Kepler-7b", "Alpha Omicron", "Nelvana" },
            texture = {
                surface = "planets/gas-3.png",
            },
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
        },
        {
            name = { "Ahch-To", "Cantonica", "Cato Neimoidia", "Corellia" },
            color = {
                red = random(0, 0.2),
                green = random(0, 0.2),
                blue = random(0.8, 1),
            },
            texture = {
                surface = "planets/planet-1.png",
                cloud = "planets/clouds-2.png",
                atmosphere = "planets/atmosphere.png",
            },
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
        },
        {
            name = { "Anoat", "D'Qar", "Eadu" },
            color = {
                red = random(0, 0.4),
                green = random(0, 0.2),
                blue = random(0.8, 1),
            },
            texture = {
                surface = "planets/planet-2.png",
                cloud = "planets/clouds-3.png",
                atmosphere = "planets/atmosphere.png",
            },
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
        },
    }
    local selected_planet = tableRemoveRandom(planet_list)
    planet_fodder:setCallSign(
        selected_planet.name[math.random(1, #selected_planet.name)]
    )
    planet_fodder:setPlanetSurfaceTexture(selected_planet.texture.surface)
    if selected_planet.texture.atmosphere ~= nil then
        planet_fodder:setPlanetAtmosphereTexture(
            selected_planet.texture.atmosphere
        )
    end
    if selected_planet.texture.cloud ~= nil then
        planet_fodder:setPlanetCloudTexture(selected_planet.texture.cloud)
    end
    if selected_planet.color ~= nil then
        planet_fodder:setPlanetAtmosphereColor(
            selected_planet.color.red,
            selected_planet.color.green,
            selected_planet.color.blue
        )
    end
    planet_fodder:setAxialRotationTime(random(350, 500))
    table.insert(
        place_space,
        { obj = planet_fodder, dist = planet_radius, shape = "circle" }
    )
    for i = 1, 4 do
        px, py = vectorFromAngleNorth(
            315 + 360 / 5 * i + random(-10, 10),
            random(30000, 80000)
        )
        planet_radius = random(3000, 8000)
        planet_fodder = Planet()
            :setPosition(dev_x + px, dev_y + py)
            :setPlanetRadius(planet_radius)
        planet_fodder:setDistanceFromMovementPlane(-planet_radius * 0.2)
        selected_planet = tableRemoveRandom(planet_list)
        planet_fodder:setCallSign(
            selected_planet.name[math.random(1, #selected_planet.name)]
        )
        planet_fodder:setPlanetSurfaceTexture(selected_planet.texture.surface)
        if selected_planet.texture.atmosphere ~= nil then
            planet_fodder:setPlanetAtmosphereTexture(
                selected_planet.texture.atmosphere
            )
        end
        if selected_planet.texture.cloud ~= nil then
            planet_fodder:setPlanetCloudTexture(selected_planet.texture.cloud)
        end
        if selected_planet.color ~= nil then
            planet_fodder:setPlanetAtmosphereColor(
                selected_planet.color.red,
                selected_planet.color.green,
                selected_planet.color.blue
            )
        end
        planet_fodder:setAxialRotationTime(random(350, 500))
        table.insert(
            place_space,
            { obj = planet_fodder, dist = planet_radius, shape = "circle" }
        )
    end

    transport_list = {}
    transport_stations = {}
    env_stations = {}
    --fill in roughly circular area with semi-random terrain
    far_enough_fail = false
    local black_hole_chance = 1
    if difficulty > 1 then
        black_hole_count = 1
    else
        black_hole_count = math.random(3, 9)
    end
    local star_chance = 3
    star_count = math.random(1, 2)
    local probe_chance = 6
    local warp_jammer_chance = 3
    warp_jammer_count = math.random(2, 7)
    local worm_hole_chance = 2
    worm_hole_count = math.random(2, 7)
    local sensor_jammer_chance = 6
    sensor_jammer_count = math.random(3, 10)
    local sensor_buoy_chance = 6
    local ad_buoy_chance = 8
    local nebula_chance = 5
    local mine_chance = 4
    local station_chance = 3
    local mine_field_chance = 4
    mine_field_count = math.random(3, 8)
    local asteroid_field_chance = 4
    asteroid_field_count = math.random(2, 12)
    local transport_chance = 4
    repeat
        local current_object_chance = 0
        local object_roll = random(0, 100)
        current_object_chance = current_object_chance + black_hole_chance
        if object_roll <= current_object_chance then
            placeBlackHole()
            goto iterate
        end
        current_object_chance = current_object_chance + probe_chance
        if object_roll <= current_object_chance then
            placeProbe()
            goto iterate
        end
        current_object_chance = current_object_chance + warp_jammer_chance
        if object_roll <= current_object_chance then
            placeWarpJammer()
            goto iterate
        end
        current_object_chance = current_object_chance + worm_hole_chance
        if object_roll <= current_object_chance then
            placeWormHole()
            goto iterate
        end
        current_object_chance = current_object_chance + sensor_jammer_chance
        if object_roll <= current_object_chance then
            placeSensorJammer()
            goto iterate
        end
        current_object_chance = current_object_chance + sensor_buoy_chance
        if object_roll <= current_object_chance then
            placeSensorBuoy()
            goto iterate
        end
        current_object_chance = current_object_chance + ad_buoy_chance
        if object_roll <= current_object_chance then
            placeAdBuoy()
            goto iterate
        end
        current_object_chance = current_object_chance + nebula_chance
        if object_roll <= current_object_chance then
            placeNebula()
            goto iterate
        end
        current_object_chance = current_object_chance + mine_chance
        if object_roll <= current_object_chance then
            placeMine()
            goto iterate
        end
        current_object_chance = current_object_chance + station_chance
        if object_roll <= current_object_chance then
            placeEnvironmentStation()
            goto iterate
        end
        current_object_chance = current_object_chance + mine_field_chance
        if object_roll <= current_object_chance then
            placeMineField()
            goto iterate
        end
        current_object_chance = current_object_chance + asteroid_field_chance
        if object_roll <= current_object_chance then
            placeAsteroidField()
            goto iterate
        end
        current_object_chance = current_object_chance + transport_chance
        if object_roll <= current_object_chance then
            placeTransport()
            goto iterate
        end
        placeAsteroid()
        ::iterate::
    until (#station_list >= 10 and #transport_list >= 10) or far_enough_fail
    far_enough_fail = false
    maintenancePlot = defenseMaintenance
end

function placeWarpJammer(axis)
    if warp_jammer_count > 0 then
        if #station_list > 0 then
            local eo_x, eo_y = environmentObject(center_x, center_y, 200, axis)
            if eo_x ~= nil then
                local wj = WarpJammer():setPosition(eo_x, eo_y)
                local closest_station_distance = 999999
                local closest_station = nil
                for i, station in ipairs(station_list) do
                    local current_distance = distance(station, eo_x, eo_y)
                    if current_distance < closest_station_distance then
                        closest_station_distance = current_distance
                        closest_station = station
                    end
                end
                local selected_faction = closest_station:getFaction()
                local warp_jammer_range = 0
                for i = 1, 5 do
                    warp_jammer_range = warp_jammer_range + random(1000, 3000)
                end
                wj:setRange(warp_jammer_range):setFaction(selected_faction)
                warp_jammer_info[selected_faction].count = warp_jammer_info[selected_faction].count
                    + 1
                wj:setCallSign(
                    string.format(
                        "%sWJ%i",
                        warp_jammer_info[selected_faction].id,
                        warp_jammer_info[selected_faction].count
                    )
                )
                wj.range = warp_jammer_range
                table.insert(warp_jammer_list, wj)
                table.insert(
                    place_space,
                    { obj = wj, dist = 200, shape = "circle" }
                )
                warp_jammer_count = warp_jammer_count - 1
            end
        else
            placeAsteroid(axis)
        end
    else
        placeAsteroid(axis)
    end
end
function placeSensorBuoy(axis)
    local out = ""
    local eo_x, eo_y = environmentObject(center_x, center_y, 200, axis)
    if eo_x ~= nil then
        local sb = Artifact()
            :setPosition(eo_x, eo_y)
            :setScanningParameters(
                math.random(1, difficulty * 2),
                math.random(1, difficulty * 2)
            )
            :setRadarSignatureInfo(random(0, 1), random(0, 1), random(0, 1))
            :setModel("SensorBuoyMKIII")
        local buoy_type_list = {}
        local buoy_type = ""
        if #station_list > 0 then
            table.insert(buoy_type_list, "station")
        end
        if #transport_list > 0 then
            table.insert(buoy_type_list, "transport")
        end
        if #buoy_type_list > 0 then
            buoy_type = tableRemoveRandom(buoy_type_list)
            if buoy_type == "station" then
                local selected_stations = {}
                for i, station in ipairs(station_list) do
                    table.insert(selected_stations, station)
                end
                for i = 1, 3 do
                    if #selected_stations > 0 then
                        local station = tableRemoveRandom(selected_stations)
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
                        local transport = tableRemoveRandom(selected_transports)
                        if transport.comms_data == nil then
                            transport.comms_data =
                                { friendlyness = random(0.0, 100.0) }
                        end
                        if transport.comms_data.goods == nil then
                            goodsOnShip(transport, transport.comms_data)
                        end
                        local goods_carrying = ""
                        for good, goodData in pairs(transport.comms_data.goods) do
                            if goods_carrying == "" then
                                goods_carrying = good_desc[good]
                            else
                                goods_carrying = string.format(
                                    "%s, %s",
                                    goods_carrying,
                                    good_desc[good]
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
        sb:setDescriptions(
            _("scienceDescription-buoy", "Automated data gathering device"),
            out
        )
        table.insert(place_space, { obj = sb, dist = 200, shape = "circle" })
    end
end
function placeAdBuoy(axis)
    local eo_x, eo_y = environmentObject(center_x, center_y, 200, axis)
    if eo_x ~= nil then
        local ab = Artifact()
            :setPosition(eo_x, eo_y)
            :setScanningParameters(difficulty * 2, 1)
            :setRadarSignatureInfo(random(0, 1), random(0, 1), random(0, 1))
            :setModel("SensorBuoyMKIII")
        local billboards = {
            _(
                "scienceDescription-buoy",
                "Come to Billy Bob's for the best food in the sector"
            ),
            _(
                "scienceDescription-buoy",
                "It's never too late to buy life insurance"
            ),
            _(
                "scienceDescription-buoy",
                "You'll feel better in an Adder Mark 9"
            ),
            _(
                "scienceDescription-buoy",
                "Visit Repulse shipyards for the best deals"
            ),
            _("scienceDescription-buoy", "Fresh fish! We catch, you buy!"),
            _(
                "scienceDescription-buoy",
                "Get your fuel cells at Melinda's Market"
            ),
            _(
                "scienceDescription-buoy",
                "Find a special companion. All species available"
            ),
            _(
                "scienceDescription-buoy",
                "Feeling down? Robotherapist is there for you"
            ),
            _("scienceDescription-buoy", "30 days, 30 kilograms, guaranteed"),
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
                "Tip: make lemons an integral part of your diet"
            ),
            _(
                "scienceDescription-buoy",
                "Sam's Spacesuits - now with automatic micrometeorite puncture sealing"
            ),
        }
        ab:setDescriptions(
            _("scienceDescription-buoy", "Automated data gathering device"),
            billboards[math.random(1, #billboards)]
        )
        table.insert(place_space, { obj = ab, dist = 200, shape = "circle" })
    end
end
function placeEnvironmentStation(axis)
    local station_defend_dist = {
        [ST.SMALL_STATION] = 2800, --2620
        [ST.MEDIUM_STATION] = 4200, --4000
        [ST.LARGE_STATION] = 4800, --4590
        [ST.HUGE_STATION] = 5200, --4985
    }
    local s_size = szt()
    local eo_x, eo_y =
        environmentObject(center_x, center_y, station_defend_dist[s_size], axis)
    if eo_x ~= nil then
        --check station distance to other stations
        local spaced_station = true
        local closest_station_distance = 999999
        local closest_station = nil
        for i, station in ipairs(station_list) do
            local current_distance = distance(station, eo_x, eo_y)
            if current_distance < closest_station_distance then
                closest_station_distance = current_distance
                closest_station = station
            end
            if current_distance < 16000 then
                spaced_station = false
                break
            end
        end
        if not spaced_station then
            placeAsteroid()
            return
        end
        if faction_spread == nil then
            faction_spread = {
                "Human Navy",
                "Independent",
                "Kraylor",
                "Arlenians",
                "Exuari",
                "Ghosts",
                "Ktlitans",
                "TSN",
                "USN",
                "CUF",
            }
        end
        if #faction_spread < 1 then
            faction_spread = {
                "Human Navy",
                "Independent",
                "Kraylor",
                "Arlenians",
                "Exuari",
                "Ghosts",
                "Ktlitans",
                "TSN",
                "USN",
                "CUF",
            }
        end
        local selected_faction = tableRemoveRandom(faction_spread)
        local name_group = "RandomHumanNeutral"
        local tsa = Artifact():setFaction(selected_faction)
        local tpa = Artifact():setFaction(player_faction)
        if tsa:isEnemy(tpa) then
            name_group = "Sinister"
        end
        tsa:destroy()
        tpa:destroy()
        local station =
            placeStation(eo_x, eo_y, name_group, selected_faction, s_size)
        table.insert(
            place_space,
            {
                obj = station,
                dist = station_defend_dist[s_size],
                shape = "circle",
            }
        )
        table.insert(station_list, station)
        size_probability = {
            [ST.SMALL_STATION] = 60,
            [ST.MEDIUM_STATION] = 75,
            [ST.LARGE_STATION] = 85,
            [ST.HUGE_STATION] = 95,
        }
        station.comms_data.service_available = {
            supplydrop = random(1, 100) < size_probability[s_size],
            reinforcements = random(1, 100) < size_probability[s_size],
            hornet_reinforcements = random(1, 100) < size_probability[s_size],
            phobos_reinforcements = random(1, 100) < size_probability[s_size],
            amk3_reinforcements = random(1, 100) < size_probability[s_size],
            amk8_reinforcements = random(1, 100) < size_probability[s_size],
            jump_overcharge = random(1, 100) < size_probability[s_size],
            shield_overcharge = random(1, 100) < size_probability[s_size],
            jonque = random(1, 100) < size_probability[s_size],
        }
        station.comms_data.service_cost = {
            supplydrop = math.random(90, 110),
            reinforcements = math.random(140, 160),
            hornet_reinforcements = math.random(75, 125),
            phobos_reinforcements = math.random(175, 225),
            amk3_reinforcements = math.random(75, 125),
            amk8_reinforcements = math.random(150, 200),
            shield_overcharge = math.random(1, 5) * 5,
            scan_repair = math.random(2, 7),
            hack_repair = math.random(2, 7),
            probe_launch_repair = math.random(2, 7),
            self_destruct_repair = math.random(2, 7),
            tube_slow_down_repair = math.random(2, 7),
            combat_maneuver_repair = math.random(2, 7),
        }
        --defense fleet
        local fleet = spawnEnemies(eo_x, eo_y, 1, selected_faction, 35)
        for i, ship in ipairs(fleet) do
            ship:setFaction("Independent")
            ship:orderDefendTarget(station)
            ship:setFaction(selected_faction)
            ship:setCallSign(generateCallSign(nil, selected_faction))
        end
        station.defense_fleet = fleet
        return station
    end
end
function placeTransport(axis)
    local eo_x, eo_y = environmentObject(center_x, center_y, 600, axis)
    if eo_x ~= nil then
        local ship, ship_size = randomTransportType()
        local human_transports = 0
        local independent_transports = 0
        for i, transport in ipairs(transport_list) do
            if transport:isValid() then
                if transport:getFaction() == "Human Navy" then
                    human_transports = human_transports + 1
                else
                    independent_transports = independent_transports + 1
                end
            end
        end
        local transport_factions = { "Human Navy", "Independent" }
        local transport_faction =
            transport_factions[math.random(1, #transport_factions)]
        if human_transports >= 4 then
            transport_faction = "Independent"
        elseif independent_transports >= 8 then
            transport_faction = "Human Navy"
        end
        ship:setPosition(eo_x, eo_y):setFaction(transport_faction)
        ship:setCallSign(generateCallSign(nil, ship:getFaction()))
        table.insert(place_space, { obj = ship, dist = 600, shape = "circle" })
        table.insert(transport_list, ship)
    end
end
function farEnough(o_x, o_y, obj_dist)
    local far_enough = true
    for i, item in ipairs(place_space) do
        if item.shape == "circle" then
            if distanceDiagnostic then
                print(
                    "Distance diagnostic 2: item.obj:",
                    item.obj,
                    item.obj:getCallSign(),
                    "o_x:",
                    o_x,
                    "o_y:",
                    o_y
                )
            end
            if item.obj ~= nil and item.obj:isValid() then
                if distance(item.obj, o_x, o_y) < (obj_dist + item.dist) then
                    far_enough = false
                    break
                end
            elseif item.ps_x ~= nil then
                if
                    distance(item.ps_x, item.ps_y, o_x, o_y)
                    < (obj_dist + item.dist)
                then
                    far_enough = false
                    break
                end
            end
        elseif item.shape == "rectangle" then
            if
                o_x > item.lo_x
                and o_x < item.hi_x
                and o_y > item.lo_y
                and o_y < item.hi_y
            then
                far_enough = false
                break
            end
        elseif item.shape == "toroid" then
            if item.obj ~= nil and item.obj:isValid() then
                local origin_dist = distance(item.obj, o_x, o_y)
                if
                    origin_dist > item.inner_orbit - obj_dist
                    and origin_dist < item.outer_orbit + obj_dist
                then
                    far_enough = false
                    break
                end
            end
        elseif item.shape == "zone" then
            local va = VisualAsteroid():setPosition(o_x, o_y)
            if item.zone:isInside(va) then
                far_enough = false
            end
            va:destroy()
            if far_enough then
                for i = 1, 30 do
                    local v_x, v_y = vectorFromAngleNorth(i * 12, obj_dist)
                    if item.zone:isInside(va) then
                        far_enough = false
                    end
                    va:destroy()
                    if not far_enough then
                        break
                    end
                end
            end
            if not far_enough then
                break
            end
        end
    end
    return far_enough
end
-- Terrain and environment creation functions
---------------------------------------
-- Support for constant plot lines  --
---------------------------------------
-- Maintenance functions
function defenseMaintenance(delta)
    if #station_list > 0 then
        for station_index, station in ipairs(station_list) do
            if station ~= nil and station:isValid() then
                local fleet_count = 0
                local deleted_ship = false
                if
                    station.defense_fleet ~= nil
                    and #station.defense_fleet > 0
                then
                    for fleet_index, ship in ipairs(station.defense_fleet) do
                        if ship ~= nil and ship:isValid() then
                            fleet_count = fleet_count + 1
                        else
                            station.defense_fleet[fleet_index] =
                                station.defense_fleet[#station.defense_fleet]
                            station.defense_fleet[#station.defense_fleet] = nil
                            deleted_ship = true
                            break
                        end
                    end
                end
                if fleet_count < 1 and not deleted_ship then
                    if station.defense_fleet_timer == nil then
                        station.defense_fleet_timer = getScenarioTime() + 30
                    end
                    if station.defense_fleet_timer < getScenarioTime() then
                        if station:areEnemiesInRange(10000) then
                            station.defense_fleet_timer = nil
                            local df_x, df_y = station:getPosition()
                            local station_faction = station:getFaction()
                            local fleet =
                                spawnEnemies(df_x, df_y, 1, station_faction)
                            for i, ship in ipairs(fleet) do
                                ship:setFaction("Independent")
                                ship:orderDefendTarget(station)
                                ship:setFaction(station_faction)
                                ship:setCallSign(
                                    generateCallSign(nil, ship:getFaction())
                                )
                            end
                            station.defense_fleet = fleet
                        else
                            station.defense_fleet_timer = getScenarioTime() + 30
                        end
                    end
                end
            else
                station_list[station_index] = station_list[#station_list]
                station_list[#station_list] = nil
                break
            end
        end
    end
    maintenancePlot = transportCommerceMaintenance
end
-- Sensor jammer functions
-- Transport selection and direction functions
-- Early end
function enforcerEnd()
    enforcers = {}
    for i, p in ipairs(getActivePlayerShips()) do
        local start_angle = random(0, 60)
        local px, py = p:getPosition()
        for j = 1, 6 do
            local ship =
                ship_template["Barracuda"].create("Kraylor", "Barracuda")
            local sx, sy = vectorFromAngle(
                j * 60 + start_angle,
                p:getLongRangeRadarRange() + 500,
                true
            )
            sx = sx + px
            sy = sy + py
            ship:setPosition(sx, sy)
                :setHeading(angleHeading(sx, sy, px, py))
                :orderAttack(p)
            ship:setCallSign(generateCallSign(nil, "Kraylor"))
            table.insert(enforcers, { p = p, ship = ship })
        end
        p:addToShipLog(
            _(
                "shipLog",
                "Sensors show that the Kraylor have launched a squad of protectors against you. The current Kraylor protection squad protocol dictates six Barracudas in an enclosing ambush formation, each equipped with a high powered warp jammer. Very dangerous. It's been nice knowing you."
            ),
            "Red"
        )
    end
    enforce_end = true
end
function maintainEndEnforcers(p)
    local px, py = p:getPosition()
    for i, enf in ipairs(enforcers) do
        if enf.p == p then
            if enf.ship:isValid() then
                if enf.ship.jammer == nil then
                    local sx, sy = enf.ship:getPosition()
                    if
                        distance(px, py, sx, sy)
                        < p:getLongRangeRadarRange() * 0.8
                    then
                        WarpJammer()
                            :setRange(p:getLongRangeRadarRange())
                            :setPosition(sx, sy)
                        enf.ship.jammer = true
                    end
                end
            end
        end
    end
end
--------------------------------
-- Station creation functions --
--------------------------------
---------------------------
-- Station communication --
---------------------------
local function addDevourerInformation(docked)
    if comms_target:isFriendly(comms_source) then
        addCommsReply(
            _("mission-comms", "Locate Planet Devourer"),
            function()
                local output_message = string.format(
                    _("mission-comms", "%s is located in sector %s."),
                    devourer:getCallSign(),
                    devourer:getSectorName()
                )
                if
                    devourer.planet_target ~= nil
                    and devourer.planet_target:isValid()
                then
                    output_message = string.format(
                        _(
                            "mission-comms",
                            "%s We project that %s plans to destroy %s in sector %s"
                        ),
                        output_message,
                        devourer:getCallSign(),
                        devourer.planet_target:getCallSign(),
                        devourer.planet_target:getSectorName()
                    )
                end
                setCommsMessage(output_message)
                addCommsReply(_("Back"), commsStation)
            end
        )
        if docked then
            if approached_devourer then
                addCommsReply(
                    string.format(
                        _("mission-comms", "How do we destroy %s?"),
                        devourer:getCallSign()
                    ),
                    function()
                        if
                            comms_source.plan_extractor ~= nil
                            and comms_source.plan_extractor == "extracted"
                        then
                            setCommsMessage(
                                _(
                                    "mission-comms",
                                    "Were you able to get the plans?"
                                )
                            )
                            addCommsReply(
                                _(
                                    "mission-comms",
                                    "We got the plans. Now what?"
                                ),
                                function()
                                    local beam_nerf = _("mission-comms", "Four")
                                    local missile_nerf =
                                        _("mission-comms", "three")
                                    if difficulty == 1 then
                                        beam_nerf = _("mission-comms", "Six")
                                        missile_nerf = _("mission-comms", "six")
                                    elseif difficulty < 1 then
                                        beam_nerf = _("mission-comms", "Eight")
                                        missile_nerf =
                                            _("mission-comms", "nine")
                                    end
                                    setCommsMessage(
                                        string.format(
                                            _(
                                                "mission-comms",
                                                "Good job bringing in those plans. Our analysis shows a weakness in the weapons control system of the %s. If we can upload a digital virus through a small thermal exhaust port just below the main port, we should be able to create a virtual canyon between the weapons systems by forcing them into maintenance mode. %s out of sixteen beam emplacements will be reduced in range from 3.2 units to 1 unit and their cycle time will be increased from 3 seconds to 30 seconds. Similarly, %s out of fifteen weapons tubes will have their load times increased from 3 seconds to 3 minutes. This should make it easier for you to deliver destructuve beam and missile fire to %s"
                                            ),
                                            devourer:getCallSign(),
                                            beam_nerf,
                                            missile_nerf,
                                            devourer:getCallSign()
                                        )
                                    )
                                    addCommsReply(
                                        _(
                                            "mission-comms",
                                            "How do we upload this virus?"
                                        ),
                                        function()
                                            comms_source.virus_upload =
                                                "enabled"
                                            setCommsMessage(
                                                string.format(
                                                    _(
                                                        "mission-comms",
                                                        "The approach will not be easy. You are required to maneuver straight down this trench and skim the surface to this point. The target area is only two meters wide... ...uh... ...sorry, I'm reading from the wrong script. Simply approach within 3 units of %s and have your engineer activate the upload using the button that should appear on the engineering console. Remember that the beam range on the %s is 3.2 units, so you'll have to take a couple of hits to deliver the virus. Your engineer will want to boost the shields for better protection. You'll probably also want your weapons officer to calibrate your shields, too."
                                                    ),
                                                    devourer:getCallSign(),
                                                    devourer:getCallSign()
                                                )
                                            )
                                            addCommsReply(
                                                _("Back"),
                                                commsStation
                                            )
                                        end
                                    )
                                    addCommsReply(_("Back"), commsStation)
                                end
                            )
                        else
                            setCommsMessage(
                                _(
                                    "mission-comms",
                                    "It's a monster. If we had the technical readouts for the Planet Devourer, we might find a weakness, and exploit it."
                                )
                            )
                            addCommsReply(
                                _(
                                    "mission-comms",
                                    "Where can we get the plans for the Planet Devourer?"
                                ),
                                function()
                                    if station_kraylor == nil then
                                        for i, station in ipairs(station_list) do
                                            if
                                                station ~= nil
                                                and station:isValid()
                                            then
                                                if
                                                    station:getFaction()
                                                    == "Kraylor"
                                                then
                                                    station_kraylor = station
                                                    break
                                                end
                                            end
                                        end
                                    end
                                    if
                                        station_kraylor ~= nil
                                        and station_kraylor:isValid()
                                    then
                                        setCommsMessage(
                                            string.format(
                                                _(
                                                    "mission-comms",
                                                    "Kraylor station %s in sector %s probably has them. But they are likely to be heavily protected."
                                                ),
                                                station_kraylor:getCallSign(),
                                                station_kraylor:getSectorName()
                                            )
                                        )
                                        addCommsReply(
                                            _(
                                                "mission-comms",
                                                "How can we get those plans?"
                                            ),
                                            function()
                                                setCommsMessage(
                                                    _(
                                                        "mission-comms",
                                                        "You can't"
                                                    )
                                                )
                                                addCommsReply(
                                                    _(
                                                        "mission-comms",
                                                        "What? There must be something we can do"
                                                    ),
                                                    function()
                                                        setCommsMessage(
                                                            _(
                                                                "mission-comms",
                                                                "I can't think of anything. Do you have any ideas?"
                                                            )
                                                        )
                                                        addCommsReply(
                                                            _(
                                                                "mission-comms",
                                                                "Threaten to destroy them unless they give up the plans."
                                                            ),
                                                            function()
                                                                setCommsMessage(
                                                                    _(
                                                                        "mission-comms",
                                                                        "They'd call your bluff. We can't get the plans if the station has been destroyed."
                                                                    )
                                                                )
                                                                addCommsReply(
                                                                    _("Back"),
                                                                    commsStation
                                                                )
                                                            end
                                                        )
                                                        addCommsReply(
                                                            _(
                                                                "mission-comms",
                                                                "Sneak aboard the station and steal the plans."
                                                            ),
                                                            function()
                                                                setCommsMessage(
                                                                    _(
                                                                        "mission-comms",
                                                                        "They would not let you dock. Even if you could force your way onto the station, standard protocol is to wipe the databanks. However, we might be able to install a powerful cyber system on your ship. You'd have to get close and stay close for it to work."
                                                                    )
                                                                )
                                                                addCommsReply(
                                                                    _(
                                                                        "mission-comms",
                                                                        "That sounds better than nothing. Let's try it"
                                                                    ),
                                                                    function()
                                                                        setCommsMessage(
                                                                            _(
                                                                                "mission-comms",
                                                                                "You'd have to get within 2.5 units and stay there for at least 47 seconds for the system to infiltrate and extract the plans."
                                                                            )
                                                                        )
                                                                        addCommsReply(
                                                                            _(
                                                                                "mission-comms",
                                                                                "Got it. Please install it quickly"
                                                                            ),
                                                                            function()
                                                                                comms_source.plan_extractor =
                                                                                    "installed"
                                                                                setCommsMessage(
                                                                                    _(
                                                                                        "mission-comms",
                                                                                        "We installed the cyber system. Your engineer will see an activation button when you get in range."
                                                                                    )
                                                                                )
                                                                                addCommsReply(
                                                                                    _(
                                                                                        "Back"
                                                                                    ),
                                                                                    commsStation
                                                                                )
                                                                            end
                                                                        )
                                                                        addCommsReply(
                                                                            _(
                                                                                "Back"
                                                                            ),
                                                                            commsStation
                                                                        )
                                                                    end
                                                                )
                                                                addCommsReply(
                                                                    _("Back"),
                                                                    commsStation
                                                                )
                                                            end
                                                        )
                                                        addCommsReply(
                                                            _(
                                                                "mission-comms",
                                                                "Check with other stations for the plans."
                                                            ),
                                                            function()
                                                                setCommsMessage(
                                                                    _(
                                                                        "mission-comms",
                                                                        "Those plans are highly classified by the Kraylor. We've been trying to talk to anyone that's worked on it outside of Kraylor controlled groups, but that information is just not available anywhere but within Kraylor controlled space."
                                                                    )
                                                                )
                                                                addCommsReply(
                                                                    _("Back"),
                                                                    commsStation
                                                                )
                                                            end
                                                        )
                                                        addCommsReply(
                                                            string.format(
                                                                _(
                                                                    "mission-comms",
                                                                    "Deep scan %s ourselves to determine a weakness"
                                                                ),
                                                                devourer:getCallSign()
                                                            ),
                                                            function()
                                                                setCommsMessage(
                                                                    string.format(
                                                                        _(
                                                                            "mission-comms",
                                                                            "%s has very strong shields. They prevent detailed analysis of ship functions. Even if you got some information, by the time you determined a weakness, the planets in this area will all have been destroyed."
                                                                        ),
                                                                        devourer:getCallSign()
                                                                    )
                                                                )
                                                                addCommsReply(
                                                                    _("Back"),
                                                                    commsStation
                                                                )
                                                            end
                                                        )
                                                        addCommsReply(
                                                            _("Back"),
                                                            commsStation
                                                        )
                                                    end
                                                )
                                                addCommsReply(
                                                    _("Back"),
                                                    commsStation
                                                )
                                            end
                                        )
                                    else
                                        setCommsMessage(
                                            _(
                                                "mission-comms",
                                                "All the Kraylor stations in the area have been destroyed. Too bad."
                                            )
                                        )
                                    end
                                    addCommsReply(_("Back"), commsStation)
                                end
                            )
                        end
                        addCommsReply(_("Back"), commsStation)
                    end
                )
            end
        else
            if approached_devourer then
                if
                    comms_source.plan_extractor == nil
                    or comms_source.plan_extractor ~= "extracted"
                then
                    addCommsReply(
                        string.format(
                            _("mission-comms", "How do we destroy %s?"),
                            devourer:getCallSign()
                        ),
                        function()
                            setCommsMessage(
                                _(
                                    "mission-comms",
                                    "What a terrible thing to contemplate, much less say out loud. Seriously, if you want to discuss such things, you should dock first so that the Kraylor cannot intercept the transmission no matter how good the encryption protocols."
                                )
                            )
                            addCommsReply(_("Back"), commsStation)
                        end
                    )
                end
            end
            if comms_source.plan_extractor == "extracted" then
                addCommsReply(
                    _("mission-comms", "We got the plans. Now what?"),
                    function()
                        setCommsMessage(
                            _(
                                "mission-comms",
                                "Bring them to a friendly station for analysis. Subspace communications bandwidth prevent transmission and decryption without Kraylor destructive interference. We've started analysis based on the gestalt, but need the physical plans to complete it and provide an exploitable weakness."
                            )
                        )
                        addCommsReply(_("Back"), commsStation)
                    end
                )
            end
        end
    end
end

local function showCurrentOrders(docked)
    setOptionalOrders()
    setSecondaryOrders()
    if docked then
        primary_orders = _("orders-comms", "Save the planets from destruction")
        ordMsg = primary_orders .. "\n" .. secondary_orders .. optional_orders
    else
        primary_orders = _("orders-comms", "Save the planets from destruction.")
        ordMsg = string.format(
            _("orders-comms", "%s\n%s%s"),
            primary_orders,
            secondary_orders,
            optional_orders
        )
    end
    if playWithTimeLimit then
        ordMsg = ordMsg
            .. string.format(
                _("orders-comms", "\n   %i Minutes remain in game"),
                math.floor(gameTimeLimit / 60)
            )
    end
    setCommsMessage(ordMsg)
end

station_profile = {
    main_menu = commsStation,
    goods_name = function(good)
        return good_desc[good]
    end,
    require_docked = true,
    resources = { prompt = true },
    docked = {
        show_reputation = false,
        group_services = true,
        service_label = _(
            "station-comms",
            "Station services (restock ordnance, repairs)"
        ),
        information = {
            prompt = _("station-comms", "What do you need to know?"),
            sections = {
                { kind = "warp_jammer" },
                {
                    kind = "callback",
                    callback = function()
                        addDevourerInformation(true)
                    end,
                },
                { kind = "gossip" },
                { kind = "sensor_jammer" },
                {
                    kind = "orders",
                    callback = function()
                        showCurrentOrders(true)
                    end,
                },
            },
        },
        group_resources = true,
    },
    undocked = {
        cleanup_warp_jammers = false,
        warp_jammer_details = false,
        warp_jammer_back = true,
        waypoint_id = function(index)
            return comms_source:getWaypointID(index)
        end,
        information = {
            prompt = _("station-comms", "What kind of information do you need?"),
            sections = {
                {
                    kind = "callback",
                    callback = function()
                        addDevourerInformation(false)
                    end,
                },
                {
                    kind = "orders",
                    callback = function()
                        showCurrentOrders(false)
                    end,
                },
                {
                    kind = "service_information",
                    label = _(
                        "station-comms",
                        "Station services (ordnance restock, repair)"
                    ),
                    status_repair_typo = true,
                },
                { kind = "goods_information" },
                { kind = "gossip" },
                { kind = "character" },
                { kind = "status" },
            },
        },
        assistance = true,
    },
}
function setSecondaryOrders()
    secondary_orders = ""
    if comms_source.plan_extractor == "installed" then
        secondary_orders =
            _("orders-comms", "Steal Planet Devourer plans from Kraylor")
    elseif comms_source.plan_extractor == "extracted" then
        secondary_orders = _(
            "orders-comms",
            "Deliver stolen Planet Devourer plans to friendly station"
        )
    end
    if comms_source.virus_upload == "enabled" then
        secondary_orders = _("orders-comms", "Upload virus to Planet Devourer")
    end
end
setOptionalOrders = MissionMenu.clearOptionalOrdersSnakeCase
-----------------------
-- Ship communication --
------------------------
ship_profile = {
    enemy = enemyComms,
    main_menu = commsShip,
    goods_name = function(good)
        return good_desc[good]
    end,
    friendly_status_destination = true,
    can_dock = function()
        return comms_target:getTypeName() ~= "Defense platform"
    end,
    neutral_destination_query = true,
}
function spawnSingleEnemy(
    xOrigin,
    yOrigin,
    danger,
    enemyFaction,
    enemyStrength,
    template_pool
)
    if enemyFaction == nil then
        enemyFaction = "Kraylor"
    end
    if danger == nil then
        danger = 1
    end
    if enemyStrength == nil then
        enemyStrength = math.max(danger * enemy_power * playerPower(), 5)
    end
    if template_pool == nil then
        template_pool_size = 15
        pool_selectivity = "less/heavy"
        template_pool = getTemplatePool(enemyStrength)
        pool_selectivity = "full"
    end
    if #template_pool < 1 then
        print("Empty Template pool: fix excludes or other criteria")
        return
    end
    local selected_template = template_pool[math.random(1, #template_pool)]
    local ship =
        ship_template[selected_template].create(enemyFaction, selected_template)
    ship:setCallSign(generateCallSign(nil, enemyFaction)):orderRoaming()
    ship:setPosition(xOrigin, yOrigin)
    ship:setCommsScript(""):setCommsFunction(commsShip)
    return ship
end
function spawnEnemies(
    xOrigin,
    yOrigin,
    danger,
    enemyFaction,
    enemyStrength,
    template_pool,
    shape,
    spawn_distance,
    spawn_angle,
    px,
    py
)
    if enemyFaction == nil then
        enemyFaction = "Kraylor"
    end
    if danger == nil then
        danger = 1
    end
    if enemyStrength == nil then
        enemyStrength = math.max(danger * enemy_power * playerPower(), 5)
    end
    local original_enemy_strength = enemyStrength
    local enemy_position = 0
    local sp = irandom(400, 900) --random spacing of spawned group
    if shape == nil then
        shape = "square"
        if random(1, 100) < 50 then
            shape = "hexagonal"
        end
    end
    local enemyList = {}
    if template_pool == nil then
        template_pool_size = 15
        template_pool = getTemplatePool(enemyStrength)
    end
    if #template_pool < 1 then
        addGMMessage("Empty Template pool: fix excludes or other criteria")
        return enemyList, original_enemy_strength
    end
    while enemyStrength > 0 do
        local selected_template = template_pool[math.random(1, #template_pool)]
        if spawn_enemy_diagnostic then
            print(
                "Spawn Enemies selected template:",
                selected_template,
                "template pool:",
                template_pool,
                "ship template:",
                ship_template,
                "Enemy faction:",
                enemyFaction
            )
        end
        local ship = ship_template[selected_template].create(
            enemyFaction,
            selected_template
        )
        ship:setCallSign(generateCallSign(nil, enemyFaction)):orderRoaming()
        enemy_position = enemy_position + 1
        if shape == "none" or shape == "pyramid" or shape == "ambush" then
            ship:setPosition(xOrigin, yOrigin)
        else
            ship:setPosition(
                xOrigin + formation_delta[shape].x[enemy_position] * sp,
                yOrigin + formation_delta[shape].y[enemy_position] * sp
            )
        end
        ship:setCommsScript(""):setCommsFunction(commsShip)
        table.insert(enemyList, ship)
        enemyStrength = enemyStrength
            - ship_template[selected_template].strength
    end
    if shape == "pyramid" then
        if spawn_distance == nil then
            spawn_distance = 30
        end
        if spawn_angle == nil then
            spawn_angle = random(0, 360)
        end
        if px == nil then
            px = 0
        end
        if py == nil then
            py = 0
        end
        local pyramid_tier = math.min(#enemyList, max_pyramid_tier)
        for index, ship in ipairs(enemyList) do
            if index <= max_pyramid_tier then
                local pyramid_angle = spawn_angle
                    + formation_delta.pyramid[pyramid_tier][index].angle
                if pyramid_angle < 0 then
                    pyramid_angle = pyramid_angle + 360
                end
                pyramid_angle = pyramid_angle % 360
                rx, ry = vectorFromAngle(
                    pyramid_angle,
                    spawn_distance * 1000
                        + formation_delta.pyramid[pyramid_tier][index].distance
                            * 800
                )
                ship:setPosition(px + rx, py + ry)
            else
                ship:setPosition(px + vx, py + vy)
            end
            ship:setHeading((spawn_angle + 270) % 360)
            ship:orderFlyTowards(px, py)
        end
    end
    if shape == "ambush" then
        if spawn_distance == nil then
            spawn_distance = 5
        end
        if spawn_angle == nil then
            spawn_angle = random(0, 360)
        end
        local circle_increment = 360 / #enemyList
        for i, enemy in ipairs(enemyList) do
            local dex, dey = vectorFromAngle(spawn_angle, spawn_distance * 1000)
            enemy
                :setPosition(xOrigin + dex, yOrigin + dey)
                :setRotation(spawn_angle + 180)
            spawn_angle = spawn_angle + circle_increment
        end
    end
    return enemyList, original_enemy_strength
end

------------------------
-- Update functions  --
------------------------
-- Update loop related functions
function updatePlayerTubeSizeBanner(p)
    if p.tube_size ~= nil then
        local tube_size_banner = string.format(
            _("-tabWeapons&Tactical", "%s tubes: %s"),
            p:getCallSign(),
            p.tube_size
        )
        if #p.tube_size == 1 then
            tube_size_banner = string.format(
                _("-tabWeapons&Tactical", "%s tube: %s"),
                p:getCallSign(),
                p.tube_size
            )
        end
        p.tube_sizes_wea = "tube_sizes_wea"
        p:addCustomInfo("Weapons", p.tube_sizes_wea, tube_size_banner, 5)
        p.tube_sizes_tac = "tube_sizes_tac"
        p:addCustomInfo("Tactical", p.tube_sizes_tac, tube_size_banner, 5)
    end
end
function devourPlanets()
    if devourer.planet_target == nil and ejecta == nil then
        local object_list = devourer:getObjectsInRange(300000)
        local planets = {}
        for i, obj in ipairs(object_list) do
            if isObjectType(obj, "Planet") then
                table.insert(planets, obj)
            end
        end
        local distance_to_planet = 999999
        local selected_planet = nil
        if #planets > 0 then
            for i, planet in ipairs(planets) do
                if distance(devourer, planet) < distance_to_planet then
                    selected_planet = planet
                    distance_to_planet = distance(devourer, planet)
                end
            end
            if selected_planet ~= nil then
                devourer.planet_target = selected_planet
                local px, py = selected_planet:getPosition()
                devourer:orderFlyTowards(px, py)
            end
        else
            globalMessage(
                _("msgMainscreen", "All the planets have been destroyed")
            )
            victory("Kraylor")
        end
    else
        if
            devourer.planet_target ~= nil and devourer.planet_target:isValid()
        then
            if distance(devourer, devourer.planet_target) <= 10000 then
                local dx, dy = devourer:getPosition()
                local px, py = devourer.planet_target:getPosition()
                if devourer.destroy_time == nil then
                    devourer.destroy_time = getScenarioTime()
                    devourer.start_beam_2_time = devourer.destroy_time + 0.5
                    devourer.start_beam_3_time = devourer.destroy_time + 1
                    devourer.start_beam_4_time = devourer.destroy_time + 1.5
                    devourer.start_beam_5_time = devourer.destroy_time + 2
                    devourer.explosion_time = devourer.destroy_time + 5
                    devourer.explosion_emp_time = devourer.destroy_time + 6
                    devourer.explosion_neb_time = devourer.destroy_time + 7
                end
                if
                    getScenarioTime() > devourer.destroy_time
                    and devourer.start_beam_1 == nil
                then
                    devourer.start_beam_1 = "started"
                    BeamEffect()
                        :setSource(devourer, 0, 0, 0)
                        :setTarget(devourer.planet_target, 0, 0)
                        :setBeamFireSoundPower(20)
                        :setDuration(5)
                end
                if
                    getScenarioTime() > devourer.start_beam_2_time
                    and devourer.start_beam_2 == nil
                then
                    devourer.start_beam_2 = "started"
                    BeamEffect()
                        :setSource(devourer, 0, 0, 100)
                        :setTarget(devourer.planet_target, 0, 0)
                        :setBeamFireSoundPower(21)
                        :setDuration(4.5)
                end
                if
                    getScenarioTime() > devourer.start_beam_3_time
                    and devourer.start_beam_3 == nil
                then
                    devourer.start_beam_3 = "started"
                    BeamEffect()
                        :setSource(devourer, 0, 0, -100)
                        :setTarget(devourer.planet_target, 0, 0)
                        :setBeamFireSoundPower(22)
                        :setDuration(4)
                end
                if
                    getScenarioTime() > devourer.start_beam_4_time
                    and devourer.start_beam_4 == nil
                then
                    devourer.start_beam_4 = "started"
                    BeamEffect()
                        :setSource(devourer, 0, 0, 200)
                        :setTarget(devourer.planet_target, 0, 0)
                        :setBeamFireSoundPower(23)
                        :setDuration(3.5)
                end
                if
                    getScenarioTime() > devourer.start_beam_5_time
                    and devourer.start_beam_5 == nil
                then
                    devourer.start_beam_5 = "started"
                    BeamEffect()
                        :setSource(devourer, 0, 0, -200)
                        :setTarget(devourer.planet_target, 0, 0)
                        :setBeamFireSoundPower(24)
                        :setDuration(3)
                end
                if
                    getScenarioTime() > devourer.explosion_time
                    and devourer.explosion == nil
                then
                    devourer.explosion = "started"
                    devourer.px = px
                    devourer.py = py
                    devourer.planet_target:destroy()
                    ExplosionEffect()
                        :setPosition(px, py)
                        :setSize(10000)
                        :setOnRadar(true)
                end
            end
        else
            devourer.planet_target = nil
        end
    end
    if devourer.px ~= nil then
        formerPlanetExplosion(devourer.px, devourer.py)
    end
end
function formerPlanetExplosion(px, py)
    if
        getScenarioTime() > devourer.explosion_emp_time
        and devourer.explosion_emp == nil
    then
        devourer.explosion_emp = "started"
        ElectricExplosionEffect()
            :setPosition(px, py)
            :setSize(10000)
            :setOnRadar(true)
    end
    if ejecta == nil then
        local lo_speed = 20
        local hi_speed = 200
        ejecta = {}
        local nebula_ejecta = 100
        for i = 1, nebula_ejecta do
            local neb = Nebula():setPosition(px, py)
            local angle =
                random((i - 1) * 360 / nebula_ejecta, i * 360 / nebula_ejecta)
            local speed = random(lo_speed, hi_speed)
            local dist = random(5000, 80000)
            local actions = { "dissipate", "stop", "dissipate", "dissipate" }
            local iterations = math.floor(dist / speed)
            table.insert(ejecta, {
                obj = neb,
                dir = angle,
                speed = speed,
                dist = dist,
                action = actions[math.random(1, #actions)],
                iterations = iterations,
                del = false,
            })
        end
        local asteroid_ejecta = 100
        for i = 1, asteroid_ejecta do
            local angle = random(
                (i - 1) * 360 / asteroid_ejecta,
                i * 360 / asteroid_ejecta
            )
            local speed = random(lo_speed, hi_speed)
            local dist = random(5000, 80000)
            local size = random(5, 50) + random(5, 50) + random(5, 200)
            local origin_x, origin_y = vectorFromAngle(angle, size * 3)
            local ast = Asteroid()
                :setPosition(px + origin_x, py + origin_y)
                :setSize(size)
            local actions = { "dissipate", "explode", "stop" }
            local iterations = math.floor(dist / speed)
            table.insert(ejecta, {
                obj = ast,
                dir = angle,
                speed = speed,
                dist = dist,
                action = actions[math.random(1, #actions)],
                iterations = iterations,
                del = false,
            })
        end
        local visual_asteroid_ejecta = 100
        for i = 1, visual_asteroid_ejecta do
            local angle = random(
                (i - 1) * 360 / visual_asteroid_ejecta,
                i * 360 / visual_asteroid_ejecta
            )
            local speed = random(lo_speed, hi_speed)
            local dist = random(5000, 80000)
            local size = random(5, 50) + random(5, 50) + random(5, 200)
            local ast = VisualAsteroid():setPosition(px, py):setSize(size)
            local actions = { "dissipate", "explode", "stop" }
            local iterations = math.floor(dist / speed)
            table.insert(ejecta, {
                obj = ast,
                dir = angle,
                speed = speed,
                dist = dist,
                action = actions[math.random(1, #actions)],
                iterations = iterations,
                del = false,
            })
        end
        local energy_ejecta = 100
        for i = 1, energy_ejecta do
            local angle =
                random((i - 1) * 360 / energy_ejecta, i * 360 / energy_ejecta)
            local speed = random(lo_speed, hi_speed)
            local dist = random(5000, 80000)
            local ene = Artifact()
                :setPosition(px, py)
                :allowPickup(false)
                :setRadarTraceColor(
                    math.random(1, 255),
                    math.random(1, 255),
                    math.random(1, 255)
                )
            local actions = { "dissipate", "explode" }
            local iterations = math.floor(dist / speed)
            table.insert(ejecta, {
                obj = ene,
                dir = angle,
                speed = speed,
                dist = dist,
                action = actions[math.random(1, #actions)],
                iterations = iterations,
                del = false,
            })
        end
    else
        if #ejecta > 0 then
            for i = 1, #ejecta do
                local ej = ejecta[i]
                local obj = ej.obj
                if obj ~= nil and obj:isValid() then
                    local ox, oy = obj:getPosition()
                    setCirclePos(obj, ox, oy, ej.dir, ej.speed)
                    ej.iterations = ej.iterations - 1
                    if ej.iterations <= 0 then
                        if ej.action == "dissipate" then
                            obj:destroy()
                            ej.obj = nil
                            ej.del = true
                        elseif ej.action == "stop" then
                            ej.obj = nil
                            ej.del = true
                        elseif ej.action == "explode" then
                            if isObjectType(obj, "Artifact") then
                                obj:explode()
                            else
                                local ex, ey = obj:getPosition()
                                obj:destroy()
                                ExplosionEffect()
                                    :setPosition(ex, ey)
                                    :setSize(100)
                            end
                            ej.obj = nil
                            ej.del = true
                        end
                    else
                        ej.speed = ej.speed - random(0, 10)
                    end
                else
                    ej.obj = nil
                    ej.del = true
                end
            end
            for i = #ejecta, 1, -1 do
                if ejecta[i].del then
                    ejecta[i] = ejecta[#ejecta]
                    ejecta[#ejecta] = nil
                end
            end
        else
            ejecta = nil
            devourer.planet_target = nil
            devourer.destroy_time = nil
            devourer.start_beam_2_time = nil
            devourer.start_beam_3_time = nil
            devourer.start_beam_4_time = nil
            devourer.start_beam_5_time = nil
            devourer.explosion_time = nil
            devourer.explosion_emp_time = nil
            devourer.explosion_neb_time = nil
            devourer.start_beam_1 = nil
            devourer.start_beam_2 = nil
            devourer.start_beam_3 = nil
            devourer.start_beam_4 = nil
            devourer.start_beam_5 = nil
            devourer.explosion = nil
            devourer.px = nil
            devourer.py = nil
            devourer.explosion_emp = nil
        end
    end
end
function stealPlans(p)
    if station_kraylor ~= nil and station_kraylor:isValid() then
        if p.plan_extractor == "installed" then
            if distance(p, station_kraylor) < 2500 then
                if p.extract_time ~= nil then
                    if getScenarioTime() > p.extract_time then
                        p.plan_extractor = "extracted"
                        if p.extracted_award == nil then
                            p.extracted_award = "given"
                            p:addReputationPoints(50)
                        end
                        p:removeCustom(p.extract_info_eng)
                        p:removeCustom(p.extract_info_epl)
                        p:removeCustom(p.extract_info_hlm)
                        p.plans_extracted_msg_eng = "plans_extracted_msg_eng"
                        p:addCustomMessage(
                            "Engineering",
                            p.plans_extracted_msg_eng,
                            string.format(
                                _(
                                    "mission-msgEngineer",
                                    "The technical readouts for %s have been extracted from the databanks on Kraylor station %s"
                                ),
                                devourer:getCallSign(),
                                station_kraylor:getCallSign()
                            )
                        )
                        p.plans_extracted_msg_epl = "plans_extracted_msg_epl"
                        p:addCustomMessage(
                            "Engineering+",
                            p.plans_extracted_msg_epl,
                            string.format(
                                _(
                                    "mission-msgEngineer+",
                                    "The technical readouts for %s have been extracted from the databanks on Kraylor station %s"
                                ),
                                devourer:getCallSign(),
                                station_kraylor:getCallSign()
                            )
                        )
                        p.plans_extracted_msg_dmg = "plans_extracted_msg_dmg"
                        p:addCustomMessage(
                            "DamageControl",
                            p.plans_extracted_msg_dmg,
                            string.format(
                                _(
                                    "mission-msgDamageControl",
                                    "The technical readouts for %s have been extracted from the databanks on Kraylor station %s"
                                ),
                                devourer:getCallSign(),
                                station_kraylor:getCallSign()
                            )
                        )
                    else
                        p.extract_info_eng = "extract_info_eng"
                        p:addCustomInfo(
                            "Engineering",
                            p.extract_info_eng,
                            string.format(
                                _("mission-tabEngineer", "Extract timer:%i"),
                                math.floor(p.extract_time - getScenarioTime())
                            ),
                            30
                        )
                        p.extract_info_epl = "extract_info_epl"
                        p:addCustomInfo(
                            "Engineering+",
                            p.extract_info_epl,
                            string.format(
                                _("mission-tabEngineer+", "Extract timer:%i"),
                                math.floor(p.extract_time - getScenarioTime())
                            ),
                            30
                        )
                        p.extract_info_dmg = "extract_info_dmg"
                        p:addCustomInfo(
                            "DamageControl",
                            p.extract_info_dmg,
                            string.format(
                                _(
                                    "mission-tabDamageControl",
                                    "Extract timer:%i"
                                ),
                                math.floor(p.extract_time - getScenarioTime())
                            ),
                            30
                        )
                        p.extract_info_hlm = "extract_info_hlm"
                        p:addCustomInfo(
                            "Helms",
                            p.extract_info_hlm,
                            string.format(
                                _("mission-tabHelms", "Extract timer:%i"),
                                math.floor(p.extract_time - getScenarioTime())
                            ),
                            30
                        )
                    end
                else
                    if p.extract_button_eng == nil then
                        p.extract_button_eng = "extract_button_eng"
                        p:addCustomButton(
                            "Engineering",
                            p.extract_button_eng,
                            _("mission-buttonEngineer", "Extract Plans"),
                            function()
                                p:removeCustom(p.extract_button_eng)
                                p:removeCustom(p.extract_button_epl)
                                p:removeCustom(p.extract_button_dmg)
                                p.extract_time = getScenarioTime() + 47
                                p.extract_info_eng = "extract_info_eng"
                                p:addCustomInfo(
                                    "Engineering",
                                    p.extract_info_eng,
                                    string.format(
                                        _(
                                            "mission-tabEngineer",
                                            "Extract timer:%i"
                                        ),
                                        math.floor(
                                            p.extract_time - getScenarioTime()
                                        )
                                    ),
                                    30
                                )
                                p.extract_info_epl = "extract_info_epl"
                                p:addCustomInfo(
                                    "Engineering+",
                                    p.extract_info_epl,
                                    string.format(
                                        _(
                                            "mission-tabEngineer+",
                                            "Extract timer:%i"
                                        ),
                                        math.floor(
                                            p.extract_time - getScenarioTime()
                                        )
                                    ),
                                    30
                                )
                                p.extract_info_dmg = "extract_info_dmg"
                                p:addCustomInfo(
                                    "DamageControl",
                                    p.extract_info_dmg,
                                    string.format(
                                        _(
                                            "mission-tabDamageControl",
                                            "Extract timer:%i"
                                        ),
                                        math.floor(
                                            p.extract_time - getScenarioTime()
                                        )
                                    ),
                                    30
                                )
                                p.extract_info_hlm = "extract_info_hlm"
                                p:addCustomInfo(
                                    "Helms",
                                    p.extract_info_hlm,
                                    string.format(
                                        _(
                                            "mission-tabHelms",
                                            "Extract timer:%i"
                                        ),
                                        math.floor(
                                            p.extract_time - getScenarioTime()
                                        )
                                    ),
                                    30
                                )
                            end,
                            29
                        )
                    end
                    if p.extract_button_epl == nil then
                        p.extract_button_epl = "extract_button_epl"
                        p:addCustomButton(
                            "Engineering+",
                            p.extract_button_epl,
                            _("mission-buttonEngineer+", "Extract Plans"),
                            function()
                                p:removeCustom(p.extract_button_epl)
                                p:removeCustom(p.extract_button_eng)
                                p:removeCustom(p.extract_button_dmg)
                                p.extract_time = getScenarioTime() + 47
                                p.extract_info_eng = "extract_info_eng"
                                p:addCustomInfo(
                                    "Engineering",
                                    p.extract_info_eng,
                                    string.format(
                                        _(
                                            "mission-tabEngineer",
                                            "Extract timer:%i"
                                        ),
                                        math.floor(
                                            p.extract_time - getScenarioTime()
                                        )
                                    ),
                                    30
                                )
                                p.extract_info_epl = "extract_info_epl"
                                p:addCustomInfo(
                                    "Engineering+",
                                    p.extract_info_epl,
                                    string.format(
                                        _(
                                            "mission-tabEngineer+",
                                            "Extract timer:%i"
                                        ),
                                        math.floor(
                                            p.extract_time - getScenarioTime()
                                        )
                                    ),
                                    30
                                )
                                p.extract_info_dmg = "extract_info_dmg"
                                p:addCustomInfo(
                                    "DamageControl",
                                    p.extract_info_dmg,
                                    string.format(
                                        _(
                                            "mission-tabDamageControl",
                                            "Extract timer:%i"
                                        ),
                                        math.floor(
                                            p.extract_time - getScenarioTime()
                                        )
                                    ),
                                    30
                                )
                                p.extract_info_hlm = "extract_info_hlm"
                                p:addCustomInfo(
                                    "Helms",
                                    p.extract_info_hlm,
                                    string.format(
                                        _(
                                            "mission-tabHelms",
                                            "Extract timer:%i"
                                        ),
                                        math.floor(
                                            p.extract_time - getScenarioTime()
                                        )
                                    ),
                                    30
                                )
                            end,
                            29
                        )
                    end
                    if p.extract_button_dmg == nil then
                        p.extract_button_dmg = "extract_button_dmg"
                        p:addCustomButton(
                            "DamageControl",
                            p.extract_button_dmg,
                            _("mission-buttonDamageControl", "Extract Plans"),
                            function()
                                p:removeCustom(p.extract_button_eng)
                                p:removeCustom(p.extract_button_epl)
                                p:removeCustom(p.extract_button_dmg)
                                p.extract_time = getScenarioTime() + 47
                                p.extract_info_eng = "extract_info_eng"
                                p:addCustomInfo(
                                    "Engineering",
                                    p.extract_info_eng,
                                    string.format(
                                        _(
                                            "mission-tabEngineer",
                                            "Extract timer:%i"
                                        ),
                                        math.floor(
                                            p.extract_time - getScenarioTime()
                                        )
                                    ),
                                    30
                                )
                                p.extract_info_epl = "extract_info_epl"
                                p:addCustomInfo(
                                    "Engineering+",
                                    p.extract_info_epl,
                                    string.format(
                                        _(
                                            "mission-tabEngineer+",
                                            "Extract timer:%i"
                                        ),
                                        math.floor(
                                            p.extract_time - getScenarioTime()
                                        )
                                    ),
                                    30
                                )
                                p.extract_info_dmg = "extract_info_dmg"
                                p:addCustomInfo(
                                    "DamageControl",
                                    p.extract_info_dmg,
                                    string.format(
                                        _(
                                            "mission-tabDamageControl",
                                            "Extract timer:%i"
                                        ),
                                        math.floor(
                                            p.extract_time - getScenarioTime()
                                        )
                                    ),
                                    30
                                )
                                p.extract_info_hlm = "extract_info_hlm"
                                p:addCustomInfo(
                                    "Helms",
                                    p.extract_info_hlm,
                                    string.format(
                                        _(
                                            "mission-tabHelms",
                                            "Extract timer:%i"
                                        ),
                                        math.floor(
                                            p.extract_time - getScenarioTime()
                                        )
                                    ),
                                    30
                                )
                            end,
                            29
                        )
                    end
                end
            else
                if p.extract_info_eng ~= nil then
                    p:removeCustom(p.extract_info_eng)
                    p.extract_info_eng = nil
                end
                if p.extract_info_epl ~= nil then
                    p:removeCustom(p.extract_info_epl)
                    p.extract_info_epl = nil
                end
                if p.extract_button_eng ~= nil then
                    p:removeCustom(p.extract_button_eng)
                    p.extract_button_eng = nil
                end
                if p.extract_button_epl ~= nil then
                    p:removeCustom(p.extract_button_epl)
                    p.extract_button_epl = nil
                end
                p.extract_time = nil
            end
        end
    end
end
function deployVirus(p)
    if devourer ~= nil and devourer:isValid() then
        if p.devourer_nerfed_eng == nil and p.devourer_nerfed_epl == nil then
            if distance(p, devourer) < 3000 then
                p.deploy_virus_eng = "deploy_virus_eng"
                p:addCustomButton(
                    "Engineering",
                    p.deploy_virus_eng,
                    _("mission-buttonEngineer", "Upload Virus"),
                    function()
                        p:removeCustom(p.deploy_virus_eng)
                        p:removeCustom(p.deploy_virus_epl)
                        p:removeCustom(p.deploy_virus_dmg)
                        nerfDevourer()
                        if p.nerf_award == nil then
                            p.nerf_award = "given"
                            p:addReputationPoints(100)
                        end
                        p.devourer_nerfed_eng = "devourer_nerfed_eng"
                        p:addCustomMessage(
                            "Engineering",
                            p.devourer_nerfed_eng,
                            string.format(
                                _(
                                    "mission-msgEngineer",
                                    "The virus has been uploaded to %s. A portion of the Planet Devourer's beam and missile systems have entered maintenance mode."
                                ),
                                devourer:getCallSign()
                            )
                        )
                    end,
                    33
                )
                p.deploy_virus_epl = "deploy_virus_epl"
                p:addCustomButton(
                    "Engineering+",
                    p.deploy_virus_epl,
                    _("mission-buttonEngineer+", "Upload Virus"),
                    function()
                        p:removeCustom(p.deploy_virus_epl)
                        p:removeCustom(p.deploy_virus_eng)
                        p:removeCustom(p.deploy_virus_dmg)
                        nerfDevourer()
                        if p.nerf_award == nil then
                            p.nerf_award = "given"
                            p:addReputationPoints(100)
                        end
                        p.devourer_nerfed_epl = "devourer_nerfed_epl"
                        p:addCustomMessage(
                            "Engineering+",
                            p.devourer_nerfed_epl,
                            string.format(
                                _(
                                    "mission-msgEngineer+",
                                    "The virus has been uploaded to %s. A portion of the Planet Devourer's beam and missile systems have entered maintenance mode."
                                ),
                                devourer:getCallSign()
                            )
                        )
                    end,
                    33
                )
                p.deploy_virus_dmg = "deploy_virus_dmg"
                p:addCustomButton(
                    "DamageControl",
                    p.deploy_virus_dmg,
                    _("mission-buttonDamageControl", "Upload Virus"),
                    function()
                        p:removeCustom(p.deploy_virus_epl)
                        p:removeCustom(p.deploy_virus_eng)
                        p:removeCustom(p.deploy_virus_dmg)
                        nerfDevourer()
                        if p.nerf_award == nil then
                            p.nerf_award = "given"
                            p:addReputationPoints(100)
                        end
                        p.devourer_nerfed_dmg = "devourer_nerfed_dmg"
                        p:addCustomMessage(
                            "DamageControl",
                            p.devourer_nerfed_dmg,
                            string.format(
                                _(
                                    "mission-msgDamageControl",
                                    "The virus has been uploaded to %s. A portion of the Planet Devourer's beam and missile systems have entered maintenance mode."
                                ),
                                devourer:getCallSign()
                            )
                        )
                    end,
                    33
                )
            else
                if p.deploy_virus_eng ~= nil then
                    p:removeCustom(p.deploy_virus_eng)
                    p.deploy_virus_eng = nil
                end
                if p.deploy_virus_epl ~= nil then
                    p:removeCustom(p.deploy_virus_epl)
                    p.deploy_virus_epl = nil
                end
                if p.deploy_virus_dmg ~= nil then
                    p:removeCustom(p.deploy_virus_dmg)
                    p.deploy_virus_dmg = nil
                end
            end
        end
    end
end
function nerfDevourer()
    if devourer ~= nil and devourer:isValid() then
        --  Arc, Dir, Range, Cycle, Damage
        devourer:setBeamWeapon(0, 90, 0, 1000, 30, 10)
        devourer:setBeamWeapon(1, 90, 22.5, 1000, 30, 10)
        devourer:setBeamWeapon(2, 90, 45, 1000, 30, 10)
        devourer:setBeamWeapon(3, 90, 67.5, 1000, 30, 10)
        devourer:setTubeLoadTime(0, 180)
        devourer:setTubeLoadTime(1, 180)
        devourer:setTubeLoadTime(2, 180)
        if difficulty <= 1 then
            --  Arc, Dir, Range, Cycle, Damage
            devourer:setBeamWeapon(4, 90, 0, 1000, 30, 10)
            devourer:setBeamWeapon(5, 90, 22.5, 1000, 30, 10)
            devourer:setTubeLoadTime(3, 180)
            devourer:setTubeLoadTime(4, 180)
            devourer:setTubeLoadTime(5, 180)
        end
        if difficulty < 1 then
            --  Arc, Dir, Range, Cycle, Damage
            devourer:setBeamWeapon(6, 90, 0, 1000, 30, 10)
            devourer:setBeamWeapon(7, 90, 22.5, 1000, 30, 10)
            devourer:setTubeLoadTime(6, 180)
            devourer:setTubeLoadTime(7, 180)
            devourer:setTubeLoadTime(8, 180)
        end
    end
end
function approachDevourer(p)
    if devourer ~= nil and devourer:isValid() then
        if distance(p, devourer) < 5000 then
            approached_devourer = true
            if p.approach_award == nil then
                p.approach_award = "given"
                p:addReputationPoints(20)
            end
        end
    end
end
function prepareDevourerExplosion(self, instigator)
    dev_explode_x, dev_explode_y = self:getPosition()
end
function explodeDevourer()
    if dev_explode_x ~= nil then
        if dev_ejecta == nil then
            local lo_speed = 20
            local hi_speed = 200
            dev_ejecta = {}
            local visual_asteroid_ejecta = 100
            for i = 1, visual_asteroid_ejecta do
                local angle = random(
                    (i - 1) * 360 / visual_asteroid_ejecta,
                    i * 360 / visual_asteroid_ejecta
                )
                local speed = random(lo_speed, hi_speed)
                local dist = random(5000, 10000)
                local size = random(5, 50) + random(5, 50) + random(5, 200)
                local ast = VisualAsteroid()
                    :setPosition(dev_explode_x, dev_explode_y)
                    :setSize(size)
                local actions = { "dissipate", "stop" }
                local iterations = math.floor(dist / speed)
                table.insert(dev_ejecta, {
                    obj = ast,
                    dir = angle,
                    speed = speed,
                    dist = dist,
                    action = actions[math.random(1, #actions)],
                    iterations = iterations,
                    del = false,
                })
            end
        else
            if #dev_ejecta > 0 then
                for i = 1, #dev_ejecta do
                    local ej = dev_ejecta[i]
                    local obj = ej.obj
                    if obj ~= nil and obj:isValid() then
                        local ox, oy = obj:getPosition()
                        local dx, dy = vectorFromAngleNorth(ej.dir, ej.speed)
                        obj:setPosition(ox + dx, oy + dy)
                        ej.iterations = ej.iterations - 1
                        if ej.iterations <= 0 then
                            if ej.action == "dissipate" then
                                obj:destroy()
                                ej.obj = nil
                                ej.del = true
                            elseif ej.action == "stop" then
                                ej.obj = nil
                                ej.del = true
                            end
                        else
                            ej.speed = ej.speed - random(0, 10)
                        end
                    else
                        ej.obj = nil
                        ej.del = true
                    end
                end
                for i = #dev_ejecta, 1, -1 do
                    if dev_ejecta[i].del then
                        dev_ejecta[i] = dev_ejecta[#dev_ejecta]
                        dev_ejecta[#dev_ejecta] = nil
                    end
                end
            else
                local object_list =
                    getObjectsInRadius(center_x, center_y, 300000)
                local planet_count = 0
                for i, obj in ipairs(object_list) do
                    if isObjectType(obj, "Planet") then
                        planet_count = planet_count + 1
                    end
                end
                globalMessage(
                    string.format(
                        _(
                            "msgMainscreen",
                            "Planet Devourer destroyed. %i out of 5 planets saved."
                        ),
                        planet_count
                    )
                )
                victory("Human Navy")
            end
        end
    end
end
function defendDevourer(p)
    if devourer ~= nil and devourer:isValid() then
        if distance(p, devourer) < 8000 then
            if p.devourer_fleet == nil then
                p.devourer_fleet = getScenarioTime() + 700 - (difficulty * 60)
                local start_angle = random(0, 360)
                local spawn_dist = 3500
                local fleet_prefix = generateCallSignPrefix()
                local wing_count = 3
                if difficulty < 1 then
                    wing_count = 2
                elseif difficulty > 1 then
                    wing_count = 5
                end
                for i = 1, wing_count do
                    local fwc_x, fwc_y = devourer:getPosition()
                    local spawn_angle = start_angle + 360 / wing_count * i
                    local dc_x, dc_y =
                        vectorFromAngleNorth(spawn_angle, spawn_dist)
                    local ship = ship_template["MV52 Hornet"].create(
                        devourer:getFaction(),
                        "MV52 Hornet"
                    )
                    ship:setPosition(fwc_x + dc_x, fwc_y + dc_y)
                        :setHeading(spawn_angle)
                        :orderDefendTarget(devourer)
                    ship:setCallSign(generateCallSign(fleet_prefix))
                end
            elseif getScenarioTime() > p.devourer_fleet then
                p.devourer_fleet = nil
            end
        end
    end
end
-- Mortal repair crew functions. Includes coolant loss as option to losing repair crew
--      Inventory button and functions for relay/operations

function updateInner(delta)
    if delta == 0 then
        --game paused
        for pidx, p in ipairs(getActivePlayerShips()) do
            if p.pidx == nil then
                p.pidx = pidx
                setPlayers(p)
            end
        end
        return
    end
    if not isPerSystemDamageUsed() then
        reason = _(
            "msgMainscreen",
            "Scenario needs the 'Per-system damage' option under 'Extra settings'"
        )
        globalMessage(reason)
        setBanner(reason)
        victory("Kraylor")
    end
    if mainGMButtons == mainGMButtonsDuringPause then
        mainGMButtons = mainGMButtonsAfterPause
        mainGMButtons()
    end
    if devourer ~= nil and devourer:isValid() then
        devourPlanets()
    end
    explodeDevourer()
    for i, p in ipairs(getActivePlayerShips()) do
        if p.start_message == nil then
            p:addToShipLog(
                string.format(
                    _(
                        "goal-shipLog",
                        "From: Headquarters\nTo: Captain and crew of %s\nThe Kraylor have decided to field test some newly developed weaponry. All we know is that it's big. Find out what they are up to. If, as usual, they are up to no good, stop them.\nGood luck."
                    ),
                    p:getCallSign()
                ),
                "Magenta"
            )
            p.start_message = "sent"
        end
        if p.more_info_message == nil then
            if getScenarioTime() > 60 then
                if availableForComms(p) then
                    local friendly_station = nil
                    for j, station in ipairs(station_list) do
                        if station ~= nil and station:isValid() then
                            if station:isFriendly(p) then
                                friendly_station = station
                                break
                            end
                        end
                    end
                    if friendly_station ~= nil then
                        local output_message = _(
                            "mission-incCall",
                            "We intercepted some Kraylor transmissions on that weapons test. They say they are going to demonstrate the destructive power of their ultimate force in the universe. This is starting to sound like the plot from a late 20th century space opera movie...\nAnyway, the ship type is the Planet Devourer (not the Death Star for all you 20th century movie history buffs). We expect the Kraylor to wantonly destroy all the planets in the area, because that's just the kind of beings they are."
                        )
                        if devourer ~= nil and devourer:isValid() then
                            output_message = string.format(
                                _(
                                    "mission-incCall",
                                    "We intercepted some Kraylor transmissions on that weapons test. They say they are going to demonstrate the destructive power of their ultimate force in the universe. This is starting to sound like the plot from a late 20th century space opera movie...\nAnyway, the ship name is the %s (not the Death Star for all you 20th century movie history buffs). The ship class is Planet Devourer. We expect the Kraylor to wantonly destroy all the planets in the area, because that's just the kind of beings they are."
                                ),
                                devourer:getCallSign()
                            )
                        end
                        friendly_station:sendCommsMessage(p, output_message)
                        p.more_info_message = "sent"
                    end
                end
            end
        end
        if enforce_end then
            maintainEndEnforcers(p)
        end
        defendDevourer(p)
        updatePlayerLongRangeSensors(p)
        updatePlayerTubeSizeBanner(p)
        if not approached_devourer then
            approachDevourer(p)
        end
        stealPlans(p)
        if p.virus_upload ~= nil then
            deployVirus(p)
        end
        p.name_tag_hlm = "name_tag_hlm"
        p:addCustomInfo(
            "Helms",
            p.name_tag_hlm,
            string.format(
                _("mission-tabHelms", "%s %s in %s"),
                p:getFaction(),
                p:getCallSign(),
                p:getSectorName()
            ),
            3
        )
        p.name_tag_tac = "name_tag_tac"
        p:addCustomInfo(
            "Tactical",
            p.name_tag_tac,
            string.format(
                _("mission-tabTactical", "%s %s in %s"),
                p:getFaction(),
                p:getCallSign(),
                p:getSectorName()
            ),
            3
        )
    end
    if maintenancePlot ~= nil then
        maintenancePlot(delta)
    end
    if plotCI ~= nil then --cargo inventory
        plotCI(delta)
    end
    if plotH ~= nil then --health
        plotH(delta)
    end
    if plotRevert ~= nil then
        plotRevert(delta)
    end
    if plotContinuum ~= nil then
        plotContinuum(delta)
    end
end
update = Runtime.protectedUpdate(updateInner, {
    popup = function() return popupGMDebug end,
    set_popup = function(value) popupGMDebug = value end,
    message = function() return "script error - \n" end,
})
