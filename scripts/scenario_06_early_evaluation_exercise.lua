-- Name: Early Evaluation Exercise
-- Description: An entry level, learn to play scenario.  Designed for trainees in the Human Navy. Up to 16 player ships may train simultaneously. Based on Earn Your Wings Scenario by Kilted Klingon.
-- Type: Basic
-- Author: Xansta
-- Setting[Orbits]: Configures orbit speeds of planets. Further refinement available on GM screen
-- Orbits[Sedate]: Slowest inner and outer orbit speeds
-- Orbits[Calm]: Slow inner speed, slowest outer speed
-- Orbits[Moving Along]: Average inner speed, slowest outer speed
-- Orbits[Quick Time|Default]: Faster inner and outer speeds
-- Orbits[Ludicrous Speed]: Fastest inner and outer speeds
-- Setting[Ships]: Determines the number of player ships.
-- Ships[1|Default]: One player ship
-- Ships[2]: Two player ships
-- Ships[3]: Three player ships
-- Ships[4]: Four player ships
-- Ships[5]: Five player ships
-- Ships[6]: Six 6 player ships
-- Ships[7]: Seven player ships
-- Ships[8]: Eight player ships
-- Ships[9]: Nine player ships
-- Ships[10]: Ten player ships
-- Ships[11]: Eleven player ships
-- Ships[12]: Twelve player ships
-- Ships[13]: Thirteen player ships
-- Ships[14]: Fourteen player ships
-- Ships[15]: Fifteen player ships
-- Ships[16]: Sixteen player ships
-- Setting[Control]: Configure whether or not control codes will be used
-- Control[Use|Default]: Control codes will be used. GM button Random PShip Names switches to random control codes and player ship names
-- Control[None]: Control codes will not be used
-- Setting[Crutch]: Configure whether a popup message for inexperienced players appears for each task
-- Crutch[Use|Default]: Popup messages will appear for each task
-- Crutch[None]: No popup message will appear
-- Setting[Insight]: Configure whether the players may see the GM evaluation
-- Insight[No|Default]: Players see the number portion of their task evaluation, but not the evaluation portion
-- Insight[Yes]: Players see both the numbers and their evaluation for each task
-- Setting[Names]: Configures whether player ship names are selected at random or are fixed
-- Names[Fixed|Default]: Player ship names are pre-assigned
-- Names[Random]: Player ship names are selected at random from a list

---------- Tasks given to players ----------
-- First Task: Dock
--     Hurdles: request permission to dock, calibrate shields and beams, power down missiles
--     Participants: Helm, weapons, relay, engineering

-- Second Task: Scan to discriminate targets
--     Hurdles: nebula obscures some targets
--     Participants: Science, relay

-- Third Task: Destroy enemy freighter
--     Hurdles: Limited beam function, only HVLI type missiles
--     Participants: Helm, Weapons, engineering, science, relay

-- Fourth Task: Assist freighter
--     Hurdles: Get parts from station, find freighter, fend off attackers
--     Participants: Helm, science, relay, engineering, weapons

-- Fifth task: Research anomalous planetary orbital behavior
--     Hurdles: Bumping into planets causes severe damage to ship, navigate carefully
--     Participants: Helm, Science, Relay, Engineering

-- Bonus task: Destroy enemy base
--     Hurdles: Enemy space ships, enemy base is far from primary base
--     Participants: Helm, Weapons, Engineering, Science, Relay

require("utils.lua") -- common math/geometry utility library
require("place_station_scenario_utility.lua")
require("cpu_ship_diversification_scenario_utility.lua")
require("control_code_scenario_utility.lua")
local defaults = require("defaults_scenario_utility.lua")
local Fleet = require("spawn_ships_scenario_utility.lua")
local Environment = require("environment_scenario_utility.lua")
local createRandomAsteroidAlongArc = Environment.createRandomAsteroidAlongArcUnregistered
local getTemplatePool = Fleet.templatePoolGetter({
    catalog = function() return ship_template end,
    selectivity = function() return pool_selectivity end,
    composition = "Random",
    limit = function() return template_pool_size end,
})

local Relation = require("comms_relation_scenario_utility.lua")
local relation = Relation.new({
    diagnostic = function(message) if func_diagnostic then print(message) end end,
})
isAllowedTo = relation.isAllowedTo
getFriendStatus = relation.friendStatus

local ShipComms = require("comms_ship_support.lua")
local StationCore = require("comms_station_core.lua")
local StationMenu = require("comms_station_menu.lua")
local sharedGoodsOnShip = ShipComms.goodsOnShip
local sharedAvailableForComms = ShipComms.availableForComms
local getEnemyHealth = ShipComms.getEnemyHealth
local ship_profile
local Runtime = require("runtime_scenario_utility.lua")

function goodsOnShip(comms_target, comms_data)
    if func_diagnostic then
        print("goods on ship")
    end
    sharedGoodsOnShip(comms_target, comms_data)
end

function init()
    scenario_version = "1.0.2"
    ee_version = "2024.12.08"
    print(
        string.format(
            "    ----    Scenario: Early Evaluation Exercise    ----    Version %s    ----    Tested with EE version %s    ----",
            scenario_version,
            ee_version
        )
    )
    if _VERSION ~= nil then
        print("Lua version:", _VERSION)
    end
    spawn_enemy_diagnostic = true
    func_diagnostic = false
    planet_collision_diagnostic = false
    setConstants()
    setVariations()
    setGMButtons()
end
function setVariations()
    -- One aspect of this scenario is the multiple planets that are orbiting the center black hole and each other.
    -- Early versions of this game had the planets orbiting at rather fast speeds...
    -- like warp 5 (or something that seems like that). Some crews found it hilarious, others were
    -- rather annoyed that they would get mowed down by a planet that they couldn't avoid, so the
    -- orbital speed schema may be configured. Use GM buttons while paused to configure the scheme
    -- The speed value represents the number of seconds it takes to complete an orbit.
    orbital_schemes = {
        ["Sedate"] = { inner_multiplier = 6, outer_multiplier = 6 },
        ["Calm"] = { inner_multiplier = 4.5, outer_multiplier = 6 },
        ["Moving Along"] = { inner_multiplier = 3, outer_multiplier = 6 },
        ["Quick Time"] = { inner_multiplier = 2.25, outer_multiplier = 2.25 },
        ["Ludicrous Speed"] = { inner_multiplier = 1, outer_multiplier = 1 },
    }
    orbital_scheme = getScenarioSetting("Orbits")
    inner_multiplier = orbital_schemes[orbital_scheme].inner_multiplier
    outer_multiplier = orbital_schemes[orbital_scheme].outer_multiplier
    crutch = true
    if getScenarioSetting("Crutch") == "None" then
        crutch = false
    end
    use_control_codes = true
    if getScenarioSetting("Control") == "None" then
        use_control_codes = false
    end
    if getScenarioSetting("Names") == "Fixed" then
        if use_control_codes then
            predefined_player_ships = {
                { name = "Damocles", control_code = "SPRINGFIELD443" },
                { name = "Endeavor", control_code = "VALIANT898" },
                { name = "Hyperion", control_code = "DANUBE555" },
                { name = "Liberty", control_code = "SALADIN676" },
                { name = "Prismatic", control_code = "CONSTITUTION424" },
                { name = "Visionary", control_code = "GALAXY332" },
                { name = "Newton", control_code = "STRIKE535" },
                { name = "Reliant", control_code = "MIRANDA909" },
            }
        else
            predefined_player_ships = {
                { name = "Damocles" },
                { name = "Endeavor" },
                { name = "Hyperion" },
                { name = "Liberty" },
                { name = "Prismatic" },
                { name = "Visionary" },
                { name = "Newton" },
                { name = "Reliant" },
            }
        end
    end
    player_ship_count = getScenarioSetting("Ships")
    for i = 1, player_ship_count do
        local p = PlayerSpaceship():setTemplate(ST.ATLANTIS)
        p.pidx = i
        identifyPlayerShip(p, true)
    end
    player_insight = false
    if getScenarioSetting("Insight") == "Yes" then
        player_insight = true
    end
end
function setConstants()
    storage = getScriptStorage()
    storage.gatherStats = gatherStats
    -- the first group is the 2 planetoids orbiting closest to the center black hole (the black hole doesn't move)
    orb_speed_closest_to_black_hole = 15
    orb_speed_second_closest_to_black_hole = 25
    -- the second group is the planetary sub-system that starts to the "north" of the black hole; call this 'planet_group_1'
    -- there is 1 main planet with 4 planetoids/moons in orbit around the main; these are assigned from main to outer most orbiter
    orb_speed_planet_group_1_main = 300 -- this body orbits the central black hole
    orb_speed_planet_group_1_orbiter_1 = 30 -- this body orbits planet_group_1_main
    orb_speed_planet_group_1_orbiter_2 = 60 -- this body orbits planet_group_1_main
    orb_speed_planet_group_1_orbiter_2_1 = 10 -- this body orbits planet_group_1_orbiter_2
    orb_speed_planet_group_1_orbiter_2_2 = 60 -- this body orbits planet_group_1_orbiter_2
    -- the third group is the planetary sub-system that starts to the "south" of the black hole; call this 'planet_group_2'
    -- it is a mirror image of the first/"north" group
    -- there is 1 main planet with 4 planetoids/moons in orbit around the main; these are assigned from main to outer most orbiter
    orb_speed_planet_group_2_main = 300
    orb_speed_planet_group_2_orbiter_1 = 30
    orb_speed_planet_group_2_orbiter_2 = 60
    orb_speed_planet_group_2_orbiter_2_1 = 10
    orb_speed_planet_group_2_orbiter_2_2 = 60

    terrain_center_x = 0 --replaces original variable entitled origin_X
    terrain_center_y = -20000
    trainee_placement_radius = 47000
    trainee_base_placement_radius = 50000
    human_player_ship_value = 50
    human_player_station_value = 150
    exuari_score = 0
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
        },
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
        ["Beast Breaker"] = 300,
        [ST.BLOCKADE_RUNNER] = 400,
        [ST.BLADE] = 300,
        ["Broom"] = 100,
        ["Brush"] = 100,
        [ST.BUSTER] = 100,
        ["Command Base"] = 800,
        ["Courier"] = 600,
        ["Cruiser"] = 200,
        ["Cucaracha"] = 200,
        [ST.DAGGER] = 100,
        [ST.DASH] = 200,
        [ST.DEFENSE_PLATFORM] = 800,
        ["Diva"] = 350,
        ["Tsarina"] = 350,
        ["Brood Mother"] = 350,
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
        ["Fighter"] = 200,
        [ST.FLASH] = 100,
        [ST.FLAVIA] = 200,
        [ST.FLAVIA_FALCON] = 200,
        [ST.FORTRESS] = 2000,
        ["Foul Feeder"] = 300,
        ["Fray"] = 200,
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
        ["Mikado"] = 200,
        ["Military Outpost"] = 800,
        ["Missile Pod D1"] = 800,
        ["Missile Pod D2"] = 800,
        ["Missile Pod D4"] = 800,
        ["Missile Pod T1"] = 800,
        ["Missile Pod T2"] = 800,
        ["Missile Pod TI2"] = 800,
        ["Missile Pod TI4"] = 800,
        ["Missile Pod TI8"] = 800,
        ["Missile Pod TX4"] = 800,
        ["Missile Pod TX8"] = 800,
        ["Missile Pod TX16"] = 800,
        ["Missile Pod S1"] = 800,
        ["Missile Pod S4"] = 800,
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
        ["Porcupine"] = 400,
        ["Prador"] = 2000,
        ["Predator"] = 200,
        ["Predator V2"] = 200,
        [ST.RACER] = 200,
        [ST.RANGER] = 100,
        [ST.RANUS_U] = 200,
        ["Roc"] = 200,
        ["Rook"] = 200,
        [ST.RYDER] = 2000,
        [ST.SENTINEL] = 600,
        ["Service Jonque"] = 800,
        [ST.SHOOTER] = 100,
        ["Sloop"] = 200,
        ["Sniper Tower"] = 800,
        ["Space Sedan"] = 600,
        [ST.STALKER_Q5] = 200,
        [ST.STALKER_Q7] = 200,
        [ST.STALKER_R5] = 200,
        [ST.STALKER_R7] = 200,
        [ST.STARHAMMER_II] = 400,
        ["Starhammer III"] = 400,
        ["Starhammer V"] = 400,
        [ST.STORM] = 200,
        [ST.STRIKE] = 200,
        [ST.STRIX] = 200,
        ["Strongarm"] = 400,
        ["Supervisor"] = 400,
        ["Sweeper"] = 100,
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
        ["Whirlwind"] = 200,
        ["Wombat"] = 100,
        ["Work Wagon"] = 600,
        ["WX-Lindworm"] = 100,
        ["WZ-Lindworm"] = 100,
    }
    player_ship_stats = { --ordered by strength
        [ST.ENDER] = {
            strength = 100,
            cargo = 20,
            distance = 2000,
            long_range_radar = 45000,
            short_range_radar = 7000,
        },
        ["Klantis"] = {
            strength = 60,
            cargo = 6,
            distance = 400,
            long_range_radar = 30000,
            short_range_radar = 5000,
        },
        [ST.ATLANTIS] = {
            strength = 52,
            cargo = 6,
            distance = 400,
            long_range_radar = 30000,
            short_range_radar = 5000,
        },
        [ST.CRUCIBLE] = {
            strength = 45,
            cargo = 5,
            distance = 200,
            long_range_radar = 20000,
            short_range_radar = 6000,
        },
        [ST.MAVERICK] = {
            strength = 45,
            cargo = 5,
            distance = 200,
            long_range_radar = 20000,
            short_range_radar = 4000,
        },
        [ST.AVALANCHE] = {
            strength = 45,
            cargo = 8,
            distance = 200,
            long_range_radar = 35000,
            short_range_radar = 6000,
        },
        [ST.VINDICATOR] = {
            strength = 40,
            cargo = 6,
            distance = 400,
            long_range_radar = 30000,
            short_range_radar = 5000,
        },
        [ST.HATHCOCK] = {
            strength = 30,
            cargo = 6,
            distance = 200,
            long_range_radar = 35000,
            short_range_radar = 6000,
        },
        [ST.PHOBOS_M3P] = {
            strength = 19,
            cargo = 10,
            distance = 200,
            long_range_radar = 25000,
            short_range_radar = 5000,
        },
        [ST.PIRANHA] = {
            strength = 16,
            cargo = 8,
            distance = 200,
            long_range_radar = 25000,
            short_range_radar = 6000,
        },
        [ST.REPULSE] = {
            strength = 14,
            cargo = 12,
            distance = 200,
            long_range_radar = 38000,
            short_range_radar = 5000,
        },
        [ST.FLAVIA_PFALCON] = {
            strength = 13,
            cargo = 15,
            distance = 200,
            long_range_radar = 40000,
            short_range_radar = 5000,
        },
        [ST.NAUTILUS] = {
            strength = 12,
            cargo = 7,
            distance = 200,
            long_range_radar = 22000,
            short_range_radar = 4000,
        },
        [ST.BENEDICT] = {
            strength = 10,
            cargo = 9,
            distance = 400,
            long_range_radar = 30000,
            short_range_radar = 5000,
        },
        [ST.KIRIYA] = {
            strength = 10,
            cargo = 9,
            distance = 400,
            long_range_radar = 35000,
            short_range_radar = 5000,
        },
        [ST.CROW] = {
            strength = 8,
            cargo = 4,
            distance = 200,
            long_range_radar = 35000,
            short_range_radar = 5000,
        },
        ["ZX-Lindworm"] = {
            strength = 8,
            cargo = 3,
            distance = 100,
            long_range_radar = 18000,
            short_range_radar = 5500,
        },
        [ST.MP52_HORNET] = {
            strength = 7,
            cargo = 3,
            distance = 100,
            long_range_radar = 18000,
            short_range_radar = 4000,
        },
        [ST.STINGRAY] = {
            strength = 7,
            cargo = 3,
            distance = 100,
            long_range_radar = 15000,
            short_range_radar = 4500,
        },
    }
    ship_template = { --ordered by relative strength
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
            create = stockTemplate,
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
            create = stockTemplate,
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
            create = stockTemplate,
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
            create = stockTemplate,
        },
        ["Missile Cruiser"] = {
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
            create = stockTemplate,
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
            create = stockTemplate,
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
            create = stockTemplate,
        },
        ["Cruiser"] = {
            strength = 18,
            adder = true,
            missiler = false,
            beamer = true,
            frigate = true,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            create = stockTemplate,
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
            create = stockTemplate,
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
            create = stockTemplate,
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
            create = stockTemplate,
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
            create = stockTemplate,
        },
        [ST.KTLITAN_WORKER] = {
            strength = 40,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            create = stockTemplate,
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
            create = stockTemplate,
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
            create = stockTemplate,
        },
        [ST.BLOCKADE_RUNNER] = {
            strength = 65,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = false,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
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
            create = stockTemplate,
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
            create = stockTemplate,
        },
        [ST.BATTLESTATION] = {
            strength = 100,
            adder = false,
            missiler = false,
            beamer = true,
            frigate = false,
            chaser = true,
            fighter = false,
            drone = false,
            unusual = false,
            base = false,
            create = stockTemplate,
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
            create = stockTemplate,
        },
    }
    control_code_stem = controlCodeStems()
    trainer_player_ship_names = { --predator pirate players
        "Ajax",
        "Amar",
        "Archon",
        "Artosk",
        "Belak",
        "Bortas",
        "Buruk",
        "Ch'Tang",
        "Cortez",
        "Decius",
        "Desna",
        "Devisor",
        "Devoras",
        "Dividices",
        "Drovana",
        "Fek'lhr",
        "Firebrand",
        "Gasko",
        "Genorex",
        "Gor Korus",
        "Gor Nivik",
        "Gor Portas",
        "Gorkon",
        "Guernik",
        "Haakona",
        "Havana",
        "Hegh'ta",
        "Hor'Cha",
        "Ki'tang",
        "Klothos",
        "K'mpec",
        "Koraga",
        "Korinar",
        "Makar",
        "Malpara",
        "Marjat",
        "Narada",
        "Orantho",
        "Par'tok",
        "Pell Togah",
        "Preceptor",
        "Rotarran",
        "Scimitar",
        "Shaenor",
        "Soyuz",
        "T'Acog",
        "T'Met",
        "Talvath",
        "Terix",
        "Tomal",
        "Torzat",
        "Ursva",
        "Valdore",
        "Vor'nak",
    }
    trainee_player_ship_names = { --newbie players
        "Adelphi",
        "Ahwahnee",
        "Akagi",
        "Akira",
        "Al-Batani",
        "Ambassador",
        "Andromeda",
        "Antares",
        "Apollo",
        "Appalachia",
        "Arcos",
        "Aries",
        "Athena",
        "Beethoven",
        "Bellerophon",
        "Biko",
        "Bonchune",
        "Bozeman",
        "Bradbury",
        "Brattain",
        "Budapest",
        "Buran",
        "Cairo",
        "Calypso",
        "Capricorn",
        "Carolina",
        "Centaur",
        "Challenger",
        "Charlseton",
        -- "Chekov",
        "Cheyenne",
        "Clement",
        "Cochraine",
        "Columbia",
        "Concorde",
        "Constantinople",
        "Constellation",
        "Constitution",
        "Copernicus",
        "Cousteau",
        "Crazy Horse",
        "Crockett",
        "Daedalus",
        "Danube",
        -- "Defiant",
        "Deneva",
        "Denver",
        "Discovery",
        "Drake",
        "Endeavor",
        "Endurance",
        "Equinox",
        "Essex",
        "Excalibur",
        "Exeter",
        "Farragut",
        "Fearless",
        "Fleming",
        "Fredrickson",
        "Freedom",
        "Gage",
        "Galaxy",
        "Galileo",
        -- "Ganges",
        "Gander",
        "Gettysburg",
        "Ghandi",
        "Goddard",
        "Grissom",
        "Hathaway",
        "Helin",
        "Hera",
        -- "Heracles",
        "Hokule'a",
        "Honshu",
        "Hood",
        "Hope",
        "Horatio",
        "Horizon",
        "Interceptor",
        -- "Intrepid",
        "Istanbul",
        "Jenolen",
        "Kearsarge",
        "Kongo",
        "Korolev",
        "Kyushu",
        "Lakota",
        "Lalo",
        "Lancer",
        "Lantree",
        "LaSalle",
        "Leeds",
        "Lexington",
        "Luna",
        -- "Magellan",
        "Majestic",
        "Malinche",
        "Maryland",
        "Mediterranean",
        "Mekong",
        "Melbourne",
        "Merced",
        "Merrimack",
        "Miranda",
        "Nash",
        "Nebula",
        "New Orleans",
        -- "Newton",
        "Niagra",
        "Nobel",
        "Norway",
        "Nova",
        "Oberth",
        "Odyssey",
        "Orinoco",
        "Osiris",
        "Pasteur",
        "Pegasus",
        "Peregrine",
        "Poseidon",
        "Potempkin",
        "Princeton",
        "Prokofiev",
        "Prometheus",
        "Proxima",
        "Rabin",
        "Raman",
        "Relativity",
        -- "Reliant",
        "Renaissance",
        "Renegade",
        "Republic",
        "Rhode Island",
        "Rigel",
        "Rubicon",
        "Rutledge",
        "Sarajevo",
        "Saratoga",
        "Scimitar",
        "Sequoia",
        "Shenandoah",
        "ShirKahr",
        "Sitak",
        "Socrates",
        "Sovereign",
        "Spector",
        "Springfield",
        "Stargazer",
        "Steamrunner",
        "Surak",
        "Sutherland",
        "Sydney",
        "T'Kumbra",
        "Thomas Paine",
        "Thunderchild",
        "Tian An Men",
        "Titan",
        "Tolstoy",
        "Trial",
        "Trieste",
        "Trinculo",
        "Tripoli",
        "Ulysses",
        "Valdemar",
        "Valiant",
        "Venture",
        "Volga",
        "Voyager",
        "Wambundu",
        "Waverider",
        "Wellington",
        "Wells",
        "Wyoming",
        "Yamaguchi",
        "Yamato",
        "Yangtzee Kiang",
        "Yeager",
        "Yorkshire",
        "Yorktown",
        "Yosemite",
        "Yukon",
        "Zapata",
        "Zhukov",
        "Zodiac",
    }
    -- these are the global tables for organizing all relevant game entities
    game_state = "paused"
    human_station_list = {} --number, station, name, killer, killer faction
    independent_station_list = {} --number, station, name, killer, killer faction
    human_transport_list = {} --number, transport, name, killer, killer faction
    exuari_list = {} --number, ship, name, Counts: Human kill, Kraylor kill
    enemyList = {}
    friendlyList = {}
    stationList = {}
    transportList = {}
    planetList = {}
    planetKillRadius = {}
    player_restart = {}
    player_restart.add = playerRestartAdd
    -- these are the global tables/variables for collecting stats during play
    friendlyDestroyedCountList = {}
    friendlyTalliedKilledList = {}
    human_station_destroyed_list = {}
    independent_station_destroyed_list = {}
    transport_destroyed_list = {}
    total_player_ships_crashed_into_planets = 0
    total_trainees_crashed_into_planets = 0
    total_trainers_crashed_into_planets = 0
    total_enemy_ships_spawned = 0
    total_enemy_ships_crashed_into_planets = 0
    total_enemy_ships_destroyed_by_players = 0
    total_transport_ships_spawned = 0
    total_transport_ships_crashed_into_planets = 0
    total_transport_ships_destroyed_by_enemy_ships = 0

    total_exuari_killed = 0
    total_exuari_killed_by_exuari = 0
    total_exuari_killed_by_kraylor = 0
    total_exuari_killed_by_human = 0
    -- variables for randomly spawning transports
    spawn_delay = 0
    -- note that all planetary bodies are globals as well, but they are established as the planets are created in the createEnvironment() function
    commonGoods = defaults.goods().commonGoods
    componentGoods = defaults.goods().componentGoods
    mineralGoods = defaults.goods().mineralGoods
    vapor_goods =
        { "gold pressed latinum", "unobtanium", "eludium", "impossibrium" }
    research_task_length = 2
    pool_selectivity = "full"
    posthumous = {}
    task_list = {
        ["dock"] = taskDock,
        ["completed dock"] = taskCompletedDock,
        ["scan"] = taskScan,
        ["completed scan"] = taskCompletedScan,
        ["destroy freighter"] = taskDestroyFreighter,
        ["completed destroy freighter"] = taskCompletedDestroyFreighter,
        ["assist freighter"] = taskAssistFreighter,
        ["completed assist freighter"] = taskCompletedAssistFreighter,
        ["research"] = taskResearch,
        ["completed research"] = taskCompletedResearch,
        ["research cleanup"] = taskResearchCleanup,
        ["bonus"] = taskBonus,
    }
end
function playerRestartAdd(
    pidx,
    name,
    control_code,
    start_x,
    start_y,
    angle,
    template,
    faction,
    deaths,
    exuari_deaths,
    kraylor_deaths,
    human_deaths,
    kills,
    exuari_kills,
    kraylor_kills,
    human_kills
)
    if func_diagnostic then
        print("player restart add")
    end
    if pidx == nil then
        return
    end
    if player_restart[pidx] ~= nil then
        if name == nil then
            name = player_restart[pidx].name
        end
        if control_code == nil then
            control_code = player_restart[pidx].control_code
        end
        if start_x == nil then
            start_x = player_restart[pidx].start_x
        end
        if start_y == nil then
            start_y = player_restart[pidx].start_y
        end
        if angle == nil then
            angle = player_restart[pidx].angle
        end
        if template == nil then
            template = player_restart[pidx].template
        end
        if faction == nil then
            faction = player_restart[pidx].faction
        end
        if deaths == nil then
            deaths = player_restart[pidx].deaths
        end
        if exuari_deaths == nil then
            exuari_deaths = player_restart[pidx].exuari_deaths
        end
        if kraylor_deaths == nil then
            kraylor_deaths = player_restart[pidx].kraylor_deaths
        end
        if human_deaths == nil then
            human_deaths = player_restart[pidx].human_deaths
        end
        if kills == nil then
            kills = player_restart[pidx].kills
        end
        if exuari_kills == nil then
            exuari_kills = player_restart[pidx].exuari_kills
        end
        if kraylor_kills == nil then
            kraylor_kills = player_restart[pidx].kraylor_kills
        end
        if human_kills == nil then
            human_kills = player_restart[pidx].human_kills
        end
    end
    player_restart[pidx] = {
        name = name,
        control_code = control_code,
        start_x = start_x,
        start_y = start_y,
        angle = angle,
        template = template,
        faction = faction,
        deaths = deaths,
        exuari_deaths = exuari_deaths,
        kraylor_deaths = kraylor_deaths,
        human_deaths = human_deaths,
        kills = kills,
        exuari_kills = exuari_kills,
        kraylor_kills = kraylor_kills,
        human_kills = human_kills,
    }
end
----------------------------------------------------
-- Game Master buttons and supporting functions  --
----------------------------------------------------
setGMButtons = Runtime.setGMButtons
function mainGMButtonsDuringPause()
    clearGMFunctions()
    addGMFunction(
        string.format(_("buttonGM", "Version %s"), scenario_version),
        function()
            local version_message = string.format(
                _("buttonGM", "Scenario version %s\n LUA version %s"),
                scenario_version,
                _VERSION
            )
            addGMMessage(version_message)
            print(version_message)
        end
    )
    if use_control_codes then
        addGMFunction(_("buttonGM", "Show control codes"), showControlCodes)
        addGMFunction(_("buttonGM", "Reset control codes"), resetControlCodes)
    end
    addGMFunction(_("buttonGM", "+Orbital Scheme"), setOrbitalScheme)
    if predefined_player_ships ~= nil then
        addGMFunction(_("buttonGM", "Random PShip Names"), function()
            predefined_player_ships = nil
            addGMMessage(
                _(
                    "buttonGM",
                    "Human Navy Player ship names will now be selected at random.\nHuman Navy Player ship control codes will now be generated at random"
                )
            )
            mainGMButtons()
        end)
    end
end
function mainGMButtonsAfterPause()
    clearGMFunctions()
    addGMFunction(
        string.format(_("buttonGM", "Version %s"), scenario_version),
        function()
            local version_message = string.format(
                _("buttonGM", "Scenario version %s\n LUA version %s"),
                scenario_version,
                _VERSION
            )
            addGMMessage(version_message)
            print(version_message)
        end
    )
    if use_control_codes then
        addGMFunction(_("buttonGM", "Show control codes"), showControlCodes)
    end
    addGMFunction(_("buttonGM", "+Evaluations"), showEvaluations)
    addGMFunction(_("buttonGM", "+Trigger Waves"), triggerWaves)
    addGMFunction(_("buttonGM", "+End Scenario"), gracefulConculsion)
    -- addGMFunction(_("buttonGM","+Jump to task"),jumpToTask) -- when this line is commented out, you can't reach any of the jump to functions
    addGMFunction(_("buttonGM", "+Trigger end task"), function()
        addGMMessage(
            _(
                "msgGM",
                "These triggers are for testing purposes. You should not use them with actual players."
            )
        )
        triggerEndTask()
    end)
end
function triggerEndTask()
    clearGMFunctions()
    addGMFunction(_("buttonGM", "-Main"), mainGMButtons)
    addGMFunction(_("buttonGM", "Dock"), function()
        for i, p in ipairs(getActivePlayerShips()) do
            p:setSystemPower("missilesystem", 0)
                :commandSetSystemPowerRequest("missilesystem", 0)
            p:setShieldsFrequency(p.dock_shield_frequency)
            p:commandSetBeamFrequency(p.dock_beam_frequency)
            if p.dock_call_port_authority_clock == nil then
                p.dock_call_port_authority_clock = getScenarioTime()
            end
        end
        addGMMessage(
            _(
                "msgGM",
                "Docking frequencies set for all players. All player missile systems powered down. Players still have to dock, but the protocols have been set"
            )
        )
    end)
    addGMFunction(_("buttonGM", "Scan"), function()
        local players_with_scan_targets = {}
        for i, p in ipairs(getActivePlayerShips()) do
            if p.scan_targets ~= nil then
                table.insert(players_with_scan_targets, p)
                for j, t in ipairs(p.scan_targets) do
                    t.ship:setScanned(true)
                    if t.single_scan_clock == nil then
                        t.single_scan_clock = getScenarioTime()
                    end
                end
            end
        end
        local out = _("msgGM", "Scan targets set to scanned for these players:")
        for i, p in ipairs(players_with_scan_targets) do
            out = string.format("%s\n    %s", out, p:getCallSign())
        end
        out = string.format(
            _("msgGM", "%s\nThey still need to report the results of the scans"),
            out
        )
        addGMMessage(out)
    end)
    addGMFunction(_("buttonGM", "Destroy freighter"), function()
        out = _(
            "msgGM",
            "Player ships with corresponding Kraylor freighters destroyed:"
        )
        for i, d in ipairs(destroy_freighters) do
            if d.ship:isValid() then
                d.ship:takeDamage(9999)
                out = string.format("%s\n    %s", out, d.player_ship_name)
            end
        end
        addGMMessage(out)
    end)
    addGMFunction(_("buttonGM", "Assist Freighter"), function()
        local out = _(
            "msgGM",
            "Player ships with freighter fixed and marauders destroyed:"
        )
        for i, p in ipairs(getActivePlayerShips()) do
            if p.assist_freighter ~= nil and p.assist_freighter:isValid() then
                out = string.format("%s\n    %s", out, p:getCallSign())
                if p.assist_freighter_fully_scanned_clock == nil then
                    p.assist_freighter:setScanned(true)
                    p.assist_freighter_fully_scanned_clock = getScenarioTime()
                    if p.assist_freighter_scanned_clock == nil then
                        p.assist_freighter_scanned_clock = getScenarioTime()
                    end
                end
                if p.assist_freighter_fixed_clock == nil then
                    if p.assist_freighter_parts_clock == nil then
                        p.assist_freighter_parts_clock = getScenarioTime()
                    end
                    p.assist_freighter_fixed_clock = getScenarioTime()
                    p.assist_freighter:setSystemHealthMax("impulse", 1)
                end
                if p.assist_freighter_marauders ~= nil then
                    for i, m in ipairs(p.assist_freighter_marauders) do
                        if m.ship:isValid() then
                            m.ship:takeDamage(9999)
                        end
                    end
                end
            end
        end
        addGMMessage(out)
    end)
    addGMFunction(_("buttonGM", "Research"), function()
        local out = _(
            "msgGM",
            "Player ships where research of orbital bodies has all been marked complete:"
        )
        for i, p in ipairs(getActivePlayerShips()) do
            if p.orbital_body_research ~= nil then
                out = string.format("%s\n    %s", out, p:getCallSign())
                for j, orbit in ipairs(p.orbital_body_research) do
                    orbit.research = "Y"
                    if orbit.start_scan_clock == nil then
                        orbit.start_scan_clock = getScenarioTime()
                    end
                end
            end
        end
        addGMMessage(out)
    end)
end
function jumpToTask()
    clearGMFunctions()
    addGMFunction(_("buttonGM", "-Main"), mainGMButtons)
    addGMFunction(_("buttonGM", "+Scan"), jumpToScan)
    addGMFunction(_("buttonGM", "+Destroy freighter"), jumpToDestroyFreighter)
    addGMFunction(_("buttonGM", "+Assist Freighter"), jumpToAssistFreighter)
    addGMFunction(_("buttonGM", "+Research"), jumpToResearch)
