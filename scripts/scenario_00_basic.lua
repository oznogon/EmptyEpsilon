-- Name: Basic Battle
-- Type: Basic
--
-- Setting[Enemies]: Configures the amount of enemies spawned in the scenario.
-- Enemies[Empty]: No enemies. Recommended for GM-controlled scenarios and rookie crew orientation. The scenario continues until the GM declares victory or all Human Navy ships are destroyed.
-- Enemies[Easy]: Fewer enemies. Recommended for inexperienced crews.
-- Enemies[Normal|Default]: Normal amount of enemies. Recommended for a normal crew.
-- Enemies[Hard]: More enemies. Recommended if you have multiple player-controlled ships.
-- Enemies[Extreme]: Many enemies. Inexperienced player crews will pretty surely be overwhelmed.
--
-- Setting[Time]: Sets up how much time the players have for the scenario
-- Time[Unlimited|Default]: No time limit
-- Time[20min]: Automatic loss after 20 minutes
-- Time[30min]: Automatic loss after 30 minutes
-- Time[60min]: Automatic loss after 60 minutes
-- Setting[PlayerShip]: Sets the default player ship
-- PlayerShip[Atlantis|Default]: Powerful ship with sidewards missile tubes. Requires more advanced play.
-- PlayerShip[Phobos M3P]: Simpler, less powerful ship. But easier to handle. Recommended for new crews.
--
-- Description: A few random stations are under attack by enemies, with random terrain around them. Destroy all enemies to win.
---
--- The scenario provides a single player-controlled Atlantis, which is sufficient to win even in the "Extreme" variant.
---
--- Other player ships can be spawned, but the strength of enemy ships is independent of the number and types of player ships.

--- Basic Battle scenario 00 for EmptyEpsilon
-- @script scenario_00_basic
-- @author daid (primary)
-- @author capt-t
-- @author hemmond
-- @author muerteFR
-- @author aBlueShadow
-- @author GinjaNinja32
-- @author oznogon
-- @license GPLv2
-- @release fork-dev-20261125

require("utils.lua")
-- For this scenario, utils.lua provides:
--   vectorFromAngle(angle, length)
--      Returns a relative vector (x, y coordinates)
--   setCirclePos(obj, x, y, angle, distance)
--      Returns the object with its position set to the resulting coordinates.
--   distance(a, b, c, d)
--      Returns the distance between two objects/coordinates
--   angleRotation(a, b, c, d)
--      Returns the bearing between first object/coordinate and second object/coordinate.

-- Global variables for this scenario
local enemy_list
local friendly_list
local station_list
local player_list
local add_waves_to_GM_position -- If set to true, add wave will require GM to click on the map to position, where the wave should be spawned.

local game_time_remaining = nil -- Maximum game time in seconds.
local time_warning = nil -- Used for checking when to give a warning, and to update it so the warning happens once.

--- List of generic player ship names, selected from at random for new player ships
local ship_names = {
    "SS Epsilon",
    "Ironic Gentleman",
    "Binary Sunset",
    "USS Roddenberry",
    "Earthship Sagan",
    "Explorer",
    "ISV Phantom",
    "Keelhaul",
    "Peacekeeper",
    "WarMonger",
    "Death Bringer",
    "Executor",
    "Excaliber",
    "Voyager",
    "Khan's Wrath",
    "Kronos' Savior",
    "HMS Captor",
    "Imperial Stature",
    "ESS Hellfire",
    "Helen's Fury",
    "Venus' Light",
    "Blackbeard's Way",
    "ISV Monitor",
    "Argent",
    "Echo One",
    "Earth's Might",
    "ESS Tomahawk",
    "Sabretooth",
    "Hiro-maru",
    "USS Nimoy",
    "Earthship Tyson",
    "Destiny's Tear",
    "HMS SuperNova",
    "Alma del Terra",
    "DreadHeart",
    "Devil's Maw",
    "Cougar's Claw",
    "Blood-oath",
    "Imperial Fist",
    "HMS Promise",
    "ESS Catalyst",
    "Hercules Ascendant",
    "Heavens Mercy",
    "HMS Adams",
    "Explorer",
    "Discovery",
    "Stratosphere",
    "USS Kelly",
    "HMS Honour",
    "Devilfish",
    "Minnow",
    "Earthship Nye",
    "Starcruiser Solo",
    "Starcruiser Reynolds",
    "Starcruiser Hunt",
    "Starcruiser Lipinski",
    "Starcruiser Tylor",
    "Starcruiser Kato",
    "Starcruiser Picard",
    "Starcruiser Janeway",
    "Starcruiser Archer",
    "Starcruiser Sisko",
    "Starcruiser Kirk",
    "Aluminum Falcon",
    "SS Essess",
    "Jenny",
}

