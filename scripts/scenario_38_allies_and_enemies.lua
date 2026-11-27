-- Name: Allies and Enemies
-- Description: The Arlenians are your allies. The Kraylors and Exuari are your enemies and will try to prevent you from completing your missions. Duration: approximately 30 minutes
---
--- Version 2 - Nov2024
---
--- USN Discord: https://discord.gg/PntGG3a where you can join a game online. There's one nearly every weekend. All experience levels are welcome.
-- Type: Replayable
-- Setting[Murphy]: Configures how the odds are stacked against you - Murphy's law.
-- Murphy[Easy]: Murphy generally smiles on you
-- Murphy[Normal|Default]: The normal distribution of the odds against you
-- Murphy[Hard]: Murphy is in particularly strong form today
-- Setting[Missions]: Configures the way missions work
-- Missions[All|Default]: Missions are conducted in random order
-- Missions[One]: One mission is is selected at random (shorter duration)
-- Setting[Enemies]: Configures the strength and/or number of enemy forces
-- Enemies[Easy]: Easier set of enemies
-- Enemies[Normal|Default]: Normal set of enemies
-- Enemies[Hard]: Hard set of enemies

require("utils.lua")
local PlayerState = require("player_state_scenario_utility.lua")
closestPlayerTo = PlayerState.closestPlayerTo
local AlliesStationCatalog = require("allies_station_catalog.lua")
local AlliesStationPlacement = require("allies_station_placement.lua")
local Grid = require("grid_scenario_utility.lua")
local Environment = require("environment_scenario_utility.lua")
placeRandomListAroundPoint = Environment.randomAroundPoint
local Fleet = require("spawn_ships_scenario_utility.lua")
local StationKnowledge = require("station_knowledge.lua")
nearStations = StationKnowledge.nearStations
local ShipComms = require("comms_ship_support.lua")
local ShipNames = require("player_ship_names_scenario_utility.lua")
local StationCore = require("comms_station_core.lua")
local StationMenu = require("comms_station_menu.lua")
local StationGoods = require("comms_station_goods.lua")
local Relation = require("comms_relation_scenario_utility.lua")
local relation = Relation.new({
    source = function() return player end,
})
isAllowedTo = relation.isAllowedTo
getFriendStatus = relation.friendStatus
local ship_profile
local allies_station_catalog
local allies_station_placement

local Inventory = require("inventory_scenario_utility.lua")
local player_goods = Inventory.indexedGoods({
    registry = function() return goods end,
    owner = function() return player end,
})
local target_goods = Inventory.indexedGoods({
    registry = function() return goods end,
    owner = function() return comms_target end,
})
incrementPlayerGoods = player_goods.increment
decrementPlayerGoods = player_goods.decrement
decrementStationGoods = target_goods.decrement
decrementShipGoods = target_goods.decrement

local MissionMenu = require("comms_mission_menu.lua")

local function fillStationBrains()
    StationKnowledge.fill(humanStationList, { goods = goods, trade_medicine = tradeMedicine, trade_food = tradeFood, trade_luxury = tradeLuxury })
end

local function playerPower()
    return Fleet.playerPower({ player = function(index) return getPlayerShip(index) end, limit = 8 })
end


----------------------
--  Initialization  --
----------------------
function init()
    scenario_version = "2.1.2"
    ee_version = "2024.12.08"
    print(
        string.format(
            "    ----    Scenario: Allies and Enemies    ----    Version %s    ----    Tested with EE version %s    ----",
            scenario_version,
            ee_version
        )
    )
    if _VERSION ~= nil then
        print("Lua version:", _VERSION)
    end
    diagnostic = false
    endStatDiagnostic = false
    updateDiagnostic = false
    setPlayerDiagnostic = false
    miningConflictDiagnostic = false
    sickAdmiralDiagnostic = false
    professorDiagnostic = false
    healthDiagnostic = false
    onNewPlayerShip(setPlayers)
    setConstants() --data not expected to change
    setGlobals() --data used everywhere that might change
    setVariations() --apply settings
    constructEnvironment()
    mainGMButtons()
end
function setGlobals()
    primaryOrders = ""
    secondaryOrders = ""
    optionalOrders = ""
    setPlots()
    plotManager = plotDelay
    plotM = movingObjects
    plotCI = cargoInventory
    plotCN = coolantNebulae
    plotH = healthCheck --Damage to ship can kill repair crew members
    healthCheckTimer = 5
    scarceResources = false
    doctorSearch = false
end
function mainGMButtons()
    clearGMFunctions()
    GMMining = _("buttonGM", "Mining")
    addGMFunction(GMMining, triggerMining)
    GMAdmiral = _("buttonGM", "Admiral")
    addGMFunction(GMAdmiral, triggerAdmiral)
    GMDoomsday = _("buttonGM", "Doomsday")
    addGMFunction(GMDoomsday, triggerDoomsday)
    addGMFunction(_("buttonGM", "+Spawn Ship(s)"), spawnGMShips)
end
function constructEnvironment()
    local universeCreateRetryCount = 0
    repeat
        setGossipSnippets()
        setGoodsList()
        setListOfStations()
        setTerritoryZones()
        buildStationsPlus()
        if
            #kraylorStationList < 5
            or #humanStationList < 5
            or #exuariStationList < 5
            or #arlenianStationList < 5
        then
            resetStationsPlus()
            universeCreateRetryCount = universeCreateRetryCount + 1
        end
    until (
            #kraylorStationList >= 5
            and #humanStationList >= 5
            and #exuariStationList >= 5
            and #arlenianStationList >= 5
        ) or universeCreateRetryCount > repeatExitBoundary
    if universeCreateRetryCount > 0 then
        if diagnostic then
            print("universe create retry count: " .. universeCreateRetryCount)
        end
    end
    if universeCreateRetryCount > repeatExitBoundary then
        print("Universe not created. Attempts:", universeCreateRetryCount)
    end
    setFleets()
end
function triggerMining()
    if plot1 == nil then
        plotChoice = 1
        plot1 = plotList[1]
        table.remove(plotList, 1)
        plotManager = plotRun
    else
        nextPlot = miningConflict
    end
end
function triggerAdmiral()
    if plot1 == nil then
        if #plotList == 3 then
            plotChoice = 2
            plot1 = plotList[2]
            table.remove(plotList, 2)
        else
            if plotList[1] == sickArlenianAdmiral then
                plotChoice = 1
                plot1 = plotList[1]
                table.remove(plotList, 1)
            else
                plotChoice = 2
                plot1 = plotList[2]
                table.remove(plotList, 2)
            end
        end
        plotManager = plotRun
    else
        nextPlot = sickArlenianAdmiral
    end
end
function triggerDoomsday()
    if plot1 == nil then
        if #plotList == 3 then
            plotChoice = 3
            plot1 = plotList[3]
            table.remove(plotList, 3)
        else
            if plotList[1] == doomsday then
                plotChoice = 1
                plot1 = plotList[1]
                table.remove(plotList, 1)
            else
                plotChoice = 2
                plot1 = plotList[2]
                table.remove(plotList, 2)
            end
        end
        plotManager = plotRun
    else
        nextPlot = doomsday
    end
end
function setVariations()
    local murphy_config = {
        ["Easy"] = {
            number = 0.5,
            adverse = 0.999,
            coolant_loss = 0.99999,
            coolant_gain = 0.01,
        },
        ["Normal"] = {
            number = 1,
            adverse = 0.995,
            coolant_loss = 0.99995,
            coolant_gain = 0.001,
        },
        ["Hard"] = {
            number = 2,
            adverse = 0.99,
            coolant_loss = 0.9999,
            coolant_gain = 0.0001,
        },
    }
    difficulty = murphy_config[getScenarioSetting("Murphy")].number
    adverseEffect = murphy_config[getScenarioSetting("Murphy")].adverse
    coolant_loss = murphy_config[getScenarioSetting("Murphy")].coolant_loss
    coolant_gain = murphy_config[getScenarioSetting("Murphy")].coolant_gain
    local mission_config = {
        ["All"] = false,
        ["One"] = true,
    }
    onlyOneMission = mission_config[getScenarioSetting("Missions")]
    local enemy_config = {
        ["Easy"] = 0.5,
        ["Normal"] = 1,
        ["Hard"] = 2,
    }
    enemy_power = enemy_config[getScenarioSetting("Enemies")]