end
function jumpToScan()
    clearGMFunctions()
    addGMFunction(_("buttonGM", "-Main from scan"), mainGMButtons)
    addGMFunction(_("buttonGM", "-Jump"), jumpToTask)
    for i, p in ipairs(getActivePlayerShips()) do
        addGMFunction(
            string.format("%s:%s", p:getCallSign(), p.task),
            function()
                string.format("")
                p.task = "completed dock"
                p.scan_message = "start"
                p.start_dock_message = "sent"
                jumpToTask()
            end
        )
    end
end
function jumpToDestroyFreighter()
    clearGMFunctions()
    addGMFunction(_("buttonGM", "-Main frm dstry frgtr"), mainGMButtons)
    addGMFunction(_("buttonGM", "-Jump"), jumpToTask)
    for i, p in ipairs(getActivePlayerShips()) do
        addGMFunction(
            string.format("%s:%s", p:getCallSign(), p.task),
            function()
                string.format("")
                p.task = "completed scan"
                p.destroy_freighter_message = "start"
                p.start_dock_message = "sent"
                p.scan_message = "sent"
                jumpToTask()
            end
        )
    end
end
function jumpToAssistFreighter()
    clearGMFunctions()
    addGMFunction(_("buttonGM", "-Main frm hlp frgtr"), mainGMButtons)
    addGMFunction(_("buttonGM", "-Jump"), jumpToTask)
    for i, p in ipairs(getActivePlayerShips()) do
        addGMFunction(
            string.format("%s:%s", p:getCallSign(), p.task),
            function()
                string.format("")
                p.task = "completed destroy freighter"
                p.assist_freighter_message = "start"
                p.start_dock_message = "sent"
                p.scan_message = "sent"
                p.destroy_freighter_message = "sent"
                jumpToTask()
            end
        )
    end
end
function jumpToResearch()
    clearGMFunctions()
    addGMFunction(_("buttonGM", "-Main from research"), mainGMButtons)
    addGMFunction(_("buttonGM", "-Jump"), jumpToTask)
    for i, p in ipairs(getActivePlayerShips()) do
        addGMFunction(
            string.format("%s:%s", p:getCallSign(), p.task),
            function()
                string.format("")
                p.task = "completed assist freighter"
                p.research_message = "start"
                p.start_dock_message = "sent"
                p.scan_message = "sent"
                p.destroy_freighter_message = "sent"
                p.assist_freighter_message = "sent"
                p:setWeaponStorageMax("Homing", 12) -- restore missiles
                p:setWeaponStorage("Homing", 12)
                p:setWeaponStorageMax("Mine", 8)
                p:setWeaponStorage("Mine", 8)
                p:setWeaponStorageMax("EMP", 6)
                p:setWeaponStorage("EMP", 6)
                p:setWeaponStorageMax("Nuke", 4)
                p:setWeaponStorage("Nuke", 4)
                --                 Arc,  Dir, Range, CycleTime, Dmg
                p:setBeamWeapon(0, 100, -20, 1500, 6, 8) -- restore cycle time
                p:setBeamWeapon(1, 100, 20, 1500, 6, 8)
                jumpToTask()
            end
        )
    end
end
function triggerWaves()
    clearGMFunctions()
    addGMFunction("-Main", mainGMButtons)
    addGMFunction(_("buttonGM", "Strix wave"), function()
        addWave(
            enemyList,
            0,
            setWaveAngle(math.random(20), math.random(20)),
            setWaveDistance(math.random(5))
        )
    end)

    addGMFunction(_("buttonGM", "Fighter wave"), function()
        addWave(
            enemyList,
            1,
            setWaveAngle(math.random(20), math.random(20)),
            setWaveDistance(math.random(5))
        )
    end)

    addGMFunction(_("buttonGM", "Gunship wave"), function()
        addWave(
            enemyList,
            2,
            setWaveAngle(math.random(20), math.random(20)),
            setWaveDistance(math.random(5))
        )
    end)

    addGMFunction(_("buttonGM", "Dreadnought"), function()
        addWave(
            enemyList,
            4,
            setWaveAngle(math.random(20), math.random(20)),
            setWaveDistance(math.random(5))
        )
    end)

    addGMFunction(_("buttonGM", "Missile cruiser wave"), function()
        addWave(
            enemyList,
            5,
            setWaveAngle(math.random(20), math.random(20)),
            setWaveDistance(math.random(5))
        )
    end)

    addGMFunction(_("buttonGM", "Cruiser wave"), function()
        addWave(
            enemyList,
            6,
            setWaveAngle(math.random(20), math.random(20)),
            setWaveDistance(math.random(5))
        )
    end)

    addGMFunction(_("buttonGM", "Adv. striker wave"), function()
        addWave(
            enemyList,
            9,
            setWaveAngle(math.random(20), math.random(20)),
            setWaveDistance(math.random(5))
        )
    end)
end
function gracefulConculsion()
    clearGMFunctions()
    addGMFunction(_("buttonGM", "-Main"), mainGMButtons)
    addGMFunction(_("buttonGM", "Trainees win"), function()
        game_state = "victory-human"
        victory("Human Navy")
    end)
    addGMFunction(_("buttonGM", "Trainers win"), function()
        game_state = "victory-kraylor"
        victory("Kraylor")
    end)
    addGMFunction(_("buttonGM", "Scenario wins"), function()
        game_state = "victory-exuari"
        victory("Exuari")
    end)
end
function showEvaluations()
    clearGMFunctions()
    addGMFunction(_("buttonGM", "-From evaluations"), mainGMButtons)
    addGMFunction(_("buttonGM", "+Dock"), dockEvaluations)
    addGMFunction(_("buttonGM", "+Scan"), scanEvaluations)
    addGMFunction(
        _("buttonGM", "+Destroy freighter"),
        destroyFreighterEvaluations
    )
    addGMFunction(
        _("buttonGM", "+Assist freighter"),
        assistFreighterEvaluations
    )
    addGMFunction(_("buttonGM", "+Research"), researchEvaluations)
    addGMFunction(_("buttonGM", "+Bonus"), bonusEvaluations)
    addGMFunction(_("buttonGM", "+Posthumous"), posthumousEvaluations)
end
function posthumousEvaluations()
    clearGMFunctions()
    addGMFunction(_("buttonGM", "-Main from Posthumous"), mainGMButtons)
    addGMFunction(_("buttonGM", "-Evaluations"), showEvaluations)
    local out = _(
        "evaluation-comms",
        "Posthumous evaluations are intended for those times when you want the evaluation information, but the player ship has been destroyed. A copy is made in the posthumous list at the time the task is completed. So, just because they are on the posthumous list does not mean the player ship has been destroyed. Only the first instance of a task is recorded. If the player ship does a task again, the posthumous table only keeps their first attempt. If they are destroyed a second time, no new record is made of any tasks they had already completed the first time. Of course if they live, their current evaluation information is attached to their ship and thus is available.\n\nSingle letter evaluation decode:\nN = Needs improvement\nC = Competent\nE = Exceeds expectations\nS = Superior"
    )
    local count = 0
    for i, eval in ipairs(posthumous) do
        count = count + 1
        addGMFunction(string.format("%s %s", eval.name, eval.task), function()
            addGMMessage(
                string.format(
                    _("evaluation-comms", "%s     %s     Clock: %.1f\n%s"),
                    eval.name,
                    eval.task,
                    eval.clock,
                    eval.desc
                )
            )
        end)
    end
    if count == 0 then
        out = string.format(
            _(
                "evaluation-comms",
                "%s\n\nNo tasks completed, so no tasks recorded in the posthumous table"
            ),
            out
        )
    end
    addGMMessage(out)
end
function bonusEvaluations()
    clearGMFunctions()
    addGMFunction(_("buttonGM", "-Main from Bonus"), mainGMButtons)
    addGMFunction(_("buttonGM", "-Evaluations"), showEvaluations)
    for i, p in ipairs(getActivePlayerShips()) do
        addGMFunction(p:getCallSign(), function()
            string.format("")
            local out = _(
                "evaluation-comms",
                "Research task is not complete, no bonus possible yet"
            )
            if p.research_task == "complete" then
                out = bonusTaskEvaluationOutput(p, "gm")
                out = string.format(
                    _("evaluation-comms", "%s Bonus Evaluation:\n%s"),
                    p:getCallSign(),
                    out
                )
            end
            addGMMessage(out)
        end)
    end
end
function researchEvaluations()
    clearGMFunctions()
    addGMFunction(_("buttonGM", "-Main from Research"), mainGMButtons)
    addGMFunction(_("buttonGM", "-Evaluations"), showEvaluations)
    for i, p in ipairs(getActivePlayerShips()) do
        addGMFunction(p:getCallSign(), function()
            string.format("")
            local out = _("evaluation-comms", "Research task is not complete")
            if p.research_task == "complete" then
                out = researchTaskEvaluationOutput(p, "gm")
                out = string.format(
                    _("evaluation-comms", "%s Research Evaluation:\n%s"),
                    p:getCallSign(),
                    out
                )
            end
            out = string.format(
                _(
                    "evaluation-comms",
                    "%s\n\nSuggested subjective evaluation criteria:\nDid anyone suggest using probes to gather data?\nDid Relay put out waypoints for guidance around the planets?\nDid Engineering boost maneuver for Helm? Did Helm request a maneuver boost?\nWas Weapons diligent about the shields?\nDid Science let everyone know when the data was gathered for a planet?"
                ),
                out
            )
            addGMMessage(out)
        end)
    end
end
function assistFreighterEvaluations()
    clearGMFunctions()
    addGMFunction(_("buttonGM", "-Main frm Help Frgtr"), mainGMButtons)
    addGMFunction(_("buttonGM", "-Evaluations"), showEvaluations)
    for i, p in ipairs(getActivePlayerShips()) do
        addGMFunction(p:getCallSign(), function()
            string.format("")
            local out =
                _("evaluation-comms", "Assist freighter task is not complete")
            if p.assist_freighter_task == "complete" then
                out = assistFreighterTaskEvaluationOutput(p, "gm")
                out = string.format(
                    _("evaluation-comms", "%s Assist Freighter Evaluation:\n%s"),
                    p:getCallSign(),
                    out
                )
            end
            out = string.format(
                _(
                    "evaluation-comms",
                    "%s\n\nSuggested subjective evaluation criteria:\nDid anyone suggest using probes to find the freighter?\nDid Relay put out waypoints for the freighter and the home station?\nHow did the captain and crew handle the balancing of getting the parts and protecting the freighter?\nHow well did the crew coordinate during combat?\nWere targets prioritized/identified?\nDid Engineering boost systems based on weapon use?\nWas the type of combat identified (beam/missile)?\nDid Science provide beam frequencies for Weapons? Did Science keep the crew informed on the shield/hull status of enemies?\nDid Relay hack any enemy systems?"
                ),
                out
            )
            addGMMessage(out)
        end)
    end
end
function destroyFreighterEvaluations()
    clearGMFunctions()
    addGMFunction(_("buttonGM", "-Main frm Destroy Frgtr"), mainGMButtons)
    addGMFunction(_("buttonGM", "-Evaluations"), showEvaluations)
    for i, p in ipairs(getActivePlayerShips()) do
        addGMFunction(p:getCallSign(), function()
            string.format("")
            local out =
                _("evaluation-comms", "Destroy freighter task is not complete")
            if p.destroy_freighter_task == "complete" then
                out = destroyFreighterTaskEvaluationOutput(p, "gm")
                out = string.format(
                    _(
                        "evaluation-comms",
                        "%s Destroy Freighter Evaluation:\n%s"
                    ),
                    p:getCallSign(),
                    out
                )
            end
            out = string.format(
                _(
                    "evaluation-comms",
                    "%s\n\nSuggested subjective evaluation criteria:\nDid Helm and Science coordinate verbally to determine where to go to destroy the freighter?\nDid Weapons and Engineering collaborate on boosting applicable combat systems like missiles?\nDid Helm indicate the method of approaching the enemy freighter (impulse/jump)?\nDid Relay hack the enemy ship? If so, what systems and were those communicated?\nDid Science provide details on enemy shield and hull strengths?\nHow well did Helm and Weapons coordinate the firing of HVLIs?"
                ),
                out
            )
            addGMMessage(out)
        end)
    end
end
function scanEvaluations()
    clearGMFunctions()
    addGMFunction(_("buttonGM", "-Main from Scan"), mainGMButtons)
    addGMFunction(_("buttonGM", "-Evaluations"), showEvaluations)
    for i, p in ipairs(getActivePlayerShips()) do
        addGMFunction(p:getCallSign(), function()
            string.format("")
            local out = _("evaluation-comms", "Scan task is not complete")
            if p.scan_task == "complete" then
                out = scanTaskEvaluationOutput(p, "gm")
                out = string.format(
                    _("evaluation-comms", "%s Scan Evaluation:\n%s"),
                    p:getCallSign(),
                    out
                )
            end
            out = string.format(
                _(
                    "evaluation-comms",
                    "%s\n\nSuggested subjective evaluation criteria:\nDid science request a probe in the nebula?\nDid Science communicate which target he started scanning first?\nWas Relay standing by to report the scan results as soon as they came in?\nWas there clear communication between Science and Relay?"
                ),
                out
            )
            addGMMessage(out)
        end)
    end
end
function dockEvaluations()
    clearGMFunctions()
    addGMFunction(_("buttonGM", "-Main from Dock"), mainGMButtons)
    addGMFunction("-Evaluations", showEvaluations)
    for i, p in ipairs(getActivePlayerShips()) do
        addGMFunction(p:getCallSign(), function()
            string.format("")
            local out = _("evaluation-comms", "Dock task is not complete")
            if p.dock_task == "complete" then
                out = dockTaskEvaluationOutput(p, "gm")
                out = string.format(
                    _("evaluation-comms", "%s Dock Evaluation:\n%s"),
                    p:getCallSign(),
                    out
                )
            end
            out = string.format(
                _(
                    "evaluation-comms",
                    "%s\n\nSuggested subjective evaluation criteria (mostly about collaboration and communication):\nDid Relay verbally communicate the initial instructions? How about the docking protocol to Weapons and Engineering?\nDid Helm request an impulse boost to get to the station more quickly?\nDid Helm fly backwards to the station?\nDid Engineering confirm that missile systems were powered down?"
                ),
                out
            )
            addGMMessage(out)
        end)
    end
end
-----------------------------
-- Environment Functions  --
-----------------------------
function setOrbitalScheme()
    --GM function that impacts the environment
    clearGMFunctions()
    addGMFunction(_("buttonGM", "-From Orbit Scheme"), mainGMButtons)
    for scheme, details in pairs(orbital_schemes) do
        button_label = scheme
        if orbital_scheme == button_label then
            button_label = button_label .. "*"
        end
        addGMFunction(button_label, function()
            orbital_scheme = scheme
            inner_multiplier = details.inner_multiplier
            outer_multiplier = details.outer_multiplier
            setOrbitalScheme()
        end)
    end
    if inner_multiplier > 1 then
        addGMFunction(
            string.format(
                _("buttonGM", "Faster in %.2f -> %.2f"),
                inner_multiplier,
                inner_multiplier - 0.25
            ),
            function()
                inner_multiplier = inner_multiplier - 0.25
                setOrbitalScheme()
            end
        )
    end
    if inner_multiplier < 6 then
        addGMFunction(
            string.format(
                _("buttonGM", "Slower in %.2f -> %.2f"),
                inner_multiplier,
                inner_multiplier + 0.25
            ),
            function()
                inner_multiplier = inner_multiplier + 0.25
                setOrbitalScheme()
            end
        )
    end
    if outer_multiplier > 1 then
        addGMFunction(
            string.format(
                _("buttonGM", "Faster out %.2f -> %.2f"),
                outer_multiplier,
                outer_multiplier - 0.25
            ),
            function()
                outer_multiplier = outer_multiplier - 0.25
                setOrbitalScheme()
            end
        )
    end
    if outer_multiplier < 6 then
        addGMFunction(
            string.format(
                _("buttonGM", "Slower out %.2f -> %.2f"),
                outer_multiplier,
                outer_multiplier + 0.25
            ),
            function()
                outer_multiplier = outer_multiplier + 0.25
                setOrbitalScheme()
            end
        )
    end
end
function setOrbitalSpeeds()
    orb_speed_closest_to_black_hole = orb_speed_closest_to_black_hole
        * inner_multiplier
    orb_speed_second_closest_to_black_hole = orb_speed_second_closest_to_black_hole
        * inner_multiplier

    orb_speed_planet_group_1_main = orb_speed_planet_group_1_main
        * outer_multiplier
    orb_speed_planet_group_1_orbiter_1 = orb_speed_planet_group_1_orbiter_1
        * outer_multiplier
    orb_speed_planet_group_1_orbiter_2 = orb_speed_planet_group_1_orbiter_2
        * outer_multiplier
    orb_speed_planet_group_1_orbiter_2_1 = orb_speed_planet_group_1_orbiter_2_1
        * outer_multiplier
    orb_speed_planet_group_1_orbiter_2_2 = orb_speed_planet_group_1_orbiter_2_2
        * outer_multiplier

    orb_speed_planet_group_2_main = orb_speed_planet_group_2_main
        * outer_multiplier
    orb_speed_planet_group_2_orbiter_1 = orb_speed_planet_group_2_orbiter_1
        * outer_multiplier
    orb_speed_planet_group_2_orbiter_2 = orb_speed_planet_group_2_orbiter_2
        * outer_multiplier
    orb_speed_planet_group_2_orbiter_2_1 = orb_speed_planet_group_2_orbiter_2_1
        * outer_multiplier
    orb_speed_planet_group_2_orbiter_2_2 = orb_speed_planet_group_2_orbiter_2_2
        * outer_multiplier
end
function createEnvironment()
    createOrbitalBodies()
    placeNebulae()
    -- add some asteroids
    createRandomAsteroidAlongArc(
        130,
        terrain_center_x,
        terrain_center_y,
        (trainee_base_placement_radius + 100000) / 2,
        0,
        180,
        (100000 - trainee_base_placement_radius) / 2
    )
    createRandomAsteroidAlongArc(
        130,
        terrain_center_x,
        terrain_center_y,
        (trainee_base_placement_radius + 100000) / 2,
        180,
        360,
        (100000 - trainee_base_placement_radius) / 2
    )
end
function createOrbitalBodies()
    orbital_body_names = {
        ["black hole"] = _("callsign-blackhole", "Balor"),
        ["cbheh1"] = _("callsign-planet", "Draugr"),
        ["cbheh2"] = _("callsign-planet", "Dimidium"),
        ["cbhmp1"] = _("callsign-planet", "Phobetor"),
        ["mp1s1"] = _("callsign-planet", "Saffar"),
        ["mp1s2"] = _("callsign-planet", "Keplar-452b"),
        ["mp1s2s1"] = _("callsign-planet", "HD 23472 d"),
        ["mp1s3"] = _("callsign-planet", "K2-89 b"),
        ["cbhmp2"] = _("callsign-planet", "Samh"),
        ["mp2s1"] = _("callsign-planet", "GJ 1061 d"),
        ["mp2s2"] = _("callsign-planet", "Teegarden's Star b"),
        ["mp2s2s1"] = _("callsign-planet", "Wolf 503b"),
        ["mp2s3"] = _("callsign-planet", "YZ Ceti b"),
    }
    -- BLACK HOLE ORBITAL SYSTEM
    -- initial alignment of objects is along the X axis (X value is the same; Y changes for distance from center)
    -- the center object
    center_blackhole = BlackHole()
        :setPosition(terrain_center_x, terrain_center_y)
        :setCallSign(orbital_body_names["black hole"])
    -- planetList = {}  -- copied here just for easy reference; DO NOT UNCOMMENT!
    -- planetKillRadius = {}  -- copied here just for easy reference; DO NOT UNCOMMENT!
    no_atmosphere_padding = 250 -- current estimate is extra 250 distance is necessary for planet with NO atmosphere; don't think the size of the planet matters
    atmosphere_padding = 500 -- current estimate is extra 500 distance is necessary for planet WITH atmosphere; don't think the size of the planet matters

    -- "on the edge" planet orbiting just outside the event horizon, very fast (warp speed? ha)
    cbh_event_horizon1 = Planet()
        :setPosition(terrain_center_x, terrain_center_y - 6000)
        :setPlanetRadius(500)
        :setDistanceFromMovementPlane(0)
        :setPlanetSurfaceTexture("planets/moon-1.png")
        :setPlanetAtmosphereColor(0.2, 0.2, 0.2)
        :setCallSign(orbital_body_names["cbheh1"])
    table.insert(planetList, cbh_event_horizon1)
    table.insert(planetKillRadius, 500 + no_atmosphere_padding)
    cbh_event_horizon1:setOrbit(
        center_blackhole,
        orb_speed_closest_to_black_hole
    )

    -- "near the edge" planet orbiting near the event horizon, fast
    cbh_event_horizon2 = Planet()
        :setPosition(terrain_center_x, terrain_center_y - 10000)
        :setPlanetRadius(1000)
        :setDistanceFromMovementPlane(0)
        :setPlanetSurfaceTexture("planets/planet-2.png")
        :setPlanetAtmosphereColor(0.4, 0, 0)
        :setCallSign(orbital_body_names["cbheh2"])
    table.insert(planetList, cbh_event_horizon2)
    table.insert(planetKillRadius, 1000 + atmosphere_padding) -- not sure why, but this planet needs the additional atmosphere padding for collision calculations
    cbh_event_horizon2:setOrbit(
        center_blackhole,
        orb_speed_second_closest_to_black_hole
    )

    -- planetary orbital sub-system 1, to the 'north' of the center black hole
    cbh_main_planet1 = Planet()
        :setPosition(terrain_center_x, terrain_center_y - 30000)
        :setPlanetRadius(3000)
        :setDistanceFromMovementPlane(0)
        :setAxialRotationTime(30)
        :setPlanetSurfaceTexture("planets/planet-1.png")
        :setPlanetCloudTexture("planets/clouds-1.png")
        :setPlanetAtmosphereTexture("planets/atmosphere.png")
        :setPlanetAtmosphereColor(0.2, 0.2, 1.0)
        :setCallSign(orbital_body_names["cbhmp1"])
    table.insert(planetList, cbh_main_planet1)
    table.insert(planetKillRadius, 3000 + atmosphere_padding)
    cbh_main_planet1:setOrbit(center_blackhole, orb_speed_planet_group_1_main)

    -- orbiting bodies for cbh_main_planet1, inner to outer
    mp1_satelite1 = Planet()
        :setPosition(terrain_center_x, terrain_center_y - 24000)
        :setPlanetRadius(500)
        :setDistanceFromMovementPlane(0)
        :setPlanetSurfaceTexture("planets/moon-1.png")
        :setPlanetAtmosphereColor(0.2, 0.2, 0.2)
        :setCallSign(orbital_body_names["mp1s1"])
    table.insert(planetList, mp1_satelite1)
    table.insert(planetKillRadius, 500 + no_atmosphere_padding)
    mp1_satelite1:setOrbit(cbh_main_planet1, orb_speed_planet_group_1_orbiter_1)

    mp1_satelite2 = Planet()
        :setPosition(terrain_center_x, terrain_center_y - 20000)
        :setPlanetRadius(1000)
        :setDistanceFromMovementPlane(0)
        :setAxialRotationTime(30)
        :setPlanetSurfaceTexture("planets/planet-1.png")
        :setPlanetCloudTexture("planets/clouds-1.png")
        :setPlanetAtmosphereTexture("planets/atmosphere.png")
        :setPlanetAtmosphereColor(0, 0.8, 0.2)
        :setCallSign(orbital_body_names["mp1s2"])
    table.insert(planetList, mp1_satelite2)
    table.insert(planetKillRadius, 1000 + atmosphere_padding)
    mp1_satelite2:setOrbit(cbh_main_planet1, orb_speed_planet_group_1_orbiter_2)

    mp1s2_satelite1 = Planet()
        :setPosition(terrain_center_x, terrain_center_y - 18000)
        :setPlanetRadius(200)
        :setDistanceFromMovementPlane(0)
        :setAxialRotationTime(10)
        :setPlanetSurfaceTexture("planets/moon-1.png")
        :setPlanetAtmosphereColor(0.2, 0.2, 0.2)
        :setCallSign(orbital_body_names["mp1s2s1"])
    table.insert(planetList, mp1s2_satelite1)
    table.insert(planetKillRadius, 200 + no_atmosphere_padding)
    mp1s2_satelite1:setOrbit(
        mp1_satelite2,
        orb_speed_planet_group_1_orbiter_2_1
    )

    mp1_satelite3 = Planet()
        :setPosition(terrain_center_x, terrain_center_y - 16000)
        :setPlanetRadius(500)
        :setDistanceFromMovementPlane(0)
        :setAxialRotationTime(30)
        :setPlanetSurfaceTexture("planets/planet-2.png")
        :setPlanetAtmosphereColor(0.4, 0, 0)
        :setCallSign(orbital_body_names["mp1s3"])
    table.insert(planetList, mp1_satelite3)
    table.insert(planetKillRadius, 500 + atmosphere_padding)
    mp1_satelite3:setOrbit(
        cbh_main_planet1,
        orb_speed_planet_group_1_orbiter_2_2
    )

    -- planetary orbital sub-system 2, to the 'south' of the center black hole
    cbh_main_planet2 = Planet()
        :setPosition(terrain_center_x, terrain_center_y + 30000)
        :setPlanetRadius(3000)
        :setDistanceFromMovementPlane(0)
        :setAxialRotationTime(30)
        :setPlanetSurfaceTexture("planets/gas-1.png")
        :setPlanetAtmosphereColor(0.4, 0, 0)
        :setCallSign(orbital_body_names["cbhmp2"])
    table.insert(planetList, cbh_main_planet2)
    table.insert(planetKillRadius, 3000 + atmosphere_padding)
    cbh_main_planet2:setOrbit(center_blackhole, orb_speed_planet_group_2_main)

    -- orbiting bodies for cbh_main_planet2, inner to outer
    mp2_satelite1 = Planet()
        :setPosition(terrain_center_x, terrain_center_y + 24000)
        :setPlanetRadius(500)
        :setDistanceFromMovementPlane(0)
        :setPlanetSurfaceTexture("planets/moon-1.png")
        :setPlanetAtmosphereColor(0.2, 0.2, 0.2)
        :setCallSign(orbital_body_names["mp2s1"])
    table.insert(planetList, mp2_satelite1)
    table.insert(planetKillRadius, 500 + no_atmosphere_padding)
    mp2_satelite1:setOrbit(cbh_main_planet2, orb_speed_planet_group_2_orbiter_1)

    mp2_satelite2 = Planet()
        :setPosition(terrain_center_x, terrain_center_y + 20000)
        :setPlanetRadius(1000)
        :setDistanceFromMovementPlane(0)
        :setAxialRotationTime(30)
        :setPlanetSurfaceTexture("planets/planet-1.png")
        :setPlanetCloudTexture("planets/clouds-1.png")
        :setPlanetAtmosphereTexture("planets/atmosphere.png")
        :setPlanetAtmosphereColor(0.2, 0.2, 1.0)
        :setCallSign(orbital_body_names["mp2s2"])
    table.insert(planetList, mp2_satelite2)
    table.insert(planetKillRadius, 1000 + atmosphere_padding)
    mp2_satelite2:setOrbit(cbh_main_planet2, orb_speed_planet_group_2_orbiter_2)

    mp2s2_satelite1 = Planet()
        :setPosition(terrain_center_x, terrain_center_y + 18000)
        :setPlanetRadius(200)
        :setDistanceFromMovementPlane(0)
        :setAxialRotationTime(10)
        :setPlanetSurfaceTexture("planets/moon-1.png")
        :setPlanetAtmosphereColor(0.2, 0.2, 0.2)
        :setCallSign(orbital_body_names["mp2s2s1"])
    table.insert(planetList, mp2s2_satelite1)
    table.insert(planetKillRadius, 200 + no_atmosphere_padding)
    mp2s2_satelite1:setOrbit(
        mp2_satelite2,
        orb_speed_planet_group_2_orbiter_2_1
    )

    mp2_satelite3 = Planet()
        :setPosition(terrain_center_x, terrain_center_y + 16000)
        :setPlanetRadius(500)
        :setDistanceFromMovementPlane(0)
        :setAxialRotationTime(30)
        :setPlanetSurfaceTexture("planets/planet-2.png")
        :setPlanetAtmosphereColor(0.4, 0, 0)
        :setCallSign(orbital_body_names["mp2s3"])
    table.insert(planetList, mp2_satelite3)
    table.insert(planetKillRadius, 500 + atmosphere_padding)
    mp2_satelite3:setOrbit(
        cbh_main_planet2,
        orb_speed_planet_group_2_orbiter_2_2
    )
end
function placeNebulae()
    -- add all the nebula
    Nebula():setPosition(-89207, -57749)
    Nebula():setPosition(-85944, -65810)
    Nebula():setPosition(-84792, -71377)
    Nebula():setPosition(-89207, -74832)
    Nebula():setPosition(-84024, -84045)
    Nebula():setPosition(-78458, -79822)
    Nebula():setPosition(-75387, -90954)
    Nebula():setPosition(-68285, -97672)
    Nebula():setPosition(-58880, -102471)
    Nebula():setPosition(-53698, -104582)
    Nebula():setPosition(-21836, -108421)
    Nebula():setPosition(-29898, -109381)
    Nebula():setPosition(-33352, -109381)
    Nebula():setPosition(-43333, -105542)
    Nebula():setPosition(-42949, -108421)
    Nebula():setPosition(-4370, -109764)
    Nebula():setPosition(-11855, -109572)
    Nebula():setPosition(5611, -108805)
    Nebula():setPosition(6763, -107461)
    Nebula():setPosition(20774, -111492)
    Nebula():setPosition(13289, -111876)
    Nebula():setPosition(30755, -105926)
    Nebula():setPosition(35745, -106501)
    Nebula():setPosition(57051, -101511)
    Nebula():setPosition(87761, -66002)
    Nebula():setPosition(89488, -57557)
    Nebula():setPosition(42655, -108613)
    Nebula():setPosition(52060, -106118)
    Nebula():setPosition(83922, -72912)
    Nebula():setPosition(74325, -81933)
    Nebula():setPosition(69719, 32078)
    Nebula():setPosition(64152, 38988)
    Nebula():setPosition(57818, 44938)
    Nebula():setPosition(48221, 53191)
    Nebula():setPosition(37665, 58182)
    Nebula():setPosition(29220, 58950)
    Nebula():setPosition(17319, 65476)
    Nebula():setPosition(21158, 65092)
    Nebula():setPosition(8298, 67971)
    Nebula():setPosition(1196, 69122)
    Nebula():setPosition(-10896, 69122)
    Nebula():setPosition(-21836, 71042)
    Nebula():setPosition(-32585, 71618)
    Nebula():setPosition(-39686, 67395)
    Nebula():setPosition(-45061, 65476)
    Nebula():setPosition(-54850, 67011)
    Nebula():setPosition(96782, -9381)
    Nebula():setPosition(95822, -17058)
    Nebula():setPosition(96782, -39131)
    Nebula():setPosition(96782, -23392)
    Nebula():setPosition(93327, -30302)
    Nebula():setPosition(95054, -33565)
    Nebula():setPosition(91792, 792)
    Nebula():setPosition(90256, -6501)
    Nebula():setPosition(86225, 8662)
    Nebula():setPosition(82770, 16147)
    Nebula():setPosition(76628, 26128)
    Nebula():setPosition(81427, -79246)
    Nebula():setPosition(66264, -91722)
    Nebula():setPosition(71254, -87691)
    Nebula():setPosition(94287, -41818)
    Nebula():setPosition(90832, -48344)
    Nebula():setPosition(-99763, -35868)
    Nebula():setPosition(-98228, -44889)
    Nebula():setPosition(-92086, -50072)
    Nebula():setPosition(-95924, -57941)
    Nebula():setPosition(-95924, -57941)
    Nebula():setPosition(-97844, 8086)
    Nebula():setPosition(-100531, -3430)
    Nebula():setPosition(-94581, -10916)
    Nebula():setPosition(-98612, -20513)
    Nebula():setPosition(-98420, -25887)
    Nebula():setPosition(-52354, 60101)
    Nebula():setPosition(-57153, 52808)
    Nebula():setPosition(-68093, 47241)
    Nebula():setPosition(-78458, 45322)
    Nebula():setPosition(-85176, 38220)
    Nebula():setPosition(-91894, 32462)
    Nebula():setPosition(-91510, 23057)
    Nebula():setPosition(-90550, 14036)
