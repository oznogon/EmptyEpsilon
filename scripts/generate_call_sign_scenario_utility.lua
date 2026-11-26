-- Generate call sign functions
-- Usage
--     generateCallSign()
--         No passed parameters. Prefix generated internally. No related faction prefix.
--     generateCallSign(prefix)
--         A call sign prefix has already been determined and passed in. The numeric
--         part after the prefix is what is generated. Especially useful if you want a
--         group of call signs with the same prefix, but with different numeric suffixes.
--     generateCallSign(nil,faction)
--         No prefix specified, but a faction is specified. The prefix will be taken from
--         the list of faction prefixes for the faction provided. The numeric suffix is
--         also generated.
--     generateCallSign(prefix,faction)
--         Both prefix and faction specified. Assumes you want a faction flavored prefix
--         along with the prefix provided. The prefix portion will be the faction flavored
--         prefix followed by a space followed by the provided prefix. The numeric suffix
--         follows.
--     generateCallSignPrefix()
--         No length specified. A call sign prefix of random characters of length
--         prefix_length will be generated. The randomness comes from a pool of characters
--         to reduce the chance of repetition. The pool is rebuilt when exhausted. Called
--         by generateCallSign when prefix is not provided. Useful when you want the same
--         prefix for a group of call signs, but you want it randomly generated: use
--         generateCallSignPrefix and pass the result to generateCallSign for each call
--         sign desired for your group.
--     generateCallSignPrefix(length)
--         Generates a random group of characters of the length passed.
--     getFactionPrefix()
--         Calls generateCallSignPrefix() if the faction is omitted
--     getFactionPrefix(faction)
--         Provides a faction flavored call sign prefix. Called internally by
--         generateCallSign(<>,faction). Pulled from the pool of faction prefixes. The
--         faction prefix pool is refilled when exhausted.
-- Global variables (set here if not set externally)
--     suffix_index - set to zero if not set externally
--     prefix_length - set to zero if not set externally
--     Faction flavored call sign prefixes:
--         kraylor_names, exuari_names, ghosts_names, independent_names, human_names,
--         arlenian_names, usn_names, tsn_names, cuf_names, ktlitan_names
-- Faction flavored prefix names
--     The Kraylor, Arlenian, Exuari and Ktlitan names are supposed to sound alien. They
--     follow an internal pattern so that with enough experience, one can tell by the
--     ship name what faction they belong to. The Ghost names come from computer hardware
--     and software terminology in keeping with their cyber origins. The USN names follow
--     a pirate theme. The TSN names follow a traditional space ship theme from science
--     fiction. The CUF names are somewhat whimsical with alliteration for multipart names.
--     The independent names borrow from every group since they represent ships that come
--     from a variety of sources.
--
--     You can set up your own list of names using the same list name and format. Once
--     your names have been exhausted, the pool will be refilled with the names here.
function generateCallSign(prefix, faction)
    if faction == nil then
        if prefix == nil then
            prefix = generateCallSignPrefix()
        end
    else
        if prefix == nil then
            prefix = getFactionPrefix(faction)
        else
            prefix = string.format("%s %s", getFactionPrefix(faction), prefix)
        end
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
function generateCallSignPrefix(length)
    if prefix_length == nil then
        prefix_length = 0
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
    for i = 1, 26 do
        table.insert(call_sign_prefix_pool, string.char(i + 64))
    end
end

-- Optional per-scenario pool patches. Keys are the global pool names used below.
-- Example: call_sign_name_overrides = { human_names = { add = {"Heracles"} } }
function applyCallSignNameOverrides(pool_name, names)
    local overrides = call_sign_name_overrides
        and call_sign_name_overrides[pool_name]
    if overrides == nil then
        return
    end
    if overrides.remove ~= nil then
        local excluded = {}
        for _, name in ipairs(overrides.remove) do
            excluded[name] = true
        end
        for index = #names, 1, -1 do
            if excluded[names[index]] then
                table.remove(names, index)
            end
        end
    end
    if overrides.add ~= nil then
        for _, name in ipairs(overrides.add) do
            table.insert(names, name)
        end
    end
end

