-- Shared player ship call-sign pools.
--
-- Scenarios name player ships from themed call-sign pools keyed by ship
-- template. This module holds the pools that the scenarios use identically,
-- and returns fresh copies so a scenario can add its own pools or override a
-- shared pool without changing the catalog.

local M = {}

-- Keys use ship template constants where they exist. Atlantis II, Proto-Atlantis,
-- Redhook, Stricken, and Surkov have no constant in ship_template_constants.lua.
local shared_pools = {
    [ST.ATLANTIS] = {
        "Excaliber",
        "Thrasher",
        "Punisher",
        "Vorpal",
        "Protang",
        "Drummond",
        "Parchim",
        "Coronado",
    },
    ["Atlantis II"] = {
        "Spyder",
        "Shelob",
        "Tarantula",
        "Aragog",
        "Charlotte",
    },
    [ST.AVALANCHE] = {
        "Projectus",
        "Hurlmeister",
        "Flinger",
        "Ovod",
        "Amatola",
        "Nakhimov",
        "Antigone",
    },
    [ST.BENEDICT] = {
        "Elizabeth",
        "Ford",
        "Vikramaditya",
        "Liaoning",
        "Avenger",
        "Naruebet",
        "Washington",
        "Lincoln",
        "Garibaldi",
        "Eisenhower",
    },
    [ST.CRUCIBLE] = {
        "Sling",
        "Stark",
        "Torrid",
        "Kicker",
        "Flummox",
        "3rd Charm",
    },
    [ST.CROW] = {
        "Sparrow",
        "Sizzle",
        "Squawk",
        "Corvus",
        "Phoenix",
        "Snowbird",
        "Hawk",
    },
    [ST.ENDER] = {
        "Mongo",
        "Godzilla",
        "Leviathan",
        "Kraken",
        "Jupiter",
        "Saturn",
    },
    [ST.FLAVIA_PFALCON] = {
        "Ladyhawke",
        "Hunter",
        "Seeker",
        "Gyrefalcon",
        "Kestrel",
        "Magpie",
        "Bandit",
        "Buccaneer",
    },
    [ST.HATHCOCK] = {
        "Hayha",
        "Waldron",
        "Plunkett",
        "Mawhinney",
        "Furlong",
        "Zaytsev",
        "Pavlichenko",
        "Pegahmagabow",
        "Fett",
        "Hawkeye",
        "Hanzo",
    },
    [ST.KIRIYA] = {
        "Cavour",
        "Reagan",
        "Gaulle",
        "Paulo",
        "Truman",
        "Stennis",
        "Kuznetsov",
        "Roosevelt",
        "Vinson",
        "Old Salt",
    },
    [ST.MAVERICK] = {
        "Angel",
        "Thunderbird",
        "Roaster",
        "Magnifier",
        "Hedge",
        "Festoon",
        "Earp",
        "Schwartz",
        "Tentacular",
        "Prickly",
        "Hickok",
        "Clifton",
        "Holliday",
        "Sundance",
    },
    [ST.MP52_HORNET] = {
        "Dragonfly",
        "Scarab",
        "Vespa",
        "Yellow Jacket",
        "Jimminy",
        "Flik",
        "Thorny",
        "Buzz",
    },
    [ST.NAUTILUS] = {
        "October",
        "Abdiel",
        "Manxman",
        "Newcon",
        "Nusret",
        "Pluton",
        "Amiral",
        "Amur",
        "Heinkel",
        "Dornier",
    },
    [ST.PHOBOS_M3P] = {
        "Blinder",
        "Castillo",
        "Centurion",
        "Cogitate",
        "Coyote",
        "Deimos",
        "Distortion",
        "Fortune",
        "Ganymede",
        "Gauntlet",
        "Haft",
        "Rage",
        "Retrograde",
        "Shade",
        "Shadow",
        "Thebe",
        "Thrust",
        "Trident",
    },
    [ST.PIRANHA] = {
        "Razor",
        "Biter",
        "Ripper",
        "Voracious",
        "Carnivorous",
        "Characid",
        "Vulture",
        "Predator",
    },
    ["Proto-Atlantis"] = {
        "Narsil",
        "Blade",
        "Decapitator",
        "Trisect",
        "Sabre",
    },
    ["Redhook"] = {
        "Headhunter",
        "Thud",
        "Troll",
        "Scalper",
        "Shark",
    },
    [ST.REPULSE] = {
        "Fiddler",
        "Brinks",
        "Loomis",
        "Mowag",
        "Patria",
        "Pandur",
        "Terrex",
        "Komatsu",
        "Eitan",
    },
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
    [ST.STINGRAY] = {
        "Buzzer",
        "Flitter",
        "Zippiticus",
        "Hopper",
        "Molt",
        "Stinger",
        "Stripe",
    },
    ["Stricken"] = {
        "Blazon",
        "Streaker",
        "Pinto",
        "Spear",
        "Javelin",
    },
    ["Surkov"] = {
        "Sting",
        "Sneak",
        "Bingo",
        "Thrill",
        "Vivisect",
    },
    [ST.VINDICATOR] = {
        "Excelsior",
        "Velociraptor",
        "Thunder",
        "Kona",
        "Encounter",
        "Perth",
        "Aspern",
        "Panther",
    },
    [ST.ZX_LINDWORM] = {
        "Seagull",
        "Catapult",
        "Blowhard",
        "Flapper",
        "Nixie",
        "Pixie",
        "Tinkerbell",
    },
}

local function copyPool(pool)
    local copy = {}
    for index, name in ipairs(pool) do
        copy[index] = name
    end
    return copy
end

--- Returns a fresh copy of a shared pool.
--- @tparam string template Ship template name.
--- @treturn table|nil Call-sign pool, or nil when no shared pool exists.
function M.pool(template)
    local names = shared_pools[template]
    if names == nil then
        return nil
    end
    return copyPool(names)
end

--- Creates the player ship name pools for a scenario.
--- @tparam[opt] table pools Scenario-specific pools or shared pool overrides.
--- @treturn table Ship template names mapped to call-sign pools.
function M.forScenario(pools)
    local result = {}
    for template, names in pairs(shared_pools) do
        result[template] = copyPool(names)
    end
    for template, names in pairs(pools or {}) do
        result[template] = copyPool(names)
    end
    return result
end

--- Creates a table containing only the shared player ship name pools.
--- @treturn table Ship template names mapped to call-sign pools.
function M.shared()
    return M.forScenario()
end

return M
