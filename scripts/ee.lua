--- Elementary Lua additions to EE.
--
-- (It might be a good idea to let EE provide some of these values.)
--
-- **Planned additions**
--
-- - Constants for crew positions.
--
-- **Changelog**
--
-- *Version 0.8* (2026.06)
--
-- - Add constants for DamageType, Physics::Type, FactionRelation,
--   AIOrder, EMissileWeapons, EMissileSizes, MountPoint::State,
--   DockingPort::State, CommsTransmitter::State, Function::Type,
--   MainScreenSetting, MainScreenOverlay.
-- - Add canonical forms for scanned states (SS_NONE, SS_FOF,
--   SS_SIMPLE, SS_FULL).
--
-- *Version 0.7* (2020.08)
--
-- - Add constants for the scanned states and the array `SCANNED_STATES`.
--
-- *Version 0.6* (2020.05)
--
-- - Add the constant `MAX_PLAYER_SHIPS`.
-- - Add constants for the missile types and the array `MISSILE_TYPES`.
-- - Add constants for the alert levels and the array `ALERT_LEVELS`.
--
-- *Version 0.5* (2020.05)
--
-- - Add the constants `SYS_REACTOR` etc. and the array `SYSTEMS`.
--
-- @usage
-- require("ee.lua")
-- -- and see below
--
-- @module ee
-- @author Tom

--- Playerships.
-- @section playerships

--- Maximum number of player spaceships.
--
-- @usage
-- for index = 1, MAX_PLAYER_SHIPS do
--   local pship = getPlayerShip(index)
--   if pship then
--     -- do something
--     print(index, pship:getCallSign())
--   end
-- end
MAX_PLAYER_SHIPS = 32

--- Damage types.
--
-- String constants for `DamageType` from `src/script/enum.h`.
--
-- @section damage_types

--- `"energy"`
DT_ENERGY = "energy"
--- `"kinetic"`
DT_KINETIC = "kinetic"
--- `"emp"`
DT_EMP = "emp"

--- Array of the damage types.
DAMAGE_TYPES = {
    DT_ENERGY,
    DT_KINETIC,
    DT_EMP,
}

--- Physics types.
--
-- String constants for `sp::Physics::Type` from `src/script/enum.h`.
--
-- @section physics_types

--- `"sensor"`
PHYSICS_SENSOR = "sensor"
--- `"dynamic"`
PHYSICS_DYNAMIC = "dynamic"
--- `"static"`
PHYSICS_STATIC = "static"

--- Array of the physics types.
PHYSICS_TYPES = {
    PHYSICS_SENSOR,
    PHYSICS_DYNAMIC,
    PHYSICS_STATIC,
}

--- Faction relations.
--
-- String constants for `FactionRelation` from `src/script/enum.h`.
--
-- @section faction_relations

--- `"friendly"`
REL_FRIENDLY = "friendly"
--- `"neutral"`
REL_NEUTRAL = "neutral"
--- `"enemy"`
REL_ENEMY = "enemy"

--- Array of the faction relations.
FACTION_RELATIONS = {
    REL_FRIENDLY,
    REL_NEUTRAL,
    REL_ENEMY,
}

--- Scan states.
--
-- String constants for `ScanState::State` from `src/script/enum.h`.
--
-- @section scan_states

--- `"none"` (not scanned)
SS_NONE = "none"
--- `"fof"` (friend-or-foe known)
SS_FOF = "fof"
--- `"simple"` (simple scan)
SS_SIMPLE = "simple"
--- `"full"` (full scan)
SS_FULL = "full"

--- Array of the canonical scanned states.
SCANNED_STATES = {
    SS_NONE,
    SS_FOF,
    SS_SIMPLE,
    SS_FULL,
}

--- AI orders.
--
-- String constants for `AIOrder` from `src/script/enum.h`.
--
-- @section ai_orders

--- `"Idle"`
AI_IDLE = "Idle"
--- `"Roaming"`
AI_ROAM = "Roaming"
--- `"Retreat"`
AI_RETREAT = "Retreat"
--- `"Stand Ground"`
AI_STAND_GROUND = "Stand Ground"
--- `"Defend Location"`
AI_DEFEND_LOCATION = "Defend Location"
--- `"Defend Target"`
AI_DEFEND_TARGET = "Defend Target"
--- `"Fly in formation"`
AI_FLY_FORMATION = "Fly in formation"
--- `"Fly towards"`
AI_FLY_TOWARDS = "Fly towards"
--- `"Fly towards (ignore all)"`
AI_FLY_TOWARDS_BLIND = "Fly towards (ignore all)"
--- `"Dock"`
AI_DOCK = "Dock"
--- `"Attack"`
AI_ATTACK = "Attack"

--- Array of the AI orders.
AI_ORDERS = {
    AI_IDLE,
    AI_ROAM,
    AI_RETREAT,
    AI_STAND_GROUND,
    AI_DEFEND_LOCATION,
    AI_DEFEND_TARGET,
    AI_FLY_FORMATION,
    AI_FLY_TOWARDS,
    AI_FLY_TOWARDS_BLIND,
    AI_DOCK,
    AI_ATTACK,
}