end
function setConstants()
    repeatExitBoundary = 100
    healthCheckTimerInterval = 5
    missile_types = { "Homing", "Nuke", "Mine", "EMP", "HVLI" }
    --Ship Template Name List
    stnl = {
        "MT52 Hornet",
        "MU52 Hornet",
        "Adder MK5",
        "Adder MK4",
        "WX-Lindworm",
        "Adder MK6",
        "Phobos T3",
        "Phobos M3",
        "Piranha F8",
        "Piranha F12",
        "Ranus U",
        "Nirvana R5A",
        "Stalker Q7",
        "Stalker R7",
        "Atlantis X23",
        "Starhammer II",
        "Odin",
        ST.FIGHTER,
        ST.CRUISER,
        ST.MISSILE_CRUISER,
        "Strix",
        "Magpie",
        "Dreadnought",
        "Battlestation",
        "Blockade Runner",
        "Ktlitan Fighter",
        "Ktlitan Breaker",
        "Ktlitan Worker",
        "Ktlitan Drone",
        "Ktlitan Feeder",
        "Ktlitan Scout",
        "Ktlitan Destroyer",
        "Storm",
    }
    --Ship Template Score List
    stsl = {
        5,
        5,
        7,
        6,
        7,
        8,
        15,
        16,
        15,
        15,
        25,
        20,
        25,
        25,
        50,
        70,
        250,
        6,
        18,
        14,
        30,
        27,
        80,
        100,
        65,
        6,
        45,
        40,
        4,
        48,
        8,
        50,
        22,
    }
    -- square grid deployment
    fleetPosDelta1x = {
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
    }
    fleetPosDelta1y = {
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
    }
    -- rough hexagonal deployment
    fleetPosDelta2x = {
        0,
        2,
        -2,
        1,
        -1,
        1,
        1,
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
    }
    fleetPosDelta2y = {
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
    }
    player_ship_names = {
        [ST.ATLANTIS] = ShipNames.pool(ST.ATLANTIS),
        ["Atlantis II"] = ShipNames.pool("Atlantis II"),
        [ST.BENEDICT] = ShipNames.pool("Benedict"),
        [ST.CRUCIBLE] = ShipNames.pool(ST.CRUCIBLE),
        [ST.ENDER] = ShipNames.pool("Ender"),
        [ST.FLAVIA_PFALCON] = ShipNames.pool("Flavia P.Falcon"),
        [ST.HATHCOCK] = ShipNames.pool("Hathcock"),
        [ST.KIRIYA] = ShipNames.pool("Kiriya"),
        [ST.MAVERICK] = ShipNames.pool("Maverick"),
        [ST.MP52_HORNET] = ShipNames.pool("MP52 Hornet"),
        [ST.NAUTILUS] = ShipNames.pool("Nautilus"),
        [ST.PHOBOS_M3P] = ShipNames.pool("Phobos M3P"),
        [ST.PIRANHA] = ShipNames.pool("Piranha"),
        [ST.VINDICATOR] = ShipNames.pool("Vindicator"),
        [ST.STINGRAY] = ShipNames.pool("Stingray"),
        [ST.AVALANCHE] = ShipNames.pool("Avalanche"),
        ["Proto-Atlantis"] = ShipNames.pool("Proto-Atlantis"),
        ["Redhook"] = ShipNames.pool("Redhook"),
        [ST.REPULSE] = ShipNames.pool("Repulse"),
        [ST.SAIPAN] = {
            "Atlas",
            "Bernard",
            "Alexander",
            "Retribution",
            "Sulaco",
            "Conestoga",
            "Saratoga",
            "Pegasus",
        },
        [ST.CROW] = ShipNames.pool("Crow"),
        ["Surkov"] = ShipNames.pool("Surkov"),
        ["ZX-Lindworm"] = ShipNames.pool("ZX-Lindworm"),
        ["Leftovers"] = { "Foregone", "Righteous", "Masher" },
    }
    player_ship_stats =
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
            [ST.SAIPAN] = {
                strength = 35,
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
        }
    characterNames = {
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
end
function setGossipSnippets()
    gossipSnippets = {}
    table.insert(
        gossipSnippets,
        _(
            "gossip-comms",
            "I hear the head of operations has a thing for his administrative assistant"
        )
    ) --1
    table.insert(
        gossipSnippets,
        _(
            "gossip-comms",
            "My mining friends tell me Krak or Kruk is about to strike it rich"
        )
    ) --2
    table.insert(
        gossipSnippets,
        _(
            "gossip-comms",
            "Did you know you can usually hire replacement repair crew cheaper at friendly stations?"
        )
    ) --3
    table.insert(
        gossipSnippets,
        _(
            "gossip-comms",
            "Under their uniforms, the Kraylors have an extra appendage. I wonder what they use it for"
        )
    ) --4
    table.insert(
        gossipSnippets,
        _(
            "gossip-comms",
            "The Kraylors may be human navy enemies, but they make some mighty fine BBQ Mynock"
        )
    ) --5
    table.insert(
        gossipSnippets,
        _(
            "gossip-comms",
            "The Kraylors and the Ktlitans may be nearing a cease fire from what I hear. That'd be bad news for us"
        )
    ) --6
    table.insert(
        gossipSnippets,
        _(
            "gossip-comms",
            "Docking bay 7 has interesting mind altering substances for sale, but they're monitored between 1900 and 2300"
        )
    ) --7
    table.insert(
        gossipSnippets,
        _(
            "gossip-comms",
            "Watch the sky tonight in quadrant J around 2243. It should be spectacular"
        )
    ) --8
    table.insert(
        gossipSnippets,
        _(
            "gossip-comms",
            "I think the shuttle pilot has a tame miniature Ktlitan caged in his quarters. Sometimes I hear it at night"
        )
    ) --9
    table.insert(
        gossipSnippets,
        _(
            "gossip-comms",
            "Did you hear the screaming chase in the corridors on level 4 last night? Three Kraylors were captured and put in the brig"
        )
    ) --10
    table.insert(
        gossipSnippets,
        _(
            "gossip-comms",
            "Rumor has it that the two Lichten brothers are on the verge of a new discovery. And it's not another wine flavor either"
        )
    ) --11
end
function setGoodsList()
    --list of goods available to buy, sell or trade (sell still under development)
    goodsList = {
        { "food", 0 },
        { "medicine", 0 },
        { "nickel", 0 },
        { "platinum", 0 },
        { "gold", 0 },
        { "dilithium", 0 },
        { "tritanium", 0 },
        { "luxury", 0 },
        { "cobalt", 0 },
        { "impulse", 0 },
        { "warp", 0 },
        { "shield", 0 },
        { "tractor", 0 },
        { "repulsor", 0 },
        { "beam", 0 },
        { "optic", 0 },
        { "robotic", 0 },
        { "filament", 0 },
        { "transporter", 0 },
        { "sensor", 0 },
        { "communication", 0 },
        { "autodoc", 0 },
        { "lifter", 0 },
        { "android", 0 },
        { "nanites", 0 },
        { "software", 0 },
        { "circuit", 0 },
        { "battery", 0 },
    }
    goods = {} --overall tracking of goods
    tradeFood = {} --stations that will trade food for other goods
    tradeLuxury = {} --stations that will trade luxury for other goods
    tradeMedicine = {} --stations that will trade medicine for other goods
end
function setListOfStations()
    --array of station names to facilitate randomized station placement
    allies_station_catalog = AlliesStationCatalog.new(
        AlliesStationCatalog.alliesConfig(),
        {
            comms = commsStation,
            inventory = {
                goods = goods,
                food = tradeFood,
                medicine = tradeMedicine,
                luxury = tradeLuxury,
            },
            place_random_around = placeRandomAroundPoint,
            create_random_along_arc = createRandomAlongArc,
            vector_from_angle = vectorFromAngle,
        }
    )
    placeStation = allies_station_catalog:group("friendly")
    placeGenericStation = allies_station_catalog:group("generic")
    placeEnemyStation = allies_station_catalog:group("enemy")
    allies_station_placement = AlliesStationPlacement.new({
        catalog = allies_station_catalog,
        friendly = placeStation,
        generic = placeGenericStation,
        enemy = placeEnemyStation,
    })
end
function bendAngle(fe)
    local angleToReturn = 0
    if random(1, 100) < 80 then
        angleToReturn = random(0, 60 + fe) + (15 - (fe / 2))
    else
        for i = 1, 15 do
            angleToReturn = angleToReturn + random(1, 5)
        end
    end
    return angleToReturn
end
function setTerritoryZones()
    borderStartAngle = random(0, 360) --shared border between Human and Arlenian
    borderStartX, borderStartY =
        vectorFromAngle(borderStartAngle, random(3500, 4900))
    local halfLength = random(8000, 15000)
    zoneLimit = 150000
    zpi = 1 --zone point index
    --Note: "left" and "right" refer to someone standing on the 2D board at the spawn point
    --  looking at the shared Human and Arlenian border;
    humanLeftX = {}
    humanLeftY = {}
    humanRightX = {}
    humanRightY = {}
    arlenianLeftX = {}
    arlenianLeftY = {}
    arlenianRightX = {}
    arlenianRightY = {}
    local szbx, szby = vectorFromAngle(borderStartAngle + 270, halfLength)
    sharedZoneBorderLeftX = borderStartX + szbx
    sharedZoneBorderLeftY = borderStartY + szby
    szbx, szby = vectorFromAngle(borderStartAngle + 90, halfLength)
    sharedZoneBorderRightX = borderStartX + szbx
    sharedZoneBorderRightY = borderStartY + szby
    local firstLowerLength = 10000
    local firstUpperLength = 20000
    local ba = bendAngle(0)
    local hlx, hly = vectorFromAngle(
        borderStartAngle + 270 - ba,
        random(firstLowerLength, firstUpperLength)
    )
    table.insert(humanLeftX, sharedZoneBorderLeftX + hlx)
    table.insert(humanLeftY, sharedZoneBorderLeftY + hly)
    ba = bendAngle(0)
    hlx, hly = vectorFromAngle(
        borderStartAngle + 90 + ba,
        random(firstLowerLength, firstUpperLength)
    )
    table.insert(humanRightX, sharedZoneBorderRightX + hlx)
    table.insert(humanRightY, sharedZoneBorderRightY + hly)
    ba = bendAngle(0)
    hlx, hly = vectorFromAngle(
        borderStartAngle + 270 + ba,
        random(firstLowerLength, firstUpperLength)
    )
    table.insert(arlenianLeftX, sharedZoneBorderLeftX + hlx)
    table.insert(arlenianLeftY, sharedZoneBorderLeftY + hly)
    ba = bendAngle(0)
    hlx, hly = vectorFromAngle(
        borderStartAngle + 90 - ba,
        random(firstLowerLength, firstUpperLength)
    )
    table.insert(arlenianRightX, sharedZoneBorderRightX + hlx)
    table.insert(arlenianRightY, sharedZoneBorderRightY + hly)
    local lowerLength = 8000
    local upperLength = 15000
    for i = 1, 20 do
        ba = bendAngle(i)
        hlx, hly = vectorFromAngle(
            borderStartAngle + 270 - ba,
            random(lowerLength, upperLength)
        )
        table.insert(humanLeftX, humanLeftX[zpi] + hlx)
        table.insert(humanLeftY, humanLeftY[zpi] + hly)
        ba = bendAngle(i)
        hlx, hly = vectorFromAngle(
            borderStartAngle + 90 + ba,
            random(lowerLength, upperLength)
        )
        table.insert(humanRightX, humanRightX[zpi] + hlx)
        table.insert(humanRightY, humanRightY[zpi] + hly)
        ba = bendAngle(i)
        hlx, hly = vectorFromAngle(
            borderStartAngle + 270 + ba,
            random(lowerLength, upperLength)
        )
        table.insert(arlenianLeftX, arlenianLeftX[zpi] + hlx)
        table.insert(arlenianLeftY, arlenianLeftY[zpi] + hly)
        ba = bendAngle(i)
        hlx, hly = vectorFromAngle(
            borderStartAngle + 90 - ba,
            random(lowerLength, upperLength)
        )
        table.insert(arlenianRightX, arlenianRightX[zpi] + hlx)
        table.insert(arlenianRightY, arlenianRightY[zpi] + hly)
        zpi = zpi + 1
    end
    humanZone = Zone():setPoints(
        humanLeftX[21],
        humanLeftY[21],
        humanLeftX[20],
        humanLeftY[20],
        humanLeftX[19],
        humanLeftY[19],
        humanLeftX[18],
        humanLeftY[18],
        humanLeftX[17],
        humanLeftY[17],
        humanLeftX[16],
        humanLeftY[16],
        humanLeftX[15],
        humanLeftY[15],
        humanLeftX[14],
        humanLeftY[14],
        humanLeftX[13],
        humanLeftY[13],
        humanLeftX[12],
        humanLeftY[12],
        humanLeftX[11],
        humanLeftY[11],
        humanLeftX[10],
        humanLeftY[10],
        humanLeftX[9],
        humanLeftY[9],
        humanLeftX[8],
        humanLeftY[8],
        humanLeftX[7],
        humanLeftY[7],
        humanLeftX[6],
        humanLeftY[6],
        humanLeftX[5],
        humanLeftY[5],
        humanLeftX[4],
        humanLeftY[4],
        humanLeftX[3],
        humanLeftY[3],
        humanLeftX[2],
        humanLeftY[2],
        humanLeftX[1],
        humanLeftY[1],
        sharedZoneBorderLeftX,
        sharedZoneBorderLeftY,
        sharedZoneBorderRightX,
        sharedZoneBorderRightY,
        humanRightX[1],
        humanRightY[1],
        humanRightX[2],
        humanRightY[2],
        humanRightX[3],
        humanRightY[3],
        humanRightX[4],
        humanRightY[4],
        humanRightX[5],
        humanRightY[5],
        humanRightX[6],
        humanRightY[6],
        humanRightX[7],
        humanRightY[7],
        humanRightX[8],
        humanRightY[8],
        humanRightX[9],
        humanRightY[9],
        humanRightX[10],
        humanRightY[10],
        humanRightX[11],
        humanRightY[11],
        humanRightX[12],
        humanRightY[12],
        humanRightX[13],
        humanRightY[13],
        humanRightX[14],
        humanRightY[14],
        humanRightX[15],
        humanRightY[15],
        humanRightX[16],
        humanRightY[16],
        humanRightX[17],
        humanRightY[17],
        humanRightX[18],
        humanRightY[18],
        humanRightX[19],
        humanRightY[19],
        humanRightX[20],
        humanRightY[20],
        humanRightX[21],
        humanRightY[21]
    )
    arlenianZone = Zone():setPoints(
        arlenianRightX[21],
        arlenianRightY[21],
        arlenianRightX[20],
        arlenianRightY[20],
        arlenianRightX[19],
        arlenianRightY[19],
        arlenianRightX[18],
        arlenianRightY[18],
        arlenianRightX[17],
        arlenianRightY[17],
        arlenianRightX[16],
        arlenianRightY[16],
        arlenianRightX[15],
        arlenianRightY[15],
        arlenianRightX[14],
        arlenianRightY[14],
        arlenianRightX[13],
        arlenianRightY[13],
        arlenianRightX[12],
        arlenianRightY[12],
        arlenianRightX[11],
        arlenianRightY[11],
        arlenianRightX[10],
        arlenianRightY[10],
        arlenianRightX[9],
        arlenianRightY[9],
        arlenianRightX[8],
        arlenianRightY[8],
        arlenianRightX[7],
        arlenianRightY[7],
        arlenianRightX[6],
        arlenianRightY[6],
        arlenianRightX[5],
        arlenianRightY[5],
        arlenianRightX[4],
        arlenianRightY[4],
        arlenianRightX[3],
        arlenianRightY[3],
        arlenianRightX[2],
        arlenianRightY[2],
        arlenianRightX[1],
        arlenianRightY[1],
        sharedZoneBorderRightX,
        sharedZoneBorderRightY,
        sharedZoneBorderLeftX,
        sharedZoneBorderLeftY,
        arlenianLeftX[1],
        arlenianLeftY[1],
        arlenianLeftX[2],
        arlenianLeftY[2],
        arlenianLeftX[3],
        arlenianLeftY[3],
        arlenianLeftX[4],
        arlenianLeftY[4],
        arlenianLeftX[5],
        arlenianLeftY[5],
        arlenianLeftX[6],
        arlenianLeftY[6],
        arlenianLeftX[7],
        arlenianLeftY[7],
        arlenianLeftX[8],
        arlenianLeftY[8],
        arlenianLeftX[9],
        arlenianLeftY[9],
        arlenianLeftX[10],
        arlenianLeftY[10],
        arlenianLeftX[11],
        arlenianLeftY[11],
        arlenianLeftX[12],
        arlenianLeftY[12],
        arlenianLeftX[13],
        arlenianLeftY[13],
        arlenianLeftX[14],
        arlenianLeftY[14],
        arlenianLeftX[15],
        arlenianLeftY[15],
        arlenianLeftX[16],
        arlenianLeftY[16],
        arlenianLeftX[17],
        arlenianLeftY[17],
        arlenianLeftX[18],
        arlenianLeftY[18],
        arlenianLeftX[19],
        arlenianLeftY[19],
        arlenianLeftX[20],
        arlenianLeftY[20],
        arlenianLeftX[21],
        arlenianLeftY[21]
    )
    kraylorZone = Zone():setPoints(
        arlenianLeftX[21],
        arlenianLeftY[21],
        arlenianLeftX[20],
        arlenianLeftY[20],
        arlenianLeftX[19],
        arlenianLeftY[19],
        arlenianLeftX[18],
        arlenianLeftY[18],
        arlenianLeftX[17],
        arlenianLeftY[17],
        arlenianLeftX[16],
        arlenianLeftY[16],
        arlenianLeftX[15],
        arlenianLeftY[15],
        arlenianLeftX[14],
        arlenianLeftY[14],
        arlenianLeftX[13],
        arlenianLeftY[13],
        arlenianLeftX[12],
        arlenianLeftY[12],
        arlenianLeftX[11],
        arlenianLeftY[11],
        arlenianLeftX[10],
        arlenianLeftY[10],
        arlenianLeftX[9],
        arlenianLeftY[9],
        arlenianLeftX[8],
        arlenianLeftY[8],
        arlenianLeftX[7],
        arlenianLeftY[7],
        arlenianLeftX[6],
        arlenianLeftY[6],
        arlenianLeftX[5],
        arlenianLeftY[5],
        arlenianLeftX[4],
        arlenianLeftY[4],
        arlenianLeftX[3],
        arlenianLeftY[3],
        arlenianLeftX[2],
        arlenianLeftY[2],
        arlenianLeftX[1],
        arlenianLeftY[1],
        sharedZoneBorderLeftX,
        sharedZoneBorderLeftY,
        humanLeftX[1],
        humanLeftY[1],
        humanLeftX[2],
        humanLeftY[2],
        humanLeftX[3],
        humanLeftY[3],
        humanLeftX[4],
        humanLeftY[4],
        humanLeftX[5],
        humanLeftY[5],
        humanLeftX[6],
        humanLeftY[6],
        humanLeftX[7],
        humanLeftY[7],
        humanLeftX[8],
        humanLeftY[8],
        humanLeftX[9],
        humanLeftY[9],
        humanLeftX[10],
        humanLeftY[10],
        humanLeftX[11],
        humanLeftY[11],
        humanLeftX[12],
        humanLeftY[12],
        humanLeftX[13],
        humanLeftY[13],
        humanLeftX[14],
        humanLeftY[14],
        humanLeftX[15],
        humanLeftY[15],
        humanLeftX[16],
        humanLeftY[16],
        humanLeftX[17],
        humanLeftY[17],
        humanLeftX[18],
        humanLeftY[18],
        humanLeftX[19],
        humanLeftY[19],
        humanLeftX[20],
        humanLeftY[20],
        humanLeftX[21],
        humanLeftY[21]
    )
    exuariZone = Zone():setPoints(
        humanRightX[21],
        humanRightY[21],
        humanRightX[20],
        humanRightY[20],
        humanRightX[19],
        humanRightY[19],
        humanRightX[18],
        humanRightY[18],
        humanRightX[17],
        humanRightY[17],
        humanRightX[16],
        humanRightY[16],
        humanRightX[15],
        humanRightY[15],
        humanRightX[14],
        humanRightY[14],
        humanRightX[13],
        humanRightY[13],
        humanRightX[12],
        humanRightY[12],
        humanRightX[11],
        humanRightY[11],
        humanRightX[10],
        humanRightY[10],
        humanRightX[9],
        humanRightY[9],
        humanRightX[8],
        humanRightY[8],
        humanRightX[7],
        humanRightY[7],
        humanRightX[6],
        humanRightY[6],
        humanRightX[5],
        humanRightY[5],
        humanRightX[4],
        humanRightY[4],
        humanRightX[3],
        humanRightY[3],
        humanRightX[2],
        humanRightY[2],
        humanRightX[1],
        humanRightY[1],
        sharedZoneBorderRightX,
        sharedZoneBorderRightY,
        arlenianRightX[1],
        arlenianRightY[1],
        arlenianRightX[2],
        arlenianRightY[2],
        arlenianRightX[3],
        arlenianRightY[3],
        arlenianRightX[4],
        arlenianRightY[4],
        arlenianRightX[5],
        arlenianRightY[5],
        arlenianRightX[6],
        arlenianRightY[6],
        arlenianRightX[7],
        arlenianRightY[7],
        arlenianRightX[8],
        arlenianRightY[8],
        arlenianRightX[9],
        arlenianRightY[9],
        arlenianRightX[10],
        arlenianRightY[10],
        arlenianRightX[11],
        arlenianRightY[11],
        arlenianRightX[12],
        arlenianRightY[12],
        arlenianRightX[13],
        arlenianRightY[13],
        arlenianRightX[14],
        arlenianRightY[14],
        arlenianRightX[15],
        arlenianRightY[15],
        arlenianRightX[16],
        arlenianRightY[16],
        arlenianRightX[17],
        arlenianRightY[17],
        arlenianRightX[18],
        arlenianRightY[18],
        arlenianRightX[19],
        arlenianRightY[19],
        arlenianRightX[20],
        arlenianRightY[20],
        arlenianRightX[21],
        arlenianRightY[21]
    )
    humanZone
        :setColor(0, 54, 0)
        :setLabel(_("ZoneLabelDescription-faction", "Human"))
    arlenianZone
        :setColor(0, 0, 54)
        :setLabel(_("ZoneLabelDescription-faction", "Arlenian"))
    kraylorZone
        :setColor(54, 0, 0)
        :setLabel(_("ZoneLabelDescription-faction", "Kraylor"))
    exuariZone
        :setColor(54, 0, 0)
        :setLabel(_("ZoneLabelDescription-faction", "Exuari"))
end
function resetStationsPlus()
    for i = 1, #stationList do
        stationList[i]:destroy()
    end
    allObjects = getAllObjects()
    for _, obj in ipairs(allObjects) do
        obj:destroy()
    end
end
function buildStationsPlus()
    stationFaction = ""
    stationList = {}
    humanStationList = {}
    humanStationsRemain = true
    kraylorStationList = {}
    kraylorStationsRemain = true
    neutralStationList = {}
    neutralStationsRemain = true
    exuariStationList = {}
    exuariStationsRemain = true
    arlenianStationList = {}
    arlenianStationsRemain = true
    humanStationDestroyedNameList = {}
    humanStationDestroyedValue = {}
    kraylorStationDestroyedNameList = {}
    kraylorStationDestroyedValue = {}
    exuariStationDestroyedNameList = {}
    exuariStationDestroyedValue = {}
    arlenianStationDestroyedNameList = {}
    arlenianStationDestroyedValue = {}
    neutralStationDestroyedNameList = {}
    neutralStationDestroyedValue = {}
    gbLow = 1 --grid boundary low
    gbHigh = 500 --grid boundary high
    grid = {} --grid - positional model
    grid_helper = Grid.new({ min = gbLow, max = gbHigh, grid = grid })
    for i = gbLow, gbHigh do
        grid[i] = {}
    end
    gx = gbHigh / 2 --grid coordinate x
    gy = gbHigh / 2 --grid coordinate y
    gp = 1 --grid position list index
    gSize = random(6000, 8000) --grid cell size in positional units
    adjList = {} --adjacent space on grid location list
    wzac = 0 --weird zone adjustment count
    humanStationStrength = 0
    kraylorStationStrength = 0
    neutralStationStrength = 0
    arlenianStationStrength = 0
    exuariStationStrength = 0
    repeat
        tSize = math.random(2, 5) --tack on to region size (3-6 since first is outside loop)
        grid[gx][gy] = gp --set current grid location to grid position list index
        gRegion = {} --grow region
        table.insert(gRegion, { gx, gy })
        for i = 1, tSize do
            adjList = grid_helper:current(gx, gy, gp)
            if #adjList < 1 then --exit loop if there are no more adjacent spaces available
                break
            end
            rd = math.random(1, #adjList) --random direction to grow from adjacent list
            grid[adjList[rd][1]][adjList[rd][2]] = gp
            table.insert(gRegion, { adjList[rd][1], adjList[rd][2] })
        end
        --get adjacent list after done growing region
        adjList = grid_helper:current(gx, gy, gp)
        if #adjList < 1 then
            adjList = grid_helper:all(gx, gy)
        else
            if random(1, 100) < 63 then
                adjList = grid_helper:all(gx, gy)
            end
        end
        sri = math.random(1, #gRegion) --select station random region index
        psx = (gRegion[sri][1] - (gbHigh / 2)) * gSize
            + random(-gSize / 2 * 0.95, gSize / 2 * 0.95) --place station x coordinate
        psy = (gRegion[sri][2] - (gbHigh / 2)) * gSize
            + random(-gSize / 2 * 0.95, gSize / 2 * 0.95) --place station y coordinate
        ta = VisualAsteroid():setPosition(psx, psy)
        pStation = nil
        if humanZone:isInside(ta) then
            allies_station_placement.placeHuman()
        elseif arlenianZone:isInside(ta) then
            allies_station_placement.placeArlenian()
        elseif kraylorZone:isInside(ta) then
            allies_station_placement.placeKraylor()
        elseif exuariZone:isInside(ta) then
            allies_station_placement.placeExuari()
        else
            allies_station_placement.placeNeutral()
        end
        ta:destroy()
        if
            #gossipSnippets > 0
            and stationFaction == "Human Navy"
            and pStation ~= nil
        then
            if gp % 2 == 0 then
                ni = math.random(1, #gossipSnippets)
                pStation.gossip = gossipSnippets[ni]
                table.remove(gossipSnippets, ni)
            end
        end
        gp = gp + 1 --set next station number
        rn = math.random(1, #adjList) --random next station start location
        gx = adjList[rn][1]
        gy = adjList[rn][2]
    until not neutralStationsRemain
        or not humanStationsRemain
        or not kraylorStationsRemain
        or not exuariStationsRemain
    local oobCount = 0
    local humanOob = 0
    local kraylorOob = 0
    local exuariOob = 0
    local arlenianOob = 0
    local neutralOob = 0
    for i = 1, #stationList do
        local extractStation = stationList[i]
        local psf = extractStation:getFaction()
        if psf == "Human Navy" and not humanZone:isInside(extractStation) then
            oobCount = oobCount + 1
            humanOob = humanOob + 1
        end
        if psf == "Kraylor" and not kraylorZone:isInside(extractStation) then
            oobCount = oobCount + 1
            kraylorOob = kraylorOob + 1
        end
        if psf == "Exuari" and not exuariZone:isInside(extractStation) then
            oobCount = oobCount + 1
            exuariOob = exuariOob + 1
        end
        if psf == "Arlenians" and not arlenianZone:isInside(extractStation) then
            oobCount = oobCount + 1
            arlenianOob = arlenianOob + 1
        end
        if
            psf == "Independent"
            and (
                humanZone:isInside(extractStation)
                or kraylorZone:isInside(extractStation)
                or exuariZone:isInside(extractStation)
                or arlenianZone:isInside(extractStation)
            )
        then
            oobCount = oobCount + 1
            neutralOob = neutralOob + 1
        end
    end
    if oobCount > 0 then
        if diagnostic then
            print(
                string.format(
                    "OOB: %i, Human: %i, Kraylor: %i, Exuari: %i, Arlenian: %i, Neutral: %i",
                    oobCount,
                    humanOob,
                    kraylorOob,
                    exuariOob,
                    arlenianOob,
                    neutralOob
                )
            )
        end
    end
    if diagnostic then
        print(
            string.format(
                "Human stations: %i, Kraylor stations: %i, Exuari stations: %i, Arlenian stations: %i, Neutral stations: %i",
                #humanStationList,
                #kraylorStationList,
                #exuariStationList,
                #arlenianStationList,
                #neutralStationList
            )
        )
    end
    if not diagnostic then
        local nebula_count = math.random(7, 25)
        local nebula_list =
            placeRandomListAroundPoint(Nebula, nebula_count, 1, 150000, 0, 0)
        local nebula_index = 0
        for i = 1, #nebula_list do
            nebula_list[i].lose = false
            nebula_list[i].gain = false
        end
        coolant_nebula = {}
        for i = 1, math.random(math.floor(nebula_count / 2)) do
            nebula_index = math.random(1, #nebula_list)
            table.insert(coolant_nebula, nebula_list[nebula_index])
            table.remove(nebula_list, nebula_index)
            if math.random(1, 100) < 50 then
                coolant_nebula[#coolant_nebula].lose = true
            else
                coolant_nebula[#coolant_nebula].gain = true
            end
        end
    end
end
----------------------------------------
-- Set up enemy and friendly fleets  --
----------------------------------------
function setFleets()
    rawKraylorShipStrength = 0
    rawHumanShipStrength = 0
    rawExuariShipStrength = 0
    rawArlenianShipStrength = 0
    rawNeutralShipStrength = 0
    kraylorVesselDestroyedNameList = {}
    kraylorVesselDestroyedType = {}
    kraylorVesselDestroyedValue = {}
    exuariVesselDestroyedNameList = {}
    exuariVesselDestroyedType = {}
    exuariVesselDestroyedValue = {}
    humanVesselDestroyedNameList = {}
    humanVesselDestroyedType = {}
    humanVesselDestroyedValue = {}
    arlenianVesselDestroyedNameList = {}
    arlenianVesselDestroyedType = {}
    arlenianVesselDestroyedValue = {}
    setKraylorDefensiveFleet()
    setExuariDefensiveFleet()
    setHumanDefensiveFleet()
    setArlenianDefensiveFleet()
end
function setKraylorDefensiveFleet()
    kraylorResource = 100 + difficulty * 200
    kraylorFleetList = {}
    kraylorDefensiveFleetList = {}
    kraylorFleet1base = kraylorStationList[math.random(1, #kraylorStationList)]
    local f1bx, f1by = kraylorFleet1base:getPosition()
    kraylorFleet1, kraylorFleet1Power =
        spawnEnemyFleet(f1bx, f1by, random(90, 130))
    for i, enemy in ipairs(kraylorFleet1) do
        enemy:orderDefendTarget(kraylorFleet1base)
    end
    table.insert(kraylorFleetList, kraylorFleet1)
    table.insert(kraylorDefensiveFleetList, kraylorFleet1)
    kraylorResource = kraylorResource - kraylorFleet1Power
    if kraylorResource > 120 then
        kraylorFleet2Power = random(80, 120)
    else
        kraylorFleet2Power = 120
    end
    repeat
        candidate = kraylorStationList[math.random(1, #kraylorStationList)]
        if candidate ~= kraylorFleet1base then
            kraylorFleet2base = candidate
        end
    until kraylorFleet2base ~= nil
    local f1bx, f1by = kraylorFleet2base:getPosition()
    kraylorFleet2, kraylorFleet2Power =
        spawnEnemyFleet(f1bx, f1by, kraylorFleet2Power)
    for i, enemy in ipairs(kraylorFleet2) do
        enemy:orderDefendTarget(kraylorFleet2base)
    end
    table.insert(kraylorFleetList, kraylorFleet2)
    table.insert(kraylorDefensiveFleetList, kraylorFleet2)
    kraylorResource = kraylorResource - kraylorFleet2Power
    if kraylorResource > 120 then
        kraylorFleet3Power = random(80, 120)
    else
        kraylorFleet3Power = 120
    end
    repeat
        candidate = kraylorStationList[math.random(1, #kraylorStationList)]
        if
            candidate ~= kraylorFleet1base
            and candidate ~= kraylorFleet2base
        then
            kraylorFleet3base = candidate
        end
    until kraylorFleet3base ~= nil
    local f1bx, f1by = kraylorFleet3base:getPosition()
    kraylorFleet3, kraylorFleet3Power =
        spawnEnemyFleet(f1bx, f1by, kraylorFleet3Power)
    for _, enemy in ipairs(kraylorFleet3) do
        enemy:orderDefendTarget(kraylorFleet3base)
    end
    table.insert(kraylorFleetList, kraylorFleet3)
    table.insert(kraylorDefensiveFleetList, kraylorFleet3)
    kraylorResource = kraylorResource - kraylorFleet3Power
    repeat
        candidate = kraylorStationList[math.random(1, #kraylorStationList)]
        if
            candidate ~= kraylorFleet1base
            and candidate ~= kraylorFleet2base
            and candidate ~= kraylorFleet3base
        then
            kraylorFleet4base = candidate
        end
    until kraylorFleet4base ~= nil
    local f1bx, f1by = kraylorFleet4base:getPosition()
    kraylorFleet4, kraylorFleet4Power =
        spawnEnemyFleet(f1bx, f1by, kraylorResource / 2)
    for _, enemy in ipairs(kraylorFleet4) do
        enemy:orderDefendTarget(kraylorFleet4base)
    end
    table.insert(kraylorFleetList, kraylorFleet4)
    table.insert(kraylorDefensiveFleetList, kraylorFleet4)
    kraylorResource = kraylorResource - kraylorFleet4Power
    repeat
        candidate = kraylorStationList[math.random(1, #kraylorStationList)]
        if
            candidate ~= kraylorFleet1base
            and candidate ~= kraylorFleet2base
            and candidate ~= kraylorFleet3base
            and candidate ~= kraylorFleet4base
        then
            kraylorFleet5base = candidate
        end
    until kraylorFleet5base ~= nil
    local f1bx, f1by = kraylorFleet5base:getPosition()
    kraylorFleet5, kraylorFleet5Power =
        spawnEnemyFleet(f1bx, f1by, kraylorResource)
    for _, enemy in ipairs(kraylorFleet5) do
        enemy:orderDefendTarget(kraylorFleet5base)
    end
    table.insert(kraylorFleetList, kraylorFleet5)
    table.insert(kraylorDefensiveFleetList, kraylorFleet5)
end
function setExuariDefensiveFleet()
    exuariResource = 100 + difficulty * 200
    exuariFleetList = {}
    exuariDefensiveFleetList = {}
    exuariFleet1base = exuariStationList[math.random(1, #exuariStationList)]
    local f1bx, f1by = exuariFleet1base:getPosition()
    exuariFleet1, exuariFleet1Power =
        spawnEnemyFleet(f1bx, f1by, random(90, 130), 1, "Exuari")
    for _, enemy in ipairs(exuariFleet1) do
        enemy:orderDefendTarget(exuariFleet1base)
    end
    table.insert(exuariFleetList, exuariFleet1)
    table.insert(exuariDefensiveFleetList, exuariFleet1)
    exuariResource = exuariResource - exuariFleet1Power
    if exuariResource > 120 then
        exuariFleet2Power = random(80, 120)
    else
        exuariFleet2Power = 120
    end
    repeat
        candidate = exuariStationList[math.random(1, #exuariStationList)]
        if candidate ~= exuariFleet1base then
            exuariFleet2base = candidate
        end
    until exuariFleet2base ~= nil
    local f1bx, f1by = exuariFleet2base:getPosition()
    exuariFleet2, exuariFleet2Power =
        spawnEnemyFleet(f1bx, f1by, exuariFleet2Power, 1, "Exuari")
    for _, enemy in ipairs(exuariFleet2) do
        enemy:orderDefendTarget(exuariFleet2base)
    end
    table.insert(exuariFleetList, exuariFleet2)
    table.insert(exuariDefensiveFleetList, exuariFleet2)
    exuariResource = exuariResource - exuariFleet2Power
    if exuariResource > 120 then
        exuariFleet3Power = random(80, 120)
    else
        exuariFleet3Power = 120
    end
    repeat
        candidate = exuariStationList[math.random(1, #exuariStationList)]
        if candidate ~= exuariFleet1base and candidate ~= exuariFleet2base then
            exuariFleet3base = candidate
        end
    until exuariFleet3base ~= nil
    local f1bx, f1by = exuariFleet3base:getPosition()
    exuariFleet3, exuariFleet3Power =
        spawnEnemyFleet(f1bx, f1by, exuariFleet3Power, 1, "Exuari")
    for _, enemy in ipairs(exuariFleet3) do
        enemy:orderDefendTarget(exuariFleet3base)
    end
    table.insert(exuariFleetList, exuariFleet3)
    table.insert(exuariDefensiveFleetList, exuariFleet3)
    exuariResource = exuariResource - exuariFleet3Power
    repeat
        candidate = exuariStationList[math.random(1, #exuariStationList)]
        if
            candidate ~= exuariFleet1base
            and candidate ~= exuariFleet2base
            and candidate ~= exuariFleet3base
        then
            exuariFleet4base = candidate
        end
    until exuariFleet4base ~= nil
    local f1bx, f1by = exuariFleet4base:getPosition()
    exuariFleet4, exuariFleet4Power =
        spawnEnemyFleet(f1bx, f1by, exuariResource / 2, 1, "Exuari")
    for _, enemy in ipairs(exuariFleet4) do
        enemy:orderDefendTarget(exuariFleet4base)
    end
    table.insert(exuariFleetList, exuariFleet4)
    table.insert(exuariDefensiveFleetList, exuariFleet4)
    exuariResource = exuariResource - exuariFleet4Power
    repeat
        candidate = exuariStationList[math.random(1, #exuariStationList)]
        if
            candidate ~= exuariFleet1base
            and candidate ~= exuariFleet2base
            and candidate ~= exuariFleet3base
            and candidate ~= exuariFleet4base
        then
            exuariFleet5base = candidate
        end
    until exuariFleet5base ~= nil
    local f1bx, f1by = exuariFleet5base:getPosition()
    exuariFleet5, exuariFleet5Power =
        spawnEnemyFleet(f1bx, f1by, exuariResource, 1, "Exuari")
    for _, enemy in ipairs(exuariFleet5) do
        enemy:orderDefendTarget(exuariFleet5base)
    end
    table.insert(exuariFleetList, exuariFleet5)
    table.insert(exuariDefensiveFleetList, exuariFleet5)
end
function setArlenianDefensiveFleet()
    arlenianResource = 100 + difficulty * 200
    arlenianFleetList = {}
    arlenianDefensiveFleetList = {}
    arlenianFleet1base =
        arlenianStationList[math.random(1, #arlenianStationList)]
    local f1bx, f1by = arlenianFleet1base:getPosition()
    arlenianFleet1, arlenianFleet1Power =
        spawnEnemyFleet(f1bx, f1by, random(90, 130), 1, "Arlenians")
    for _, enemy in ipairs(arlenianFleet1) do
        enemy:orderDefendTarget(arlenianFleet1base)
    end
    table.insert(arlenianFleetList, arlenianFleet1)
    table.insert(arlenianDefensiveFleetList, arlenianFleet1)
    arlenianResource = arlenianResource - arlenianFleet1Power
    if arlenianResource > 120 then
        arlenianFleet2Power = random(80, 120)
    else
        arlenianFleet2Power = 120
    end
    repeat
        candidate = arlenianStationList[math.random(1, #arlenianStationList)]
        if candidate ~= arlenianFleet1base then
            arlenianFleet2base = candidate
            arlenian_fleet_base_2_name = arlenianFleet2base:getCallSign()
        end
    until arlenianFleet2base ~= nil
    local f1bx, f1by = arlenianFleet2base:getPosition()
    arlenianFleet2, arlenianFleet2Power =
        spawnEnemyFleet(f1bx, f1by, arlenianFleet2Power, 1, "Arlenians")
    for _, enemy in ipairs(arlenianFleet2) do
        enemy:orderDefendTarget(arlenianFleet2base)
    end
    table.insert(arlenianFleetList, arlenianFleet2)
    table.insert(arlenianDefensiveFleetList, arlenianFleet2)
    arlenianResource = arlenianResource - arlenianFleet2Power
    if arlenianResource > 120 then
        arlenianFleet3Power = random(80, 120)
    else
        arlenianFleet3Power = 120
    end
    repeat
        candidate = arlenianStationList[math.random(1, #arlenianStationList)]
        if
            candidate ~= arlenianFleet1base
            and candidate ~= arlenianFleet2base
        then
            arlenianFleet3base = candidate
        end
    until arlenianFleet3base ~= nil
    local f1bx, f1by = arlenianFleet3base:getPosition()
    arlenianFleet3, arlenianFleet3Power =
        spawnEnemyFleet(f1bx, f1by, arlenianFleet3Power, 1, "Arlenians")
    for _, enemy in ipairs(arlenianFleet3) do
        enemy:orderDefendTarget(arlenianFleet3base)
    end
    table.insert(arlenianFleetList, arlenianFleet3)
    table.insert(arlenianDefensiveFleetList, arlenianFleet3)
    arlenianResource = arlenianResource - arlenianFleet3Power
    repeat
        candidate = arlenianStationList[math.random(1, #arlenianStationList)]
        if
            candidate ~= arlenianFleet1base
            and candidate ~= arlenianFleet2base
            and candidate ~= arlenianFleet3base
        then
            arlenianFleet4base = candidate
        end
    until arlenianFleet4base ~= nil
    local f1bx, f1by = arlenianFleet4base:getPosition()
    arlenianFleet4, arlenianFleet4Power =
        spawnEnemyFleet(f1bx, f1by, arlenianResource / 2, 1, "Arlenians")
    for _, enemy in ipairs(arlenianFleet4) do
        enemy:orderDefendTarget(arlenianFleet4base)
    end
    table.insert(arlenianFleetList, arlenianFleet4)
    table.insert(arlenianDefensiveFleetList, arlenianFleet4)
    arlenianResource = arlenianResource - arlenianFleet4Power
    repeat
        candidate = arlenianStationList[math.random(1, #arlenianStationList)]
        if
            candidate ~= arlenianFleet1base
            and candidate ~= arlenianFleet2base
            and candidate ~= arlenianFleet3base
            and candidate ~= arlenianFleet4base
        then
            arlenianFleet5base = candidate
        end
    until arlenianFleet5base ~= nil
    local f1bx, f1by = arlenianFleet5base:getPosition()
    arlenianFleet5, arlenianFleet5Power =
        spawnEnemyFleet(f1bx, f1by, arlenianResource, 1, "Arlenians")
    for _, enemy in ipairs(arlenianFleet5) do
        enemy:orderDefendTarget(arlenianFleet5base)
    end
    table.insert(arlenianFleetList, arlenianFleet5)
    table.insert(arlenianDefensiveFleetList, arlenianFleet5)
end
function setHumanDefensiveFleet()
    humanResource = 300
    humanFleetList = {}
    humanHelperFleet = {}
    table.insert(humanFleetList, humanHelperFleet)
    humanFleet1base = humanStationList[math.random(1, #humanStationList)]
    local f1bx, f1by = humanFleet1base:getPosition()
    humanFleet1, humanFleet1Power =
        spawnEnemyFleet(f1bx, f1by, random(30, 70), 1, "Human Navy")
    for _, enemy in ipairs(humanFleet1) do
        enemy:orderDefendTarget(humanFleet1base):setScanned(true)
    end
    table.insert(humanFleetList, humanFleet1)
    humanResource = humanResource - humanFleet1Power
    if humanResource > 60 then
        humanFleet2Power = random(40, 60)
    else
        humanFleet2Power = 60
    end
    repeat
        candidate = humanStationList[math.random(1, #humanStationList)]
        if candidate ~= humanFleet1base then
            humanFleet2base = candidate
        end
    until humanFleet2base ~= nil
    local f1bx, f1by = humanFleet2base:getPosition()
    humanFleet2, humanFleet2Power =
        spawnEnemyFleet(f1bx, f1by, humanFleet2Power, 1, "Human Navy")
    for _, enemy in ipairs(humanFleet2) do
        enemy:orderDefendTarget(humanFleet2base):setScanned(true)
    end
    table.insert(humanFleetList, humanFleet2)
    humanResource = humanResource - humanFleet2Power
    if humanResource > 60 then
        humanFleet3Power = random(40, 60)
    else
        humanFleet3Power = 60
    end
    repeat
        candidate = humanStationList[math.random(1, #humanStationList)]
        if candidate ~= humanFleet1base and candidate ~= humanFleet2base then
            humanFleet3base = candidate
        end
    until humanFleet3base ~= nil
    local f1bx, f1by = humanFleet3base:getPosition()
    humanFleet3, humanFleet3Power =
        spawnEnemyFleet(f1bx, f1by, humanFleet3Power, 1, "Human Navy")
    for _, enemy in ipairs(humanFleet3) do
        enemy:orderDefendTarget(humanFleet3base):setScanned(true)
    end
    table.insert(humanFleetList, humanFleet3)
    humanResource = humanResource - humanFleet3Power
    repeat
        candidate = humanStationList[math.random(1, #humanStationList)]
        if
            candidate ~= humanFleet1base
            and candidate ~= humanFleet2base
            and candidate ~= humanFleet3base
        then
            humanFleet4base = candidate
        end
    until humanFleet4base ~= nil
    local f1bx, f1by = humanFleet4base:getPosition()
    humanFleet4, humanFleet4Power =
        spawnEnemyFleet(f1bx, f1by, humanResource / 2, 1, "Human Navy")
    for _, enemy in ipairs(humanFleet4) do
        enemy:orderDefendTarget(humanFleet4base):setScanned(true)
    end
    table.insert(humanFleetList, humanFleet4)
    humanResource = humanResource - humanFleet4Power
    repeat
        candidate = humanStationList[math.random(1, #humanStationList)]
        if
            candidate ~= humanFleet1base
            and candidate ~= humanFleet2base
            and candidate ~= humanFleet3base
            and candidate ~= humanFleet4base
        then
            humanFleet5base = candidate
        end
    until humanFleet5base ~= nil
    local f1bx, f1by = humanFleet5base:getPosition()
    humanFleet5, humanFleet5Power =
        spawnEnemyFleet(f1bx, f1by, humanResource, 1, "Human Navy")
    for _, enemy in ipairs(humanFleet5) do
        enemy:orderDefendTarget(humanFleet5base):setScanned(true)
    end
    table.insert(humanFleetList, humanFleet5)
end
function spawnEnemyFleet(xOrigin, yOrigin, power, danger, enemyFaction)
    if enemyFaction == nil then
        enemyFaction = "Kraylor"
    end
    if danger == nil then
        danger = 1
    end
    enemyStrength = math.max(power * danger * difficulty, 5)
    enemyPosition = 0
    sp = irandom(400, 900) --random spacing of spawned group
    deployConfig = random(1, 100) --randomly choose between squarish formation and hexagonish formation
    enemyList = {}
    fleetPower = 0
    while enemyStrength > 0 do
        shipTemplateType = irandom(1, #stsl)
        while stsl[shipTemplateType] > enemyStrength * 1.1 + 5 do
            shipTemplateType = irandom(1, #stsl)
        end
        fleetPower = fleetPower + stsl[shipTemplateType]
        ship = CpuShip()
            :setFaction(enemyFaction)
            :setTemplate(stnl[shipTemplateType])
            :orderRoaming()
        if enemyFaction == "Kraylor" then
            rawKraylorShipStrength = rawKraylorShipStrength
                + stsl[shipTemplateType]
            ship:onDestruction(kraylorVesselDestroyed)
        elseif enemyFaction == "Human Navy" then
            rawHumanShipStrength = rawHumanShipStrength + stsl[shipTemplateType]
            ship:onDestruction(humanVesselDestroyed)
        elseif enemyFaction == "Exuari" then
            rawExuariShipStrength = rawExuariShipStrength
                + stsl[shipTemplateType]
            ship:onDestruction(exuariVesselDestroyed)
        elseif enemyFaction == "Arlenians" then
            rawArlenianShipStrength = rawArlenianShipStrength
                + stsl[shipTemplateType]
            ship:onDestruction(arlenianVesselDestroyed)
        elseif enemyFaction == "Independent" then
            rawNeutralShipStrength = rawNeutralShipStrength
                + stsl[shipTemplateType]
            ship:onDestruction(neutralVesselDestroyed)
        end
        enemyPosition = enemyPosition + 1
        if deployConfig < 50 then
            ship:setPosition(
                xOrigin + fleetPosDelta1x[enemyPosition] * sp,
                yOrigin + fleetPosDelta1y[enemyPosition] * sp
            )
        else
            ship:setPosition(
                xOrigin + fleetPosDelta2x[enemyPosition] * sp,
                yOrigin + fleetPosDelta2y[enemyPosition] * sp
            )
        end
        ship:setCommsScript(""):setCommsFunction(commsShip)
        table.insert(enemyList, ship)
        enemyStrength = enemyStrength - stsl[shipTemplateType]
    end
    fleetPower = math.max(fleetPower / danger / difficulty, 5)
    return enemyList, fleetPower
end
-----------------------------
-- Station communication  --
-----------------------------
-----------------------------
--  Station communication  --
-----------------------------
local station_profile

local function addMissionDockedReplies()
    if comms_target == professorStation then
        if professorSearch and not professorProvidedPlans then
            addCommsReply(
                _("doomsday-comms", "Tell me about Gregory Unruh"),
                function()
                    setCommsMessage(
                        _(
                            "doomsday-comms",
                            "He's a retired scientist here. He's on C deck if you'd like to visit"
                        )
                    )
                    addCommsReply(
                        _("doomsday-comms", "Visit Gregory Unruh on C deck"),
                        function()
                            setCommsMessage(
                                _(
                                    "doomsday-comms",
                                    "[Gregory Unruh] What can I do for you?"
                                )
                            )
                            addCommsReply(
                                _(
                                    "doomsday-comms",
                                    "We need your plans for a doomsday device defense mechanism"
                                ),
                                function()
                                    setCommsMessage(
                                        _(
                                            "doomsday-comms",
                                            "Ah, I see someone is taking my research seriously. Here is my incomplete prototype along with the plans. You'll notice that certain components are still required."
                                        )
                                    )
                                    professorProvidedPlans = true
                                    player.professor = true
                                end
                            )
                        end
                    )
                end
            )
        end
    end
    if comms_target == doctorStation then
        if doctorSearch and not doctorAssisting then
            addCommsReply(
                _("doctor-comms", "Tell me about Morrigan Thultris"),
                function()
                    setCommsMessage(
                        _("doctor-comms", "She does medical research here")
                    )
                    addCommsReply(
                        _("doctor-comms", "May I speak with her?"),
                        function()
                            setCommsMessage(
                                _(
                                    "doctor-comms",
                                    "She won't come to the communications nexus, but you may visit her in her quarters"
                                )
                            )
                            addCommsReply(
                                _("doctor-comms", "Visit Dr. Thultris"),
                                function()
                                    setCommsMessage(
                                        _(
                                            "doctor-comms",
                                            "[Dr. Thultris behind closed quarters door]\nWho is it?"
                                        )
                                    )
                                    addCommsReply(
                                        string.format(
                                            _(
                                                "doctor-comms",
                                                "I am an officer from the Human Navy ship, %s"
                                            ),
                                            player:getCallSign()
                                        ),
                                        function()
                                            setCommsMessage(
                                                _(
                                                    "doctor-comms",
                                                    "[Dr. Thultris behind closed quarters door]\nWhat do you want?"
                                                )
                                            )
                                            addCommsReply(
                                                _(
                                                    "doctor-comms",
                                                    "We need your help"
                                                ),
                                                function()
                                                    if
                                                        random(1, 4)
                                                            + doctorRejectionCount
                                                        >= 3
                                                    then
                                                        setCommsMessage(
                                                            _(
                                                                "doctor-comms",
                                                                "[Dr. Thultris opens her door]\nWith what?"
                                                            )
                                                        )
                                                        addCommsReply(
                                                            _(
                                                                "doctor-comms",
                                                                "Grab Dr. Thultris"
                                                            ),
                                                            function()
                                                                if
                                                                    random(1, 4)
                                                                    >= 3
                                                                then
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "As you pull her down the corridor back to the ship, explaining why you've come for her, she protests initially then eventually runs back with you, convinced of the urgency of the situation"
                                                                        )
                                                                    )
                                                                    player.doctorAboard =
                                                                        true
                                                                    doctorAssisting =
                                                                        true
                                                                else
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "She slams the door in your face as you reach for her"
                                                                        )
                                                                    )
                                                                    doctorRejectionCount =
                                                                        0
                                                                end
                                                            end
                                                        )
                                                        addCommsReply(
                                                            _(
                                                                "doctor-comms",
                                                                "A dying patient needs your expertise"
                                                            ),
                                                            function()
                                                                if
                                                                    random(
                                                                            1,
                                                                            4
                                                                        )
                                                                        + doctorRejectionCount
                                                                    >= 3
                                                                then
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "[Dr. Thultris] Then let's get going to help the patient\n\nAs you both return, you explain the situation to her"
                                                                        )
                                                                    )
                                                                    player.doctorAboard =
                                                                        true
                                                                    doctorAssisting =
                                                                        true
                                                                else
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "People die all the time\n[Dr. Thultris closes her door]"
                                                                        )
                                                                    )
                                                                    doctorRejectionCount = doctorRejectionCount
                                                                        + 1
                                                                end
                                                            end
                                                        )
                                                        addCommsReply(
                                                            _(
                                                                "doctor-comms",
                                                                "An Arlenian Admiral shows symptoms like those you published"
                                                            ),
                                                            function()
                                                                if
                                                                    random(
                                                                            1,
                                                                            4
                                                                        )
                                                                        + doctorRejectionCount
                                                                    >= 3
                                                                then
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "[Dr. Thultris] Take me to the admiral\n\nAs you both return to the ship, you explain the situation to her"
                                                                        )
                                                                    )
                                                                    player.doctorAboard =
                                                                        true
                                                                    doctorAssisting =
                                                                        true
                                                                else
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "An Arlenian Admiral? Who cares!\n[Dr. Thultris closes her door]"
                                                                        )
                                                                    )
                                                                    doctorRejectionCount = doctorRejectionCount
                                                                        + 1
                                                                end
                                                            end
                                                        )
                                                    else
                                                        setCommsMessage(
                                                            _(
                                                                "doctor-comms",
                                                                "[Dr. Thultris behind closed quarters door]\nGo away, I'm busy"
                                                            )
                                                        )
                                                        doctorRejectionCount = doctorRejectionCount
                                                            + 1
                                                    end
                                                end
                                            )
                                            addCommsReply(
                                                _(
                                                    "doctor-comms",
                                                    "Medical team suggested your research for a patient"
                                                ),
                                                function()
                                                    if
                                                        random(1, 4)
                                                            + doctorRejectionCount
                                                        >= 3
                                                    then
                                                        setCommsMessage(
                                                            _(
                                                                "doctor-comms",
                                                                "[Dr. Thultris opens her door]\nHow does my research apply to a patient?"
                                                            )
                                                        )
                                                        addCommsReply(
                                                            _(
                                                                "Doctor-comms",
                                                                "Grab Dr. Thultris"
                                                            ),
                                                            function()
                                                                if
                                                                    random(1, 4)
                                                                    >= 3
                                                                then
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "As you pull her down the corridor back to the ship, explaining why you've come for her, she protests initially then eventually runs back with you, convinced of the urgency of the situation"
                                                                        )
                                                                    )
                                                                    player.doctorAboard =
                                                                        true
                                                                    doctorAssisting =
                                                                        true
                                                                else
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "She slams the door in your face as you reach for her"
                                                                        )
                                                                    )
                                                                    doctorRejectionCount =
                                                                        0
                                                                end
                                                            end
                                                        )
                                                        addCommsReply(
                                                            _(
                                                                "doctor-comms",
                                                                "The symptoms closely correlate to your research"
                                                            ),
                                                            function()
                                                                if
                                                                    random(
                                                                            1,
                                                                            4
                                                                        )
                                                                        + doctorRejectionCount
                                                                    >= 3
                                                                then
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "[Dr. Thultris] I think I can help\n\nAs you both return, you explain the situation to her"
                                                                        )
                                                                    )
                                                                    player.doctorAboard =
                                                                        true
                                                                    doctorAssisting =
                                                                        true
                                                                else
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "Let me know what happens with the patient\n[Dr. Thultris closes her door]"
                                                                        )
                                                                    )
                                                                    doctorRejectionCount = doctorRejectionCount
                                                                        + 1
                                                                end
                                                            end
                                                        )
                                                        addCommsReply(
                                                            _(
                                                                "doctor-comms",
                                                                "Your research may save an Arlenian Admiral's life"
                                                            ),
                                                            function()
                                                                if
                                                                    random(
                                                                            1,
                                                                            4
                                                                        )
                                                                        + doctorRejectionCount
                                                                    >= 3
                                                                then
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "[Dr. Thultris] I would love to apply my research\n\nAs you both return, you explain the situation to her"
                                                                        )
                                                                    )
                                                                    player.doctorAboard =
                                                                        true
                                                                    doctorAssisting =
                                                                        true
                                                                else
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "Diplomacy and military matters bore me\n[Dr. Thultris closes her door]"
                                                                        )
                                                                    )
                                                                    doctorRejectionCount = doctorRejectionCount
                                                                        + 1
                                                                end
                                                            end
                                                        )
                                                    else
                                                        setCommsMessage(
                                                            _(
                                                                "doctor-comms",
                                                                "[Dr. Thultris behind closed quarters door]\nThat's nice. Leave me alone"
                                                            )
                                                        )
                                                        doctorRejectionCount = doctorRejectionCount
                                                            + 1
                                                    end
                                                end
                                            )
                                            addCommsReply(
                                                _(
                                                    "doctor-comms",
                                                    "Arlenian with an unusual disease is near death"
                                                ),
                                                function()
                                                    if
                                                        random(1, 4)
                                                            + doctorRejectionCount
                                                        >= 3
                                                    then
                                                        setCommsMessage(
                                                            _(
                                                                "doctor-comms",
                                                                "[Dr. Thultris opens her door]\nWhy come to me?"
                                                            )
                                                        )
                                                        addCommsReply(
                                                            _(
                                                                "doctor-comms",
                                                                "Grab Dr. Thultris"
                                                            ),
                                                            function()
                                                                if
                                                                    random(1, 4)
                                                                    >= 3
                                                                then
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "As you pull her down the corridor back to the ship, explaining why you've come for her, she protests initially then eventually runs back with you, convinced of the urgency of the situation"
                                                                        )
                                                                    )
                                                                    player.doctorAboard =
                                                                        true
                                                                    doctorAssisting =
                                                                        true
                                                                else
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "She slams the door in your face as you reach for her"
                                                                        )
                                                                    )
                                                                    doctorRejectionCount =
                                                                        0
                                                                end
                                                            end
                                                        )
                                                        addCommsReply(
                                                            _(
                                                                "doctor-comms",
                                                                "The Arlenian medical team referred us to you"
                                                            ),
                                                            function()
                                                                if
                                                                    random(
                                                                            1,
                                                                            4
                                                                        )
                                                                        + doctorRejectionCount
                                                                    >= 3
                                                                then
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "[Dr. Thultris] Nice to be recognized outside of human space\n\nAs you both return, you explain the situation to her"
                                                                        )
                                                                    )
                                                                    player.doctorAboard =
                                                                        true
                                                                    doctorAssisting =
                                                                        true
                                                                else
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "What do the Arlenians know?\n[Dr. Thultris closes her door]"
                                                                        )
                                                                    )
                                                                    doctorRejectionCount = doctorRejectionCount
                                                                        + 1
                                                                end
                                                            end
                                                        )
                                                        addCommsReply(
                                                            _(
                                                                "doctor-comms",
                                                                "Your research accurately describes the symptoms"
                                                            ),
                                                            function()
                                                                if
                                                                    random(
                                                                            1,
                                                                            4
                                                                        )
                                                                        + doctorRejectionCount
                                                                    >= 3
                                                                then
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "[Dr. Thultris] I would like to see the patient\n\nAs you both return, you explain the situation to her"
                                                                        )
                                                                    )
                                                                    player.doctorAboard =
                                                                        true
                                                                    doctorAssisting =
                                                                        true
                                                                else
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "Coincidental, I'm sure\n[Dr. Thultris closes her door]"
                                                                        )
                                                                    )
                                                                    doctorRejectionCount = doctorRejectionCount
                                                                        + 1
                                                                end
                                                            end
                                                        )
                                                    else
                                                        setCommsMessage(
                                                            _(
                                                                "doctor-comms",
                                                                "[Dr. Thultris behind closed quarters door]\nMy condolences. Goodbye"
                                                            )
                                                        )
                                                        doctorRejectionCount = doctorRejectionCount
                                                            + 1
                                                    end
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
                                            "doctor-comms",
                                            "I am an admirer of your research and have questions"
                                        ),
                                        function()
                                            setCommsMessage(
                                                _(
                                                    "doctor-comms",
                                                    "[Dr. Thultris behind closed quarters door]\nReally? What is it about my research you admire?"
                                                )
                                            )
                                            addCommsReply(
                                                _(
                                                    "doctor-comms",
                                                    "The depth of your most recent publication"
                                                ),
                                                function()
                                                    if
                                                        random(1, 4)
                                                            + doctorRejectionCount
                                                        >= 3
                                                    then
                                                        setCommsMessage(
                                                            _(
                                                                "doctor-comms",
                                                                "[Dr. Thultris opens her door]\nWhy does this research interest you?"
                                                            )
                                                        )
                                                        addCommsReply(
                                                            _(
                                                                "doctor-comms",
                                                                "Grab Dr. Thultris"
                                                            ),
                                                            function()
                                                                if
                                                                    random(1, 4)
                                                                    >= 3
                                                                then
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "As you pull her down the corridor back to the ship, explaining why you've come for her, she protests initially then eventually runs back with you, convinced of the urgency of the situation"
                                                                        )
                                                                    )
                                                                    player.doctorAboard =
                                                                        true
                                                                    doctorAssisting =
                                                                        true
                                                                else
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "She slams the door in your face as you reach for her"
                                                                        )
                                                                    )
                                                                    doctorRejectionCount =
                                                                        0
                                                                end
                                                            end
                                                        )
                                                        addCommsReply(
                                                            _(
                                                                "doctor-comms",
                                                                "I know of a patient that might benefit"
                                                            ),
                                                            function()
                                                                if
                                                                    random(
                                                                            1,
                                                                            4
                                                                        )
                                                                        + doctorRejectionCount
                                                                    >= 3
                                                                then
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "[Dr. Thultris] Those are rare. May I see the patient?\n\nAs you both return, you explain the situation to her"
                                                                        )
                                                                    )
                                                                    player.doctorAboard =
                                                                        true
                                                                    doctorAssisting =
                                                                        true
                                                                else
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "My research is unlikely to apply\n[Dr. Thultris closes her door]"
                                                                        )
                                                                    )
                                                                    doctorRejectionCount = doctorRejectionCount
                                                                        + 1
                                                                end
                                                            end
                                                        )
                                                        addCommsReply(
                                                            _(
                                                                "doctor-comms",
                                                                "Your research could help a sick Arlenian Admiral"
                                                            ),
                                                            function()
                                                                if
                                                                    random(
                                                                            1,
                                                                            4
                                                                        )
                                                                        + doctorRejectionCount
                                                                    >= 3
                                                                then
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "[Dr. Thultris] I would like to see my research in the Arlenian context\n\nAs you both return, you explain the situation to her"
                                                                        )
                                                                    )
                                                                    player.doctorAboard =
                                                                        true
                                                                    doctorAssisting =
                                                                        true
                                                                else
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "I don't think it applies to Arlenians\n[Dr. Thultris closes her door]"
                                                                        )
                                                                    )
                                                                    doctorRejectionCount = doctorRejectionCount
                                                                        + 1
                                                                end
                                                            end
                                                        )
                                                    else
                                                        setCommsMessage(
                                                            _(
                                                                "doctor-comms",
                                                                "[Dr. Thultris behind closed quarters door]\nPublish a review and we'll talk"
                                                            )
                                                        )
                                                        doctorRejectionCount = doctorRejectionCount
                                                            + 1
                                                    end
                                                end
                                            )
                                            addCommsReply(
                                                _(
                                                    "doctor-comms",
                                                    "The breadth of knowledge you demonstrate"
                                                ),
                                                function()
                                                    if
                                                        random(1, 4)
                                                            + doctorRejectionCount
                                                        >= 3
                                                    then
                                                        setCommsMessage(
                                                            _(
                                                                "doctor-comms",
                                                                "[Dr. Thultris opens her door]\nI doubt that. Why are you *really* here?"
                                                            )
                                                        )
                                                        addCommsReply(
                                                            _(
                                                                "doctor-comms",
                                                                "Grab Dr. Thultris"
                                                            ),
                                                            function()
                                                                if
                                                                    random(1, 4)
                                                                    >= 3
                                                                then
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "As you pull her down the corridor back to the ship, explaining why you've come for her, she protests initially then eventually runs back with you, convinced of the urgency of the situation"
                                                                        )
                                                                    )
                                                                    player.doctorAboard =
                                                                        true
                                                                    doctorAssisting =
                                                                        true
                                                                else
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "She slams the door in your face as you reach for her"
                                                                        )
                                                                    )
                                                                    doctorRejectionCount =
                                                                        0
                                                                end
                                                            end
                                                        )
                                                        addCommsReply(
                                                            _(
                                                                "doctor-comms",
                                                                "We need your help with a dying Arlenian Admiral"
                                                            ),
                                                            function()
                                                                if
                                                                    random(
                                                                            1,
                                                                            4
                                                                        )
                                                                        + doctorRejectionCount
                                                                    >= 3
                                                                then
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "[Dr. Thultris] Why didn't you say so? Of course I'll help\n\nAs you both return, you explain the situation to her"
                                                                        )
                                                                    )
                                                                    player.doctorAboard =
                                                                        true
                                                                    doctorAssisting =
                                                                        true
                                                                else
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "Your first story was better\n[Dr. Thultris closes her door]"
                                                                        )
                                                                    )
                                                                    doctorRejectionCount = doctorRejectionCount
                                                                        + 1
                                                                end
                                                            end
                                                        )
                                                        addCommsReply(
                                                            _(
                                                                "doctor-comms",
                                                                "An Arlenian medical team thinks you can help a dying patient"
                                                            ),
                                                            function()
                                                                if
                                                                    random(
                                                                            1,
                                                                            4
                                                                        )
                                                                        + doctorRejectionCount
                                                                    >= 3
                                                                then
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "[Dr. Thultris] That's reasonable. Let's go\n\nAs you both return, you explain the situation to her"
                                                                        )
                                                                    )
                                                                    player.doctorAboard =
                                                                        true
                                                                    doctorAssisting =
                                                                        true
                                                                else
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "I'm not concerned with Arlenian patients\n[Dr. Thultris closes her door]"
                                                                        )
                                                                    )
                                                                    doctorRejectionCount = doctorRejectionCount
                                                                        + 1
                                                                end
                                                            end
                                                        )
                                                    else
                                                        setCommsMessage(
                                                            _(
                                                                "doctor-comms",
                                                                "[Dr. Thultris behind closed quarters door]\nFaint praise insults me. Go away"
                                                            )
                                                        )
                                                        doctorRejectionCount = doctorRejectionCount
                                                            + 1
                                                    end
                                                end
                                            )
                                            addCommsReply(
                                                _(
                                                    "doctor-comms",
                                                    "Your superb publication presentation"
                                                ),
                                                function()
                                                    if
                                                        random(1, 4)
                                                            + doctorRejectionCount
                                                        >= 3
                                                    then
                                                        setCommsMessage(
                                                            _(
                                                                "doctor-comms",
                                                                "[Dr. Thultris opens her door]\nHa! Is that why you're here?"
                                                            )
                                                        )
                                                        addCommsReply(
                                                            _(
                                                                "doctor-comms",
                                                                "Grab Dr. Thultris"
                                                            ),
                                                            function()
                                                                if
                                                                    random(1, 4)
                                                                    >= 3
                                                                then
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "As you pull her down the corridor back to the ship, explaining why you've come for her, she protests initially then eventually runs back with you, convinced of the urgency of the situation"
                                                                        )
                                                                    )
                                                                    player.doctorAboard =
                                                                        true
                                                                    doctorAssisting =
                                                                        true
                                                                else
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "She slams the door in your face as you reach for her"
                                                                        )
                                                                    )
                                                                    doctorRejectionCount =
                                                                        0
                                                                end
                                                            end
                                                        )
                                                        addCommsReply(
                                                            _(
                                                                "doctor-comms",
                                                                "Not really. We need your help"
                                                            ),
                                                            function()
                                                                if
                                                                    random(
                                                                            1,
                                                                            4
                                                                        )
                                                                        + doctorRejectionCount
                                                                    >= 3
                                                                then
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "[Dr. Thultris] Why didn't you say so? Of course I'll help\n\nAs you both return, you explain the situation to her"
                                                                        )
                                                                    )
                                                                    player.doctorAboard =
                                                                        true
                                                                    doctorAssisting =
                                                                        true
                                                                else
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "I'm sorry, but I'm too busy right now\n[Dr. Thultris closes her door]"
                                                                        )
                                                                    )
                                                                    doctorRejectionCount = doctorRejectionCount
                                                                        + 1
                                                                end
                                                            end
                                                        )
                                                        addCommsReply(
                                                            _(
                                                                "doctor-comms",
                                                                "Of course! I've got a case study for you to examine"
                                                            ),
                                                            function()
                                                                if
                                                                    random(
                                                                            1,
                                                                            4
                                                                        )
                                                                        + doctorRejectionCount
                                                                    >= 3
                                                                then
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "[Dr. Thultris] An application for my research?! Goody Goody!\n\nAs you both return, you explain the situation to her"
                                                                        )
                                                                    )
                                                                    player.doctorAboard =
                                                                        true
                                                                    doctorAssisting =
                                                                        true
                                                                else
                                                                    setCommsMessage(
                                                                        _(
                                                                            "doctor-comms",
                                                                            "Sounds interesting, but not right now, thanks\n[Dr. Thultris closes her door]"
                                                                        )
                                                                    )
                                                                    doctorRejectionCount = doctorRejectionCount
                                                                        + 1
                                                                end
                                                            end
                                                        )
                                                    else
                                                        setCommsMessage(
                                                            _(
                                                                "doctor-comms",
                                                                "[Dr. Thultris behind closed quarters door]\nGet a writing advisor and get out of here"
                                                            )
                                                        )
                                                        doctorRejectionCount = doctorRejectionCount
                                                            + 1
                                                    end
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
                            addCommsReply(_("Back"), commsStation)
                        end
                    )
                    addCommsReply(_("Back"), commsStation)
                end
            )
        end
    end
    if comms_target.character ~= nil then
        addCommsReply(
            string.format(
                _("characterInfo-comms", "Tell me about %s"),
                comms_target.character
            ),
            function()
                if comms_target.characterDescription ~= nil then
                    setCommsMessage(comms_target.characterDescription)
                else
                    if comms_target.characterDeadEnd == nil then
                        local deadEndChoice = math.random(1, 5)
                        if deadEndChoice == 1 then
                            comms_target.characterDeadEnd = string.format(
                                _("characterInfo-comms", "Never heard of %s"),
                                comms_target.character
                            )
                        elseif deadEndChoice == 2 then
                            comms_target.characterDeadEnd = string.format(
                                _(
                                    "characterInfo-comms",
                                    "%s died last week. The funeral was yesterday"
                                ),
                                comms_target.character
                            )
                        elseif deadEndChoice == 3 then
                            comms_target.characterDeadEnd = string.format(
                                _(
                                    "characterInfo-comms",
                                    "%s? Who's %s? There's nobody here named %s"
                                ),
                                comms_target.character,
                                comms_target.character,
                                comms_target.character
                            )
                        elseif deadEndChoice == 4 then
                            comms_target.characterDeadEnd = string.format(
                                _(
                                    "characterInfo-comms",
                                    "We don't talk about %s. They are gone and good riddance"
                                ),
                                comms_target.character
                            )
                        else
                            comms_target.characterDeadEnd = string.format(
                                _(
                                    "characterInfo-comms",
                                    "I think %s moved away"
                                ),
                                comms_target.character
                            )
                        end
                    end
                    setCommsMessage(comms_target.characterDeadEnd)
                end
                addCommsReply(_("Back"), commsStation)
            end
        )
    end
