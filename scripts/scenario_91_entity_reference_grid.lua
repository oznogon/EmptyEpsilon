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
    CpuShip()
        :setTemplate(ST.PHOBOS_T3)
        :setPosition(entity_grid(idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)

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
    Planet()
        :setPosition(px, py)
        :setPlanetRadius(1000)
        :setDistanceFromMovementPlane(-500)
        :setPlanetSurfaceTexture("planets/planet-1.png")

    idx = idx + 1
    PlayerSpaceship()
        :setTemplate(ST.ATLANTIS)
        :setPosition(entity_grid(idx))
        :setFaction("Human Navy")
        :setCallSign("EE Reference")

    idx = idx + 1
    ScanProbe():setPosition(entity_grid(idx)):setLifetime(60 * 60)

    idx = idx + 1
    SpaceStation()
        :setTemplate(ST.SMALL_STATION)
        :setPosition(entity_grid(idx))
        :setFaction("Human Navy")
        :setScanned(true)

    idx = idx + 1
    SupplyDrop()
        :setPosition(entity_grid(idx))
        :setWeaponStorage("Homing", 6)
        :setEnergy(500)

    idx = idx + 1
    VisualAsteroid():setPosition(entity_grid(idx))

    idx = idx + 1
    WarpJammer()
        :setPosition(entity_grid(idx))
        :setRange(3000)

    idx = idx + 1
    WormHole():setPosition(entity_grid(idx))

    idx = idx + 1
    local zx, zy = entity_grid(idx)
    Zone()
        :setColor(0, 255, 0)
        :setPoints(
            zx - 500,
            zy - 500,
            zx + 500,
            zy - 500,
            zx + 500,
            zy + 500,
            zx - 500,
            zy + 500
        )
        :setLabel("Zone")

    -- ==========================
    -- Part 2: Ship templates
    -- ==========================
    local s_idx = 0

    -- starfighters.lua
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.MT52_HORNET)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.MU52_HORNET)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    PlayerSpaceship()
        :setTemplate(ST.MP52_HORNET)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :setCallSign("Ref")
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.ADDER_MK5)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.ADDER_MK4)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.ADDER_MK3)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.ADDER_MK6)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.ADDER_MK7)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.ADDER_MK8)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.ADDER_MK9)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.WX_LINDWORM)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    PlayerSpaceship()
        :setTemplate(ST.ZX_LINDWORM)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :setCallSign("Ref")

    -- frigates.lua
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.PHOBOS_T3)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.ELARA_P2)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.PHOBOS_M3)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    PlayerSpaceship()
        :setTemplate(ST.PHOBOS_M3P)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :setCallSign("Ref")
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.NIRVANA_R5)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.NIRVANA_R5A)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.NIRVANA_R3)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.STORM)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    PlayerSpaceship()
        :setTemplate(ST.HATHCOCK)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :setCallSign("Ref")
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.PIRANHA_F12)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.PIRANHA_F12M)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.PIRANHA_F8)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    PlayerSpaceship()
        :setTemplate(ST.PIRANHA)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :setCallSign("Ref")
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.STALKER_Q7)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.STALKER_Q5)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.STALKER_R7)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.STALKER_R5)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.RANUS_U)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.FLAVIA)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.FLAVIA_FALCON)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    PlayerSpaceship()
        :setTemplate(ST.FLAVIA_PFALCON)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :setCallSign("Ref")
    s_idx = s_idx + 1
    PlayerSpaceship()
        :setTemplate(ST.REPULSE)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :setCallSign("Ref")
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.FIEND_G3)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.FIEND_G4)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.FIEND_G6)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.FIEND_G5)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)

    -- corvette.lua
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.ATLANTIS_X23)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    PlayerSpaceship()
        :setTemplate(ST.ATLANTIS)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :setCallSign("Ref")
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.STARHAMMER_II)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    PlayerSpaceship()
        :setTemplate(ST.CRUCIBLE)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :setCallSign("Ref")
    s_idx = s_idx + 1
    PlayerSpaceship()
        :setTemplate(ST.MAVERICK)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :setCallSign("Ref")
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.DEFENSE_PLATFORM)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.PERSONNEL_FREIGHTER_1)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.PERSONNEL_FREIGHTER_2)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.PERSONNEL_FREIGHTER_3)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.PERSONNEL_FREIGHTER_4)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.PERSONNEL_FREIGHTER_5)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.PERSONNEL_JUMP_FREIGHTER_3)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.PERSONNEL_JUMP_FREIGHTER_4)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.PERSONNEL_JUMP_FREIGHTER_5)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.GOODS_FREIGHTER_1)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.GOODS_FREIGHTER_2)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.GOODS_FREIGHTER_3)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.GOODS_FREIGHTER_4)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.GOODS_FREIGHTER_5)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.GOODS_JUMP_FREIGHTER_3)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.GOODS_JUMP_FREIGHTER_4)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.GOODS_JUMP_FREIGHTER_5)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.GARBAGE_FREIGHTER_1)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.GARBAGE_FREIGHTER_2)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.GARBAGE_FREIGHTER_3)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.GARBAGE_FREIGHTER_4)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.GARBAGE_FREIGHTER_5)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.GARBAGE_JUMP_FREIGHTER_3)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.GARBAGE_JUMP_FREIGHTER_4)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.GARBAGE_JUMP_FREIGHTER_5)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.EQUIPMENT_FREIGHTER_1)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.EQUIPMENT_FREIGHTER_2)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.EQUIPMENT_FREIGHTER_3)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.EQUIPMENT_FREIGHTER_4)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.EQUIPMENT_FREIGHTER_5)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.EQUIPMENT_JUMP_FREIGHTER_3)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.EQUIPMENT_JUMP_FREIGHTER_4)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.EQUIPMENT_JUMP_FREIGHTER_5)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.FUEL_FREIGHTER_1)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.FUEL_FREIGHTER_2)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.FUEL_FREIGHTER_3)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.FUEL_FREIGHTER_4)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.FUEL_FREIGHTER_5)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.FUEL_JUMP_FREIGHTER_3)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.FUEL_JUMP_FREIGHTER_4)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.FUEL_JUMP_FREIGHTER_5)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.JUMP_CARRIER)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    PlayerSpaceship()
        :setTemplate(ST.BENEDICT)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :setCallSign("Ref")
    s_idx = s_idx + 1
    PlayerSpaceship()
        :setTemplate(ST.KIRIYA)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :setCallSign("Ref")
    s_idx = s_idx + 1
    PlayerSpaceship()
        :setTemplate(ST.SAIPAN)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :setCallSign("Ref")

    -- exuari.lua
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.DAGGER)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.BLADE)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.GUNNER)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.SHOOTER)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.JAGGER)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.RACER)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.HUNTER)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.STRIKE)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.DASH)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.GUARD)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.SENTINEL)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.WARDEN)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.FLASH)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.RANGER)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.BUSTER)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.RYDER)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.FORTRESS)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)

    -- ktlitan.lua
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.KTLITAN_FIGHTER)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.KTLITAN_BREAKER)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.KTLITAN_WORKER)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.KTLITAN_DRONE)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.KTLITAN_FEEDER)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.KTLITAN_SCOUT)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.KTLITAN_DESTROYER)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.KTLITAN_QUEEN)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)

    -- dreadnaught.lua
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.ODIN)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)

    -- stations.lua
    s_idx = s_idx + 1
    SpaceStation()
        :setTemplate(ST.SMALL_STATION)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :setScanned(true)
    s_idx = s_idx + 1
    SpaceStation()
        :setTemplate(ST.MEDIUM_STATION)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :setScanned(true)
    s_idx = s_idx + 1
    SpaceStation()
        :setTemplate(ST.LARGE_STATION)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :setScanned(true)
    s_idx = s_idx + 1
    SpaceStation()
        :setTemplate(ST.HUGE_STATION)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :setScanned(true)

    -- satellites.lua
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.ANT_615)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)

    -- transport.lua
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.TRANSPORT1X1)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.TRANSPORT1X2)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.TRANSPORT1X3)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.TRANSPORT1X4)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.TRANSPORT1X5)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.TRANSPORT2X1)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.TRANSPORT2X2)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.TRANSPORT2X3)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.TRANSPORT2X4)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.TRANSPORT2X5)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.TRANSPORT3X1)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.TRANSPORT3X2)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.TRANSPORT3X3)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.TRANSPORT3X4)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.TRANSPORT3X5)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.TRANSPORT4X1)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.TRANSPORT4X2)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.TRANSPORT4X3)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.TRANSPORT4X4)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.TRANSPORT4X5)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.TRANSPORT5X1)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.TRANSPORT5X2)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.TRANSPORT5X3)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.TRANSPORT5X4)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.TRANSPORT5X5)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)

    -- OLD.lua
    s_idx = s_idx + 1
    PlayerSpaceship()
        :setTemplate(ST.VINDICATOR)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :setCallSign("Ref")
    s_idx = s_idx + 1
    PlayerSpaceship()
        :setTemplate(ST.AVALANCHE)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :setCallSign("Ref")
    s_idx = s_idx + 1
    PlayerSpaceship()
        :setTemplate(ST.STINGRAY)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :setCallSign("Ref")
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.APIS)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    PlayerSpaceship()
        :setTemplate(ST.NAUTILUS)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :setCallSign("Ref")
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.RIPOSTE)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.KARNACK)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.KARNACK)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.KARNACK_MK2)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.POLARIS)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.GUNSHIP)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.ADV_GUNSHIP)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.STRIX)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.MAGPIE)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    PlayerSpaceship()
        :setTemplate(ST.CROW)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :setCallSign("Ref")
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.DREADNOUGHT)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.BATTLESTATION)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    PlayerSpaceship()
        :setTemplate(ST.ENDER)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :setCallSign("Ref")
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.WEAPONS_PLATFORM)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)
    s_idx = s_idx + 1
    CpuShip()
        :setTemplate(ST.BLOCKADE_RUNNER)
        :setPosition(ship_grid(s_idx))
        :setFaction("Human Navy")
        :orderIdle()
        :setScanned(true)

    addGMFunction(_("buttonGM", "Print all grid positions"), function()
        print("Entity type grid (5U spacing):")
        local entity_names = {
            "Asteroid",
            "Artifact",
            "BeamEffect",
            "BlackHole",
            "CpuShip",
            "ElectricExplosionEffect",
            "ExplosionEffect",
            "Mine",
            "Nebula",
            "Planet",
            "PlayerSpaceship",
            "ScanProbe",
            "SpaceStation",
            "SupplyDrop",
            "VisualAsteroid",
            "WarpJammer",
            "WormHole",
            "Zone",
        }
        for i, name in ipairs(entity_names) do
            local x, y = entity_grid(i)
            print(string.format("  %2d  %-25s  (%6d, %6d)", i, name, x, y))
        end
    end)
end

function update(delta) end