function getFactionPrefix(faction)
    local faction_prefix = nil
    if faction == "Kraylor" then
        if kraylor_names == nil then
            setKraylorNames()
        else
            if #kraylor_names < 1 then
                setKraylorNames()
            end
        end
        local kraylor_name_choice = math.random(1, #kraylor_names)
        faction_prefix = kraylor_names[kraylor_name_choice]
        table.remove(kraylor_names, kraylor_name_choice)
    end
    if faction == "Exuari" then
        if exuari_names == nil then
            setExuariNames()
        else
            if #exuari_names < 1 then
                setExuariNames()
            end
        end
        local exuari_name_choice = math.random(1, #exuari_names)
        faction_prefix = exuari_names[exuari_name_choice]
        table.remove(exuari_names, exuari_name_choice)
    end
    if faction == "Ghosts" then
        if ghosts_names == nil then
            setGhostsNames()
        else
            if #ghosts_names < 1 then
                setGhostsNames()
            end
        end
        local ghosts_name_choice = math.random(1, #ghosts_names)
        faction_prefix = ghosts_names[ghosts_name_choice]
        table.remove(ghosts_names, ghosts_name_choice)
    end
    if faction == "Independent" then
        if independent_names == nil then
            setIndependentNames()
        else
            if #independent_names < 1 then
                setIndependentNames()
            end
        end
        local independent_name_choice = math.random(1, #independent_names)
        faction_prefix = independent_names[independent_name_choice]
        table.remove(independent_names, independent_name_choice)
    end
    if faction == "Human Navy" then
        if human_names == nil then
            setHumanNames()
        else
            if #human_names < 1 then
                setHumanNames()
            end
        end
        local human_name_choice = math.random(1, #human_names)
        faction_prefix = human_names[human_name_choice]
        table.remove(human_names, human_name_choice)
    end
    if faction == "Arlenians" then
        if arlenian_names == nil then
            setArlenianNames()
        else
            if #arlenian_names < 1 then
                setArlenianNames()
            end
        end
        local arlenian_name_choice = math.random(1, #arlenian_names)
        faction_prefix = arlenian_names[arlenian_name_choice]
        table.remove(arlenian_names, arlenian_name_choice)
    end
    if faction == "USN" then
        if usn_names == nil then
            setUsnNames()
        else
            if #usn_names < 1 then
                setUsnNames()
            end
        end
        local usn_name_choice = math.random(1, #usn_names)
        faction_prefix = usn_names[usn_name_choice]
        table.remove(usn_names, usn_name_choice)
    end
    if faction == "TSN" then
        if tsn_names == nil then
            setTsnNames()
        else
            if #tsn_names < 1 then
                setTsnNames()
            end
        end
        local tsn_name_choice = math.random(1, #tsn_names)
        faction_prefix = tsn_names[tsn_name_choice]
        table.remove(tsn_names, tsn_name_choice)
    end
    if faction == "CUF" then
        if cuf_names == nil then
            setCufNames()
        else
            if #cuf_names < 1 then
                setCufNames()
            end
        end
        local cuf_name_choice = math.random(1, #cuf_names)
        faction_prefix = cuf_names[cuf_name_choice]
        table.remove(cuf_names, cuf_name_choice)
    end
    if faction == "Ktlitans" then
        if ktlitan_names == nil then
            setKtlitanNames()
        else
            if #ktlitan_names < 1 then
                setKtlitanNames()
            end
        end
        local ktlitan_name_choice = math.random(1, #ktlitan_names)
        faction_prefix = ktlitan_names[ktlitan_name_choice]
        table.remove(ktlitan_names, ktlitan_name_choice)
    end
    if faction_prefix == nil then
        faction_prefix = generateCallSignPrefix()
    end
    return faction_prefix
end
function setGhostsNames()
    ghosts_names = {
        "Abstract",
        "Ada",
        "Assemble",
        "Assert",
        "Backup",
        "BASIC",
        "Big Iron",
        "BigEndian",
        "Binary",
        "Bit",
        "Block",
        "Boot",
        "Branch",
        "BTree",
        "Bubble",
        "Byte",
        "Capacitor",
        "Case",
        "Chad",
        "Charge",
        "COBOL",
        "Collate",
        "Compile",
        "Control",
        "Construct",
        "Cycle",
        "Data",
        "Debug",
        "Decimal",
        "Decision",
        "Default",
        "DIMM",
        "Displacement",
        "Edge",
        "Exit",
        "Factor",
        "Flag",
        "Float",
        "Flow",
        "FORTRAN",
        "Fullword",
        "GIGO",
        "Graph",
        "Hack",
        "Hash",
        "Halfword",
        "Hertz",
        "Hexadecimal",
        "Indicator",
        "Initialize",
        "Integer",
        "Integrate",
        "Interrupt",
        "Java",
        "Lisp",
        "List",
        "Logic",
        "Loop",
        "Lua",
        "Magnetic",
        "Mask",
        "Memory",
        "Mnemonic",
        "Micro",
        "Model",
        "Nibble",
        "Octal",
        "Order",
        "Operator",
        "Parameter",
        "Pascal",
        "Pattern",
        "Pixel",
        "Point",
        "Polygon",
        "Port",
        "Process",
        "RAM",
        "Raster",
        "Rate",
        "Redundant",
        "Reference",
        "Refresh",
        "Register",
        "Resistor",
        "ROM",
        "Routine",
        "Ruby",
        "SAAS",
        "Sequence",
        "Share",
        "Silicon",
        "SIMM",
        "Socket",
        "Sort",
        "Structure",
        "Switch",
        "Symbol",
        "Trace",
        "Transistor",
        "Value",
        "Vector",
        "Version",
        "View",
        "WYSIWYG",
        "XOR",
    }
    applyCallSignNameOverrides("ghosts_names", ghosts_names)
end
function setExuariNames()
    exuari_names = {
        "Astonester",
        "Ametripox",
        "Bakeltevex",
        "Baropledax",
        "Batongomox",
        "Bekilvimix",
        "Benoglopok",
        "Bilontipur",
        "Bolictimik",
        "Bomagralax",
        "Buteldefex",
        "Catondinab",
        "Chatorlonox",
        "Culagromik",
        "Dakimbinix",
        "Degintalix",
        "Dimabratax",
        "Dokintifix",
        "Dotandirex",
        "Dupalgawax",
        "Ekoftupex",
        "Elidranov",
        "Fakobrovox",
        "Femoplabix",
        "Fibatralax",
        "Fomartoran",
        "Gateldepex",
        "Gamutrewal",
        "Gesanterux",
        "Gimardanax",
        "Hamintinal",
        "Holangavak",
        "Igolpafik",
        "Inoklomat",
        "Jamewtibex",
        "Jepospagox",
        "Kajortonox",
        "Kapogrinix",
        "Kelitravax",
        "Kipaldanax",
        "Kodendevex",
        "Kotelpedex",
        "Kutandolak",
        "Lakirtinix",
        "Lapoldinek",
        "Lavorbonox",
        "Letirvinix",
        "Lowibromax",
        "Makintibix",
        "Makorpohox",
        "Matoprowox",
        "Mefinketix",
        "Motandobak",
        "Nakustunux",
        "Nequivonax",
        "Nitaldavax",
        "Nobaldorex",
        "Obimpitix",
        "Owaklanat",
        "Pakendesik",
        "Pazinderix",
        "Pefoglamuk",
        "Pekirdivix",
        "Potarkadax",
        "Pulendemex",
        "Quatordunix",
        "Rakurdumux",
        "Ralombenik",
        "Regosporak",
        "Retordofox",
        "Rikondogox",
        "Rokengelex",
        "Rutarkadax",
        "Sakeldepex",
        "Setiftimix",
        "Siparkonal",
        "Sopaldanax",
        "Sudastulux",
        "Takeftebex",
        "Taliskawit",
        "Tegundolex",
        "Tekintipix",
        "Tiposhomox",
        "Tokaldapax",
        "Tomuglupux",
        "Tufeldepex",
        "Unegremek",
        "Uvendipax",
        "Vatorgopox",
        "Venitribix",
        "Vobalterix",
        "Wakintivix",
        "Wapaltunix",
        "Wekitrolax",
        "Wofarbanax",
        "Xeniplofek",
        "Yamaglevik",
        "Yakildivix",
        "Yegomparik",
        "Zapondehex",
        "Zikandelat",
    }
    applyCallSignNameOverrides("exuari_names", exuari_names)
end
function setKraylorNames()
    kraylor_names = {
        "Abroten",
        "Ankwar",
        "Bakrik",
        "Belgor",
        "Benkop",
        "Blargvet",
        "Bloktarg",
        "Bortok",
        "Bredjat",
        "Chankret",
        "Chatork",
        "Chokarp",
        "Cloprak",
        "Coplek",
        "Cortek",
        "Daltok",
        "Darpik",
        "Dastek",
        "Dotark",
        "Drambok",
        "Duntarg",
        "Earklat",
        "Ekmit",
        "Fakret",
        "Fapork",
        "Fawtrik",
        "Fenturp",
        "Feplik",
        "Figront",
        "Floktrag",
        "Fonkack",
        "Fontreg",
        "Foondrap",
        "Frotwak",
        "Gastonk",
        "Gentouk",
        "Gonpruk",
        "Gortak",
        "Gronkud",
        "Hewtang",
        "Hongtag",
        "Hortook",
        "Indrut",
        "Iprant",
        "Jakblet",
        "Jonket",
        "Jontot",
        "Kandarp",
        "Kantrok",
        "Kiptak",
        "Kortrant",
        "Krontgat",
        "Lobreck",
        "Lokrant",
        "Lomprok",
        "Lutrank",
        "Makrast",
        "Moklahft",
        "Morpug",
        "Nagblat",
        "Nokrat",
        "Nomek",
        "Notark",
        "Ontrok",
        "Orkpent",
        "Peechak",
        "Plogrent",
        "Pokrint",
        "Potarg",
        "Prangtil",
        "Quagbrok",
        "Quimprill",
        "Reekront",
        "Ripkort",
        "Rokust",
        "Rontrait",
        "Saknep",
        "Sengot",
        "Skitkard",
        "Skopgrek",
        "Sletrok",
        "Slorknat",
        "Spogrunk",
        "Staklurt",
        "Stonkbrant",
        "Swaktrep",
        "Tandrok",
        "Takrost",
        "Tonkrut",
        "Torkrot",
        "Trablok",
        "Trokdin",
        "Unkelt",
        "Urjop",
        "Vankront",
        "Vintrep",
        "Volkerd",
        "Vortread",
        "Wickurt",
        "Xokbrek",
        "Yeskret",
        "Zacktrope",
    }
    applyCallSignNameOverrides("kraylor_names", kraylor_names)
end
function setIndependentNames()
    independent_names = {
        "Akdroft", --faux Kraylor
        "Bletnik", --faux Kraylor
        "Brogfent", --faux Kraylor
        "Cruflech", --faux Kraylor
        "Dengtoct", --faux Kraylor
        "Fiklerg", --faux Kraylor
        "Groftep", --faux Kraylor
        "Hinkflort", --faux Kraylor
        "Irklesht", --faux Kraylor
        "Jotrak", --faux Kraylor
        "Kargleth", --faux Kraylor
        "Lidroft", --faux Kraylor
        "Movrect", --faux Kraylor
        "Nitrang", --faux Kraylor
        "Poklapt", --faux Kraylor
        "Raknalg", --faux Kraylor
        "Stovtuk", --faux Kraylor
        "Trongluft", --faux Kraylor
        "Vactremp", --faux Kraylor
        "Wunklesp", --faux Kraylor
        "Yentrilg", --faux Kraylor
        "Zeltrag", --faux Kraylor
        "Avoltojop", --faux Exuari
        "Bimartarax", --faux Exuari
        "Cidalkapax", --faux Exuari
        "Darongovax", --faux Exuari
        "Felistiyik", --faux Exuari
        "Gopendewex", --faux Exuari
        "Hakortodox", --faux Exuari
        "Jemistibix", --faux Exuari
        "Kilampafax", --faux Exuari
        "Lokuftumux", --faux Exuari
        "Mabildirix", --faux Exuari
        "Notervelex", --faux Exuari
        "Pekolgonex", --faux Exuari
        "Rifaltabax", --faux Exuari
        "Sobendeyex", --faux Exuari
        "Tinaftadax", --faux Exuari
        "Vadorgomax", --faux Exuari
        "Wilerpejex", --faux Exuari
        "Yukawvalak", --faux Exuari
        "Zajiltibix", --faux Exuari
        "Alter", --faux Ghosts
        "Assign", --faux Ghosts
        "Brain", --faux Ghosts
        "Break", --faux Ghosts
        "Boundary", --faux Ghosts
        "Code", --faux Ghosts
        "Compare", --faux Ghosts
        "Continue", --faux Ghosts
        "Core", --faux Ghosts
        "CRUD", --faux Ghosts
        "Decode", --faux Ghosts
        "Decrypt", --faux Ghosts
        "Device", --faux Ghosts
        "Encode", --faux Ghosts
        "Encrypt", --faux Ghosts
        "Event", --faux Ghosts
        "Fetch", --faux Ghosts
        "Frame", --faux Ghosts
        "Go", --faux Ghosts
        "IO", --faux Ghosts
        "Interface", --faux Ghosts
        "Kilo", --faux Ghosts
        "Modify", --faux Ghosts
        "Pin", --faux Ghosts
        "Program", --faux Ghosts
        "Purge", --faux Ghosts
        "Retrieve", --faux Ghosts
        "Store", --faux Ghosts
        "Unit", --faux Ghosts
        "Wire", --faux Ghosts
        "Chakak", --faux Ktlitans
        "Chakik", --faux Ktlitans
        "Chaklik", --faux Ktlitans
        "Kaklak", --faux Ktlitans
        "Kiklak", --faux Ktlitans
        "Kitpak", --faux Ktlitans
        "Kitplak", --faux Ktlitans
        "Pipklat", --faux Ktlitans
        "Piptik", --faux Ktlitans
    }
    applyCallSignNameOverrides("independent_names", independent_names)
end
function setCufNames()
    cuf_names = {
        "Allegro",
        "Bonafide",
        "Brief Blur",
        "Byzantine Born",
        "Celeste",
        "Chosen Charter",
        "Conundrum",
        "Crazy Clef",
        "Curtail",
        "Dark Demesne",
        "Diminutive Drama",
        "Draconian Destiny",
        "Fickle Frown",
        "Final Freeze",
        "Fried Feather",
        "Frozen Flare",
        "Gaunt Gator",
        "Hidden Harpoon",
        "Intense Interest",
        "Lackadaisical",
        "Largess",
        "Ointment",
        "Plush Puzzle",
        "Slick",
        "Thumper",
        "Torpid",
        "Triple Take",
    }
    applyCallSignNameOverrides("cuf_names", cuf_names)
end
function setUsnNames()
    usn_names = {
        "Belladonna",
        "Broken Dragon",
        "Burning Knave",
        "Corona Flare",
        "Daring the Deep",
        "Dragon's Cutlass",
        "Dragon's Sadness",
        "Elusive Doom",
        "Fast Flare",
        "Flying Flare",
        "Fulminate",
        "Gaseous Gale",
        "Golden Anger",
        "Greedy Promethean",
        "Happy Mynock",
        "Jimi Saru",
        "Jolly Roger",
        "Killer's Grief",
        "Mad Delight",
        "Nocturnal Neptune",
        "Obscure Orbiter",
        "Red Rift",
        "Rusty Belle",
        "Silver Pearl",
        "Sodden Corsair",
        "Solar Sailor",
        "Solar Secret",
        "Sun's Grief",
        "Tortuga Shadows",
        "Trinity",
        "Wayfaring Wind",
    }
    applyCallSignNameOverrides("usn_names", usn_names)
end
function setTsnNames()
    tsn_names = {
        "Aegis",
        "Allegiance",
        "Apollo",
        "Ares",
        "Casper",
        "Charger",
        "Dauntless",
        "Demeter",
        "Eagle",
        "Excalibur",
        "Falcon",
        "Guardian",
        "Hawk",
        "Hera",
        "Horizon",
        "Hunter",
        "Hydra",
        "Intrepid",
        "Lancer",
        "Montgomery",
        "Nemesis",
        "Osiris",
        "Pegasus",
        "Phoenix",
        "Poseidon",
        "Raven",
        "Sabre",
        "Stalker",
        "Valkyrie",
        "Viper",
    }
    applyCallSignNameOverrides("tsn_names", tsn_names)
end
function setHumanNames()
    human_names = {
        "Andromeda",
        "Angelica",
        "Artemis",
        "Barrier",
        "Beauteous",
        "Bliss",
        "Bonita",
        "Bounty Hunter",
        "Bueno",
        "Capitol",
        "Castigator",
        "Centurion",
        "Chakalaka",
        "Charity",
        "Christmas",
        "Chutzpah",
        "Constantine",
        "Crystal",
        "Dauntless",
        "Defiant",
        "Discovery",
        "Dorcas",
        "Elite",
        "Empathy",
        "Enlighten",
        "Enterprise",
        "Escape",
        "Exclamatory",
        "Faith",
        "Felicity",
        "Firefly",
        "Foresight",
        "Forthright",
        "Fortitude",
        "Frankenstein",
        "Gallant",
        "Gladiator",
        "Glider",
        "Godzilla",
        "Grind",
        "Happiness",
        "Hearken",
        "Helena",
        "Honorable Intentions",
        "Hope",
        "Inertia",
        "Ingenius",
        "Injurious",
        "Insight",
        "Insufferable",
        "Insurmountable",
        "Intractable",
        "Intransigent",
        "Jenny",
        "Juice",
        "Justice",
        "Jurassic",
        "Karma Cast",
        "Knockout",
        "Leila",
        "Light Fantastic",
        "Livid",
        "Lolita",
        "Mercury",
        "Moira",
        "Mona Lisa",
        "Nancy",
        "Olivia",
        "Ominous",
        "Oracle",
        "Orca",
        "Pandemic",
        "Parsimonious",
        "Personal Prejudice",
        "Porpoise",
        "Pristine",
        "Purple Passion",
        "Renegade",
        "Revelation",
        "Rosanna",
        "Rozelle",
        "Sainted Gramma",
        "Shazam",
        "Starbird",
        "Stargazer",
        "Stile",
        "Streak",
        "Take Flight",
        "Taskmaster",
        "The Way",
        "Tornado",
        "Trailblazer",
        "Trident",
        "Triple Threat",
        "Turnabout",
        "Undulator",
        "Urgent",
        "Victoria",
        "Wee Bit",
        "Wet Willie",
    }
    applyCallSignNameOverrides("human_names", human_names)
end
function setKtlitanNames()
    ktlitan_names = {
        "Chaklak",
        "Chaklit",
        "Chitlat",
        "Chitlit",
        "Chitpik",
        "Chokpit",
        "Choktip",
        "Choktot",
        "Chotlap",
        "Chotlat",
        "Chotlot",
        "Kaftlit",
        "Kaplak",
        "Kaplat",
        "Kichpak",
        "Kichpik",
        "Kichtak",
        "Kiftlat",
        "Kiftak",
        "Kiftakt",
        "Kiftlikt",
        "Kiftlit",
        "Kiklat",
        "Kiklik",
        "Kiklit",
        "Kiplit",
        "Kiptot",
        "Kitchip",
        "Kitchit",
        "Kitlaft",
        "Kitlak",
        "Kitlakt",
        "Kitlich",
        "Kitlik",
        "Kitpok",
        "Koptich",
        "Koptlik",
        "Kotplat",
        "Pachtik",
        "Paflak",
        "Paftak",
        "Paftik",
        "Pakchit",
        "Pakchok",
        "Paktok",
        "Piklit",
        "Piflit",
        "Piftik",
        "Pitlak",
        "Pochkik",
        "Pochkit",
        "Poftlit",
        "Pokchap",
        "Pokchat",
        "Poktat",
        "Poklit",
        "Potlak",
        "Tachpik",
        "Tachpit",
        "Taklit",
        "Talkip",
        "Talpik",
        "Taltkip",
        "Taltkit",
        "Tichpik",
        "Tikplit",
        "Tiklich",
        "Tiklip",
        "Tiklip",
        "Tilpit",
        "Tiltlit",
        "Tochtik",
        "Tochkap",
        "Tochpik",
        "Tochpit",
        "Tochkit",
        "Totlop",
        "Totlot",
    }
    applyCallSignNameOverrides("ktlitan_names", ktlitan_names)
end
function setArlenianNames()
    arlenian_names = {
        "Balura",
        "Baminda",
        "Belarne",
        "Bilanna",
        "Calonda",
        "Carila",
        "Carulda",
        "Charma",
        "Choralle",
        "Corlune",
        "Damilda",
        "Dilenda",
        "Dorla",
        "Elena",
        "Emerla",
        "Famelda",
        "Finelle",
        "Fontaine",
        "Forlanne",
        "Gendura",
        "Gilarne",
        "Grizelle",
        "Hilerna",
        "Homella",
        "Jarille",
        "Jindarre",
        "Juminde",
        "Kalena",
        "Kimarna",
        "Kolira",
        "Lanerra",
        "Lamura",
        "Lavila",
        "Lavorna",
        "Lendura",
        "Limala",
        "Lorelle",
        "Mavelle",
        "Menola",
        "Merla",
        "Mitelle",
        "Mivelda",
        "Morainne",
        "Morda",
        "Morlena",
        "Nadela",
        "Naminda",
        "Nilana",
        "Nurelle",
        "Panela",
        "Pelnare",
        "Pilera",
        "Povelle",
        "Quilarre",
        "Ramila",
        "Renatha",
        "Rendelle",
        "Rinalda",
        "Riderla",
        "Rifalle",
        "Samila",
        "Salura",
        "Selinda",
        "Simanda",
        "Sodila",
        "Talinda",
        "Tamierre",
        "Telorre",
        "Terila",
        "Turalla",
        "Valerna",
        "Vilanda",
        "Vomera",
        "Wanelle",
        "Warenda",
        "Wilena",
        "Wodarla",
        "Yamelda",
        "Yelanda",
    }
    applyCallSignNameOverrides("arlenian_names", arlenian_names)
end
