-- Name: Close the Gaps
-- Description: Using Nautilus class mine layer, lay mines across the space lanes expected to be used by invading enemies
---
--- Version 2 - Jan2025
---
--- Mission advice: It's better to hit an asteroid than a mine
-- Type: Mission
-- Setting[Enemies]: Configures strength and/or number of enemies in this scenario
-- Enemies[Easy]: Fewer or weaker enemies
-- Enemies[Normal|Default]: Normal number or strength of enemies
-- Enemies[Hard]: More or stronger enemies
-- Enemies[Extreme]: Much stronger, many more enemies
-- Enemies[Quixotic]: Insanely strong and/or inordinately large numbers of enemies
-- Setting[Murphy]: Configures the perversity of the universe according to Murphy's law
-- Murphy[Easy]: Random factors or puzzle difficulties are easier than normal
-- Murphy[Normal|Default]: Random factors or puzzle difficulties are normal
-- Murphy[Hard]: Random factors or puzzle difficulties are more challenging than normal
-- Setting[Timed]: Sets whether or not the scenario has a time limit. Default is no time limit
-- Timed[None|Default]: No time limit
-- Timed[30]: Scenario ends in 30 minutes
-- Timed[40]: Scenario ends in 40 minutes
-- Timed[45]: Scenario ends in 45 minutes
-- Timed[50]: Scenario ends in 50 minutes
-- Timed[55]: Scenario ends in 55 minutes
-- Timed[60]: Scenario ends in 60 minutes
-- Timed[70]: Scenario ends in 70 minutes
-- Timed[80]: Scenario ends in 80 minutes
-- Timed[90]: Scenario ends in 90 minutes

require("utils.lua")
local PlayerState = require("player_state_scenario_utility.lua")
require("place_station_scenario_utility.lua")
local Environment = require("environment_scenario_utility.lua")
local createRandomAlongArc = Environment.createRandomAlongArc
local defaults = require("defaults_scenario_utility.lua")
local ShipNames = require("player_ship_names_scenario_utility.lua")
local ShipComms = require("comms_ship_support.lua")
local enemyComms = ShipComms.enemyCommsAlternate
local Fleet = require("spawn_ships_scenario_utility.lua")
local StationCore = require("comms_station_core.lua")
local StationMenu = require("comms_station_menu.lua")
local ShipStatus = require("ship_status_scenario_utility.lua")
local crew_status = ShipStatus.new({
    consequence_mode = "crew_only",
    notifications = {
        { position = "Engineering", suffix = "" },
        { position = "Engineering+", suffix = "Plus" },
    },
})
local Relation = require("comms_relation_scenario_utility.lua")
local station_profile
local relation = Relation.new({})
isAllowedTo = relation.isAllowedTo
getFriendStatus = relation.friendStatus

local StationKnowledge = require("station_knowledge.lua")
function randomNearStation5(nobj)
    return StationKnowledge.randomNearStations(nobj, stationList, 5, irandom)
end

local crewFate = ShipStatus.fateCallback(crew_status)

local playerPower = Fleet.playerPowerGetter({
    player = function(index) return getPlayerShip(index) end,
    limit = 8,
    minimum = 24,
})

local goodsOnShip = ShipComms.goodsOnShip


function init()
    scenario_version = "2.0.9"
    ee_version = "2024.12.08"
    print(
        string.format(
            "    ----    Scenario: Close the Gaps    ----    Version %s    ----    Tested with EE version %s    ----",
            scenario_version,
            ee_version
        )
    )
    if _VERSION ~= nil then
        print("Lua version:", _VERSION)
    end
    setVariations()
    setConstants()
    setGlobals()
    mainGMButtons()
    buildStations()
    spawnPlayer()
    plot1 = initialInstructions
    initialOrderTimer = 3
    buildAsteroids()
    if not diagnostic then
        createRandomAlongArc(
            Nebula,
            difficulty * 10,
            50000,
            50000,
            70000,
            180,
            270,
            35000
        )
    end
    wfv = "end of init"
end
function setConstants()
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
    }
    -- rough hexagonal deployment
    fleetPosDelta2x = {
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
    }
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
    commonGoods = defaults.goods().commonGoods
    componentGoods = defaults.goods().componentGoods
    mineralGoods = defaults.goods().mineralGoods
end
function setGlobals()
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
    diagnostic = false
    interwave_delay_name = _("buttonGM", "Normal")
    interWave = 150
    goods = {} --overall tracking of goods
    stationList = {} --friendly and neutral stations
    enemyStationList = {}
    tradeFood = {} --stations that will trade food for other goods
    tradeLuxury = {} --stations that will trade luxury for other goods
    tradeMedicine = {} --stations that will trade medicine for other goods
    --Player ship name lists to supplant standard randomized call sign generation
    playerShipNamesForMP52Hornet = ShipNames.pool("MP52 Hornet")
    playerShipNamesForPiranha = ShipNames.pool("Piranha")
    playerShipNamesForFlaviaPFalcon = ShipNames.pool("Flavia P.Falcon")
    playerShipNamesForPhobosM3P = ShipNames.pool("Phobos M3P")
    playerShipNamesForAtlantis = ShipNames.pool("Atlantis")
    playerShipNamesForCruiser = ShipNames.pool("Vindicator")
    playerShipNamesForMissileCruiser = ShipNames.pool("Avalanche")
    playerShipNamesForFighter = ShipNames.pool("Stingray")
    playerShipNamesForBenedict = ShipNames.pool("Benedict")
    playerShipNamesForKiriya = ShipNames.pool("Kiriya")
    playerShipNamesForStriker =
        { "Sparrow", "Sizzle", "Squawk", "Crow", "Phoenix", "Snowbird", "Hawk" }
    playerShipNamesForLindworm = ShipNames.pool("ZX-Lindworm")
    playerShipNamesForRepulse = ShipNames.pool("Repulse")
    playerShipNamesForEnder = ShipNames.pool("Ender")
    playerShipNamesForNautilus = ShipNames.pool("Nautilus")
    playerShipNamesForHathcock = ShipNames.pool("Hathcock")
    playerShipNamesForLeftovers = { "Foregone", "Righteous", "Masher" }
    primaryOrders = ""
    secondaryOrders = ""
    optionalOrders = ""
    transportList = {}
    transportSpawnDelay = 10
    healthCheckTimer = 5
    healthCheckTimerInterval = 5
    northMineCount = -1
    southMineCount = -1
    eastMineCount = -1
    westMineCount = -1
    northObjCount = -1
    southObjCount = -1
    eastObjCount = -1
    westObjCount = -1
    northClosed = false
    southClosed = false
    eastClosed = false
    westClosed = false
    northMet = false
    southMet = false
    eastMet = false
    westMet = false
    --North
    ndiv2s1 = 0 --division 2, section 1
    ndiv2s2 = 0 --division 2, section 2
    ndiv2s3 = 0 --division 2, section 3
    ndiv2s4 = 0 --division 2, section 4
    ndiv1s1 = 0 --division 1, section 1
    ndiv1s2 = 0 --division 1, section 2
    --South
    sdiv2s1 = 0 --division 2, section 1
    sdiv2s2 = 0 --division 2, section 2
    sdiv2s3 = 0 --division 3, section 3
    sdiv2s4 = 0 --division 4, section 4
    sdiv1s1 = 0 --division 1, section 1
    sdiv1s2 = 0 --division 1, section 2
    --East
    ediv2s1 = 0 --division 2, section 1
    ediv2s2 = 0 --division 2, section 2
    ediv2s3 = 0 --division 2, section 3
    ediv2s4 = 0 --division 2, section 4
    ediv1s1 = 0 --division 1, section 1
    ediv1s2 = 0 --division 1, section 2
    --West
    wdiv2s1 = 0 --division 2, section 1
    wdiv2s2 = 0 --division 2, section 2
    wdiv2s3 = 0 --division 2, section 3
    wdiv2s4 = 0 --division 2, section 4
    wdiv1s1 = 0 --division 1, section 1
    wdiv1s2 = 0 --division 1, section 2
    north_gap_graphic = false
    south_gap_graphic = false
    east_gap_graphic = false
    west_gap_graphic = false
end
function mainGMButtons()
    clearGMFunctions()
    if diagnostic then
        diagnostic_string = _("diagnosticState", "true")
    else
        diagnostic_string = _("diagnosticState", "false")
    end
    addGMFunction(
        string.format(_("buttonGM", "Diagnostic %s"), diagnostic_string),
        function()
            if diagnostic then
                diagnostic = false
                mainGMButtons()
            else
                diagnostic = true
                mainGMButtons()
            end
        end
    )
    addGMFunction(
        string.format(_("buttonGM", "+Delay %s"), interwave_delay_name),
        setDelay
    )
end
function setDelay()
    clearGMFunctions()
    addGMFunction(_("buttonGM", "-Main from delay"), mainGMButtons)
    --Slow is used for testing when the tester does not want constant enemy ships spawned while testing
    local button_label = _("buttonGM", "Slow")
    if interwave_delay_name == _("buttonGM", "Slow") then
        button_label = button_label .. "*"
    end
    addGMFunction(button_label, function()
        interwave_delay_name = _("buttonGM", "Slow")
        interWave = 600
        setDelay()
    end)
    --Normal is the normal amount of time between enemy ship spawns
    button_label = _("buttonGM", "Normal")
    if interwave_delay_name == _("buttonGM", "Normal") then
        button_label = button_label .. "*"
    end
    addGMFunction(button_label, function()
        interwave_delay_name = _("buttonGM", "Normal")
        interWave = 150
        setDelay()
    end)
    --Fast is for testing of the enemy ship spawn routine
    button_label = _("buttonGM", "Fast")
    if interwave_delay_name == _("buttonGM", "Fast") then
        button_label = button_label .. "*"
    end
    addGMFunction(button_label, function()
        interwave_delay_name = _("buttonGM", "Fast")
        interWave = 20
        setDelay()
    end)
end
function setVariations()
    local enemy_config = {
        ["Easy"] = { number = 0.5 },
        ["Normal"] = { number = 1 },
        ["Hard"] = { number = 2 },
        ["Extreme"] = { number = 3 },
        ["Quixotic"] = { number = 5 },
    }
    enemy_power = enemy_config[getScenarioSetting("Enemies")].number
    local murphy_config = {
        ["Easy"] = { number = 0.5, gap = 5 },
        ["Normal"] = { number = 1, gap = 10 },
        ["Hard"] = { number = 2, gap = 15 },
    }
    difficulty = murphy_config[getScenarioSetting("Murphy")].number
    gapCheckDelayTimer = murphy_config[getScenarioSetting("Murphy")].gap
    gapCheckInterval = gapCheckDelayTimer
    local timed_config = {
        ["None"] = { limit = 0, limited = false },
        ["30"] = { limit = 30, limited = true },
        ["40"] = { limit = 40, limited = true },
        ["45"] = { limit = 45, limited = true },
        ["50"] = { limit = 50, limited = true },
        ["55"] = { limit = 55, limited = true },
        ["60"] = { limit = 60, limited = true },
        ["70"] = { limit = 70, limited = true },
        ["80"] = { limit = 80, limited = true },
        ["90"] = { limit = 90, limited = true },
    }
    playWithTimeLimit = timed_config[getScenarioSetting("Timed")].limited
    defaultGameTimeLimitInMinutes =
        timed_config[getScenarioSetting("Timed")].limit
    gameTimeLimit = defaultGameTimeLimitInMinutes * 60
end
function buildStations()
    stationFaction = "Human Navy"
    psx = 0 --place station x coordinate
    psy = 0 --place station y coordinate
    homeStation = placeStation(0, 0, "RandomHumanNeutral", "Human Navy")
    table.insert(stationList, homeStation)
    table.insert(
        stationList,
        placeStation(31000, 31000, "RandomHumanNeutral", "Independent")
    )
    table.insert(
        stationList,
        placeStation(-31000, 31000, "RandomHumanNeutral", "Independent")
    )
    table.insert(
        stationList,
        placeStation(31000, -31000, "RandomHumanNeutral", "Independent")
    )
    table.insert(
        stationList,
        placeStation(-31000, -31000, "RandomHumanNeutral", "Independent")
    )
    local placed_station = placeStation(0, -60000, "Sinister", "Kraylor")
    table.insert(enemyStationList, placed_station)
    local fleet = spawnEnemies(0, -60000, 10, "Kraylor")
    for i, ship in ipairs(fleet) do
        ship:orderDefendTarget(placed_station)
    end
    placed_station = placeStation(0, 60000, "Sinister", "Ghosts")
    table.insert(enemyStationList, placed_station)
    fleet = spawnEnemies(0, 60000, 10, "Ghosts")
    for i, ship in ipairs(fleet) do
        ship:orderDefendTarget(placed_station)
    end
    placed_station = placeStation(60000, 0, "Sinister", "Exuari")
    table.insert(enemyStationList, placed_station)
    fleet = spawnEnemies(60000, 0, 10, "Exuari")
    for i, ship in ipairs(fleet) do
        ship:orderDefendTarget(placed_station)
    end
    placed_station = placeStation(-60000, 0, "Sinister", "Ktlitans")
    table.insert(enemyStationList, placed_station)
    fleet = spawnEnemies(-60000, 0, 10, "Ktlitans")
    for i, ship in ipairs(fleet) do
        ship:orderDefendTarget(placed_station)
    end
