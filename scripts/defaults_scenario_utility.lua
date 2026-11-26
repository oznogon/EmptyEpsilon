-- Shared declarative defaults for scenario scripts.
--
-- This module returns fresh tables so scenarios can customize their configuration
-- without mutating a shared catalog, so it intentionally avoids globals.

local M = {}

local common_goods = {
    "food",
    "medicine",
    "nickel",
    "platinum",
    "gold",
    "dilithium",
    "tritanium",
    "luxury",
    "cobalt",
    "impulse",
    "warp",
    "shield",
    "tractor",
    "repulsor",
    "beam",
    "optic",
    "robotic",
    "filament",
    "transporter",
    "sensor",
    "communication",
    "autodoc",
    "lifter",
    "android",
    "nanites",
    "software",
    "circuit",
    "battery",
}

local mineral_goods = {
    "nickel",
    "platinum",
    "gold",
    "dilithium",
    "tritanium",
    "cobalt",
}

local component_goods = {
    "impulse",
    "warp",
    "shield",
    "tractor",
    "repulsor",
    "beam",
    "optic",
    "robotic",
    "filament",
    "transporter",
    "sensor",
    "communication",
    "autodoc",
    "lifter",
    "android",
    "nanites",
    "software",
    "circuit",
    "battery",
}

local system_types = {
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

local extended_system_types = {
    "reactor",
    "beamweapons",
    "missilesystem",
    "maneuver",
    "impulse",
    "warp",
    "jumpdrive",
    "frontshield",
    "rearshield",
    "utilitybeam",
    "sensors",
    "dockingbay",
}

local function copy(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, item in pairs(value) do
        result[key] = copy(item)
    end
    return result
end

local function merge(base, overrides)
    local result = copy(base)
    if type(overrides) ~= "table" then
        return result
    end
    for key, value in pairs(overrides) do
        if type(value) == "table" and type(result[key]) == "table" then
            result[key] = merge(result[key], value)
        else
            result[key] = copy(value)
        end
    end
    return result
end

function M.copy(value)
    return copy(value)
end

function M.merge(base, overrides)
    return merge(base or {}, overrides or {})
end

function M.goods()
    return {
        commonGoods = copy(common_goods),
        componentGoods = copy(component_goods),
        mineralGoods = copy(mineral_goods),
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
        },
    }
end

function M.systems(extended)
    local pretty_system = {
        ["reactor"] = _("stationServices-comms", "reactor"),
        ["beamweapons"] = _("stationServices-comms", "beam weapons"),
        ["missilesystem"] = _("stationServices-comms", "missile system"),
        ["maneuver"] = _("stationServices-comms", "maneuver"),
        ["impulse"] = _("stationServices-comms", "impulse engines"),
        ["warp"] = _("stationServices-comms", "warp drive"),
        ["jumpdrive"] = _("stationServices-comms", "jump drive"),
        ["frontshield"] = _("stationServices-comms", "front shield"),
        ["rearshield"] = _("stationServices-comms", "rear shield"),
    }
    local pretty_short_system = {
        ["reactor"] = _("stationServices-comms", "reactor"),
        ["beamweapons"] = _("stationServices-comms", "beams"),
        ["missilesystem"] = _("stationServices-comms", "missiles"),
        ["maneuver"] = _("stationServices-comms", "maneuver"),
        ["impulse"] = _("stationServices-comms", "impulse"),
        ["warp"] = _("stationServices-comms", "warp"),
        ["jumpdrive"] = _("stationServices-comms", "jump"),
        ["frontshield"] = _("stationServices-comms", "front shield"),
        ["rearshield"] = _("stationServices-comms", "rear shield"),
    }
    if extended then
        pretty_system.utilitybeam = _("stationServices-comms", "utility beam")
        pretty_system.sensors = _("stationServices-comms", "sensors")
        pretty_system.dockingbay = _("stationServices-comms", "docking bay")
        pretty_short_system.utilitybeam =
            _("stationServices-comms", "utility beam")
        pretty_short_system.sensors = _("stationServices-comms", "sensors")
        pretty_short_system.dockingbay =
            _("stationServices-comms", "docking bay")
    end
    return {
        pretty_system = pretty_system,
        pretty_short_system = pretty_short_system,
        system_types = copy(extended and extended_system_types or system_types),
    }
end

function M.ordnanceTypes()
    return {
        "Homing",
        "Nuke",
        "Mine",
        "EMP",
        "HVLI"
    }
end

return M
