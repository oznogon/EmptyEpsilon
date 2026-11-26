-- Name: Doomed Outpost
-- Description: Far from home, an isolated outpost tries to survive a hostile environment. This scenario starts off simply enough, but the challenges are significant. It's not recommended for those players that want to reach victory nearly every game or feel claustrophobic starting in a starship with limited capabilities.
---
--- Designed to run with one or more player ships with different terrain each time. Player ships start off with more limited capabilities than usual, but can easily be upgraded beyond the normal player ship capabilities.
--- Rank awarded at the end of the mission from lowest to highest: Cadet, Acting Ensign, Ensign, Lieutenant, Commander, Captain, Admiral
---
--- Duration: About an hour if you play to the first major attack. If you survive the first major attack and wish to attempt a victory, it could take five hours or more. Know your real life time constraints before you start.
---
--- Version 2
---
--- USN Discord: https://discord.gg/PntGG3a where you can join a game online. There's one every Saturday at 1600 UTC (aka GMT or Zulu). All experience levels are welcome.
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
-- Setting[Pace]: How slow or fast do the enemies get more powerful
-- Pace[Glacial]: The slowest pace
-- Pace[Snail]: Slower than slow pacing
-- Pace[Slow]: Slower than normal pacing
-- Pace[Normal|Default]: Normal pacing
-- Pace[Fast]: Faster than normal pacing
-- Pace[Impatient]: Faster than fast pacing
-- Pace[Blitz]: Fastest pace
-- Setting[Reputation]: Amount of reputation to start with
-- Reputation[Unknown|Default]: Zero reputation - nobody knows anything about you
-- Reputation[Nice]: 20 reputation - you've had a small positive influence on the local community
-- Reputation[Hero]: 50 reputation - you helped important people or lots of people
-- Reputation[Major Hero]: 100 reputation - you're well known by nearly everyone as a force for good
-- Reputation[Super Hero]: 200 reputation - everyone knows you and relies on you for help
-- Setting[Upgrade]: General price of upgrades to player ships
-- Upgrade[Cheap]: Lower priced player ship upgrades
-- Upgrade[Normal|Default]: Normal price for player ship upgrades
-- Upgrade[Expensive]: Higher priced player ship upgrades
-- Upgrade[Luxurious]: Very high prices for player ship upgrades
-- Upgrade[Monopolistic]: Extremely high prices for player ship upgrades
-- Setting[Unique Ship]: Choose player ship outside of standard player ship list
-- Unique Ship[None|Default]: None: just use standard player ship list on spawn screen
-- Unique Ship[Amalgam]: Based on Atlantis, 4 beams (vs 2), single broadside tube on each side for large homing missiles only, 2 mining tubes, weaker defenses and engines
-- Unique Ship[Midian]: Based on missile cruiser, reduced tubes, missiles and base warp speed to get beam weapons and HVLI
-- Unique Ship[Raven]: Based on Cruiser, stronger shields, weaker hull, broadside beams, tweaked tubes and missiles, low powered warp drive, tweaked sensor ranges
-- Unique Ship[Squid]: Based on Piranha, stronger defenses, added a beam weapon, reduced missile load, large homing missiles, reconfigured tubes, shorter jump and sensor ranges

require("utils.lua")
require("place_station_scenario_utility.lua")
require("player_ship_upgrade_downgrade_path_scenario_utility.lua")
local Fleet = require("spawn_ships_scenario_utility.lua")
local friendlyVesselDestroyed = Fleet.noopDestroyed

local Heading = require("heading_scenario_utility.lua")
local vectorFromAngleNorth = Heading.north(vectorFromAngle)

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
require("control_code_scenario_utility.lua")
require("cpu_ship_diversification_scenario_utility.lua")
require("generate_call_sign_scenario_utility.lua")
local Environment = require("environment_scenario_utility.lua")
local moonCollisionCheck = Environment.moonCollisionCheck
local environmentObject = Environment.environmentObject
local farEnough = Environment.farEnough
local placeAsteroid = Environment.placeAsteroid
local placeAsteroidField = Environment.placeAsteroidField
local placeBlackHole = Environment.placeBlackHole
local placeMine = Environment.placeMine
local placeMineField = Environment.placeMineField
local placeNebula = Environment.placeNebula
local placeProbe = Environment.placeProbe
local placeWormHole = Environment.placeWormHole
local placeStar = Environment.placeStar
local placeRandomAsteroidsAroundPoint = Environment.asteroidsAroundPointCoarse
local createRandomAlongArc = Environment.createRandomAlongArcNorth
local createRandomAsteroidAlongArc = Environment.createRandomAsteroidAlongArc
local defaults = require("defaults_scenario_utility.lua")
local ShipNames = require("player_ship_names_scenario_utility.lua")
local PlayerState = require("player_state_scenario_utility.lua")
local updatePlayerTubeSizeBanner = PlayerState.updatePlayerTubeSizeBanner
local ShipStatus = require("ship_status_scenario_utility.lua")
local ServiceOptions = require("comms_service_options.lua")
local neutralServiceJonqueComms = ServiceOptions.neutralServiceJonqueComms
local friendlyServiceJonqueComms = ServiceOptions.friendlyServiceJonqueComms
local ShipComms = require("comms_ship_support.lua")
local StationCore = require("comms_station_core.lua")
local StationMenu = require("comms_station_menu.lua")
local StationMissions = require("comms_station_missions.lua")
local Inventory = require("inventory_scenario_utility.lua")
local playerShipCargoInventory = Inventory.renderer(function() return good_desc end)
local cargoInventory = Inventory.buttons(32, playerShipCargoInventory)
local spawnSingleEnemy = Fleet.singleEnemySpawner({
    catalog = function() return ship_template end,
    enemy_power = function() return enemy_power end,
    player_power = playerPower,
    pool = getTemplatePool,
    configure_pool = function()
        template_pool_size = 5
        pool_selectivity = "less/heavy"
    end,
    restore_pool = function() pool_selectivity = "full" end,
    callsign = generateCallSign,
    comms = function() return commsShip end,
})

local Runtime = require("runtime_scenario_utility.lua")

local Sensor = require("sensor_scenario_utility.lua")
local Continuum = require("continuum_scenario_utility.lua")
local Transport = require("transport_scenario_utility.lua")
local pickTransportTarget = Transport.pickTransportTarget
local randomTransportType = Transport.randomTransportTypeExtended
local function placeTransport(axis)
    return Environment.placeTransport(axis, randomTransportType)
end
local transportCommerceMaintenance = Transport.transportCommerceMaintenance
local warpJammerMaintenance = Transport.warpJammerMaintenance(function() return transportCommerceMaintenance end)

local checkContinuum = Continuum.checkContinuum
local resetContinuum = Continuum.resetContinuum
local revertCheck = Continuum.revertCheck
local revertWait = Continuum.revertWait

local sensorJammer = Sensor.sensorJammerExtended
local function placeSensorJammer(axis)
    return Environment.placeSensorJammer(axis, sensorJammer)
end
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

local enemyComms = ShipComms.enemyComms
local getEnemyHealth = ShipComms.getEnemyHealth
local goodsOnShip = ShipComms.goodsOnShip

local commonServiceOptions = ServiceOptions.commonServiceOptions

local ship_profile
commsShip = ShipComms.commsShipGetter(function() return ship_profile end)
commsServiceJonque = ServiceOptions.serviceJonque({
    friendly = friendlyServiceJonqueComms,
    neutral = neutralServiceJonqueComms,
    enemy = enemyComms,
})

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
    scenario_version = "2.0.1"
    ee_version = "2024.12.08"
    print(
        string.format(
            "    ----    Scenario: Doomed Outpost    ----    Version %s    ----    Tested with EE version %s    ----",
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
    mainGMButtons = mainGMButtonsDuringPause
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
        upgrade_price = 1
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
        local pacing_config = {
            ["Glacial"] = 600,
            ["Snail"] = 450,
            ["Slow"] = 300,
            ["Normal"] = 250,
            ["Fast"] = 200,
            ["Impatient"] = 150,
            ["Blitz"] = 100,
        }
        danger_pace = pacing_config[getScenarioSetting("Pace")]
        local reputation_config = {
            ["Unknown"] = 0,
            ["Nice"] = 20,
            ["Hero"] = 50,
            ["Major Hero"] = 100,
            ["Super Hero"] = 200,
        }
        reputation_start_amount =
            reputation_config[getScenarioSetting("Reputation")]
        local upgrade_config = {
            ["Cheap"] = 0.5,
            ["Normal"] = 1,
            ["Expensive"] = 1.5,
            ["Luxurious"] = 2,
            ["Monopolistic"] = 3,
        }
        upgrade_price = upgrade_config[getScenarioSetting("Upgrade")]
        local player_ship_config = {
            ["Amalgam"] = createPlayerShipMixer,
            ["Midian"] = createPlayerShipFlipper,
            ["Raven"] = createPlayerShipClaw,
            ["Squid"] = createPlayerShipInk,
        }
        if getScenarioSetting("Unique Ship") ~= "None" then
            player_ship_config[getScenarioSetting("Unique Ship")]()
        end
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
    player_ship_spawn_count = 0
    player_ship_death_count = 0
    max_repeat_loop = 300
    center_x = 909000 + random(-300000, 300000)
    center_y = 211000 + random(-60000, 60000)
    primary_orders = _("orders-comms", "Survive")
    plotCI = cargoInventory
    plotH = healthCheck --Damage to ship can kill repair crew members
    healthCheckTimerInterval = 8
    healthCheckTimer = healthCheckTimerInterval
    prefix_length = 0
    suffix_index = 0
    cpu_ships = {}
    star_list = {
        {
            radius = random(600, 1400),
            distance = random(-2500, -1400),
            name = {
                "Gamma Piscium",
                "Beta Lyporis",
                "Sigma Draconis",
                "Iota Carinae",
                "Theta Arietis",
                "Epsilon Indi",
                "Beta Hydri",
            },
            color = {
                red = random(0.8, 1),
                green = random(0.8, 1),
                blue = random(0.8, 1),
            },
            texture = {
                atmosphere = "planets/star-1.png",
            },
        },
    }
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
    player_ship_names_for["Cruzeiro"] =
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
    template_pool_size = 5
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
        [ST.BATTLESTATION] = 2000,
        [ST.BLOCKADE_RUNNER] = 400,
        [ST.BLADE] = 300,
        [ST.BUSTER] = 100,
        ["Courier"] = 600,
        ["Cruiser"] = 200,
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
        ["Fighter"] = 100,
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
        ["Hurricane"] = 200,
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
        ["Missile Cruiser"] = 200,
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
    base_upgrade_cost = 5
    playerShipUpgradeDowngradeData()
    commonGoods = defaults.goods().commonGoods
    componentGoods = defaults.goods().componentGoods
    mineralGoods = defaults.goods().mineralGoods
    vapor_goods =
        { "gold pressed latinum", "unobtanium", "eludium", "impossibrium" }
    artifact_counter = 0
    artifact_number = 0
    sensor_impact = 1 --normal
    sensor_jammer_list = {}
    sensor_jammer_range = 60000
    sensor_jammer_impact = 40000
    sensor_jammer_scan_complexity = 3
    sensor_jammer_scan_depth = 3
    sensor_jammer_power_units = true --false means percentage, true is units
    may_explain_sensor_jammer = false
    whammy = random(2950, 3050) -- ~50 minutes
    total_whammies = 0
    continuous_spawn_diagnostic = false
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
    possible_victory_time = 600 --final: 600
    saboteur_idea_time = 1200 --final: 1200
    target_station_pool = {}
    clarifyExistingScience()
    mainLinearPlot = continuousSpawn
end
-- Game Master functions --
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
            print(version_message)
        end
    )
    addGMFunction(_("buttonGM", "+Station Reports"), stationReports)
    addGMFunction(_("buttonGM", "+Difficulty"), setDifficulty)
    addGMFunction(_("buttonGM", "+Enemy Power"), setEnemyPower)
    addGMFunction(_("buttonGM", "+Reputation"), setInitialReputation)
    addGMFunction(_("buttonGM", "+Control Codes"), manageControlCodes)
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
            print(version_message)
        end
    )
    addGMFunction(_("buttonGM", "+Station Reports"), stationReports)
    addGMFunction(_("buttonGM", "Mission Stations"), function()
        addGMMessage(
            string.format(
                _(
                    "msgGM",
                    "This is spoiler information. Consider carefully before you reveal this to the rest of the players. If you feel you have to reveal this information, I suggest you select the player ship using the widget to the right of the 'Global message' button, then click the 'Hail ship' button, identify yourself as a character in game like the regional headquarters stellar cartography technician, then type the information as if you were that character helping them out on their mission.\n\nMedical research station: %s in sector %s\nPlague station %s in %s"
                ),
                station_medical_research:getCallSign(),
                station_medical_research:getSectorName(),
                station_plague:getCallSign(),
                station_plague:getSectorName()
            )
        )
    end)
    addGMFunction(_("buttonGM", "+Test Non-DB Ships"), testNonDBShips)
    if whammy > getScenarioTime() then
        addGMFunction(
            string.format(_("buttonGM", "Whammy %s"), math.floor(whammy)),
            function()
                whammy = getScenarioTime()
                mainGMButtonsAfterPause()
            end
        )
    end
    addGMFunction(_("buttonGM", "+Spawn Ship(s)"), spawnGMShips)
    addGMFunction(_("buttonGM", "+Control Codes"), manageControlCodes)
end
function setEnemyPower()
    clearGMFunctions()
    addGMFunction(_("buttonGM", "-From Enemy Power"), mainGMButtons)
    local powers = {
        { val = 0.5, desc = _("buttonGM", "Easy") },
        { val = 1, desc = _("buttonGM", "Normal") },
        { val = 2, desc = _("buttonGM", "Hard") },
        { val = 3, desc = _("buttonGM", "Extreme") },
        { val = 5, desc = _("buttonGM", "Quixotic") },
    }
    for index, power in ipairs(powers) do
        local button_label =
            string.format(_("buttonGM", "%s %.1f"), power.desc, power.val)
        if power.val == enemy_power then
            button_label = button_label .. _("buttonGM", "*")
        end
        addGMFunction(button_label, function()
            enemy_power = power.val
            setEnemyPower()
        end)
    end
end
function setDifficulty()
    clearGMFunctions()
    addGMFunction(_("buttonGM", "-From Difficulty"), mainGMButtons)
    local difficulties = {
        { val = 0.5, desc = _("buttonGM", "Easy") },
        { val = 1, desc = _("buttonGM", "Normal") },
        { val = 2, desc = _("buttonGM", "Hard") },
    }
    for index, diff in ipairs(difficulties) do
        local button_label =
            string.format(_("buttonGM", "%s %.1f"), diff.desc, diff.val)
        if diff.val == difficulty then
            button_label = button_label .. _("buttonGM", "*")
        end
        addGMFunction(button_label, function()
            difficulty = diff.val
            setDifficulty()
        end)
    end
end
function setInitialReputation()
    clearGMFunctions()
    addGMFunction(_("buttonGM", "-From Reputation"), mainGMButtons)
    local reputation_values = {
        { name = _("buttonGM", "Unknown"), value = 0 },
        { name = _("buttonGM", "Nice"), value = 20 },
        { name = _("buttonGM", "Hero"), value = 50 },
        { name = _("buttonGM", "Major Hero"), value = 100 },
        { name = _("buttonGM", "Super Hero"), value = 200 },
    }
    for index, rep in ipairs(reputation_values) do
        local button_label =
            string.format(_("buttonGM", "%s %i"), rep.name, rep.value)
        if reputation_start_amount == rep.value then
            button_label = button_label .. _("buttonGM", "*")
        end
        addGMFunction(button_label, function()
            reputation_start_amount = rep.value
            setInitialReputation()
        end)
    end
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
                                -- out = string.format(_("stationReport-msgGM", "%s\n      %s: %s"),out,service,cost)
                                out = string.format(
                                    _(
                                        "stationReport-msgGM",
                                        "%s\n      %s: %s %s"
                                    ),
                                    out,
                                    service,
                                    cost,
                                    station.comms_data.service_available[service]
                                )
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
function testNonDBShips()
    clearGMFunctions()
    addGMFunction(_("buttonGM", "-Main"), mainGMButtons)
    local non_db_ships = {
        ["farco3"] = farco3,
        ["farco5"] = farco5,
        ["farco8"] = farco8,
        ["farco11"] = farco11,
        ["farco13"] = farco13,
        ["whirlwind"] = whirlwind,
        ["phobosR2"] = phobosR2,
        ["hornetMV52"] = hornetMV52,
        ["k2fighter"] = k2fighter,
        ["k3fighter"] = k3fighter,
        ["waddle5"] = waddle5,
        ["jade5"] = jade5,
        ["droneLite"] = droneLite,
        ["droneHeavy"] = droneHeavy,
        ["droneJacket"] = droneJacket,
        ["wzLindworm"] = wzLindworm,
        ["tempest"] = tempest,
        ["enforcer"] = enforcer,
        ["predator"] = predator,
        ["atlantisY42"] = atlantisY42,
        ["starhammerV"] = starhammerV,
        ["tyr"] = tyr,
        ["gnat"] = gnat,
        ["cucaracha"] = cucaracha,
        ["maniapak"] = maniapak,
        ["starhammerIII"] = starhammerIII,
        ["k2breaker"] = k2breaker,
        ["hurricane"] = hurricane,
        ["phobosT4"] = phobosT4,
    }
    for index, func in pairs(non_db_ships) do
        addGMFunction(index, function()
            string.format("")
            local ship = func("Exuari")
            ship:setPosition(5000, 5000)
        end)
    end