end

local function addArlenianPath()
    if comms_target:getFaction() == "Arlenians" then
        if scarceResources then
            addCommsReply(_("path-comms", "Where is Bespin?"), function()
                if
                    stationCloudCity ~= nil
                    and stationCloudCity:isValid()
                    and stationCloudCity:areEnemiesInRange(30000)
                then
                    setCommsMessage(
                        string.format(
                            _(
                                "path-comms",
                                "Bespin is in %s and enemies are within 30U of Cloud City"
                            ),
                            planetBespin:getSectorName()
                        )
                    )
                else
                    setCommsMessage(
                        string.format(
                            _("path-comms", "Bespin is in %s"),
                            planetBespin:getSectorName()
                        )
                    )
                end
                addCommsReply(_("Back"), commsStation)
            end)
        end
    end
end

local function addGoodsExplanation()
        addCommsReply(
            _(
                "explainGoods-comms",
                "No tutorial covered goods or cargo. Explain"
            ),
            function()
                setCommsMessage(
                    _(
                        "explainGoods-comms",
                        "Different types of cargo or goods may be obtained from stations, freighters or other sources. They go by one word descriptions such as dilithium, optic, warp, etc. Certain mission goals may require a particular type or types of cargo. Each player ship differs in cargo carrying capacity. Goods may be obtained by spending reputation points or by trading other types of cargo (typically food, medicine or luxury)"
                    )
                )
                addCommsReply(
                    _(
                        "explainGoodsComponent-comms",
                        "Explain the component goods"
                    ),
                    explainComponents
                )
                addCommsReply(
                    _("explainGoodsMineral-comms", "Explain the mineral goods"),
                    explainMinerals
                )
                addCommsReply(
                    _("explainGoodsTrade-comms", "Explain the trade goods"),
                    explainTradeGoods
                )
                addCommsReply(
                    _("explainGoodsVapor-comms", "Explain vapor goods"),
                    function()
                        setCommsMessage(
                            _(
                                "explainGoodsVapor-comms",
                                "On rare occasions, the system cannot determine an appropriate good. In that case one of these 'vapor' or fake goods will be listed:\n   gold pressed latinum, unobtanium, eludium, impossibrium\n\nIf you see one of these, that means that the good is not available. The need or desire for that good will go unmet or the mission will have to be satisfied in some other fashion."
                            )
                        )
                        addCommsReply(_("Back"), commsStation)
                    end
                )
                addCommsReply(_("Back"), commsStation)
            end
        )
