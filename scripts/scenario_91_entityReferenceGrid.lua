-- Name: Entity Reference Grid
-- Description: Places one of each entity type and ship template in grids, spaced 5U apart. Useful as a visual reference for entity types, their default sizes, and radar signatures. GMs can also use this as a starting point to copy-paste individual entity patterns.
-- Type: Development

require("utils.lua")

local U = 1000
local SPACING = 5 * U

-- Entity API grid (18 items, 6 columns)
local ENTITY_COLS = 6
local ENTITY_ROWS = math.ceil(18 / ENTITY_COLS)

local function entity_grid(index)
    local row = math.floor((index - 1) / ENTITY_COLS)
    local col = (index - 1) % ENTITY_COLS
    local x = (col - (ENTITY_COLS - 1) / 2) * SPACING
    local y = ((ENTITY_ROWS - 1) / 2 - row) * SPACING
    return x, y
end

-- Ship template grid (164 items, 20 columns)
local SHIP_COLS = 20
local SHIP_ROWS = math.ceil(164 / SHIP_COLS)
local SHIP_CENTER_Y = -35000

local function ship_grid(index)
    local row = math.floor((index - 1) / SHIP_COLS)
    local col = (index - 1) % SHIP_COLS
    local x = (col - (SHIP_COLS - 1) / 2) * SPACING
    local y = SHIP_CENTER_Y + ((SHIP_ROWS - 1) / 2 - row) * SPACING
    return x, y
end