end
-----------------------
-- Utility Functions --
-----------------------
function gatherStats()
    if func_diagnostic then
        print("gather stats")
    end
    local stat_list = {}
    stat_list.scenario =
        { name = "Early Evaluation Exercise", version = scenario_version }
    stat_list.times = {}
    stat_list.times.game = {}
    stat_list.times.stage = game_state
    stat_list.human = {}
    stat_list.human.ship = {}
    stat_list.human.total_ship_deaths = 0
    stat_list.human.total_transport_ships_destroyed =
        total_transport_ships_destroyed_by_enemy_ships
    stat_list.human.score = total_transport_ships_destroyed_by_enemy_ships * -10
    stat_list.kraylor = {}
    stat_list.kraylor.ship = {}
    stat_list.kraylor.total_ship_deaths = 0
    stat_list.kraylor.score = 0
    stat_list.exuari = {}
    stat_list.exuari.score = exuari_score
    if #player_restart > 0 then
        for pidx, details in pairs(player_restart) do
            if type(details) ~= "function" then
                local deaths = 0
                if details.deaths ~= nil then
                    deaths = details.deaths
                end
                if details.faction == "Human Navy" then
                    stat_list.human.ship[details.name] = {
                        deaths = deaths,
                        score = -deaths * human_player_ship_value,
                        station = true,
                    }
                    stat_list.human.total_ship_deaths = stat_list.human.total_ship_deaths
                        + deaths
                    if #human_station_destroyed_list > 0 then
                        for i = 1, #human_station_destroyed_list do
                            if
                                string.find(
                                    human_station_destroyed_list[i],
                                    details.name
                                )
                            then
                                stat_list.human.ship[details.name].station =
                                    false
                                stat_list.human.ship[details.name].score = stat_list.human.ship[details.name].score
                                    - human_player_station_value
                                break
                            end
                        end
                    end
                    stat_list.human.score = stat_list.human.score
                        + stat_list.human.ship[details.name].score
                elseif details.faction == "Kraylor" then
                    local ship_value =
                        player_ship_stats[player_restart[pidx].template].strength
                    stat_list.kraylor.ship[details.name] = {
                        deaths = deaths,
                        score = -deaths * ship_value,
                        station = true,
                        ship_value = ship_value,
                    }
                    stat_list.kraylor.total_ship_deaths = stat_list.kraylor.total_ship_deaths
                        + deaths
                    stat_list.kraylor.score = stat_list.kraylor.score
                        + stat_list.kraylor.ship[details.name].score
                end
            end
        end
    end
    return stat_list
end
function vectorFromAngleNorth(angle, distance)
    if func_diagnostic then
        print("vector from angle north")
    end
    -- print("input angle to vectorFromAngleNorth:")
    -- print(angle)
    angle = (angle + 270) % 360
    local x, y = vectorFromAngle(angle, distance)
    return x, y
end
function tableRemoveRandom(array)
    if func_diagnostic then
        print("table remove random")
    end
    -- Remove random element from array and return it.
    -- Returns nil if the array is empty,
    -- analogous to `table.remove`.
    local array_item_count = #array
    if array_item_count == 0 then
        return nil
    end
    local selected_item = math.random(array_item_count)
    local temp = array[selected_item]
    array[selected_item] = array[array_item_count]
    array[array_item_count] = temp
    return table.remove(array)