--- Wrapper function to spawn an enemy wave.
--
-- This wrapper calls either @{addWaveInner} directly (when using random wave positioning)
-- or after @{onGMClick} (when using GM wave positioning).
--
-- @tparam table list A table containing enemy ship objects.
-- @tparam integer kind A number; at each integer, determines which wave of ships to add
--  to the list. Any number is valid, but only 0.99-9.0 are meaningful.
-- @tparam number a The spawned wave's heading relative to the players' spawn point (ignored when using GM positioning).
-- @tparam number d The spawned wave's distance from the players' spawn point (ignored when using GM positioning).
function addWave(list, kind, a, d)
    if add_waves_to_GM_position then
        onGMClick(function(x, y)
            onGMClick(nil)
            addWaveInner(
                list,
                kind,
                angleRotation(0, 0, x, y),
                distance(0, 0, x, y)
            )
        end)
    else
        addWaveInner(list, kind, a, d)
    end
end

--- Spawns an enemy wave.
--
-- Creates an enemy wave and adds all of its ships to `list`.
--
-- @tparam table list A table containing enemy ship objects.
-- @tparam integer kind A number; at each integer, determines which wave of ships to add
--  to the list. Any number is valid, but only 0.99-9.0 are meaningful.
-- @tparam number a The spawned wave's heading relative to the players' spawn point.
-- @tparam number d The spawned wave's distance from the players' spawn point.
function addWaveInner(list, kind, a, d)
    if kind < 1.0 then
        table.insert(
            list,
            setCirclePos(
                CpuShip()
                    :setTemplate(ST.STALKER_Q7)
                    :setRotation(a + 180)
                    :orderRoaming(),
                0,
                0,
                a,
                d
            )
        )
    elseif kind < 2.0 then
        local leader = setCirclePos(
            CpuShip()
                :setTemplate(ST.PHOBOS_T3)
                :setRotation(a + 180)
                :orderRoaming(),
            0,
            0,
            a + random(-1, 1),
            d + random(-100, 100)
        )
        table.insert(list, leader)
        table.insert(
            list,
            setCirclePos(
                CpuShip()
                    :setTemplate(ST.MT52_HORNET)
                    :setRotation(a + 180)
                    :orderFlyFormation(leader, -400, 0),
                0,
                0,
                a + random(-1, 1),
                d + random(-100, 100)
            )
        )
        table.insert(
            list,
            setCirclePos(
                CpuShip()
                    :setTemplate(ST.MT52_HORNET)
                    :setRotation(a + 180)
                    :orderFlyFormation(leader, 400, 0),
                0,
                0,
                a + random(-1, 1),
                d + random(-100, 100)
            )
        )
        table.insert(
            list,
            setCirclePos(
                CpuShip()
                    :setTemplate(ST.MT52_HORNET)
                    :setRotation(a + 180)
                    :orderFlyFormation(leader, -400, 400),
                0,
                0,
                a + random(-1, 1),
                d + random(-100, 100)
            )
        )
        table.insert(
            list,
            setCirclePos(
                CpuShip()
                    :setTemplate(ST.MT52_HORNET)
                    :setRotation(a + 180)
                    :orderFlyFormation(leader, 400, 400),
                0,
                0,
                a + random(-1, 1),
                d + random(-100, 100)
            )
        )
    elseif kind < 3.0 then
        table.insert(
            list,
            setCirclePos(
                CpuShip()
                    :setTemplate(ST.ADDER_MK5)
                    :setRotation(a + 180)
                    :orderRoaming(),
                0,
                0,
                a + random(-5, 5),
                d + random(-100, 100)
            )
        )
        table.insert(
            list,
            setCirclePos(
                CpuShip()
                    :setTemplate(ST.ADDER_MK5)
                    :setRotation(a + 180)
                    :orderRoaming(),
                0,
                0,
                a + random(-5, 5),
                d + random(-100, 100)
            )
        )
    elseif kind < 4.0 then
        table.insert(
            list,
            setCirclePos(
                CpuShip()
                    :setTemplate(ST.PHOBOS_T3)
                    :setRotation(a + 180)
                    :orderRoaming(),
                0,
                0,
                a + random(-5, 5),
                d + random(-100, 100)
            )
        )
        table.insert(
            list,
            setCirclePos(
                CpuShip()
                    :setTemplate(ST.PHOBOS_T3)
                    :setRotation(a + 180)
                    :orderRoaming(),
                0,
                0,
                a + random(-5, 5),
                d + random(-100, 100)
            )
        )
        table.insert(
            list,
            setCirclePos(
                CpuShip()
                    :setTemplate(ST.PHOBOS_T3)
                    :setRotation(a + 180)
                    :orderRoaming(),
                0,
                0,
                a + random(-5, 5),
                d + random(-100, 100)
            )
        )
    elseif kind < 5.0 then
        table.insert(
            list,
            setCirclePos(
                CpuShip()
                    :setTemplate(ST.PHOBOS_T3)
                    :setRotation(a + 180)
                    :orderRoaming(),
                0,
                0,
                a + random(-5, 5),
                d + random(-100, 100)
            )
        )
    elseif kind < 6.0 then
        local leader = setCirclePos(
            CpuShip()
                :setTemplate(ST.PIRANHA_F12)
                :setRotation(a + 180)
                :orderRoaming(),
            0,
            0,
            a + random(-5, 5),
            d + random(-100, 100)
        )
        table.insert(list, leader)
        table.insert(
            list,
            setCirclePos(
                CpuShip()
                    :setTemplate(ST.MT52_HORNET)
                    :setRotation(a + 180)
                    :orderFlyFormation(leader, -1500, 400),
                0,
                0,
                a + random(-1, 1),
                d + random(-100, 100)
            )
        )
        table.insert(
            list,
            setCirclePos(
                CpuShip()
                    :setTemplate(ST.MT52_HORNET)
                    :setRotation(a + 180)
                    :orderFlyFormation(leader, 1500, 400),
                0,
                0,
                a + random(-1, 1),
                d + random(-100, 100)
            )
        )
    elseif kind < 7.0 then
        table.insert(
            list,
            setCirclePos(
                CpuShip()
                    :setTemplate(ST.MT52_HORNET)
                    :setRotation(a + 180)
                    :orderRoaming(),
                0,
                0,
                a + random(-5, 5),
                d + random(-100, 100)
            )
        )
        table.insert(
            list,
            setCirclePos(
                CpuShip()
                    :setTemplate(ST.PHOBOS_T3)
                    :setRotation(a + 180)
                    :orderRoaming(),
                0,
                0,
                a + random(-5, 5),
                d + random(-100, 100)
            )
        )
    elseif kind < 8.0 then
        table.insert(
            list,
            setCirclePos(
                CpuShip()
                    :setTemplate(ST.NIRVANA_R5)
                    :setRotation(a + 180)
                    :orderRoaming(),
                0,
                0,
                a + random(-5, 5),
                d + random(-100, 100)
            )
        )
    elseif kind < 9.0 then
        table.insert(
            list,
            setCirclePos(
                CpuShip()
                    :setTemplate(ST.MU52_HORNET)
                    :setRotation(a + 180)
                    :orderRoaming(),
                0,
                0,
                a + random(-5, 5),
                d + random(-100, 100)
            )
        )
    else
        table.insert(
            list,
            setCirclePos(
                CpuShip()
                    :setTemplate(ST.STALKER_R7)
                    :setRotation(a + 180)
                    :orderRoaming(),
                0,
                0,
                a + random(-5, 5),
                d + random(-100, 100)
            )
        )
        table.insert(
            list,
            setCirclePos(
                CpuShip()
                    :setTemplate(ST.STALKER_R7)
                    :setRotation(a + 180)
                    :orderRoaming(),
                0,
                0,
                a + random(-5, 5),
                d + random(-100, 100)
            )
        )
    end