function init()
    ECS = createEntity ~= nil

    -- ==========================
    -- Part 1: Entity API types
    -- ==========================
    local idx = 0

    idx = idx + 1
    Asteroid():setPosition(entity_grid(idx))

    idx = idx + 1
    Artifact():setPosition(entity_grid(idx)):setDescription("Artifact entity")

    idx = idx + 1
    local bx, by = entity_grid(idx)
    BeamEffect():setPosition(bx, by):setDuration(600)

    idx = idx + 1
    BlackHole():setPosition(entity_grid(idx))

    idx = idx + 1
    CpuShip():setTemplate("Phobos T3"):setPosition(entity_grid(idx)):setFaction("Human Navy"):orderIdle():setScanned(true)

    idx = idx + 1
    local ex, ey = entity_grid(idx)
    ElectricExplosionEffect():setPosition(ex, ey):setSize(100):setOnRadar(true)

    idx = idx + 1
    local xx, xy = entity_grid(idx)
    ExplosionEffect():setPosition(xx, xy):setSize(100):setOnRadar(true)

    idx = idx + 1
    Mine():setPosition(entity_grid(idx))

    idx = idx + 1
    Nebula():setPosition(entity_grid(idx))

    idx = idx + 1
    local px, py = entity_grid(idx)
    Planet():setPosition(px, py):setPlanetRadius(1000):setDistanceFromMovementPlane(-500):setPlanetSurfaceTexture("planets/planet-1.png")

    idx = idx + 1
    PlayerSpaceship():setTemplate("Atlantis"):setPosition(entity_grid(idx)):setFaction("Human Navy"):setCallSign("EE Reference")

    idx = idx + 1
    ScanProbe():setPosition(entity_grid(idx)):setLifetime(60 * 60)

    idx = idx + 1
    SpaceStation():setTemplate("Small Station"):setPosition(entity_grid(idx)):setFaction("Human Navy"):setScanned(true)

    idx = idx + 1
    SupplyDrop():setPosition(entity_grid(idx)):setWeaponStorage("Homing", 6):setEnergy(500)

    idx = idx + 1
    VisualAsteroid():setPosition(entity_grid(idx))

    idx = idx + 1
    WarpJammer():setPosition(entity_grid(idx)):setRange(3000)

    idx = idx + 1
    WormHole():setPosition(entity_grid(idx))

    idx = idx + 1
    local zx, zy = entity_grid(idx)
    Zone():setColor(0, 255, 0):setPoints(
        zx - 500, zy - 500,
        zx + 500, zy - 500,
        zx + 500, zy + 500,
        zx - 500, zy + 500
    ):setLabel("Zone")

    -- ==========================
    -- Part 2: Ship templates
    -- ==========================
    local s_idx = 0

    -- starFighters.lua
    s_idx = s_idx + 1; CpuShip():setTemplate("MT52 Hornet"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("MU52 Hornet"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; PlayerSpaceship():setTemplate("MP52 Hornet"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):setCallSign("Ref")
    s_idx = s_idx + 1; CpuShip():setTemplate("Adder MK5"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Adder MK4"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Adder MK3"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Adder MK6"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Adder MK7"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Adder MK8"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Adder MK9"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("WX-Lindworm"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; PlayerSpaceship():setTemplate("ZX-Lindworm"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):setCallSign("Ref")

    -- frigates.lua
    s_idx = s_idx + 1; CpuShip():setTemplate("Phobos T3"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Elara P2"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Phobos M3"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; PlayerSpaceship():setTemplate("Phobos M3P"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):setCallSign("Ref")
    s_idx = s_idx + 1; CpuShip():setTemplate("Nirvana R5"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Nirvana R5A"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Nirvana R3"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Storm"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; PlayerSpaceship():setTemplate("Hathcock"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):setCallSign("Ref")
    s_idx = s_idx + 1; CpuShip():setTemplate("Piranha F12"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Piranha F12.M"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Piranha F8"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; PlayerSpaceship():setTemplate("Piranha"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):setCallSign("Ref")
    s_idx = s_idx + 1; CpuShip():setTemplate("Stalker Q7"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Stalker Q5"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Stalker R7"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Stalker R5"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Ranus U"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Flavia"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Flavia Falcon"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; PlayerSpaceship():setTemplate("Flavia P.Falcon"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):setCallSign("Ref")
    s_idx = s_idx + 1; PlayerSpaceship():setTemplate("Repulse"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):setCallSign("Ref")
    s_idx = s_idx + 1; CpuShip():setTemplate("Fiend G3"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Fiend G4"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Fiend G6"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Fiend G5"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)

    -- corvette.lua
    s_idx = s_idx + 1; CpuShip():setTemplate("Atlantis X23"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; PlayerSpaceship():setTemplate("Atlantis"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):setCallSign("Ref")
    s_idx = s_idx + 1; CpuShip():setTemplate("Starhammer II"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; PlayerSpaceship():setTemplate("Crucible"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):setCallSign("Ref")
    s_idx = s_idx + 1; PlayerSpaceship():setTemplate("Maverick"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):setCallSign("Ref")
    s_idx = s_idx + 1; CpuShip():setTemplate("Defense platform"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Personnel Freighter 1"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Personnel Freighter 2"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Personnel Freighter 3"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Personnel Freighter 4"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Personnel Freighter 5"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Personnel Jump Freighter 3"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Personnel Jump Freighter 4"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Personnel Jump Freighter 5"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Goods Freighter 1"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Goods Freighter 2"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Goods Freighter 3"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Goods Freighter 4"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Goods Freighter 5"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Goods Jump Freighter 3"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Goods Jump Freighter 4"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Goods Jump Freighter 5"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Garbage Freighter 1"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Garbage Freighter 2"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Garbage Freighter 3"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Garbage Freighter 4"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Garbage Freighter 5"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Garbage Jump Freighter 3"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Garbage Jump Freighter 4"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Garbage Jump Freighter 5"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Equipment Freighter 1"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Equipment Freighter 2"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Equipment Freighter 3"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Equipment Freighter 4"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Equipment Freighter 5"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Equipment Jump Freighter 3"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Equipment Jump Freighter 4"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Equipment Jump Freighter 5"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Fuel Freighter 1"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Fuel Freighter 2"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Fuel Freighter 3"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Fuel Freighter 4"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Fuel Freighter 5"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Fuel Jump Freighter 3"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Fuel Jump Freighter 4"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Fuel Jump Freighter 5"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Jump Carrier"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; PlayerSpaceship():setTemplate("Benedict"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):setCallSign("Ref")
    s_idx = s_idx + 1; PlayerSpaceship():setTemplate("Kiriya"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):setCallSign("Ref")
    s_idx = s_idx + 1; PlayerSpaceship():setTemplate("Saipan"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):setCallSign("Ref")

    -- exuari.lua
    s_idx = s_idx + 1; CpuShip():setTemplate("Dagger"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Blade"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Gunner"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Shooter"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Jagger"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Racer"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Hunter"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Strike"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Dash"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Guard"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Sentinel"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Warden"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Flash"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Ranger"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Buster"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Ryder"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Fortress"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)

    -- ktlitan.lua
    s_idx = s_idx + 1; CpuShip():setTemplate("Ktlitan Fighter"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Ktlitan Breaker"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Ktlitan Worker"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Ktlitan Drone"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Ktlitan Feeder"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Ktlitan Scout"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Ktlitan Destroyer"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Ktlitan Queen"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)

    -- dreadnaught.lua
    s_idx = s_idx + 1; CpuShip():setTemplate("Odin"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)

    -- stations.lua
    s_idx = s_idx + 1; SpaceStation():setTemplate("Small Station"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):setScanned(true)
    s_idx = s_idx + 1; SpaceStation():setTemplate("Medium Station"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):setScanned(true)
    s_idx = s_idx + 1; SpaceStation():setTemplate("Large Station"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):setScanned(true)
    s_idx = s_idx + 1; SpaceStation():setTemplate("Huge Station"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):setScanned(true)

    -- satellites.lua
    s_idx = s_idx + 1; CpuShip():setTemplate("ANT 615"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)

    -- transport.lua
    s_idx = s_idx + 1; CpuShip():setTemplate("Transport1x1"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Transport1x2"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Transport1x3"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Transport1x4"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Transport1x5"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Transport2x1"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Transport2x2"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Transport2x3"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Transport2x4"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Transport2x5"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Transport3x1"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Transport3x2"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Transport3x3"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Transport3x4"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Transport3x5"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Transport4x1"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Transport4x2"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Transport4x3"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Transport4x4"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Transport4x5"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Transport5x1"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Transport5x2"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Transport5x3"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Transport5x4"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Transport5x5"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)

    -- OLD.lua
    s_idx = s_idx + 1; PlayerSpaceship():setTemplate("Player Cruiser"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):setCallSign("Ref")
    s_idx = s_idx + 1; PlayerSpaceship():setTemplate("Player Missile Cr."):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):setCallSign("Ref")
    s_idx = s_idx + 1; PlayerSpaceship():setTemplate("Player Fighter"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):setCallSign("Ref")
    s_idx = s_idx + 1; CpuShip():setTemplate("Tug"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; PlayerSpaceship():setTemplate("Nautilus"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):setCallSign("Ref")
    s_idx = s_idx + 1; CpuShip():setTemplate("Fighter"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Karnack"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Cruiser"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Karnack MK2"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Missile Cruiser"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Gunship"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Adv. Gunship"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Strikeship"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Adv. Striker"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; PlayerSpaceship():setTemplate("Striker"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):setCallSign("Ref")
    s_idx = s_idx + 1; CpuShip():setTemplate("Dreadnought"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Battlestation"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; PlayerSpaceship():setTemplate("Ender"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):setCallSign("Ref")
    s_idx = s_idx + 1; CpuShip():setTemplate("Weapons platform"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)
    s_idx = s_idx + 1; CpuShip():setTemplate("Blockade Runner"):setPosition(ship_grid(s_idx)):setFaction("Human Navy"):orderIdle():setScanned(true)

    addGMFunction(
        _("buttonGM", "Print all grid positions"),
        function()
            print("Entity type grid (5U spacing):")
            local entity_names = {
                "Asteroid", "Artifact", "BeamEffect", "BlackHole",
                "CpuShip", "ElectricExplosionEffect", "ExplosionEffect",
                "Mine", "Nebula", "Planet", "PlayerSpaceship",
                "ScanProbe", "SpaceStation", "SupplyDrop",
                "VisualAsteroid", "WarpJammer", "WormHole", "Zone"
            }
            for i, name in ipairs(entity_names) do
                local x, y = entity_grid(i)
                print(string.format("  %2d  %-25s  (%6d, %6d)", i, name, x, y))
            end
        end
    )
end

function update(delta)
end