--- Missile storage types.
--
-- String constants for `MissileWeaponData` used by weapon storage
-- functions (`setWeaponStorage`, `getWeaponStorageMax`, etc.).
--
-- For the tube API (`setTubeMissileWeapon`), see `MW_` constants
-- in the `EMissileWeapons` section below.
--
-- @section missile_types

--- `"Homing"`
MISSILE_HOMING = "Homing"
--- `"Nuke"`
MISSILE_NUKE = "Nuke"
--- `"Mine"`
MISSILE_MINE = "Mine"
--- `"EMP"`
MISSILE_EMP = "EMP"
--- `"HVLI"`
MISSILE_HVLI = "HVLI"

--- Array of the missile storage types.
MISSILE_TYPES = {
    MISSILE_HOMING,
    MISSILE_NUKE,
    MISSILE_MINE,
    MISSILE_EMP,
    MISSILE_HVLI,
}

--- Tube missile weapon types.
--
-- String constants for `EMissileWeapons` from `src/script/enum.h`.
-- These lowercase values are used by tube-related functions such as
-- `setTubeMissileWeapon` and `weaponTubeAllowMissle`.
--
-- @section tube_missile_weapons

--- `"none"`
MW_NONE = "none"
--- `"homing"`
MW_HOMING = "homing"
--- `"nuke"`
MW_NUKE = "nuke"
--- `"mine"`
MW_MINE = "mine"
--- `"emp"`
MW_EMP = "emp"
--- `"hvli"`
MW_HVLI = "hvli"

--- Array of the tube missile weapon types.
TUBE_MISSILE_TYPES = {
    MW_NONE,
    MW_HOMING,
    MW_NUKE,
    MW_MINE,
    MW_EMP,
    MW_HVLI,
}

--- Missile sizes.
--
-- String constants for `EMissileSizes` from `src/script/enum.h`.
--
-- @section missile_sizes

--- `"small"`
MS_SMALL = "small"
--- `"medium"`
MS_MEDIUM = "medium"
--- `"large"`
MS_LARGE = "large"

--- Array of the missile sizes.
MISSILE_SIZES = {
    MS_SMALL,
    MS_MEDIUM,
    MS_LARGE,
}

--- Ship system names.
--
-- String constants for `ShipSystem::Type` from `src/script/enum.h`.
-- Used in Engineering functions.
--
-- @section systems

--- `"none"`
SYS_NONE = "none"
--- `"reactor"`
SYS_REACTOR = "reactor"
--- `"beamweapons"`
SYS_BEAMWEAPONS = "beamweapons"
--- `"missilesystem"`
SYS_MISSILESYSTEM = "missilesystem"
--- `"maneuver"`
SYS_MANEUVER = "maneuver"
--- `"impulse"`
SYS_IMPULSE = "impulse"
--- `"warp"`
SYS_WARP = "warp"
--- `"jumpdrive"`
SYS_JUMPDRIVE = "jumpdrive"
--- `"frontshield"`
SYS_FRONTSHIELD = "frontshield"
--- `"rearshield"`
SYS_REARSHIELD = "rearshield"

--- Array of the system names.
--
-- @usage
-- local pship = getPlayerShip(-1)
-- for idx, system in ipairs(SYSTEMS) do
--   pship:setSystemHealth(system, 1.0)
--   pship:setSystemHeat(system, 0.0)
--   pship:setSystemPower(system, 1.0)
--   pship:commandSetSystemPowerRequest(system, 1.0)
--   pship:setSystemCoolant(system, 0.0)
--   pship:commandSetSystemCoolantRequest(system, 0.0)
-- end
SYSTEMS = {
    SYS_REACTOR,
    SYS_BEAMWEAPONS,
    SYS_MISSILESYSTEM,
    SYS_MANEUVER,
    SYS_IMPULSE,
    SYS_WARP,
    SYS_JUMPDRIVE,
    SYS_FRONTSHIELD,
    SYS_REARSHIELD,
}

--- Tube states.
--
-- String constants for `MissileTubes::MountPoint::State` from
-- `src/script/enum.h`.
--
-- @section tube_states

--- `"empty"`
TUBE_EMPTY = "empty"
--- `"loading"`
TUBE_LOADING = "loading"
--- `"loaded"`
TUBE_LOADED = "loaded"
--- `"unloading"`
TUBE_UNLOADING = "unloading"
--- `"firing"`
TUBE_FIRING = "firing"

--- Array of the tube states.
TUBE_STATES = {
    TUBE_EMPTY,
    TUBE_LOADING,
    TUBE_LOADED,
    TUBE_UNLOADING,
    TUBE_FIRING,
}

--- Docking port states.
--
-- String constants for `DockingPort::State` from `src/script/enum.h`.
--
-- @section docking_states