end
function generateCallSignPrefix(length)
    if func_diagnostic then
        print("generate call sign prefix")
    end
    if prefix_length == nil then
        prefix_length = 1
    end
    if call_sign_prefix_pool == nil then
        call_sign_prefix_pool = {}
        prefix_length = prefix_length + 1
        if prefix_length > 3 then
            prefix_length = 1
        end
        fillPrefixPool()
    end
    if length == nil then
        length = prefix_length
    end
    local prefix_index = 0
    local prefix = ""
    for i = 1, length do
        if #call_sign_prefix_pool < 1 then
            fillPrefixPool()
        end
        prefix_index = math.random(1, #call_sign_prefix_pool)
        prefix = prefix .. call_sign_prefix_pool[prefix_index]
        table.remove(call_sign_prefix_pool, prefix_index)
    end
    return prefix
end
function fillPrefixPool()
    if func_diagnostic then
        print("fill prefix pool")
    end
    for i = 1, 26 do
        table.insert(call_sign_prefix_pool, string.char(i + 64))
    end
end
function generateCallSign(prefix)
    if func_diagnostic then
        print("generate call sign")
    end
    if prefix == nil then
        prefix = generateCallSignPrefix()
    end
    if suffix_index == nil then
        suffix_index = 0
    end
    suffix_index = suffix_index + math.random(1, 3)
    if suffix_index > 999 then
        suffix_index = 1
    end
    return string.format("%s%i", prefix, suffix_index)
end
function availableForComms(p)
    if func_diagnostic then
        print("available for comms")
    end
    return sharedAvailableForComms(p)
end
function planetCollisionDetection()
    if func_diagnostic then
        print("planet collision detection")
    end
    local planet_bump_damage = 5
    if planet_collision_diagnostic then
        print(
            "planet collision detection. bump damage:",
            planet_bump_damage,
            "planet count:",
            #planetList
        )
    end
    for planet_index, planet in ipairs(planetList) do
        local planet_x, planet_y = planet:getPosition()
        local collision_list = getObjectsInRadius(
            planet_x,
            planet_y,
            planet:getPlanetRadius() + 2000
        )
        local obj_dist = 0
        local ship_distance = 0
        local obj_type_name = ""
        if planet_collision_diagnostic then
            print(
                "planet index:",
                planet_index,
                "name:",
                planet:getCallSign(),
                "collision list count:",
                #collision_list
            )
        end
        for i, obj in ipairs(collision_list) do
            if obj:isValid() then
                if distance_diagnostic then
                    print("distance_diagnostic 25 obj:", obj, "planet:", planet)
                end
                obj_dist = distance(obj, planet)
                if isObjectType(obj, "CpuShip") then
                    obj_type_name = obj:getTypeName()
                    if obj_type_name ~= nil then
                        ship_distance = shipTemplateDistance[obj:getTypeName()]
                        if ship_distance == nil then
                            print(
                                "distance not retrieved from ship template for cpu ship:",
                                obj:getCallSign(),
                                "defaulting to ship distance 400"
                            )
                            ship_distance = 400
                        end
                    else
                        print(
                            "type name nil on cpu ship:",
                            obj:getCallSign(),
                            "defaulting to ship distance 400"
                        )
                        ship_distance = 400
                    end
                    if planet_collision_diagnostic then
                        print(
                            "CpuShip typename:",
                            obj_type_name,
                            "ship distance:",
                            ship_distance,
                            "object distance:",
                            obj_dist,
                            "planet radius:",
                            planet:getPlanetRadius()
                        )
                    end
                    if
                        obj_dist
                        <= (planet:getPlanetRadius() + ship_distance + 100)
                    then
                        obj:takeDamage(
                            planet_bump_damage,
                            "kinetic",
                            planet_x,
                            planet_y
                        )
                    end
                end
                if isObjectType(obj, "PlayerSpaceship") then
                    obj_type_name = obj:getTypeName()
                    if obj_type_name ~= nil then
                        ship_distance =
                            playerShipStats[obj:getTypeName()].distance
                        if ship_distance == nil then
                            print(
                                "distance not retrieved from player ship stats for player ship:",
                                obj:getCallSign(),
                                "defaulting to ship distance 400"
                            )
                            ship_distance = 400
                        end
                    else
                        print(
                            "type name nil on player ship:",
                            obj:getCallSign(),
                            "defaulting to ship distance 400"
                        )
                        ship_distance = 400
                    end
                    if
                        obj_dist
                        <= (planet:getPlanetRadius() + ship_distance + 100)
                    then
                        obj:takeDamage(
                            planet_bump_damage,
                            "kinetic",
                            planet_x,
                            planet_y
                        )
                    end
                    if planet_collision_diagnostic then
                        print(
                            "Player ship typename:",
                            obj_type_name,
                            "ship distance:",
                            ship_distance,
                            "object distance:",
                            obj_dist,
                            "planet radius:",
                            planet:getPlanetRadius()
                        )
                    end
                    if obj.task == "research" then
                        if planet_collision_diagnostic then
                            print(
                                "research orbital body count:",
                                #orbital_body_research
                            )
                        end
                        for j, orbit in ipairs(obj.orbital_body_research) do
                            if orbit.research == "N" then
                                if planet == orbit.body then
                                    if planet_collision_diagnostic then
                                        print(
                                            "incomplete body:",
                                            planet:getCallSign(),
                                            "obj/planet distance:",
                                            distance(obj, planet),
                                            "planet radius:",
                                            planet:getPlanetRadius()
                                        )
                                    end
                                    if
                                        distance(obj, planet)
                                        < (planet:getPlanetRadius() + 1800)
                                    then
                                        if orbit.start_scan_clock == nil then
                                            orbit.start_scan_clock =
                                                getScenarioTime()
                                            if planet_collision_diagnostic then
                                                print(
                                                    "start clock:",
                                                    orbit.start_scan_clock
                                                )
                                            end
                                        else
                                            if
                                                (
                                                    getScenarioTime()
                                                    - orbit.start_scan_clock
                                                )
                                                > research_task_length
                                            then
                                                orbit.research = "Y"
                                                obj.orbital_body_scanned_message_sci =
                                                    "orbital_body_scanned_message_sci"
                                                obj:addCustomMessage(
                                                    "Science",
                                                    obj.orbital_body_scanned_message_sci,
                                                    string.format(
                                                        _(
                                                            "msgScience",
                                                            "Scan complete for %s"
                                                        ),
                                                        planet:getCallSign()
                                                    )
                                                )
                                                obj.orbital_body_scanned_message_ops =
                                                    "orbital_body_scanned_message_ops"
                                                obj:addCustomMessage(
                                                    "Operations",
                                                    obj.orbital_body_scanned_message_ops,
                                                    string.format(
                                                        _(
                                                            "msgOperations",
                                                            "Scan complete for %s"
                                                        ),
                                                        planet:getCallSign()
                                                    )
                                                )
                                                if
                                                    planet_collision_diagnostic
                                                then
                                                    print(
                                                        "completed. start clock:",
                                                        orbit.start_scan_clock,
                                                        "current clock:",
                                                        getScenarioTime(),
                                                        "task length:",
                                                        research_task_length
                                                    )
                                                end
                                            end
                                        end
                                    else
                                        orbit.start_scan_clock = nil
                                        if planet_collision_diagnostic then
                                            print("reset start clock")
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                if isObjectType(obj, "ScanProbe") then
                    if obj_dist <= (planet:getPlanetRadius() + 50) then
                        obj:takeDamage(
                            planet_bump_damage,
                            "kinetic",
                            planet_x,
                            planet_y
                        )
                    end
                    local p = obj:getOwner()
                    if p ~= nil and p.task == "research" then
                        if obj.arrived then
                            for j, orbit in ipairs(p.orbital_body_research) do
                                if orbit.research == "N" then
                                    if planet == orbit.body then
                                        if
                                            distance(obj, planet)
                                            < (planet:getPlanetRadius() + 1800)
                                        then
                                            if
                                                orbit.start_scan_clock == nil
                                            then
                                                orbit.start_scan_clock =
                                                    getScenarioTime()
                                            else
                                                if
                                                    (
                                                        getScenarioTime()
                                                        - orbit.start_scan_clock
                                                    )
                                                    > research_task_length
                                                then
                                                    orbit.research = "Y"
                                                    p.orbital_body_scanned_message_sci =
                                                        "orbital_body_scanned_message_sci"
                                                    p:addCustomMessage(
                                                        "Science",
                                                        p.orbital_body_scanned_message_sci,
                                                        string.format(
                                                            _(
                                                                "msgScience",
                                                                "Scan complete for %s"
                                                            ),
                                                            planet:getCallSign()
                                                        )
                                                    )
                                                    p.orbital_body_scanned_message_ops =
                                                        "orbital_body_scanned_message_ops"
                                                    p:addCustomMessage(
                                                        "Operations",
                                                        p.orbital_body_scanned_message_ops,
                                                        string.format(
                                                            _(
                                                                "msgOperations",
                                                                "Scan complete for %s"
                                                            ),
                                                            planet:getCallSign()
                                                        )
                                                    )
                                                end
                                            end
                                        else
                                            orbit.start_scan_clock = nil
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
function blackHoleResearch(p)
    if func_diagnostic then
        print("black hole research")
    end
    if p.task == "research" then
        for i, orbit in ipairs(p.orbital_body_research) do
            if isObjectType(orbit.body, "BlackHole") then
                if orbit.research == "N" then
                    local scanning_count = 0
                    local black_hole_scan_range = 6800
                    if
                        distance(p, center_blackhole) < black_hole_scan_range
                    then
                        scanning_count = scanning_count + 1
                        if orbit.start_scan_clock == nil then
                            orbit.start_scan_clock = getScenarioTime()
                        else
                            if
                                (getScenarioTime() - orbit.start_scan_clock)
                                > research_task_length
                            then
                                orbit.research = "Y"
                                p.orbital_body_scanned_message_sci =
                                    "orbital_body_scanned_message_sci"
                                p:addCustomMessage(
                                    "Science",
                                    p.orbital_body_scanned_message_sci,
                                    string.format(
                                        _("msgScience", "Scan complete for %s"),
                                        orbit.body:getCallSign()
                                    )
                                )
                                p.orbital_body_scanned_message_ops =
                                    "orbital_body_scanned_message_ops"
                                p:addCustomMessage(
                                    "Operations",
                                    p.orbital_body_scanned_message_ops,
                                    string.format(
                                        _(
                                            "msgOperations",
                                            "Scan complete for %s"
                                        ),
                                        orbit.body:getCallSign()
                                    )
                                )
                            end
                        end
                    end
                    local obj_list = getObjectsInRadius(
                        terrain_center_x,
                        terrain_center_y,
                        black_hole_scan_range
                    )
                    for i, obj in ipairs(obj_list) do
                        if isObjectType(obj, "ScanProbe") then
                            if obj:getOwner() == p then
                                if obj.arrived then
                                    scanning_count = scanning_count + 1
                                    if orbit.start_scan_clock == nil then
                                        orbit.start_scan_clock =
                                            getScenarioTime()
                                    else
                                        if
                                            (
                                                getScenarioTime()
                                                - orbit.start_scan_clock
                                            )
                                            > research_task_length
                                        then
                                            orbit.research = "Y"
                                            p.orbital_body_scanned_message_sci =
                                                "orbital_body_scanned_message_sci"
                                            p:addCustomMessage(
                                                "Science",
                                                p.orbital_body_scanned_message_sci,
                                                string.format(
                                                    _(
                                                        "msgScience",
                                                        "Scan complete for %s"
                                                    ),
                                                    orbit.body:getCallSign()
                                                )
                                            )
                                            p.orbital_body_scanned_message_ops =
                                                "orbital_body_scanned_message_ops"
                                            p:addCustomMessage(
                                                "Operations",
                                                p.orbital_body_scanned_message_ops,
                                                string.format(
                                                    _(
                                                        "msgOperations",
                                                        "Scan complete for %s"
                                                    ),
                                                    orbit.body:getCallSign()
                                                )
                                            )
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if scanning_count == 0 then
                        orbit.start_scan_clock = nil
                    end
                end
                break
            end
        end
    end
end
function marauderDestroyed(self, instigator)
    if func_diagnostic then
        print("marauder destroyed")
    end
    local ship_found = false
    for i, p in ipairs(getActivePlayerShips()) do
        if p.assist_freighter_marauders ~= nil then
            for j, m in ipairs(p.assist_freighter_marauders) do
                if m.name == self:getCallSign() then
                    if m.destroyed_clock == nil then
                        m.destroyed_clock = getScenarioTime()
                        ship_found = true
                        break
                    end
                end
            end
            if ship_found then
                break
            end
        end
    end
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
    if func_diagnostic then
        print("spawn enemies")
    end
    if enemyFaction == nil then
        enemyFaction = "Kraylor"
    end
    if danger == nil then
        danger = 1
    end
    if enemyStrength == nil then
        enemyStrength = math.max(danger * 50, 5)
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
            local selected_template_info = string.format(
                "Spawn enemies selected template: %s",
                selected_template
            )
            local enemy_strength_info =
                string.format("enemy strength: %s", enemyStrength)
            local template_info = "No ship template"
            if ship_template ~= nil then
                template_info = string.format(
                    "template strength: %s",
                    ship_template[selected_template].strength
                )
            end
            print(
                selected_template_info,
                enemy_strength_info,
                template_info,
                enemyFaction
            )
            -- print("Spawn Enemies selected template:",selected_template,"enemy strength:",enemyStrength,"template strength:",ship_template[selected_template].strength,"Enemy faction:",enemyFaction)
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
------------------------------------------------
-- Enemy (Computer controlled Exuari) Waves  --
------------------------------------------------
function addWave(enemyList, type, a, d)
    if func_diagnostic then
        print("add wave")
    end
    -- Add an enemy wave.
    -- enemyList: A table containing enemy ship objects.
    -- type: A number; at each integer, determines a different wave of ships to add
    --       to the enemyList. Any number is valid, but only 0.99-9.0 are meaningful.
    -- a: The spawned wave's heading relative to the players' spawn point.
    -- d: The spawned wave's distance from the players' spawn point.
    -- NOTE: terrain_center_x and terrain_center_y are for the center of the black hole, which is essentially the center of the environment design
    -- the black hole is off-set from the F5 origin so that if ships have to respawn into the game and they do so at the F5 origin, they don't get immediately sucked into the black hole... bummer

    if type < 1.0 then
        -- table.insert(enemyList, setCirclePos(CpuShip():setTemplate('Stalker Q7'):setRotation(a + 180):orderRoaming(), 0, 0, a, d))    -- original code
        table.insert(
            enemyList,
            setCirclePos(
                    CpuShip()
                        :setFaction("Exuari")
                        :setTemplate(ST.STALKER_Q7)
                        :setRotation(a + 180)
                        :orderRoaming()
                        :onDestruction(enemyCpuShipDestroyed),
                    terrain_center_x,
                    terrain_center_y,
                    a,
                    d
                )
                :setCommsScript("")
                :setCommsFunction(commsShip)
        )
        total_enemy_ships_spawned = total_enemy_ships_spawned + 1
        -- 'Stalker Q7' ships already have a warp drive, so no real modification is necessary
    elseif type < 2.0 then
        leader = setCirclePos(
            CpuShip()
                :setFaction("Exuari")
                :setTemplate(ST.PHOBOS_T3)
                :setRotation(a + 180)
                :orderRoaming()
                :setWarpDrive(true)
                :onDestruction(enemyCpuShipDestroyed),
            terrain_center_x,
            terrain_center_y,
            a + random(-1, 1),
            d + random(-100, 100):setCommsScript(""):setCommsFunction(commsShip)
        )
        table.insert(enemyList, leader)
        table.insert(
            enemyList,
            setCirclePos(
                CpuShip()
                    :setFaction("Exuari")
                    :setTemplate(ST.MT52_HORNET)
                    :setRotation(a + 180)
                    :setWarpDrive(true)
                    :orderFlyFormation(leader, -400, 0)
                    :onDestruction(enemyCpuShipDestroyed),
                terrain_center_x,
                terrain_center_y,
                a + random(-1, 1),
                d + random(-100, 100)
            )
        )
        table.insert(
            enemyList,
            setCirclePos(
                CpuShip()
                    :setFaction("Exuari")
                    :setTemplate(ST.MT52_HORNET)
                    :setRotation(a + 180)
                    :setWarpDrive(true)
                    :orderFlyFormation(leader, 400, 0)
                    :onDestruction(enemyCpuShipDestroyed),
                terrain_center_x,
                terrain_center_y,
                a + random(-1, 1),
                d + random(-100, 100)
            )
        )
        table.insert(
            enemyList,
            setCirclePos(
                CpuShip()
                    :setFaction("Exuari")
                    :setTemplate(ST.MT52_HORNET)
                    :setRotation(a + 180)
                    :setWarpDrive(true)
                    :orderFlyFormation(leader, -400, 400)
                    :onDestruction(enemyCpuShipDestroyed),
                terrain_center_x,
                terrain_center_y,
                a + random(-1, 1),
                d + random(-100, 100)
            )
        )
        table.insert(
            enemyList,
            setCirclePos(
                CpuShip()
                    :setFaction("Exuari")
                    :setTemplate(ST.MT52_HORNET)
                    :setRotation(a + 180)
                    :setWarpDrive(true)
                    :orderFlyFormation(leader, 400, 400)
                    :onDestruction(enemyCpuShipDestroyed),
                terrain_center_x,
                terrain_center_y,
                a + random(-1, 1),
                d + random(-100, 100)
            )
        )
        total_enemy_ships_spawned = total_enemy_ships_spawned + 5
    elseif type < 3.0 then
        table.insert(
            enemyList,
            setCirclePos(
                CpuShip()
                    :setFaction("Exuari")
                    :setTemplate(ST.ADDER_MK5)
                    :setRotation(a + 180)
                    :setWarpDrive(true)
                    :orderRoaming()
                    :onDestruction(enemyCpuShipDestroyed),
                terrain_center_x,
                terrain_center_y,
                a + random(-5, 5),
                d + random(-100, 100)
            )
        )
        table.insert(
            enemyList,
            setCirclePos(
                CpuShip()
                    :setFaction("Exuari")
                    :setTemplate(ST.ADDER_MK5)
                    :setRotation(a + 180)
                    :setWarpDrive(true)
                    :orderRoaming()
                    :onDestruction(enemyCpuShipDestroyed),
                terrain_center_x,
                terrain_center_y,
                a + random(-5, 5),
                d + random(-100, 100)
            )
        )
        total_enemy_ships_spawned = total_enemy_ships_spawned + 2
    elseif type < 4.0 then
        table.insert(
            enemyList,
            setCirclePos(
                CpuShip()
                    :setFaction("Exuari")
                    :setTemplate(ST.PHOBOS_T3)
                    :setRotation(a + 180)
                    :setWarpDrive(true)
                    :orderRoaming()
                    :onDestruction(enemyCpuShipDestroyed),
                terrain_center_x,
                terrain_center_y,
                a + random(-5, 5),
                d + random(-100, 100)
            )
        )
        table.insert(
            enemyList,
            setCirclePos(
                CpuShip()
                    :setFaction("Exuari")
                    :setTemplate(ST.PHOBOS_T3)
                    :setRotation(a + 180)
                    :setWarpDrive(true)
                    :orderRoaming()
                    :onDestruction(enemyCpuShipDestroyed),
                terrain_center_x,
                terrain_center_y,
                a + random(-5, 5),
                d + random(-100, 100)
            )
        )
        table.insert(
            enemyList,
            setCirclePos(
                CpuShip()
                    :setFaction("Exuari")
                    :setTemplate(ST.PHOBOS_T3)
                    :setRotation(a + 180)
                    :setWarpDrive(true)
                    :orderRoaming()
                    :onDestruction(enemyCpuShipDestroyed),
                terrain_center_x,
                terrain_center_y,
                a + random(-5, 5),
                d + random(-100, 100)
            )
        )
        total_enemy_ships_spawned = total_enemy_ships_spawned + 3
    elseif type < 5.0 then
        table.insert(
            enemyList,
            setCirclePos(
                CpuShip()
                    :setFaction("Exuari")
                    :setTemplate(ST.ATLANTIS_X23)
                    :setRotation(a + 180)
                    :orderRoaming()
                    :setWeaponStorageMax("Homing", 40)
                    :setWeaponStorage("Homing", 40)
                    :setWeaponStorageMax("Nuke", 15)
                    :setWeaponStorage("Nuke", 15)
                    :setWeaponStorageMax("EMP", 10)
                    :setWeaponStorage("EMP", 10)
                    :onDestruction(enemyCpuShipDestroyed),
                terrain_center_x,
                terrain_center_y,
                a + random(-5, 5),
                d + random(-100, 100)
            )
        )
        total_enemy_ships_spawned = total_enemy_ships_spawned + 1
    elseif type < 6.0 then
        leader = setCirclePos(
            CpuShip()
                :setFaction("Exuari")
                :setTemplate(ST.PIRANHA_F12)
                :setRotation(a + 180)
                :setWarpDrive(true)
                :orderRoaming()
                :onDestruction(enemyCpuShipDestroyed),
            terrain_center_x,
            terrain_center_y,
            a + random(-5, 5),
            d + random(-100, 100)
        )
        table.insert(enemyList, leader)
        table.insert(
            enemyList,
            setCirclePos(
                CpuShip()
                    :setFaction("Exuari")
                    :setTemplate(ST.MT52_HORNET)
                    :setRotation(a + 180)
                    :setWarpDrive(true)
                    :orderFlyFormation(leader, -1500, 400)
                    :onDestruction(enemyCpuShipDestroyed),
                terrain_center_x,
                terrain_center_y,
                a + random(-1, 1),
                d + random(-100, 100)
            )
        )
        table.insert(
            enemyList,
            setCirclePos(
                CpuShip()
                    :setFaction("Exuari")
                    :setTemplate(ST.MT52_HORNET)
                    :setRotation(a + 180)
                    :setWarpDrive(true)
                    :orderFlyFormation(leader, 1500, 400)
                    :onDestruction(enemyCpuShipDestroyed),
                terrain_center_x,
                terrain_center_y,
                a + random(-1, 1),
                d + random(-100, 100)
            )
        )
        total_enemy_ships_spawned = total_enemy_ships_spawned + 3
    elseif type < 7.0 then
        table.insert(
            enemyList,
            setCirclePos(
                CpuShip()
                    :setFaction("Exuari")
                    :setTemplate(ST.PHOBOS_T3)
                    :setRotation(a + 180)
                    :setWarpDrive(true)
                    :orderRoaming()
                    :onDestruction(enemyCpuShipDestroyed),
                terrain_center_x,
                terrain_center_y,
                a + random(-5, 5),
                d + random(-100, 100)
            )
        )
        table.insert(
            enemyList,
            setCirclePos(
                CpuShip()
                    :setFaction("Exuari")
                    :setTemplate(ST.PHOBOS_T3)
                    :setRotation(a + 180)
                    :setWarpDrive(true)
                    :orderRoaming()
                    :onDestruction(enemyCpuShipDestroyed),
                terrain_center_x,
                terrain_center_y,
                a + random(-5, 5),
                d + random(-100, 100)
            )
        )
        total_enemy_ships_spawned = total_enemy_ships_spawned + 2
    elseif type < 8.0 then
        table.insert(
            enemyList,
            setCirclePos(
                CpuShip()
                    :setFaction("Exuari")
                    :setTemplate(ST.NIRVANA_R5)
                    :setRotation(a + 180)
                    :setWarpDrive(true)
                    :orderRoaming()
                    :onDestruction(enemyCpuShipDestroyed),
                terrain_center_x,
                terrain_center_y,
                a + random(-5, 5),
                d + random(-100, 100)
            )
        )
        total_enemy_ships_spawned = total_enemy_ships_spawned + 1
    elseif type < 9.0 then
        table.insert(
            enemyList,
            setCirclePos(
                CpuShip()
                    :setFaction("Exuari")
                    :setTemplate(ST.MU52_HORNET)
                    :setRotation(a + 180)
                    :setWarpDrive(true)
                    :orderRoaming()
                    :onDestruction(enemyCpuShipDestroyed),
                terrain_center_x,
                terrain_center_y,
                a + random(-5, 5),
                d + random(-100, 100)
            )
        )
        total_enemy_ships_spawned = total_enemy_ships_spawned + 1
    else
        table.insert(
            enemyList,
            setCirclePos(
                CpuShip()
                    :setFaction("Exuari")
                    :setTemplate(ST.STALKER_R7)
                    :setRotation(a + 180)
                    :setWarpDrive(true)
                    :orderRoaming()
                    :onDestruction(enemyCpuShipDestroyed),
                terrain_center_x,
                terrain_center_y,
                a + random(-5, 5),
                d + random(-100, 100)
            )
        )
        table.insert(
            enemyList,
            setCirclePos(
                CpuShip()
                    :setFaction("Exuari")
                    :setTemplate(ST.STALKER_R7)
                    :setRotation(a + 180)
                    :setWarpDrive(true)
                    :orderRoaming()
                    :onDestruction(enemyCpuShipDestroyed),
                terrain_center_x,
                terrain_center_y,
                a + random(-5, 5),
                d + random(-100, 100)
            )
        )
        total_enemy_ships_spawned = total_enemy_ships_spawned + 2
    end
end
function setWaveAngle(cnt, enemy_group_count)
    if func_diagnostic then
        print("set wave angle")
    end
    -- Returns a semi-random heading.
    -- cnt: A counter, generally between 1 and the number of enemy groups.
    -- enemy_group_count: A number of enemy groups, generally set by the scenario type.
    return cnt * 360 / enemy_group_count + random(-60, 60) -- this is the original code segment
end
function setWaveDistance(enemy_group_count)
    if func_diagnostic then
        print("set wave distance")
    end
    -- Returns a semi-random distance.
    -- enemy_group_count: A number of enemy groups, generally set by the scenario type.
    -- return random(35000, 40000 + enemy_group_count * 3000)   -- this is the original code segment
    return random(80000, 100000 + enemy_group_count * 3000)
end
function enemyCpuShipDestroyed(self, instigator)
    if func_diagnostic then
        print("enemy cpu ship destroyed")
    end
    local instigator_pidx = nil
    local instigator_faction = nil
    if instigator ~= nil then
        if instigator.pidx ~= nil then
            instigator_pidx = instigator.pidx
        end
        if instigator:getFaction() ~= nil then
            instigator_faction = instigator:getFaction()
        end
    end
    total_exuari_killed = total_exuari_killed + 1
    exuari_score = exuari_score - ship_template[self:getTypeName()].strength
    if instigator_faction ~= nil then
        if instigator_faction == "Exuari" then
            total_exuari_killed_by_exuari = total_exuari_killed_by_exuari + 1
        end
        if instigator_faction == "Kraylor" then
            total_exuari_killed_by_kraylor = total_exuari_killed_by_kraylor + 1
        end
        if instigator_faction == "Human Navy" then
            total_exuari_killed_by_human = total_exuari_killed_by_human + 1
        end
        if
            instigator_faction == "Kraylor"
            or instigator_faction == "Human Navy"
        then
            if instigator_pidx ~= nil then
                if player_restart[instigator_pidx] ~= nil then
                    if player_restart[instigator_pidx].kills == nil then
                        player_restart.add(
                            instigator_pidx,
                            nil,
                            nil,
                            nil,
                            nil,
                            nil,
                            nil,
                            nil,
                            0,
                            0,
                            0,
                            0,
                            0,
                            0,
                            0,
                            0
                        )
                    end
                    player_restart[instigator_pidx].kills = player_restart[instigator_pidx].kills
                        + 1
                    player_restart[instigator_pidx].exuari_kills = player_restart[instigator_pidx].exuari_kills
                        + 1
                end
            end
        end
    end
    local culprit = ""
    if instigator_faction ~= nil then
        culprit = " by " .. instigator_faction
        if instigator_pidx ~= nil then
            culprit = " by " .. instigator:getCallSign()
        end
    end
    print(
        string.format(
            "!WHACK!  Exuari vessel %s has been destroyed%s!",
            self:getCallSign(),
            culprit
        )
    )
    if instigator_faction ~= nil then
        for i = 1, 32 do
            local p = getPlayerShip(i)
            if p ~= nil and p:isValid() and p ~= instigator then
                if p:getFaction() == instigator_faction then
                    p:addToShipLog(
                        string.format(
                            "!WHACK!  Exuari vessel %s has been destroyed%s!",
                            self:getCallSign(),
                            culprit
                        ),
                        "Red"
                    )
                end
            end
        end
    end
end
---------------------------------------------
-- Player setup and management functions  --
---------------------------------------------
function identifyPlayerShip(p, paused)
    if func_diagnostic then
        print("identify player ship")
    end
    --first parameter, p is the player ship
    --second parameter, paused tells whether the game is paused. Players created during pause are trainees
    local function transformTrainee(p)
        p:setTemplate(ST.ATLANTIS)
        p:setWeaponStorageMax("Homing", 0) --these missile types will come back later
        p:setWeaponStorage("Homing", 0)
        p:setWeaponStorageMax("Mine", 0)
        p:setWeaponStorage("Mine", 0)
        p:setWeaponStorageMax("EMP", 0)
        p:setWeaponStorage("EMP", 0)
        p:setWeaponStorageMax("Nuke", 0)
        p:setWeaponStorage("Nuke", 0)
        --                 Arc,  Dir, Range, CycleTime, Dmg
        p:setBeamWeapon(0, 100, -20, 1500, 60, 8) --raise cycle time from 6
        p:setBeamWeapon(1, 100, 20, 1500, 60, 8) --these beams are corrected later
        player_restart.add(
            p.pidx,
            nil,
            nil,
            nil,
            nil,
            nil,
            p:getTypeName(),
            "Human Navy"
        )
        --this is where you might reset based on the tasks completed so far
    end
    -- print("identify player ship")
    local pidx = nil
    if p.pidx == nil then
        if paused then
            print("problem: p.pidx not set and we're paused")
        else
            for api, ap in ipairs(getActivePlayerShips()) do
                if ap == p then
                    p.pidx = api
                    pidx = api
                    break
                end
            end
        end
    else
        pidx = p.pidx
    end
    p:onDestroyed(playerDestroyed)
    -- print("pidx:",pidx)
    if paused then --you can only spawn trainees while paused
        transformTrainee(p)
    else
        if pidx > trainee_player_count then --trainers (player controlled Kraylor) are spawned here
            if
                player_restart[pidx] ~= nil
                and player_restart[pidx].template ~= nil
            then
                p:setTemplate(player_restart[pidx].template)
            else
                player_restart.add(
                    pidx,
                    nil,
                    nil,
                    nil,
                    nil,
                    nil,
                    p:getTypeName(),
                    "Kraylor"
                )
                p:addToShipLog(
                    _(
                        "shipLog",
                        "Destroy Human Navy ships and bases. You might get help from Independent bases. Destroying Exuari is secondary but glorifies the Kraylor empire in the eyes of those around you. Avoid planetary bodies."
                    ),
                    "Magenta"
                )
            end
            p:setFaction("Kraylor")
            if not p:hasWarpDrive() and not p:hasJumpDrive() then --for ships without FTL drive
                p:setWarpDrive(true)
                p:setWarpSpeed(250)
                p:setHullMax(p:getHullMax() * 2)
            end
        else --respawned trainees need to be transformed again
            transformTrainee(p)
        end
    end
    local player_template = p:getTypeName()
    p.max_repair_crew = p:getRepairCrewCount()
    p.ship_score = player_ship_stats[player_template].strength
    p.max_cargo = player_ship_stats[player_template].cargo
    p.cargo = p.max_cargo
    p:setLongRangeRadarRange(
        player_ship_stats[player_template].long_range_radar
    )
    p.normal_long_range_radar =
        player_ship_stats[player_template].long_range_radar
    p:setShortRangeRadarRange(
        player_ship_stats[player_template].short_range_radar
    )
    p:onProbeLaunch(probeTracker)
    if player_restart[pidx] ~= nil and player_restart[pidx].name ~= nil then
        p:setCallSign(player_restart[pidx].name)
        for i, station in ipairs(stationList) do
            if station:isValid() then
                if station.home_player_name ~= nil then
                    if station.home_player_name == p:getCallSign() then
                        p.home_station = station
                        break
                    end
                end
            end
        end
        if p.home_station == nil then
            for i, station in ipairs(allied_stations) do
                if station:isValid() then
                    p.home_station = station
                    station.home_player_name = p:getCallSign()
                    break
                end
            end
        end
        if nemesis_stations ~= nil then
            for i, nemesis in ipairs(nemesis_stations) do
                local station = nemesis.station
                if station:isValid() then
                    if station.victim_name ~= nil then
                        if station.victim_name == p:getCallSign() then
                            p.nemesis_station = station
                            break
                        end
                    end
                end
            end
        end
    -- print("set player ship name to stored player ship name:",player_restart[pidx].name)
    else
        if paused ~= nil and paused == true then
            if
                predefined_player_ships ~= nil
                and predefined_player_ships[pidx] ~= nil
            then
                p:setCallSign(predefined_player_ships[pidx].name)
            -- print("setting player ship name to predefined name:",predefined_player_ships[pidx].name)
            else
                local selected_name_index =
                    math.random(1, #trainee_player_ship_names)
                p:setCallSign(trainee_player_ship_names[selected_name_index])
                -- print("setting player name to randomly selected trainee name:",trainee_player_ship_names[selected_name_index])
                table.remove(trainee_player_ship_names, selected_name_index)
            end
        else
            selected_name_index = math.random(1, #trainer_player_ship_names)
            p:setCallSign(trainer_player_ship_names[selected_name_index])
            -- print("setting player ship name to randomly selected trainer name:",trainer_player_ship_names[selected_name_index])
            table.remove(trainer_player_ship_names, selected_name_index)
        end
        player_restart.add(pidx, p:getCallSign())
    end
    if use_control_codes then
        if
            player_restart[pidx] ~= nil
            and player_restart[pidx].control_code ~= nil
        then
            p.control_code = player_restart[pidx].control_code
            p:setControlCode(player_restart[pidx].control_code)
        else
            local control_code_set = false
            if
                predefined_player_ships ~= nil
                and predefined_player_ships[pidx] ~= nil
            then
                if predefined_player_ships[pidx].control_code ~= nil then
                    p.control_code = predefined_player_ships[pidx].control_code
                    p:setControlCode(predefined_player_ships[pidx].control_code)
                    control_code_set = true
                end
            end
            if not control_code_set then
                assignControlCode(p)
            end
            player_restart.add(pidx, nil, p.control_code)
        end
    end
end
function placeTraineePlayerShipsAndStations()
    if func_diagnostic then
        print("place trainee player ships and stations")
    end
    local angle = random(0, 360) --arbitrary start position around circle
    local psx = 0
    local psy = 0
    local angle_increment = 360 / trainee_player_count
    allied_stations = {}
    for pidx = 1, trainee_player_count do
        local p = getPlayerShip(pidx)
        if p ~= nil and p:isValid() then
            psx, psy = vectorFromAngle(angle, trainee_placement_radius)
            psx = terrain_center_x + psx
            psy = terrain_center_y + psy
            p:setPosition(psx, psy)
            p.start_x = psx
            p.start_y = psy
            p.angle = angle
            local tra = angle + 180
            if tra > 360 then
                tra = tra - 360
            end
            p:commandTargetRotation(tra)
            local ha = angle + 270
            if ha > 360 then
                ha = ha - 360
            end
            p:setHeading(ha)
            player_restart.add(pidx, nil, nil, p.start_x, p.start_y, p.angle)
            psx, psy = vectorFromAngle(angle, trainee_base_placement_radius)
            local allied_station = placeStation(
                terrain_center_x + psx,
                terrain_center_y + psy,
                "RandomHumanNeutral",
                "Human Navy",
                "Medium Station"
            )
            p.home_station = allied_station
            allied_station.home_player_name = p:getCallSign()
            allied_station:setSharesEnergyWithDocked(true)
            allied_station:setRepairDocked(true)
            allied_station:setRestocksScanProbes(true)
            allied_station.heading_angle = (ha + 180) % 360
            allied_station.distress_signal_delay = 0 -- the intent here is to build in a delay on how many times a station sends out a distress call, otherwise, the log gets overwhelmed with updates; initially set to no delay for first notice
            table.insert(stationList, allied_station)
            table.insert(allied_stations, allied_station)
            --these stations are not strictly trainee, but can be used by trainees and trainers
            psx, psy = vectorFromAngle(
                (angle + (angle_increment / 2) % 360),
                trainee_base_placement_radius + random(8000, 25000)
            )
            local station = placeStation(
                terrain_center_x + psx,
                terrain_center_y + psy,
                "RandomHumanNeutral",
                "Independent",
                "Small Station"
            )
            station.comms_data = {
                weapons = {
                    Homing = "neutral",
                    HVLI = "neutral",
                    Mine = "neutral",
                    Nuke = "neutral",
                    EMP = "neutral",
                },
                weapon_cost = {
                    Homing = 2,
                    HVLI = 1,
                    Mine = 3,
                    Nuke = 15,
                    EMP = 12,
                },
                reputation_cost_multipliers = { friend = 1.0, neutral = 2 },
                max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            }
            station.distress_signal_delay = 0
            table.insert(stationList, station)
            local neb_x, neb_y =
                vectorFromAngleNorth(allied_station.heading_angle, 25000)
            local station_x, station_y = allied_station:getPosition()
            neb_x = neb_x + station_x
            neb_y = neb_y + station_y
            Nebula():setPosition(neb_x, neb_y)
            allied_station.neb_x = neb_x
            allied_station.neb_y = neb_y
            angle = angle + angle_increment
            if angle > 360 then
                angle = angle - 360
            end
        end
    end
end
function probeTracker(launcher, probe)
    if func_diagnostic then
        print("probe tracker")
    end
    string.format("")
    if probe_list == nil then
        probe_list = {}
    end
    table.insert(probe_list, {
        launcher = launcher,
        probe = probe,
        clock = getScenarioTime(),
        del = false,
    })
    probe.arrived = false
    probe:onArrival(function(self, x, y)
        string.format("")
        self.arrived = true
    end)
end
function destroyOnArrival(self)
    if func_diagnostic then
        print("destroy on arrival")
    end
    string.format("")
    self:destroy()
end
function playerDestroyed(self, instigator)
    if func_diagnostic then
        print("player destroyed")
    end
    local pidx = self.pidx --set player (self) player index value
    local faction = self:getFaction() --set player (self) faction
    local instigator_pidx = nil
    local instigator_faction = nil
    if instigator ~= nil then --if instigator of destruction is recognized
        if instigator.pidx ~= nil then --if instigator is a player (pidx will be set)
            instigator_pidx = instigator.pidx
        end
        if instigator:getFaction() ~= nil then
            instigator_faction = instigator:getFaction()
        end
    end
    if player_restart[pidx].deaths == nil then --if counters not yet set
        player_restart.add(
            pidx,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            nil,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        )
    end
    player_restart[pidx].deaths = player_restart[pidx].deaths + 1 --increment player death counter
    if instigator_faction ~= nil then
        if instigator_pidx ~= nil then
            if player_restart[instigator_pidx] ~= nil then
                if player_restart[instigator_pidx].kills == nil then --if counters not yet set
                    player_restart.add(
                        instigator_pidx,
                        nil,
                        nil,
                        nil,
                        nil,
                        nil,
                        nil,
                        nil,
                        0,
                        0,
                        0,
                        0,
                        0,
                        0,
                        0,
                        0
                    )
                end
                player_restart[instigator_pidx].kills = player_restart[instigator_pidx].kills
                    + 1
                if faction == "Exuari" then
                    player_restart[instigator_pidx].exuari_kills = player_restart[instigator_pidx].exuari_kills
                        + 1
                end
                if faction == "Kraylor" then
                    player_restart[instigator_pidx].kraylor_kills = player_restart[instigator_pidx].kraylor_kills
                        + 1
                end
                if faction == "Human Navy" then
                    player_restart[instigator_pidx].human_kills = player_restart[instigator_pidx].human_kills
                        + 1
                end
            end
        end
        if instigator_faction == "Exuari" then
            player_restart[pidx].exuari_deaths = player_restart[pidx].exuari_deaths
                + 1
        end
        if instigator_faction == "Kraylor" then
            player_restart[pidx].kraylor_deaths = player_restart[pidx].kraylor_deaths
                + 1
        end
        if instigator_faction == "Human Navy" then
            player_restart[pidx].human_deaths = player_restart[pidx].human_deaths
                + 1
        end
    end
    local culprit = ""
    if instigator_faction ~= nil then
        culprit = " by " .. instigator_faction
    end
    print(
        string.format(
            "!WHACK!  %s has been destroyed%s! Will respawn automatically",
            self:getCallSign(),
            culprit
        )
    )
    globalMessage(
        string.format(
            _("msgMainscreen", "%s has been destroyed%s! Respawning"),
            self:getCallSign(),
            culprit
        )
    )
    for i = 1, 32 do
        local p = getPlayerShip(pidx)
        if p ~= nil and p:isValid() and p ~= self then
            if p:getFaction() == faction then
                p:addToShipLog(
                    string.format(
                        _(
                            "shipLog",
                            "%s has been destroyed%s! All crew lost. Rest in peace"
                        ),
                        self:getCallSign(),
                        culprit
                    ),
                    "Red"
                )
            end
        end
    end
end
---------------------------
-- Station communication --
---------------------------
-----------------------------
--  Station communication  --
-----------------------------
local station_profile

local function handleHomeStationTask()
    if comms_target ~= comms_source.home_station then
        return false
    end
    local handled = true
        if comms_source.start_dock_message == "start" then
            setCommsMessage(
                string.format(
                    _(
                        "station-comms",
                        "Greetings captain and crew of %s. You have been assigned to station %s. You will be given several tasks. For each task, you will be provided an evaluation.\n\nReady for your first task?"
                    ),
                    comms_source:getCallSign(),
                    comms_target:getCallSign()
                )
            )
            addCommsReply(
                _("station-comms", "We are ready for our first task"),
                function()
                    comms_source.start_dock_message = "sent"
                    if comms_source.dock_start_clock == nil then
                        comms_source.dock_start_clock = getScenarioTime()
                    end
                    if crutch then
                        sendCrutch(comms_source, "dock")
                    end
                    setCommsMessage(
                        string.format(
                            _(
                                "station-comms",
                                "Your first task is to dock with %s. Check with the docking port authority on %s for any docking protocols. Your evaluation has begun. Clock: %s"
                            ),
                            comms_target:getCallSign(),
                            comms_target:getCallSign(),
                            colonTime(comms_source.dock_start_clock)
                        )
                    )
                end
            )
        elseif comms_source.scan_message == "start" then
            setCommsMessage(
                string.format(
                    _(
                        "station-comms",
                        "Congratulations on completing your docking task, %s. Are you ready for your next task?"
                    ),
                    comms_source:getCallSign()
                )
            )
            addCommsReply(
                _("station-comms", "View docking task evalutation"),
                dockTaskEvaluation
            )
            addCommsReply(
                _("station-comms", "We are ready for our second task"),
                function()
                    comms_source.scan_message = "sent"
                    if comms_source.scan_start_clock == nil then
                        comms_source.scan_start_clock = getScenarioTime()
                    end
                    if crutch then
                        sendCrutch(comms_source, "scan")
                    end
                    setCommsMessage(
                        string.format(
                            _(
                                "station-comms",
                                "Identify the targets at bearing %.1f from %s. A probe might help. Report those details to us once you've completed your scans. Your evaluation has begun. Clock: %s"
                            ),
                            comms_target.heading_angle,
                            comms_target:getCallSign(),
                            colonTime(comms_source.scan_start_clock)
                        )
                    )
                end
            )
        elseif comms_source.destroy_freighter_message == "start" then
            setCommsMessage(
                string.format(
                    _(
                        "station-comms",
                        "Congratulations on completing your scanning task, %s. Are you ready for your next task?"
                    ),
                    comms_source:getCallSign()
                )
            )
            addCommsReply(
                _("station-comms", "View scanning task evaluation"),
                scanTaskEvaluation
            )
            addCommsReply(
                _("station-comms", "We are ready for our third task"),
                function()
                    comms_source.destroy_freighter_message = "sent"
                    if comms_source.destroy_freighter_start_clock == nil then
                        comms_source.destroy_freighter_start_clock =
                            getScenarioTime()
                    end
                    if crutch then
                        sendCrutch(comms_source, "destroy freighter")
                    end
                    setCommsMessage(
                        string.format(
                            _(
                                "station-comms",
                                "Destroy the Kraylor freighter you identified during your scanning task. Use HVLI. Your beams will take too long to cycle. Your evaluation has begun. Clock: %s"
                            ),
                            colonTime(
                                comms_source.destroy_freighter_start_clock
                            )
                        )
                    )
                end
            )
        elseif comms_source.assist_freighter_message == "start" then
            setCommsMessage(
                string.format(
                    _(
                        "station-comms",
                        "Congratulations on completing your task to destroy that Kraylor freighter, %s. Are you ready for your next task?"
                    ),
                    comms_source:getCallSign()
                )
            )
            addCommsReply(
                _("station-comms", "View destroy freighter task evaluation"),
                destroyFreighterTaskEvaluation
            )
            addCommsReply(
                _("station-comms", "We are ready for our fourth task"),
                function()
                    comms_source.assist_freighter_message = "sent"
                    if comms_source.assist_freighter_start_clock == nil then
                        comms_source.assist_freighter_start_clock =
                            getScenarioTime()
                    end
                    if crutch then
                        sendCrutch(comms_source, "assist freighter")
                    end
                    setCommsMessage(
                        string.format(
                            _(
                                "station-comms",
                                "We received a distress call from Arlenian freighter %s. They report experiencing engine trouble, but the report lacked technical details. They're worried about possible Kraylor nearby. Your task: talk to them, find out about their needs, help them and protect them if necessary. Most likely, %s has the repair parts for their engines, but will need details on the problem before providing any parts. You can find %s in sector %s. Your combat systems are fully operational. Your evaluation has begun. Clock: %s"
                            ),
                            comms_source.assist_freighter:getCallSign(),
                            comms_source.home_station:getCallSign(),
                            comms_source.assist_freighter:getCallSign(),
                            comms_source.assist_freighter:getSectorName(),
                            colonTime(comms_source.assist_freighter_start_clock)
                        )
                    )
                end
            )
        elseif comms_source.assist_freighter_attack_warning == "start" then
            setCommsMessage(
                string.format(
                    _(
                        "station-comms",
                        "We just received a panicky call from Arlenian freighter %s. Their sensors have picked up Kraylor fighters 20 units away headed for them at 4.8 units per minute. They urgently request you come protect them."
                    ),
                    comms_source.assist_freighter:getCallSign()
                )
            )
            addCommsReply("Remind us where they are located", function()
                setCommsMessage(
                    string.format(
                        "Arlenian freighter %s is located in sector %s",
                        comms_source.assist_freighter:getCallSign(),
                        comms_source.assist_freighter:getSectorName()
                    )
                )
                addCommsReply(_("Back"), commsStation)
            end)
            addCommsReply(
                _("station-comms", "We'll protect them as soon as we can"),
                function()
                    setCommsMessage(
                        _(
                            "station-comms",
                            "I'm sure they'll appreciate any protection you can provide."
                        )
                    )
                    comms_source.assist_freighter_attack_warning = "sent"
                end
            )
            if comms_source.assist_freighter_parts == "loaded" then
                addCommsReply(
                    _("station-comms", "We've got their parts and are en route"),
                    function()
                        setCommsMessage(
                            _(
                                "station-comms",
                                "We will pass along that information. Good luck and keep a sharp eye out for those Kraylor"
                            )
                        )
                        comms_source.assist_freighter_attack_warning = "sent"
                    end
                )
            else
                addCommsReply(
                    _("station-comms", "What about their repair parts?"),
                    function()
                        setCommsMessage(
                            _(
                                "station-comms",
                                "You must prioritize and choose your next destination. If they get destroyed, there won't be any engine to repair. Also, their destruction could adversely impact our ongoing diplomatic negotiations with the Arlenians"
                            )
                        )
                        comms_source.assist_freighter_attack_warning = "sent"
                    end
                )
            end
        elseif comms_source.research_message == "start" then
            setCommsMessage(
                string.format(
                    _(
                        "station-comms",
                        "Congratulations on completing your task to assist that Arlenian freighter, %s. Are you ready for your next task?"
                    ),
                    comms_source:getCallSign()
                )
            )
            addCommsReply(
                _("station-comms", "View assist freighter task evaluation"),
                assistFreighterTaskEvaluation
            )
            addCommsReply(
                _("station-comms", "We are ready for our fifth task"),
                function()
                    comms_source.research_message = "sent"
                    if comms_source.research_start_clock == nil then
                        comms_source.research_start_clock = getScenarioTime()
                    end
                    if crutch then
                        sendCrutch(comms_source, "research")
                    end
                    setCommsMessage(
                        string.format(
                            _(
                                "station-comms",
                                "We've observed several Kraylor appearing near the planetary bodies orbiting the black hole, %s. The energy signatures when they appear match the exit point from a wormhole. This implies a degree of control over wormhole physics by the Kraylor previously unsuspected. We think it relates to the planetary bodies orbiting %s. Get detailed readings on over half of the planetary bodies using probes or your ship. You or the probe must get within 1.8 units and remain there for %s seconds to gather the required data. To facilitate your research, we've added a warp drive to your ship. It's fast, but it still takes time to switch from impulse to warp and back. Use caution when you approach those planetary bodies. Your evaluation has begun. Clock %s"
                            ),
                            orbital_body_names["black hole"],
                            orbital_body_names["black hole"],
                            research_task_length,
                            colonTime(comms_source.research_start_clock)
                        )
                    )
                end
            )
    else
        handled = false
    end
    return handled
end

local function addDockingAuthorityDocked()
    addCommsReply(
        _("station-comms", "Check with docking port authority"),
        function()
            setCommsMessage(
                string.format(
                    _(
                        "station-comms",
                        "Greetings %s. I am your automated docking port authority message provider. Protocol dictates that you calibrate your shields to %s THz, your beam weapons to %s THz and that you power down your missile systems in order to dock or undock with %s.\n\nHave a nice day!"
                    ),
                    comms_source:getCallSign(),
                    comms_source.dock_shield_frequency * 20 + 400,
                    comms_source.dock_beam_frequency * 20 + 400,
                    comms_target:getCallSign()
                )
            )
            addCommsReply(_("Back"), commsStation)
        end
    )
end

local function addDockedTaskStatus()
    if comms_source.task == "scan" then
        reportOnScannedShips()
    end
    if comms_source.task == "assist freighter" then
        if comms_source.assist_freighter_contacted then
            if comms_source.assist_freighter_reported_damage == nil then
                reportFreighterEngineProblems()
            else
                if comms_source.home_station == comms_target then
                    addCommsReply(
                        string.format(
                            _("station-comms", "Get parts to repair %s"),
                            comms_source.assist_freighter:getCallSign()
                        ),
                        function()
                            setCommsMessage(
                                string.format(
                                    _(
                                        "station-comms",
                                        "We've loaded the parts aboard %s. Now all you need to do is get within 5 units of %s and you can deliver the parts so they can make repairs."
                                    ),
                                    comms_source:getCallSign(),
                                    comms_source.assist_freighter:getCallSign()
                                )
                            )
                            comms_source.assist_freighter_parts = "loaded"
                            comms_source.assist_freighter_parts_clock =
                                getScenarioTime()
                        end
                    )
                end
            end
        end
    end
end

local function addEvaluationsDocked()
    if comms_source.dock_task == "complete" then
        if comms_source.scan_task == "complete" then
            addCommsReply(_("station-comms", "View evaluations"), function()
                setCommsMessage(
                    _(
                        "station-comms",
                        "Which task evaluation would you like to view?"
                    )
                )
                addCommsReply(
                    _("station-comms", "View docking task evalutation"),
                    dockTaskEvaluation
                )
                addCommsReply(
                    _("station-comms", "View scanning task evalutation"),
                    scanTaskEvaluation
                )
                if comms_source.destroy_freighter_task == "complete" then
                    addCommsReply(
                        _(
                            "station-comms",
                            "View destroy freighter task evalutation"
                        ),
                        destroyFreighterTaskEvaluation
                    )
                end
                if comms_source.assist_freighter_task == "complete" then
                    addCommsReply(
                        _(
                            "station-comms",
                            "View assist freighter task evalutation"
                        ),
                        assistFreighterTaskEvaluation
                    )
                end
                if comms_source.research_task == "complete" then
                    addCommsReply(
                        _("station-comms", "View research task evalutation"),
                        researchTaskEvaluation
                    )
                    addCommsReply(
                        _("station-comms", "View bonus task evalutation"),
                        bonusTaskEvaluation
                    )
                    addCommsReply(
                        _("station-comms", "Posthumous evaluations"),
                        playerPosthumousEvaluations
                    )
                end
                addCommsReply(_("Back"), commsStation)
            end)
        else
            addCommsReply(
                _("station-comms", "View docking task evalutation"),
                dockTaskEvaluation
            )
        end
    end
end

local function addCurrentOrdersDocked()
    if comms_source:isFriendly(comms_target) then
        addCommsReply(
            _("orders-comms", "What are my current orders?"),
            function()
                setOptionalOrders()
                setSecondaryOrders()
                primary_orders = _("orders-comms", "Perform tasks as given")
                if comms_source.task == "dock" then
                    primary_orders = string.format(
                        _("orders-comms", "Dock with %s"),
                        comms_source.home_station:getCallSign()
                    )
                elseif comms_source.task == "scan" then
                    primary_orders = string.format(
                        _(
                            "orders-comms",
                            "Scan the targets. Report results to %s"
                        ),
                        comms_source.home_station:getCallSign()
                    )
                elseif comms_source.task == "destroy freighter" then
                    primary_orders = _(
                        "orders-comms",
                        "Destroy the Kraylor freighter or transport"
                    )
                elseif comms_source.task == "assist freighter" then
                    primary_orders =
                        _("orders-comms", "Assist the Arlenian freighter")
                elseif comms_source.task == "research" then
                    primary_orders =
                        _("orders-comms", "Gather data on orbiting bodies")
                end
                ordMsg = primary_orders
                    .. "\n"
                    .. secondary_orders
                    .. optional_orders
                if playWithTimeLimit then
                    ordMsg = ordMsg
                        .. string.format(
                            _("orders-comms", "\n   %i Minutes remain in game"),
                            math.floor(gameTimeLimit / 60)
                        )
                end
                setCommsMessage(ordMsg)
                addCommsReply(_("Back"), commsStation)
            end
        )
    end
end

function setSecondaryOrders()
    if func_diagnostic then
        print("set secondary orders")
    end
    secondary_orders = ""
    if comms_source.task == "assist freighter" then
        if comms_source.assist_freighter_contacted == nil then
            secondary_orders = string.format(
                _("orders-comms", "Contact %s in %s."),
                comms_source.assist_freighter:getCallSign(),
                comms_source.assist_freighter:getSectorName()
            )
        else
            if comms_source.assist_freighter:isFullyScannedBy(comms_source) then
                if comms_source.assist_freighter_reported_damage == nil then
                    secondary_orders = string.format(
                        _(
                            "orders-comms",
                            "Report details of Arlenian freighter %s engine damage to %s."
                        ),
                        comms_source.assist_freighter:getCallSign(),
                        comms_source.home_station:getCallSign()
                    )
                else
                    if comms_source.assist_freighter_parts == "loaded" then
                        secondary_orders = string.format(
                            _(
                                "orders-comms",
                                "Deliver parts to %s in %s by traveling to within 5 units of them and contacting them to deliver the parts."
                            ),
                            comms_source.assist_freighter:getCallSign(),
                            comms_source.assist_freighter:getSectorName()
                        )
                    else
                        secondary_orders = string.format(
                            _(
                                "orders-comms",
                                "Dock with %s and get parts for %s's engines."
                            ),
                            comms_source.home_station:getCallSign(),
                            comms_source.assist_freighter:getCallSign()
                        )
                    end
                end
            else
                secondary_orders = string.format(
                    _("orders-comms", "Deep scan %s in %s."),
                    comms_source.assist_freighter:getCallSign(),
                    comms_source.assist_freighter:getSectorName()
                )
            end
        end
    end
end
function setOptionalOrders()
    if func_diagnostic then
        print("set optional orders")
    end
    optional_orders = ""
    if comms_source.task == "assist freighter" then
        optional_orders = string.format(
            _("orders-comms", " Protect %s."),
            comms_source.assist_freighter:getCallSign()
        )
    end
end

local function addDockingAuthorityUndocked()
    addCommsReply(
        _("station-comms", "Check with docking port authority"),
        function()
            if comms_source.dock_call_port_authority_clock == nil then
                comms_source.dock_call_port_authority_clock = getScenarioTime()
            end
            setCommsMessage(
                string.format(
                    _(
                        "station-comms",
                        "Greetings %s. I am your automated docking port authority message provider. Protocol dictates that you calibrate your shields to %s THz, your beam weapons to %s THz and that you power down your missile systems in order to dock or undock with %s.\n\nHave a nice day!"
                    ),
                    comms_source:getCallSign(),
                    comms_source.dock_shield_frequency * 20 + 400,
                    comms_source.dock_beam_frequency * 20 + 400,
                    comms_target:getCallSign()
                )
            )
            addCommsReply(_("Back"), commsStation)
        end
    )
end

local function addUndockedTaskStatus()
    if comms_source.task == "scan" then
        reportOnScannedShips()
    end
    if comms_source.task == "assist freighter" then
        if comms_source.assist_freighter_contacted then
            if comms_source.assist_freighter_reported_damage == nil then
                reportFreighterEngineProblems()
            end
        end
    end
end

local function addEvaluationsUndocked()
        if comms_source.dock_task == "complete" then
            if comms_source.scan_task == "complete" then
                addCommsReply(_("station-comms", "View evaluations"), function()
                    setCommsMessage(
                        _(
                            "station-comms",
                            "Which task evaluation would you like to view?"
                        )
                    )
                    addCommsReply(
                        _("station-comms", "View docking task evalutation"),
                        dockTaskEvaluation
                    )
                    addCommsReply(
                        _("station-comms", "View scanning task evalutation"),
                        scanTaskEvaluation
                    )
                    if comms_source.destroy_freighter_task == "complete" then
                        addCommsReply(
                            _(
                                "station-comms",
                                "View destroy freighter task evalutation"
                            ),
                            destroyFreighterTaskEvaluation
                        )
                    end
                    if comms_source.assist_freighter_task == "complete" then
                        addCommsReply(
                            _(
                                "station-comms",
                                "View assist freighter task evalutation"
                            ),
                            assistFreighterTaskEvaluation
                        )
                    end
                    if comms_source.research_task == "complete" then
                        addCommsReply(
                            _("station-comms", "View research task evalutation"),
                            researchTaskEvaluation
                        )
                        addCommsReply(
                            _("station-comms", "View bonus task evalutation"),
                            bonusTaskEvaluation
                        )
                    end
                    addCommsReply(_("Back"), commsStation)
                end)
            else
                addCommsReply(
                    _("station-comms", "View docking task evalutation"),
                    dockTaskEvaluation
                )
            end
        end
end

local function addCurrentOrdersUndocked()
        if comms_target:isFriendly(comms_source) then
            addCommsReply(
                _("orders-comms", "What are my current orders?"),
                function()
                    setOptionalOrders()
                    setSecondaryOrders()
                    primary_orders = _("orders-comms", "Perform tasks as given")
                    if comms_source.task == "dock" then
                        primary_orders = string.format(
                            _("orders-comms", "Dock with %s"),
                            comms_source.home_station:getCallSign()
                        )
                    elseif comms_source.task == "scan" then
                        primary_orders = string.format(
                            _(
                                "orders-comms",
                                "Scan the targets. Report results to %s"
                            ),
                            comms_source.home_station:getCallSign()
                        )
                    elseif comms_source.task == "destroy freighter" then
                        primary_orders = _(
                            "orders-comms",
                            "Destroy the Kraylor freighter or transport"
                        )
                    elseif comms_source.task == "assist freighter" then
                        primary_orders =
                            _("orders-comms", "Assist the Arlenian freighter")
                    elseif comms_source.task == "research" then
                        primary_orders =
                            _("orders-comms", "Gather data on orbiting bodies")
                    end
                    ordMsg = primary_orders
                        .. "\n"
                        .. secondary_orders
                        .. optional_orders
                    if playWithTimeLimit then
                        ordMsg = ordMsg
                            .. string.format(
                                _(
                                    "orders-comms",
                                    "\n   %i Minutes remain in game"
                                ),
                                math.floor(gameTimeLimit / 60)
                            )
                    end
                    setCommsMessage(ordMsg)
                    addCommsReply(_("Back"), commsStation)
                end
            )
        end
end

local function addStationServices()
        addCommsReply(_("station-comms", "Station services"), function()
            local ordnanceListMsg = ""
            local missileTypeAvailableCount = 0
            if comms_target.comms_data.weapon_available.Nuke then
                missileTypeAvailableCount = missileTypeAvailableCount + 1
                ordnanceListMsg = ordnanceListMsg
                    .. _("ammo-comms", "\n   Nuke")
            end
            if comms_target.comms_data.weapon_available.EMP then
                missileTypeAvailableCount = missileTypeAvailableCount + 1
                ordnanceListMsg = ordnanceListMsg .. _("ammo-comms", "\n   EMP")
            end
            if comms_target.comms_data.weapon_available.Homing then
                missileTypeAvailableCount = missileTypeAvailableCount + 1
                ordnanceListMsg = ordnanceListMsg
                    .. _("ammo-comms", "\n   Homing")
            end
            if comms_target.comms_data.weapon_available.Mine then
                missileTypeAvailableCount = missileTypeAvailableCount + 1
                ordnanceListMsg = ordnanceListMsg
                    .. _("ammo-comms", "\n   Mine")
            end
            if comms_target.comms_data.weapon_available.HVLI then
                missileTypeAvailableCount = missileTypeAvailableCount + 1
                ordnanceListMsg = ordnanceListMsg
                    .. _("ammo-comms", "\n   HVLI")
            end
            if missileTypeAvailableCount == 0 then
                ordnanceListMsg =
                    _("ammo-comms", "We have no ordnance available for restock")
            elseif missileTypeAvailableCount == 1 then
                ordnanceListMsg = string.format(
                    _(
                        "ammo-comms",
                        "We have the following type of ordnance available for restock:%s"
                    ),
                    ordnanceListMsg
                )
            else
                ordnanceListMsg = string.format(
                    _(
                        "ammo-comms",
                        "We have the following types of ordnance available for restock:%s"
                    ),
                    ordnanceListMsg
                )
            end
            service_status = string.format(
                _(
                    "dockingServicesStatus-comms",
                    "%s\nStation primary docking services:"
                ),
                ordnanceListMsg
            )
            if comms_target:getRestocksScanProbes() then
                service_status = string.format(
                    _(
                        "dockingServicesStatus-comms",
                        "%s\nReplenish scan probes."
                    ),
                    service_status
                )
            else
                if comms_target.probe_fail_reason == nil then
                    local reason_list = {
                        _(
                            "dockingServicesStatus-comms",
                            "Cannot replenish scan probes due to fabrication unit failure."
                        ),
                        _(
                            "dockingServicesStatus-comms",
                            "Parts shortage prevents scan probe replenishment."
                        ),
                        _(
                            "dockingServicesStatus-comms",
                            "Station management has curtailed scan probe replenishment for cost cutting reasons."
                        ),
                    }
                    comms_target.probe_fail_reason =
                        reason_list[math.random(1, #reason_list)]
                end
                service_status = string.format(
                    "%s\n%s",
                    service_status,
                    comms_target.probe_fail_reason
                )
            end
            if comms_target:getRepairDocked() then
                service_status = string.format(
                    _("dockingServicesStatus-comms", "%s\nShip hull repair."),
                    service_status
                )
            else
                if comms_target.repair_fail_reason == nil then
                    reason_list = {
                        _(
                            "dockingServicesStatus-comms",
                            "We're out of the necessary materials and supplies for hull repair."
                        ),
                        _(
                            "dockingServicesStatus-comms",
                            "Hull repair automation unavailable whie it is undergoing maintenance."
                        ),
                        _(
                            "dockingServicesStatus-comms",
                            "All hull repair technicians quarantined to quarters due to illness."
                        ),
                    }
                    comms_target.repair_fail_reason =
                        reason_list[math.random(1, #reason_list)]
                end
                service_status = string.format(
                    "%s\n%s",
                    service_status,
                    comms_target.repair_fail_reason
                )
            end
            if comms_target:getSharesEnergyWithDocked() then
                service_status = string.format(
                    _(
                        "dockingServicesStatus-comms",
                        "%s\nRecharge ship energy stores."
                    ),
                    service_status
                )
            else
                if comms_target.energy_fail_reason == nil then
                    reason_list = {
                        _(
                            "dockingServicesStatus-comms",
                            "A recent reactor failure has put us on auxiliary power, so we cannot recharge ships."
                        ),
                        _(
                            "dockingServicesStatus-comms",
                            "A damaged power coupling makes it too dangerous to recharge ships."
                        ),
                        _(
                            "dockingServicesStatus-comms",
                            "An asteroid strike damaged our solar cells and we are short on power, so we can't recharge ships right now."
                        ),
                    }
                    comms_target.energy_fail_reason =
                        reason_list[math.random(1, #reason_list)]
                end
                service_status = string.format(
                    "%s\n%s",
                    service_status,
                    comms_target.energy_fail_reason
                )
            end
            setCommsMessage(service_status)
            addCommsReply(_("Back"), commsStation)
        end)
end

local function stationDocked()
    if handleHomeStationTask() then
        return true
    end
    StationMenu.docked(station_profile)
    return true
end

local function stationUndocked()
    if handleHomeStationTask() then
        return true
    end
    StationMenu.undocked(station_profile)
    return true
end

commsStation = StationMenu.entrypoint(function() return station_profile end)

station_profile = {
    main_menu = commsStation,
    data = {
        weapon_cost = {
            Homing = 2,
            HVLI = 2,
            Mine = 3,
            Nuke = 15,
            EMP = 10,
        },
        reputation_cost_multipliers = { neutral = 2.0 },
    },
    weapon_availability = {
        Nuke = 4,
        EMP = 5,
        Homing = 6,
        Mine = 7,
        HVLI = 9,
    },
    under_attack = function()
        return comms_target:areEnemiesInRange(5000)
            and comms_source.scan_task == "complete"
    end,
    resources = {
        prompt = false,
        recruitment = false,
        coolant = false,
        goods = false,
    },
    docked = {
        greeting = "fixed",
        show_reputation = false,
        before = function()
            addDockingAuthorityDocked()
            addDockedTaskStatus()
            addEvaluationsDocked()
        end,
        group_services = false,
        service_prompt = false,
        service_sections = {
            "ordnance",
            "repair",
            {
                kind = "docking_status",
                mode = "combined",
                status_repair_typo = true,
            },
        },
        ordnance = {
            always = true,
            back = true,
            label = _("station-comms", "Restock Ordnance"),
            order = { "Homing", "Nuke", "Mine", "EMP", "HVLI" },
        },
        after_services = addCurrentOrdersDocked,
        group_resources = false,
    },
    undocked = {
        before_information = function()
            addDockingAuthorityUndocked()
            addUndockedTaskStatus()
        end,
        information = {
            prompt = _("station-comms", "What kind of information do you need?"),
            sections = {
                { kind = "callback", callback = addEvaluationsUndocked },
                { kind = "callback", callback = addCurrentOrdersUndocked },
                { kind = "callback", callback = addStationServices },
                { kind = "gossip" },
            },
        },
    },
}

function reportOnScannedShips()
    if func_diagnostic then
        print("report on scanned ships")
    end
    if comms_source.home_station == comms_target then
        if comms_source.scan_targets ~= nil then
            local single_scan_count = 0
            local double_scan_count = 0
            for i, scan_target in ipairs(comms_source.scan_targets) do
                if scan_target.ship:isValid() then
                    if scan_target.ship:isScannedBy(comms_source) then
                        single_scan_count = single_scan_count + 1
                    end
                    if scan_target.ship:isFullyScannedBy(comms_source) then
                        double_scan_count = double_scan_count + 1
                    end
                else
                    if scan_target.single_scan_clock ~= nil then
                        single_scan_count = single_scan_count + 1
                    end
                    if scan_target.full_scan_clock ~= nil then
                        double_scan_count = double_scan_count + 1
                    end
                end
            end
            if single_scan_count > 0 then
                addCommsReply(
                    _("station-comms", "Report ship type on scanned ships"),
                    function()
                        local single_scan_reported_count = 0
                        local single_scan_reportable_count = 0
                        local out = ""
                        for i, scan_target in ipairs(comms_source.scan_targets) do
                            if scan_target.ship:isValid() then
                                if
                                    scan_target.ship:isScannedBy(comms_source)
                                then
                                    if scan_target.type_report_clock == nil then
                                        addCommsReply(
                                            string.format(
                                                _(
                                                    "station-comms",
                                                    "Report on %s"
                                                ),
                                                scan_target.name
                                            ),
                                            function()
                                                setCommsMessage(
                                                    string.format(
                                                        _(
                                                            "station-comms",
                                                            "What type of ship is %s?"
                                                        ),
                                                        scan_target.name
                                                    )
                                                )
                                                local scan_ship_types = {
                                                    _(
                                                        "station-comms",
                                                        "Personnel Freighter 5"
                                                    ),
                                                    _(
                                                        "station-comms",
                                                        "Goods Freighter 5"
                                                    ),
                                                    _(
                                                        "station-comms",
                                                        "Garbage Freighter 5"
                                                    ),
                                                    _(
                                                        "station-comms",
                                                        "Equipment Freighter 5"
                                                    ),
                                                    _(
                                                        "station-comms",
                                                        "Fuel Freighter 5"
                                                    ),
                                                    _(
                                                        "station-comms",
                                                        "Transport1x5"
                                                    ),
                                                    _(
                                                        "station-comms",
                                                        "Transport2x5"
                                                    ),
                                                    _(
                                                        "station-comms",
                                                        "Transport3x5"
                                                    ),
                                                    _(
                                                        "station-comms",
                                                        "Transport4x5"
                                                    ),
                                                    _(
                                                        "station-comms",
                                                        "Transport5x5"
                                                    ),
                                                }
                                                for i, ship_type in
                                                    ipairs(scan_ship_types)
                                                do
                                                    addCommsReply(
                                                        ship_type,
                                                        function()
                                                            scan_target.identified_type =
                                                                ship_type
                                                            scan_target.type_report_clock =
                                                                getScenarioTime()
                                                            setCommsMessage(
                                                                _(
                                                                    "station-comms",
                                                                    "Your report has been noted"
                                                                )
                                                            )
                                                            addCommsReply(
                                                                _("Back"),
                                                                commsStation
                                                            )
                                                        end
                                                    )
                                                end
                                                addCommsReply(
                                                    _("Back"),
                                                    commsStation
                                                )
                                            end
                                        )
                                        single_scan_reportable_count = single_scan_reportable_count
                                            + 1
                                    else --already reported
                                        single_scan_reported_count = single_scan_reported_count
                                            + 1
                                        if out == "" then
                                            out = _(
                                                "station-comms",
                                                "Review of ships already reported:"
                                            )
                                        end
                                        out = string.format(
                                            _(
                                                "station-comms",
                                                "%s\n%s reported as type %s"
                                            ),
                                            out,
                                            scan_target.name,
                                            scan_target.identified_type
                                        )
                                    end
                                end
                            else --ship not valid (destroyed)
                                if scan_target.type_report_clock ~= nil then
                                    single_scan_reported_count = single_scan_reported_count
                                        + 1
                                    if out == "" then
                                        out = _(
                                            "station-comms",
                                            "Review of ships already reported:"
                                        )
                                    end
                                    out = string.format(
                                        _(
                                            "station-comms",
                                            "%s\n%s reported as type %s"
                                        ),
                                        out,
                                        scan_target.name,
                                        scan_target.identified_type
                                    )
                                end
                            end
                        end --loop through scan targets
                        if single_scan_reportable_count > 0 then
                            if single_scan_reported_count > 0 then
                                out = string.format(
                                    _(
                                        "station-comms",
                                        "%s\n\nWhat ship do you want to report on?"
                                    ),
                                    out
                                )
                            else
                                out = _(
                                    "station-comms",
                                    "What ship do you want to report on?"
                                )
                            end
                        else
                            if single_scan_reported_count == 0 then
                                out = _("station-comms", "Nothing to report")
                            end
                        end
                        setCommsMessage(out)
                        addCommsReply(_("Back"), commsStation)
                    end
                )
            end
            if double_scan_count > 0 then
                addCommsReply(
                    _(
                        "station-comms",
                        "Report shield frequency on deep scanned ships"
                    ),
                    function()
                        local double_scan_reported_count = 0
                        local double_scan_reportable_count = 0
                        local out = ""
                        for i, scan_target in ipairs(comms_source.scan_targets) do
                            if scan_target.ship:isValid() then
                                if
                                    scan_target.ship:isFullyScannedBy(
                                        comms_source
                                    )
                                then
                                    if
                                        scan_target.frequency_report_clock
                                        == nil
                                    then
                                        addCommsReply(
                                            string.format(
                                                _(
                                                    "station-comms",
                                                    "Report on %s"
                                                ),
                                                scan_target.name
                                            ),
                                            function()
                                                setCommsMessage(
                                                    string.format(
                                                        _(
                                                            "station-comms",
                                                            "At what shield frequency does ship %s block the most beam damage?"
                                                        ),
                                                        scan_target.name
                                                    )
                                                )
                                                for j = 0, 20 do
                                                    addCommsReply(
                                                        string.format(
                                                            _(
                                                                "station-comms",
                                                                "%s THz"
                                                            ),
                                                            j * 20 + 400
                                                        ),
                                                        function()
                                                            scan_target.identified_frequency =
                                                                j
                                                            scan_target.frequency_report_clock =
                                                                getScenarioTime()
                                                            setCommsMessage(
                                                                _(
                                                                    "station-comms",
                                                                    "Your report has been noted"
                                                                )
                                                            )
                                                            addCommsReply(
                                                                _("Back"),
                                                                commsStation
                                                            )
                                                        end
                                                    )
                                                end
                                                addCommsReply(
                                                    _("Back"),
                                                    commsStation
                                                )
                                            end
                                        )
                                        double_scan_reportable_count = double_scan_reportable_count
                                            + 1
                                    else --already reported
                                        double_scan_reported_count = double_scan_reported_count
                                            + 1
                                        if out == "" then
                                            out = _(
                                                "station-comms",
                                                "Review of ships already reported:"
                                            )
                                        end
                                        out = string.format(
                                            _(
                                                "station-comms",
                                                "%s\nThe shield frequency of %s was reported the strongest at %s THz"
                                            ),
                                            out,
                                            scan_target.name,
                                            scan_target.identified_frequency
                                                    * 20
                                                + 400
                                        )
                                    end
                                end
                            else --ship not valid (destroyed)
                                if
                                    scan_target.frequency_report_clock ~= nil
                                then
                                    double_scan_reported_count = double_scan_reported_count
                                        + 1
                                    if out == "" then
                                        out = _(
                                            "station-comms",
                                            "Review of ships already reported:"
                                        )
                                    end
                                    out = string.format(
                                        _(
                                            "station-comms",
                                            "%s\nThe shield frequency of %s was reported the strongest at %s THz"
                                        ),
                                        out,
                                        scan_target.name,
                                        scan_target.identified_frequency * 20
                                            + 400
                                    )
                                end
                            end
                        end --loop through scan targets
                        if double_scan_reportable_count > 0 then
                            if double_scan_reported_count > 0 then
                                out = string.format(
                                    _(
                                        "station-comms",
                                        "%s\n\nWhat ship do you want to report on?"
                                    ),
                                    out
                                )
                            else
                                out = _(
                                    "station-comms",
                                    "What ship do you want to report on?"
                                )
                            end
                        else
                            if double_scan_reported_count == 0 then
                                out = _("station-comms", "Nothing to report")
                            end
                        end
                        setCommsMessage(out)
                        addCommsReply(_("Back"), commsStation)
                    end
                )
            end
        end
    end
end
function reportFreighterEngineProblems()
    if func_diagnostic then
        print("report freighter engine problems")
    end
    if comms_source.home_station == comms_target then
        addCommsReply(
            string.format(
                _("station-comms", "Provide %s engine damage details"),
                comms_source.assist_freighter:getCallSign()
            ),
            function()
                setCommsMessage(
                    string.format(
                        _(
                            "station-comms",
                            "What is the damage level of the impulse engines on %s? Select the value that is the closest."
                        ),
                        comms_source.assist_freighter:getCallSign()
                    )
                )
                for i = -25, -75, -5 do
                    addCommsReply(string.format("%i%%", i), function()
                        comms_source.assist_freighter_reported_damage = i
                        comms_source.assist_freighter_reported_damage_clock =
                            getScenarioTime()
                        setCommsMessage(
                            string.format(
                                _(
                                    "station-comms",
                                    "We've got repair parts for that kind of engine damage. Dock with us to pick up the parts. Then you can take the parts to %s. Travel to within 5 units of %s to deliver the parts"
                                ),
                                comms_source.assist_freighter:getCallSign(),
                                comms_source.assist_freighter:getCallSign()
                            )
                        )
                    end)
                end
                addCommsReply(_("Back"), commsStation)
            end
        )
        addCommsReply(
            _("station-comms", "How do we get engine damage details?"),
            function()
                setCommsMessage(
                    string.format(
                        _(
                            "station-comms",
                            "To get engine damage details on %s, you need to deep scan it. After completing the second scan, click on 'Tactical' and select 'Systems' to see all the ship's systems and the degree of functioning or damage. Anything less than 100%% is functional but damaged. Negative numbers indicate a non-functioning system."
                        ),
                        comms_source.assist_freighter:getCallSign()
                    )
                )
                addCommsReply(_("Back"), commsStation)
            end
        )
    end
end
------------------------------------------------------------------
-- Task evaluations. Used by GM and via station communication    --
------------------------------------------------------------------
function colonTime(time)
    if func_diagnostic then
        print("colon time")
    end
    if time > 60 then
        local minutes = time / 60
        if minutes > 60 then
            local hours = math.floor(time / 3600)
            local minutes = math.floor((time - (hours * 3600)) / 60)
            local seconds = math.floor(time - (hours * 3600) - (minutes * 60))
            return string.format("%s:%02d:%02d", hours, minutes, seconds)
        end
        minutes = math.floor(time / 60)
        local seconds = math.floor(time - (minutes * 60))
        return string.format("%s:%02d", minutes, seconds)
    end
    return math.floor(time)
end
-- First Task: Dock
-- Hurdles: request permission to dock, calibrate shields and beams, power down missiles
-- Participants: Helm, weapons, relay, engineering
function dockTaskEvaluation()
    if func_diagnostic then
        print("dock task evaluation")
    end
    local out = dockTaskEvaluationOutput(comms_source)
    out = string.format(
        _(
            "evaluation-comms",
            "We only have objective evaluation data. Subjective evaluation must come from a different source. The entire crew contributes to the success of a task. Certain members are measured on part of the task.\n----- First Task: Dock -----\n%s"
        ),
        out
    )
    setCommsMessage(out)
    addCommsReply(_("Back"), commsStation)
end
function dockTaskEvaluationOutput(p, gm)
    if func_diagnostic then
        print("dock task evaluation output")
    end
    -- S = Superior, E = Exceeds expectations, C = Competent, N = Needs improvement
    if player_insight then
        gm = "gm"
    end
    local gm_grades = {
        ["overall"] = { superior = 40, exceed = 60, competent = 120 },
        ["protocol"] = { superior = 10, exceed = 20, competent = 40 },
        ["beam"] = { superior = 10, exceed = 20, competent = 40 },
        ["shield"] = { superior = 10, exceed = 20, competent = 40 },
        ["missile"] = { superior = 15, exceed = 30, competent = 60 },
        ["speed"] = { superior = 16.199, exceed = 10, competent = 5.4 },
    }
    local grade_total = 0
    local overall = _("evaluation-comms", "N")
    local overall_speed = p.dock_end_clock - p.dock_start_clock
    local grade = gm_grades["overall"]
    if overall_speed < grade.superior then
        overall = _("evaluation-comms", "S")
        grade_total = grade_total + 3
    elseif overall_speed < grade.exceed then
        overall = _("evaluation-comms", "E")
        grade_total = grade_total + 2
    elseif overall_speed < grade.competent then
        overall = _("evaluation-comms", "C")
        grade_total = grade_total + 1
    end
    local out = string.format(
        _("evaluation-comms", "Overall time to complete the task: %s"),
        colonTime(overall_speed)
    )
    if gm == "gm" then
        out = string.format("%s %s", out, overall)
    end
    local relay_time = p.dock_call_port_authority_clock - p.dock_start_clock
    local relay = _("evaluation-comms", "N")
    grade = gm_grades["protocol"]
    if relay_time < grade.superior then
        relay = _("evaluation-comms", "S")
        grade_total = grade_total + 3
    elseif relay_time < grade.exceed then
        relay = _("evaluation-comms", "E")
        grade_total = grade_total + 2
    elseif relay_time < grade.competent then
        relay = _("evaluation-comms", "C")
        grade_total = grade_total + 1
    end
    out = string.format(
        _(
            "evaluation-comms",
            "%s\nRelay time taken to request dock protocol: %s"
        ),
        out,
        colonTime(relay_time)
    )
    if gm == "gm" then
        out = string.format("%s %s", out, relay)
    end
    local beam = _("evaluation-comms", "N")
    local beam_speed = p.dock_set_beam_clock - p.dock_start_clock - relay_time
    grade = gm_grades["beam"]
    if beam_speed < grade.superior then
        beam = _("evaluation-comms", "S")
        grade_total = grade_total + 3
    elseif beam_speed < grade.exceed then
        beam = _("evaluation-comms", "E")
        grade_total = grade_total + 2
    elseif beam_speed < grade.competent then
        beam = _("evaluation-comms", "C")
        grade_total = grade_total + 1
    end
    out = string.format(
        _("evaluation-comms", "%s\nWeapons time taken to calibrate beams: %s"),
        out,
        colonTime(beam_speed)
    )
    if gm == "gm" then
        out = string.format("%s %s", out, beam)
    end
    local shield = _("evaluation-comms", "N")
    local shield_speed = p.dock_set_shield_clock
        - p.dock_start_clock
        - relay_time
    grade = gm_grades["shield"]
    if shield_speed < grade.superior then
        shield = _("evaluation-comms", "S")
        grade_total = grade_total + 3
    elseif shield_speed < grade.exceed then
        shield = _("evaluation-comms", "E")
        grade_total = grade_total + 2
    elseif shield_speed < grade.competent then
        shield = _("evaluation-comms", "C")
        grade_total = grade_total + 1
    end
    out = string.format(
        _("evaluation-comms", "%s\nWeapons time taken to calibrate shields: %s"),
        out,
        colonTime(shield_speed)
    )
    if gm == "gm" then
        out = string.format("%s %s", out, shield)
    end
    local missile = _("evaluation-comms", "N")
    local missile_time = p.dock_engineer_missile_zero_clock
        - p.dock_start_clock
        - relay_time
    if missile_time < 0 then
        missile_time = p.dock_engineer_missile_zero_clock - p.dock_start_clock
    end
    grade = gm_grades["missile"]
    if missile_time < grade.superior then
        missile = _("evaluation-comms", "S")
        grade_total = grade_total + 3
    elseif missile_time < grade.exceed then
        missile = _("evaluation-comms", "E")
        grade_total = grade_total + 2
    elseif missile_time < grade.competent then
        missile = _("evaluation-comms", "C")
        grade_total = grade_total + 1
    end
    out = string.format(
        _(
            "evaluation-comms",
            "%s\nEngineering time taken to power down missile system: %s"
        ),
        out,
        colonTime(missile_time)
    )
    if gm == "gm" then
        out = string.format("%s %s", out, missile)
    end
    local speed = _("evaluation-comms", "N")
    grade = gm_grades["speed"]
    if p.dock_max_velocity >= grade.superior then
        speed = _("evaluation-comms", "S")
        grade_total = grade_total + 3
    elseif p.dock_max_velocity >= grade.exceed then
        speed = _("evaluation-comms", "E")
        grade_total = grade_total + 2
    elseif p.dock_max_velocity >= grade.competent then
        speed = _("evaluation-comms", "C")
        grade_total = grade_total + 1
    end
    out = string.format(
        _(
            "evaluation-comms",
            "%s\nHelm/Engineering maximum velocity reached: %.1f units per minute"
        ),
        out,
        p.dock_max_velocity
    )
    if gm == "gm" then
        out = string.format("%s %s", out, speed)
    end
    local final_grade = _("evaluation-comms", "Needs improvement")
    if grade_total >= 18 then
        final_grade = _("evaluation-comms", "Perfect")
    elseif grade_total >= 15 then
        final_grade = _("evaluation-comms", "Superior")
    elseif grade_total >= 11 then
        final_grade = _("evaluation-comms", "Exceeds expectations")
    elseif grade_total >= 6 then
        final_grade = _("evaluation-comms", "Competent")
    end
    if gm == "gm" then
        out = string.format(
            _(
                "evaluation-comms",
                "%s\n\nWith a score of %i points out of 18, the system gives a rating of %s"
            ),
            out,
            grade_total,
            final_grade
        )
        out = string.format(
            _(
                "evaluation-comms",
                "%s\n\nFor each subtask, the single letter evaluations are:\n    N = Needs improvement\n    C = Competent\n    E = Exceeds expectations\n    S = Superior"
            ),
            out
        )
    end
    return out
end
-- Second Task: Scan to discriminate targets
-- Hurdles: nebula obscures some targets
-- Participants: Science, relay
function scanTaskEvaluation()
    if func_diagnostic then
        print("scan task evaluation")
    end
    local out = scanTaskEvaluationOutput(comms_source)
    out = string.format(
        _(
            "evaluation-comms",
            "We only have objective evaluation data. Subjective evaluation must come from a different source. The entire crew contributes to the success of a task. Certain members are measured on part of the task.\n----- Second Task: Scan -----\n%s"
        ),
        out
    )
    setCommsMessage(out)
    addCommsReply(_("Back"), commsStation)
end
function scanTaskEvaluationOutput(p, gm)
    if func_diagnostic then
        print("scan task evaluation output")
    end
    if player_insight then
        gm = "gm"
    end
    local gm_grades = {
        ["overall"] = { superior = 200, exceed = 300, competent = 450 },
        ["interval"] = { superior = 15, exceed = 20, competent = 35 },
    }
    local timeline = {}
    local evaluation_score = 0
    local overall_time = p.scan_end_clock - p.scan_start_clock
    local gm_grade = gm_grades["overall"]
    local overall = _("evaluation-comms", "Needs improvement")
    if overall_time < gm_grade.superior then
        overall = _("evaluation-comms", "Superior")
        evaluation_score = evaluation_score + 6
    elseif overall_time < gm_grade.exceed then
        overall = _("evaluation-comms", "Exceeds expectations")
        evaluation_score = evaluation_score + 4
    elseif overall_time < gm_grade.competent then
        overall = _("evaluation-comms", "Competent")
        evaluation_score = evaluation_score + 2
    end
    local out = string.format(
        _("evaluation-comms", "Overall time to complete the task: %s"),
        colonTime(overall_time)
    )
    if gm == "gm" then
        out = string.format("%s %s", out, overall)
    end
    out = string.format(
        _(
            "evaluation-comms",
            "%s\nReport line per scan ship: faction name: SS = Simple Scan time in seconds, DS = Deep Scan time in seconds, RT = Reported Type time in seconds (yes/no), RF = Reported Frequency time in seconds (yes/no)"
        ),
        out
    )
    local task_time = nil
    for i, scan_target in ipairs(p.scan_targets) do
        local ss = "--"
        task_time = scan_target.single_scan_clock - p.scan_start_clock
        if scan_target.single_scan_clock ~= nil then
            ss = string.format("%.1f", task_time)
            table.insert(timeline, task_time)
        else
            table.insert(timeline, 9999)
        end
        local ds = "--"
        task_time = scan_target.full_scan_clock - p.scan_start_clock
        if scan_target.full_scan_clock ~= nil then
            ds = string.format("%.1f", task_time)
            table.insert(timeline, task_time)
        else
            table.insert(timeline, 9999)
        end
        local rt = "--"
        task_time = scan_target.type_report_clock - p.scan_start_clock
        if scan_target.type_report_clock ~= nil then
            rt = string.format("%.1f", task_time)
            table.insert(timeline, task_time)
        else
            table.insert(timeline, 9999)
        end
        local rta = _("evaluation-comms", "(no)")
        --note: scan_target is not a class, it just happens to have a typeName entry
        if scan_target.typeName == scan_target.identified_type then
            rta = _("evaluation-comms", "(yes)")
            evaluation_score = evaluation_score + 2
        end
        local rf = "--"
        task_time = scan_target.frequency_report_clock - p.scan_start_clock
        if scan_target.frequency_report_clock ~= nil then
            rf = string.format("%.1f", task_time)
            table.insert(timeline, task_time)
        else
            table.insert(timeline, 9999)
        end
        local rfa = _("evaluation-comms", "(no)")
        if scan_target.shield_frequency == scan_target.identified_frequency then
            rfa = _("evaluation-comms", "(yes)")
            evaluation_score = evaluation_score + 2
        end
        out = string.format(
            _("evaluation-comms", "%s\n%s %s: SS:%s, DS:%s, RT:%s %s, RF:%s %s"),
            out,
            scan_target.faction,
            scan_target.name,
            ss,
            ds,
            rt,
            rta,
            rf,
            rfa
        )
    end
    table.sort(timeline)
    gm_grade = gm_grades["interval"]
    for i, clock in ipairs(timeline) do
        if clock < gm_grade.superior * i then
            evaluation_score = evaluation_score + 3
        elseif clock < gm_grade.exceed * i then
            evaluation_score = evaluation_score + 2
        elseif clock < gm_grade.competent * i then
            evaluation_score = evaluation_score + 1
        end
    end
    local final_grade = _("evaluation-comms", "Needs improvement")
    if evaluation_score >= 54 then
        final_grade = _("evaluation-comms", "Perfect")
    elseif evaluation_score >= 42 then
        final_grade = _("evaluation-comms", "Superior")
    elseif evaluation_score >= 31 then
        final_grade = _("evaluation-comms", "Exceeds expectations")
    elseif evaluation_score >= 21 then
        final_grade = _("evaluation-comms", "Competent")
    end
    if gm == "gm" then
        out = string.format(
            _(
                "evaluation-comms",
                "%s\n\nWith a score of %i points out of 54, the system gives a rating of %s"
            ),
            out,
            evaluation_score,
            final_grade
        )
        out = string.format(
            _(
                "evaluation-comms",
                "%s\n\nFor each subtask, the single letter evaluations are:\n    N = Needs improvement\n    C = Competent\n    E = Exceeds expectations\n    S = Superior"
            ),
            out
        )
    end
    return out
end
-- Third Task: Destroy enemy freighter
-- Hurdles: Limited beam function, only HVLI type missiles
-- Participants: Helm, Weapons, engineering, science, relay
function destroyFreighterTaskEvaluation()
    if func_diagnostic then
        print("destroy freighter task evaluation")
    end
    local out = destroyFreighterTaskEvaluationOutput(comms_source)
    out = string.format(
        _(
            "evaluation-comms",
            "We only have objective evaluation data. Subjective evaluation must come from a different source. The entire crew contributes to the success of a task. Certain members are measured on part of the task.\n----- Third Task: Destroy Freighter -----\n%s"
        ),
        out
    )
    setCommsMessage(out)
    addCommsReply(_("Back"), commsStation)
end
function destroyFreighterTaskEvaluationOutput(p, gm)
    if func_diagnostic then
        print("destroy freighter task evaluation output")
    end
    if player_insight then
        gm = "gm"
    end
    local gm_grades = {
        ["overall"] = { superior = 100, exceed = 200, competent = 350 },
        ["magazine"] = { superior = 16, exceed = 14, competent = 10 },
    }
    local evaluation_score = 0
    local overall_time = p.destroy_freighter_end_clock
        - p.destroy_freighter_start_clock
    local gm_grade = gm_grades["overall"]
    local overall = _("evaluation-comms", "Needs improvement")
    if overall_time < gm_grade.superior then
        overall = _("evaluation-comms", "Superior")
        evaluation_score = evaluation_score + 3
    elseif overall_time < gm_grade.exceed then
        overall = _("evaluation-comms", "Exceeds expectations")
        evaluation_score = evaluation_score + 2
    elseif overall_time < gm_grade.competent then
        overall = _("evaluation-comms", "Competent")
        evaluation_score = evaluation_score + 1
    end
    local out = string.format(
        _("evaluation-comms", "Overall time to complete the task: %s"),
        colonTime(overall_time)
    )
    if gm == "gm" then
        out = string.format("%s %s", out, overall)
    end
    out = string.format(
        _("evaluation-comms", "%s\nHelm/Weapons HVLI in storage: %i"),
        out,
        p.destroy_freighter_remaining_HVLI
    )
    gm_grade = gm_grades["magazine"]
    local magazine = _("evaluation-comms", "Needs improvement")
    if p.destroy_freighter_remaining_HVLI >= gm_grade.superior then
        magazine = _("evaluation-comms", "Superior")
        evaluation_score = evaluation_score + 3
    elseif p.destroy_freighter_remaining_HVLI >= gm_grade.exceed then
        magazine = _("evaluation-comms", "Exceeds expectations")
        evaluation_score = evaluation_score + 2
    elseif p.destroy_freighter_remaining_HVLI >= gm_grade.competent then
        magazine = _("evaluation-comms", "Competent")
        evaluation_score = evaluation_score + 1
    end
    if gm == "gm" then
        out = string.format("%s %s", out, magazine)
    end
    local final_grade = _("evaluation-comms", "Needs improvement")
    if evaluation_score >= 6 then
        final_grade = _("evaluation-comms", "Perfect")
    elseif evaluation_score >= 5 then
        final_grade = _("evaluation-comms", "Superior")
    elseif evaluation_score >= 4 then
        final_grade = _("evaluation-comms", "Exceeds expectations")
    elseif evaluation_score >= 2 then
        final_grade = _("evaluation-comms", "Competent")
    end
    if gm == "gm" then
        out = string.format(
            _(
                "evaluation-comms",
                "%s\n\nWith a score of %i points out of 6, the system gives a rating of %s"
            ),
            out,
            evaluation_score,
            final_grade
        )
        out = string.format(
            _(
                "evaluation-comms",
                "%s\n\nFor each subtask, the single letter evaluations are:\n    N = Needs improvement\n    C = Competent\n    E = Exceeds expectations\n    S = Superior"
            ),
            out
        )
    end
    return out
end
-- Fourth Task: Assist freighter
-- Hurdles: Get parts from station, find freighter, fend off attackers
-- Participants: Helm, science, relay, engineering, weapons
function assistFreighterTaskEvaluation()
    if func_diagnostic then
        print("assist freighter task evaluation")
    end
    local out = assistFreighterTaskEvaluationOutput(comms_source)
    out = string.format(
        _(
            "evaluation-comms",
            "We only have objective evaluation data. Subjective evaluation must come from a different source. The entire crew contributes to the success of a task. Certain members are measured on part of the task.\n----- Fourth Task: Assist Freighter -----\n%s"
        ),
        out
    )
    setCommsMessage(out)
    addCommsReply(_("Back"), commsStation)
end
function assistFreighterTaskEvaluationOutput(p, gm)
    if func_diagnostic then
        print("assist freighter task evaluation output")
    end
    if player_insight then
        gm = "gm"
    end
    local gm_grades = {
        ["overall"] = { superior = 500, exceed = 700, competent = 900 },
        ["contact"] = { superior = 70, exceed = 100, competent = 140 },
        ["report"] = { superior = 50, exceed = 100, competent = 200 },
        ["obtain"] = { superior = 80, exceed = 160, competent = 300 },
        ["deliver"] = { superior = 180, exceed = 250, competent = 320 },
        ["scan"] = { superior = 90, exceed = 100, competent = 120 },
        ["deepscan"] = { superior = 15, exceed = 30, competent = 50 },
        ["interval"] = { superior = 30, exceed = 50, competent = 90 },
    }
    local overall_time = p.assist_freighter_end_clock
        - p.assist_freighter_start_clock
    local gm_grade = gm_grades["overall"]
    local overall = _("evaluation-comms", "N")
    local evaluation_score = 0
    if overall_time < gm_grade.superior then
        overall = _("evaluation-comms", "S")
        evaluation_score = evaluation_score + 3
    elseif overall_time < gm_grade.exceed then
        overall = _("evaluation-comms", "E")
        evaluation_score = evaluation_score + 2
    elseif overall_time < gm_grade.competent then
        overall = _("evaluation-comms", "C")
        evaluation_score = evaluation_score + 1
    end
    local out = string.format(
        _("evaluation-comms", "Overall time to complete the task: %s"),
        colonTime(overall_time)
    )
    if gm == "gm" then
        out = string.format("%s %s", out, overall)
    end
    local freighter_name = _("evaluation-comms", "Arlenian freighter")
    local scan_time = 9999
    if p.assist_freighter:isValid() then
        freighter_name = p.assist_freighter:getCallSign()
    end
    local contacted = _("evaluation-comms", "N")
    local contact_time = 0
    if p.assist_freighter_contacted_clock ~= nil then
        contact_time = p.assist_freighter_contacted_clock
            - p.assist_freighter_start_clock
        gm_grade = gm_grades["contact"]
        if contact_time < gm_grade.superior then
            contacted = _("evaluation-comms", "S")
            evaluation_score = evaluation_score + 3
        elseif contact_time < gm_grade.exceed then
            contacted = _("evaluation-comms", "E")
            evaluation_score = evaluation_score + 2
        elseif contact_time < gm_grade.competent then
            contacted = _("evaluation-comms", "C")
            evaluation_score = evaluation_score + 1
        end
        out = string.format(
            _("evaluation-comms", "%s\nRelay time taken to contact %s: %s"),
            out,
            freighter_name,
            colonTime(contact_time)
        )
        if gm == "gm" then
            out = string.format("%s %s", out, contacted)
        end
    else
        out = string.format(
            _("evaluation-comms", "%s\nFailed to contact Arlenian freighter"),
            out
        )
        if gm == "gm" then
            out = string.format(_("evaluation-comms", "%s N"), out)
        end
    end
    local report = _("evaluation-comms", "N")
    local report_damage_time = 0
    if p.assist_freighter_reported_damage_clock ~= nil then
        report_damage_time = p.assist_freighter_reported_damage_clock
            - p.assist_freighter_start_clock
            - contact_time
        gm_grade = gm_grades["report"]
        if report_damage_time < gm_grade.superior then
            report = _("evaluation-comms", "S")
            evaluation_score = evaluation_score + 3
        elseif report_damage_time < gm_grade.exceed then
            report = _("evaluation-comms", "E")
            evaluation_score = evaluation_score + 2
        elseif report_damage_time < gm_grade.competent then
            report = _("evaluation-comms", "C")
            evaluation_score = evaluation_score + 1
        end
        out = string.format(
            _(
                "evaluation-comms",
                "%s\nRelay time taken to report damage to %s's engines: %s"
            ),
            out,
            freighter_name,
            colonTime(report_damage_time)
        )
        if gm == "gm" then
            out = string.format("%s %s", out, report)
        end
    else
        out = string.format(
            _(
                "evaluation-comms",
                "%s\nFailed to report damage to Arlenian freighter"
            ),
            out
        )
        if gm == "gm" then
            out = string.format(_("evaluation-comms", "%s N"), out)
        end
    end
    local obtain = _("evaluation-comms", "N")
    local get_parts_time = 0
    if p.assist_freighter_parts_clock ~= nil then
        get_parts_time = p.assist_freighter_parts_clock
            - p.assist_freighter_start_clock
            - report_damage_time
        gm_grade = gm_grades["obtain"]
        if get_parts_time < gm_grade.superior then
            obtain = _("evaluation-comms", "S")
            evaluation_score = evaluation_score + 3
        elseif get_parts_time < gm_grade.exceed then
            obtain = _("evaluation-comms", "E")
            evaluation_score = evaluation_score + 2
        elseif get_parts_time < gm_grade.competent then
            obtain = _("evaluation-comms", "C")
            evaluation_score = evaluation_score + 1
        end
        out = string.format(
            _("evaluation-comms", "%s\nHelm/Relay time taken to get parts: %s"),
            out,
            colonTime(get_parts_time)
        )
        if gm == "gm" then
            out = string.format("%s %s", out, obtain)
        end
    else
        out = string.format(
            _(
                "evaluation-comms",
                "%s\nFailed to get parts for Arlenian freighter"
            ),
            out
        )
        if gm == "gm" then
            out = string.format(_("evaluation-comms", "%s N"), out)
        end
    end
    local deliver = _("evaluation-comms", "N")
    if p.assist_freighter_fixed_clock ~= nil then
        local engine_repair_time = p.assist_freighter_fixed_clock
            - p.assist_freighter_start_clock
            - get_parts_time
        gm_grade = gm_grades["deliver"]
        if engine_repair_time < gm_grade.superior then
            deliver = _("evaluation-comms", "S")
            evaluation_score = evaluation_score + 3
        elseif engine_repair_time < gm_grade.exceed then
            deliver = _("evaluation-comms", "E")
            evaluation_score = evaluation_score + 2
        elseif engine_repair_time < gm_grade.competent then
            deliver = _("evaluation-comms", "C")
            evaluation_score = evaluation_score + 1
        end
        out = string.format(
            _(
                "evaluation-comms",
                "%s\nHelm/Relay time taken to provide parts for %s: %s"
            ),
            out,
            freighter_name,
            colonTime(engine_repair_time)
        )
        if gm == "gm" then
            out = string.format("%s %s", out, deliver)
        end
    else
        out = string.format(
            _(
                "evaluation-comms",
                "%s\nFailed to provide parts to Arlenian freighter"
            ),
            out
        )
        if gm == "gm" then
            out = string.format(_("evaluation-comms", "%s N"), out)
        end
    end
    local scan = _("evaluation-comms", "N")
    if p.assist_freighter_scanned_clock ~= nil then
        scan_time = p.assist_freighter_scanned_clock
            - p.assist_freighter_start_clock
        gm_grade = gm_grades["scan"]
        if scan_time < gm_grade.superior then
            scan = _("evaluation-comms", "S")
            evaluation_score = evaluation_score + 3
        elseif scan_time < gm_grade.exceed then
            scan = _("evaluation-comms", "E")
            evaluation_score = evaluation_score + 2
        elseif scan_time < gm_grade.competent then
            scan = _("evaluation-comms", "C")
            evaluation_score = evaluation_score + 1
        end
        out = string.format(
            _("evaluation-comms", "%s\nScience time taken to scan %s: %s"),
            out,
            freighter_name,
            colonTime(scan_time)
        )
        if gm == "gm" then
            out = string.format("%s %s", out, scan)
        end
    else
        out = string.format(
            _("evaluation-comms", "%s\nFailed to scan Arlenian freighter"),
            out
        )
        if gm == "gm" then
            out = string.format(_("evaluation-comms", "%s N"), out)
        end
    end
    local deepscan = _("evaluation-comms", "N")
    if p.assist_freighter_fully_scanned_clock ~= nil then
        local fully_scanned_time = p.assist_freighter_fully_scanned_clock
            - p.assist_freighter_start_clock
            - scan_time
        gm_grade = gm_grades["deepscan"]
        if fully_scanned_time < gm_grade.superior then
            deepscan = _("evaluation-comms", "S")
            evaluation_score = evaluation_score + 3
        elseif fully_scanned_time < gm_grade.exceed then
            deepscan = _("evaluation-comms", "E")
            evaluation_score = evaluation_score + 2
        elseif fully_scanned_time < gm_grade.competent then
            deepscan = _("evaluation-comms", "C")
            evaluation_score = evaluation_score + 1
        end
        out = string.format(
            _("evaluation-comms", "%s\nScience time taken to fully scan %s: %s"),
            out,
            freighter_name,
            colonTime(fully_scanned_time)
        )
        if gm == "gm" then
            out = string.format("%s %s", out, deepscan)
        end
    else
        out = string.format(
            _("evaluation-comms", "%s\nFailed to deep scan Arlenian freighter"),
            out
        )
        if gm == "gm" then
            out = string.format(_("evaluation-comms", "%s N"), out)
        end
    end
    out = string.format(
        _(
            "evaluation-comms",
            "%s\nWeapons/Helm/Engineering time to destroy each marauder in seconds:\n"
        ),
        out
    )
    local timeline = {}
    for i, m in ipairs(p.assist_freighter_marauders) do
        table.insert(
            timeline,
            m.destroyed_clock - p.assist_freighter_start_clock
        )
    end
    table.sort(timeline)
    gm_grade = gm_grades["interval"]
    local intervals = {}
    for i = 1, #timeline - 1 do
        table.insert(intervals, timeline[i + 1] - timeline[i])
    end
    local interval_grade = 0
    for i, clock in ipairs(intervals) do
        if i < #timeline then
            if clock < gm_grade.superior then
                evaluation_score = evaluation_score + 3
                interval_grade = interval_grade + 3
            elseif clock < gm_grade.exceed then
                evaluation_score = evaluation_score + 2
                interval_grade = interval_grade + 2
            elseif clock < gm_grade.competent then
                evaluation_score = evaluation_score + 1
                interval_grade = interval_grade + 1
            end
        end
    end
    local interval = _("evaluation-comms", "N")
    if interval_grade >= 11 then
        interval = _("evaluation-comms", "S")
    elseif interval_grade >= 8 then
        interval = _("evaluation-comms", "E")
    elseif interval_grade >= 4 then
        interval = _("evaluation-comms", "C")
    end
    for i, m in ipairs(p.assist_freighter_marauders) do
        local kill_time = m.destroyed_clock - p.assist_freighter_start_clock
        out = string.format("%s%s    ", out, colonTime(kill_time))
    end
    if gm == "gm" then
        out = string.format("%s %s", out, interval)
    end
    if p.assist_freighter:isValid() then
        if p.assist_freighter_fixed_clock ~= nil then
            out = string.format(
                _("evaluation-comms", "%s\nTask status: complete"),
                out
            )
            evaluation_score = evaluation_score + 10
        end
    else
        if p.assist_freighter_fixed_clock ~= nil then
            out = string.format(
                _(
                    "evaluation-comms",
                    "%s\nTask status: failed (partial success in providing repair parts)"
                ),
                out
            )
            evaluation_score = evaluation_score + 5
        else
            out = string.format(
                _("evaluation-comms", "%s\nTask status: failed"),
                out
            )
        end
    end
    local final_grade = _("evaluation-comms", "Needs improvement")
    if evaluation_score >= 43 then
        final_grade = _("evaluation-comms", "Perfect")
    elseif evaluation_score >= 38 then
        final_grade = _("evaluation-comms", "Superior")
    elseif evaluation_score >= 31 then
        final_grade = _("evaluation-comms", "Exceeds expectations")
    elseif evaluation_score >= 17 then
        final_grade = _("evaluation-comms", "Competent")
    end
    if gm == "gm" then
        out = string.format(
            _(
                "evaluation-comms",
                "%s\n\nWith a score of %i points out of 43, the system gives a rating of %s"
            ),
            out,
            evaluation_score,
            final_grade
        )
        out = string.format(
            _(
                "evaluation-comms",
                "%s\n\nFor each subtask, the single letter evaluations are:\n    N = Needs improvement\n    C = Competent\n    E = Exceeds expectations\n    S = Superior"
            ),
            out
        )
    end
    return out
end
-- Fifth task: Research anomalous planetary orbital behavior
-- Hurdles: Bumping into planets causes severe damage to ship, navigate carefully
-- Participants: Helm, Science, Relay, Engineering
function researchTaskEvaluation()
    if func_diagnostic then
        print("research task evaluation")
    end
    local out = researchTaskEvaluationOutput(comms_source)
    out = string.format(
        _(
            "evaluation-comms",
            "We only have objective evaluation data. Subjective evaluation must come from a different source. The entire crew contributes to the success of a task. Certain members are measured on part of the task.\n----- Fifth Task: Research -----\n%s"
        ),
        out
    )
    setCommsMessage(out)
    addCommsReply(_("Back"), commsStation)
end
function researchTaskEvaluationOutput(p, gm)
    if func_diagnostic then
        print("research task evaluation output")
    end
    if player_insight then
        gm = "gm"
    end
    local gm_grades = {
        { superior = 80, exceed = 120, competent = 160 },
        { superior = 120, exceed = 160, competent = 200 },
        { superior = 150, exceed = 190, competent = 230 },
        { superior = 200, exceed = 240, competent = 280 },
        { superior = 240, exceed = 280, competent = 320 },
        { superior = 280, exceed = 320, competent = 360 },
        { superior = 320, exceed = 360, competent = 400 },
        { superior = 360, exceed = 400, competent = 440 },
        { superior = 400, exceed = 440, competent = 480 },
        { superior = 440, exceed = 480, competent = 520 },
        { superior = 480, exceed = 520, competent = 560 },
        { superior = 520, exceed = 560, competent = 600 },
        { superior = 560, exceed = 600, competent = 640 },
        ["overall"] = { superior = 500, exceed = 600, competent = 700 },
        ["average"] = { superior = 250, exceed = 280, competent = 350 },
        ["median"] = { superior = 250, exceed = 280, competent = 350 },
    }
    local overall_time = p.research_end_clock - p.research_start_clock
    local gm_grade = gm_grades["overall"]
    local overall = _("evaluation-comms", "N")
    local evaluation_score = 0
    if overall_time < gm_grade.superior then
        overall = _("evaluation-comms", "S")
        evaluation_score = evaluation_score + 3
    elseif overall_time < gm_grade.exceed then
        overall = _("evaluation-comms", "E")
        evaluation_score = evaluation_score + 2
    elseif overall_time < gm_grade.competent then
        overall = _("evaluation-comms", "C")
        evaluation_score = evaluation_score + 1
    end
    local out = string.format(
        _("evaluation-comms", "Overall time to complete the task: %s"),
        colonTime(overall_time)
    )
    if gm == "gm" then
        out = string.format("%s %s", out, overall)
    end
    for i, orbit in ipairs(p.orbital_body_research) do
        if orbit.start_scan_clock == nil then
            orbit.start_scan_clock = 0
        end
    end
    table.sort(p.orbital_body_research, function(a, b)
        return a.start_scan_clock < b.start_scan_clock
            or (
                a.start_scan_clock == b.start_scan_clock
                and a.body:getCallSign() < b.body:getCallSign()
            )
    end)
    local total = 0
    local bodies_scanned = 0
    for i, orbit in ipairs(p.orbital_body_research) do
        if orbit.start_scan_clock ~= 0 and orbit.research == "Y" then
            bodies_scanned = bodies_scanned + 1
            local length = (orbit.start_scan_clock + research_task_length)
                - p.research_start_clock
            local length_grade = _("evaluation-comms", "N")
            gm_grade = gm_grades[i]
            if length < gm_grade.superior then
                length_grade = _("evaluation-comms", "S")
                evaluation_score = evaluation_score + 3
            elseif length < gm_grade.exceed then
                length_grade = _("evaluation-comms", "E")
                evaluation_score = evaluation_score + 2
            elseif length < gm_grade.competent then
                length_grade = _("evaluation-comms", "C")
                evaluation_score = evaluation_score + 1
            end
            total = total + length
            out = string.format(
                "%s\n%s %s",
                out,
                colonTime(length),
                orbit.body:getCallSign()
            )
            if gm == "gm" then
                out = string.format("%s %s", out, length_grade)
            end
        end
    end
    local average = total / bodies_scanned
    local average_grade = _("evaluation-comms", "N")
    gm_grade = gm_grades["average"]
    local average_grade = _("evaluation-comms", "N")
    if average < gm_grade.superior then
        average_grade = _("evaluation-comms", "S")
        evaluation_score = evaluation_score + 3
    elseif average < gm_grade.exceed then
        average_grade = _("evaluation-comms", "E")
        evaluation_score = evaluation_score + 2
    elseif average < gm_grade.competent then
        average_grade = _("evaluation-comms", "C")
        evaluation_score = evaluation_score + 1
    end
    local median = (
        p.orbital_body_research[7].start_scan_clock + research_task_length
    ) - p.research_start_clock
    local median_grade = _("evaluation-comms", "N")
    gm_grade = gm_grades["median"]
    if median < gm_grade.superior then
        median_grade = _("evaluation-comms", "S")
        evaluation_score = evaluation_score + 3
    elseif median < gm_grade.exceed then
        median_grade = _("evaluation-comms", "E")
        evaluation_score = evaluation_score + 2
    elseif median < gm_grade.competent then
        median_grade = _("evaluation-comms", "C")
        evaluation_score = evaluation_score + 1
    end
    if gm == "gm" then
        out = string.format(
            "%s\nAverage: %s %s    Median: %s %s",
            out,
            colonTime(average),
            average_grade,
            colonTime(median),
            median_grade
        )
    else
        out = string.format(
            "%s\nAverage: %s     Median: %s",
            out,
            colonTime(average),
            colonTime(median)
        )
    end
    local final_grade = _("evaluation-comms", "Needs improvement")
    if evaluation_score >= 48 then
        final_grade = _("evaluation-comms", "Perfect")
    elseif evaluation_score >= 40 then
        final_grade = _("evaluation-comms", "Superior")
    elseif evaluation_score >= 31 then
        final_grade = _("evaluation-comms", "Exceeds expectations")
    elseif evaluation_score >= 19 then
        final_grade = _("evaluation-comms", "Competent")
    end
    if gm == "gm" then
        out = string.format(
            _(
                "evaluation-comms",
                "%s\n\nWith a score of %i points out of 48, the system gives a rating of %s"
            ),
            out,
            evaluation_score,
            final_grade
        )
        out = string.format(
            _(
                "evaluation-comms",
                "%s\n\nFor each subtask, the single letter evaluations are:\n    N = Needs improvement\n    C = Competent\n    E = Exceeds expectations\n    S = Superior"
            ),
            out
        )
    end
    return out
end
-- Bonus task: Destroy enemy base
-- Hurdles: Enemy space ships, enemy base is far from primary base
-- Participants: Helm, Weapons, Engineering, Science, Relay
function bonusTaskEvaluation()
    if func_diagnostic then
        print("bonus task evaluation")
    end
    local out = bonusTaskEvaluationOutput(comms_source)
    out = string.format(
        _(
            "evaluation-comms",
            "We only have objective evaluation data. Subjective evaluation must come from a different source. The entire crew contributes to the success of a task. Certain members are measured on part of the task.\n----- Bonus Task -----\n%s"
        ),
        out
    )
    setCommsMessage(out)
    addCommsReply(_("Back"), commsStation)
end
function bonusTaskEvaluationOutput(p, gm)
    if func_diagnostic then
        print("bonus task evaluation output")
    end
    local bonus_task_complete = true
    local my_nemesis_index = nil
    for i, nemesis in ipairs(nemesis_stations) do
        if p.nemesis_station == nemesis.station then
            my_nemesis_index = i
        end
        if nemesis.station:isValid() then
            bonus_task_complete = false
        end
    end
    local nem = nemesis_stations[my_nemesis_index]
    local bonus_task_time = getScenarioTime() - p.research_end_clock
    local status_desc = {
        ["complete"] = _("evaluation-comms", "complete"),
        ["incomplete"] = _("evaluation-comms", "incomplete"),
        ["partially complete"] = _("evaluation-comms", "partially complete"),
    }
    local bonus_task_status = "complete"
    local my_nemesis_state = "(destroyed)"
    if p.nemesis_station:isValid() then
        bonus_task_status = "incomplete"
        my_nemesis_state = ""
    else
        if bonus_task_complete then
            bonus_task_time = bonus_task_end_clock - p.research_end_clock
        else
            my_nemesis_state = string.format(
                _("evaluation-comms", "%s time: %s"),
                my_nemesis_state,
                colonTime(p.complete_my_nemesis_clock - p.research_end_clock)
            )
            bonus_task_status = "partially complete"
        end
    end
    out = string.format(
        _("evaluation-comms", "Bonus task length: %s     Status: %s"),
        colonTime(bonus_task_time),
        status_desc[bonus_task_status]
    )
    out = string.format(
        _("evaluation-comms", "%s\nStation %s %s"),
        out,
        nem.name,
        my_nemesis_state
    )
    out = string.format(
        _(
            "evaluation-comms",
            "%s\n     Ships spawned: count: %i, strength: %.1f"
        ),
        out,
        nem.defense_ship_spawn_count,
        nem.defense_spawn_strength
    )
    out = string.format(
        _(
            "evaluation-comms",
            "%s\n     Ships destroyed: count: %i, strength: %.1f"
        ),
        out,
        nem.defense_ship_destroyed_count,
        nem.defense_ship_destroyed_strength
    )
    if
        bonus_task_status == "complete"
        or bonus_task_status == "partially complete"
    then
        for i, nemesis in ipairs(nemesis_stations) do
            if i ~= my_nemesis_index then
                local nemesis_state = _("evaluation-comms", "(destroyed)")
                if nemesis.station:isValid() then
                    nemesis_state = ""
                end
                out = string.format(
                    _("evaluation-comms", "%s\nStation %s %s"),
                    out,
                    nemesis.name,
                    nemesis_state
                )
                out = string.format(
                    _(
                        "evaluation-comms",
                        "%s\n     Ships spawned: count: %i, strength: %.1f"
                    ),
                    out,
                    nemesis.defense_ship_spawn_count,
                    nemesis.defense_spawn_strength
                )
                out = string.format(
                    _(
                        "evaluation-comms",
                        "%s\n     Ships destroyed: count: %i, strength: %.1f"
                    ),
                    out,
                    nemesis.defense_ship_destroyed_count,
                    nemesis.defense_ship_destroyed_strength
                )
            end
        end
    end
    return out
end
function playerPosthumousEvaluations()
    if func_diagnostic then
        print("player posthumous evaluations")
    end
    local out = _(
        "evaluation-comms",
        "Posthumous evaluations are intended for those times when you want the evaluation information, but the player ship has been destroyed. A copy is made in the posthumous list at the time the task is completed. So, just because they are on the posthumous list does not mean the player ship has been destroyed. Only the first instance of a task is recorded. If the player ship does a task again, the posthumous table only keeps their first attempt. If they are destroyed a second time, no new record is made of any tasks they had already completed the first time. Of course if they live, their current evaluation information is attached to their ship and thus is available.\n\nSingle letter evaluation decode:\nN = Needs improvement\nC = Competent\nE = Exceeds expectations\nS = Superior"
    )
    local count = 0
    for i, eval in ipairs(posthumous) do
        count = count + 1
        addCommsReply(string.format("%s %s", eval.name, eval.task), function()
            setCommsMessage(
                string.format(
                    _("evaluation-comms", "%s     %s     Clock: %.1f\n%s"),
                    eval.name,
                    eval.task,
                    colonTime(eval.clock),
                    eval.desc
                )
            )
            addCommsReply(_("Back"), commsStation)
        end)
    end
    if count == 0 then
        out = string.format(
            _(
                "evaluation-comms",
                "%s\n\nNo tasks completed, so no tasks recorded in the posthumous table"
            ),
            out
        )
    end
    setCommsMessage(out)
    addCommsReply(_("evaluation-comms", "Current Evaluations"), function()
        setCommsMessage(
            _("station-comms", "Which task evaluation would you like to view?")
        )
        addCommsReply(
            _("station-comms", "View docking task evalutation"),
            function()
                setCommsMessage(dockTaskEvaluationOutput(comms_source, "gm"))
                addCommsReply(_("Back"), commsStation)
            end
        )
        addCommsReply(
            _("station-comms", "View scanning task evalutation"),
            function()
                setCommsMessage(scanTaskEvaluationOutput(comms_source, "gm"))
                addCommsReply(_("Back"), commsStation)
            end
        )
        addCommsReply(
            _("station-comms", "View destroy freighter task evalutation"),
            function()
                setCommsMessage(
                    destroyFreighterTaskEvaluationOutput(comms_source, "gm")
                )
                addCommsReply(_("Back"), commsStation)
            end
        )
        addCommsReply(
            _("station-comms", "View assist freighter task evalutation"),
            function()
                setCommsMessage(
                    assistFreighterTaskEvaluationOutput(comms_source, "gm")
                )
                addCommsReply(_("Back"), commsStation)
            end
        )
        addCommsReply(
            _("station-comms", "View research task evalutation"),
            function()
                setCommsMessage(
                    researchTaskEvaluationOutput(comms_source, "gm")
                )
                addCommsReply(_("Back"), commsStation)
            end
        )
        addCommsReply(_("Back"), commsStation)
    end)
    addCommsReply(_("Back"), commsStation)
end
------------------------
-- Ship communication --
------------------------
local function assistFreighterComms()
    if comms_source.assist_freighter ~= comms_target then
        return
    end
    if comms_source.assist_freighter_contacted == nil then
        setCommsMessage(_("ship-comms", "We are in need of some assistance."))
        addCommsReply(
            _("ship-comms", "What kind of assistance do you need?"),
            function()
                comms_source.assist_freighter_contacted = true
                comms_source.assist_freighter_contacted_clock =
                    getScenarioTime()
                setCommsMessage(
                    _(
                        "ship-comms",
                        "We're not exactly sure. We just know our engines are not working"
                    )
                )
                addCommsReply(
                    _("ship-comms", "May we scan your ship?"),
                    function()
                        setCommsMessage(
                            _(
                                "ship-comms",
                                "If that helps you figure out what's wrong with the engines, go right ahead"
                            )
                        )
                        addCommsReply(
                            string.format(
                                _(
                                    "ship-comms",
                                    "We'll provide %s with your ship data and get back to you"
                                ),
                                comms_source.home_station:getCallSign()
                            ),
                            function()
                                setCommsMessage(
                                    _(
                                        "ship-comms",
                                        "We'll be here. We're not going enywhere. We are worried about Kraylor in the area, so don't take too long"
                                    )
                                )
                                addCommsReply(_("Back"), commsShip)
                            end
                        )
                        addCommsReply(_("Back"), commsShip)
                    end
                )
                addCommsReply(_("Back"), commsShip)
            end
        )
    elseif comms_source.assist_freighter_parts == "loaded" then
        if distance(comms_source, comms_target) < 5000 then
            addCommsReply(_("ship-comms", "Deliver repair parts"), function()
                if
                    comms_source.assist_freighter_integer_health_max
                    == comms_source.assist_freighter_reported_damage
                then
                    setCommsMessage(
                        _(
                            "ship-comms",
                            "These match exactly what we need. We will fully restore our engines shortly"
                        )
                    )
                    comms_target:setSystemHealthMax("impulse", 1)
                    comms_source.assist_freighter_fixed_clock =
                        getScenarioTime()
                else
                    setCommsMessage(
                        _(
                            "ship-comms",
                            "These parts don't look like they solve our problem. You may want to double check the information you provided to the parts supplier"
                        )
                    )
                    comms_source.assist_freighter_parts = nil
                    comms_source.assist_freighter_reported_damage = nil
                end
            end)
        end
    end
end

function commsShip()
    if func_diagnostic then
        print("comms ship")
    end
    return ShipComms.commsShip(ship_profile)
end

ship_profile = {
    enemy = function(comms_data)
        if func_diagnostic then
            print("enemy comms")
        end
        return ShipComms.enemyComms(comms_data)
    end,
    friendly = function(comms_data)
        if func_diagnostic then
            print("friendly comms")
        end
        return ShipComms.friendlyComms(ship_profile, comms_data)
    end,
    neutral = function(comms_data)
        if func_diagnostic then
            print("neutral comms")
        end
        return ShipComms.neutralComms(ship_profile, comms_data)
    end,
    main_menu = commsShip,
    init_goods = function(comms_target, comms_data)
        if comms_data.goods == nil then
            goodsOnShip(comms_target, comms_data)
        end
    end,
    friendly_status_destination = true,
    can_dock = function()
        return comms_target:getTypeName() ~= "Defense platform"
    end,
    neutral_destination_query = true,
    neutral_after_message = assistFreighterComms,
}
function revertWait(delta)
    if func_diagnostic then
        print("revert wait")
    end
    revert_timer = revert_timer - delta
    if revert_timer < 0 then
        revert_timer = delta + revert_timer_interval
        plotRevert = revertCheck
    end
end
function revertCheck(delta)
    if func_diagnostic then
        print("revert check")
    end
    if enemy_reverts ~= nil then
        for i, enemy in ipairs(enemy_reverts) do
            if enemy ~= nil and enemy:isValid() then
                local expiration_chance = 0
                local enemy_faction = enemy:getFaction()
                if enemy.taunt_may_expire then
                    if enemy_faction == "Kraylor" then
                        expiration_chance = 4.5
                    elseif enemy_faction == "Arlenians" then
                        expiration_chance = 7
                    elseif enemy_faction == "Exuari" then
                        expiration_chance = 2.5
                    elseif enemy_faction == "Ghosts" then
                        expiration_chance = 8.5
                    elseif enemy_faction == "Ktlitans" then
                        expiration_chance = 5.5
                    elseif enemy_faction == "TSN" then
                        expiration_chance = 3
                    elseif enemy_faction == "USN" then
                        expiration_chance = 3.5
                    elseif enemy_faction == "CUF" then
                        expiration_chance = 4
                    else
                        expiration_chance = 6
                    end
                elseif enemy.amenability_may_expire then
                    local enemy_health = getEnemyHealth(enemy)
                    if enemy_faction == "Kraylor" then
                        expiration_chance = 2.5
                    elseif enemy_faction == "Arlenians" then
                        expiration_chance = 3.25
                    elseif enemy_faction == "Exuari" then
                        expiration_chance = 6.6
                    elseif enemy_faction == "Ghosts" then
                        expiration_chance = 3.2
                    elseif enemy_faction == "Ktlitans" then
                        expiration_chance = 4.8
                    elseif enemy_faction == "TSN" then
                        expiration_chance = 3.5
                    elseif enemy_faction == "USN" then
                        expiration_chance = 2.8
                    elseif enemy_faction == "CUF" then
                        expiration_chance = 3
                    else
                        expiration_chance = 4
                    end
                    expiration_chance = expiration_chance + enemy_health * 5
                end
                local expiration_roll = random(1, 100)
                if expiration_roll < expiration_chance then
                    local oo = enemy.original_order
                    local otx = enemy.original_target_x
                    local oty = enemy.original_target_y
                    local ot = enemy.original_target
                    if oo ~= nil then
                        if oo == "Attack" then
                            if ot ~= nil and ot:isValid() then
                                enemy:orderAttack(ot)
                            else
                                enemy:orderRoaming()
                            end
                        elseif oo == "Dock" then
                            if ot ~= nil and ot:isValid() then
                                enemy:orderDock(ot)
                            else
                                enemy:orderRoaming()
                            end
                        elseif oo == "Defend Target" then
                            if ot ~= nil and ot:isValid() then
                                enemy:orderDefendTarget(ot)
                            else
                                enemy:orderRoaming()
                            end
                        elseif oo == "Fly towards" then
                            if otx ~= nil and oty ~= nil then
                                enemy:orderFlyTowards(otx, oty)
                            else
                                enemy:orderRoaming()
                            end
                        elseif oo == "Defend Location" then
                            if otx ~= nil and oty ~= nil then
                                enemy:orderDefendLocation(otx, oty)
                            else
                                enemy:orderRoaming()
                            end
                        elseif oo == "Fly towards (ignore all)" then
                            if otx ~= nil and oty ~= nil then
                                enemy:orderFlyTowardsBlind(otx, oty)
                            else
                                enemy:orderRoaming()
                            end
                        else
                            enemy:orderRoaming()
                        end
                    else
                        enemy:orderRoaming()
                    end
                    if enemy.original_faction ~= nil then
                        enemy:setFaction(enemy.original_faction)
                    end
                    enemy.taunt_may_expire = false
                    enemy.amenability_may_expire = false
                end
            end
        end
    end
    plotRevert = revertWait
end
function checkContinuum(delta)
    if func_diagnostic then
        print("check continuum")
    end
    local continuum_count = 0
    for pidx = 1, 32 do
        local p = getPlayerShip(pidx)
        if p ~= nil and p:isValid() then
            if p.continuum_target then
                continuum_count = continuum_count + 1
                if p.continuum_timer == nil then
                    p.continuum_timer = delta + 30
                end
                p.continuum_timer = p.continuum_timer - delta
                if p.continuum_timer < 0 then
                    if
                        p.continuum_initiator ~= nil
                        and p.continuum_initiator:isValid()
                    then
                        if random(1, 100) < (30 + (difficulty * 4)) then
                            p:setSystemHealth(
                                "frontshield",
                                (p:getSystemHealth("frontshield") - 1) / 2
                            )
                        end
                        if random(1, 100) < (30 + (difficulty * 4)) then
                            p:setSystemHealth(
                                "rearshield",
                                (p:getSystemHealth("rearshield") - 1) / 2
                            )
                        end
                        if random(1, 100) < (30 + (difficulty * 4)) then
                            p:setSystemHealth(
                                "reactor",
                                (p:getSystemHealth("reactor") - 1) / 2
                            )
                        end
                        if random(1, 100) < (30 + (difficulty * 4)) then
                            p:setSystemHealth(
                                "maneuver",
                                (p:getSystemHealth("maneuver") - 1) / 2
                            )
                        end
                        if random(1, 100) < (30 + (difficulty * 4)) then
                            p:setSystemHealth(
                                "impulse",
                                (p:getSystemHealth("impulse") - 1) / 2
                            )
                        end
                        if random(1, 100) < (30 + (difficulty * 4)) then
                            p:setSystemHealth(
                                "beamweapons",
                                (p:getSystemHealth("beamweapons") - 1) / 2
                            )
                        end
                        if random(1, 100) < (30 + (difficulty * 4)) then
                            p:setSystemHealth(
                                "missilesystem",
                                (p:getSystemHealth("missilesystem") - 1) / 2
                            )
                        end
                        if random(1, 100) < (30 + (difficulty * 4)) then
                            p:setSystemHealth(
                                "warp",
                                (p:getSystemHealth("warp") - 1) / 2
                            )
                        end
                        if random(1, 100) < (30 + (difficulty * 4)) then
                            p:setSystemHealth(
                                "jumpdrive",
                                (p:getSystemHealth("jumpdrive") - 1) / 2
                            )
                        end
                        local ex, ey = p.continuum_initiator:getPosition()
                        p.continuum_initiator:destroy()
                        ExplosionEffect():setPosition(ex, ey):setSize(3000)
                        resetContinuum(p)
                    else
                        resetContinuum(p)
                    end
                else
                    local timer_display = string.format(
                        _("tabRelay", "Disruption %i"),
                        math.floor(p.continuum_timer)
                    )
                    if p:hasPlayerAtPosition("Relay") then
                        p.continuum_timer_display = "continuum_timer_display"
                        p:addCustomInfo(
                            "Relay",
                            p.continuum_timer_display,
                            timer_display,
                            1
                        )
                    end
                    if p:hasPlayerAtPosition("Operations") then
                        p.continuum_timer_display_ops =
                            "continuum_timer_display_ops"
                        p:addCustomInfo(
                            "Operations",
                            p.continuum_timer_display_ops,
                            timer_display,
                            1
                        )
                    end
                end
            else
                resetContinuum(p)
            end
        end
    end
end
function resetContinuum(p)
    if func_diagnostic then
        print("reset continuum")
    end
    p.continuum_target = nil
    p.continuum_timer = nil
    p.continuum_initiator = nil
    if p.continuum_timer_display ~= nil then
        p:removeCustom("Relay", p.continuum_timer_display)
        p.continuum_timer_display = nil
    end
    if p.continuum_timer_display_ops ~= nil then
        p:removeCustom("Operations", p.continuum_timer_display_ops)
        p.continuum_timer_display_ops = nil
    end
end
function sendCrutch(p, task)
    if func_diagnostic then
        print("send crutch")
    end
    if task == "dock" then
        if p.protocol_source == nil then
            p.protocol_source =
                string.format("station %s", p.home_station:getCallSign())
            if p:hasPlayerAtPosition("Relay") then
                p.protocol_source = "Relay"
            elseif p:hasPlayerAtPosition("Operations") then
                p.protocol_source = "Operations"
            end
            -- helm
            p.crutch_dock_hlm_msg = string.format(
                _(
                    "msgHelms",
                    "The most direct route to dock with station %s is to put the ship in full reverse impulse. The engines start at minimal power, so you may have to ask engineering to put more power in the impulse engines. You get a better evaluation score the higher your speed. You won't be able to dock until the docking protocols are satisfied."
                ),
                p.home_station:getCallSign()
            )
            p.crutch_dock_hlm = "crutch_dock_hlm"
            p:addCustomMessage(
                "Helms",
                p.crutch_dock_hlm,
                p.crutch_dock_hlm_msg
            )
            -- weapons
            p.crutch_dock_wea_msg = string.format(
                _(
                    "msgWeapons",
                    "Get the docking protocol shield and beam frequency from %s. Calibrate the shields by adjusting the frequency in the lower right of your console then click the calibrate button. Set the beam weapons frequency by adjusting the frequency above the shield frequency in the lower right of your console."
                ),
                p.protocol_source
            )
            p.crutch_dock_wea = "crutch_dock_wea"
            p:addCustomMessage(
                "Weapons",
                p.crutch_dock_wea,
                p.crutch_dock_wea_msg
            )
            -- tactical
            p.crutch_dock_tac_msg = string.format(
                _(
                    "msgTactical",
                    "%s Get the docking protocol beam frequency from %s. Calibrate the beams using the frequency shown along the bottom edge of your console in the middle of your console."
                ),
                p.crutch_dock_hlm_msg,
                p.protocol_source
            )
            p.crutch_dock_tac = "crutch_dock_tac"
            p:addCustomMessage(
                "Tactical",
                p.crutch_dock_tac,
                p.crutch_dock_tac_msg
            )
            -- engineering
            p.crutch_dock_eng_msg = string.format(
                _(
                    "msgEngineer",
                    "All systems start at a low power level. You'll want to put power in the impulse engines based on the first task requirement. Be prepared to run the impulse engines up to 300%% with max coolant at Helm's request until you reach the station. You'll hear from %s that the docking protocol calls for zero power in the missile systems, so take the power all the way out of missile systems."
                ),
                p.protocol_source
            )
            p.crutch_dock_eng = "crutch_dock_eng"
            p:addCustomMessage(
                "Engineering",
                p.crutch_dock_eng,
                p.crutch_dock_eng_msg
            )
            -- engineering plus
            p.crutch_dock_epl_msg = string.format(
                _(
                    "msgEngineer+",
                    "%s The docking protocol also calls for shield calibration. Listen for the shield frequency. Adjust the shield frequency with the frequency selector along the left edge of your console in the middle. Click the Calibrate button after you have set the frequency."
                ),
                p.crush_dock_eng_msg
            )
            p.crutch_dock_epl = "crutch_dock_epl"
            p:addCustomMessage(
                "Engineering+",
                p.crutch_dock_epl,
                p.crutch_dock_epl_msg
            )
            -- relay
            p.crutch_dock_rel_msg = string.format(
                _(
                    "msgRelay",
                    "To contact station %s for the docking protocol, click %s then click the Open Comms button in the upper left of your console. Once communications are open, click the Check with docking port authority button to determine the docking protocol. Report the protocol to your crew."
                ),
                p.home_station:getCallSign(),
                p.home_station:getCallSign()
            )
            p.crutch_dock_rel = "crutch_dock_rel"
            p:addCustomMessage(
                "Relay",
                p.crutch_dock_rel,
                p.crutch_dock_rel_msg
            )
            -- operations
            p.crutch_dock_ops_msg = string.format(
                _(
                    "msgOperations",
                    "To contact station %s for the docking protocol, click %s then click the Open Comms button along the bottom edge of your console to the right. Once communications are open, click the Check with docking port authority button to determine the docking protocol. Report the protocol to your crew."
                ),
                p.home_station:getCallSign(),
                p.home_station:getCallSign()
            )
            p.crutch_dock_ops = "crutch_dock_ops"
            p:addCustomMessage(
                "Operations",
                p.crutch_dock_ops,
                p.crutch_dock_ops_msg
            )
        end
    elseif task == "scan" then
        if not p:hasPlayerAtPosition("Relay") then
            -- helm
            p.crutch_scan_hlm_msg = _(
                "msgHelms",
                "You might be asked to jump into the nearby nebula so that a freighter can be scanned."
            )
            p.crutch_scan_hlm = "crutch_scan_hlm"
            p:addCustomMessage(
                "Helms",
                p.crutch_scan_hlm,
                p.crutch_scan_hlm_msg
            )
            -- tactical
            p.crutch_scan_tac_msg = p.crutch_scan_hlm_msg
            p.crutch_scan_tac = "crutch_scan_tac"
            p:addCustomMessage(
                "Tactical",
                p.crutch_scan_tac,
                p.crutch_scan_tac_msg
            )
        end
        -- science
        p.crutch_scan_sci_msg = string.format(
            _(
                "msgScience",
                "Start scanning the target at bearing %.1f right away. Report the type of ship as soon as you finish the simple scan. Then start the deep scan. The default keyboard shortcut is S to start the scan. After completing the deep scan, get the scanned ship's strongest shield deflection frequency by hovering over the lowest, reddest point on the bar graph. Report that frequency."
            ),
            p.home_station.heading_angle
        )
        p.crutch_scan_sci = "crutch_scan_sci"
        p:addCustomMessage("Science", p.crutch_scan_sci, p.crutch_scan_sci_msg)
        -- relay
        p.crutch_scan_rel_msg = _(
            "msgRelay",
            "Send a probe to the middle of the nearest nebula: click the launch probe button, then click the middle of the nebula. Once it's there, link it to science. Be ready to report the ship type and the frequency as soon as Science completes each scan."
        )
        p.crutch_scan_rel = "crutch_scan_rel"
        p:addCustomMessage("Relay", p.crutch_scan_rel, p.crutch_scan_rel_msg)
        -- operations
        p.crutch_scan_ops_msg = string.format(
            _(
                "msgOperations",
                "Start scanning the target at bearing %.1f right away. There are likely more targets in the nebula, so you should request that helm or tactical take you closer to the nebula. Report the type of ship as soon as you finish the simple scan. Then start the deep scan. The default keyboard shortcut is S to start the scan. After completing the deep scan, get the scanned ship's strongest shield deflection frequency by hovering over the lowest, reddest point on the bar graph. Report that frequency. Once you scan the other targets that are likely in the nebula, you will need to exit the nebula to report their characteristics to %s."
            ),
            p.home_station.heading_angle,
            p.home_station:getCallSign()
        )
        p.crutch_scan_ops = "crutch_scan_ops"
        p:addCustomMessage(
            "Operations",
            p.crutch_scan_ops,
            p.crutch_scan_ops_msg
        )
    elseif task == "destroy freighter" then
        -- helm
        p.crutch_destroy_hlm_msg = _(
            "msgHelms",
            "Jump to the enemy freighter if it's farther than 5 units away. Get the bearing and distance from Science or Operations, subtract 2 units to place you in optimal firing range. Once you're near, rotate to point the left or right tube to the enemy. He'll try to run away, so be ready to angle the tube to lead the HVLIs in front of the enemy freighter."
        )
        p.crutch_destroy_hlm = "crutch_destroy_hlm"
        p:addCustomMessage(
            "Helms",
            p.crutch_destroy_hlm,
            p.crutch_destroy_hlm_msg
        )
        -- weapons
        p.crutch_destroy_wea_msg = _(
            "msgWeapons",
            "Load up HVLIs on both sides. You may have to ask Engineering for power to missile systems."
        )
        p.crutch_destroy_wea = "crutch_destroy_wea"
        p:addCustomMessage(
            "Weapons",
            p.crutch_destroy_wea,
            p.crutch_destroy_wea_msg
        )
        -- tactical
        p.crutch_destroy_tac_msg = string.format(
            "%s %s",
            p.crutch_destroy_wea_msg,
            p.crutch_destroy_hlm_msg
        )
        p.crutch_destroy_tac = "crutch_destroy_tac"
        p:addCustomMessage(
            "Tactical",
            p.crutch_destroy_tac,
            p.crutch_destroy_tac_msg
        )
        -- engineering
        p.crutch_destroy_eng_msg = _(
            "msgEngineer",
            "Raise power to missile systems to 100%. Put even more in along with coolant to make them load faster. Be ready to add power to impulse and/or maneuvering as requested."
        )
        p.crutch_destroy_eng = "crutch_destroy_eng"
        p:addCustomMessage(
            "Engineering",
            p.crutch_destroy_eng,
            p.crutch_destroy_eng_msg
        )
        -- engineering plus
        p.crutch_destroy_epl_msg = p.crutch_destroy_eng_msg
        p.crutch_destroy_epl = "crutch_destroy_epl"
        p:addCustomMessage(
            "Engineering+",
            p.crutch_destroy_epl,
            p.crutch_destroy_epl_msg
        )
        -- science
        p.crutch_destroy_sci_msg = _(
            "msgScience",
            "Select the enemy freighter. Use radar or probe view as applicable. Provide bearing and distance to freighter to crew. You can find it along the right of your console screen."
        )
        p.crutch_destroy_sci = "crutch_destroy_sci"
        p:addCustomMessage(
            "Science",
            p.crutch_destroy_sci,
            p.crutch_destroy_sci_msg
        )
        -- operations
        p.crutch_destroy_ops_msg = _(
            "msgOperations",
            "Provide bearing and range to enemy freighter. If nebula obscures your view, estimate based on recent scans, otherwise click the enemy freighter and read the bearing and distance from your console."
        )
        p.crutch_destroy_ops = "crutch_destroy_ops"
        p:addCustomMessage(
            "Operations",
            p.crutch_destroy_ops,
            p.crutch_destroy_ops_msg
        )
        -- relay
        p.crutch_destroy_rel_msg = _(
            "msgRelay",
            "Hack enemy ships once they are in range either via probe or your ship. Impulse engines for the fighter types is a good choice since it makes it easier to shoot them down."
        )
        p.crutch_destroy_rel = "crutch_destroy_rel"
        p:addCustomMessage(
            "Relay",
            p.crutch_destroy_rel,
            p.crutch_destroy_rel_msg
        )
    elseif task == "assist freighter" then
        -- helm
        p.crutch_assist_hlm_msg = _(
            "msgHelms",
            "You will have to go to the distressed freighter to help defend it against Kraylor and to help repair it. You may have to pick up parts from your home station. Deciding which to do first will be up to your commanding officer or CO. Be thinking about both options."
        )
        p.crutch_assist_hlm = "crutch_assist_hlm"
        p:addCustomMessage(
            "Helms",
            p.crutch_assist_hlm,
            p.crutch_assist_hlm_msg
        )
        -- weapons
        p.crutch_assist_wea_msg = _(
            "msgWeapons",
            "Your beams are fully functional. Your missiles have been returned to you. Load up your tubes in preparation for combat. Homing missiles are recommended. Even homing missiles can be dodged by the enemy. Try for as straight a shot as possible."
        )
        p.crutch_assist_wea = "crutch_assist_wea"
        p:addCustomMessage(
            "Weapons",
            p.crutch_assist_wea,
            p.crutch_assist_wea_msg
        )
        -- tactical
        p.crutch_assist_tac_msg = string.format(
            "%s %s",
            p.crutch_assist_hlm_msg,
            p.crutch_assist_wea_msg
        )
        p.crutch_assist_tac = "crutch_assist_tac"
        p:addCustomMessage(
            "Tactical",
            p.crutch_assist_tac,
            p.crutch_assist_tac_msg
        )
        -- engineering
        p.crutch_assist_eng_msg = _(
            "msgEngineer",
            "Pay careful attention to what systems are used and give them additional power when needed (along with coolant). Remember the docking/undocking protocol (no missile energy)"
        )
        p.crutch_assist_eng = "crutch_assist_eng"
        p:addCustomMessage(
            "Engineering",
            p.crutch_assist_eng,
            p.crutch_assist_eng_msg
        )
        -- engineering plus
        p.crutch_assist_epl_msg = p.crutch_assist_eng_msg
        p.crutch_assist_epl = "crutch_assist_epl"
        p:addCustomMessage(
            "Engineering+",
            p.crutch_assist_epl,
            p.crutch_assist_epl_msg
        )
        -- science
        p.crutch_assist_sci_msg = _(
            "msgScience",
            "Scan the distressed Arlenian freighter as soon as you can (twice). After the second scan, get the impulse engine damage percentage by clicking the Tactical widget and selecting Systems. Report it to Relay who will report it to the home station."
        )
        p.crutch_assist_sci = "crutch_assist_sci"
        p:addCustomMessage(
            "Science",
            p.crutch_assist_sci,
            p.crutch_assist_sci_msg
        )
        -- relay
        p.crutch_assist_rel_msg = _(
            "msgRelay",
            "Launch probes to cover the sector where the distressed Arlenian freighter is located. Link the probe that finds the freighter to science. Contact the freighter. Report Science's scan results to your home station."
        )
        p.crutch_assist_rel = "crutch_assist_rel"
        p:addCustomMessage(
            "Relay",
            p.crutch_assist_rel,
            p.crutch_assist_rel_msg
        )
        -- operations
        p.crutch_assist_ops_msg = _(
            "msgOperations",
            "Contact the distressed Arlenian freighter, then scan the freighter as soon as you can (twice). After the second scan, get the impulse engine damage percentage by clicking the Tactical widget and selecting Systems. Report it to the home station."
        )
        p.crutch_assist_ops = "crutch_assist_ops"
        p:addCustomMessage(
            "Operations",
            p.crutch_assist_ops,
            p.crutch_assist_ops_msg
        )
    elseif task == "research" then
        -- helm
        p.crutch_research_hlm_msg = _(
            "msgHelms",
            "Use warp to approach but not intersect the planets and moons in motion. Intersetion will damage and quickly destroy your ship. Use guidance from Relay/Science/Operations for good approach vectors. Warn Engineering when you use warp, especially anything above warp one."
        )
        p.crutch_research_hlm = "crutch_research_hlm"
        p:addCustomMessage(
            "Helms",
            p.crutch_research_hlm,
            p.crutch_research_hlm_msg
        )
        -- weapons
        p.crutch_research_wea_msg = _(
            "msgWeapons",
            "Watch for enemy targets of opportunity. The planets and moons are far more dangerous, but if you leave the enemies alone, eventually, they will start attacking your home station."
        )
        p.crutch_research_wea = "crutch_research_wea"
        p:addCustomMessage(
            "Weapons",
            p.crutch_research_wea,
            p.crutch_research_wea_msg
        )
        -- tactical
        p.crutch_research_tac_msg = string.format(
            "%s %s",
            p.crutch_research_hlm_msg,
            p.crutch_research_wea_msg
        )
        p.crutch_research_tac = "crutch_research_tac"
        p:addCustomMessage(
            "Tactical",
            p.crutch_research_tac,
            p.crutch_research_tac_msg
        )
        -- engineering
        p.crutch_research_eng_msg = _(
            "msgEngineer",
            "Suggested default settings: 50% coolant in warp, 50% coolant in maneuvering, 150% power in maneuvering, remaining systems: 100%, remainig coolant: 0. Watch energy carefully and let the commanding officer know when you get below 200 so you can dock and get more. The reactor will help, but charging at a station is more efficient."
        )
        p.crutch_research_eng = "crutch_research_eng"
        p:addCustomMessage(
            "Engineering",
            p.crutch_research_eng,
            p.crutch_research_eng_msg
        )
        -- engineering plus
        p.crutch_research_epl_msg = p.crutch_research_eng_msg
        p.crutch_research_epl = "crutch_research_epl"
        p:addCustomMessage(
            "Engineering+",
            p.crutch_research_epl,
            p.crutch_research_epl_msg
        )
        -- science
        p.crutch_research_sci_msg =
            "Quickly tell Helm/Tactical when planets or moons are coming. They don't see as far as you do. Study the orbiting bodies. Know that there are orbits of orbits. Tell everyone when you are notified that the data has been gathered on a moon or planet."
        p.crutch_research_sci = "crutch_research_sci"
        p:addCustomMessage(
            "Science",
            p.crutch_research_sci,
            p.crutch_research_sci_msg
        )
        -- relay
        p.crutch_research_rel_msg =
            "Quickly tell Helm/Tactical when planets or moons are coming. They don't see as far as you do. Study the orbiting bodies. Know that there are orbits of orbits. Plan approach vectors for Helm and clearly communicate them. Provide updates on what's scanned and what remains by using the 'Orbit research' button."
        p.crutch_research_rel = "crutch_research_rel"
        p:addCustomMessage(
            "Relay",
            p.crutch_research_rel,
            p.crutch_research_rel_msg
        )
        -- operations
        p.crutch_research_ops_msg =
            "Quickly tell Helm/Tactical when planets or moons are coming. They don't see as far as you do. Study the orbiting bodies. Know that there are orbits of orbits. Plan approach vectors for Helm and clearly communicate them. Tell everyone when you are notified that the data has been gathered on a moon or planet."
        p.crutch_research_ops = "crutch_research_ops"
        p:addCustomMessage(
            "Operations",
            p.crutch_research_ops,
            p.crutch_research_ops_msg
        )
    end
end
function validHomeStation(p)
    if p.home_station ~= nil and p.home_station:isValid() then
        return p.home_station
    end
    local station_candidates = {}
    if allied_stations ~= nil then
        for i, station in ipairs(allied_stations) do
            table.insert(station_candidates, station)
        end
    end
    if stationList ~= nil then
        for i, station in ipairs(stationList) do
            table.insert(station_candidates, station)
        end
    end
    for i, station in ipairs(station_candidates) do
        if station:isValid() then
            if station.heading_angle == nil then
                station.heading_angle = station:getRotation()
            end
            if station.neb_x == nil or station.neb_y == nil then
                local station_x, station_y = station:getPosition()
                local vx, vy =
                    vectorFromAngleNorth(station.heading_angle, 25000)
                station.neb_x = station_x + vx
                station.neb_y = station_y + vy
            end
            if station.home_player_name == nil then
                station.home_player_name = p:getCallSign()
            end
            p.home_station = station
            return station
        end
    end
    p.home_station = nil
    return nil
end
function playerTask(p)
    if func_diagnostic then
        print("player task")
    end
    if p.home_station == nil or not p.home_station:isValid() then
        if validHomeStation(p) == nil then
            return
        end
    end
    if p.task == nil then
        local power_systems = {
            "reactor",
            "beamweapons",
            "missilesystem",
            "maneuver",
            "impulse",
            "jumpdrive",
            "frontshield",
            "rearshield",
        }
        for i, system in ipairs(power_systems) do
            p:setSystemPower(system, 0.31)
                :commandSetSystemPowerRequest(system, 0.31)
        end
        p.start_heading = p:getHeading()
        p:setCanDock(false)
        -- print("shield frequency:",p:getShieldsFrequency(),string.format("(%i THz)",p:getShieldsFrequency()*20+400),"beam frequency:",p:getBeamFrequency(),string.format("(%i THz)",p:getBeamFrequency()*20+400))
        local current_shield_frequency = p:getShieldsFrequency()
        local current_beam_frequency = p:getBeamFrequency()
        repeat
            p.dock_shield_frequency = math.random(1, 20)
        until p.dock_shield_frequency ~= current_shield_frequency
        repeat
            p.dock_beam_frequency = math.random(0, 20)
        until p.dock_beam_frequency ~= current_beam_frequency
        p.task = "dock"
    else
        task_list[p.task](p)
    end
end
-- First Task: Dock
-- Hurdles: request permission to dock, calibrate shields and beams, power down missiles
-- Participants: Helm, weapons, relay, engineering
function taskDock(p)
    if func_diagnostic then
        print("task dock")
    end
    if p.start_dock_message == nil then
        if availableForComms(p) then
            p.start_dock_message = "start"
            p.home_station:openCommsTo(p) --send dock task instructional message
        end
    end
    if p.dock_start_clock == nil then --check for non-relay message start triggers
        if p.start_heading ~= p:getHeading() then
            p.dock_start_clock = getScenarioTime()
        else
            local vx, vy = p:getVelocity()
            if vx ~= 0 or vy ~= 0 then
                p.dock_start_clock = getScenarioTime()
            end
        end
    else --dock task started, check for task completion
        if p.dock_max_velocity == nil then
            p.dock_max_velocity = 0
        end
        local vx, vy = p:getVelocity()
        local player_velocity = math.sqrt(
            (math.abs(vx) * math.abs(vx)) + (math.abs(vy) * math.abs(vy))
        ) * 60 / 1000
        if player_velocity > p.dock_max_velocity then
            p.dock_max_velocity = player_velocity
        end
        if p.dock_engineer_missile_zero_clock == nil then
            if p:getSystemPower("missilesystem") <= 0 then
                p.dock_engineer_missile_zero_clock = getScenarioTime()
            end
        end
        if p.dock_set_shield_clock == nil then
            if p.dock_shield_frequency == p:getShieldsFrequency() then
                p.dock_set_shield_clock = getScenarioTime()
            end
        end
        if p.dock_set_beam_clock == nil then
            if p.dock_beam_frequency == p:getBeamFrequency() then
                p.dock_set_beam_clock = getScenarioTime()
            end
        end
        if p.home_station ~= nil then
            if p:isDocked(p.home_station) then
                p.dock_end_clock = getScenarioTime()
                p.task = "completed dock"
                p.dock_task = "complete"
            end
        end
    end
end
function taskCompletedDock(p)
    if func_diagnostic then
        print("task completed dock")
    end
    p.task = "scan"
    local recorded = false
    for i, eval in ipairs(posthumous) do
        if eval.name == p:getCallSign() then
            if eval.task == "dock" then
                recorded = true
                break
            end
        end
    end
    if not recorded then
        table.insert(posthumous, {
            name = p:getCallSign(),
            task = "dock",
            clock = getScenarioTime(),
            desc = dockTaskEvaluationOutput(p, "gm"),
        })
    end
    -- handle pre-launched scan probes
    if probe_list ~= nil and #probe_list > 0 then
        for i, pr in ipairs(probe_list) do
            if pr.probe:isValid() then
                if p == pr.launcher and pr.clock < p.dock_end_clock then
                    local pt_x, pt_y = pr.probe:getTarget()
                    local dist = distance(
                        pt_x,
                        pt_y,
                        p.home_station.neb_x,
                        p.home_station.neb_y
                    )
                    if dist < 10000 then
                        local pp_x, pp_y = pr.probe:getPosition()
                        dist = distance(
                            pp_x,
                            pp_y,
                            p.home_station.neb_x,
                            p.home_station.neb_y
                        )
                        if dist < 10000 then
                            pr.probe:destroy()
                        else
                            pr.probe:onArrival(destroyOnArrival)
                        end
                        pr.del = true
                    end
                end
            else
                pr.del = true
            end
        end
        for i = #probe_list, 1, -1 do
            if probe_list[i].del then
                probe_list[i] = probe_list[#probe_list]
                probe_list[#probe_list] = nil
            end
        end
    end
    -- add scan targets
    local scan_target_coordinates = {}
    table.insert(
        scan_target_coordinates,
        { x = p.home_station.neb_x, y = p.home_station.neb_y }
    )
    local vx, vy = vectorFromAngleNorth(p.home_station.heading_angle, 5500)
    table.insert(
        scan_target_coordinates,
        { x = p.home_station.neb_x + vx, y = p.home_station.neb_y + vy }
    )
    vx, vy =
        vectorFromAngleNorth((p.home_station.heading_angle + 180) % 360, 5500)
    table.insert(
        scan_target_coordinates,
        { x = p.home_station.neb_x + vx, y = p.home_station.neb_y + vy }
    )
    p.scan_targets = {}
    local scan_ship_types = {
        _("station-comms", "Personnel Freighter 5"),
        _("station-comms", "Goods Freighter 5"),
        _("station-comms", "Garbage Freighter 5"),
        _("station-comms", "Equipment Freighter 5"),
        _("station-comms", "Fuel Freighter 5"),
        _("station-comms", "Transport1x5"),
        _("station-comms", "Transport2x5"),
        _("station-comms", "Transport3x5"),
        _("station-comms", "Transport4x5"),
        _("station-comms", "Transport5x5"),
    }
    local coordinates = tableRemoveRandom(scan_target_coordinates)
    local ship = CpuShip()
        :setTemplate(tableRemoveRandom(scan_ship_types))
        :setPosition(coordinates.x, coordinates.y)
        :setFaction("Human Navy")
        :orderDock(p.home_station)
        :setHeading((p.home_station.heading_angle + 180) % 360)
        :setCommsScript("")
        :setCommsFunction(commsShip)
    table.insert(p.scan_targets, {
        ship = ship,
        name = ship:getCallSign(),
        faction = ship:getFaction(),
        single_scan_clock = nil,
        full_scan_clock = nil,
        typeName = ship:getTypeName(),
        identified_type = nil,
        shield_frequency = ship:getShieldsFrequency(),
        identified_frequency = nil,
        type_report_clock = nil,
        frequency_report_clock = nil,
    })
    table.insert(transportList, ship)
    coordinates = tableRemoveRandom(scan_target_coordinates)
    ship = CpuShip()
        :setTemplate(tableRemoveRandom(scan_ship_types))
        :setPosition(coordinates.x, coordinates.y)
        :setFaction("Independent")
        :orderDock(p.home_station)
        :setHeading((p.home_station.heading_angle + 180) % 360)
        :setCommsScript("")
        :setCommsFunction(commsShip)
    table.insert(p.scan_targets, {
        ship = ship,
        name = ship:getCallSign(),
        faction = ship:getFaction(),
        single_scan_clock = nil,
        full_scan_clock = nil,
        typeName = ship:getTypeName(),
        identified_type = nil,
        shield_frequency = ship:getShieldsFrequency(),
        identified_frequency = nil,
        type_report_clock = nil,
        frequency_report_clock = nil,
    })
    table.insert(transportList, ship)
    coordinates = tableRemoveRandom(scan_target_coordinates)
    local station_x, station_y = p.home_station:getPosition()
    ship = CpuShip()
        :setTemplate(tableRemoveRandom(scan_ship_types))
        :setPosition(coordinates.x, coordinates.y)
        :setFaction("Kraylor")
        :orderFlyTowards(station_x, station_y)
        :setHeading((p.home_station.heading_angle + 180) % 360)
        :setCommsScript("")
        :setCommsFunction(commsShip)
    if destroy_freighters == nil then
        destroy_freighters = {}
    end
    table.insert(destroy_freighters, {
        player_ship_name = p:getCallSign(),
        ship = ship,
        front_shield = ship:getShieldLevel(0),
        rear_shield = ship:getShieldLevel(1),
    })
    --     destroy_freighter = {ship = ship,front_shield = ship:getShieldLevel(0),rear_shield = ship:getShieldLevel(1)}
    table.insert(p.scan_targets, {
        ship = ship,
        name = ship:getCallSign(),
        faction = ship:getFaction(),
        single_scan_clock = nil,
        full_scan_clock = nil,
        typeName = ship:getTypeName(),
        identified_type = nil,
        shield_frequency = ship:getShieldsFrequency(),
        identified_frequency = nil,
        type_report_clock = nil,
        frequency_report_clock = nil,
    })
end
-- Second Task: Scan to discriminate targets
-- Hurdles: nebula obscures some targets
-- Participants: Science, relay
function taskScan(p)
    if func_diagnostic then
        print("task scan")
    end
    if p.scan_message == nil then
        if availableForComms(p) then
            p.scan_message = "start"
            p.home_station:openCommsTo(p) -- send scan task instructional message
        end
    end
    if p.scan_start_clock == nil then -- check for non-relay message start triggers
        if not p:isDocked(p.home_station) then
            p.scan_start_clock = getScenarioTime()
        end
        if p.scan_targets ~= nil then
            for i, scan_target in ipairs(p.scan_targets) do
                if scan_target.ship:isValid() then
                    if scan_target.ship:isScannedBy(p) then
                        p.scan_start_clock = getScenarioTime()
                        if scan_target.single_scan_clock == nil then
                            scan_target.single_scan_clock = getScenarioTime()
                                + 1
                        end
                        break
                    end
                end
            end
        end
    else -- scan task started, check for task completion
        local identified_type_count = 0
        local identified_frequency_count = 0
        for i, scan_target in ipairs(p.scan_targets) do
            if scan_target.ship:isValid() then
                if scan_target.identified_type ~= nil then
                    identified_type_count = identified_type_count + 1
                end
                if scan_target.identified_frequency ~= nil then
                    identified_frequency_count = identified_frequency_count + 1
                end
            else
                if scan_target.identified_type == nil then
                    scan_target.identified_type = "unidentified"
                end
                if scan_target.identified_frequency == nil then
                    scan_target.identified_frequency = -1000
                end
            end
        end
        if identified_type_count >= 3 and identified_frequency_count >= 3 then
            p.scan_end_clock = getScenarioTime()
            p.task = "completed scan"
            p.scan_task = "complete"
        end
    end
end
function taskCompletedScan(p)
    if func_diagnostic then
        print("task completed scan")
    end
    p.task = "destroy freighter"
    local recorded = false
    for i, eval in ipairs(posthumous) do
        if eval.name == p:getCallSign() then
            if eval.task == "scan" then
                recorded = true
                break
            end
        end
    end
    if not recorded then
        table.insert(posthumous, {
            name = p:getCallSign(),
            task = "scan",
            clock = getScenarioTime(),
            desc = scanTaskEvaluationOutput(p, "gm"),
        })
    end
    local destroy_freighter = nil
    for i, d in ipairs(destroy_freighters) do
        if p:getCallSign() == d.player_ship_name then
            destroy_freighter = d
        end
    end
    if destroy_freighter ~= nil and not destroy_freighter.ship:isValid() then
        local station_x, station_y = p.home_station:getPosition()
        local ship = CpuShip()
            :setTemplate(p.scan_targets[3].typeName)
            :setPosition(p.home_station.neb_x, p.home_station.neb_y)
            :setFaction("Kraylor")
            :orderFlyTowards(station_x, station_y)
            :setHeading(p.home_station.heading_angle)
            :setCommsScript("")
            :setCommsFunction(commsShip)
        destroy_freighter = {
            player_ship_name = p:getCallSign(),
            ship = ship,
            front_shield = ship:getShieldLevel(0),
            rear_shield = ship:getShieldLevel(1),
        }
    end
end
-- Third Task: Destroy enemy freighter
-- Hurdles: Limited beam function, only HVLI type missiles
-- Participants: Helm, Weapons, engineering, science, relay
function taskDestroyFreighter(p)
    if func_diagnostic then
        print("task destroy freighter")
    end
    if p.destroy_freighter_message == nil then
        if availableForComms(p) then
            p.destroy_freighter_message = "start"
            p.home_station:openCommsTo(p) -- send destroy freighter task instructional message
        end
    end
    local destroy_freighter = nil
    for i, d in ipairs(destroy_freighters) do
        if p:getCallSign() == d.player_ship_name then
            destroy_freighter = d
        end
    end
    if p.destroy_freighter_start_clock == nil then -- check for non-relay message start triggers
        if
            destroy_freighter.ship:getShieldLevel(0)
            < destroy_freighter.front_shield
        then
            p.destroy_freighter_start_clock = getScenarioTime()
        end
        if
            destroy_freighter.ship:getShieldLevel(1)
            < destroy_freighter.rear_shield
        then
            p.destroy_freighter_start_clock = getScenarioTime()
        end
        if p:getWeaponStorage("HVLI") < 16 then
            p.destroy_freighter_start_clock = getScenarioTime()
        end
    else -- destroy freighter task started, check for completion
        if not destroy_freighter.ship:isValid() then
            p.destroy_freighter_end_clock = getScenarioTime()
            p.destroy_freighter_remaining_HVLI = p:getWeaponStorage("HVLI")
            p.task = "completed destroy freighter"
            p.destroy_freighter_task = "complete"
        end
    end
end
function taskCompletedDestroyFreighter(p)
    if func_diagnostic then
        print("task completed destroy freighter")
    end
    p.task = "assist freighter"
    local recorded = false
    for i, eval in ipairs(posthumous) do
        if eval.name == p:getCallSign() then
            if eval.task == "destroy freighter" then
                recorded = true
                break
            end
        end
    end
    if not recorded then
        table.insert(posthumous, {
            name = p:getCallSign(),
            task = "destroy freighter",
            clock = getScenarioTime(),
            desc = destroyFreighterTaskEvaluationOutput(p, "gm"),
        })
    end
    local af_x, af_y = vectorFromAngleNorth(p.home_station.heading_angle, 60000)
    local station_x, station_y = p.home_station:getPosition()
    p.assist_freighter = CpuShip()
        :setTemplate(ST.PERSONNEL_FREIGHTER_1)
        :setFaction("Arlenians")
        :setPosition(station_x + af_x, station_y + af_y)
        :orderDock(p.home_station)
        :setCommsScript("")
        :setCommsFunction(commsShip)
    table.insert(transportList, p.assist_freighter)
    local health_max = (math.random(-10, 0) * 5 - 25)
    p.assist_freighter_integer_health_max = health_max
    health_max = health_max / 100
    p.assist_freighter:setSystemHealthMax("impulse", health_max)
    local psx, psy = vectorFromAngleNorth(p.home_station.heading_angle, 93000)
    p.nemesis_station = placeStation(
        psx + station_x,
        psy + station_y,
        "Sinister",
        "Kraylor",
        "Large Station"
    )
    if nemesis_stations == nil then
        nemesis_stations = {}
    end
    table.insert(nemesis_stations, {
        station = p.nemesis_station,
        ship = p,
        name = p.nemesis_station:getCallSign(),
        defense_ship_spawn_count = 0,
        defense_spawn_strength = 0,
        defense_ship_destroyed_count = 0,
        defense_ship_destroyed_strength = 0,
    })
    p.nemesis_station.victim_name = p:getCallSign()
    p.nemesis_station:onDestruction(function(self, instigator)
        string.format("")
        for i, p in ipairs(getActivePlayerShips()) do
            if p:getCallSign() == self.victim_name then
                p.complete_my_nemesis_clock = getScenarioTime()
            end
        end
        local more_nemesis_stations = false
        for i, nemesis in ipairs(nemesis_stations) do
            if nemesis.station ~= self then
                if nemesis.station:isValid() then
                    more_nemesis_stations = true
                end
            end
        end
        if not more_nemesis_stations then
            bonus_task_end_clock = getScenarioTime()
        end
    end)
    -- spawn some fighters to chase freighter
    local attack_angle = p.home_station.heading_angle
    local poa_x, poa_y = vectorFromAngleNorth(attack_angle, 3000)
    poa_x = poa_x + psx + station_x
    poa_y = poa_y + psy + station_y
    local fleet_prefix = generateCallSignPrefix()
    p.assist_freighter_marauders = {}
    local lead_ship = CpuShip()
        :setTemplate(ST.ADDER_MK5)
        :setFaction("Kraylor")
        :setCommsScript("")
        :setCommsFunction(commsShip)
        :onDestruction(marauderDestroyed)
    lead_ship
        :setPosition(poa_x, poa_y)
        :setHeading(attack_angle)
        :orderFlyTowards(station_x, station_y)
        :setCallSign(generateCallSign(fleet_prefix))
    table.insert(
        p.assist_freighter_marauders,
        { ship = lead_ship, name = lead_ship:getCallSign() }
    )
    lead_ship.formation_ships = {}
    local forward_formation = {
        { angle = 10, dist = 2500 },
        { angle = 30, dist = 2700 },
        { angle = 350, dist = 2500 },
        { angle = 330, dist = 2700 },
    }
    for i, form in ipairs(forward_formation) do
        local ship = CpuShip()
            :setTemplate(ST.MU52_HORNET)
            :setFaction("Kraylor")
            :setCommsScript("")
            :setCommsFunction(commsShip)
        local form_x, form_y =
            vectorFromAngleNorth(attack_angle + form.angle, form.dist)
        local form_prime_x, form_prime_y =
            vectorFromAngle(form.angle, form.dist)
        ship:setPosition(poa_x + form_x, poa_y + form_y)
            :setHeading(attack_angle)
            :orderFlyFormation(lead_ship, form_prime_x, form_prime_y)
            :setCallSign(generateCallSign(fleet_prefix))
        ship:onDestruction(marauderDestroyed)
        table.insert(
            p.assist_freighter_marauders,
            { ship = ship, name = ship:getCallSign() }
        )
    end
    p:setWeaponStorageMax("Homing", 12)
    p:setWeaponStorage("Homing", 12)
    p:setWeaponStorageMax("Mine", 8)
    p:setWeaponStorage("Mine", 8)
    p:setWeaponStorageMax("EMP", 6)
    p:setWeaponStorage("EMP", 6)
    p:setWeaponStorageMax("Nuke", 4)
    p:setWeaponStorage("Nuke", 4)
    --                            Arc,  Dir, Range, CycleTime, Dmg
    p:setBeamWeapon(0, 100, -20, 1500, 6, 8) -- restore cycle time
    p:setBeamWeapon(1, 100, 20, 1500, 6, 8)
    psx, psy = vectorFromAngleNorth(p.home_station.heading_angle, 103000)
    local wh = WormHole():setPosition(station_x + psx, station_y + psy)
    local rx, ry =
        vectorFromAngleNorth(p.home_station.heading_angle + 180, 13000)
    wh:setTargetPosition(terrain_center_x + rx, terrain_center_y + ry)
    wh:onTeleportation(function(self, teleportee)
        string.format("")
        if isObjectType(teleportee, "PlayerSpaceship") then
            teleportee:setSystemHealth("jumpdrive", -random(0.2, 0.8))
            teleportee:setSystemHealth("beamweapons", -random(0.2, 0.8))
            teleportee:setSystemHealth("missilesystem", -random(0.2, 0.8))
        end
    end)
end
-- Fourth Task: Assist freighter
-- Hurdles: Get parts from station, find freighter, fend off attackers
-- Participants: Helm, science, relay, engineering, weapons
function taskAssistFreighter(p)
    if func_diagnostic then
        print("task assist freighter")
    end
    if p.assist_freighter_message == nil then
        if availableForComms(p) then
            p.assist_freighter_message = "start"
            p.home_station:openCommsTo(p) -- send assist freighter task instructional message
        end
    end
    if p.assist_freighter_start_clock == nil then -- check for non-relay message start triggers
        if p.assist_freighter:isValid() then
            for i, m in ipairs(p.assist_freighter_marauders) do
                if m.ship:isValid() then
                    if distance(p.assist_freighter, m.ship) < 20000 then
                        p.assist_freighter_start_clock = getScenarioTime()
                    end
                end
            end
        end
    else -- task has started, check for completion
        local freighter_part_complete = false
        if p.assist_freighter:isValid() then
            if p.assist_freighter_fixed_clock ~= nil then
                freighter_part_complete = true
            else
                if p.assist_freighter_scanned_clock == nil then
                    if p.assist_freighter:isScannedBy(p) then
                        p.assist_freighter_scanned_clock = getScenarioTime()
                    end
                else
                    if p.assist_freighter_fully_scanned_clock == nil then
                        if p.assist_freighter:isFullyScannedBy(p) then
                            p.assist_freighter_fully_scanned_clock =
                                getScenarioTime()
                        end
                    end
                end
            end
        else
            freighter_part_complete = true -- freighter was destroyed
        end
        local marauder_count = 0
        for i, m in ipairs(p.assist_freighter_marauders) do
            if m.ship:isValid() then
                marauder_count = marauder_count + 1
                break
            end
        end
        if freighter_part_complete and marauder_count == 0 then
            p.assist_freighter_end_clock = getScenarioTime()
            p.task = "completed assist freighter"
            p.assist_freighter_task = "complete"
        end
    end
    if p.assist_freighter_attack_warning == nil then
        if p.assist_freighter_message == "sent" then
            if p.assist_freighter:isValid() then
                for i, m in ipairs(p.assist_freighter_marauders) do
                    if m.ship:isValid() then
                        if distance(p.assist_freighter, m.ship) < 20000 then
                            if availableForComms(p) then
                                p.assist_freighter_attack_warning = "start"
                                p.home_station:openCommsTo(p)
                            end
                        end
                    end
                end
            end
        end
    end
end
function taskCompletedAssistFreighter(p)
    if func_diagnostic then
        print("task completed assist freighter")
    end
    local recorded = false
    for i, eval in ipairs(posthumous) do
        if eval.name == p:getCallSign() then
            if eval.task == "assist freighter" then
                recorded = true
                break
            end
        end
    end
    if not recorded then
        table.insert(posthumous, {
            name = p:getCallSign(),
            task = "assist freighter",
            clock = getScenarioTime(),
            desc = assistFreighterTaskEvaluationOutput(p, "gm"),
        })
    end
    p.orbital_body_research = {}
    table.insert(
        p.orbital_body_research,
        { body = center_blackhole, research = "N" }
    )
    for i, body in pairs(planetList) do
        table.insert(p.orbital_body_research, { body = body, research = "N" })
    end
    p.task = "research"
end
-- Fifth task: Research anomalous planetary orbital behavior
-- Hurdles: Bumping into planets causes severe damage to ship, navigate carefully
-- Participants: Helm, Science, Relay, Engineering
function taskResearch(p)
    if func_diagnostic then
        print("task research")
    end
    if p.research_message == nil then
        if availableForComms(p) then
            p.research_message = "start"
            p.home_station:openCommsTo(p) -- send research task instructional message
        end
    elseif p.research_message == "sent" then
        if p.orbit_research_button_rel == nil then
            p.orbit_research_button_rel = "orbit_research_button_rel"
            p:addCustomButton(
                "Relay",
                p.orbit_research_button_rel,
                "Orbit research",
                function()
                    string.format("")
                    orbitResearch(p)
                end,
                20
            )
            p.orbit_research_button_ops = "orbit_research_button_ops"
            p:addCustomButton(
                "Operations",
                p.orbit_research_button_ops,
                "Orbit research",
                function()
                    string.format("")
                    orbitResearch(p)
                end,
                20
            )
        end
        p:setWarpDrive(true)
        p:setWarpSpeed(1250)
        p.research_message = "no more messages"
    end
    if p.research_start_clock == nil then
        for i, orbit in ipairs(p.orbital_body_research) do
            if orbit.start_scan_clock ~= nil then
                p.research_start_clock = getScenarioTime()
                break
            end
        end
    else -- task started, check for completion conditions
        if p.research_fleet == nil then
            p.research_fleet = {}
            p.research_fleet_clock = getScenarioTime()
        else
            if getScenarioTime() - p.research_fleet_clock > 60 then
                p.research_fleet_clock = getScenarioTime()
                if #p.research_fleet < 5 then
                    local templates = {
                        "MT52 Hornet",
                        "MU52 Hornet",
                        "Ktlitan Fighter",
                        "Ktlitan Scout",
                        "Fighter",
                    }
                    local rx, ry = vectorFromAngleNorth(
                        p.home_station.heading_angle + 180,
                        13000
                    )
                    local sx, sy = p.home_station:getPosition()
                    local ship = CpuShip()
                        :setTemplate(templates[math.random(1, #templates)])
                        :setPosition(
                            terrain_center_x + rx,
                            terrain_center_y + ry
                        )
                        :setFaction("Kraylor")
                        :orderFlyTowards(sx, sy)
                    table.insert(p.research_fleet, ship)
                end
            end
            for i, ship in ipairs(p.research_fleet) do
                if not ship:isValid() then
                    p.research_fleet[i] = p.research_fleet[#p.research_fleet]
                    p.research_fleet[#p.research_fleet] = nil
                    break
                end
            end
        end
        local research_complete = false
        local scan_count = 0
        for i, orbit in ipairs(p.orbital_body_research) do
            if orbit.research == "Y" then
                scan_count = scan_count + 1
            end
            if scan_count > (#p.orbital_body_research / 2) then
                research_complete = true
            end
        end
        if research_complete then
            p.research_end_clock = getScenarioTime()
            p.task = "completed research"
            p.research_task = "complete"
        end
    end
end
function taskCompletedResearch(p)
    if func_diagnostic then
        print("task completed research")
    end
    local recorded = false
    for i, eval in ipairs(posthumous) do
        if eval.name == p:getCallSign() then
            if eval.task == "research" then
                recorded = true
                break
            end
        end
    end
    if not recorded then
        table.insert(posthumous, {
            name = p:getCallSign(),
            task = "research",
            clock = getScenarioTime(),
            desc = researchTaskEvaluationOutput(p, "gm"),
        })
    end
    if p.completed_research_message == nil then
        if availableForComms(p) then
            p.completed_research_message = "sent"
            if p.home_station:isValid() then
                p.home_station:sendCommsMessage(
                    p,
                    string.format(
                        _(
                            "human-incCall",
                            "You completed the research task. Destroy any Kraylor headed for %s"
                        ),
                        p.home_station:getCallSign()
                    )
                )
            else
                p:addToShipLog(
                    _(
                        "goal-shipLog",
                        "You completed the research task. Destroy any Kraylor that were headed for your home base"
                    ),
                    "Magenta"
                )
            end
            if p.home_station:isValid() then
                local nsx, nsy = p.nemesis_station:getPosition()
                local psx, psy =
                    vectorFromAngleNorth(p.home_station.heading_angle, 3000)
                CpuShip()
                    :setTemplate(ST.DEFENSE_PLATFORM)
                    :setFaction("Kraylor")
                    :setPosition(nsx + psx, nsy + psy)
                    :orderStandGround()
                local psx, psy = vectorFromAngleNorth(
                    p.home_station.heading_angle + 120,
                    3000
                )
                CpuShip()
                    :setTemplate(ST.DEFENSE_PLATFORM)
                    :setFaction("Kraylor")
                    :setPosition(nsx + psx, nsy + psy)
                    :orderStandGround()
                local psx, psy = vectorFromAngleNorth(
                    p.home_station.heading_angle + 240,
                    3000
                )
                CpuShip()
                    :setTemplate(ST.DEFENSE_PLATFORM)
                    :setFaction("Kraylor")
                    :setPosition(nsx + psx, nsy + psy)
                    :orderStandGround()
            end
            p.task = "research cleanup"
        end
    end
end
function taskResearchCleanup(p)
    if func_diagnostic then
        print("task research cleanup")
    end
    if #p.research_fleet > 0 then
        for i, ship in ipairs(p.research_fleet) do
            if ship == nil or not ship:isValid() then
                p.research_fleet[i] = p.research_fleet[#p.research_fleet]
                p.research_fleet[#p.research_fleet] = nil
                break
            end
        end
    else
        p:removeCustom(p.orbit_research_button_rel)
        p:removeCustom(p.orbit_research_button_ops)
        if p.completed_research_cleanup_message == nil then
            if availableForComms(p) then
                if p.home_station:isValid() then
                    p.home_station:sendCommsMessage(
                        p,
                        string.format(
                            "The Kraylor gunning for %s have been eliminated. Take the fight to the Kraylor by finding and destroying the station that sent fighters after that defenseless Arlenian freighter. Be careful though. I'm sure the Kraylor will not give up their station easily.",
                            p.home_station:getCallSign()
                        )
                    )
                else
                    p:addToShipLog(
                        "The Kraylor gunning for your home station have been eliminated. Take the fight to the Kraylor by finding and destroying the station that sent fighters after that defenseless Arlenian freighter. Be careful though. I'm sure the Kraylor will not give up their station easily.",
                        "Magenta"
                    )
                end
                p.task = "bonus"
                p.completed_research_cleanup_message = "sent"
            end
        end
    end
end
-- Bonus task: Destroy enemy base
-- Hurdles: Enemy space ships, enemy base is far from primary base
-- Participants: Helm, Weapons, Engineering, Science, Relay
function taskBonus(p)
    if func_diagnostic then
        print("task bonus")
    end
    local bonus_task_complete = true
    local my_nemesis_index = nil
    for i, nemesis in ipairs(nemesis_stations) do
        if p.nemesis_station == nemesis.station then
            my_nemesis_index = i
        end
        if nemesis.station:isValid() then
            bonus_task_complete = false
        end
    end
    local other_players_working_tasks = false
    for index, player in pairs(player_restart) do
        if index ~= "add" then
            local pc = getPlayerShip(index)
            if pc ~= nil and pc:isValid() then
                if
                    pc.research_task == nil
                    or pc.research_task ~= "complete"
                then
                    other_players_working_tasks = true
                    break
                end
            end
        end
    end
    local nem = nemesis_stations[my_nemesis_index]
    if not p.nemesis_station:isValid() then
        if availableForComms(p) then
            if p.home_station:isValid() then
                if bonus_task_complete then
                    if other_players_working_tasks then
                        if p.player_waiting_message == nil then
                            p.home_station:sendCommsMessage(
                                p,
                                "All the Kraylor stations have been destroyed. There are other Human Navy ships working on tasks. Feel free to examine the evaluations on all of your tasks including the bonus task."
                            )
                            p.player_waiting_message = "sent"
                        end
                    else
                        globalMessage(
                            "All tasks complete. All Kraylor stations destroyed."
                        )
                        victory("Human Navy")
                    end
                else
                    if p.bonus_partially_completed_message == nil then
                        p.home_station:sendCommsMessage(
                            p,
                            string.format(
                                "%s, the station that was after the Arlenian freighter has been destroyed. There may be other Kraylor stations outside the nebula ring that you could hunt down and destroy.",
                                nem.name
                            )
                        )
                        p.bonus_partially_completed_message = "sent"
                    end
                end
            else
                if bonus_task_complete then
                    if other_players_working_tasks then
                        if p.player_waiting_message == nil then
                            p:addToShipLog(
                                "All the Kraylor stations have been destroyed. There are other Human Navy ships working on tasks. Feel free to examine the evaluations on all of your tasks including the bonus task.",
                                "Magenta"
                            )
                            p.player_waiting_message = "sent"
                        end
                    else
                        globalMessage(
                            "All tasks complete. All Kraylor stations destroyed."
                        )
                        victory("Human Navy")
                    end
                else
                    if p.bonus_partially_completed_message == nil then
                        p:addToShipLog(
                            string.format(
                                "%s, the station that was after the Arlenian freighter has been destroyed. There may be other Kraylor stations outside the nebula ring that you could hunt down and destroy.",
                                nem.name
                            ),
                            "Magenta"
                        )
                        p.bonus_partially_completed_message = "sent"
                    end
                end
            end
        end
    end
end

function orbitResearch(p)
    if func_diagnostic then
        print("orbit research")
    end
    table.sort(p.orbital_body_research, function(a, b)
        return a.research < b.research
            or (
                a.research == b.research
                and a.body:getCallSign() < b.body:getCallSign()
            )
    end)
    local out = ""
    local completed_count = 0
    local incomplete_count = 0
    for i, orbit in ipairs(p.orbital_body_research) do
        out = string.format(
            "%s\n%s %s",
            out,
            orbit.research,
            orbit.body:getCallSign()
        )
        if orbit.start_scan_clock ~= nil then
            out = string.format(
                _("msgRelay&Operations", "%s   Scan started at %.1f"),
                out,
                orbit.start_scan_clock
            )
        end
        if orbit.research == "Y" then
            completed_count = completed_count + 1
        else
            incomplete_count = incomplete_count + 1
        end
    end
    out = string.format(
        _(
            "msgRelay&Operations",
            "Orbital body researched status:\nCompleted: %s     Remaining: %s\n%s"
        ),
        completed_count,
        incomplete_count,
        out
    )
    if p.task == "research cleanup" then
        if #p.research_fleet > 0 then
            local hunter_out = _("msgRelay&Operations", "Enemy ships hunting")
            if p.home_station ~= nil and p.home_station:isValid() then
                hunter_out = string.format(
                    _("msgRelay&Operations", "%s for %s:"),
                    hunter_out,
                    p.home_station:getCallSign()
                )
            else
                hunter_out = string.format("%s:", hunter_out)
            end
            for i, ship in ipairs(p.research_fleet) do
                if ship ~= nil and ship:isValid() then
                    hunter_out = string.format(
                        _("msgRelay&Operations", "%s\n   %s in %s"),
                        hunter_out,
                        ship:getCallSign(),
                        ship:getSectorName()
                    )
                end
            end
            out = string.format("%s\n%s", hunter_out, out)
        end
    end
    p.orbit_research_status_message_rel = "orbit_research_status_message_rel"
    p:addCustomMessage("Relay", p.orbit_research_status_message_rel, out)
    p.orbit_research_status_message_ops = "orbit_research_status_message_ops"
    p:addCustomMessage("Operations", p.orbit_research_status_message_ops, out)
end
function enableDock(p)
    if func_diagnostic then
        print("enable dock")
    end
    if
        p.dock_shield_frequency == p:getShieldsFrequency()
        and p.dock_beam_frequency == p:getBeamFrequency()
        and p:getSystemPower("missilesystem") <= 0
    then
        p:setCanDock(true)
    else
        p:setCanDock(false)
    end
end
function trackFreighterScans(p)
    if func_diagnostic then
        print("track freighter scans")
    end
    if p.scan_targets ~= nil then
        for i, scan_target in ipairs(p.scan_targets) do
            if scan_target.ship:isValid() then
                if scan_target.single_scan_clock == nil then
                    if scan_target.ship:isScannedBy(p) then
                        scan_target.single_scan_clock = getScenarioTime()
                    end
                end
                if scan_target.full_scan_clock == nil then
                    if scan_target.ship:isFullyScannedBy(p) then
                        scan_target.full_scan_clock = getScenarioTime()
                    end
                end
            end
        end
    end
end
function rotateAlliedStations(delta)
    if func_diagnostic then
        print("rotate allied stations")
    end
    for i, station in ipairs(allied_stations) do
        if station:isValid() then
            station:setRotation((station:getRotation() + 0.03) % 360)
        end
    end
end
function nemesisMaintenance(p)
    if func_diagnostic then
        print("nemesis maintenance")
    end
    if nemesis_stations ~= nil then
        for i, nemesis in ipairs(nemesis_stations) do
            if nemesis.station:isValid() then
                local station = nemesis.station
                if distance(p, station) < 20000 then
                    local sx, sy = station:getPosition()
                    local fleet = nil
                    if station.defense_fleet == nil then
                        if p.nemesis_danger == nil then
                            p.nemesis_danger = 1
                        end
                        fleet =
                            spawnEnemies(sx, sy, p.nemesis_danger, "Kraylor")
                        p.nemesis_danger = p.nemesis_danger + random(0, 1)
                        nemesis.defense_ship_spawn_count = nemesis.defense_ship_spawn_count
                            + #fleet
                        station.defense_fleet = {}
                        for j, ship in ipairs(fleet) do
                            ship:orderDefendTarget(station)
                            table.insert(station.defense_fleet, ship)
                            local selected_template = ship:getTypeName()
                            nemesis.defense_spawn_strength = nemesis.defense_spawn_strength
                                + ship_template[selected_template].strength
                            ship.nemesis_index = i
                            ship:onDestruction(function(self, instigator)
                                string.format("")
                                nemesis_stations[self.nemesis_index].defense_ship_destroyed_count = nemesis_stations[self.nemesis_index].defense_ship_destroyed_count
                                    + 1
                                local selected_template = self:getTypeName()
                                nemesis_stations[self.nemesis_index].defense_ship_destroyed_strength = nemesis_stations[self.nemesis_index].defense_ship_destroyed_strength
                                    + ship_template[selected_template].strength
                            end)
                        end
                        station.defense_fleet_spawn_clock = getScenarioTime()
                    else
                        local purged = nil
                        repeat
                            purged = true
                            for i = 1, #station.defense_fleet do
                                if not station.defense_fleet[i]:isValid() then
                                    station.defense_fleet[i] =
                                        station.defense_fleet[#station.defense_fleet]
                                    station.defense_fleet[#station.defense_fleet] =
                                        nil
                                    purged = false
                                    break
                                end
                            end
                        until purged
                        if
                            getScenarioTime()
                                - station.defense_fleet_spawn_clock
                            > 60
                        then
                            if #station.defense_fleet > 0 then
                                if random(1, 100) < 7 then
                                    fleet = spawnEnemies(
                                        sx,
                                        sy,
                                        random(0.3, 1),
                                        "Kraylor"
                                    )
                                    nemesis.defense_ship_spawn_count = nemesis.defense_ship_spawn_count
                                        + #fleet
                                    for i, ship in ipairs(fleet) do
                                        ship:orderDefendTarget(station)
                                        table.insert(
                                            station.defense_fleet,
                                            ship
                                        )
                                        local selected_template =
                                            ship:getTypeName()
                                        nemesis.defense_spawn_strength = nemesis.defense_spawn_strength
                                            + ship_template[selected_template].strength
                                        ship.nemesis_index = i
                                        ship:onDestruction(
                                            function(self, instigator)
                                                string.format("")
                                                nemesis_stations[self.nemesis_index].defense_ship_destroyed_count = nemesis_stations[self.nemesis_index].defense_ship_destroyed_count
                                                    + 1
                                                local selected_template =
                                                    self:getTypeName()
                                                nemesis_stations[self.nemesis_index].defense_ship_destroyed_strength = nemesis_stations[self.nemesis_index].defense_ship_destroyed_strength
                                                    + ship_template[selected_template].strength
                                            end
                                        )
                                    end
                                end
                            else
                                if random(1, 100) < 87 then
                                    fleet = spawnEnemies(
                                        sx,
                                        sy,
                                        random(0.6, 1),
                                        "Kraylor"
                                    )
                                    nemesis.defense_ship_spawn_count = nemesis.defense_ship_spawn_count
                                        + #fleet
                                    for i, ship in ipairs(fleet) do
                                        ship:orderDefendTarget(station)
                                        table.insert(
                                            station.defense_fleet,
                                            ship
                                        )
                                        local selected_template =
                                            ship:getTypeName()
                                        nemesis.defense_spawn_strength = nemesis.defense_spawn_strength
                                            + ship_template[selected_template].strength
                                        ship.nemesis_index = i
                                        ship:onDestruction(
                                            function(self, instigator)
                                                string.format("")
                                                nemesis_stations[self.nemesis_index].defense_ship_destroyed_count = nemesis_stations[self.nemesis_index].defense_ship_destroyed_count
                                                    + 1
                                                local selected_template =
                                                    self:getTypeName()
                                                nemesis_stations[self.nemesis_index].defense_ship_destroyed_strength = nemesis_stations[self.nemesis_index].defense_ship_destroyed_strength
                                                    + ship_template[selected_template].strength
                                            end
                                        )
                                    end
                                end
                            end
                            station.defense_fleet_spawn_clock =
                                getScenarioTime()
                        end
                    end
                end
            end
        end
    end
end
function transportMaintenance()
    if func_diagnostic then
        print("transport maintenance")
    end
    for i, ship in ipairs(transportList) do
        local set_dock_destination = false
        if ship:isValid() then
            local docked_station = ship:getDockedWith()
            if docked_station ~= nil then
                if ship.undock_delay == nil then
                    ship.undock_delay = getScenarioTime() + random(5, 10)
                else
                    if getScenarioTime() > ship.undock_delay then
                        set_dock_destination = true
                    end
                end
            end
            if string.find(ship:getOrder(), "Dock") then
                if not ship:getOrderTarget():isValid() then
                    set_dock_destination = true
                end
            else
                set_dock_destination = true
            end
            if set_dock_destination then
                local all_stations_valid = true
                local dock_candidates = {}
                for j, station in ipairs(stationList) do
                    if station:isValid() then
                        if station ~= docked_station then
                            table.insert(dock_candidates, {
                                station = station,
                                dist = distance(ship, station),
                            })
                        end
                    else
                        stationList[j] = stationList[#stationList]
                        stationList[#stationList] = nil
                        all_stations_valid = false
                        break
                    end
                end
                if all_stations_valid then
                    if #dock_candidates > 0 then
                        table.sort(dock_candidates, function(a, b)
                            return a.dist < b.dist
                        end)
                        ship:orderDock(
                            dock_candidates[math.random(
                                1,
                                math.min(5, #dock_candidates)
                            )].station
                        )
                        ship.undock_delay = nil
                    end
                end
            end
        else
            transportList[i] = transportList[#transportList]
            transportList[#transportList] = nil
            break
        end
    end
end

function update(delta)
    if func_diagnostic then
        print("update")
    end
    if delta == 0 then
        --game paused
        for pidx = 1, 32 do
            local p = getPlayerShip(pidx)
            if p ~= nil and p:isValid() then
                if p.pidx == nil then
                    p.pidx = pidx
                    identifyPlayerShip(p, true)
                end
            end
        end
        return --skip unpaused functions
    end
    if post_pause_initialization == nil then
        game_state = "post pause initialization"
        if mainGMButtons == mainGMButtonsDuringPause then --switch GM buttons
            mainGMButtons = mainGMButtonsAfterPause
            mainGMButtons()
        end
        if trainee_player_count == nil then --count trainee ships
            trainee_player_count = 0
            for pidx = 1, 32 do
                local p = getPlayerShip(pidx)
                if p ~= nil and p:isValid() then
                    trainee_player_count = trainee_player_count + 1
                end
            end
        end
        setOrbitalSpeeds() --uses default values or those set by GM buttons while paused
        createEnvironment() --depends on set orbital speeds function
        post_pause_initialization = "done"
        game_state = "running"
    end
    local valid_players = 0
    for pidx = 1, 32 do
        local p = getPlayerShip(pidx)
        if p ~= nil then
            if p:isValid() then
                valid_players = valid_players + 1
                if p.pidx == nil then --if player ship not identified (spawn/respawn)
                    p.pidx = pidx
                    identifyPlayerShip(p, false)
                end
                if p.start_x == nil then --if player ship not placed (spawn/respawn)
                    if pidx > trainee_player_count then --place trainer
                        local angle = random(0, 360)
                        if
                            player_restart[pidx] ~= nil
                            and player_restart[pidx].start_x ~= nil
                        then
                            p.start_x = player_restart[pidx].start_x
                            p.start_y = player_restart[pidx].start_y
                            p.angle = player_restart[pidx].angle
                            angle = p.angle
                        else
                            local psx, psy = vectorFromAngle(angle, 100000)
                            p.start_x = terrain_center_x + psx
                            p.start_y = terrain_center_y + psy
                            p.angle = angle
                            player_restart.add(
                                pidx,
                                nil,
                                nil,
                                p.start_x,
                                p.start_y,
                                p.angle
                            )
                            if pirate_reputation == nil then
                                p:addReputationPoints(50)
                                pirate_reputation = "provided"
                            end
                        end
                        local tra = angle + 180
                        if tra > 360 then
                            tra = tra - 360
                        end
                        p:commandTargetRotation(tra)
                        local ha = angle + 270
                        if ha > 360 then
                            ha = ha - 360
                        end
                        p:setHeading(ha)
                        p:setPosition(p.start_x, p.start_y)
                    else --place trainee
                        if players_positioned == nil then
                            placeTraineePlayerShipsAndStations() --determine and set player initial positions
                            players_positioned = true
                        else --start trainee back at starting location
                            p.start_x = player_restart[pidx].start_x
                            p.start_y = player_restart[pidx].start_y
                            p:setPosition(p.start_x, p.start_y)
                            p.angle = player_restart[pidx].angle
                            angle = p.angle
                            tra = angle + 180
                            if tra > 360 then
                                tra = tra - 360
                            end
                            p:commandTargetRotation(tra)
                            ha = angle + 270
                            if ha > 360 then
                                ha = ha - 360
                            end
                            p:setHeading(ha)
                            if player_restart[pidx].restart_count == nil then
                                player_restart[pidx].restart_count = 0
                            end
                            player_restart[pidx].restart_count = player_restart[pidx].restart_count
                                + 1
                        end
                    end
                else
                    playerTask(p)
                    enableDock(p)
                    trackFreighterScans(p)
                    blackHoleResearch(p)
                    nemesisMaintenance(p)
                end
            end
        end
    end
    rotateAlliedStations(delta)
    transportMaintenance()
    local player_count = 0
    for p, details in pairs(player_restart) do
        player_count = player_count + 1
    end
    player_count = player_count - 1 --subtract 1 for add function in table
    if valid_players < player_count then --count is short, respawn destroyed player
        local respawned_player = PlayerSpaceship()
        identifyPlayerShip(respawned_player, false)
        local pidx = respawned_player.pidx
        respawned_player:setPosition(
            player_restart[pidx].start_x,
            player_restart[pidx].start_y
        )
    end
    planetCollisionDetection()
end