end

function explainComponents()
    local component_goods_explanation = {
        ["impulse"] = _(
            "explainGoodsComponent-comms",
            "Technicians use impulse components to fix or enhance impulse engines or related impulse systems."
        ),
        ["warp"] = _(
            "explainGoodsComponent-comms",
            "Engineers use warp components to fix or enhance warp engines, warp cores and/or other related warp technology based systems."
        ),
        ["shield"] = _(
            "explainGoodsComponent-comms",
            "Technicians use shield components to enhance or fix shield capacitors, shield charging systems and other shield or energy field generation systems."
        ),
        ["tractor"] = _(
            "explainGoodsComponent-comms",
            "Engineers and technicians use tractor components to repair or enhance systems designed to pull objects towards the ship."
        ),
        ["repulsor"] = _(
            "explainGoodsComponent-comms",
            "Technicians use repulsor components to repair or enhance systems designed to move objects away from the ship."
        ),
        ["beam"] = _(
            "explainGoodsComponent-comms",
            "Engineers and weapon systems repair specialists use beam components to fix, improve and/or tune beam weapons or related beam systems."
        ),
        ["optic"] = _(
            "explainGoodsComponent-comms",
            "Repair crew use optic components in a variety of ship systems. Optic components serve as the information pathways and linkages between many ship systems"
        ),
        ["robotic"] = _(
            "explainGoodsComponent-comms",
            "Engineers often use robotic components to facilitate missile loading. Other typical systems needing robotic components include medical bays, food preparation, automated repair systems, etc."
        ),
        ["filament"] = _(
            "explainGoodsComponent-comms",
            "Some of the esoteric ship systems have specialized material requirements. These are typically satisfied with a filament component of some kind"
        ),
        ["transporter"] = _(
            "explainGoodsComponent-comms",
            "Engineers use transporter components to fix systems designed to move objects from one location to another. The movement methods range from simple belt rollers to atomic disassembly and reassembly."
        ),
        ["sensor"] = _(
            "explainGoodsComponent-comms",
            "Repair crew use sensor components to fix or repair those systems that support the Science console in gathering information about the universe around the ship."
        ),
        ["communication"] = _(
            "explainGoodsComponent-comms",
            "Technicians use communication components to fix the various systems used to connect the ship to other ships, stations and/or alien entities on the Relay console."
        ),
        ["autodoc"] = _(
            "explainGoodsComponent-comms",
            "Technicians use autodoc components to repair or maintain the automated medical facilities used on many ships in place of a medical doctor or medical staff."
        ),
        ["lifter"] = _(
            "explainGoodsComponent-comms",
            "Engineers need lifter components for a variety of systems needing to temporarily move mechanisms or portions of mechanisms against the acceleration or gravity aboard a ship."
        ),
        ["android"] = _(
            "explainGoodsComponent-comms",
            "Engineers use android components to build, repair and maintain androids that serve on ships. Repair crews on many ships consist largely of androids."
        ),
        ["nanites"] = _(
            "explainGoodsComponent-comms",
            "Technicians and engineers use nanites in a number of systems including shield, reactor, impulse engines, jump drives and warp drives. The nanites are programmed to fix things at the molecular level, often in conditions hazardous to organic beings such as humans."
        ),
        ["software"] = _(
            "explainGoodsComponent-comms",
            "With all the automated systems on a ship, technicians often need software components to upgrade or adjust systems."
        ),
        ["circuit"] = _(
            "explainGoodsComponent-comms",
            "Many systems have specialized circuits that need upgrading or replacing via one or more circuit components."
        ),
        ["battery"] = _(
            "explainGoodsComponent-comms",
            "Batteries on a ship range in size from the ones that provide most of the energy to run the ship to tiny ones used in EVA space suits. Battery components help maintain and improve these systems."
        ),
    }
    setCommsMessage(
        _(
            "explainGoodsComponent-comms",
            "These are the typical component goods available. Which one would you like a greater explanation of?"
        )
    )
    for component, explanation in pairs(component_goods_explanation) do
        addCommsReply(component, function()
            setCommsMessage(explanation)
            addCommsReply(_("Back"), commsStation)
        end)
    end
end
function explainTradeGoods()
    setCommsMessage(
        _(
            "explainGoodsTrade-comms",
            "These are the typical trade goods available. Which one would you like a greater explanation of?"
        )
    )
    local trade_goods_explanation = {
        ["food"] = _(
            "explainGoodsTrade-comms",
            "Many people want or need food to sustain themselves or to enjoy. A good Relay officer will try to keep at least one food on board for the potential trade benefit. When offered for sale, it's usually very cheap."
        ),
        ["medicine"] = _(
            "explainGoodsTrade-comms",
            "Many people need medicine to cure illness or symptoms associated with illness. Medicine is almost as cheap as food. The trade benefits are usually very high. A good Relay officer will try to keep at least on medicine on board for the potential trade benefit."
        ),
        ["luxury"] = _(
            "explainGoodsTrade-comms",
            "A luxury good is anything someone considers valuable. Luxury types include jewelry, specialized clothing, rare art, etc. The trade value of luxury is not as high as food or medicine, but can still give some trade benefit. A good Relay officer will be watching for relatively low priced luxury which can be used to trade for higher priced components or minerals."
        ),
    }
    for trade, explanation in pairs(trade_goods_explanation) do
        addCommsReply(trade, function()
            setCommsMessage(explanation)
            addCommsReply(_("Back"), commsStation)
        end)
    end