end
function spawnPlayer()
    local px, py = vectorFromAngle(random(0, 360), random(2500, 3000))
    player = PlayerSpaceship()
        :setFaction("Human Navy")
        :setTemplate(ST.NAUTILUS)
        :setPosition(px, py)
    ni = math.random(1, #playerShipNamesForNautilus)
    player:setCallSign(playerShipNamesForNautilus[ni])
    table.remove(playerShipNamesForNautilus, ni)
    player.nameAssigned = true
    player.shipScore = 12
    player.maxCargo = 7
    player.cargo = 7
    player.maxRepairCrew = player:getRepairCrewCount()
    player.healthyShield = 1.0
    player.prevShield = 1.0
    player.healthyReactor = 1.0
    player.prevReactor = 1.0
    player.healthyManeuver = 1.0
    player.prevManeuver = 1.0
    player.healthyImpulse = 1.0
    player.prevImpulse = 1.0
    player.healthyBeam = 1.0
    player.prevBeam = 1.0
    player.healthyMissile = 1.0
    player.prevMissile = 1.0
    player.healthyJump = 1.0
    player.prevJump = 1.0
    player.healthyWarp = 1.0
    player.prevWarp = 1.0
    goods[player] = goodsList
    player:addReputationPoints(100)
    player.initialRep = true
    allowNewPlayerShips(false)
end
function buildAsteroids()
    local lowerDensity = 70
    local upperDensity = 150
    local thickness = 2000
    --Arcs
    createRandomAlongArc(
        Asteroid,
        random(lowerDensity, upperDensity),
        0,
        0,
        20000,
        5,
        85,
        thickness
    )
    createRandomAlongArc(
        Asteroid,
        random(lowerDensity, upperDensity),
        0,
        0,
        20000,
        95,
        175,
        thickness
    )
    createRandomAlongArc(
        Asteroid,
        random(lowerDensity, upperDensity),
        0,
        0,
        20000,
        185,
        265,
        thickness
    )
    createRandomAlongArc(
        Asteroid,
        random(lowerDensity, upperDensity),
        0,
        0,
        20000,
        275,
        355,
        thickness
    )
    --Bulges
    local ax, ay = vectorFromAngle(random(20, 70), 20000)
    placeRandomAroundPoint(Asteroid, 40, 1, 5000, ax, ay)
    ax, ay = vectorFromAngle(random(110, 160), 20000)
    placeRandomAroundPoint(Asteroid, 40, 1, 5000, ax, ay)
    ax, ay = vectorFromAngle(random(200, 250), 20000)
    placeRandomAroundPoint(Asteroid, 40, 1, 5000, ax, ay)
    ax, ay = vectorFromAngle(random(290, 340), 20000)
    placeRandomAroundPoint(Asteroid, 40, 1, 5000, ax, ay)
end
-- Transport ship generation and handling
function transportPlot(delta)
    if transportSpawnDelay > 0 then
        transportSpawnDelay = transportSpawnDelay - delta
    end
    if transportSpawnDelay < 0 then
        transportSpawnDelay = delta + random(5, 15)
        transportCount = 0
        for tidx, obj in ipairs(transportList) do
            if obj:isValid() then
                if obj:isDocked(obj.target) then
                    if obj.undock_delay > 0 then
                        obj.undock_delay = obj.undock_delay - 1
                    else
                        obj.target = randomNearStation5(obj)
                        obj.undock_delay = irandom(1, 4)
                        obj:orderDock(obj.target)
                    end
                end
                transportCount = transportCount + 1
            end
        end
        lastTransportCount = transportCount
        if transportCount < #transportList then
            tempTransportList = {}
            for _, obj in ipairs(transportList) do
                if obj:isValid() then
                    table.insert(tempTransportList, obj)
                end
            end
            transportList = tempTransportList
        end
        if #transportList < #stationList then
            target = nil
            repeat
                candidate = stationList[math.random(1, #stationList)]
                if candidate:isValid() then
                    target = candidate
                end
            until target ~= nil
            rnd = irandom(1, 5)
            if rnd == 1 then
                name = "Personnel"
            elseif rnd == 2 then
                name = "Goods"
            elseif rnd == 3 then
                name = "Garbage"
            elseif rnd == 4 then
                name = "Equipment"
            else
                name = "Fuel"
            end
            if irandom(1, 100) < 30 then
                name = name .. " Jump Freighter " .. irandom(3, 5)
            else
                name = name .. " Freighter " .. irandom(1, 5)
            end
            obj = CpuShip()
                :setTemplate(name)
                :setFaction("Independent")
                :setCommsScript("")
                :setCommsFunction(commsShip)
            obj.target = target
            obj.undock_delay = irandom(1, 4)
            rifl = math.floor(random(1, #goodsList)) -- random item from list
            goodsType = goodsList[rifl][1]
            if goodsType == nil then
                goodsType = "nickel"
            end
            rcoi = math.floor(random(30, 90)) -- random cost of item
            goods[obj] = { { goodsType, 1, rcoi } }
            obj:orderDock(obj.target)
            x, y = obj.target:getPosition()
            xd, yd = vectorFromAngle(random(0, 360), random(25000, 40000))
            obj:setPosition(x + xd, y + yd)
            table.insert(transportList, obj)
        end
    end
end
-- Station communication
commsStation = StationMenu.entrypoint(function() return station_profile end)
local function explainMinefield()
    addCommsReply(_("minefield-comms", "What is a minefield?"), function()
        local mMsg = string.format(
            _(
                "minefield-comms",
                "For the automated sensors on station %s to register a minefield as completed across a gap, it must meet the following criteria:"
            ),
            homeStation:getCallSign()
        )
        mMsg = string.format(
            _(
                "minefield-comms",
                "%s\n   1. Must contain at least 12 mines: Nautilus class standard load"
            ),
            mMsg
        )
        mMsg = string.format(
            _(
                "minefield-comms",
                "%s\n   2. Must be within a 1.5U radius of sector corner in gap"
            ),
            mMsg
        )
        if difficulty > 0.5 then
            mMsg = string.format(
                _(
                    "minefield-comms",
                    "%s\n   3. Must be centered: 6 on one side and 6 on the other"
                ),
                mMsg
            )
        end
        if difficulty > 1 then
            mMsg = string.format(
                _(
                    "minefield-comms",
                    "%s\n   4. Must be along 20U distance from station line connecting asteroids"
                ),
                mMsg
            )
        end
        setCommsMessage(mMsg)
        if not northMet then
            addCommsReply(
                _(
                    "minefield-comms",
                    "What do the sensors show for the north gap?"
                ),
                commsNorthGap
            )
        end
        if not southMet then
            addCommsReply(
                _(
                    "minefield-comms",
                    "What do the sensors show for the south gap?"
                ),
                commsSouthGap
            )
        end
        if not eastMet then
            addCommsReply(
                _(
                    "minefield-comms",
                    "What do the sensors show for the east gap?"
                ),
                commsEastGap
            )
        end
        if not westMet then
            addCommsReply(
                _(
                    "minefield-comms",
                    "What do the sensors show for the west gap?"
                ),
                commsWestGap
            )
        end
        addCommsReply(_("Back"), commsStation)
    end)
end

local function setOptionalOrders()
    optionalOrders = ""
end

local function showCurrentOrders()
    setOptionalOrders()
    ordMsg = primaryOrders .. "\n" .. secondaryOrders .. optionalOrders
    if playWithTimeLimit then
        ordMsg = ordMsg
            .. string.format(
                _("orders-comms", "\n   %i Minutes remain in game"),
                math.floor(gameTimeLimit / 60)
            )
    end
    setCommsMessage(ordMsg)
    addCommsReply(
        _("minefield-comms", "What is a minefield?"),
        explainMinefield
    )
end

local function addDiagnosticData()
    --Diagnostic data is used to help test and debug the script while it is under construction
    if diagnostic then
        addCommsReply("Diagnostic data", function()
            oMsg = string.format("Difficulty: %.1f", difficulty)
            if playWithTimeLimit then
                oMsg = oMsg
                    .. string.format("  time remaining: %.1f", gameTimeLimit)
            end
            if plot1name == nil or plot1 == nil then
                oMsg = oMsg .. ""
            else
                oMsg = oMsg .. "\nplot1: " .. plot1name
                oMsg = oMsg
                    .. string.format(
                        "\nobject count N: %i, S: %i, E: %i, W: %i",
                        northObjCount,
                        southObjCount,
                        eastObjCount,
                        westObjCount
                    )
                oMsg = oMsg
                    .. string.format(
                        "\nCheck Timer: %.1f wave timer: %.1f",
                        gapCheckDelayTimer,
                        waveTimer
                    )
                oMsg = oMsg .. string.format("\nInterwave: %i", interWave)
            end
            oMsg = oMsg .. "\n" .. wfv
            setCommsMessage(oMsg)
            addCommsReply(_("Back"), commsStation)
        end)
    end
end

station_profile = {
    main_menu = commsStation,
    prepare = function()
        setPlayers()
        local data = comms_target.comms_data
        data.general = data.general or comms_target.generalInformation
        data.history = data.history or comms_target.stationHistory
        data.gossip = data.gossip or comms_target.gossip
    end,
    weapon_availability = {
        Nuke = 4,
        EMP = 5,
        Homing = 6,
        Mine = 7,
        HVLI = 9,
        always = function(weapon)
            if weapon == "Mine" and comms_target == homeStation then
                return true
            end
        end,
    },
    require_docked = true,
    goods_name = function(good)
        return good_desc[good]
    end,
    goods_knowledge = {
        stations = function()
            return stationList
        end,
        max = 5,
    },
    resources = {
        prompt = false,
        recruitment = {
            mode = "immediate",
            available = function()
                return math.random(1, 6) <= (4 - difficulty)
            end,
        },
    },
    docked = {
        greeting = "fixed",
        show_reputation = false,
        group_services = false,
        service_prompt = false,
        service_sections = { "ordnance" },
        restock = "alternate",
        ordnance = {
            show_reputation = false,
            prompts = {
                Mine = {
                    _("ammo-comms", "We could use some mines. ("),
                    _("ammo-comms", "How about mines? ("),
                    _("ammo-comms", "More mines ("),
                    _("ammo-comms", "All the mines we can take. ("),
                    _("ammo-comms", "Mines! What else? ("),
                },
            },
        },
        before_resources = function()
            if comms_source:isFriendly(comms_target) then
                StationMenu.currentOrders(station_profile, showCurrentOrders)
            end
            if comms_target.publicRelations then
                StationMenu.gossip(station_profile, {
                    gossip_roll = "half",
                    back = false,
                })
            end
        end,
        group_resources = false,
    },
    undocked = {
        waypoint_id = function(index)
            return comms_source:getWaypointID(index)
        end,
        information = {
            prompt = _(
                "station-comms",
                "What kind of information do you need?"
            ),
            sections = {
                { kind = "ordnance" },
                { kind = "goods_available" },
                { kind = "enemy_warning" },
                { kind = "goods_knowledge" },
                {
                    kind = "general_information",
                    available = function()
                        return comms_target.publicRelations
                    end,
                },
            },
        },
        before_assistance = function()
            if comms_source:isFriendly(comms_target) then
                StationMenu.currentOrders(station_profile, showCurrentOrders)
            end
            addDiagnosticData()
        end,
        assistance = true,
    },
}
function commsNorthGap()
    string.format("")
    local cMsg = string.format(
        _("minefield-comms", "Count within 1.5U radius: %i."),
        northObjCount
    )
    if difficulty < 1 then
        cMsg = string.format(_("minefield-comms", "%s\nYou need twelve."), cMsg)
    elseif difficulty > 1 then
        --division 2, section 1         0
        --division 2, section 2 | 3 | 2 | 4 | 1 |
        --division 2, section 3     |       |
        --division 2, section 4   -750     750
        cMsg = string.format(
            _("minefield-comms", "%s\nCount near middle on the right: %i."),
            cMsg,
            ndiv2s4
        )
        cMsg = string.format(
            _("minefield-comms", "%s\nCount near middle on the left: %i."),
            cMsg,
            ndiv2s2
        )
        cMsg = string.format(
            _("minefield-comms", "%s\nCount near asteroids on the left: %i."),
            cMsg,
            ndiv2s3
        )
        cMsg = string.format(
            _("minefield-comms", "%s\nCount near asteroids on the right: %i."),
            cMsg,
            ndiv2s1
        )
        cMsg = string.format(
            _(
                "minefield-comms",
                "%s\n\nYou need three in each sensor scan area."
            ),
            cMsg
        )
    else --difficulty is 1 (normal)
        cMsg = string.format(
            _("minefield-comms", "%s\nCount on the right: %i."),
            cMsg,
            ndiv1s1
        )
        cMsg = string.format(
            _("minefield-comms", "%s\nCount on the left: %i."),
            cMsg,
            ndiv1s2
        )
        cMsg = string.format(
            _("minefield-comms", "%s\n\nYou need six in each sensor scan area."),
            cMsg
        )
    end
    cMsg = string.format(
        _("minefield-comms", "%s\nSensors refresh every %i seconds."),
        cMsg,
        gapCheckInterval
    )
    cMsg = string.format(
        _("minefield-comms", "%s\nNext refresh in approximately %i seconds."),
        cMsg,
        math.floor(gapCheckDelayTimer)
    )
    setCommsMessage(cMsg)
    north_gap_graphic = true
    addCommsReply(_("Back"), commsStation)
end
function commsSouthGap()
    string.format("")
    local cMsg = string.format(
        _("minefield-comms", "Count within 1.5U radius: %i"),
        southObjCount
    )
    if difficulty < 1 then
        cMsg = string.format(_("minefield-comms", "%s\nYou need twelve."), cMsg)
    elseif difficulty > 1 then
        --division 2, section 1   -750     750
        --division 2, section 2     |       |
        --division 3, section 3 | 3 | 2 | 1 | 4
        --division 4, section 4         0
        cMsg = string.format(
            _("minefield-comms", "%s\nCount near middle on the right: %i"),
            cMsg,
            sdiv2s1
        )
        cMsg = string.format(
            _("minefield-comms", "%s\nCount near middle on the left: %i"),
            cMsg,
            sdiv2s2
        )
        cMsg = string.format(
            _("minefield-comms", "%s\nCount near asteroids on the left: %i"),
            cMsg,
            sdiv2s3
        )
        cMsg = string.format(
            _("minefield-comms", "%s\nCount near asteroids on the right: %i"),
            cMsg,
            sdiv2s4
        )
        cMsg = string.format(
            _(
                "minefield-comms",
                "%s\n\nYou need three in each sensor scan area"
            ),
            cMsg
        )
    else --difficulty is 1 (normal)
        cMsg = string.format(
            _("minefield-comms", "%s\nCount on the right: %i"),
            cMsg,
            sdiv1s1
        )
        cMsg = string.format(
            _("minefield-comms", "%s\nCount on the left: %i"),
            cMsg,
            sdiv1s2
        )
        cMsg = string.format(
            _("minefield-comms", "%s\n\nYou need six in each sensor scan area"),
            cMsg
        )
    end
    cMsg = string.format(
        _("minefield-comms", "%s\nSensors refresh every %i seconds"),
        cMsg,
        gapCheckInterval
    )
    cMsg = string.format(
        _("minefield-comms", "%s\nNext refresh in approximately %i seconds."),
        cMsg,
        math.floor(gapCheckDelayTimer)
    )
    setCommsMessage(cMsg)
    south_gap_graphic = true
    addCommsReply(_("Back"), commsStation)
end
function commsEastGap()
    string.format("")
    local cMsg = string.format(
        _("minefield-comms", "Count within radius: %i"),
        eastObjCount
    )
    if difficulty < 1 then
        cMsg = string.format(_("minefield-comms", "%s\nYou need twelve."), cMsg)
    elseif difficulty > 1 then
        --              -
        --              3
        -- -750 -
        --              2
        --              - 0
        --              1
        --      750 -
        --              4
        --              -
        cMsg = string.format(
            _("minefield-comms", "%s\nCount near middle below: %i"),
            cMsg,
            ediv2s1
        )
        cMsg = string.format(
            _("minefield-comms", "%s\nCount near middle above: %i"),
            cMsg,
            ediv2s2
        )
        cMsg = string.format(
            _("minefield-comms", "%s\nCount near asteroids above: %i"),
            cMsg,
            ediv2s3
        )
        cMsg = string.format(
            _("minefield-comms", "%s\nCount near asteroids below: %i"),
            cMsg,
            ediv2s4
        )
        cMsg = string.format(
            _(
                "minefield-comms",
                "%s\n\nYou need three in each sensor scan area"
            ),
            cMsg
        )
    else
        cMsg = string.format(
            _("minefield-comms", "%s\nCount below: %i"),
            cMsg,
            ediv1s1
        ) --was 2432: applies to normal difficulty
        cMsg = string.format(
            _("minefield-comms", "%s\nCount above: %i"),
            cMsg,
            ediv1s2
        ) --was 2433: applies to normal difficulty
        cMsg = string.format(
            _("minefield-comms", "%s\n\nYou need six in each sensor scan area"),
            cMsg
        )
    end
    cMsg = string.format(
        _("minefield-comms", "%s\nSensors refresh every %i seconds"),
        cMsg,
        gapCheckInterval
    )
    cMsg = string.format(
        _("minefield-comms", "%s\nNext refresh in approximately %i seconds."),
        cMsg,
        math.floor(gapCheckDelayTimer)
    )
    setCommsMessage(cMsg)
    east_gap_graphic = true
    addCommsReply(_("Back"), commsStation)
end
function commsWestGap()
    string.format("")
    local cMsg = string.format(
        _("minefield-comms", "Count within radius: %i"),
        westObjCount
    )
    if difficulty < 1 then
        cMsg = string.format(_("minefield-comms", "%s\nYou need twelve."), cMsg)
    elseif difficulty > 1 then
        --              -
        --              3
        --              - -750
        --              2
        --        0 -
        --              1
        --              -  750
        --              4
        --              -
        cMsg = string.format(
            _("minefield-comms", "%s\nCount near middle below: %i"),
            cMsg,
            wdiv2s1
        )
        cMsg = string.format(
            _("minefield-comms", "%s\nCount near middle above: %i"),
            cMsg,
            wdiv2s2
        )
        cMsg = string.format(
            _("minefield-comms", "%s\nCount near asteroids above: %i"),
            cMsg,
            wdiv2s3
        )
        cMsg = string.format(
            _("minefield-comms", "%s\nCount near asteroids below: %i"),
            cMsg,
            wdiv2s4
        )
        cMsg = string.format(
            _(
                "minefield-comms",
                "%s\n\nYou need three in each sensor scan area"
            ),
            cMsg
        )
    else
        cMsg = string.format(
            _("minefield-comms", "%s\nCount below: %i"),
            cMsg,
            wdiv1s1
        ) --was 2452: applies to normal difficulty
        cMsg = string.format(
            _("minefield-comms", "%s\nCount above: %i"),
            cMsg,
            wdiv1s2
        ) --was 2453: applies to normal difficulty
        cMsg = string.format(
            _("minefield-comms", "%s\n\nYou need six in each sensor scan area"),
            cMsg
        )
    end
    cMsg = string.format(
        _("minefield-comms", "%s\nSensors refresh every %i seconds"),
        cMsg,
        gapCheckInterval
    )
    cMsg = string.format(
        _("minefield-comms", "%s\nNext refresh in approximately %i seconds."),
        cMsg,
        math.floor(gapCheckDelayTimer)
    )
    setCommsMessage(cMsg)
    west_gap_graphic = true
    addCommsReply(_("Back"), commsStation)
end
function commsShip()
    if comms_target.comms_data == nil then
        comms_target.comms_data = { friendlyness = random(0.0, 100.0) }
    end
    if comms_target.comms_data.goods == nil then
        goodsOnShip(comms_target, comms_target.comms_data)
    end
    setPlayers()
    if comms_source:isFriendly(comms_target) then
        return friendlyComms()
    end
    if
        comms_source:isEnemy(comms_target)
        and comms_target:isFriendOrFoeIdentifiedBy(comms_source)
    then
        return enemyComms()
    end
    return neutralComms()
end
function friendlyComms()
    if comms_target.comms_data.friendlyness < 20 then
        setCommsMessage(_("shipAssist-comms", "What do you want?"))
    else
        setCommsMessage(_("shipAssist-comms", "Sir, how can we assist?"))
    end
    addCommsReply(_("shipAssist-comms", "Defend a waypoint"), function()
        if comms_source:getWaypointCount() == 0 then
            setCommsMessage(
                _(
                    "shipAssist-comms",
                    "No waypoints set. Please set a waypoint first."
                )
            )
            addCommsReply(_("Back"), commsShip)
        else
            setCommsMessage(
                _("shipAssist-comms", "Which waypoint should we defend?")
            )
            for n = 1, comms_source:getWaypointCount() do
                addCommsReply(
                    string.format(
                        _("shipAssist-comms", "Defend WP %d"),
                        comms_source:getWaypointID(n)
                    ),
                    function()
                        comms_target:orderDefendLocation(
                            comms_source:getWaypoint(n)
                        )
                        setCommsMessage(
                            string.format(
                                _(
                                    "shipAssist-comms",
                                    "We are heading to assist at WP %d."
                                ),
                                comms_source:getWaypointID(n)
                            )
                        )
                        addCommsReply(_("Back"), commsShip)
                    end
                )
            end
        end
    end)
    if comms_target.comms_data.friendlyness > 0.2 then
        addCommsReply(_("shipAssist-comms", "Assist me"), function()
            setCommsMessage(
                _("shipAssist-comms", "Heading toward you to assist.")
            )
            comms_target:orderDefendTarget(comms_source)
            addCommsReply(_("Back"), commsShip)
        end)
    end
    addCommsReply(_("shipAssist-comms", "Report status"), function()
        local msg = string.format(
            _("shipAssist-comms", "Hull: %d%%\n"),
            comms_target:getHullPercentage()
        )
        local shields = comms_target:getShieldCount()
        if shields == 1 then
            msg = string.format(
                _("shipAssist-comms", "%sShield: %d%%\n"),
                msg,
                math.floor(
                    comms_target:getShieldLevel(0)
                        / comms_target:getShieldMax(0)
                        * 100
                )
            )
        elseif shields == 2 then
            msg = string.format(
                _("shipAssist-comms", "%sFront Shield: %d%%\n"),
                msg,
                math.floor(
                    comms_target:getShieldLevel(0)
                        / comms_target:getShieldMax(0)
                        * 100
                )
            )
            msg = string.format(
                _("shipAssist-comms", "%sRear Shield: %d%%\n"),
                msg,
                math.floor(
                    comms_target:getShieldLevel(1)
                        / comms_target:getShieldMax(1)
                        * 100
                )
            )
        else
            for n = 0, shields - 1 do
                msg = string.format(
                    _("shipAssist-comms", "%sShield %s: %d%%\n"),
                    msg,
                    n,
                    math.floor(
                        comms_target:getShieldLevel(n)
                            / comms_target:getShieldMax(n)
                            * 100
                    )
                )
            end
        end
        missile_types = { "Homing", "Nuke", "Mine", "EMP", "HVLI" }
        for i, missile_type in ipairs(missile_types) do
            if comms_target:getWeaponStorageMax(missile_type) > 0 then
                msg = string.format(
                    _("shipAssist-comms", "%s%s Missiles: %d/%d\n"),
                    msg,
                    missile_type,
                    math.floor(comms_target:getWeaponStorage(missile_type)),
                    math.floor(comms_target:getWeaponStorageMax(missile_type))
                )
            end
        end
        setCommsMessage(msg)
        addCommsReply(_("Back"), commsShip)
    end)
    for idx, obj in ipairs(comms_target:getObjectsInRange(5000)) do
        if
            isObjectType(obj, "SpaceStation") and not comms_target:isEnemy(obj)
        then
            addCommsReply(
                string.format(
                    _("shipAssist-comms", "Dock at %s"),
                    obj:getCallSign()
                ),
                function()
                    setCommsMessage(
                        string.format(
                            _("shipAssist-comms", "Docking at %s."),
                            obj:getCallSign()
                        )
                    )
                    comms_target:orderDock(obj)
                    addCommsReply(_("Back"), commsShip)
                end
            )
        end
    end
    return true
end
function neutralComms()
    shipType = comms_target:getTypeName()
    if shipType:find("Freighter") ~= nil then
        if comms_target.comms_data.friendlyness > 66 then
            setCommsMessage(_("trade-comms", "Yes?"))
            -- Offer destination information
            addCommsReply(_("trade-comms", "Where are you headed?"), function()
                setCommsMessage(comms_target.target:getCallSign())
                addCommsReply(_("Back"), commsShip)
            end)
            -- Offer to trade goods if goods or equipment freighter
            if distance(comms_source, comms_target) < 5000 then
                local goodCount = 0
                if comms_source.goods ~= nil then
                    for good, goodQuantity in pairs(comms_source.goods) do
                        if goodQuantity > 0 then
                            goodCount = goodCount + 1
                        end
                    end
                end
                if goodCount > 0 then
                    addCommsReply(_("trade-comms", "Jettison cargo"), function()
                        setCommsMessage(
                            string.format(
                                _(
                                    "trade-comms",
                                    "Available space: %i\nWhat would you like to jettison?"
                                ),
                                comms_source.cargo
                            )
                        )
                        for good, good_quantity in pairs(comms_source.goods) do
                            if good_quantity > 0 then
                                addCommsReply(good_desc[good], function()
                                    comms_source.goods[good] = comms_source.goods[good]
                                        - 1
                                    comms_source.cargo = comms_source.cargo + 1
                                    setCommsMessage(
                                        string.format(
                                            _(
                                                "trade-comms",
                                                "One %s jettisoned"
                                            ),
                                            good_desc[good]
                                        )
                                    )
                                    addCommsReply(_("Back"), commsShip)
                                end)
                            end
                        end
                        addCommsReply(_("Back"), commsShip)
                    end)
                end
                if
                    shipType:find("Goods") ~= nil
                    or shipType:find("Equipment") ~= nil
                then
                    local luxury_quantity = 0
                    if comms_source.goods ~= nil then
                        for good, goodQuantity in pairs(comms_source.goods) do
                            if good == "luxury" and goodQuantity > 0 then
                                luxury_quantity = luxury_quantity + 1
                            end
                        end
                    end
                    if luxury_quantity > 0 then
                        if comms_target.comms_data.goods ~= nil then
                            for good, good_data in
                                pairs(comms_target.comms_data.goods)
                            do
                                if
                                    good_data.quantity > 0
                                    and good ~= "luxury"
                                then
                                    addCommsReply(
                                        string.format(
                                            _(
                                                "trade-comms",
                                                "Trade luxury for %s"
                                            ),
                                            good_desc[good]
                                        ),
                                        function()
                                            string.format("")
                                            if good_data.quantity < 1 then
                                                setCommsMessage(
                                                    _(
                                                        "trade-comms",
                                                        "Insufficient inventory on freighter for trade."
                                                    )
                                                )
                                            elseif
                                                comms_source.goods.luxury < 1
                                            then
                                                setCommsMessage(
                                                    _(
                                                        "trade-comms",
                                                        "Insufficient inventory on your ship for trade."
                                                    )
                                                )
                                            else
                                                comms_source.goods.luxury = comms_source.goods.luxury
                                                    - 1
                                                comms_source.goods[good] = comms_source.goods[good]
                                                    + 1
                                                good_data.quantity = good_data.quantity
                                                    - 1
                                                setCommsMessage(
                                                    _("trade-comms", "Traded")
                                                )
                                            end
                                            addCommsReply(_("Back"), commsShip)
                                        end
                                    )
                                end
                            end
                        end
                    end
                else
                    if comms_target.comms_data.goods ~= nil then
                        for good, good_data in
                            pairs(comms_target.comms_data.goods)
                        do
                            if good_data.quantity > 0 then
                                addCommsReply(
                                    string.format(
                                        "Buy one %s for %i reputation",
                                        good_desc[good],
                                        math.floor(good_data.cost)
                                    ),
                                    function()
                                        if comms_source.cargo < 1 then
                                            setCommsMessage(
                                                _(
                                                    "trade-comms",
                                                    "Insufficient cargo space for purchase"
                                                )
                                            )
                                        elseif good_data.quantity < 1 then
                                            setCommsMessage(
                                                _(
                                                    "trade-comms",
                                                    "Insufficient inventory on freighter"
                                                )
                                            )
                                        else
                                            if
                                                comms_source:takeReputationPoints(
                                                    math.floor(good_data.cost)
                                                )
                                            then
                                                comms_source.cargo = comms_source.cargo
                                                    - 1
                                                if
                                                    comms_source.goods == nil
                                                then
                                                    comms_source.goods = {}
                                                end
                                                if
                                                    comms_source.goods[good]
                                                    == nil
                                                then
                                                    comms_source.goods[good] = 0
                                                end
                                                comms_source.goods[good] = comms_source.goods[good]
                                                    + 1
                                                setCommsMessage(
                                                    _(
                                                        "trade-comms",
                                                        "Purchased"
                                                    )
                                                )
                                                good_data.quantity = good_data.quantity
                                                    - 1
                                            else
                                                setCommsMessage(
                                                    _(
                                                        "needRep-comms",
                                                        "Insufficient reputation for purchase"
                                                    )
                                                )
                                            end
                                        end
                                        addCommsReply(_("Back"), commsShip)
                                    end
                                )
                            end
                        end
                    end
                end
            end
        elseif comms_target.comms_data.friendlyness > 33 then
            setCommsMessage(_("shipAssist-comms", "What do you want?"))
            -- Offer to sell destination information
            destRep = math.random(1, 5)
            addCommsReply(
                string.format(
                    _(
                        "trade-comms",
                        "Where are you headed? (cost: %i reputation)"
                    ),
                    destRep
                ),
                function() --was 3443: make reputation integer
                    if not comms_source:takeReputationPoints(destRep) then
                        setCommsMessage(
                            _("needRep-comms", "Insufficient reputation")
                        )
                    else
                        setCommsMessage(comms_target.target:getCallSign())
                    end
                    addCommsReply(_("Back"), commsShip)
                end
            )
            -- Offer to sell goods if goods or equipment freighter
            if distance(comms_source, comms_target) < 5000 then
                if
                    shipType:find("Goods") ~= nil
                    or shipType:find("Equipment") ~= nil
                then
                    if comms_target.comms_data.goods ~= nil then
                        for good, good_data in
                            pairs(comms_target.comms_data.goods)
                        do
                            if good_data.quantity > 0 then
                                addCommsReply(
                                    string.format(
                                        "Buy one %s for %i reputation",
                                        good_desc[good],
                                        math.floor(good_data.cost)
                                    ),
                                    function()
                                        if comms_source.cargo < 1 then
                                            setCommsMessage(
                                                _(
                                                    "trade-comms",
                                                    "Insufficient cargo space for purchase"
                                                )
                                            )
                                        elseif good_data.quantity < 1 then
                                            setCommsMessage(
                                                _(
                                                    "trade-comms",
                                                    "Insufficient inventory on freighter"
                                                )
                                            )
                                        else
                                            if
                                                comms_source:takeReputationPoints(
                                                    math.floor(good_data.cost)
                                                )
                                            then
                                                comms_source.cargo = comms_source.cargo
                                                    - 1
                                                if
                                                    comms_source.goods == nil
                                                then
                                                    comms_source.goods = {}
                                                end
                                                if
                                                    comms_source.goods[good]
                                                    == nil
                                                then
                                                    comms_source.goods[good] = 0
                                                end
                                                comms_source.goods[good] = comms_source.goods[good]
                                                    + 1
                                                setCommsMessage(
                                                    _(
                                                        "trade-comms",
                                                        "Purchased"
                                                    )
                                                )
                                                good_data.quantity = good_data.quantity
                                                    - 1
                                            else
                                                setCommsMessage(
                                                    _(
                                                        "needRep-comms",
                                                        "Insufficient reputation for purchase"
                                                    )
                                                )
                                            end
                                        end
                                        addCommsReply(_("Back"), commsShip)
                                    end
                                )
                            end
                        end
                    end
                else
                    -- Offer to sell goods double price
                    if comms_target.comms_data.goods ~= nil then
                        for good, good_data in
                            pairs(comms_target.comms_data.goods)
                        do
                            if good_data.quantity > 0 then
                                addCommsReply(
                                    string.format(
                                        "Buy one %s for %i reputation",
                                        good_desc[good],
                                        math.floor(good_data.cost * 2)
                                    ),
                                    function()
                                        if comms_source.cargo < 1 then
                                            setCommsMessage(
                                                _(
                                                    "trade-comms",
                                                    "Insufficient cargo space for purchase"
                                                )
                                            )
                                        elseif good_data.quantity < 1 then
                                            setCommsMessage(
                                                _(
                                                    "trade-comms",
                                                    "Insufficient inventory on freighter"
                                                )
                                            )
                                        else
                                            if
                                                comms_source:takeReputationPoints(
                                                    math.floor(
                                                        good_data.cost * 2
                                                    )
                                                )
                                            then
                                                comms_source.cargo = comms_source.cargo
                                                    - 1
                                                if
                                                    comms_source.goods == nil
                                                then
                                                    comms_source.goods = {}
                                                end
                                                if
                                                    comms_source.goods[good]
                                                    == nil
                                                then
                                                    comms_source.goods[good] = 0
                                                end
                                                comms_source.goods[good] = comms_source.goods[good]
                                                    + 1
                                                setCommsMessage(
                                                    _(
                                                        "trade-comms",
                                                        "Purchased"
                                                    )
                                                )
                                                good_data.quantity = good_data.quantity
                                                    - 1
                                            else
                                                setCommsMessage(
                                                    _(
                                                        "needRep-comms",
                                                        "Insufficient reputation for purchase"
                                                    )
                                                )
                                            end
                                        end
                                        addCommsReply(_("Back"), commsShip)
                                    end
                                )
                            end
                        end
                    end
                end
            end
        else
            setCommsMessage(_("trade-comms", "Why are you bothering me?"))
            -- Offer to sell goods if goods or equipment freighter double price
            if distance(comms_source, comms_target) < 5000 then
                if
                    shipType:find("Goods") ~= nil
                    or shipType:find("Equipment") ~= nil
                then
                    if comms_target.comms_data.goods ~= nil then
                        for good, good_data in
                            pairs(comms_target.comms_data.goods)
                        do
                            if good_data.quantity > 0 then
                                addCommsReply(
                                    string.format(
                                        "Buy one %s for %i reputation",
                                        good_desc[good],
                                        math.floor(good_data.cost * 2)
                                    ),
                                    function()
                                        if comms_source.cargo < 1 then
                                            setCommsMessage(
                                                _(
                                                    "trade-comms",
                                                    "Insufficient cargo space for purchase"
                                                )
                                            )
                                        elseif good_data.quantity < 1 then
                                            setCommsMessage(
                                                _(
                                                    "trade-comms",
                                                    "Insufficient inventory on freighter"
                                                )
                                            )
                                        else
                                            if
                                                comms_source:takeReputationPoints(
                                                    math.floor(
                                                        good_data.cost * 2
                                                    )
                                                )
                                            then
                                                comms_source.cargo = comms_source.cargo
                                                    - 1
                                                if
                                                    comms_source.goods == nil
                                                then
                                                    comms_source.goods = {}
                                                end
                                                if
                                                    comms_source.goods[good]
                                                    == nil
                                                then
                                                    comms_source.goods[good] = 0
                                                end
                                                comms_source.goods[good] = comms_source.goods[good]
                                                    + 1
                                                setCommsMessage(
                                                    _(
                                                        "trade-comms",
                                                        "Purchased"
                                                    )
                                                )
                                                good_data.quantity = good_data.quantity
                                                    - 1
                                            else
                                                setCommsMessage(
                                                    _(
                                                        "needRep-comms",
                                                        "Insufficient reputation for purchase"
                                                    )
                                                )
                                            end
                                        end
                                        addCommsReply(_("Back"), commsShip)
                                    end
                                )
                            end
                        end
                    end
                end
            end
        end
    else
        if comms_target.comms_data.friendlyness > 50 then
            setCommsMessage(
                _(
                    "ship-comms",
                    "Sorry, we have no time to chat with you.\nWe are on an important mission."
                )
            )
        else
            setCommsMessage(
                _("ship-comms", "We have nothing for you.\nGood day.")
            )
        end
    end
    return true
end
--set up players with name, goods, cargo space, reputation and either a warp drive or a jump drive if applicable
local function playerNamePools()
    return {
        MP52Hornet = playerShipNamesForMP52Hornet,
        Piranha = playerShipNamesForPiranha,
        FlaviaPFalcon = playerShipNamesForFlaviaPFalcon,
        PhobosM3P = playerShipNamesForPhobosM3P,
        Atlantis = playerShipNamesForAtlantis,
        Cruiser = playerShipNamesForCruiser,
        MissileCruiser = playerShipNamesForMissileCruiser,
        Fighter = playerShipNamesForFighter,
        Benedict = playerShipNamesForBenedict,
        Kiriya = playerShipNamesForKiriya,
        Striker = playerShipNamesForStriker,
        Lindworm = playerShipNamesForLindworm,
        Repulse = playerShipNamesForRepulse,
        Ender = playerShipNamesForEnder,
        Nautilus = playerShipNamesForNautilus,
        Hathcock = playerShipNamesForHathcock,
        Leftovers = playerShipNamesForLeftovers,
    }
end

local player_profiles = {
    ["MP52 Hornet"] = { names = "MP52Hornet", score = 7, cargo = 3, coolant_field = "autoCoolant", auto_coolant = false, warp = true },
    ["Piranha"] = { names = "Piranha", score = 16, cargo = 8 },
    ["Flavia P.Falcon"] = { names = "FlaviaPFalcon", score = 13, cargo = 15 },
    ["Phobos M3P"] = { names = "PhobosM3P", score = 19, cargo = 10, warp = true },
    ["Atlantis"] = { names = "Atlantis", score = 52, cargo = 6 },
    ["Vindicator"] = { names = "Cruiser", score = 40, cargo = 6 },
    ["Avalanche"] = { names = "MissileCruiser", score = 45, cargo = 8 },
    ["Stingray"] = { names = "Fighter", score = 7, cargo = 3, coolant_field = "autoCoolant", auto_coolant = false, jump = { 3000, 40000 } },
    ["Benedict"] = { names = "Benedict", score = 10, cargo = 9 },
    ["Kiriya"] = { names = "Kiriya", score = 10, cargo = 9 },
    ["Crow"] = { names = "Striker", score = 8, cargo = 4, jump = { 3000, 40000 } },
    ["ZX-Lindworm"] = { names = "Lindworm", score = 8, cargo = 3, coolant_field = "autoCoolant", auto_coolant = false, warp = true },
    ["Repulse"] = { names = "Repulse", score = 14, cargo = 12 },
    ["Ender"] = { names = "Ender", score = 100, cargo = 20 },
    ["Nautilus"] = { names = "Nautilus", score = 12, cargo = 7 },
    ["Hathcock"] = { names = "Hathcock", score = 30, cargo = 6 },
}

function setPlayers()
    concurrentPlayerCount = 0
    for p1idx = 1, 8 do
        pobj = getPlayerShip(p1idx)
        if pobj ~= nil and pobj:isValid() then
            concurrentPlayerCount = concurrentPlayerCount + 1
            if goods[pobj] == nil then
                goods[pobj] = goodsList
            end
            if pobj.initialRep == nil then
                pobj:addReputationPoints(250 - (difficulty * 6))
                pobj.initialRep = true
            end
            if not pobj.nameAssigned then
                pobj.nameAssigned = true
                pobj.spinUpgrade = false
                pobj.beamTimeUpgrade = false
                pobj.hullUpgrade = false
                PlayerState.applyShipProfile(pobj, {
                    profiles = player_profiles,
                    name_pools = playerNamePools,
                    fallback = { names = "Leftovers", score = 24, cargo = 5, warp = true },
                    score_field = "shipScore",
                    cargo_field = "maxCargo",
                    name_selection = "remove",
                })
                if pobj.cargo == nil then
                    pobj.cargo = pobj.maxCargo
                    PlayerState.resetBaseline(pobj, {
                        tube_size = false,
                        initial_coolant = false,
                        coolant_rates = false,
                        beam_range_threshold = 1,
                    })
                end
            end
        end
    end
    setConcurrenetPlayerCount = concurrentPlayerCount
end
function healthCheck(delta)
    healthCheckTimer = healthCheckTimer - delta
    if healthCheckTimer < 0 then
        for pidx = 1, 8 do
            p = getPlayerShip(pidx)
            if p ~= nil and p:isValid() then
                if p:getRepairCrewCount() > 0 then
                    fatalityChance = 0
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
                    fatalityChance = fatalityChance
                        + (p.prevReactor - p:getSystemHealth("reactor"))
                    p.prevReactor = p:getSystemHealth("reactor")
                    fatalityChance = fatalityChance
                        + (p.prevManeuver - p:getSystemHealth("maneuver"))
                    p.prevManeuver = p:getSystemHealth("maneuver")
                    fatalityChance = fatalityChance
                        + (p.prevImpulse - p:getSystemHealth("impulse"))
                    p.prevImpulse = p:getSystemHealth("impulse")
                    if p:getBeamWeaponRange(0) > 1 then
                        if p.healthyBeam == nil then
                            p.healthyBeam = 1.0
                            p.prevBeam = 1.0
                        end
                        fatalityChance = fatalityChance
                            + (p.prevBeam - p:getSystemHealth("beamweapons"))
                        p.prevBeam = p:getSystemHealth("beamweapons")
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
                    if p:hasWarpDrive() then
                        if p.healthyWarp == nil then
                            p.healthyWarp = 1.0
                            p.prevWarp = 1.0
                        end
                        fatalityChance = fatalityChance
                            + (p.prevWarp - p:getSystemHealth("warp"))
                        p.prevWarp = p:getSystemHealth("warp")
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
                    if p:getRepairCrewCount() == 1 then
                        fatalityChance = fatalityChance / 2 -- increase chances of last repair crew standing
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
function initialInstructions(delta)
    plot1name = "initialInstructions"
    initialOrderTimer = initialOrderTimer - delta
    if initialOrderTimer < 0 then
        player:addToShipLog(
            string.format(
                _(
                    "goal-shiplog",
                    "Since %s is so isolated and so close to enemy territory, we need you to lay a minefield across each gap in the surrounding asteroids"
                ),
                homeStation:getCallSign()
            ),
            "Magenta"
        )
        primaryOrders = _(
            "goal-comms",
            "Lay minefield across each gap in surrounding asteroids."
        )
        plot1 = checkGaps
        plot1name = "checkGaps"
        waveTimer = interWave
        plot2 = waves
        plot2name = "waves"
    end
end
function checkGaps(delta)
    gapCheckDelayTimer = gapCheckDelayTimer - delta
    if gapCheckDelayTimer < 0 then
        if not southMet then
            prevSouthClosed = southClosed
            southMineCount = 0
            southClosed = checkSouthernGap()
            if prevSouthClosed and southClosed then
                southMet = true
                player:addToShipLog(
                    string.format(
                        _(
                            "minefieldOrder-shiplog",
                            "Congratulations, You've closed the gap at heading 180 from %s"
                        ),
                        homeStation:getCallSign()
                    ),
                    "Magenta"
                )
                primaryOrders = primaryOrders
                    .. _("minefieldOrders-comms", " South gap closed.")
                player:addReputationPoints(20 - (difficulty * 6))
            end
        end
        if not northMet then
            prevNorthClosed = northClosed
            northMineCount = 0
            northClosed = checkNorthernGap()
            if prevNorthClosed and northClosed then
                northMet = true
                player:addToShipLog(
                    string.format(
                        _(
                            "minefieldOrders-shiplog",
                            "Congratulations, You've closed the gap at heading 0 from %s"
                        ),
                        homeStation:getCallSign()
                    ),
                    "Magenta"
                )
                primaryOrders = primaryOrders
                    .. _("minefieldOrders-comms", " North gap closed.")
                player:addReputationPoints(20 - (difficulty * 6))
            end
        end
        if not westMet then
            prevWestClosed = westClosed
            westMineCount = 0
            westClosed = checkWesternernGap()
            if prevWestClosed and westClosed then
                westMet = true
                player:addToShipLog(
                    string.format(
                        _(
                            "minefieldOrders-shiplog",
                            "Congratulations, You've closed the gap at heading 270 from %s"
                        ),
                        homeStation:getCallSign()
                    ),
                    "Magenta"
                )
                primaryOrders = primaryOrders
                    .. _("minefieldOrders-comms", " West gap closed.")
                player:addReputationPoints(20 - (difficulty * 6))
            end
        end
        if not eastMet then
            prevEastClosed = eastClosed
            eastMineCount = 0
            eastClosed = checkEasternernGap()
            if prevEastClosed and eastClosed then
                eastMet = true
                player:addToShipLog(
                    string.format(
                        _(
                            "minefieldOrders-shiplog",
                            "Congratulations, You've closed the gap at heading 90 from %s"
                        ),
                        homeStation:getCallSign()
                    ),
                    "Magenta"
                )
                primaryOrders = primaryOrders
                    .. _("minefieldOrders-comms", " East gap closed.")
                player:addReputationPoints(20 - (difficulty * 6))
            end
        end
        if southMet and northMet and westMet and eastMet then
            if playWithTimeLimit then
                for pidx = 1, 8 do
                    p = getPlayerShip(pidx)
                    if p ~= nil and p:isValid() then
                        p:addReputationPoints(100)
                        p:addToShipLog(
                            string.format(
                                _(
                                    "minefieldOrders-shiplog",
                                    "You've closed the gaps. Now for the Quixotic part: go destroy the enemy bases surrounding us while keeping %s alive. You'll find them straight out from the gaps"
                                ),
                                homeStation:getCallSign()
                            ),
                            "Magenta"
                        )
                        primaryOrders = string.format(
                            _(
                                "minefieldOrders-comms",
                                "Protect %s. Destroy enemy bases straight out from gaps"
                            ),
                            homeStation:getCallSign()
                        )
                    end
                end
                plot1name = "destroyEnemyBases"
                plot1 = destroyEnemyBases
            else
                victory("Human Navy")
            end
        end
        if homeStation == nil or not homeStation:isValid() then
            local mine_count = 0
            for pidx = 1, 32 do
                local p = getPlayerShip(pidx)
                if p ~= nil and p:isValid() then
                    mine_count = mine_count + p:getWeaponStorage("Mine")
                end
            end
            if mine_count == 0 then
                victory("Kraylor")
            end
        end
        gapCheckDelayTimer = delta + gapCheckInterval
    end
end
function checkEasternernGap()
    local gapClosed = false
    eastObjCount = 0
    local eastObjs = getObjectsInRadius(20000, 0, 1500)
    local east_mines = {}
    for _, obj in ipairs(eastObjs) do
        if isObjectType(obj, "Mine") then
            eastObjCount = eastObjCount + 1
            table.insert(east_mines, obj)
        end
    end
    if difficulty < 1 then
        if eastObjCount >= 12 then
            gapClosed = true
        end
    elseif difficulty > 1 then
        ediv2s1 = 0 --division 2, section 1             --              -
        ediv2s2 = 0 --division 2, section 2             --              3
        ediv2s3 = 0 --division 2, section 3             -- -750 -
        ediv2s4 = 0 --division 2, section 4             --              2
        for i, m in ipairs(east_mines) do --            - 0
            local mx, my = m:getPosition() --           1
            if mx < 20375 and mx > 19625 then --        750 -
                if my > 0 then --               4
                    if my > 750 then --         -
                        ediv2s4 = ediv2s4 + 1
                    else
                        ediv2s1 = ediv2s1 + 1
                    end
                end
                if my < 0 then
                    if my < -750 then
                        ediv2s3 = ediv2s3 + 1
                    else
                        ediv2s2 = ediv2s2 + 1
                    end
                end
            end
        end
        if ediv2s1 >= 3 and ediv2s2 >= 3 and ediv2s3 >= 3 and ediv2s4 >= 3 then
            gapClosed = true
        end
    else
        ediv1s1 = 0 --division 1, section 1
        ediv1s2 = 0 --division 1, section 2
        for i, m in ipairs(east_mines) do
            local mx, my = m:getPosition()
            if my > 0 then
                ediv1s1 = ediv1s1 + 1
            end
            if my < 0 then
                ediv1s2 = ediv1s2 + 1
            end
        end
        if ediv1s1 >= 6 and ediv1s2 >= 6 then
            gapClosed = true
        end
    end
    return gapClosed
end
function checkWesternernGap()
    local gapClosed = false
    westObjCount = 0
    local westObjs = getObjectsInRadius(-20000, 0, 1500)
    local west_mines = {}
    for _, obj in ipairs(westObjs) do
        if isObjectType(obj, "Mine") then
            westObjCount = westObjCount + 1
            table.insert(west_mines, obj)
        end
    end
    if difficulty < 1 then
        if westObjCount >= 12 then
            gapClosed = true
        end
    elseif difficulty > 1 then
        wdiv2s1 = 0 --division 2, section 1             --              -
        wdiv2s2 = 0 --division 2, section 2             --              3
        wdiv2s3 = 0 --division 2, section 3             --              - -750
        wdiv2s4 = 0 --division 2, section 4             --              2
        for i, m in ipairs(west_mines) do --      0 -
            local mx, my = m:getPosition() --           1
            if mx < 20375 and mx > 19625 then --                -  750
                if my > 0 then --               4
                    if my > 750 then --         -
                        wdiv2s4 = wdiv2s4 + 1
                    else
                        wdiv2s1 = wdiv2s1 + 1
                    end
                end
                if my < 0 then
                    if my < -750 then
                        wdiv2s3 = wdiv2s3 + 1
                    else
                        wdiv2s2 = wdiv2s2 + 1
                    end
                end
            end
        end
        if wdiv2s1 >= 3 and wdiv2s2 >= 3 and wdiv2s3 >= 3 and wdiv2s4 >= 3 then
            gapClosed = true
        end
    else
        wdiv1s1 = 0 --division 1, section 1
        wdiv1s2 = 0 --division 1, section 2
        for i, m in ipairs(west_mines) do
            local mx, my = m:getPosition()
            if my > 0 then
                wdiv1s1 = wdiv1s1 + 1
            end
            if my < 0 then
                wdiv1s2 = wdiv1s2 + 1
            end
        end
        if wdiv1s1 >= 6 and wdiv1s2 >= 6 then
            gapClosed = true
        end
    end
    return gapClosed
end
function checkNorthernGap()
    local gapClosed = false
    northObjCount = 0
    local northObjs = getObjectsInRadius(0, -20000, 1500)
    local north_mines = {}
    for _, obj in ipairs(northObjs) do
        if isObjectType(obj, "Mine") then
            northObjCount = northObjCount + 1
            table.insert(north_mines, obj)
        end
    end
    if difficulty < 1 then
        if northObjCount >= 12 then
            gapClosed = true
        end
    elseif difficulty > 1 then
        ndiv2s1 = 0 --division 2, section 1         0
        ndiv2s2 = 0 --division 2, section 2 | 3 | 2 | 4 | 1 |
        ndiv2s3 = 0 --division 2, section 3     |       |
        ndiv2s4 = 0 --division 2, section 4   -750     750
        for i, m in ipairs(north_mines) do
            local mx, my = m:getPosition()
            if my > -20375 and my < -19625 then
                if mx > 0 then
                    if mx > 750 then
                        ndiv2s4 = ndiv2s4 + 1
                    else
                        ndiv2s1 = ndiv2s1 + 1
                    end
                end
                if mx < 0 then
                    if mx < -750 then
                        ndiv2s3 = ndiv2s3 + 1
                    else
                        ndiv2s2 = ndiv2s2 + 1
                    end
                end
            end
        end
        if ndiv2s1 >= 3 and ndiv2s2 >= 3 and ndiv2s3 >= 3 and ndiv2s4 >= 3 then
            gapClosed = true
        end
    else --difficulty is 1 (normal)
        ndiv1s1 = 0 --division 1, section 1     0
        ndiv1s2 = 0 --division 1, section 2 | 2 | 1 |
        for i, m in ipairs(north_mines) do
            local mx, my = m:getPosition()
            if mx > 0 then
                ndiv1s1 = ndiv1s1 + 1
            end
            if mx < 0 then
                ndiv1s2 = ndiv1s2 + 1
            end
        end
        if ndiv1s1 >= 6 and ndiv1s2 >= 6 then
            gapClosed = true
        end
    end
    return gapClosed
end
function checkSouthernGap()
    local gapClosed = false
    southObjCount = 0
    local southObjs = getObjectsInRadius(0, 20000, 1500)
    local south_mines = {}
    for _, obj in ipairs(southObjs) do
        if isObjectType(obj, "Mine") then
            southObjCount = southObjCount + 1
            table.insert(south_mines, obj)
        end
    end
    if difficulty < 1 then
        if southObjCount >= 12 then
            gapClosed = true
        end
    elseif difficulty > 1 then
        sdiv2s1 = 0 --division 2, section 1   -750     750
        sdiv2s2 = 0 --division 2, section 2     |       |
        sdiv2s3 = 0 --division 3, section 3 | 3 | 2 | 1 | 4
        sdiv2s4 = 0 --division 4, section 4         0
        for i, m in ipairs(south_mines) do
            local mx, my = m:getPosition()
            if my > 19625 and my < 20375 then
                if mx > 0 then
                    if mx > 750 then
                        sdiv2s4 = sdiv2s4 + 1
                    else
                        sdiv2s1 = sdiv2s1 + 1
                    end
                end
                if mx < 0 then
                    if mx < -750 then
                        sdiv2s3 = sdiv2s3 + 1
                    else
                        sdiv2s2 = sdiv2s2 + 1
                    end
                end
            end
        end
        if sdiv2s1 >= 3 and sdiv2s2 >= 3 and sdiv2s3 >= 3 and sdiv2s4 >= 3 then
            gapClosed = true
        end
    else --difficulty is 1 (normal)
        sdiv1s1 = 0 --division 1, section 1 | 2 | 1 |
        sdiv1s2 = 0 --division 1, section 2     0
        for i, m in ipairs(south_mines) do
            local mx, my = m:getPosition()
            if mx > 0 then
                sdiv1s1 = sdiv1s1 + 1
            end
            if mx < 0 then
                sdiv1s2 = sdiv1s2 + 1
            end
        end
        if sdiv1s1 >= 6 and sdiv1s2 >= 6 then
            gapClosed = true
        end
    end
    return gapClosed
end
function gapGraphic()
    local blue_value = { 64, 192, 96, 160, 255, 128 }
    if north_gap_graphic then
        if north_gap_phase == nil then
            north_gap_phase = 1
            north_gap_angle = random(0, 10)
            north_gap_zones = {}
            local zone_points = {}
            for k = 1, 6 do
                local zx, zy = vectorFromAngle(north_gap_angle, 1500, true)
                zone_points[k] = { x = zx, y = -20000 + zy }
                north_gap_angle = (north_gap_angle + 60) % 360
            end
            local zone = Zone():setPoints(
                zone_points[1].x,
                zone_points[1].y,
                zone_points[2].x,
                zone_points[2].y,
                zone_points[3].x,
                zone_points[3].y,
                zone_points[4].x,
                zone_points[4].y,
                zone_points[5].x,
                zone_points[5].y,
                zone_points[6].x,
                zone_points[6].y
            ):setColor(0, 0, blue_value[north_gap_phase])
            zone.hex = true
            table.insert(north_gap_zones, zone)
            if difficulty == 1 then
                zone = Zone():setPoints(
                    0,
                    -21500,
                    0,
                    -18500,
                    -1500,
                    -18500,
                    -1500,
                    -21500
                ):setColor(128, 0, 0)
                table.insert(north_gap_zones, zone)
                zone = Zone():setPoints(
                    1500,
                    -21500,
                    1500,
                    -18500,
                    0,
                    -18500,
                    0,
                    -21500
                ):setColor(0, 128, 0)
                table.insert(north_gap_zones, zone)
            elseif difficulty > 1 then
                zone = Zone():setPoints(
                    -750,
                    -20375,
                    -750,
                    -19625,
                    -1500,
                    -19625,
                    -1500,
                    -20375
                ):setColor(128, 0, 0)
                table.insert(north_gap_zones, zone)
                zone = Zone():setPoints(
                    0,
                    -20375,
                    0,
                    -19625,
                    -750,
                    -19625,
                    -750,
                    -20375
                ):setColor(0, 128, 0)
                table.insert(north_gap_zones, zone)
                zone = Zone():setPoints(
                    750,
                    -20375,
                    750,
                    -19625,
                    0,
                    -19625,
                    0,
                    -20375
                ):setColor(128, 0, 128)
                table.insert(north_gap_zones, zone)
                zone = Zone():setPoints(
                    1500,
                    -20375,
                    1500,
                    -19625,
                    750,
                    -19625,
                    750,
                    -20375
                ):setColor(255, 255, 0)
                table.insert(north_gap_zones, zone)
            end
            north_gap_time = getScenarioTime() + 1
        else
            if getScenarioTime() > north_gap_time then
                if north_gap_phase ~= 6 then
                    north_gap_angle = north_gap_angle + 10
                    local zone_points = {}
                    for k = 1, 6 do
                        local zx, zy =
                            vectorFromAngle(north_gap_angle, 1500, true)
                        zone_points[k] = { x = zx, y = -20000 + zy }
                        north_gap_angle = (north_gap_angle + 60) % 360
                    end
                    local zone = Zone():setPoints(
                        zone_points[1].x,
                        zone_points[1].y,
                        zone_points[2].x,
                        zone_points[2].y,
                        zone_points[3].x,
                        zone_points[3].y,
                        zone_points[4].x,
                        zone_points[4].y,
                        zone_points[5].x,
                        zone_points[5].y,
                        zone_points[6].x,
                        zone_points[6].y
                    ):setColor(
                        0,
                        0,
                        blue_value[north_gap_phase]
                    )
                    zone.hex = true
                    local destroy_me = north_gap_zones[1]
                    north_gap_zones[1] = zone
                    destroy_me:destroy()
                end
                if north_gap_phase == 1 then
                    if difficulty == 1 then
                        north_gap_zones[2]:setColor(128, 0, 128)
                        north_gap_zones[3]:setColor(128, 0, 0)
                    elseif difficulty > 1 then --R G P Y
                        north_gap_zones[2]:setColor(255, 0, 255) --Y R G P--
                        north_gap_zones[3]:setColor(128, 0, 0) --P Y R G
                        north_gap_zones[4]:setColor(0, 128, 0) --G P Y R
                        north_gap_zones[5]:setColor(128, 0, 128) --R P G Y
                    end --G Y R P
                    north_gap_phase = 2
                    north_gap_time = getScenarioTime() + 1
                elseif north_gap_phase == 2 then
                    if difficulty == 1 then
                        north_gap_zones[2]:setColor(255, 0, 255)
                        north_gap_zones[3]:setColor(128, 0, 128)
                    elseif difficulty > 1 then --R G P Y
                        north_gap_zones[2]:setColor(128, 0, 128) --Y R G P
                        north_gap_zones[3]:setColor(255, 0, 255) --P Y R G--
                        north_gap_zones[4]:setColor(128, 0, 0) --G P Y R
                        north_gap_zones[5]:setColor(0, 128, 0) --R P G Y
                    end --G Y R P
                    north_gap_phase = 3
                    north_gap_time = getScenarioTime() + 1
                elseif north_gap_phase == 3 then
                    if difficulty == 1 then
                        north_gap_zones[2]:setColor(128, 0, 0)
                        north_gap_zones[3]:setColor(255, 0, 255)
                    elseif difficulty > 1 then --R G P Y
                        north_gap_zones[2]:setColor(0, 128, 0) --Y R G P
                        north_gap_zones[3]:setColor(128, 0, 128) --P Y R G
                        north_gap_zones[4]:setColor(255, 0, 255) --G P Y R--
                        north_gap_zones[5]:setColor(128, 0, 0) --R P G Y
                    end --G Y R P
                    north_gap_phase = 4
                    north_gap_time = getScenarioTime() + 1
                elseif north_gap_phase == 4 then
                    if difficulty == 1 then
                        north_gap_zones[2]:setColor(128, 0, 128)
                        north_gap_zones[3]:setColor(128, 0, 0)
                    elseif difficulty > 1 then --R G P Y
                        north_gap_zones[2]:setColor(128, 0, 0) --Y R G P
                        north_gap_zones[3]:setColor(255, 0, 255) --P Y R G
                        north_gap_zones[4]:setColor(0, 128, 0) --G P Y R
                        north_gap_zones[5]:setColor(128, 0, 128) --R Y G P--
                    end --Y P R G
                    north_gap_phase = 5
                    north_gap_time = getScenarioTime() + 1
                elseif north_gap_phase == 5 then
                    if difficulty == 1 then
                        north_gap_zones[2]:setColor(0, 128, 0)
                        north_gap_zones[3]:setColor(128, 0, 128)
                    elseif difficulty > 1 then --R G P Y
                        north_gap_zones[2]:setColor(255, 0, 255) --Y R G P
                        north_gap_zones[3]:setColor(128, 0, 128) --P Y R G
                        north_gap_zones[4]:setColor(128, 0, 0) --G P Y R
                        north_gap_zones[5]:setColor(0, 128, 0) --R Y G P
                    end --Y P R G--
                    north_gap_phase = 6
                    north_gap_time = getScenarioTime() + 1
                elseif north_gap_phase == 6 then
                    north_gap_zones[1]:destroy()
                    if difficulty == 1 then
                        north_gap_zones[2]:destroy()
                        north_gap_zones[3]:destroy()
                    elseif difficulty > 1 then
                        north_gap_zones[2]:destroy()
                        north_gap_zones[3]:destroy()
                        north_gap_zones[4]:destroy()
                        north_gap_zones[5]:destroy()
                    end
                    north_gap_phase = nil
                    north_gap_time = nil
                    north_gap_graphic = false
                end
            end
        end
    end
    if south_gap_graphic then
        if south_gap_phase == nil then
            south_gap_phase = 1
            south_gap_angle = random(0, 10)
            south_gap_zones = {}
            local zone_points = {}
            for k = 1, 6 do
                local zx, zy = vectorFromAngle(south_gap_angle, 1500, true)
                zone_points[k] = { x = zx, y = 20000 + zy }
                south_gap_angle = (south_gap_angle + 60) % 360
            end
            local zone = Zone():setPoints(
                zone_points[1].x,
                zone_points[1].y,
                zone_points[2].x,
                zone_points[2].y,
                zone_points[3].x,
                zone_points[3].y,
                zone_points[4].x,
                zone_points[4].y,
                zone_points[5].x,
                zone_points[5].y,
                zone_points[6].x,
                zone_points[6].y
            ):setColor(0, 0, blue_value[south_gap_phase])
            zone.hex = true
            table.insert(south_gap_zones, zone)
            if difficulty == 1 then
                zone = Zone():setPoints(
                    0,
                    18500,
                    0,
                    21500,
                    -1500,
                    21500,
                    -1500,
                    18500
                ):setColor(128, 0, 0)
                table.insert(south_gap_zones, zone)
                zone = Zone()
                    :setPoints(1500, 18500, 1500, 21500, 0, 21500, 0, 18500)
                    :setColor(0, 128, 0)
                table.insert(south_gap_zones, zone)
            elseif difficulty > 1 then
                zone = Zone():setPoints(
                    -750,
                    19625,
                    -750,
                    20375,
                    -1500,
                    20375,
                    -1500,
                    19625
                ):setColor(128, 0, 0)
                table.insert(south_gap_zones, zone)
                zone = Zone()
                    :setPoints(0, 19625, 0, 20375, -750, 20375, -750, 19625)
                    :setColor(0, 128, 0)
                table.insert(south_gap_zones, zone)
                zone = Zone()
                    :setPoints(750, 19625, 750, 20375, 0, 20375, 0, 19625)
                    :setColor(128, 0, 128)
                table.insert(south_gap_zones, zone)
                zone = Zone():setPoints(
                    1500,
                    19625,
                    1500,
                    20375,
                    750,
                    20375,
                    750,
                    19625
                ):setColor(255, 255, 0)
                table.insert(south_gap_zones, zone)
            end
            south_gap_time = getScenarioTime() + 1
        else
            if getScenarioTime() > south_gap_time then
                if south_gap_phase ~= 6 then
                    south_gap_angle = south_gap_angle + 10
                    local zone_points = {}
                    for k = 1, 6 do
                        local zx, zy =
                            vectorFromAngle(south_gap_angle, 1500, true)
                        zone_points[k] = { x = zx, y = 20000 + zy }
                        south_gap_angle = (south_gap_angle + 60) % 360
                    end
                    local zone = Zone():setPoints(
                        zone_points[1].x,
                        zone_points[1].y,
                        zone_points[2].x,
                        zone_points[2].y,
                        zone_points[3].x,
                        zone_points[3].y,
                        zone_points[4].x,
                        zone_points[4].y,
                        zone_points[5].x,
                        zone_points[5].y,
                        zone_points[6].x,
                        zone_points[6].y
                    ):setColor(
                        0,
                        0,
                        blue_value[south_gap_phase]
                    )
                    zone.hex = true
                    local destroy_me = south_gap_zones[1]
                    south_gap_zones[1] = zone
                    destroy_me:destroy()
                end
                if south_gap_phase == 1 then
                    if difficulty == 1 then
                        south_gap_zones[2]:setColor(128, 0, 128)
                        south_gap_zones[3]:setColor(128, 0, 0)
                    elseif difficulty > 1 then --R G P Y
                        south_gap_zones[2]:setColor(255, 0, 255) --Y R G P--
                        south_gap_zones[3]:setColor(128, 0, 0) --P Y R G
                        south_gap_zones[4]:setColor(0, 128, 0) --G P Y R
                        south_gap_zones[5]:setColor(128, 0, 128) --R P G Y
                    end --G Y R P
                    south_gap_phase = 2
                    south_gap_time = getScenarioTime() + 1
                elseif south_gap_phase == 2 then
                    if difficulty == 1 then
                        south_gap_zones[2]:setColor(255, 0, 255)
                        south_gap_zones[3]:setColor(128, 0, 128)
                    elseif difficulty > 1 then --R G P Y
                        south_gap_zones[2]:setColor(128, 0, 128) --Y R G P
                        south_gap_zones[3]:setColor(255, 0, 255) --P Y R G--
                        south_gap_zones[4]:setColor(128, 0, 0) --G P Y R
                        south_gap_zones[5]:setColor(0, 128, 0) --R P G Y
                    end --G Y R P
                    south_gap_phase = 3
                    south_gap_time = getScenarioTime() + 1
                elseif south_gap_phase == 3 then
                    if difficulty == 1 then
                        south_gap_zones[2]:setColor(128, 0, 0)
                        south_gap_zones[3]:setColor(255, 0, 255)
                    elseif difficulty > 1 then --R G P Y
                        south_gap_zones[2]:setColor(0, 128, 0) --Y R G P
                        south_gap_zones[3]:setColor(128, 0, 128) --P Y R G
                        south_gap_zones[4]:setColor(255, 0, 255) --G P Y R--
                        south_gap_zones[5]:setColor(128, 0, 0) --R P G Y
                    end --G Y R P
                    south_gap_phase = 4
                    south_gap_time = getScenarioTime() + 1
                elseif south_gap_phase == 4 then
                    if difficulty == 1 then
                        south_gap_zones[2]:setColor(128, 0, 128)
                        south_gap_zones[3]:setColor(128, 0, 0)
                    elseif difficulty > 1 then --R G P Y
                        south_gap_zones[2]:setColor(128, 0, 0) --Y R G P
                        south_gap_zones[3]:setColor(255, 0, 255) --P Y R G
                        south_gap_zones[4]:setColor(0, 128, 0) --G P Y R
                        south_gap_zones[5]:setColor(128, 0, 128) --R Y G P--
                    end --Y P R G
                    south_gap_phase = 5
                    south_gap_time = getScenarioTime() + 1
                elseif south_gap_phase == 5 then
                    if difficulty == 1 then
                        south_gap_zones[2]:setColor(0, 128, 0)
                        south_gap_zones[3]:setColor(128, 0, 128)
                    elseif difficulty > 1 then --R G P Y
                        south_gap_zones[2]:setColor(255, 0, 255) --Y R G P
                        south_gap_zones[3]:setColor(128, 0, 128) --P Y R G
                        south_gap_zones[4]:setColor(128, 0, 0) --G P Y R
                        south_gap_zones[5]:setColor(0, 128, 0) --R Y G P
                    end --Y P R G--
                    south_gap_phase = 6
                    south_gap_time = getScenarioTime() + 1
                elseif south_gap_phase == 6 then
                    south_gap_zones[1]:destroy()
                    if difficulty == 1 then
                        south_gap_zones[2]:destroy()
                        south_gap_zones[3]:destroy()
                    elseif difficulty > 1 then
                        south_gap_zones[2]:destroy()
                        south_gap_zones[3]:destroy()
                        south_gap_zones[4]:destroy()
                        south_gap_zones[5]:destroy()
                    end
                    south_gap_phase = nil
                    south_gap_time = nil
                    south_gap_graphic = false
                end
            end
        end
    end
    if east_gap_graphic then
        if east_gap_phase == nil then
            east_gap_phase = 1
            east_gap_angle = random(0, 10)
            east_gap_zones = {}
            local zone_points = {}
            for k = 1, 6 do
                local zx, zy = vectorFromAngle(east_gap_angle, 1500, true)
                zone_points[k] = { x = zx + 20000, y = zy }
                east_gap_angle = (east_gap_angle + 60) % 360
            end
            local zone = Zone():setPoints(
                zone_points[1].x,
                zone_points[1].y,
                zone_points[2].x,
                zone_points[2].y,
                zone_points[3].x,
                zone_points[3].y,
                zone_points[4].x,
                zone_points[4].y,
                zone_points[5].x,
                zone_points[5].y,
                zone_points[6].x,
                zone_points[6].y
            ):setColor(0, 0, blue_value[east_gap_phase])
            zone.hex = true
            table.insert(east_gap_zones, zone)
            if difficulty == 1 then
                zone = Zone():setPoints(
                    21500,
                    -1500,
                    21500,
                    0,
                    18500,
                    0,
                    18500,
                    -1500
                ):setColor(128, 0, 0)
                table.insert(east_gap_zones, zone)
                zone = Zone()
                    :setPoints(21500, 0, 21500, 1500, 18500, 1500, 18500, 0)
                    :setColor(0, 128, 0)
                table.insert(east_gap_zones, zone)
            elseif difficulty > 1 then
                zone = Zone():setPoints(
                    20375,
                    -1500,
                    20375,
                    -750,
                    19625,
                    -750,
                    19625,
                    -1500
                ):setColor(128, 0, 0)
                table.insert(east_gap_zones, zone)
                zone = Zone()
                    :setPoints(20375, -750, 20375, 0, 19625, 0, 19625, -750)
                    :setColor(0, 128, 0)
                table.insert(east_gap_zones, zone)
                zone = Zone()
                    :setPoints(20375, 0, 20375, 750, 19625, 750, 19625, 0)
                    :setColor(128, 0, 128)
                table.insert(east_gap_zones, zone)
                zone = Zone():setPoints(
                    20375,
                    750,
                    20375,
                    1500,
                    19625,
                    1500,
                    19625,
                    750
                ):setColor(255, 255, 0)
                table.insert(east_gap_zones, zone)
            end
            east_gap_time = getScenarioTime() + 1
        else
            if getScenarioTime() > east_gap_time then
                if east_gap_phase ~= 6 then
                    east_gap_angle = east_gap_angle + 10
                    local zone_points = {}
                    for k = 1, 6 do
                        local zx, zy =
                            vectorFromAngle(east_gap_angle, 1500, true)
                        zone_points[k] = { x = zx + 20000, y = zy }
                        east_gap_angle = (east_gap_angle + 60) % 360
                    end
                    local zone = Zone():setPoints(
                        zone_points[1].x,
                        zone_points[1].y,
                        zone_points[2].x,
                        zone_points[2].y,
                        zone_points[3].x,
                        zone_points[3].y,
                        zone_points[4].x,
                        zone_points[4].y,
                        zone_points[5].x,
                        zone_points[5].y,
                        zone_points[6].x,
                        zone_points[6].y
                    ):setColor(
                        0,
                        0,
                        blue_value[east_gap_phase]
                    )
                    zone.hex = true
                    local destroy_me = east_gap_zones[1]
                    east_gap_zones[1] = zone
                    destroy_me:destroy()
                end
                if east_gap_phase == 1 then
                    if difficulty == 1 then
                        east_gap_zones[2]:setColor(128, 0, 128)
                        east_gap_zones[3]:setColor(128, 0, 0)
                    elseif difficulty > 1 then --R G P Y
                        east_gap_zones[2]:setColor(255, 0, 255) --Y R G P--
                        east_gap_zones[3]:setColor(128, 0, 0) --P Y R G
                        east_gap_zones[4]:setColor(0, 128, 0) --G P Y R
                        east_gap_zones[5]:setColor(128, 0, 128) --R P G Y
                    end --G Y R P
                    east_gap_phase = 2
                    east_gap_time = getScenarioTime() + 1
                elseif east_gap_phase == 2 then
                    if difficulty == 1 then
                        east_gap_zones[2]:setColor(255, 0, 255)
                        east_gap_zones[3]:setColor(128, 0, 128)
                    elseif difficulty > 1 then --R G P Y
                        east_gap_zones[2]:setColor(128, 0, 128) --Y R G P
                        east_gap_zones[3]:setColor(255, 0, 255) --P Y R G--
                        east_gap_zones[4]:setColor(128, 0, 0) --G P Y R
                        east_gap_zones[5]:setColor(0, 128, 0) --R P G Y
                    end --G Y R P
                    east_gap_phase = 3
                    east_gap_time = getScenarioTime() + 1
                elseif east_gap_phase == 3 then
                    if difficulty == 1 then
                        east_gap_zones[2]:setColor(128, 0, 0)
                        east_gap_zones[3]:setColor(255, 0, 255)
                    elseif difficulty > 1 then --R G P Y
                        east_gap_zones[2]:setColor(0, 128, 0) --Y R G P
                        east_gap_zones[3]:setColor(128, 0, 128) --P Y R G
                        east_gap_zones[4]:setColor(255, 0, 255) --G P Y R--
                        east_gap_zones[5]:setColor(128, 0, 0) --R P G Y
                    end --G Y R P
                    east_gap_phase = 4
                    east_gap_time = getScenarioTime() + 1
                elseif east_gap_phase == 4 then
                    if difficulty == 1 then
                        east_gap_zones[2]:setColor(128, 0, 128)
                        east_gap_zones[3]:setColor(128, 0, 0)
                    elseif difficulty > 1 then --R G P Y
                        east_gap_zones[2]:setColor(128, 0, 0) --Y R G P
                        east_gap_zones[3]:setColor(255, 0, 255) --P Y R G
                        east_gap_zones[4]:setColor(0, 128, 0) --G P Y R
                        east_gap_zones[5]:setColor(128, 0, 128) --R Y G P--
                    end --Y P R G
                    east_gap_phase = 5
                    east_gap_time = getScenarioTime() + 1
                elseif east_gap_phase == 5 then
                    if difficulty == 1 then
                        east_gap_zones[2]:setColor(0, 128, 0)
                        east_gap_zones[3]:setColor(128, 0, 128)
                    elseif difficulty > 1 then --R G P Y
                        east_gap_zones[2]:setColor(255, 0, 255) --Y R G P
                        east_gap_zones[3]:setColor(128, 0, 128) --P Y R G
                        east_gap_zones[4]:setColor(128, 0, 0) --G P Y R
                        east_gap_zones[5]:setColor(0, 128, 0) --R Y G P
                    end --Y P R G--
                    east_gap_phase = 6
                    east_gap_time = getScenarioTime() + 1
                elseif east_gap_phase == 6 then
                    east_gap_zones[1]:destroy()
                    if difficulty == 1 then
                        east_gap_zones[2]:destroy()
                        east_gap_zones[3]:destroy()
                    elseif difficulty > 1 then
                        east_gap_zones[2]:destroy()
                        east_gap_zones[3]:destroy()
                        east_gap_zones[4]:destroy()
                        east_gap_zones[5]:destroy()
                    end
                    east_gap_phase = nil
                    east_gap_time = nil
                    east_gap_graphic = false
                end
            end
        end
    end
    if west_gap_graphic then
        if west_gap_phase == nil then
            west_gap_phase = 1
            west_gap_angle = random(0, 10)
            west_gap_zones = {}
            local zone_points = {}
            for k = 1, 6 do
                local zx, zy = vectorFromAngle(west_gap_angle, 1500, true)
                zone_points[k] = { x = zx + -20000, y = zy }
                west_gap_angle = (west_gap_angle + 60) % 360
            end
            local zone = Zone():setPoints(
                zone_points[1].x,
                zone_points[1].y,
                zone_points[2].x,
                zone_points[2].y,
                zone_points[3].x,
                zone_points[3].y,
                zone_points[4].x,
                zone_points[4].y,
                zone_points[5].x,
                zone_points[5].y,
                zone_points[6].x,
                zone_points[6].y
            ):setColor(0, 0, blue_value[west_gap_phase])
            zone.hex = true
            table.insert(west_gap_zones, zone)
            if difficulty == 1 then
                zone = Zone():setPoints(
                    -18500,
                    -1500,
                    -18500,
                    0,
                    -21500,
                    0,
                    -21500,
                    -1500
                ):setColor(128, 0, 0)
                table.insert(west_gap_zones, zone)
                zone = Zone():setPoints(
                    -18500,
                    0,
                    -18500,
                    1500,
                    -21500,
                    1500,
                    -21500,
                    0
                ):setColor(0, 128, 0)
                table.insert(west_gap_zones, zone)
            elseif difficulty > 1 then
                zone = Zone():setPoints(
                    -19625,
                    -1500,
                    -19625,
                    -750,
                    -20375,
                    -750,
                    -20375,
                    -1500
                ):setColor(128, 0, 0)
                table.insert(west_gap_zones, zone)
                zone = Zone():setPoints(
                    -19625,
                    -750,
                    -19625,
                    0,
                    -20375,
                    0,
                    -20375,
                    -750
                ):setColor(0, 128, 0)
                table.insert(west_gap_zones, zone)
                zone = Zone():setPoints(
                    -19625,
                    0,
                    -19625,
                    750,
                    -20375,
                    750,
                    -20375,
                    0
                ):setColor(128, 0, 128)
                table.insert(west_gap_zones, zone)
                zone = Zone():setPoints(
                    -19625,
                    750,
                    -19625,
                    1500,
                    -20375,
                    1500,
                    -20375,
                    750
                ):setColor(255, 255, 0)
                table.insert(west_gap_zones, zone)
            end
            west_gap_time = getScenarioTime() + 1
        else
            if getScenarioTime() > west_gap_time then
                if west_gap_phase ~= 6 then
                    west_gap_angle = west_gap_angle + 10
                    local zone_points = {}
                    for k = 1, 6 do
                        local zx, zy =
                            vectorFromAngle(west_gap_angle, 1500, true)
                        zone_points[k] = { x = zx + -20000, y = zy }
                        west_gap_angle = (west_gap_angle + 60) % 360
                    end
                    local zone = Zone():setPoints(
                        zone_points[1].x,
                        zone_points[1].y,
                        zone_points[2].x,
                        zone_points[2].y,
                        zone_points[3].x,
                        zone_points[3].y,
                        zone_points[4].x,
                        zone_points[4].y,
                        zone_points[5].x,
                        zone_points[5].y,
                        zone_points[6].x,
                        zone_points[6].y
                    ):setColor(
                        0,
                        0,
                        blue_value[west_gap_phase]
                    )
                    zone.hex = true
                    local destroy_me = west_gap_zones[1]
                    west_gap_zones[1] = zone
                    destroy_me:destroy()
                end
                if west_gap_phase == 1 then
                    if difficulty == 1 then
                        west_gap_zones[2]:setColor(128, 0, 128)
                        west_gap_zones[3]:setColor(128, 0, 0)
                    elseif difficulty > 1 then --R G P Y
                        west_gap_zones[2]:setColor(255, 0, 255) --Y R G P--
                        west_gap_zones[3]:setColor(128, 0, 0) --P Y R G
                        west_gap_zones[4]:setColor(0, 128, 0) --G P Y R
                        west_gap_zones[5]:setColor(128, 0, 128) --R P G Y
                    end --G Y R P
                    west_gap_phase = 2
                    west_gap_time = getScenarioTime() + 1
                elseif west_gap_phase == 2 then
                    if difficulty == 1 then
                        west_gap_zones[2]:setColor(255, 0, 255)
                        west_gap_zones[3]:setColor(128, 0, 128)
                    elseif difficulty > 1 then --R G P Y
                        west_gap_zones[2]:setColor(128, 0, 128) --Y R G P
                        west_gap_zones[3]:setColor(255, 0, 255) --P Y R G--
                        west_gap_zones[4]:setColor(128, 0, 0) --G P Y R
                        west_gap_zones[5]:setColor(0, 128, 0) --R P G Y
                    end --G Y R P
                    west_gap_phase = 3
                    west_gap_time = getScenarioTime() + 1
                elseif west_gap_phase == 3 then
                    if difficulty == 1 then
                        west_gap_zones[2]:setColor(128, 0, 0)
                        west_gap_zones[3]:setColor(255, 0, 255)
                    elseif difficulty > 1 then --R G P Y
                        west_gap_zones[2]:setColor(0, 128, 0) --Y R G P
                        west_gap_zones[3]:setColor(128, 0, 128) --P Y R G
                        west_gap_zones[4]:setColor(255, 0, 255) --G P Y R--
                        west_gap_zones[5]:setColor(128, 0, 0) --R P G Y
                    end --G Y R P
                    west_gap_phase = 4
                    west_gap_time = getScenarioTime() + 1
                elseif west_gap_phase == 4 then
                    if difficulty == 1 then
                        west_gap_zones[2]:setColor(128, 0, 128)
                        west_gap_zones[3]:setColor(128, 0, 0)
                    elseif difficulty > 1 then --R G P Y
                        west_gap_zones[2]:setColor(128, 0, 0) --Y R G P
                        west_gap_zones[3]:setColor(255, 0, 255) --P Y R G
                        west_gap_zones[4]:setColor(0, 128, 0) --G P Y R
                        west_gap_zones[5]:setColor(128, 0, 128) --R Y G P--
                    end --Y P R G
                    west_gap_phase = 5
                    west_gap_time = getScenarioTime() + 1
                elseif west_gap_phase == 5 then
                    if difficulty == 1 then
                        west_gap_zones[2]:setColor(0, 128, 0)
                        west_gap_zones[3]:setColor(128, 0, 128)
                    elseif difficulty > 1 then --R G P Y
                        west_gap_zones[2]:setColor(255, 0, 255) --Y R G P
                        west_gap_zones[3]:setColor(128, 0, 128) --P Y R G
                        west_gap_zones[4]:setColor(128, 0, 0) --G P Y R
                        west_gap_zones[5]:setColor(0, 128, 0) --R Y G P
                    end --Y P R G--
                    west_gap_phase = 6
                    west_gap_time = getScenarioTime() + 1
                elseif west_gap_phase == 6 then
                    west_gap_zones[1]:destroy()
                    if difficulty == 1 then
                        west_gap_zones[2]:destroy()
                        west_gap_zones[3]:destroy()
                    elseif difficulty > 1 then
                        west_gap_zones[2]:destroy()
                        west_gap_zones[3]:destroy()
                        west_gap_zones[4]:destroy()
                        west_gap_zones[5]:destroy()
                    end
                    west_gap_phase = nil
                    west_gap_time = nil
                    west_gap_graphic = false
                end
            end
        end
    end
end
--  Quixotic addition
function destroyEnemyBases(delta)
    if homeStation:isValid() then
        validEnemies = 0
        for i = 1, #enemyStationList do
            if enemyStationList[i]:isValid() then
                validEnemies = validEnemies + 1
            end
        end
        if validEnemies == 0 then
            victory("Human Navy")
        end
    else
        victory("Kraylor")
    end
end
-- keep the pressure up on the players
function waves(delta)
    waveTimer = waveTimer - delta
    if waveTimer < 0 then
        waveTimer = delta + interWave + random(1, 60)
        spawnCompass = math.random(1, 4)
        if spawnCompass == 1 then
            hf = spawnEnemies(0, -40000, difficulty, "Kraylor")
            if northMet then
                for _, enemy in ipairs(hf) do
                    enemy:orderFlyTowardsBlind(0, 0)
                end
                waveTimer = waveTimer - random(1, 60)
            else
                for _, enemy in ipairs(hf) do
                    enemy:orderFlyTowards(0, 0)
                end
            end
        elseif spawnCompass == 2 then
            hf = spawnEnemies(0, 40000, difficulty, "Ghosts")
            if southMet then
                for _, enemy in ipairs(hf) do
                    enemy:orderFlyTowardsBlind(0, 0)
                end
                waveTimer = waveTimer - random(1, 60)
            else
                for _, enemy in ipairs(hf) do
                    enemy:orderFlyTowards(0, 0)
                end
            end
        elseif spawnCompass == 3 then
            hf = spawnEnemies(40000, 0, difficulty, "Exuari")
            if eastMet then
                for _, enemy in ipairs(hf) do
                    enemy:orderFlyTowardsBlind(0, 0)
                end
                waveTimer = waveTimer - random(1, 60)
            else
                for _, enemy in ipairs(hf) do
                    enemy:orderFlyTowards(0, 0)
                end
            end
        else
            hf = spawnEnemies(-40000, 0, difficulty, "Ktlitans")
            if westMet then
                for _, enemy in ipairs(hf) do
                    enemy:orderFlyTowardsBlind(0, 0)
                end
                waveTimer = waveTimer - random(1, 60)
            else
                for _, enemy in ipairs(hf) do
                    enemy:orderFlyTowards(0, 0)
                end
            end
        end
        if homeStation:areEnemiesInRange(2000) then
            wakeEnemyFleet = homeStation:getObjectsInRange(2000)
            for _, enemy in ipairs(wakeEnemyFleet) do
                if enemy:isEnemy(homeStation) then
                    enemy:orderRoaming()
                end
            end
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
    if enemy_power == nil then
        enemy_power = 1
    end
    enemyStrength = math.max(danger * enemy_power * playerPower(), 5)
    enemyPosition = 0
    sp = irandom(300, 500) --random spacing of spawned group
    deployConfig = random(1, 100) --randomly choose between squarish formation and hexagonish formation
    enemyList = {}
    -- Reminder: stsl and stnl are ship template score and name list
    while enemyStrength > 0 do
        shipTemplateType = irandom(1, #stsl)
        while stsl[shipTemplateType] > enemyStrength * 1.1 + 5 do
            shipTemplateType = irandom(1, #stsl)
        end
        ship = CpuShip()
            :setFaction(enemyFaction)
            :setTemplate(stnl[shipTemplateType])
            :orderRoaming()
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
        table.insert(enemyList, ship)
        enemyStrength = enemyStrength - stsl[shipTemplateType]
    end
    return enemyList
end
--evaluate the players for enemy strength and size spawning purposes
function update(delta)
    if delta == 0 then
        --game paused
        setPlayers()
        return
    end
    gapGraphic()
    healthCheck(delta)
    transportPlot(delta)
    if playWithTimeLimit then
        gameTimeLimit = gameTimeLimit - delta
        if gameTimeLimit < 0 then
            victory("Kraylor")
        end
    end
    if plot1 ~= nil then --main plot
        plot1(delta)
    end
    if plot2 ~= nil then --waves
        plot2(delta)
    end
end