--- `"not_docking"`
DOCK_NOT_DOCKING = "not_docking"
--- `"docking"`
DOCK_DOCKING = "docking"
--- `"docked"`
DOCK_DOCKED = "docked"

--- Array of the docking port states.
DOCK_STATES = {
    DOCK_NOT_DOCKING,
    DOCK_DOCKING,
    DOCK_DOCKED,
}

--- Comms transmitter states.
--
-- String constants for `CommsTransmitter::State` from
-- `src/script/enum.h`.
--
-- @section comms_states

--- `"inactive"`
COMMS_INACTIVE = "inactive"
--- `"opening"`
COMMS_OPENING = "opening"
--- `"hailed"`
COMMS_HAILED = "hailed"
--- `"hailed_gm"`
COMMS_HAILED_GM = "hailed_gm"
--- `"open"`
COMMS_OPEN = "open"
--- `"open_player"`
COMMS_OPEN_PLAYER = "open_player"
--- `"open_gm"`
COMMS_OPEN_GM = "open_gm"
--- `"failed"`
COMMS_FAILED = "failed"
--- `"broken"`
COMMS_BROKEN = "broken"
--- `"closed"`
COMMS_CLOSED = "closed"

--- Array of the comms transmitter states.
COMMS_STATES = {
    COMMS_INACTIVE,
    COMMS_OPENING,
    COMMS_HAILED,
    COMMS_HAILED_GM,
    COMMS_OPEN,
    COMMS_OPEN_PLAYER,
    COMMS_OPEN_GM,
    COMMS_FAILED,
    COMMS_BROKEN,
    COMMS_CLOSED,
}

--- Alert levels.
--
-- String constants for `AlertLevel` from `src/script/enum.h`.
--
-- @section alert_levels

--- `"Normal"` alert
ALERT_NORMAL = "Normal"
--- `"YELLOW ALERT"`
ALERT_YELLOW = "YELLOW ALERT"
--- `"RED ALERT"`
ALERT_RED = "RED ALERT"

--- Array of the alert levels.
ALERT_LEVELS = {
    ALERT_NORMAL,
    ALERT_YELLOW,
    ALERT_RED,
}

--- Custom ship function types.
--
-- String constants for `CustomShipFunctions::Function::Type` from
-- `src/script/enum.h`.
--
-- @section function_types

--- `"info"`
FUNC_INFO = "info"
--- `"button"`
FUNC_BUTTON = "button"
--- `"message"`
FUNC_MESSAGE = "message"

--- Array of the custom ship function types.
FUNCTION_TYPES = {
    FUNC_INFO,
    FUNC_BUTTON,
    FUNC_MESSAGE,
}

--- Scanning complexity.
--
-- String constants for `EScanningComplexity` from `src/script/enum.h`.
--
-- @section scanning_complexities

SC_NONE = "none"
SC_SIMPLE = "simple"
SC_NORMAL = "normal"
SC_ADVANCED = "advanced"

--- Array of the scan complexities.
SCANNING_COMPLEXITIES = {
    SC_NONE,
    SC_SIMPLE,
    SC_NORMAL,
    SC_ADVANCED,
}

--- Main screen views.
--
-- String constants for `MainScreenSetting` from `src/script/enum.h`.
--
-- @section main_screen_settings

--- `"front"`
SCREEN_FRONT = "front"
--- `"back"`
SCREEN_BACK = "back"
--- `"left"`
SCREEN_LEFT = "left"
--- `"right"`
SCREEN_RIGHT = "right"
--- `"target"`
SCREEN_TARGET = "target"
--- `"tactical"`
SCREEN_TACTICAL = "tactical"
--- `"longrange"`
SCREEN_LONG_RANGE = "longrange"
--- `"strategic"`
SCREEN_STRATEGIC = "strategic"

--- Array of the main screen settings.
MAIN_SCREEN_SETTINGS = {
    SCREEN_FRONT,
    SCREEN_BACK,
    SCREEN_LEFT,
    SCREEN_RIGHT,
    SCREEN_TARGET,
    SCREEN_TACTICAL,
    SCREEN_LONG_RANGE,
    SCREEN_STRATEGIC,
}

--- Main screen overlays.
--
-- String constants for `MainScreenOverlay` from `src/script/enum.h`.
--
-- @section main_screen_overlays

--- `"hidecomms"`
OVERLAY_HIDE_COMMS = "hidecomms"
--- `"showcomms"`
OVERLAY_SHOW_COMMS = "showcomms"

--- Array of the main screen overlays.
MAIN_SCREEN_OVERLAYS = {
    OVERLAY_HIDE_COMMS,
    OVERLAY_SHOW_COMMS,
}

--- Hacking games.
--
-- String constants for `EHackingGames` from `src/script/enum.h`.
--
-- @section hacking_games

HG_Mine = "mines"
HG_Lights = "lights"
HG_All = "all"

--- Array of the hacking games.
HACKING_GAMES = {
    HG_Mine,
    HG_Lights,
    HG_All,
}
