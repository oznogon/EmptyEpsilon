-- Name: The Omicron Plague
-- Description: A routine patrol mission turns into a desperate attempt to save humanity from an Exuari biological weapon
---
--- Designed to run in a limited time with different terrain each time. Multiple player ships may join
---
--- Duration: approximately 45 minutes depending on the configuration options chosen
---
--- Version 1
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
-- Setting[Rescue]: Number of minutes given to rescue an ailing ensign. Grant more time to make it easier, less time to make it harder.
-- Rescue[15]: Fifteen minutes to help ensign
-- Rescue[20|Default]: Twenty minutes to help ensign
-- Rescue[25]: Twenty-five minutes to help ensign
-- Rescue[30]: Thirty minutes to help ensign
-- Setting[Destroy]: Number of minutes given to destroy designated enemy base. Grant more time to make it easier, less time to make it harder.
-- Destroy[15]: Fifteen minutes to destroy base
-- Destroy[20|Default]: Twenty minutes to destroy base
-- Destroy[25]: Twenty-five minutes to destroy base
-- Destroy[30]: Thirty minutes to destroy base
-- Setting[Reputation]: Amount of reputation to start with
-- Reputation[Unknown|Default]: Zero reputation - nobody knows anything about you
-- Reputation[Nice]: 20 reputation - you've had a small positive influence on the local community
-- Reputation[Hero]: 50 reputation - you helped important people or lots of people
-- Reputation[Major Hero]: 100 reputation - you're well known by nearly everyone as a force for good
-- Reputation[Super Hero]: 200 reputation - everyone knows you and relies on you for help
-- Setting[Unique Ship]: Choose player ship outside of standard player ship list
-- Unique Ship[None|Default]: None: just use standard player ship list on spawn screen
-- Unique Ship[Amalgam]: Based on Atlantis, 4 beams (vs 2), single broadside tube on each side for large homing missiles only, 2 mining tubes, weaker defenses and engines
-- Unique Ship[Midian]: Based on missile cruiser, reduced tubes, missiles and base warp speed to get beam weapons and HVLI
-- Unique Ship[Raven]: Based on Cruiser, stronger shields, weaker hull, broadside beams, tweaked tubes and missiles, low powered warp drive, tweaked sensor ranges
-- Unique Ship[Squid]: Based on Piranha, stronger defenses, added a beam weapon, reduced missile load, large homing missiles, reconfigured tubes, shorter jump and sensor ranges

require("utils.lua")
require("place_station_scenario_utility.lua")
require("generate_call_sign_scenario_utility.lua")
require("cpu_ship_diversification_scenario_utility.lua")
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
local Heading = require("heading_scenario_utility.lua")
local vectorFromAngleNorth = Heading.north(vectorFromAngle)

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

local MissionMenu = require("comms_mission_menu.lua")

local function placeTransport(axis)
    return Environment.placeTransport(axis, randomTransportType)
end
local transportCommerceMaintenance = Transport.transportCommerceMaintenance

local checkContinuum = Continuum.checkContinuum
local resetContinuum = Continuum.resetContinuum
local revertCheck = Continuum.revertCheck
local revertWait = Continuum.revertWait

local sensorJammer = Sensor.sensorJammerExtended
local sensorJammerPickupProcess = Sensor.sensorJammerPickupExtended
local updatePlayerLongRangeSensors = Sensor.updatePlayerLongRangeSensorsExtended


local station_profile
local function stationCommsData()
    return {
        service_cost = {
            probe_launch_repair = math.random(5, 10),
            hack_repair = math.random(5, 10),
            scan_repair = math.random(5, 10),
            combat_maneuver_repair = math.random(5, 10),
            self_destruct_repair = 1,
        },
    }