end

--- Returns a semi-random heading for a wave of ships.
--
-- @tparam number cnt A counter, generally between 1 and the number of enemy groups.
-- @tparam number enemy_group_count A number of enemy groups, generally set by the scenario variation.
-- @treturn number A random angle between 0-60 and 360+60
function randomWaveAngle(cnt, enemy_group_count)
    return cnt * 360 / enemy_group_count + random(-60, 60)
end

--- Returns a semi-random distance for a wave of ships.
--
-- `enemy_group_count` is multiplied by 3u and increases the distance.
--
-- @tparam number enemy_group_count A number of enemy groups, generally set by the scenario variation.
-- @treturn number The random distance.
function randomWaveDistance(enemy_group_count)
    return random(35000, 40000 + enemy_group_count * 3000)
end

--- Initializes the main GM Menu.
function gmButtons()
    clearGMFunctions()
    addGMFunction(_("buttonGM", "+Named waves"), namedWaves)
    addGMFunction(_("buttonGM", "Random wave"), function()
        addWave(
            enemy_list,
            random(0, 10),
            randomWaveAngle(math.random(20), math.random(20)),
            randomWaveDistance(math.random(20))
        )
    end)

    -- Let the GM spawn random reinforcements. Their distance from the
    -- players' spawn point is about half that of enemy waves.
    addGMFunction(_("buttonGM", "Random friendly"), function()
        local friendly_ship = {
            ST.PHOBOS_T3,
            ST.MU52_HORNET,
            ST.PIRANHA_F12
        }
        local friendly_ship_index = math.random(#friendly_ship)

        if add_waves_to_GM_position then
            onGMClick(function(x, y)
                onGMClick(nil)
                local a = angleRotation(0, 0, x, y)
                local d = distance(0, 0, x, y)
                table.insert(
                    friendly_list,
                    setCirclePos(
                        CpuShip()
                            :setTemplate(friendly_ship[friendly_ship_index])
                            :setRotation(a)
                            :setFaction("Human Navy")
                            :orderRoaming()
                            :setScanned(true),
                        0,
                        0,
                        a + random(-5, 5),
                        d + random(-100, 100)
                    )
                )
            end)
        else
            local a = randomWaveAngle(math.random(20), math.random(20))
            local d = random(15000, 20000 + math.random(20) * 1500)
            table.insert(
                friendly_list,
                setCirclePos(
                    CpuShip()
                        :setTemplate(friendly_ship[friendly_ship_index])
                        :setRotation(a)
                        :setFaction("Human Navy")
                        :orderRoaming()
                        :setScanned(true),
                    0,
                    0,
                    a + random(-5, 5),
                    d + random(-100, 100)
                )
            )
        end
    end)

    addGMPositionToggle()

    -- End scenario with Human Navy (players) victorious.
    addGMFunction(_("buttonGM", "Win"), gmVictoryYesNo)
end

--- Shows a Yes/No question dialog GM submenu to ask if the Human Navy faction should win.
function gmVictoryYesNo()
    clearGMFunctions()
    addGMFunction(_("buttonGM", "Victory?"), function()
        string.format("")
    end)
    addGMFunction(_("buttonGM", "Yes"), function()
        victory("Human Navy")
        clearGMFunctions()
        addGMMessage(_(
            "msgGM",
            [[Players have won.
Scenario ended.]]
        ))
    end)
    addGMFunction(_("buttonGM", "No"), gmButtons)
end

--- Generates a GM toggle button to change how waves are positioned.
function addGMPositionToggle()
    local name = _("buttonGM", "Position: ")

    if add_waves_to_GM_position then
        name = name .. _("buttonGM", "GM")
    else
        name = name .. _("buttonGM", "Random")
    end

    addGMFunction(name, function()
        string.format("") -- Provides global context for SeriousProton
        add_waves_to_GM_position = not add_waves_to_GM_position
        gmButtons()
    end)
end

--- Shows the "Named waves" GM submenu, which contains tools to spawn more waves.
function namedWaves()
    local wave_names = {
        [0] = _("buttonGM", ST.STRIX),
        [1] = _("buttonGM", ST.RIPOSTE),
        [2] = _("buttonGM", ST.GUNSHIP),
        [4] = _("buttonGM", ST.DREADNOUGHT),
        [5] = _("buttonGM", ST.POLARIS),
        [6] = _("buttonGM", ST.KARNACK_MK2), --
        [9] = _("buttonGM", ST.MAGPIE), --
    }
    clearGMFunctions()
    addGMFunction(_("buttonGM", "-From named waves"), gmButtons)
    for index, name in pairs(wave_names) do
        addGMFunction(name, function()
            string.format("")
            addWave(
                enemy_list,
                index,
                randomWaveAngle(math.random(20), math.random(20)),
                randomWaveDistance(math.random(5))
            )
        end)
    end
end

--- Initializes the scenario (invoked at scenario start).
function init()
    -- Spawn a player Atlantis.
    player = PlayerSpaceship()
        :setFaction("Human Navy")
        :setTemplate(getScenarioSetting("PlayerShip"))
        :setCallSign(ship_names[irandom(1, #ship_names)])
    if not player:hasWarpDrive() and not player:hasJumpDrive() then
        player:setWarpDrive(true)
    end

    enemy_list = {}
    friendly_list = {}
    station_list = {}
    player_list = { player }

    onNewPlayerShip(function(ship)
        table.insert(player_list, ship)
    end)

    add_waves_to_GM_position = false

    -- Randomly distribute 3 allied stations throughout the region.
    local n = 0
    -- station_X.comms_data are not yet used, it is here for time when Defense Fleet functionality is implemented to comms_station.lua
    station_1 = SpaceStation()
        :setTemplate(ST.SMALL_STATION)
        :setRotation(random(0, 360))
        :setFaction("Human Navy")
    setCirclePos(
        station_1,
        0,
        0,
        n * 360 / 3 + random(-30, 30),
        random(10000, 22000)
    )
    station_1.comms_data = {
        idle_defense_fleet = {
            DF1 = ST.MT52_HORNET,
            DF2 = ST.MT52_HORNET,
            DF3 = ST.MT52_HORNET,
        },
    }
    table.insert(station_list, station_1)
    table.insert(friendly_list, station_1)
    n = 1
    station_2 = SpaceStation()
        :setTemplate(ST.MEDIUM_STATION)
        :setRotation(random(0, 360))
        :setFaction("Human Navy")
    setCirclePos(
        station_2,
        0,
        0,
        n * 360 / 3 + random(-30, 30),
        random(10000, 22000)
    )
    station_2.comms_data = {
        idle_defense_fleet = {
            DF1 = ST.ADDER_MK5,
            DF2 = ST.ADDER_MK5,
            DF3 = ST.ADDER_MK5,
        },
    }
    table.insert(station_list, station_2)
    table.insert(friendly_list, station_2)
    n = 2
    station_3 = SpaceStation()
        :setTemplate(ST.LARGE_STATION)
        :setRotation(random(0, 360))
        :setFaction("Human Navy")
    setCirclePos(
        station_3,
        0,
        0,
        n * 360 / 3 + random(-30, 30),
        random(10000, 22000)
    )
    station_3.comms_data = {
        idle_defense_fleet = {
            DF1 = ST.PHOBOS_T3,
            DF2 = ST.PHOBOS_T3,
            DF3 = ST.PHOBOS_T3,
        },
    }
    table.insert(station_list, station_3)
    table.insert(friendly_list, station_3)

    -- Start the players with 300 reputation.
    friendly_list[1]:addReputationPoints(300.0)

    -- Spawn a random black hole, avoiding the player's starting position and stations.
    local bh_x, bh_y
    local spawn_hole = false
    local bh_attempts = 0
    while not spawn_hole and bh_attempts < 100 do
        bh_attempts = bh_attempts + 1
        local a = random(0, 360)
        local d = random(10000, 45000)
        bh_x, bh_y = vectorFromAngle(a, d)

        spawn_hole = true
        if distance(0, 0, bh_x, bh_y) < 5000 then
            spawn_hole = false
        end
        if spawn_hole then
            for _, station in ipairs(station_list) do
                if distance(station, bh_x, bh_y) < 5000 then
                    spawn_hole = false
                    break
                end
            end
        end
    end
    local black_hole
    if spawn_hole then
        black_hole = BlackHole():setPosition(bh_x, bh_y)
    end

    -- Randomly scatter nebulae near the players' spawn point.
    local cx, cy = friendly_list[1]:getPosition()
    local ndx, ndy = vectorFromAngle(random(0, 360), 6000)
    if
        not (
            black_hole
            and black_hole:isValid()
            and distance(bh_x, bh_y, cx + ndx, cy + ndy) < 5000
        )
    then
        Nebula():setPosition(cx + ndx, cy + ndy)
    end

    for idx = 1, 5 do
        local ndx, ndy = vectorFromAngle(random(0, 360), random(20000, 45000))
        if
            not (
                black_hole
                and black_hole:isValid()
                and distance(bh_x, bh_y, ndx, ndy) < 5000
            )
        then
            Nebula():setPosition(ndx, ndy)
        end
    end
    gmButtons()

    -- Set the number of enemy waves based on the scenario variation.
    local counts = {
        ["Extreme"] = 20,
        ["Hard"] = 8,
        ["Normal"] = 5,
        ["Easy"] = 3,
        ["Empty"] = 0,
    }
    local enemy_group_count = counts[getScenarioSetting("Enemies")]
    assert(
        enemy_group_count,
        "unknown enemies setting: "
            .. getScenarioSetting("Enemies")
            .. " could not set enemy_group_count"
    )

    local time_setting = {
        ["Unlimited"] = nil,
        ["20min"] = 20 * 60,
        ["30min"] = 30 * 60,
        ["60min"] = 60 * 60,
    }
    game_time_remaining = time_setting[getScenarioSetting("Time")]
    if game_time_remaining ~= nil then
        time_warning = game_time_remaining - 5 * 60
    end

    -- If not in the Empty variation, spawn the corresponding number of random
    -- enemy waves at distributed random headings and semi-random distances
    -- relative to the players' spawn point.
    for cnt = 1, enemy_group_count do
        local a = randomWaveAngle(cnt, enemy_group_count)
        local d = randomWaveDistance(enemy_group_count)
        local kind = random(0, 10)
        addWaveInner(enemy_list, kind, a, d)
    end

    -- Reposition any enemies that spawned within 5U of the black hole.
    if black_hole and black_hole:isValid() then
        for _, enemy in ipairs(enemy_list) do
            if enemy:isValid() then
                local ex, ey = enemy:getPosition()
                if distance(bh_x, bh_y, ex, ey) < 5000 then
                    local safe_angle = angleRotation(bh_x, bh_y, ex, ey)
                    local dx, dy = vectorFromAngle(safe_angle, 6000)
                    enemy:setPosition(bh_x + dx, bh_y + dy)
                end
            end
        end
    end

    -- Spawn 2-5 random asteroid belts.
    for i_ = 1, irandom(2, 5) do
        local a = random(0, 360)
        local a2 = random(0, 360)
        local d = random(3000, 40000)
        local x, y = vectorFromAngle(a, d)
        local asteroid_positions = {}

        local asteroids_this_belt = 0
        for attempt = 1, 500 do
            if asteroids_this_belt >= 50 then
                break
            end
            local dx1, dy1 = vectorFromAngle(a2, random(-1000, 1000))
            local dx2, dy2 = vectorFromAngle(a2 + 90, random(-20000, 20000))
            local posx = x + dx1 + dx2
            local posy = y + dy1 + dy2
            if math.abs(posx) > 1000 and math.abs(posy) > 1000 then
                local allow_spawn = true
                for _, station in ipairs(station_list) do
                    if distance(station, posx, posy) < 2000 then
                        allow_spawn = false
                        break
                    end
                end
                if
                    allow_spawn
                    and black_hole
                    and black_hole:isValid()
                    and distance(bh_x, bh_y, posx, posy) < 5000
                then
                    allow_spawn = false
                end
                if allow_spawn then
                    local size = random(100, 500)
                    for _, ap in ipairs(asteroid_positions) do
                        if
                            distance(ap[1], ap[2], posx, posy)
                            < ap[3] + size
                        then
                            allow_spawn = false
                            break
                        end
                    end
                    if allow_spawn then
                        table.insert(asteroid_positions, { posx, posy, size })
                        Asteroid():setPosition(posx, posy):setSize(size)
                        asteroids_this_belt = asteroids_this_belt + 1
                    end
                end
            end
        end

        local vis_asteroids_this_belt = 0
        for attempt = 1, 500 do
            if vis_asteroids_this_belt >= 50 then
                break
            end
            local dx1, dy1 = vectorFromAngle(a2, random(-1500, 1500))
            local dx2, dy2 = vectorFromAngle(a2 + 90, random(-20000, 20000))
            local vax = x + dx1 + dx2
            local vay = y + dy1 + dy2
            if
                not (
                    black_hole
                    and black_hole:isValid()
                    and distance(bh_x, bh_y, vax, vay) < 5000
                )
            then
                VisualAsteroid():setPosition(vax, vay)
                vis_asteroids_this_belt = vis_asteroids_this_belt + 1
            end
        end
    end

    -- Spawn 0-3 random mine fields.
    for i_ = 1, irandom(0, 3) do
        local a = random(0, 360)
        local a2 = random(0, 360)
        local d = random(20000, 40000)
        local x, y = vectorFromAngle(a, d)

        for nx = -1, 1 do
            for ny = -5, 5 do
                if random(0, 100) < 90 then
                    local dx1, dy1 =
                        vectorFromAngle(a2, (nx * 1000) + random(-100, 100))
                    local dx2, dy2 = vectorFromAngle(
                        a2 + 90,
                        (ny * 1000) + random(-100, 100)
                    )
                    local mx = x + dx1 + dx2
                    local my = y + dy1 + dy2
                    if
                        not (
                            black_hole
                            and black_hole:isValid()
                            and distance(bh_x, bh_y, mx, my) < 5000
                        )
                    then
                        Mine():setPosition(mx, my)
                    end
                end
            end
        end
    end

    -- Spawn random neutral transports.
    Script():run("util_random_transports.lua")

    local station = friendly_list[1]
    if game_time_remaining ~= nil then
        station:sendCommsMessage(
            player,
            string.format(
                _(
                    "goal-incCall",
                    [[%s, your objective is to fend off the incoming Kraylor attack.

Please inform your Captain and crew that you have a total of %d minutes for this mission.

The mission started at the arrival of this message.

Good luck.]]
                ),
                player:getCallSign(),
                game_time_remaining / 60
            )
        )
    else
        station:sendCommsMessage(
            player,
            string.format(
                _(
                    "goal-incCall",
                    [[%s, your objective is to fend off the incoming Kraylor attack.

Good luck.]]
                ),
                player:getCallSign()
            )
        )
    end
end

--- Counts all valid entities in a list of entities.
-- @tparam table object_list A list of entities.
-- @treturn number The number of valid entities in the list.
function countValid(object_list)
    local object_count = 0
    for i_, object in ipairs(object_list) do
        if object:isValid() then
            object_count = object_count + 1
        end
    end
    return object_count
end

--- Updates the scenario (invoked every frame).
--
-- Checks victory/defeat conditions, ticks the game clock, and updates the spectator banner.
-- Victory/defeat conditions depend on the scenario variant in play.
--
-- @tparam number delta The time delta from the last update, in seconds.
function update(delta)
    -- Count all surviving enemies and allies.
    local enemy_count = countValid(enemy_list)
    local friendly_count = countValid(friendly_list)
    local player_count = countValid(player_list)

    -- If not playing the Empty variation, declare victory for the
    -- Humans (players) once all enemies are destroyed. Note that players can win
    -- even if they destroy the enemies by blowing themselves up.
    --
    -- In the Empty variation, the GM must use the Win button to declare
    -- a Human victory.
    if enemy_count == 0 and getScenarioSetting("Enemies") ~= "Empty" then
        victory("Human Navy")
        if game_time_remaining ~= nil then
            local text = string.format(
                _(
                    "msgMainscreen&Spectbanner",
                    "Mission: SUCCESS (%d seconds left)"
                ),
                math.floor(game_time_remaining)
            )
            globalMessage(text)
            setBanner(text)
            return
        end
    end

    if game_time_remaining ~= nil then
        game_time_remaining = game_time_remaining - delta
        if game_time_remaining < 0 then
            victory("Kraylor")
            local text = _(
                "msgMainscreen&Spectbanner",
                "Mission: FAILED (time has run out)"
            )
            globalMessage(text)
            setBanner(text)
            return
        end
        if game_time_remaining < time_warning then
            local minutes = time_warning / 60
            if time_warning <= 1 * 60 then -- Less then 1 minutes left.
                for idx, player in ipairs(player_list) do
                    friendly_list[1]:sendCommsMessage(
                        player,
                        string.format(
                            _(
                                minutes,
                                "time-incCall",
                                [[%s, you have one minute remaining.]],
                                [[%s, you have %d minutes remaining.]]
                            ),
                            player:getCallSign(),
                            minutes
                        )
                    )
                end
                time_warning = time_warning - 2 * 60
            elseif time_warning <= 5 * 60 then -- Less then 5 minutes left. Warn ever 2 minutes instead of every 5.
                for idx, player in ipairs(player_list) do
                    friendly_list[1]:sendCommsMessage(
                        player,
                        string.format(
                            _(
                                minutes,
                                "time-incCall",
                                [[%s, you have one minute remaining.]],
                                [[%s, you have %d minutes remaining.]]
                            ),
                            player:getCallSign(),
                            minutes
                        )
                    )
                end
                time_warning = time_warning - 2 * 60
            else
                for idx, player in ipairs(player_list) do
                    friendly_list[1]:sendCommsMessage(
                        player,
                        string.format(
                            _(
                                minutes,
                                "time-incCall",
                                [[%s, you have one minute remaining.]],
                                [[%s, you have %d minutes remaining.]]
                            ),
                            player:getCallSign(),
                            minutes
                        )
                    )
                end
                time_warning = time_warning - 5 * 60
            end
        end
    end

    -- If all allies are destroyed, the Humans (players) lose.
    if friendly_count == 0 then
        victory("Kraylor")
        local text = _(
            "msgMainscreen&Spectbanner",
            "Mission: FAILED (no friendlies left)"
        )
        globalMessage(text)
        setBanner(text)
        return
    else
        -- As the battle continues, award reputation based on
        -- the players' progress and number of surviving allies.
        for i_, friendly in ipairs(friendly_list) do
            if friendly:isValid() then
                friendly:addReputationPoints(delta * friendly_count * 0.1)
            end
        end
    end

    -- If last player ship is destroyed, the Humans (players) lose.
    if player_count == 0 then
        victory("Kraylor")
        local text = _(
            "msgMainscreen&Spectbanner",
            "Mission: FAILED (all your ships destroyed)"
        )
        globalMessage(text)
        setBanner(text)
        return
    end

    -- Set banner for cinematic view.
    if game_time_remaining ~= nil then
        setBanner(
            string.format(
                _(
                    "msgSpectbanner",
                    "Mission in progress - Time left: %d:%02d - Enemies: %d"
                ),
                math.floor(game_time_remaining / 60),
                math.floor(game_time_remaining % 60),
                enemy_count
            )
        )
    else
        setBanner(
            string.format(
                _(
                    "msgSpectbanner",
                    "Mission in progress - Enemies: %d"
                ),
                enemy_count
            )
        )
    end
end
