-- This utility can be used to place a station at a particular location of random size,
-- with a colorful name and description. If you write your station communications
-- routines for it, the station will include various services, general station
-- information and station history. If you define your station comms routine in function
-- commsStation, placement will include setting the station to use that function.

-- Potential global variables that may interact with these functions:
--
-- function commsStation:
--     If defined, the placed station will be set to use it for communications.
-- string stationFaction:
--     Defines the station's faction if the faction parameter is nil.
-- table station_pool:
--     Defined here if not already defined. Helps avoid duplicate stations.
-- table componentGoods:
--     Defined here if not already defined.
-- table mineralGoods:
--     Defined here if not already defined.
-- number difficulty:
--     Default to 1 (normal) if not already defined.
-- table station_priority:
--     Defined here if not already defined. See populateStationPool.
-- table station_template_chance:
--     Defined here if not already defined. The value is the modification of the
--     chance out of 100 that a station will have a service based on station template.
-- table faction_station_service_chance:
--     Defined here if not already defined. The value is the modification of the
--     chance out of 100 that a station will have a service based on station faction.
-- string sizeTemplate:
--     Set to the station template size if the station size is selected randomly.

require("ee.lua")

local sinister_names = {
    "Aramanth",
    "Empok Nor",
    "Ganalda",
    "Hassenstadt",
    "Kaldor",
    "Magenta Mesra",
    "Mos Eisley",
    "Questa Verde",
    "R'lyeh",
    "Scarlet Citadel",
    "Stahlstadt",
    "Ticonderoga",
    "Uruk",
    "Ashoka",
    "Lanka",
    "Oberon",
    "R. U. Sirius",
    "Villa Straylight",
    "Tycho",
    "Iapetus",
    "Laconia",
    "Castila",
    "Eudoxia",
    "Fusang",
    "Gedara",
    "Gewitter",
    "Ragnar Anchorage",
    "Black Hammer",
    "Blood Razor",
    "Amorris",
    "Sayblohn",
    "Kauronia",
    "Solar Terror",
    "Takonda",
    "Taraloon",
    "Jagomir",
    "Laakteen Depot",
    "Nelori",
    "Yarrum",
    "Enthra",
    "Woxoxit",
    "Vosak",
    "Maranga",
    "Mewudoh",
    "Jeuaiei",
    "Mada",
    "Tandorian",
    "Jaq",
    "Kuzukoh",
}

local function stationGood(cost, qty)
    return {
        quantity = qty or 5,
        cost = cost,
    }
end

local function stationDefaultServices()
    return {
        supplydrop = "friend",
        reinforcements = "friend",
        jumpsupplydrop = "friend",
    }
end

local function stationDefaultServiceCost()
    return {
        supplydrop = math.random(80, 120),
        reinforcements = math.random(125, 175),
        jumpsupplydrop = math.random(110, 140),
    }
end

local function stationDefaultReputationCost(neutral)
    return { friend = 1.0, neutral = neutral or 3.0 }
end

local function stationDefaultWeapons(difficulty)
    return {
        Homing = random(1, 13) <= (8 - difficulty),
        HVLI = random(1, 13) <= (9 - difficulty),
        Mine = random(1, 13) <= (7 - difficulty),
        Nuke = random(1, 13) <= (5 - difficulty),
        EMP = random(1, 13) <= (6 - difficulty),
    }
end

local function stationDefaultTrade()
    return { food = false, medicine = false, luxury = false }
end

local function stationBuild(spec)
    local weapons
    if spec.weapons ~= nil then
        weapons = spec.weapons
    else
        weapons = stationDefaultWeapons(difficulty)
        if spec.weapons_override ~= nil then
            for k, v in pairs(spec.weapons_override) do
                weapons[k] = v
            end
        end
    end
    return {
        weapon_available = weapons,
        services = spec.services or stationDefaultServices(),
        service_cost = spec.service_cost or stationDefaultServiceCost(),
        reputation_cost_multipliers = spec.reputation_cost_multipliers
            or stationDefaultReputationCost(spec.reputation_neutral),
        trade = spec.trade or stationDefaultTrade(),
        goods = spec.goods or {},
        description = spec.description or "",
        general = spec.general or "",
        history = spec.history or "",
        weapon_cost = spec.weapon_cost,
        buy = spec.buy,
    }
end

local function stationEmpty()
    return {
        goods = {},
        description = "",
        general = "",
        history = "",
    }
end

-- placeStation returns the station placed or nil if there was an error.
-- placeStation sets the global sizeTemplate if selected randomly via szt function.
function placeStation(x, y, name, faction, size, diagnostic)
    -- x and y are the position of the station.
    -- name should be the name of the station or the name of the station group.
    -- Omit name to get random station from groups in priority order. See pickStation.
    -- Special values across groups: Random, RandomHumanNeutral, RandomGenericSinister
    -- faction is the faction of the station
    -- If you omit faction, the global variable stationFaction will be used.
    -- If stationFaction is not defined, the faction will be set to Independent.
    -- size is the name of the station template to use
    -- If you omit size, the station template will be chosen at random via szt function.
    if x == nil then
        print(
            "The first parameter that the function placeStation expects is an x coordinate. Nil is not valid."
        )
        return nil
    end
    if y == nil then
        print(
            "The second parameter that the function placeStation expects is a y coordinate. Nil is not valid."
        )
        return nil
    end
    local group, station = pickStation(name, diagnostic, size)
    if group == nil then
        print(
            "place station error: Sub function pick station did not return a group name. Nil is not valid. Parameter name passed:",
            name
        )
        return nil
    end
    station:setPosition(x, y)

    if faction ~= nil then
        station:setFaction(faction)
    else
        if stationFaction ~= nil then
            station:setFaction(stationFaction)
            faction = stationFaction
        else
            station:setFaction("Independent")
            faction = "Independent"
        end
    end

    if faction_station_service_chance == nil then
        faction_station_service_chance = {
            ["Human Navy"] = 0,
            ["Kraylor"] = 0,
            ["Independent"] = 0,
            ["Arlenians"] = 0,
            ["Ghosts"] = 0,
            ["Ktlitans"] = 0,
            ["Exuari"] = 0,
            ["TSN"] = 0,
            ["USN"] = 0,
            ["CUF"] = 0,
        }
    end

    if diagnostic == nil then
        diagnostic = false
    else
        diagnostic = true
    end

    local size_matters = station_template_chance[station:getTypeName()] or 0
    local faction_matters = faction_station_service_chance[faction] or 0
    local base_chance = size_matters + faction_matters
    if station.comms_data.service_cost == nil then
        station.comms_data.service_cost = {}
    end

    -- Randomize the availability of some station services. Unless you write your station
    -- communication routines to take advantage of these, they'll be ignored,
    -- except for the last three. See below.
    local scalar_services = {
        { "probe_launch_repair", 20, true },
        { "scan_repair", 30, true },
        { "hack_repair", 10, true },
        { "combat_maneuver_repair", 15, true },
        { "self_destruct_repair", 25, true },
        { "jump_overcharge", 5, false }, -- no cost; jump overcharge is free
    }
    for _, entry in ipairs(scalar_services) do
        local svc_name, base = entry[1], entry[2]
        station.comms_data[svc_name] = random(1, 100) <= (base + base_chance)

        if station.comms_data[svc_name] and entry[3] then
            station.comms_data.service_cost[svc_name] = math.random(2, 8)
        end
    end
    --[[
    If you want a station where the players can dock to provide energy,
    repair hull and restock scan probes, set these to true after
    the station gets placed.
    ]]
    --
    station:setSharesEnergyWithDocked(random(1, 100) <= (50 + base_chance))
    station:setRepairDocked(random(1, 100) <= (55 + base_chance))
    station:setRestocksScanProbes(random(1, 100) <= (45 + base_chance))
    -- More repair services
    station.comms_data.system_repair = {}
    station.comms_data.coolant_pump_repair = {}
    local system_chance = 60 + base_chance
    for _, system in ipairs(SYSTEMS) do
        station.comms_data.system_repair[system] = random(1, 100)
            <= system_chance
        station.comms_data.coolant_pump_repair[system] = random(1, 100)
            <= system_chance
    end
    return station