end
function explainMinerals()
    setCommsMessage(
        _(
            "explainGoodsMineral-comms",
            "These are the typical mineral goods available. Which one would you like a greater explanation of?"
        )
    )
    mineral_goods_explanation = {
        ["nickel"] = _(
            "explainGoodsMineral-comms",
            "Nickel is one of the most common metals found among asteroids. As such, it has become the defacto standard metal for most of the structure of ships."
        ),
        ["platinum"] = _(
            "explainGoodsMineral-comms",
            "Platinum has electronic, explosive and medical applications, so techniciams use it to repair and upgrade a variety of ship systems."
        ),
        ["gold"] = _(
            "explainGoodsMineral-comms",
            "Civilians and military technicians value gold for a variety of reasons including use in jewelry and electronics."
        ),
        ["dilithium"] = _(
            "explainGoodsMineral-comms",
            "Due to its high potential for energy storage, engineers value dilithium in ship engines and shields."
        ),
        ["tritanium"] = _(
            "explainGoodsMineral-comms",
            "Designers and engineers use tritanium in many aspects of ship construction due to how it interacts with warp fields and jump mechanics."
        ),
        ["cobalt"] = _(
            "explainGoodsMineral-comms",
            "Engineers value cobalt due to its magnetic, alloy and energy storage applications."
        ),
    }
    for mineral, explanation in pairs(mineral_goods_explanation) do
        addCommsReply(mineral, function()
            setCommsMessage(explanation)
            addCommsReply(_("Back"), commsStation)
        end)
    end
end
setOptionalOrders = MissionMenu.clearOptionalOrders
function setSecondaryOrders()
    secondaryOrders = ""
end

