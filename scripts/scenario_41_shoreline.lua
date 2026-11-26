-- Name: Shoreline
-- Description: Waves of increasingly difficult enemies. Warp capable ship is strongly suggested. At least one required mission and several optional missions. Missions selected at random unless game master intervenes
---
--- Maximum of 8 player ships supported by scenario. More player ships may experience strange results
---
--- Version 2
-- Type: Replayable
-- Setting[Enemies]: Configures strength and/or number of enemies in this scenario
-- Enemies[Easy]: Fewer or weaker enemies
-- Enemies[Normal|Default]: Normal number or strength of enemies
-- Enemies[Hard]: More or stronger enemies
-- Enemies[Extreme]: Much stronger, many more enemies
-- Enemies[Quixotic]: Insanely strong and/or inordinately large numbers of enemies
-- Setting[Murphy]: Configures the perversity of the universe according to Murphy's law
-- Murphy[Very Easy]: Random factors are way more in your favor
-- Murphy[Easy]: Random factors are more in your favor
-- Murphy[Normal|Default]: Random factors are normal
-- Murphy[Hard]: Random factors are more against you
-- Murphy[Extreme]: Random factors are way more against you
-- Setting[Timed]: Sets whether or not the scenario has a time limit. Default is no time limit
-- Timed[None|Default]: No time limit
-- Timed[45]: Scenario ends in 45 minutes

-- improvements:
-- - Add stations of other factions.
-- - Have transports of various factions
-- - Have other enemies cruising the area
-- - Add defensive fleets around some stations

require("utils.lua")
require("place_station_scenario_utility.lua")
local PlayerState = require("player_state_scenario_utility.lua")
require("generate_call_sign_scenario_utility.lua")
local Environment = require("environment_scenario_utility.lua")
local placeRandomAsteroidsAroundPoint = Environment.asteroidsAroundPointDense
local createRandomAlongArc = Environment.createRandomAlongArc
local ShorelineStations = require("shoreline_station_placement.lua")
local stationPlacement = ShorelineStations.new({
    asteroids_around_point = placeRandomAsteroidsAroundPoint,
    asteroid_arc = function(...)
        return createRandomAsteroidAlongArc(...)
    end,
    create_random_along_arc = createRandomAlongArc,
})
local defaults = require("defaults_scenario_utility.lua")
local ShipNames = require("player_ship_names_scenario_utility.lua")
local Inventory = require("inventory_scenario_utility.lua")
local Fleet = require("spawn_ships_scenario_utility.lua")
local Heading = require("heading_scenario_utility.lua")
local StationCore = require("comms_station_core.lua")
local StationMenu = require("comms_station_menu.lua")
local vectorFromAngleNorth = Heading.north(vectorFromAngle)

local playerPower = Fleet.playerPowerGetter({
    player = function(index) return getPlayerShip(index) end,
    limit = 8,
})

local function cargoInventoryGivenShip(p)
    Inventory.render(p, { filter_zero = true, empty_newline = true })
end


function createRandomAsteroidAlongArc(
    amount,
    x,
    y,
    distance,
    startArc,
    endArcClockwise,
    randomize
)
    -- Create amount of asteroids along arc
    -- Center defined by x and y
    -- Radius defined by distance
    -- Start of arc between 0 and 360 (startArc), end arc: endArcClockwise
    -- Use randomize to vary the distance from the center point. Omit to keep distance constant
    -- Example:
    --   createRandomAsteroidAlongArc(100, 500, 3000, 65, 120, 450)
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
    local asteroid_size = random(1, 100)
        + random(1, 75)
        + random(1, 75)
        + random(1, 20)
        + random(1, 20)
        + random(1, 20)
        + random(1, 20)
        + random(1, 20)
        + random(1, 20)
        + random(1, 20)
    if amount > arcLen then
        for ndex = 1, arcLen do
            local radialPoint = startArc + ndex
            local pointDist = distance + random(-randomize, randomize)
            asteroid_size = random(1, 100)
                + random(1, 75)
                + random(1, 75)
                + random(1, 20)
                + random(1, 20)
                + random(1, 20)
                + random(1, 20)
                + random(1, 20)
                + random(1, 20)
                + random(1, 20)
            local ax = x + math.cos(radialPoint / 180 * math.pi) * pointDist
            local ay = y + math.sin(radialPoint / 180 * math.pi) * pointDist
            if farEnough(ax, ay, asteroid_size) then
                local ta = Asteroid():setPosition(ax, ay):setSize(asteroid_size)
                table.insert(
                    place_space,
                    { obj = ta, dist = asteroid_size, shape = "circle" }
                )
            end
        end
        for ndex = 1, amount - arcLen do
            radialPoint = random(startArc, endArcClockwise)
            pointDist = distance + random(-randomize, randomize)
            asteroid_size = random(1, 100)
                + random(1, 75)
                + random(1, 75)
                + random(1, 20)
                + random(1, 20)
                + random(1, 20)
                + random(1, 20)
                + random(1, 20)
                + random(1, 20)
                + random(1, 20)
            local ax = x + math.cos(radialPoint / 180 * math.pi) * pointDist
            local ay = y + math.sin(radialPoint / 180 * math.pi) * pointDist
            if farEnough(ax, ay, asteroid_size) then
                local ta = Asteroid():setPosition(ax, ay):setSize(asteroid_size)
                table.insert(
                    place_space,
                    { obj = ta, dist = asteroid_size, shape = "circle" }
                )
            end
        end
    else
        for ndex = 1, amount do
            radialPoint = random(startArc, endArcClockwise)
            pointDist = distance + random(-randomize, randomize)
            asteroid_size = random(1, 100)
                + random(1, 75)
                + random(1, 75)
                + random(1, 20)
                + random(1, 20)
                + random(1, 20)
                + random(1, 20)
                + random(1, 20)
                + random(1, 20)
                + random(1, 20)
            local ax = x + math.cos(radialPoint / 180 * math.pi) * pointDist
            local ay = y + math.sin(radialPoint / 180 * math.pi) * pointDist
            if farEnough(ax, ay, asteroid_size) then
                local ta = Asteroid():setPosition(ax, ay):setSize(asteroid_size)
                table.insert(
                    place_space,
                    { obj = ta, dist = asteroid_size, shape = "circle" }
                )
            end
        end
    end
end
-----------------------------
--  Dynamic map functions  --
-----------------------------
function moveBlackHole(delta)
    local mbhx, mbhy = grawp:getPosition()
    if mbhx < 67000 or mbhx > 90000 or mbhy < -21000 or mbhy > 40000 then
        if mbhx < 67000 then
            grawp.angle = random(0, 180) + 270
        end
        if mbhx > 90000 then
            grawp.angle = random(90, 270)
        end
        if mbhy < -21000 then
            grawp.angle = random(0, 180)
        end
        if mbhy > 40000 then
            grawp.angle = random(180, 360)
        end
        if grawp.angle == nil then
            print("grawp.angle is nil (1)")
        end
        local deltaBlackx, deltaBlacky =
            vectorFromAngle(grawp.angle, grawp.travel + 20)
        grawp:setPosition(mbhx + deltaBlackx, mbhy + deltaBlacky)
        grawp.travel = random(1, 5 + difficulty)
    else
        if grawp.angle == nil then
            print("grawp.angle is nil (2)")
        end
        deltaBlackx, deltaBlacky = vectorFromAngle(grawp.angle, grawp.travel)
        grawp:setPosition(mbhx + deltaBlackx, mbhy + deltaBlacky)
    end
end
function moveAsteroids(delta)
    local movingAsteroidCount = 0
    for aidx, aObj in ipairs(movingAsteroidList) do
        if aObj:isValid() then
            movingAsteroidCount = movingAsteroidCount + 1
            local mAstx, mAsty = aObj:getPosition()
            if
                mAstx < -150000
                or mAstx > 150000
                or mAsty < -150000
                or mAsty > 150000
            then
                aObj.angle = random(0, 360)
                local curve = 0
                if random(1, 100) < 50 then
                    curve = math.random() * 0.08
                end
                if aObj.angle < 90 then
                    aObj:setPosition(
                        random(-150000, -100000),
                        random(-150000, -100000)
                    )
                    if aObj.angle < 45 then
                        aObj.curve = curve
                    else
                        aObj.curve = -curve
                    end
                elseif aObj.angle < 180 then
                    aObj:setPosition(
                        random(100000, 150000),
                        random(-150000, -100000)
                    )
                    if aObj.angle < 135 then
                        aObj.curve = curve
                    else
                        aObj.curve = -curve
                    end
                elseif aObj.angle < 270 then
                    aObj:setPosition(
                        random(100000, 150000),
                        random(100000, 150000)
                    )
                    if aObj.angle < 225 then
                        aObj.curve = curve
                    else
                        aObj.curve = -curve
                    end
                else
                    aObj:setPosition(
                        random(-150000, -100000),
                        random(100000, 150000)
                    )
                    if aObj.angle < 315 then
                        aObj.curve = curve
                    else
                        aObj.curve = -curve
                    end
                end
            else
                if aObj.angle == nil then
                    print("aObj.angle is nil")
                end
                local deltaAstx, deltaAsty =
                    vectorFromAngle(aObj.angle, aObj.travel)
                aObj:setPosition(mAstx + deltaAstx, mAsty + deltaAsty)
                aObj.angle = aObj.angle + aObj.curve
            end
        end
    end
    if movingAsteroidCount < 1 then
        setMovingAsteroids()
    end
end
----------------------
--  Initialization  --
----------------------
function init()
    scenario_version = "2.0.4"
    print(
        string.format(
            "     -----     Scenario: Shoreline     -----     Version %s     -----",
            scenario_version
        )
    )
    if _VERSION ~= nil then
        print("Lua version:", _VERSION)
    end
    diagnostic = false
    game_end_statistics_diagnostic = false
    update_loop_diagnostic = false
    optional_mission_loop_diagnostic = false
    distanceDiagnostic = false
    patrol_plot_diagnostic = false
    setVariations()
    setConstants()
    setPlayers()
    setMovingAsteroids()
    stationPlacement.setStations()
    plotT = transportPlot
    plotB = moveBlackHole
    plotW = monitorWaves
    plotH = helpWarn
    plotCI = cargoInventory --manage button on relay/operations to show cargo inventory
    plotCN = coolantNebulae
    mainGMButtons()
end
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
    addGMFunction(_("buttonGM", "+Required Missions"), requiredMissions)
    addGMFunction(_("buttonGM", "+Optional Missions"), optionalMissions)
end
function requiredMissions()
    clearGMFunctions()
    addGMFunction(_("buttonGM", "-From Required Miss"), mainGMButtons)
    --Allow choice of required mission on GM screen rather than being selected at random
    if undercutMission ~= "done" then
        addGMFunction(_("buttonGM", "Req Undercut"), undercutGM)
    end
    if stettorMission ~= "done" then
        addGMFunction(_("buttonGM", "Req Stettor"), stettorGM)
    end
    if horizonMission ~= "done" then
        addGMFunction(_("buttonGM", "Req Horizon"), horizonGM)
    end
    if sporiskyMission ~= "done" then
        addGMFunction(_("buttonGM", "Req Sporisky"), sporiskyGM)
    end
end
function optionalMissions()
    clearGMFunctions()
    addGMFunction(_("buttonGM", "-From Optional Miss"), mainGMButtons)
    --Allow choice of optional mission on GM screen rather than being selected at random
    if beamRangePlot ~= "done" then
        addGMFunction(_("buttonGM", "Opt Beam Range"), beamRangeGM)
    end
    if impulseSpeedPlot ~= "done" then
        addGMFunction(_("buttonGM", "Opt Impulse"), impulseGM)
    end
    if spinPlot ~= "done" then
        addGMFunction(_("buttonGM", "Opt Spin"), spinGM)
    end
    if quantumArtPlot ~= "done" then
        addGMFunction(_("buttonGM", "Opt Shield"), shieldGM)
    end
    if beamDamagePlot ~= "done" then
        addGMFunction(_("buttonGM", "Opt Beam Damage"), beamDamageGM)
    end
end
function setVariations()
    local timed_config = {
        ["None"] = {
            limit = 0,
            limited = false,
            wave = 30,
            rmd = 20,
            cmd = 1800,
        },
        ["45"] = {
            limit = 45,
            limited = true,
            wave = 15,
            rmd = nil,
            cmd = nil,
        },
    }
    playWithTimeLimit = timed_config[getScenarioSetting("Timed")].limited
    defaultGameTimeLimitInMinutes =
        timed_config[getScenarioSetting("Timed")].limit
    gameTimeLimit = defaultGameTimeLimitInMinutes * 60
    waveDelayCountCheck = timed_config[getScenarioSetting("Timed")].wave
    requiredMissionDelay = timed_config[getScenarioSetting("Timed")].rmd
    clueMessageDelay = timed_config[getScenarioSetting("Timed")].cmd
    local enemy_config = {
        ["Easy"] = { number = 0.5 },
        ["Normal"] = { number = 1 },
        ["Hard"] = { number = 2 },
        ["Extreme"] = { number = 3 },
        ["Quixotic"] = { number = 5 },
    }
    enemy_power = enemy_config[getScenarioSetting("Enemies")].number
    local murphy_config = {
        ["Very Easy"] = {
            number = 0.25,
            lose_cool = 0.999995,
            gain_cool = 0.015,
            wave = 9,
            prog = 0.15,
        },
        ["Easy"] = {
            number = 0.5,
            lose_cool = 0.99999,
            gain_cool = 0.01,
            wave = 6,
            prog = 0.2,
        },
        ["Normal"] = {
            number = 1,
            lose_cool = 0.99995,
            gain_cool = 0.001,
            wave = 0,
            prog = 0.25,
        },
        ["Hard"] = {
            number = 2,
            lose_cool = 0.9999,
            gain_cool = 0.0001,
            wave = -6,
            prog = 0.5,
        },
        ["Extreme"] = {
            number = 3,
            lose_cool = 0.999,
            gain_cool = 0.00001,
            wave = -9,
            prog = 0.75,
        },
    }
    difficulty = murphy_config[getScenarioSetting("Murphy")].number
    coolant_loss = murphy_config[getScenarioSetting("Murphy")].lose_cool
    coolant_gain = murphy_config[getScenarioSetting("Murphy")].gain_cool
    waveDelayCountCheck = waveDelayCountCheck
        + murphy_config[getScenarioSetting("Murphy")].wave
    waveProgressInterval = murphy_config[getScenarioSetting("Murphy")].prog
end
function setConstants()
    mission_transport_list = {}
    transport_list = {}
    transport_spawn_delay = 30
    transportSpawnDelay = 30
    -- 27 types of goods so far
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
        { "battery", 0 },
    }
    goods = {}
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
    prefix_length = 0
    suffix_index = 0
    persistentEnemies = {}
    waveDelayCount = 0
    waveInProgress = false
    waveProgressInterval = 0.25
    waveProgress = 0
    helpWarnDelay = 30
    vaiken_damage_timer_interval = 120
    vaiken_damage_timer = vaiken_damage_timer_interval
    primaryOrders = _(
        "orders-comms",
        "Defend bases in the area (human navy and independent) from enemy attack."
    )
    secondaryOrders = ""
    optionalOrders = ""
    undercutLocation = "station"
    requiredMissionCount = 0
    optionalMissionDelay = 60
    f_n = { "friend", "neutral" } --friend or neutral
    missile_types = { "Homing", "Nuke", "Mine", "EMP", "HVLI" }
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
    --stnl: Ship Template Name List, stsl: Ship Template Score List, stbl: Ship Template Boolean List, nsfl: Non Standard Function List
    stnl = {
        "Phobos R2",
        "Adder MK8",
        "Adder MK7",
        "Adder MK3",
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
        ST.STINGRAY,
        ST.VINDICATOR,
        ST.AVALANCHE,
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
    stsl = {
        13,
        10,
        9,
        5,
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
    stbl = {
        false,
        false,
        false,
        false,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
    }
    nsfl = {}
    table.insert(nsfl, phobosR2)
    table.insert(nsfl, adderMk8)
    table.insert(nsfl, adderMk7)
    table.insert(nsfl, adderMk3)
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
    playerShipNamesForAtlantisII = ShipNames.pool("Atlantis II")
    playerShipNamesForProtoAtlantis = ShipNames.pool("Proto-Atlantis")
    playerShipNamesForSurkov = ShipNames.pool("Surkov")
    playerShipNamesForRedhook = ShipNames.pool("Redhook")
    playerShipNamesForLeftovers = { "Foregone", "Righteous", "Masher" }
    playerShipNamesFor = {}
    playerShipNamesFor[ST.CRUCIBLE] = ShipNames.pool("Crucible")
    playerShipNamesFor[ST.MAVERICK] = ShipNames.pool("Maverick")
    commonGoods = defaults.goods().commonGoods
    componentGoods = defaults.goods().componentGoods
    mineralGoods = defaults.goods().mineralGoods
    cargoInventoryList = {}
    table.insert(cargoInventoryList, cargoInventory1)
    table.insert(cargoInventoryList, cargoInventory2)
    table.insert(cargoInventoryList, cargoInventory3)
    table.insert(cargoInventoryList, cargoInventory4)
    table.insert(cargoInventoryList, cargoInventory5)
    table.insert(cargoInventoryList, cargoInventory6)
    table.insert(cargoInventoryList, cargoInventory7)
    table.insert(cargoInventoryList, cargoInventory8)
    get_coolant_function = {}
    table.insert(get_coolant_function, getCoolant1)
    table.insert(get_coolant_function, getCoolant2)
    table.insert(get_coolant_function, getCoolant3)
    table.insert(get_coolant_function, getCoolant4)
    table.insert(get_coolant_function, getCoolant5)
    table.insert(get_coolant_function, getCoolant6)
    table.insert(get_coolant_function, getCoolant7)
    table.insert(get_coolant_function, getCoolant8)
end
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
        [ST.CRUCIBLE] = playerShipNamesFor[ST.CRUCIBLE],
        [ST.MAVERICK] = playerShipNamesFor[ST.MAVERICK],
        Kiriya = playerShipNamesForKiriya,
        Striker = playerShipNamesForStriker,
        Lindworm = playerShipNamesForLindworm,
        Repulse = playerShipNamesForRepulse,
        Ender = playerShipNamesForEnder,
        Nautilus = playerShipNamesForNautilus,
        Hathcock = playerShipNamesForHathcock,
        AtlantisII = playerShipNamesForAtlantisII,
        ProtoAtlantis = playerShipNamesForProtoAtlantis,
        Surkov = playerShipNamesForSurkov,
        Redhook = playerShipNamesForRedhook,
        Leftovers = playerShipNamesForLeftovers,
    }
end

local player_profiles = {
    ["MP52 Hornet"] = { names = "MP52Hornet", score = 7, cargo = 3, warp = true },
    ["Piranha"] = { names = "Piranha", score = 16, cargo = 8 },
    ["Flavia P.Falcon"] = { names = "FlaviaPFalcon", score = 15, cargo = 15 },
    ["Phobos M3P"] = { names = "PhobosM3P", score = 19, cargo = 10, warp = true, warp_speed = 650 },
    ["Atlantis"] = { names = "Atlantis", score = 52, cargo = 6 },
    [ST.VINDICATOR] = { names = "Cruiser", score = 40, cargo = 6 },
    [ST.AVALANCHE] = { names = "MissileCruiser", score = 45, cargo = 8 },
    [ST.STINGRAY] = { names = "Fighter", score = 7, cargo = 3, warp = true },
    ["Benedict"] = { names = "Benedict", score = 10, cargo = 9 },
    [ST.CRUCIBLE] = { names = ST.CRUCIBLE, score = 45, cargo = 5 },
    [ST.MAVERICK] = { names = ST.MAVERICK, score = 45, cargo = 5 },
    ["Kiriya"] = { names = "Kiriya", score = 10, cargo = 9 },
    ["Crow"] = { names = "Striker", score = 8, cargo = 4, warp = true, customize = PlayerState.customizeCrow },
    ["ZX-Lindworm"] = { names = "Lindworm", score = 8, cargo = 3, coolant_field = "autoCoolant", auto_coolant = false, warp = true },
    ["Repulse"] = { names = "Repulse", score = 14, cargo = 12 },
    ["Ender"] = { names = "Ender", score = 100, cargo = 20 },
    ["Nautilus"] = { names = "Nautilus", score = 12, cargo = 7 },
    ["Hathcock"] = { names = "Hathcock", score = 30, cargo = 6 },
    ["Atlantis II"] = { names = "AtlantisII", score = 60, cargo = 5 },
    ["Proto-Atlantis"] = { names = "ProtoAtlantis", score = 40, cargo = 4 },
    ["Surkov"] = { names = "Surkov", score = 35, cargo = 6 },
    ["Redhook"] = { names = "Redhook", score = 18, cargo = 8 },
}

function setPlayers()
    --set player ship name, reputation, relative numeric ship score, cargo capacity, FTL drive, initial systems health and coolant
    for p1idx = 1, 8 do
        pobj = getPlayerShip(p1idx)
        if pobj ~= nil and pobj:isValid() then
            if goods[pobj] == nil then
                goods[pobj] = goodsList
            end
            if pobj.goods == nil then
                pobj.goods = {}
            end
            if pobj.initialRep == nil then
                pobj:addReputationPoints(100 - (difficulty * 6))
                pobj.initialRep = true
            end
            if not pobj.nameAssigned then
                pobj.nameAssigned = true
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
                    })
                end
            end
            pobj.initialCoolant = pobj:getMaxCoolant()
        end
    end
end
--required mission selection GM functions
function undercutGM()
    if undercutMission ~= "done" and undercutLocation ~= "free" then
        plotR = undercutOrderMessage
        chooseUndercutBase()
    end
    removeGMFunction("Req Undercut")
end
function stettorGM()
    if stettorMission ~= "done" then
        chooseSensorBase()
        chooseSensorParts()
        plotR = stettorOrderMessage
    end
    removeGMFunction("Req Stettor")
end
function horizonGM()
    if horizonMission ~= "done" then
        chooseHorizonParts()
        plotR = horizonOrderMessage
    end
    removeGMFunction("Req Horizon")
end
function sporiskyGM()
    if sporiskyMission ~= "done" then
        chooseTraitorBase()
        plotR = traitorOrderMessage
    end
    removeGMFunction("Req Sporisky")
end
--optional mission selection GM functions
function beamRangeGM()
    if beamRangePlot ~= "done" then
        chooseBeamRangeParts()
        plotO = beamRangeMessage
    end
    removeGMFunction("Opt Beam Range")
end
function impulseGM()
    if impulseSpeedPlot ~= "done" then
        impulseSpeedParts()
        plotO = impulseSpeedMessage
    end
    removeGMFunction("Opt Impulse")
end
function spinGM()
    if spinPlot ~= "done" then
        chooseSpinBaseParts()
        plotO = spinMessage
    end
    removeGMFunction("Opt Spin")
end
function shieldGM()
    if quantumArtPlot ~= "done" then
        plotO = quantumArtMessage
    end
    removeGMFunction("Opt Shield")
end
function beamDamageGM()
    if beamDamagePlot ~= "done" then
        chooseBeamDamageParts()
        plotO = beamDamageMessage
    end
    removeGMFunction("Opt Beam Damage")
end
--additional ad hoc ship definitions
function phobosR2(enemyFaction)
    local ship = CpuShip():setFaction(enemyFaction):setTemplate(ST.PHOBOS_T3)
    local p = getPlayerShip(-1)
    if p ~= nil and p:isValid() and p:isFriendly(ship) then
        local temp_faction = ship:getFaction()
        ship:setFaction("Independent")
        ship:orderRoaming()
        ship:setFaction(temp_faction)
    else
        ship:orderRoaming()
    end
    ship:setTypeName("Phobos R2")
    ship:setWeaponTubeCount(1) --one tube (vs 2)
    ship:setWeaponTubeDirection(0, 0)
    ship:setImpulseMaxSpeed(55) --slower impulse (vs 60)
    ship:setRotationMaxSpeed(15) --faster maneuver (vs 10)
    return ship
end
function adderMk8(enemyFaction)
    local ship = CpuShip():setFaction(enemyFaction):setTemplate(ST.ADDER_MK5)
    local p = getPlayerShip(-1)
    if p ~= nil and p:isValid() and p:isFriendly(ship) then
        local temp_faction = ship:getFaction()
        ship:setFaction("Independent")
        ship:orderRoaming()
        ship:setFaction(temp_faction)
    else
        ship:orderRoaming()
    end
    ship:setTypeName("Adder MK8")
    ship:setShieldsMax(50) --stronger shields (vs 30)
    ship:setShields(50)
    ship:setBeamWeapon(0, 30, 0, 900, 5.0, 2.3) --narrower (30 vs 35) but longer (900 vs 800) and stronger (2.3 vs 2.0) beam
    ship:setRotationMaxSpeed(30) --faster maneuver (vs 25)
    return ship
end
function adderMk7(enemyFaction)
    local ship = CpuShip():setFaction(enemyFaction):setTemplate(ST.ADDER_MK6)
    local p = getPlayerShip(-1)
    if p ~= nil and p:isValid() and p:isFriendly(ship) then
        local temp_faction = ship:getFaction()
        ship:setFaction("Independent")
        ship:orderRoaming()
        ship:setFaction(temp_faction)
    else
        ship:orderRoaming()
    end
    ship:setTypeName("Adder MK7")
    ship:setShieldsMax(40) --stronger shields (vs 30)
    ship:setShields(40)
    ship:setBeamWeapon(0, 30, 0, 900, 5.0, 2.0) --narrower (30 vs 35) but longer (900 vs 800) beam
    return ship
end
function adderMk3(enemyFaction)
    local ship = CpuShip():setFaction(enemyFaction):setTemplate(ST.ADDER_MK4)
    local p = getPlayerShip(-1)
    if p ~= nil and p:isValid() and p:isFriendly(ship) then
        local temp_faction = ship:getFaction()
        ship:setFaction("Independent")
        ship:orderRoaming()
        ship:setFaction(temp_faction)
    else
        ship:orderRoaming()
    end
    ship:setTypeName("Adder MK3")
    ship:setHullMax(35) --weaker hull (vs 40)
    ship:setHull(35)
    ship:setShieldsMax(15) --weaker shield (vs 20)
    ship:setShields(15)
    ship:setRotationMaxSpeed(35) --faster maneuver (vs 20)
    return ship
end
--station related functions
function setMovingAsteroids()
    movingAsteroidList = {}
    for aidx = 1, 30 do
        local xAst = random(-100000, 100000)
        local yAst = random(-100000, 100000)
        local outRange = true
        for p2idx = 1, 8 do
            local p2obj = getPlayerShip(p2idx)
            if p2obj ~= nil and p2obj:isValid() then
                if p2obj == nil then
                    print("p2obj is nil")
                end
                if xAst == nil then
                    print("xAst is nil")
                end
                local x1, y1 = p2obj:getPosition()
                if distanceDiagnostic then
                    print(
                        "Distance diagnostic 1: x1:",
                        x1,
                        "y1:",
                        y1,
                        "xAst:",
                        xAst,
                        "yAst:",
                        yAst
                    )
                end
                if distance(x1, y1, xAst, yAst) < 30000 then
                    outRange = false
                end
            end
        end
        if outRange then
            local mAst = Asteroid():setPosition(xAst, yAst)
            mAst.angle = random(0, 360)
            mAst.travel = random(40, 220)
            if random(1, 100) < 50 then
                mAst.curve = 0
            else
                mAst.curve = math.random() * 0.16 - 0.08
            end
            table.insert(movingAsteroidList, mAst)
        end
    end
    plotA = moveAsteroids