end

function setStationTemplate(station, size)
    if size == nil then
        station:setTemplate(szt())
    else
        if station_template_chance[size] ~= nil then
            station:setTemplate(size)
        else
            station:setTemplate(szt())
        end
    end
end

local function selectFromGroup(group, label, diagnostic, size)
    local stations = station_pool[group]
    if stations == nil then
        return nil
    end

    local names = {}
    for n, _ in pairs(stations) do
        table.insert(names, n)
    end
    if #names == 0 then
        return nil
    end

    local pick_name = names[math.random(#names)]
    local pick_details = stations[pick_name]
    local station = SpaceStation()
        :setCallSign(pick_name)
        :setDescription(pick_details.description)
    setStationTemplate(station, size)

    if commsStation ~= nil then
        station:setCommsScript(""):setCommsFunction(commsStation)
    end

    station.comms_data = pick_details
    station_pool[group][pick_name] = nil

    if diagnostic then
        print(
            "Place station diagnostic: pick station returned group:",
            group,
            "...and station:",
            station,
            station:getCallSign(),
            "name is " .. tostring(label)
        )
    end

    return group, station
end

function pickStation(name, diagnostic, size)
    if station_pool == nil then
        populateStationPool()
    end

    if station_template_chance == nil then
        station_template_chance = {
            ["Small Station"] = 0,
            ["Medium Station"] = 20,
            ["Large Station"] = 30,
            ["Huge Station"] = 40,
        }
    end

    if name == nil then
        -- Default to random in priority order: first non-empty group wins.
        for _, group in ipairs(station_priority) do
            local g, s = selectFromGroup(group, "nil", diagnostic, size)
            if g ~= nil then
                return g, s
            end
        end
        if diagnostic then
            print(
                "Place station diagnostic: Pick station returned nothing, station selection lists empty, all groups exhausted, name is nil."
            )
        end
        return nil
    elseif
        name == "Random"
        or name == "RandomHumanNeutral"
        or name == "RandomGenericSinister"
    then
        local filter
        if name == "Random" then
            filter = function()
                return true
            end
        elseif name == "RandomHumanNeutral" then
            filter = function(g)
                return g ~= "Generic" and g ~= "Sinister"
            end
        else
            filter = function(g)
                return g == "Generic" or g == "Sinister"
            end
        end
        local candidates = {}
        for group, stations in pairs(station_pool) do
            if filter(group) then
                for n, d in pairs(stations) do
                    table.insert(
                        candidates,
                        { group = group, name = n, details = d }
                    )
                end
            end
        end

        if #candidates == 0 then
            if diagnostic then
                print(
                    "Place station diagnostic: Pick station returned nothing, name is "
                        .. name
                )
            end
            return nil
        end

        local pick = candidates[math.random(#candidates)]
        local station = SpaceStation()
            :setCallSign(pick.name)
            :setDescription(pick.details.description)
        setStationTemplate(station, size)

        if commsStation ~= nil then
            station:setCommsScript(""):setCommsFunction(commsStation)
        end

        station.comms_data = pick.details
        station_pool[pick.group][pick.name] = nil

        if diagnostic then
            print(
                "Place station diagnostic: pick station returned group:",
                pick.group,
                "...and station:",
                station,
                station:getCallSign(),
                "name is " .. name
            )
        end

        return pick.group, station
    else
        local g, s = selectFromGroup(name, name, diagnostic, size)
        if g ~= nil then
            return g, s
        end

        for group, stations in pairs(station_pool) do
            if stations[name] ~= nil then
                local pick_details = stations[name]
                local station = SpaceStation()
                    :setCallSign(name)
                    :setDescription(pick_details.description)
                setStationTemplate(station, size)

                if commsStation ~= nil then
                    station:setCommsScript(""):setCommsFunction(commsStation)
                end

                station.comms_data = pick_details
                station_pool[group][name] = nil

                return group, station
            end
        end

        print(
            "Place station error: Name provided to place station not found in groups or stations, nor is it an accepted specialized name, like Random, RandomHumanNeutral or RandomGenericSinister"
        )

        return nil
    end
end

-- Randomly choose station size template.
function szt()
    local stationSizeRandom = random(1, 100)

    if stationSizeRandom <= 8 then
        sizeTemplate = "Huge Station" -- 8% huge
    elseif stationSizeRandom <= 24 then
        sizeTemplate = "Large Station" -- 16% large
    elseif stationSizeRandom <= 50 then
        sizeTemplate = "Medium Station" -- 26% medium
    else
        sizeTemplate = "Small Station" -- 50% small
    end

    return sizeTemplate
end

local function pickFromList(t, exclude)
    local good = t[math.random(#t)]
    if exclude == nil then
        return good
    end
    repeat
        good = t[math.random(#t)]
    until good ~= exclude
    return good
end

function randomComponent(exclude)
    if componentGoods == nil then
        componentGoods = {
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
    end
    return pickFromList(componentGoods, exclude)
end

function randomMineral(exclude)
    if mineralGoods == nil then
        mineralGoods = {
            "nickel",
            "platinum",
            "gold",
            "dilithium",
            "tritanium",
            "cobalt",
        }
    end
    return pickFromList(mineralGoods, exclude)
end

function populateStationPool()
    -- Expected values for global difficulty variable:
    -- 1 = normal
    -- 5 = easy
    -- 2 = hard
    -- Default to normal if not defined

    if difficulty == nil then
        difficulty = 1
    end
    station_pool = {
        ["Science"] = {
            ["Asimov"] = stationBuild({
                weapons_override = { Homing = true, Mine = true },
                reputation_neutral = 3.0,
                goods = {
                    tractor = stationGood(48),
                    repulsor = stationGood(48),
                },
                description = _(
                    "scienceDescription-station",
                    "Training and coordination"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We train naval cadets in routine and specialized functions aboard space vessels and coordinate naval activity throughout the sector."
                ),
                history = _(
                    "stationStory-comms",
                    "The original station builders were fans of the late 20th-century scientist and author Isaac Asimov. The station was initially named Foundation. It started as a stellar observatory, then became a supply stop, and as it has grown has become the region's educational and coordination hub."
                ),
            }),
            ["Armstrong"] = stationBuild({
                weapons_override = { HVLI = true, EMP = true },
                goods = { warp = stationGood(77), repulsor = stationGood(62) },
                trade = {
                    food = random(1, 100) <= 45,
                    medicine = false,
                    luxury = false,
                },
                buy = { [randomMineral()] = math.random(40, 200) },
                description = _(
                    "scienceDescription-station",
                    "Warp and impulse engine manufacturing"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We manufacture warp, impulse, and jump engines for the Human Navy fleet as well as other independent clients on a contract basis."
                ),
                history = _(
                    "stationStory-comms",
                    "The station is named after the 19th-century astronaut as well as the fictionlized stations that followed. The station initially constructed spaceworthy vessels, but over time it transitioned into specializing in propulsion systems."
                ),
            }),
            ["Broeck"] = stationBuild({
                goods = { warp = stationGood(36) },
                trade = {
                    food = random(1, 100) <= 14,
                    medicine = false,
                    luxury = random(1, 100) < 62,
                },
                buy = { [randomMineral()] = math.random(40, 200) },
                description = _(
                    "scienceDescription-station",
                    "Warp drive components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We provide warp drive engines and components."
                ),
                history = _(
                    "stationStory-comms",
                    "This station is named after Chris Van Den Broeck, who did some initial research into the possibility of warp drives in the late 20th century on Earth."
                ),
            }),
            ["Coulomb"] = stationBuild({
                reputation_neutral = 3.0,
                goods = { circuit = stationGood(50) },
                trade = {
                    food = random(1, 100) <= 35,
                    medicine = false,
                    luxury = random(1, 100) < 82,
                },
                buy = { [randomMineral()] = math.random(40, 200) },
                description = _(
                    "scienceDescription-station",
                    "Shielded circuitry fabrication"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We make a large variety of circuits for numerous ship systems shielded from sensor detection and external control interference."
                ),
                history = _(
                    "stationStory-comms",
                    "Our station is named after the law which quantifies the amount of force with which stationary electrically charged particals repel or attact each other, a fundamental principle in the design of our circuits."
                ),
            }),
            ["Heyes"] = stationBuild({
                weapons_override = { HVLI = true },
                reputation_neutral = 3.0,
                goods = { sensor = stationGood(72) },
                trade = {
                    food = random(1, 100) <= 32,
                    medicine = false,
                    luxury = true,
                },
                buy = { [randomMineral()] = math.random(40, 200) },
                description = _(
                    "scienceDescription-station",
                    "Sensor components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We research and manufacture sensor components and systems"
                ),
                history = _(
                    "stationStory-comms",
                    "The station is named after Tony Heyes, the inventor of some of the earliest electromagnetic sensors in the mid-20th century on Earth in the United Kingdom, which aided in mobility for blind humans."
                ),
            }),
            ["Hossam"] = stationBuild({
                reputation_neutral = 3.0,
                goods = { nanites = stationGood(90) },
                trade = {
                    food = random(1, 100) < 24,
                    medicine = random(1, 100) < 44,
                    luxury = random(1, 100) < 63,
                },
                description = _(
                    "scienceDescription-station",
                    "Nanite supplier"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We provide nanites for various organic and non-organic systems."
                ),
                history = _(
                    "stationStory-comms",
                    "This station is named after the Israeli nanotechnologist Hossam Haick, from the early 21st century on Earth."
                ),
            }),
            ["Maiman"] = stationBuild({
                weapons_override = { HVLI = false },
                reputation_neutral = 3.0,
                goods = { beam = stationGood(70) },
                trade = {
                    food = random(1, 100) <= 75,
                    medicine = true,
                    luxury = false,
                },
                buy = { [randomMineral()] = math.random(40, 200) },
                description = _(
                    "scienceDescription-station",
                    "Energy beam components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We research and manufacture energy beam components and systems."
                ),
                history = _(
                    "stationStory-comms",
                    "The station is named after Theodore Maiman, who researched and built the first laser in the mid-20th century on Earth."
                ),
            }),
            ["Malthus"] = stationBuild({
                reputation_neutral = 3.0,
                trade = {
                    food = random(1, 100) <= 65,
                    medicine = false,
                    luxury = false,
                },
                description = _(
                    "scienceDescription-station",
                    "Gambling and resupply"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "The oldest station in the quadrant."
                ),
                history = "",
            }),
            ["Marconi"] = stationBuild({
                reputation_neutral = 3.0,
                goods = { beam = stationGood(80) },
                trade = {
                    food = random(1, 100) <= 53,
                    medicine = false,
                    luxury = true,
                },
                description = _(
                    "scienceDescription-station",
                    "Energy beam components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We manufacture energy beam components."
                ),
                history = _(
                    "stationStory-comms",
                    "Station named after Guglielmo Marconi, an Italian inventor from early 20th-century Earth who, along with Nikola Tesla, claimed to have invented a death ray or particle beam weapon."
                ),
            }),
            ["Miller"] = stationBuild({
                reputation_neutral = 3.0,
                goods = { optic = stationGood(60) },
                trade = {
                    food = random(1, 100) <= 68,
                    medicine = false,
                    luxury = false,
                },
                description = _(
                    "scienceDescription-station",
                    "Exobiology research"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We study recently discovered life forms not native to Earth"
                ),
                history = _(
                    "stationStory-comms",
                    "This station was named after one of the early exobiologists from mid-20th-century Earth, Dr. Stanley Miller"
                ),
            }),
            ["Shawyer"] = stationBuild({
                reputation_neutral = 2.0,
                goods = { impulse = stationGood(100) },
                trade = {
                    food = random(1, 100) <= 42,
                    medicine = false,
                    luxury = true,
                },
                description = _(
                    "scienceDescription-station",
                    "Impulse engine components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We research and manufacture impulse engine components and systems."
                ),
                history = _(
                    "stationStory-comms",
                    "The station is named after Roger Shawyer, who built the first prototype impulse engine in the early 21st century."
                ),
            }),
        },
        ["History"] = {
            ["Archimedes"] = stationBuild({
                reputation_neutral = 3.0,
                goods = { beam = stationGood(80) },
                trade = { food = true, medicine = false, luxury = true },
                description = _(
                    "scienceDescription-station",
                    "Energy and particle beam components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We fabricate general and specialized components for ship beam systems."
                ),
                history = _(
                    "stationStory-comms",
                    "This station was named after Archimedes, who, according to legend, used a series of adjustable focal length mirrors to focus sunlight on a Roman naval fleet invading Syracuse and set fire to it."
                ),
            }),
            ["Chatuchak"] = stationBuild({
                weapons = {
                    Homing = random(1, 10) <= (8 - difficulty),
                    HVLI = random(1, 10) <= (9 - difficulty),
                    Mine = false,
                    Nuke = random(1, 10) <= (5 - difficulty),
                    EMP = random(1, 10) <= (6 - difficulty),
                },
                reputation_neutral = 2.0,
                goods = { luxury = stationGood(60) },
                description = _(
                    "scienceDescription-station",
                    "Trading station"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "Only the largest market and trading location in twenty sectors. You can find your heart's desire here."
                ),
                history = _(
                    "stationStory-comms",
                    "Modeled after the early 21st-century bazaar on Earth in Bangkok, Thailand. Designed and built with trade and commerce in mind."
                ),
            }),
            ["Grasberg"] = stationBuild({
                reputation_neutral = 2.0,
                goods = { luxury = stationGood(70) },
                trade = { food = true, medicine = false, luxury = false },
                buy = { [randomComponent()] = math.random(40, 200) },
                description = _("scienceDescription-station", "Mining"),
                general = _(
                    "stationGeneralInfo-comms",
                    "We mine nearby asteroids for precious minerals and process them for sale."
                ),
                history = _(
                    "stationStory-comms",
                    "This station's name is inspired by a large gold mine on Earth in Indonesia. The station builders hoped to have a similar amount of minerals found amongst these asteroids."
                ),
            }),
            ["Hayden"] = stationBuild({
                reputation_neutral = 2.0,
                goods = { nanites = stationGood(65) },
                trade = {
                    food = random(1, 100) <= 85,
                    medicine = false,
                    luxury = false,
                },
                description = _(
                    "scienceDescription-station",
                    "Observatory and stellar mapping"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We study the cosmos and map stellar phenomena. We also track moving asteroids. Look out! Just kidding."
                ),
                history = _(
                    "stationStory-comms",
                    "Station named in honor of Charles Hayden, whose philanthropy continued astrophysical research and education on Earth in the early 20th century."
                ),
            }),
            ["Lipkin"] = stationBuild({
                weapons_override = { Mine = false },
                reputation_neutral = 2.0,
                goods = { autodoc = stationGood(76) },
                trade = { food = false, medicine = false, luxury = true },
                description = _(
                    "scienceDescription-station",
                    "Autodoc components"
                ),
                general = "",
                history = _(
                    "stationStory-comms",
                    "The station is named after Dr. Lipkin, who pioneered some of the research and application around robot assisted surgery in the area of partial nephrectomy for renal tumors in the early 21st century on Earth."
                ),
            }),
            ["Madison"] = stationBuild({
                weapons_override = { Homing = false },
                reputation_neutral = 2.0,
                goods = { luxury = stationGood(math.random(60, 70)) },
                trade = { food = false, medicine = true, luxury = false },
                description = _(
                    "scienceDescription-station",
                    "Zero-gravity sports and entertainment"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "Take in a game or two, or perhaps see a show"
                ),
                history = _(
                    "stationStory-comms",
                    "Named after Madison Square Garden from 21st-century Earth, this station was designed to serve similar purposes in space as a venue for sports and entertainment."
                ),
            }),
            ["Rutherford"] = stationBuild({
                reputation_neutral = 2.0,
                goods = { shield = stationGood(90) },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = random(1, 100) < 43,
                },
                description = _(
                    "scienceDescription-station",
                    "Shield components and research"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We research and fabricate components for ship shield systems."
                ),
                history = _(
                    "stationStory-comms",
                    "This station was named after Rutherford Appleton Laboratory, a national research institution in the United Kingdom on Earth, which conducted preliminary research into the feasability of generating an energy shield in the late 20th century."
                ),
            }),
            ["Toohie"] = stationBuild({
                reputation_neutral = 3.0,
                goods = { shield = stationGood(90) },
                trade = {
                    food = random(1, 100) <= 21,
                    medicine = false,
                    luxury = true,
                },
                description = _(
                    "scienceDescription-station",
                    "Shield and armor components and research"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We research and make general and specialized components for ship shield and ship armor systems."
                ),
                history = _(
                    "stationStory-comms",
                    "This station was named after Alexander Toohie, one of the earliest researchers in shield technology, back when it was considered impractical to construct shields due to the physics involved."
                ),
            }),
        },
        ["Alt Sci Fi"] = {
            ["Cortex Gate"] = stationBuild({
                weapons_override = { Homing = false, EMP = true },
                reputation_neutral = 2.0,
                goods = {
                    battery = stationGood(66),
                    software = stationGood(115),
                },
                description = _(
                    "scienceDescription-station",
                    "Battery and software engineering"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We provide high quality high capacity batteries and specialized software for all shipboard systems."
                ),
                history = _(
                    "stationStory-comms",
                    "The station was founded by a collective of electrical and software engineers who distrusted third-party systems. They built their own from scratch, and demand has kept them busy since."
                ),
            }),
            ["Bulwark"] = stationBuild({
                weapons_override = { HVLI = true, EMP = true },
                goods = { shield = stationGood(90) },
                trade = { food = false, medicine = false, luxury = true },
                buy = { [randomMineral()] = math.random(40, 200) },
                description = _(
                    "scienceDescription-station",
                    "Shield and armor research"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "The finest shield and armor manufacturer in the quadrant."
                ),
                history = _(
                    "stationStory-comms",
                    "Originally a military outpost, the station's fabrication bays were repurposed for defensive systems production after an armistice. The quality of their work has never declined."
                ),
            }),
            ["Wavecrest"] = stationBuild({
                weapons_override = { Mine = false },
                goods = { communication = stationGood(58) },
                trade = { food = false, medicine = false, luxury = false },
                buy = { [randomMineral()] = math.random(40, 200) },
                description = _(
                    "scienceDescription-station",
                    "Communication components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We provide a range of communication equipment and software for use aboard ships."
                ),
                history = _(
                    "stationStory-comms",
                    "The station was first built as a deep-space relay outpost during the early days of interstellar exploration. As the sector grew, so did this station, eventually evolving into a full manufacturing hub for communication systems."
                ),
            }),
            ["Mechadyne"] = stationBuild({
                weapons_override = { Homing = false },
                reputation_neutral = 3.0,
                goods = { robotic = stationGood(90) },
                trade = {
                    food = random(1, 100) <= 35,
                    medicine = false,
                    luxury = true,
                },
                buy = { [randomComponent("robotic")] = math.random(40, 200) },
                description = _(
                    "scienceDescription-station",
                    "Robotic research"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We research and provide robotic systems and components."
                ),
                history = _(
                    "stationStory-comms",
                    "A consortium of cyberneticists and mechanical engineers pooled their resources to create a dedicated research center for autonomous systems. Their breakthroughs in actuator design and decision algorithms are used across the sector."
                ),
            }),
            ["Tensilica"] = stationBuild({
                reputation_neutral = 2.0,
                goods = { filament = stationGood(42) },
                description = _(
                    "scienceDescription-station",
                    "Advanced Material components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We fabricate several different kinds of materials critical to various space industries, such as shipbuilding, station construction, and mineral extraction"
                ),
                history = _(
                    "stationStory-comms",
                    "The station began as a materials science lab investigating high-tensile alloys for deep-space construction. Their discoveries led to a full production line that now supplies construction firms across the sector."
                ),
            }),
            ["Thrust Harbor"] = stationBuild({
                reputation_neutral = 3.0,
                goods = { impulse = stationGood(124) },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = random(1, 100) < 78,
                },
                description = _(
                    "scienceDescription-station",
                    "Impulse engine components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We supply high-quality impulse engines and parts for use aboard ships"
                ),
                history = _(
                    "stationStory-comms",
                    "The station was founded by a team of propulsion engineers who believed that conventional thruster design had room for dramatic improvement. Their iterative refinements have made them a trusted name in sublight travel."
                ),
            }),
            ["Autonom"] = stationBuild({
                reputation_neutral = 2.0,
                goods = { android = stationGood(73) },
                trade = { food = false, medicine = false, luxury = true },
                description = _(
                    "scienceDescription-station",
                    "Android components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "Supplier of android components, programming, and service"
                ),
                history = _(
                    "stationStory-comms",
                    "Founded by a cooperative of engineers who saw the growing demand for synthetic laborers and companions. Their modular design philosophy makes repairs and upgrades straightforward."
                ),
            }),
            ["Beamhold"] = stationBuild({
                goods = { transporter = stationGood(63) },
                trade = { food = false, medicine = false, luxury = true },
                description = _(
                    "scienceDescription-station",
                    "Transporter components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We provide transporters used aboard ships as well as the components for repair and maintenance."
                ),
                history = _(
                    "stationStory-comms",
                    "The station was founded by the lead engineers from a defunct transporter manufacturing conglomerate. When the parent company folded, they pooled their severance and built a better facility from the ground up."
                ),
            }),
            ["Lucky Draw"] = stationBuild({
                reputation_neutral = 2.0,
                goods = { luxury = stationGood(math.random(30, 80)) },
                description = _(
                    "scienceDescription-station",
                    "Commerce and gambling"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "Come play some games and shop. House take does not exceed 4 percent."
                ),
                history = _(
                    "stationStory-comms",
                    "What started as a single card table in a maintenance bay grew organically into one of the busiest entertainment hubs in the sector. The original table is still on display in the main atrium."
                ),
            }),
            ["Rosetta"] = stationBuild({
                weapons_override = { Mine = true, Nuke = false },
                reputation_neutral = 2.0,
                goods = { filament = stationGood(46) },
                description = _(
                    "scienceDescription-station",
                    "Xenopsychology training"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We provide classes and simulation to help train diverse species in how to relate to each other."
                ),
                history = _(
                    "stationStory-comms",
                    "Psychologists, sociologists, and xenobiologists founded this station as a dedicated institute for interspecies communication. The curriculum has been adopted by several naval academies."
                ),
            }),
            ["Astra"] = stationBuild({
                weapons = {
                    Homing = true,
                    HVLI = true,
                    Mine = true,
                    Nuke = false,
                    EMP = false,
                },
                weapon_cost = {
                    Homing = math.random(2, 5),
                    HVLI = 2,
                    Mine = math.random(2, 5),
                },
                goods = { shield = stationGood(90) },
                description = _(
                    "scienceDescription-station",
                    "Casino and gambling"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We never tell you the odds, because they're always in your favor!"
                ),
                history = _(
                    "stationStory-comms",
                    "A front for an interstellar crime syndicate that launders and fences much of its ill-gotten goods through this seedy hall of games."
                ),
            }),
            ["Crossway"] = stationBuild({
                goods = { luxury = stationGood(60) },
                trade = { food = true, medicine = true, luxury = false },
                description = _(
                    "scienceDescription-station",
                    "Trading station"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "Come to Crossway Bazaar for all your trade and commerce needs and desires!"
                ),
                history = _(
                    "stationStory-comms",
                    "Independent traders from a dozen systems formed a cooperative to establish this central marketplace. Over time, permanent storefronts replaced the temporary stalls, but the spirit of the bazaar remains."
                ),
            }),
            ["Auton Yard"] = stationBuild({
                weapons_override = { HVLI = false },
                reputation_neutral = 3.0,
                goods = { android = stationGood(93) },
                trade = { food = false, medicine = true, luxury = false },
                buy = {
                    [randomMineral()] = math.random(40, 200),
                    [randomComponent("android")] = math.random(40, 200),
                },
                description = _(
                    "scienceDescription-station",
                    "Android components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "Androids and their parts, maintenance, and recycling."
                ),
                history = _(
                    "stationStory-comms",
                    "The station grew out of a small repair shop that specialized in synthetic personnel. As demand for android labor increased, the facility expanded into manufacturing and recycling."
                ),
            }),
            ["Flux Gate"] = stationBuild({
                reputation_neutral = 3.0,
                goods = { transporter = stationGood(76) },
                trade = {
                    food = random(1, 100) < 13,
                    medicine = true,
                    luxury = random(1, 100) < 43,
                },
                description = _(
                    "scienceDescription-station",
                    "Transporter components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We research and fabricate high-quality transporters and transporter components for use aboard ships."
                ),
                history = _(
                    "stationStory-comms",
                    "The station was founded by a veteran logistics coordinator who saw an opportunity to improve transporter reliability. Their precision components are now standard equipment on many civilian vessels."
                ),
            }),
            ["Concord"] = stationBuild({
                reputation_neutral = 2.0,
                goods = { luxury = stationGood(95) },
                description = _(
                    "scienceDescription-station",
                    "Diplomatic training"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "The premeire academy for leadership and diplomacy training in the region."
                ),
                history = _(
                    "stationStory-comms",
                    "The station was conceived during a fragile peace negotiation between human factions. The delegates agreed that a permanent center for diplomatic study would help prevent future conflicts."
                ),
            }),
            ["Liftmaster"] = stationBuild({
                weapons_override = { Homing = true, HVLI = false },
                reputation_neutral = 3.0,
                goods = { lifter = stationGood(61) },
                trade = { food = false, medicine = false, luxury = true },
                description = _(
                    "scienceDescription-station",
                    "Load lifters and components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We provide load lifters and components for various ship systems."
                ),
                history = _(
                    "stationStory-comms",
                    "The station was built around a heavy-equipment machine shop that had been operating for decades. When the original owners retired, the foreman bought the operation and expanded into full-scale manufacturing."
                ),
            }),
            ["Crane"] = stationBuild({
                weapons_override = { Homing = false, HVLI = true },
                reputation_neutral = 3.0,
                goods = { lifter = stationGood(82) },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = random(1, 100) < 47,
                },
                description = _(
                    "scienceDescription-station",
                    "Load lifters and components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We provide load lifters and components."
                ),
                history = _(
                    "stationStory-comms",
                    "The station was started by a cargo-hauler cooperative that grew tired of overpaying for replacement parts. They bought their own manufacturing equipment and soon began selling to other haulers."
                ),
            }),
            ["Carousel"] = stationBuild({
                reputation_neutral = 2.0,
                goods = { luxury = stationGood(math.random(30, 80)) },
                description = _(
                    "scienceDescription-station",
                    "Routine maintenance and entertainment"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "Stop by for repairs. Take in one of our juggling shows featuring the four-armed jugglers from the outer ring."
                ),
                history = _(
                    "stationStory-comms",
                    "Traveling entertainers and independent mechanics converged at this waypoint, turning a simple rest stop into a vibrant community of performers and repair specialists."
                ),
            }),
            ["Onom"] = stationBuild({
                reputation_neutral = 3.0,
                goods = { android = stationGood(73) },
                trade = { food = false, medicine = false, luxury = true },
                description = _(
                    "scienceDescription-station",
                    "Android components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We create androids and android components."
                ),
                history = _(
                    "stationStory-comms",
                    "The station was established by a group of engineers who believed that synthetic lifeforms should be accessible to all. Their open-source designs have been adapted for everything from domestic service to hazardous environment exploration."
                ),
            }),
            ["Sentinel"] = stationBuild({
                reputation_neutral = 3.0,
                goods = { software = stationGood(140) },
                description = _(
                    "scienceDescription-station",
                    "Automated weapons systems"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We research and create automated weapons systems to improve ship combat capability."
                ),
                history = _(
                    "stationStory-comms",
                    "The station was founded by a group of defense contractors who foresaw the growing need for automated turret and point-defense systems. Their early-warning algorithms have saved countless vessels from ambush."
                ),
            }),
            ["Logi Lodge"] = stationBuild({
                goods = { food = stationGood(1) },
                description = _(
                    "scienceDescription-station",
                    "Logistics coordination"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We support the stations and ships in the area with planning and communication services."
                ),
                history = _(
                    "stationStory-comms",
                    "Shipping companies founded this station to coordinate supply routes across their sectors. Its routing algorithms and communication relays keep traffic flowing smoothly."
                ),
            }),
            ["Filamentropolis"] = stationBuild({
                reputation_neutral = 3.0,
                goods = { filament = stationGood(42) },
                description = _(
                    "scienceDescription-station",
                    "Advanced material components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We create multiple types of advanced material components. Our most popular products are our filaments."
                ),
                history = _(
                    "stationStory-comms",
                    "After discovering a unique high-yield refining process, the station's founders cornered the market on structural filaments. The technique remains a closely guarded trade secret."
                ),
            }),
            ["Orbitalwerks"] = stationBuild({
                weapons_override = { Nuke = true },
                goods = { warp = stationGood(167) },
                description = _(
                    "scienceDescription-station",
                    "Ship building and maintenance facility"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We work on all aspects of astronaval shipbuilding and maintenance."
                ),
                history = _(
                    "stationStory-comms",
                    "Many of this station's ship models are researched, designed, and built entirely on site. Their designs seek to make the spacefaring experience as simple as possible, given the tremendous capabilities of the modern vessel."
                ),
            }),
            ["KwikDock"] = stationBuild({
                goods = {
                    food = stationGood(1, 10),
                    medicine = stationGood(5),
                    impulse = stationGood(math.random(65, 97)),
                },
                description = _(
                    "scienceDescription-station",
                    "Ship building and maintenance facility"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "If your motivator's shot, there's no cheaper replacement in this quadrant than here."
                ),
                history = _(
                    "stationStory-comms",
                    "Despite its run-down appearance, this station is home to some of the best salvage refurbishment techs and mechanics. A favorite maintenance stop among crews of outdated and out-of-support vessels."
                ),
            }),
            ["Warpwell"] = stationBuild({
                reputation_neutral = 3.0,
                goods = { warp = stationGood(140) },
                trade = { food = false, medicine = false, luxury = true },
                description = _(
                    "scienceDescription-station",
                    "Warp engine components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We specialize in the esoteric components necessary to make warp drives function properly."
                ),
                history = _(
                    "stationStory-comms",
                    "The station was founded by physicists and engineers who dedicated their careers to mastering faster-than-light travel. Their precision components are trusted by every major shipyard in known space."
                ),
            }),
        },
        ["Spec Sci Fi"] = {
            ["Alcaleica"] = stationBuild({
                goods = { optic = stationGood(66) },
                buy = { [randomMineral()] = math.random(40, 200) },
                description = _(
                    "scienceDescription-station",
                    "Optical Components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We make and supply optic components for various station and ship systems"
                ),
                history = _(
                    "stationStory-comms",
                    "This station continues the businesses from Earth based on the merging of several companies including Leica from Switzerland, the lens manufacturer and the Japanese advanced low carbon (ALCA) electronic and optic research and development company"
                ),
            }),
            ["Bethesda"] = stationBuild({
                reputation_neutral = 3.0,
                goods = {
                    autodoc = stationGood(36),
                    medicine = stationGood(5),
                    food = stationGood(1, math.random(5, 10)),
                },
                description = _(
                    "scienceDescription-station",
                    "Medical research"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We research and treat exotic medical conditions"
                ),
                history = _(
                    "stationStory-comms",
                    "The station is named after the United States national medical research center based in Bethesda, Maryland on earth which was established in the mid 20th century"
                ),
            }),
            ["Deer"] = stationBuild({
                goods = {
                    tractor = stationGood(90),
                    repulsor = stationGood(math.random(85, 95)),
                },
                trade = { food = false, medicine = false, luxury = true },
                description = _(
                    "scienceDescription-station",
                    "Repulsor and Tractor Beam Components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We can meet all your pushing and pulling needs with specialized equipment custom made"
                ),
                history = _(
                    "stationStory-comms",
                    "The station name comes from a short story by the 20th century author Clifford D. Simak as well as from the 19th century developer John Deere who inspired a company that makes the Earth bound equivalents of our products"
                ),
            }),
            ["Evondos"] = stationBuild({
                weapons_override = { HVLI = true },
                reputation_neutral = 3.0,
                goods = { autodoc = stationGood(56) },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = random(1, 100) < 41,
                },
                description = _(
                    "scienceDescription-station",
                    "Autodoc components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We provide components for automated medical machinery"
                ),
                history = _(
                    "stationStory-comms",
                    "The station is the evolution of the company that started automated pharmaceutical dispensing in the early 21st century on Earth in Finland"
                ),
            }),
            ["Feynman"] = stationBuild({
                weapons_override = { Mine = true },
                reputation_neutral = 3.0,
                goods = {
                    software = stationGood(115),
                    nanites = stationGood(79),
                },
                trade = { food = false, medicine = false, luxury = true },
                description = _(
                    "scienceDescription-station",
                    "Nanotechnology research"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We provide nanites and software for a variety of ship-board systems"
                ),
                history = _(
                    "stationStory-comms",
                    "This station's name recognizes one of the first scientific researchers into nanotechnology, physicist Richard Feynman"
                ),
            }),
            ["Mayo"] = stationBuild({
                goods = {
                    autodoc = stationGood(128),
                    food = stationGood(1),
                    medicine = stationGood(5),
                },
                description = _(
                    "scienceDescription-station",
                    "Medical Research"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We research exotic diseases and other human medical conditions"
                ),
                history = _(
                    "stationStory-comms",
                    "We continue the medical work started by William Worrall Mayo in the late 19th century on Earth"
                ),
            }),
            ["Olympus"] = stationBuild({
                reputation_neutral = 3.0,
                goods = { optic = stationGood(66) },
                description = _(
                    "scienceDescription-station",
                    "Optical components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We fabricate optical lenses and related equipment as well as fiber optic cabling and components"
                ),
                history = _(
                    "stationStory-comms",
                    "This station grew out of the Olympus company based on earth in the early 21st century. It merged with Infinera, then bought several software comapnies before branching out into space based industry"
                ),
            }),
            ["Panduit"] = stationBuild({
                reputation_neutral = 3.0,
                goods = { optic = stationGood(79) },
                trade = { food = false, medicine = false, luxury = true },
                description = _(
                    "scienceDescription-station",
                    "Optic components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We provide optic components for various ship systems"
                ),
                history = _(
                    "stationStory-comms",
                    "This station is an outgrowth of the Panduit corporation started in the mid 20th century on Earth in the United States"
                ),
            }),
            ["Shree"] = stationBuild({
                reputation_neutral = 3.0,
                goods = {
                    tractor = stationGood(90),
                    repulsor = stationGood(math.random(85, 95)),
                },
                trade = { food = false, medicine = false, luxury = true },
                description = _(
                    "scienceDescription-station",
                    "Repulsor and tractor beam components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We make ship systems designed to push or pull other objects around in space"
                ),
                history = _(
                    "stationStory-comms",
                    "Our station is named Shree after one of many tugboat manufacturers in the early 21st century on Earth in India. Tugboats serve a similar purpose for ocean-going vessels on earth as tractor and repulsor beams serve for space-going vessels today"
                ),
            }),
            ["Vactel"] = stationBuild({
                goods = { circuit = stationGood(50) },
                description = _(
                    "scienceDescription-station",
                    "Shielded Circuitry Fabrication"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We specialize in circuitry shielded from external hacking suitable for ship systems"
                ),
                history = _(
                    "stationStory-comms",
                    "We started as an expansion from the lunar based chip manufacturer of Earth legacy Intel electronic chips"
                ),
            }),
            ["Veloquan"] = stationBuild({
                reputation_neutral = 3.0,
                goods = { sensor = stationGood(68) },
                description = _(
                    "scienceDescription-station",
                    "Sensor components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We research and construct components for the most powerful and accurate sensors used aboard ships along with the software to make them easy to use"
                ),
                history = _(
                    "stationStory-comms",
                    "The Veloquan company has its roots in the manufacturing of LIDAR sensors in the early 21st century on Earth in the United States for autonomous ground-based vehicles. They expanded research and manufacturing operations to include various sensors for space vehicles. Veloquan was the result of numerous mergers and acquisitions of several companies including Velodyne and Quanergy"
                ),
            }),
            ["Tandon"] = stationBuild({
                reputation_neutral = 3.0,
                description = _(
                    "scienceDescription-station",
                    "Biotechnology research"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "Merging the organic and inorganic through research"
                ),
                history = _(
                    "stationStory-comms",
                    "Continued from the Tandon school of engineering started on Earth in the early 21st century"
                ),
            }),
        },
        ["Generic"] = {
            ["California"] = stationBuild({
                goods = {
                    gold = stationGood(90),
                    dilithium = stationGood(25, 2),
                },
                description = _("scienceDescription-station", "Mining station"),
                general = "",
                history = "",
            }),
            ["Carradine"] = stationBuild({
                reputation_neutral = 2.0,
                goods = { impulse = stationGood(100) },
                trade = {
                    food = random(1, 100) <= 42,
                    medicine = false,
                    luxury = true,
                },
                description = _(
                    "scienceDescription-station",
                    "Impulse engine components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We research and manufacture impulse engine components and systems"
                ),
                history = _(
                    "stationStory-comms",
                    "Named after one of the station commander's favorite actors from the 20th century"
                ),
            }),
            ["Impala"] = stationBuild({
                reputation_neutral = 3.0,
                goods = { luxury = stationGood(70) },
                trade = { food = true, medicine = false, luxury = true },
                buy = { [randomComponent()] = math.random(40, 200) },
                description = _("scienceDescription-station", "Mining"),
                general = _(
                    "stationGeneralInfo-comms",
                    "We mine nearby asteroids for precious minerals"
                ),
                history = "",
            }),
            ["Grup"] = stationBuild({
                weapons_override = { Mine = true },
                reputation_neutral = 3.0,
                goods = { nickel = stationGood(20) },
                trade = {
                    food = random(1, 100) < 50,
                    medicine = true,
                    luxury = random(1, 100) < 50,
                },
                buy = { [randomComponent()] = math.random(40, 200) },
                description = _("scienceDescription-station", "Mining station"),
                general = "",
                history = "",
            }),
            ["Grap"] = stationBuild({
                weapons_override = { Homing = true },
                reputation_neutral = 3.0,
                goods = { nickel = stationGood(20) },
                trade = {
                    food = random(1, 100) < 50,
                    medicine = true,
                    luxury = random(1, 100) < 50,
                },
                buy = { [randomComponent()] = math.random(40, 200) },
                description = _("scienceDescription-station", "Mining station"),
                general = "",
                history = "",
            }),
            ["Krak"] = stationBuild({
                weapons_override = { HVLI = true },
                reputation_neutral = 3.0,
                goods = { nickel = stationGood(20) },
                trade = {
                    food = random(1, 100) < 50,
                    medicine = true,
                    luxury = random(1, 100) < 50,
                },
                buy = { [randomComponent()] = math.random(40, 200) },
                description = _("scienceDescription-station", "Mining station"),
                general = "",
                history = "",
            }),
            ["Krik"] = stationBuild({
                reputation_neutral = 3.0,
                goods = { nickel = stationGood(20) },
                trade = {
                    food = true,
                    medicine = true,
                    luxury = random(1, 100) < 50,
                },
                description = _("scienceDescription-station", "Mining station"),
                general = "",
                history = "",
            }),
            ["Kruk"] = stationBuild({
                reputation_neutral = 3.0,
                goods = { nickel = stationGood(20) },
                trade = {
                    food = random(1, 100) < 50,
                    medicine = random(1, 100) < 50,
                    luxury = true,
                },
                buy = { [randomComponent()] = math.random(40, 200) },
                description = _("scienceDescription-station", "Mining station"),
                general = "",
                history = "",
            }),
            ["Maverick"] = stationBuild({
                goods = { luxury = stationGood(math.random(30, 80)) },
                description = _(
                    "scienceDescription-station",
                    "Gambling and resupply"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "Relax and meet some interesting players"
                ),
                history = "",
            }),
            ["Nefatha"] = stationBuild({
                reputation_neutral = 2.0,
                goods = { luxury = stationGood(math.random(30, 80)) },
                description = _(
                    "scienceDescription-station",
                    "Commerce and recreation"
                ),
                general = "",
                history = "",
            }),
            ["Okun"] = stationBuild({
                weapons_override = { Mine = false },
                reputation_neutral = 3.0,
                description = _(
                    "scienceDescription-station",
                    "Xenopsychology research"
                ),
                general = "",
                history = "",
            }),
            ["Outpost-15"] = stationBuild({
                reputation_neutral = 2.0,
                goods = { luxury = stationGood(math.random(30, 80)) },
                description = _(
                    "scienceDescription-station",
                    "Mining and trade"
                ),
                general = "",
                history = "",
            }),
            ["Outpost-21"] = stationBuild({
                reputation_neutral = 2.0,
                goods = { luxury = stationGood(math.random(30, 80)) },
                description = _(
                    "scienceDescription-station",
                    "Mining and gambling"
                ),
                general = "",
                history = "",
            }),
            ["Outpost-7"] = stationBuild({
                reputation_neutral = 2.0,
                goods = { luxury = stationGood(math.random(30, 80)) },
                description = _("scienceDescription-station", "Resupply"),
                general = "",
                history = "",
            }),
            ["Outpost-8"] = stationBuild({
                reputation_neutral = 2.0,
                goods = { luxury = stationGood(math.random(30, 80)) },
                description = "",
                general = "",
                history = "",
            }),
            ["Outpost-33"] = stationBuild({
                reputation_neutral = 2.0,
                goods = { luxury = stationGood(math.random(30, 80)) },
                description = _("scienceDescription-station", "Resupply"),
                general = "",
                history = "",
            }),
            ["Prada"] = stationBuild({
                weapons_override = { Mine = false },
                reputation_neutral = 2.0,
                description = _(
                    "scienceDescription-station",
                    "Textiles and fashion"
                ),
                general = "",
                history = "",
            }),
            ["Research-11"] = stationBuild({
                reputation_neutral = 2.0,
                goods = { medicine = stationGood(math.random(30, 80)) },
                description = _(
                    "scienceDescription-station",
                    "Stress Psychology Research"
                ),
                general = "",
                history = "",
            }),
            ["Research-19"] = stationBuild({
                reputation_neutral = 2.0,
                description = _(
                    "scienceDescription-station",
                    "Low gravity research"
                ),
                general = "",
                history = "",
            }),
            ["Rubis"] = stationBuild({
                reputation_neutral = 3.0,
                goods = { luxury = stationGood(math.random(30, 80)) },
                description = _("scienceDescription-station", "Resupply"),
                general = _(
                    "stationGeneralInfo-comms",
                    "Get your energy here! Grab a drink before you go!"
                ),
                history = "",
            }),
            ["Science-2"] = stationBuild({
                goods = { circuit = stationGood(math.random(30, 80)) },
                description = _(
                    "scienceDescription-station",
                    "Research Lab and Observatory"
                ),
                general = "",
                history = "",
            }),
            ["Science-4"] = stationBuild({
                reputation_neutral = 2.0,
                goods = {
                    medicine = stationGood(math.random(30, 80)),
                    autodoc = stationGood(math.random(30, 80)),
                },
                description = _(
                    "scienceDescription-station",
                    "Biotech research"
                ),
                general = "",
                history = "",
            }),
            ["Science-7"] = stationBuild({
                goods = { food = stationGood(1, 2) },
                description = _("scienceDescription-station", "Observatory"),
                general = "",
                history = "",
            }),
            ["Spot"] = stationBuild({
                reputation_neutral = 3.0,
                description = _("scienceDescription-station", "Observatory"),
                general = "",
                history = "",
            }),
            ["Valero"] = stationBuild({
                reputation_neutral = 2.0,
                goods = { luxury = stationGood(math.random(30, 80)) },
                description = _("scienceDescription-station", "Resupply"),
                general = "",
                history = "",
            }),
        },
        ["Sinister"] = {},
    }
    for _, name in ipairs(sinister_names) do
        station_pool["Sinister"][name] = stationEmpty()
    end
    -- If you want one group to have a higher priority, simply define station_priority.
    -- For example, If you think the History group is the most important followed by
    -- the Science group and the other groups don't matter, define station_priority:
    -- station_priority = {"History","Science"}
    if station_priority == nil then
        station_priority = {
            "Science",
            "Alt Sci Fi",
            "Spec Sci Fi",
            "History",
            "Generic",
        }
    end
    for group, list in pairs(station_pool) do
        local already_inserted = false
        for idx, previous_group in ipairs(station_priority) do
            if group == previous_group then
                already_inserted = true
                break
            end
        end
        if not already_inserted and group ~= "Sinister" then
            table.insert(station_priority, group)
        end
    end
end