end
-- Player ship functions
function updatePlayerSoftTemplate(p)
    local tempTypeName = p:getTypeName()
    if tempTypeName ~= nil then
        if playerShipStats[tempTypeName] ~= nil then
            p.upgrade_path = {
                ["beam"] = 1,
                ["missiles"] = 1,
                ["shield"] = 1,
                ["hull"] = 1,
                ["impulse"] = 1,
                ["ftl"] = 1,
                ["sensors"] = 1,
            }
            for i = 0, 15 do
                p:setBeamWeapon(i, 0, 0, 0, 0, 0)
            end
            for i, b in ipairs(upgrade_path[tempTypeName].beam[1]) do
                p:setBeamWeapon(b.idx, b.arc, b.dir, b.rng, b.cyc, b.dmg)
                if b.tar ~= nil then
                    p:setBeamWeaponTurret(b.idx, b.tar, b.tdr, b.trt)
                end
            end
            p:setWeaponTubeCount(0)
            local missile_trans = {
                { typ = "Homing", short_type = "hom" },
                { typ = "Nuke", short_type = "nuk" },
                { typ = "EMP", short_type = "emp" },
                { typ = "Mine", short_type = "min" },
                { typ = "HVLI", short_type = "hvl" },
            }
            if upgrade_path[tempTypeName].tube[1][1].idx >= 0 then
                p:setWeaponTubeCount(#upgrade_path[tempTypeName].tube[1])
                local size_trans = {
                    ["S"] = "small",
                    ["M"] = "medium",
                    ["L"] = "large",
                }
                for i, m in ipairs(upgrade_path[tempTypeName].tube[1]) do
                    p:setWeaponTubeDirection(m.idx, m.dir)
                    p:setTubeSize(m.idx, size_trans[m.siz])
                    p:setTubeLoadTime(m.idx, m.spd)
                    local exclusive = false
                    for j, lm in ipairs(missile_trans) do
                        if m[lm.short_type] then
                            if exclusive then
                                p:weaponTubeAllowMissle(m.idx, lm.typ)
                            else
                                p:setWeaponTubeExclusiveFor(m.idx, lm.typ)
                                exclusive = true
                            end
                        end
                    end
                end
            end
            for i, o in ipairs(missile_trans) do
                -- print("type:",o.typ,"amount:",upgrade_path[tempTypeName].ordnance[1][o.short_type])
                p:setWeaponStorageMax(
                    o.typ,
                    upgrade_path[tempTypeName].ordnance[1][o.short_type]
                )
                p:setWeaponStorage(
                    o.typ,
                    upgrade_path[tempTypeName].ordnance[1][o.short_type]
                )
            end
            if p:getWeaponTubeCount() > 0 then
                local size_letter = {
                    ["small"] = "S",
                    ["medium"] = "M",
                    ["large"] = "L",
                }
                p.tube_size = ""
                for i = 1, p:getWeaponTubeCount() do
                    p.tube_size = p.tube_size
                        .. size_letter[p:getTubeSize(i - 1)]
                end
            end
            p:setShieldsMax(upgrade_path[tempTypeName].shield[1][1].max)
            p:setShields(upgrade_path[tempTypeName].shield[1][1].max)
            p:setHullMax(upgrade_path[tempTypeName].hull[1].max)
            p:setHull(upgrade_path[tempTypeName].hull[1].max)
            p:setImpulseMaxSpeed(
                upgrade_path[tempTypeName].impulse[1].max_front,
                upgrade_path[tempTypeName].impulse[1].max_back
            )
            p:setAcceleration(
                upgrade_path[tempTypeName].impulse[1].accel_front,
                upgrade_path[tempTypeName].impulse[1].accel_back
            )
            p:setRotationMaxSpeed(upgrade_path[tempTypeName].impulse[1].turn)
            p:setCanCombatManeuver(false)
            p:setCombatManeuver(0, 0)
            p.combat_maneuver_capable = false
            p:setJumpDrive(false)
            p:setWarpDrive(false)
            p:setLongRangeRadarRange(upgrade_path[tempTypeName].sensors[1].long)
            p.normal_long_range_radar =
                upgrade_path[tempTypeName].sensors[1].long
            p:setShortRangeRadarRange(
                upgrade_path[tempTypeName].sensors[1].short
            )
            p.prox_scan = upgrade_path[tempTypeName].sensors[1].prox_scan
            p.shipScore = upgrade_path[tempTypeName].score
            if not upgrade_path[tempTypeName].providers then
                local station_service_pool = {
                    "beam",
                    "missiles",
                    "shield",
                    "hull",
                    "impulse",
                    "ftl",
                    "sensors",
                }
                local station_pool = {}
                while #station_service_pool > 0 do
                    local service = tableRemoveRandom(station_service_pool)
                    if #station_pool < 1 then
                        for _, station in ipairs(inner_circle) do
                            if station ~= nil and station:isValid() then
                                table.insert(station_pool, station)
                            end
                        end
                    end
                    local station_1 = tableRemoveRandom(station_pool)
                    if #station_pool < 1 then
                        for _, station in ipairs(inner_circle) do
                            if station ~= nil and station:isValid() then
                                table.insert(station_pool, station)
                            end
                        end
                    end
                    local station_2 = tableRemoveRandom(station_pool)
                    if station_1.comms_data.upgrade_path == nil then
                        station_1.comms_data.upgrade_path = {}
                    end
                    if
                        station_1.comms_data.upgrade_path[tempTypeName] == nil
                    then
                        station_1.comms_data.upgrade_path[tempTypeName] = {}
                    end
                    if station_2.comms_data.upgrade_path == nil then
                        station_2.comms_data.upgrade_path = {}
                    end
                    if
                        station_2.comms_data.upgrade_path[tempTypeName] == nil
                    then
                        station_2.comms_data.upgrade_path[tempTypeName] = {}
                    end
                    station_1.comms_data.upgrade_path[tempTypeName][service] =
                        math.floor(#upgrade_path[tempTypeName][service] / 2)
                    station_2.comms_data.upgrade_path[tempTypeName][service] =
                        math.floor(#upgrade_path[tempTypeName][service] / 2)
                end
                station_service_pool = {
                    "beam",
                    "missiles",
                    "shield",
                    "hull",
                    "impulse",
                    "ftl",
                    "sensors",
                }
                station_pool = {}
                while #station_service_pool > 0 do
                    local service = tableRemoveRandom(station_service_pool)
                    if #station_pool < 1 then
                        for _, station in ipairs(circle_stations) do
                            if station ~= nil and station:isValid() then
                                if not station:isEnemy(p) then
                                    table.insert(station_pool, station)
                                end
                            end
                        end
                    end
                    local station_1 = tableRemoveRandom(station_pool)
                    if station_1.comms_data.upgrade_path == nil then
                        station_1.comms_data.upgrade_path = {}
                    end
                    if
                        station_1.comms_data.upgrade_path[tempTypeName] == nil
                    then
                        station_1.comms_data.upgrade_path[tempTypeName] = {}
                    end
                    station_1.comms_data.upgrade_path[tempTypeName][service] =
                        #upgrade_path[tempTypeName][service]
                end
                station_service_pool = {
                    "beam",
                    "missiles",
                    "shield",
                    "hull",
                    "impulse",
                    "ftl",
                    "sensors",
                }
                station_pool = {}
                while #station_service_pool > 0 do
                    local service = tableRemoveRandom(station_service_pool)
                    if #station_pool < 1 then
                        for _, station in ipairs(env_stations) do
                            if station ~= nil and station:isValid() then
                                if not station:isEnemy(p) then
                                    table.insert(station_pool, station)
                                end
                            end
                        end
                    end
                    local station_1 = tableRemoveRandom(station_pool)
                    if station_1 ~= nil then
                        if station_1.comms_data.upgrade_path == nil then
                            station_1.comms_data.upgrade_path = {}
                        end
                        if
                            station_1.comms_data.upgrade_path[tempTypeName]
                            == nil
                        then
                            station_1.comms_data.upgrade_path[tempTypeName] = {}
                        end
                        station_1.comms_data.upgrade_path[tempTypeName][service] =
                            #upgrade_path[tempTypeName][service]
                    end
                end
                upgrade_path[tempTypeName].providers = true
            end
            --set values from list
            p.maxCargo = playerShipStats[tempTypeName].cargo
            p.cargo = p.maxCargo
            p:setMaxScanProbeCount(playerShipStats[tempTypeName].probes)
            p:setScanProbeCount(p:getMaxScanProbeCount())
            p.tractor = playerShipStats[tempTypeName].tractor
            p.tractor_target_lock = false
            p.mining = playerShipStats[tempTypeName].mining
            -- p.prox_scan = playerShipStats[tempTypeName].prox_scan
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
            addShipUpgradeInfoToScienceDatabase(tempTypeName)
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
    PlayerState.resetBaseline(p, {})
end
function setPlayers(p)
    if p == nil then
        return
    end
    p:setPosition(player_spawn_x, player_spawn_y)
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
    p:onDestroyed(playerDestroyed)
    p:onDestruction(playerDestruction)
    if p:getReputationPoints() == 0 then
        p:setReputationPoints(reputation_start_amount)
    end
end
function playerDestruction(self, instigator)
    -- Note: invoked by destruction by damage
    local players = getActivePlayerShips()
    if #players <= 1 then --last player ship destroyed
        local outpost_count = 0
        for _, station in ipairs(inner_circle) do
            if station ~= nil and station:isValid() then
                outpost_count = outpost_count + 1
            end
        end
        local rank = getTripleFactorRank()
        local duration_string = getDuration()
        local reason = ""
        if outpost_count > 1 then
            reason = string.format(
                _(
                    "msgMainscreen",
                    "Outpost stations surrendered without you.\nOutpost resisted for %s.\nPosthumous rank: %s"
                ),
                duration_string,
                rank
            )
        else
            reason = string.format(
                _(
                    "msgMainscreen",
                    "Last outpost station surrendered without you.\nOutpost resisted for %s.\nPosthumous rank: %s"
                ),
                duration_string,
                rank
            )
        end
        globalMessage(reason)
        setBanner(reason)
        victory("Exuari")
    end
end
function playerDestroyed(self, instigator)
    player_ship_death_count = player_ship_death_count + 1
end
-- End of game messaging functions
function getTripleFactorRank()
    local outpost_count = 0
    for _, station in ipairs(inner_circle) do
        if station ~= nil and station:isValid() then
            outpost_count = outpost_count + 1
        end
    end
    local duration_string = getDuration()
    local duration = getScenarioTime()
    local rank = _("msgMainscreen", "Cadet")
    local posthumous_rank = {
        {
            whammy = 0,
            stations = 4,
            duration = 1.0,
            rank = _("msgMainscreen", "Admiral"),
        },
        {
            whammy = 0,
            stations = 3,
            duration = 1.0,
            rank = _("msgMainscreen", "Captain"),
        },
        {
            whammy = 0,
            stations = 2,
            duration = 1.0,
            rank = _("msgMainscreen", "Commander"),
        },
        {
            whammy = 0,
            stations = 1,
            duration = 1.0,
            rank = _("msgMainscreen", "Lieutenant"),
        },
        {
            whammy = 1,
            stations = 4,
            duration = 1.0,
            rank = _("msgMainscreen", "Admiral"),
        },
        {
            whammy = 1,
            stations = 4,
            duration = 1.5,
            rank = _("msgMainscreen", "Captain"),
        },
        {
            whammy = 1,
            stations = 3,
            duration = 1.0,
            rank = _("msgMainscreen", "Captain"),
        },
        {
            whammy = 1,
            stations = 3,
            duration = 1.5,
            rank = _("msgMainscreen", "Commander"),
        },
        {
            whammy = 1,
            stations = 2,
            duration = 1.0,
            rank = _("msgMainscreen", "Commander"),
        },
        {
            whammy = 1,
            stations = 2,
            duration = 1.5,
            rank = _("msgMainscreen", "Lieutenant"),
        },
        {
            whammy = 1,
            stations = 1,
            duration = 1.0,
            rank = _("msgMainscreen", "Lieutenant"),
        },
        {
            whammy = 1,
            stations = 1,
            duration = 1.5,
            rank = _("msgMainscreen", "Ensign"),
        },
        {
            whammy = 2,
            stations = 4,
            duration = 2.0,
            rank = _("msgMainscreen", "Admiral"),
        },
        {
            whammy = 2,
            stations = 4,
            duration = 2.5,
            rank = _("msgMainscreen", "Captain"),
        },
        {
            whammy = 2,
            stations = 3,
            duration = 2.0,
            rank = _("msgMainscreen", "Commander"),
        },
        {
            whammy = 2,
            stations = 3,
            duration = 2.5,
            rank = _("msgMainscreen", "Commander"),
        },
        {
            whammy = 2,
            stations = 2,
            duration = 2.0,
            rank = _("msgMainscreen", "Lieutenant"),
        },
        {
            whammy = 2,
            stations = 2,
            duration = 2.5,
            rank = _("msgMainscreen", "Ensign"),
        },
        {
            whammy = 2,
            stations = 1,
            duration = 2.0,
            rank = _("msgMainscreen", "Ensign"),
        },
        {
            whammy = 2,
            stations = 1,
            duration = 2.5,
            rank = _("msgMainscreen", "Acting Ensign"),
        },
        {
            whammy = 3,
            stations = 4,
            duration = 3.0,
            rank = _("msgMainscreen", "Admiral"),
        },
        {
            whammy = 3,
            stations = 4,
            duration = 3.5,
            rank = _("msgMainscreen", "Captain"),
        },
        {
            whammy = 3,
            stations = 3,
            duration = 3.0,
            rank = _("msgMainscreen", "Commander"),
        },
        {
            whammy = 3,
            stations = 3,
            duration = 3.5,
            rank = _("msgMainscreen", "Lieutenant"),
        },
        {
            whammy = 3,
            stations = 2,
            duration = 3.0,
            rank = _("msgMainscreen", "Lieutenant"),
        },
        {
            whammy = 3,
            stations = 2,
            duration = 3.5,
            rank = _("msgMainscreen", "Ensign"),
        },
        {
            whammy = 3,
            stations = 1,
            duration = 3.0,
            rank = _("msgMainscreen", "Ensign"),
        },
        {
            whammy = 3,
            stations = 1,
            duration = 3.5,
            rank = _("msgMainscreen", "Acting Ensign"),
        },
        {
            whammy = 4,
            stations = 4,
            duration = 4.0,
            rank = _("msgMainscreen", "Admiral"),
        },
        {
            whammy = 4,
            stations = 4,
            duration = 4.5,
            rank = _("msgMainscreen", "Captain"),
        },
        {
            whammy = 4,
            stations = 3,
            duration = 4.0,
            rank = _("msgMainscreen", "Commander"),
        },
        {
            whammy = 4,
            stations = 3,
            duration = 4.5,
            rank = _("msgMainscreen", "Lieutenant"),
        },
        {
            whammy = 4,
            stations = 2,
            duration = 4.0,
            rank = _("msgMainscreen", "Ensign"),
        },
        {
            whammy = 4,
            stations = 2,
            duration = 4.5,
            rank = _("msgMainscreen", "Acting Ensign"),
        },
        {
            whammy = 4,
            stations = 1,
            duration = 4.0,
            rank = _("msgMainscreen", "Acting Ensign"),
        },
        {
            whammy = 4,
            stations = 1,
            duration = 4.5,
            rank = _("msgMainscreen", "Acting Ensign"),
        },
        {
            whammy = 5,
            stations = 4,
            duration = 5.0,
            rank = _("msgMainscreen", "Captain"),
        },
        {
            whammy = 5,
            stations = 4,
            duration = 5.5,
            rank = _("msgMainscreen", "Commander"),
        },
        {
            whammy = 5,
            stations = 3,
            duration = 5.0,
            rank = _("msgMainscreen", "Lieutenant"),
        },
        {
            whammy = 5,
            stations = 3,
            duration = 5.5,
            rank = _("msgMainscreen", "Ensign"),
        },
        {
            whammy = 5,
            stations = 2,
            duration = 5.0,
            rank = _("msgMainscreen", "Acting Ensign"),
        },
        {
            whammy = 6,
            stations = 4,
            duration = 6.0,
            rank = _("msgMainscreen", "Commander"),
        },
        {
            whammy = 6,
            stations = 4,
            duration = 6.5,
            rank = _("msgMainscreen", "Lieutenant"),
        },
        {
            whammy = 6,
            stations = 3,
            duration = 6.0,
            rank = _("msgMainscreen", "Ensign"),
        },
        {
            whammy = 6,
            stations = 3,
            duration = 6.5,
            rank = _("msgMainscreen", "Acting Ensign"),
        },
        {
            whammy = 7,
            stations = 4,
            duration = 7.0,
            rank = _("msgMainscreen", "Lieutenant"),
        },
        {
            whammy = 7,
            stations = 4,
            duration = 7.5,
            rank = _("msgMainscreen", "Ensign"),
        },
        {
            whammy = 7,
            stations = 3,
            duration = 7.5,
            rank = _("msgMainscreen", "Acting Ensign"),
        },
        {
            whammy = 8,
            stations = 4,
            duration = 8.0,
            rank = _("msgMainscreen", "Ensign"),
        },
        {
            whammy = 8,
            stations = 4,
            duration = 8.5,
            rank = _("msgMainscreen", "Acting Ensign"),
        },
        {
            whammy = 9,
            stations = 4,
            duration = 9.0,
            rank = _("msgMainscreen", "Acting Ensign"),
        },
    }
    for i, pr in ipairs(posthumous_rank) do
        if total_whammies == pr.whammy then
            if stations == outpost_count then
                if duration < (60 * 60 * pr.duration) then
                    rank = pr.rank
                    break
                end
            end
        end
    end
    return rank
end
function getDuration()
    local duration = getScenarioTime()
    local duration_string = math.floor(duration)
    if duration > 60 then
        if duration > 3600 then
        else
            local minutes = math.floor(duration / 60)
            local seconds = math.floor(duration % 60)
            if minutes > 1 then
                if minutes > 60 then
                    local hours = math.floor(minutes / 60)
                    minutes = math.floor(minutes % 60)
                    if hours > 1 then
                        if minutes > 1 then
                            if seconds > 1 then
                                duration_string = string.format(
                                    _(
                                        "msgMainscreen",
                                        "%s hours, %s minutes and %s seconds"
                                    ),
                                    hours,
                                    minutes,
                                    seconds
                                )
                            else
                                duration_string = string.format(
                                    _(
                                        "msgMainscreen",
                                        "%s hours, %s minutes and %s second"
                                    ),
                                    hours,
                                    minutes,
                                    seconds
                                )
                            end
                        else
                            if seconds > 1 then
                                duration_string = string.format(
                                    _(
                                        "msgMainscreen",
                                        "%s hours, %s minute and %s seconds"
                                    ),
                                    hours,
                                    minutes,
                                    seconds
                                )
                            else
                                duration_string = string.format(
                                    _(
                                        "msgMainscreen",
                                        "%s hours, %s minute and %s second"
                                    ),
                                    hours,
                                    minutes,
                                    seconds
                                )
                            end
                        end
                    else
                        if minutes > 1 then
                            if seconds > 1 then
                                duration_string = string.format(
                                    _(
                                        "msgMainscreen",
                                        "%s hour, %s minutes and %s seconds"
                                    ),
                                    hours,
                                    minutes,
                                    seconds
                                )
                            else
                                duration_string = string.format(
                                    _(
                                        "msgMainscreen",
                                        "%s hour, %s minutes and %s second"
                                    ),
                                    hours,
                                    minutes,
                                    seconds
                                )
                            end
                        else
                            if seconds > 1 then
                                duration_string = string.format(
                                    _(
                                        "msgMainscreen",
                                        "%s hour, %s minute and %s seconds"
                                    ),
                                    hours,
                                    minutes,
                                    seconds
                                )
                            else
                                duration_string = string.format(
                                    _(
                                        "msgMainscreen",
                                        "%s hour, %s minute and %s second"
                                    ),
                                    hours,
                                    minutes,
                                    seconds
                                )
                            end
                        end
                    end
                else
                    if seconds > 1 then
                        duration_string = string.format(
                            _("msgMainscreen", "%s minutes and %s seconds"),
                            minutes,
                            seconds
                        )
                    else
                        duration_string = string.format(
                            _("msgMainscreen", "%s minutes and %s second"),
                            minutes,
                            seconds
                        )
                    end
                end
            else
                duration_string =
                    string.format("%s minute and %s seconds", minutes, seconds)
            end
        end
    else
        duration_string = string.format("%s seconds", duration_string)
    end
    return duration_string
end
-- Construct environment and related functions
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
    station_list = {}
    inner_circle = {}
    player_factions = { "Human Navy", "CUF", "USN", "TSN" }
    player_faction = player_factions[math.random(1, #player_factions)]
    ir_faction = { player_faction, "Human Navy" }
    if player_faction == "Human Navy" then
        ir_faction = { "Human Navy", "CUF", "USN", "TSN" }
    end
    station_regional_hq = placeStation(
        center_x,
        center_y,
        "Alt Sci Fi",
        player_faction,
        "Medium Station"
    )
    table.insert(station_list, station_regional_hq)
    table.insert(inner_circle, station_regional_hq)
    table.insert(
        place_space,
        { obj = station_regional_hq, dist = 1000, shape = "circle" }
    )
    local defense_platform_angle = random(0, 360)
    local dp_x, dp_y = vectorFromAngle(defense_platform_angle, 3000)
    local dp = CpuShip()
        :setTemplate(ST.DEFENSE_PLATFORM)
        :setFaction(player_faction)
        :setPosition(center_x + dp_x, center_y + dp_y)
        :setScanState("fullscan")
        :orderStandGround()
    player_spawn_x, player_spawn_y = vectorFromAngleNorth(
        random(-20, 20) + defense_platform_angle,
        random(-300, 300) + 1500
    )
    player_spawn_x = player_spawn_x + center_x
    player_spawn_y = player_spawn_y + center_y
    local circle_x, circle_y = vectorFromAngleNorth(
        random(-15, 15) + defense_platform_angle + 180,
        random(8000, 14500)
    )
    local station_size = szt()
    local circle_station = placeStation(
        center_x + circle_x,
        center_y + circle_y,
        "Spec Sci Fi",
        ir_faction[math.random(1, #ir_faction)],
        station_size
    )
    table.insert(station_list, circle_station)
    table.insert(inner_circle, circle_station)
    table.insert(place_space, {
        obj = circle_station,
        dist = station_defend_dist[station_size],
        shape = "circle",
    })
    circle_x, circle_y = vectorFromAngleNorth(
        random(-15, 15) + defense_platform_angle + 60,
        random(8000, 14500)
    )
    station_size = szt()
    circle_station = placeStation(
        center_x + circle_x,
        center_y + circle_y,
        "Science",
        ir_faction[math.random(1, #ir_faction)],
        station_size
    )
    table.insert(station_list, circle_station)
    table.insert(inner_circle, circle_station)
    table.insert(place_space, {
        obj = circle_station,
        dist = station_defend_dist[station_size],
        shape = "circle",
    })
    circle_x, circle_y = vectorFromAngleNorth(
        random(-15, 15) + defense_platform_angle - 60,
        random(8000, 14500)
    )
    station_size = szt()
    circle_station = placeStation(
        center_x + circle_x,
        center_y + circle_y,
        "History",
        ir_faction[math.random(1, #ir_faction)],
        station_size
    )
    table.insert(station_list, circle_station)
    table.insert(inner_circle, circle_station)
    table.insert(place_space, {
        obj = circle_station,
        dist = station_defend_dist[station_size],
        shape = "circle",
    })
    --energy, hull, probe,
    --homing, nuke, emp, mine, hvli,
    --scan, hack, launch probe, combat maneuver, self destruct
    --reactor, beam, missile, maneuver, impulse, warp, jump, front shield, rear shield
    --supply drop, reinforcements, jump overcharge, shield overcharge,
    for _, station in ipairs(inner_circle) do
        station:setSharesEnergyWithDocked(false)
        station:setRepairDocked(false)
        station:setRestocksScanProbes(false)
        station.comms_data.weapon_available.Homing = false
        station.comms_data.weapon_available.Nuke = false
        station.comms_data.weapon_available.EMP = false
        station.comms_data.weapon_available.Mine = false
        station.comms_data.weapon_available.HVLI = false
        station.comms_data.scan_repair = false
        station.comms_data.hack_repair = false
        station.comms_data.probe_launch_repair = false
        station.comms_data.combat_maneuver_repair = false
        station.comms_data.self_destruct_repair = false
        station.comms_data.tube_slow_down_repair = false
        station.comms_data.system_repair = {
            ["reactor"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = false,
            },
            ["beamweapons"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = false,
            },
            ["missilesystem"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = false,
            },
            ["maneuver"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = false,
            },
            ["impulse"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = false,
            },
            ["warp"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = false,
            },
            ["jumpdrive"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = false,
            },
            ["frontshield"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = false,
            },
            ["rearshield"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = false,
            },
        }
        station.comms_data.service_available = {
            supplydrop = false,
            reinforcements = false,
            hornet_reinforcements = false,
            phobos_reinforcements = false,
            amk3_reinforcements = false,
            amk8_reinforcements = false,
            jump_overcharge = false,
            shield_overcharge = false,
            jonque = false,
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
    end
    local station_service_pool = {
        "energy",
        "hull",
        "restock_probes",
        "homing",
        "nuke",
        "emp",
        "mine",
        "hvli",
        "fix_scan",
        "fix_hack",
        "fix_probe_launch",
        "fix_combat_maneuver",
        "fix_self_destruct",
        "fix_slow_tube",
        "fix_reactor",
        "fix_beam",
        "fix_missile",
        "fix_maneuver",
        "fix_impulse",
        "fix_warp",
        "fix_jump",
        "fix_front_shield",
        "fix_rear_shield",
        "supply_drop",
        "reinforcements",
        "hornet_reinforcements",
        "phobos_reinforcements",
        "amk3_reinforcements",
        "amk8_reinforcements",
        "jump_overcharge",
        "shield_overcharge",
        "jonque",
    }
    local station_pool = {}
    while #station_service_pool > 0 do
        local service = tableRemoveRandom(station_service_pool)
        if #station_pool < 1 then
            for _, station in ipairs(inner_circle) do
                table.insert(station_pool, station)
            end
        end
        local station_1 = tableRemoveRandom(station_pool)
        if #station_pool < 1 then
            for _, station in ipairs(inner_circle) do
                table.insert(station_pool, station)
            end
        end
        local station_2 = tableRemoveRandom(station_pool)
        if service == "energy" then
            station_1:setSharesEnergyWithDocked(true)
            station_2:setSharesEnergyWithDocked(true)
        elseif service == "hull" then
            station_1:setRepairDocked(true)
            station_2:setRepairDocked(true)
        elseif service == "restock_probes" then
            station_1:setRestocksScanProbes(true)
            station_2:setRestocksScanProbes(true)
        elseif service == "homing" then
            station_1.comms_data.weapon_available.Homing = true
            station_2.comms_data.weapon_available.Homing = true
        elseif service == "nuke" then
            station_1.comms_data.weapon_available.Nuke = true
            station_2.comms_data.weapon_available.Nuke = true
        elseif service == "emp" then
            station_1.comms_data.weapon_available.EMP = true
            station_2.comms_data.weapon_available.EMP = true
        elseif service == "mine" then
            station_1.comms_data.weapon_available.Mine = true
            station_2.comms_data.weapon_available.Mine = true
        elseif service == "hvli" then
            station_1.comms_data.weapon_available.HVLI = true
            station_2.comms_data.weapon_available.HVLI = true
        elseif service == "fix_scan" then
            station_1.comms_data.scan_repair = true
            station_2.comms_data.scan_repair = true
        elseif service == "fix_hack" then
            station_1.comms_data.hack_repair = true
            station_2.comms_data.hack_repair = true
        elseif service == "fix_probe_launch" then
            station_1.comms_data.probe_launch_repair = true
            station_2.comms_data.probe_launch_repair = true
        elseif service == "fix_combat_maneuver" then
            station_1.comms_data.combat_maneuver_repair = true
            station_2.comms_data.combat_maneuver_repair = true
        elseif service == "fix_self_destruct" then
            station_1.comms_data.self_destruct_repair = true
            station_2.comms_data.self_destruct_repair = true
        elseif service == "fix_slow_tube" then
            station_1.comms_data.tube_slow_down_repair = true
            station_2.comms_data.tube_slow_down_repair = true
        elseif service == "fix_reactor" then
            station_1.comms_data.system_repair.reactor.avail = true
            station_2.comms_data.system_repair.reactor.avail = true
        elseif service == "fix_beam" then
            station_1.comms_data.system_repair.beamweapons.avail = true
            station_2.comms_data.system_repair.beamweapons.avail = true
        elseif service == "fix_missile" then
            station_1.comms_data.system_repair.missilesystem.avail = true
            station_2.comms_data.system_repair.missilesystem.avail = true
        elseif service == "fix_maneuver" then
            station_1.comms_data.system_repair.maneuver.avail = true
            station_2.comms_data.system_repair.maneuver.avail = true
        elseif service == "fix_impulse" then
            station_1.comms_data.system_repair.impulse.avail = true
            station_2.comms_data.system_repair.impulse.avail = true
        elseif service == "fix_warp" then
            station_1.comms_data.system_repair.warp.avail = true
            station_2.comms_data.system_repair.warp.avail = true
        elseif service == "fix_jump" then
            station_1.comms_data.system_repair.jumpdrive.avail = true
            station_2.comms_data.system_repair.jumpdrive.avail = true
        elseif service == "fix_front_shield" then
            station_1.comms_data.system_repair.frontshield.avail = true
            station_2.comms_data.system_repair.frontshield.avail = true
        elseif service == "fix_rear_shield" then
            station_1.comms_data.system_repair.rearshield.avail = true
            station_2.comms_data.system_repair.rearshield.avail = true
        elseif service == "supply_drop" then
            station_1.comms_data.service_available.supplydrop = true
            station_2.comms_data.service_available.supplydrop = true
        elseif service == "reinforcements" then
            station_1.comms_data.service_available.reinforcements = true
            station_2.comms_data.service_available.reinforcements = true
        elseif service == "hornet_reinforcements" then
            station_1.comms_data.service_available.hornet_reinforcements = true
            station_2.comms_data.service_available.hornet_reinforcements = true
        elseif service == "phobos_reinforcements" then
            station_1.comms_data.service_available.phobos_reinforcements = true
            station_2.comms_data.service_available.phobos_reinforcements = true
        elseif service == "amk3_reinforcements" then
            station_1.comms_data.service_available.amk3_reinforcements = true
            station_2.comms_data.service_available.amk3_reinforcements = true
        elseif service == "amk8_reinforcements" then
            station_1.comms_data.service_available.amk8_reinforcements = true
            station_2.comms_data.service_available.amk8_reinforcements = true
        elseif service == "jump_overcharge" then
            station_1.comms_data.service_available.jump_overcharge = true
            station_2.comms_data.service_available.jump_overcharge = true
        elseif service == "shield_overcharge" then
            station_1.comms_data.service_available.shield_overcharge = true
            station_2.comms_data.service_available.shield_overcharge = true
        elseif service == "jonque" then
            station_1.comms_data.service_available.jonque = true
            station_2.comms_data.service_available.jonque = true
        end
    end
    initial_angle = random(0, 360)
    local defense_platforms = {
        [ST.SMALL_STATION] = { count = 3, dist = 2000 },
        [ST.MEDIUM_STATION] = { count = 4, dist = 3300 },
        [ST.LARGE_STATION] = { count = 5, dist = 4000 },
        [ST.HUGE_STATION] = { count = 6, dist = 4500 },
    }
    circle_stations = {}
    local station_circle_distance_base = 25000
    local total_station_circle_distance = 0
    --create station circle stations
    for i = 1, #faction_circle do
        local station_circle_distance = station_circle_distance_base
            + random(0, 30000)
        total_station_circle_distance = total_station_circle_distance
            + station_circle_distance
        local ps_x, ps_y = vectorFromAngleNorth(
            initial_angle + (i - 1) * (360 / #faction_circle),
            station_circle_distance
        )
        local station_size = szt()
        local station = placeStation(
            center_x + ps_x,
            center_y + ps_y,
            nil,
            faction_circle[i],
            station_size
        )
        table.insert(station_list, station)
        table.insert(
            place_space,
            {
                obj = station,
                dist = station_defend_dist[station_size],
                shape = "circle",
            }
        )
        table.insert(circle_stations, station)
        local dp_angle = random(0, 360)
        for j = 1, defense_platforms[station_size].count do
            local dp_x, dp_y =
                vectorFromAngle(dp_angle, defense_platforms[station_size].dist)
            local dp = CpuShip()
                :setTemplate(ST.DEFENSE_PLATFORM)
                :setFaction(faction_circle[i])
                :setPosition(center_x + ps_x + dp_x, center_y + ps_y + dp_y)
                :orderStandGround()
            dp:setCallSign(
                string.format(
                    "%sDP%i%s",
                    faction_letter[faction_circle[i]],
                    j,
                    string.char(96 + math.random(1, 26))
                )
            )
            table.insert(
                place_space,
                { obj = dp, dist = 1000, shape = "circle" }
            )
            dp_angle = (
                dp_angle + (360 / defense_platforms[station_size].count)
            ) % 360
        end
    end
    for _, station in ipairs(circle_stations) do
        station:setSharesEnergyWithDocked(false)
        station:setRepairDocked(false)
        station:setRestocksScanProbes(false)
        station.comms_data.weapon_available.Homing = false
        station.comms_data.weapon_available.Nuke = false
        station.comms_data.weapon_available.EMP = false
        station.comms_data.weapon_available.Mine = false
        station.comms_data.weapon_available.HVLI = false
        station.comms_data.scan_repair = false
        station.comms_data.hack_repair = false
        station.comms_data.probe_launch_repair = false
        station.comms_data.combat_maneuver_repair = false
        station.comms_data.self_destruct_repair = false
        station.comms_data.tube_slow_down_repair = false
        station.comms_data.system_repair = {
            ["reactor"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = false,
            },
            ["beamweapons"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = false,
            },
            ["missilesystem"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = false,
            },
            ["maneuver"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = false,
            },
            ["impulse"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = false,
            },
            ["warp"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = false,
            },
            ["jumpdrive"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = false,
            },
            ["frontshield"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = false,
            },
            ["rearshield"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = false,
            },
        }
        station.comms_data.service_available = {
            supplydrop = false,
            reinforcements = false,
            hornet_reinforcements = false,
            phobos_reinforcements = false,
            amk3_reinforcements = false,
            amk8_reinforcements = false,
            jump_overcharge = false,
            shield_overcharge = false,
            jonque = false,
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
    end
    station_service_pool = {
        "energy",
        "hull",
        "restock_probes",
        "homing",
        "nuke",
        "emp",
        "mine",
        "hvli",
        "fix_scan",
        "fix_hack",
        "fix_probe_launch",
        "fix_combat_maneuver",
        "fix_self_destruct",
        "fix_slow_tube",
        "fix_reactor",
        "fix_beam",
        "fix_missile",
        "fix_maneuver",
        "fix_impulse",
        "fix_warp",
        "fix_jump",
        "fix_front_shield",
        "fix_rear_shield",
        "supply_drop",
        "reinforcements",
        "hornet_reinforcements",
        "phobos_reinforcements",
        "amk3_reinforcements",
        "amk8_reinforcements",
        "jump_overcharge",
        "shield_overcharge",
        "jonque",
    }
    station_pool = {}
    while #station_service_pool > 0 do
        local service = tableRemoveRandom(station_service_pool)
        if #station_pool < 1 then
            for _, station in ipairs(circle_stations) do
                if not station:isEnemy(station_regional_hq) then
                    table.insert(station_pool, station)
                end
            end
        end
        local station_1 = tableRemoveRandom(station_pool)
        if service == "energy" then
            station_1:setSharesEnergyWithDocked(true)
        elseif service == "hull" then
            station_1:setRepairDocked(true)
        elseif service == "restock_probes" then
            station_1:setRestocksScanProbes(true)
        elseif service == "homing" then
            station_1.comms_data.weapon_available.Homing = true
        elseif service == "nuke" then
            station_1.comms_data.weapon_available.Nuke = true
        elseif service == "emp" then
            station_1.comms_data.weapon_available.EMP = true
        elseif service == "mine" then
            station_1.comms_data.weapon_available.Mine = true
        elseif service == "hvli" then
            station_1.comms_data.weapon_available.HVLI = true
        elseif service == "fix_scan" then
            station_1.comms_data.scan_repair = true
        elseif service == "fix_hack" then
            station_1.comms_data.hack_repair = true
        elseif service == "fix_probe_launch" then
            station_1.comms_data.probe_launch_repair = true
        elseif service == "fix_combat_maneuver" then
            station_1.comms_data.combat_maneuver_repair = true
        elseif service == "fix_self_destruct" then
            station_1.comms_data.self_destruct_repair = true
        elseif service == "fix_slow_tube" then
            station_1.comms_data.tube_slow_down_repair = true
        elseif service == "fix_reactor" then
            station_1.comms_data.system_repair.reactor.avail = true
        elseif service == "fix_beam" then
            station_1.comms_data.system_repair.beamweapons.avail = true
        elseif service == "fix_missile" then
            station_1.comms_data.system_repair.missilesystem.avail = true
        elseif service == "fix_maneuver" then
            station_1.comms_data.system_repair.maneuver.avail = true
        elseif service == "fix_impulse" then
            station_1.comms_data.system_repair.impulse.avail = true
        elseif service == "fix_warp" then
            station_1.comms_data.system_repair.warp.avail = true
        elseif service == "fix_jump" then
            station_1.comms_data.system_repair.jumpdrive.avail = true
        elseif service == "fix_front_shield" then
            station_1.comms_data.system_repair.frontshield.avail = true
        elseif service == "fix_rear_shield" then
            station_1.comms_data.system_repair.rearshield.avail = true
        elseif service == "supply_drop" then
            station_1.comms_data.service_available.supplydrop = true
        elseif service == "reinforcements" then
            station_1.comms_data.service_available.reinforcements = true
        elseif service == "hornet_reinforcements" then
            station_1.comms_data.service_available.hornet_reinforcements = true
        elseif service == "phobos_reinforcements" then
            station_1.comms_data.service_available.phobos_reinforcements = true
        elseif service == "amk3_reinforcements" then
            station_1.comms_data.service_available.amk3_reinforcements = true
        elseif service == "amk8_reinforcements" then
            station_1.comms_data.service_available.amk8_reinforcements = true
        elseif service == "jump_overcharge" then
            station_1.comms_data.service_available.jump_overcharge = true
        elseif service == "shield_overcharge" then
            station_1.comms_data.service_available.shield_overcharge = true
        elseif service == "jonque" then
            station_1.comms_data.service_available.jonque = true
        end
    end
    average_station_circle_distance = total_station_circle_distance
        / #faction_circle
    local greatest_distance = 0
    local greatest_distance_index = 0
    --create station circle protective warp jammers
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
    }
    for index, station in ipairs(circle_stations) do
        local higher_index = index + 1
        if higher_index > #circle_stations then
            higher_index = 1
        end
        local lower_index = index - 1
        if lower_index < 1 then
            lower_index = #circle_stations
        end
        local higher_distance = distance(station, circle_stations[higher_index])
        if higher_distance >= greatest_distance then
            greatest_distance = higher_distance
            greatest_distance_index = index
        end
        local lower_distance = distance(station, circle_stations[lower_index])
        local jammer_range = (higher_distance / 3 + lower_distance / 3) / 2
        local j_x, j_y = vectorFromAngle(random(0, 360), 1500)
        local sp_x, sp_y = station:getPosition()
        local warp_jammer = WarpJammer()
            :setPosition(sp_x + j_x, sp_y + j_y)
            :setRange(jammer_range)
            :setFaction(station:getFaction())
        warp_jammer.range = jammer_range
        station.warp_jammer_list = {}
        table.insert(station.warp_jammer_list, warp_jammer)
        warp_jammer_info[station:getFaction()].count = warp_jammer_info[station:getFaction()].count
            + 1
        warp_jammer:setCallSign(
            string.format(
                "L%sWJ%i",
                warp_jammer_info[station:getFaction()].id,
                warp_jammer_info[station:getFaction()].count
            )
        )
        table.insert(warp_jammer_list, warp_jammer)
        station.higher_distance = higher_distance
        station.lower_distance = lower_distance
        station.higher_neighbor = circle_stations[higher_index]
        station.lower_neighbor = circle_stations[lower_index]
    end
    local planet_threshold = 20000
    --add planet with orbiting moon in largest gap if it's big enough
    if greatest_distance > planet_threshold then
        local station_a = circle_stations[greatest_distance_index]
        local station_b =
            circle_stations[greatest_distance_index].higher_neighbor
        local warp_jammer_a = station_a.warp_jammer_list[1]
        local warp_jammer_b = station_b.warp_jammer_list[1]
        local gap_size = distance(warp_jammer_a, warp_jammer_b)
            - warp_jammer_a.range
            - warp_jammer_b.range
        local planet_radius = gap_size * 0.8 / 2
        local wja_x, wja_y = warp_jammer_a:getPosition()
        local wjb_x, wjb_y = warp_jammer_b:getPosition()
        local planet_barrier = Planet():setPlanetRadius(planet_radius)
        planet_barrier:setPosition((wja_x + wjb_x) / 2, (wja_y + wjb_y) / 2)
        planet_barrier:setDistanceFromMovementPlane(-planet_radius * 0.2)
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
        local selected_planet = math.random(1, #planet_list)
        planet_barrier:setCallSign(
            planet_list[selected_planet].name[math.random(
                1,
                #planet_list[selected_planet].name
            )]
        )
        planet_barrier:setPlanetSurfaceTexture(
            planet_list[selected_planet].texture.surface
        )
        if planet_list[selected_planet].texture.atmosphere ~= nil then
            planet_barrier:setPlanetAtmosphereTexture(
                planet_list[selected_planet].texture.atmosphere
            )
        end
        if planet_list[selected_planet].texture.cloud ~= nil then
            planet_barrier:setPlanetCloudTexture(
                planet_list[selected_planet].texture.cloud
            )
        end
        if planet_list[selected_planet].color ~= nil then
            planet_barrier:setPlanetAtmosphereColor(
                planet_list[selected_planet].color.red,
                planet_list[selected_planet].color.green,
                planet_list[selected_planet].color.blue
            )
        end
        planet_barrier:setAxialRotationTime(random(350, 500))
        table.insert(
            place_space,
            { obj = planet_barrier, dist = planet_radius, shape = "circle" }
        )
        local moon_list = {
            {
                name = { "Ganymede", "Europa", "Deimos", "Tango", "Gavotte" },
                texture = {
                    surface = "planets/moon-1.png",
                },
            },
            {
                name = { "Myopia", "Zapata", "Lichen", "Fandango", "Boogie" },
                texture = {
                    surface = "planets/moon-2.png",
                },
            },
            {
                name = { "Scratmat", "Tipple", "Dranken", "Calypso", "Hustle" },
                texture = {
                    surface = "planets/moon-3.png",
                },
            },
        }
        local selected_moon = math.random(1, #moon_list)
        local moon_radius = planet_radius * 0.2
        moon_barrier = Planet():setPlanetRadius(moon_radius)
        moon_barrier.moon_radius = moon_radius
        moon_barrier:setPosition(
            (wja_x + wjb_x) / 2,
            (wja_y + wjb_y) / 2 + (gap_size / 2) * 1.2
        )
        -- moon_barrier:setDistanceFromMovementPlane(-planet_radius*.08*.2)
        moon_barrier:setCallSign(
            moon_list[selected_moon].name[math.random(
                1,
                #moon_list[selected_moon].name
            )]
        )
        moon_barrier:setPlanetSurfaceTexture(
            moon_list[selected_moon].texture.surface
        )
        moon_barrier:setAxialRotationTime(random(500, 900))
        moon_barrier:setOrbit(planet_barrier, random(10, 40))
        table.insert(place_space, {
            obj = planet_barrier,
            inner_orbit = ((gap_size / 2) * 1.2) - moon_radius,
            outer_orbit = ((gap_size / 2) * 1.2) + moon_radius,
            shape = "toroid",
        })
        station_a.barrier = "planet"
    end
    transport_list = {}
    transport_stations = {}
    env_stations = {}
    --fill in roughly circular area with semi-random terrain
    far_enough_fail = false
    local black_hole_chance = 1
    black_hole_count = math.random(1, 6)
    local star_chance = 3
    star_count = math.random(1, 2)
    local probe_chance = 6
    local warp_jammer_chance = 3
    warp_jammer_count = math.random(7, 12)
    local worm_hole_chance = 2
    worm_hole_count = math.random(1, 4)
    local sensor_jammer_chance = 6
    sensor_jammer_count = math.random(7, 12)
    local sensor_buoy_chance = 6
    local ad_buoy_chance = 8
    local nebula_chance = 5
    local mine_chance = 4
    local station_chance = 3
    local mine_field_chance = 4
    mine_field_count = math.random(3, 8)
    local asteroid_field_chance = 4
    asteroid_field_count = math.random(2, 6)
    local transport_chance = 4
    repeat
        local current_object_chance = 0
        local object_roll = random(0, 100)
        current_object_chance = current_object_chance + black_hole_chance
        if object_roll <= current_object_chance then
            placeBlackHole()
            goto iterate
        end
        current_object_chance = current_object_chance + star_chance
        if object_roll <= current_object_chance then
            placeStar()
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
    until #transport_list >= #circle_stations or far_enough_fail
    far_enough_fail = false
    for _, station in ipairs(env_stations) do
        station:setSharesEnergyWithDocked(false)
        station:setRepairDocked(false)
        station:setRestocksScanProbes(false)
        if station.comms_data == nil then
            station.comms_data = {}
        end
        if station.comms_data.weapon_available == nil then
            station.comms_data.weapon_available = {}
        end
        station.comms_data.weapon_available.Homing = false
        station.comms_data.weapon_available.Nuke = false
        station.comms_data.weapon_available.EMP = false
        station.comms_data.weapon_available.Mine = false
        station.comms_data.weapon_available.HVLI = false
        station.comms_data.scan_repair = false
        station.comms_data.hack_repair = false
        station.comms_data.probe_launch_repair = false
        station.comms_data.combat_maneuver_repair = false
        station.comms_data.self_destruct_repair = false
        station.comms_data.tube_slow_down_repair = false
        station.comms_data.system_repair = {
            ["reactor"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = false,
            },
            ["beamweapons"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = false,
            },
            ["missilesystem"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = false,
            },
            ["maneuver"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = false,
            },
            ["impulse"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = false,
            },
            ["warp"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = false,
            },
            ["jumpdrive"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = false,
            },
            ["frontshield"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = false,
            },
            ["rearshield"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = false,
            },
        }
        station.comms_data.service_available = {
            supplydrop = false,
            reinforcements = false,
            hornet_reinforcements = false,
            phobos_reinforcements = false,
            amk3_reinforcements = false,
            amk8_reinforcements = false,
            jump_overcharge = false,
            shield_overcharge = false,
            jonque = false,
        }
        station.comms_data.service_cost = {
            supplydrop = math.random(90, 110),
            reinforcements = math.random(140, 160),
            hornet_reinforcements = math.random(75, 125),
            phobos_reinforcements = math.random(175, 225),
            amk3_reinforcements = math.random(75, 125),
            amk8_reinforcements = math.random(150, 200),
            shield_overcharge = math.random(1, 5) * 5,
        }
    end
    station_service_pool = {
        "energy",
        "hull",
        "restock_probes",
        "homing",
        "nuke",
        "emp",
        "mine",
        "hvli",
        "fix_scan",
        "fix_hack",
        "fix_probe_launch",
        "fix_combat_maneuver",
        "fix_self_destruct",
        "fix_slow_tube",
        "fix_reactor",
        "fix_beam",
        "fix_missile",
        "fix_maneuver",
        "fix_impulse",
        "fix_warp",
        "fix_jump",
        "fix_front_shield",
        "fix_rear_shield",
        "supply_drop",
        "reinforcements",
        "hornet_reinforcements",
        "phobos_reinforcements",
        "amk3_reinforcements",
        "amk8_reinforcements",
        "jump_overcharge",
        "shield_overcharge",
        "jonque",
    }
    station_pool = {}
    while #station_service_pool > 0 do
        local service = tableRemoveRandom(station_service_pool)
        if #station_pool < 1 then
            for _, station in ipairs(env_stations) do
                if not station:isEnemy(station_regional_hq) then
                    table.insert(station_pool, station)
                end
            end
        end
        local station_1 = tableRemoveRandom(station_pool)
        if station_1 ~= nil then
            if service == "energy" then
                station_1:setSharesEnergyWithDocked(true)
            elseif service == "hull" then
                station_1:setRepairDocked(true)
            elseif service == "restock_probes" then
                station_1:setRestocksScanProbes(true)
            elseif service == "homing" then
                station_1.comms_data.weapon_available.Homing = true
            elseif service == "nuke" then
                station_1.comms_data.weapon_available.Nuke = true
            elseif service == "emp" then
                station_1.comms_data.weapon_available.EMP = true
            elseif service == "mine" then
                station_1.comms_data.weapon_available.Mine = true
            elseif service == "hvli" then
                station_1.comms_data.weapon_available.HVLI = true
            elseif service == "fix_scan" then
                station_1.comms_data.scan_repair = true
            elseif service == "fix_hack" then
                station_1.comms_data.hack_repair = true
            elseif service == "fix_probe_launch" then
                station_1.comms_data.probe_launch_repair = true
            elseif service == "fix_combat_maneuver" then
                station_1.comms_data.combat_maneuver_repair = true
            elseif service == "fix_self_destruct" then
                station_1.comms_data.self_destruct_repair = true
            elseif service == "fix_slow_tube" then
                station_1.comms_data.tube_slow_down_repair = true
            elseif service == "fix_reactor" then
                station_1.comms_data.system_repair.reactor.avail = true
            elseif service == "fix_beam" then
                station_1.comms_data.system_repair.beamweapons.avail = true
            elseif service == "fix_missile" then
                station_1.comms_data.system_repair.missilesystem.avail = true
            elseif service == "fix_maneuver" then
                station_1.comms_data.system_repair.maneuver.avail = true
            elseif service == "fix_impulse" then
                station_1.comms_data.system_repair.impulse.avail = true
            elseif service == "fix_warp" then
                station_1.comms_data.system_repair.warp.avail = true
            elseif service == "fix_jump" then
                station_1.comms_data.system_repair.jumpdrive.avail = true
            elseif service == "fix_front_shield" then
                station_1.comms_data.system_repair.frontshield.avail = true
            elseif service == "fix_rear_shield" then
                station_1.comms_data.system_repair.rearshield.avail = true
            elseif service == "supply_drop" then
                station_1.comms_data.service_available.supplydrop = true
            elseif service == "reinforcements" then
                station_1.comms_data.service_available.reinforcements = true
            elseif service == "hornet_reinforcements" then
                station_1.comms_data.service_available.hornet_reinforcements =
                    true
            elseif service == "phobos_reinforcements" then
                station_1.comms_data.service_available.phobos_reinforcements =
                    true
            elseif service == "amk3_reinforcements" then
                station_1.comms_data.service_available.amk3_reinforcements =
                    true
            elseif service == "amk8_reinforcements" then
                station_1.comms_data.service_available.amk8_reinforcements =
                    true
            elseif service == "jump_overcharge" then
                station_1.comms_data.service_available.jump_overcharge = true
            elseif service == "shield_overcharge" then
                station_1.comms_data.service_available.shield_overcharge = true
            elseif service == "jonque" then
                station_1.comms_data.service_available.jonque = true
            end
        end
    end
    maintenancePlot = defenseMaintenance
end
function placeWarpJammer(axis)
    if warp_jammer_count > 0 then
        local eo_x, eo_y = environmentObject(center_x, center_y, 200, axis)
        if eo_x ~= nil then
            local wj = WarpJammer():setPosition(eo_x, eo_y)
            local closest_station_distance = 999999
            local closest_station = nil
            for _, station in ipairs(station_list) do
                local current_distance = distance(station, eo_x, eo_y)
                if current_distance < closest_station_distance then
                    closest_station_distance = current_distance
                    closest_station = station
                end
            end
            local selected_faction = closest_station:getFaction()
            local warp_jammer_range = 0
            for i = 1, 5 do
                warp_jammer_range = warp_jammer_range + random(1000, 4000)
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
                for _, station in ipairs(station_list) do
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
                for _, transport in ipairs(transport_list) do
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
        for _, station in ipairs(station_list) do
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
        for index, station in ipairs(circle_stations) do
            if closest_station:getFaction() == station:getFaction() then
                match_index = index
                break
            end
        end
        local hi_neighbor = match_index + 1
        if hi_neighbor > #circle_stations then
            hi_neighbor = 1
        end
        local lo_neighbor = match_index - 1
        if lo_neighbor < 1 then
            lo_neighbor = #circle_stations
        end
        local faction_choices = {
            circle_stations[match_index]:getFaction(),
            circle_stations[hi_neighbor]:getFaction(),
            circle_stations[lo_neighbor]:getFaction(),
        }
        local selected_faction = faction_choices[math.random(1, 3)]
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
        local tfa = { true, false }
        station:setSharesEnergyWithDocked(tfa[math.random(1, 2)])
        station:setRepairDocked(tfa[math.random(1, 2)])
        station:setRestocksScanProbes(tfa[math.random(1, 2)])
        station.comms_data.weapon_available = {}
        station.comms_data.weapon_available.Homing = tfa[math.random(1, 2)]
        station.comms_data.weapon_available.Nuke = tfa[math.random(1, 2)]
        station.comms_data.weapon_available.EMP = tfa[math.random(1, 2)]
        station.comms_data.weapon_available.Mine = tfa[math.random(1, 2)]
        station.comms_data.weapon_available.HVLI = tfa[math.random(1, 2)]
        station.comms_data.scan_repair = tfa[math.random(1, 2)]
        station.comms_data.hack_repair = tfa[math.random(1, 2)]
        station.comms_data.probe_launch_repair = tfa[math.random(1, 2)]
        station.comms_data.combat_maneuver_repair = tfa[math.random(1, 2)]
        station.comms_data.self_destruct_repair = tfa[math.random(1, 2)]
        station.comms_data.tube_slow_down_repair = tfa[math.random(1, 2)]
        station.comms_data.system_repair = {
            ["reactor"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = tfa[math.random(1, 2)],
            },
            ["beamweapons"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = tfa[math.random(1, 2)],
            },
            ["missilesystem"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = tfa[math.random(1, 2)],
            },
            ["maneuver"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = tfa[math.random(1, 2)],
            },
            ["impulse"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = tfa[math.random(1, 2)],
            },
            ["warp"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = tfa[math.random(1, 2)],
            },
            ["jumpdrive"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = tfa[math.random(1, 2)],
            },
            ["frontshield"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = tfa[math.random(1, 2)],
            },
            ["rearshield"] = {
                cost = math.random(1, 9),
                max = random(0.7, 0.99),
                avail = tfa[math.random(1, 2)],
            },
        }
        station.comms_data.service_available = {
            supplydrop = tfa[math.random(1, 2)],
            reinforcements = tfa[math.random(1, 2)],
            hornet_reinforcements = tfa[math.random(1, 2)],
            phobos_reinforcements = tfa[math.random(1, 2)],
            amk3_reinforcements = tfa[math.random(1, 2)],
            amk8_reinforcements = tfa[math.random(1, 2)],
            jump_overcharge = tfa[math.random(1, 2)],
            shield_overcharge = tfa[math.random(1, 2)],
            jonque = tfa[math.random(1, 2)],
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
        table.insert(
            place_space,
            {
                obj = station,
                dist = station_defend_dist[s_size],
                shape = "circle",
            }
        )
        table.insert(station_list, station)
        table.insert(env_stations, station)
        --defense fleet
        local fleet = spawnEnemies(eo_x, eo_y, 1, selected_faction, 35)
        for _, ship in ipairs(fleet) do
            ship:setFaction("Independent")
            ship:orderDefendTarget(station)
            ship:setFaction(selected_faction)
            ship:setCallSign(generateCallSign(nil, selected_faction))
        end
        station.defense_fleet = fleet
        return station
    end
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
                            for _, ship in ipairs(fleet) do
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
function sensorJammerPickupProcess(self, retriever)
    local jammer_call_sign = self:getCallSign()
    sensor_jammer_list[jammer_call_sign] = nil
    if not self:isScannedBy(retriever) then
        retriever:setCanScan(false)
        retriever.scanner_dead = "scanner_dead"
        retriever:addCustomMessage(
            "Science",
            retriever.scanner_dead,
            _(
                "damage-msgScience",
                "The unscanned artifact we just picked up has fried our scanners"
            )
        )
        retriever.scanner_dead_ops = "scanner_dead_ops"
        retriever:addCustomMessage(
            "Operations",
            retriever.scanner_dead_ops,
            _(
                "damage-msgOperations",
                "The unscanned artifact we just picked up has fried our scanners"
            )
        )
    end
    may_explain_sensor_jammer = true
end
-- Transport selection and direction functions
---------------------------
-- Station communication --
---------------------------
local function showCurrentOrders(docked)
    setOptionalOrders()
    setSecondaryOrders()
    if docked then
        local station_count = 0
        for _, station in ipairs(inner_circle) do
            if station ~= nil and station:isValid() then
                station_count = station_count + 1
            end
        end
        if station_count > 1 then
            primary_orders = _(
                "orders-comms",
                "Survive. Protect the outpost which includes the following stations:"
            )
        else
            primary_orders = _(
                "orders-comms",
                "Survive. Protect the outpost which consists of the following station:"
            )
        end
        station_count = 0
        for _, station in ipairs(inner_circle) do
            if station ~= nil and station:isValid() then
                station_count = station_count + 1
                if station_count > 1 then
                    primary_orders = string.format(
                        "%s, %s (%s)",
                        primary_orders,
                        station:getCallSign(),
                        station:getFaction()
                    )
                else
                    primary_orders = string.format(
                        "%s %s (%s)",
                        primary_orders,
                        station:getCallSign(),
                        station:getFaction()
                    )
                end
            end
        end
        primary_orders = primary_orders .. "."
    else
        primary_orders = _(
            "orders-comms",
            "Survive. Protect the outpost which includes the following stations:"
        )
        for _, station in ipairs(inner_circle) do
            if station ~= nil and station:isValid() then
                primary_orders = string.format(
                    "%s\n%s (%s)",
                    primary_orders,
                    station:getCallSign(),
                    station:getFaction()
                )
            end
        end
    end
    ordMsg = primary_orders .. "\n" .. secondary_orders .. optional_orders
    if playWithTimeLimit then
        ordMsg = ordMsg
            .. string.format(
                _("orders-comms", "\n   %i Minutes remain in game"),
                math.floor(gameTimeLimit / 60)
            )
    end
    setCommsMessage(ordMsg)
    if getScenarioTime() > possible_victory_time then
        saboteurOption()
    end
end

local function offerOutpostHelp()
    for station_index, station in ipairs(circle_stations) do
        if station == comms_target then
            if not comms_target.help_requested then
                addCommsReply(
                    _(
                        "station-comms",
                        "Could you help defend our stations with some ships?"
                    ),
                    function()
                        setCommsMessage(
                            _(
                                "station-comms",
                                "We are also experiencing attacks. However, we will do what we can to help."
                            )
                        )
                        comms_target.help_requested = true
                        addCommsReply(_("Back"), commsStation)
                    end
                )
            end
            return
        end
    end
end

station_profile = {
    main_menu = commsStation,
    require_docked = true,
    combat_maneuver_capable = true,
    resources = { prompt = true },
    upgrades = {
        apply = function(player, upgrade_type)
            upgradePlayerShip(player, upgrade_type)
        end,
        explain = function()
            explainShipUpgrades()
        end,
    },
    docked = {
        show_reputation = true,
        before = StationMissions.docked,
        group_services = true,
        service_label = _(
            "station-comms",
            "Station services (restock ordnance, upgrades, repairs)"
        ),
        information = {
            prompt = _("station-comms", "What do you need to know?"),
            sections = {
                { kind = "warp_jammer", variant = "all" },
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
        cleanup_warp_jammers = true,
        warp_jammer_details = true,
        warp_jammer_details_context = "station_comms",
        warp_jammer_detail_order = {
            "friendly_friendly",
            "friendly_enemy",
            "friendly_neutral",
            "enemy_friendly",
            "enemy_enemy",
            "enemy_neutral",
            "neutral_friendly",
            "neutral_enemy",
            "neutral_neutral",
        },
        warp_jammer_back = true,
        waypoint_id = function(index)
            return comms_source:getWaypointID(index)
        end,
        information = {
            prompt = _("station-comms", "What kind of information do you need?"),
            sections = {
                {
                    kind = "orders",
                    callback = function()
                        showCurrentOrders(false)
                    end,
                },
                { kind = "location" },
                {
                    kind = "service_information",
                    label = _(
                        "station-comms",
                        "Station services (ordnance restock, repair, upgrade)"
                    ),
                    status_repair_typo = true,
                },
                { kind = "callback", callback = offerOutpostHelp },
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
    if getScenarioTime() > possible_victory_time then
        if comms_source.aggressive_enemy ~= nil then
            if comms_source.aggressive_enemy:isValid() then
                secondary_orders = string.format(
                    _(
                        "orders-comms",
                        "Destroy aggressive enemy bases including %s station %s in %s."
                    ),
                    comms_source.aggressive_enemy:getFaction(),
                    comms_source.aggressive_enemy:getCallSign(),
                    comms_source.aggressive_enemy:getSectorName()
                )
            else
                secondary_orders =
                    _("orders-comms", "Destroy aggressive enemy bases.")
            end
        end
    end
end
function setOptionalOrders()
    optional_orders = ""
    if
        comms_source.transport_mission ~= nil
        or comms_source.cargo_mission ~= nil
    then
        optional_orders = _("orders-comms", "\nOptional:")
    end
    if comms_source.transport_mission ~= nil then
        if
            comms_source.transport_mission.destination ~= nil
            and comms_source.transport_mission.destination:isValid()
        then
            optional_orders = string.format(
                _("orders-comms", "%s\nTransport %s to %s station %s in %s"),
                optional_orders,
                comms_source.transport_mission.character,
                comms_source.transport_mission.destination:getFaction(),
                comms_source.transport_mission.destination_name,
                comms_source.transport_mission.destination:getSectorName()
            )
        else
            optional_orders = string.format(
                _("orders-comms", "%s\nTransport %s to station %s (defunct)"),
                optional_orders,
                comms_source.transport_mission.character,
                comms_source.transport_mission.destination_name
            )
        end
    end
    if comms_source.cargo_mission ~= nil then
        if comms_source.cargo_mission.loaded then
            if
                comms_source.cargo_mission.destination ~= nil
                and comms_source.cargo_mission.destination:isValid()
            then
                optional_orders = string.format(
                    _(
                        "orders-comms",
                        "%s\nDeliver cargo for %s to station %s in %s"
                    ),
                    optional_orders,
                    comms_source.cargo_mission.character,
                    comms_source.cargo_mission.destination_name,
                    comms_source.cargo_mission.destination:getSectorName()
                )
            else
                optional_orders = string.format(
                    _(
                        "orders-comms",
                        "%s\nDeliver cargo for %s to station %s (defunct)"
                    ),
                    optional_orders,
                    comms_source.cargo_mission.character,
                    comms_source.cargo_mission.destination_name
                )
            end
        else
            if
                comms_source.cargo_mission.origin ~= nil
                and comms_source.cargo_mission.origin:isValid()
            then
                optional_orders = string.format(
                    _(
                        "orders-comms",
                        "%s\nPick up cargo for %s at station %s in %s"
                    ),
                    optional_orders,
                    comms_source.cargo_mission.character,
                    comms_source.cargo_mission.origin_name,
                    comms_source.cargo_mission.origin:getSectorName()
                )
            else
                optional_orders = string.format(
                    _(
                        "orders-comms",
                        "%s\nPick up cargo for %s at station %s (defunct)"
                    ),
                    optional_orders,
                    comms_source.cargo_mission.character,
                    comms_source.cargo_mission.origin_name
                )
            end
        end
    end
    local out1 = "None"
    if comms_source.saboteur_instructions ~= nil then
        out1 = comms_source.saboteur_instructions
    end
    local out2 = "No deployed ship"
    if comms_source.saboteur_deployed ~= nil then
        out2 = comms_source.saboteur_deployed
    end
    local out3 = "None"
    if comms_source.saboteur_ship ~= nil then
        out3 = comms_source.saboteur_ship
    end
    local out4 = "Not successful"
    local out5 = "No target"
    if
        comms_source.saboteur_ship ~= nil
        and comms_source.saboteur_ship:isValid()
    then
        if comms_source.saboteur_ship.sabotage_success ~= nil then
            out4 = comms_source.saboteur_ship.sabotage_success
        end
        if
            comms_source.saboteur_ship.sabotage_target ~= nil
            and comms_source.saboteur_ship.sabotage_target:isValid()
        then
            out5 = comms_source.saboteur_ship.sabotage_target:getCallSign()
        else
            out5 = "Target destroyed"
        end
    end
    print(
        "instructions:",
        out1,
        "deployed:",
        out2,
        "ship:",
        out3,
        "success:",
        out4,
        "target:",
        out5
    )
    if comms_source.saboteur_instructions ~= nil then
        if comms_source.saboteur_deployed ~= nil then
            if
                comms_source.saboteur_ship ~= nil
                and comms_source.saboteur_ship:isValid()
            then
                if comms_source.saboteur_ship.sabotage_success == nil then
                    local docked_station =
                        comms_source.saboteur_ship:getDockedWith()
                    if comms_source.saboteur_ship.sabotage_target ~= nil then
                        if
                            comms_source.saboteur_ship.sabotage_target:isValid()
                        then
                            if docked_station == nil then
                                optional_orders = string.format(
                                    _(
                                        "orders-comms",
                                        "%s\nExplosives planted on aggressive %s station %s. Expect detonation in %s seconds"
                                    ),
                                    optional_orders,
                                    comms_source.saboteur_ship.sabotage_target:getFaction(),
                                    comms_source.saboteur_ship.sabotage_target:getCallSign(),
                                    math.floor(
                                        comms_source.saboteur_ship.explode_time
                                            - getScenarioTime()
                                    )
                                )
                            else
                                optional_orders = string.format(
                                    _(
                                        "orders-comms",
                                        "%s\nSaboteur's ship, %s, docked with %s station %s in sector %s. %s has been identified as an aggressive station. Explosives have been planted. Expect detonation in %s seconds"
                                    ),
                                    optional_orders,
                                    comms_source.saboteur_deployed,
                                    docked_station:getFaction(),
                                    docked_station:getCallSign(),
                                    docked_station:getSectorName(),
                                    docked_station:getCallSign(),
                                    math.floor(
                                        comms_source.saboteur_ship.explode_time
                                            - getScenarioTime()
                                    )
                                )
                            end
                        else
                            optional_orders = string.format(
                                _(
                                    "orders-comms",
                                    "%s\nSabotage target station has been destroyed"
                                ),
                                optional_orders
                            )
                        end
                    else
                        if docked_station == nil then
                            local saboteur_target_aggressive = false
                            local saboteur_target =
                                comms_source.saboteur_ship:getOrderTarget()
                            local target_station_message = ""
                            if saboteur_target ~= nil then
                                for _, station in ipairs(circle_stations) do
                                    if station ~= nil and station:isValid() then
                                        if station == saboteur_target then
                                            if
                                                comms_source:isEnemy(station)
                                            then
                                                saboteur_target_aggressive =
                                                    true
                                            end
                                            break
                                        end
                                    end
                                end
                                target_station_message = string.format(
                                    _(
                                        "orders-comms",
                                        "%s's destination station, %s in %s, is not an aggressive enemy station."
                                    ),
                                    comms_source.saboteur_deployed,
                                    saboteur_target:getCallSign(),
                                    saboteur_target:getSectorName()
                                )
                                if saboteur_target_aggressive then
                                    target_station_message = string.format(
                                        _(
                                            "orders-comms",
                                            "%s's destination station, %s in %s, has been identified as an aggressive enemy station."
                                        ),
                                        comms_source.saboteur_deployed,
                                        saboteur_target:getCallSign(),
                                        saboteur_target:getSectorName()
                                    )
                                end
                            end
                            optional_orders = string.format(
                                _(
                                    "orders-comms",
                                    "%s\nSaboteur's ship, %s, is in transit in sector %s. %s"
                                ),
                                optional_orders,
                                comms_source.saboteur_deployed,
                                comms_source.saboteur_ship:getSectorName(),
                                target_station_message
                            )
                        else
                            local in_circle = false
                            for _, station in ipairs(circle_stations) do
                                if docked_station == station then
                                    in_circle = true
                                    break
                                end
                            end
                            if docked_station:isEnemy(comms_source) then
                                if in_circle then
                                    optional_orders = string.format(
                                        _(
                                            "orders-comms",
                                            "%s\nSaboteur's ship, %s, docked with %s station %s in sector %s. %s has been identified as an aggressive station"
                                        ),
                                        optional_orders,
                                        comms_source.saboteur_deployed,
                                        docked_station:getFaction(),
                                        docked_station:getCallSign(),
                                        docked_station:getSectorName(),
                                        docked_station:getCallSign()
                                    )
                                else
                                    optional_orders = string.format(
                                        _(
                                            "orders-comms",
                                            "%s\nSaboteur's ship, %s, docked with %s station %s in sector %s. %s is not an aggressive station"
                                        ),
                                        optional_orders,
                                        comms_source.saboteur_deployed,
                                        docked_station:getFaction(),
                                        docked_station:getCallSign(),
                                        docked_station:getSectorName(),
                                        docked_station:getCallSign()
                                    )
                                end
                            else
                                optional_orders = string.format(
                                    _(
                                        "orders-comms",
                                        "%s\nSaboteur's ship, %s, docked with %s station %s in sector %s."
                                    ),
                                    optional_orders,
                                    comms_source.saboteur_deployed,
                                    docked_station:getFaction(),
                                    docked_station:getCallSign(),
                                    docked_station:getSectorName()
                                )
                            end
                        end
                    end
                else
                    optional_orders = string.format(
                        _(
                            "orders-comms",
                            "%s\nSaboteur successfully destroyed aggressive enemy station %s"
                        ),
                        optional_orders,
                        comms_source.saboteur_ship.sabotage_success
                    )
                end
            else
                optional_orders = string.format(
                    _(
                        "orders-comms",
                        "%s\nSaboteur's ship, %s, has been destroyed"
                    ),
                    optional_orders,
                    comms_source.saboteur_deployed
                )
            end
        else
            optional_orders = string.format(
                _("orders-comms", "%s\nPlant saboteur on freighter"),
                optional_orders
            )
        end
    end
end
-- Non-standard communications functions
function upgradePlayerShip(p, u_type)
    local tempTypeName = p:getTypeName()
    local current_level = p.upgrade_path[u_type]
    if u_type == "beam" then
        for i, b in ipairs(upgrade_path[tempTypeName].beam[current_level + 1]) do
            p:setBeamWeapon(b.idx, b.arc, b.dir, b.rng, b.cyc, b.dmg)
            p:setBeamWeaponTurret(b.idx, 0, 0, 0)
            if b.tar ~= nil then
                p:setBeamWeaponTurret(b.idx, b.tar, b.tdr, b.trt)
            end
        end
    elseif u_type == "missiles" then
        for i = 1, p:getWeaponTubeCount() do
            local tube_speed = p:getTubeLoadTime(i - 1)
            p:setTubeLoadTime(i + 1, 0.000001)
            p:commandUnloadTube(i - 1)
            p:setTubeLoadTime(i + 1, tube_speed)
        end
        local tube_level =
            upgrade_path[tempTypeName].missiles[current_level + 1].tube
        local ordnance_level =
            upgrade_path[tempTypeName].missiles[current_level + 1].ord
        p:setWeaponTubeCount(#upgrade_path[tempTypeName].tube[tube_level])
        local size_trans = {
            ["S"] = "small",
            ["M"] = "medium",
            ["L"] = "large",
        }
        local missile_trans = {
            { typ = "Homing", short_type = "hom" },
            { typ = "Nuke", short_type = "nuk" },
            { typ = "EMP", short_type = "emp" },
            { typ = "Mine", short_type = "min" },
            { typ = "HVLI", short_type = "hvl" },
        }
        for i, m in ipairs(upgrade_path[tempTypeName].tube[tube_level]) do
            p:setWeaponTubeDirection(m.idx, m.dir)
            p:setTubeSize(m.idx, size_trans[m.siz])
            p:setTubeLoadTime(m.idx, m.spd)
            local exclusive = false
            for j, lm in ipairs(missile_trans) do
                if m[lm.short_type] then
                    if exclusive then
                        p:weaponTubeAllowMissle(m.idx, lm.typ)
                    else
                        p:setWeaponTubeExclusiveFor(m.idx, lm.typ)
                        exclusive = true
                    end
                end
            end
        end
        for i, o in ipairs(missile_trans) do
            -- print("upgrade ship missiles: o typ:",o.typ,"template:",tempTypeName,"ordnance level:",ordnance_level,"o short type:",o.short_type)
            p:setWeaponStorageMax(
                o.typ,
                upgrade_path[tempTypeName].ordnance[ordnance_level][o.short_type]
            )
        end
        if p:getWeaponTubeCount() > 0 then
            local size_letter = {
                ["small"] = "S",
                ["medium"] = "M",
                ["large"] = "L",
            }
            p.tube_size = ""
            for i = 1, p:getWeaponTubeCount() do
                p.tube_size = p.tube_size .. size_letter[p:getTubeSize(i - 1)]
            end
        end
    elseif u_type == "shield" then
        if #upgrade_path[tempTypeName].shield[current_level + 1] > 1 then
            p:setShieldsMax(
                upgrade_path[tempTypeName].shield[current_level + 1][1].max,
                upgrade_path[tempTypeName].shield[current_level + 1][2].max
            )
            p:setShields(
                upgrade_path[tempTypeName].shield[current_level + 1][1].max,
                upgrade_path[tempTypeName].shield[current_level + 1][2].max
            )
        else
            p:setShieldsMax(
                upgrade_path[tempTypeName].shield[current_level + 1][1].max
            )
            p:setShields(
                upgrade_path[tempTypeName].shield[current_level + 1][1].max
            )
        end
    elseif u_type == "hull" then
        p:setHullMax(upgrade_path[tempTypeName].hull[current_level + 1].max)
        p:setHull(upgrade_path[tempTypeName].hull[current_level + 1].max)
    elseif u_type == "impulse" then
        p:setImpulseMaxSpeed(
            upgrade_path[tempTypeName].impulse[current_level + 1].max_front,
            upgrade_path[tempTypeName].impulse[current_level + 1].max_back
        )
        p:setAcceleration(
            upgrade_path[tempTypeName].impulse[current_level + 1].accel_front,
            upgrade_path[tempTypeName].impulse[current_level + 1].accel_back
        )
        p:setRotationMaxSpeed(
            upgrade_path[tempTypeName].impulse[current_level + 1].turn
        )
        if
            upgrade_path[tempTypeName].impulse[current_level + 1].boost > 0
            or upgrade_path[tempTypeName].impulse[current_level + 1].strafe
                > 0
        then
            p:setCanCombatManeuver(true)
            p:setCombatManeuver(
                upgrade_path[tempTypeName].impulse[current_level + 1].boost,
                upgrade_path[tempTypeName].impulse[current_level + 1].strafe
            )
            p.combat_maneuver_capable = true
        end
    elseif u_type == "ftl" then
        if upgrade_path[tempTypeName].ftl[current_level + 1].jump_long > 0 then
            p:setJumpDrive(true)
            p.max_jump_range =
                upgrade_path[tempTypeName].ftl[current_level + 1].jump_long
            p.min_jump_range =
                upgrade_path[tempTypeName].ftl[current_level + 1].jump_short
            p:setJumpDriveRange(p.min_jump_range, p.max_jump_range)
            p:setJumpDriveCharge(p.max_jump_range)
        end
        if upgrade_path[tempTypeName].ftl[current_level + 1].warp > 0 then
            p:setWarpDrive(true)
            p:setWarpSpeed(
                upgrade_path[tempTypeName].ftl[current_level + 1].warp
            )
        end
    elseif u_type == "sensors" then
        p:setLongRangeRadarRange(
            upgrade_path[tempTypeName].sensors[current_level + 1].long
        )
        p.normal_long_range_radar =
            upgrade_path[tempTypeName].sensors[current_level + 1].long
        p:setShortRangeRadarRange(
            upgrade_path[tempTypeName].sensors[current_level + 1].short
        )
        p.prox_scan =
            upgrade_path[tempTypeName].sensors[current_level + 1].prox_scan
    end
    p.upgrade_path[u_type] = current_level + 1
    p.shipScore = p.shipScore + 1
end
function explainShipUpgrades()
    setCommsMessage(
        _(
            "upgrade-comms",
            "Which ship system upgrade category are you wondering about?"
        )
    )
    --upgrade_path explained
    addCommsReply(_("upgrade-comms", "beam"), function()
        setCommsMessage(
            _(
                "upgrade-comms",
                "Beam upgrades refer to the beam weapons systems. They might include additional beam mounts, longer range, faster recharge or cycle times, increased damage, wider beam firing arcs or faster beam turret rotation speed."
            )
        )
        addCommsReply(
            _("upgrade-comms", "Back to ship upgrade category explanation list"),
            explainShipUpgrades
        )
        addCommsReply(_("Back"), commsStation)
    end)
    addCommsReply(_("upgrade-comms", "missiles"), function()
        setCommsMessage(
            _(
                "upgrade-comms",
                "Missile upgrades refer to aspects of the missile weapons systems. They might include additional tubes, faster tube load times, increased tube size, additional missile types or additional missile storage capacity."
            )
        )
        addCommsReply(
            _("upgrade-comms", "Back to ship upgrade category explanation list"),
            explainShipUpgrades
        )
        addCommsReply(_("Back"), commsStation)
    end)
    addCommsReply(_("upgrade-comms", "shield"), function()
        setCommsMessage(
            _(
                "upgrade-comms",
                "Shield upgrades refer to the protective energy shields around your ship. They might include increased charge capacity (overall strength) for the front, rear or both shield arcs or the addition of a shield arc."
            )
        )
        addCommsReply(
            _("upgrade-comms", "Back to ship upgrade category explanation list"),
            explainShipUpgrades
        )
        addCommsReply(_("Back"), commsStation)
    end)
    addCommsReply(_("upgrade-comms", "hull"), function()
        setCommsMessage(
            _(
                "upgrade-comms",
                "Hull upgrades refer to strengthening the ship hull to withstand more damage in the form of armor plating or structural bolstering."
            )
        )
        addCommsReply(
            _("upgrade-comms", "Back to ship upgrade category explanation list"),
            explainShipUpgrades
        )
        addCommsReply(_("Back"), commsStation)
    end)
    addCommsReply(_("upgrade-comms", "impulse"), function()
        setCommsMessage(
            _(
                "upgrade-comms",
                "Impulse upgrades refer to changes related to the impulse engines. They might include improving the top speed or acceleration (forward, reverse or both), maneuvering speed or combat maneuver (boost, which is moving forward, or strafe, which is sideways motion or both)."
            )
        )
        addCommsReply(
            _("upgrade-comms", "Back to ship upgrade category explanation list"),
            explainShipUpgrades
        )
        addCommsReply(_("Back"), commsStation)
    end)
    addCommsReply(_("upgrade-comms", "ftl"), function()
        setCommsMessage(
            _(
                "upgrade-comms",
                "FTL (short for faster than light) upgrades refer to warp drive or jump drive enhancements. They might include the addition of an ftl drive, a change in the range of the jump drive or an increase in the top speed of the warp drive"
            )
        )
        addCommsReply(
            _("upgrade-comms", "Back to ship upgrade category explanation list"),
            explainShipUpgrades
        )
        addCommsReply(_("Back"), commsStation)
    end)
    addCommsReply(_("upgrade-comms", "sensors"), function()
        setCommsMessage(
            _(
                "upgrade-comms",
                "Sensor upgrades refer to the ship's ability to detect other objects. They might include increased long range sensors, increased short range sensors, automated proximity scanners for ships or improved range for automated proximity scanners."
            )
        )
        addCommsReply(
            _("upgrade-comms", "Back to ship upgrade category explanation list"),
            explainShipUpgrades
        )
        addCommsReply(_("Back"), commsStation)
    end)
    addCommsReply(_("Back"), commsStation)
end
function saboteurOption()
    if comms_source.aggressive_enemy == nil then
        addCommsReply(
            _(
                "orders-comms",
                "Is there any chance at victory for this outpost?"
            ),
            function()
                setCommsMessage(
                    _(
                        "orders-comms",
                        "The outpost leadership have been bemoaning their fate and discussing various options. They think there's an off chance for long term viability for the outpost."
                    )
                )
                addCommsReply(
                    _("orders-comms", "Don't keep me in suspense"),
                    function()
                        setCommsMessage(
                            _(
                                "orders-comms",
                                "It's a low probability scenario, but if we destroyed the most aggressive enemy stations in the area, we might get the rest to agree to a truce."
                            )
                        )
                        addCommsReply(
                            _(
                                "orders-comms",
                                "Which ones are the aggressive ones?"
                            ),
                            function()
                                if comms_source.aggressive_enemy == nil then
                                    setCommsMessage(
                                        _(
                                            "orders-comms",
                                            "The ones that keep sending attacking ships. You can just track back along the attacking ships' approach vector to find their home base."
                                        )
                                    )
                                    addCommsReply(
                                        _(
                                            "orders-comms",
                                            "Have you tracked any based on approach vector?"
                                        ),
                                        function()
                                            local aggressive_enemies = {}
                                            for i, station in
                                                ipairs(circle_stations)
                                            do
                                                if
                                                    station ~= nil
                                                    and station:isValid()
                                                    and station:isEnemy(
                                                        comms_source
                                                    )
                                                then
                                                    table.insert(
                                                        aggressive_enemies,
                                                        station
                                                    )
                                                end
                                            end
                                            comms_source.aggressive_enemy =
                                                tableRemoveRandom(
                                                    aggressive_enemies
                                                )
                                            setCommsMessage(
                                                string.format(
                                                    _(
                                                        "orders-comms",
                                                        "From our observations, %s station %s in %s is one of them.\n\nOne more thing about this plan..."
                                                    ),
                                                    comms_source.aggressive_enemy:getFaction(),
                                                    comms_source.aggressive_enemy:getCallSign(),
                                                    comms_source.aggressive_enemy:getSectorName()
                                                )
                                            )
                                            addCommsReply(
                                                _(
                                                    "orders-comms",
                                                    "Just one? What is it?"
                                                ),
                                                function()
                                                    setCommsMessage(
                                                        _(
                                                            "orders-comms",
                                                            "If there are any friendly or neutral stations you haven't contacted yet to ask for their help, you should contact them at your earliest opportunity. A truce benefits them, too, assuming you succeed. The help they provide in protecting the outpost can free you up to destroy the aggressive stations."
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
                                else
                                    if
                                        comms_source.aggressive_enemy:isValid()
                                    then
                                        setCommsMessage(
                                            string.format(
                                                _(
                                                    "orders-comms",
                                                    "%s station %s in %s"
                                                ),
                                                comms_source.aggressive_enemy:getFaction(),
                                                comms_source.aggressive_enemy:getCallSign(),
                                                comms_source.aggressive_enemy:getSectorName()
                                            )
                                        )
                                    else
                                        local aggressive_enemies = {}
                                        for i, station in
                                            ipairs(circle_stations)
                                        do
                                            if
                                                station ~= nil
                                                and station:isValid()
                                                and station:isEnemy(
                                                    comms_source
                                                )
                                            then
                                                table.insert(
                                                    aggressive_enemies,
                                                    station
                                                )
                                            end
                                        end
                                        comms_source.aggressive_enemy =
                                            tableRemoveRandom(
                                                aggressive_enemies
                                            )
                                        setCommsMessage(
                                            string.format(
                                                _(
                                                    "orders-comms",
                                                    "%s station %s in %s is probably another aggressive station"
                                                ),
                                                comms_source.aggressive_enemy:getFaction(),
                                                comms_source.aggressive_enemy:getCallSign(),
                                                comms_source.aggressive_enemy:getSectorName()
                                            )
                                        )
                                    end
                                end
                                addCommsReply(_("Back"), commsStation)
                            end
                        )
                        addCommsReply(_("Back"), commsStation)
                    end
                )
                addCommsReply(_("Back"), commsStation)
            end
        )
    else
        addCommsReply(
            _("orders-comms", "Any better chance at victory for this outpost?"),
            function()
                local out = ""
                if comms_source.aggressive_enemy:isValid() then
                    out = string.format(
                        _(
                            "orders-comms",
                            "%s station %s in %s is still the one station we've been able to track the attacking ships back to."
                        ),
                        comms_source.aggressive_enemy:getFaction(),
                        comms_source.aggressive_enemy:getCallSign(),
                        comms_source.aggressive_enemy:getSectorName()
                    )
                else
                    local aggressive_enemies = {}
                    for i, station in ipairs(circle_stations) do
                        if
                            station ~= nil
                            and station:isValid()
                            and station:isEnemy(comms_source)
                        then
                            table.insert(aggressive_enemies, station)
                        end
                    end
                    comms_source.aggressive_enemy =
                        tableRemoveRandom(aggressive_enemies)
                    out = string.format(
                        _(
                            "orders-comms",
                            "%s station %s in %s is probably another aggressive station."
                        ),
                        comms_source.aggressive_enemy:getFaction(),
                        comms_source.aggressive_enemy:getCallSign(),
                        comms_source.aggressive_enemy:getSectorName()
                    )
                end
                if getScenarioTime() > saboteur_idea_time then
                    if comms_source.saboteur_instructions then
                        addCommsReply(
                            _(
                                "orders-comms",
                                "Remind me about the saboteur plan"
                            ),
                            function()
                                local out = _(
                                    "orders-comms",
                                    "Summary: Be sure you have at least one mine aboard. Find a neutral freighter. Convince them to take on a new crewmember. From there it's up to the saboteur."
                                )
                                if comms_source.saboteur_deployed ~= nil then
                                    out = string.format(
                                        _(
                                            "orders-comms",
                                            "%s\nYou have already planted the saboteur on %s"
                                        ),
                                        out,
                                        comms_source.saboteur_deployed
                                    )
                                else
                                    if
                                        comms_source:getRepairCrewCount() < 1
                                    then
                                        out = string.format(
                                            _(
                                                "orders-comms",
                                                "%s\nYou need to replace one or more of your repair crew. We'll be sure the first one you get also has saboteur training."
                                            ),
                                            out
                                        )
                                    end
                                    if
                                        comms_source:getWeaponStorage("Mine")
                                        < 1
                                    then
                                        out = string.format(
                                            _(
                                                "orders-comms",
                                                "%s\nYou need a mine to give to the saboteur."
                                            ),
                                            out
                                        )
                                    end
                                end
                                setCommsMessage(out)
                                addCommsReply(_("Back"), commsStation)
                            end
                        )
                    else
                        if
                            comms_source:getRepairCrewCount() > 0
                            and comms_source:getWeaponStorage("Mine") > 0
                        then
                            out = string.format(
                                _(
                                    "orders-comms",
                                    "%s The outpost leadership have an idea about how an aggressive enemy station might be destroyed. It differs from the confrontational solution of attacking an aggressive enemy station directly. Interested?"
                                ),
                                out
                            )
                            addCommsReply(
                                _(
                                    "orders-comms",
                                    "Yes, tell me about this idea"
                                ),
                                function()
                                    setCommsMessage(
                                        _(
                                            "orders-comms",
                                            "The idea is to sneak a saboteur aboard an aggressive enemy station."
                                        )
                                    )
                                    addCommsReply(
                                        _(
                                            "orders-comms",
                                            "We can't dock with an enemy station"
                                        ),
                                        function()
                                            setCommsMessage(
                                                _(
                                                    "orders-comms",
                                                    "That's true. However, commercial freighters dock with those stations all the time. Commerce must go on despite the hostilities."
                                                )
                                            )
                                            addCommsReply(
                                                _(
                                                    "orders-comms",
                                                    "Put a saboteur on a freighter?"
                                                ),
                                                function()
                                                    setCommsMessage(
                                                        _(
                                                            "orders-comms",
                                                            "Right. The saboteur stays on the freighter until the freighter docks with an aggressive enemy station. The saboteur then plants explosives on the station at a vulnerable point."
                                                        )
                                                    )
                                                    addCommsReply(
                                                        _(
                                                            "orders-comms",
                                                            "I see problems with this idea"
                                                        ),
                                                        function()
                                                            setCommsMessage(
                                                                _(
                                                                    "orders-comms",
                                                                    "Oh yes, there are several critical points where the plan could fail. The freighter you choose might not accept the saboteur. The freighter might get destroyed before they dock at an aggressive enemy station. The security measures on the station may prevent the saboteur from planting the explosives."
                                                                )
                                                            )
                                                            addCommsReply(
                                                                _(
                                                                    "orders-comms",
                                                                    "Another point: we don't have a saboteur"
                                                                ),
                                                                function()
                                                                    setCommsMessage(
                                                                        _(
                                                                            "orders-comms",
                                                                            "Actually, that's not true. One of your repair crew recently completed a correspondence course in espionage and sabotage and thus could be deployed as the saboteur for this plan."
                                                                        )
                                                                    )
                                                                    addCommsReply(
                                                                        _(
                                                                            "orders-comms",
                                                                            "Does graduation come with complimentary explosives?"
                                                                        ),
                                                                        function()
                                                                            setCommsMessage(
                                                                                _(
                                                                                    "orders-comms",
                                                                                    "No. We did away with an actual graduation ceremony because too many of our graduates wanted to test their new sabotage skills as a prank at graduation causing distressful mayhem. However, your repair crew now has the training to adapt one of your mines into the appropriate explosives for the plan."
                                                                                )
                                                                            )
                                                                            addCommsReply(
                                                                                _(
                                                                                    "orders-comms",
                                                                                    "Isn't it illegal?"
                                                                                ),
                                                                                function()
                                                                                    setCommsMessage(
                                                                                        string.format(
                                                                                            _(
                                                                                                "orders-comms",
                                                                                                "Your repair crew saboteur has the full backing and approval of the outpost leadership. The sabotage is sanctioned under the rules outlined in the %s charter assuming the saboteur knows the risks and volunteers. We've taken the liberty of providing an outline of the plan to the repair crew saboteur and secured their agreement to conduct the mission in writing. Copies of this and the formal sanctioning of the action by the outpost leadership are in your secure databanks."
                                                                                            ),
                                                                                            comms_source:getFaction()
                                                                                        )
                                                                                    )
                                                                                    addCommsReply(
                                                                                        _(
                                                                                            "orders-comms",
                                                                                            "How do we know if this plan succeeds or fails?"
                                                                                        ),
                                                                                        function()
                                                                                            setCommsMessage(
                                                                                                _(
                                                                                                    "orders-comms",
                                                                                                    "Every saboteur is trained to send simple status reports through the microscopic subspace transmitter surgically implanted in them during their training. When you check on your orders, updates will be shown on the plan progress in that report."
                                                                                                )
                                                                                            )
                                                                                            addCommsReply(
                                                                                                _(
                                                                                                    "orders-comms",
                                                                                                    "That's a convoluted plan. Can you summarize what we need to do?"
                                                                                                ),
                                                                                                function()
                                                                                                    setCommsMessage(
                                                                                                        _(
                                                                                                            "orders-comms",
                                                                                                            "Be sure you have at least one mine aboard. Find a neutral freighter. Convince them to take on a new crewmember. From there it's up to the saboteur."
                                                                                                        )
                                                                                                    )
                                                                                                    comms_source.saboteur_instructions =
                                                                                                        true
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
                                    addCommsReply(_("Back"), commsStation)
                                end
                            )
                            addCommsReply(
                                _(
                                    "orders-comms",
                                    "No, we're having enough trouble as it is"
                                ),
                                function()
                                    setCommsMessage(
                                        _("orders-comms", "Suit yourself")
                                    )
                                    addCommsReply(_("Back"), commsStation)
                                end
                            )
                        end
                    end
                end
                setCommsMessage(out)
                addCommsReply(_("Back"), commsStation)
            end
        )
    end
end
------------------------
-- Ship communication --
------------------------
function deploySaboteur()
    if comms_source.saboteur_instructions then
        if comms_source.saboteur_deployed == nil then
            if comms_source:getRepairCrewCount() > 0 then
                if comms_source:getWeaponStorage("Mine") > 0 then
                    if not comms_target.saboteur_process_complete then
                        addCommsReply(
                            _(
                                "ship-comms",
                                "Would you like another crewmember?"
                            ),
                            function()
                                setCommsMessage(
                                    _("ship-comms", "We don't really need one")
                                )
                                addCommsReply(
                                    _(
                                        "ship-comms",
                                        "This one's got repair crew experience"
                                    ),
                                    function()
                                        local convincing_avenue = false
                                        if
                                            comms_source:getReputationPoints()
                                            >= 50
                                        then
                                            convincing_avenue = true
                                            addCommsReply(
                                                _(
                                                    "ship-comms",
                                                    "Take on crewmember as a favor (50 reputation)?"
                                                ),
                                                function()
                                                    if
                                                        comms_source:getRepairCrewCount()
                                                        > 0
                                                    then
                                                        if
                                                            comms_source:getWeaponStorage(
                                                                "Mine"
                                                            )
                                                            > 0
                                                        then
                                                            if
                                                                comms_source:takeReputationPoints(
                                                                    50
                                                                )
                                                            then
                                                                comms_target.saboteur_process_complete =
                                                                    true
                                                                comms_source:setRepairCrewCount(
                                                                    comms_source:getRepairCrewCount()
                                                                        - 1
                                                                )
                                                                comms_source:setWeaponStorage(
                                                                    "Mine",
                                                                    comms_source:getWeaponStorage(
                                                                        "Mine"
                                                                    )
                                                                        - 1
                                                                )
                                                                comms_source.saboteur_deployed =
                                                                    comms_target:getCallSign()
                                                                comms_source.saboteur_ship =
                                                                    comms_target
                                                                if
                                                                    saboteur_freighters
                                                                    == nil
                                                                then
                                                                    saboteur_freighters =
                                                                        {}
                                                                end
                                                                table.insert(
                                                                    saboteur_freighters,
                                                                    comms_target
                                                                )
                                                                setCommsMessage(
                                                                    _(
                                                                        "ship-comms",
                                                                        "We have taken on your repair crewmember as a new crewmember on our ship."
                                                                    )
                                                                )
                                                            else
                                                                setCommsMessage(
                                                                    _(
                                                                        "needRep-comms",
                                                                        "Insufficient reputation"
                                                                    )
                                                                )
                                                                comms_target.saboteur_process_complete =
                                                                    true
                                                            end
                                                        else
                                                            setCommsMessage(
                                                                _(
                                                                    "ship-comms",
                                                                    "No mine to send with saboteur"
                                                                )
                                                            )
                                                            comms_target.saboteur_process_complete =
                                                                true
                                                        end
                                                    else
                                                        setCommsMessage(
                                                            _(
                                                                "ship-comms",
                                                                "No repair crew to send"
                                                            )
                                                        )
                                                        comms_target.saboteur_process_complete =
                                                            true
                                                    end
                                                    addCommsReply(
                                                        _("Back"),
                                                        commsShip
                                                    )
                                                end
                                            )
                                        end
                                        local player_good_count = 0
                                        if comms_source.goods ~= nil then
                                            for good, goodQuantity in
                                                pairs(comms_source.goods)
                                            do
                                                player_good_count = player_good_count
                                                    + goodQuantity
                                            end
                                        end
                                        if player_good_count > 0 then
                                            convincing_avenue = true
                                            for good, goodQuantity in
                                                pairs(comms_source.goods)
                                            do
                                                if goodQuantity > 0 then
                                                    addCommsReply(
                                                        string.format(
                                                            _(
                                                                "ship-comms",
                                                                "Offer %s to take on crewmember"
                                                            ),
                                                            good
                                                        ),
                                                        function()
                                                            if
                                                                comms_source:getRepairCrewCount()
                                                                > 0
                                                            then
                                                                if
                                                                    comms_source:getWeaponStorage(
                                                                        "Mine"
                                                                    )
                                                                    > 0
                                                                then
                                                                    comms_source.goods[good] = comms_source.goods[good]
                                                                        - 1
                                                                    comms_target.saboteur_process_complete =
                                                                        true
                                                                    comms_source:setRepairCrewCount(
                                                                        comms_source:getRepairCrewCount()
                                                                            - 1
                                                                    )
                                                                    comms_source:setWeaponStorage(
                                                                        "Mine",
                                                                        comms_source:getWeaponStorage(
                                                                            "Mine"
                                                                        )
                                                                            - 1
                                                                    )
                                                                    comms_source.saboteur_deployed =
                                                                        comms_target:getCallSign()
                                                                    comms_source.saboteur_ship =
                                                                        comms_target
                                                                    if
                                                                        saboteur_freighters
                                                                        == nil
                                                                    then
                                                                        saboteur_freighters =
                                                                            {}
                                                                    end
                                                                    table.insert(
                                                                        saboteur_freighters,
                                                                        comms_target
                                                                    )
                                                                    setCommsMessage(
                                                                        string.format(
                                                                            _(
                                                                                "ship-comms",
                                                                                "Thanks for the %s. We have taken on your repair crewmember as a new crewmember on our ship."
                                                                            ),
                                                                            good
                                                                        )
                                                                    )
                                                                else
                                                                    setCommsMessage(
                                                                        _(
                                                                            "ship-comms",
                                                                            "No mine to send with saboteur"
                                                                        )
                                                                    )
                                                                    comms_target.saboteur_process_complete =
                                                                        true
                                                                end
                                                            else
                                                                setCommsMessage(
                                                                    _(
                                                                        "ship-comms",
                                                                        "No repair crew to send"
                                                                    )
                                                                )
                                                                comms_target.saboteur_process_complete =
                                                                    true
                                                            end
                                                            addCommsReply(
                                                                _("Back"),
                                                                commsShip
                                                            )
                                                        end
                                                    )
                                                end
                                            end
                                        end
                                        if convincing_avenue then
                                            setCommsMessage(
                                                _(
                                                    "ship-comms",
                                                    "I talked to the captain, but he still needs convincing."
                                                )
                                            )
                                        else
                                            setCommsMessage(
                                                string.format(
                                                    _(
                                                        "ship-comms",
                                                        "Not interested.\n\n[Outpost Leadership] We were monitoring your exchange with %s. Next time, try convincing the captain using 50 or more reputation or with some cargo aboard your ship."
                                                    ),
                                                    comms_target:getCallSign()
                                                )
                                            )
                                            comms_target.saboteur_process_complete =
                                                true
                                        end
                                        addCommsReply(_("Back"), commsShip)
                                    end
                                )
                                addCommsReply(
                                    _(
                                        "ship-comms",
                                        "This one can upgrade your impulse engines"
                                    ),
                                    function()
                                        local convincing_avenue = false
                                        if
                                            comms_source:getReputationPoints()
                                            >= 25
                                        then
                                            convincing_avenue = true
                                            addCommsReply(
                                                _(
                                                    "ship-comms",
                                                    "Take on crewmember as a favor (25 reputation)?"
                                                ),
                                                function()
                                                    if
                                                        comms_source:getRepairCrewCount()
                                                        > 0
                                                    then
                                                        if
                                                            comms_source:getWeaponStorage(
                                                                "Mine"
                                                            )
                                                            > 0
                                                        then
                                                            if
                                                                comms_source:takeReputationPoints(
                                                                    25
                                                                )
                                                            then
                                                                comms_target.saboteur_process_complete =
                                                                    true
                                                                comms_source:setRepairCrewCount(
                                                                    comms_source:getRepairCrewCount()
                                                                        - 1
                                                                )
                                                                comms_source:setWeaponStorage(
                                                                    "Mine",
                                                                    comms_source:getWeaponStorage(
                                                                        "Mine"
                                                                    )
                                                                        - 1
                                                                )
                                                                comms_source.saboteur_deployed =
                                                                    comms_target:getCallSign()
                                                                comms_source.saboteur_ship =
                                                                    comms_target
                                                                comms_target:setImpulseMaxSpeed(
                                                                    comms_target:getImpulseMaxSpeed()
                                                                        * 2
                                                                )
                                                                if
                                                                    saboteur_freighters
                                                                    == nil
                                                                then
                                                                    saboteur_freighters =
                                                                        {}
                                                                end
                                                                table.insert(
                                                                    saboteur_freighters,
                                                                    comms_target
                                                                )
                                                                setCommsMessage(
                                                                    _(
                                                                        "ship-comms",
                                                                        "We have taken on your repair crewmember as a new crewmember on our ship. The increased impulse speed is greatly appreciated."
                                                                    )
                                                                )
                                                            else
                                                                setCommsMessage(
                                                                    _(
                                                                        "needRep-comms",
                                                                        "Insufficient reputation"
                                                                    )
                                                                )
                                                                comms_target.saboteur_process_complete =
                                                                    true
                                                            end
                                                        else
                                                            setCommsMessage(
                                                                _(
                                                                    "ship-comms",
                                                                    "No mine to send with saboteur"
                                                                )
                                                            )
                                                            comms_target.saboteur_process_complete =
                                                                true
                                                        end
                                                    else
                                                        setCommsMessage(
                                                            _(
                                                                "ship-comms",
                                                                "No repair crew to send"
                                                            )
                                                        )
                                                        comms_target.saboteur_process_complete =
                                                            true
                                                    end
                                                    addCommsReply(
                                                        _("Back"),
                                                        commsShip
                                                    )
                                                end
                                            )
                                        end
                                        local player_good_count = 0
                                        if comms_source.goods ~= nil then
                                            for good, goodQuantity in
                                                pairs(comms_source.goods)
                                            do
                                                player_good_count = player_good_count
                                                    + goodQuantity
                                            end
                                        end
                                        if player_good_count > 0 then
                                            convincing_avenue = true
                                            for good, goodQuantity in
                                                pairs(comms_source.goods)
                                            do
                                                if goodQuantity > 0 then
                                                    addCommsReply(
                                                        string.format(
                                                            _(
                                                                "ship-comms",
                                                                "Offer %s to take on crewmember"
                                                            ),
                                                            good
                                                        ),
                                                        function()
                                                            if
                                                                comms_source:getRepairCrewCount()
                                                                > 0
                                                            then
                                                                if
                                                                    comms_source:getWeaponStorage(
                                                                        "Mine"
                                                                    )
                                                                    > 0
                                                                then
                                                                    comms_source.goods[good] = comms_source.goods[good]
                                                                        - 1
                                                                    comms_target.saboteur_process_complete =
                                                                        true
                                                                    comms_source:setRepairCrewCount(
                                                                        comms_source:getRepairCrewCount()
                                                                            - 1
                                                                    )
                                                                    comms_source:setWeaponStorage(
                                                                        "Mine",
                                                                        comms_source:getWeaponStorage(
                                                                            "Mine"
                                                                        )
                                                                            - 1
                                                                    )
                                                                    comms_source.saboteur_deployed =
                                                                        comms_target:getCallSign()
                                                                    comms_source.saboteur_ship =
                                                                        comms_target
                                                                    comms_target:setImpulseMaxSpeed(
                                                                        comms_target:getImpulseMaxSpeed()
                                                                            * 2
                                                                    )
                                                                    if
                                                                        saboteur_freighters
                                                                        == nil
                                                                    then
                                                                        saboteur_freighters =
                                                                            {}
                                                                    end
                                                                    table.insert(
                                                                        saboteur_freighters,
                                                                        comms_target
                                                                    )
                                                                    setCommsMessage(
                                                                        string.format(
                                                                            _(
                                                                                "ship-comms",
                                                                                "Thanks for the %s. We have taken on your repair crewmember as a new crewmember on our ship. The increased impulse speed is greatly appreciated."
                                                                            ),
                                                                            good
                                                                        )
                                                                    )
                                                                else
                                                                    setCommsMessage(
                                                                        _(
                                                                            "ship-comms",
                                                                            "No mine to send with saboteur"
                                                                        )
                                                                    )
                                                                    comms_target.saboteur_process_complete =
                                                                        true
                                                                end
                                                            else
                                                                setCommsMessage(
                                                                    _(
                                                                        "ship-comms",
                                                                        "No repair crew to send"
                                                                    )
                                                                )
                                                                comms_target.saboteur_process_complete =
                                                                    true
                                                            end
                                                            addCommsReply(
                                                                _("Back"),
                                                                commsShip
                                                            )
                                                        end
                                                    )
                                                end
                                            end
                                        end
                                        if convincing_avenue then
                                            setCommsMessage(
                                                _(
                                                    "ship-comms",
                                                    "I talked to the captain, but he still needs convincing."
                                                )
                                            )
                                        else
                                            setCommsMessage(
                                                string.format(
                                                    _(
                                                        "ship-comms",
                                                        "Not interested.\n\n[Outpost Leadership] We were monitoring your exchange with %s. Next time, try convincing the captain using 25 or more reputation or with some cargo aboard your ship."
                                                    ),
                                                    comms_target:getCallSign()
                                                )
                                            )
                                            comms_target.saboteur_process_complete =
                                                true
                                        end
                                        addCommsReply(_("Back"), commsShip)
                                    end
                                )
                                addCommsReply(
                                    _(
                                        "ship-comms",
                                        "This one wants civilian experience"
                                    ),
                                    function()
                                        local convincing_avenue = false
                                        local saboteur_reputation =
                                            math.random(40, 90)
                                        if
                                            comms_source:getReputationPoints()
                                            >= saboteur_reputation
                                        then
                                            convincing_avenue = true
                                            addCommsReply(
                                                string.format(
                                                    _(
                                                        "ship-comms",
                                                        "Take on crewmember as a favor (%i reputation)?"
                                                    ),
                                                    saboteur_reputation
                                                ),
                                                function()
                                                    if
                                                        comms_source:getRepairCrewCount()
                                                        > 0
                                                    then
                                                        if
                                                            comms_source:getWeaponStorage(
                                                                "Mine"
                                                            )
                                                            > 0
                                                        then
                                                            if
                                                                comms_source:takeReputationPoints(
                                                                    saboteur_reputation
                                                                )
                                                            then
                                                                comms_target.saboteur_process_complete =
                                                                    true
                                                                comms_source:setRepairCrewCount(
                                                                    comms_source:getRepairCrewCount()
                                                                        - 1
                                                                )
                                                                comms_source:setWeaponStorage(
                                                                    "Mine",
                                                                    comms_source:getWeaponStorage(
                                                                        "Mine"
                                                                    )
                                                                        - 1
                                                                )
                                                                comms_source.saboteur_deployed =
                                                                    comms_target:getCallSign()
                                                                comms_source.saboteur_ship =
                                                                    comms_target
                                                                if
                                                                    saboteur_freighters
                                                                    == nil
                                                                then
                                                                    saboteur_freighters =
                                                                        {}
                                                                end
                                                                table.insert(
                                                                    saboteur_freighters,
                                                                    comms_target
                                                                )
                                                                setCommsMessage(
                                                                    _(
                                                                        "ship-comms",
                                                                        "We have taken on your repair crewmember as a new crewmember on our ship."
                                                                    )
                                                                )
                                                            else
                                                                setCommsMessage(
                                                                    _(
                                                                        "needRep-comms",
                                                                        "Insufficient reputation"
                                                                    )
                                                                )
                                                                comms_target.saboteur_process_complete =
                                                                    true
                                                            end
                                                        else
                                                            setCommsMessage(
                                                                _(
                                                                    "ship-comms",
                                                                    "No mine to send with saboteur"
                                                                )
                                                            )
                                                            comms_target.saboteur_process_complete =
                                                                true
                                                        end
                                                    else
                                                        setCommsMessage(
                                                            _(
                                                                "ship-comms",
                                                                "No repair crew to send"
                                                            )
                                                        )
                                                        comms_target.saboteur_process_complete =
                                                            true
                                                    end
                                                    addCommsReply(
                                                        _("Back"),
                                                        commsShip
                                                    )
                                                end
                                            )
                                        end
                                        local player_good_count = 0
                                        if comms_source.goods ~= nil then
                                            for good, goodQuantity in
                                                pairs(comms_source.goods)
                                            do
                                                player_good_count = player_good_count
                                                    + goodQuantity
                                            end
                                        end
                                        if player_good_count > 0 then
                                            convincing_avenue = true
                                            for good, goodQuantity in
                                                pairs(comms_source.goods)
                                            do
                                                if goodQuantity > 0 then
                                                    addCommsReply(
                                                        string.format(
                                                            _(
                                                                "ship-comms",
                                                                "Offer %s to take on crewmember"
                                                            ),
                                                            good
                                                        ),
                                                        function()
                                                            if
                                                                comms_source:getRepairCrewCount()
                                                                > 0
                                                            then
                                                                if
                                                                    comms_source:getWeaponStorage(
                                                                        "Mine"
                                                                    )
                                                                    > 0
                                                                then
                                                                    comms_source.goods[good] = comms_source.goods[good]
                                                                        - 1
                                                                    comms_target.saboteur_process_complete =
                                                                        true
                                                                    comms_source:setRepairCrewCount(
                                                                        comms_source:getRepairCrewCount()
                                                                            - 1
                                                                    )
                                                                    comms_source:setWeaponStorage(
                                                                        "Mine",
                                                                        comms_source:getWeaponStorage(
                                                                            "Mine"
                                                                        )
                                                                            - 1
                                                                    )
                                                                    comms_source.saboteur_deployed =
                                                                        comms_target:getCallSign()
                                                                    comms_source.saboteur_ship =
                                                                        comms_target
                                                                    if
                                                                        saboteur_freighters
                                                                        == nil
                                                                    then
                                                                        saboteur_freighters =
                                                                            {}
                                                                    end
                                                                    table.insert(
                                                                        saboteur_freighters,
                                                                        comms_target
                                                                    )
                                                                    setCommsMessage(
                                                                        string.format(
                                                                            _(
                                                                                "ship-comms",
                                                                                "Thanks for the %s. We have taken on your repair crewmember as a new crewmember on our ship."
                                                                            ),
                                                                            good
                                                                        )
                                                                    )
                                                                else
                                                                    setCommsMessage(
                                                                        _(
                                                                            "ship-comms",
                                                                            "No mine to send with saboteur"
                                                                        )
                                                                    )
                                                                    comms_target.saboteur_process_complete =
                                                                        true
                                                                end
                                                            else
                                                                setCommsMessage(
                                                                    _(
                                                                        "ship-comms",
                                                                        "No repair crew to send"
                                                                    )
                                                                )
                                                                comms_target.saboteur_process_complete =
                                                                    true
                                                            end
                                                            addCommsReply(
                                                                _("Back"),
                                                                commsShip
                                                            )
                                                        end
                                                    )
                                                end
                                            end
                                        end
                                        if convincing_avenue then
                                            setCommsMessage(
                                                _(
                                                    "ship-comms",
                                                    "I talked to the captain, but he still needs convincing."
                                                )
                                            )
                                        else
                                            setCommsMessage(
                                                string.format(
                                                    _(
                                                        "ship-comms",
                                                        "Not interested.\n\n[Outpost Leadership] We were monitoring your exchange with %s. Next time, try convincing the captain using 40 to 90 reputation or with some cargo aboard your ship."
                                                    ),
                                                    comms_target:getCallSign()
                                                )
                                            )
                                            comms_target.saboteur_process_complete =
                                                true
                                        end
                                        addCommsReply(_("Back"), commsShip)
                                    end
                                )
                                addCommsReply(_("Back"), commsShip)
                            end
                        )
                    end
                end
            end
        end
    end
end
ship_profile = {
    enemy = enemyComms,
    main_menu = commsShip,
    before_trade = function()
        deploySaboteur()
    end,
}
----------------------
-- Utility functions --
-----------------------
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
        addGMMessage(
            _("msgGM", "Empty Template pool: fix excludes or other criteria")
        )
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
        for _, enemy in ipairs(enemyList) do
            local dex, dey = vectorFromAngle(spawn_angle, spawn_distance * 1000)
            enemy
                :setPosition(xOrigin + dex, yOrigin + dey)
                :setRotation(spawn_angle + 180)
            spawn_angle = spawn_angle + circle_increment
        end
    end
    return enemyList, original_enemy_strength
end

----------------------------------------------------------------------------------------
--  Additional player ships with modifications from the original template parameters  --
----------------------------------------------------------------------------------------
function createPlayerShipMixer()
    playerAmalgam = PlayerSpaceship()
        :setTemplate(ST.ATLANTIS)
        :setFaction("Human Navy")
        :setCallSign("Mixer")
        :setTypeName("Amalgam")
        :setRepairCrewCount(5) --more repair crew (vs 3)
    playerAmalgam.max_jump_range = 40000 --shorter (vs 50)
    playerAmalgam.min_jump_range = 4000 --shorter (vs 5)
    playerAmalgam
        :setJumpDriveRange(
            playerAmalgam.min_jump_range,
            playerAmalgam.max_jump_range
        )
        :setJumpDriveCharge(playerAmalgam.max_jump_range)
        :setImpulseMaxSpeed(80) --slower (vs 90)
        :setRotationMaxSpeed(8) --slower (vs 10)
        :setShieldsMax(150, 150) --weaker shields (vs 200)
        :setShields(150, 150)
        :setBeamWeapon(0, 90, -20, 1200, 6, 8) --narrower (vs 100), shorter (vs 1500)
        :setBeamWeapon(1, 90, 20, 1200, 6, 8) --narrower (vs 100), shorter (vs 1500)
        :setBeamWeapon(2, 10, -60, 1000, 4, 6) --additional beam
        :setBeamWeapon(3, 10, 60, 1000, 4, 6) --additional beam
        :setBeamWeaponTurret(2, 60, -60, 0.6)
        :setBeamWeaponTurret(3, 60, 60, 0.6)
        :setWeaponTubeCount(4) --2 fewer broadside, 1 extra mine (vs 5)
        :setWeaponTubeDirection(1, 90) --mine tube points right (vs left)
        :setWeaponTubeDirection(2, 180) --mine tube points back (vs right)
        :setWeaponTubeDirection(3, 180) --mine tube points back (vs right)
        :setWeaponTubeExclusiveFor(0, "Homing") --homing only (vs any)
        :setWeaponTubeExclusiveFor(1, "Homing") --homing only (vs any)
        :setWeaponTubeExclusiveFor(2, "Mine") --mine only (vs any)
        :setWeaponTubeExclusiveFor(3, "Mine") --mine only (vs any)
        :setTubeLoadTime(2, 16) --rear tube slower (vs 8)
        :setTubeLoadTime(3, 16) --rear tube slower (vs 8)
        :setTubeSize(0, "large") --left tube large (vs normal)
        :setTubeSize(1, "large") --right tube large (vs normal)
        :setWeaponStorageMax("Homing", 16) --more (vs 12)
        :setWeaponStorage("Homing", 16)
        :setWeaponStorageMax("Nuke", 0) --less (vs 4)
        :setWeaponStorage("Nuke", 0)
        :setWeaponStorageMax("Mine", 10) --more (vs 8)
        :setWeaponStorage("Mine", 10)
        :setWeaponStorageMax("EMP", 0) --less (vs 6)
        :setWeaponStorage("EMP", 0)
        :setWeaponStorageMax("HVLI", 0) --less (vs 20)
        :setWeaponStorage("HVLI", 0)
    return playerAmalgam
end
function createPlayerShipFlipper()
    playerFlipper = PlayerSpaceship()
        :setTemplate(ST.AVALANCHE)
        :setFaction("Human Navy")
        :setCallSign("Flipper")
        :setTypeName("Midian")
        :setRadarTrace("cruiser.png") --different radar trace
        :setWarpSpeed(320)
        :setBeamWeapon(0, 50, -20, 1000, 6, 4) --beams (vs none)
        :setBeamWeapon(1, 50, 20, 1000, 6, 4)
        :setBeamWeapon(2, 10, 180, 1000, 6, 2)
        :setBeamWeaponTurret(2, 220, 180, 0.3)
        :setWeaponTubeCount(5) --fewer (vs 7)
        :setWeaponTubeDirection(0, -2) --angled (vs front)
        :setWeaponTubeDirection(1, 2) --angled (vs front)
        :setWeaponTubeDirection(2, -90) --left (vs right)
        :setWeaponTubeDirection(4, 180) --rear (vs left)
        :setTubeSize(0, "small") --small vs medium
        :setTubeSize(1, "small") --small vs medium
        :setWeaponTubeExclusiveFor(0, "Homing") --homing only
        :setWeaponTubeExclusiveFor(1, "Homing") --homing only
        :setWeaponTubeExclusiveFor(2, "HVLI")
        :setWeaponTubeExclusiveFor(3, "HVLI")
        :setWeaponTubeExclusiveFor(4, "Mine")
        :weaponTubeAllowMissle(2, "EMP")
        :weaponTubeAllowMissle(3, "EMP")
        :weaponTubeAllowMissle(2, "Nuke")
        :weaponTubeAllowMissle(3, "Nuke")
        :setTubeLoadTime(2, 12)
        :setTubeLoadTime(3, 12)
        :setTubeLoadTime(4, 15)
        :setWeaponStorageMax("Homing", 16) --less (vs 30)
        :setWeaponStorage("Homing", 16)
        :setWeaponStorageMax("Nuke", 2) --less (vs 8)
        :setWeaponStorage("Nuke", 2)
        :setWeaponStorageMax("EMP", 5) --less (vs 10)
        :setWeaponStorage("EMP", 5)
        :setWeaponStorageMax("Mine", 5) --less (vs 12)
        :setWeaponStorage("Mine", 5)
        :setWeaponStorageMax("HVLI", 16) --more (vs 0)
        :setWeaponStorage("HVLI", 16)
    playerFlipper.smallHomingOnly = true
    return playerFlipper
end
function createPlayerShipInk()
    playerInk = PlayerSpaceship()
        :setTemplate(ST.PIRANHA)
        :setFaction("Human Navy")
        :setCallSign("Ink")
        :setTypeName("Squid")
        :setRepairCrewCount(5) --more repair crew (vs 2)
        :setShieldsMax(100, 100) --stronger shields (vs 70, 70)
        :setShields(100, 100)
        :setHullMax(130) --stronger (vs 120)
        :setHull(130)
    playerInk.max_jump_range = 20000 --shorter than typical (vs 50)
    playerInk.min_jump_range = 2000 --shorter than typical (vs 5)
    playerInk
        :setJumpDriveRange(
            playerInk.min_jump_range,
            playerInk.max_jump_range
        )
        :setJumpDriveCharge(playerInk.max_jump_range)
        :setBeamWeapon(0, 10, 0, 1000, 4, 4) --one beam (vs 0)
        :setBeamWeaponTurret(0, 80, 0, 1) --slow turret
        :setWeaponTubeDirection(0, 0) --forward facing (vs left)
        :setWeaponTubeDirection(3, 0) --forward facing (vs right)
        :setTubeLoadTime(0, 12) --slower (vs 8)
        :setTubeLoadTime(3, 12) --slower (vs 8)
        :setWeaponTubeExclusiveFor(2, "Homing") --homing only (vs HVLI)
        :setWeaponTubeExclusiveFor(5, "Homing") --homing only (vs HVLI)
        :setTubeLoadTime(2, 10) --slower (vs 8)
        :setTubeLoadTime(5, 10) --slower (vs 8)
        :setTubeLoadTime(6, 15) --slower (vs 8)
        :setTubeLoadTime(7, 15) --slower (vs 8)
        :setWeaponTubeExclusiveFor(0, "HVLI") --HVLI only (vs Homing + HVLI)
        :setWeaponTubeExclusiveFor(3, "HVLI") --HVLI only (vs Homing + HVLI)
        :weaponTubeDisallowMissle(1, "Mine") --no sideways mines
        :weaponTubeDisallowMissle(4, "Mine") --no sideways mines
        :setWeaponStorageMax("HVLI", 10) --fewer HVLI (vs 20)
        :setWeaponStorage("HVLI", 10)
        :setWeaponStorageMax("Homing", 10) --fewer Homing (vs 12)
        :setWeaponStorage("Homing", 10)
        :setWeaponStorageMax("Mine", 6) --fewer mines (vs 8)
        :setWeaponStorage("Mine", 6)
        :setWeaponStorageMax("EMP", 4) --more EMPs (vs 0)
        :setWeaponStorage("EMP", 4)
        :setWeaponStorageMax("Nuke", 4) --fewer Nukes (vs 6)
        :setWeaponStorage("Nuke", 4)
        :setLongRangeRadarRange(25000) --shorter long range sensors (vs 30000)
    playerInk.normal_long_range_radar = 25000
    return playerInk
end
function createPlayerShipClaw()
    playerRaven = PlayerSpaceship()
        :setTemplate(ST.VINDICATOR)
        :setFaction("Human Navy")
        :setCallSign("Claw")
        :setTypeName("Raven")
        :setJumpDrive(false)
        :setWarpDrive(true) --warp drive (vs jump)
        :setWarpSpeed(300)
        :setShieldsMax(100, 100) --stronger shields (vs 80, 80)
        :setShields(100, 100)
        :setHullMax(150) --weaker hull (vs 200)
        :setHull(150)
        :setBeamWeapon(0, 10, -90, 900, 6, 10) --left (vs front) shorter (vs 1000)
        :setBeamWeapon(1, 10, 90, 900, 6, 10) --right (vs front) shorter (vs 1000)
        :setBeamWeaponTurret(0, 90, -90, 1)
        :setBeamWeaponTurret(1, 90, 90, 1)
        :setWeaponTubeCount(6) --more (vs 3)
        :setWeaponTubeDirection(0, -30) --more angled (vs -5)
        :setWeaponTubeDirection(1, 30) --more angled (vs 5)
        :setTubeSize(0, "small") --small (vs medium)
        :setTubeSize(1, "small") --small (vs medium)
        :setWeaponTubeExclusiveFor(0, "Nuke") --Nuke only (vs all but mine)
        :setWeaponTubeExclusiveFor(1, "Nuke") --Nuke only (vs all but mine)
        :setWeaponTubeDirection(2, -60)
        :setWeaponTubeDirection(3, 60)
        :setTubeSize(2, "small")
        :setTubeSize(3, "small")
        :setWeaponTubeExclusiveFor(2, "EMP")
        :setWeaponTubeExclusiveFor(3, "EMP")
        :setTubeLoadTime(4, 12) --slower (vs 8)
        :setTubeSize(4, "large")
        :setWeaponTubeExclusiveFor(4, "Homing")
        :setWeaponTubeDirection(5, 180)
        :setTubeLoadTime(5, 10) --slower (vs 8)
        :setWeaponTubeExclusiveFor(5, "Mine")
        :setWeaponStorageMax("Homing", 4) --less (vs 12)
        :setWeaponStorage("Homing", 4)
        :setWeaponStorageMax("EMP", 4) --less (vs 6)
        :setWeaponStorage("EMP", 4)
        :setWeaponStorageMax("Mine", 4) --less (vs 8)
        :setWeaponStorage("Mine", 4)
    return playerRaven
end
------------------------
-- Update functions  --
------------------------
-- Update loop related functions
function continuousSpawn(delta)
    if #spawn_source_pool < 1 then
        for _, station in ipairs(circle_stations) do
            if station ~= nil and station:isValid() then
                table.insert(spawn_source_pool, station)
            end
        end
        spawn_interval_index = spawn_interval_index + 1
        if spawn_interval_index > #spawn_intervals then
            spawn_interval_index = 1
        end
        spawn_interval = spawn_intervals[spawn_interval_index].pace
        spawn_respite_interval = spawn_intervals[spawn_interval_index].respite
        spawn_timer = spawn_interval + random(1, spawn_variance)
        if continuous_spawn_diagnostic then
            print(
                "spawn timer:",
                spawn_timer,
                "pace:",
                spawn_interval,
                "respite:",
                spawn_respite_interval
            )
        end
    end
    spawn_timer = spawn_timer - delta
    if spawn_timer < 0 then
        local origin_station = tableRemoveRandom(spawn_source_pool)
        if origin_station ~= nil and origin_station:isValid() then
            if #target_station_pool < 1 then
                for _, station in ipairs(inner_circle) do
                    if station ~= nil and station:isValid() then
                        table.insert(target_station_pool, station)
                    end
                end
                if continuous_spawn_diagnostic then
                    print(
                        "Inner circle target station pool rebuilt. Size:",
                        #target_station_pool
                    )
                end
            end
            local spawn_target = tableRemoveRandom(target_station_pool)
            if spawn_target == nil or not spawn_target:isValid() then
                local player_pool = getActivePlayerShips()
                spawn_target = tableRemoveRandom(player_pool)
            end
            if spawn_target ~= nil and spawn_target:isValid() then
                local ox, oy = origin_station:getPosition()
                local fleet = {}
                local fleet_strength = 0
                local ship_removed = false
                repeat
                    ship_removed = false
                    for i, ship in ipairs(cpu_ships) do
                        if ship == nil then
                            cpu_ships[i] = cpu_ships[#cpu_ships]
                            cpu_ships[#cpu_ships] = nil
                            ship_removed = true
                            break
                        else
                            if not ship:isValid() then
                                cpu_ships[i] = cpu_ships[#cpu_ships]
                                cpu_ships[#cpu_ships] = nil
                                ship_removed = true
                                break
                            end
                        end
                    end
                until not ship_removed
                local active_enemy_strength = 0
                local active_friendly_strength = 0
                local active_neutral_strength = 0
                for i, ship in ipairs(cpu_ships) do
                    local p = getPlayerShip(-1)
                    if p ~= nil then
                        local current_ship_template = ship:getTypeName()
                        if ship:isEnemy(p) then
                            if ship_template[current_ship_template] == nil then
                                print(
                                    "Missing enemy ship from strength evaluation. Ship template list does not contain:",
                                    current_ship_template
                                )
                            else
                                active_enemy_strength = active_enemy_strength
                                    + ship_template[current_ship_template].strength
                            end
                        elseif ship:isFriendly(p) then
                            if ship_template[current_ship_template] == nil then
                                print(
                                    "Missing friendly ship from strength evaluation. Ship template list does not contain:",
                                    current_ship_template
                                )
                            else
                                active_friendly_strength = active_friendly_strength
                                    + ship_template[current_ship_template].strength
                            end
                        else
                            if ship_template[current_ship_template] == nil then
                                print(
                                    "Missing neutral ship from strength evaluation. Ship template list does not contain:",
                                    current_ship_template
                                )
                            else
                                active_neutral_strength = active_neutral_strength
                                    + ship_template[current_ship_template].strength
                            end
                        end
                    else
                        print("no player ship")
                    end
                end
                local balance_factor = 0
                if
                    (active_friendly_strength + active_neutral_strength)
                    >= active_enemy_strength
                then
                    if
                        (active_friendly_strength + active_neutral_strength) > 0
                    then
                        balance_factor = 1
                            - (
                                active_enemy_strength
                                / (
                                    active_friendly_strength
                                    + active_neutral_strength
                                )
                            )
                    end
                else
                    if active_enemy_strength > 0 then
                        balance_factor = (
                            active_friendly_strength + active_neutral_strength
                        ) / active_enemy_strength
                    end
                end
                local pace_factor = getScenarioTime() / danger_pace
                local danger_value = 1 + (pace_factor * balance_factor)
                if continuous_spawn_diagnostic then
                    print(
                        "pace factor:",
                        pace_factor,
                        "balance factor:",
                        balance_factor,
                        "Ene:",
                        active_enemy_strength,
                        "Frn:",
                        active_friendly_strength,
                        "Neu:",
                        active_neutral_strength
                    )
                end
                if origin_station:isEnemy(spawn_target) then
                    fleet, fleet_strength = spawnEnemies(
                        ox,
                        oy,
                        danger_value,
                        origin_station:getFaction()
                    )
                    for _, ship in ipairs(fleet) do
                        table.insert(cpu_ships, ship)
                    end
                    if random(1, 100) < 30 then
                        for _, ship in ipairs(fleet) do
                            ship:orderAttack(spawn_target)
                        end
                        if continuous_spawn_diagnostic then
                            print(
                                "Enemy fleet from:",
                                origin_station:getCallSign(),
                                "attacking:",
                                spawn_target:getCallSign(),
                                "danger:",
                                danger_value,
                                "strength:",
                                fleet_strength
                            )
                        end
                    else
                        for _, ship in ipairs(fleet) do
                            local tx, ty = spawn_target:getPosition()
                            ship:orderFlyTowards(tx, ty)
                        end
                        if continuous_spawn_diagnostic then
                            print(
                                "Enemy fleet from:",
                                origin_station:getCallSign(),
                                "flying to:",
                                spawn_target:getCallSign(),
                                "danger:",
                                danger_value,
                                "strength:",
                                fleet_strength
                            )
                        end
                    end
                else
                    if origin_station.help_requested then
                        fleet, fleet_strength = spawnEnemies(
                            ox,
                            oy,
                            danger_value,
                            origin_station:getFaction()
                        )
                        for _, ship in ipairs(fleet) do
                            ship:orderDefendTarget(spawn_target)
                        end
                        if origin_station:isFriendly(spawn_target) then
                            if continuous_spawn_diagnostic then
                                print(
                                    "Friendly fleet from:",
                                    origin_station:getCallSign(),
                                    "defending:",
                                    spawn_target:getCallSign(),
                                    "danger:",
                                    danger_value,
                                    "strength:",
                                    fleet_strength
                                )
                            end
                        else
                            if continuous_spawn_diagnostic then
                                print(
                                    "Neutral fleet from:",
                                    origin_station:getCallSign(),
                                    "defending:",
                                    spawn_target:getCallSign(),
                                    "danger:",
                                    danger_value,
                                    "strength:",
                                    fleet_strength
                                )
                            end
                        end
                    else
                        if continuous_spawn_diagnostic then
                            print(
                                "No neutral/friendly fleet spawned from:",
                                origin_station:getCallSign(),
                                "(not requested)"
                            )
                        end
                    end
                end
            end
        end
        if #spawn_source_pool > 0 then
            spawn_timer = spawn_interval + random(1, spawn_variance)
        else
            spawn_timer = spawn_respite_interval + random(1, spawn_variance)
        end
        if continuous_spawn_diagnostic then
            print("spawn timer:", spawn_timer)
        end
    end
    mainLinearPlot = outpostSurvival
end
function outpostSurvival(delta)
    local outpost_count = 0
    for _, station in ipairs(inner_circle) do
        if station ~= nil and station:isValid() then
            outpost_count = outpost_count + 1
        end
    end
    if outpost_count < 1 then
        local duration_string = getDuration()
        local duration = getScenarioTime()
        local rank = _("msgMainscreen", "Cadet")
        local posthumous_rank = {
            {
                whammy = 0,
                duration = 0.5,
                rank = _("msgMainscreen", "Acting Ensign"),
            },
            { whammy = 1, duration = 1.5, rank = _("msgMainscreen", "Ensign") },
            {
                whammy = 1,
                duration = 1.0,
                rank = _("msgMainscreen", "Acting Ensign"),
            },
            {
                whammy = 2,
                duration = 2.5,
                rank = _("msgMainscreen", "Lieutenant"),
            },
            { whammy = 2, duration = 2.0, rank = _("msgMainscreen", "Ensign") },
            {
                whammy = 2,
                duration = 1.5,
                rank = _("msgMainscreen", "Acting Ensign"),
            },
            {
                whammy = 3,
                duration = 3.5,
                rank = _("msgMainscreen", "Commander"),
            },
            {
                whammy = 3,
                duration = 3.0,
                rank = _("msgMainscreen", "Lieutenant"),
            },
            { whammy = 3, duration = 2.5, rank = _("msgMainscreen", "Ensign") },
            {
                whammy = 3,
                duration = 2.0,
                rank = _("msgMainscreen", "Acting Ensign"),
            },
            {
                whammy = 4,
                duration = 4.5,
                rank = _("msgMainscreen", "Captain"),
            },
            {
                whammy = 4,
                duration = 4.0,
                rank = _("msgMainscreen", "Commander"),
            },
            {
                whammy = 4,
                duration = 3.5,
                rank = _("msgMainscreen", "Lieutenant"),
            },
            { whammy = 4, duration = 3.0, rank = _("msgMainscreen", "Ensign") },
            {
                whammy = 4,
                duration = 2.5,
                rank = _("msgMainscreen", "Acting Ensign"),
            },
            {
                whammy = 5,
                duration = 5.5,
                rank = _("msgMainscreen", "Admiral"),
            },
            {
                whammy = 5,
                duration = 5.0,
                rank = _("msgMainscreen", "Captain"),
            },
            {
                whammy = 5,
                duration = 4.5,
                rank = _("msgMainscreen", "Commander"),
            },
            {
                whammy = 5,
                duration = 4.0,
                rank = _("msgMainscreen", "Lieutenant"),
            },
            { whammy = 5, duration = 3.5, rank = _("msgMainscreen", "Ensign") },
            {
                whammy = 5,
                duration = 3.0,
                rank = _("msgMainscreen", "Acting Ensign"),
            },
            {
                whammy = 6,
                duration = 6.5,
                rank = _("msgMainscreen", "Admiral"),
            },
            {
                whammy = 6,
                duration = 6.0,
                rank = _("msgMainscreen", "Captain"),
            },
            {
                whammy = 6,
                duration = 5.5,
                rank = _("msgMainscreen", "Commander"),
            },
            {
                whammy = 6,
                duration = 5.0,
                rank = _("msgMainscreen", "Lieutenant"),
            },
            { whammy = 6, duration = 4.5, rank = _("msgMainscreen", "Ensign") },
            {
                whammy = 6,
                duration = 4.0,
                rank = _("msgMainscreen", "Acting Ensign"),
            },
            {
                whammy = 7,
                duration = 7.5,
                rank = _("msgMainscreen", "Admiral"),
            },
            {
                whammy = 7,
                duration = 7.0,
                rank = _("msgMainscreen", "Captain"),
            },
            {
                whammy = 7,
                duration = 6.5,
                rank = _("msgMainscreen", "Commander"),
            },
            {
                whammy = 7,
                duration = 6.0,
                rank = _("msgMainscreen", "Lieutenant"),
            },
            { whammy = 7, duration = 5.5, rank = _("msgMainscreen", "Ensign") },
            {
                whammy = 7,
                duration = 5.0,
                rank = _("msgMainscreen", "Acting Ensign"),
            },
            {
                whammy = 8,
                duration = 8.5,
                rank = _("msgMainscreen", "Admiral"),
            },
            {
                whammy = 8,
                duration = 8.0,
                rank = _("msgMainscreen", "Captain"),
            },
            {
                whammy = 8,
                duration = 7.5,
                rank = _("msgMainscreen", "Commander"),
            },
            {
                whammy = 8,
                duration = 7.0,
                rank = _("msgMainscreen", "Lieutenant"),
            },
            { whammy = 8, duration = 6.5, rank = _("msgMainscreen", "Ensign") },
            {
                whammy = 8,
                duration = 6.0,
                rank = _("msgMainscreen", "Acting Ensign"),
            },
            {
                whammy = 9,
                duration = 9.5,
                rank = _("msgMainscreen", "Admiral"),
            },
            {
                whammy = 9,
                duration = 9.0,
                rank = _("msgMainscreen", "Captain"),
            },
            {
                whammy = 9,
                duration = 8.5,
                rank = _("msgMainscreen", "Commander"),
            },
            {
                whammy = 9,
                duration = 8.0,
                rank = _("msgMainscreen", "Lieutenant"),
            },
            { whammy = 9, duration = 7.5, rank = _("msgMainscreen", "Ensign") },
            {
                whammy = 9,
                duration = 7.0,
                rank = _("msgMainscreen", "Acting Ensign"),
            },
        }
        for i, pr in ipairs(posthumous_rank) do
            if total_whammies == pr.whammy then
                if duration > (60 * 60 * pr.duration) then
                    rank = pr.rank
                    break
                end
            end
        end
        local reason = string.format(
            _(
                "msgMainscreen",
                "All outpost stations destroyed.\nOutpost survived for %s. Posthumous rank: %s"
            ),
            duration_string,
            rank
        )
        globalMessage(reason)
        setBanner(reason)
        victory("Exuari")
    end
    mainLinearPlot = continuousSpawn
end
function sabotageCheck(p)
    for index, ship in ipairs(saboteur_freighters) do
        if ship:isValid() then
            if ship.sabotage_target == nil then
                if ship.sabotage_success == nil then
                    local docked_station = ship:getDockedWith()
                    if docked_station ~= nil then
                        local failed_station = false
                        if ship.failed_stations ~= nil then
                            for _, f_station in ipairs(ship.failed_stations) do
                                if docked_station == f_station then
                                    failed_station = true
                                    break
                                end
                            end
                        end
                        if not failed_station then
                            for _, station in ipairs(circle_stations) do
                                if station == docked_station then
                                    if station:isEnemy(p) then
                                        local success_roll = random(1, 100)
                                        if success_roll < 50 then
                                            ship.sabotage_target = station
                                            ship.explode_time = getScenarioTime()
                                                + 180
                                        elseif success_roll > 80 then
                                            local ex, ey = ship:getPosition()
                                            ExplosionEffect()
                                                :setPosition(ex, ey)
                                                :setSize(3000)
                                            saboteur_freighters[index] =
                                                saboteur_freighters[#saboteur_freighters]
                                            saboteur_freighters[#saboteur_freighters] =
                                                nil
                                            ship:destroy()
                                        else
                                            if ship.failed_stations == nil then
                                                ship.failed_stations = {}
                                            end
                                            table.insert(
                                                ship.failed_stations,
                                                station
                                            )
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            else
                if getScenarioTime() > ship.explode_time then
                    if
                        ship.sabotage_target ~= nil
                        and ship.sabotage_target:isValid()
                    then
                        local ex, ey = ship.sabotage_target:getPosition()
                        ExplosionEffect():setPosition(ex, ey):setSize(3000)
                        ship.sabotage_success =
                            ship.sabotage_target:getCallSign()
                        ship.sabotage_target:destroy()
                    end
                    ship.sabotage_target = nil
                    ship.explode_time = nil
                end
            end
        else
            saboteur_freighters[index] =
                saboteur_freighters[#saboteur_freighters]
            saboteur_freighters[#saboteur_freighters] = nil
        end
    end
end
function updatePlayerProximityScan(p)
    local obj_list = p:getObjectsInRange(p.prox_scan * 1000)
    if obj_list ~= nil and #obj_list > 0 then
        for _, obj in ipairs(obj_list) do
            if
                obj:isValid()
                and isObjectType(obj, "CpuShip")
                and not obj:isFullyScannedBy(p)
            then
                obj:setScanState("simplescan")
            end
        end
    end
end
function whammyTime(p)
    local p_x, p_y = p:getPosition()
    local objs = getObjectsInRadius(p_x, p_y, 10000)
    local nebulae = {}
    for i, obj in ipairs(objs) do
        if isObjectType(obj, "Nebula") then
            table.insert(nebulae, obj)
        end
    end
    if #nebulae > 0 then
        local neb = tableRemoveRandom(nebulae)
        local neb_x, neb_y = neb:getPosition()
        local attack_angle = angleFromVectorNorth(p_x, p_y, neb_x, neb_y)
        local base_distance = distance(neb, p)
        local poa_x, poa_y = vectorFromAngle(attack_angle, 4000)
        poa_x = poa_x + neb_x
        poa_y = poa_y + neb_y
        WarpJammer()
            :setPosition(poa_x, poa_y)
            :setRange(math.max(4000, base_distance * 2))
            :setFaction("Exuari")
        local fleet_prefix = generateCallSignPrefix()
        local lead_ship = starhammerV("Exuari")
        lead_ship
            :setPosition(poa_x, poa_y)
            :setHeading(attack_angle)
            :orderFlyTowards(p_x, p_y)
            :setCallSign(generateCallSign(fleet_prefix))
        lead_ship.formation_ships = {}
        local forward_formation = {
            { angle = 10, dist = 2500 },
            { angle = 30, dist = 2700 },
            { angle = 350, dist = 2500 },
            { angle = 330, dist = 2700 },
        }
        for _, form in ipairs(forward_formation) do
            local ship =
                ship_template[ST.ADDER_MK9].create("Exuari", "Adder MK9")
            local form_x, form_y =
                vectorFromAngleNorth(attack_angle + form.angle, form.dist)
            local form_prime_x, form_prime_y =
                vectorFromAngle(form.angle, form.dist)
            ship:setPosition(poa_x + form_x, poa_y + form_y)
                :setHeading(attack_angle)
                :orderFlyFormation(lead_ship, form_prime_x, form_prime_y)
                :setCallSign(generateCallSign(fleet_prefix))
            table.insert(lead_ship.formation_ships, ship)
        end
        local rear_formation = {
            { angle = 120, dist = 2500 },
            { angle = 240, dist = 2500 },
            { angle = 180, dist = 2500 },
        }
        for _, form in ipairs(rear_formation) do
            local ship = ship_template["Maniapak"].create("Exuari", "Maniapak")
            local form_x, form_y =
                vectorFromAngleNorth(attack_angle + form.angle, form.dist)
            local form_prime_x, form_prime_y =
                vectorFromAngle(form.angle, form.dist)
            ship:setPosition(poa_x + form_x, poa_y + form_y)
                :setHeading(attack_angle)
                :orderFlyFormation(lead_ship, form_prime_x, form_prime_y)
                :setCallSign(generateCallSign(fleet_prefix))
            table.insert(lead_ship.formation_ships, ship)
        end
        p:addToShipLog(
            _("shipLog", "Encrypted Exuari communications traffic observed"),
            "Magenta"
        )
        return true
    else
        return false
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
        victory("Exuari")
    end
    if mainGMButtons == mainGMButtonsDuringPause then
        mainGMButtons = mainGMButtonsAfterPause
        mainGMButtons()
    end
    if mainLinearPlot ~= nil then
        mainLinearPlot(delta)
    end
    local s_time = getScenarioTime()
    local whammy_count = 0
    local active_player_count = 0
    for pidx, p in ipairs(getActivePlayerShips()) do
        active_player_count = active_player_count + 1
        if p.pidx == nil then
            p.pidx = pidx
            setPlayers(p)
        end
        updatePlayerLongRangeSensors(p)
        updatePlayerTubeSizeBanner(p)
        if s_time > whammy then
            if whammyTime(p) then
                whammy_count = whammy_count + 1
            end
        end
        if p.prox_scan ~= nil and p.prox_scan > 0 then
            updatePlayerProximityScan(p)
        end
        if p.briefing_time == nil then
            p.briefing_time = getScenarioTime() + 8
        elseif p.briefing_time < getScenarioTime() then
            if p.briefing_sent == nil then
                p.briefing_sent = "done"
                p:addToShipLog(
                    _(
                        "shipLog",
                        "You've been assigned to this outpost for what seems like an eternity. Hostile forces in the area have attacked in wave after wave. Only one defense platform remains. The more powerful ships assigned to protect this outpost have been destroyed. Using salvaged ships, the internal ship maintenance facilities have cobbled together a ship for you. With enough reputation, you can get ship upgrades from friendly and neutral stations. These stations might help defend the outpost if asked, but they've been hit hard, too. Do your best to protect this remote outpost consisting of the following stations:"
                    ),
                    "Magenta"
                )
                for i, station in ipairs(inner_circle) do
                    if station ~= nil and station:isValid() then
                        p:addToShipLog(
                            string.format(
                                _("shipLog", "%s (%s) in sector %s"),
                                station:getCallSign(),
                                station:getFaction(),
                                station:getSectorName()
                            ),
                            "Magenta"
                        )
                    end
                end
            end
        end
        if p.briefing_2_time == nil then
            p.briefing_2_time = getScenarioTime() + 150
        elseif p.briefing_2_time < getScenarioTime() then
            if p.briefing_2_sent == nil then
                p.briefing_2_sent = "done"
                p:addToShipLog(
                    _(
                        "shipLog",
                        "Intelligence operatives tell us they monitored Exuari communication traffic pertinent to the outpost. The Exuari monitor our traffic, too. They know you plan to protect the outpost, so they have some kind of big attack planned. Intelligence is still trying to figure out when. Best estimate they have is 'between 15 minutes and 2 hours.' That's intelligence for you. Keep a sharp eye out."
                    ),
                    "Magenta"
                )
            end
        end
    end
    if whammy_count >= active_player_count then
        whammy = whammy * 0.8 + getScenarioTime() + random(30, 90)
        total_whammies = total_whammies + 1
        -- whammy = 3000 + getScenarioTime()
    end
    if s_time > possible_victory_time then
        local p = getPlayerShip(-1)
        if p ~= nil then
            local aggressive_station = false
            for i, station in ipairs(circle_stations) do
                if
                    station ~= nil
                    and station:isValid()
                    and station:isEnemy(p)
                then
                    aggressive_station = true
                    break
                end
            end
            if not aggressive_station then
                local duration_string = getDuration()
                local rank = getTripleFactorRank()
                local reason = string.format(
                    _(
                        "msgMainscreen",
                        "Aggressive enemy stations destroyed. Remaining stations agree to a truce.\nConflict lasted %s. Rank: %s"
                    ),
                    duration_string,
                    rank
                )
                globalMessage(reason)
                setBanner(reason)
                victory(player_faction)
            end
        end
        if s_time > saboteur_idea_time and saboteur_freighters ~= nil then
            sabotageCheck(p)
        end
    end
    moonCollisionCheck()
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
})