end
--patrol functions
function addPatrol(delta)
    if patrol_plot_diagnostic then
        print("Patrol plot diagnostic, add patrol. patrol delay", patrol_delay)
    end
    local selected_faction = nil
    local selected_station = nil
    for si, station in ipairs(defensive_station_list) do
        if station:isValid() then
            selected_faction = station:getFaction()
            selected_station = station
            if patrol_group[selected_faction] == nil then
                patrol_group[selected_faction] = {}
            end
            if #patrol_group[selected_faction] < 1 then
                if patrol_depleted[selected_faction] == nil then
                    break
                end
            end
        else
            defensive_station_list[si] =
                defensive_station_list[#defensive_station_list]
            defensive_station_list[#defensive_station_list] = nil
            return
        end
    end
    if patrol_plot_diagnostic then
        print("Patrol group:")
        for faction, group in pairs(patrol_group) do
            print("    Faction:", faction, "Group size:", #group)
        end
        print(
            "Patrol plot diagnostic, add patrol. selected faction:",
            selected_faction,
            "patrol group size:",
            #patrol_group[selected_faction]
        )
    end
    if selected_faction == nil or #patrol_group[selected_faction] > 0 then
        resetPatrolDelay()
        patrolPlot = checkPatrol
        return
    end
    local station_finish, station_start = pickPatrolPoint(selected_faction)
    if patrol_plot_diagnostic then
        if station_finish == nil then
            print("Patrol plot diagnostic, add patrol. station finish: nil")
        else
            print(
                "Patrol plot diagnostic, add patrol. station finish:",
                station_finish:getCallSign(),
                "station start:",
                station_start:getCallSign()
            )
        end
    end
    if station_finish == nil then
        resetPatrolDelay()
        patrolPlot = checkPatrol
        return
    end
    local ss_x, ss_y = station_start:getPosition()
    local sf_x, sf_y = station_finish:getPosition()
    local patrol_angle = angleFromVectorNorth(sf_x, sf_y, ss_x, ss_y)
    local ps_x, ps_y = vectorFromAngleNorth(patrol_angle, 1000)
    ps_x = ps_x + ss_x
    ps_y = ps_y + ss_y
    local patrol_fleet = spawnEnemies(ps_x, ps_y, 1, selected_faction)
    local slowest_speed = 999
    local slowest_ship = nil
    local slowest_index = 0
    for index, ship in ipairs(patrol_fleet) do
        if ship:getImpulseMaxSpeed() < slowest_speed then
            if not ship:hasJumpDrive() and not ship:hasWarpDrive() then
                slowest_speed = ship:getImpulseMaxSpeed()
                slowest_ship = ship
                slowest_index = index
            end
        end
    end
    if slowest_ship == nil then
        print(
            "Slowest ship not identified. All in patrol fleet have warp or jump"
        )
        slowest_index = 1
        slowest_ship = patrol_fleet[1]
    end
    if #patrol_fleet < 3 then
        table.insert(
            patrol_fleet,
            CpuShip()
                :setTemplate(ST.MU52_HORNET)
                :setFaction(selected_faction)
                :setPosition(ps_x, ps_y)
                :setCommsScript("")
                :setCommsFunction(altShipComms)
        )
        if #patrol_fleet < 3 then
            table.insert(
                patrol_fleet,
                CpuShip()
                    :setTemplate(ST.MU52_HORNET)
                    :setFaction(selected_faction)
                    :setPosition(ps_x, ps_y)
                    :setCommsScript("")
                    :setCommsFunction(altShipComms)
            )
        end
    end
    local patrol_leader = slowest_ship
    patrol_leader:setPosition(ps_x, ps_y):setHeading(patrol_angle)
    local p = getPlayerShip(-1)
    if p ~= nil and p:isValid() and p:isFriendly(patrol_leader) then
        local temp_faction = patrol_leader:getFaction()
        patrol_leader:setFaction("Independent")
        patrol_leader:orderFlyTowards(sf_x, sf_y)
        patrol_leader:setFaction(temp_faction)
    else
        patrol_leader:orderFlyTowards(sf_x, sf_y)
    end
    patrol_leader.leader = true
    patrol_leader.target = station_finish
    table.insert(patrol_group[selected_faction], patrol_leader)
    table.remove(patrol_fleet, slowest_index)
    local formation_groups = {
        [2] = {
            {
                { angle = 60, dist = 800 },
                { angle = 300, dist = 800 },
            },
            {
                { angle = 120, dist = 800 },
                { angle = 240, dist = 800 },
            },
            {
                { angle = 60, dist = 800 },
                { angle = 240, dist = 800 },
            },
            {
                { angle = 120, dist = 800 },
                { angle = 300, dist = 800 },
            },
        },
        [3] = {
            {
                { angle = 60, dist = 800 },
                { angle = 180, dist = 800 },
                { angle = 300, dist = 800 },
            },
            {
                { angle = 0, dist = 800 },
                { angle = 120, dist = 800 },
                { angle = 240, dist = 800 },
            },
            {
                { angle = 180, dist = 800 },
                { angle = 120, dist = 800 },
                { angle = 240, dist = 800 },
            },
            {
                { angle = 0, dist = 800 },
                { angle = 60, dist = 800 },
                { angle = 300, dist = 800 },
            },
        },
        [4] = {
            {
                { angle = 60, dist = 800 },
                { angle = 300, dist = 800 },
                { angle = 60, dist = 1600 },
                { angle = 300, dist = 1600 },
            },
            {
                { angle = 120, dist = 800 },
                { angle = 240, dist = 800 },
                { angle = 120, dist = 1600 },
                { angle = 240, dist = 1600 },
            },
            {
                { angle = 60, dist = 800 },
                { angle = 300, dist = 800 },
                { angle = 120, dist = 800 },
                { angle = 240, dist = 800 },
            },
            {
                { angle = 30, dist = 800 },
                { angle = 330, dist = 800 },
                { angle = 150, dist = 800 },
                { angle = 210, dist = 800 },
            },
        },
        [5] = {
            {
                { angle = 45, dist = 800 },
                { angle = 315, dist = 800 },
                { angle = 90, dist = 800 },
                { angle = 270, dist = 800 },
                { angle = 0, dist = 1600 },
            },
            {
                { angle = 60, dist = 800 },
                { angle = 300, dist = 800 },
                { angle = 60, dist = 1600 },
                { angle = 300, dist = 1600 },
                { angle = 0, dist = 1600 },
            },
            {
                { angle = 120, dist = 800 },
                { angle = 240, dist = 800 },
                { angle = 120, dist = 1600 },
                { angle = 240, dist = 1600 },
                { angle = 180, dist = 1600 },
            },
            {
                { angle = 10, dist = 800 },
                { angle = 82, dist = 800 },
                { angle = 154, dist = 800 },
                { angle = 226, dist = 800 },
                { angle = 298, dist = 800 },
            },
        },
        [6] = {
            {
                { angle = 60, dist = 800 },
                { angle = 300, dist = 800 },
                { angle = 120, dist = 800 },
                { angle = 240, dist = 800 },
                { angle = 30, dist = 1600 },
                { angle = 330, dist = 1600 },
            },
            {
                { angle = 30, dist = 800 },
                { angle = 330, dist = 800 },
                { angle = 90, dist = 800 },
                { angle = 270, dist = 800 },
                { angle = 150, dist = 800 },
                { angle = 210, dist = 800 },
            },
            {
                { angle = 60, dist = 800 },
                { angle = 300, dist = 800 },
                { angle = 120, dist = 800 },
                { angle = 240, dist = 800 },
                { angle = 60, dist = 1600 },
                { angle = 300, dist = 1600 },
            },
            {
                { angle = 90, dist = 800 },
                { angle = 270, dist = 800 },
                { angle = 75, dist = 1600 },
                { angle = 105, dist = 1600 },
                { angle = 285, dist = 1600 },
                { angle = 255, dist = 1600 },
            },
        },
        [7] = {
            {
                { angle = 60, dist = 800 },
                { angle = 300, dist = 800 },
                { angle = 120, dist = 800 },
                { angle = 240, dist = 800 },
                { angle = 60, dist = 1600 },
                { angle = 300, dist = 1600 },
                { angle = 0, dist = 1600 },
            },
            {
                { angle = 60, dist = 800 },
                { angle = 300, dist = 800 },
                { angle = 120, dist = 800 },
                { angle = 240, dist = 800 },
                { angle = 90, dist = 1600 },
                { angle = 270, dist = 1600 },
                { angle = 0, dist = 1600 },
            },
            {
                { angle = 60, dist = 800 },
                { angle = 300, dist = 800 },
                { angle = 120, dist = 800 },
                { angle = 240, dist = 800 },
                { angle = 60, dist = 1600 },
                { angle = 300, dist = 1600 },
                { angle = 180, dist = 1600 },
            },
            {
                { angle = 45, dist = 800 },
                { angle = 135, dist = 800 },
                { angle = 225, dist = 800 },
                { angle = 315, dist = 800 },
                { angle = 0, dist = 1600 },
                { angle = 90, dist = 1600 },
                { angle = 270, dist = 1600 },
            },
        },
    }
    --[[
    if patrol_plot_diagnostic then
        for member_count, group in pairs(formation_groups) do
            print("Member count:",member_count)
            for i=1,4 do
                print(string.format("    Set %i of 4",i))
                for j=1,member_count do
                    print("        Angle:",group[i][j].angle,"Distance:",group[i][j].dist)
                end
            end
        end
    end
--]]
    if #patrol_fleet > 7 then
        print("-----     Patrol fleet larger than available formations")
    end
    local form_index = math.random(1, 4)
    for pfi, ship in ipairs(patrol_fleet) do
        local form_x, form_y = vectorFromAngleNorth(
            (
                patrol_angle
                + formation_groups[#patrol_fleet][form_index][pfi].angle
            ) % 360,
            formation_groups[#patrol_fleet][form_index][pfi].dist
        )
        local form_prime_x, form_prime_y = vectorFromAngle(
            formation_groups[#patrol_fleet][form_index][pfi].angle,
            formation_groups[#patrol_fleet][form_index][pfi].dist
        )
        ship:setPosition(ps_x + form_x, ps_y + form_y):setHeading(patrol_angle)
        local p = getPlayerShip(-1)
        if p ~= nil and p:isValid() and p:isFriendly(ship) then
            local temp_faction = ship:getFaction()
            ship:setFaction("Independent")
            ship:orderFlyFormation(patrol_leader, form_prime_x, form_prime_y)
            ship:setFaction(temp_faction)
        else
            ship:orderFlyFormation(patrol_leader, form_prime_x, form_prime_y)
        end
        ship.target = station_finish
        table.insert(patrol_group[selected_faction], ship)
    end
    if patrol_plot_diagnostic then
        print(
            "Patrol leader:",
            patrol_leader:getCallSign(),
            "Faction:",
            selected_faction,
            "Start station:",
            station_start:getCallSign(),
            "Finish station:",
            station_finish:getCallSign(),
            "number of patrol followers:",
            #patrol_fleet
        )
    end
    resetPatrolDelay()
    patrolPlot = checkPatrol
end
function resetPatrolDelay()
    -- patrol_delay = random(50,100)
    patrol_delay = random(10, 20)
end
function pickPatrolPoint(faction, start_station)
    if patrol_plot_diagnostic then
        if start_station == nil then
            print(
                "Patrol plot diagnostic, pick patrol point. Faction:",
                faction,
                "start station: nil"
            )
        else
            print(
                "Patrol plot diagnostic, pick patrol point. Faction:",
                faction,
                "start station:",
                start_station:getCallSign()
            )
        end
    end
    local affinity_stations = {}
    for si, station in ipairs(defensive_station_list) do
        if station:isValid() then
            if station:getFaction() == faction then
                if start_station ~= nil then
                    if start_station ~= station then
                        table.insert(affinity_stations, station)
                    end
                else
                    table.insert(affinity_stations, station)
                end
            end
        else
            defensive_station_list[si] =
                defensive_station_list[#defensive_station_list]
            defensive_station_list[#defensive_station_list] = nil
            return
        end
    end
    if patrol_plot_diagnostic then
        print(
            "Patrol plot diagnostic, pick patrol point. Affinity station count:",
            #affinity_stations
        )
    end
    if #affinity_stations > 1 then
        if start_station == nil then
            start_station = tableRemoveRandom(affinity_stations)
        end
        local finish_station = tableRemoveRandom(affinity_stations)
        if patrol_plot_diagnostic then
            print(
                "Pick Patrol Point: finish station:",
                finish_station:getCallSign(),
                "start station:",
                start_station:getCallSign()
            )
        end
        return finish_station, start_station
    else
        local fa =
            VisualAsteroid():setFaction(faction):setPosition(600000, 600000)
        if #affinity_stations > 0 then
            if start_station == nil then
                --cannot give start and end point
                affinity_stations = {}
                for si, station in ipairs(transport_station_list) do
                    if station:isValid() then
                        if not station:isEnemy(fa) then
                            if
                                start_station ~= nil
                                and start_station ~= station
                            then
                                table.insert(affinity_stations, station)
                            end
                        end
                    else
                        transport_station_list[si] =
                            transport_station_list[#transport_station_list]
                        transport_station_list[#transport_station_list] = nil
                        fa:destroy()
                        return
                    end
                end
                if #affinity_stations > 1 then
                    if start_station == nil then
                        start_station = tableRemoveRandom(affinity_stations)
                    end
                    fa:destroy()
                    return tableRemoveRandom(affinity_stations), start_station
                else
                    if #affinity_stations > 0 then
                        if start_station == nil then
                            fa:destroy()
                            return
                        else
                            fa:destroy()
                            return affinity_stations[1], start_station
                        end
                    else
                        fa:destroy()
                        return
                    end
                end
            else
                fa:destroy()
                return affinity_stations[1], start_station
            end
        else
            affinity_stations = {}
            for si, station in ipairs(transport_station_list) do
                if station:isValid() then
                    if not station:isEnemy(fa) then
                        if
                            start_station ~= nil
                            and start_station ~= station
                        then
                            table.insert(affinity_stations, station)
                        end
                    end
                else
                    transport_station_list[si] =
                        transport_station_list[#transport_station_list]
                    transport_station_list[#transport_station_list] = nil
                    fa:destroy()
                    return
                end
            end
            if #affinity_stations > 1 then
                if start_station == nil then
                    start_station = tableRemoveRandom(affinity_stations)
                end
                fa:destroy()
                return tableRemoveRandom(affinity_stations), start_station
            else
                if #affinity_stations > 0 then
                    if start_station == nil then
                        fa:destroy()
                        return
                    else
                        fa:destroy()
                        return affinity_stations[1], start_station
                    end
                else
                    fa:destroy()
                    return
                end
            end
        end
    end
end
function checkPatrol(delta)
    if patrol_plot_diagnostic then
        -- print("Patrol plot diagnostic, check patrol. patrol delay:",patrol_delay)
    end
    patrol_delay = patrol_delay - delta
    if patrol_delay < 0 then
        resetPatrolDelay()
        patrolPlot = addPatrol
        return
    end
    for faction, group in pairs(patrol_group) do
        if #group > 0 then
            for index, ship in ipairs(group) do
                if not ship:isValid() then
                    group[index] = group[#group]
                    group[#group] = nil
                    return
                end
            end
        end
    end
    patrolPlot = checkPatrolDestination
end
function checkPatrolDestination(delta)
    if patrol_plot_diagnostic then
        -- print("Patrol plot diagnostic, check patrol destination. patrol delay:",patrol_delay)
    end
    patrol_delay = patrol_delay - delta
    if patrol_delay < 0 then
        resetPatrolDelay()
        patrolPlot = addPatrol
        return
    end
    for faction, group in pairs(patrol_group) do
        if #group > 0 then
            local leader = nil
            for index, ship in ipairs(group) do
                if ship:isValid() then
                    if ship.leader then
                        leader = ship
                        break
                    end
                else
                    group[index] = group[#group]
                    group[#group] = nil
                    return
                end
            end
            if leader ~= nil then
                if leader.target:isValid() then
                    if distance(leader, leader.target) < 2000 then
                        local station_finish, station_start =
                            pickPatrolPoint(faction, leader.target)
                        if patrol_plot_diagnostic then
                            print(
                                "Check Patrol Destination, reached destination, stations returned from pick patrol point: finish station:",
                                station_finish,
                                "start station:",
                                station_start
                            )
                        end
                        if station_finish == nil then
                            patrol_depleted[faction] = true
                            for _, ship in pairs(group) do
                                if ship:isValid() then
                                    local p = getPlayerShip(-1)
                                    if
                                        p ~= nil
                                        and p:isValid()
                                        and p:isFriendly(ship)
                                    then
                                        local temp_faction = ship:getFaction()
                                        ship:setFaction("Independent")
                                        ship:orderRoaming()
                                        ship:setFaction(temp_faction)
                                    else
                                        ship:orderRoaming()
                                    end
                                end
                            end
                            patrol_group[faction] = {}
                        else
                            local p_x, p_y = station_finish:getPosition()
                            leader:orderFlyTowards(p_x, p_y)
                            leader.target = station_finish
                            for _, ship in pairs(group) do
                                if ship:isValid() then
                                    if ship ~= leader then
                                        local p = getPlayerShip(-1)
                                        if
                                            p ~= nil
                                            and p:isValid()
                                            and p:isFriendly(ship)
                                        then
                                            local temp_faction =
                                                ship:getFaction()
                                            ship:setFaction("Independent")
                                            ship:orderDefendTarget(leader)
                                            ship:setFaction(temp_faction)
                                        else
                                            ship:orderDefendTarget(leader)
                                        end
                                        ship.target = station_finish
                                    end
                                end
                            end
                        end
                    end
                else --target not valid, choose another
                    local station_finish, station_start =
                        pickPatrolPoint(faction)
                    if patrol_plot_diagnostic then
                        print(
                            "Check Patrol Destination, leader target invalid, stations returned from pick patrol point: finish station:",
                            station_finish,
                            "start station:",
                            station_start
                        )
                    end
                    if station_finish == nil then
                        patrol_depleted[faction] = true
                        for _, ship in pairs(group) do
                            if ship:isValid() then
                                local p = getPlayerShip(-1)
                                if
                                    p ~= nil
                                    and p:isValid()
                                    and p:isFriendly(ship)
                                then
                                    local temp_faction = ship:getFaction()
                                    ship:setFaction("Independent")
                                    ship:orderRoaming()
                                    ship:setFaction(temp_faction)
                                else
                                    ship:orderRoaming()
                                end
                            end
                        end
                        patrol_group[faction] = {}
                    else
                        local p_x, p_y = station_finish:getPosition()
                        leader:orderFlyTowards(p_x, p_y)
                        leader.target = station_finish
                        for _, ship in pairs(group) do
                            if ship:isValid() then
                                if ship ~= leader then
                                    local p = getPlayerShip(-1)
                                    if
                                        p ~= nil
                                        and p:isValid()
                                        and p:isFriendly(ship)
                                    then
                                        local temp_faction = ship:getFaction()
                                        ship:setFaction("Independent")
                                        ship:orderDefendTarget(leader)
                                        ship:setFaction(temp_faction)
                                    else
                                        ship:orderDefendTarget(leader)
                                    end
                                    ship.target = station_finish
                                end
                            end
                        end
                    end
                end
            else --no leader
                local group_target = nil
                for _, ship in pairs(group) do
                    if ship:isValid() then
                        if ship.target:isValid() then
                            group_target = ship.target
                            break
                        end
                    end
                end
                if group_target ~= nil then
                    local p_x, p_y = group_target:getPosition()
                    for _, ship in pairs(group) do
                        if ship:isValid() then
                            local p = getPlayerShip(-1)
                            if
                                p ~= nil
                                and p:isValid()
                                and p:isFriendly(ship)
                            then
                                local temp_faction = ship:getFaction()
                                ship:setFaction("Independent")
                                ship:orderFlyTowards(p_x, p_y)
                                ship:setFaction(temp_faction)
                            else
                                ship:orderFlyTowards(p_x, p_y)
                            end
                            ship.target = group_target
                        end
                    end
                else --no valid group target, pick new
                    local station_finish, station_start =
                        pickPatrolPoint(faction)
                    if patrol_plot_diagnostic then
                        print(
                            "CPD, no leader, bad target, ppp: finish station:",
                            station_finish:getCallSign(),
                            "start station:",
                            station_start:getCallSign(),
                            "faction:",
                            faction,
                            "group size:",
                            #group
                        )
                    end
                    if station_finish == nil then
                        patrol_depleted[faction] = true
                        for _, ship in pairs(group) do
                            if ship:isValid() then
                                local p = getPlayerShip(-1)
                                if
                                    p ~= nil
                                    and p:isValid()
                                    and p:isFriendly(ship)
                                then
                                    local temp_faction = ship:getFaction()
                                    ship:setFaction("Independent")
                                    ship:orderRoaming()
                                    ship:setFaction(temp_faction)
                                else
                                    ship:orderRoaming()
                                end
                            end
                        end
                        patrol_group[faction] = {}
                    else
                        local p_x, p_y = station_finish:getPosition()
                        for _, ship in pairs(group) do
                            if ship:isValid() then
                                local p = getPlayerShip(-1)
                                if
                                    p ~= nil
                                    and p:isValid()
                                    and p:isFriendly(ship)
                                then
                                    local temp_faction = ship:getFaction()
                                    ship:setFaction("Independent")
                                    ship:orderFlyTowards(p_x, p_y)
                                    ship:setFaction(temp_faction)
                                else
                                    ship:orderFlyTowards(p_x, p_y)
                                end
                                ship.target = station_finish
                            end
                        end
                    end
                end
            end
        end
    end
    patrolPlot = checkPatrolEnemyProximity
end
function checkPatrolEnemyProximity(delta)
    if patrol_plot_diagnostic then
        -- print("Patrol plot diagnostic, check patrol enemy proximity. patrol delay:",patrol_delay)
    end
    patrol_delay = patrol_delay - delta
    if patrol_delay < 0 then
        resetPatrolDelay()
        patrolPlot = addPatrol
        return
    end
    for faction, group in pairs(patrol_group) do
        if #group > 0 then
            local leader = nil
            for index, ship in ipairs(group) do
                if ship:isValid() then
                    if ship.leader then
                        leader = ship
                        break
                    end
                else
                    group[index] = group[#group]
                    group[#group] = nil
                    return
                end
            end
            if leader ~= nil then
                if leader:areEnemiesInRange(5000) then
                    for _, ship in pairs(group) do
                        if ship:isValid() then
                            if ship ~= leader then
                                if
                                    not string.find(ship:getOrder(), "Defend")
                                then
                                    local p = getPlayerShip(-1)
                                    if
                                        p ~= nil
                                        and p:isValid()
                                        and p:isFriendly(ship)
                                    then
                                        local temp_faction = ship:getFaction()
                                        ship:setFaction("Independent")
                                        ship:orderDefendTarget(leader)
                                        ship:setFaction(temp_faction)
                                    else
                                        ship:orderDefendTarget(leader)
                                    end
                                end
                            end
                        end
                    end
                end
            else --no leader
                local rogue_patrol = false
                for _, ship in pairs(group) do
                    if ship:isValid() then
                        if ship:areEnemiesInRange(5000) then
                            rogue_patrol = true
                        end
                    end
                end
                if rogue_patrol then
                    for _, ship in pairs(group) do
                        if ship:isValid() then
                            local p = getPlayerShip(-1)
                            if
                                p ~= nil
                                and p:isValid()
                                and p:isFriendly(ship)
                            then
                                local temp_faction = ship:getFaction()
                                ship:setFaction("Independent")
                                ship:orderRoaming()
                                ship:setFaction(temp_faction)
                            else
                                ship:orderRoaming()
                            end
                        end
                    end
                    patrol_group[faction] = {}
                end
            end
        end
    end
    patrolPlot = checkPatrol
end
function farEnough(o_x, o_y, obj_dist)
    local far_enough = true
    for _, item in ipairs(place_space) do
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
        end
    end
    return far_enough
end
--      Inventory button and functions for relay/operations
function cargoInventory(delta)
    for pidx = 1, 8 do
        local p = getPlayerShip(pidx)
        if p ~= nil and p:isValid() then
            if p:isCommsInactive() then
                p.interaction = {}
            end
            local cargoHoldEmpty = true
            if p.goods ~= nil then
                for good, quantity in pairs(p.goods) do
                    if quantity ~= nil and quantity > 0 then
                        cargoHoldEmpty = false
                        break
                    end
                end
            end
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
    cargoInventoryGivenShip(p)
end
function cargoInventory2()
    local p = getPlayerShip(2)
    cargoInventoryGivenShip(p)
end
function cargoInventory3()
    local p = getPlayerShip(3)
    cargoInventoryGivenShip(p)
end
function cargoInventory4()
    local p = getPlayerShip(4)
    cargoInventoryGivenShip(p)
end
function cargoInventory5()
    local p = getPlayerShip(5)
    cargoInventoryGivenShip(p)
end
function cargoInventory6()
    local p = getPlayerShip(6)
    cargoInventoryGivenShip(p)
end
function cargoInventory7()
    local p = getPlayerShip(7)
    cargoInventoryGivenShip(p)
end
function cargoInventory8()
    local p = getPlayerShip(8)
    cargoInventoryGivenShip(p)
end
-- Gain or lose coolant from nebula functions
function coolantNebulae(delta)
    local x1, y1, x2, y2
    for pidx = 1, 8 do
        local p = getPlayerShip(pidx)
        if p ~= nil and p:isValid() then
            local inside_gain_coolant_nebula = false
            local wonky_nebula_index = 0
            for i = 1, #coolant_nebula do
                --[[
                if p == nil then print("p is nil") end
                if coolant_nebula[i] == nil then print("coolant_nebula[i] is nil") end
                x1, y1 = p:getPosition()
                x2, y2 = coolant_nebula[i]:getPosition()
                if x2 == nil or y2 == nil then
                    print("wonky nebula")
                    print(string.format("i: %i",i))
                    print(string.format("#coolant_nebula: %i",#coolant_nebula))
                end
                ]]
                if x2 ~= nil and y2 ~= nil then
                    if distanceDiagnostic then
                        print(
                            "Distance diagnostic 3: x1:",
                            x1,
                            "y1:",
                            y1,
                            "x2:",
                            x2,
                            "y2:",
                            y2
                        )
                    end
                    if distance(x1, y1, x2, y2) < 5000 then
                        if coolant_nebula[i].lose then
                            p:setMaxCoolant(p:getMaxCoolant() * coolant_loss)
                        end
                        if coolant_nebula[i].gain then
                            inside_gain_coolant_nebula = true
                        end
                    end
                else
                    wonky_nebula_index = i
                end
            end
            if wonky_nebula_index ~= 0 then
                table.remove(coolant_nebula, wonky_nebula_index)
            end
            if inside_gain_coolant_nebula then
                if p.get_coolant then
                    if p.coolant_trigger then
                        updateCoolantGivenPlayer(p, delta)
                    end
                else
                    if p:hasPlayerAtPosition("Engineering") then
                        p.get_coolant_button = "get_coolant_button"
                        p:addCustomButton(
                            "Engineering",
                            p.get_coolant_button,
                            _("coolant-buttonEngineer", "Get Coolant"),
                            get_coolant_function[pidx]
                        )
                        p.get_coolant = true
                    end
                    if p:hasPlayerAtPosition("Engineering+") then
                        p.get_coolant_button_plus = "get_coolant_button_plus"
                        p:addCustomButton(
                            "Engineering+",
                            p.get_coolant_button_plus,
                            _("coolant-buttonEngineer+", "Get Coolant"),
                            get_coolant_function[pidx]
                        )
                        p.get_coolant = true
                    end
                end
            else
                p.get_coolant = false
                p.coolant_trigger = false
                p.configure_coolant_timer = nil
                p.deploy_coolant_timer = nil
                if p:hasPlayerAtPosition("Engineering") then
                    if p.get_coolant_button ~= nil then
                        p:removeCustom(p.get_coolant_button)
                        p.get_coolant_button = nil
                    end
                    if p.gather_coolant ~= nil then
                        p:removeCustom(p.gather_coolant)
                        p.gather_coolant = nil
                    end
                end
                if p:hasPlayerAtPosition("Engineering+") then
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
    if p:hasPlayerAtPosition("Engineering") then
        p.gather_coolant = "gather_coolant"
        p:addCustomInfo("Engineering", p.gather_coolant, gather_coolant_status)
    end
    if p:hasPlayerAtPosition("Engineering+") then
        p.gather_coolant_plus = "gather_coolant_plus"
        p:addCustomInfo(
            "Engineering",
            p.gather_coolant_plus,
            gather_coolant_status
        )
    end
end
function getCoolantGivenPlayer(p)
    if p:hasPlayerAtPosition("Engineering") then
        if p.get_coolant_button ~= nil then
            p:removeCustom(p.get_coolant_button)
            p.get_coolant_button = nil
        end
    end
    if p:hasPlayerAtPosition("Engineering+") then
        if p.get_coolant_button_plus ~= nil then
            p:removeCustom(p.get_coolant_button_plus)
            p.get_coolant_button_plus = nil
        end
    end
    p.coolant_trigger = true
end
function getCoolant1()
    local p = getPlayerShip(1)
    getCoolantGivenPlayer(p)
end
function getCoolant2()
    local p = getPlayerShip(2)
    getCoolantGivenPlayer(p)
end
function getCoolant3()
    local p = getPlayerShip(3)
    getCoolantGivenPlayer(p)
end
function getCoolant4()
    local p = getPlayerShip(4)
    getCoolantGivenPlayer(p)
end
function getCoolant5()
    local p = getPlayerShip(5)
    getCoolantGivenPlayer(p)
end
function getCoolant6()
    local p = getPlayerShip(6)
    getCoolantGivenPlayer(p)
end
function getCoolant7()
    local p = getPlayerShip(7)
    getCoolantGivenPlayer(p)
end
function getCoolant8()
    local p = getPlayerShip(8)
    getCoolantGivenPlayer(p)
end
----------------------------------------------
--  Transport ship generation and handling  --
----------------------------------------------
function randomStation()
    local stationCount = 0
    for sidx, obj in ipairs(stationList) do
        if obj:isValid() then
            stationCount = stationCount + 1
        else
            table.remove(stationList, sidx)
        end
    end
    local sidx = math.floor(random(1, #stationList + 0.99))
    return stationList[sidx]
end
function nearbyStation(object, pool_size)
    if object == nil then
        return
    end
    if pool_size == nil then
        pool_size = 1
    end
    local temp_list = {}
    local temp_station = nil
    for i = 1, #stationList do
        temp_station = stationList[i]
        if
            temp_station ~= nil
            and temp_station:isValid()
            and object ~= temp_station
        then
            table.insert(temp_list, temp_station)
        end
    end
    local nearest_distance = 999999
    for i = 1, #temp_list do
        temp_station = temp_list[i]
        if temp_station ~= nil and temp_station:isValid() then
            nearest_station = temp_station
            nearest_station_index = i
            local x1, y1 = temp_station:getPosition()
            local x2, y2 = object:getPosition()
            if distanceDiagnostic then
                print(
                    "Distance diagnostic 4: x1:",
                    x1,
                    "y1:",
                    y1,
                    "x2:",
                    x2,
                    "y2:",
                    y2
                )
            end
            nearest_distance = distance(x1, y1, x2, y2)
            break
        end
    end
    if nearest_station == nil then
        return
    else
        local station_pool = {}
        for i = 1, pool_size do
            for j = 1, #temp_list do
                temp_station = temp_list[j]
                if temp_station ~= nil and temp_station:isValid() then
                    if temp_station == nil then
                        print("temp_station is nil")
                    end
                    if object == nil then
                        print("object is nil")
                    end
                    local x1, y1 = temp_station:getPosition()
                    local x2, y2 = object:getPosition()
                    local temp_distance = distance(x1, y1, x2, y2)
                    if temp_distance < nearest_distance then
                        nearest_station_index = j
                        nearest_distance = temp_distance
                    end
                end
            end
            if nearest_station_index ~= nil then
                table.insert(station_pool, temp_list[nearest_station_index])
                table.remove(temp_list, nearest_station_index)
            end
            nearest_station_index = nil
            nearest_distance = 999999
        end
        local selected_station = math.random(1, #station_pool)
        return station_pool[selected_station]
    end
end
function transportPlot(delta)
    local p = getPlayerShip(-1)
    transport_spawn_delay = transport_spawn_delay - delta
    if transport_spawn_delay < 0 then
        transport_spawn_delay = random(5, 15)
        --clean up transport list
        local deleted_a_transport = false
        for tidx, transport in ipairs(transport_list) do
            if not transport:isValid() then
                transport_list[tidx] = transport_list[#transport_list]
                transport_list[#transport_list] = nil
                deleted_a_transport = true
                break
            end
        end
        --clean up station list
        local deleted_a_station = false
        local free_station = {}
        for sidx, station in ipairs(transport_station_list) do
            if station:isValid() then
                if station.transport == nil then
                    table.insert(free_station, station)
                else
                    if not station.transport:isValid() then
                        station.transport = nil
                        table.insert(free_station, station)
                    end
                end
            else
                transport_station_list[sidx] =
                    transport_station_list[#transport_station_list]
                transport_station_list[#transport_station_list] = nil
                deleted_a_station = true
                break
            end
        end
        if deleted_a_transport or deleted_a_station then
            transport_spawn_delay = -1 --retry after clean up
        else
            --new transport goes to linked station
            if #transport_list < #transport_station_list then
                local linked_station =
                    free_station[math.random(1, #free_station)]
                local compression_interval = 1000
                local area_radius = 100000
                local o_x = 0
                local o_y = 0
                repeat
                    o_x, o_y =
                        vectorFromAngle(random(0, 360), random(0, area_radius))
                    area_radius = area_radius + compression_interval
                until farEnough(o_x, o_y, 500)
                local transport = randomTransportType()
                transport
                    :setFaction(linked_station:getFaction())
                    :setPosition(o_x, o_y)
                local p = getPlayerShip(-1)
                if p ~= nil and p:isValid() and p:isFriendly(transport) then
                    local temp_faction = transport:getFaction()
                    transport:setFaction("Independent")
                    transport:orderDock(linked_station)
                    transport:setFaction(temp_faction)
                else
                    transport:orderDock(linked_station)
                end
                linked_station.transport = transport
                table.insert(transport_list, transport)
                if p ~= nil and p:isValid() then
                    if not p:isEnemy(transport) then
                        table.insert(mission_transport_list, transport)
                    end
                end
            end
            --docked transports may need a new destination
            local target_station_list = {}
            for _, transport in ipairs(transport_list) do
                local docked_station = transport:getDockedWith()
                local ordered_station = transport:getOrderTarget()
                if ordered_station ~= nil and ordered_station:isValid() then
                    if
                        docked_station ~= nil
                        and docked_station ~= ordered_station
                    then
                        docked_station = nil
                    end
                end
                if docked_station ~= nil then
                    local ordered_station = transport:getOrderTarget()
                    if
                        ordered_station ~= nil
                        and ordered_station:isValid()
                        and ordered_station == docked_station
                    then
                        local transport_faction = transport:getFaction()
                        if target_station_list[transport_faction] == nil then
                            target_station_list[transport_faction] = {}
                            for _, station in ipairs(transport_station_list) do
                                if not station:isEnemy(transport) then
                                    table.insert(
                                        target_station_list[transport_faction],
                                        station
                                    )
                                end
                            end
                        end
                        local p = getPlayerShip(-1)
                        if
                            p ~= nil
                            and p:isValid()
                            and p:isFriendly(transport)
                        then
                            local temp_faction = transport:getFaction()
                            transport:setFaction("Independent")
                            transport:orderDock(
                                target_station_list[transport_faction][math.random(
                                    1,
                                    #target_station_list[transport_faction]
                                )]
                            )
                            transport:setFaction(temp_faction)
                        else
                            transport:orderDock(
                                target_station_list[transport_faction][math.random(
                                    1,
                                    #target_station_list[transport_faction]
                                )]
                            )
                        end
                    end
                end
            end
        end
    end
end
function randomTransportType()
    local transport_type =
        { "Personnel", "Goods", "Garbage", "Equipment", "Fuel" }
    local freighter_engine = "Freighter"
    local freighter_size = math.random(1, 5)
    if random(1, 100) < 30 then
        freighter_engine = "Jump Freighter"
        freighter_size = math.random(3, 5)
    end
    return CpuShip()
        :setTemplate(
            string.format(
                "%s %s %i",
                transport_type[math.random(1, #transport_type)],
                freighter_engine,
                freighter_size
            )
        )
        :setCommsScript("")
        :setCommsFunction(altShipComms),
        freighter_size
end

-----------------------------
--  Station communication  --
-----------------------------
local function showCurrentOrders()
    local ordMsg = primaryOrders .. secondaryOrders .. optionalOrders
    if playWithTimeLimit then
        ordMsg = ordMsg
            .. string.format(
                _("orders-comms", "\n   %i Minutes remain in game"),
                math.floor(gameTimeLimit / 60)
            )
    end
    setCommsMessage(ordMsg)
end

local function addMissionDiagnostic()
    addCommsReply("Diagnostic data", function()
        local dMsg = ""
        if playWithTimeLimit then
            dMsg = string.format("Game time remaining: %f", gameTimeLimit)
        else
            dMsg = string.format(
                "Clue message time remaining: %f",
                clueMessageDelay
            )
        end
        for p12idx = 1, 8 do
            local p12 = getPlayerShip(p12idx)
            if p12 ~= nil and p12:isValid() then
                dMsg = dMsg
                    .. string.format(
                        "\nPlayer %i: %s in sector %s",
                        p12idx,
                        p12:getCallSign(),
                        p12:getSectorName()
                    )
            end
        end
        if plotR ~= nil then
            if plotR == undercutStation then
                dMsg = dMsg
                    .. "\nUndercut station: hide base: "
                    .. hideBase:getCallSign()
                dMsg = dMsg .. "\nundercut location: " .. undercutLocation
            elseif plotR == undercutTransport then
                dMsg = dMsg .. "\nundercut location: " .. undercutLocation
                dMsg = dMsg
                    .. "\nhide transport: "
                    .. hideTransport:getCallSign()
                    .. " in sector "
                    .. hideTransport:getSectorName()
            elseif plotR == undercutEnemyBase then
                dMsg = dMsg
                    .. "\nundercut enemy base: "
                    .. undercutTarget:getCallSign()
                    .. " in sector "
                    .. undercutTarget:getSectorName()
            elseif plotR == horizonStationDeliver then
                dMsg = dMsg
                    .. string.format(
                        "\nhorizon station deliver part1: %s, part2: %s",
                        hr1part,
                        hr2part
                    )
                if comms_source.horizonComponents == nil then
                    dMsg = dMsg .. "\nplayer horizon components: nil"
                else
                    dMsg = dMsg
                        .. "\nplayer horizon components: "
                        .. comms_source.horizonComponents
                end
            end
        end
        setCommsMessage(dMsg)
        addCommsReply(_("Back"), commsStation)
    end)
end

local function addMissionStationComms()
    if sensorBase ~= nil and comms_target == sensorBase then
        upgradeSensors()
    end
    if plotR == horizonStationDeliver and comms_target == stationEmory then
        researchBlackHole()
    end
    if plotO == beamRangeUpgrade and comms_target == stationMarconi then
        researchIncreasedBeamRange()
    end
    if plotO == impulseSpeedUpgrade and comms_target == stationCyrus then
        researchImpulseUpgrade()
    end
    if plotO == spinUpgrade and comms_target == spinBase then
        researchManeuverUpgrade()
    end
    if plotO == beamDamageUpgrade and comms_target == stationNefatha then
        researchIncreasedBeamDamage()
    end
    if comms_target == stationVaiken then
        if beamRangeUpgradeAvailable then
            addCommsReply(
                _(
                    "opt1BeamRangeUpgrade-comms",
                    "Apply Marconi station beam range upgrade"
                ),
                function()
                    if comms_source.marconiBeamUpgrade then
                        setCommsMessage(
                            _(
                                "opt1BeamRangeUpgrade-comms",
                                "You already have the upgrade"
                            )
                        )
                    else
                        if comms_source:getBeamWeaponRange(0) > 0 then
                            local bi = 0
                            repeat
                                local tempArc =
                                    comms_source:getBeamWeaponArc(bi)
                                local tempDir =
                                    comms_source:getBeamWeaponDirection(bi)
                                local tempRng =
                                    comms_source:getBeamWeaponRange(bi)
                                local tempCyc =
                                    comms_source:getBeamWeaponCycleTime(bi)
                                local tempDmg =
                                    comms_source:getBeamWeaponDamage(bi)
                                comms_source:setBeamWeapon(
                                    bi,
                                    tempArc,
                                    tempDir,
                                    tempRng * 1.25,
                                    tempCyc,
                                    tempDmg
                                )
                                bi = bi + 1
                            until comms_source:getBeamWeaponRange(bi) < 1
                            comms_source.marconiBeamUpgrade = true
                            setCommsMessage(
                                _(
                                    "opt1BeamRangeUpgrade-comms",
                                    "Your beam range has been improved by 25 percent"
                                )
                            )
                        else
                            setCommsMessage(
                                _(
                                    "opt1BeamRangeUpgrade-comms",
                                    "Your ship type does not support a beam weapon upgrade."
                                )
                            )
                        end
                    end
                end
            )
        end
        if impulseSpeedUpgradeAvailable then
            addCommsReply(
                _(
                    "opt4ImpulseUpgrade-comms",
                    "Apply Nikhil Morrison impulse engine upgrade"
                ),
                function()
                    if comms_source.morrisonUpgrade then
                        setCommsMessage(
                            _(
                                "opt4ImpulseUpgrade-comms",
                                "You already have the upgrade"
                            )
                        )
                    else
                        comms_source:setImpulseMaxSpeed(
                            comms_source:getImpulseMaxSpeed() * 1.25
                        )
                        comms_source.morrisonUpgrade = true
                        setCommsMessage(
                            _(
                                "opt4ImpulseUpgrade-comms",
                                "Your impulse engine speed has been improved by 25 percent"
                            )
                        )
                    end
                end
            )
        end
        if spinUpgradeAvailable then
            addCommsReply(
                _("opt3SpinUpgrade-comms", "Apply maneuver upgrade"),
                function()
                    if comms_source.spinUpgrade then
                        setCommsMessage(
                            _(
                                "opt3SpinUpgrade-comms",
                                "You already have the upgrade"
                            )
                        )
                    else
                        comms_source:setRotationMaxSpeed(
                            comms_source:getRotationMaxSpeed() * 2
                        )
                        comms_source.spinUpgrade = true
                        setCommsMessage(
                            _(
                                "opt3SpinUpgrade-comms",
                                "Your spin speed has been doubled"
                            )
                        )
                    end
                end
            )
        end
        if shieldUpgradeAvailable then
            addCommsReply(
                _(
                    "opt5ShieldsUpgrade-comms",
                    "Apply Phillip Organa shield upgrade"
                ),
                function()
                    if comms_source.shieldUpgrade then
                        setCommsMessage(
                            _(
                                "opt5ShieldsUpgrade-comms",
                                "You already have the upgrade"
                            )
                        )
                    else
                        local frontShieldValue = comms_source:getShieldMax(0)
                        local rearShieldValue = comms_source:getShieldMax(1)
                        comms_source:setShieldsMax(
                            frontShieldValue * 1.25,
                            rearShieldValue * 1.25
                        )
                        comms_source.shieldUpgrade = true
                        setCommsMessage(
                            _(
                                "opt5ShieldsUpgrade-comms",
                                "Your shield capacity has been increased by 25 percent"
                            )
                        )
                    end
                end
            )
        end
        if beamDamageUpgradeAvailable then
            addCommsReply(
                _(
                    "opt2BeamDamUpgrade-comms",
                    "Apply Nefatha beam damage upgrade"
                ),
                function()
                    if comms_source.nefathaUpgrade then
                        setCommsMessage(
                            _(
                                "opt2BeamDamUpgrade-comms",
                                "You already have the upgrade"
                            )
                        )
                    else
                        if comms_source:getBeamWeaponRange(0) > 0 then
                            local bi = 0
                            repeat
                                local tempArc =
                                    comms_source:getBeamWeaponArc(bi)
                                local tempDir =
                                    comms_source:getBeamWeaponDirection(bi)
                                local tempRng =
                                    comms_source:getBeamWeaponRange(bi)
                                local tempCyc =
                                    comms_source:getBeamWeaponCycleTime(bi)
                                local tempDmg =
                                    comms_source:getBeamWeaponDamage(bi)
                                comms_source:setBeamWeapon(
                                    bi,
                                    tempArc,
                                    tempDir,
                                    tempRng,
                                    tempCyc,
                                    tempDmg * 1.25
                                )
                                bi = bi + 1
                            until comms_source:getBeamWeaponRange(bi) < 1
                            comms_source.nefathaUpgrade = true
                            setCommsMessage(
                                _(
                                    "opt2BeamDamUpgrade-comms",
                                    "Your beam weapons damage has improved by 25 percent"
                                )
                            )
                        else
                            setCommsMessage(
                                _(
                                    "opt2BeamDamUpgrade-comms",
                                    "Your ship type does not support a beam weapon upgrade."
                                )
                            )
                        end
                    end
                end
            )
        end
    end
end

local station_profile
station_profile = {
    main_menu = commsStation,
    preserve_rng = true,
    require_docked = false,
    data = {
        weapons = {
            Homing = "neutral",
            HVLI = "neutral",
            Mine = "neutral",
            Nuke = "friend",
            EMP = "friend",
        },
        weapon_cost = {
            Homing = 2,
            HVLI = 2,
            Mine = 2,
            Nuke = 15,
            EMP = 10,
        },
        services = {
            supplydrop = "friend",
            reinforcements = "friend",
        },
        service_cost = {
            supplydrop = 100,
            reinforcements = 150,
        },
        reputation_cost_multipliers = {
            friend = 1.0,
            neutral = 2.5,
        },
        max_weapon_refill_amount = {
            friend = 1.0,
            neutral = 0.5,
        },
    },
    prepare = function()
        setPlayers()
        local data = comms_target.comms_data
        data.general = data.general or data.general_information
    end,
    goods_knowledge = {
        stations = function()
            return stationList
        end,
        exclude_enemies = false,
    },
    resources = {
        prompt = false,
        recruitment = false,
        coolant = false,
    },
    goods = {
        jettison_when = "full",
        jettison_prompt = _("trade-comms", "What would you like to jettison?"),
    },
    docked = {
        greeting = function()
            if comms_source:isFriendly(comms_target) then
                return _(
                    "station-comms",
                    "Good day, officer!\nWhat can we do for you today?\n"
                )
            end
            return _("station-comms", "Welcome to our lovely station.\n")
        end,
        show_reputation = false,
        group_services = false,
        service_prompt = false,
        service_sections = { "ordnance" },
        ordnance = {
            show_reputation = false,
            ignore_availability = true,
            label = function(weapon)
                return string.format(
                    _("ammo-comms", "%s (%d rep each)"),
                    weapon,
                    StationCore.getWeaponCost(weapon)
                )
            end,
        },
        after_services = function()
            if comms_source:isFriendly(comms_target) then
                StationMenu.currentOrders(station_profile, showCurrentOrders)
            end
        end,
        before_resources = function()
            if comms_target.comms_data.public_relations then
                StationMenu.gossip(station_profile, {
                    defer_roll = true,
                    back = false,
                })
            end
        end,
        group_resources = false,
        after_resources = function()
            addMissionStationComms()
        end,
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
                { kind = "enemy_warning" },
                { kind = "ordnance" },
                { kind = "goods_available" },
                { kind = "goods_knowledge" },
            },
        },
        after_information = function()
            if comms_source:isFriendly(comms_target) then
                StationMenu.currentOrders(station_profile, showCurrentOrders)
            end
            if diagnostic then
                addMissionDiagnostic()
            end
        end,
        assistance = false,
        after_assistance = function()
            StationMenu.supplyDrop(station_profile)
            StationMenu.reinforcements(station_profile)
        end,
        reinforcements = {
            {
                service = "reinforcements",
                label = _(
                    "stationAssist-comms",
                    "Please send reinforcements! (%d rep)"
                ),
                spawn = function(index)
                    local ship = CpuShip()
                        :setFactionId(comms_target:getFactionId())
                        :setPosition(comms_target:getPosition())
                        :setTemplate(ST.ADDER_MK5)
                        :setScanned(true)
                    local p = getPlayerShip(-1)
                    if
                        p ~= nil
                        and p:isValid()
                        and p:isFriendly(ship)
                    then
                        local temp_faction = ship:getFaction()
                        ship:setFaction("Independent")
                        ship:orderDefendLocation(
                            comms_source:getWaypoint(index)
                        )
                        ship:setFaction(temp_faction)
                    else
                        ship:orderDefendLocation(
                            comms_source:getWaypoint(index)
                        )
                    end
                    ship:setCallSign(generateCallSign())
                    return ship
                end,
            },
        },
    },
}

commsStation = StationMenu.entrypoint(function() return station_profile end)
--mission specific functions
function upgradeSensors()
    if comms_source.stettor == nil then
        local ctd = comms_target.comms_data
        local s1PartQuantity = 0
        local s2PartQuantity = 0
        local s3PartQuantity = 0
        if
            comms_source.goods ~= nil
            and comms_source.goods[s1part] ~= nil
            and comms_source.goods[s1part] > 0
        then
            s1PartQuantity = comms_source.goods[s1part]
        end
        if
            comms_source.goods ~= nil
            and comms_source.goods[s2part] ~= nil
            and comms_source.goods[s2part] > 0
        then
            s2PartQuantity = comms_source.goods[s2part]
        end
        if
            comms_source.goods ~= nil
            and comms_source.goods[s3part] ~= nil
            and comms_source.goods[s3part] > 0
        then
            s3PartQuantity = comms_source.goods[s3part]
        end
        if s1PartQuantity > 0 and s2PartQuantity > 0 and s3PartQuantity > 0 then
            addCommsReply(
                string.format(
                    _(
                        "upgradeSensors-comms",
                        "Provide %s, %s and %s for sensor upgrade"
                    ),
                    s1part,
                    s2part,
                    s3part
                ),
                function()
                    comms_source.goods[s1part] = comms_source.goods[s1part] - 1
                    comms_source.goods[s2part] = comms_source.goods[s2part] - 1
                    comms_source.goods[s3part] = comms_source.goods[s3part] - 1
                    comms_source.cargo = comms_source.cargo + 3
                    if stettorTarget == nil then
                        if stationGanalda:isValid() then
                            stettorTarget = stationGanalda
                        elseif stationTic:isValid() then
                            stettorTarget = stationTic
                        else
                            stettorTarget = stationEmpok
                        end
                    end
                    local oMsg = string.format(
                        _(
                            "upgradeSensors-comms",
                            "Our upgraded sensors found an enemy base in sector %s"
                        ),
                        stettorTarget:getSectorName()
                    )
                    comms_source.stettor = "provided"
                    setCommsMessage(oMsg)
                    addCommsReply(_("Back"), commsStation)
                end
            )
        end
    end
end
function researchBlackHole()
    if comms_source.horizonComponents == nil then
        local ctd = comms_target.comms_data
        local hr1partQuantity = 0
        local hr2partQuantity = 0
        if
            comms_source.goods ~= nil
            and comms_source.goods[hr1part] ~= nil
            and comms_source.goods[hr1part] > 0
        then
            hr1partQuantity = comms_source.goods[hr1part]
        end
        if
            comms_source.goods ~= nil
            and comms_source.goods[hr2part] ~= nil
            and comms_source.goods[hr2part] > 0
        then
            hr2partQuantity = comms_source.goods[hr2part]
        end
        if hr1partQuantity > 0 and hr2partQuantity > 0 then
            addCommsReply(
                string.format(
                    _(
                        "blackHoleresearch-comms",
                        "Provide %s and %s for black hole research"
                    ),
                    hr1part,
                    hr2part
                ),
                function()
                    comms_source.goods[hr1part] = comms_source.goods[hr1part]
                        - 1
                    comms_source.goods[hr2part] = comms_source.goods[hr2part]
                        - 1
                    comms_source.cargo = comms_source.cargo + 2
                    local bhsMsg = _(
                        "blackHoleresearch-comms",
                        "With the materials you supplied, we installed special sensors on your ship. "
                    )
                    bhsMsg = bhsMsg
                        .. _(
                            "blackHoleresearch-comms",
                            "We need you to get close to the black hole and run sensor sweeps. "
                        )
                    bhsMsg = bhsMsg
                        .. _(
                            "blackHoleresearch-comms",
                            "Your science console will have the controls when your ship is in range."
                        )
                    bhsMsg = bhsMsg
                        .. string.format(
                            _(
                                "blackHoleresearch-comms",
                                "\nThe mobile black hole was last seen in sector %s"
                            ),
                            grawp:getSectorName()
                        )
                    setCommsMessage(bhsMsg)
                    comms_source.horizonComponents = "provided"
                end
            )
        end
    end
end
function researchIncreasedBeamDamage()
    if comms_source.beamDamageComponents == nil then
        local ctd = comms_target.comms_data
        local bd1partQuantity = 0
        local bd2partQuantity = 0
        local bd3partQuantity = 0
        if comms_source.goods ~= nil then
            if comms_source.goods[bd1part] ~= nil then
                if comms_source.goods[bd1part] > 0 then
                    bd1partQuantity = comms_source.goods[bd1part]
                end
            end
        end
        if
            comms_source.goods ~= nil
            and comms_source.goods[bd2part] ~= nil
            and comms_source.goods[bd2part] > 0
        then
            bd2partQuantity = comms_source.goods[bd2part]
        end
        if
            comms_source.goods ~= nil
            and comms_source.goods[bd3part] ~= nil
            and comms_source.goods[bd3part] > 0
        then
            bd3partQuantity = comms_source.goods[bd3part]
        end
        if
            bd1partQuantity > 0
            and bd2partQuantity > 0
            and bd3partQuantity > 0
        then
            addCommsReply(
                string.format(
                    _(
                        "opt2BeamDamResearch-comms",
                        "Provide %s, %s and %s for beam damage research"
                    ),
                    bd1part,
                    bd2part,
                    bd3part
                ),
                function()
                    comms_source.goods[bd1part] = comms_source.goods[bd1part]
                        - 1
                    comms_source.goods[bd2part] = comms_source.goods[bd2part]
                        - 1
                    comms_source.goods[bd3part] = comms_source.goods[bd3part]
                        - 1
                    comms_source.cargo = comms_source.cargo + 3
                    setCommsMessage(
                        _(
                            "opt2BeamDamResearch-comms",
                            "Thanks. We completed our beam damage research. We transmitted our results to Vaiken. The next time you dock at Vaiken, you can upgrade your beam weapon damage."
                        )
                    )
                    comms_source.beamDamageComponents = "provided"
                end
            )
        end
    end
end
function researchIncreasedBeamRange()
    if comms_source.beamComponents == nil then
        local ctd = comms_target.comms_data
        local br1partQuantity = 0
        local br2partQuantity = 0
        local br3partQuantity = 0
        if comms_source.goods ~= nil then
            if comms_source.goods[br1part] ~= nil then
                if comms_source.goods[br1part] > 0 then
                    br1partQuantity = comms_source.goods[br1part]
                end
            end
        end
        if
            comms_source.goods ~= nil
            and comms_source.goods[br2part] ~= nil
            and comms_source.goods[br2part] > 0
        then
            br2partQuantity = comms_source.goods[br2part]
        end
        if
            comms_source.goods ~= nil
            and comms_source.goods[br3part] ~= nil
            and comms_source.goods[br3part] > 0
        then
            br3partQuantity = comms_source.goods[br3part]
        end
        if
            br1partQuantity > 0
            and br2partQuantity > 0
            and br3partQuantity > 0
        then
            addCommsReply(
                string.format(
                    _(
                        "opt1BeamRangeResearch-comms",
                        "Provide %s, %s and %s for beam research project"
                    ),
                    br1part,
                    br2part,
                    br3part
                ),
                function()
                    comms_source.goods[br1part] = comms_source.goods[br1part]
                        - 1
                    comms_source.goods[br2part] = comms_source.goods[br2part]
                        - 1
                    comms_source.goods[br3part] = comms_source.goods[br3part]
                        - 1
                    comms_source.cargo = comms_source.cargo + 3
                    setCommsMessage(
                        _(
                            "opt1BeamRangeResearch-comms",
                            "With the goods you provided, we completed our advanced beam weapons prototype. We transmitted our research results to Vaiken. The next time you dock at Vaiken, you can have the range of your beam weapons upgraded."
                        )
                    )
                    comms_source.beamComponents = "provided"
                end
            )
        end
    end
end
function researchImpulseUpgrade()
    if comms_source.impulseSpeedComponents == nil then
        local ctd = comms_target.comms_data
        local is1partQuantity = 0
        local is2partQuantity = 0
        if
            comms_source.goods ~= nil
            and comms_source.goods[is1part] ~= nil
            and comms_source.goods[is1part] > 0
        then
            is1partQuantity = comms_source.goods[is1part]
        end
        if
            comms_source.goods ~= nil
            and comms_source.goods[is2part] ~= nil
            and comms_source.goods[is2part] > 0
        then
            is2partQuantity = comms_source.goods[is2part]
        end
        if is2partQuantity > 0 and is2partQuantity > 0 then
            addCommsReply(
                string.format(
                    _(
                        "opt4ImpulseResearch-comms",
                        "Provide %s and %s for impulse engine research project"
                    ),
                    is1part,
                    is2part
                ),
                function()
                    comms_source.goods[is1part] = comms_source.goods[is1part]
                        - 1
                    comms_source.goods[is2part] = comms_source.goods[is2part]
                        - 1
                    comms_source.cargo = comms_source.cargo + 2
                    setCommsMessage(
                        _(
                            "opt4ImpulseResearch-comms",
                            "[Nikhil Morrison] With the goods you provided, I completed the impulse engine research. I transmitted the research results to Vaiken. The next time you dock at Vaiken, you can have the speed of your impulse engines improved."
                        )
                    )
                    comms_source.impulseSpeedComponents = "provided"
                end
            )
        end
    end
end
function researchManeuverUpgrade()
    if comms_source.spinComponents == nil then
        local ctd = comms_target.comms_data
        local sp1partQuantity = 0
        local sp2partQuantity = 0
        local sp3partQuantity = 0
        if
            comms_source.goods ~= nil
            and comms_source.goods[sp1part] ~= nil
            and comms_source.goods[sp1part] > 0
        then
            sp1partQuantity = comms_source.goods[sp1part]
        end
        if
            comms_source.goods ~= nil
            and comms_source.goods[sp2part] ~= nil
            and comms_source.goods[sp2part] > 0
        then
            sp2partQuantity = comms_source.goods[sp2part]
        end
        if
            comms_source.goods ~= nil
            and comms_source.goods[sp3part] ~= nil
            and comms_source.goods[sp3part] > 0
        then
            sp3partQuantity = comms_source.goods[sp3part]
        end
        if
            sp1partQuantity > 0
            and sp2partQuantity > 0
            and sp3partQuantity > 0
        then
            addCommsReply(
                string.format(
                    _(
                        "opt3SpinResearch-comms",
                        "Provide %s, %s and %s for maneuver research project"
                    ),
                    sp1part,
                    sp2part,
                    sp3part
                ),
                function()
                    comms_source.goods[sp1part] = comms_source.goods[sp1part]
                        - 1
                    comms_source.goods[sp2part] = comms_source.goods[sp2part]
                        - 1
                    comms_source.goods[sp3part] = comms_source.goods[sp3part]
                        - 1
                    comms_source.cargo = comms_source.cargo + 3
                    setCommsMessage(
                        _(
                            "opt3SpinResearch-comms",
                            "[Maneuver technician] With the goods you provided, we completed the maneuver research and transmitted the research results to Vaiken. The next time you dock at Vaiken, you can have your ship's maneuver speed improved."
                        )
                    )
                    comms_source.spinComponents = "provided"
                end
            )
        end
    end
end

--------------------------
--  Ship communication  --
--------------------------
function altShipComms()
    if comms_target.comms_data == nil then
        comms_target.comms_data = { friendlyness = random(0.0, 100.0) }
    else
        if comms_target.comms_data.friendlyness == nil then
            comms_target.comms_data.friendlyness = random(0.0, 100.0)
        end
    end
    comms_data = comms_target.comms_data
    if comms_target.comms_data.goods == nil then
        comms_target.comms_data.goods = {}
        comms_target.comms_data.goods[commonGoods[math.random(1, #commonGoods)]] =
            { quantity = 1, cost = math.random(20, 80) }
        local shipType = comms_target:getTypeName()
        if shipType:find("Freighter") ~= nil then
            if
                shipType:find("Goods") ~= nil
                or shipType:find("Equipment") ~= nil
            then
                repeat
                    comms_target.comms_data.goods[commonGoods[math.random(
                        1,
                        #commonGoods
                    )]] =
                        { quantity = 1, cost = math.random(20, 80) }
                    local goodCount = 0
                    for good, goodData in pairs(comms_target.comms_data.goods) do
                        goodCount = goodCount + 1
                    end
                until goodCount >= 3
            end
        end
    end
    setPlayers()
    if comms_source:isFriendly(comms_target) then
        local c_msg = _("shipAssist-comms", "Sir, how can we assist?")
        if comms_target.comms_data.friendlyness < 20 then
            c_msg = _("shipAssist-comms", "What do you want?")
        elseif comms_target.comms_data.friendlyness < 40 then
            c_msg = _("shipAssist-comms", "Hello?")
        elseif comms_target.comms_data.friendlyness < 60 then
            c_msg = _("shipAssist-comms", "Greetings")
        end
        setCommsMessage(c_msg)
        return altFriendlyShipComms()
    end
    if
        comms_source:isEnemy(comms_target)
        and comms_target:isFriendOrFoeIdentifiedBy(comms_source)
    then
        return enemyComms(comms_data)
    end
    return neutralComms(comms_data)
end
function neutralFriendlyFreighterComms()
    if undercutLocation == "transport" then
        if comms_source == nil then
            print("comms_source 5 is nil")
        end
        if comms_target == nil then
            print("comms_target 5 is nil")
        end
        if distanceDiagnostic then
            print(
                "Distance diagnostic 5: comms_source:",
                comms_source:getCallSign(),
                "comms_target:",
                comms_target:getCallSign()
            )
        end
        if distance(comms_source, comms_target) < 5000 then
            if comms_target == hideTransport then
                addCommsReply(
                    _("Undercut2-comms", "I need to talk to Charles Undercut"),
                    function()
                        setCommsMessage(
                            _(
                                "Undercut2-comms",
                                "[Charles Undercut] Haven't you destroyed my life enough?"
                            )
                        )
                        addCommsReply(
                            _(
                                "Undercut2-comms",
                                "We need the information you obtained about enemies in this region"
                            ),
                            function()
                                setCommsMessage(
                                    _(
                                        "Undercut2-comms",
                                        "That will cost you something more than just pretty words. Got any luxury, gold or platinum goods?"
                                    )
                                )
                                if comms_source.goods ~= nil then
                                    if
                                        comms_source.goods["luxury"] ~= nil
                                        and comms_source.goods["luxury"] > 0
                                    then
                                        addCommsReply(
                                            _(
                                                "Undercut2-comms",
                                                "Trade luxury for information"
                                            ),
                                            function()
                                                comms_source.goods["luxury"] = comms_source.goods["luxury"]
                                                    - 1
                                                comms_source.cargo = comms_source.cargo
                                                    + 1
                                                if stationGanalda:isValid() then
                                                    undercutTarget =
                                                        stationGanalda
                                                elseif
                                                    stationEmpok:isValid()
                                                then
                                                    undercutTarget =
                                                        stationEmpok
                                                else
                                                    undercutTarget = stationTic
                                                end
                                                comms_source:addToShipLog(
                                                    string.format(
                                                        _(
                                                            "Undercut2-shipLog",
                                                            "enemy base identified in sector %s"
                                                        ),
                                                        undercutTarget:getSectorName()
                                                    ),
                                                    "Magenta"
                                                )
                                                setCommsMessage(
                                                    string.format(
                                                        _(
                                                            "Undercut2-comms",
                                                            "I found an enemy base in sector %s"
                                                        ),
                                                        undercutTarget:getSectorName()
                                                    )
                                                )
                                                undercutLocation = "free"
                                            end
                                        )
                                    end
                                    if
                                        comms_source.goods["gold"] ~= nil
                                        and comms_source.goods["gold"] > 0
                                    then
                                        addCommsReply(
                                            _(
                                                "Undercut2-comms",
                                                "Trade gold for information"
                                            ),
                                            function()
                                                comms_source.goods["gold"] = comms_source.goods["gold"]
                                                    - 1
                                                comms_source.cargo = comms_source.cargo
                                                    + 1
                                                if stationGanalda:isValid() then
                                                    undercutTarget =
                                                        stationGanalda
                                                elseif
                                                    stationEmpok:isValid()
                                                then
                                                    undercutTarget =
                                                        stationEmpok
                                                else
                                                    undercutTarget = stationTic
                                                end
                                                comms_source:addToShipLog(
                                                    string.format(
                                                        _(
                                                            "Undercut2-shipLog",
                                                            "enemy base identified in sector %s"
                                                        ),
                                                        undercutTarget:getSectorName()
                                                    ),
                                                    "Magenta"
                                                )
                                                setCommsMessage(
                                                    string.format(
                                                        _(
                                                            "Undercut2-comms",
                                                            "I found an enemy base in sector %s"
                                                        ),
                                                        undercutTarget:getSectorName()
                                                    )
                                                )
                                                undercutLocation = "free"
                                            end
                                        )
                                    end
                                    if
                                        comms_source.goods["platinum"]
                                            ~= nil
                                        and comms_source.goods["platinum"]
                                            > 0
                                    then
                                        addCommsReply(
                                            _(
                                                "Undercut2-comms",
                                                "Trade platinum for information"
                                            ),
                                            function()
                                                comms_source.goods["platinum"] = comms_source.goods["platinum"]
                                                    - 1
                                                comms_source.cargo = comms_source.cargo
                                                    + 1
                                                if stationGanalda:isValid() then
                                                    undercutTarget =
                                                        stationGanalda
                                                elseif
                                                    stationEmpok:isValid()
                                                then
                                                    undercutTarget =
                                                        stationEmpok
                                                else
                                                    undercutTarget = stationTic
                                                end
                                                comms_source:addToShipLog(
                                                    string.format(
                                                        _(
                                                            "Undercut2-shipLog",
                                                            "enemy base identified in sector %s"
                                                        ),
                                                        undercutTarget:getSectorName()
                                                    ),
                                                    "Magenta"
                                                )
                                                setCommsMessage(
                                                    string.format(
                                                        _(
                                                            "Undercut2-comms",
                                                            "I found an enemy base in sector %s"
                                                        ),
                                                        undercutTarget:getSectorName()
                                                    )
                                                )
                                                undercutLocation = "free"
                                            end
                                        )
                                    end
                                end
                                addCommsReply(_("Back"), altShipComms)
                            end
                        )
                        addCommsReply(_("Back"), altShipComms)
                    end
                )
            end
        end
    end
    if plotR == sporiskyTransport then
        if comms_target == runTransport then
            if comms_source == nil then
                print("comms_source 6 is nil")
            end
            if comms_target == nil then
                print("comms_target 6 is nil")
            end
            local x1, y1 = comms_source:getPosition()
            local x2, y2 = comms_target:getPosition()
            if distance(x1, y1, x2, y2) < 5000 then
                if sporiskyLocation ~= "aboard ship" then
                    addCommsReply(
                        _(
                            "Undercut2-comms",
                            "We need you to hand over Annette Sporisky"
                        ),
                        function()
                            local asMsg = _(
                                "Undercut2-comms",
                                "Why should we? Despite what you may have heard, she is not related to this freighter's owner. "
                            )
                            asMsg = asMsg
                                .. _(
                                    "Undercut2-comms",
                                    "However, she's obviously valuable. I'll hand her over for something I can trade, "
                                )
                            asMsg = asMsg
                                .. _(
                                    "Undercut2-comms",
                                    "one of the following types of goods: "
                                )
                            if as1part == nil then
                                local as1choice = math.floor(random(1, 3))
                                if as1choice == 1 then
                                    as1part = "dilithium"
                                elseif as1choice == 2 then
                                    as1part = "platinum"
                                else
                                    as1part = "gold"
                                end
                            end
                            if as2part == nil then
                                local as2choice = math.floor(random(1, 3))
                                if as2choice == 1 then
                                    as2part = "nanites"
                                elseif as2choice == 2 then
                                    as2part = "impulse"
                                else
                                    as2part = "communication"
                                end
                            end
                            if as3part == nil then
                                local as3choice = math.floor(random(1, 3))
                                if as3choice == 1 then
                                    as3part = "optic"
                                elseif as3choice == 2 then
                                    as3part = "lifter"
                                else
                                    as3part = "filament"
                                end
                            end
                            asMsg = asMsg
                                .. as1part
                                .. ", "
                                .. as2part
                                .. _("trade-comms", " or ")
                                .. as3part
                            setCommsMessage(asMsg)
                            if comms_source.goods ~= nil then
                                if
                                    comms_source.goods[as1part] ~= nil
                                    and comms_source.goods[as1part] > 0
                                then
                                    addCommsReply(
                                        string.format(
                                            _(
                                                "Undercut2-comms",
                                                "Trade %s for Annette Sporisky"
                                            ),
                                            as1part
                                        ),
                                        function()
                                            comms_source.goods[as1part] = comms_source.goods[as1part]
                                                - 1
                                            comms_source.cargo = comms_source.cargo
                                                + 1
                                            comms_source.traitorBought = true
                                            comms_source:addToShipLog(
                                                _(
                                                    "Undercut2-comms",
                                                    "Annette Sporisky aboard"
                                                ),
                                                "Magenta"
                                            )
                                            setCommsMessage(
                                                _("trade-comms", "Traded")
                                            )
                                            sporiskyTarget = stationGanalda
                                            sporiskyLocation = "aboard ship"
                                        end
                                    )
                                end
                                if
                                    comms_source.goods[as2part] ~= nil
                                    and comms_source.goods[as2part] > 0
                                then
                                    addCommsReply(
                                        string.format(
                                            _(
                                                "Undercut2-comms",
                                                "Trade %s for Annette Sporisky"
                                            ),
                                            as2part
                                        ),
                                        function()
                                            comms_source.goods[as2part] = comms_source.goods[as2part]
                                                - 1
                                            comms_source.cargo = comms_source.cargo
                                                + 1
                                            comms_source.traitorBought = true
                                            comms_source:addToShipLog(
                                                _(
                                                    "Undercut2-comms",
                                                    "Annette Sporisky aboard"
                                                ),
                                                "Magenta"
                                            )
                                            setCommsMessage(
                                                _("trade-comms", "Traded")
                                            )
                                            sporiskyTarget = stationEmpok
                                            sporiskyLocation = "aboard ship"
                                        end
                                    )
                                end
                                if
                                    comms_source.goods[as3part] ~= nil
                                    and comms_source.goods[as3part] > 0
                                then
                                    addCommsReply(
                                        string.format(
                                            _(
                                                "Undercut2-comms",
                                                "Trade %s for Annette Sporisky"
                                            ),
                                            as3part
                                        ),
                                        function()
                                            comms_source.goods[as3part] = comms_source.goods[as3part]
                                                - 1
                                            comms_source.cargo = comms_source.cargo
                                                + 1
                                            comms_source.traitorBought = true
                                            comms_source:addToShipLog(
                                                _(
                                                    "Undercut2-comms",
                                                    "Annette Sporisky aboard"
                                                ),
                                                "Magenta"
                                            )
                                            setCommsMessage(
                                                _("trade-comms", "Traded")
                                            )
                                            sporiskyTarget = stationTic
                                            sporiskyLocation = "aboard ship"
                                        end
                                    )
                                end
                            end
                            addCommsReply(_("Back"), altShipComms)
                        end
                    )
                end
            end
        end
    end
end
function friendlyFreighterComms()
    if comms_source.interaction == nil then
        comms_source.interaction = {}
    end
    if comms_source.interaction[comms_target] == nil then
        comms_source.interaction[comms_target] = {}
    end
    if comms_source.interaction[comms_target].chat_list == nil then
        comms_source.interaction[comms_target].chat_list = {
            {
                prompt = _("friendlyFreighter-comms", "How's your family?"),
                resp = {
                    _("friendlyFreighter-comms", "Pretty good."),
                    _("friendlyFreighter-comms", "All healthy."),
                    _(
                        "friendlyFreighter-comms",
                        "I love 'em, but they bug me."
                    ),
                },
            },
            {
                prompt = _("friendlyFreighter-comms", "How's business?"),
                resp = {
                    _("friendlyFreighter-comms", "Not bad."),
                    _(
                        "friendlyFreighter-comms",
                        "I'm making a fortune out here."
                    ),
                    _("friendlyFreighter-comms", "Could be better."),
                    _("trade-comms", "The pirates make it hard."),
                },
            },
            {
                prompt = _(
                    "friendlyFreighter-comms",
                    "Made any interesting contacts?"
                ),
                resp = {
                    _("friendlyFreighter-comms", "Made a couple."),
                    _("friendlyFreighter-comms", "Not this week."),
                    _(
                        "friendlyFreighter-comms",
                        "Met the friendliest alien the other day. Purchased all my cargo."
                    ),
                },
            },
            {
                prompt = _(
                    "friendlyFreighter-comms",
                    "What have you been up to?"
                ),
                resp = {
                    _("friendlyFreighter-comms", "Oh, the usual."),
                    _("friendlyFreighter-comms", "About 2 meters."),
                    _("friendlyFreighter-comms", "Not much."),
                    _("trade-comms", "Trying to stay alive, mostly."),
                },
            },
        }
    end
    if #comms_source.interaction[comms_target].chat_list > 0 then
        for chat_index, chat in
            ipairs(comms_source.interaction[comms_target].chat_list)
        do
            addCommsReply(chat.prompt, function()
                local c_msg = chat.resp[math.random(1, #chat.resp)]
                setCommsMessage(c_msg)
                table.remove(
                    comms_source.interaction[comms_target].chat_list,
                    chat_index
                )
                addCommsReply(_("Back"), function()
                    -- setCommsMessage(c_msg)
                    setCommsMessage("")
                    friendlyFreighterComms()
                end)
                comms_target.comms_data.friendlyness = math.min(
                    100,
                    comms_target.comms_data.friendlyness + random(1, 10)
                )
            end)
        end
    end
    if
        #comms_source.interaction[comms_target].chat_list < 1
        or random(1, 100) < 22
    then
        if comms_target.comms_data.friendlyness > 66 then
            -- setCommsMessage(_("trade-comms", "Yes?"))
            addCommsReply(
                _("trade-comms", "Do you have cargo you might sell?"),
                function()
                    local goodCount = 0
                    local cargoMsg = _("trade-comms", "We've got ")
                    for good, goodData in pairs(comms_target.comms_data.goods) do
                        if goodData.quantity > 0 then
                            if goodCount > 0 then
                                cargoMsg = cargoMsg
                                    .. _("trade-comms", ", ")
                                    .. good
                            else
                                cargoMsg = cargoMsg .. good
                            end
                        end
                        goodCount = goodCount + goodData.quantity
                    end --freighter goods list loop
                    if goodCount == 0 then
                        cargoMsg = cargoMsg .. _("trade-comms", "nothing")
                    end
                    setCommsMessage(cargoMsg)
                end
            )
            -- Offer destination information
            addCommsReply(_("trade-comms", "Where are you headed?"), function()
                setCommsMessage(comms_target.target:getCallSign())
                addCommsReply(_("Back"), altShipComms)
            end)
            -- Offer to trade goods if goods or equipment freighter
            if comms_source == nil then
                print("comms_source 2 is nil")
            end
            if comms_target == nil then
                print("comms_target 2 is nil")
            end
            local x1, y1 = comms_source:getPosition()
            local x2, y2 = comms_target:getPosition()
            if distance(x1, y1, x2, y2) < 5000 then
                if
                    shipType:find("Goods") ~= nil
                    or shipType:find("Equipment") ~= nil
                then
                    if comms_source.goods == nil then
                        comms_source.goods = {}
                    end
                    if comms_source.goods["luxury"] == nil then
                        comms_source.goods["luxury"] = 0
                    end
                    if comms_source.goods["luxury"] > 0 then
                        for good, good_data in
                            pairs(comms_target.comms_data.goods)
                        do
                            if good_data.quantity > 0 then
                                addCommsReply(
                                    string.format(
                                        _("trade-comms", "Trade luxury for %s"),
                                        good
                                    ),
                                    function()
                                        comms_target.comms_data.goods.good.quantity = comms_target.comms_data.goods.good.quantity
                                            - 1
                                        comms_source.goods["luxury"] = comms_source.goods["luxury"]
                                            - 1
                                        if comms_source.goods[good] == nil then
                                            comms_source.goods[good] = 0
                                        end
                                        comms_source.goods[good] = comms_source.goods[good]
                                            + 1
                                        setCommsMessage(
                                            _("trade-comms", "Traded")
                                        )
                                        addCommsReply(_("Back"), altShipComms)
                                    end
                                )
                            end
                        end
                    end --player has luxury
                else --not a goods or equipment freighter
                    if comms_source.cargo < 1 then
                        addCommsReply(
                            _("trade-comms", "Jettison cargo"),
                            function()
                                setCommsMessage(
                                    _(
                                        "trade-comms",
                                        "What would you like to jettison?"
                                    )
                                )
                                for good, good_quantity in
                                    pairs(comms_source.goods)
                                do
                                    if good_quantity > 0 then
                                        addCommsReply(good, function()
                                            comms_source.goods[good] = comms_source.goods[good]
                                                - 1
                                            comms_source.cargo = comms_source.cargo
                                                + 1
                                            setCommsMessage(
                                                string.format(
                                                    _(
                                                        "trade-comms",
                                                        "One %s jettisoned"
                                                    ),
                                                    good
                                                )
                                            )
                                            addCommsReply(
                                                _("Back"),
                                                altShipComms
                                            )
                                        end)
                                    end
                                end
                                addCommsReply(_("Back"), altShipComms)
                            end
                        )
                    end
                    -- Offer to sell goods
                    for good, good_data in pairs(comms_target.comms_data.goods) do
                        if
                            good_data.quantity > 0
                            and comms_source.cargo > 0
                        then
                            addCommsReply(
                                string.format(
                                    _(
                                        "trade-comms",
                                        "Buy one %s for %i reputation"
                                    ),
                                    good,
                                    good_data.cost
                                ),
                                function()
                                    if
                                        comms_source:takeReputationPoints(
                                            good_data.cost
                                        )
                                    then
                                        comms_source.cargo = comms_source.cargo
                                            - 1
                                        if comms_source.goods == nil then
                                            comms_source.goods = {}
                                        end
                                        if comms_source.goods[good] == nil then
                                            comms_source.goods[good] = 0
                                        end
                                        comms_source.goods[good] = comms_source.goods[good]
                                            + 1
                                        comms_target.comms_data.goods[good].quantity = comms_target.comms_data.goods[good].quantity
                                            - 1
                                        setCommsMessage(
                                            _("trade-comms", "Purchased")
                                        )
                                    else
                                        setCommsMessage(
                                            _(
                                                "needRep-comms",
                                                "Insufficient reputation for purchase"
                                            )
                                        )
                                    end
                                end
                            )
                        end --freighter has good and there's room on the player's ship
                    end --freighter goods list loop
                end --different freighter types
            end --ship under 5 units away
        elseif comms_target.comms_data.friendlyness > 33 then
            setCommsMessage(_("shipAssist-comms", "What do you want?"))
            -- Offer to sell destination information
            local destRep = math.floor(random(1, 5))
            addCommsReply(
                string.format(
                    _(
                        "trade-comms",
                        "Where are you headed? (cost: %f reputation)"
                    ),
                    destRep
                ),
                function()
                    if not comms_source:takeReputationPoints(destRep) then
                        setCommsMessage(
                            _("needRep-comms", "Insufficient reputation")
                        )
                    else
                        setCommsMessage(comms_target.target:getCallSign())
                    end
                    addCommsReply(_("Back"), altShipComms)
                end
            )
            -- Offer to sell goods if goods or equipment freighter
            if comms_source == nil then
                print("comms_source 3 is nil")
            end
            if comms_target == nil then
                print("comms_target 3 is nil")
            end
            local x1, y1 = comms_source:getPosition()
            local x2, y2 = comms_target:getPosition()
            if distance(x1, y1, x2, y2) < 5000 then
                if comms_source.cargo < 1 then
                    addCommsReply(_("trade-comms", "Jettison cargo"), function()
                        setCommsMessage(
                            _("trade-comms", "What would you like to jettison?")
                        )
                        for good, good_quantity in pairs(comms_source.goods) do
                            if good_quantity > 0 then
                                addCommsReply(good, function()
                                    comms_source.goods[good] = comms_source.goods[good]
                                        - 1
                                    comms_source.cargo = comms_source.cargo + 1
                                    setCommsMessage(
                                        string.format(
                                            _(
                                                "trade-comms",
                                                "One %s jettisoned"
                                            ),
                                            good
                                        )
                                    )
                                    addCommsReply(_("Back"), altShipComms)
                                end)
                            end
                        end
                        addCommsReply(_("Back"), altShipComms)
                    end)
                end
                if
                    shipType:find("Goods") ~= nil
                    or shipType:find("Equipment") ~= nil
                then
                    for good, good_data in pairs(comms_target.comms_data.goods) do
                        if
                            good_data.quantity > 0
                            and comms_source.cargo > 0
                        then
                            addCommsReply(
                                string.format(
                                    _(
                                        "trade-comms",
                                        "Buy one %s for %i reputation"
                                    ),
                                    good,
                                    good_data.cost
                                ),
                                function()
                                    if
                                        comms_source:takeReputationPoints(
                                            good_data.cost
                                        )
                                    then
                                        comms_source.cargo = comms_source.cargo
                                            - 1
                                        if comms_source.goods == nil then
                                            comms_source.goods = {}
                                        end
                                        if comms_source.goods[good] == nil then
                                            comms_source.goods[good] = 0
                                        end
                                        comms_source.goods[good] = comms_source.goods[good]
                                            + 1
                                        good_data["quantity"] = good_data["quantity"]
                                            - 1
                                        setCommsMessage(
                                            _("trade-comms", "Purchased")
                                        )
                                    else
                                        setCommsMessage(
                                            _(
                                                "needRep-comms",
                                                "Insufficient reputation for purchase"
                                            )
                                        )
                                    end
                                end
                            )
                        end
                    end
                else --not goods or equipment type freighter
                    -- Offer to sell goods double price
                    for good, good_data in pairs(comms_target.comms_data.goods) do
                        if
                            good_data.quantity > 0
                            and comms_source.cargo > 0
                        then
                            addCommsReply(
                                string.format(
                                    _(
                                        "trade-comms",
                                        "Buy one %s for %i reputation"
                                    ),
                                    good,
                                    good_data.cost * 2
                                ),
                                function()
                                    if
                                        comms_source:takeReputationPoints(
                                            good_data.cost * 2
                                        )
                                    then
                                        comms_source.cargo = comms_source.cargo
                                            - 1
                                        if comms_source.goods == nil then
                                            comms_source.goods = {}
                                        end
                                        if comms_source.goods[good] == nil then
                                            comms_source.goods[good] = 0
                                        end
                                        comms_source.goods[good] = comms_source.goods[good]
                                            + 1
                                        comms_target.comms_data.goods[good].quantity = comms_target.comms_data.goods[good].quantity
                                            - 1
                                        setCommsMessage(
                                            _("trade-comms", "Purchased")
                                        )
                                    else
                                        setCommsMessage(
                                            _(
                                                "needRep-comms",
                                                "Insufficient reputation for purchase"
                                            )
                                        )
                                    end
                                end
                            )
                        end --freighter has some of the good and there's room on the player's ship
                    end --loop through freighter good list
                end --types of freighters
            end --freighter in range (< 5U)
        else --least friendly branch
            setCommsMessage(_("trade-comms", "Why are you bothering me?"))
            -- Offer to sell goods if goods or equipment freighter double price
            if comms_source == nil then
                print("comms_source 4 is nil")
            end
            if comms_target == nil then
                print("comms_target 4 is nil")
            end
            local x1, y1 = comms_source:getPosition()
            local x2, y2 = comms_target:getPosition()
            if distance(x1, y1, x2, y2) < 5000 then
                if comms_source.cargo < 1 then
                    addCommsReply(_("trade-comms", "Jettison cargo"), function()
                        setCommsMessage(
                            _("trade-comms", "What would you like to jettison?")
                        )
                        for good, good_quantity in pairs(comms_source.goods) do
                            if good_quantity > 0 then
                                addCommsReply(good, function()
                                    comms_source.goods[good] = comms_source.goods[good]
                                        - 1
                                    comms_source.cargo = comms_source.cargo + 1
                                    setCommsMessage(
                                        string.format(
                                            _(
                                                "trade-comms",
                                                "One %s jettisoned"
                                            ),
                                            good
                                        )
                                    )
                                    addCommsReply(_("Back"), altShipComms)
                                end)
                            end
                        end
                        addCommsReply(_("Back"), altShipComms)
                    end)
                end
                if
                    shipType:find("Goods") ~= nil
                    or shipType:find("Equipment") ~= nil
                then
                    for good, good_data in pairs(comms_target.comms_data.goods) do
                        if
                            good_data.quantity > 0
                            and comms_source.cargo > 0
                        then
                            addCommsReply(
                                string.format(
                                    _(
                                        "trade-comms",
                                        "Buy one %s for %i reputation"
                                    ),
                                    good,
                                    good_data.cost * 2
                                ),
                                function()
                                    if
                                        comms_source:takeReputationPoints(
                                            good_data.cost * 2
                                        )
                                    then
                                        comms_source.cargo = comms_source.cargo
                                            - 1
                                        if comms_source.goods == nil then
                                            comms_source.goods = {}
                                        end
                                        if comms_source.goods[good] == nil then
                                            comms_source.goods[good] = 0
                                        end
                                        comms_source.goods[good] = comms_source.goods[good]
                                            + 1
                                        comms_target.comms_data.goods[good].quantity = comms_target.comms_data.goods[good].quantity
                                            - 1
                                        setCommsMessage(
                                            _("trade-comms", "Purchased")
                                        )
                                    else
                                        setCommsMessage(
                                            _(
                                                "needRep-comms",
                                                "Insufficient reputation for purchase"
                                            )
                                        )
                                    end
                                end
                            )
                        end
                    end
                end
            end
        end --friendly branches
        neutralFriendlyFreighterComms()
    end
end
function altFriendlyShipComms()
    local shipType = comms_target:getTypeName()
    if shipType:find("Freighter") ~= nil then
        friendlyFreighterComms()
    else
        addCommsReply(_("shipAssist-comms", "Defend a waypoint"), function()
            if comms_source:getWaypointCount() == 0 then
                setCommsMessage(
                    _(
                        "shipAssist-comms",
                        "No waypoints set. Please set a waypoint first."
                    )
                )
                addCommsReply(_("Back"), altShipComms)
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
                            local p = getPlayerShip(-1)
                            if
                                p ~= nil
                                and p:isValid()
                                and p:isFriendly(comms_target)
                            then
                                local temp_faction = comms_target:getFaction()
                                comms_target:setFaction("Independent")
                                comms_target:orderDefendLocation(
                                    comms_source:getWaypoint(n)
                                )
                                comms_target:setFaction(temp_faction)
                            else
                                comms_target:orderDefendLocation(
                                    comms_source:getWaypoint(n)
                                )
                            end
                            setCommsMessage(
                                string.format(
                                    _(
                                        "shipAssist-comms",
                                        "We are heading to assist at WP %d."
                                    ),
                                    comms_source:getWaypointID(n)
                                )
                            )
                            addCommsReply(_("Back"), altShipComms)
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
                local p = getPlayerShip(-1)
                if p ~= nil and p:isValid() and p:isFriendly(comms_target) then
                    local temp_faction = comms_target:getFaction()
                    comms_target:setFaction("Independent")
                    comms_target:orderDefendTarget(comms_source)
                    comms_target:setFaction(temp_faction)
                else
                    comms_target:orderDefendTarget(comms_source)
                end
                addCommsReply(_("Back"), altShipComms)
            end)
        end
        addCommsReply(_("shipAssist-comms", "Report status"), function()
            local msg = string.format(
                _("shipAssist-comms", "Hull: %d%%\n"),
                comms_target:getHullPercentage()
            )
            shields = comms_target:getShieldCount()
            if shields == 1 then
                msg = msg
                    .. string.format(
                        _("shipAssist-comms", "Shield: %d%%\n"),
                        math.floor(
                            comms_target:getShieldLevel(0)
                                / comms_target:getShieldMax(0)
                                * 100
                        )
                    )
            elseif shields == 2 then
                msg = msg
                    .. string.format(
                        _("shipAssist-comms", "Front Shield: %d%%\n"),
                        math.floor(
                            comms_target:getShieldLevel(0)
                                / comms_target:getShieldMax(0)
                                * 100
                        )
                    )
                msg = msg
                    .. string.format(
                        _("shipAssist-comms", "Rear Shield: %d%%\n"),
                        math.floor(
                            comms_target:getShieldLevel(1)
                                / comms_target:getShieldMax(1)
                                * 100
                        )
                    )
            else
                for n = 0, shields - 1 do
                    msg = msg
                        .. string.format(
                            _("shipAssist-comms", "Shield %s: %d%%\n"),
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
                    msg = msg
                        .. string.format(
                            _("shipAssist-comms", "%s Missiles: %d/%d\n"),
                            missile_type,
                            math.floor(
                                comms_target:getWeaponStorage(missile_type)
                            ),
                            math.floor(
                                comms_target:getWeaponStorageMax(missile_type)
                            )
                        )
                end
            end
            setCommsMessage(msg)
            addCommsReply(_("Back"), altShipComms)
        end)
        for idx, obj in ipairs(comms_target:getObjectsInRange(5000)) do
            if
                isObjectType(obj, "SpaceStation")
                and not comms_target:isEnemy(obj)
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
                        local p = getPlayerShip(-1)
                        if
                            p ~= nil
                            and p:isValid()
                            and p:isFriendly(comms_target)
                        then
                            local temp_faction = comms_target:getFaction()
                            comms_target:setFaction("Independent")
                            comms_target:orderDock(obj)
                            comms_target:setFaction(temp_faction)
                        else
                            comms_target:orderDock(obj)
                        end
                        addCommsReply(_("Back"), altShipComms)
                    end
                )
            end
        end
    end
    addCommsReply(_("Back"), altShipComms)
    return true
end
function friendlyComms(comms_data)
    if comms_data.friendlyness < 20 then
        setCommsMessage(_("shipAssist-comms", "What do you want?"))
    else
        setCommsMessage(_("shipAssist-comms", "Sir, how can we assist?"))
    end
    if shipType:find("Freighter") ~= nil then
        if comms_data.friendlyness > 66 then
            setCommsMessage(_("trade-comms", "Yes?"))
            addCommsReply(
                _("trade-comms", "Do you have cargo you might sell?"),
                function()
                    local goodCount = 0
                    local cargoMsg = _("trade-comms", "We've got ")
                    for good, goodData in pairs(comms_data.goods) do
                        if goodData.quantity > 0 then
                            if goodCount > 0 then
                                cargoMsg = cargoMsg
                                    .. _("trade-comms", ", ")
                                    .. good
                            else
                                cargoMsg = cargoMsg .. good
                            end
                        end
                        goodCount = goodCount + goodData.quantity
                    end --freighter goods list loop
                    if goodCount == 0 then
                        cargoMsg = cargoMsg .. _("trade-comms", "nothing")
                    end
                    setCommsMessage(cargoMsg)
                end
            )
            -- Offer destination information
            addCommsReply(_("trade-comms", "Where are you headed?"), function()
                setCommsMessage(comms_target.target:getCallSign())
                addCommsReply(_("Back"), altShipComms)
            end)
            -- Offer to trade goods if goods or equipment freighter
            if comms_source == nil then
                print("comms_source 2 is nil")
            end
            if comms_target == nil then
                print("comms_target 2 is nil")
            end
            local x1, y1 = comms_source:getPosition()
            local x2, y2 = comms_target:getPosition()
            if distance(x1, y1, x2, y2) < 5000 then
                if
                    shipType:find("Goods") ~= nil
                    or shipType:find("Equipment") ~= nil
                then
                    if comms_source.goods == nil then
                        comms_source.goods = {}
                    end
                    if comms_source.goods["luxury"] == nil then
                        comms_source.goods["luxury"] = 0
                    end
                    if comms_source.goods["luxury"] > 0 then
                        for good, good_data in pairs(comms_data.goods) do
                            if good_data.quantity > 0 then
                                addCommsReply(
                                    string.format(
                                        _("trade-comms", "Trade luxury for %s"),
                                        good
                                    ),
                                    function()
                                        comms_data.goods.good.quantity = comms_data.goods.good.quantity
                                            - 1
                                        comms_source.goods["luxury"] = comms_source.goods["luxury"]
                                            - 1
                                        if comms_source.goods[good] == nil then
                                            comms_source.goods[good] = 0
                                        end
                                        comms_source.goods[good] = comms_source.goods[good]
                                            + 1
                                        setCommsMessage(
                                            _("trade-comms", "Traded")
                                        )
                                        addCommsReply(_("Back"), altShipComms)
                                    end
                                )
                            end
                        end
                    end --player has luxury
                else --not a goods or equipment freighter
                    if comms_source.cargo < 1 then
                        addCommsReply(
                            _("trade-comms", "Jettison cargo"),
                            function()
                                setCommsMessage(
                                    _(
                                        "trade-comms",
                                        "What would you like to jettison?"
                                    )
                                )
                                for good, good_quantity in
                                    pairs(comms_source.goods)
                                do
                                    if good_quantity > 0 then
                                        addCommsReply(good, function()
                                            comms_source.goods[good] = comms_source.goods[good]
                                                - 1
                                            comms_source.cargo = comms_source.cargo
                                                + 1
                                            setCommsMessage(
                                                string.format(
                                                    _(
                                                        "trade-comms",
                                                        "One %s jettisoned"
                                                    ),
                                                    good
                                                )
                                            )
                                            addCommsReply(
                                                _("Back"),
                                                altShipComms
                                            )
                                        end)
                                    end
                                end
                                addCommsReply(_("Back"), altShipComms)
                            end
                        )
                    end
                    -- Offer to sell goods
                    for good, good_data in pairs(comms_data.goods) do
                        if
                            good_data.quantity > 0
                            and comms_source.cargo > 0
                        then
                            addCommsReply(
                                string.format(
                                    _(
                                        "trade-comms",
                                        "Buy one %s for %i reputation"
                                    ),
                                    good,
                                    good_data.cost
                                ),
                                function()
                                    if
                                        comms_source:takeReputationPoints(
                                            good_data.cost
                                        )
                                    then
                                        comms_source.cargo = comms_source.cargo
                                            - 1
                                        if comms_source.goods == nil then
                                            comms_source.goods = {}
                                        end
                                        if comms_source.goods[good] == nil then
                                            comms_source.goods[good] = 0
                                        end
                                        comms_source.goods[good] = comms_source.goods[good]
                                            + 1
                                        comms_data.goods[good].quantity = comms_data.goods[good].quantity
                                            - 1
                                        setCommsMessage(
                                            _("trade-comms", "Purchased")
                                        )
                                    else
                                        setCommsMessage(
                                            _(
                                                "needRep-comms",
                                                "Insufficient reputation for purchase"
                                            )
                                        )
                                    end
                                end
                            )
                        end --freighter has good and there's room on the player's ship
                    end --freighter goods list loop
                end --different freighter types
            end --ship under 5 units away
        elseif comms_data.friendlyness > 33 then
            setCommsMessage(_("shipAssist-comms", "What do you want?"))
            -- Offer to sell destination information
            local destRep = random(1, 5)
            addCommsReply(
                string.format(
                    _(
                        "trade-comms",
                        "Where are you headed? (cost: %f reputation)"
                    ),
                    destRep
                ),
                function()
                    if not comms_source:takeReputationPoints(destRep) then
                        setCommsMessage(
                            _("needRep-comms", "Insufficient reputation")
                        )
                    else
                        setCommsMessage(comms_target.target:getCallSign())
                    end
                    addCommsReply(_("Back"), altShipComms)
                end
            )
            -- Offer to sell goods if goods or equipment freighter
            if comms_source == nil then
                print("comms_source 3 is nil")
            end
            if comms_target == nil then
                print("comms_target 3 is nil")
            end
            local x1, y1 = comms_source:getPosition()
            local x2, y2 = comms_target:getPosition()
            if distance(x1, y1, x2, y2) < 5000 then
                if comms_source.cargo < 1 then
                    addCommsReply(_("trade-comms", "Jettison cargo"), function()
                        setCommsMessage(
                            _("trade-comms", "What would you like to jettison?")
                        )
                        for good, good_quantity in pairs(comms_source.goods) do
                            if good_quantity > 0 then
                                addCommsReply(good, function()
                                    comms_source.goods[good] = comms_source.goods[good]
                                        - 1
                                    comms_source.cargo = comms_source.cargo + 1
                                    setCommsMessage(
                                        string.format(
                                            _(
                                                "trade-comms",
                                                "One %s jettisoned"
                                            ),
                                            good
                                        )
                                    )
                                    addCommsReply(_("Back"), altShipComms)
                                end)
                            end
                        end
                        addCommsReply(_("Back"), altShipComms)
                    end)
                end
                if
                    shipType:find("Goods") ~= nil
                    or shipType:find("Equipment") ~= nil
                then
                    for good, good_data in pairs(comms_data.goods) do
                        if
                            good_data.quantity > 0
                            and comms_source.cargo > 0
                        then
                            addCommsReply(
                                string.format(
                                    _(
                                        "trade-comms",
                                        "Buy one %s for %i reputation"
                                    ),
                                    good,
                                    good_data.cost
                                ),
                                function()
                                    if
                                        comms_source:takeReputationPoints(
                                            good_data.cost
                                        )
                                    then
                                        comms_source.cargo = comms_source.cargo
                                            - 1
                                        if comms_source.goods == nil then
                                            comms_source.goods = {}
                                        end
                                        if comms_source.goods[good] == nil then
                                            comms_source.goods[good] = 0
                                        end
                                        comms_source.goods[good] = comms_source.goods[good]
                                            + 1
                                        good_data["quantity"] = good_data["quantity"]
                                            - 1
                                        setCommsMessage(
                                            _("trade-comms", "Purchased")
                                        )
                                    else
                                        setCommsMessage(
                                            _(
                                                "needRep-comms",
                                                "Insufficient reputation for purchase"
                                            )
                                        )
                                    end
                                end
                            )
                        end
                    end
                else --not goods or equipment type freighter
                    -- Offer to sell goods double price
                    for good, good_data in pairs(comms_data.goods) do
                        if
                            good_data.quantity > 0
                            and comms_source.cargo > 0
                        then
                            addCommsReply(
                                string.format(
                                    _(
                                        "trade-comms",
                                        "Buy one %s for %i reputation"
                                    ),
                                    good,
                                    good_data.cost * 2
                                ),
                                function()
                                    if
                                        comms_source:takeReputationPoints(
                                            good_data.cost * 2
                                        )
                                    then
                                        comms_source.cargo = comms_source.cargo
                                            - 1
                                        if comms_source.goods == nil then
                                            comms_source.goods = {}
                                        end
                                        if comms_source.goods[good] == nil then
                                            comms_source.goods[good] = 0
                                        end
                                        comms_source.goods[good] = comms_source.goods[good]
                                            + 1
                                        comms_data.goods[good].quantity = comms_data.goods[good].quantity
                                            - 1
                                        setCommsMessage(
                                            _("trade-comms", "Purchased")
                                        )
                                    else
                                        setCommsMessage(
                                            _(
                                                "needRep-comms",
                                                "Insufficient reputation for purchase"
                                            )
                                        )
                                    end
                                end
                            )
                        end --freighter has some of the good and there's room on the player's ship
                    end --loop through freighter good list
                end --types of freighters
            end --freighter in range (< 5U)
        else --least friendly branch
            setCommsMessage(_("trade-comms", "Why are you bothering me?"))
            -- Offer to sell goods if goods or equipment freighter double price
            if comms_source == nil then
                print("comms_source 4 is nil")
            end
            if comms_target == nil then
                print("comms_target 4 is nil")
            end
            local x1, y1 = comms_source:getPosition()
            local x2, y2 = comms_target:getPosition()
            if distance(x1, y1, x2, y2) < 5000 then
                if comms_source.cargo < 1 then
                    addCommsReply(_("trade-comms", "Jettison cargo"), function()
                        setCommsMessage(
                            _("trade-comms", "What would you like to jettison?")
                        )
                        for good, good_quantity in pairs(comms_source.goods) do
                            if good_quantity > 0 then
                                addCommsReply(good, function()
                                    comms_source.goods[good] = comms_source.goods[good]
                                        - 1
                                    comms_source.cargo = comms_source.cargo + 1
                                    setCommsMessage(
                                        string.format(
                                            _(
                                                "trade-comms",
                                                "One %s jettisoned"
                                            ),
                                            good
                                        )
                                    )
                                    addCommsReply(_("Back"), altShipComms)
                                end)
                            end
                        end
                        addCommsReply(_("Back"), altShipComms)
                    end)
                end
                if
                    shipType:find("Goods") ~= nil
                    or shipType:find("Equipment") ~= nil
                then
                    for good, good_data in pairs(comms_data.goods) do
                        if
                            good_data.quantity > 0
                            and comms_source.cargo > 0
                        then
                            addCommsReply(
                                string.format(
                                    _(
                                        "trade-comms",
                                        "Buy one %s for %i reputation"
                                    ),
                                    good,
                                    good_data.cost * 2
                                ),
                                function()
                                    if
                                        comms_source:takeReputationPoints(
                                            good_data.cost * 2
                                        )
                                    then
                                        comms_source.cargo = comms_source.cargo
                                            - 1
                                        if comms_source.goods == nil then
                                            comms_source.goods = {}
                                        end
                                        if comms_source.goods[good] == nil then
                                            comms_source.goods[good] = 0
                                        end
                                        comms_source.goods[good] = comms_source.goods[good]
                                            + 1
                                        comms_data.goods[good].quantity = comms_data.goods[good].quantity
                                            - 1
                                        setCommsMessage(
                                            _("trade-comms", "Purchased")
                                        )
                                    else
                                        setCommsMessage(
                                            _(
                                                "needRep-comms",
                                                "Insufficient reputation for purchase"
                                            )
                                        )
                                    end
                                end
                            )
                        end
                    end
                end
            end
        end --friendly branches
        if undercutLocation == "transport" then
            if comms_source == nil then
                print("comms_source 5 is nil")
            end
            if comms_target == nil then
                print("comms_target 5 is nil")
            end
            if distanceDiagnostic then
                print(
                    "Distance diagnostic 5: comms_source:",
                    comms_source:getCallSign(),
                    "comms_target:",
                    comms_target:getCallSign()
                )
            end
            if distance(comms_source, comms_target) < 5000 then
                if comms_target == hideTransport then
                    addCommsReply(
                        _(
                            "Undercut2-comms",
                            "I need to talk to Charles Undercut"
                        ),
                        function()
                            setCommsMessage(
                                _(
                                    "Undercut2-comms",
                                    "[Charles Undercut] Haven't you destroyed my life enough?"
                                )
                            )
                            addCommsReply(
                                _(
                                    "Undercut2-comms",
                                    "We need the information you obtained about enemies in this region"
                                ),
                                function()
                                    setCommsMessage(
                                        _(
                                            "Undercut2-comms",
                                            "That will cost you something more than just pretty words. Got any luxury, gold or platinum goods?"
                                        )
                                    )
                                    if comms_source.goods ~= nil then
                                        if
                                            comms_source.goods["luxury"]
                                                ~= nil
                                            and comms_source.goods["luxury"]
                                                > 0
                                        then
                                            addCommsReply(
                                                _(
                                                    "Undercut2-comms",
                                                    "Trade luxury for information"
                                                ),
                                                function()
                                                    comms_source.goods["luxury"] = comms_source.goods["luxury"]
                                                        - 1
                                                    comms_source.cargo = comms_source.cargo
                                                        + 1
                                                    if
                                                        stationGanalda:isValid()
                                                    then
                                                        undercutTarget =
                                                            stationGanalda
                                                    elseif
                                                        stationEmpok:isValid()
                                                    then
                                                        undercutTarget =
                                                            stationEmpok
                                                    else
                                                        undercutTarget =
                                                            stationTic
                                                    end
                                                    comms_source:addToShipLog(
                                                        string.format(
                                                            _(
                                                                "Undercut2-shipLog",
                                                                "enemy base identified in sector %s"
                                                            ),
                                                            undercutTarget:getSectorName()
                                                        ),
                                                        "Magenta"
                                                    )
                                                    setCommsMessage(
                                                        string.format(
                                                            _(
                                                                "Undercut2-comms",
                                                                "I found an enemy base in sector %s"
                                                            ),
                                                            undercutTarget:getSectorName()
                                                        )
                                                    )
                                                    undercutLocation = "free"
                                                end
                                            )
                                        end
                                        if
                                            comms_source.goods["gold"]
                                                ~= nil
                                            and comms_source.goods["gold"]
                                                > 0
                                        then
                                            addCommsReply(
                                                _(
                                                    "Undercut2-comms",
                                                    "Trade gold for information"
                                                ),
                                                function()
                                                    comms_source.goods["gold"] = comms_source.goods["gold"]
                                                        - 1
                                                    comms_source.cargo = comms_source.cargo
                                                        + 1
                                                    if
                                                        stationGanalda:isValid()
                                                    then
                                                        undercutTarget =
                                                            stationGanalda
                                                    elseif
                                                        stationEmpok:isValid()
                                                    then
                                                        undercutTarget =
                                                            stationEmpok
                                                    else
                                                        undercutTarget =
                                                            stationTic
                                                    end
                                                    comms_source:addToShipLog(
                                                        string.format(
                                                            _(
                                                                "Undercut2-shipLog",
                                                                "enemy base identified in sector %s"
                                                            ),
                                                            undercutTarget:getSectorName()
                                                        ),
                                                        "Magenta"
                                                    )
                                                    setCommsMessage(
                                                        string.format(
                                                            _(
                                                                "Undercut2-comms",
                                                                "I found an enemy base in sector %s"
                                                            ),
                                                            undercutTarget:getSectorName()
                                                        )
                                                    )
                                                    undercutLocation = "free"
                                                end
                                            )
                                        end
                                        if
                                            comms_source.goods["platinum"]
                                                ~= nil
                                            and comms_source.goods["platinum"]
                                                > 0
                                        then
                                            addCommsReply(
                                                _(
                                                    "Undercut2-comms",
                                                    "Trade platinum for information"
                                                ),
                                                function()
                                                    comms_source.goods["platinum"] = comms_source.goods["platinum"]
                                                        - 1
                                                    comms_source.cargo = comms_source.cargo
                                                        + 1
                                                    if
                                                        stationGanalda:isValid()
                                                    then
                                                        undercutTarget =
                                                            stationGanalda
                                                    elseif
                                                        stationEmpok:isValid()
                                                    then
                                                        undercutTarget =
                                                            stationEmpok
                                                    else
                                                        undercutTarget =
                                                            stationTic
                                                    end
                                                    comms_source:addToShipLog(
                                                        string.format(
                                                            _(
                                                                "Undercut2-shipLog",
                                                                "enemy base identified in sector %s"
                                                            ),
                                                            undercutTarget:getSectorName()
                                                        ),
                                                        "Magenta"
                                                    )
                                                    setCommsMessage(
                                                        string.format(
                                                            _(
                                                                "Undercut2-comms",
                                                                "I found an enemy base in sector %s"
                                                            ),
                                                            undercutTarget:getSectorName()
                                                        )
                                                    )
                                                    undercutLocation = "free"
                                                end
                                            )
                                        end
                                    end
                                    addCommsReply(_("Back"), altShipComms)
                                end
                            )
                            addCommsReply(_("Back"), altShipComms)
                        end
                    )
                end
            end
        end
        if plotR == sporiskyTransport then
            if comms_target == runTransport then
                if comms_source == nil then
                    print("comms_source 6 is nil")
                end
                if comms_target == nil then
                    print("comms_target 6 is nil")
                end
                local x1, y1 = comms_source:getPosition()
                local x2, y2 = comms_target:getPosition()
                if distance(x1, y1, x2, y2) < 5000 then
                    if sporiskyLocation ~= "aboard ship" then
                        addCommsReply(
                            _(
                                "Undercut2-comms",
                                "We need you to hand over Annette Sporisky"
                            ),
                            function()
                                local asMsg = _(
                                    "Undercut2-comms",
                                    "Why should we? Despite what you may have heard, she is not related to this freighter's owner. "
                                )
                                asMsg = asMsg
                                    .. _(
                                        "Undercut2-comms",
                                        "However, she's obviously valuable. I'll hand her over for something I can trade, "
                                    )
                                asMsg = asMsg
                                    .. _(
                                        "Undercut2-comms",
                                        "one of the following types of goods: "
                                    )
                                if as1part == nil then
                                    local as1choice = math.floor(random(1, 3))
                                    if as1choice == 1 then
                                        as1part = "dilithium"
                                    elseif as1choice == 2 then
                                        as1part = "platinum"
                                    else
                                        as1part = "gold"
                                    end
                                end
                                if as2part == nil then
                                    local as2choice = math.floor(random(1, 3))
                                    if as2choice == 1 then
                                        as2part = "nanites"
                                    elseif as2choice == 2 then
                                        as2part = "impulse"
                                    else
                                        as2part = "communication"
                                    end
                                end
                                if as3part == nil then
                                    local as3choice = math.floor(random(1, 3))
                                    if as3choice == 1 then
                                        as3part = "optic"
                                    elseif as3choice == 2 then
                                        as3part = "lifter"
                                    else
                                        as3part = "filament"
                                    end
                                end
                                asMsg = asMsg
                                    .. as1part
                                    .. ", "
                                    .. as2part
                                    .. _("Undercut2-comms", " or ")
                                    .. as3part
                                setCommsMessage(asMsg)
                                if comms_source.goods ~= nil then
                                    if
                                        comms_source.goods[as1part] ~= nil
                                        and comms_source.goods[as1part] > 0
                                    then
                                        addCommsReply(
                                            string.format(
                                                _(
                                                    "Undercut2-comms",
                                                    "Trade %s for Annette Sporisky"
                                                ),
                                                as1part
                                            ),
                                            function()
                                                comms_source.goods[as1part] = comms_source.goods[as1part]
                                                    - 1
                                                comms_source.cargo = comms_source.cargo
                                                    + 1
                                                comms_source.traitorBought =
                                                    true
                                                comms_source:addToShipLog(
                                                    _(
                                                        "Undercut2-comms",
                                                        "Annette Sporisky aboard"
                                                    ),
                                                    "Magenta"
                                                )
                                                setCommsMessage(
                                                    _("trade-comms", "Traded")
                                                )
                                                sporiskyTarget = stationGanalda
                                                sporiskyLocation = "aboard ship"
                                            end
                                        )
                                    end
                                    if
                                        comms_source.goods[as2part] ~= nil
                                        and comms_source.goods[as2part] > 0
                                    then
                                        addCommsReply(
                                            string.format(
                                                _(
                                                    "Undercut2-comms",
                                                    "Trade %s for Annette Sporisky"
                                                ),
                                                as2part
                                            ),
                                            function()
                                                comms_source.goods[as2part] = comms_source.goods[as2part]
                                                    - 1
                                                comms_source.cargo = comms_source.cargo
                                                    + 1
                                                comms_source.traitorBought =
                                                    true
                                                comms_source:addToShipLog(
                                                    _(
                                                        "Undercut2-comms",
                                                        "Annette Sporisky aboard"
                                                    ),
                                                    "Magenta"
                                                )
                                                setCommsMessage(
                                                    _("trade-comms", "Traded")
                                                )
                                                sporiskyTarget = stationEmpok
                                                sporiskyLocation = "aboard ship"
                                            end
                                        )
                                    end
                                    if
                                        comms_source.goods[as3part] ~= nil
                                        and comms_source.goods[as3part] > 0
                                    then
                                        addCommsReply(
                                            string.format(
                                                _(
                                                    "Undercut2-comms",
                                                    "Trade %s for Annette Sporisky"
                                                ),
                                                as3part
                                            ),
                                            function()
                                                comms_source.goods[as3part] = comms_source.goods[as3part]
                                                    - 1
                                                comms_source.cargo = comms_source.cargo
                                                    + 1
                                                comms_source.traitorBought =
                                                    true
                                                comms_source:addToShipLog(
                                                    _(
                                                        "Undercut2-comms",
                                                        "Annette Sporisky aboard"
                                                    ),
                                                    "Magenta"
                                                )
                                                setCommsMessage(
                                                    _("trade-comms", "Traded")
                                                )
                                                sporiskyTarget = stationTic
                                                sporiskyLocation = "aboard ship"
                                            end
                                        )
                                    end
                                end
                                addCommsReply(_("Back"), altShipComms)
                            end
                        )
                    end
                end
            end
        end
    else
        addCommsReply(_("shipAssist-comms", "Defend a waypoint"), function()
            if comms_source:getWaypointCount() == 0 then
                setCommsMessage(
                    _(
                        "shipAssist-comms",
                        "No waypoints set. Please set a waypoint first."
                    )
                )
                addCommsReply(_("Back"), altShipComms)
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
                            local p = getPlayerShip(-1)
                            if
                                p ~= nil
                                and p:isValid()
                                and p:isFriendly(comms_target)
                            then
                                local temp_faction = comms_target:getFaction()
                                comms_target:setFaction("Independent")
                                comms_target:orderDefendLocation(
                                    comms_source:getWaypoint(n)
                                )
                                comms_target:setFaction(temp_faction)
                            else
                                comms_target:orderDefendLocation(
                                    comms_source:getWaypoint(n)
                                )
                            end
                            setCommsMessage(
                                string.format(
                                    _(
                                        "shipAssist-comms",
                                        "We are heading to assist at WP %d."
                                    ),
                                    comms_source:getWaypointID(n)
                                )
                            )
                            addCommsReply(_("Back"), altShipComms)
                        end
                    )
                end
            end
        end)
        if comms_data.friendlyness > 0.2 then
            addCommsReply(_("shipAssist-comms", "Assist me"), function()
                setCommsMessage(
                    _("shipAssist-comms", "Heading toward you to assist.")
                )
                local p = getPlayerShip(-1)
                if p ~= nil and p:isValid() and p:isFriendly(comms_target) then
                    local temp_faction = comms_target:getFaction()
                    comms_target:setFaction("Independent")
                    comms_target:orderDefendTarget(comms_source)
                    comms_target:setFaction(temp_faction)
                else
                    comms_target:orderDefendTarget(comms_source)
                end
                addCommsReply(_("Back"), altShipComms)
            end)
        end
        addCommsReply(_("shipAssist-comms", "Report status"), function()
            local msg = string.format(
                _("shipAssist-comms", "Hull: %d%%\n"),
                comms_target:getHullPercentage()
            )
            shields = comms_target:getShieldCount()
            if shields == 1 then
                msg = msg
                    .. string.format(
                        _("shipAssist-comms", "Shield: %d%%\n"),
                        math.floor(
                            comms_target:getShieldLevel(0)
                                / comms_target:getShieldMax(0)
                                * 100
                        )
                    )
            elseif shields == 2 then
                msg = msg
                    .. string.format(
                        _("shipAssist-comms", "Front Shield: %d%%\n"),
                        math.floor(
                            comms_target:getShieldLevel(0)
                                / comms_target:getShieldMax(0)
                                * 100
                        )
                    )
                msg = msg
                    .. string.format(
                        _("shipAssist-comms", "Rear Shield: %d%%\n"),
                        math.floor(
                            comms_target:getShieldLevel(1)
                                / comms_target:getShieldMax(1)
                                * 100
                        )
                    )
            else
                for n = 0, shields - 1 do
                    msg = msg
                        .. string.format(
                            _("shipAssist-comms", "Shield %s: %d%%\n"),
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
                    msg = msg
                        .. string.format(
                            _("shipAssist-comms", "%s Missiles: %d/%d\n"),
                            missile_type,
                            math.floor(
                                comms_target:getWeaponStorage(missile_type)
                            ),
                            math.floor(
                                comms_target:getWeaponStorageMax(missile_type)
                            )
                        )
                end
            end
            setCommsMessage(msg)
            addCommsReply(_("Back"), altShipComms)
        end)
        for idx, obj in ipairs(comms_target:getObjectsInRange(5000)) do
            if
                isObjectType(obj, "SpaceStation")
                and not comms_target:isEnemy(obj)
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
                        local p = getPlayerShip(-1)
                        if
                            p ~= nil
                            and p:isValid()
                            and p:isFriendly(comms_target)
                        then
                            local temp_faction = comms_target:getFaction()
                            comms_target:setFaction("Independent")
                            comms_target:orderDock(obj)
                            comms_target:setFaction(temp_faction)
                        else
                            comms_target:orderDock(obj)
                        end
                        addCommsReply(_("Back"), altShipComms)
                    end
                )
            end
        end
    end
    return true
end
function enemyComms(comms_data)
    if comms_data.friendlyness > 50 then
        local faction = comms_target:getFaction()
        local taunt_option =
            _("shipEnemy-comms", "We will see to your destruction!")
        local taunt_success_reply =
            _("shipEnemy-comms", "Your bloodline will end here!")
        local taunt_failed_reply =
            _("shipEnemy-comms", "Your feeble threats are meaningless.")
        if faction == "Kraylor" then
            setCommsMessage(
                _("shipEnemy-comms", "Ktzzzsss.\nYou will DIEEee weaklingsss!")
            )
        elseif faction == "Arlenians" then
            setCommsMessage(
                _(
                    "shipEnemy-comms",
                    "We wish you no harm, but will harm you if we must.\nEnd of transmission."
                )
            )
        elseif faction == "Exuari" then
            setCommsMessage(
                _(
                    "shipEnemy-comms",
                    "Stay out of our way, or your death will amuse us extremely!"
                )
            )
        elseif faction == "Ghosts" then
            setCommsMessage(
                _(
                    "shipEnemy-comms",
                    "One zero one.\nNo binary communication detected.\nSwitching to universal speech.\nGenerating appropriate response for target from human language archives.\n:Do not cross us:\nCommunication halted."
                )
            )
            taunt_option = _("shipEnemy-comms", "EXECUTE: SELFDESTRUCT")
            taunt_success_reply = _(
                "shipEnemy-comms",
                "Rogue command received. Targeting source."
            )
            taunt_failed_reply =
                _("shipEnemy-comms", "External command ignored.")
        elseif faction == "Ktlitans" then
            setCommsMessage(
                _(
                    "shipEnemy-comms",
                    "The hive suffers no threats. Opposition to any of us is opposition to us all.\nStand down or prepare to donate your corpses toward our nutrition."
                )
            )
            taunt_option = _(
                "shipEnemy-comms",
                "<Transmit 'The Itsy-Bitsy Spider' on all wavelengths>"
            )
            taunt_success_reply = _(
                "shipEnemy-comms",
                "We do not need permission to pluck apart such an insignificant threat."
            )
            taunt_failed_reply = _(
                "shipEnemy-comms",
                "The hive has greater priorities than exterminating pests."
            )
        else
            setCommsMessage(_("shipEnemy-comms", "Mind your own business!"))
        end
        comms_data.friendlyness = comms_data.friendlyness - random(0, 10)
        addCommsReply(taunt_option, function()
            if random(0, 100) < 30 then
                comms_target:orderAttack(comms_source)
                setCommsMessage(taunt_success_reply)
            else
                setCommsMessage(taunt_failed_reply)
            end
        end)
        return true
    end
    return false
end
function neutralComms(comms_data)
    local shipType = comms_target:getTypeName()
    if shipType:find("Freighter") ~= nil then
        if comms_data.friendlyness > 66 then
            setCommsMessage(_("trade-comms", "Yes?"))
            addCommsReply(
                _("trade-comms", "Do you have cargo you might sell?"),
                function()
                    local goodCount = 0
                    local cargoMsg = _("trade-comms", "We've got ")
                    for good, goodData in pairs(comms_data.goods) do
                        if goodData.quantity > 0 then
                            if goodCount > 0 then
                                cargoMsg = cargoMsg
                                    .. _("trade-comms", ", ")
                                    .. good
                            else
                                cargoMsg = cargoMsg .. good
                            end
                        end
                        goodCount = goodCount + goodData.quantity
                    end --freighter goods list loop
                    if goodCount == 0 then
                        cargoMsg = cargoMsg .. _("trade-comms", "nothing")
                    end
                    setCommsMessage(cargoMsg)
                end
            )
            -- Offer destination information
            addCommsReply(_("trade-comms", "Where are you headed?"), function()
                setCommsMessage(comms_target.target:getCallSign())
                addCommsReply(_("Back"), altShipComms)
            end)
            -- Offer to trade goods if goods or equipment freighter
            if comms_source == nil then
                print("comms_source 2 is nil")
            end
            if comms_target == nil then
                print("comms_target 2 is nil")
            end
            local x1, y1 = comms_source:getPosition()
            local x2, y2 = comms_target:getPosition()
            if distance(x1, y1, x2, y2) < 5000 then
                if
                    shipType:find("Goods") ~= nil
                    or shipType:find("Equipment") ~= nil
                then
                    if comms_source.goods == nil then
                        comms_source.goods = {}
                    end
                    if comms_source.goods["luxury"] == nil then
                        comms_source.goods["luxury"] = 0
                    end
                    if comms_source.goods["luxury"] > 0 then
                        for good, good_data in pairs(comms_data.goods) do
                            if good_data.quantity > 0 then
                                addCommsReply(
                                    string.format(
                                        _("trade-comms", "Trade luxury for %s"),
                                        good
                                    ),
                                    function()
                                        comms_data.goods.good.quantity = comms_data.goods.good.quantity
                                            - 1
                                        comms_source.goods["luxury"] = comms_source.goods["luxury"]
                                            - 1
                                        if comms_source.goods[good] == nil then
                                            comms_source.goods[good] = 0
                                        end
                                        comms_source.goods[good] = comms_source.goods[good]
                                            + 1
                                        setCommsMessage(
                                            _("trade-comms", "Traded")
                                        )
                                        addCommsReply(_("Back"), altShipComms)
                                    end
                                )
                            end
                        end
                    end --player has luxury
                else --not a goods or equipment freighter
                    if comms_source.cargo < 1 then
                        addCommsReply(
                            _("trade-comms", "Jettison cargo"),
                            function()
                                setCommsMessage(
                                    _(
                                        "trade-comms",
                                        "What would you like to jettison?"
                                    )
                                )
                                for good, good_quantity in
                                    pairs(comms_source.goods)
                                do
                                    if good_quantity > 0 then
                                        addCommsReply(good, function()
                                            comms_source.goods[good] = comms_source.goods[good]
                                                - 1
                                            comms_source.cargo = comms_source.cargo
                                                + 1
                                            setCommsMessage(
                                                string.format(
                                                    _(
                                                        "trade-comms",
                                                        "One %s jettisoned"
                                                    ),
                                                    good
                                                )
                                            )
                                            addCommsReply(
                                                _("Back"),
                                                altShipComms
                                            )
                                        end)
                                    end
                                end
                                addCommsReply(_("Back"), altShipComms)
                            end
                        )
                    end
                    -- Offer to sell goods
                    for good, good_data in pairs(comms_data.goods) do
                        if
                            good_data.quantity > 0
                            and comms_source.cargo > 0
                        then
                            addCommsReply(
                                string.format(
                                    _(
                                        "trade-comms",
                                        "Buy one %s for %i reputation"
                                    ),
                                    good,
                                    good_data.cost
                                ),
                                function()
                                    if
                                        comms_source:takeReputationPoints(
                                            good_data.cost
                                        )
                                    then
                                        comms_source.cargo = comms_source.cargo
                                            - 1
                                        if comms_source.goods == nil then
                                            comms_source.goods = {}
                                        end
                                        if comms_source.goods[good] == nil then
                                            comms_source.goods[good] = 0
                                        end
                                        comms_source.goods[good] = comms_source.goods[good]
                                            + 1
                                        comms_data.goods[good].quantity = comms_data.goods[good].quantity
                                            - 1
                                        setCommsMessage(
                                            _("trade-comms", "Purchased")
                                        )
                                    else
                                        setCommsMessage(
                                            _(
                                                "needRep-comms",
                                                "Insufficient reputation for purchase"
                                            )
                                        )
                                    end
                                end
                            )
                        end --freighter has good and there's room on the player's ship
                    end --freighter goods list loop
                end --different freighter types
            end --ship under 5 units away
        elseif comms_data.friendlyness > 33 then
            setCommsMessage(_("shipAssist-comms", "What do you want?"))
            -- Offer to sell destination information
            local destRep = random(1, 5)
            addCommsReply(
                string.format(
                    _(
                        "trade-comms",
                        "Where are you headed? (cost: %f reputation)"
                    ),
                    destRep
                ),
                function()
                    if not comms_source:takeReputationPoints(destRep) then
                        setCommsMessage(
                            _("needRep-comms", "Insufficient reputation")
                        )
                    else
                        setCommsMessage(comms_target.target:getCallSign())
                    end
                    addCommsReply(_("Back"), altShipComms)
                end
            )
            -- Offer to sell goods if goods or equipment freighter
            if comms_source == nil then
                print("comms_source 3 is nil")
            end
            if comms_target == nil then
                print("comms_target 3 is nil")
            end
            local x1, y1 = comms_source:getPosition()
            local x2, y2 = comms_target:getPosition()
            if distance(x1, y1, x2, y2) < 5000 then
                if comms_source.cargo < 1 then
                    addCommsReply(_("trade-comms", "Jettison cargo"), function()
                        setCommsMessage(
                            _("trade-comms", "What would you like to jettison?")
                        )
                        for good, good_quantity in pairs(comms_source.goods) do
                            if good_quantity > 0 then
                                addCommsReply(good, function()
                                    comms_source.goods[good] = comms_source.goods[good]
                                        - 1
                                    comms_source.cargo = comms_source.cargo + 1
                                    setCommsMessage(
                                        string.format(
                                            _(
                                                "trade-comms",
                                                "One %s jettisoned"
                                            ),
                                            good
                                        )
                                    )
                                    addCommsReply(_("Back"), altShipComms)
                                end)
                            end
                        end
                        addCommsReply(_("Back"), altShipComms)
                    end)
                end
                if
                    shipType:find("Goods") ~= nil
                    or shipType:find("Equipment") ~= nil
                then
                    for good, good_data in pairs(comms_data.goods) do
                        if
                            good_data.quantity > 0
                            and comms_source.cargo > 0
                        then
                            addCommsReply(
                                string.format(
                                    _(
                                        "trade-comms",
                                        "Buy one %s for %i reputation"
                                    ),
                                    good,
                                    good_data.cost
                                ),
                                function()
                                    if
                                        comms_source:takeReputationPoints(
                                            good_data.cost
                                        )
                                    then
                                        comms_source.cargo = comms_source.cargo
                                            - 1
                                        if comms_source.goods == nil then
                                            comms_source.goods = {}
                                        end
                                        if comms_source.goods[good] == nil then
                                            comms_source.goods[good] = 0
                                        end
                                        comms_source.goods[good] = comms_source.goods[good]
                                            + 1
                                        good_data["quantity"] = good_data["quantity"]
                                            - 1
                                        setCommsMessage(
                                            _("trade-comms", "Purchased")
                                        )
                                    else
                                        setCommsMessage(
                                            _(
                                                "needRep-comms",
                                                "Insufficient reputation for purchase"
                                            )
                                        )
                                    end
                                end
                            )
                        end
                    end
                else --not goods or equipment type freighter
                    -- Offer to sell goods double price
                    for good, good_data in pairs(comms_data.goods) do
                        if
                            good_data.quantity > 0
                            and comms_source.cargo > 0
                        then
                            addCommsReply(
                                string.format(
                                    _(
                                        "trade-comms",
                                        "Buy one %s for %i reputation"
                                    ),
                                    good,
                                    good_data.cost * 2
                                ),
                                function()
                                    if
                                        comms_source:takeReputationPoints(
                                            good_data.cost * 2
                                        )
                                    then
                                        comms_source.cargo = comms_source.cargo
                                            - 1
                                        if comms_source.goods == nil then
                                            comms_source.goods = {}
                                        end
                                        if comms_source.goods[good] == nil then
                                            comms_source.goods[good] = 0
                                        end
                                        comms_source.goods[good] = comms_source.goods[good]
                                            + 1
                                        comms_data.goods[good].quantity = comms_data.goods[good].quantity
                                            - 1
                                        setCommsMessage(
                                            _("trade-comms", "Purchased")
                                        )
                                    else
                                        setCommsMessage(
                                            _(
                                                "needRep-comms",
                                                "Insufficient reputation for purchase"
                                            )
                                        )
                                    end
                                end
                            )
                        end --freighter has some of the good and there's room on the player's ship
                    end --loop through freighter good list
                end --types of freighters
            end --freighter in range (< 5U)
        else --least friendly branch
            setCommsMessage(_("trade-comms", "Why are you bothering me?"))
            -- Offer to sell goods if goods or equipment freighter double price
            if comms_source == nil then
                print("comms_source 4 is nil")
            end
            if comms_target == nil then
                print("comms_target 4 is nil")
            end
            local x1, y1 = comms_source:getPosition()
            local x2, y2 = comms_target:getPosition()
            if distance(x1, y1, x2, y2) < 5000 then
                if comms_source.cargo < 1 then
                    addCommsReply(_("trade-comms", "Jettison cargo"), function()
                        setCommsMessage(
                            _("trade-comms", "What would you like to jettison?")
                        )
                        for good, good_quantity in pairs(comms_source.goods) do
                            if good_quantity > 0 then
                                addCommsReply(good, function()
                                    comms_source.goods[good] = comms_source.goods[good]
                                        - 1
                                    comms_source.cargo = comms_source.cargo + 1
                                    setCommsMessage(
                                        string.format(
                                            _(
                                                "trade-comms",
                                                "One %s jettisoned"
                                            ),
                                            good
                                        )
                                    )
                                    addCommsReply(_("Back"), altShipComms)
                                end)
                            end
                        end
                        addCommsReply(_("Back"), altShipComms)
                    end)
                end
                if
                    shipType:find("Goods") ~= nil
                    or shipType:find("Equipment") ~= nil
                then
                    for good, good_data in pairs(comms_data.goods) do
                        if
                            good_data.quantity > 0
                            and comms_source.cargo > 0
                        then
                            addCommsReply(
                                string.format(
                                    _(
                                        "trade-comms",
                                        "Buy one %s for %i reputation"
                                    ),
                                    good,
                                    good_data.cost * 2
                                ),
                                function()
                                    if
                                        comms_source:takeReputationPoints(
                                            good_data.cost * 2
                                        )
                                    then
                                        comms_source.cargo = comms_source.cargo
                                            - 1
                                        if comms_source.goods == nil then
                                            comms_source.goods = {}
                                        end
                                        if comms_source.goods[good] == nil then
                                            comms_source.goods[good] = 0
                                        end
                                        comms_source.goods[good] = comms_source.goods[good]
                                            + 1
                                        comms_data.goods[good].quantity = comms_data.goods[good].quantity
                                            - 1
                                        setCommsMessage(
                                            _("trade-comms", "Purchased")
                                        )
                                    else
                                        setCommsMessage(
                                            _(
                                                "needRep-comms",
                                                "Insufficient reputation for purchase"
                                            )
                                        )
                                    end
                                end
                            )
                        end
                    end
                end
            end
        end --friendly branches
        neutralFriendlyFreighterComms()
    else
        if comms_data.friendlyness > 50 then
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
------------------------------------
--  Generate call sign functions  --
------------------------------------
-----------------------
--  Wave management  --
-----------------------
function spawnEnemies(
    xOrigin,
    yOrigin,
    danger,
    enemyFaction,
    perimeter_min,
    perimeter_max
)
    if enemyFaction == nil then
        enemyFaction = "Kraylor"
    end
    if danger == nil then
        danger = 1
    end
    local enemyStrength = math.max(danger * enemy_power * playerPower(), 5)
    local enemyPosition = 0
    local sp = irandom(400, 900) --random spacing of spawned group
    local deployConfig = random(1, 100) --randomly choose between squarish formation and hexagonish formation
    local enemyList = {}
    -- Reminder: stsl and stnl are ship template score and name list
    local prefix = generateCallSignPrefix(1)
    while enemyStrength > 0 do
        local shipTemplateType = irandom(1, #stsl)
        while stsl[shipTemplateType] > enemyStrength * 1.1 + 5 do
            shipTemplateType = irandom(1, #stsl)
        end
        local ship = nil
        if stbl[shipTemplateType] then
            ship = CpuShip()
                :setFaction(enemyFaction)
                :setTemplate(stnl[shipTemplateType])
            local p = getPlayerShip(-1)
            if p ~= nil and p:isValid() and p:isFriendly(ship) then
                local temp_faction = ship:getFaction()
                ship:setFaction("Independent")
                ship:orderRoaming()
                ship:setFaction(temp_faction)
            else
                ship:orderRoaming()
            end
        else
            ship = nsfl[shipTemplateType](enemyFaction)
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
        ship:setCommsScript(""):setCommsFunction(altShipComms)
        table.insert(enemyList, ship)
        enemyStrength = enemyStrength - stsl[shipTemplateType]
        ship:setCallSign(generateCallSign(prefix))
    end
    if perimeter_min ~= nil then
        local enemy_angle = random(0, 360)
        local circle_increment = 360 / #enemyList
        local perimeter_deploy = perimeter_min
        if perimeter_max ~= nil then
            perimeter_deploy = random(perimeter_min, perimeter_max)
        end
        for _, enemy in pairs(enemyList) do
            if enemy_angle == nil then
                print("enemy_angle is nil")
            end
            local dex, dey = vectorFromAngle(enemy_angle, perimeter_deploy)
            enemy:setPosition(xOrigin + dex, yOrigin + dey)
            enemy_angle = enemy_angle + circle_increment
        end
    end
    return enemyList
end
function launchWaves()
    waveSize = irandom(1, 4)
    waveProgress = waveProgress + waveProgressInterval
    local wave1angle = 0
    local wave2angle = 0
    local wave3angle = 0
    local wave4angle = 0
    if random(1, 100) < 50 then
        wave1angle = ganaldaAngle
    else
        wave1angle = ticAngle
    end
    if wave1angle == nil then
        wave1angle = random(0, 360)
    end
    if wave1angle == nil then
        print("wave1angle is nil")
    end
    local wave_start_incursion_distance = 60000 - (difficulty * 5000)
    local wave1startx, wave1starty = vectorFromAngle(
        wave1angle,
        random(
            wave_start_incursion_distance + waveProgress * 10000,
            wave_start_incursion_distance + 20000 + waveProgress * 10000
        )
    )
    wave1list = {}
    wave1list = spawnEnemies(wave1startx, wave1starty, random(0.6, 3))
    waveEnemyCount = 0
    local svx = 0
    local svy = 0
    if stationVaiken:isValid() then
        svx, svy = stationVaiken:getPosition()
    end
    for _, enemy in ipairs(wave1list) do
        enemy:orderFlyTowards(svx, svy)
        waveEnemyCount = waveEnemyCount + 1
    end
    if waveSize > 1 then
        if waveSize == 4 then
            wave2angle = wave1angle + random(60, 120)
        elseif waveSize == 3 then
            wave2angle = wave1angle + random(60, 180)
        else
            wave2angle = wave1angle + random(90, 270)
        end
        local wave2distance = random(
            wave_start_incursion_distance + waveProgress * 10000,
            wave_start_incursion_distance + 20000 + waveProgress * 10000
        )
        -- if wave2angle == nil then print("wave2angle is nil") end
        local wave2startx, wave2starty =
            vectorFromAngle(wave2angle, wave2distance)
        wave2list = {}
        wave2list = spawnEnemies(
            wave2startx,
            wave2starty,
            random(0.5, 2.5) + waveProgress,
            "Exuari"
        )
        for _, enemy in ipairs(wave2list) do
            enemy:orderFlyTowards(svx, svy)
            waveEnemyCount = waveEnemyCount + 1
        end
    end
    if waveSize > 2 then
        if waveSize == 4 then
            wave3angle = wave2angle + random(60, 120)
        else
            wave3angle = wave2angle + random(60, 180)
        end
        -- if wave3angle == nil then print("wave3angle is nil") end
        local wave3startx, wave3starty = vectorFromAngle(
            wave3angle,
            random(
                wave_start_incursion_distance + waveProgress * 10000,
                wave_start_incursion_distance + 20000 + waveProgress * 10000
            )
        )
        wave3list = {}
        wave3list = spawnEnemies(
            wave3startx,
            wave3starty,
            random(0.4, 2) + waveProgress
        )
        for _, enemy in ipairs(wave3list) do
            enemy:orderFlyTowards(svx, svy)
            waveEnemyCount = waveEnemyCount + 1
        end
    end
    if waveSize == 4 then
        wave4angle = wave3angle + random(60, 120)
        -- if wave4angle == nil then print("wave4angle is nil") end
        local wave4startx, wave4starty = vectorFromAngle(
            wave4angle,
            random(
                wave_start_incursion_distance + waveProgress * 10000,
                wave_start_incursion_distance + 20000 + waveProgress * 10000
            )
        )
        wave4list = {}
        wave4list =
            spawnEnemies(wave4startx, wave4starty, random(0.3, 1.5), "Exuari")
        for _, enemy in ipairs(wave3list) do
            enemy:orderFlyTowards(svx, svy)
            waveEnemyCount = waveEnemyCount + 1
        end
    end
    local p = getPlayerShip(-1)
    if p ~= nil and p:isValid() then
        p:addReputationPoints(math.floor(waveProgress * 10 / difficulty))
    end
end
function monitorWaves(delta)
    if waveInProgress then
        waveCheckDelay = waveCheckDelay - delta
        if waveCheckDelay > 0 then
            return
        end
        local waveRemainingEnemies = 0
        for _, enemy in ipairs(wave1list) do
            if enemy ~= nil and enemy:isValid() then
                waveRemainingEnemies = waveRemainingEnemies + 1
            end
        end
        if waveSize > 1 then
            for _, enemy in ipairs(wave2list) do
                if enemy ~= nil and enemy:isValid() then
                    waveRemainingEnemies = waveRemainingEnemies + 1
                end
            end
        end
        if waveSize > 2 then
            for _, enemy in ipairs(wave3list) do
                if enemy ~= nil and enemy:isValid() then
                    waveRemainingEnemies = waveRemainingEnemies + 1
                end
            end
        end
        if waveSize == 4 then
            for _, enemy in ipairs(wave4list) do
                if enemy ~= nil and enemy:isValid() then
                    waveRemainingEnemies = waveRemainingEnemies + 1
                end
            end
        end
        if
            waveRemainingEnemies / waveEnemyCount < 0.12
            or waveDelayCount > waveDelayCountCheck
        then
            for _, enemy in ipairs(wave1list) do
                if enemy ~= nil and enemy:isValid() then
                    table.insert(persistentEnemies, enemy)
                end
            end
            if waveSize > 1 then
                for _, enemy in ipairs(wave2list) do
                    if enemy ~= nil and enemy:isValid() then
                        table.insert(persistentEnemies, enemy)
                    end
                end
            end
            if waveSize > 2 then
                for _, enemy in ipairs(wave3list) do
                    if enemy ~= nil and enemy:isValid() then
                        table.insert(persistentEnemies, enemy)
                    end
                end
            end
            if waveSize == 4 then
                for _, enemy in ipairs(wave4list) do
                    if enemy ~= nil and enemy:isValid() then
                        table.insert(persistentEnemies, enemy)
                    end
                end
            end
            for _, enemy in ipairs(persistentEnemies) do
                local pecdist = 999999 --player to enemy closest distance
                if enemy ~= nil and enemy:isValid() then
                    local closest = nil
                    for p6idx = 1, 8 do
                        local p6obj = getPlayerShip(p6idx)
                        if p6obj ~= nil and p6obj:isValid() then
                            -- if p6obj == nil then print("p6obj is nil") end
                            -- if enemy == nil then print("enemy is nil") end
                            local x1, y1 = p6obj:getPosition()
                            local x2, y2 = enemy:getPosition()
                            local curdist = distance(x1, y1, x2, y2)
                            if curdist < pecdist then
                                closest = p6obj
                                pecdist = curdist
                            end
                        end
                    end
                    enemy:orderAttack(closest)
                end
            end
            waveInProgress = false
        end
        waveCheckDelay = delta + 20
        if playWithTimeLimit then
            waveDelayCount = waveDelayCount + 1
        end
    else --wave not in progress, launch one
        for i = 1, #stationList do
            local current_station = stationList[i]
            if current_station ~= nil and current_station:isValid() then
                current_station.warn_count = 0
            end
        end
        launchWaves()
        waveDelayCount = 0
        waveInProgress = true
        waveCheckDelay = delta + 20
    end
end
function helpWarn(delta)
    helpWarnDelay = helpWarnDelay - delta
    if helpWarnDelay > 0 then
        return
    end
    helpWarnDelay = delta + 30
    waveNear(wave1list)
    if waveSize > 1 then
        waveNear(wave2list)
    end
    if waveSize > 2 then
        waveNear(wave3list)
    end
    if waveSize == 4 then
        waveNear(wave4list)
    end
end
function waveNear(enemyWaveList)
    for idx, enemy in pairs(enemyWaveList) do
        if enemy ~= nil and enemy:isValid() then
            local playerInRange = false -- no warning if a player in range
            for p7idx = 1, 8 do
                local p7 = getPlayerShip(p7idx)
                if p7 ~= nil and p7:isValid() then
                    if p7 == nil then
                        print("p7 is nil")
                    end
                    if enemy == nil then
                        print("enemy 2 is nil")
                    end
                    local x1, y1 = p7:getPosition()
                    local x2, y2 = enemy:getPosition()
                    if distance(x1, y1, x2, y2) < 30000 then
                        playerInRange = true
                        break
                    end
                end
            end
            if not playerInRange then
                local distToEnemy = 999999
                local closestStation = nil
                for idx2, obj in ipairs(enemy:getObjectsInRange(30000)) do
                    if obj ~= nil and obj:isValid() then
                        if isObjectType(obj, "SpaceStation") then
                            if
                                obj:getFaction() == "Human Navy"
                                or obj:getFaction() == "Independent"
                            then
                                if obj == nil then
                                    print("obj is nil")
                                end
                                if enemy == nil then
                                    print("enemy 3 is nil")
                                end
                                local x1, y1 = obj:getPosition()
                                local x2, y2 = enemy:getPosition()
                                local curDist = distance(x1, y1, x2, y2)
                                if curDist < distToEnemy then
                                    distToEnemy = curDist
                                    closestStation = obj
                                end
                            end
                        end
                    end
                end
                if random(1, 100) > distToEnemy / 30000 * 100 then
                    if
                        closestStation ~= nil
                        and closestStation.warn_count ~= nil
                        and closestStation.warn_count < 3
                    then
                        local distToPlayer = 999999
                        local closestPlayer = nil
                        for p8idx = 1, 8 do
                            local p8 = getPlayerShip(p8idx)
                            if p8 ~= nil and p8:isValid() then
                                if p8 == nil then
                                    print("p8 is nil")
                                end
                                if closestStation == nil then
                                    print("closestStation is nil")
                                end
                                local x1, y1 = p8:getPosition()
                                local x2, y2 = closestStation:getPosition()
                                curDist = distance(x1, y1, x2, y2)
                                if curDist < distToPlayer then
                                    distToPlayer = curDist
                                    closestPlayer = p8
                                end
                            end
                        end
                        if closestPlayer ~= nil then
                            local lMsg = string.format(
                                _(
                                    "helpfullWarning-shipLog",
                                    "[%s, Sector %s] There are enemies nearby"
                                ),
                                closestStation:getCallSign(),
                                closestStation:getSectorName()
                            )
                            closestPlayer:addToShipLog(lMsg, "Red")
                        end
                        closestStation.warn_count = closestStation.warn_count + 1
                        return
                    end
                end
            end
        end
    end
end
function showGameEndStatistics()
    if game_end_statistics_diagnostic then
        print("top of game end statistics function")
    end
    local destroyedStations = 0
    local survivedStations = 0
    local destroyedFriendlyStations = 0
    local survivedFriendlyStations = 0
    local destroyedNeutralStations = 0
    local survivedNeutralStations = 0
    local gMsg = ""
    local reference_player = getPlayerShip(-1)
    if reference_player == nil then
        reference_player = getPlayerShip(1)
    end
    if reference_player ~= nil then
        if game_end_statistics_diagnostic then
            print("reference player is not nil")
        end
        if game_end_statistics_diagnostic then
            print("reference player: " .. reference_player:getCallSign())
        end
        for _, station in pairs(originalStationList) do
            if station:isFriendly(reference_player) then
                if station:isValid() then
                    survivedStations = survivedStations + 1
                    survivedFriendlyStations = survivedFriendlyStations + 1
                end
            else
                if station:isValid() then
                    survivedStations = survivedStations + 1
                    survivedNeutralStations = survivedNeutralStations + 1
                end
            end
        end
        if game_end_statistics_diagnostic then
            print("completed station examination loop")
        end
        destroyedStations = totalStations - survivedStations
        destroyedFriendlyStations = friendlyStations - survivedFriendlyStations
        destroyedNeutralStations = neutralStations - survivedNeutralStations
        gMsg = string.format(
            _("msgMainscreen", "Stations: %i\t survived: %i\t destroyed: %i"),
            totalStations,
            survivedStations,
            destroyedStations
        )
        gMsg = gMsg
            .. string.format(
                _(
                    "msgMainscreen",
                    "\nFriendly Stations: %i\t survived: %i\t destroyed: %i"
                ),
                friendlyStations,
                survivedFriendlyStations,
                destroyedFriendlyStations
            )
        gMsg = gMsg
            .. string.format(
                _(
                    "msgMainscreen",
                    "\nNeutral Stations: %i\t survived: %i\t destroyed: %i"
                ),
                neutralStations,
                survivedNeutralStations,
                destroyedNeutralStations
            )
        gMsg = gMsg
            .. string.format(
                _("msgMainscreen", "\n\n\n\nRequired missions completed: %i"),
                requiredMissionCount
            )
        if not stationVaiken:isValid() then
            gMsg = gMsg
                .. _(
                    "msgMainscreen",
                    "\nHuman Navy headquarters station Vaiken destroyed"
                )
        end
        local rankVal = survivedFriendlyStations / friendlyStations * 0.7
            + survivedNeutralStations / neutralStations * 0.3
        if rankVal < 0.7 then
            rank = _("msgMainscreen", "Ensign")
        elseif rankVal < 0.8 then
            rank = _("msgMainscreen", "Lieutenant")
        elseif rankVal < 0.9 then
            rank = _("msgMainscreen", "Commander")
        elseif rankVal < 0.95 then
            rank = _("msgMainscreen", "Captain")
        else
            rank = _("msgMainscreen", "Admiral")
        end
        gMsg = gMsg
            .. string.format(_("msgMainscreen", "\nEarned rank:  %s"), rank)
    else
        gMsg =
            _("msgMainscreen", "Not enough data from ship to gather statistics")
    end
    globalMessage(gMsg)
    if game_end_statistics_diagnostic then
        print("end of game end statistics function")
    end
end
-----------------------------
--  Required plot choices  --
-----------------------------
-- Required plot choice: Undercut leads to base destruction
--     Randomly choose between stations (Outpost-21, Outpost-33, Lando, Outpost-8) as the base where Charles Undercut hides
--     At the base, player told that Undercut took a job on a freighter
--     At the freighter, the captain will want cargo before allowing Undercut to talk
--     Undercut identifies an enemy Kraylor base after cargo provided
--     Destruction of enemy base completes mission.
function chooseUndercutBase()
    local hideChoice = math.random(1, 4)
    if hideChoice == 1 then
        if stationOutpost21:isValid() then
            hideBase = stationOutpost21
        elseif stationOutpost33:isValid() then
            hideBase = stationOutpost33
        elseif stationLando:isValid() then
            hideBase = stationLando
        else
            hideBase = stationOutpost8
        end
    elseif hideChoice == 2 then
        if stationOutpost33:isValid() then
            hideBase = stationOutpost33
        elseif stationLando:isValid() then
            hideBase = stationLando
        elseif stationOutpost8:isValid() then
            hideBase = stationOutpost8
        else
            hideBase = stationOutpost21
        end
    elseif hideChoice == 3 then
        if stationLando:isValid() then
            hideBase = stationLando
        elseif stationOutpost8:isValid() then
            hideBase = stationOutpost8
        elseif stationOutpost21:isValid() then
            hideBase = stationOutpost21
        else
            hideBase = stationOutpost33
        end
    else
        if stationOutpost8:isValid() then
            hideBase = stationOutpost8
        elseif stationOutpost33:isValid() then
            hideBase = stationOutpost33
        elseif stationLando:isValid() then
            hideBase = stationLando
        else
            hideBase = stationOutpost21
        end
    end
    hideStationName = hideBase:getCallSign()
    hideStationSector = hideBase:getSectorName()
end
function undercutOrderMessage(delta)
    local nMsg = _(
        "Undercut1Orders-shipLog",
        "[Vaiken] As a naval operative, Charles Undercut discovered information about enemies in this region. Unfortunately, he was fired for his poor performance as a maintenance technician by his commanding officer before he could file a report. We need his information."
    )
    if difficulty > 1 then
        nMsg = string.format(
            _(
                "Undercut1Orders-shipLog",
                "%s His last known location was station %s. Go find him and get that information"
            ),
            nMsg,
            hideBase:getCallSign()
        )
    else
        nMsg = string.format(
            _(
                "Undercut1Orders-shipLog",
                "%s His last known location was station %s in sector %s. Go find him and get that information"
            ),
            nMsg,
            hideBase:getCallSign(),
            hideBase:getSectorName()
        )
    end
    for p11idx = 1, 8 do
        local p11 = getPlayerShip(p11idx)
        if p11 ~= nil and p11:isValid() then
            p11:addToShipLog(nMsg, "Magenta")
        end
    end
    if difficulty > 1 then
        secondaryOrders = string.format(
            _(
                "Undercut1Orders-comms",
                "\nFind Charles Undercut last reported at station %s who has information on enemy activity"
            ),
            hideStationName
        )
    else
        secondaryOrders = string.format(
            _(
                "Undercut1Orders-comms",
                "\nFind Charles Undercut last reported at station %s in sector %s who has information on enemy activity"
            ),
            hideStationName,
            hideStationSector
        )
    end
    plotR = undercutStation
end
function undercutStation(delta)
    if hideBase ~= nil and hideBase:isValid() then
        for p9idx = 1, 8 do
            local p9 = getPlayerShip(p9idx)
            if p9 ~= nil and p9:isValid() then
                if p9:isDocked(hideBase) then
                    if p9.undercut == nil then
                        if hideTransport == nil then
                            local farthestTransport = nil
                            for _, ft in ipairs(mission_transport_list) do
                                if ft ~= nil and ft:isValid() then
                                    farthestTransport = ft
                                    break
                                end
                            end
                            for _, t in ipairs(mission_transport_list) do
                                if t ~= nil and t:isValid() then
                                    if hideBase == nil then
                                        print("hideBase is nil")
                                    end
                                    if t == nil then
                                        print("t is nil")
                                    end
                                    if farthestTransport == nil then
                                        print("farthestTransport 2 is nil")
                                    end
                                    local x1, y1 = hideBase:getPosition()
                                    local x2, y2 = t:getPosition()
                                    local x3, y3 =
                                        farthestTransport:getPosition()
                                    if
                                        distance(x1, y1, x2, y2)
                                        > distance(x1, y1, x3, y3)
                                    then
                                        farthestTransport = t
                                    end
                                end
                            end
                            hideTransport = farthestTransport
                        end
                        p9.undercut = hideTransport
                        local fMsg = string.format(
                            _(
                                "Undercut1-shipLog",
                                "[%s] We haven't seen Charles Undercut in a while. He took a job as a maintenance technician aboard %s"
                            ),
                            hideBase:getCallSign(),
                            hideTransport:getCallSign()
                        )
                        fMsg = fMsg
                            .. string.format(
                                _(
                                    "Undercut1-shipLog",
                                    ".\nLast we heard, that ship was working in the %s sector. He was desperate for a job."
                                ),
                                hideTransport:getSectorName()
                            )
                        p9:addToShipLog(fMsg, "Magenta")
                        plotR = undercutTransport
                        undercutLocation = "transport"
                        undercutHelp = 30
                        local random_good = nil
                        if hideTransport.comms_data == nil then
                            hideTransport.comms_data = {}
                        end
                        if hideTransport.comms_data.goods ~= nil then
                            if
                                hideTransport.comms_data.goods["luxury"] ~= nil
                            then
                                hideTransport.comms_data.goods["luxury"].quantity =
                                    0
                                repeat
                                    random_good = commonGoods[math.random(
                                        1,
                                        #commonGoods
                                    )]
                                until random_good ~= "luxury"
                                    and random_good ~= "gold"
                                    and random_good ~= "platinum"
                                hideTransport.comms_data.goods[random_good] =
                                    { quantity = 1, cost = math.random(20, 80) }
                            end
                            if
                                hideTransport.comms_data.goods["gold"] ~= nil
                            then
                                hideTransport.comms_data.goods["gold"].quantity =
                                    0
                                repeat
                                    random_good = commonGoods[math.random(
                                        1,
                                        #commonGoods
                                    )]
                                until random_good ~= "luxury"
                                    and random_good ~= "gold"
                                    and random_good ~= "platinum"
                                hideTransport.comms_data.goods[random_good] =
                                    { quantity = 1, cost = math.random(20, 80) }
                            end
                            if
                                hideTransport.comms_data.goods["platinum"]
                                ~= nil
                            then
                                hideTransport.comms_data.goods["platinum"].quantity =
                                    0
                                repeat
                                    random_good = commonGoods[math.random(
                                        1,
                                        #commonGoods
                                    )]
                                until random_good ~= "luxury"
                                    and random_good ~= "gold"
                                    and random_good ~= "platinum"
                                hideTransport.comms_data.goods[random_good] =
                                    { quantity = 1, cost = math.random(20, 80) }
                            end
                        else
                            hideTransport.comms_data.goods = {}
                            repeat
                                random_good =
                                    commonGoods[math.random(1, #commonGoods)]
                            until random_good ~= "luxury"
                                and random_good ~= "gold"
                                and random_good ~= "platinum"
                            hideTransport.comms_data.goods[random_good] =
                                { quantity = 1, cost = math.random(20, 80) }
                            local shipType = hideTransport:getTypeName()
                            if shipType:find("Freighter") ~= nil then
                                if
                                    shipType:find("Goods") ~= nil
                                    or shipType:find("Equipment") ~= nil
                                then
                                    repeat
                                        repeat
                                            random_good =
                                                commonGoods[math.random(
                                                    1,
                                                    #commonGoods
                                                )]
                                        until random_good ~= "luxury"
                                            and random_good ~= "gold"
                                            and random_good ~= "platinum"
                                        hideTransport.comms_data.goods[random_good] =
                                            {
                                                quantity = 1,
                                                cost = math.random(20, 80),
                                            }
                                        local goodCount = 0
                                        for good, goodData in
                                            pairs(
                                                hideTransport.comms_data.goods
                                            )
                                        do
                                            goodCount = goodCount + 1
                                        end
                                    until goodCount >= 3
                                end
                            end
                        end
                        if difficulty > 1 then
                            hideTransport:setImpulseMaxSpeed(
                                hideTransport:getImpulseMaxSpeed() * 2
                            )
                        end
                    end
                end
            end
        end
    else
        undercutMission = "done"
        plotR = nil
        removeGMFunction("Req Undercut")
    end
end
function undercutTransport(delta)
    if hideTransport ~= nil and hideTransport:isValid() then
        if undercutLocation == "transport" then
            undercutHelp = undercutHelp - delta
            if undercutHelp < 0 then
                local helpHideTransport = false
                if hideTransport:getHull() < hideTransport:getHullMax() then
                    helpHideTransport = true
                end
                shields = hideTransport:getShieldCount()
                for n = 0, shields - 1 do
                    if
                        hideTransport:getShieldLevel(n)
                            / hideTransport:getShieldMax(n)
                        < 0.5
                    then
                        helpHideTransport = true
                    end
                end
                if helpHideTransport then
                    local playerDistance = 999999
                    local closestPlayer = nil
                    for p10idx = 1, 8 do
                        local p10 = getPlayerShip(p10idx)
                        if p10 ~= nil and p10:isValid() then
                            if p10 == nil then
                                print("p10 is nil")
                            end
                            if hideTransport == nil then
                                print("hideTransport is nil")
                            end
                            local x1, y1 = p10:getPosition()
                            local x2, y2 = hideTransport:getPosition()
                            local currentDistance = distance(x1, y1, x2, y2)
                            if currentDistance < playerDistance then
                                closestPlayer = p10
                                playerDistance = currentDistance
                            end
                        end
                    end
                    local hMsg = string.format(
                        _(
                            "Undercut1-shipLog",
                            "[%s] we need help. Our maintenance technician says you might be interested. "
                        ),
                        hideTransport:getCallSign()
                    )
                    hMsg = hMsg
                        .. string.format(
                            _(
                                "Undercut1-shipLog",
                                "We are in sector %s. Hurry."
                            ),
                            hideTransport:getSectorName()
                        )
                    closestPlayer:addToShipLog(hMsg, "Magenta")
                end
                undercutHelp = delta + 30
            end
        end
        if undercutLocation == "free" then
            secondaryOrders = string.format(
                _("Undercut1Orders-comms", "\nDestroy enemy base in sector %s"),
                undercutTarget:getSectorName()
            )
            plotR = undercutEnemyBase
        end
    else
        undercutMission = "done"
        plotR = nil
        removeGMFunction("Req Undercut")
    end
end
function undercutEnemyBase(delta)
    if undercutBaseDefense == nil then
        local undercutTargetx, undercutTargetY = undercutTarget:getPosition()
        local undercutWaveDefenseList = {}
        undercutWaveDefenseList = spawnEnemies(
            undercutTargetx,
            undercutTargetY,
            1,
            undercutTarget:getFaction()
        )
        for _, enemy in ipairs(undercutWaveDefenseList) do
            enemy:orderDefendTarget(undercutTarget)
        end
        undercutBaseDefense = true
    end
    if not undercutTarget:isValid() then
        requiredMissionCount = requiredMissionCount + 1
        secondaryOrders = ""
        undercutMission = "done"
        for p30idx = 1, 8 do
            local p30 = getPlayerShip(p30idx)
            if p30 ~= nil and p30:isValid() and undercutRep == nil then
                p30:addReputationPoints(100 - (difficulty * 5))
                undercutRep = "awarded"
            end
        end
        plotR = nil
        removeGMFunction("Req Undercut")
    end
end
-- Required plot choice: Stettor sensors find enemy base - destroy
-- - Randomly choose between stations (Vactel, Archer, Deer, Cavor) as the base to bring random cargo items to
-- - Randomly select cargo items (part 1: dilithium, cobalt, tritanium; part 2: software, optic, robotic; part 3: sensor)
-- - After the cargo is brought, sensors detect an enemy base to destroy
-- - Destruction of enemy base completes the mission
function chooseSensorBase()
    if sensorBase == nil then
        local sensorChoice = math.floor(random(1, 4))
        if sensorChoice == 1 then
            sensorBase = stationVactel
        elseif sensorChoice == 2 then
            sensorBase = stationArcher
        elseif sensorChoice == 3 then
            sensorBase = stationDeer
        else
            sensorBase = stationCavor
        end
    end
    sensorBaseName = sensorBase:getCallSign()
    sensorBaseSector = sensorBase:getSectorName()
end
function chooseSensorParts()
    if s1part == nil then
        local si1Choice = math.floor(random(1, 3))
        if si1Choice == 1 then
            s1part = "dilithium"
        elseif si1Choice == 2 then
            s1part = "cobalt"
        else
            s1part = "tritanium"
        end
    end
    if s2part == nil then
        local si2Choice = math.floor(random(1, 3))
        if si2Choice == 1 then
            s2part = "software"
        elseif si2Choice == 2 then
            s2part = "optic"
        else
            s2part = "robotic"
        end
    end
    s3part = "sensor"
end
function stettorOrderMessage(delta)
    local snsMsg = _(
        "StettorOrders-shipLog",
        "[Vaiken] Jing Stettor's research on advanced sensor technology produced a breakthrough. To facilitate rapid deployment, we need you to gather the following:\n"
    )
    snsMsg = snsMsg .. s1part .. "\n"
    snsMsg = snsMsg .. s2part .. "\n"
    snsMsg = snsMsg .. s3part .. "\n"
    if difficulty > 1 then
        snsMsg = snsMsg
            .. string.format(
                _("StettorOrders-shipLog", "and take these items to station %s"),
                sensorBaseName
            )
        secondaryOrders = string.format(
            _(
                "StettorOrders-comms",
                "\nGather the following:\n%s\n%s\n%s\nand take to station %s"
            ),
            s1part,
            s2part,
            s3part,
            sensorBaseName
        )
    else
        snsMsg = snsMsg
            .. string.format(
                _(
                    "StettorOrders-shipLog",
                    "and take these items to station %s in sector %s"
                ),
                sensorBaseName,
                sensorBaseSector
            )
        secondaryOrders = string.format(
            _(
                "StettorOrders-comms",
                "\nGather the following:\n%s\n%s\n%s\nand take to station %s in sector %s"
            ),
            s1part,
            s2part,
            s3part,
            sensorBaseName,
            sensorBaseSector
        )
    end
    if sensorMessage == nil then
        for p13idx = 1, 8 do
            local p13 = getPlayerShip(p13idx)
            if p13 ~= nil and p13:isValid() then
                p13:addToShipLog(snsMsg, "Magenta")
            end
        end
        sensorMessage = "done"
    end
    plotR = stettorStation
end
function stettorStation(delta)
    if sensorBase:isValid() then
        for p14idx = 1, 8 do
            local p14 = getPlayerShip(p14idx)
            if p14 ~= nil and p14:isValid() then
                if p14:isDocked(sensorBase) then
                    if p14.stettor == "provided" then
                        secondaryOrders = string.format(
                            _(
                                "StettorOrders-comms",
                                "\nDestroy enemy base in sector %s"
                            ),
                            stettorTarget:getSectorName()
                        )
                        plotR = stettorEnemyBase
                    end
                end
            end
        end
    else
        stettorMission = "done"
        plotR = nil
        removeGMFunction("Req Stettor")
    end
end
function stettorEnemyBase(delta)
    if not stettorTarget:isValid() then
        requiredMissionCount = requiredMissionCount + 1
        secondaryOrders = ""
        stettorMission = "done"
        for p31idx = 1, 8 do
            local p31 = getPlayerShip(p31idx)
            if p31 ~= nil and p31:isValid() and stettorRep == nil then
                p31:addReputationPoints(80 - (difficulty * 5))
                stettorRep = "awarded"
            end
        end
        plotR = nil
        removeGMFunction("Req Stettor")
    end
end
--      Required plot choice: Traitor bought identifies enemy base
-- - Randomly choose between stations (Marconi, Muddville, Alcaleica) for spy location
-- - At the station, find out spy is on a freighter
-- - The freighter will demand cargo for spy (randomly selected)
-- - Spy will identify an enemy base
-- - Destruction of enemy base completes the mission
function chooseTraitorBase()
    if traitorBase == nil then
        local traiterBaseChoice = math.floor(random(1, 3))
        if traiterBaseChoice == 1 then
            traitorBase = stationMarconi
        elseif traiterBaseChoice == 2 then
            traitorBase = stationMudd
        else
            traitorBase = stationAlcaleica
        end
    end
    traitorBaseName = traitorBase:getCallSign()
    traitorBaseSector = traitorBase:getSectorName()
end
function traitorOrderMessage(delta)
    local tMsg = string.format(
        _(
            "Sporisky-shipLog",
            "[Vaiken] Intelligence observed a spy for the enemy at station %s"
        ),
        traitorBaseName
    )
    if difficulty <= 1 then
        tMsg = string.format(
            _("Sporisky-shipLog", "%s in sector %s"),
            tMsg,
            traitorBaseSector
        )
    end
    tMsg = string.format(
        _(
            "SporiskyOrders-shipLog",
            "%s. Go find out what you can about this spy."
        ),
        tMsg
    )
    if difficulty <= 1 then
        secondaryOrders = string.format(
            _(
                "SporiskyOrders-comms",
                "\nInvestigate spy reported at station %s in sector %s"
            ),
            traitorBaseName,
            traitorBaseSector
        )
    else
        secondaryOrders = string.format(
            _(
                "SporiskyOrders-comms",
                "\nInvestigate spy reported at station %s"
            ),
            traitorBaseName
        )
    end
    if traitorMessage == nil then
        for p14idx = 1, 8 do
            local p14 = getPlayerShip(p14idx)
            if p14 ~= nil and p14:isValid() then
                p14:addToShipLog(tMsg, "Magenta")
            end
        end
        traitorMessage = "done"
    end
    plotR = traitorStation
end
function traitorStation(delta)
    if traitorBase ~= nil and traitorBase:isValid() then
        for p15idx = 1, 8 do
            local p15 = getPlayerShip(p15idx)
            if p15 ~= nil and p15:isValid() then
                if p15:isDocked(traitorBase) then
                    if p15.traitor == nil then
                        if runTransport == nil then
                            local farthestTransport = nil
                            for _, ft in ipairs(mission_transport_list) do
                                if ft ~= nil and ft:isValid() then
                                    farthestTransport = ft
                                    break
                                end
                            end
                            for _, t in ipairs(mission_transport_list) do
                                if t ~= nil and t:isValid() then
                                    if traitorBase == nil then
                                        print("traitorBase is nil")
                                    end
                                    if t == nil then
                                        print("t 2 is nil")
                                    end
                                    if farthestTransport == nil then
                                        print("farthestTransport 3 is nil")
                                    end
                                    local x1, y1 = traitorBase:getPosition()
                                    local x2, y2 = t:getPosition()
                                    local x3, y3 =
                                        farthestTransport:getPosition()
                                    if
                                        distance(x1, y1, x2, y2)
                                        > distance(x1, y1, x3, y3)
                                    then
                                        farthestTransport = t
                                    end
                                end
                            end
                            runTransport = farthestTransport
                        end
                        p15.traitor = runTransport
                        local trMsg = string.format(
                            _(
                                "Sporisky-shipLog",
                                "[%s] The girl you're looking for is Annette Sporisky. She boarded a freighter owned by her family: %s"
                            ),
                            traitorBaseName,
                            runTransport:getCallSign()
                        )
                        trMsg = trMsg
                            .. string.format(
                                _(
                                    "Sporisky-shipLog",
                                    ".\nLast we heard, that ship was working in the %s sector."
                                ),
                                runTransport:getSectorName()
                            )
                        p15:addToShipLog(trMsg, "Magenta")
                        plotR = sporiskyTransport
                        if difficulty > 1 then
                            runTransport:setImpulseMaxSpeed(
                                runTransport:getImpulseMaxSpeed() * 2
                            )
                        end
                        secondaryOrders = string.format(
                            _(
                                "SporiskyOrders-comms",
                                "\nGet the spy Annette Sporisky from transport %s and bring her to Vaiken station for questioning"
                            ),
                            runTransport:getCallSign()
                        )
                    end
                end
            end
        end
    else
        sporiskyMission = "done"
        plotR = nil
        removeGMFunction("Req Sporisky")
    end
end
function sporiskyTransport(delta)
    if runTransport:isValid() then
        for p16idx = 1, 8 do
            local p16 = getPlayerShip(p16idx)
            if p16 ~= nil and p16:isValid() then
                if p16.traitorBought == true then
                    plotR = sporiskyQuestioned
                end
            end
        end
    else
        sporiskyMission = "done"
        plotR = nil
        removeGMFunction("Req Sporisky")
    end
end
function sporiskyQuestioned(delta)
    if stationVaiken:isValid() then
        for p17idx = 1, 8 do
            local p17 = getPlayerShip(p17idx)
            if p17 ~= nil and p17:isValid() then
                if p17:isDocked(stationVaiken) then
                    if p17.traitorBought then
                        p17:addToShipLog(
                            _(
                                "Sporisky-shipLog",
                                "Annette Sporisky transferred to Vaiken station"
                            ),
                            "Magenta"
                        )
                        if sporiskyTarget:isValid() then
                            p17:addToShipLog(
                                string.format(
                                    _(
                                        "Sporisky-shipLog",
                                        "Spy identified enemy base in sector %s"
                                    ),
                                    sporiskyTarget:getSectorName()
                                ),
                                "Magenta"
                            )
                            secondaryOrders = string.format(
                                _(
                                    "SporiskyOrders-comms",
                                    "\nDestroy enemy base in sector %s"
                                ),
                                sporiskyTarget:getSectorName()
                            )
                        else
                            if stationGanalda:isValid() then
                                sporiskyTarget = stationGanalda
                            elseif stationEmpok:isValid() then
                                sporiskyTarget = stationEmpok
                            elseif stationTic:isValid() then
                                sporiskyTarget = stationTic
                            end
                            if sporiskyTarget:isValid() then
                                p17:addToShipLog(
                                    string.format(
                                        _(
                                            "Sporisky-shipLog",
                                            "Spy identified enemy base in sector %s"
                                        ),
                                        sporiskyTarget:getSectorName()
                                    ),
                                    "Magenta"
                                )
                                secondaryOrders = string.format(
                                    _(
                                        "SporiskyOrders-comms",
                                        "\nDestroy enemy base in sector %s"
                                    ),
                                    sporiskyTarget:getSectorName()
                                )
                            else
                                p17:addToShipLog(
                                    string.format(
                                        _(
                                            "Sporisky-shipLog",
                                            "The enemy base identified has already been destroyed"
                                        )
                                    ),
                                    "Magenta"
                                )
                            end
                        end
                        plotR = sporiskyEnemyBase
                    end
                end
            end
        end
    else
        sporiskyMission = "done"
        plotR = nil
        removeGMFunction("Req Sporisky")
    end
end
function sporiskyEnemyBase(delta)
    if not sporiskyTarget:isValid() then
        requiredMissionCount = requiredMissionCount + 1
        plotR = nil
        removeGMFunction("Req Sporisky")
        secondaryOrders = ""
        sporiskyMission = "done"
        for p32idx = 1, 8 do
            local p32 = getPlayerShip(p32idx)
            if p32 ~= nil and p32:isValid() and sporiskyRep == nil then
                p32:addReputationPoints(80 - (difficulty * 5))
                sporiskyRep = "awarded"
            end
        end
    end
end
--      Required plot choice: black hole horizon research
-- - Randomly choose necessary research cargo (part 1: communication, lifter, repulsor; part 2: sensor) to bring to station Emory
-- - Once parts are gathered, player will need to gather data from black hole by staying close to get sensor readings
-- - Getting the black hole scans completes the mission
function chooseHorizonParts()
    if hr1part == nil then
        local hr1Choice = math.random(3)
        if hr1Choice == 1 then
            hr1part = "communication"
        elseif hr1Choice == 2 then
            hr1part = "lifter"
        else
            hr1part = "repulsor"
        end
    end
    hr2part = "sensor"
end
function horizonOrderMessage(delta)
    if stationEmory:isValid() then
        local hMsg = string.format(
            _(
                "blackHoleOrders-shipLog",
                "[Emory] After years or research, we are near a breakthrough on our mobile black hole research. We need some assistance for the next phase. Please bring us some %s and %s type goods."
            ),
            hr1part,
            hr2part
        )
        secondaryOrders = string.format(
            _("blackHoleOrders-comms", "\nBring %s and %s to station Emory"),
            hr1part,
            hr2part
        )
        if horizonMessage == nil then
            for p25idx = 1, 8 do
                local p25 = getPlayerShip(p25idx)
                if p25 ~= nil and p25:isValid() then
                    p25:addToShipLog(hMsg, "Magenta")
                end
            end
            horizonMessage = "done"
        end
        horizonScanRange = 5000 - (difficulty * 200)
        plotR = horizonStationDeliver
    else
        horizonMission = "done"
        plotR = nil
        removeGMFunction("Req Horizon")
    end
end
function horizonStationDeliver(delta)
    if stationEmory:isValid() then
        for p26idx = 1, 8 do
            local p26 = getPlayerShip(p26idx)
            if p26 ~= nil and p26:isValid() then
                if p26:isDocked(stationEmory) then
                    if p26.horizonComponents == "provided" then
                        secondaryOrders = _(
                            "blackHoleOrders-comms",
                            "Gather sensor data from black hole by close approach"
                        )
                        horizonScienceMessageStartTimer = 20
                        phScan = p26
                        elapsedScanTime = 0
                        plotR = horizonScienceMessage
                    end
                end
            end
        end
    else
        horizonMission = "done"
        plotR = nil
        removeGMFunction("Req Horizon")
    end
end
function horizonScienceMessage(delta)
    horizonScienceMessageStartTimer = horizonScienceMessageStartTimer - delta
    if horizonScienceMessageStartTimer < 0 then
        if phScan.horizonConsoleMessage ~= "sent" then
            horizonConsoleMessage = "grawp scan instructions"
            if phScan:hasPlayerAtPosition("Science") then
                phScan:addCustomMessage(
                    "Science",
                    horizonConsoleMessage,
                    _(
                        "blackHole-msgScience",
                        "When the ship gets close enough, a button to initiate black hole scan will become available. Click it to start scanning the black hole. The ship must remain within scanning distance for a full 30 seconds to complete the scan."
                    )
                )
                phScan.horizonConsoleMessage = "sent"
            end
            if phScan:hasPlayerAtPosition("Operations") then
                phScan:addCustomMessage(
                    "Operations",
                    horizonConsoleMessage,
                    _(
                        "blackHole-msgOperations",
                        "When the ship gets close enough, a button to initiate black hole scan will become available. Click it to start scanning the black hole. The ship must remain within scanning distance for a full 30 seconds to complete the scan."
                    )
                )
                phScan.horizonConsoleMessage = "sent"
            end
        end
    end
    local grawp_status = nil
    if phScan == nil then
        print("phScan is nil")
    end
    if grawp == nil then
        print("grawp is nil")
    end
    local x1, y1 = phScan:getPosition()
    local x2, y2 = grawp:getPosition()
    if distance(x1, y1, x2, y2) < horizonScanRange then
        grawp_status =
            _("blackHole-tabHelms&Tact&Science&Ops", "Grawp in range")
        if scanGrawpButton then
            if scanGrawp then
                if elapsedScanTime == 0 then
                    elapsedScanTime = delta
                    elapsedScanTimeHalf = delta + 15
                    elapsedScanTimeGoal = delta + 30
                else
                    elapsedScanTime = elapsedScanTime + delta
                end
                if elapsedScanTime > elapsedScanTimeHalf then
                    if phScan.halfScanMessage ~= "sent" then
                        phScan:addToShipLog(
                            _(
                                "blackHole-shipLog",
                                "[Scan technician] Black hole scan 50 percent complete"
                            ),
                            "Blue"
                        )
                        phScan.halfScanMessage = "sent"
                    end
                end
                if elapsedScanTime > elapsedScanTimeGoal then
                    phScan:addToShipLog(
                        _(
                            "blackHole-shipLog",
                            "[Scan technician] Black hole scan complete"
                        ),
                        "Blue"
                    )
                    if horizonScienceScanButton == "scan button" then
                        phScan:removeCustom(horizonScienceScanButton)
                        horizonScienceScanButton = nil
                    end
                    if
                        horizonScienceScanButtonOperations
                        == "scan button operations"
                    then
                        phScan:removeCustom(horizonScienceScanButtonOperations)
                        horizonScienceScanButtonOperations = nil
                    end
                    if grawp_status_helm == "grawp_status_helm" then
                        phScan:removeCustom(grawp_status_helm)
                        grawp_status_helm = nil
                    end
                    if grawp_status_tactical == "grawp_status_tactical" then
                        phScan:removeCustom(grawp_status_tactical)
                        grawp_status_tactical = nil
                    end
                    if grawp_status_science == "grawp_status_science" then
                        phScan:removeCustom(grawp_status_science)
                        grawp_status_science = nil
                    end
                    if grawp_status_operations == "grawp_status_operations" then
                        phScan:removeCustom(grawp_status_operations)
                        grawp_status_operations = nil
                    end
                    requiredMissionCount = requiredMissionCount + 1
                    secondaryOrders = ""
                    horizonMission = "done"
                    for p33idx = 1, 8 do
                        local p33 = getPlayerShip(p33idx)
                        if
                            p33 ~= nil
                            and p33:isValid()
                            and horizonRep == nil
                        then
                            p33:addToShipLog(
                                string.format(
                                    _(
                                        "blackHole-shipLog",
                                        "[Emory] With the scan data provided by %s, we can complete our research on mobile black holes. Thank you. Your assistance is greatly appreciated."
                                    ),
                                    phScan:getCallSign()
                                ),
                                "Magenta"
                            )
                            p33:addReputationPoints(70 - (difficulty * 5))
                            horizonRep = "awarded"
                        end
                    end
                    plotR = nil
                    removeGMFunction("Req Horizon")
                end
                grawp_status = string.format(
                    _(
                        "blackHole-tabHelms&Tact&Science&Ops",
                        "Grawp in range: %i"
                    ),
                    math.ceil(elapsedScanTimeGoal - elapsedScanTime)
                )
            end
        else
            if phScan:hasPlayerAtPosition("Science") then
                horizonScienceScanButton = "scan button"
                phScan:addCustomButton(
                    "Science",
                    horizonScienceScanButton,
                    _("blackHole-buttonScience", "Scan black hole"),
                    scanBlackHole
                )
                scanGrawpButton = true
            end
            if phScan:hasPlayerAtPosition("Operations") then
                horizonScienceScanButtonOperations = "scan button operations"
                phScan:addCustomButton(
                    "Operations",
                    horizonScienceScanButtonOperations,
                    _("blackHole-buttonOperations", "Scan black hole"),
                    scanBlackHole
                )
                scanGrawpButton = true
            end
        end
    else
        grawp_status =
            _("blackHole-tabHelms&Tact&Science&Ops", "Grawp out of range")
        if scanGrawpButton then
            if horizonScienceScanButton == "scan button" then
                phScan:removeCustom(horizonScienceScanButton)
                horizonScienceScanButton = nil
            end
            if
                horizonScienceScanButtonOperations == "scan button operations"
            then
                phScan:removeCustom(horizonScienceScanButtonOperations)
                horizonScienceScanButtonOperations = nil
            end
            phScan:addToShipLog(
                _(
                    "blackHole-shipLog",
                    "[Scan technician] Black hole scan aborted before completion"
                ),
                "Blue"
            )
            phScan.halfScanMessage = "reset"
            elapsedScanTime = 0
            scanGrawp = false
            scanGrawpButton = false
        end
    end
    if plotR ~= nil then
        if phScan:hasPlayerAtPosition("Helms") then
            grawp_status_helm = "grawp_status_helm"
            phScan:addCustomInfo("Helms", grawp_status_helm, grawp_status)
        end
        if phScan:hasPlayerAtPosition("Tactical") then
            grawp_status_tactical = "grawp_status_tactical"
            phScan:addCustomInfo(
                "Tactical",
                grawp_status_tactical,
                grawp_status
            )
        end
        if phScan:hasPlayerAtPosition("Science") then
            grawp_status_science = "grawp_status_science"
            phScan:addCustomInfo("Science", grawp_status_science, grawp_status)
        end
        if phScan:hasPlayerAtPosition("Operations") then
            grawp_status_operations = "grawp_status_operations"
            phScan:addCustomInfo(
                "Operations",
                grawp_status_operations,
                grawp_status
            )
        end
    end
end
function scanBlackHole()
    scanGrawp = true
    phScan:addToShipLog(
        _("blackHole-shipLog", "[Scan technician] Black hole scan started"),
        "Blue"
    )
end
-----------------------------
--  Optional plot choices  --
-----------------------------
-- Optional plot choice: Beam range upgrade
function chooseBeamRangeParts()
    if br1part == nil then
        local br1partChoice = math.floor(random(1, 3))
        if br1partChoice == 1 then
            br1part = "gold"
        elseif br1partChoice == 2 then
            br1part = "nickel"
        else
            br1part = "cobalt"
        end
    end
    if br2part == nil then
        local br2partChoice = math.floor(random(1, 3))
        if br2partChoice == 1 then
            br2part = "lifter"
        elseif br2partChoice == 2 then
            br2part = "filament"
        else
            br2part = "optic"
        end
    end
    if br3part == nil then
        local br3partChoice = math.floor(random(1, 3))
        if br3partChoice == 1 then
            br3part = "robotic"
        elseif br3partChoice == 2 then
            br3part = "nanites"
        else
            br3part = "battery"
        end
    end
end
function beamRangeMessage(delta)
    optionalOrders = string.format(
        _(
            "opt1BeamRangeOrders-comms",
            "\nOptional: Gather and bring goods to station Marconi: %s, %s, %s"
        ),
        br1part,
        br2part,
        br3part
    )
    local obrMsg = string.format(
        _(
            "opt1BeamRangeOrders-shipLog",
            "[Station Marconi] Please bring us some components and materials for a project we are working on: %s, %s, %s"
        ),
        br1part,
        br2part,
        br3part
    )
    if difficulty <= 1 then
        obrMsg = obrMsg
            .. _(
                "opt1BeamRangeOrders-shipLog",
                ". The project relates to improving the range of beam weapons"
            )
    end
    for p18idx = 1, 8 do
        local p18 = getPlayerShip(p18idx)
        if p18 ~= nil and p18:isValid() then
            p18:addToShipLog(obrMsg, "Magenta")
        end
    end
    plotO = beamRangeUpgrade
end
function beamRangeUpgrade(delta)
    if stationMarconi:isValid() then
        for p19idx = 1, 8 do
            local p19 = getPlayerShip(p19idx)
            if p19 ~= nil and p19:isValid() then
                if p19:isDocked(stationMarconi) then
                    if p19.beamComponents == "provided" then
                        beamRangeUpgradeAvailable = true
                        optionalMissionDelay = delta + random(30, 90)
                        beamRangePlot = "done"
                        optionalOrders = ""
                        for p34idx = 1, 8 do
                            local p34 = getPlayerShip(p34idx)
                            if
                                p34 ~= nil
                                and p34:isValid()
                                and beamRangeRep == nil
                            then
                                p34:addReputationPoints(50 - (difficulty * 5))
                                beamRangeRep = "awarded"
                            end
                        end
                        plotO = nil
                        removeGMFunction("Opt Beam Range")
                    end
                end
            end
        end
    else
        beamRangePlot = "done"
        plotO = nil
    end
end
--      Optional plot choice: Beam damage upgrade
function chooseBeamDamageParts()
    if bd1part == nil then
        local bd1partChoice = math.floor(random(1, 3))
        if bd1partChoice == 1 then
            bd1part = "platinum"
        elseif bd1partChoice == 2 then
            bd1part = "tritanium"
        else
            bd1part = "dilithium"
        end
    end
    if bd2part == nil then
        local bd2partChoice = math.floor(random(1, 3))
        if bd2partChoice == 1 then
            bd2part = "sensor"
        elseif bd2partChoice == 2 then
            bd2part = "software"
        else
            bd2part = "android"
        end
    end
    if bd3part == nil then
        local bd3partChoice = math.floor(random(1, 3))
        if bd3partChoice == 1 then
            bd3part = "circuit"
        elseif bd3partChoice == 2 then
            bd3part = "repulsor"
        else
            bd3part = "transporter"
        end
    end
end
function beamDamageMessage(delta)
    optionalOrders = string.format(
        _(
            "opt2BeamDamOrders-comms",
            "\nOptional: Gather and bring goods to station Nefatha: %s, %s, %s"
        ),
        bd1part,
        bd2part,
        bd3part
    )
    local obdMsg = string.format(
        _(
            "opt2BeamDamOrders-shipLog",
            "[Station Nefatha] Please bring us some components and materials for a weapons project we are working on: %s, %s, %s"
        ),
        bd1part,
        bd2part,
        bd3part
    )
    if difficulty <= 1 then
        obdMsg = obdMsg
            .. _(
                "opt2BeamDam-shipLog",
                ". The project relates to increasing the amount of damage that a beam weapon inflicts on the target"
            )
    end
    for p20idx = 1, 8 do
        local p20 = getPlayerShip(p20idx)
        if p20 ~= nil and p20:isValid() then
            p20:addToShipLog(obdMsg, "Magenta")
        end
    end
    plotO = beamDamageUpgrade
end
function beamDamageUpgrade(delta)
    if stationNefatha:isValid() then
        for p21idx = 1, 8 do
            local p21 = getPlayerShip(p21idx)
            if p21 ~= nil and p21:isValid() then
                if p21:isDocked(stationNefatha) then
                    if p21.beamDamageComponents == "provided" then
                        beamDamageUpgradeAvailable = true
                        optionalMissionDelay = delta + random(30, 90)
                        beamDamagePlot = "done"
                        optionalOrders = ""
                        for p35idx = 1, 8 do
                            local p35 = getPlayerShip(p35idx)
                            if
                                p35 ~= nil
                                and p35:isValid()
                                and beamDamageRep == nil
                            then
                                p35:addReputationPoints(50 - (difficulty * 5))
                                beamDamageRep = "awarded"
                            end
                        end
                        plotO = nil
                        removeGMFunction("Opt Beam Damage")
                    end
                end
            end
        end
    else
        beamDamagePlot = "done"
        plotO = nil
        removeGMFunction("Opt Beam Damage")
    end
end
--      Optional plot choice: Spin upgrade - maneuver
function chooseSpinBaseParts()
    if sp1part == nil then
        local sp1partChoice = math.random(3)
        if sp1partChoice == 1 then
            sp1part = "platinum"
        elseif sp1partChoice == 2 then
            sp1part = "dilithium"
        else
            sp1part = "gold"
        end
    end
    if sp2part == nil then
        local sp2partChoice = math.random(3)
        if sp2partChoice == 1 then
            sp2part = "tractor"
        elseif sp2partChoice == 2 then
            sp2part = "transporter"
        else
            sp2part = "impulse"
        end
    end
    if sp3part == nil then
        local sp3partChoice = math.random(3)
        if sp3partChoice == 1 then
            sp3part = "battery"
        elseif sp3partChoice == 2 then
            sp3part = "android"
        else
            sp3part = "robotic"
        end
    end
    if spinBase == nil then
        local spinBaseChoice = math.random(3)
        if spinBaseChoice == 1 then
            if stationCalifornia:isValid() then
                spinBase = stationCalifornia
            elseif stationScience2:isValid() then
                spinBase = stationScience2
            else
                spinBase = stationOutpost33
            end
        elseif spinBaseChoice == 2 then
            if stationScience2:isValid() then
                spinBase = stationScience2
            elseif stationOutpost33:isValid() then
                spinBase = stationOutpost33
            else
                spinBase = stationCalifornia
            end
        else
            if stationOutpost33:isValid() then
                spinBase = stationOutpost33
            elseif stationCalifornia:isValid() then
                spinBase = stationCalifornia
            else
                spinBase = stationScience2
            end
        end
    end
end
function spinMessage(delta)
    optionalOrders = string.format(
        _(
            "opt3SpinOrders-comms",
            "\nOptional: Bring %s, %s and %s to station %s in sector %s"
        ),
        sp1part,
        sp2part,
        sp3part,
        spinBase:getCallSign(),
        spinBase:getSectorName()
    )
    local spMsg = string.format(
        _(
            "opt3SpinOrders-shipLog",
            "[Station %s, sector %s] Please bring us some goods to help us with a project: %s, %s, %s"
        ),
        spinBase:getCallSign(),
        spinBase:getSectorName(),
        sp1part,
        sp2part,
        sp3part
    )
    if difficulty <= 1 then
        spMsg = spMsg
            .. _(
                "opt3SpinOrders-shipLog",
                ". The project relates to improved ship maneuverability"
            )
    end
    for p28idx = 1, 8 do
        local p28 = getPlayerShip(p28idx)
        if p28 ~= nil and p28:isValid() then
            p28:addToShipLog(spMsg, "Magenta")
        end
    end
    plotO = spinUpgrade
end
function spinUpgrade(delta)
    if spinBase:isValid() then
        for p29idx = 1, 8 do
            local p29 = getPlayerShip(p29idx)
            if p29 ~= nil and p29:isValid() then
                if p29:isDocked(spinBase) then
                    if p29.spinComponents == "provided" then
                        spinUpgradeAvailable = true
                        optionalMissionDelay = delta + random(30, 90)
                        spinPlot = "done"
                        optionalOrders = ""
                        for p36idx = 1, 8 do
                            p36 = getPlayerShip(p36idx)
                            if
                                p36 ~= nil
                                and p36:isValid()
                                and spinRep == nil
                            then
                                p36:addReputationPoints(50 - (difficulty * 5))
                                spinRep = "awarded"
                            end
                        end
                        plotO = nil
                        removeGMFunction("Opt Spin")
                    end
                end
            end
        end
    else
        spinPlot = "done"
        plotO = nil
        removeGMFunction("Opt Spin")
    end
end
--      Optional plot choice: Impulse speed upgrade
function impulseSpeedParts()
    if is1part == nil then
        local is1partChoice = math.floor(random(1, 3))
        if is1partChoice == 1 then
            is1part = "nickel"
        elseif is1partChoice == 2 then
            is1part = "tritanium"
        else
            is1part = "cobalt"
        end
    end
    if is2part == nil then
        local is2partChoice = math.floor(random(1, 3))
        if is2partChoice == 1 then
            is2part = "software"
        elseif is2partChoice == 2 then
            is2part = "robotic"
        else
            is2part = "android"
        end
    end
    if morrisonBase == nil then
        local morrisonBaseChoice = math.floor(random(1, 3))
        if morrisonBaseChoice == 1 then
            morrisonBase = stationResearch11
        elseif morrisonBaseChoice == 2 then
            morrisonBase = stationScience4
        else
            morrisonBase = stationScience2
        end
    end
    morrisonBaseName = morrisonBase:getCallSign()
    morrisonBaseSector = morrisonBase:getSectorName()
end
function impulseSpeedMessage(delta)
    optionalOrders = string.format(
        _(
            "opt4ImpulseOrders-comms",
            "\nOptional: Get Nikhil Morrison from station %s in sector %s"
        ),
        morrisonBaseName,
        morrisonBaseSector
    )
    local oisMsg = string.format(
        _(
            "opt4ImpulseOrders-shipLog",
            "[Station %s] Research scientist Nikhil Morrison is close to a breakthrough on his project, but needs some assistance. Dock with us if you wish to help."
        ),
        morrisonBaseName
    )
    for p22idx = 1, 8 do
        local p22 = getPlayerShip(p22idx)
        if p22 ~= nil and p22:isValid() then
            p22:addToShipLog(oisMsg, "Magenta")
        end
    end
    plotO = impulseSpeedPartMessage
end
function impulseSpeedPartMessage(delta)
    if morrisonBase:isValid() then
        for p23idx = 1, 8 do
            local p23 = getPlayerShip(p23idx)
            if p23 ~= nil and p23:isValid() then
                if p23:isDocked(morrisonBase) then
                    if p23.morrison ~= "aboard" then
                        p23.morrison = "aboard"
                        p23:addToShipLog(
                            _(
                                "opt4Impulse-shipLog",
                                "Nikhil Morrison is aboard"
                            ),
                            "Magenta"
                        )
                        p23:addToShipLog(
                            string.format(
                                _(
                                    "Opt4ImpulseOrders-shipLog",
                                    "He requests that you get %s and %s type goods and take him to station Cyrus"
                                ),
                                is1part,
                                is2part
                            ),
                            "Magenta"
                        )
                        if difficulty <= 1 then
                            p23:addToShipLog(
                                _(
                                    "opt4Impulse-shipLog",
                                    "He says his project relates to increasing ship impulse speeds"
                                ),
                                "Magenta"
                            )
                        end
                        optionalOrders = string.format(
                            _(
                                "opt4ImpulseOrders-comms",
                                "\nOptional: Get %s and %s and transport Nikhil Morrison to station Cyrus"
                            ),
                            is1part,
                            is2part
                        )
                        plotO = impulseSpeedUpgrade
                    end
                end
            end
        end
    else
        impulseSpeedPlot = "done"
        plotO = nil
        removeGMFunction("Opt Impulse")
    end
end
function impulseSpeedUpgrade(delta)
    if stationCyrus:isValid() then
        for p24idx = 1, 8 do
            local p24 = getPlayerShip(p24idx)
            if p24 ~= nil and p24:isValid() then
                if p24:isDocked(stationCyrus) then
                    if p24.impulseSpeedComponents == "provided" then
                        impulseSpeedUpgradeAvailable = true
                        optionalMissionDelay = delta + random(30, 90)
                        impulseSpeedPlot = "done"
                        optionalOrders = ""
                        for p37idx = 1, 8 do
                            local p37 = getPlayerShip(p37idx)
                            if
                                p37 ~= nil
                                and p37:isValid()
                                and impulseSpeedRep == nil
                            then
                                p37:addReputationPoints(50 - (difficulty * 5))
                                impulseSpeedRep = "awarded"
                            end
                        end
                        plotO = nil
                        removeGMFunction("Opt Impulse")
                    end
                end
            end
        end
    else
        impulseSpeedPlot = "done"
        plotO = nil
        removeGMFunction("Opt Impulse")
    end
end
--      Optional plot choice: Get quantum biometric artifact
function quantumArtMessage(delta)
    if stationOrgana:isValid() then
        optionalOrders = string.format(
            _(
                "opt5ShieldsOrders-comms",
                "\nOptional: Retrieve artifact with quantum biometric characteristics and bring to station Organa in sector %s"
            ),
            stationOrgana:getSectorName()
        )
        local qaMsg = string.format(
            _(
                "opt5ShieldsOrders-shipLog",
                "[Station Organa, sector %s] Research scientist Phillip Solo of the royal research academy finished the theoretical research portion of his dissertation. He needs an artifact with quantum biometric characteristics to apply his research. Please retrieve an artifact with quantum biometric characteristics and bring it to Organa station"
            ),
            stationOrgana:getSectorName()
        )
        if difficulty <= 1 then
            qaMsg = qaMsg
                .. string.format(
                    _(
                        "opt5Shields-shipLog",
                        ". Possible items to examine have been located in %s, %s and %s"
                    ),
                    art1:getSectorName(),
                    art2:getSectorName(),
                    art3:getSectorName()
                )
        end
        for p40idx = 1, 8 do
            local p40 = getPlayerShip(p40idx)
            if p40 ~= nil and p40:isValid() then
                p40:addToShipLog(qaMsg, "Magenta")
            end
        end
        if art1.quantum then
            artQ = art1
        elseif art2.quantum then
            artQ = art2
        else
            artQ = art3
        end
        if difficulty <= 1 then
            quantumArtHintDelay = 60
        else
            quantumArtHintDelay = 120
        end
        plotO = quantumRetrieveArt
    else -- station Organa destroyed
        plotO = nil
        quantumArtPlot = "done"
        removeGMFunction("Opt Shield")
    end
end
function quantumRetrieveArt(delta)
    if artQ ~= nil and artQ:isValid() then
        if artQ:isScannedByFaction("Human Navy") then
            artQ:allowPickup(true)
        end
        quantumArtHintDelay = quantumArtHintDelay - delta
        local cptad = 999999 -- closest player to artifact distance
        local closestPlayer = nil
        for p41idx = 1, 8 do
            local p41 = getPlayerShip(p41idx)
            if p41 ~= nil and p41:isValid() then
                if artQ == nil then
                    print("artQ is nil")
                end
                if p41 == nil then
                    print("p41 is nil")
                end
                local x1, y1 = artQ:getPosition()
                local x2, y2 = p41:getPosition()
                local clpd = distance(x1, y1, x2, y2) -- current loop player distance
                if clpd < cptad then
                    cptad = clpd
                    closestPlayer = p41
                end
            end
        end
        if quantumArtHintDelay < 0 then
            if quantumArtHint == nil and closestPlayer ~= nil then
                closestPlayer:addToShipLog(
                    string.format(
                        _(
                            "opt5Shields-shipLog",
                            "[Station Organa] We just received a report that an artifact with quantum biometric characteristics may have been observed in sector %s"
                        ),
                        artQ:getSectorName()
                    ),
                    "Magenta"
                )
                if difficulty <= 1 then
                    closestPlayer:addToShipLog(
                        _(
                            "opt5Shields-shipLog",
                            "Solo's research may have application for ship shield systems"
                        ),
                        "Magenta"
                    )
                end
                quantumArtHint = "delivered"
            end
        end
        for p42idx = 1, 8 do
            local p42 = getPlayerShip(p42idx)
            if p42 ~= nil and p42:isValid() then
                if p42 == closestPlayer then
                    p42.artQ = true
                else
                    p42.artQ = false
                end
            end
        end
    else
        plotO = quantumDeliverArt
    end
end
function quantumDeliverArt(delta)
    if stationOrgana:isValid() then
        for p44idx = 1, 8 do
            local p44 = getPlayerShip(p44idx)
            if p44.artQ then
                if p44.artQaboardMessage == nil then
                    p44:addToShipLog(
                        _("opt5Shields-shipLog", "Artifact is aboard"),
                        "Magenta"
                    )
                    p44.artQaboardMessage = "sent"
                end
                if p44:isDocked(stationOrgana) then
                    p44:addToShipLog(
                        _(
                            "opt5Shields-shipLog",
                            "[Phillip Organa] Thanks for the artifact. I completed my research. Next time you dock with Vaiken, you can improve your shield effectiveness."
                        ),
                        "Magenta"
                    )
                    shieldUpgradeAvailable = true
                    p44:addReputationPoints(50 - (difficulty * 5))
                    quantumArtPlot = "done"
                    plotO = nil
                    removeGMFunction("Opt Shield")
                end
            end
        end
    else
        quantumArtPlot = "done"
        plotO = nil
        removeGMFunction("Opt Shield")
    end
end
function vaikenStatus(delta)
    if stationVaiken:isValid() then
        local shields_damaged = false
        local shield_index = 0
        local shield_level_total = 0
        local shield_max_total = 0
        local shield_level = 0
        local shield_max = 0
        local shield_report = _("Vaiken-shipLog", "Shields:")
        local critical_shield = ""
        repeat
            shield_level = stationVaiken:getShieldLevel(shield_index)
            shield_max = stationVaiken:getShieldMax(shield_index)
            if shield_level < shield_max then
                shields_damaged = true
            end
            shield_level_total = shield_level_total + shield_level
            shield_max_total = shield_max_total + shield_max
            shield_report = shield_report
                .. string.format(
                    _("Vaiken-shipLog", " %i:%i/%i"),
                    shield_index,
                    math.floor(shield_level),
                    math.floor(shield_max)
                )
            if shield_level / shield_max < 0.2 then
                critical_shield = critical_shield
                    .. string.format(
                        _("Vaiken-shipLog", "Shield %i is critical "),
                        shield_index
                    )
            end
            shield_index = shield_index + 1
        until shield_index >= stationVaiken:getShieldCount()
        if shields_damaged then
            vaiken_damage_timer = vaiken_damage_timer - delta
            if vaiken_damage_timer < 0 then
                if shield_level_total / shield_max_total < 0.85 then
                    local hull_max = stationVaiken:getHullMax()
                    local hull_level = stationVaiken:getHull()
                    local hull_damage = hull_level / hull_max
                    for pidx = 1, 8 do
                        local p = getPlayerShip(pidx)
                        if p ~= nil and p:isValid() then
                            p:addToShipLog(
                                _(
                                    "Vaiken-shipLog",
                                    "[Vaiken] Station shields have been damaged. "
                                )
                                    .. shield_report,
                                "Magenta"
                            )
                            if critical_shield ~= "" then
                                p:addToShipLog(
                                    _("Vaiken-shipLog", "[Vaiken] ")
                                        .. critical_shield,
                                    "Red"
                                )
                                if hull_damage < 0.4 then
                                    p:addToShipLog(
                                        string.format(
                                            _(
                                                "Vaiken-shipLog",
                                                "[Vaiken] Hull damage: %i out of %i"
                                            ),
                                            math.floor(hull_level),
                                            math.floor(hull_max)
                                        ),
                                        "Red"
                                    )
                                elseif hull_damage < 0.8 then
                                    p:addToShipLog(
                                        string.format(
                                            _(
                                                "Vaiken-shipLog",
                                                "[Vaiken] Hull damage: %i out of %i"
                                            ),
                                            math.floor(hull_level),
                                            math.floor(hull_max)
                                        ),
                                        "Magenta"
                                    )
                                end
                            end
                        end
                    end
                    if critical_shield ~= "" then
                        vaiken_damage_timer_interval = 60
                        if hull_damage < 0.4 then
                            vaiken_damage_timer_interval = 30
                        end
                    else
                        vaiken_damage_timer_interval = 120
                    end
                else
                    for pidx = 1, 8 do
                        local p = getPlayerShip(pidx)
                        if p ~= nil and p:isValid() then
                            p:addToShipLog(
                                _(
                                    "Vaiken-shipLog",
                                    "[Vaiken] Station has been damaged"
                                ),
                                "Magenta"
                            )
                        end
                    end
                    vaiken_damage_timer_interval = 120
                end
                vaiken_damage_timer = delta + vaiken_damage_timer_interval
            end
        end
    else
        showGameEndStatistics()
        victory("Kraylor")
    end
end
function update(delta)
    if delta == 0 then
        --game paused
        setPlayers()
        return
    end
    if initial_defense_fleet == nil then
        initial_defense_fleet = "spawned"
        for _, pStation in ipairs(defensive_station_list) do
            local o_x, o_y = pStation:getPosition()
            local defense_fleet =
                spawnEnemies(o_x, o_y, 1, pStation:getFaction())
            for _, ship in ipairs(defense_fleet) do
                local p = getPlayerShip(-1)
                if p ~= nil and p:isValid() and p:isFriendly(ship) then
                    local temp_faction = ship:getFaction()
                    ship:setFaction("Independent")
                    ship:orderDefendTarget(pStation)
                    ship:setFaction(temp_faction)
                else
                    ship:orderDefendTarget(pStation)
                end
            end
        end
    end
    if playWithTimeLimit then
        gameTimeLimit = gameTimeLimit - delta
        if gameTimeLimit < 0 then
            showGameEndStatistics()
            if requiredMissionCount > 0 and plotR == nil then
                victory("Human Navy")
            else
                victory("Kraylor")
            end
        end
        -- select required mission
        if plotR == nil then
            -- timed missions
            local requiredMissionChoice = math.random(4)
            if requiredMissionChoice == 1 then
                if
                    undercutMission ~= "done"
                    and undercutLocation ~= "free"
                    and gameTimeLimit < 2670
                    and gameTimeLimit > 2400
                then
                    mPart = 1
                    plotR = undercutOrderMessage
                    chooseUndercutBase()
                end
                removeGMFunction("Req Undercut")
            elseif requiredMissionChoice == 2 then
                if
                    stettorMission ~= "done"
                    and gameTimeLimit < 2670
                    and gameTimeLimit > 1800
                then
                    chooseSensorBase()
                    chooseSensorParts()
                    plotR = stettorOrderMessage
                end
                removeGMFunction("Req Stettor")
            elseif requiredMissionChoice == 3 then
                if
                    horizonMission ~= "done"
                    and gameTimeLimit < 2670
                    and gameTimeLimit > 1200
                then
                    chooseHorizonParts()
                    plotR = horizonOrderMessage
                end
                removeGMFunction("Req Horizon")
            else
                if
                    sporiskyMission ~= "done"
                    and gameTimeLimit < 2670
                    and gameTimeLimit > 1700
                then
                    chooseTraitorBase()
                    plotR = traitorOrderMessage
                end
                removeGMFunction("Req Sporisky")
            end
        end
        local game_time_status = _("-tabRelay&Operations", "Game Timer")
        local game_minutes = math.floor(gameTimeLimit / 60)
        local game_seconds = math.floor(gameTimeLimit % 60)
        if game_minutes <= 0 then
            game_time_status = string.format(
                _("-tabRelay&Operations", "%s %i"),
                game_time_status,
                game_seconds
            )
        else
            game_time_status = string.format(
                _("-tabRelay&Operations", "%s %i:%.2i"),
                game_time_status,
                game_minutes,
                game_seconds
            )
        end
        for pidx = 1, 8 do
            local p = getPlayerShip(pidx)
            if p ~= nil and p:isValid() then
                if p:hasPlayerAtPosition("Relay") then
                    p.game_time_status = "game_time_status"
                    p:addCustomInfo(
                        "Relay",
                        p.game_time_status,
                        game_time_status
                    )
                end
                if p:hasPlayerAtPosition("Operations") then
                    p.game_time_status_operations =
                        "game_time_status_operations"
                    p:addCustomInfo(
                        "Operations",
                        p.game_time_status_operations,
                        game_time_status
                    )
                end
            end
        end
    else
        clueMessageDelay = clueMessageDelay - delta
        if clueMessageDelay < 0 then
            if clueMessage ~= "delivered" then
                local clMsg = _(
                    "clueOrders-shipLog",
                    "Intelligence has analyzed all the enemy activity in this area and has determined that there must be three enemy bases. Find these bases and destroy them."
                )
                local enemyBaseCount = 0
                if stationEmpok:isValid() then
                    enemyBaseCount = enemyBaseCount + 1
                end
                if stationTic:isValid() then
                    enemyBaseCount = enemyBaseCount + 1
                end
                if stationGanalda:isValid() then
                    enemyBaseCount = enemyBaseCount + 1
                end
                if enemyBaseCount == 1 then
                    clMsg = clMsg
                        .. _(
                            "clueOrders-shipLog",
                            " You have already destroyed two of them."
                        )
                elseif enemyBaseCount == 2 then
                    clMsg = clMsg
                        .. _(
                            "clueOrders-shipLog",
                            " You have already destroyed one of them."
                        )
                end
                primaryOrders = _(
                    "clueOrders-comms",
                    "Defend bases in the area (human navy and independent) from enemy attack and destroy three enemy bases."
                )
                for p43idx = 1, 8 do
                    local p43 = getPlayerShip(p43idx)
                    if p43 ~= nil and p43:isValid() then
                        p43:addToShipLog(clMsg, "Magenta")
                    end
                end
                clueMessage = "delivered"
            end
        end
        if plotR == nil then
            requiredMissionDelay = requiredMissionDelay - delta
            if
                requiredMissionCount > 0
                and not stationEmpok:isValid()
                and not stationTic:isValid()
                and not stationGanalda:isValid()
            then
                showGameEndStatistics()
                victory("Human Navy")
            end
            if requiredMissionDelay < 0 then
                requiredMissionChoice = math.random(4)
                if requiredMissionChoice == 1 then
                    if
                        undercutMission ~= "done"
                        and undercutLocation ~= "free"
                    then
                        plotR = undercutOrderMessage
                        chooseUndercutBase()
                    end
                    removeGMFunction("Req Undercut")
                elseif requiredMissionChoice == 2 then
                    if stettorMission ~= "done" then
                        chooseSensorBase()
                        chooseSensorParts()
                        plotR = stettorOrderMessage
                    end
                    removeGMFunction("Req Stettor")
                elseif requiredMissionChoice == 3 then
                    if horizonMission ~= "done" then
                        chooseHorizonParts()
                        plotR = horizonOrderMessage
                    end
                    removeGMFunction("Req Horizon")
                else
                    if sporiskyMission ~= "done" then
                        chooseTraitorBase()
                        plotR = traitorOrderMessage
                    end
                    removeGMFunction("Req Sporisky")
                end
                requiredMissionDelay = delta + random(10, 30)
            end
        end
        if update_loop_diagnostic then
            local plot_name = ""
            local first_reference_station_name = ""
            local first_reference_station_sector = ""
            local first_part = ""
            local second_part = ""
            local third_part = ""
            local elapsed_time = 0
            if plotR == undercutOrderMessage then
                plot_name = "Required plot Undercut order message"
                if hideStationName ~= nil then
                    first_reference_station_name = hideStationName
                end
                if hideStationSector ~= nil then
                    first_reference_station_sector = hideStationSector
                end
                --print("Required plot Undercut order message " .. hideStationName .. " " .. hideStationSector .. ". Required missions completed: " .. requiredMissionCount)
            elseif plotR == stettorOrderMessage then
                plot_name = "Required plot Stettor order message. Sensor base"
                if sensorBaseName ~= nil then
                    first_reference_station_name = sensorBaseName
                end
                if sensorBaseSector ~= nil then
                    first_reference_station_sector = sensorBaseSector
                end
                if s1part ~= nil then
                    first_part = s1part
                end
                if s2part ~= nil then
                    second_part = s2part
                end
                if s3part ~= nil then
                    third_part = s3part
                end
                --print("Required plot Stettor order message. Sensor base: " .. sensorBaseName .. " " .. sensorBaseSector .. ". Parts: " .. s1part .. ", " .. s2part .. ", " .. s3part .. ". Required missions completed: " .. requiredMissionCount)
            elseif plotR == horizonOrderMessage then
                plot_name = "Required plot Horizon order message. Parts"
                if hr1part ~= nil then
                    first_part = hr1part
                end
                if hr2part ~= nil then
                    second_part = hr2part
                end
                --print("Required plot Horizon order message. Parts: " .. hr1part .. ", " .. hr2part .. ". Required missions completed: " .. requiredMissionCount)
            elseif plotR == traitorOrderMessage then
                plot_name = "Required plot Traitor order message. Traitor base"
                if traitorBaseName ~= nil then
                    first_reference_station_name = traitorBaseName
                end
                if traitorBaseSector ~= nil then
                    first_reference_station_sector = traitorBaseSector
                end
                --print("Required plot Traitor order message. Traitor base: " .. traitorBaseName .. " " .. traitorBaseSector .. ". Required missions completed: " .. requiredMissionCount)
            elseif plotR == undercutStation then
                plot_name = "Required plot Undercut station"
                if hideStationName ~= nil then
                    first_reference_station_name = hideStationName
                end
                if hideStationSector ~= nil then
                    first_reference_station_sector = hideStationSector
                end
                --print("Required plot Undercut station " .. hideStationName .. " " .. hideStationSector .. ". Required missions completed: " .. requiredMissionCount)
            elseif plotR == undercutTransport then
                plot_name = "Required plot Undercut transport"
                if hideTransport ~= nil then
                    if hideTransport:isValid() then
                        first_reference_station_name =
                            hideTransport:getCallSign()
                        first_reference_station_sector =
                            hideTransport:getSectorName()
                    else
                        first_reference_station_name = "not valid"
                    end
                end
                --print("Required plot Undercut transport " .. hideTransport:getCallSign() .. " " .. hideTransport:getSectorName() .. ". Required missions completed: " .. requiredMissionCount)
            elseif plotR == undercutEnemyBase then
                plot_name = "Required plot Undercut enemy base"
                if undercutTarget ~= nil then
                    if undercutTarget:isValid() then
                        first_reference_station_name =
                            undercutTarget:getCallSign()
                        first_reference_station_sector =
                            undercutTarget:getSectorName()
                    else
                        first_reference_station_name = "not valid"
                    end
                end
                --print("Required plot Undercut enemy base " .. undercutTarget:getCallSign() .. " " .. undercutTarget:getSectorName() .. ". Required missions completed: " .. requiredMissionCount)
            elseif plotR == stettorStation then
                plot_name = "Required plot Stettor station. Sensor base"
                if sensorBaseName ~= nil then
                    first_reference_station_name = sensorBaseName
                end
                if sensorBaseSector ~= nil then
                    first_reference_station_sector = sensorBaseSector
                end
                if s1part ~= nil then
                    first_part = s1part
                end
                if s2part ~= nil then
                    second_part = s2part
                end
                if s3part ~= nil then
                    third_part = s3part
                end
                --print("Required plot Stettor station. Sensor base: " .. sensorBaseName .. " " .. sensorBaseSector .. ". Parts: " .. s1part .. ", " .. s2part .. ", " .. s3part .. ". Required missions completed: " .. requiredMissionCount)
            elseif plotR == stettorEnemyBase then
                plot_name = "Required plot Stettor enemy base"
                if stettorTarget ~= nil then
                    if stettorTarget:isValid() then
                        first_reference_station_name =
                            stettorTarget:getCallSign()
                        first_reference_station_sector =
                            stettorTarget:getSectorName()
                    else
                        first_reference_station_name = "not valid"
                    end
                end
                --print("Required plot Stettor enemy base " .. stettorTarget:getCallSign() .. " " .. stettorTarget:getSectorName() .. ". Required missions completed: " .. requiredMissionCount)
            elseif plotR == traitorStation then
                plot_name = "Required plot Traitor station. Traitor base"
                if traitorBaseName ~= nil then
                    first_reference_station_name = traitorBaseName
                end
                if traitorBaseSector ~= nil then
                    first_reference_station_sector = traitorBaseSector
                end
                --print("Required plot Traitor station. Traitor base: " .. traitorBaseName .. " " .. traitorBaseSector .. ". Required missions completed: " .. requiredMissionCount)
            elseif plotR == sporiskyTransport then
                plot_name = "Required plot Sporisky transport"
                if runTransport ~= nil then
                    if runTransport:isValid() then
                        first_reference_station_name =
                            runTransport:getCallSign()
                        first_reference_station_sector =
                            runTransport:getSectorName()
                    else
                        first_reference_station_name = "not valid"
                    end
                end
                --print("Required plot Sporisky transport " .. runTransport:getCallSign() .. " " .. runTransport:getSectorName() .. ". Required missions completed: " .. requiredMissionCount)
            elseif plotR == sporiskyQuestioned then
                plot_name = "Required plot Sporisky questioned"
                --print("Required plot Sporisky questioned. Required missions completed: " .. requiredMissionCount)
            elseif plotR == sporiskyEnemyBase then
                plot_name = "Required plot Sporisky enemy base"
                if sporiskyTarget ~= nil then
                    if sporiskyTarget:isValid() then
                        first_reference_station_name =
                            sporiskyTarget:getCallSign()
                        first_reference_station_sector =
                            sporiskyTarget:getSectorName()
                    else
                        first_reference_station_name = "not valid"
                    end
                end
                --print("Required plot Sporisky enemy base " .. sporiskyTarget:getCallSign() .. " " .. sporiskyTarget:getSectorName() .. ". Required missions completed: " .. requiredMissionCount)
            elseif plotR == horizonStationDeliver then
                plot_name = "Required plot Horizon station deliver. Parts"
                if hr1part ~= nil then
                    first_part = hr1part
                end
                if hr2part ~= nil then
                    second_part = hr2part
                end
                --print("Required plot Horizon station deliver. Parts: " .. hr1part .. ", " .. hr2part .. ". Required missions completed: " .. requiredMissionCount)
            elseif plotR == horizonScienceMessage then
                plot_name = "Required plot Horizon science message"
                if elapsedScanTime ~= nil then
                    elapsed_time = elapsedScanTime
                else
                    elapsed_time = -1
                end
                --print(string.format("Required plot Horizon science message. Elapsed scan time: %i. Required missions completed: %i",math.floor(elapsedScanTime),requiredMissionCount))
            else
                plot_name = "Required plot undefined"
                --print("Required plot undefined")
            end
            print(
                string.format(
                    "%s %s %s %s %s %s Required missions completed: %i",
                    plot_name,
                    first_reference_station_name,
                    first_reference_station_sector,
                    first_part,
                    second_part,
                    third_part,
                    requiredMissionCount
                )
            )
        end
    end
    -- select optional mission
    if plotO == nil then
        optionalMissionDelay = optionalMissionDelay - delta
        if optionalMissionDelay < 0 then
            local optionalMissionChoice = math.random(5)
            if optionalMissionChoice == 1 then
                if beamRangePlot ~= "done" then
                    chooseBeamRangeParts()
                    plotO = beamRangeMessage
                end
                removeGMFunction("Opt Beam Range")
            elseif optionalMissionChoice == 2 then
                if impulseSpeedPlot ~= "done" then
                    impulseSpeedParts()
                    plotO = impulseSpeedMessage
                end
                removeGMFunction("Opt Impulse")
            elseif optionalMissionChoice == 3 then
                if spinPlot ~= "done" then
                    chooseSpinBaseParts()
                    plotO = spinMessage
                end
                removeGMFunction("Opt Spin")
            elseif optionalMissionChoice == 4 then
                if quantumArtPlot ~= "done" then
                    plotO = quantumArtMessage
                end
                removeGMFunction("Opt Shield")
            else
                if beamDamagePlot ~= "done" then
                    chooseBeamDamageParts()
                    plotO = beamDamageMessage
                end
                removeGMFunction("Opt Beam Damage")
            end
            optionalMissionDelay = delta + random(20, 40)
        end
    end
    if optional_mission_loop_diagnostic then
        plot_name = ""
        first_reference_station_name = ""
        first_reference_station_sector = ""
        first_part = ""
        second_part = ""
        third_part = ""
        if plotO == beamRangeMessage then
            plot_name = "Optional beam range message"
            if stationMarconi:isValid() then
                first_reference_station_name = "Marconi"
                first_reference_station_sector = stationMarconi:getSectorName()
            else
                first_reference_station_name = "not valid"
            end
            if br1part ~= nil then
                first_part = br1part
            end
            if br2part ~= nil then
                second_part = br2part
            end
            if br3part ~= nil then
                third_part = br3part
            end
        elseif plotO == beamRangeUpgrade then
            plot_name = "Optional beam range upgrade"
            if stationMarconi:isValid() then
                first_reference_station_name = "Marconi"
                first_reference_station_sector = stationMarconi:getSectorName()
            else
                first_reference_station_name = "not valid"
            end
            if br1part ~= nil then
                first_part = br1part
            end
            if br2part ~= nil then
                second_part = br2part
            end
            if br3part ~= nil then
                third_part = br3part
            end
        elseif plotO == impulseSpeedMessage then
            plot_name = "Optional impulse speed message"
            if morrisonBase ~= nil then
                if morrisonBase:isValid() then
                    first_reference_station_name = morrisonBase:getCallSign()
                    first_reference_station_sector =
                        morrisonBase:getSectorName()
                else
                    first_reference_station_name = "not valid"
                end
            end
        elseif plotO == impulseSpeedPartMessage then
            plot_name = "Optional impulse speed part message"
            if morrisonBase ~= nil then
                if morrisonBase:isValid() then
                    first_reference_station_name = morrisonBase:getCallSign()
                    first_reference_station_sector =
                        morrisonBase:getSectorName()
                else
                    first_reference_station_name = "not valid"
                end
            end
        elseif plotO == impulseSpeedUpgrade then
            plot_name = "Optional impulse speed upgrade"
            if stationCyrus:isValid() then
                first_reference_station_name = "Cyrus"
                first_reference_station_sector = stationCyrus:getSectorName()
            else
                first_reference_station_name = "not valid"
            end
            if is1part ~= nil then
                first_part = is1part
            end
            if is2part ~= nil then
                second_part = is2part
            end
        elseif plotO == spinMessage then
            plot_name = "Optional spin message"
            if spinBase ~= nil then
                if spinBase:isValid() then
                    first_reference_station_name = spinBase:getCallSign()
                    first_reference_station_sector = spinBase:getSectorName()
                else
                    first_reference_station_name = "not valid"
                end
            end
            if sp1part ~= nil then
                first_part = sp1part
            end
            if sp2part ~= nil then
                second_part = sp2part
            end
            if sp3part ~= nil then
                third_part = sp3part
            end
        elseif plotO == spinUpgrade then
            plot_name = "Optional spin upgrade"
            if spinBase ~= nil then
                if spinBase:isValid() then
                    first_reference_station_name = spinBase:getCallSign()
                    first_reference_station_sector = spinBase:getSectorName()
                else
                    first_reference_station_name = "not valid"
                end
            end
            if sp1part ~= nil then
                first_part = sp1part
            end
            if sp2part ~= nil then
                second_part = sp2part
            end
            if sp3part ~= nil then
                third_part = sp3part
            end
        elseif plotO == quantumArtMessage then
            plot_name = "Optional quantum artifact message"
        elseif plotO == quantumRetrieveArt then
            plot_name = "Optional quantum retrieve artifact"
            if artQ ~= nil then
                if artQ:isValid() then
                    first_reference_station_sector = artQ:getSectorName()
                else
                    first_reference_station_sector = "not valid"
                end
            end
        elseif plotO == quantumDeliverArt then
            plot_name = "Optional quantum deliver artifact"
            if stationOrgana ~= nil then
                if stationOrgana:isValid() then
                    first_reference_station_name = "Organa"
                    first_reference_station_sector =
                        stationOrgana:getSectorName()
                else
                    first_reference_station_name = "not valid"
                end
            end
        elseif plotO == beamDamageMessage then
            plot_name = "Optional beam damage message"
        elseif plotO == beamDamageUpgrade then
            plot_name = "Optional beam damage upgrade"
            if stationNefatha ~= nil then
                if stationNefatha:isValid() then
                    first_reference_station_name = "Nefatha"
                    first_reference_station_sector =
                        stationNefatha:getSectorName()
                else
                    first_reference_station_name = "not valid"
                end
            end
            if bd1part ~= nil then
                first_part = bd1part
            end
            if bd2part ~= nil then
                second_part = bd2part
            end
            if bd3part ~= nil then
                third_part = bd3part
            end
        else
            plot_name = "Optional plot undefined"
        end
        print(
            string.format(
                "%s %s %s %s %s %s",
                plot_name,
                first_reference_station_name,
                first_reference_station_sector,
                first_part,
                second_part,
                third_part
            )
        )
    end
    vaikenStatus(delta)
    if patrolPlot ~= nil then
        patrolPlot(delta)
    end
    if plotR ~= nil then
        plotR(delta) --required mission
    end
    if plotO ~= nil then
        plotO(delta) --optional mission
    end
    if plotA ~= nil then
        plotA(delta) --asteroids
    end
    if plotB ~= nil then
        plotB(delta) --black hole
    end
    if plotT ~= nil then
        plotT(delta) --transports
    end
    if plotW ~= nil then
        plotW(delta) --waves
    end
    if plotH ~= nil then
        plotH(delta) --help warning
    end
    if plotCN ~= nil then
        plotCN(delta) --coolant via nebula
    end
    if plotCI ~= nil then
        plotCI(delta) --cargo inventory
    end
end