local function addMissionUndockedInfo()
        if comms_target:getFaction() == "Arlenians" then
            if scarceResources then
                addCommsReply(_("path-comms", "Where is Bespin?"), function()
                    setCommsMessage(
                        string.format(
                            _("path-comms", "Bespin is in %s"),
                            planetBespin:getSectorName()
                        )
                    )
                    addCommsReply(_("Back"), commsStation)
                end)
            end
        end
        if comms_target == professorStation then
            addCommsReply(
                _("doomsday-comms", "Tell me about Gregory Unruh"),
                function()
                    setCommsMessage(
                        _(
                            "doomsday-comms",
                            "He's got nice retirement quarters here"
                        )
                    )
                    addCommsReply(
                        _("doomsday-comms", "May we speak with him?"),
                        function()
                            setCommsMessage(
                                _(
                                    "doomsday-comms",
                                    "He won't talk with anyone from the Human Navy. He's still bitter over early retirement. You'll need to visit in person"
                                )
                            )
                            addCommsReply(_("Back"), commsStation)
                        end
                    )
                    addCommsReply(_("Back"), commsStation)
                end
            )
        end
        if comms_target == doctorStation then
            addCommsReply(
                _("doctor-comms", "Tell me about Morrigan Thultris"),
                function()
                    setCommsMessage(_("doctor-comms", "She does research here"))
                    addCommsReply(
                        _(
                            "doctor-comms",
                            "We need her skills. May I speak with her?"
                        ),
                        function()
                            setCommsMessage(
                                _(
                                    "doctor-comms",
                                    "She refuses to come to the communications nexus except on her terms. This usually means only outgoing communications. There is a very short list of contacts she will respond to and you are not on that list. If you wish to speak with her, you will need to dock and visit in person"
                                )
                            )
                            addCommsReply(
                                _(
                                    "doctor-comms",
                                    "The Arlenian Admiral is critically ill and she could help"
                                ),
                                function()
                                    setCommsMessage(
                                        _(
                                            "doctor-comms",
                                            "There could be a deadly plague covering all of Human and Arlenian space and she would remain in her quarters tending to her research until the plague destroyed all other personnel on the station. Even then, it might take her a few days to realize everyone else was dead. You really will need to dock to talk to her"
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

local function addCurrentOrders()
        if player:isFriendly(comms_target) then
            addCommsReply(
                _("orders-comms", "What are my current orders?"),
                function()
                    setOptionalOrders()
                    setSecondaryOrders()
                    ordMsg = primaryOrders
                        .. "\n"
                        .. secondaryOrders
                        .. optionalOrders
                    setCommsMessage(ordMsg)
                    addCommsReply(_("Back"), commsStation)
                end
            )
        end
end

commsStation = StationMenu.entrypoint(function() return station_profile end)

local function prepareStation()
    setPlayers()
    for index = 1, 8 do
        local ship = getPlayerShip(index)
        if
            ship ~= nil
            and ship:isValid()
            and ship:isCommsOpening()
        then
            player = ship
        end
    end
    local data = comms_target.comms_data
    if comms_target.publicRelations then
        if comms_target.generalInformation ~= nil then
            data.general = comms_target.generalInformation
        end
        if comms_target.stationHistory ~= nil then
            data.history = comms_target.stationHistory
        end
        if comms_target.gossip ~= nil then
            data.gossip = comms_target.gossip
        end
    end
    if comms_target.character ~= nil then
        data.character = comms_target.character
        data.characterDescription = comms_target.characterDescription
        data.characterDeadEnd = comms_target.characterDeadEnd
    end
    if data.service_cost.phobosReinforcements == nil then
        data.service_cost.phobosReinforcements = math.random(200, 250)
    end
    if data.service_cost.stalkerReinforcements == nil then
        data.service_cost.stalkerReinforcements = math.random(275, 325)
    end
end

local function addLegacyGoods()
    StationGoods.addTrade({
        source = player,
        back = commsStation,
        explain = addGoodsExplanation,
    })
end

station_profile = {
    main_menu = commsStation,
    source = function() return player end,
    prepare = prepareStation,
    weapon_availability = {
        Nuke = 4,
        EMP = 5,
        Homing = 6,
        Mine = 7,
        HVLI = 9,
    },
    goods = {
        menu = addLegacyGoods,
    },
    resources = {
        prompt = false,
        recruitment = {
            mode = "immediate",
            available = function(relationship)
                return relationship == "friendly"
                    and math.random(1, 5) <= (3 - difficulty)
            end,
        },
        coolant = {
            mode = "immediate",
            available = function(relationship)
                return relationship == "friendly"
                    and math.random(1, 5) <= (3 - difficulty)
            end,
        },
    },
    docked = {
        greeting = "fixed",
        show_reputation = false,
        group_services = false,
        service_prompt = false,
        service_sections = { "ordnance" },
        ordnance = {
            back = true,
            refill_scale = function()
                if scarceResources then
                    return 0.5
                end
                return 1
            end,
            suffix = function()
                if scarceResources then
                    return ""
                end
                return _(
                    "ammo-comms",
                    " The Kraylor threat to mineral resources has reduced ordnance availablilty"
                )
            end,
        },
        after_services = function()
            if comms_target.publicRelations then
                StationMenu.gossip(station_profile, { gossip_roll = "half" })
            end
            addMissionDockedReplies()
            addArlenianPath()
        end,
        group_resources = false,
    },
    undocked = {
        information = {
            prompt = _("station-comms", "What kind of information do you need?"),
            sections = {
                { kind = "callback", callback = addMissionUndockedInfo },
                { kind = "character", always = true },
                { kind = "callback", callback = addCurrentOrders },
                { kind = "ordnance" },
                {
                    kind = "callback",
                    callback = function()
                        StationGoods.addAvailability({ back = commsStation })
                    end,
                },
                {
                    kind = "callback",
                    callback = function()
                        StationGoods.addKnowledge({
                            back = commsStation,
                            fill = fillStationBrains,
                        })
                    end,
                },
                {
                    kind = "gossip",
                    gossip_roll = "half",
                    available = function()
                        return comms_target.publicRelations
                    end,
                },
                { kind = "status" },
            },
        },
        supply_drop = {
            label = _(
                "stationAssist-comms",
                "Can you send a supply drop? (%d rep)"
            ),
            waypoint_label = _("stationAssist-comms", "Waypoint %d"),
            dispatch_message = _(
                "stationAssist-comms",
                "We have dispatched a supply ship toward waypoint %d"
            ),
            no_waypoint_message = _(
                "stationAssist-comms",
                "You need to set a waypoint before you can request supplies."
            ),
        },
        reinforcements = {
            {
                service = "reinforcements",
                permission = "reinforcements",
                template = ST.ADDER_MK5,
                label = _(
                    "stationAssist-comms",
                    "Please send Adder MK5 reinforcements! (%d rep)"
                ),
                waypoint_label = _("stationAssist-comms", "Waypoint %d"),
                success_message = _(
                    "stationAssist-comms",
                    "We have dispatched %s to assist at waypoint %d"
                ),
                destruction = humanVesselDestroyed,
            },
            {
                service = "phobosReinforcements",
                permission = "reinforcements",
                template = ST.PHOBOS_T3,
                label = _(
                    "stationAssist-comms",
                    "Please send Phobos T3 reinforcements! (%d rep)"
                ),
                waypoint_label = _("stationAssist-comms", "Waypoint %d"),
                success_message = _(
                    "stationAssist-comms",
                    "We have dispatched %s to assist at waypoint %d"
                ),
                destruction = humanVesselDestroyed,
            },
            {
                service = "stalkerReinforcements",
                permission = "reinforcements",
                template = ST.STALKER_Q7,
                label = _(
                    "stationAssist-comms",
                    "Please send Stalker Q7 reinforcements! (%d rep)"
                ),
                waypoint_label = _("stationAssist-comms", "Waypoint %d"),
                success_message = _(
                    "stationAssist-comms",
                    "We have dispatched %s to assist at waypoint %d"
                ),
                destruction = humanVesselDestroyed,
            },
        },
        assistance = true,
    },
}

commsShip = ShipComms.commsShipGetter(function() return ship_profile end)

ship_profile = {
    source = function()
        return player
    end,
    before_comms = function()
        setPlayers()
        for index = 1, 8 do
            local candidate = getPlayerShip(index)
            if
                candidate ~= nil
                and candidate:isValid()
                and candidate:isCommsOpening()
            then
                player = candidate
            end
        end
    end,
    init_goods = function(comms_target, comms_data)
        if goods[comms_target] == nil then
            goods[comms_target] = {
                { goodsList[irandom(1, #goodsList)][1], 1, random(20, 80) },
            }
        end
    end,
    enemy = function(comms_data)
        return ShipComms.enemyCommsSimple(comms_data, player)
    end,
    main_menu = commsShip,
    inventory = function(owner)
        return goods[owner]
    end,
    inventory_format = "array",
    waypoint_labels = {
        defend = function(waypoint_index, index)
            return string.format(
                _("shipAssist-comms", "Defend waypoint %d"),
                index
            )
        end,
    },
    order_messages = {
        defend = function(index)
            return string.format(
                _(
                    "shipAssist-comms",
                    "We are heading to assist at waypoint %d."
                ),
                index
            )
        end,
    },
    trade = {
        far_cargo_query = false,
        jettison = false,
        require_cargo = false,
        check_inventory = true,
        multiplier = ShipComms.arrayTradeMultiplier,
        luxury_neutral = true,
        luxury_replaces_purchase = true,
        purchase_message = function()
            return _("trade-comms", "Purchased")
        end,
        luxury_message = function()
            return _("trade-comms", "Traded")
        end,
    },
    neutral_before = bespinComms,
    neutral_cargo_query = false,
    neutral_message = ShipComms.freighterNeutralMessage,
    neutral_destination_query = "paid",
}
------------------------
-- Cargo management  --
------------------------
-------------------------
-- Utility functions  --
-------------------------
function createRandomAlongArc(
    object_type,
    amount,
    x,
    y,
    distance,
    startArc,
    endArcClockwise,
    randomize
)
    -- Create amount of objects of type object_type along arc
    -- Center defined by x and y
    -- Radius defined by distance
    -- Start of arc between 0 and 360 (startArc), end arc: endArcClockwise
    -- Use randomize to vary the distance from the center point. Omit to keep distance constant
    -- Example:
    --   createRandomAlongArc(Asteroid, 100, 500, 3000, 65, 120, 450)
    if randomize == nil then
        randomize = 0
    end
    if amount == nil then
        amount = 1
    end
    local arcLen = endArcClockwise - startArc
    if startArc > endArcClockwise then
        endArcClockwise = endArcClockwise + 360
        arcLen = arcLen + 360
    end
    if amount > arcLen then
        for ndex = 1, arcLen do
            local radialPoint = startArc + ndex
            local pointDist = distance + random(-randomize, randomize)
            object_type():setPosition(
                x + math.cos(radialPoint / 180 * math.pi) * pointDist,
                y + math.sin(radialPoint / 180 * math.pi) * pointDist
            )
        end
        for ndex = 1, amount - arcLen do
            radialPoint = random(startArc, endArcClockwise)
            pointDist = distance + random(-randomize, randomize)
            object_type():setPosition(
                x + math.cos(radialPoint / 180 * math.pi) * pointDist,
                y + math.sin(radialPoint / 180 * math.pi) * pointDist
            )
        end
    else
        for ndex = 1, amount do
            radialPoint = random(startArc, endArcClockwise)
            pointDist = distance + random(-randomize, randomize)
            object_type():setPosition(
                x + math.cos(radialPoint / 180 * math.pi) * pointDist,
                y + math.sin(radialPoint / 180 * math.pi) * pointDist
            )
        end
    end
end
function spawnEnemies(xOrigin, yOrigin, danger, enemyFaction)
    if enemyFaction == nil then
        enemyFaction = "Kraylor"
    end
    if danger == nil then
        danger = 1
    end
    local enemyStrength = math.max(danger * difficulty * playerPower(), 5)
    local enemyPosition = 0
    local sp = irandom(400, 900) --random spacing of spawned group
    local deployConfig = random(1, 100) --randomly choose between squarish formation and hexagonish formation
    local enemyList = {}
    -- Reminder: stsl and stnl are ship template score and name list
    while enemyStrength > 0 do
        local shipTemplateType = irandom(1, #stsl)
        while stsl[shipTemplateType] > enemyStrength * 1.1 + 5 do
            shipTemplateType = irandom(1, #stsl)
        end
        local ship = CpuShip()
            :setFaction(enemyFaction)
            :setTemplate(stnl[shipTemplateType])
            :orderRoaming()
        if enemyFaction == "Kraylor" then
            rawKraylorShipStrength = rawKraylorShipStrength
                + stsl[shipTemplateType]
            ship:onDestruction(kraylorVesselDestroyed)
        elseif enemyFaction == "Human Navy" then
            rawHumanShipStrength = rawHumanShipStrength + stsl[shipTemplateType]
            ship:onDestruction(humanVesselDestroyed)
        elseif enemyFaction == "Exuari" then
            rawExuariShipStrength = rawExuariShipStrength
                + stsl[shipTemplateType]
            ship:onDestruction(exuariVesselDestroyed)
        elseif enemyFaction == "Arlenians" then
            rawArlenianShipStrength = rawArlenianShipStrength
                + stsl[shipTemplateType]
            ship:onDestruction(arlenianVesselDestroyed)
        end
        enemyPosition = enemyPosition + 1
        if deployConfig < 50 then
            ship:setPosition(
                xOrigin + fleetPosDelta1x[enemyPosition] * sp,
                yOrigin + fleetPosDelta1y[enemyPosition] * sp
            )
        else
            ship:setPosition(
                xOrigin + fleetPosDelta2x[enemyPosition] * sp,
                yOrigin + fleetPosDelta2y[enemyPosition] * sp
            )
        end
        ship:setCommsScript(""):setCommsFunction(commsShip)
        table.insert(enemyList, ship)
        enemyStrength = enemyStrength - stsl[shipTemplateType]
    end
    return enemyList
end
---------------------------------------------
-- Inventory button for relay/operations  --
---------------------------------------------
function cargoInventory(delta)
    if cargoInventoryList == nil then
        cargoInventoryList = {}
        table.insert(cargoInventoryList, cargoInventory1)
        table.insert(cargoInventoryList, cargoInventory2)
        table.insert(cargoInventoryList, cargoInventory3)
        table.insert(cargoInventoryList, cargoInventory4)
        table.insert(cargoInventoryList, cargoInventory5)
        table.insert(cargoInventoryList, cargoInventory6)
        table.insert(cargoInventoryList, cargoInventory7)
        table.insert(cargoInventoryList, cargoInventory8)
    end
    for pidx = 1, 8 do
        p = getPlayerShip(pidx)
        if p ~= nil and p:isValid() then
            gi = 1
            cargoHoldEmpty = true
            repeat
                playerGoodsType = goods[p][gi][1]
                playerGoodsQuantity = goods[p][gi][2]
                if playerGoodsQuantity > 0 then
                    cargoHoldEmpty = false
                end
                gi = gi + 1
            until gi > #goods[p]
            if not cargoHoldEmpty then
                if p:hasPlayerAtPosition("Relay") then
                    if p.inventoryButton == nil then
                        local tbi = "inventory" .. p:getCallSign()
                        p:addCustomButton(
                            "Relay",
                            tbi,
                            _("inventory-buttonRelay", "Inventory"),
                            cargoInventoryList[pidx]
                        )
                        p.inventoryButton = true
                    end
                end
                if p:hasPlayerAtPosition("Operations") then
                    if p.inventoryButton == nil then
                        local tbi = "inventoryOp" .. p:getCallSign()
                        p:addCustomButton(
                            "Operations",
                            tbi,
                            _("inventory-buttonOperations", "Inventory"),
                            cargoInventoryList[pidx]
                        )
                        p.inventoryButton = true
                    end
                end
            end
        end
    end
end
function cargoInventory1()
    local p = getPlayerShip(1)
    p:addToShipLog(
        string.format(
            _("inventory-shipLog", "%s Current cargo:"),
            p:getCallSign()
        ),
        "Yellow"
    )
    gi = 1
    local cargoHoldEmpty = true
    repeat
        local playerGoodsType = goods[p][gi][1]
        local playerGoodsQuantity = goods[p][gi][2]
        if playerGoodsQuantity > 0 then
            p:addToShipLog(
                string.format(
                    _("inventory-shipLog", "     %s: %i"),
                    playerGoodsType,
                    playerGoodsQuantity
                ),
                "Yellow"
            )
            cargoHoldEmpty = false
        end
        gi = gi + 1
    until gi > #goods[p]
    if cargoHoldEmpty then
        p:addToShipLog(_("inventory-shipLog", "     Empty\n"), "Yellow")
    end
    p:addToShipLog(
        string.format(_("inventory-shipLog", "Available space: %i"), p.cargo),
        "Yellow"
    )
end
function cargoInventory2()
    local p = getPlayerShip(2)
    p:addToShipLog(
        string.format(
            _("inventory-shipLog", "%s Current cargo:"),
            p:getCallSign()
        ),
        "Yellow"
    )
    gi = 1
    local cargoHoldEmpty = true
    repeat
        local playerGoodsType = goods[p][gi][1]
        local playerGoodsQuantity = goods[p][gi][2]
        if playerGoodsQuantity > 0 then
            p:addToShipLog(
                string.format(
                    _("inventory-shipLog", "     %s: %i"),
                    playerGoodsType,
                    playerGoodsQuantity
                ),
                "Yellow"
            )
            cargoHoldEmpty = false
        end
        gi = gi + 1
    until gi > #goods[p]
    if cargoHoldEmpty then
        p:addToShipLog(_("inventory-shipLog", "     Empty\n"), "Yellow")
    end
    p:addToShipLog(
        string.format(_("inventory-shipLog", "Available space: %i"), p.cargo),
        "Yellow"
    )
end
function cargoInventory3()
    local p = getPlayerShip(3)
    p:addToShipLog(
        string.format(
            _("inventory-shipLog", "%s Current cargo:"),
            p:getCallSign()
        ),
        "Yellow"
    )
    gi = 1
    local cargoHoldEmpty = true
    repeat
        local playerGoodsType = goods[p][gi][1]
        local playerGoodsQuantity = goods[p][gi][2]
        if playerGoodsQuantity > 0 then
            p:addToShipLog(
                string.format(
                    _("inventory-shipLog", "     %s: %i"),
                    playerGoodsType,
                    playerGoodsQuantity
                ),
                "Yellow"
            )
            cargoHoldEmpty = false
        end
        gi = gi + 1
    until gi > #goods[p]
    if cargoHoldEmpty then
        p:addToShipLog(_("inventory-shipLog", "     Empty\n"), "Yellow")
    end
    p:addToShipLog(
        string.format(_("inventory-shipLog", "Available space: %i"), p.cargo),
        "Yellow"
    )
end
function cargoInventory4()
    local p = getPlayerShip(4)
    p:addToShipLog(
        string.format(
            _("inventory-shipLog", "%s Current cargo:"),
            p:getCallSign()
        ),
        "Yellow"
    )
    gi = 1
    local cargoHoldEmpty = true
    repeat
        local playerGoodsType = goods[p][gi][1]
        local playerGoodsQuantity = goods[p][gi][2]
        if playerGoodsQuantity > 0 then
            p:addToShipLog(
                string.format(
                    _("inventory-shipLog", "     %s: %i"),
                    playerGoodsType,
                    playerGoodsQuantity
                ),
                "Yellow"
            )
            cargoHoldEmpty = false
        end
        gi = gi + 1
    until gi > #goods[p]
    if cargoHoldEmpty then
        p:addToShipLog(_("inventory-shipLog", "     Empty\n"), "Yellow")
    end
    p:addToShipLog(
        string.format(_("inventory-shipLog", "Available space: %i"), p.cargo),
        "Yellow"
    )
end
function cargoInventory5()
    local p = getPlayerShip(5)
    p:addToShipLog(
        string.format(
            _("inventory-shipLog", "%s Current cargo:"),
            p:getCallSign()
        ),
        "Yellow"
    )
    gi = 1
    local cargoHoldEmpty = true
    repeat
        local playerGoodsType = goods[p][gi][1]
        local playerGoodsQuantity = goods[p][gi][2]
        if playerGoodsQuantity > 0 then
            p:addToShipLog(
                string.format(
                    _("inventory-shipLog", "     %s: %i"),
                    playerGoodsType,
                    playerGoodsQuantity
                ),
                "Yellow"
            )
            cargoHoldEmpty = false
        end
        gi = gi + 1
    until gi > #goods[p]
    if cargoHoldEmpty then
        p:addToShipLog(_("inventory-shipLog", "     Empty\n"), "Yellow")
    end
    p:addToShipLog(
        string.format(_("inventory-shipLog", "Available space: %i"), p.cargo),
        "Yellow"
    )
end
function cargoInventory6()
    local p = getPlayerShip(6)
    p:addToShipLog(
        string.format(
            _("inventory-shipLog", "%s Current cargo:"),
            p:getCallSign()
        ),
        "Yellow"
    )
    gi = 1
    local cargoHoldEmpty = true
    repeat
        local playerGoodsType = goods[p][gi][1]
        local playerGoodsQuantity = goods[p][gi][2]
        if playerGoodsQuantity > 0 then
            p:addToShipLog(
                string.format(
                    _("inventory-shipLog", "     %s: %i"),
                    playerGoodsType,
                    playerGoodsQuantity
                ),
                "Yellow"
            )
            cargoHoldEmpty = false
        end
        gi = gi + 1
    until gi > #goods[p]
    if cargoHoldEmpty then
        p:addToShipLog(_("inventory-shipLog", "     Empty\n"), "Yellow")
    end
    p:addToShipLog(
        string.format(_("inventory-shipLog", "Available space: %i"), p.cargo),
        "Yellow"
    )
end
function cargoInventory7()
    local p = getPlayerShip(7)
    p:addToShipLog(
        string.format(
            _("inventory-shipLog", "%s Current cargo:"),
            p:getCallSign()
        ),
        "Yellow"
    )
    gi = 1
    local cargoHoldEmpty = true
    repeat
        local playerGoodsType = goods[p][gi][1]
        local playerGoodsQuantity = goods[p][gi][2]
        if playerGoodsQuantity > 0 then
            p:addToShipLog(
                string.format(
                    _("inventory-shipLog", "     %s: %i"),
                    playerGoodsType,
                    playerGoodsQuantity
                ),
                "Yellow"
            )
            cargoHoldEmpty = false
        end
        gi = gi + 1
    until gi > #goods[p]
    if cargoHoldEmpty then
        p:addToShipLog(_("inventory-shipLog", "     Empty\n"), "Yellow")
    end
    p:addToShipLog(
        string.format(_("inventory-shipLog", "Available space: %i"), p.cargo),
        "Yellow"
    )
end
function cargoInventory8()
    local p = getPlayerShip(8)
    p:addToShipLog(
        string.format(
            _("inventory-shipLog", "%s Current cargo:"),
            p:getCallSign()
        ),
        "Yellow"
    )
    gi = 1
    local cargoHoldEmpty = true
    repeat
        local playerGoodsType = goods[p][gi][1]
        local playerGoodsQuantity = goods[p][gi][2]
        if playerGoodsQuantity > 0 then
            p:addToShipLog(
                string.format(
                    _("inventory-shipLog", "     %s: %i"),
                    playerGoodsType,
                    playerGoodsQuantity
                ),
                "Yellow"
            )
            cargoHoldEmpty = false
        end
        gi = gi + 1
    until gi > #goods[p]
    if cargoHoldEmpty then
        p:addToShipLog(_("inventory-shipLog", "     Empty\n"), "Yellow")
    end
    p:addToShipLog(
        string.format(_("inventory-shipLog", "Available space: %i"), p.cargo),
        "Yellow"
    )
end
-------------------------------------
-- Coolant buttons and functions  --
-------------------------------------
function coolantNebulae(delta)
    for i, p in ipairs(getActivePlayerShips()) do
        local inside_gain_coolant_nebula = false
        for j, neb in ipairs(coolant_nebula) do
            if neb ~= nil and neb:isValid() then
                if distance(p, neb) < 5000 then
                    if neb.lose then
                        p:setMaxCoolant(p:getMaxCoolant() * coolant_loss)
                    end
                    if neb.gain then
                        inside_gain_coolant_nebula = true
                    end
                end
            end
        end
        if inside_gain_coolant_nebula then
            if p.get_coolant then
                if p.coolant_trigger then
                    updateCoolantGivenPlayer(p, delta)
                end
            else
                p.get_coolant_button = "get_coolant_button"
                p:addCustomButton(
                    "Engineering",
                    p.get_coolant_button,
                    _("coolant-buttonEngineer", "Get Coolant"),
                    function()
                        string.format("")
                        getCoolant(p)
                    end
                )
                p.get_coolant_button_plus = "get_coolant_button_plus"
                p:addCustomButton(
                    "Engineering+",
                    p.get_coolant_button_plus,
                    _("coolant-buttonEngineer+", "Get Coolant"),
                    function()
                        string.format("")
                        getCoolant(p)
                    end
                )
                p.get_coolant = true
            end
        else --not inside coolant gaining nebula
            p.get_coolant = false
            p.coolant_trigger = false
            p.configure_coolant_timer = nil
            p.deploy_coolant_timer = nil
            if p.get_coolant_button ~= nil then
                p:removeCustom(p.get_coolant_button)
                p.get_coolant_button = nil
            end
            if p.gather_coolant ~= nil then
                p:removeCustom(p.gather_coolant)
                p.gather_coolant = nil
            end
            if p.get_coolant_button_plus ~= nil then
                p:removeCustom(p.get_coolant_button_plus)
                p.get_coolant_button_plus = nil
            end
            if p.gather_coolant_plus ~= nil then
                p:removeCustom(p.gather_coolant_plus)
                p.gather_coolant_plus = nil
            end
        end
    end
end
function updateCoolantGivenPlayer(p, delta)
    if p.configure_coolant_timer == nil then
        p.configure_coolant_timer = delta + 5
    end
    p.configure_coolant_timer = p.configure_coolant_timer - delta
    if p.configure_coolant_timer < 0 then
        if p.deploy_coolant_timer == nil then
            p.deploy_coolant_timer = delta + 5
        end
        p.deploy_coolant_timer = p.deploy_coolant_timer - delta
        if p.deploy_coolant_timer < 0 then
            gather_coolant_status =
                _("coolant-tabEngineer", "Gathering Coolant")
            p:setMaxCoolant(p:getMaxCoolant() + coolant_gain)
        else
            gather_coolant_status = string.format(
                _("coolant-tabEngineer", "Deploying Collectors %i"),
                math.ceil(p.deploy_coolant_timer - delta)
            )
        end
    else
        gather_coolant_status = string.format(
            _("coolant-tabEngineer", "Configuring Collectors %i"),
            math.ceil(p.configure_coolant_timer - delta)
        )
    end
    p.gather_coolant = "gather_coolant"
    p:addCustomInfo("Engineering", p.gather_coolant, gather_coolant_status)
    p.gather_coolant_plus = "gather_coolant_plus"
    p:addCustomInfo(
        "Engineering+",
        p.gather_coolant_plus,
        gather_coolant_status
    )
end
function getCoolant(p)
    string.format("")
    p:removeCustom(p.get_coolant_button)
    p:removeCustom(p.get_coolant_button_plus)
    p.coolant_trigger = true
end
--------------------
-- Manage plots  --
--------------------
function setPlots()
    plotList = { miningConflict, sickArlenianAdmiral, doomsday }
    maxPlotCount = #plotList
end
function plotDelay(delta)
    if plotDelayTimer == nil then
        plotDelayTimer = delta + random(10, 30)
    end
    plotDelayTimer = plotDelayTimer - delta
    if plotDelayTimer < 0 then
        plotDelayTimer = nil
        plotManager = plotChoose
    end
end
function plotChoose(delta)
    if onlyOneMission then
        if #plotList < maxPlotCount then
            missionCompleteReason =
                _("msgMainscreen", "Single selected mission completed")
            missionVictory = true
            endStatistics()
            victory("Human Navy")
        else
            plotManager = plotRun
            plotChoice = math.random(1, #plotList)
            plot1 = plotList[plotChoice]
            table.remove(plotList, plotChoice)
        end
    else
        if #plotList < 1 then
            missionCompleteReason = _("msgMainscreen", "All missions completed")
            missionVictory = true
            endStatistics()
            victory("Human Navy")
        else
            plotManager = plotRun
            if nextPlot == nil then
                plotChoice = math.random(1, #plotList)
                plot1 = plotList[plotChoice]
                table.remove(plotList, plotChoice)
            else
                plot1 = nextPlot
                nextPlot = nil
                for i = 1, #plotList do
                    if plotList[i] == nextPlot then
                        table.remove(plotList, i)
                    end
                end
            end
        end
    end
end
function plotRun(delta)
    if plot1 == nil then
        plotManager = plotDelay
    end
end
-----------------------
-- Doomsday device  --
-----------------------
function startDoomsday()
    setUpDoomsday = "done"
    for pidx = 1, 8 do
        p = getPlayerShip(pidx)
        if p ~= nil and p:isValid() then
            p:addToShipLog(
                _(
                    "doomsdayGoal-shipLog",
                    "Intelligence tells us the Exuari have nearly completed a 'doomsday' device. Retired scientist, Gregory Unruh warned us before he retired about this possibility, but we did not take him seriously. He was working on a defense mechanism. Find professor Unruh and get the plans for his defense mechanism"
                ),
                "Magenta"
            )
        end
    end
    primaryOrders = _(
        "doomsdayOrders-comms",
        "Find professor Unruh for doomsday defense mechanism plans"
    )
    local professorStationAttemptCount = 0
    repeat
        professorStation = humanStationList[math.random(1, #humanStationList)]
        professorStationAttemptCount = professorStationAttemptCount + 1
    until (professorStation ~= nil and professorStation:isValid())
        or professorStationAttemptCount > repeatExitBoundary
    if professorStationAttemptCount > repeatExitBoundary then
        if professorDiagnostic then
            print("bad professor station")
        end
        plot1 = nil
        primaryOrders = ""
    else
        if professorDiagnostic then
            print("professor station set")
        end
        professorSearch = true
        professorProvidedPlans = false
        componentsPicked = false
        defenseDeployed = false
        doomsdayDeployed = false
    end
    for i = 1, 3 do
        local clueStationAttemptCount = 0
        repeat
            clueStation = humanStationList[math.random(1, #humanStationList)]
            clueStationAttemptCount = clueStationAttemptCount + 1
        until (
                clueStation ~= nil
                and clueStation:isValid()
                and clueStation ~= professorStation
                and (
                    clueStation.character == nil
                    or clueStation.character == "Morrigan Thultris"
                )
            ) or clueStationAttemptCount > repeatExitBoundary
        if clueStationAttemptCount < repeatExitBoundary then
            clueStation.character = "Gregory Unruh"
            clueStation.characterDescription = string.format(
                _("doomsday-comms", "Gregory Unruh resides on station %s"),
                professorStation:getCallSign()
            )
        end
    end
    if professorDiagnostic then
        print("done with doomsday setup")
    end
    removeGMFunction(GMDoomsday)
end
function doomsday(delta)
    if setUpDoomsday == nil then
        startDoomsday()
    end
    doomsdayTimer = 800 - difficulty * 150
    halfDoom = doomsdayTimer / 2
    quarterDoom = halfDoom / 2
    plot1 = checkDoomsdayEvents
end
function checkDoomsdayEvents(delta)
    doomsdayTimer = doomsdayTimer - delta
    if doomsdayTimer < quarterDoom then
        if exuariRampage == nil then
            exuariRampage = "launched"
            for _, enemy in ipairs(exuariFleet4) do
                enemy:orderRoaming()
            end
            for _, enemy in ipairs(exuariFleet5) do
                enemy:orderRoaming()
            end
            for _, enemy in ipairs(kraylorFleet2) do
                enemy:orderRoaming()
            end
            for _, enemy in ipairs(kraylorFleet3) do
                enemy:orderRoaming()
            end
            for _, enemy in ipairs(kraylorFleet4) do
                enemy:orderRoaming()
            end
            for _, enemy in ipairs(kraylorFleet5) do
                enemy:orderRoaming()
            end
            local pillageAttempt = 0
            repeat
                humanPillageTarget =
                    humanStationList[math.random(1, #humanStationList)]
                pillageAttempt = pillageAttempt + 1
            until (
                    humanPillageTarget ~= nil and humanPillageTarget:isValid()
                ) or pillageAttempt > repeatExitBoundary
            if pillageAttempt <= repeatExitBoundary then
                local tx, ty = humanPillageTarget:getPosition()
                local ox, oy =
                    vectorFromAngle(random(0, 360), random(20000, 30000))
                pillageFleet = spawnEnemies(tx + ox, ty + oy, 1, "Exuari")
                for _, enemy in ipairs(pillageFleet) do
                    enemy:orderFlyTowards(tx, ty)
                end
                table.insert(exuariFleetList, pillageFleet)
                local pillageAttempt = 0
                repeat
                    humanPillageTarget2 =
                        humanStationList[math.random(1, #humanStationList)]
                    pillageAttempt = pillageAttempt + 1
                until (
                        humanPillageTarget2 ~= nil
                        and humanPillageTarget2:isValid()
                        and humanPillageTarget ~= humanPillageTarget2
                    )
                    or pillageAttempt > repeatExitBoundary
                if pillageAttempt <= repeatExitBoundary then
                    local tx, ty = humanPillageTarget2:getPosition()
                    local ox, oy =
                        vectorFromAngle(random(0, 360), random(20000, 30000))
                    pillageFleet = spawnEnemies(tx + ox, ty + oy, 1, "Exuari")
                    for _, enemy in ipairs(pillageFleet) do
                        enemy:orderFlyTowards(tx, ty)
                    end
                    table.insert(exuariFleetList, pillageFleet)
                end
            end
        end
    end
    if doomsdayTimer < halfDoom then
        if doomsdayWarning == nil then
            doomsdayWarning = "sent"
            for pidx = 1, 8 do
                p = getPlayerShip(pidx)
                if p ~= nil and p:isValid() then
                    p:addToShipLog(
                        string.format(
                            _(
                                "doomsday-shipLog",
                                "Intelligence estimates %i minutes remain before the Exuari deploy the doomsday device. Exuari and Kraylors both seem to be on a pillaging rampage"
                            ),
                            math.floor(doomsdayTimer / 60)
                        ),
                        "Magenta"
                    )
                end
            end
        end
    end
    if professorProvidedPlans then
        if componentsPicked then
            primaryOrders = string.format(
                _(
                    "doomsdayOrders-comms",
                    "Get %s, %s and %s to build doomsday defense mechanism"
                ),
                component1,
                component2,
                component3
            )
            if componentMessage1 == nil then
                componentMessage1 = "sent"
                for pidx = 1, 8 do
                    p = getPlayerShip(pidx)
                    if p ~= nil and p:isValid() and p.professor then
                        p:addToShipLog(
                            string.format(
                                _(
                                    "doomsday-shipLog",
                                    "The instructions list %s, %s and %s as necessary components"
                                ),
                                component1,
                                component2,
                                component3
                            ),
                            "Magenta"
                        )
                    end
                end
                notesMarker = doomsdayTimer - 30
            end
            if componentMessage2 == nil and doomsdayTimer < notesMarker then
                componentMessage2 = "sent"
                for pidx = 1, 8 do
                    p = getPlayerShip(pidx)
                    if p ~= nil and p:isValid() and p.professor then
                        p:addToShipLog(
                            string.format(
                                _(
                                    "doomsday-shipLog",
                                    "Further inspection of Gregory Unruh's plans reveal notes in the margin: %s on %s, %s on %s, %s on %s"
                                ),
                                component1,
                                component1Base:getCallSign(),
                                component2,
                                component2Base:getCallSign(),
                                component3,
                                component3Base:getCallSign()
                            ),
                            "Magenta"
                        )
                    end
                end
            end
            for pidx = 1, 8 do
                p = getPlayerShip(pidx)
                if p ~= nil and p:isValid() and p.professor then
                    local gi = 1
                    local part1Quantity = 0
                    local part2Quantity = 0
                    local part3Quantity = 0
                    if professorDiagnostic then
                        print("check for defense goods")
                    end
                    repeat
                        if goods[p][gi][1] == component1 then
                            part1Quantity = goods[p][gi][2]
                        end
                        if goods[p][gi][1] == component2 then
                            part2Quantity = goods[p][gi][2]
                        end
                        if goods[p][gi][1] == component3 then
                            part3Quantity = goods[p][gi][2]
                        end
                        gi = gi + 1
                    until gi > #goods[player]
                    if
                        part1Quantity > 0
                        and part2Quantity > 0
                        and part3Quantity > 0
                    then
                        decrementPlayerGoods(component1)
                        decrementPlayerGoods(component2)
                        decrementPlayerGoods(component3)
                        player.cargo = player.cargo + 3
                        p:addToShipLog(
                            _(
                                "doomsday-shipLog",
                                "With all three components obtained, Engineering and Science quickly complete and deploy the doomsday device defense mechanism"
                            ),
                            "Magenta"
                        )
                        plot1 = nil
                        defenseDeployed = true
                        primaryOrders = ""
                        if p.doomsday_status ~= nil then
                            p:removeCustom(p.doomsday_status)
                            p.doomsday_status = nil
                        end
                        if p.doomsday_status_plus ~= nil then
                            p:removeCustom(p.doomsday_status_plus)
                            p.doomsday_status_plus = nil
                        end
                    end
                end
            end
        else
            pickComponents()
        end
    end
    if doomsdayTimer < 0 then
        if doomsdayDeployed then
            local dTarg = doomsdayBlackHole.target
            if defenseDeployed then
                doomsdayBlackHole:destroy()
            else
                repositionDelay = repositionDelay - delta
                if repositionDelay < 0 then
                    if dTarg ~= nil then
                        if dTarg:isValid() then
                            if distance(dTarg, doomsdayBlackHole) > 4500 then
                                if professorDiagnostic then
                                    print("move doomsday device")
                                end
                                local dx, dy = doomsdayBlackHole:getPosition()
                                local tx, ty = dTarg:getPosition()
                                doomsdayBlackHole:setPosition(
                                    (dx + tx) / 2,
                                    (dy + ty) / 2
                                )
                            end
                        else
                            getNextDoomsdayTarget()
                        end
                    else
                        getNextDoomsdayTarget()
                    end
                    repositionDelay = delta + 5
                end
            end
        else
            repositionDelay = delta + 5
            if professorDiagnostic then
                print("deploy doomsday device")
            end
            doomsdayBlackHole = BlackHole()
            doomsdayBlackHole.target =
                humanStationList[math.random(1, #humanStationList)]
            doomsdayDeployed = true
        end
    end
    local doomsday_status =
        _("doomsday-tabEngineer&Engineer+", "Doomsday Device:")
    if doomsdayTimer < 0 then
        doomsday_status =
            _("doomsday-tabEngineer&Engineer+", "Doomsday Device Built")
    else
        local doomsday_minutes = math.floor(doomsdayTimer / 60)
        local doomsday_seconds = math.floor(doomsdayTimer % 60)
        doomsday_status =
            _("doomsday-tabEngineer&Engineer+", "Doomsday Device:")
        if doomsday_minutes <= 0 then
            doomsday_status = string.format(
                _("doomsday-tabEngineer&Engineer+", "%s %i"),
                doomsday_status,
                doomsday_seconds
            )
        else
            doomsday_status = string.format(
                _("doomsday-tabEngineer&Engineer+", "%s %i:%.2i"),
                doomsday_status,
                doomsday_minutes,
                doomsday_seconds
            )
        end
    end
    for pidx = 1, 8 do
        local p = getPlayerShip(pidx)
        if p ~= nil and p:isValid() then
            if p:hasPlayerAtPosition("Engineering") then
                p.doomsday_status = "doomsday_status"
                p:addCustomInfo(
                    "Engineering",
                    p.doomsday_status,
                    doomsday_status
                )
            end
            if p:hasPlayerAtPosition("Engineering+") then
                p.doomsday_status_plus = "doomsday_status_plus"
                p:addCustomInfo(
                    "Engineering+",
                    p.doomsday_status_plus,
                    doomsday_status
                )
            end
        end
    end
end
function getNextDoomsdayTarget()
    if professorDiagnostic then
        print("pick next doomsday target")
    end
    tempHumanStationList = {}
    for _, hStation in ipairs(humanStationList) do
        if hStation ~= nil and hStation:isValid() then
            table.insert(tempHumanStationList, hStation)
        end
    end
    if professorDiagnostic then
        print("use fresh human station list")
    end
    humanStationList = tempHumanStationList
    if #humanStationList < 1 then
        missionCompleteReason =
            _("doomsday-msgMainscreen", "All human stations destroyed")
        missionVictory = false
        endStatistics()
        victory("Exuari")
    else
        --  doomsdayBlackHole.target = humanStationList[math.random(1,#humanStationList)]
        doomsdayBlackHole.target =
            nearStations(doomsdayBlackHole, humanStationList)
    end
    if professorDiagnostic then
        print("done picking next doomsday target")
    end
end
function pickComponents()
    local attemptCount = 0
    repeat
        candidate = humanStationList[math.random(1, #humanStationList)]
        if candidate ~= nil and candidate:isValid() then
            if #goods[candidate] > 0 then
                gi = 1
                repeat
                    if
                        goods[candidate][gi][1] ~= "food"
                        and goods[candidate][gi][1] ~= "medicine"
                        and goods[candidate][gi][1] ~= "luxury"
                    then
                        component1Base = candidate
                        component1 = goods[candidate][gi][1]
                        gi = #goods[candidate] --exit repeat loop
                    end
                    gi = gi + 1
                until gi > #goods[candidate]
            end
        end
        attemptCount = attemptCount + 1
    until component1Base ~= nil or attemptCount > repeatExitBoundary
    if component1Base ~= nil then
        local attemptCount = 0
        repeat
            candidate = humanStationList[math.random(1, #humanStationList)]
            if
                candidate ~= nil
                and candidate:isValid()
                and candidate ~= component1Base
            then
                if #goods[candidate] > 0 then
                    gi = 1
                    repeat
                        if
                            goods[candidate][gi][1] ~= "food"
                            and goods[candidate][gi][1] ~= "medicine"
                            and goods[candidate][gi][1] ~= "luxury"
                            and goods[candidate][gi][1] ~= component1
                        then
                            component2Base = candidate
                            component2 = goods[candidate][gi][1]
                            gi = #goods[candidate] --exit repeat loop
                        end
                        gi = gi + 1
                    until gi > #goods[candidate]
                end
            end
            attemptCount = attemptCount + 1
        until component2Base ~= nil or attemptCount > repeatExitBoundary
        if component2Base ~= nil then
            local attemptCount = 0
            repeat
                candidate = humanStationList[math.random(1, #humanStationList)]
                if
                    candidate ~= nil
                    and candidate:isValid()
                    and candidate ~= component1Base
                    and candidate ~= component2Base
                then
                    if #goods[candidate] > 0 then
                        gi = 1
                        repeat
                            if
                                goods[candidate][gi][1] ~= "food"
                                and goods[candidate][gi][1] ~= "medicine"
                                and goods[candidate][gi][1] ~= "luxury"
                                and goods[candidate][gi][1] ~= component1
                                and goods[candidate][gi][1] ~= component2
                            then
                                component3Base = candidate
                                component3 = goods[candidate][gi][1]
                                gi = #goods[candidate] --exit repeat loop
                            end
                            gi = gi + 1
                        until gi > #goods[candidate]
                    end
                end
                attemptCount = attemptCount + 1
            until component3Base ~= nil or attemptCount > repeatExitBoundary
            if component3Base ~= nil then
                componentsPicked = true
            else
                plot1 = nil
                primaryOrders = ""
                professorSearch = false
                return
            end
        else
            plot1 = nil
            primaryOrders = ""
            professorSearch = false
            return
        end
    else
        plot1 = nil
        primaryOrders = ""
        professorSearch = false
        return
    end
end
----------------------------------
-- Sick Arlenian Admiral plot  --
----------------------------------
function startSickArlenianAdmiral()
    setUpSickArlenianAdmiral = "done"
    for pidx = 1, 8 do
        p = getPlayerShip(pidx)
        if p ~= nil and p:isValid() then
            p:addToShipLog(
                _(
                    "doctorGoal-shipLog",
                    "Our allies, the Arlenians tell us that Admiral Koshenz has contracted a severe disease. The Arlenian doctors have struggled for days with the disease with minimal change in his condition. They fear he does not have much longer to live. They have asked for assistance from any Human researchers in Arlenian disease. One of their medical team referred to a Dr. Morrigan Thultris who recently published information regarding a disease that shares symptoms and characteristics with the admiral's affliction. Dr. Thultris does not show up on our military registry implying she works in relative seclusion. Search the Human Navy stations and find her and enlist her aid if applicable. Do it quickly, Admiral Koshenz likely does not have long to live"
                ),
                "Magenta"
            )
        end
    end
    primaryOrders = _(
        "doctorOrders-comms",
        "Find Dr. Thultris for help with Arlenian Admiral Koshenz"
    )
    local doctorStationAttemptCount = 0
    repeat
        doctorStation = humanStationList[math.random(1, #humanStationList)]
        doctorStationAttemptCount = doctorStationAttemptCount + 1
    until (doctorStation ~= nil and doctorStation:isValid())
        or doctorStationAttemptCount > repeatExitBoundary
    if doctorStationAttemptCount > repeatExitBoundary then
        if sickAdmiralDiagnostic then
            print("bad doctor station")
        end
        plot1 = nil
        primaryOrders = ""
    else
        if sickAdmiralDiagnostic then
            print("doctor station set")
        end
        doctorSearch = true
        doctorAssisting = false
        doctorRejectionCount = 0
    end
    for i = 1, 3 do
        local clueStationAttemptCount = 0
        repeat
            clueStation = humanStationList[math.random(1, #humanStationList)]
            clueStationAttemptCount = clueStationAttemptCount + 1
        until (
                clueStation ~= nil
                and clueStation:isValid()
                and clueStation ~= doctorStation
                and (
                    clueStation.character == nil
                    or clueStation.character == "Gregory Unruh"
                )
            ) or clueStationAttemptCount > repeatExitBoundary
        if clueStationAttemptCount < repeatExitBoundary then
            clueStation.character = "Morrigan Thultris"
            clueStation.characterDescription = string.format(
                _("doctor-comms", "Dr. Thultris resides on station %s"),
                doctorStation:getCallSign()
            )
        end
    end
    if sickAdmiralDiagnostic then
        print("done with sick admiral setup")
    end
    removeGMFunction(GMAdmiral)
end
function sickArlenianAdmiral(delta)
    if setUpSickArlenianAdmiral == nil then
        startSickArlenianAdmiral()
    end
    admiralTimeToLive = 700 - difficulty * 100
    plot1 = checkSickArlenianAdmiralEvents
end
function checkSickArlenianAdmiralEvents(delta)
    admiralTimeToLive = admiralTimeToLive - delta
    if admiralTimeToLive < 0 then
        missionCompleteReason =
            _("doctor-msgMainscreen", "Arlenian Admiral Koshenz dies")
        missionVictory = false
        endStatistics()
        victory("Kraylor")
    elseif not arlenianFleet2base:isValid() then
        missionCompleteReason = string.format(
            _(
                "doctor-msgMainscreen",
                "Arlenian Admiral Koshenz dies along with the rest of the Arlenians on station %s"
            ),
            arlenian_fleet_base_2_name
        )
        missionVictory = false
        endStatistics()
        victory("Kraylor")
    end
    if admiralTimeToLive < 180 and admiralDyingWarning == nil then
        admiralDyingWarning = "sent"
        for pidx = 1, 8 do
            p = getPlayerShip(pidx)
            if p ~= nil and p:isValid() then
                p:addToShipLog(
                    _(
                        "doctor-shipLog",
                        "The Arlenians say that they think the admiral has less than three minutes to live"
                    ),
                    "Magenta"
                )
            end
        end
    end
    if admiralTimeToLive < 250 and kraylorAfterAdmiral == nil then
        kraylorAfterAdmiral = "launched"
        local kafx, kafy = vectorFromAngle(
            random(borderStartAngle + 240, borderStartAngle + 270),
            random(20000, 30000) - (7000 * difficulty)
        )
        local aasx, aasy = arlenianFleet2base:getPosition()
        menaceAdmiralFleet =
            spawnEnemies(aasx + kafx, aasy + kafy, 2, "Kraylor")
        for _, enemy in ipairs(menaceAdmiralFleet) do
            enemy:orderFlyTowards(aasx, aasy)
        end
    end
    if admiralTimeToLive < 225 and kraylorAdmiralWarning == nil then
        kraylorAdmiralWarning = "sent"
        for pidx = 1, 8 do
            p = getPlayerShip(pidx)
            if p ~= nil and p:isValid() then
                p:addToShipLog(
                    string.format(
                        _(
                            "doctor-shipLog",
                            "The Kraylors seem to have discovered the location of Admiral Koshenz. We detect Kraylor ships en route to %s"
                        ),
                        arlenianFleet2base:getCallSign()
                    ),
                    "Magenta"
                )
            end
        end
    end
    if admiralTimeToLive < 200 and exuariAfterAdmiral == nil then
        exuariAfterAdmiral = "directed"
        local aasx, aasy = arlenianFleet2base:getPosition()
        for _, enemy in ipairs(exuariFleet3) do
            enemy:orderFlyTowards(aasx, aasy)
        end
    end
    if doctorAssisting then
        if admiralLocationMessage == nil then
            admiralLocationMessage = "sent"
            if arlenianFleet2base ~= nil and arlenianFleet2base:isValid() then
                for pidx = 1, 8 do
                    p = getPlayerShip(pidx)
                    if p ~= nil and p:isValid() then
                        p:addToShipLog(
                            string.format(
                                _(
                                    "doctor-shipLog",
                                    "Admiral Koshenz is on %s in %s"
                                ),
                                arlenianFleet2base:getCallSign(),
                                arlenianFleet2base:getSectorName()
                            ),
                            "Magenta"
                        )
                    end
                end
                primaryOrders = string.format(
                    _("doctorOrders-comms", "Take Dr. Thultris to %s in %s"),
                    arlenianFleet2base:getCallSign(),
                    arlenianFleet2base:getSectorName()
                )
            end
        end
        for pidx = 1, 8 do
            p = getPlayerShip(pidx)
            if p ~= nil and p:isValid() and p.doctorAboard then
                if p:isDocked(arlenianFleet2base) then
                    p:addToShipLog(
                        _(
                            "doctor-shipLog",
                            "Dr. Thultris applied her knowledge and Admiral Koshenz is improving"
                        ),
                        "Magenta"
                    )
                    plot1 = nil
                    doctorSearch = false
                    primaryOrders = ""
                    if p.admiral_status ~= nil then
                        p:removeCustom(p.admiral_status)
                        p.admiral_status = nil
                    end
                    if p.admiral_status_operations ~= nil then
                        p:removeCustom(p.admiral_status_operations)
                        p.admiral_status_operations = nil
                    end
                end
            end
        end
    end
    local death_minutes = math.floor(admiralTimeToLive / 60)
    local death_seconds = math.floor(admiralTimeToLive % 60)
    local admiral_status = _("doctor-tabScience&Operations", "Koshenz Death:")
    if death_minutes <= 0 then
        admiral_status = string.format(
            _("doctor-tabScience&Operations", "%s %i"),
            admiral_status,
            death_seconds
        )
    else
        admiral_status = string.format(
            _("doctor-tabScience&Operations", "%s %i:%.2i"),
            admiral_status,
            death_minutes,
            death_seconds
        )
    end
    for pidx = 1, 8 do
        local p = getPlayerShip(pidx)
        if p ~= nil and p:isValid() then
            if p:hasPlayerAtPosition("Science") then
                p.admiral_status = "admiral_status"
                p:addCustomInfo("Science", p.admiral_status, admiral_status)
            end
            if p:hasPlayerAtPosition("Operations") then
                p.admiral_status_operations = "admiral_status_operations"
                p:addCustomInfo(
                    "Operations",
                    p.admiral_status_operations,
                    admiral_status
                )
            end
        end
    end
end
-------------------------------------
-- Mining resource conflict plot  --
-------------------------------------
function startMiningConflict()
    setUpMiningConflict = "done"
    removeGMFunction(GMMining)
    for pidx = 1, 8 do
        p = getPlayerShip(pidx)
        if p ~= nil and p:isValid() then
            p:addToShipLog(
                _(
                    "BespinGoal-shipLog",
                    "Our allies, the Arlenians tell us that the Kraylors are attacking the mining facility around the planet Bespin. We rely heavily on that mineral supply for commerce and military operations. Contact the Arlenians and render assistance"
                ),
                "Magenta"
            )
        end
    end
    primaryOrders = _(
        "BespinOrders-comms",
        "Contact Arlenians and render assistance with Kraylor attack"
    )
    bespinX, bespinY = vectorFromAngle(
        random(borderStartAngle - 30, borderStartAngle + 30),
        random(100000, 130000)
    )
    planetBespin = Planet()
        :setPosition(bespinX, bespinY)
        :setPlanetRadius(2700)
        :setDistanceFromMovementPlane(-2000)
        :setCallSign("Bespin")
    planetBespin
        :setPlanetSurfaceTexture("planets/gas-1.png")
        :setAxialRotationTime(300)
        :setDescription(
            _("scienceDescription-planet", "Gas giant suitable for mining")
        )
    stationCloudCity = SpaceStation()
        :setTemplate(ST.SMALL_STATION)
        :setFaction("Arlenians")
        :setCommsScript("")
        :setCommsFunction(commsStation)
    stationCloudCity
        :setPosition(bespinX, bespinY + 3500)
        :setCallSign("Cloud City")
        :setDescription(_("scienceDescription-station", "Bespin Gas Mining"))
    goods[stationCloudCity] = { { "cobalt", 5, 68 } }
    ccOrbitDelayInterval = 3 -- Cloud city orbit delay interval
    ccOrbitDelayTimer = ccOrbitDelayInterval -- Cloud city orbit delay timer
    ccoa = 90 -- cloud city orbit angle
    if miningConflictDiagnostic then
        print("mining planet and station established")
    end
    local kmfx, kmfy = vectorFromAngle(
        random(borderStartAngle + 200, borderStartAngle + 250),
        random(30000, 50000)
    )
    menaceMiningFleet =
        spawnEnemies(bespinX + kmfx, bespinY + kmfy, 2, "Kraylor")
    if miningConflictDiagnostic then
        print("mining menace Kraylor fleet established")
    end
    for _, enemy in ipairs(menaceMiningFleet) do
        enemy:orderFlyTowards(bespinX, bespinY)
    end
    if miningConflictDiagnostic then
        print("menacing fleet in flight")
    end
    table.insert(kraylorFleetList, menaceMiningFleet)
    for _, ally in ipairs(arlenianFleet1) do
        ally:orderDefendTarget(stationCloudCity)
    end
    if miningConflictDiagnostic then
        print("Arlenian fleet in flight")
    end
    scarceResources = true
    if miningConflictDiagnostic then
        print("Done with start mining conflict function")
    end
    removeGMFunction(GMMining)
end
function miningConflict(delta)
    if setUpMiningConflict == nil then
        startMiningConflict()
    end
    plot1 = checkMiningConflictEvents
end
function checkMiningConflictEvents(delta)
    if stationCloudCity ~= nil and stationCloudCity:isValid() then
        if exuariMiningOpportunity == nil then
            if miningConflictDiagnostic then
                print("exuari mining opportunity")
            end
            closestToCC = closestPlayerTo(stationCloudCity)
            if miningConflictDiagnostic then
                print("closest player chosen")
            end
            if distance(closestToCC, stationCloudCity) < 30000 then
                if miningConflictDiagnostic then
                    print("player close enough to trigger Exuari activity")
                end
                exuariMiningOpportunity = "done"
                exuariMiningWarningTimer = delta + 120
                local f1bx, f1by = arlenianFleet1base:getPosition()
                for _, enemy in ipairs(exuariFleet1) do
                    enemy:orderFlyTowards(f1bx, f1by)
                end
                humanMiningTargetStation =
                    nearStations(exuariFleet2base, humanStationList)
                if humanMiningTargetStation ~= nil then
                    local f1bx, f1by = humanMiningTargetStation:getPosition()
                    for _, enemy in ipairs(exuariFleet2) do
                        enemy:orderFlyTowards(f1bx, f1by)
                    end
                else
                    for _, enemy in ipairs(exuariFleet2) do
                        enemy:orderRoaming()
                    end
                end
            end
        end
        if exuariMiningOpportunity == "done" then
            if exuari2Released == nil then
                if humanMiningTargetStation == nil then
                    for _, enemy in ipairs(exuariFleet2) do
                        enemy:orderRoaming()
                    end
                    exuari2Released = "done"
                elseif not humanMiningTargetStation:isValid() then
                    for _, enemy in ipairs(exuariFleet2) do
                        enemy:orderRoaming()
                    end
                    exuari2Released = "done"
                end
            end
        end
        if exuariMiningWarningTimer ~= nil then
            exuariMiningWarningTimer = exuariMiningWarningTimer - delta
            if exuariMiningWarningTimer < 0 then
                if exuariMiningWarning == nil then
                    exuariMiningWarning = "sent"
                    for pidx = 1, 8 do
                        p = getPlayerShip(pidx)
                        if p ~= nil and p:isValid() then
                            p:addToShipLog(
                                _(
                                    "Bespin-shipLog",
                                    "Looks like the Exuari are taking advantage of the Kraylor mining incident by sending forces against us and the Arlenians"
                                ),
                                "Magenta"
                            )
                        end
                    end
                end
            end
        end
        local menaceMiningFleetCount = 0
        for _, enemy in ipairs(menaceMiningFleet) do
            if enemy ~= nil and enemy:isValid() then
                menaceMiningFleetCount = menaceMiningFleetCount + 1
            end
        end
        if menaceMiningFleetCount < 1 then
            for pidx = 1, 8 do
                p = getPlayerShip(pidx)
                if p ~= nil and p:isValid() then
                    p:addToShipLog(
                        _(
                            "Bespin-shipLog",
                            "The Arlenians thanked us for the help with the Kraylors around Cloud City"
                        ),
                        "Magenta"
                    )
                end
            end
            scarceResources = false
            plot1 = nil
            primaryOrders = ""
        end
    else
        missionCompleteReason =
            _("Bespin-msgMainscreen", "Mining station Cloud City destroyed")
        missionVictory = false
        endStatistics()
        victory("Kraylor")
    end
end

function movingObjects(delta)
    if ccOrbitDelayTimer ~= nil then
        ccOrbitDelayTimer = ccOrbitDelayTimer - delta
        if ccOrbitDelayTimer < 0 then
            ccoa = ccoa + 1
            if ccoa >= 360 then
                ccoa = 0
            end
            orbitBx, orbitBy = vectorFromAngle(ccoa, 3500)
            stationCloudCity:setPosition(bespinX + orbitBx, bespinY + orbitBy)
            ccOrbitDelayTimer = ccOrbitDelayInterval
        end
    end
end
function healthCheck(delta)
    healthCheckTimer = healthCheckTimer - delta
    if healthCheckTimer < 0 then
        if healthDiagnostic then
            print("health check timer expired")
        end
        for pidx = 1, 8 do
            if healthDiagnostic then
                print("in player loop")
            end
            local p = getPlayerShip(pidx)
            if healthDiagnostic then
                print("got player ship")
            end
            if p ~= nil and p:isValid() then
                if healthDiagnostic then
                    print("valid ship")
                end
                if p:getRepairCrewCount() > 0 then
                    if healthDiagnostic then
                        print("crew on valid ship")
                    end
                    local fatalityChance = 0
                    if healthDiagnostic then
                        print("shields")
                    end
                    sc = p:getShieldCount()
                    if healthDiagnostic then
                        print("sc: " .. sc)
                    end
                    if p:getShieldCount() > 1 then
                        cShield = (
                            p:getSystemHealth("frontshield")
                            + p:getSystemHealth("rearshield")
                        ) / 2
                    else
                        cShield = p:getSystemHealth("frontshield")
                    end
                    fatalityChance = fatalityChance + (p.prevShield - cShield)
                    p.prevShield = cShield
                    if healthDiagnostic then
                        print("reactor")
                    end
                    fatalityChance = fatalityChance
                        + (p.prevReactor - p:getSystemHealth("reactor"))
                    p.prevReactor = p:getSystemHealth("reactor")
                    if healthDiagnostic then
                        print("maneuver")
                    end
                    fatalityChance = fatalityChance
                        + (p.prevManeuver - p:getSystemHealth("maneuver"))
                    p.prevManeuver = p:getSystemHealth("maneuver")
                    if healthDiagnostic then
                        print("impulse")
                    end
                    fatalityChance = fatalityChance
                        + (p.prevImpulse - p:getSystemHealth("impulse"))
                    p.prevImpulse = p:getSystemHealth("impulse")
                    if healthDiagnostic then
                        print("beamweapons")
                    end
                    if p:getBeamWeaponRange(0) > 0 then
                        if p.healthyBeam == nil then
                            p.healthyBeam = 1.0
                            p.prevBeam = 1.0
                        end
                        fatalityChance = fatalityChance
                            + (p.prevBeam - p:getSystemHealth("beamweapons"))
                        p.prevBeam = p:getSystemHealth("beamweapons")
                    end
                    if healthDiagnostic then
                        print("missilesystem")
                    end
                    if p:getWeaponTubeCount() > 0 then
                        if p.healthyMissile == nil then
                            p.healthyMissile = 1.0
                            p.prevMissile = 1.0
                        end
                        fatalityChance = fatalityChance
                            + (
                                p.prevMissile
                                - p:getSystemHealth("missilesystem")
                            )
                        p.prevMissile = p:getSystemHealth("missilesystem")
                    end
                    if healthDiagnostic then
                        print("warp")
                    end
                    if p:hasWarpDrive() then
                        if p.healthyWarp == nil then
                            p.healthyWarp = 1.0
                            p.prevWarp = 1.0
                        end
                        fatalityChance = fatalityChance
                            + (p.prevWarp - p:getSystemHealth("warp"))
                        p.prevWarp = p:getSystemHealth("warp")
                    end
                    if healthDiagnostic then
                        print("jumpdrive")
                    end
                    if p:hasJumpDrive() then
                        if p.healthyJump == nil then
                            p.healthyJump = 1.0
                            p.prevJump = 1.0
                        end
                        fatalityChance = fatalityChance
                            + (p.prevJump - p:getSystemHealth("jumpdrive"))
                        p.prevJump = p:getSystemHealth("jumpdrive")
                    end
                    if healthDiagnostic then
                        print("adjust")
                    end
                    if p:getRepairCrewCount() == 1 then
                        fatalityChance = fatalityChance / 2 -- increase chances of last repair crew standing
                    end
                    if healthDiagnostic then
                        print("check")
                    end
                    if fatalityChance > 0 then
                        crewFate(p, fatalityChance)
                    end
                end
            end
        end
        healthCheckTimer = delta + healthCheckTimerInterval
    end
end
function crewFate(p, fatalityChance)
    if math.random() < fatalityChance then
        p:setRepairCrewCount(p:getRepairCrewCount() - 1)
        if p:hasPlayerAtPosition("Engineering") then
            local repairCrewFatality = "repairCrewFatality"
            p:addCustomMessage(
                "Engineering",
                repairCrewFatality,
                _(
                    "repairCrew-msgEngineer",
                    "One of your repair crew has perished"
                )
            )
        end
        if p:hasPlayerAtPosition("Engineering+") then
            local repairCrewFatalityPlus = "repairCrewFatalityPlus"
            p:addCustomMessage(
                "Engineering+",
                repairCrewFatalityPlus,
                _(
                    "repairCrew-msgEngineer+",
                    "One of your repair crew has perished"
                )
            )
        end
    end
end --set up players with name, goods, cargo space, reputation and either a warp drive or a jump drive if applicable
function setPlayers()
    for i, p in ipairs(getActivePlayerShips()) do
        if goods[p] == nil then
            goods[p] = {}
            for i, good in ipairs(goodsList) do
                table.insert(goods[p], good)
            end
        end
        if p.initialRep == nil then
            p:addReputationPoints(100 - (difficulty * 20))
            p.initialRep = true
        end
        if not p.nameAssigned then
            p.nameAssigned = true
            local temp_player_type = p:getTypeName()
            p:setCallSign(
                tableRemoveRandom(player_ship_names[temp_player_type])
            )
            if p:getCallSign() == nil then
                p:setCallSign(tableSelectRandom(player_ship_names["Leftovers"]))
                p.shipScore = 24
                p.MaxCargo = 5
            end
            p.shipScore = player_ship_stats[temp_player_type].strength
            p.maxCargo = player_ship_stats[temp_player_type].cargo
            if temp_player_type == "MP52 Hornet" then
                p.autoCoolant = false
                p.setWarpDrive(true)
            elseif temp_player_type == "Phobos M3P" then
                p.setWarpDrive(true)
            elseif temp_player_type == "Stingray" then
                p.autoCoolant = false
                p.setJumpDrive(true)
                p:setJumpDriveRange(3000, 40000)
            elseif temp_player_type == "Crow" then
                if p:getImpulseMaxSpeed() == 45 then
                    p:setImpulseMaxSpeed(90)
                end
                if p:getBeamWeaponCycleTime(0) == 6 then
                    local bi = 0
                    repeat
                        local tempArc = p:getBeamWeaponArc(bi)
                        local tempDir = p:getBeamWeaponDirection(bi)
                        local tempRng = p:getBeamWeaponRange(bi)
                        local tempDmg = p:getBeamWeaponDamage(bi)
                        p:setBeamWeapon(
                            bi,
                            tempArc,
                            tempDir,
                            tempRng,
                            5,
                            tempDmg
                        )
                        bi = bi + 1
                    until p:getBeamWeaponRange(bi) < 1
                end
                p.autoCoolant = false
                p:setJumpDrive(true)
                p:setJumpDriveRange(3000, 40000)
            elseif temp_player_type == "ZX-Lindworm" then
                p.autoCoolant = false
                p.setWarpDrive(true)
            end
            if p.cargo == nil then
                p.cargo = p.maxCargo
                PlayerState.resetBaseline(p, {
                    tube_size = false,
                    initial_coolant = false,
                    coolant_rates = false,
                })
            end
        end
    end
    return
end
function kraylorVesselDestroyed(self, instigator)
    tempShipType = self:getTypeName()
    table.insert(kraylorVesselDestroyedNameList, self:getCallSign())
    table.insert(kraylorVesselDestroyedType, tempShipType)
    for k = 1, #stnl do
        if tempShipType == stnl[k] then
            table.insert(kraylorVesselDestroyedValue, stsl[k])
        end
    end
end
function exuariVesselDestroyed(self, instigator)
    tempShipType = self:getTypeName()
    table.insert(exuariVesselDestroyedNameList, self:getCallSign())
    table.insert(exuariVesselDestroyedType, tempShipType)
    for k = 1, #stnl do
        if tempShipType == stnl[k] then
            table.insert(exuariVesselDestroyedValue, stsl[k])
        end
    end
end
function humanVesselDestroyed(self, instigator)
    tempShipType = self:getTypeName()
    table.insert(humanVesselDestroyedNameList, self:getCallSign())
    table.insert(humanVesselDestroyedType, tempShipType)
    for k = 1, #stnl do
        if tempShipType == stnl[k] then
            table.insert(humanVesselDestroyedValue, stsl[k])
        end
    end
end
function arlenianVesselDestroyed(self, instigator)
    tempShipType = self:getTypeName()
    table.insert(arlenianVesselDestroyedNameList, self:getCallSign())
    table.insert(arlenianVesselDestroyedType, tempShipType)
    for k = 1, #stnl do
        if tempShipType == stnl[k] then
            table.insert(arlenianVesselDestroyedValue, stsl[k])
        end
    end
end
function humanStationDestroyed(self, instigator)
    table.insert(humanStationDestroyedNameList, self:getCallSign())
    table.insert(humanStationDestroyedValue, self.strength)
end
function kraylorStationDestroyed(self, instigator)
    table.insert(kraylorStationDestroyedNameList, self:getCallSign())
    table.insert(kraylorStationDestroyedValue, self.strength)
end
function exuariStationDestroyed(self, instigator)
    table.insert(exuariStationDestroyedNameList, self:getCallSign())
    table.insert(exuariStationDestroyedValue, self.strength)
end
function arlenianStationDestroyed(self, instigator)
    table.insert(arlenianStationDestroyedNameList, self:getCallSign())
    table.insert(arlenianStationDestroyedValue, self.strength)
end
function listStatuses()
    local humanCountPercentage, humanValuePercentage, kraylorCountPercentage, kraylorValuePercentage, exuariCountPercentage, exuariValuePercentage, arlenianCountPercentage, arlenianValuePercentage, neutralCountPercentage, neutralValuePercentage =
        stationStatus()
    if humanCountPercentage == nil then
        return nil
    end
    --ship information
    local humanMilitaryShipSurvivedCount = 0
    local humanMilitaryShipSurvivedValue = 0
    for j = 1, #humanFleetList do
        local tempFleet = humanFleetList[j]
        for _, tempEnemy in ipairs(tempFleet) do
            if tempEnemy ~= nil and tempEnemy:isValid() then
                humanMilitaryShipSurvivedCount = humanMilitaryShipSurvivedCount
                    + 1
                for k = 1, #stnl do
                    if tempEnemy:getTypeName() == stnl[k] then
                        humanMilitaryShipSurvivedValue = humanMilitaryShipSurvivedValue
                            + stsl[k]
                    end
                end
            end
        end
    end
    local kraylorMilitaryShipSurvivedCount = 0
    local kraylorMilitaryShipSurvivedValue = 0
    for j = 1, #kraylorFleetList do
        local tempFleet = kraylorFleetList[j]
        for _, tempEnemy in ipairs(tempFleet) do
            if tempEnemy ~= nil and tempEnemy:isValid() then
                kraylorMilitaryShipSurvivedCount = kraylorMilitaryShipSurvivedCount
                    + 1
                for k = 1, #stnl do
                    if tempEnemy:getTypeName() == stnl[k] then
                        kraylorMilitaryShipSurvivedValue = kraylorMilitaryShipSurvivedValue
                            + stsl[k]
                    end
                end
            end
        end
    end
    local exuariMilitaryShipSurvivedCount = 0
    local exuariMilitaryShipSurvivedValue = 0
    for j = 1, #exuariFleetList do
        local tempFleet = exuariFleetList[j]
        for _, tempEnemy in ipairs(tempFleet) do
            if tempEnemy ~= nil and tempEnemy:isValid() then
                exuariMilitaryShipSurvivedCount = exuariMilitaryShipSurvivedCount
                    + 1
                for k = 1, #stnl do
                    if tempEnemy:getTypeName() == stnl[k] then
                        exuariMilitaryShipSurvivedValue = exuariMilitaryShipSurvivedValue
                            + stsl[k]
                    end
                end
            end
        end
    end
    local arlenianMilitaryShipSurvivedCount = 0
    local arlenianMilitaryShipSurvivedValue = 0
    for j = 1, #arlenianFleetList do
        local tempFleet = arlenianFleetList[j]
        for _, tempEnemy in ipairs(tempFleet) do
            if tempEnemy ~= nil and tempEnemy:isValid() then
                arlenianMilitaryShipSurvivedCount = arlenianMilitaryShipSurvivedCount
                    + 1
                for k = 1, #stnl do
                    if tempEnemy:getTypeName() == stnl[k] then
                        arlenianMilitaryShipSurvivedValue = arlenianMilitaryShipSurvivedValue
                            + stsl[k]
                    end
                end
            end
        end
    end
    local humanMilitaryShipValuePercentage = humanMilitaryShipSurvivedValue
        / rawHumanShipStrength
        * 100
    local kraylorMilitaryShipValuePercentage = kraylorMilitaryShipSurvivedValue
        / rawKraylorShipStrength
        * 100
    local exuariMilitaryShipValuePercentage = exuariMilitaryShipSurvivedValue
        / rawExuariShipStrength
        * 100
    local arlenianMilitaryShipValuePercentage = arlenianMilitaryShipSurvivedValue
        / rawArlenianShipStrength
        * 100
    return humanCountPercentage,
        humanValuePercentage,
        kraylorCountPercentage,
        kraylorValuePercentage,
        exuariCountPercentage,
        exuariValuePercentage,
        arlenianCountPercentage,
        arlenianValuePercentage,
        neutralCountPercentage,
        neutralValuePercentage,
        humanMilitaryShipValuePercentage,
        kraylorMilitaryShipValuePercentage,
        exuariMilitaryShipValuePercentage,
        arlenianMilitaryShipValuePercentage
end
function stationStatus()
    local strengths = {
        [ST.HUGE_STATION] = 10,
        [ST.LARGE_STATION] = 5,
        [ST.MEDIUM_STATION] = 3,
        [ST.SMALL_STATION] = 1,
    }
    local counts = {
        ["Human Navy"] = 0,
        ["Kraylor"] = 0,
        ["Exuari"] = 0,
        ["Arlenians"] = 0,
        ["Independent"] = 0,
    }
    local values = {
        ["Human Navy"] = 0,
        ["Kraylor"] = 0,
        ["Exuari"] = 0,
        ["Arlenians"] = 0,
        ["Independent"] = 0,
    }
    local percentages = {
        ["Human Navy"] = {
            count = 0,
            value = 0,
            count_base = #humanStationList,
            strength_base = humanStationStrength,
        },
        ["Kraylor"] = {
            count = 0,
            value = 0,
            count_base = #kraylorStationList,
            strength_base = kraylorStationStrength,
        },
        ["Exuari"] = {
            count = 0,
            value = 0,
            count_base = #exuariStationList,
            strength_base = exuariStationStrength,
        },
        ["Arlenians"] = {
            count = 0,
            value = 0,
            count_base = #arlenianStationList,
            strength_base = arlenianStationStrength,
        },
        ["Independent"] = {
            count = 0,
            value = 0,
            count_base = #neutralStationList,
            strength_base = neutralStationStrength,
        },
    }
    for i, station in ipairs(stationList) do
        if station:isValid() then
            counts[station:getFaction()] = counts[station:getFaction()] + 1
            values[station:getFaction()] = values[station:getFaction()]
                + strengths[station:getTypeName()]
        end
    end
    for faction, item in pairs(percentages) do
        if item.count_base > 0 then
            item.count = counts[faction] / item.count_base * 100
        else
            item.count = -1
        end
        if item.strength_base > 0 then
            item.value = values[faction] / item.strength_base * 100
        else
            item.value = -1
        end
    end
    return percentages["Human Navy"].count,
        percentages["Human Navy"].value,
        percentages["Kraylor"].count,
        percentages["Kraylor"].value,
        percentages["Exuari"].count,
        percentages["Exuari"].value,
        percentages["Arlenians"].count,
        percentages["Arlenians"].value,
        percentages["Independent"].count,
        percentages["Independent"].value
    --[[
    local humanSurvivedCount = 0
    local humanSurvivedValue = 0
    local kraylorSurvivedCount = 0
    local kraylorSurvivedValue = 0
    local exuariSurvivedCount = 0
    local exuariSurvivedValue = 0
    local arlenianSurvivedCount = 0
    local arlenianSurvivedValue = 0
    local neutralSurvivedCount = 0
    local neutralSurvivedValue = 0
    for _, station in pairs(stationList) do
        if station:isValid() then
            local tsf = station:getFaction()
            if tsf == "Human Navy" then
                humanSurvivedCount = humanSurvivedCount + 1
                humanSurvivedValue = humanSurvivedValue + station.strength
            elseif tsf == "Kraylor" then
                kraylorSurvivedCount = kraylorSurvivedCount + 1
                kraylorSurvivedValue = kraylorSurvivedValue + station.strength
            elseif tsf == "Exuari" then
                exuariSurvivedCount = exuariSurvivedCount + 1
                exuariSurvivedValue = exuariSurvivedValue + station.strength
            elseif tsf == "Arlenians" then
                arlenianSurvivedCount = arlenianSurvivedCount + 1
                arlenianSurvivedValue = arlenianSurvivedValue + station.strength
            else
                neutralSurvivedCount = neutralSurvivedCount + 1
                neutralSurvivedValue = neutralSurvivedValue + station.strength
            end
        end
    end
    local humanCountPercentage = humanSurvivedCount/#humanStationList*100
    local humanValuePercentage = humanSurvivedValue/humanStationStrength*100
    local kraylorCountPercentage = kraylorSurvivedCount/#kraylorStationList*100
    local kraylorValuePercentage = kraylorSurvivedValue/kraylorStationStrength*100
    local exuariCountPercentage = exuariSurvivedCount/#exuariStationList*100
    local exuariValuePercentage = exuariSurvivedValue/exuariStationStrength*100
    local arlenianCountPercentage = arlenianSurvivedCount/#arlenianStationList*100
    local arlenianValuePercentage = arlenianSurvivedValue/arlenianStationStrength*100
    if #neutralStationList > 0 then
        local neutralCountPercentage = neutralSurvivedCount/#neutralStationList*100
        local neutralValuePercentage = neutralSurvivedValue/neutralStationStrength*100
    else
        local neutralCountPercentage = -1
        local neutralValuePercentage = -1
    end
    return humanCountPercentage, humanValuePercentage, kraylorCountPercentage, kraylorValuePercentage, exuariCountPercentage, exuariValuePercentage, arlenianCountPercentage, arlenianValuePercentage, neutralCountPercentage, neutralValuePercentage
    --]]
end
function endStatistics()
    if endStatDiagnostic then
        print("starting end statistics")
    end
    local humanCountPercentage, humanValuePercentage, kraylorCountPercentage, kraylorValuePercentage, exuariCountPercentage, exuariValuePercentage, arlenianCountPercentage, arlenianValuePercentage, neutralCountPercentage, neutralValuePercentage, humanMilitaryShipValuePercentage, kraylorMilitaryShipValuePercentage, exuariMilitaryShipValuePercentage, arlenianMilitaryShipValuePercentage =
        listStatuses()
    local human_stations = ""
    if type(humanCountPercentage) == "number" then
        human_stations = string.format(
            _("msgMainscreen", "Human stations: survived:%.1f%%"),
            humanCountPercentage
        )
    end
    if type(humanValuePercentage) == "number" then
        if human_stations ~= "" then
            human_stations = string.format(
                _("msgMainscreen", "%s, strength:%.1f%%"),
                human_stations,
                humanValuePercentage
            )
        else
            human_stations = string.format(
                _("msgMainscreen", "Human stations: strength:%.1f%%"),
                humanValuePercentage
            )
        end
    end
    local arlenian_stations = ""
    if type(arlenianCountPercentage) == "number" then
        arlenian_stations = string.format(
            _("msgMainscreen", "Arlenian stations: survived:%.1f%%"),
            arlenianCountPercentage
        )
    end
    if type(arlenianValuePercentage) == "number" then
        if arlenian_stations ~= "" then
            arlenian_stations = string.format(
                _("msgMainscreen", "%s, strength:%.1f%%"),
                arlenian_stations,
                arlenianValuePercentage
            )
        else
            arlenian_stations = string.format(
                _("msgMainscreen", "Arlenian stations: strength:%.1f%%"),
                arlenianValuePercentage
            )
        end
    end
    local kraylor_stations = ""
    if type(kraylorCountPercentage) == "number" then
        kraylor_stations = string.format(
            _("msgMainscreen", "Kraylor stations: survived:%.1f%%"),
            kraylorCountPercentage
        )
    end
    if type(kraylorValuePercentage) == "number" then
        if kraylor_stations ~= "" then
            kraylor_stations = string.format(
                _("msgMainscreen", "%s, strength:%.1f%%"),
                kraylor_stations,
                kraylorValuePercentage
            )
        else
            kraylor_stations = string.format(
                _("msgMainscreen", "Kraylor stations: strength:%.1f%%"),
                kraylorValuePercentage
            )
        end
    end
    local exuari_stations = ""
    if type(exuariCountPercentage) == "number" then
        exuari_stations = string.format(
            _("msgMainscreen", "Exuari stations: survived:%.1f%%"),
            exuariCountPercentage
        )
    end
    if type(exuariValuePercentage) == "number" then
        if exuari_stations ~= "" then
            exuari_stations = string.format(
                _("msgMainscreen", "%s, strength:%.1f%%"),
                exuari_stations,
                exuariValuePercentage
            )
        else
            exuari_stations = string.format(
                _("msgMainscreen", "Exuari stations: strength:%.1f%%"),
                exuariValuePercentage
            )
        end
    end
    local neutral_stations = ""
    if type(neutralCountPercentage) == "number" then
        neutral_stations = string.format(
            _("msgMainscreen", "Neutral stations: survived:%.1f%%"),
            neutralCountPercentage
        )
    end
    if type(neutralValuePercentage) == "number" then
        if neutral_stations ~= "" then
            neutral_stations = string.format(
                _("msgMainscreen", "%s, strength:%.1f%%"),
                neutral_stations,
                neutralValuePercentage
            )
        else
            neutral_stations = string.format(
                _("msgMainscreen", "Neutral stations: strength:%.1f%%"),
                neutralValuePercentage
            )
        end
    end
    local human_ships = ""
    if type(humanMilitaryShipValuePercentage) == "number" then
        human_ships = string.format(
            _("msgMainscreen", "Human ships: strength:%.1f%%"),
            humanMilitaryShipValuePercentage
        )
    end
    local arlenian_ships = ""
    if type(arlenianMilitaryShipValuePercentage) == "number" then
        arlenian_ships = string.format(
            _("msgMainscreen", "Arlenian ships: strength:%.1f%%"),
            arlenianMilitaryShipValuePercentage
        )
    end
    local alliedValue = humanValuePercentage / 100 * 0.5
        + arlenianValuePercentage / 100 * 0.25
        + humanMilitaryShipValuePercentage / 100 * 0.17
        + arlenianMilitaryShipValuePercentage / 100 * 0.08
    local enemyValue = kraylorValuePercentage / 100 * 0.35
        + exuariValuePercentage / 100 * 0.35
        + kraylorMilitaryShipValuePercentage / 100 * 0.15
        + exuariMilitaryShipValuePercentage / 100 * 0.15
    local rankVal = alliedValue * 0.5 + (1 - enemyValue) * 0.5
    local reason_for_mission_end = ""
    if missionCompleteReason ~= nil then
        reason_for_mission_end = string.format(
            _("msgMainscreen", "Mission ended because %s"),
            missionCompleteReason
        )
    end
    local rank_weight = {
        { rank = _("msgMainscreen", "Ensign"), v_thresh = 0.7, d_thresh = 0.6 },
        {
            rank = _("msgMainscreen", "Lieutenant"),
            v_thresh = 0.8,
            d_thresh = 0.7,
        },
        {
            rank = _("msgMainscreen", "Commander"),
            v_thresh = 0.9,
            d_thresh = 0.8,
        },
        {
            rank = _("msgMainscreen", "Captain"),
            v_thresh = 0.95,
            d_thresh = 0.9,
        },
        { rank = _("msgMainscreen", "Admiral"), v_thresh = 1, d_thresh = 1 },
    }
    local rank = ""
    for i, r_item in ipairs(rank_weight) do
        if missionVictory then
            if rankVal < r_item.v_thresh then
                rank = string.format(
                    _("msgMainscreen", "Earned rank: %s"),
                    r_item.rank
                )
                break
            end
        else
            if rankVal < r_item.d_thresh then
                rank = string.format(
                    _("msgMainscreen", "Earned rank: %s"),
                    r_item.rank
                )
                break
            end
        end
    end
    local gMsg = ""
    if human_stations ~= "" then
        gMsg = human_stations
    end
    if arlenian_stations ~= "" then
        if gMsg ~= "" then
            gMsg = string.format("%s\n%s", gMsg, arlenian_stations)
        else
            gMsg = arlenian_stations
        end
    end
    if kraylor_stations ~= "" then
        if gMsg ~= "" then
            gMsg = string.format("%s\n%s", gMsg, kraylor_stations)
        else
            gMsg = kraylor_stations
        end
    end
    if exuari_stations ~= "" then
        if gMsg ~= "" then
            gMsg = string.format("%s\n%s", gMsg, exuari_stations)
        else
            gMsg = exuari_stations
        end
    end
    if neutral_stations ~= "" then
        if gMsg ~= "" then
            gMsg = string.format("%s\n%s", gMsg, neutral_stations)
        else
            gMsg = neutral_stations
        end
    end
    if human_ships ~= "" then
        if gMsg ~= "" then
            gMsg = string.format("%s\n%s", gMsg, human_ships)
        else
            gMsg = human_ships
        end
    end
    if arlenian_ships ~= "" then
        if gMsg ~= "" then
            gMsg = string.format("%s\n%s", gMsg, arlenian_ships)
        else
            gMsg = arlenian_ships
        end
    end
    if reason_for_mission_end ~= "" then
        if gMsg ~= "" then
            gMsg = string.format("%s\n%s", gMsg, reason_for_mission_end)
        else
            gMsg = reason_for_mission_end
        end
    end
    if rank ~= "" then
        if gMsg ~= "" then
            gMsg = string.format("%s\n%s", gMsg, rank)
        else
            gMsg = rank
        end
    end
    if endStatDiagnostic then
        print(gMsg)
    end
    globalMessage(gMsg)
    if endStatDiagnostic then
        print("sent to the global message function")
    end
end
function update(delta)
    if delta == 0 then
        --game paused
        setPlayers()
        return
    end
    if #getActivePlayerShips() < 1 then
        return
    end
    if updateDiagnostic then
        print("plotManager")
    end
    if plotManager ~= nil then
        plotManager(delta)
    end
    if updateDiagnostic then
        print("plot1")
    end
    if plot1 ~= nil then --randomly chosen plot
        plot1(delta)
    end
    if updateDiagnostic then
        print("plotM")
    end
    if plotM ~= nil then --moving objects
        plotM(delta)
    end
    if updateDiagnostic then
        print("plotCI")
    end
    if plotCI ~= nil then --cargo inventory
        plotCI(delta)
    end
    if updateDiagnostic then
        print("plotH")
    end
    if plotH ~= nil then --health
        plotH(delta)
    end
    if plotCN ~= nil then --coolant via nebula
        plotCN(delta)
    end
end