end
commsStation = StationMenu.entrypoint(function() return station_profile end)
local getFriendStatus = StationCore.getFriendStatus
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
    notifications = {
        { position = "Engineering", suffix = "" },
        { position = "Engineering+", suffix = "Plus" },
    },
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
    scenario_version = "1.0.2"
    ee_version = "2024.12.08"
    print(
        string.format(
            "    ----    Scenario: Omicron    ----    Version %s    ----    Tested with EE version %s    ----",
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
        difficulty = 1
        adverseEffect = 0.995
        coolant_loss = 0.99995
        coolant_gain = 0.001
        starting_rep = 20
        enemy_power = 1
        rescue_time_limit = 20
        destroy_time_limit = 20
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
                rep = 70,
                adverse = 0.999,
                lose_coolant = 0.99999,
                gain_coolant = 0.005,
            },
            ["Normal"] = {
                number = 1,
                rep = 50,
                adverse = 0.995,
                lose_coolant = 0.99995,
                gain_coolant = 0.001,
            },
            ["Hard"] = {
                number = 2,
                rep = 30,
                adverse = 0.99,
                lose_coolant = 0.9999,
                gain_coolant = 0.0001,
            },
        }
        difficulty = murphy_config[getScenarioSetting("Murphy")].number
        adverseEffect = murphy_config[getScenarioSetting("Murphy")].adverse
        coolant_loss = murphy_config[getScenarioSetting("Murphy")].lose_coolant
        coolant_gain = murphy_config[getScenarioSetting("Murphy")].gain_coolant
        starting_rep = murphy_config[getScenarioSetting("Murphy")].rep
        local rescue_config = {
            ["10"] = 10,
            ["15"] = 15,
            ["20"] = 20,
            ["25"] = 25,
            ["30"] = 30,
        }
        rescue_time_limit = rescue_config[getScenarioSetting("Rescue")]
        local destroy_config = {
            ["10"] = 10,
            ["15"] = 15,
            ["20"] = 20,
            ["25"] = 25,
            ["30"] = 30,
        }
        destroy_time_limit = destroy_config[getScenarioSetting("Destroy")]
        local reputation_config = {
            ["Unknown"] = 0,
            ["Nice"] = 20,
            ["Hero"] = 50,
            ["Major Hero"] = 100,
            ["Super Hero"] = 200,
        }
        reputation_start_amount =
            reputation_config[getScenarioSetting("Reputation")]
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
    call_sign_name_overrides = {
        human_names = { add = { "Heracles" } },
    }
    far_enough_fail = false
    medical_research_obtained = false
    distance_diagnostic = false
    stationCommsDiagnostic = false
    change_enemy_order_diagnostic = false
    healthDiagnostic = false
    sensor_jammer_diagnostic = false
    sj_diagnostic = false --short sensor jammer diagnostic, once at env create
    guaranteed_comms_diagnostic = false
    medical_message_diagnostic = false
    all_players_hailed_by_medical_research_station = false
    player_ship_spawn_count = 0
    player_ship_death_count = 0
    expedition_count = 5 + (difficulty * 2)
    task_force_count = 5 + (difficulty * 2)
    max_repeat_loop = 300
    local c_x, c_y = vectorFromAngleNorth(random(0, 360), random(0, 60000))
    center_x = 909000 + c_x
    center_y = 151000 + c_y
    primary_orders = _("orders-comms", "Contact regional headquarters")
    plotCI = cargoInventory
    plotH = healthCheck --Damage to ship can kill repair crew members
    healthCheckTimerInterval = 8
    healthCheckTimer = healthCheckTimerInterval
    prefix_length = 0
    suffix_index = 0
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
        ["Tug"] = 200,
        ["Tyr"] = 2000,
        ["Waddle 5"] = 100,
        [ST.WARDEN] = 600,
        [ST.WEAPONS_PLATFORM] = 200,
        ["Work Wagon"] = 600,
        ["WX-Lindworm"] = 100,
        ["WZ-Lindworm"] = 100,
    }
    fly_formation = {
        ["V"] = {
            { angle = 60, dist = 1 },
            { angle = 300, dist = 1 },
        },
        ["Vac"] = {
            { angle = 30, dist = 1 },
            { angle = 330, dist = 1 },
        },
        ["V4"] = {
            { angle = 60, dist = 1 },
            { angle = 300, dist = 1 },
            { angle = 60, dist = 2 },
            { angle = 300, dist = 2 },
        },
        ["Vac4"] = {
            { angle = 30, dist = 1 },
            { angle = 330, dist = 1 },
            { angle = 30, dist = 2 },
            { angle = 330, dist = 2 },
        },
        ["A"] = {
            { angle = 120, dist = 1 },
            { angle = 240, dist = 1 },
        },
        ["Aac"] = {
            { angle = 150, dist = 1 },
            { angle = 210, dist = 1 },
        },
        ["A4"] = {
            { angle = 120, dist = 1 },
            { angle = 240, dist = 1 },
            { angle = 120, dist = 2 },
            { angle = 240, dist = 2 },
        },
        ["Aac4"] = {
            { angle = 150, dist = 1 },
            { angle = 210, dist = 1 },
            { angle = 150, dist = 2 },
            { angle = 210, dist = 2 },
        },
        ["/"] = {
            { angle = 60, dist = 1 },
            { angle = 240, dist = 1 },
        },
        ["-"] = {
            { angle = 90, dist = 1 },
            { angle = 270, dist = 1 },
        },
        ["-4"] = {
            { angle = 90, dist = 1 },
            { angle = 270, dist = 1 },
            { angle = 90, dist = 2 },
            { angle = 270, dist = 2 },
        },
        ["\\"] = {
            { angle = 300, dist = 1 },
            { angle = 120, dist = 1 },
        },
        ["|"] = {
            { angle = 0, dist = 1 },
            { angle = 180, dist = 1 },
        },
        ["|4"] = {
            { angle = 0, dist = 1 },
            { angle = 180, dist = 1 },
            { angle = 0, dist = 2 },
            { angle = 180, dist = 2 },
        },
        ["/ac"] = {
            { angle = 30, dist = 1 },
            { angle = 210, dist = 1 },
        },
        ["\\ac"] = {
            { angle = 330, dist = 1 },
            { angle = 150, dist = 1 },
        },
        ["M"] = {
            { angle = 60, dist = 1 },
            { angle = 90, dist = 1 },
            { angle = 300, dist = 1 },
            { angle = 270, dist = 1 },
        },
        ["Mac"] = {
            { angle = 30, dist = 1 },
            { angle = 90, dist = 1 },
            { angle = 330, dist = 1 },
            { angle = 270, dist = 1 },
        },
        ["M6"] = {
            { angle = 60, dist = 1 },
            { angle = 90, dist = 1 },
            { angle = 300, dist = 1 },
            { angle = 270, dist = 1 },
            { angle = 120, dist = 1.3 },
            { angle = 240, dist = 1.3 },
        },
        ["Mac6"] = {
            { angle = 30, dist = 1 },
            { angle = 90, dist = 1 },
            { angle = 330, dist = 1 },
            { angle = 270, dist = 1 },
            { angle = 125, dist = 1.7 },
            { angle = 235, dist = 1.7 },
        },
        ["W"] = {
            { angle = 120, dist = 1 },
            { angle = 240, dist = 1 },
            { angle = 90, dist = 1 },
            { angle = 270, dist = 1 },
        },
        ["Wac"] = {
            { angle = 150, dist = 1 },
            { angle = 210, dist = 1 },
            { angle = 90, dist = 1 },
            { angle = 270, dist = 1 },
        },
        ["W6"] = {
            { angle = 120, dist = 1 },
            { angle = 240, dist = 1 },
            { angle = 90, dist = 1 },
            { angle = 270, dist = 1 },
            { angle = 60, dist = 1.3 },
            { angle = 300, dist = 1.3 },
        },
        ["Wac6"] = {
            { angle = 150, dist = 1 },
            { angle = 210, dist = 1 },
            { angle = 90, dist = 1 },
            { angle = 270, dist = 1 },
            { angle = 55, dist = 1.7 },
            { angle = 295, dist = 1.7 },
        },
        ["X"] = {
            { angle = 60, dist = 1 },
            { angle = 300, dist = 1 },
            { angle = 120, dist = 1 },
            { angle = 240, dist = 1 },
        },
        ["Xac"] = {
            { angle = 30, dist = 1 },
            { angle = 330, dist = 1 },
            { angle = 150, dist = 1 },
            { angle = 210, dist = 1 },
        },
        ["X8"] = {
            { angle = 60, dist = 1 },
            { angle = 300, dist = 1 },
            { angle = 120, dist = 1 },
            { angle = 240, dist = 1 },
            { angle = 60, dist = 2 },
            { angle = 300, dist = 2 },
            { angle = 120, dist = 2 },
            { angle = 240, dist = 2 },
        },
        ["Xac8"] = {
            { angle = 30, dist = 1 },
            { angle = 330, dist = 1 },
            { angle = 150, dist = 1 },
            { angle = 210, dist = 1 },
            { angle = 30, dist = 2 },
            { angle = 330, dist = 2 },
            { angle = 150, dist = 2 },
            { angle = 210, dist = 2 },
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
    max_pyramid_tier = 15
    -- patrol_probe value should be between 0 and 5 not inclusive (0 = no patrol probes). The higher the value, the faster the patrol probe and the fewer patrol probes available
    playerShipStats = {
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
            print(version_message)
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
            print(version_message)
        end
    )
    addGMFunction(_("buttonGM", "+Station Reports"), stationReports)
    addGMFunction(_("buttonGM", "+Rescue Time"), setRescueTime)
    addGMFunction(_("buttonGM", "+Destroy Time"), setDestroyTime)
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
end
function setDestroyTime()
    clearGMFunctions()
    addGMFunction(_("buttonGM", "-From Destroy Time"), mainGMButtons)
    local destroy_times = { 15, 20, 25, 30 }
    for index, time in ipairs(destroy_times) do
        local button_label = string.format(_("buttonGM", "%i minutes"), time)
        if time == destroy_time_limit then
            button_label = button_label .. "*"
        end
        addGMFunction(button_label, function()
            destroy_time_limit = time
            setDestroyTime()
        end)
    end
end
function setRescueTime()
    clearGMFunctions()
    addGMFunction(_("buttonGM", "-From Rescue Time"), mainGMButtons)
    local rescue_times = { 15, 20, 25, 30 }
    for index, time in ipairs(rescue_times) do
        local button_label = string.format(_("buttonGM", "%i minutes"), time)
        if time == rescue_time_limit then
            button_label = button_label .. "*"
        end
        addGMFunction(button_label, function()
            rescue_time_limit = time
            setRescueTime()
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
                            -- out = string.format("%s\n      Cost multipliers and Max Refill:   Friend: %.1f %.1f,   Neutral: %.1f %.1f",out,station.comms_data.reputation_cost_multipliers.friend,station.comms_data.max_weapon_refill_amount.friend,station.comms_data.reputation_cost_multipliers.neutral,station.comms_data.max_weapon_refill_amount.neutral)
                            out = string.format(
                                _(
                                    "stationReport-msgGM",
                                    "%s\nServices and their costs:"
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
            p:setMaxScanProbeCount(playerShipStats[tempTypeName].probes)
            p:setScanProbeCount(p:getMaxScanProbeCount())
            p.tractor = playerShipStats[tempTypeName].tractor
            p.tractor_target_lock = false
            p.mining = playerShipStats[tempTypeName].mining
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
    p.impulse_upgrade = 0
    p.shield_upgrade = 0
    p.tube_speed_upgrade = 0
    if not p:hasJumpDrive() and not p:hasWarpDrive() then
        if random(1, 100) <= 50 then
            p:setJumpDrive(true)
            local jump_range = { 20, 25, 30, 35 }
            p.max_jump_range = jump_range[math.random(1, #jump_range)] * 1000
            p.min_jump_range = p.max_jump_range / 10
            p:setJumpDriveRange(p.min_jump_range, p.max_jump_range)
            p:setJumpDriveCharge(p.max_jump_range)
        else
            p:setWarpDrive(true)
            p:setWarpSpeed(450 + (math.random(1, 10) * 50))
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
    p:setFaction(player_faction)
    updatePlayerSoftTemplate(p)
    player_ship_spawn_count = player_ship_spawn_count + 1
    p:onDestroyed(playerDestroyed)
    if p:getReputationPoints() == 0 then
        p:setReputationPoints(reputation_start_amount)
    end
end
function playerDestroyed(self, instigator)
    player_ship_death_count = player_ship_death_count + 1
end
-- Construct environment and related functions
function constructEnvironment()
    place_space = {}
    local faction_circle = {
        "Exuari",
        "Ghosts",
        "TSN",
        "Independent",
        "Human Navy",
        "Arlenians",
        "Ktlitans",
        "CUF",
        "USN",
        "Kraylor",
        "Ghosts",
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
    local inner_circle = {}
    player_factions = { "Human Navy", "CUF", "USN", "TSN" }
    player_faction = player_factions[math.random(1, #player_factions)]
    station_regional_hq = placeStation(
        center_x,
        center_y,
        "Alt Sci Fi",
        player_faction,
        "Large Station"
    )
    table.insert(station_list, station_regional_hq)
    table.insert(
        place_space,
        { obj = station_regional_hq, dist = 1000, shape = "circle" }
    )
    hq_medical_message = Artifact()
        :setCallSign(station_regional_hq:getCallSign())
        :setCommsScript("")
        :setCommsFunction(medicalAttentionComms)
    hq_plague_message = Artifact()
        :setCallSign(station_regional_hq:getCallSign())
        :setCommsScript("")
        :setCommsFunction(destroyPlagueComms)
    local defense_platform_angle = random(0, 360)
    for i = 1, 6 do
        local dp_x, dp_y = vectorFromAngle(defense_platform_angle, 4000)
        local dp = CpuShip()
            :setTemplate(ST.DEFENSE_PLATFORM)
            :setFaction(player_faction)
            :setPosition(center_x + dp_x, center_y + dp_y)
            :setScanState("fullscan")
            :orderStandGround()
        dp:setCallSign(
            string.format(
                "%sDP%i%s",
                faction_letter[player_faction],
                i,
                string.char(96 + math.random(1, 26))
            )
        )
        table.insert(place_space, { obj = dp, dist = 1000, shape = "circle" })
        defense_platform_angle = (defense_platform_angle + 60) % 360
    end
    initial_angle = random(0, 360)
    player_spawn_x, player_spawn_y =
        vectorFromAngleNorth(initial_angle, 10000 + difficulty * 5000)
    player_spawn_x = player_spawn_x + center_x
    player_spawn_y = player_spawn_y + center_y
    local defense_platforms = {
        [ST.SMALL_STATION] = { count = 3, dist = 2000 },
        [ST.MEDIUM_STATION] = { count = 4, dist = 3300 },
        [ST.LARGE_STATION] = { count = 5, dist = 4000 },
        [ST.HUGE_STATION] = { count = 6, dist = 4500 },
    }
    circle_stations = {}
    local station_circle_distance_base = 30000
    local total_station_circle_distance = 0
    --create station circle stations
    for i = 1, #faction_circle do
        local station_circle_distance = station_circle_distance_base
            + random(0, 40000)
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
    local planet_threshold = 30000
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
    --set barriers between protective warp jammer bubbles
    for index, station in ipairs(circle_stations) do
        if station.barrier == nil then
            local station_b = station.higher_neighbor
            local warp_jammer_a = station.warp_jammer_list[1]
            local warp_jammer_b = station_b.warp_jammer_list[1]
            local gap_size = distance(warp_jammer_a, warp_jammer_b)
                - warp_jammer_a.range
                - warp_jammer_b.range
            local wja_x, wja_y = warp_jammer_a:getPosition()
            local wjb_x, wjb_y = warp_jammer_b:getPosition()
            local barrier_center_x = (wja_x + wjb_x) / 2
            local barrier_center_y = (wja_y + wjb_y) / 2
            local aj_angle = angleFromVectorNorth(wja_x, wja_y, wjb_x, wjb_y) --barrier to warp jammer a angle
            local bj_angle = angleFromVectorNorth(wjb_x, wjb_y, wja_x, wja_y) --barrier to warp jammer b angle
            local mine_space = 1200
            local start_point_x, start_point_y =
                vectorFromAngleNorth(bj_angle, warp_jammer_a.range)
            start_point_x = start_point_x + wja_x
            start_point_y = start_point_y + wja_y
            local line_angle = (bj_angle + 90) % 360
            local m_x, m_y = vectorFromAngleNorth(line_angle, mine_space)
            local start_point_right_x = start_point_x + m_x
            local start_point_right_y = start_point_y + m_y
            line_angle = (bj_angle + 270) % 360
            m_x, m_y = vectorFromAngleNorth(line_angle, mine_space)
            local start_point_left_x = start_point_x + m_x
            local start_point_left_y = start_point_y + m_y
            local finish_point_x, finish_point_y =
                vectorFromAngleNorth(bj_angle, gap_size)
            local finish_point_left_x = start_point_left_x + finish_point_x
            local finish_point_left_y = start_point_left_y + finish_point_y
            local finish_point_right_x = start_point_right_x + finish_point_x
            local finish_point_right_y = start_point_right_y + finish_point_y
            local barrier_choices =
                { "Warp Jammer", "Mines", "Danger Zone", "Patrol", "Asteroids" }
            if station.higher_distance > 18000 then
                barrier_choices = {
                    "Warp Jammer",
                    "Mines",
                    "Danger Zone",
                    "Patrol",
                    "Asteroids",
                    "Black Hole",
                }
            end
            local barrier_choice =
                barrier_choices[math.random(1, #barrier_choices)]
            -- local barrier_choice = "Asteroids"
            if barrier_choice == "Black Hole" then
                local bh =
                    BlackHole():setPosition(barrier_center_x, barrier_center_y)
                table.insert(
                    place_space,
                    { obj = bh, dist = 6000, shape = "circle" }
                )
                station.barrier = "black hole"
                local a_to_bh = distance(warp_jammer_a, bh)
                local b_to_bh = distance(warp_jammer_b, bh)
                -- print("a to bh:",a_to_bh,"b to bh:",b_to_bh,"a range:",warp_jammer_a.range,"b range:",warp_jammer_b.range)
                -- print("a and b:",warp_jammer_a,warp_jammer_b)
                -- print(station:getCallSign(),station_b:getCallSign())
                if
                    a_to_bh > warp_jammer_a.range + 5000
                    and b_to_bh > warp_jammer_b.range + 5000
                then
                    -- print("met")
                    local aj_x, aj_y = vectorFromAngleNorth(aj_angle, 6000)
                    local ncj_x = 0
                    local ncj_y = 0
                    local bhwj = WarpJammer()
                        :setPosition(
                            barrier_center_x + aj_x,
                            barrier_center_y + aj_y
                        )
                        :setRange(6000)
                        :setFaction(station:getFaction())
                    bhwj.range = 6000
                    table.insert(station.warp_jammer_list, bhwj)
                    warp_jammer_info[station:getFaction()].count = warp_jammer_info[station:getFaction()].count
                        + 1
                    bhwj:setCallSign(
                        string.format(
                            "L%sWJ%i",
                            warp_jammer_info[station:getFaction()].id,
                            warp_jammer_info[station:getFaction()].count
                        )
                    )
                    table.insert(warp_jammer_list, bhwj)
                    if random(1, 100) < 30 + difficulty * 20 then
                        ncj_x, ncj_y = vectorFromAngleNorth(
                            aj_angle + random(-90, 90),
                            random(1000, 4000)
                        )
                        Nebula():setPosition(
                            barrier_center_x + aj_x + ncj_x,
                            barrier_center_y + aj_y + ncj_y
                        )
                    end
                    aj_x, aj_y =
                        vectorFromAngleNorth((aj_angle + 180) % 360, 6000)
                    bhwj = WarpJammer()
                        :setPosition(
                            barrier_center_x + aj_x,
                            barrier_center_y + aj_y
                        )
                        :setRange(6000)
                        :setFaction(station_b:getFaction())
                    bhwj.range = 6000
                    table.insert(station.warp_jammer_list, bhwj)
                    warp_jammer_info[station:getFaction()].count = warp_jammer_info[station:getFaction()].count
                        + 1
                    bhwj:setCallSign(
                        string.format(
                            "L%sWJ%i",
                            warp_jammer_info[station:getFaction()].id,
                            warp_jammer_info[station:getFaction()].count
                        )
                    )
                    table.insert(warp_jammer_list, bhwj)
                    if random(1, 100) < 30 + difficulty * 20 then
                        ncj_x, ncj_y = vectorFromAngleNorth(
                            aj_angle + 180 + random(-90, 90),
                            random(1000, 4000)
                        )
                        Nebula():setPosition(
                            barrier_center_x + aj_x + ncj_x,
                            barrier_center_y + aj_y + ncj_y
                        )
                    end
                end
            elseif barrier_choice == "Warp Jammer" then
                local wj = WarpJammer()
                    :setPosition(barrier_center_x, barrier_center_y)
                    :setFaction(station:getFaction())
                local wj_range =
                    math.min(warp_jammer_a.range, warp_jammer_b.range)
                wj_range = distance(warp_jammer_a, wj) - wj_range
                -- print("range:",wj_range)
                wj:setRange(wj_range)
                wj.range = wj_range
                table.insert(station.warp_jammer_list, wj)
                warp_jammer_info[station:getFaction()].count = warp_jammer_info[station:getFaction()].count
                    + 1
                wj:setCallSign(
                    string.format(
                        "L%sWJ%i",
                        warp_jammer_info[station:getFaction()].id,
                        warp_jammer_info[station:getFaction()].count
                    )
                )
                table.insert(warp_jammer_list, wj)
                station.barrier = "warp jammer"
            elseif barrier_choice == "Mines" then
                local mine_count = 0
                repeat
                    m_x, m_y =
                        vectorFromAngleNorth(bj_angle, mine_count * mine_space)
                    local placed_mine_center = Mine():setPosition(
                        start_point_x + m_x,
                        start_point_y + m_y
                    )
                    local placed_mine_right = Mine():setPosition(
                        start_point_right_x + m_x,
                        start_point_right_y + m_y
                    )
                    local placed_mine_left = Mine():setPosition(
                        start_point_left_x + m_x,
                        start_point_left_y + m_y
                    )
                    table.insert(
                        place_space,
                        {
                            obj = placed_mine_center,
                            dist = 800,
                            shape = "circle",
                        }
                    )
                    table.insert(
                        place_space,
                        {
                            obj = placed_mine_right,
                            dist = 800,
                            shape = "circle",
                        }
                    )
                    table.insert(
                        place_space,
                        { obj = placed_mine_left, dist = 800, shape = "circle" }
                    )
                    mine_count = mine_count + 1
                until distance(placed_mine_center, warp_jammer_b)
                        < warp_jammer_b.range
                    or mine_count > 20
                if random(1, 100) < 30 + difficulty * 20 then
                    local mwj_x, mwj_y = vectorFromAngleNorth(
                        aj_angle + 270,
                        warp_jammer_a.range
                    )
                    if random(1, 50) < 50 then
                        mwj_x, mwj_y = vectorFromAngleNorth(
                            aj_angle + 90,
                            warp_jammer_a.range
                        )
                    end
                    local mwj = WarpJammer()
                        :setPosition(
                            barrier_center_x + mwj_x,
                            barrier_center_y + mwj_y
                        )
                        :setRange(warp_jammer_a.range + 1200)
                        :setFaction(station:getFaction())
                    warp_jammer_info[station:getFaction()].count = warp_jammer_info[station:getFaction()].count
                        + 1
                    mwj:setCallSign(
                        string.format(
                            "%sWJ%i",
                            warp_jammer_info[station:getFaction()].id,
                            warp_jammer_info[station:getFaction()].count
                        )
                    )
                    mwj.range = warp_jammer_a.range + 1200
                    table.insert(warp_jammer_list, mwj)
                    local nd_angle = random(0, 360)
                    local bn_x, bn_y =
                        vectorFromAngle(nd_angle, random(1000, 4000))
                    Nebula():setPosition(
                        barrier_center_x + mwj_x + bn_x,
                        barrier_center_y + mwj_y + bn_y
                    )
                    if random(1, 100) < 50 then
                        nd_angle = nd_angle + random(-60, 60)
                        bn_x, bn_y =
                            vectorFromAngle(nd_angle, random(2000, 4500))
                        Nebula():setPosition(
                            barrier_center_x + mwj_x + bn_x,
                            barrier_center_y + mwj_y + bn_y
                        )
                        if random(1, 100) < 50 then
                            nd_angle = nd_angle + random(-60, 60)
                            bn_x, bn_y =
                                vectorFromAngle(nd_angle, random(2000, 4500))
                            Nebula():setPosition(
                                barrier_center_x + mwj_x + bn_x,
                                barrier_center_y + mwj_y + bn_y
                            )
                        end
                    end
                end
                station.barrier = "mines"
            elseif barrier_choice == "Danger Zone" then
                if danger_zones == nil then
                    danger_zones = {}
                end
                local dz = Zone():setPoints(
                    start_point_right_x,
                    start_point_right_y,
                    start_point_left_x,
                    start_point_left_y,
                    finish_point_left_x,
                    finish_point_left_y,
                    finish_point_right_x,
                    finish_point_right_y
                )
                table.insert(danger_zones, dz)
                station.barrier = "danger zone"
            elseif barrier_choice == "Patrol" then
                if barrier_patrols == nil then
                    barrier_patrols = {}
                end
                local ship = CpuShip()
                    :setTemplate(ST.PHOBOS_T3)
                    :setPosition(start_point_right_x, start_point_right_y)
                    :setFaction(station:getFaction())
                ship:setCallSign(generateCallSign(nil, station:getFaction()))
                ship:orderFlyTowards(start_point_right_x, start_point_right_y)
                ship.patrol_points = {
                    { x = start_point_right_x, y = start_point_right_y },
                    { x = finish_point_left_x, y = finish_point_left_y },
                }
                ship.patrol_base_station = station
                ship.patrol_point_index = 1
                ship.patrol_check_timer_interval = 5
                ship.patrol_check_timer = ship.patrol_check_timer_interval
                ship:onDestruction(refreshBarrierPatrol)
                table.insert(barrier_patrols, ship)
                ship = CpuShip()
                    :setTemplate(ST.PHOBOS_T3)
                    :setPosition(finish_point_right_x, finish_point_right_y)
                    :setFaction(station_b:getFaction())
                ship:setCallSign(generateCallSign(nil, station_b:getFaction()))
                ship:orderFlyTowards(finish_point_right_x, finish_point_right_y)
                ship.patrol_points = {
                    { x = finish_point_right_x, y = finish_point_right_y },
                    { x = start_point_left_x, y = start_point_left_y },
                }
                ship.patrol_base_station = station_b
                ship.patrol_point_index = 1
                ship.patrol_check_timer_interval = 5
                ship.patrol_check_timer = ship.patrol_check_timer_interval
                table.insert(barrier_patrols, ship)
                station.barrier = "patrol"
            elseif barrier_choice == "Asteroids" then
                local asteroid_count =
                    math.floor((gap_size * 3600 / (250 * 250)) / random(9, 17))
                for i = 1, asteroid_count do
                    local lax_x, lax_y =
                        vectorFromAngleNorth(bj_angle, random(0, gap_size))
                    local sax_x, sax_y =
                        vectorFromAngleNorth(bj_angle + 90, random(0, 3600))
                    local ba = Asteroid():setPosition(
                        start_point_left_x + lax_x + sax_x,
                        start_point_left_y + lax_y + sax_y
                    )
                    local size = 0
                    for j = 1, 5 do
                        size = size + random(4, 100)
                    end
                    ba:setSize(size)
                    table.insert(
                        place_space,
                        { obj = ba, dist = size * 0.1, shape = "circle" }
                    )
                end
                if random(1, 100) < 30 + difficulty * 20 then
                    local mwj_x, mwj_y = vectorFromAngleNorth(
                        aj_angle + 270,
                        warp_jammer_a.range
                    )
                    if random(1, 50) < 50 then
                        mwj_x, mwj_y = vectorFromAngleNorth(
                            aj_angle + 90,
                            warp_jammer_a.range
                        )
                    end
                    local mwj = WarpJammer()
                        :setPosition(
                            barrier_center_x + mwj_x,
                            barrier_center_y + mwj_y
                        )
                        :setRange(warp_jammer_a.range + 1200)
                        :setFaction(station:getFaction())
                    warp_jammer_info[station:getFaction()].count = warp_jammer_info[station:getFaction()].count
                        + 1
                    mwj:setCallSign(
                        string.format(
                            "%sWJ%i",
                            warp_jammer_info[station:getFaction()].id,
                            warp_jammer_info[station:getFaction()].count
                        )
                    )
                    mwj.range = warp_jammer_a.range + 1200
                    table.insert(warp_jammer_list, mwj)
                    local nd_angle = random(0, 360)
                    local bn_x, bn_y =
                        vectorFromAngle(nd_angle, random(1000, 4000))
                    Nebula():setPosition(
                        barrier_center_x + mwj_x + bn_x,
                        barrier_center_y + mwj_y + bn_y
                    )
                    if random(1, 100) < 50 then
                        nd_angle = nd_angle + random(-60, 60)
                        bn_x, bn_y =
                            vectorFromAngle(nd_angle, random(2000, 4500))
                        Nebula():setPosition(
                            barrier_center_x + mwj_x + bn_x,
                            barrier_center_y + mwj_y + bn_y
                        )
                        if random(1, 100) < 50 then
                            nd_angle = nd_angle + random(-60, 60)
                            bn_x, bn_y =
                                vectorFromAngle(nd_angle, random(2000, 4500))
                            Nebula():setPosition(
                                barrier_center_x + mwj_x + bn_x,
                                barrier_center_y + mwj_y + bn_y
                            )
                        end
                    end
                end
                station.barrier = "asteroids"
            end
        end
    end
    -- set up for protect the freighter plot
    local t_x, t_y =
        vectorFromAngleNorth(initial_angle, 6000 + difficulty * 5000)
    critical_transport = randomTransportType()
    critical_transport:setPosition(center_x + t_x, center_y + t_y)
    critical_transport:setCallSign(generateCallSign(nil, player_faction))
    critical_transport:setFaction("Independent")
    critical_transport:orderDock(station_regional_hq)
    critical_transport
        :setFaction(player_faction)
        :setCommsScript("")
        :setCommsFunction(commsShip)
    table.insert(
        place_space,
        { obj = critical_transport, dist = 600, shape = "circle" }
    )
    primary_orders = string.format(
        _("orders-comms", "Protect freighter %s until they dock at %s"),
        critical_transport:getCallSign(),
        station_regional_hq:getCallSign()
    )
    -- freighter attackers
    local attack_angle = initial_angle + 180
    local l1_x, l1_y = vectorFromAngleNorth(initial_angle, 25000)
    local leader_1 = CpuShip()
        :setTemplate(ST.ADDER_MK5)
        :setPosition(center_x + l1_x, center_y + l1_y)
        :setFaction("Exuari")
        :setHeading(attack_angle)
    leader_1:setCallSign(generateCallSign(nil, "Exuari"))
    table.insert(place_space, { obj = leader_1, dist = 200, shape = "circle" })
    local l2_x, l2_y = vectorFromAngleNorth(initial_angle + 90, 5000)
    local leader_2 = CpuShip()
        :setTemplate(ST.ADDER_MK5)
        :setPosition(center_x + l1_x + l2_x, center_y + l1_y + l2_y)
        :setFaction("Exuari")
        :setHeading(attack_angle)
    leader_2:setCallSign(generateCallSign(nil, "Exuari"))
    table.insert(place_space, { obj = leader_2, dist = 200, shape = "circle" })
    local l3_x, l3_y = vectorFromAngleNorth(initial_angle + 270, 5000)
    local leader_3 = CpuShip()
        :setTemplate(ST.ADDER_MK5)
        :setPosition(center_x + l1_x + l3_x, center_y + l1_y + l3_y)
        :setFaction("Exuari")
        :setHeading(attack_angle)
    leader_3:setCallSign(generateCallSign(nil, "Exuari"))
    table.insert(place_space, { obj = leader_3, dist = 200, shape = "circle" })
    local form_choice = {
        [0.5] = "V",
        [1] = "V4",
        [2] = "W6",
    }
    local template = "MT52 Hornet"
    local formation_spacing = 1000
    local selected_faction = "Exuari"
    local lx =
        { center_x + l1_x, center_x + l1_x + l2_x, center_x + l1_x + l3_x }
    local ly =
        { center_y + l1_y, center_y + l1_y + l2_y, center_y + l1_y + l3_y }
    local leader = { leader_1, leader_2, leader_3 }
    for i = 1, 3 do
        for idx, form in ipairs(fly_formation[form_choice[difficulty]]) do
            local ship =
                ship_template[template].create(selected_faction, template)
            local form_x, form_y = vectorFromAngleNorth(
                attack_angle + form.angle,
                form.dist * formation_spacing
            )
            local form_prime_x, form_prime_y =
                vectorFromAngle(form.angle, form.dist * formation_spacing)
            ship:setFaction("Independent")
            ship:setPosition(lx[i] + form_x, ly[i] + form_y)
                :setHeading(attack_angle)
                :orderFlyFormation(leader[i], form_prime_x, form_prime_y)
            ship:setFaction(selected_faction)
            ship:setCallSign(generateCallSign(nil, selected_faction))
            ship.home_station = circle_stations[1]
            ship.home_station_name = circle_stations[1]:getCallSign()
            ship:setCommsScript(""):setCommsFunction(commsShip)
            table.insert(
                place_space,
                { obj = ship, dist = 200, shape = "circle" }
            )
        end
    end
    local ship = tableRemoveRandom(leader)
    ship:orderFlyTowards(center_x, center_y)
    ship = tableRemoveRandom(leader)
    ship:orderAttack(critical_transport)
    leader[1]:orderRoaming()
    mainLinearPlot = freighterMessage
    transport_list = {}
    transport_stations = {}
    --fill in roughly circular area with semi-random terrain
    local black_hole_chance = 1
    black_hole_count = math.random(1, 6)
    local star_chance = 3
    star_count = math.random(1, 2)
    local probe_chance = 6
    local warp_jammer_chance = 3
    local worm_hole_chance = 2
    worm_hole_count = math.random(1, 4)
    local sensor_jammer_chance = 6
    local sensor_buoy_chance = 6
    local ad_buoy_chance = 8
    local nebula_chance = 5
    local mine_chance = 4
    local station_chance = 3
    local mine_field_chance = 4
    mine_field_count = math.random(3, 8)
    local asteroid_field_chance = 4
    asteroid_field_count = math.random(2, 6)
    local transport_chance = 5
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
    --create an axis off the circle for a medical research station
    research_axis = random(0, 360)
    local research_axis_stations = {}
    transport_chance = 3
    station_chance = 5
    repeat
        local current_object_chance = 0
        local object_roll = random(0, 100)
        current_object_chance = current_object_chance + black_hole_chance
        if object_roll <= current_object_chance then
            placeBlackHole(research_axis)
            goto iterate_research_axis
        end
        current_object_chance = current_object_chance + star_chance
        if object_roll <= current_object_chance then
            placeStar(research_axis)
            goto iterate_research_axis
        end
        current_object_chance = current_object_chance + probe_chance
        if object_roll <= current_object_chance then
            placeProbe(research_axis)
            goto iterate_research_axis
        end
        current_object_chance = current_object_chance + warp_jammer_chance
        if object_roll <= current_object_chance then
            placeWarpJammer(research_axis)
            goto iterate_research_axis
        end
        current_object_chance = current_object_chance + worm_hole_chance
        if object_roll <= current_object_chance then
            placeWormHole(research_axis)
            goto iterate_research_axis
        end
        current_object_chance = current_object_chance + sensor_jammer_chance
        if object_roll <= current_object_chance then
            placeSensorJammer(research_axis)
            goto iterate_research_axis
        end
        current_object_chance = current_object_chance + sensor_buoy_chance
        if object_roll <= current_object_chance then
            placeSensorBuoy(research_axis)
            goto iterate_research_axis
        end
        current_object_chance = current_object_chance + ad_buoy_chance
        if object_roll <= current_object_chance then
            placeAdBuoy(research_axis)
            goto iterate_research_axis
        end
        current_object_chance = current_object_chance + nebula_chance
        if object_roll <= current_object_chance then
            placeNebula(research_axis)
            goto iterate_research_axis
        end
        current_object_chance = current_object_chance + mine_chance
        if object_roll <= current_object_chance then
            placeMine(research_axis)
            goto iterate_research_axis
        end
        current_object_chance = current_object_chance + station_chance
        if object_roll <= current_object_chance then
            local placed_station = placeEnvironmentStation(research_axis)
            if placed_station ~= nil then
                table.insert(research_axis_stations, placed_station)
            end
            goto iterate_research_axis
        end
        current_object_chance = current_object_chance + mine_field_chance
        if object_roll <= current_object_chance then
            placeMineField(research_axis)
            goto iterate_research_axis
        end
        current_object_chance = current_object_chance + asteroid_field_chance
        if object_roll <= current_object_chance then
            placeAsteroidField(research_axis)
            goto iterate_research_axis
        end
        current_object_chance = current_object_chance + transport_chance
        if object_roll <= current_object_chance then
            placeTransport(research_axis)
            goto iterate_research_axis
        end
        placeAsteroid()
        ::iterate_research_axis::
    until #research_axis_stations >= 5 or far_enough_fail
    if far_enough_fail then
        if #research_axis_stations > 0 then
            local independent_found = false
            for index, station in ipairs(research_axis_stations) do
                if station:getFaction() == "Independent" then
                    independent_found = true
                    station_medical_research = station
                    break
                end
            end
            if not independent_found then
                local tpa = Artifact():setFaction(player_faction)
                local neutral_friendly_found = false
                for index, station in ipairs(research_axis_stations) do
                    if not station:isEnemy(tpa) then
                        neutral_friendly_found = true
                        station_medical_research = station
                        station:setFaction("Independent")
                        for _, ship in ipairs(station.defense_fleet) do
                            ship:setFaction("Independent")
                        end
                        break
                    end
                end
                tpa:destroy()
                if not neutral_friendly_found then
                    local bd_x, bd_y = vectorFromAngleNorth(
                        research_axis,
                        average_station_circle_distance + 80000
                    )
                    local station = placeStation(
                        center_x + bd_x,
                        center_y + bd_y,
                        "RandomHumanNeutral",
                        "Independent"
                    )
                    table.insert(station_list, station)
                    --defense fleet
                    local fleet = spawnEnemies(
                        center_x + bd_x,
                        center_y + bd_y,
                        1,
                        "Independent",
                        45
                    )
                    for _, ship in ipairs(fleet) do
                        ship:orderDefendTarget(station)
                        ship:setCallSign(generateCallSign(nil, "Independent"))
                    end
                    station.defense_fleet = fleet
                    table.insert(station_list, station)
                    station_medical_research = station
                end
            end
        else
            local bd_x, bd_y = vectorFromAngleNorth(
                research_axis,
                average_station_circle_distance + 80000
            )
            local station = placeStation(
                center_x + bd_x,
                center_y + bd_y,
                "RandomHumanNeutral",
                "Independent"
            )
            table.insert(station_list, station)
            --defense fleet
            local fleet = spawnEnemies(
                center_x + bd_x,
                center_y + bd_y,
                1,
                "Independent",
                45
            )
            for _, ship in ipairs(fleet) do
                ship:orderDefendTarget(station)
                ship:setCallSign(generateCallSign(nil, "Independent"))
            end
            station.defense_fleet = fleet
            table.insert(station_list, station)
            station_medical_research = station
        end
    else
        local independent_found = false
        for index, station in ipairs(research_axis_stations) do
            if station:getFaction() == "Independent" then
                independent_found = true
                station_medical_research = station
                break
            end
        end
        if not independent_found then
            local tpa = Artifact():setFaction(player_faction)
            local neutral_friendly_found = false
            for index, station in ipairs(research_axis_stations) do
                if not station:isEnemy(tpa) then
                    neutral_friendly_found = true
                    station_medical_research = station
                    station:setFaction("Independent")
                    for _, ship in ipairs(station.defense_fleet) do
                        ship:setFaction("Independent")
                    end
                    break
                end
            end
            tpa:destroy()
            if not neutral_friendly_found then
                local bd_x, bd_y = vectorFromAngleNorth(
                    research_axis,
                    average_station_circle_distance + 80000
                )
                local station = placeStation(
                    center_x + bd_x,
                    center_y + bd_y,
                    "RandomHumanNeutral",
                    "Independent"
                )
                table.insert(station_list, station)
                --defense fleet
                local fleet = spawnEnemies(
                    center_x + bd_x,
                    center_y + bd_y,
                    1,
                    "Independent",
                    45
                )
                for _, ship in ipairs(fleet) do
                    ship:orderDefendTarget(station)
                    ship:setCallSign(generateCallSign(nil, "Independent"))
                end
                station.defense_fleet = fleet
                table.insert(station_list, station)
                station_medical_research = station
            end
        end
    end
    medical_station_query_message = Artifact()
        :setCallSign(station_medical_research:getCallSign())
        :setCommsScript("")
        :setCommsFunction(medicalBaseLocationAssistanceComms)
    far_enough_fail = false
    plague_axis = (research_axis + random(120, 240)) % 360
    local plague_axis_stations = {}
    repeat
        local current_object_chance = 0
        local object_roll = random(0, 100)
        current_object_chance = current_object_chance + black_hole_chance
        if object_roll <= current_object_chance then
            placeBlackHole(plague_axis)
            goto iterate_plague_axis
        end
        current_object_chance = current_object_chance + star_chance
        if object_roll <= current_object_chance then
            placeStar(plague_axis)
            goto iterate_plague_axis
        end
        current_object_chance = current_object_chance + probe_chance
        if object_roll <= current_object_chance then
            placeProbe(plague_axis)
            goto iterate_plague_axis
        end
        current_object_chance = current_object_chance + warp_jammer_chance
        if object_roll <= current_object_chance then
            placeWarpJammer(plague_axis)
            goto iterate_plague_axis
        end
        current_object_chance = current_object_chance + worm_hole_chance
        if object_roll <= current_object_chance then
            placeWormHole(plague_axis)
            goto iterate_plague_axis
        end
        current_object_chance = current_object_chance + sensor_jammer_chance
        if object_roll <= current_object_chance then
            placeSensorJammer(plague_axis)
            goto iterate_plague_axis
        end
        current_object_chance = current_object_chance + sensor_buoy_chance
        if object_roll <= current_object_chance then
            placeSensorBuoy(plague_axis)
            goto iterate_plague_axis
        end
        current_object_chance = current_object_chance + ad_buoy_chance
        if object_roll <= current_object_chance then
            placeAdBuoy(plague_axis)
            goto iterate_plague_axis
        end
        current_object_chance = current_object_chance + nebula_chance
        if object_roll <= current_object_chance then
            placeNebula(plague_axis)
            goto iterate_plague_axis
        end
        current_object_chance = current_object_chance + mine_chance
        if object_roll <= current_object_chance then
            placeMine(plague_axis)
            goto iterate_plague_axis
        end
        current_object_chance = current_object_chance + station_chance
        if object_roll <= current_object_chance then
            local placed_station = placeEnvironmentStation(plague_axis)
            if placed_station ~= nil then
                placed_station:setFaction("Exuari")
                for _, ship in ipairs(placed_station.defense_fleet) do
                    ship:setFaction("Exuari")
                end
                table.insert(plague_axis_stations, placed_station)
            end
            goto iterate_plague_axis
        end
        current_object_chance = current_object_chance + mine_field_chance
        if object_roll <= current_object_chance then
            placeMineField(plague_axis)
            goto iterate_plague_axis
        end
        current_object_chance = current_object_chance + asteroid_field_chance
        if object_roll <= current_object_chance then
            placeAsteroidField(plague_axis)
            goto iterate_plague_axis
        end
        current_object_chance = current_object_chance + transport_chance
        if object_roll <= current_object_chance then
            placeTransport(plague_axis)
            goto iterate_plague_axis
        end
        placeAsteroid()
        ::iterate_plague_axis::
    until #plague_axis_stations >= 5 or far_enough_fail
    if far_enough_fail then
        if #plague_axis_stations > 0 then
            station_plague =
                plague_axis_stations[math.random(1, #plague_axis_stations)]
        else
            local bd_x, bd_y = vectorFromAngleNorth(
                plague_axis,
                average_station_circle_distance + 80000
            )
            local station = placeStation(
                center_x + bd_x,
                center_y + bd_y,
                "Sinister",
                "Exuari"
            )
            table.insert(station_list, station)
            --defense fleet
            local fleet =
                spawnEnemies(center_x + bd_x, center_y + bd_y, 1, "Exuari", 65)
            for _, ship in ipairs(fleet) do
                ship:orderDefendTarget(station)
                ship:setCallSign(generateCallSign(nil, "Exuari"))
            end
            station.defense_fleet = fleet
            table.insert(station_list, station)
            station_plague = station
        end
    else
        station_plague =
            plague_axis_stations[math.random(1, #plague_axis_stations)]
    end
    maintenancePlot = defenseMaintenance
end
function placeWarpJammer(axis)
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
        table.insert(place_space, { obj = wj, dist = 200, shape = "circle" })
    end
end
function placeSensorJammer(axis)
    local lo_range = 10000
    local hi_range = 30000
    local lo_impact = 10000
    local hi_impact = 20000
    local range_increment = (hi_range - lo_range) / 8
    local impact_increment = (hi_impact - lo_impact) / 4
    local mix = math.random(2, 10 - (4 - (2 * math.floor(difficulty)))) --2-6, 2-8, 2-10
    sensor_jammer_scan_complexity = 1
    sensor_jammer_scan_depth = 1
    if mix > 5 then
        sensor_jammer_scan_depth = math.min(math.random(mix - 4, mix), 8)
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
    local eo_x, eo_y = environmentObject(center_x, center_y, 200, axis)
    if eo_x ~= nil then
        local sj = sensorJammer(eo_x, eo_y)
        table.insert(place_space, { obj = sj, dist = 200, shape = "circle" })
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
                for idx, station in ipairs(station_list) do
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
                for idx, transport in ipairs(transport_list) do
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
                "Find a companion. All species available"
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
            _("scienceDescription-buoy", "Best tasting water in the quadrant"),
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
        if station ~= nil then
            table.insert(
                place_space,
                {
                    obj = station,
                    dist = station_defend_dist[s_size],
                    shape = "circle",
                }
            )
            table.insert(station_list, station)
            --defense fleet
            local fleet = spawnEnemies(eo_x, eo_y, 1, selected_faction, 35)
            for _, ship in ipairs(fleet) do
                ship:setFaction("Independent")
                ship:orderDefendTarget(station)
                ship:setFaction(selected_faction)
                ship:setCallSign(generateCallSign(nil, selected_faction))
            end
            station.defense_fleet = fleet
        end
        return station
    end
end
---------------------------------------
--  Support for constant plot lines  --
---------------------------------------
function refreshBarrierPatrol(self, instigator)
    if
        self.patrol_base_station ~= nil and self.patrol_base_station:isValid()
    then
        local bs_x, bs_y = self.patrol_base_station:getPosition()
        local ship = spawnSingleEnemy(
            bs_x,
            bs_y,
            1,
            self.patrol_base_station:getFaction()
        )
        ship.patrol_points = self.patrol_points
        ship:orderFlyTowards(ship.patrol_points[1].x, ship.patrol_points[1].y)
        ship.patrol_base_station = self.patrol_base_station
        ship.patrol_point_index = 1
        ship.patrol_check_timer_interval = 5
        ship.patrol_check_timer = ship.patrol_check_timer_interval
        ship:onDestruction(refreshBarrierPatrol)
        table.insert(barrier_patrols, ship)
    end
end
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
    maintenancePlot = patrolMaintenance
end
function patrolMaintenance(delta)
    maintenancePlot = expeditionMaintenance
end
function expeditionMaintenance(delta)
    if #station_list > 0 then
        local fleet_count = 0
        local deleted_station = false
        for station_index, station in ipairs(station_list) do
            if station ~= nil and station:isValid() then
                if
                    station.expedition_fleet ~= nil
                    and #station.expedition_fleet > 0
                then
                    fleet_count = fleet_count + 1
                end
            else
                station_list[station_index] = station_list[#station_list]
                station_list[#station_list] = nil
                deleted_station = true
                break
            end
        end
        if not deleted_station then
            if fleet_count < expedition_count then
                if #station_list > expedition_count then
                    local avail_station = {}
                    for idx, station in ipairs(station_list) do
                        if
                            station.expedition_fleet == nil
                            or #station.expedition_fleet < 1
                        then
                            table.insert(avail_station, station)
                        end
                    end
                    local station =
                        avail_station[math.random(1, #avail_station)]
                    local selected_faction = station:getFaction()
                    local expedition_templates = {
                        "Phobos T3",
                        "Karnack",
                        ST.CRUISER,
                        "Gunship",
                        "Adv. Gunship",
                        "Phobos R2",
                        "Farco 3",
                        "Farco 5",
                        "Farco 8",
                        "Farco 11",
                        "Farco 13",
                        "Phobos T4",
                    }
                    local template = expedition_templates[math.random(
                        1,
                        #expedition_templates
                    )]
                    local pf_x, pf_y = station:getPosition()
                    local expedition_angle =
                        angleFromVectorNorth(center_x, center_y, pf_x, pf_y)
                    local pd_x, pd_y =
                        vectorFromAngleNorth(expedition_angle, 2000)
                    pd_x = pd_x + pf_x
                    pd_y = pd_y + pf_y
                    if expedition_maintenance_diagnostic then
                        print(
                            "expedition template:",
                            template,
                            "faction:",
                            selected_faction
                        )
                    end
                    local leader_ship = ship_template[template].create(
                        selected_faction,
                        template
                    )
                    leader_ship:setPosition(pd_x, pd_y)
                    leader_ship:setHeading(expedition_angle)
                    leader_ship:setCallSign(
                        generateCallSign(nil, leader_ship:getFaction())
                    )
                    leader_ship:orderRoaming()
                    local formation_spacing = 800
                    station.expedition_fleet = {}
                    leader_ship.home_station = station
                    leader_ship.home_station_name = station:getCallSign()
                    leader_ship:setCommsScript(""):setCommsFunction(commsShip)
                    table.insert(station.expedition_fleet, leader_ship)
                    local expedition_follower_templates = {
                        "MT52 Hornet",
                        "MU52 Hornet",
                        ST.FIGHTER,
                        "Ktlitan Fighter",
                        "K2 Fighter",
                        "K3 Fighter",
                        "Ktlitan Scout",
                        "Cucaracha",
                    }
                    template = expedition_follower_templates[math.random(
                        1,
                        #expedition_follower_templates
                    )]
                    local formation_list = { "Vac", "V", "V4", "A", "-", "X" }
                    local selected_formation =
                        formation_list[math.random(1, #formation_list)]
                    for idx, form in ipairs(fly_formation[selected_formation]) do
                        local ship = ship_template[template].create(
                            selected_faction,
                            template
                        )
                        local form_x, form_y = vectorFromAngleNorth(
                            expedition_angle + form.angle,
                            form.dist * formation_spacing
                        )
                        local form_prime_x, form_prime_y = vectorFromAngle(
                            form.angle,
                            form.dist * formation_spacing
                        )
                        ship:setFaction("Independent")
                        ship:setPosition(pd_x + form_x, pd_y + form_y)
                            :setHeading(expedition_angle)
                            :orderFlyFormation(
                                leader_ship,
                                form_prime_x,
                                form_prime_y
                            )
                        ship:setFaction(selected_faction)
                        ship:setCallSign(
                            generateCallSign(nil, ship:getFaction())
                        )
                        -- ship:setAcceleration(ship:getAcceleration()*1.1)
                        -- ship:setImpulseMaxSpeed(ship:getImpulseMaxSpeed()*1.1)
                        ship.home_station = station
                        ship.home_station_name = station:getCallSign()
                        ship:setCommsScript(""):setCommsFunction(commsShip)
                        table.insert(station.expedition_fleet, ship)
                    end
                end
            else
                for station_index, station in ipairs(station_list) do
                    fleet_count = 0
                    local deleted_ship = false
                    if
                        station.expedition_fleet ~= nil
                        and #station.expedition_fleet > 0
                    then
                        for fleet_index, ship in
                            ipairs(station.expedition_fleet)
                        do
                            if ship ~= nil and ship:isValid() then
                                fleet_count = fleet_count + 1
                            else
                                station.expedition_fleet[fleet_index] =
                                    station.expedition_fleet[#station.expedition_fleet]
                                station.expedition_fleet[#station.expedition_fleet] =
                                    nil
                                deleted_ship = true
                                break
                            end
                        end
                    end
                    if not deleted_ship then
                        if fleet_count < 1 then
                            station.expedition_fleet = nil
                        end
                    end
                end
            end
        end
    end
    maintenancePlot = taskMaintenance
end
function taskMaintenance(delta)
    if #station_list > 0 then
        local fleet_count = 0
        local deleted_station = false
        for station_index, station in ipairs(station_list) do
            if station ~= nil and station:isValid() then
                if station.task_fleet ~= nil and #station.task_fleet > 0 then
                    fleet_count = fleet_count + 1
                end
            else
                station_list[station_index] = station_list[#station_list]
                station_list[#station_list] = nil
                deleted_station = true
                break
            end
        end
        if not deleted_station then
            if fleet_count < task_force_count then
                if #station_list > task_force_count then
                    local avail_station = {}
                    for _, station in ipairs(station_list) do
                        if
                            station.task_fleet == nil
                            or #station.task_fleet < 1
                        then
                            for tsi, station_target in ipairs(station_list) do
                                if station:isEnemy(station_target) then
                                    table.insert(avail_station, station)
                                end
                            end
                        end
                    end
                    if #avail_station > 0 then
                        local station =
                            avail_station[math.random(1, #avail_station)]
                        local selected_faction = station:getFaction()
                        local task_templates = {
                            "Phobos T3",
                            "Karnack",
                            ST.CRUISER,
                            "Gunship",
                            "Adv. Gunship",
                            "Phobos R2",
                            "Farco 3",
                            "Farco 5",
                            "Farco 8",
                            "Farco 11",
                            "Farco 13",
                            "Phobos T4",
                        }
                        local template =
                            task_templates[math.random(1, #task_templates)]
                        local pf_x, pf_y = station:getPosition()
                        local target_station_list = {}
                        for _, target_station in ipairs(station_list) do
                            if station:isEnemy(target_station) then
                                table.insert(
                                    target_station_list,
                                    target_station
                                )
                            end
                        end
                        local target_station = target_station_list[math.random(
                            1,
                            #target_station_list
                        )]
                        local ts_x, ts_y = target_station:getPosition()
                        local task_angle =
                            angleFromVectorNorth(ts_x, ts_y, pf_x, pf_y)
                        local pd_x, pd_y =
                            vectorFromAngleNorth(task_angle, 2000)
                        pd_x = pd_x + pf_x
                        pd_y = pd_y + pf_y
                        if task_maintenance_diagnostic then
                            print(
                                "task template:",
                                template,
                                "faction:",
                                selected_faction
                            )
                        end
                        local leader_ship = ship_template[template].create(
                            selected_faction,
                            template
                        )
                        leader_ship:setPosition(pd_x, pd_y)
                        leader_ship:setHeading(task_angle)
                        leader_ship:setCallSign(
                            generateCallSign(nil, leader_ship:getFaction())
                        )
                        leader_ship:orderAttack(target_station)
                        local formation_spacing = 800
                        station.task_fleet = {}
                        table.insert(station.task_fleet, leader_ship)
                        local expedition_follower_templates = {
                            "MT52 Hornet",
                            "MU52 Hornet",
                            ST.FIGHTER,
                            "Ktlitan Fighter",
                            "K2 Fighter",
                            "K3 Fighter",
                            "Ktlitan Scout",
                            "Cucaracha",
                        }
                        template = expedition_follower_templates[math.random(
                            1,
                            #expedition_follower_templates
                        )]
                        local formation_list =
                            { "Vac", "V", "V4", "A", "-", "X" }
                        local selected_formation =
                            formation_list[math.random(1, #formation_list)]
                        for _, form in ipairs(fly_formation[selected_formation]) do
                            local ship = ship_template[template].create(
                                selected_faction,
                                template
                            )
                            local form_x, form_y = vectorFromAngleNorth(
                                task_angle + form.angle,
                                form.dist * formation_spacing
                            )
                            local form_prime_x, form_prime_y = vectorFromAngle(
                                form.angle,
                                form.dist * formation_spacing
                            )
                            ship:setFaction("Independent")
                            ship:setPosition(pd_x + form_x, pd_y + form_y)
                                :setHeading(task_angle)
                                :orderFlyFormation(
                                    leader_ship,
                                    form_prime_x,
                                    form_prime_y
                                )
                            ship:setFaction(selected_faction)
                            ship:setCallSign(
                                generateCallSign(nil, ship:getFaction())
                            )
                            -- ship:setAcceleration(ship:getAcceleration()*1.1)
                            -- ship:setImpulseMaxSpeed(ship:getImpulseMaxSpeed()*1.1)
                            table.insert(station.task_fleet, ship)
                        end
                    end
                end
            else
                for station_index, station in ipairs(station_list) do
                    fleet_count = 0
                    local deleted_ship = false
                    if
                        station.task_fleet ~= nil
                        and #station.task_fleet > 0
                    then
                        for fleet_index, ship in ipairs(station.task_fleet) do
                            if ship ~= nil and ship:isValid() then
                                fleet_count = fleet_count + 1
                            else
                                station.task_fleet[fleet_index] =
                                    station.task_fleet[#station.task_fleet]
                                station.task_fleet[#station.task_fleet] = nil
                                deleted_ship = true
                                break
                            end
                        end
                    end
                    if not deleted_ship then
                        if fleet_count < 1 then
                            station.task_fleet = nil
                        end
                    end
                end
            end
        end
    end
    maintenancePlot = transportCommerceMaintenance
end
function warpJammerMaintenance()
    if #warp_jammer_list > 0 then
        for wj_index, wj in ipairs(warp_jammer_list) do
            local set_default_range = false
            if wj ~= nil and wj:isValid() then
                if wj.reset_time ~= nil then
                    if getScenarioTime() > wj.reset_time then
                        if wj.range == nil then
                            wj.range = wj:getRange()
                            print(
                                "warp jammer did not have range value set, so setting it to current value:"
                            )
                            set_default_range = true
                        end
                        wj:setRange(wj.range)
                        wj.reset_time = nil
                        if set_default_range then
                            print("warp jammer call sign:", wj:getCallSign())
                        end
                    end
                end
            else
                warp_jammer_list[wj_index] = warp_jammer_list[#warp_jammer_list]
                warp_jammer_list[#warp_jammer_list] = nil
                break
            end
        end
    end
    maintenancePlot = defenseMaintenance
end

function updatePlayerUpgradeMission(p)
    if p.impulse_upgrade == 1 then
        if p.goods ~= nil then
            for good, good_quantity in pairs(p.goods) do
                if good == p.impulse_upgrade_part and good_quantity > 0 then
                    p:setImpulseMaxSpeed(85) --faster vs base 70 and upgraded 75
                    good_quantity = good_quantity - 1
                    p.impulse_upgrade = 2
                    local final_impulse_upgrade_msg = string.format(
                        _(
                            "upgrade-msgEngineer",
                            "With the %s just acquired, you improve your impulse engine top speed by 13%%"
                        ),
                        good
                    )
                    p.final_impulse_upgrade_msg_eng =
                        "final_impulse_upgrade_msg_eng"
                    p.final_impulse_upgrade_msg_plus =
                        "final_impulse_upgrade_msg_plus"
                    p:addCustomMessage(
                        "Engineering",
                        p.final_impulse_upgrade_msg_eng,
                        final_impulse_upgrade_msg
                    )
                    p:addCustomMessage(
                        "Engineering+",
                        p.final_impulse_upgrade_msg_plus,
                        final_impulse_upgrade_msg
                    )
                end
            end
        end
    end
    if p.shield_upgrade == 1 then
        if p.goods ~= nil then
            for good, good_quantity in pairs(p.goods) do
                if good == p.shield_upgrade_part and good_quantity > 0 then
                    p:setShieldsMax(100, 100) --stronger vs base 80,80 and upgraded 90,90
                    good_quantity = good_quantity - 1
                    p.shield_upgrade = 2
                    local final_shield_upgrade_msg = string.format(
                        _(
                            "upgrade-msgEngineer",
                            "With the %s just acquired, you improve your shield charge capacity top speed by 11%%"
                        ),
                        good
                    )
                    p.final_shield_upgrade_msg_eng =
                        "final_shield_upgrade_msg_eng"
                    p.final_shield_upgrade_msg_plus =
                        "final_shield_upgrade_msg_plus"
                    p:addCustomMessage(
                        "Engineering",
                        p.final_shield_upgrade_msg_eng,
                        final_shield_upgrade_msg
                    )
                    p:addCustomMessage(
                        "Engineering+",
                        p.final_shield_upgrade_msg_plus,
                        final_shield_upgrade_msg
                    )
                end
            end
        end
    end
    if p.tube_speed_upgrade == 1 then
        if p.goods ~= nil then
            for good, good_quantity in pairs(p.goods) do
                if good == p.tube_speed_upgrade_part and good_quantity > 0 then
                    p:setTubeLoadTime(0, 10) --faster vs base 20 and upgraded 15
                    p:setTubeLoadTime(1, 10) --faster vs base 20 and upgraded 15
                    good_quantity = good_quantity - 1
                    p.tube_speed_upgrade = 2
                    local final_tube_speed_upgrade_msg = string.format(
                        _(
                            "upgrade-msgEngineer",
                            "With the %s just acquired, you improve your weapon tube load time by 33%%"
                        ),
                        good
                    )
                    p.final_tube_speed_upgrade_msg_eng =
                        "final_tube_speed_upgrade_msg_eng"
                    p.final_tube_speed_upgrade_msg_plus =
                        "final_tube_speed_upgrade_msg_plus"
                    p:addCustomMessage(
                        "Engineering",
                        p.final_tube_speed_upgrade_msg_eng,
                        final_tube_speed_upgrade_msg
                    )
                    p:addCustomMessage(
                        "Engineering+",
                        p.final_tube_speed_upgrade_msg_plus,
                        final_tube_speed_upgrade_msg
                    )
                end
            end
        end
    end
end
function updatePlayerDangerZone(p)
    if danger_zones ~= nil then
        for index, zone in ipairs(danger_zones) do
            if zone:isInside(p) then
                if p.danger_zone == nil then
                    p.danger_zone = {}
                end
                if p.danger_zone[zone] == nil then
                    p.danger_zone[zone] = 0
                end
                p.danger_zone[zone] = p.danger_zone[zone] + 1
                if p.danger_zone[zone] > 3 then
                    p.danger_zone["verified"] = true
                    local hit_list = {}
                    if p:hasSystem("beamweapons") then
                        table.insert(hit_list, "beamweapons")
                    end
                    if p:hasSystem("missilesystem") then
                        table.insert(hit_list, "missilesystem")
                    end
                    if p:hasSystem("frontshield") then
                        table.insert(hit_list, "frontshield")
                    end
                    if p:hasSystem("rearshield") then
                        table.insert(hit_list, "rearshield")
                    end
                    local hit_system = hit_list[math.random(1, #hit_list)]
                    if zone.player_message_list == nil then
                        zone.player_message_list = {}
                    end
                    local long_system = {
                        ["beamweapons"] = _("msgScience", "beam weapons"),
                        ["missilesystem"] = _(
                            "msgScience",
                            "missile weapons system"
                        ),
                        ["frontshield"] = _("msgScience", "front shield"),
                        ["rearshield"] = _("msgScience", "rear shield"),
                    }
                    if zone.player_message_list[p] == nil then
                        local hit_msg = string.format(
                            _(
                                "energyField-msgScience&Operations",
                                "Sensors just picked up an energy field. The ship must have triggered it. It seems to impact our %s and possibly other ship systems. The ship computers have plotted it on Science and Relay."
                            ),
                            long_system[hit_system]
                        )
                        p.hit_msg_science = "hit_msg_science"
                        p:addCustomMessage(
                            "Science",
                            p.hit_msg_science,
                            hit_msg
                        )
                        p.hit_msg_ops = "hit_msg_ops"
                        p:addCustomMessage("Operations", p.hit_msg_ops, hit_msg)
                        zone.player_message_list[p] = "sent"
                    end
                    if
                        p:getSystemHealth(hit_system)
                        < p:getSystemHealthMax(hit_system)
                    then
                        if random(1, 100) < 20 then
                            p:setSystemHealthMax(
                                hit_system,
                                p:getSystemHealthMax(hit_system) * adverseEffect
                            )
                        else
                            p:setSystemHealth(
                                hit_system,
                                p:getSystemHealth(hit_system) * adverseEffect
                            )
                        end
                    else
                        p:setSystemHealth(
                            hit_system,
                            p:getSystemHealth(hit_system) * adverseEffect
                        )
                    end
                    zone:setColor(128, 0, 0)
                end
            else
                if p.danger_zone ~= nil then
                    if p.danger_zone[zone] ~= nil then
                        if not p.danger_zone["verified"] then
                            print(
                                p:getCallSign(),
                                "did not reach verification threshold. Count:",
                                p.danger_zone[zone],
                                "zone:",
                                zone
                            )
                        end
                        p.danger_zone[zone] = 0
                    end
                end
            end
        end
    end
end
function updateBarrierPatrols(delta)
    if barrier_patrols ~= nil then
        for index, ship in ipairs(barrier_patrols) do
            if ship:isValid() then
                ship.patrol_check_timer = ship.patrol_check_timer - delta
                if ship.patrol_check_timer < 0 then
                    if string.find(ship:getOrder(), "Defend") then
                        ship.patrol_point_index = ship.patrol_point_index + 1
                        if ship.patrol_point_index > #ship.patrol_points then
                            ship.patrol_point_index = 1
                        end
                        ship:orderFlyTowards(
                            ship.patrol_points[ship.patrol_point_index].x,
                            ship.patrol_points[ship.patrol_point_index].y
                        )
                    end
                    ship.patrol_check_timer = ship.patrol_check_timer_interval
                end
            else
                barrier_patrols[index] = barrier_patrols[#barrier_patrols]
                barrier_patrols[#barrier_patrols] = nil
                break
            end
        end
    end
end


-- Terrain and environment creation functions
--------------------------------
-- Station creation functions --
--------------------------------
function randomMineral(exclude)
    local good = mineralGoods[math.random(1, #mineralGoods)]
    if exclude == nil then
        return good
    else
        local count_repeat_loop = 0
        repeat
            good = mineralGoods[math.random(1, #mineralGoods)]
            count_repeat_loop = count_repeat_loop + 1
        until good ~= exclude or count_repeat_loop > max_repeat_loop
        if count_repeat_loop > max_repeat_loop then
            print("repeated too many times when trying to find a mineral good")
            print("good:", good, "exclude good:", exclude)
        end
        return good
    end
end
function randomComponent(exclude)
    local good = componentGoods[math.random(1, #componentGoods)]
    if exclude == nil then
        return good
    else
        local count_repeat_loop = 0
        repeat
            good = componentGoods[math.random(1, #componentGoods)]
            count_repeat_loop = count_repeat_loop + 1
        until good ~= exclude or count_repeat_loop > max_repeat_loop
        if count_repeat_loop > max_repeat_loop then
            print(
                "repeated too many times when trying to find a component good"
            )
            print("good:", good, "exclude good:", exclude)
        end
        return good
    end
end

---------------------------
-- Station communication --
---------------------------
local function addMedicalStationComms()
    if
        comms_target == station_medical_research
        and comms_source.medical_research == nil
    then
        addCommsReply(
            _("mission2ndBis-comms", "Request medical research for Fargalli"),
            function()
                comms_source.medical_research = true
                medical_research_obtained = true
                local upgrade_msg = ""
                if medical_message_diagnostic then
                    print("original upgrade message (blank):", upgrade_msg)
                end
                if comms_source.medical_station_upgrade ~= nil then
                    local fleet_count = 0
                    if pre_med_fleet ~= nil and #pre_med_fleet > 0 then
                        for _, ship in ipairs(pre_med_fleet) do
                            if ship ~= nil and ship:isValid() then
                                fleet_count = fleet_count + 1
                            end
                        end
                    end
                    if fleet_count < 1 then
                        if comms_source.medical_station_upgrade ~= "done" then
                            if
                                comms_source.medical_station_upgrade
                                == "impulse"
                            then
                                comms_source:setImpulseMaxSpeed(
                                    comms_source:getImpulseMaxSpeed() * 1.25
                                )
                                comms_source.medical_station_upgrade = "done"
                                upgrade_msg = _(
                                    "mission3th-comms",
                                    "We also upgraded your impulse engines."
                                )
                                if medical_message_diagnostic then
                                    print(
                                        "impulse upgrade message:",
                                        upgrade_msg
                                    )
                                end
                            end
                            if
                                comms_source.medical_station_upgrade
                                == "transit"
                            then
                                comms_source.rapid_return_transit = "ready"
                                comms_source.medical_station_upgrade = "done"
                                upgrade_msg = string.format(
                                    _(
                                        "mission3th-comms",
                                        "The technicians are standing by to transport you back to %s."
                                    ),
                                    station_regional_hq:getCallSign()
                                )
                                if medical_message_diagnostic then
                                    print(
                                        "transit upgrade message:",
                                        upgrade_msg
                                    )
                                end
                            end
                            if
                                comms_source.medical_station_upgrade == "beam"
                            then
                                local bi = 0
                                repeat
                                    local arc =
                                        comms_source:getBeamWeaponArc(bi)
                                    local dir =
                                        comms_source:getBeamWeaponDirection(bi)
                                    local rng =
                                        comms_source:getBeamWeaponRange(bi)
                                    local cyc =
                                        comms_source:getBeamWeaponCycleTime(bi)
                                    local dmg =
                                        comms_source:getBeamWeaponDamage(bi)
                                    comms_source:setBeamWeapon(
                                        bi,
                                        arc,
                                        dir,
                                        rng,
                                        cyc,
                                        dmg * 1.25
                                    )
                                    bi = bi + 1
                                until comms_source:getBeamWeaponRange(bi) < 1
                                comms_source.medical_station_upgrade = "done"
                                upgrade_msg = _(
                                    "mission3th-comms",
                                    "We also upgrded the damage your beams inflict."
                                )
                                if medical_message_diagnostic then
                                    print("beam upgrade message:", upgrade_msg)
                                end
                            end
                            if
                                comms_source.medical_station_upgrade
                                == "missile"
                            then
                                comms_source:setWeaponStorage(
                                    "Homing",
                                    comms_source:getWeaponStorageMax("Homing")
                                )
                                comms_source:setWeaponStorage(
                                    "Nuke",
                                    comms_source:getWeaponStorageMax("Nuke")
                                )
                                comms_source:setWeaponStorage(
                                    "EMP",
                                    comms_source:getWeaponStorageMax("EMP")
                                )
                                comms_source:setWeaponStorage(
                                    "Mine",
                                    comms_source:getWeaponStorageMax("Mine")
                                )
                                comms_source:setWeaponStorage(
                                    "HVLI",
                                    comms_source:getWeaponStorageMax("HVLI")
                                )
                                comms_source.medical_station_upgrade = "done"
                                upgrade_msg = _(
                                    "mission3th-comms",
                                    "We also replenished your ordnance."
                                )
                                if medical_message_diagnostic then
                                    print(
                                        "ordnance upgrade message:",
                                        upgrade_msg
                                    )
                                end
                            end
                            if
                                comms_source.medical_station_upgrade == "shield"
                            then
                                if comms_source:hasSystem("frontshield") then
                                    local front_shield_max =
                                        comms_source:getShieldMax(0)
                                    if comms_source:hasSystem("rearshield") then
                                        local rear_shield_max =
                                            comms_source:getShieldMax(1)
                                        comms_source:setShieldsMax(
                                            front_shield_max * 1.25,
                                            rear_shield_max * 1.25
                                        )
                                    else
                                        comms_source:setShieldsMax(
                                            front_shield_max * 1.25
                                        )
                                    end
                                    upgrade_msg = _(
                                        "mission3th-comms",
                                        "We also increased your shield charge capacity."
                                    )
                                    if medical_message_diagnostic then
                                        print(
                                            "shield upgrade message:",
                                            upgrade_msg
                                        )
                                    end
                                else
                                    comms_source:addReputationPoints(50)
                                end
                                comms_source.medical_station_upgrade = "done"
                            end
                            if
                                comms_source.medical_station_upgrade
                                == "maneuver"
                            then
                                comms_source:setRotationMaxSpeed(
                                    comms_source:getRotationMaxSpeed() * 1.25
                                )
                                comms_source.medical_station_upgrade = "done"
                                upgrade_msg = _(
                                    "mission3th-comms",
                                    "We also upgraded your maneuvering system."
                                )
                                if medical_message_diagnostic then
                                    print(
                                        "maneuver upgrade message:",
                                        upgrade_msg
                                    )
                                end
                            end
                            if
                                comms_source.medical_station_upgrade == "ftl"
                            then
                                if comms_source:hasSystem("warp") then
                                    comms_source:setWarpSpeed(
                                        comms_source:getWarpSpeed() * 1.25
                                    )
                                    upgrade_msg = _(
                                        "mission3th-comms",
                                        "We also upgraded your base warp speed."
                                    )
                                    if medical_message_diagnostic then
                                        print(
                                            "warp ftl upgrade message:",
                                            upgrade_msg
                                        )
                                    end
                                elseif comms_source:hasSystem("jumpdrive") then
                                    local max_charge =
                                        comms_source.max_jump_range
                                    if max_charge == nil then
                                        max_charge = 50000
                                    end
                                    comms_source:setJumpDriveCharge(
                                        max_charge * 3
                                    )
                                    upgrade_msg = _(
                                        "mission3th-comms",
                                        "We also overcharged your jump drive to three times your maximum range."
                                    )
                                    if medical_message_diagnostic then
                                        print(
                                            "jump ftl upgrade message:",
                                            upgrade_msg
                                        )
                                    end
                                else
                                    comms_source:addReputationPoints(50)
                                end
                                comms_source.medical_station_upgrade = "done"
                            end
                            if medical_message_diagnostic then
                                print(
                                    "upgrade message after completing the applicable upgrade:",
                                    upgrade_msg
                                )
                            end
                        end
                        if medical_message_diagnostic then
                            print(
                                "upgrade message after medical station upgrade not done check and process:",
                                upgrade_msg
                            )
                        end
                    end
                    if medical_message_diagnostic then
                        print(
                            "upgrade message after fleet count check and process:",
                            upgrade_msg
                        )
                    end
                end
                if medical_message_diagnostic then
                    print(
                        "upgrade message outside of medical station upgrade available check and process:",
                        upgrade_msg
                    )
                end
                setCommsMessage(
                    string.format(
                        _(
                            "mission2ndBis-comms",
                            "We have transmitted all of our current research on the Omicron plague including treatment fabrication instructions. We have also transported what we believe will cure any victims of the plague along with unique raw materials required to manufacture more of the treatment. I hope you are able get this to Ensign Fargalli in time. %s"
                        ),
                        upgrade_msg
                    )
                )
                if comms_source.rapid_return_transit ~= nil then
                    addCommsReply(
                        string.format(
                            _(
                                "mission3th-comms",
                                "Take return transit from %s to %s"
                            ),
                            station_medical_research:getCallSign(),
                            station_regional_hq:getCallSign()
                        ),
                        function()
                            comms_source:commandUndock()
                            local s_x, s_y = station_regional_hq:getPosition()
                            comms_source:setPosition(s_x, s_y)
                            setCommsMessage(
                                _("mission3th-comms", "Thanks for your help")
                            )
                        end
                    )
                end
                addCommsReply(_("Back"), commsStation)
            end
        )
    end
    if
        comms_target == station_regional_hq
        and medical_research_obtained
        and not plague_victim_treated
    then
        addCommsReply(
            _(
                "mission2ndBis-comms",
                "Give medical treatment and research to sickbay"
            ),
            function()
                if comms_source.medical_research then
                    setCommsMessage(
                        _(
                            "mission2ndBis-comms",
                            "Treatment received. Fargalli is expected to live. We are beginning to conduct in depth analysis of the research material with an eye to prevention of future infection."
                        )
                    )
                    plague_victim_treated = true
                else
                    setCommsMessage(
                        _(
                            "mission2ndBis-comms",
                            "The medical research and treatment is not aboard your ship"
                        )
                    )
                end
                addCommsReply(_("Back"), commsStation)
            end
        )
    end
end

local function showCurrentOrders()
    setOptionalOrders()
    setSecondaryOrders()
    ordMsg = primary_orders .. "\n" .. secondary_orders .. optional_orders
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
    require_docked = false,
    resources = { prompt = false },
    docked = {
        show_reputation = true,
        before = addMedicalStationComms,
        group_services = false,
        service_prompt = false,
        group_resources = false,
        before_resources = function()
            StationMenu.gossip(station_profile)
            StationMenu.currentOrders(station_profile, showCurrentOrders)
        end,
    },
    undocked = {
        cleanup_warp_jammers = true,
        warp_jammer_details = true,
        warp_jammer_details_context = "station-comms",
        warp_jammer_detail_order = {
            "friendly_friendly",
            "friendly_neutral",
            "friendly_enemy",
            "neutral_friendly",
            "enemy_friendly",
            "neutral_neutral",
            "enemy_neutral",
            "neutral_enemy",
            "enemy_enemy",
        },
        warp_jammer_back = false,
        waypoint_id = function(index)
            return index
        end,
        information = {
            prompt = _("station-comms", "What kind of information do you need?"),
            sections = {
                { kind = "orders", callback = showCurrentOrders },
                { kind = "location" },
                { kind = "ordnance" },
                { kind = "docking_status", status_repair_typo = true },
                { kind = "goods_available" },
                { kind = "goods_knowledge" },
                { kind = "gossip", gossip_roll = "half", back = false },
                { kind = "character" },
                { kind = "status" },
            },
        },
        assistance = true,
    },
}
function setSecondaryOrders()
    secondary_orders = ""
end
setOptionalOrders = MissionMenu.clearOptionalOrdersSnakeCase
function destroyPlagueComms()
    setCommsMessage(
        string.format(
            _(
                "mission4th-comms",
                "To: %s\nFrom: %s\n\nAfter treating Ensign Fargalli, we took a closer look at the accompanying research. Analysis of the research material, the telemetry from your ship, and recent reports from intelligence brings us to an ominous conclusion."
            ),
            comms_source:getCallSign(),
            comms_target:getCallSign()
        )
    )
    addCommsReply(_("mission4th-comms", "What have you concluded?"), function()
        setCommsMessage(
            _(
                "mission4th-comms",
                "Fargalli's illness and the previous similar cases experienced were not accidental. They were deliberately infected."
            )
        )
        addCommsReply(
            _("mission4th-comms", "What? Who infected them?"),
            function()
                setCommsMessage(
                    _(
                        "mission4th-comms",
                        "The Exuari. Fargalli and others are apparently the victims of a preliminary experimental biological attack. The Exuari have code named this biological agent Omicron after the early 21st century pandemic virus variant on Earth which was highly contagious."
                    )
                )
                addCommsReply(
                    _(
                        "mission4th-comms",
                        "That's sobering. Do we have more information?"
                    ),
                    function()
                        setCommsMessage(
                            _(
                                "mission4th-comms",
                                "Indeed we do. It looks like Omicron might be transmitted via subspace. We believe the Exuari plan to 'broadcast' Omicron to every known human location. Needless to say, this would have extinction level consequences."
                            )
                        )
                        addCommsReply(
                            _(
                                "mission4th-comms",
                                "Ouch. Is there a planned response?"
                            ),
                            function()
                                setCommsMessage(
                                    _(
                                        "mission4th-comms",
                                        "Destruction of the Exuari Omicron production and broadcast facility is the best thing we can think of."
                                    )
                                )
                                addCommsReply(
                                    _("mission4th-comms", "Can we help?"),
                                    function()
                                        setCommsMessage(
                                            _(
                                                "mission4th-comms",
                                                "We hope that you can. We don't know the precise location of the Exuari facility, just a general direction. However, when we examined the telemetry from your science officer's console when you were near the independent medical research facility, we noticed something interesting."
                                            )
                                        )
                                        addCommsReply(
                                            _(
                                                "mission4th-comms",
                                                "What did you notice?"
                                            ),
                                            function()
                                                setCommsMessage(
                                                    _(
                                                        "mission4th-comms",
                                                        "The entity used to produce the treatment is also likely to be used to create Omicron. It gives off a powerful bio-signature that is periodic in nature, vaguely resembling a heartbeat."
                                                    )
                                                )
                                                addCommsReply(
                                                    _(
                                                        "mission4th-comms",
                                                        "This signature can identify the Exuari Omicron facility?"
                                                    ),
                                                    function()
                                                        setCommsMessage(
                                                            string.format(
                                                                _(
                                                                    "mission4th-comms",
                                                                    "Yes, but if you're unsure, you are authorized to destroy every Exuari facility. You will need to travel into Exuari infested space along bearing %i from station %s to find the Omicron facility and destroy it. Our best intelligence estimates that deployment will occur within the next %i minutes. Happy hunting!"
                                                                ),
                                                                math.floor(
                                                                    plague_axis
                                                                ),
                                                                station_regional_hq:getCallSign(),
                                                                destroy_time_limit
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
    end)
end
function medicalAttentionComms()
    setCommsMessage(
        string.format(
            _(
                "mission2nd-comms",
                "To %s\nFrom: %s\n\nEnsign Fargalli, one of the maintenance engineers aboard the freighter %s, just reported to sickbay here on %s. We can treat his symptoms, but don't have a treatment for the root cause of his illness. This is the third case of this type we've seen in the last week. The last two ended up being fatal."
            ),
            comms_source:getCallSign(),
            comms_target:getCallSign(),
            critical_transport:getCallSign(),
            station_regional_hq:getCallSign()
        )
    )
    addCommsReply(
        _("mission2nd-comms", "Why are you telling me this?"),
        function()
            setCommsMessage(
                string.format(
                    _(
                        "mission2nd-comms",
                        "We've received word that Independent station %s is conducting ongoing research into this malady and may have more information, maybe even a remedy."
                    ),
                    station_medical_research:getCallSign()
                )
            )
            addCommsReply(
                string.format(
                    _(
                        "mission2nd-comms",
                        "Then you should get that treatment from %s to save Fargalli"
                    ),
                    station_medical_research:getCallSign()
                ),
                function()
                    setCommsMessage(
                        string.format(
                            _(
                                "mission2nd-comms",
                                "We can't contact %s directly since they are not on our communications network."
                            ),
                            station_medical_research:getCallSign()
                        )
                    )
                    addCommsReply(
                        _("mission2nd-comms", "A courier could get it"),
                        function()
                            setCommsMessage(
                                string.format(
                                    _(
                                        "mission2nd-comms",
                                        "We tried sending couriers. All of our couriers were shot down. We are telling you all this because we need you to go to %s and bring back any medical research or treatment or medicine they may have"
                                    ),
                                    station_medical_research:getCallSign()
                                )
                            )
                            addCommsReply(
                                _("mission2nd-comms", "Now I understand"),
                                function()
                                    setCommsMessage(
                                        string.format(
                                            _(
                                                "mission2nd-comms",
                                                "There is some urgency. Based on the previous cases, Fargalli has about %i minutes to live"
                                            ),
                                            rescue_time_limit
                                        )
                                    )
                                    addCommsReply(
                                        string.format(
                                            _(
                                                "mission2nd-comms",
                                                "Where is station %s?"
                                            ),
                                            station_medical_research:getCallSign()
                                        ),
                                        function()
                                            if difficulty < 1 then
                                                setCommsMessage(
                                                    string.format(
                                                        _(
                                                            "mission2nd-comms",
                                                            "%s is in sector %s. Good luck"
                                                        ),
                                                        station_medical_research:getCallSign(),
                                                        station_medical_research:getSectorName()
                                                    )
                                                )
                                            elseif difficulty > 1 then
                                                setCommsMessage(
                                                    string.format(
                                                        _(
                                                            "mission2nd-comms",
                                                            "%s is on an approximate bearing of %i from %s. Distance is greater than %.1f units."
                                                        ),
                                                        station_medical_research:getCallSign(),
                                                        math.floor(
                                                            research_axis
                                                        ),
                                                        station_regional_hq:getCallSign(),
                                                        average_station_circle_distance
                                                            / 1000
                                                    )
                                                )
                                            else
                                                local med_x, med_y =
                                                    station_medical_research:getPosition()
                                                local precise_bearing =
                                                    angleFromVectorNorth(
                                                        med_x,
                                                        med_y,
                                                        center_x,
                                                        center_y
                                                    )
                                                setCommsMessage(
                                                    string.format(
                                                        _(
                                                            "mission2nd-comms",
                                                            "%s is on a precise bearing of %.1f from %s. Distance is greater than %.1f units."
                                                        ),
                                                        station_medical_research:getCallSign(),
                                                        precise_bearing,
                                                        station_regional_hq:getCallSign(),
                                                        average_station_circle_distance
                                                            / 1000
                                                    )
                                                )
                                            end
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
function medicalBaseLocationAssistanceComms()
    setCommsMessage(
        string.format(
            _("mission3th-comms", "To: %s\nFrom: %s\n\nHello, %s"),
            comms_source:getCallSign(),
            station_medical_research:getCallSign(),
            comms_source:getCallSign()
        )
    )
    addCommsReply(
        string.format(
            _("mission3th-comms", "Hello, %s"),
            comms_target:getCallSign()
        ),
        function()
            setCommsMessage(
                _(
                    "mission3th-comms",
                    "One of the commercial freighters just docked up and their personnel inferred that you might be traveling in our direction."
                )
            )
            addCommsReply(
                _("mission3th-comms", "Those are well informed personnel"),
                function()
                    setCommsMessage(
                        _(
                            "mission3th-comms",
                            "It's amazing what commercial freighters learn and how quickly they learn it."
                        )
                    )
                    addCommsReply(
                        _(
                            "mission3th-comms",
                            "Indeed. Why are you contacting us?"
                        ),
                        function()
                            setCommsMessage(
                                _(
                                    "mission3th-comms",
                                    "We were wondering how soon you might get here. You see, there's this group of Exuari approaching and they don't look terribly friendly."
                                )
                            )
                            addCommsReply(
                                _(
                                    "mission3th-comms",
                                    "We intend to get medical research, not necessarily engage Exuari"
                                ),
                                function()
                                    setCommsMessage(
                                        _(
                                            "mission3th-comms",
                                            "We could make it worth your while if you were to protect our station from these Exuari."
                                        )
                                    )
                                    addCommsReply(
                                        _("mission3th-comms", "How so?"),
                                        function()
                                            setCommsMessage(
                                                _(
                                                    "mission3th-comms",
                                                    "If you were to destroy the attacking Exuari, we could offer you one of these:"
                                                )
                                            )
                                            addCommsReply(
                                                _(
                                                    "mission3th-comms",
                                                    "25% faster impulse speed"
                                                ),
                                                function()
                                                    comms_source.medical_station_upgrade =
                                                        "impulse"
                                                    setCommsMessage(
                                                        string.format(
                                                            _(
                                                                "mission3th-comms",
                                                                "You got it. We're in sector %s"
                                                            ),
                                                            station_medical_research:getSectorName()
                                                        )
                                                    )
                                                end
                                            )
                                            addCommsReply(
                                                string.format(
                                                    _(
                                                        "mission3th-comms",
                                                        "Rapid transit back to %s"
                                                    ),
                                                    station_regional_hq:getCallSign()
                                                ),
                                                function()
                                                    comms_source.medical_station_upgrade =
                                                        "transit"
                                                    setCommsMessage(
                                                        string.format(
                                                            _(
                                                                "mission3th-comms",
                                                                "You got it. We're in sector %s"
                                                            ),
                                                            station_medical_research:getSectorName()
                                                        )
                                                    )
                                                end
                                            )
                                            if
                                                comms_source:hasSystem(
                                                    "beamweapons"
                                                )
                                            then
                                                addCommsReply(
                                                    _(
                                                        "mission3th-comms",
                                                        "25% stronger beam weapons"
                                                    ),
                                                    function()
                                                        comms_source.medical_station_upgrade =
                                                            "beam"
                                                        setCommsMessage(
                                                            string.format(
                                                                _(
                                                                    "mission3th-comms",
                                                                    "You got it. We're in sector %s"
                                                                ),
                                                                station_medical_research:getSectorName()
                                                            )
                                                        )
                                                    end
                                                )
                                            end
                                            if
                                                comms_source:hasSystem(
                                                    "missilesystem"
                                                )
                                            then
                                                addCommsReply(
                                                    _(
                                                        "mission3th-comms",
                                                        "Replenish all your ordnance"
                                                    ),
                                                    function()
                                                        comms_source.medical_station_upgrade =
                                                            "missile"
                                                        setCommsMessage(
                                                            string.format(
                                                                _(
                                                                    "mission3th-comms",
                                                                    "You got it. We're in sector %s"
                                                                ),
                                                                station_medical_research:getSectorName()
                                                            )
                                                        )
                                                    end
                                                )
                                            end
                                        end
                                    )
                                    addCommsReply(
                                        _(
                                            "mission3th-comms",
                                            "We just need to know where you are located"
                                        ),
                                        function()
                                            if difficulty < 1 then
                                                local dsx, dsy =
                                                    station_medical_research:getPosition()
                                                comms_source:commandAddWaypoint(
                                                    dsx,
                                                    dsy
                                                )
                                                setCommsMessage(
                                                    string.format(
                                                        _(
                                                            "mission3th-comms",
                                                            "We added paypoint %i to your system which identifies our station. We may or may not be able to provide what you request depending on how busy we are fighting off Exuari."
                                                        ),
                                                        comms_source:getWaypointCount()
                                                    )
                                                )
                                            else
                                                setCommsMessage(
                                                    string.format(
                                                        _(
                                                            "mission3th-comms",
                                                            "We are in sector %s. We may or may not be able to provide what you request depending on how busy we are fighting off Exuari."
                                                        ),
                                                        station_medical_research:getSectorName()
                                                    )
                                                )
                                            end
                                        end
                                    )
                                end
                            )
                            addCommsReply(
                                _(
                                    "mission3th-comms",
                                    "Sounds bad. Do you need help?"
                                ),
                                function()
                                    setCommsMessage(
                                        _(
                                            "mission3th-comms",
                                            "We welcome any help you might provide. It would facilitate our survival."
                                        )
                                    )
                                    addCommsReply(
                                        _(
                                            "mission3th-comms",
                                            "Could you provide us with your location?"
                                        ),
                                        function()
                                            setCommsMessage(
                                                string.format(
                                                    _(
                                                        "mission3th-comms",
                                                        "You mean %s did not tell you where to find us?"
                                                    ),
                                                    station_regional_hq:getCallSign()
                                                )
                                            )
                                            if difficulty < 1 then
                                                addCommsReply(
                                                    _(
                                                        "mission3th-comms",
                                                        "They did, but we prefer greater precision"
                                                    ),
                                                    function()
                                                        local dsx, dsy =
                                                            station_medical_research:getPosition()
                                                        comms_source:commandAddWaypoint(
                                                            dsx,
                                                            dsy
                                                        )
                                                        setCommsMessage(
                                                            string.format(
                                                                _(
                                                                    "mission3th-comms",
                                                                    "We added waypoint %i to your system for our station. Your timely arrival would be greatly appreciated."
                                                                ),
                                                                comms_source:getWaypointCount()
                                                            )
                                                        )
                                                    end
                                                )
                                            else
                                                addCommsReply(
                                                    string.format(
                                                        _(
                                                            "mission3th-comms",
                                                            "%s provided a bearing, but we prefer greater precision"
                                                        ),
                                                        station_regional_hq:getCallSign()
                                                    ),
                                                    function()
                                                        setCommsMessage(
                                                            string.format(
                                                                _(
                                                                    "mission3th-comms",
                                                                    "We are in sector %s. Your timely arrival would be greatly appreciated."
                                                                ),
                                                                station_medical_research:getSectorName()
                                                            )
                                                        )
                                                    end
                                                )
                                            end
                                        end
                                    )
                                end
                            )
                        end
                    )
                end
            )
            addCommsReply(
                _("mission3th-comms", "Your information is correct"),
                function()
                    setCommsMessage(
                        _(
                            "mission3th-comms",
                            "That's great news. We've got some pesky Exuari in the area."
                        )
                    )
                    addCommsReply(
                        _(
                            "mission3th-comms",
                            "Let me guess, you want our help with the Exuari?"
                        ),
                        function()
                            setCommsMessage(
                                string.format(
                                    _(
                                        "mission3th-comms",
                                        "Got it in one. We're in sector %s. Please don't dawdle"
                                    ),
                                    station_medical_research:getSectorName()
                                )
                            )
                        end
                    )
                    addCommsReply(
                        _("mission3th-comms", "They're everywhere"),
                        function()
                            setCommsMessage(
                                _(
                                    "mission3th-comms",
                                    "This batch is in our back yard. If you're going to be in the neighborhood already, could you help us out?"
                                )
                            )
                            addCommsReply(
                                _("mission3th-comms", "Sure"),
                                function()
                                    setCommsMessage(
                                        string.format(
                                            _(
                                                "mission3th-comms",
                                                "Great. We're in sector %s"
                                            ),
                                            station_medical_research:getSectorName()
                                        )
                                    )
                                    comms_source.medical_station_upgrade =
                                        "shield"
                                end
                            )
                            addCommsReply(
                                _(
                                    "mission3th-comms",
                                    "We're really only coming to get medical research"
                                ),
                                function()
                                    setCommsMessage(
                                        _("mission3th-comms", "Understood.")
                                    )
                                end
                            )
                        end
                    )
                    addCommsReply(
                        _(
                            "mission3th-comms",
                            "Identify your sector and we'll help"
                        ),
                        function()
                            setCommsMessage(
                                string.format(
                                    _(
                                        "mission3th-comms",
                                        "Fair enough. We're in sector %s"
                                    ),
                                    station_medical_research:getSectorName()
                                )
                            )
                            comms_source.medical_station_upgrade = "maneuver"
                        end
                    )
                end
            )
            addCommsReply(
                _("mission3th-comms", "We might be. Why do you ask?"),
                function()
                    setCommsMessage(
                        _(
                            "mission3th-comms",
                            "Well, we've observed some Exuari headed our way. We don't think they're making a courtesy call"
                        )
                    )
                    addCommsReply(
                        _(
                            "mission3th-comms",
                            "They never do. Would you like our help?"
                        ),
                        function()
                            setCommsMessage(
                                string.format(
                                    _(
                                        "mission3th-comms",
                                        "Yes, please. We're in sector %s"
                                    ),
                                    station_medical_research:getSectorName()
                                )
                            )
                            comms_source.medical_station_upgrade = "ftl"
                        end
                    )
                    addCommsReply(
                        _("mission3th-comms", "Where exactly is 'your way?'"),
                        function()
                            setCommsMessage(
                                string.format(
                                    _(
                                        "mission3th-comms",
                                        "Our station is located in sector %s. We hope to see you soon."
                                    ),
                                    station_medical_research:getSectorName()
                                )
                            )
                        end
                    )
                    addCommsReply(
                        _(
                            "mission3th-comms",
                            "We'd like to help, but we're having a hard time finding you"
                        ),
                        function()
                            setCommsMessage(
                                string.format(
                                    _(
                                        "mission3th-comms",
                                        "We're in sector %s. Please hurry, the Exuari look dangerous."
                                    ),
                                    station_medical_research:getSectorName()
                                )
                            )
                            comms_source.medical_station_upgrade = "impulse"
                        end
                    )
                    addCommsReply(
                        _(
                            "mission3th-comms",
                            "Technically, our mission does not cover protection from Exuari"
                        ),
                        function()
                            setCommsMessage(_("mission3th-comms", "Drat"))
                        end
                    )
                end
            )
        end
    )
    addCommsReply(_("mission3th-comms", "Where are you located?"), function()
        setCommsMessage(
            string.format(
                _(
                    "mission3th-comms",
                    "We are in sector %s. Please hurry, the Exuari are approaching."
                ),
                station_medical_research:getSectorName()
            )
        )
    end)
    addCommsReply(
        _("mission3th-comms", "We are glad you contacted us"),
        function()
            setCommsMessage(
                _(
                    "mission3th-comms",
                    "Coincidentally, we are glad to be in contact with you, too."
                )
            )
            addCommsReply(_("mission3th-comms", "Why is that?"), function()
                setCommsMessage(
                    string.format(
                        _(
                            "mission3th-comms",
                            "We are in need of some assistance with Exuari that are approaching our station, %s."
                        ),
                        station_medical_research:getCallSign()
                    )
                )
                addCommsReply(_("mission3th-comms", "We can help"), function()
                    setCommsMessage(
                        _(
                            "mission3th-comms",
                            "That's so good to hear. You may want to hurry, though."
                        )
                    )
                    addCommsReply(
                        _("mission3th-comms", "Why the rush?"),
                        function()
                            if comms_source:getWaypointCount() >= 9 then
                                setCommsMessage(
                                    string.format(
                                        _(
                                            "mission3th-comms",
                                            "The Exuari! They're getting closer! Please come to us in sector %s as soon as you can."
                                        ),
                                        station_medical_research:getSectorName()
                                    )
                                )
                            else
                                local dsx, dsy =
                                    station_medical_research:getPosition()
                                comms_source:commandAddWaypoint(dsx, dsy)
                                setCommsMessage(
                                    string.format(
                                        _(
                                            "mission3th-comms",
                                            "The Exuari! They're getting closer! I'm adding waypoint %i into your system for our station. Please get here as soon as you can."
                                        ),
                                        comms_source:getWaypointCount()
                                    )
                                )
                            end
                        end
                    )
                    if random(1, 100) < 50 then
                        addCommsReply(
                            string.format(
                                _(
                                    "mission3th-comms",
                                    "In what sector is %s located?"
                                ),
                                station_medical_research:getCallSign()
                            ),
                            function()
                                setCommsMessage(
                                    string.format(
                                        _(
                                            "mission3th-comms",
                                            "%s is located in sector %s."
                                        ),
                                        station_medical_research:getCallSign(),
                                        station_medical_research:getSectorName()
                                    )
                                )
                            end
                        )
                        addCommsReply(
                            string.format(
                                _(
                                    "mission3th-comms",
                                    "In what sector is %s located?"
                                ),
                                station_regional_hq:getCallSign()
                            ),
                            function()
                                setCommsMessage(
                                    string.format(
                                        _(
                                            "mission3th-comms",
                                            "%s is located in sector %s."
                                        ),
                                        station_regional_hq:getCallSign(),
                                        station_regional_hq:getSectorName()
                                    )
                                )
                            end
                        )
                    else
                        addCommsReply(
                            string.format(
                                _(
                                    "mission3th-comms",
                                    "In what sector is %s located?"
                                ),
                                station_regional_hq:getCallSign()
                            ),
                            function()
                                setCommsMessage(
                                    string.format(
                                        _(
                                            "mission3th-comms",
                                            "%s is located in sector %s."
                                        ),
                                        station_regional_hq:getCallSign(),
                                        station_regional_hq:getSectorName()
                                    )
                                )
                            end
                        )
                        addCommsReply(
                            string.format(
                                _(
                                    "mission3th-comms",
                                    "In what sector is %s located?"
                                ),
                                station_medical_research:getCallSign()
                            ),
                            function()
                                setCommsMessage(
                                    string.format(
                                        _(
                                            "mission3th-comms",
                                            "%s is located in sector %s."
                                        ),
                                        station_medical_research:getCallSign(),
                                        station_medical_research:getSectorName()
                                    )
                                )
                            end
                        )
                    end
                end)
            end)
        end
    )
end
------------------------
-- Ship communication --
------------------------
ship_profile = {
    enemy = enemyComms,
    main_menu = commsShip,
}
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
        enemyStrength = math.max(danger * difficulty * playerPower(), 5)
    end
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
        return enemyList
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
    return enemyList
end
-- Mortal repair crew functions. Includes coolant loss as option to losing repair crew
--      Inventory button and functions for relay/operations
-- Generate call sign functions

--------------------------------------------------------------------------------------------
--  Additional enemy ships with some modifications from the original template parameters  --
--------------------------------------------------------------------------------------------
function farco3(enemyFaction)
    local ship = CpuShip():setFaction(enemyFaction):setTemplate(ST.PHOBOS_T3)
    ship:onTakingDamage(function(self, instigator)
        string.format("") --serious proton needs a global context
        if instigator ~= nil then
            self.damage_instigator = instigator
        end
    end)
    ship:setTypeName("Farco 3")
    ship:setShieldsMax(60, 40) --stronger shields (vs 50, 40)
    ship:setShields(60, 40)
    ship:setBeamWeapon(0, 90, -15, 1500, 5.0, 6.0) --longer (vs 1200), faster (vs 8)
    ship:setBeamWeapon(1, 90, 15, 1500, 5.0, 6.0)
    local farco_3_db = queryScienceDatabase("Ships", "Frigate", "Farco 3")
    if farco_3_db == nil then
        local frigate_db = queryScienceDatabase("Ships", "Frigate")
        if frigate_db ~= nil then --added for translation issues
            frigate_db:addEntry("Farco 3")
            farco_3_db = queryScienceDatabase("Ships", "Frigate", "Farco 3")
            addShipToDatabase(
                queryScienceDatabase("Ships", "Frigate", "Phobos T3"), --base ship database entry
                farco_3_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "The Farco models are evolutionary changes to the Phobos T3. In the case of the Farco 3, the beams are longer and faster and the shields are slightly stronger."
                ),
                {
                    { key = "Tube -1", value = "60 sec" }, --torpedo tube direction and load speed
                    { key = "Tube 1", value = "60 sec" }, --torpedo tube direction and load speed
                },
                nil --jump range
            )
        end
    end
    return ship
end
function farco5(enemyFaction)
    local ship = CpuShip():setFaction(enemyFaction):setTemplate(ST.PHOBOS_T3)
    ship:onTakingDamage(function(self, instigator)
        string.format("") --serious proton needs a global context
        if instigator ~= nil then
            self.damage_instigator = instigator
        end
    end)
    ship:setTypeName("Farco 5")
    ship:setShieldsMax(60, 40) --stronger shields (vs 50, 40)
    ship:setShields(60, 40)
    ship:setTubeLoadTime(0, 30) --faster (vs 60)
    ship:setTubeLoadTime(0, 30)
    local farco_5_db = queryScienceDatabase("Ships", "Frigate", "Farco 5")
    if farco_5_db == nil then
        local frigate_db = queryScienceDatabase("Ships", "Frigate")
        if frigate_db ~= nil then --added for translation issues
            frigate_db:addEntry("Farco 5")
            farco_5_db = queryScienceDatabase("Ships", "Frigate", "Farco 5")
            addShipToDatabase(
                queryScienceDatabase("Ships", "Frigate", "Phobos T3"), --base ship database entry
                farco_5_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "The Farco models are evolutionary changes to the Phobos T3. In the case of the Farco 5, the tubes load faster and the shields are slightly stronger."
                ),
                {
                    { key = "Tube -1", value = "30 sec" }, --torpedo tube direction and load speed
                    { key = "Tube 1", value = "30 sec" }, --torpedo tube direction and load speed
                },
                nil --jump range
            )
        end
    end
    return ship
end
function farco8(enemyFaction)
    local ship = CpuShip():setFaction(enemyFaction):setTemplate(ST.PHOBOS_T3)
    ship:onTakingDamage(function(self, instigator)
        string.format("") --serious proton needs a global context
        if instigator ~= nil then
            self.damage_instigator = instigator
        end
    end)
    ship:setTypeName("Farco 8")
    ship:setShieldsMax(80, 50) --stronger shields (vs 50, 40)
    ship:setShields(80, 50)
    ship:setBeamWeapon(0, 90, -15, 1500, 5.0, 6.0) --longer (vs 1200), faster (vs 8)
    ship:setBeamWeapon(1, 90, 15, 1500, 5.0, 6.0)
    ship:setTubeLoadTime(0, 30) --faster (vs 60)
    ship:setTubeLoadTime(0, 30)
    local farco_8_db = queryScienceDatabase("Ships", "Frigate", "Farco 8")
    if farco_8_db == nil then
        local frigate_db = queryScienceDatabase("Ships", "Frigate")
        if frigate_db ~= nil then --added for translation issues
            frigate_db:addEntry("Farco 8")
            farco_8_db = queryScienceDatabase("Ships", "Frigate", "Farco 8")
            addShipToDatabase(
                queryScienceDatabase("Ships", "Frigate", "Phobos T3"), --base ship database entry
                farco_8_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "The Farco models are evolutionary changes to the Phobos T3. In the case of the Farco 8, the beams are longer and faster, the tubes load faster and the shields are stronger."
                ),
                {
                    { key = "Tube -1", value = "30 sec" }, --torpedo tube direction and load speed
                    { key = "Tube 1", value = "30 sec" }, --torpedo tube direction and load speed
                },
                nil --jump range
            )
        end
    end
    return ship
end
function farco11(enemyFaction)
    local ship = CpuShip():setFaction(enemyFaction):setTemplate(ST.PHOBOS_T3)
    ship:onTakingDamage(function(self, instigator)
        string.format("") --serious proton needs a global context
        if instigator ~= nil then
            self.damage_instigator = instigator
        end
    end)
    ship:setTypeName("Farco 11")
    ship:setShieldsMax(80, 50) --stronger shields (vs 50, 40)
    ship:setShields(80, 50)
    ship:setRotationMaxSpeed(15) --faster maneuver (vs 10)
    ship:setBeamWeapon(0, 90, -15, 1500, 5.0, 6.0) --longer (vs 1200), faster (vs 8)
    ship:setBeamWeapon(1, 90, 15, 1500, 5.0, 6.0)
    ship:setBeamWeapon(2, 20, 0, 1800, 5.0, 4.0) --additional sniping beam
    local farco_11_db = queryScienceDatabase("Ships", "Frigate", "Farco 11")
    if farco_11_db == nil then
        local frigate_db = queryScienceDatabase("Ships", "Frigate")
        if frigate_db ~= nil then --added for translation issues
            frigate_db:addEntry("Farco 11")
            farco_11_db = queryScienceDatabase("Ships", "Frigate", "Farco 11")
            addShipToDatabase(
                queryScienceDatabase("Ships", "Frigate", "Phobos T3"), --base ship database entry
                farco_11_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "The Farco models are evolutionary changes to the Phobos T3. In the case of the Farco 11, the maneuver speed is faster, the beams are longer and faster, there's an added longer sniping beam and the shields are stronger."
                ),
                {
                    { key = "Tube -1", value = "60 sec" }, --torpedo tube direction and load speed
                    { key = "Tube 1", value = "60 sec" }, --torpedo tube direction and load speed
                },
                nil --jump range
            )
        end
    end
    return ship
end
function farco13(enemyFaction)
    local ship = CpuShip():setFaction(enemyFaction):setTemplate(ST.PHOBOS_T3)
    ship:onTakingDamage(function(self, instigator)
        string.format("") --serious proton needs a global context
        if instigator ~= nil then
            self.damage_instigator = instigator
        end
    end)
    ship:setTypeName("Farco 13")
    ship:setShieldsMax(90, 70) --stronger shields (vs 50, 40)
    ship:setShields(90, 70)
    ship:setRotationMaxSpeed(15) --faster maneuver (vs 10)
    ship:setBeamWeapon(0, 90, -15, 1500, 5.0, 6.0) --longer (vs 1200), faster (vs 8)
    ship:setBeamWeapon(1, 90, 15, 1500, 5.0, 6.0)
    ship:setBeamWeapon(2, 20, 0, 1800, 5.0, 4.0) --additional sniping beam
    ship:setTubeLoadTime(0, 30) --faster (vs 60)
    ship:setTubeLoadTime(0, 30)
    ship:setWeaponStorageMax("Homing", 16) --more (vs 6)
    ship:setWeaponStorage("Homing", 16)
    ship:setWeaponStorageMax("HVLI", 30) --more (vs 20)
    ship:setWeaponStorage("HVLI", 30)
    local farco_13_db = queryScienceDatabase("Ships", "Frigate", "Farco 13")
    if farco_13_db == nil then
        local frigate_db = queryScienceDatabase("Ships", "Frigate")
        if frigate_db ~= nil then --added for translation issues
            frigate_db:addEntry("Farco 13")
            farco_13_db = queryScienceDatabase("Ships", "Frigate", "Farco 13")
            addShipToDatabase(
                queryScienceDatabase("Ships", "Frigate", "Phobos T3"), --base ship database entry
                farco_13_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "The Farco models are evolutionary changes to the Phobos T3. In the case of the Farco 13, the maneuver speed is faster, the beams are longer and faster, there's an added longer sniping beam, the tubes load faster, there are more missiles and the shields are stronger."
                ),
                {
                    { key = "Tube -1", value = "30 sec" }, --torpedo tube direction and load speed
                    { key = "Tube 1", value = "30 sec" }, --torpedo tube direction and load speed
                },
                nil --jump range
            )
        end
    end
    return ship
end
function whirlwind(enemyFaction)
    local ship = CpuShip():setFaction(enemyFaction):setTemplate(ST.STORM)
    ship:onTakingDamage(function(self, instigator)
        string.format("") --serious proton needs a global context
        if instigator ~= nil then
            self.damage_instigator = instigator
        end
    end)
    ship:setTypeName("Whirlwind")
    ship:setWeaponTubeCount(9) --more (vs 5)
    ship:setWeaponTubeDirection(0, -90) --3 left, 3 right, 3 front (vs 5 front)
    ship:setWeaponTubeDirection(1, -92)
    ship:setWeaponTubeDirection(2, -88)
    ship:setWeaponTubeDirection(3, 90)
    ship:setWeaponTubeDirection(4, 92)
    ship:setWeaponTubeDirection(5, 88)
    ship:setWeaponTubeDirection(6, 0)
    ship:setWeaponTubeDirection(7, 2)
    ship:setWeaponTubeDirection(8, -2)
    ship:setWeaponStorageMax("Homing", 36) --more (vs 15)
    ship:setWeaponStorage("Homing", 36)
    ship:setWeaponStorageMax("HVLI", 36) --more (vs 15)
    ship:setWeaponStorage("HVLI", 36)
    local whirlwind_db = queryScienceDatabase("Ships", "Frigate", "Whirlwind")
    if whirlwind_db == nil then
        local frigate_db = queryScienceDatabase("Ships", "Frigate")
        if frigate_db ~= nil then --added for translation issues
            frigate_db:addEntry("Whirlwind")
            whirlwind_db = queryScienceDatabase("Ships", "Frigate", "Whirlwind")
            addShipToDatabase(
                queryScienceDatabase("Ships", "Frigate", "Storm"), --base ship database entry
                whirlwind_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "The Whirlwind, another heavy artillery cruiser, takes the Storm and adds tubes and missiles. It's as if the Storm swallowed a Pirahna and grew gills. Expect to see missiles, lots of missiles"
                ),
                {
                    { key = "Tube -90", value = "15 sec" }, --torpedo tube direction and load speed
                    { key = "Tube -92", value = "15 sec" }, --torpedo tube direction and load speed
                    { key = "Tube -88", value = "15 sec" }, --torpedo tube direction and load speed
                    { key = "Tube  90", value = "15 sec" }, --torpedo tube direction and load speed
                    { key = "Tube  92", value = "15 sec" }, --torpedo tube direction and load speed
                    { key = "Tube  88", value = "15 sec" }, --torpedo tube direction and load speed
                    { key = "Tube   0", value = "15 sec" }, --torpedo tube direction and load speed
                    { key = "Tube   2", value = "15 sec" }, --torpedo tube direction and load speed
                    { key = "Tube  -2", value = "15 sec" }, --torpedo tube direction and load speed
                },
                nil --jump range
            )
        end
    end
    return ship
end
function phobosR2(enemyFaction)
    local ship = CpuShip():setFaction(enemyFaction):setTemplate(ST.PHOBOS_T3)
    ship:onTakingDamage(function(self, instigator)
        string.format("") --serious proton needs a global context
        if instigator ~= nil then
            self.damage_instigator = instigator
        end
    end)
    ship:setTypeName("Phobos R2")
    ship:setWeaponTubeCount(1) --one tube (vs 2)
    ship:setWeaponTubeDirection(0, 0)
    ship:setImpulseMaxSpeed(55) --slower impulse (vs 60)
    ship:setRotationMaxSpeed(15) --faster maneuver (vs 10)
    local phobos_r2_db = queryScienceDatabase("Ships", "Frigate", "Phobos R2")
    if phobos_r2_db == nil then
        local frigate_db = queryScienceDatabase("Ships", "Frigate")
        if frigate_db ~= nil then --added for translation issues
            frigate_db:addEntry("Phobos R2")
            phobos_r2_db = queryScienceDatabase("Ships", "Frigate", "Phobos R2")
            addShipToDatabase(
                queryScienceDatabase("Ships", "Frigate", "Phobos T3"), --base ship database entry
                phobos_r2_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "The Phobos R2 model is very similar to the Phobos T3. It's got a faster turn speed, but only one missile tube"
                ),
                {
                    { key = "Tube 0", value = "60 sec" }, --torpedo tube direction and load speed
                },
                nil
            )
        end
    end
    return ship
end
function hornetMV52(enemyFaction)
    local ship = CpuShip():setFaction(enemyFaction):setTemplate(ST.MT52_HORNET)
    ship:onTakingDamage(function(self, instigator)
        string.format("") --serious proton needs a global context
        if instigator ~= nil then
            self.damage_instigator = instigator
        end
    end)
    ship:setTypeName("MV52 Hornet")
    ship:setBeamWeapon(0, 30, 0, 1000.0, 4.0, 3.0) --longer and stronger beam (vs 700 & 3)
    ship:setRotationMaxSpeed(31) --faster maneuver (vs 30)
    ship:setImpulseMaxSpeed(130) --faster impulse (vs 120)
    local hornet_mv52_db =
        queryScienceDatabase("Ships", "Starfighter", "MV52 Hornet")
    if hornet_mv52_db == nil then
        local starfighter_db = queryScienceDatabase("Ships", "Starfighter")
        if starfighter_db ~= nil then --added for translation issues
            starfighter_db:addEntry("MV52 Hornet")
            hornet_mv52_db =
                queryScienceDatabase("Ships", "Starfighter", "MV52 Hornet")
            addShipToDatabase(
                queryScienceDatabase("Ships", "Starfighter", "MT52 Hornet"), --base ship database entry
                hornet_mv52_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "The MV52 Hornet is very similar to the MT52 and MU52 models. The beam does more damage than both of the other Hornet models, it's max impulse speed is faster than both of the other Hornet models, it turns faster than the MT52, but slower than the MU52"
                ),
                nil,
                nil
            )
        end
    end
    return ship
end
function k2fighter(enemyFaction)
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.KTLITAN_FIGHTER)
        :setTypeName("K2 Fighter")
        :setBeamWeapon(0, 60, 0, 1200.0, 2.5, 6) --beams cycle faster (vs 4.0)
        :setHullMax(65) --weaker hull (vs 70)
        :setHull(65)
    local k2_fighter_db =
        queryScienceDatabase("Ships", "No Class", "K2 Fighter")
    if k2_fighter_db == nil then
        local no_class_db = queryScienceDatabase("Ships", "No Class")
        if no_class_db ~= nil then --added for translation issues
            no_class_db:addEntry("K2 Fighter")
            k2_fighter_db =
                queryScienceDatabase("Ships", "No Class", "K2 Fighter")
            addShipToDatabase(
                queryScienceDatabase("Ships", "No Class", "Ktlitan Fighter"), --base ship database entry
                k2_fighter_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "Enterprising designers published this design specification based on salvaged Ktlitan Fighters. Comparatively, it's got beams that cycle faster, but the hull is a bit weaker."
                ),
                nil,
                nil --jump range
            )
        end
    end
    return ship
end
function k3fighter(enemyFaction)
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.KTLITAN_FIGHTER)
        :setTypeName("K3 Fighter")
        :setBeamWeapon(0, 60, 0, 1200.0, 2.5, 9) --beams cycle faster and damage more (vs 4.0 & 6)
        :setHullMax(60) --weaker hull (vs 70)
        :setHull(60)
    local k3_fighter_db =
        queryScienceDatabase("Ships", "No Class", "K3 Fighter")
    if k3_fighter_db == nil then
        local no_class_db = queryScienceDatabase("Ships", "No Class")
        if no_class_db ~= nil then --added for translation issues
            no_class_db:addEntry("K3 Fighter")
            k3_fighter_db =
                queryScienceDatabase("Ships", "No Class", "K3 Fighter")
            addShipToDatabase(
                queryScienceDatabase("Ships", "No Class", "Ktlitan Fighter"), --base ship database entry
                k3_fighter_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "Enterprising designers published this design specification based on salvaged Ktlitan Fighters. Comparatively, it's got beams that are stronger and that cycle faster, but the hull is weaker."
                ),
                nil,
                nil --jump range
            )
        end
    end
    return ship
end
function waddle5(enemyFaction)
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.ADDER_MK5)
        :onTakingDamage(function(self, instigator)
            string.format("") --serious proton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Waddle 5")
        :setWarpDrive(true)
        :setBeamWeapon(2, 70, -30, 600, 5.0, 2.0) --adjust beam direction to match starboard side (vs -35)
    local waddle_5_db = queryScienceDatabase("Ships", "Starfighter", "Waddle 5")
    if waddle_5_db == nil then
        local starfighter_db = queryScienceDatabase("Ships", "Starfighter")
        if starfighter_db ~= nil then --added for translation issues
            starfighter_db:addEntry("Waddle 5")
            waddle_5_db =
                queryScienceDatabase("Ships", "Starfighter", "Waddle 5")
            addShipToDatabase(
                queryScienceDatabase("Ships", "Starfighter", "Adder MK5"), --base ship database entry
                waddle_5_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "Conversions R Us purchased a number of Adder MK 5 ships at auction and added warp drives to them to produce the Waddle 5"
                ),
                {
                    { key = "Small tube 0", value = "15 sec" }, --torpedo tube direction and load speed
                },
                nil --jump range
            )
        end
    end
    return ship
end
function jade5(enemyFaction)
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.ADDER_MK5)
        :onTakingDamage(function(self, instigator)
            string.format("") --SeriousProton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Jade 5")
        :setJumpDrive(true)
        :setJumpDriveRange(5000, 35000)
        :setBeamWeapon(2, 70, -30, 600, 5.0, 2.0) --adjust beam direction to match starboard side (vs -35)
    local jade_5_db = queryScienceDatabase("Ships", "Starfighter", "Jade 5")
    if jade_5_db == nil then
        local starfighter_db = queryScienceDatabase("Ships", "Starfighter")
        if starfighter_db ~= nil then --added for translation issues
            starfighter_db:addEntry("Jade 5")
            jade_5_db = queryScienceDatabase("Ships", "Starfighter", "Jade 5")
            addShipToDatabase(
                queryScienceDatabase("Ships", "Starfighter", "Adder MK5"), --base ship database entry
                jade_5_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "Conversions R Us purchased a number of Adder MK 5 ships at auction and added jump drives to them to produce the Jade 5"
                ),
                {
                    { key = "Small tube 0", value = "15 sec" }, --torpedo tube direction and load speed
                },
                "5 - 35 U" --jump range
            )
        end
    end
    return ship
end
function droneLite(enemyFaction)
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.KTLITAN_DRONE)
        :setTypeName("Lite Drone")
        :setHullMax(20) --weaker hull (vs 30)
        :setHull(20)
        :setImpulseMaxSpeed(130) --faster impulse (vs 120)
        :setRotationMaxSpeed(20) --faster maneuver (vs 10)
        :setBeamWeapon(0, 40, 0, 600, 4, 4) --weaker (vs 6) beam
    local drone_lite_db =
        queryScienceDatabase("Ships", "No Class", "Lite Drone")
    if drone_lite_db == nil then
        local no_class_db = queryScienceDatabase("Ships", "No Class")
        if no_class_db ~= nil then --added for translation issues
            no_class_db:addEntry("Lite Drone")
            drone_lite_db =
                queryScienceDatabase("Ships", "No Class", "Lite Drone")
            addShipToDatabase(
                queryScienceDatabase("Ships", "No Class", "Ktlitan Drone"), --base ship database entry
                drone_lite_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "The light drone was pieced together from scavenged parts of various damaged Ktlitan drones. Compared to the Ktlitan drone, the lite drone has a weaker hull, and a weaker beam, but a faster turn and impulse speed"
                ),
                nil,
                nil
            )
        end
    end
    return ship
end
function droneHeavy(enemyFaction)
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.KTLITAN_DRONE)
        :setTypeName("Heavy Drone")
        :setHullMax(40) --stronger hull (vs 30)
        :setHull(40)
        :setImpulseMaxSpeed(110) --slower impulse (vs 120)
        :setBeamWeapon(0, 40, 0, 600, 4, 8) --stronger (vs 6) beam
    local drone_heavy_db =
        queryScienceDatabase("Ships", "No Class", "Heavy Drone")
    if drone_heavy_db == nil then
        local no_class_db = queryScienceDatabase("Ships", "No Class")
        if no_class_db ~= nil then --added for translation issues
            no_class_db:addEntry("Heavy Drone")
            drone_heavy_db =
                queryScienceDatabase("Ships", "No Class", "Heavy Drone")
            addShipToDatabase(
                queryScienceDatabase("Ships", "No Class", "Ktlitan Drone"), --base ship database entry
                drone_heavy_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "The heavy drone has a stronger hull and a stronger beam than the normal Ktlitan Drone, but it also moves slower"
                ),
                nil,
                nil
            )
        end
    end
    return ship
end
function droneJacket(enemyFaction)
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.KTLITAN_DRONE)
        :onTakingDamage(function(self, instigator)
            string.format("") -- SeriousProton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Jacket Drone")
        :setShieldsMax(20) --stronger shields (vs none)
        :setShields(20)
        :setImpulseMaxSpeed(110) --slower impulse (vs 120)
        :setBeamWeapon(0, 40, 0, 600, 4, 4) --weaker (vs 6) beam
    local drone_jacket_db =
        queryScienceDatabase("Ships", "No Class", "Jacket Drone")
    if drone_jacket_db == nil then
        local no_class_db = queryScienceDatabase("Ships", "No Class")
        if no_class_db ~= nil then --added for translation issues
            no_class_db:addEntry("Jacket Drone")
            drone_jacket_db =
                queryScienceDatabase("Ships", "No Class", "Jacket Drone")
            addShipToDatabase(
                queryScienceDatabase("Ships", "No Class", "Ktlitan Drone"), --base ship database entry
                drone_jacket_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "The Jacket Drone is a Ktlitan Drone with a shield. It's also slightly slower and has a slightly weaker beam due to the energy requirements of the added shield"
                ),
                nil,
                nil
            )
        end
    end
    return ship
end
function wzLindworm(enemyFaction)
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.WX_LINDWORM)
        :setTypeName("WZ-Lindworm")
        :setWeaponStorageMax("Nuke", 2) --more nukes (vs 0)
        :setWeaponStorage("Nuke", 2)
        :setWeaponStorageMax("Homing", 4) --more homing (vs 1)
        :setWeaponStorage("Homing", 4)
        :setWeaponStorageMax("HVLI", 12) --more HVLI (vs 6)
        :setWeaponStorage("HVLI", 12)
        :setRotationMaxSpeed(12) --slower maneuver (vs 15)
        :setHullMax(45) --weaker hull (vs 50)
        :setHull(45)
    local wz_lindworm_db =
        queryScienceDatabase("Ships", "Starfighter", "WZ-Lindworm")
    if wz_lindworm_db == nil then
        local starfighter_db = queryScienceDatabase("Ships", "Starfighter")
        if starfighter_db ~= nil then --added for translation issues
            starfighter_db:addEntry("WZ-Lindworm")
            wz_lindworm_db =
                queryScienceDatabase("Ships", "Starfighter", "WZ-Lindworm")
            addShipToDatabase(
                queryScienceDatabase("Ships", "Starfighter", "WX-Lindworm"), --base ship database entry
                wz_lindworm_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "The WZ-Lindworm is essentially the stock WX-Lindworm with more HVLIs, more homing missiles and added nukes. They had to remove some of the armor to get the additional missiles to fit, so the hull is weaker. Also, the WZ turns a little more slowly than the WX. This little bomber packs quite a whallop."
                ),
                {
                    { key = "Small tube 0", value = "15 sec" }, --torpedo tube direction and load speed
                    { key = "Small tube 1", value = "15 sec" }, --torpedo tube direction and load speed
                    { key = "Small tube -1", value = "15 sec" }, --torpedo tube direction and load speed
                },
                nil
            )
        end
    end
    return ship
end
function tempest(enemyFaction)
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.PIRANHA_F12)
        :onTakingDamage(function(self, instigator)
            string.format("") -- SeriousProton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Tempest")
        :setWeaponTubeCount(10) --four more tubes (vs 6)
        :setWeaponTubeDirection(0, -88) --5 per side
        :setWeaponTubeDirection(1, -89) --slight angle spread
        :setWeaponTubeDirection(3, 88) --3 for HVLI each side
        :setWeaponTubeDirection(4, 89) --2 for homing and nuke each side
        :setWeaponTubeDirection(6, -91)
        :setWeaponTubeDirection(7, -92)
        :setWeaponTubeDirection(8, 91)
        :setWeaponTubeDirection(9, 92)
        :setWeaponTubeExclusiveFor(7, "HVLI")
        :setWeaponTubeExclusiveFor(9, "HVLI")
        :setWeaponStorageMax("Homing", 16) --more (vs 6)
        :setWeaponStorage("Homing", 16)
        :setWeaponStorageMax("Nuke", 8) --more (vs 0)
        :setWeaponStorage("Nuke", 8)
        :setWeaponStorageMax("HVLI", 34) --more (vs 20)
        :setWeaponStorage("HVLI", 34)
    local tempest_db = queryScienceDatabase("Ships", "Frigate", "Tempest")
    if tempest_db == nil then
        local frigate_db = queryScienceDatabase("Ships", "Frigate")
        if frigate_db ~= nil then --added for translation issues
            frigate_db:addEntry("Tempest")
            tempest_db = queryScienceDatabase("Ships", "Frigate", "Tempest")
            addShipToDatabase(
                queryScienceDatabase("Ships", "Frigate", "Piranha F12"), --base ship database entry
                tempest_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "Loosely based on the Piranha F12 model, the Tempest adds four more broadside tubes (two on each side), more HVLIs, more Homing missiles and 8 Nukes. The Tempest can strike fear into the hearts of your enemies. Get yourself one today!"
                ),
                {
                    { key = "Large tube -88", value = "15 sec" }, --torpedo tube direction and load speed
                    { key = "Tube -89", value = "15 sec" }, --torpedo tube direction and load speed
                    { key = "Large tube -90", value = "15 sec" }, --torpedo tube direction and load speed
                    { key = "Large tube 88", value = "15 sec" }, --torpedo tube direction and load speed
                    { key = "Tube 89", value = "15 sec" }, --torpedo tube direction and load speed
                    { key = "Large tube 90", value = "15 sec" }, --torpedo tube direction and load speed
                    { key = "Tube -91", value = "15 sec" }, --torpedo tube direction and load speed
                    { key = "Tube -92", value = "15 sec" }, --torpedo tube direction and load speed
                    { key = "Tube 91", value = "15 sec" }, --torpedo tube direction and load speed
                    { key = "Tube 92", value = "15 sec" }, --torpedo tube direction and load speed
                },
                nil
            )
        end
    end
    return ship
end
function enforcer(enemyFaction)
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.BLOCKADE_RUNNER)
        :onTakingDamage(function(self, instigator)
            string.format("") -- SeriousProton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Enforcer")
        :setRadarTrace("ktlitan_destroyer.png") --different radar trace
        :setWarpDrive(true) --warp (vs none)
        :setWarpSpeed(600)
        :setImpulseMaxSpeed(100) --faster impulse (vs 60)
        :setRotationMaxSpeed(20) --faster maneuver (vs 15)
        :setShieldsMax(200, 100, 100) --stronger shields (vs 100,150)
        :setShields(200, 100, 100)
        :setHullMax(100) --stronger hull (vs 70)
        :setHull(100)
        :setBeamWeapon(0, 30, 5, 1500, 6, 10) --narrower (vs 60), longer (vs 1000), stronger (vs 8)
        :setBeamWeapon(1, 30, -5, 1500, 6, 10)
        :setBeamWeapon(2, 0, 0, 0, 0, 0) --fewer (vs 4)
        :setBeamWeapon(3, 0, 0, 0, 0, 0)
        :setWeaponTubeCount(3) --more (vs 0)
        :setTubeSize(0, "large") --large (vs normal)
        :setWeaponTubeDirection(1, -15)
        :setWeaponTubeDirection(2, 15)
        :setTubeLoadTime(0, 18)
        :setTubeLoadTime(1, 12)
        :setTubeLoadTime(2, 12)
        :setWeaponStorageMax("Homing", 18) --more (vs 0)
        :setWeaponStorage("Homing", 18)
    local enforcer_db = queryScienceDatabase("Ships", "Frigate", "Enforcer")
    if enforcer_db == nil then
        local frigate_db = queryScienceDatabase("Ships", "Frigate")
        if frigate_db ~= nil then --added for translation issues
            frigate_db:addEntry("Enforcer")
            enforcer_db = queryScienceDatabase("Ships", "Frigate", "Enforcer")
            addShipToDatabase(
                queryScienceDatabase("Ships", "Frigate", "Blockade Runner"), --base ship database entry
                enforcer_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "The Enforcer is a highly modified Blockade Runner. A warp drive was added and impulse engines boosted along with turning speed. Three missile tubes were added to shoot homing missiles, large ones straight ahead. Stronger shields and hull. Removed rear facing beams and strengthened front beams."
                ),
                {
                    { key = "Large tube 0", value = "18 sec" }, --torpedo tube direction and load speed
                    { key = "Tube -15", value = "12 sec" }, --torpedo tube direction and load speed
                    { key = "Tube 15", value = "12 sec" }, --torpedo tube direction and load speed
                },
                nil
            )
            enforcer_db:setImage("radar/ktlitan_destroyer.png") --override default radar image
        end
    end
    return ship
end
function predator(enemyFaction)
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.PIRANHA_F8)
        :onTakingDamage(function(self, instigator)
            string.format("") --serious proton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Predator")
        :setShieldsMax(100, 100) --stronger shields (vs 30,30)
        :setShields(100, 100)
        :setHullMax(80) --stronger hull (vs 70)
        :setHull(80)
        :setImpulseMaxSpeed(65) --faster impulse (vs 40)
        :setRotationMaxSpeed(15) --faster maneuver (vs 6)
        :setJumpDrive(true)
        :setJumpDriveRange(5000, 35000)
        :setBeamWeapon(0, 90, 0, 1000, 6, 4) --more (vs 0)
        :setBeamWeapon(1, 90, 180, 1000, 6, 4)
        :setWeaponTubeCount(8) --more (vs 3)
        :setWeaponTubeDirection(0, -60)
        :setWeaponTubeDirection(1, -90)
        :setWeaponTubeDirection(2, -90)
        :setWeaponTubeDirection(3, 60)
        :setWeaponTubeDirection(4, 90)
        :setWeaponTubeDirection(5, 90)
        :setWeaponTubeDirection(6, -120)
        :setWeaponTubeDirection(7, 120)
        :setWeaponTubeExclusiveFor(0, "Homing")
        :setWeaponTubeExclusiveFor(1, "Homing")
        :setWeaponTubeExclusiveFor(2, "Homing")
        :setWeaponTubeExclusiveFor(3, "Homing")
        :setWeaponTubeExclusiveFor(4, "Homing")
        :setWeaponTubeExclusiveFor(5, "Homing")
        :setWeaponTubeExclusiveFor(6, "Homing")
        :setWeaponTubeExclusiveFor(7, "Homing")
        :setWeaponStorageMax("Homing", 32) --more (vs 5)
        :setWeaponStorage("Homing", 32)
        :setWeaponStorageMax("HVLI", 0) --less (vs 10)
        :setWeaponStorage("HVLI", 0)
        :setRadarTrace("missile_cruiser.png") --different radar trace
    local predator_db = queryScienceDatabase("Ships", "Frigate", "Predator")
    if predator_db == nil then
        local frigate_db = queryScienceDatabase("Ships", "Frigate")
        if frigate_db ~= nil then --added for translation issues
            frigate_db:addEntry("Predator")
            predator_db = queryScienceDatabase("Ships", "Frigate", "Predator")
            addShipToDatabase(
                queryScienceDatabase("Ships", "Frigate", "Piranha F8"), --base ship database entry
                predator_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "The Predator is a significantly improved Piranha F8. Stronger shields and hull, faster impulse and turning speeds, a jump drive, beam weapons, eight missile tubes pointing in six directions and a large number of homing missiles to shoot."
                ),
                {
                    { key = "Large tube -60", value = "12 sec" }, --torpedo tube direction and load speed
                    { key = "Tube -90", value = "12 sec" }, --torpedo tube direction and load speed
                    { key = "Large tube -90", value = "12 sec" }, --torpedo tube direction and load speed
                    { key = "Large tube 60", value = "12 sec" }, --torpedo tube direction and load speed
                    { key = "Tube 90", value = "12 sec" }, --torpedo tube direction and load speed
                    { key = "Large tube 90", value = "12 sec" }, --torpedo tube direction and load speed
                    { key = "Tube -120", value = "12 sec" }, --torpedo tube direction and load speed
                    { key = "Tube 120", value = "12 sec" }, --torpedo tube direction and load speed
                },
                "5 - 35 U" --jump range
            )
            predator_db:setImage("radar/missile_cruiser.png") --override default radar image
            predator_db:setModelDataName("HeavyCorvetteRed")
        end
    end
    return ship
end
function atlantisY42(enemyFaction)
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.ATLANTIS_X23)
        :onTakingDamage(function(self, instigator)
            string.format("") -- SeriousProton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Atlantis Y42")
        :setShieldsMax(300, 200, 300, 200) --stronger shields (vs 200,200,200,200)
        :setShields(300, 200, 300, 200)
        :setImpulseMaxSpeed(65) --faster impulse (vs 30)
        :setRotationMaxSpeed(15) --faster maneuver (vs 3.5)
        :setBeamWeapon(2, 80, 190, 1500, 6, 8) --narrower (vs 100)
        :setBeamWeapon(3, 80, 170, 1500, 6, 8) --extra (vs 3 beams)
        :setWeaponStorageMax("Homing", 16) --more (vs 4)
        :setWeaponStorage("Homing", 16)
    local atlantis_y42_db =
        queryScienceDatabase("Ships", "Corvette", "Atlantis Y42")
    if atlantis_y42_db == nil then
        local corvette_db = queryScienceDatabase("Ships", "Corvette")
        if corvette_db ~= nil then --added for translation issues
            corvette_db:addEntry("Atlantis Y42")
            atlantis_y42_db =
                queryScienceDatabase("Ships", "Corvette", "Atlantis Y42")
            addShipToDatabase(
                queryScienceDatabase("Ships", "Corvette", "Atlantis X23"), --base ship database entry
                atlantis_y42_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "The Atlantis Y42 improves on the Atlantis X23 with stronger shields, faster impulse and turn speeds, an extra beam in back and a larger missile stock"
                ),
                {
                    { key = "Tube -90", value = "10 sec" }, --torpedo tube direction and load speed
                    { key = " Tube -90", value = "10 sec" }, --torpedo tube direction and load speed
                    { key = "Tube 90", value = "10 sec" }, --torpedo tube direction and load speed
                    { key = " Tube 90", value = "10 sec" }, --torpedo tube direction and load speed
                },
                "5 - 50 U" --jump range
            )
        end
    end
    return ship
end
function starhammerV(enemyFaction)
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.STARHAMMER_II)
        :onTakingDamage(function(self, instigator)
            string.format("") -- SeriousProton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Starhammer V")
        :setImpulseMaxSpeed(65) --faster impulse (vs 35)
        :setRotationMaxSpeed(15) --faster maneuver (vs 6)
        :setShieldsMax(450, 350, 250, 250, 350) --stronger shields (vs 450, 350, 150, 150, 350)
        :setShields(450, 350, 250, 250, 350)
        :setBeamWeapon(4, 60, 180, 1500, 8, 11) --extra rear facing beam
        :setWeaponStorageMax("Homing", 16) --more (vs 4)
        :setWeaponStorage("Homing", 16)
        :setWeaponStorageMax("HVLI", 36) --more (vs 20)
        :setWeaponStorage("HVLI", 36)
    local starhammer_v_db =
        queryScienceDatabase("Ships", "Corvette", "Starhammer V")
    if starhammer_v_db == nil then
        local corvette_db = queryScienceDatabase("Ships", "Corvette")
        if corvette_db ~= nil then --added for translation issues
            corvette_db:addEntry("Starhammer V")
            starhammer_v_db =
                queryScienceDatabase("Ships", "Corvette", "Starhammer V")
            addShipToDatabase(
                queryScienceDatabase("Ships", "Corvette", "Starhammer II"), --base ship database entry
                starhammer_v_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "The Starhammer V recognizes common modifications made in the field to the Starhammer II: stronger shields, faster impulse and turning speeds, additional rear beam and more missiles to shoot. These changes make the Starhammer V a force to be reckoned with."
                ),
                {
                    { key = "Tube 0", value = "10 sec" }, --torpedo tube direction and load speed
                    { key = " Tube 0", value = "10 sec" }, --torpedo tube direction and load speed
                },
                "5 - 50 U" --jump range
            )
        end
    end
    return ship
end
function tyr(enemyFaction)
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.BATTLESTATION)
        :onTakingDamage(function(self, instigator)
            string.format("") -- SeriousProton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Tyr")
        :setImpulseMaxSpeed(50) --faster impulse (vs 30)
        :setRotationMaxSpeed(10) --faster maneuver (vs 1.5)
        :setShieldsMax(400, 300, 300, 400, 300, 300) --stronger shields (vs 300, 300, 300, 300, 300)
        :setShields(400, 300, 300, 400, 300, 300)
        :setHullMax(100) --stronger hull (vs 70)
        :setHull(100)
        :setBeamWeapon(0, 90, -60, 2500, 6, 8) --stronger beams, broader coverage
        :setBeamWeapon(1, 90, -120, 2500, 6, 8)
        :setBeamWeapon(2, 90, 60, 2500, 6, 8)
        :setBeamWeapon(3, 90, 120, 2500, 6, 8)
        :setBeamWeapon(4, 90, -60, 2500, 6, 8)
        :setBeamWeapon(5, 90, -120, 2500, 6, 8)
        :setBeamWeapon(6, 90, 60, 2500, 6, 8)
        :setBeamWeapon(7, 90, 120, 2500, 6, 8)
        :setBeamWeapon(8, 90, -60, 2500, 6, 8)
        :setBeamWeapon(9, 90, -120, 2500, 6, 8)
        :setBeamWeapon(10, 90, 60, 2500, 6, 8)
        :setBeamWeapon(11, 90, 120, 2500, 6, 8)
    local tyr_db = queryScienceDatabase("Ships", "Dreadnought", "Tyr")
    if tyr_db == nil then
        local corvette_db = queryScienceDatabase("Ships", "Dreadnought")
        if corvette_db ~= nil then --added for translation issues
            corvette_db:addEntry("Tyr")
            tyr_db = queryScienceDatabase("Ships", "Dreadnought", "Tyr")
            addShipToDatabase(
                queryScienceDatabase("Ships", "Dreadnought", "Battlestation"), --base ship database entry
                tyr_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "The Tyr is the shipyard's answer to admiral Konstatz' casual statement that the Battlestation model was too slow to be effective. The shipyards improved on the Battlestation by fitting the Tyr with more than twice the impulse speed and more than six times the turn speed. They threw in stronger shields and hull and wider beam coverage just to show that they could"
                ),
                nil,
                "5 - 50 U" --jump range
            )
        end
    end
    return ship
end
function gnat(enemyFaction)
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.KTLITAN_DRONE)
        :setTypeName("Gnat")
        :setHullMax(15) --weaker hull (vs 30)
        :setHull(15)
        :setImpulseMaxSpeed(140) --faster impulse (vs 120)
        :setRotationMaxSpeed(25) --faster maneuver (vs 10)
        :setBeamWeapon(0, 40, 0, 600, 4, 3) --weaker (vs 6) beam
    local gnat_db = queryScienceDatabase("Ships", "No Class", "Gnat")
    if gnat_db == nil then
        local no_class_db = queryScienceDatabase("Ships", "No Class")
        if no_class_db ~= nil then --added for translation issues
            no_class_db:addEntry("Gnat")
            gnat_db = queryScienceDatabase("Ships", "No Class", "Gnat")
            addShipToDatabase(
                queryScienceDatabase("Ships", "No Class", "Gnat"), --base ship database entry
                gnat_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "The Gnat is a nimbler version of the Ktlitan Drone. It's got half the hull, but it moves and turns faster"
                ),
                nil,
                nil --jump range
            )
        end
    end
    return ship
end
function cucaracha(enemyFaction)
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.APIS)
        :onTakingDamage(function(self, instigator)
            string.format("") --serious proton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Cucaracha")
        :setShieldsMax(200, 50, 50, 50, 50, 50) --stronger shields (vs 20)
        :setShields(200, 50, 50, 50, 50, 50)
        :setHullMax(100) --stronger hull (vs 50)
        :setHull(100)
        :setRotationMaxSpeed(20) --faster maneuver (vs 10)
        :setAcceleration(30) --faster acceleration (vs 15)
        :setBeamWeapon(0, 60, 0, 1500, 6, 10) --extra rear facing beam
    local cucaracha_db = queryScienceDatabase("Ships", "No Class", "Cucaracha")
    if cucaracha_db == nil then
        local no_class_db = queryScienceDatabase("Ships", "No Class")
        if no_class_db ~= nil then --added for translation issues
            no_class_db:addEntry("Cucaracha")
            cucaracha_db =
                queryScienceDatabase("Ships", "No Class", "Cucaracha")
            addShipToDatabase(
                queryScienceDatabase("Ships", "No Class", "Cucaracha"), --base ship database entry
                cucaracha_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "The Cucaracha is a quick ship built around the Tug model with heavy shields and a heavy beam designed to be difficult to squash"
                ),
                nil,
                nil --jump range
            )
        end
    end
    return ship
end
function starhammerIII(enemyFaction)
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.STARHAMMER_II)
        :onTakingDamage(function(self, instigator)
            string.format("") -- SeriousProton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Starhammer III")
        :setBeamWeapon(4, 60, 180, 1500, 8, 11) --extra rear facing beam
        :setTubeSize(0, "large")
        :setWeaponStorageMax("Homing", 16) --more (vs 4)
        :setWeaponStorage("Homing", 16)
        :setWeaponStorageMax("HVLI", 36) --more (vs 20)
        :setWeaponStorage("HVLI", 36)
    local starhammer_iii_db =
        queryScienceDatabase("Ships", "Corvette", "Starhammer III")
    if starhammer_iii_db == nil then
        local corvette_db = queryScienceDatabase("Ships", "Corvette")
        if corvette_db ~= nil then --added for translation issues
            corvette_db:addEntry("Starhammer III")
            starhammer_iii_db =
                queryScienceDatabase("Ships", "Corvette", "Starhammer III")
            addShipToDatabase(
                queryScienceDatabase("Ships", "Corvette", "Starhammer III"), --base ship database entry
                starhammer_iii_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "The designers of the Starhammer III took the Starhammer II and added a rear facing beam, enlarged one of the missile tubes and added more missiles to fire"
                ),
                {
                    { key = "Large tube 0", value = "10 sec" }, --torpedo tube direction and load speed
                    { key = "Tube 0", value = "10 sec" }, --torpedo tube direction and load speed
                },
                "5 - 50 U" --jump range
            )
        end
    end
    return ship
end
function k2breaker(enemyFaction)
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.KTLITAN_BREAKER)
        :onTakingDamage(function(self, instigator)
            string.format("") -- SeriousProton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("K2 Breaker")
        :setHullMax(200) --stronger hull (vs 120)
        :setHull(200)
        :setWeaponTubeCount(3) --more (vs 1)
        :setTubeSize(0, "large") --large (vs normal)
        :setWeaponTubeDirection(1, -30)
        :setWeaponTubeDirection(2, 30)
        :setWeaponTubeExclusiveFor(0, "HVLI") --only HVLI (vs any)
        :setWeaponStorageMax("Homing", 16) --more (vs 0)
        :setWeaponStorage("Homing", 16)
        :setWeaponStorageMax("HVLI", 8) --more (vs 5)
        :setWeaponStorage("HVLI", 8)
    local k2_breaker_db =
        queryScienceDatabase("Ships", "No Class", "K2 Breaker")
    if k2_breaker_db == nil then
        local no_class_db = queryScienceDatabase("Ships", "No Class")
        if no_class_db ~= nil then --added for translation issues
            no_class_db:addEntry("K2 Breaker")
            k2_breaker_db =
                queryScienceDatabase("Ships", "No Class", "K2 Breaker")
            addShipToDatabase(
                queryScienceDatabase("Ships", "No Class", "K2 Breaker"), --base ship database entry
                k2_breaker_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "The K2 Breaker designers took the Ktlitan Breaker and beefed up the hull, added two bracketing tubes, enlarged the center tube and added more missiles to shoot. Should be good for a couple of enemy ships"
                ),
                {
                    { key = "Large tube 0", value = "13 sec" }, --torpedo tube direction and load speed
                    { key = "Tube -30", value = "13 sec" }, --torpedo tube direction and load speed
                    { key = "Tube 30", value = "13 sec" }, --torpedo tube direction and load speed
                },
                nil
            )
        end
    end
    return ship
end
function hurricane(enemyFaction)
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.PIRANHA_F8)
        :onTakingDamage(function(self, instigator)
            string.format("") -- SeriousProton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Hurricane")
        :setJumpDrive(true)
        :setJumpDriveRange(5000, 40000)
        :setWeaponTubeCount(8) --more (vs 3)
        :setWeaponTubeExclusiveFor(1, "HVLI") --only HVLI (vs any)
        :setWeaponTubeDirection(1, 0) --forward (vs -90)
        :setTubeSize(3, "large")
        :setWeaponTubeDirection(3, -90)
        :setTubeSize(4, "small")
        :setWeaponTubeExclusiveFor(4, "Homing")
        :setWeaponTubeDirection(4, -15)
        :setTubeSize(5, "small")
        :setWeaponTubeExclusiveFor(5, "Homing")
        :setWeaponTubeDirection(5, 15)
        :setWeaponTubeExclusiveFor(6, "Homing")
        :setWeaponTubeDirection(6, -30)
        :setWeaponTubeExclusiveFor(7, "Homing")
        :setWeaponTubeDirection(7, 30)
        :setWeaponStorageMax("Homing", 24) --more (vs 5)
        :setWeaponStorage("Homing", 24)
    local hurricane_db = queryScienceDatabase("Ships", "Frigate", "Hurricane")
    if hurricane_db == nil then
        local frigate_db = queryScienceDatabase("Ships", "Frigate")
        if frigate_db ~= nil then --added for translation issues
            frigate_db:addEntry("Hurricane")
            hurricane_db = queryScienceDatabase("Ships", "Frigate", "Hurricane")
            addShipToDatabase(
                queryScienceDatabase("Ships", "Frigate", "Hurricane"), --base ship database entry
                hurricane_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "The Hurricane is designed to jump in and shower the target with missiles. It is based on the Piranha F8, but with a jump drive, five more tubes in various directions and sizes and lots more missiles to shoot"
                ),
                {
                    { key = "Large tube 0", value = "12 sec" }, --torpedo tube direction and load speed
                    { key = "Tube 0", value = "12 sec" }, --torpedo tube direction and load speed
                    { key = "Large tube 90", value = "12 sec" }, --torpedo tube direction and load speed
                    { key = "Large tube -90", value = "12 sec" }, --torpedo tube direction and load speed
                    { key = "Small tube -15", value = "12 sec" }, --torpedo tube direction and load speed
                    { key = "Small tube 15", value = "12 sec" }, --torpedo tube direction and load speed
                    { key = "Tube -30", value = "12 sec" }, --torpedo tube direction and load speed
                    { key = "Tube 30", value = "12 sec" }, --torpedo tube direction and load speed
                },
                "5 - 40 U" --jump range
            )
        end
    end
    return ship
end
function phobosT4(enemyFaction)
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.PHOBOS_T3)
        :onTakingDamage(function(self, instigator)
            string.format("") -- SeriousProton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Phobos T4")
        :setRotationMaxSpeed(20) --faster maneuver (vs 10)
        :setShieldsMax(80, 30) --stronger shields (vs 50,40)
        :setShields(80, 30)
        :setBeamWeapon(0, 90, -15, 1500, 6, 6) --longer (vs 1200), faster (vs 8)
        :setBeamWeapon(1, 90, 15, 1500, 6, 6)
    local phobos_t4_db = queryScienceDatabase("Ships", "Frigate", "Phobos T4")
    if phobos_t4_db == nil then
        local frigate_db = queryScienceDatabase("Ships", "Frigate")
        if frigate_db ~= nil then --added for translation issues
            frigate_db:addEntry("Phobos T4")
            phobos_t4_db = queryScienceDatabase("Ships", "Frigate", "Phobos T4")
            addShipToDatabase(
                queryScienceDatabase("Ships", "Frigate", "Phobos T3"), --base ship database entry
                phobos_t4_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    "The Phobos T4 makes some simple improvements on the Phobos T3: faster maneuver, stronger front shields, though weaker rear shields and longer and faster beam weapons"
                ),
                {
                    { key = "Tube -1", value = "60 sec" }, --torpedo tube direction and load speed
                    { key = "Tube 1", value = "60 sec" }, --torpedo tube direction and load speed
                },
                nil --jump range
            )
        end
    end
    return ship
end
function serviceJonque(enemyFaction)
    local ship = CpuShip()
        :setTemplate(ST.GARBAGE_JUMP_FREIGHTER_4)
    if enemyFaction ~= nil then
        ship:setFaction(enemyFaction)
    end
    ship:setTypeName("Service Jonque")
        :setCommsScript("")
        :setCommsFunction(commsServiceJonque)
    addFreighter("Service Jonque", ship) --update science database if applicable
    return ship
end
function genericFreighterScienceInfo(specific_freighter_db, base_db, ship)
    specific_freighter_db:setImage("radar/transport.png")
    specific_freighter_db:setKeyValue("Sub-class", "Freighter")
    specific_freighter_db:setKeyValue("Size", base_db:getKeyValue("Size"))
    local shields = ship:getShieldCount()
    if shields > 0 then
        local shield_string = ""
        for i = 1, shields do
            if shield_string == "" then
                shield_string =
                    string.format("%i", math.floor(ship:getShieldMax(i - 1)))
            else
                shield_string = string.format(
                    "%s/%i",
                    shield_string,
                    math.floor(ship:getShieldMax(i - 1))
                )
            end
        end
        specific_freighter_db:setKeyValue("Shield", shield_string)
    end
    specific_freighter_db:setKeyValue(
        "Hull",
        string.format("%i", math.floor(ship:getHullMax()))
    )
    specific_freighter_db:setKeyValue(
        "Move speed",
        string.format("%.1f u/min", ship:getImpulseMaxSpeed() * 60 / 1000)
    )
    specific_freighter_db:setKeyValue(
        "Turn speed",
        string.format("%.1f deg/sec", ship:getRotationMaxSpeed())
    )
    if ship:hasJumpDrive() then
        local base_jump_range = base_db:getKeyValue("Jump range")
        if base_jump_range ~= nil and base_jump_range ~= "" then
            specific_freighter_db:setKeyValue("Jump range", base_jump_range)
        else
            specific_freighter_db:setKeyValue("Jump range", "5 - 50 u")
        end
    end
    if ship:hasWarpDrive() then
        specific_freighter_db:setKeyValue(
            "Warp Speed",
            string.format("%.1f u/min", ship:getWarpSpeed() * 60 / 1000)
        )
    end
end
function addFreighters()
    local freighter_db = queryScienceDatabase("Ships", "Freighter")
    if freighter_db == nil then
        local ship_db = queryScienceDatabase("Ships")
        ship_db:addEntry("Freighter")
        freighter_db = queryScienceDatabase("Ships", "Freighter")
        freighter_db:setImage("radar/transport.png")
        freighter_db:setLongDescription(
            _(
                "scienceDB",
                "Small, medium and large scale transport ships. These are the working ships that keep commerce going in any sector. They may carry personnel, goods, cargo, equipment, garbage, fuel, research material, etc."
            )
        )
    end
    return freighter_db
end
function addFreighter(freighter_type, ship)
    local freighter_db = addFreighters()
    if freighter_type ~= nil then
        if freighter_type == "Space Sedan" then
            local space_sedan_db =
                queryScienceDatabase("Ships", "Freighter", "Space Sedan")
            if space_sedan_db == nil then
                freighter_db:addEntry("Space Sedan")
                space_sedan_db =
                    queryScienceDatabase("Ships", "Freighter", "Space Sedan")
                genericFreighterScienceInfo(
                    space_sedan_db,
                    queryScienceDatabase(
                        "Ships",
                        "Corvette",
                        "Personnel Jump Freighter 3"
                    ),
                    ship
                )
                space_sedan_db:setModelDataName("transport_1_3")
                space_sedan_db:setLongDescription(
                    "The Space Sedan was built around a surplus Personnel Jump Freighter 3. It's designed to provide relatively low cost transportation primarily for people, but there is also a limited amount of cargo space available"
                )
            end
        elseif freighter_type == "Omnibus" then
            local omnibus_db =
                queryScienceDatabase("Ships", "Freighter", "Omnibus")
            if omnibus_db == nil then
                freighter_db:addEntry("Omnibus")
                omnibus_db =
                    queryScienceDatabase("Ships", "Freighter", "Omnibus")
                genericFreighterScienceInfo(
                    omnibus_db,
                    queryScienceDatabase(
                        "Ships",
                        "Corvette",
                        "Personnel Jump Freighter 5"
                    ),
                    ship
                )
                omnibus_db:setModelDataName("transport_1_5")
                omnibus_db:setLongDescription(
                    "The Omnibus was designed from the Personnel Jump Freighter 5. It's made to transport large numbers of passengers of various types along with their luggage and any associated cargo"
                )
            end
        elseif freighter_type == "Service Jonque" then
            local service_jonque_db =
                queryScienceDatabase("Ships", "Freighter", "Service Jonque")
            if service_jonque_db == nil then
                freighter_db:addEntry("Service Jonque")
                service_jonque_db =
                    queryScienceDatabase("Ships", "Freighter", "Service Jonque")
                genericFreighterScienceInfo(
                    service_jonque_db,
                    queryScienceDatabase(
                        "Ships",
                        "Corvette",
                        "Equipment Jump Freighter 4"
                    ),
                    ship
                )
                service_jonque_db:setModelDataName("transport_4_4")
                service_jonque_db:setLongDescription(
                    _(
                        "scienceDB",
                        "The Service Jonque is a modified Equipment Jump Freighter 4. It's designed to carry spare parts and equipment as well as the necessary repair personnel to where it's needed to repair stations and ships"
                    )
                )
            end
        elseif freighter_type == "Courier" then
            local courier_db =
                queryScienceDatabase("Ships", "Freighter", "Courier")
            if courier_db == nil then
                freighter_db:addEntry("Courier")
                courier_db =
                    queryScienceDatabase("Ships", "Freighter", "Courier")
                genericFreighterScienceInfo(
                    courier_db,
                    queryScienceDatabase(
                        "Ships",
                        "Corvette",
                        "Personnel Freighter 1"
                    ),
                    ship
                )
                courier_db:setModelDataName("transport_1_1")
                courier_db:setLongDescription(
                    "The Courier is a souped up Personnel Freighter 1. It's made to deliver people and messages fast. Very fast"
                )
            end
        elseif freighter_type == "Work Wagon" then
            local work_wagon_db =
                queryScienceDatabase("Ships", "Freighter", "Work Wagon")
            if work_wagon_db == nil then
                freighter_db:addEntry("Work Wagon")
                work_wagon_db =
                    queryScienceDatabase("Ships", "Freighter", "Work Wagon")
                genericFreighterScienceInfo(
                    work_wagon_db,
                    queryScienceDatabase(
                        "Ships",
                        "Corvette",
                        "Equipment Freighter 2"
                    ),
                    ship
                )
                work_wagon_db:setModelDataName("transport_4_2")
                work_wagon_db:setLongDescription(
                    "The Work Wagon is a conversion of an Equipment Freighter 2 designed to carry equipment and parts where they are needed for repair or construction."
                )
            end
        elseif freighter_type == "Laden Lorry" then
            local laden_lorry_db =
                queryScienceDatabase("Ships", "Freighter", "Laden Lorry")
            if laden_lorry_db == nil then
                freighter_db:addEntry("Laden Lorry")
                laden_lorry_db =
                    queryScienceDatabase("Ships", "Freighter", "Laden Lorry")
                genericFreighterScienceInfo(
                    laden_lorry_db,
                    queryScienceDatabase(
                        "Ships",
                        "Corvette",
                        "Goods Freighter 3"
                    ),
                    ship
                )
                laden_lorry_db:setModelDataName("transport_2_3")
                laden_lorry_db:setLongDescription(
                    "As a side contract, Conversion R Us put together the Laden Lorry from some recently acquired Goods Freighter 3 hulls. The added warp drive makes for a more versatile goods carrying vessel."
                )
            end
        elseif freighter_type == "Physics Research" then
            local physics_research_db =
                queryScienceDatabase("Ships", "Freighter", "Physics Research")
            if physics_research_db == nil then
                freighter_db:addEntry("Physics Research")
                physics_research_db = queryScienceDatabase(
                    "Ships",
                    "Freighter",
                    "Physics Research"
                )
                genericFreighterScienceInfo(
                    physics_research_db,
                    queryScienceDatabase(
                        "Ships",
                        "Corvette",
                        "Garbage Freighter 3"
                    ),
                    ship
                )
                physics_research_db:setModelDataName("transport_3_3")
                physics_research_db:setLongDescription(
                    "Conversion R Us cleaned up and converted excess freighter hulls into Physics Research vessels. The reduced weight improved the impulse speed and maneuverability."
                )
            end
        end
    end
end

----------------------------------------------------------------------------------------
--  Additional player ships with modifications from the original template parameters  --
----------------------------------------------------------------------------------------
function createPlayerShipMixer()
    playerAmalgam = PlayerSpaceship()
        :setTemplate(ST.ATLANTIS)
        :setFaction("Human Navy")
        :setCallSign("Mixer")
    playerAmalgam:setTypeName("Amalgam")
    playerAmalgam:setRepairCrewCount(5) --more repair crew (vs 3)
    playerAmalgam.max_jump_range = 40000 --shorter (vs 50)
    playerAmalgam.min_jump_range = 4000 --shorter (vs 5)
    playerAmalgam:setJumpDriveRange(
        playerAmalgam.min_jump_range,
        playerAmalgam.max_jump_range
    )
    playerAmalgam:setJumpDriveCharge(playerAmalgam.max_jump_range)
    playerAmalgam:setImpulseMaxSpeed(80) --slower (vs 90)
    playerAmalgam:setRotationMaxSpeed(8) --slower (vs 10)
    playerAmalgam:setShieldsMax(150, 150) --weaker shields (vs 200)
    playerAmalgam:setShields(150, 150)
    playerAmalgam:setBeamWeapon(0, 90, -20, 1200, 6, 8) --narrower (vs 100), shorter (vs 1500)
    playerAmalgam:setBeamWeapon(1, 90, 20, 1200, 6, 8) --narrower (vs 100), shorter (vs 1500)
    playerAmalgam:setBeamWeapon(2, 10, -60, 1000, 4, 6) --additional beam
    playerAmalgam:setBeamWeapon(3, 10, 60, 1000, 4, 6) --additional beam
    playerAmalgam:setBeamWeaponTurret(2, 60, -60, 0.6)
    playerAmalgam:setBeamWeaponTurret(3, 60, 60, 0.6)
    playerAmalgam:setWeaponTubeCount(4) --2 fewer broadside, 1 extra mine (vs 5)
    playerAmalgam:setWeaponTubeDirection(1, 90) --mine tube points right (vs left)
    playerAmalgam:setWeaponTubeDirection(2, 180) --mine tube points back (vs right)
    playerAmalgam:setWeaponTubeDirection(3, 180) --mine tube points back (vs right)
    playerAmalgam:setWeaponTubeExclusiveFor(0, "Homing") --homing only (vs any)
    playerAmalgam:setWeaponTubeExclusiveFor(1, "Homing") --homing only (vs any)
    playerAmalgam:setWeaponTubeExclusiveFor(2, "Mine") --mine only (vs any)
    playerAmalgam:setWeaponTubeExclusiveFor(3, "Mine") --mine only (vs any)
    playerAmalgam:setTubeLoadTime(2, 16) --rear tube slower (vs 8)
    playerAmalgam:setTubeLoadTime(3, 16) --rear tube slower (vs 8)
    playerAmalgam:setTubeSize(0, "large") --left tube large (vs normal)
    playerAmalgam:setTubeSize(1, "large") --right tube large (vs normal)
    playerAmalgam:setWeaponStorageMax("Homing", 16) --more (vs 12)
    playerAmalgam:setWeaponStorage("Homing", 16)
    playerAmalgam:setWeaponStorageMax("Nuke", 0) --less (vs 4)
    playerAmalgam:setWeaponStorage("Nuke", 0)
    playerAmalgam:setWeaponStorageMax("Mine", 10) --more (vs 8)
    playerAmalgam:setWeaponStorage("Mine", 10)
    playerAmalgam:setWeaponStorageMax("EMP", 0) --less (vs 6)
    playerAmalgam:setWeaponStorage("EMP", 0)
    playerAmalgam:setWeaponStorageMax("HVLI", 0) --less (vs 20)
    playerAmalgam:setWeaponStorage("HVLI", 0)
    return playerAmalgam
end
function createPlayerShipFlipper()
    playerFlipper = PlayerSpaceship()
        :setTemplate(ST.AVALANCHE)
        :setFaction("Human Navy")
        :setCallSign("Flipper")
    playerFlipper:setTypeName("Midian")
    playerFlipper:setRadarTrace("cruiser.png") --different radar trace
    playerFlipper:setWarpSpeed(320)
    playerFlipper:setBeamWeapon(0, 50, -20, 1000, 6, 4) --beams (vs none)
    playerFlipper:setBeamWeapon(1, 50, 20, 1000, 6, 4)
    playerFlipper:setBeamWeapon(2, 10, 180, 1000, 6, 2)
    playerFlipper:setBeamWeaponTurret(2, 220, 180, 0.3)
    playerFlipper:setWeaponTubeCount(5) --fewer (vs 7)
    playerFlipper:setWeaponTubeDirection(0, -2) --angled (vs front)
    playerFlipper:setWeaponTubeDirection(1, 2) --angled (vs front)
    playerFlipper:setWeaponTubeDirection(2, -90) --left (vs right)
    playerFlipper:setWeaponTubeDirection(4, 180) --rear (vs left)
    playerFlipper:setTubeSize(0, "small") --small vs medium
    playerFlipper:setTubeSize(1, "small") --small vs medium
    playerFlipper:setWeaponTubeExclusiveFor(0, "Homing") --homing only
    playerFlipper:setWeaponTubeExclusiveFor(1, "Homing") --homing only
    playerFlipper:setWeaponTubeExclusiveFor(2, "HVLI")
    playerFlipper:setWeaponTubeExclusiveFor(3, "HVLI")
    playerFlipper:setWeaponTubeExclusiveFor(4, "Mine")
    playerFlipper:weaponTubeAllowMissle(2, "EMP")
    playerFlipper:weaponTubeAllowMissle(3, "EMP")
    playerFlipper:weaponTubeAllowMissle(2, "Nuke")
    playerFlipper:weaponTubeAllowMissle(3, "Nuke")
    playerFlipper:setTubeLoadTime(2, 12)
    playerFlipper:setTubeLoadTime(3, 12)
    playerFlipper:setTubeLoadTime(4, 15)
    playerFlipper:setWeaponStorageMax("Homing", 16) --less (vs 30)
    playerFlipper:setWeaponStorage("Homing", 16)
    playerFlipper:setWeaponStorageMax("Nuke", 2) --less (vs 8)
    playerFlipper:setWeaponStorage("Nuke", 2)
    playerFlipper:setWeaponStorageMax("EMP", 5) --less (vs 10)
    playerFlipper:setWeaponStorage("EMP", 5)
    playerFlipper:setWeaponStorageMax("Mine", 5) --less (vs 12)
    playerFlipper:setWeaponStorage("Mine", 5)
    playerFlipper:setWeaponStorageMax("HVLI", 16) --more (vs 0)
    playerFlipper:setWeaponStorage("HVLI", 16)
    playerFlipper.smallHomingOnly = true
    return playerFlipper
end
function createPlayerShipInk()
    playerInk = PlayerSpaceship()
        :setTemplate(ST.PIRANHA)
        :setFaction("Human Navy")
        :setCallSign("Ink")
    playerInk:setTypeName("Squid")
    playerInk:setRepairCrewCount(5) --more repair crew (vs 2)
    playerInk:setShieldsMax(100, 100) --stronger shields (vs 70, 70)
    playerInk:setShields(100, 100)
    playerInk:setHullMax(130) --stronger (vs 120)
    playerInk:setHull(130)
    playerInk.max_jump_range = 20000 --shorter than typical (vs 50)
    playerInk.min_jump_range = 2000 --shorter than typical (vs 5)
    playerInk:setJumpDriveRange(
        playerInk.min_jump_range,
        playerInk.max_jump_range
    )
    playerInk:setJumpDriveCharge(playerInk.max_jump_range)
    playerInk:setBeamWeapon(0, 10, 0, 1000, 4, 4) --one beam (vs 0)
    playerInk:setBeamWeaponTurret(0, 80, 0, 1) --slow turret
    playerInk:setWeaponTubeDirection(0, 0) --forward facing (vs left)
    playerInk:setWeaponTubeDirection(3, 0) --forward facing (vs right)
    playerInk:setTubeLoadTime(0, 12) --slower (vs 8)
    playerInk:setTubeLoadTime(3, 12) --slower (vs 8)
    playerInk:setWeaponTubeExclusiveFor(2, "Homing") --homing only (vs HVLI)
    playerInk:setWeaponTubeExclusiveFor(5, "Homing") --homing only (vs HVLI)
    playerInk:setTubeLoadTime(2, 10) --slower (vs 8)
    playerInk:setTubeLoadTime(5, 10) --slower (vs 8)
    playerInk:setTubeLoadTime(6, 15) --slower (vs 8)
    playerInk:setTubeLoadTime(7, 15) --slower (vs 8)
    playerInk:setWeaponTubeExclusiveFor(0, "HVLI") --HVLI only (vs Homing + HVLI)
    playerInk:setWeaponTubeExclusiveFor(3, "HVLI") --HVLI only (vs Homing + HVLI)
    playerInk:weaponTubeDisallowMissle(1, "Mine") --no sideways mines
    playerInk:weaponTubeDisallowMissle(4, "Mine") --no sideways mines
    playerInk:setWeaponStorageMax("HVLI", 10) --fewer HVLI (vs 20)
    playerInk:setWeaponStorage("HVLI", 10)
    playerInk:setWeaponStorageMax("Homing", 10) --fewer Homing (vs 12)
    playerInk:setWeaponStorage("Homing", 10)
    playerInk:setWeaponStorageMax("Mine", 6) --fewer mines (vs 8)
    playerInk:setWeaponStorage("Mine", 6)
    playerInk:setWeaponStorageMax("EMP", 4) --more EMPs (vs 0)
    playerInk:setWeaponStorage("EMP", 4)
    playerInk:setWeaponStorageMax("Nuke", 4) --fewer Nukes (vs 6)
    playerInk:setWeaponStorage("Nuke", 4)
    playerInk:setLongRangeRadarRange(25000) --shorter long range sensors (vs 30000)
    playerInk.normal_long_range_radar = 25000
    return playerInk
end
function createPlayerShipClaw()
    playerRaven = PlayerSpaceship()
        :setTemplate(ST.VINDICATOR)
        :setFaction("Human Navy")
        :setCallSign("Claw")
    playerRaven:setTypeName("Raven")
    playerRaven:setJumpDrive(false)
    playerRaven:setWarpDrive(true) --warp drive (vs jump)
    playerRaven:setWarpSpeed(300)
    playerRaven:setShieldsMax(100, 100) --stronger shields (vs 80, 80)
    playerRaven:setShields(100, 100)
    playerRaven:setHullMax(150) --weaker hull (vs 200)
    playerRaven:setHull(150)
    playerRaven:setBeamWeapon(0, 10, -90, 900, 6, 10) --left (vs front) shorter (vs 1000)
    playerRaven:setBeamWeapon(1, 10, 90, 900, 6, 10) --right (vs front) shorter (vs 1000)
    playerRaven:setBeamWeaponTurret(0, 90, -90, 1)
    playerRaven:setBeamWeaponTurret(1, 90, 90, 1)
    playerRaven:setWeaponTubeCount(6) --more (vs 3)
    playerRaven:setWeaponTubeDirection(0, -30) --more angled (vs -5)
    playerRaven:setWeaponTubeDirection(1, 30) --more angled (vs 5)
    playerRaven:setTubeSize(0, "small") --small (vs medium)
    playerRaven:setTubeSize(1, "small") --small (vs medium)
    playerRaven:setWeaponTubeExclusiveFor(0, "Nuke") --Nuke only (vs all but mine)
    playerRaven:setWeaponTubeExclusiveFor(1, "Nuke") --Nuke only (vs all but mine)
    playerRaven:setWeaponTubeDirection(2, -60)
    playerRaven:setWeaponTubeDirection(3, 60)
    playerRaven:setTubeSize(2, "small")
    playerRaven:setTubeSize(3, "small")
    playerRaven:setWeaponTubeExclusiveFor(2, "EMP")
    playerRaven:setWeaponTubeExclusiveFor(3, "EMP")
    playerRaven:setTubeLoadTime(4, 12) --slower (vs 8)
    playerRaven:setTubeSize(4, "large")
    playerRaven:setWeaponTubeExclusiveFor(4, "Homing")
    playerRaven:setWeaponTubeDirection(5, 180)
    playerRaven:setTubeLoadTime(5, 10) --slower (vs 8)
    playerRaven:setWeaponTubeExclusiveFor(5, "Mine")
    playerRaven:setWeaponStorageMax("Homing", 4) --less (vs 12)
    playerRaven:setWeaponStorage("Homing", 4)
    playerRaven:setWeaponStorageMax("EMP", 4) --less (vs 6)
    playerRaven:setWeaponStorage("EMP", 4)
    playerRaven:setWeaponStorageMax("Mine", 4) --less (vs 8)
    playerRaven:setWeaponStorage("Mine", 4)
    return playerRaven
end

function freighterMessage()
    if getScenarioTime() > 5 then
        local player_list = getActivePlayerShips()
        for index, p in ipairs(player_list) do
            if p.protect_freighter_message == nil then
                station_regional_hq:sendCommsMessage(
                    p,
                    string.format(
                        _(
                            "mission1st-incCall",
                            "To: %s\nFrom: %s\n\nGreetings %s,\n\nPlease ensure the safe arrival of freighter %s at %s. Looks like the Exuari might attack them."
                        ),
                        p:getCallSign(),
                        station_regional_hq:getCallSign(),
                        p:getCallSign(),
                        critical_transport:getCallSign(),
                        station_regional_hq:getCallSign()
                    )
                )
                p.protect_freighter_message = "sent"
            end
        end
        mainLinearPlot = checkFreighter
    end
end
function checkFreighter()
    if critical_transport == nil then
        loseGame(_("msgMainscreen", "The freighter blew up"))
    else
        if critical_transport:isValid() then
            if station_regional_hq == nil then
                loseGame(_("msgMainscreen", "Regional headquarters blew up"))
            else
                if station_regional_hq:isValid() then
                    if critical_transport:isDocked(station_regional_hq) then
                        local p = getPlayerShip(-1)
                        p:addReputationPoints(20)
                        freighter_saved = true
                        mainLinearPlot = freighterSafeMessage
                    end
                    if critical_transport.engine_trouble == nil then
                        if
                            distance(critical_transport, station_regional_hq)
                            < (5000 + (2500 * difficulty))
                        then
                            for pidx, p in ipairs(getActivePlayerShips()) do
                                critical_transport:sendCommsMessage(
                                    p,
                                    string.format(
                                        _(
                                            "incCall",
                                            "To: %s\nFrom: %s\n\n%s,\n\nOur engines just conked out and the only person we have that can fix them is too sick to work on them. Can you send over one of you repair crew to help us, please?"
                                        ),
                                        p:getCallSign(),
                                        critical_transport:getCallSign(),
                                        p:getCallSign()
                                    )
                                )
                                p.send_repair_crew_to_freighter_eng =
                                    "send_repair_crew_to_freighter_eng"
                                p:addCustomButton(
                                    "Engineering",
                                    p.send_repair_crew_to_freighter_eng,
                                    _(
                                        "crewTransfer-buttonEngineer",
                                        "Send Repair Crew"
                                    ),
                                    function()
                                        string.format("")
                                        sendRepairCrewToFreighter(p)
                                    end
                                )
                                p.send_repair_crew_to_freighter_plus =
                                    "send_repair_crew_to_freighter_plus"
                                p:addCustomButton(
                                    "Engineering+",
                                    p.send_repair_crew_to_freighter_plus,
                                    _(
                                        "crewTransfer-buttonEngineer+",
                                        "Send Repair Crew"
                                    ),
                                    function()
                                        string.format("")
                                        sendRepairCrewToFreighter(p)
                                    end
                                )
                                p.send_repair_crew_to_freighter_dmg =
                                    "send_repair_crew_to_freighter_dmg"
                                p:addCustomButton(
                                    "DamageControl",
                                    p.send_repair_crew_to_freighter_dmg,
                                    _(
                                        "crewTransfer-buttonDamageControl",
                                        "Send Repair Crew"
                                    ),
                                    function()
                                        string.format("")
                                        sendRepairCrewToFreighter(p)
                                    end
                                )
                            end
                            critical_transport:setSystemHealthMax(
                                "impulse",
                                0.01
                            )
                            critical_transport:setSystemHealthMax(
                                "jumpdrive",
                                0.01
                            )
                            critical_transport.engine_trouble = "disabled"
                        end
                    elseif critical_transport.engine_trouble == "in work" then
                        if
                            getScenarioTime()
                            > critical_transport.engine_repair_complete_timer
                        then
                            critical_transport:setSystemHealthMax("impulse", 1)
                            critical_transport:setSystemHealthMax(
                                "jumpdrive",
                                1
                            )
                            critical_transport:setSystemHealth("impulse", 1)
                            critical_transport:setSystemHealth("jumpdrive", 1)
                            critical_transport.engine_trouble = "fixed"
                            getPlayerShip(-1):addReputationPoints(20)
                            for pidx, p in ipairs(getActivePlayerShips()) do
                                p:addToShipLog(
                                    string.format(
                                        _(
                                            "shipLog",
                                            "The engines on %s have been repaired"
                                        ),
                                        critical_transport:getCallSign()
                                    ),
                                    "Magenta"
                                )
                            end
                        end
                    end
                else
                    loseGame(
                        _("msgMainscreen", "Regional headquarters blew up")
                    )
                end
            end
        else
            loseGame(_("msgMainscreen", "The freighter blew up"))
        end
    end
end
function getRepairCrewFromFreighter(p)
    if critical_transport:isValid() then
        if
            getScenarioTime() > critical_transport.engine_repair_complete_timer
        then
            if distance(critical_transport, p) < 3000 then
                if p:getShieldsActive() then
                    p.no_transport_through_shields_eng =
                        "no_transport_through_shields_eng"
                    p:addCustomMessage(
                        "Engineering",
                        p.no_transport_through_shields_eng,
                        string.format(
                            _(
                                "crewTransfer-msgEngineer",
                                "We cannot transport a repair crew member from %s while the shields are up."
                            ),
                            critical_transport:getCallSign()
                        )
                    )
                    p.no_transport_through_shields_plus =
                        "no_transport_through_shields_plus"
                    p:addCustomMessage(
                        "Engineering+",
                        p.no_transport_through_shields_plus,
                        string.format(
                            _(
                                "crewTransfer-msgEngineer+",
                                "We cannot transport a repair crew member from %s while the shields are up."
                            ),
                            critical_transport:getCallSign()
                        )
                    )
                else
                    local vx, vy = p:getVelocity()
                    local player_velocity = math.sqrt(
                        (math.abs(vx) * math.abs(vx))
                            + (math.abs(vy) * math.abs(vy))
                    )
                    if player_velocity > 1 then
                        p.too_fast_to_transport_eng =
                            "too_fast_to_transport_eng"
                        p:addCustomMessage(
                            "Engineering",
                            p.too_fast_to_transport_eng,
                            string.format(
                                _(
                                    "crewTransfer-msgEngineer",
                                    "%s is moving too fast to transport a repair crew member from %s."
                                ),
                                p:getCallSign(),
                                critical_transport:getCallSign()
                            )
                        )
                        p.too_fast_to_transport_plus =
                            "too_fast_to_transport_plus"
                        p:addCustomMessage(
                            "Engineering+",
                            p.too_fast_to_transport_plus,
                            string.format(
                                _(
                                    "crewTransfer-msgEngineer+",
                                    "%s is moving too fast to transport a repair crew member from %s."
                                ),
                                p:getCallSign(),
                                critical_transport:getCallSign()
                            )
                        )
                    else
                        p:setRepairCrewCount(p:getRepairCrewCount() + 1)
                        p.repair_crew_returned_eng = "repair_crew_returned_eng"
                        p:addCustomMessage(
                            "Engineering",
                            p.repair_crew_returned_eng,
                            string.format(
                                _(
                                    "crewTransfer-msgEngineer",
                                    "Repair crew member retrieved from %s"
                                ),
                                critical_transport:getCallSign()
                            )
                        )
                        p.repair_crew_returned_plus =
                            "repair_crew_returned_plus"
                        p:addCustomMessage(
                            "Engineering+",
                            p.repair_crew_returned_plus,
                            string.format(
                                _(
                                    "crewTransfer-msgEngineer+",
                                    "Repair crew member retrieved from %s"
                                ),
                                critical_transport:getCallSign()
                            )
                        )
                        for pidx2, p2 in ipairs(getActivePlayerShips()) do
                            p2:removeCustom(
                                p2.get_repair_crew_from_freighter_eng
                            )
                            p2:removeCustom(
                                p2.get_repair_crew_from_freighter_plus
                            )
                            p2:removeCustom(
                                p2.get_repair_crew_from_freighter_dmg
                            )
                        end
                    end
                end
            else
                p.too_far_from_transport_eng = "too_far_from_transport_eng"
                p:addCustomMessage(
                    "Engineering",
                    p.too_far_from_transport_eng,
                    string.format(
                        _(
                            "crewTransfer-msgEngineer",
                            "%s is too far from %s to transport a repair crew member. Functional transport may occur at or under 3 units"
                        ),
                        p:getCallSign(),
                        critical_transport:getCallSign()
                    )
                )
                p.too_far_from_transport_plus = "too_far_from_transport_plus"
                p:addCustomMessage(
                    "Engineering+",
                    p.too_far_from_transport_plus,
                    string.format(
                        _(
                            "crewTransfer-msgEngineer+",
                            "%s is too far from %s to transport a repair crew member. Functional transport may occur at or under 3 units"
                        ),
                        p:getCallSign(),
                        critical_transport:getCallSign()
                    )
                )
            end
        else
            critical_transport.engine_repair_complete_timer = critical_transport.engine_repair_complete_timer
                + 10
            local estimated_time_remaining = critical_transport.engine_repair_complete_timer
                - getScenarioTime()
            local minutes_remain = math.floor(estimated_time_remaining / 60)
            local seconds_remain = math.floor(estimated_time_remaining % 60)
            local remain_status = _(
                "repairs-msgEngineer",
                "Estimated time remaining on repairs: "
            )
            if minutes_remain < 1 then
                remain_status = string.format(
                    _("repairs-msgEngineer", "%s %i seconds"),
                    remain_status,
                    seconds_remain
                )
            else
                if minutes_remain > 1 then
                    remain_status = string.format(
                        _("repairs-msgEngineer", "%s %i minutes and %i seconds"),
                        remain_status,
                        minutes_remain,
                        seconds_remain
                    )
                else
                    remain_status = string.format(
                        _("repairs-msgEngineer", "%s %i minute and %i seconds"),
                        remain_status,
                        minutes_remain,
                        seconds_remain
                    )
                end
            end
            p.not_done_yet_eng = "not_done_yet_eng"
            p:addCustomMessage(
                "Engineering",
                p.not_done_yet_eng,
                string.format(
                    _(
                        "repairs-msgEngineer",
                        "[Repair Crewmember on %s]\nWe're not done with engine repairs on %s yet.\n%s."
                    ),
                    critical_transport:getCallSign(),
                    critical_transport:getCallSign(),
                    remain_status
                )
            )
            p.not_done_yet_plus = "not_done_yet_plus"
            p:addCustomMessage(
                "Engineering+",
                p.not_done_yet_plus,
                string.format(
                    _(
                        "repairs-msgEngineer",
                        "[Repair Crewmember on %s]\nWe're not done with engine repairs on %s yet.\n%s."
                    ),
                    critical_transport:getCallSign(),
                    critical_transport:getCallSign(),
                    remain_status
                )
            )
        end
    end
end
function sendRepairCrewToFreighter(p)
    if critical_transport:isValid() then
        if distance(critical_transport, p) < 3000 then
            if p:getShieldsActive() then
                p.no_transport_through_shields_eng =
                    "no_transport_through_shields_eng"
                p:addCustomMessage(
                    "Engineering",
                    p.no_transport_through_shields_eng,
                    string.format(
                        _(
                            "crewTransfer-msgEngineer",
                            "We cannot transport a repair crew member to %s while the shields are up."
                        ),
                        critical_transport:getCallSign()
                    )
                )
                p.no_transport_through_shields_plus =
                    "no_transport_through_shields_plus"
                p:addCustomMessage(
                    "Engineering+",
                    p.no_transport_through_shields_plus,
                    string.format(
                        _(
                            "crewTransfer-msgEngineer+",
                            "We cannot transport a repair crew member to %s while the shields are up."
                        ),
                        critical_transport:getCallSign()
                    )
                )
            else
                local vx, vy = p:getVelocity()
                local player_velocity = math.sqrt(
                    (math.abs(vx) * math.abs(vx))
                        + (math.abs(vy) * math.abs(vy))
                )
                if player_velocity > 1 then
                    p.too_fast_to_transport_eng = "too_fast_to_transport_eng"
                    p:addCustomMessage(
                        "Engineering",
                        p.too_fast_to_transport_eng,
                        string.format(
                            _(
                                "crewTransfer-msgEngineer",
                                "%s is moving too fast to transport a repair crew member to %s."
                            ),
                            p:getCallSign(),
                            critical_transport:getCallSign()
                        )
                    )
                    p.too_fast_to_transport_plus = "too_fast_to_transport_plus"
                    p:addCustomMessage(
                        "Engineering+",
                        p.too_fast_to_transport_plus,
                        string.format(
                            _(
                                "crewTransfer-msgEngineer+",
                                "%s is moving too fast to transport a repair crew member to %s."
                            ),
                            p:getCallSign(),
                            critical_transport:getCallSign()
                        )
                    )
                else
                    if p:getRepairCrewCount() > 0 then
                        p:setRepairCrewCount(p:getRepairCrewCount() - 1)
                        critical_transport.engine_repair_complete_timer = getScenarioTime()
                            + 90
                        critical_transport.engine_trouble = "in work"
                        for pidx, p2 in ipairs(getActivePlayerShips()) do
                            p2:addToShipLog(
                                string.format(
                                    _(
                                        "crewTransfer-shipLog",
                                        "%s has transported one of her repair crew to %s. They report that the engines should be fixed in a minute or two."
                                    ),
                                    p:getCallSign(),
                                    critical_transport:getCallSign()
                                ),
                                "Magenta"
                            )
                            p2:removeCustom(
                                p2.send_repair_crew_to_freighter_eng
                            )
                            p2:removeCustom(
                                p2.send_repair_crew_to_freighter_plus
                            )
                            p2:removeCustom(
                                p2.send_repair_crew_to_freighter_dmg
                            )
                            p2.get_repair_crew_from_freighter_eng =
                                "get_repair_crew_from_freighter_eng"
                            p2:addCustomButton(
                                "Engineering",
                                p2.get_repair_crew_from_freighter_eng,
                                _(
                                    "crewTransfer-buttonEngineer",
                                    "Get Repair Crew"
                                ),
                                function()
                                    string.format("")
                                    getRepairCrewFromFreighter(p2)
                                end
                            )
                            p2.get_repair_crew_from_freighter_plus =
                                "get_repair_crew_from_freighter_plus"
                            p2:addCustomButton(
                                "Engineering+",
                                p2.get_repair_crew_from_freighter_plus,
                                _(
                                    "crewTransfer-buttonEngineer+",
                                    "Get Repair Crew"
                                ),
                                function()
                                    string.format("")
                                    getRepairCrewFromFreighter(p2)
                                end
                            )
                            p2.get_repair_crew_from_freighter_dmg =
                                "get_repair_crew_from_freighter_dmg"
                            p2:addCustomButton(
                                "DamageControl",
                                p2.get_repair_crew_from_freighter_dmg,
                                _(
                                    "crewTransfer-buttonEngineer+",
                                    "Get Repair Crew"
                                ),
                                function()
                                    string.format("")
                                    getRepairCrewFromFreighter(p2)
                                end
                            )
                        end
                    else
                        p.not_enough_repair_crew_eng =
                            "not_enough_repair_crew_eng"
                        p:addCustomMessage(
                            "Engineering",
                            p.not_enough_repair_crew_eng,
                            string.format(
                                _(
                                    "crewTransfer-msgEngineer",
                                    "We don't have any repair crew to send over to %s. We might get one from %s"
                                ),
                                critical_transport:getCallSign(),
                                station_regional_hq:getCallSign()
                            )
                        )
                        p.not_enough_repair_crew_plus =
                            "not_enough_repair_crew_plus"
                        p:addCustomMessage(
                            "Engineering+",
                            p.not_enough_repair_crew_plus,
                            string.format(
                                _(
                                    "crewTransfer-msgEngineer+",
                                    "We don't have any repair crew to send over to %s. We might get one from %s"
                                ),
                                critical_transport:getCallSign(),
                                station_regional_hq:getCallSign()
                            )
                        )
                    end
                end
            end
        else
            p.too_far_from_transport_eng = "too_far_from_transport_eng"
            p:addCustomMessage(
                "Engineering",
                p.too_far_from_transport_eng,
                string.format(
                    _(
                        "crewTransfer-msgEngineer",
                        "%s is too far from %s to transport a repair crew member. Functional transport may occur at or under 3 units"
                    ),
                    p:getCallSign(),
                    critical_transport:getCallSign()
                )
            )
            p.too_far_from_transport_plus = "too_far_from_transport_plus"
            p:addCustomMessage(
                "Engineering+",
                p.too_far_from_transport_plus,
                string.format(
                    _(
                        "crewTransfer-msgEngineer+",
                        "%s is too far from %s to transport a repair crew member. Functional transport may occur at or under 3 units"
                    ),
                    p:getCallSign(),
                    critical_transport:getCallSign()
                )
            )
        end
    end
end
function freighterSafeMessage()
    local player_list = getActivePlayerShips()
    local ship_type = critical_transport:getTypeName()
    local activity = _("mission1st-comms", "unloading cargo")
    if ship_type:find("Garbage") ~= nil then
        activity = _("mission1st-comms", "picking up cargo")
    elseif ship_type:find("Personnel") ~= nil then
        activity = _("mission1st-comms", "disembarking passengers")
    end
    for index, p in ipairs(player_list) do
        if p.freighter_safe_message == nil then
            station_regional_hq:sendCommsMessage(
                p,
                string.format(
                    _(
                        "mission1st-incCall",
                        "To: %s\nFrom: %s\n\nHello %s,\n\nFreighter %s has safely docked and is %s. Thanks for your assistance."
                    ),
                    p:getCallSign(),
                    station_regional_hq:getCallSign(),
                    p:getCallSign(),
                    critical_transport:getCallSign(),
                    activity
                )
            )
            p.freighter_safe_message = "sent"
        end
    end
    medical_message_milestone = getScenarioTime() + 30
    primary_orders = string.format(
        _(
            "orders-comms",
            "Protect station %s and other friendly stations and ships"
        ),
        station_regional_hq:getCallSign()
    )
    mainLinearPlot = medicalAttention
end
function medicalAttention(delta)
    if getScenarioTime() > medical_message_milestone then
        local all_hailed = true
        if guaranteed_comms_diagnostic then
            print("met medical milestone. all hailed above loop:", all_hailed)
        end
        for index, p in ipairs(getActivePlayerShips()) do
            if p.medical_attention_message == nil then
                if guaranteed_comms_diagnostic then
                    print("medical attention message nil for", p:getCallSign())
                end
                all_hailed = false
                if availableForComms(p) then
                    hq_medical_message:openCommsTo(p)
                    p.medical_attention_message = "sent"
                    if guaranteed_comms_diagnostic then
                        print("message sent to", p:getCallSign())
                    end
                else
                    all_hailed = false
                end
            end
        end
        if guaranteed_comms_diagnostic then
            print("all hailed below loop:", all_hailed)
        end
        if all_hailed then
            primary_orders = string.format(
                _(
                    "orders-comms",
                    "Gather medical details and possible treatment from %s in roughly direction %i and return to %s"
                ),
                station_medical_research:getCallSign(),
                math.floor(research_axis),
                station_regional_hq:getCallSign()
            )
            ensign_death_timer = rescue_time_limit * 60
            mainLinearPlot = saveEnsign
        end
    end
    if getScenarioTime() > (medical_message_milestone + 90) then
        if guaranteed_comms_diagnostic then
            print("met medical milestone + 60")
        end
        for index, p in ipairs(getActivePlayerShips()) do
            if p.medical_attention_message == nil then
                p:commandCloseTextComm()
                if guaranteed_comms_diagnostic then
                    print("closed text comms for", p:getCallSign())
                end
            end
        end
    end
end
function saveEnsign(delta)
    ensign_death_timer = ensign_death_timer - delta
    if ensign_death_timer < 0 then
        loseGame(
            _(
                "msgMainscreen",
                "Fargalli died. Omicron plague destroyed humanity"
            )
        )
    else
        local timer_minutes = math.floor(ensign_death_timer / 60)
        local timer_seconds = math.floor(ensign_death_timer % 60)
        local timer_status = _("-tabRelay&Operations", "Ensign Death")
        if timer_minutes <= 0 then
            timer_status = string.format(
                _("-tabRelay&Operations", "%s %i"),
                timer_status,
                timer_seconds
            )
        else
            timer_status = string.format(
                _("-tabRelay&Operations", "%s %i:%.2i"),
                timer_status,
                timer_minutes,
                timer_seconds
            )
        end
        for index, p in ipairs(getActivePlayerShips()) do
            p.ensign_death_timer_relay = "ensign_death_timer_relay"
            p:addCustomInfo(
                "Relay",
                p.ensign_death_timer_relay,
                timer_status,
                3
            )
            p.ensign_death_timer_ops = "ensign_death_timer_ops"
            p:addCustomInfo(
                "Operations",
                p.ensign_death_timer_ops,
                timer_status,
                3
            )
        end
        if medical_research_obtained then
            if station_regional_hq == nil then
                loseGame(
                    _(
                        "msgMainscreen",
                        "HQ destroyed. Omicron plague destroyed humanity"
                    )
                )
            else
                if plague_victim_treated then
                    for index, p in ipairs(getActivePlayerShips()) do
                        p:removeCustom(p.ensign_death_timer_relay)
                        p:removeCustom(p.ensign_death_timer_ops)
                    end
                    plague_message_milestone = getScenarioTime() + 30
                    primary_orders = string.format(
                        _(
                            "orders-comms",
                            "Protect station %s and other friendly stations and ships"
                        ),
                        station_regional_hq:getCallSign()
                    )
                    mainLinearPlot = destroyExuariMessage
                    local p = getPlayerShip(-1)
                    p:addReputationPoints(30)
                end
            end
        else
            if station_medical_research == nil then
                loseGame(
                    _(
                        "msgMainscreen",
                        "Station destroyed. Omicron plague destroyed humanity"
                    )
                )
            elseif station_regional_hq == nil then
                loseGame(
                    _(
                        "msgMainscreen",
                        "HQ destroyed. Omicron plague destroyed humanity"
                    )
                )
            end
        end
        if not all_players_hailed_by_medical_research_station then
            if ensign_death_timer < ((rescue_time_limit * 60) / 2) then
                all_players_hailed_by_medical_research_station = true
                for index, p in ipairs(getActivePlayerShips()) do
                    if p.medical_station_query == nil then
                        all_players_hailed_by_medical_research_station = false
                        if availableForComms(p) then
                            medical_station_query_message:openCommsTo(p)
                            p.medical_station_query = "sent"
                            preMedStrike()
                        else
                            all_players_hailed_by_medical_research_station =
                                false
                        end
                    end
                end
            end
            if not all_players_hailed_by_medical_research_station then
                all_players_hailed_by_medical_research_station = true
                for index, p in ipairs(getActivePlayerShips()) do
                    local player_to_med = distance(p, station_medical_research)
                    local half_hq_to_med = distance(
                        station_medical_research,
                        station_regional_hq
                    ) / 2
                    if player_to_med < half_hq_to_med then
                        if p.medical_station_query == nil then
                            all_players_hailed_by_medical_research_station =
                                false
                            if availableForComms(p) then
                                medical_station_query_message:openCommsTo(p)
                                p.medical_station_query = "sent"
                                preMedStrike()
                            else
                                all_players_hailed_by_medical_research_station =
                                    false
                            end
                        end
                    else
                        all_players_hailed_by_medical_research_station = false
                    end
                end
            end
        end
    end
end
function preMedStrike()
    if pre_med_fleet ~= nil then
        return
    end
    pre_med_fleet = {}
    local m_x, m_y = station_medical_research:getPosition()
    local count_repeat_loop = 0
    local ref_x = 0
    local ref_y = 0
    local outer_limit = 25000
    repeat
        local o_x, o_y =
            vectorFromAngleNorth(random(0, 360), random(18000, outer_limit))
        ref_x = m_x + o_x
        ref_y = m_y + o_y
        count_repeat_loop = count_repeat_loop + 1
        outer_limit = outer_limit + 100
    until farEnough(ref_x, ref_y, 2000) or count_repeat_loop > max_repeat_loop
    if count_repeat_loop > max_repeat_loop then
        print("tried too many times to place first enemy fleet")
    else
        local fleet = spawnEnemies(ref_x, ref_y, 2, "Exuari")
        for _, ship in ipairs(fleet) do
            ship:orderFlyTowards(m_x, m_y)
            table.insert(pre_med_fleet, ship)
        end
    end
    outer_limit = 25000
    count_repeat_loop = 0
    repeat
        local o_x, o_y =
            vectorFromAngleNorth(random(0, 360), random(18000, outer_limit))
        ref_x = m_x + o_x
        ref_y = m_y + o_y
        count_repeat_loop = count_repeat_loop + 1
        outer_limit = outer_limit + 100
    until farEnough(ref_x, ref_y, 2000) or count_repeat_loop > max_repeat_loop
    if count_repeat_loop > max_repeat_loop then
        print("tried too many times to place second enemy fleet")
    else
        local fleet = spawnEnemies(ref_x, ref_y, 1, "Exuari")
        for _, ship in ipairs(fleet) do
            ship:orderAttack(station_medical_research)
            table.insert(pre_med_fleet, ship)
        end
    end
end
function destroyExuariMessage(delta)
    if getScenarioTime() > plague_message_milestone then
        local all_hailed = true
        for index, p in ipairs(getActivePlayerShips()) do
            if p.destroy_exuari_message == nil then
                all_hailed = false
                if availableForComms(p) then
                    hq_plague_message:openCommsTo(p)
                    p.destroy_exuari_message = "sent"
                else
                    all_hailed = false
                end
            end
        end
        if all_hailed then
            primary_orders = string.format(
                _(
                    "orders-comms",
                    "Destroy Exuari Omicron plague research station in roughly direction %i"
                ),
                math.floor(plague_axis)
            )
            plague_spread_timer = destroy_time_limit * 60
            mainLinearPlot = eliminatePlague

        end
    end
    if getScenarioTime() > plague_message_milestone + 90 then
        for index, p in ipairs(getActivePlayerShips()) do
            if p.destroy_exuari_message == nil then
                p:commandCloseTextComm()
            end
        end
    end
end
function eliminatePlague(delta)
    plague_spread_timer = plague_spread_timer - delta
    if plague_spread_timer < 0 then
        loseGame(
            _(
                "msgMainscreen",
                "The Exuari deployed the Omicron plague. Humanity destroyed"
            )
        )
    else
        local timer_minutes = math.floor(plague_spread_timer / 60)
        local timer_seconds = math.floor(plague_spread_timer % 60)
        local timer_status = _("-tabRelay&Operations", "Omicron Broadcast")
        if timer_minutes <= 0 then
            timer_status = string.format(
                _("-tabRelay&Operations", "%s %i"),
                timer_status,
                timer_seconds
            )
        else
            timer_status = string.format(
                _("-tabRelay&Operations", "%s %i:%.2i"),
                timer_status,
                timer_minutes,
                timer_seconds
            )
        end
        for index, p in ipairs(getActivePlayerShips()) do
            p.omicron_broadcast_timer_relay = "omicron_broadcast_timer_relay"
            p:addCustomInfo(
                "Relay",
                p.omicron_broadcast_timer_relay,
                timer_status,
                4
            )
            p.omicron_broadcast_timer_ops = "omicron_broadcast_timer_ops"
            p:addCustomInfo(
                "Operations",
                p.omicron_broadcast_timer_ops,
                timer_status,
                4
            )
        end
        if station_plague ~= nil and station_plague:isValid() then
            if difficulty < 2 then --hint if science heartbeat masked
                for pidx, p in ipairs(getActivePlayerShips()) do
                    if p.plague_station_hint == nil then
                        local current_approach = distance(p, station_plague)
                        if p.proximity_hint_timer ~= nil then
                            if p.proximity_hint_timer > getScenarioTime() then
                                if
                                    current_approach
                                    > (p:getShortRangeRadarRange() * 3)
                                then
                                    p:addToShipLog(
                                        string.format(
                                            _(
                                                "shipLog",
                                                "[%s] Our analysis of your routine ship telemetry indicates that you passed the Exuari plague station, %s."
                                            ),
                                            station_regional_hq:getCallSign(),
                                            station_plague:getCallSign()
                                        ),
                                        "Magenta"
                                    )
                                    p.plague_station_hint = "sent"
                                end
                            end
                        else
                            if p.closest_approach == nil then
                                p.closest_approach = current_approach
                            end
                            p.closest_approach =
                                math.min(p.closest_approach, current_approach)
                            if
                                p.closest_approach < p:getShortRangeRadarRange()
                            then
                                p.proximity_hint_timer = getScenarioTime() + 60
                            end
                        end
                    end
                end
            end
        end
        if station_plague == nil then
            winGame(
                _(
                    "msgMainscreen",
                    "Exuari Omicron plague station destroyed. Humanity saved"
                )
            )
        elseif not station_plague:isValid() then
            winGame(
                _(
                    "msgMainscreen",
                    "Exuari Omicron plague station destroyed. Humanity saved"
                )
            )
        end
    end
end
function winGame(reason)
    local score = getScore()
    local timer_minutes = math.floor(getScenarioTime() / 60)
    local timer_seconds = math.floor(getScenarioTime() % 60)
    local timer_hours = math.floor(timer_minutes / 60)
    local timer_minutes_after_hour = (timer_minutes % 60)
    local duration = _("msgMainscreen", "Duration")
    if timer_minutes <= 0 then
        duration = string.format("%s: %i", duration, timer_seconds)
    else
        if timer_minutes >= 60 then
            duration = string.format(
                "%s: %i:%.2i:%.2i",
                duration,
                timer_hours,
                timer_minutes_after_hour,
                timer_seconds
            )
        else
            duration = string.format(
                "%s: %i:%.2i",
                duration,
                timer_minutes,
                timer_seconds
            )
        end
    end
    reason = string.format(
        _("msgMainscreen", "%s.\nScore: %i. %s"),
        reason,
        math.floor(score * 100),
        duration
    )
    local banner_reason = string.format(
        _("msgMainscreen", "%s. Score: %i. %s"),
        reason,
        math.floor(score * 100),
        duration
    )
    globalMessage(reason)
    setBanner(banner_reason)
    victory(player_faction)
end
function loseGame(reason)
    local score = getScore()
    local timer_minutes = math.floor(getScenarioTime() / 60)
    local timer_seconds = math.floor(getScenarioTime() % 60)
    local timer_hours = math.floor(timer_minutes / 60)
    local timer_minutes_after_hour = (timer_minutes % 60)
    local duration = _("msgMainscreen", "Duration")
    if timer_minutes <= 0 then
        duration = string.format("%s: %i", duration, timer_seconds)
    else
        if timer_minutes >= 60 then
            duration = string.format(
                "%s: %i:%.2i:%.2i",
                duration,
                timer_hours,
                timer_minutes_after_hour,
                timer_seconds
            )
        else
            duration = string.format(
                "%s: %i:%.2i",
                duration,
                timer_minutes,
                timer_seconds
            )
        end
    end
    reason = string.format(
        _("msgMainscreen", "%s.\nScore: %i. %s"),
        reason,
        100 - math.floor(score * 100),
        duration
    )
    local banner_reason = string.format(
        _("msgMainscreen", "%s. Score: %i. %s"),
        reason,
        100 - math.floor(score * 100),
        duration
    )
    globalMessage(reason)
    setBanner(banner_reason)
    victory("Exuari")
end
function getScore()
    local freighter_mission = 0
    if freighter_saved then
        freighter_mission = 1
    end
    local ensign_saved = 0
    local rapid_cure = 0
    if plague_victim_treated then
        ensign_saved = 1
        local rescue_duration = rescue_time_limit * 60 - ensign_death_timer
        if rescue_duration < 900 then
            rapid_cure = 1 - (rescue_duration / 900)
        end
    end
    local plage_stopped = 0
    local rapid_destruction = 0
    if station_plague == nil or not station_plague:isValid() then
        plage_stopped = 1
        local plague_prep_duration = destroy_time_limit * 60
            - plague_spread_timer
        if plague_prep_duration < 900 then
            rapid_destruction = 1 - (plague_prep_duration / 900)
        end
    end
    local positive_reputation = 0
    local players = getActivePlayerShips()
    if #players > 0 then
        local final_reputation = players[1]:getReputationPoints()
        if final_reputation > reputation_start_amount then
            local positive_rep_amount = final_reputation
                - reputation_start_amount
            if difficulty < 1 then
                if positive_rep_amount > 400 then
                    positive_reputation = 1
                else
                    positive_reputation = 1 - (positive_rep_amount / 400)
                end
            elseif difficulty > 1 then
                if positive_rep_amount > 100 then
                    positive_reputation = 1
                else
                    positive_reputation = 1 - (positive_rep_amount / 100)
                end
            else
                if positive_rep_amount > 200 then
                    positive_reputation = 1
                else
                    positive_reputation = 1 - (positive_rep_amount / 200)
                end
            end
        end
    end
    local player_survival = 0
    if player_ship_death_count == 0 then
        player_survival = 1
    else
        player_survival = 1
            - (player_ship_death_count / player_ship_spawn_count)
    end
    local score = (freighter_mission * 0.1)
        + (ensign_saved * 0.1)
        + (rapid_cure * 0.1)
        + (plage_stopped * 0.1)
        + (rapid_destruction * 0.3)
        + (positive_reputation * 0.2)
        + (player_survival * 0.1)
    return score
end
function bioSignatureCycle(obj, delta)
    local bio = obj:getRadarSignatureThermal()
    local ele = obj:getRadarSignatureElectrical()
    local grv = obj:getRadarSignatureGravity()
    bio = bio - delta
    if bio < 0 then
        bio = 1
    end
    -- bio = random(0,1)
    obj:setRadarSignatureInfo(grv, ele, bio)
    -- obj:setCallSign(string.format("%f",obj:getRadarSignatureThermal()))
end

------------------------
--  Update functions  --
------------------------
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
    if mainGMButtons == mainGMButtonsDuringPause then
        mainGMButtons = mainGMButtonsAfterPause
        mainGMButtons()
    end
    if mainLinearPlot ~= nil then
        mainLinearPlot(delta)
    end
    if
        station_medical_research ~= nil and station_medical_research:isValid()
    then
        bioSignatureCycle(station_medical_research, delta)
    end
    if station_plague ~= nil and station_plague:isValid() then
        bioSignatureCycle(station_plague, delta)
    end
    local s_time = getScenarioTime()
    for pidx, p in ipairs(getActivePlayerShips()) do
        if p.pidx == nil then
            p.pidx = pidx
            setPlayers(p)
        end
        updatePlayerLongRangeSensors(p)
        updatePlayerUpgradeMission(p)
        updatePlayerDangerZone(p)
        updatePlayerTubeSizeBanner(p)
    end
    moonCollisionCheck()
    updateBarrierPatrols(delta)
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
