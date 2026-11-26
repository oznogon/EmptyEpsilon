-- Shoreline's station catalog. Building is explicit so importing this module
-- never advances the RNG or mutates global state.
local M = {}

function M.build()
    local station_pool = {
        ["Science"] = {
            ["Asimov"] = {
                weapon_available = {
                    Homing = true,
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = true,
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    tractor = {
                        quantity = 5,
                        cost = 48,
                    },
                    repulsor = {
                        quantity = 5,
                        cost = 48,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _(
                    "scienceDescription-station",
                    "Training and Coordination"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We train naval cadets in routine and specialized functions aboard space vessels and coordinate naval activity throughout the sector"
                ),
                history = _(
                    "stationStory-comms",
                    "The original station builders were fans of the late 20th century scientist and author Isaac Asimov. The station was initially named Foundation, but was later changed simply to Asimov. It started off as a stellar observatory, then became a supply stop and as it has grown has become an educational and coordination hub for the region"
                ),
            },
            ["Armstrong"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = true,
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = true,
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                goods = {
                    warp = {
                        quantity = 5,
                        cost = 77,
                    },
                    repulsor = {
                        quantity = 5,
                        cost = 62,
                    },
                },
                trade = {
                    food = random(1, 100) <= 45,
                    medicine = false,
                    luxury = false,
                },
                buy = {
                    [randomMineral()] = math.random(40, 200),
                },
                description = _(
                    "scienceDescription-station",
                    "Warp and Impulse engine manufacturing"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We manufacture warp, impulse and jump engines for the human navy fleet as well as other independent clients on a contract basis"
                ),
                history = _(
                    "stationStory-comms",
                    "The station is named after the late 19th century astronaut as well as the fictionlized stations that followed. The station initially constructed entire space worthy vessels. In time, it transitioned into specializeing in propulsion systems."
                ),
            },
            ["Broeck"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                goods = {
                    warp = {
                        quantity = 5,
                        cost = 36,
                    },
                },
                trade = {
                    food = random(1, 100) <= 14,
                    medicine = false,
                    luxury = random(1, 100) < 62,
                },
                buy = {
                    [randomMineral()] = math.random(40, 200),
                },
                description = _(
                    "scienceDescription-station",
                    "Warp drive components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We provide warp drive engines and components"
                ),
                history = _(
                    "stationStory-comms",
                    "This station is named after Chris Van Den Broeck who did some initial research into the possibility of warp drive in the late 20th century on Earth"
                ),
            },
            ["Coulomb"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    circuit = {
                        quantity = 5,
                        cost = 50,
                    },
                },
                trade = {
                    food = random(1, 100) <= 35,
                    medicine = false,
                    luxury = random(1, 100) < 82,
                },
                buy = {
                    [randomMineral()] = math.random(40, 200),
                },
                description = _(
                    "scienceDescription-station",
                    "Shielded circuitry fabrication"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We make a large variety of circuits for numerous ship systems shielded from sensor detection and external control interference"
                ),
                history = _(
                    "stationStory-comms",
                    "Our station is named after the law which quantifies the amount of force with which stationary electrically charged particals repel or attact each other - a fundamental principle in the design of our circuits"
                ),
            },
            ["Heyes"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = true,
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    sensor = {
                        quantity = 5,
                        cost = 72,
                    },
                },
                trade = {
                    food = random(1, 100) <= 32,
                    medicine = false,
                    luxury = true,
                },
                buy = {
                    [randomMineral()] = math.random(40, 200),
                },
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
                    "The station is named after Tony Heyes the inventor of some of the earliest electromagnetic sensors in the mid 20th century on Earth in the United Kingdom to assist blind human mobility"
                ),
            },
            ["Hossam"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    nanites = {
                        quantity = 5,
                        cost = 90,
                    },
                },
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
                    "We provide nanites for various organic and non-organic systems"
                ),
                history = _(
                    "stationStory-comms",
                    "This station is named after the nanotechnologist Hossam Haick from the early 21st century on Earth in Israel"
                ),
            },
            ["Maiman"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = false,
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    beam = {
                        quantity = 5,
                        cost = 70,
                    },
                },
                trade = {
                    food = random(1, 100) <= 75,
                    medicine = true,
                    luxury = false,
                },
                buy = {
                    [randomMineral()] = math.random(40, 200),
                },
                description = _(
                    "scienceDescription-station",
                    "Energy beam components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We research and manufacture energy beam components and systems"
                ),
                history = _(
                    "stationStory-comms",
                    "The station is named after Theodore Maiman who researched and built the first laser in the mid 20th century on Earth"
                ),
            },
            ["Malthus"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {},
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
                    "The oldest station in the quadrant"
                ),
                history = "",
            },
            ["Marconi"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    beam = {
                        quantity = 5,
                        cost = 80,
                    },
                },
                trade = {
                    food = random(1, 100) <= 53,
                    medicine = false,
                    luxury = true,
                },
                description = _(
                    "scienceDescription-station",
                    "Energy Beam Components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We manufacture energy beam components"
                ),
                history = _(
                    "stationStory-comms",
                    "Station named after Guglielmo Marconi an Italian inventor from early 20th century Earth who, along with Nicolo Tesla, claimed to have invented a death ray or particle beam weapon"
                ),
            },
            ["Miller"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    optic = {
                        quantity = 5,
                        cost = 60,
                    },
                },
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
                    "This station was named after one of the early exobiologists from mid 20th century Earth, Dr. Stanley Miller"
                ),
            },
            ["Shawyer"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 2.0,
                },
                goods = {
                    impulse = {
                        quantity = 5,
                        cost = 100,
                    },
                },
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
                    "The station is named after Roger Shawyer who built the first prototype impulse engine in the early 21st century"
                ),
            },
        },
        ["History"] = {
            ["Archimedes"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    beam = {
                        quantity = 5,
                        cost = 80,
                    },
                },
                trade = {
                    food = true,
                    medicine = false,
                    luxury = true,
                },
                description = _(
                    "scienceDescription-station",
                    "Energy and particle beam components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We fabricate general and specialized components for ship beam systems"
                ),
                history = _(
                    "stationStory-comms",
                    "This station was named after Archimedes who, according to legend, used a series of adjustable focal length mirrors to focus sunlight on a Roman naval fleet invading Syracuse, setting fire to it"
                ),
            },
            ["Chatuchak"] = {
                weapon_available = {
                    Homing = random(1, 10) <= (8 - difficulty),
                    HVLI = random(1, 10) <= (9 - difficulty),
                    Mine = false,
                    Nuke = random(1, 10) <= (5 - difficulty),
                    EMP = random(1, 10) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 2.0,
                },
                goods = {
                    luxury = {
                        quantity = 5,
                        cost = 60,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _(
                    "scienceDescription-station",
                    "Trading station"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "Only the largest market and trading location in twenty sectors. You can find your heart's desire here"
                ),
                history = _(
                    "stationStory-comms",
                    "Modeled after the early 21st century bazaar on Earth in Bangkok, Thailand. Designed and built with trade and commerce in mind"
                ),
            },
            ["Grasberg"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 2.0,
                },
                goods = {
                    luxury = {
                        quantity = 5,
                        cost = 70,
                    },
                },
                trade = {
                    food = true,
                    medicine = false,
                    luxury = false,
                },
                buy = {
                    [randomComponent()] = math.random(40, 200),
                },
                description = _("scienceDescription-station", "Mining"),
                general = _(
                    "stationGeneralInfo-comms",
                    "We mine nearby asteroids for precious minerals and process them for sale"
                ),
                history = _(
                    "stationStory-comms",
                    "This station's name is inspired by a large gold mine on Earth in Indonesia. The station builders hoped to have a similar amount of minerals found amongst these asteroids"
                ),
            },
            ["Hayden"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 2.0,
                },
                goods = {
                    nanites = {
                        quantity = 5,
                        cost = 65,
                    },
                },
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
                    "We study the cosmos and map stellar phenomena. We also track moving asteroids. Look out! Just kidding"
                ),
                history = _(
                    "stationStory-comms",
                    "Station named in honor of Charles Hayden whose philanthropy continued astrophysical research and education on Earth in the early 20th century"
                ),
            },
            ["Lipkin"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = false,
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 2.0,
                },
                goods = {
                    autodoc = {
                        quantity = 5,
                        cost = 76,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = true,
                },
                description = _(
                    "scienceDescription-station",
                    "Autodoc components"
                ),
                general = "",
                history = _(
                    "stationStory-comms",
                    "The station is named after Dr. Lipkin who pioneered some of the research and application around robot assisted surgery in the area of partial nephrectomy for renal tumors in the early 21st century on Earth"
                ),
            },
            ["Madison"] = {
                weapon_available = {
                    Homing = false,
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 2.0,
                },
                goods = {
                    luxury = {
                        quantity = 5,
                        cost = math.random(60, 70),
                    },
                },
                trade = {
                    food = false,
                    medicine = true,
                    luxury = false,
                },
                description = _(
                    "scienceDescription-station",
                    "Zero gravity sports and entertainment"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "Come take in a game or two or perhaps see a show"
                ),
                history = _(
                    "stationStory-comms",
                    "Named after Madison Square Gardens from 21st century Earth, this station was designed to serve similar purposes in space - a venue for sports and entertainment"
                ),
            },
            ["Rutherford"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 2.0,
                },
                goods = {
                    shield = {
                        quantity = 5,
                        cost = 90,
                    },
                },
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
                    "We research and fabricate components for ship shield systems"
                ),
                history = _(
                    "stationStory-comms",
                    "This station was named after the national research institution Rutherford Appleton Laboratory in the United Kingdom which conducted some preliminary research into the feasability of generating an energy shield in the late 20th century"
                ),
            },
            ["Toohie"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    shield = {
                        quantity = 5,
                        cost = 90,
                    },
                },
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
                    "We research and make general and specialized components for ship shield and ship armor systems"
                ),
                history = _(
                    "stationStory-comms",
                    "This station was named after one of the earliest researchers in shield technology, Alexander Toohie back when it was considered impractical to construct shields due to the physics involved."
                ),
            },
        },
        ["Alt Sci Fi"] = {
            ["Anderson"] = {
                weapon_available = {
                    Homing = false,
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 2.0,
                },
                goods = {
                    battery = {
                        quantity = 5,
                        cost = 66,
                    },
                    software = {
                        quantity = 5,
                        cost = 115,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = true,
                },
                description = _(
                    "scienceDescription-station",
                    "Battery and software engineering"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We provide high quality high capacity batteries and specialized software for all shipboard systems"
                ),
                history = _(
                    "stationStory-comms",
                    "The station is named after a fictional software engineer in a late 20th century movie depicting humanity unknowingly conquered by aliens and kept docile by software generated illusion"
                ),
            },
            ["Archer"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = true,
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = true,
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                goods = {
                    shield = {
                        quantity = 5,
                        cost = 90,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = true,
                },
                buy = {
                    [randomMineral()] = math.random(40, 200),
                },
                description = _(
                    "scienceDescription-station",
                    "Shield and Armor Research"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "The finest shield and armor manufacturer in the quadrant"
                ),
                history = _(
                    "stationStory-comms",
                    "We named this station for the pioneering spirit of the 22nd century Starfleet explorer, Captain Jonathan Archer"
                ),
            },
            ["Barclay"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = false,
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                goods = {
                    communication = {
                        quantity = 5,
                        cost = 58,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                buy = {
                    [randomMineral()] = math.random(40, 200),
                },
                description = _(
                    "scienceDescription-station",
                    "Communication components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We provide a range of communication equipment and software for use aboard ships"
                ),
                history = _(
                    "stationStory-comms",
                    "The station is named after Reginald Barclay who established the first transgalactic com link through the creative application of a quantum singularity. Station personnel often refer to the station as the Broccoli station"
                ),
            },
            ["Calvin"] = {
                weapon_available = {
                    Homing = false,
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                goods = {
                    robotic = {
                        quantity = 5,
                        cost = 90,
                    },
                },
                trade = {
                    food = random(1, 100) <= 35,
                    medicine = false,
                    luxury = true,
                },
                buy = {
                    [randomComponent("robotic")] = math.random(40, 200),
                },
                description = _(
                    "scienceDescription-station",
                    "Robotic research"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We research and provide robotic systems and components"
                ),
                history = _(
                    "stationStory-comms",
                    "This station is named after Dr. Susan Calvin who pioneered robotic behavioral research and programming"
                ),
            },
            ["Cavor"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 2.0,
                },
                goods = {
                    filament = {
                        quantity = 5,
                        cost = 42,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _(
                    "scienceDescription-station",
                    "Advanced Material components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We fabricate several different kinds of materials critical to various space industries like ship building, station construction and mineral extraction"
                ),
                history = _(
                    "stationStory-comms",
                    "We named our station after Dr. Cavor, the physicist that invented a barrier material for gravity waves - Cavorite"
                ),
            },
            ["Cyrus"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    impulse = {
                        quantity = 5,
                        cost = 124,
                    },
                },
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
                    "We supply high quality impulse engines and parts for use aboard ships"
                ),
                history = _(
                    "stationStory-comms",
                    "This station was named after the fictional engineer, Cyrus Smith created by 19th century author Jules Verne"
                ),
            },
            ["Deckard"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 2.0,
                },
                goods = {
                    android = {
                        quantity = 5,
                        cost = 73,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = true,
                },
                description = _(
                    "scienceDescription-station",
                    "Android components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "Supplier of android components, programming and service"
                ),
                history = _(
                    "stationStory-comms",
                    "Named for Richard Deckard who inspired many of the sophisticated safety security algorithms now required for all androids"
                ),
            },
            ["Erickson"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                goods = {
                    transporter = {
                        quantity = 5,
                        cost = 63,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = true,
                },
                description = _(
                    "scienceDescription-station",
                    "Transporter components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We provide transporters used aboard ships as well as the components for repair and maintenance"
                ),
                history = _(
                    "stationStory-comms",
                    "The station is named after the early 22nd century inventor of the transporter, Dr. Emory Erickson. This station is proud to have received the endorsement of Admiral Leonard McCoy"
                ),
            },
            ["Jabba"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 2.0,
                },
                goods = {
                    luxury = {
                        quantity = 5,
                        cost = math.random(30, 80),
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _(
                    "scienceDescription-station",
                    "Commerce and gambling"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "Come play some games and shop. House take does not exceed 4 percent"
                ),
                history = "",
            },
            ["Komov"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = true,
                    Nuke = false,
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 2.0,
                },
                goods = {
                    filament = {
                        quantity = 5,
                        cost = 46,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _(
                    "scienceDescription-station",
                    "Xenopsychology training"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We provide classes and simulation to help train diverse species in how to relate to each other"
                ),
                history = _(
                    "stationStory-comms",
                    "A continuation of the research initially conducted by Dr. Gennady Komov in the early 22nd century on Venus, supported by the application of these principles"
                ),
            },
            ["Lando"] = {
                weapon_available = {
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
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                goods = {
                    shield = {
                        quantity = 5,
                        cost = 90,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _(
                    "scienceDescription-station",
                    "Casino and Gambling"
                ),
                general = "",
                history = "",
            },
            ["Muddville"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                goods = {
                    luxury = {
                        quantity = 5,
                        cost = 60,
                    },
                },
                trade = {
                    food = true,
                    medicine = true,
                    luxury = false,
                },
                description = _(
                    "scienceDescription-station",
                    "Trading station"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "Come to Muddvile for all your trade and commerce needs and desires"
                ),
                history = _(
                    "stationStory-comms",
                    "Upon retirement, Harry Mudd started this commercial venture using his leftover inventory and extensive connections obtained while he traveled the stars as a salesman"
                ),
            },
            ["Nexus-6"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = false,
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    android = {
                        quantity = 5,
                        cost = 93,
                    },
                },
                trade = {
                    food = false,
                    medicine = true,
                    luxury = false,
                },
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
                    "Androids, their parts, maintenance and recylcling"
                ),
                history = _(
                    "stationStory-comms",
                    "We named the station after the ground breaking android model produced by the Tyrell corporation"
                ),
            },
            ["O'Brien"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    transporter = {
                        quantity = 5,
                        cost = 76,
                    },
                },
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
                    "We research and fabricate high quality transporters and transporter components for use aboard ships"
                ),
                history = _(
                    "stationStory-comms",
                    "Miles O'Brien started this business after his experience as a transporter chief"
                ),
            },
            ["Organa"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 2.0,
                },
                goods = {
                    luxury = {
                        quantity = 5,
                        cost = 95,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _(
                    "scienceDescription-station",
                    "Diplomatic training"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "The premeire academy for leadership and diplomacy training in the region"
                ),
                history = _(
                    "stationStory-comms",
                    "Established by the royal family so critical during the political upheaval era"
                ),
            },
            ["Owen"] = {
                weapon_available = {
                    Homing = true,
                    HVLI = false,
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    lifter = {
                        quantity = 5,
                        cost = 61,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = true,
                },
                description = _(
                    "scienceDescription-station",
                    "Load lifters and components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We provide load lifters and components for various ship systems"
                ),
                history = _(
                    "stationStory-comms",
                    "Owens started off in the moisture vaporator business on Tattooine then branched out into load lifters based on acquisition of proprietary software and protocols. The station name recognizes the tragic loss of our founder to Imperial violence"
                ),
            },
            ["Ripley"] = {
                weapon_available = {
                    Homing = false,
                    HVLI = true,
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    lifter = {
                        quantity = 5,
                        cost = 82,
                    },
                },
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
                    "We provide load lifters and components"
                ),
                history = _(
                    "stationStory-comms",
                    "The station is named after Ellen Ripley who made creative and effective use of one of our load lifters when defending her ship"
                ),
            },
            ["Skandar"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 2.0,
                },
                goods = {
                    luxury = {
                        quantity = 5,
                        cost = math.random(30, 80),
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _(
                    "scienceDescription-station",
                    "Routine maintenance and entertainment"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "Stop by for repairs. Take in one of our juggling shows featuring the four-armed Skandars"
                ),
                history = _(
                    "stationStory-comms",
                    "The nomadic Skandars have set up at this station to practice their entertainment and maintenance skills as well as build a community where Skandars can relax"
                ),
            },
            ["Soong"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    android = {
                        quantity = 5,
                        cost = 73,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = true,
                },
                description = _(
                    "scienceDescription-station",
                    "Android components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We create androids and android components"
                ),
                history = _(
                    "stationStory-comms",
                    "The station is named after Dr. Noonian Soong, the famous android researcher and builder"
                ),
            },
            ["Starnet"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    software = {
                        quantity = 5,
                        cost = 140,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _(
                    "scienceDescription-station",
                    "Automated weapons systems"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We research and create automated weapons systems to improve ship combat capability"
                ),
                history = _(
                    "stationStory-comms",
                    "Lost the history memory bank. Recovery efforts only brought back the phrase, 'I'll be back'"
                ),
            },
            ["Tiberius"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                goods = {
                    food = {
                        quantity = 5,
                        cost = 1,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _(
                    "scienceDescription-station",
                    "Logistics coordination"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We support the stations and ships in the area with planning and communication services"
                ),
                history = _(
                    "stationStory-comms",
                    "We recognize the influence of Starfleet Captain James Tiberius Kirk in the 23rd century in our station name"
                ),
            },
            ["Tokra"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    filament = {
                        quantity = 5,
                        cost = 42,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _(
                    "scienceDescription-station",
                    "Advanced material components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We create multiple types of advanced material components. Our most popular products are our filaments"
                ),
                history = _(
                    "stationStory-comms",
                    "We learned several of our critical industrial processes from the Tokra race, so we honor our fortune by naming the station after them"
                ),
            },
            ["Utopia Planitia"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = true,
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                goods = {
                    warp = {
                        quantity = 5,
                        cost = 167,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _(
                    "scienceDescription-station",
                    "Ship building and maintenance facility"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We work on all aspects of naval ship building and maintenance. Many of the naval models are researched, designed and built right here on this station. Our design goals seek to make the space faring experience as simple as possible given the tremendous capabilities of the modern naval vessel"
                ),
                history = "",
            },
            ["Vaiken"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                goods = {
                    food = {
                        quantity = 10,
                        cost = 1,
                    },
                    medicine = {
                        quantity = 5,
                        cost = 5,
                    },
                    impulse = {
                        quantity = 5,
                        cost = math.random(65, 97),
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _(
                    "scienceDescription-station",
                    "Ship building and maintenance facility"
                ),
                general = "",
                history = "",
            },
            ["Zefram"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    warp = {
                        quantity = 5,
                        cost = 140,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = true,
                },
                description = _(
                    "scienceDescription-station",
                    "Warp engine components"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "We specialize in the esoteric components necessary to make warp drives function properly"
                ),
                history = _(
                    "stationStory-comms",
                    "Zefram Cochrane constructed the first warp drive in human history. We named our station after him because of the specialized warp systems work we do"
                ),
            },
        },
        ["Spec Sci Fi"] = {
            ["Alcaleica"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                goods = {
                    optic = {
                        quantity = 5,
                        cost = 66,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                buy = {
                    [randomMineral()] = math.random(40, 200),
                },
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
            },
            ["Bethesda"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    autodoc = {
                        quantity = 5,
                        cost = 36,
                    },
                    medicine = {
                        quantity = 5,
                        cost = 5,
                    },
                    food = {
                        quantity = math.random(5, 10),
                        cost = 1,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
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
            },
            ["Deer"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                goods = {
                    tractor = {
                        quantity = 5,
                        cost = 90,
                    },
                    repulsor = {
                        quantity = 5,
                        cost = math.random(85, 95),
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = true,
                },
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
            },
            ["Evondos"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = true,
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    autodoc = {
                        quantity = 5,
                        cost = 56,
                    },
                },
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
            },
            ["Feynman"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = true,
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    software = {
                        quantity = 5,
                        cost = 115,
                    },
                    nanites = {
                        quantity = 5,
                        cost = 79,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = true,
                },
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
            },
            ["Mayo"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                goods = {
                    autodoc = {
                        quantity = 5,
                        cost = 128,
                    },
                    food = {
                        quantity = 5,
                        cost = 1,
                    },
                    medicine = {
                        quantity = 5,
                        cost = 5,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
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
            },
            ["Olympus"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    optic = {
                        quantity = 5,
                        cost = 66,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
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
            },
            ["Panduit"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    optic = {
                        quantity = 5,
                        cost = 79,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = true,
                },
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
            },
            ["Shree"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    tractor = {
                        quantity = 5,
                        cost = 90,
                    },
                    repulsor = {
                        quantity = 5,
                        cost = math.random(85, 95),
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = true,
                },
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
            },
            ["Vactel"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                goods = {
                    circuit = {
                        quantity = 5,
                        cost = 50,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
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
            },
            ["Veloquan"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    sensor = {
                        quantity = 5,
                        cost = 68,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
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
            },
            ["Tandon"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {},
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
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
            },
        },
        ["Generic"] = {
            ["California"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                goods = {
                    gold = {
                        quantity = 5,
                        cost = 90,
                    },
                    dilithium = {
                        quantity = 2,
                        cost = 25,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _("scienceDescription-station", "Mining station"),
                general = "",
                history = "",
            },
            ["Impala"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    luxury = {
                        quantity = 5,
                        cost = 70,
                    },
                },
                trade = {
                    food = true,
                    medicine = false,
                    luxury = true,
                },
                buy = {
                    [randomComponent()] = math.random(40, 200),
                },
                description = _("scienceDescription-station", "Mining"),
                general = _(
                    "stationGeneralInfo-comms",
                    "We mine nearby asteroids for precious minerals"
                ),
                history = "",
            },
            ["Krak"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = true,
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    nickel = {
                        quantity = 5,
                        cost = 20,
                    },
                },
                trade = {
                    food = random(1, 100) < 50,
                    medicine = true,
                    luxury = random(1, 100) < 50,
                },
                buy = {
                    [randomComponent()] = math.random(40, 200),
                },
                description = _("scienceDescription-station", "Mining station"),
                general = "",
                history = "",
            },
            ["Krik"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    nickel = {
                        quantity = 5,
                        cost = 20,
                    },
                },
                trade = {
                    food = true,
                    medicine = true,
                    luxury = random(1, 100) < 50,
                },
                description = _("scienceDescription-station", "Mining station"),
                general = "",
                history = "",
            },
            ["Kruk"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    nickel = {
                        quantity = 5,
                        cost = 20,
                    },
                },
                trade = {
                    food = random(1, 100) < 50,
                    medicine = random(1, 100) < 50,
                    luxury = true,
                },
                buy = {
                    [randomComponent()] = math.random(40, 200),
                },
                description = _("scienceDescription-station", "Mining station"),
                general = "",
                history = "",
            },
            [ST.MAVERICK] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                goods = {
                    luxury = {
                        quantity = 5,
                        cost = math.random(30, 80),
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _(
                    "scienceDescription-station",
                    "Gambling and resupply"
                ),
                general = _(
                    "stationGeneralInfo-comms",
                    "Relax and meet some interesting players"
                ),
                history = "",
            },
            ["Nefatha"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 2.0,
                },
                goods = {
                    luxury = {
                        quantity = 5,
                        cost = math.random(30, 80),
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _(
                    "scienceDescription-station",
                    "Commerce and recreation"
                ),
                general = "",
                history = "",
            },
            ["Okun"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = false,
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {},
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _(
                    "scienceDescription-station",
                    "Xenopsychology research"
                ),
                general = "",
                history = "",
            },
            ["Outpost-15"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 2.0,
                },
                goods = {
                    luxury = {
                        quantity = 5,
                        cost = math.random(30, 80),
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _(
                    "scienceDescription-station",
                    "Mining and trade"
                ),
                general = "",
                history = "",
            },
            ["Outpost-21"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 2.0,
                },
                goods = {
                    luxury = {
                        quantity = 5,
                        cost = math.random(30, 80),
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _(
                    "scienceDescription-station",
                    "Mining and gambling"
                ),
                general = "",
                history = "",
            },
            ["Outpost-7"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 2.0,
                },
                goods = {
                    luxury = {
                        quantity = 5,
                        cost = math.random(30, 80),
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _("scienceDescription-station", "Resupply"),
                general = "",
                history = "",
            },
            ["Outpost-8"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 2.0,
                },
                goods = {
                    luxury = {
                        quantity = 5,
                        cost = math.random(30, 80),
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = "",
                general = "",
                history = "",
            },
            ["Outpost-33"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 2.0,
                },
                goods = {
                    luxury = {
                        quantity = 5,
                        cost = math.random(30, 80),
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _("scienceDescription-station", "Resupply"),
                general = "",
                history = "",
            },
            ["Prada"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = false,
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 2.0,
                },
                goods = {},
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _(
                    "scienceDescription-station",
                    "Textiles and fashion"
                ),
                general = "",
                history = "",
            },
            ["Research-11"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 2.0,
                },
                goods = {
                    medicine = {
                        quantity = 5,
                        cost = math.random(30, 80),
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _(
                    "scienceDescription-station",
                    "Stress Psychology Research"
                ),
                general = "",
                history = "",
            },
            ["Research-19"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 2.0,
                },
                goods = {},
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _(
                    "scienceDescription-station",
                    "Low gravity research"
                ),
                general = "",
                history = "",
            },
            ["Rubis"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {
                    luxury = {
                        quantity = 5,
                        cost = math.random(30, 80),
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _("scienceDescription-station", "Resupply"),
                general = _(
                    "stationGeneralInfo-comms",
                    "Get your energy here! Grab a drink before you go!"
                ),
                history = "",
            },
            ["Science-2"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                goods = {
                    circuit = {
                        quantity = 5,
                        cost = math.random(30, 80),
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _(
                    "scienceDescription-station",
                    "Research Lab and Observatory"
                ),
                general = "",
                history = "",
            },
            ["Science-4"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 2.0,
                },
                goods = {
                    medicine = {
                        quantity = 5,
                        cost = math.random(30, 80),
                    },
                    autodoc = {
                        quantity = 5,
                        cost = math.random(30, 80),
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _(
                    "scienceDescription-station",
                    "Biotech research"
                ),
                general = "",
                history = "",
            },
            ["Science-7"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                goods = {
                    food = {
                        quantity = 2,
                        cost = 1,
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _("scienceDescription-station", "Observatory"),
                general = "",
                history = "",
            },
            ["Spot"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                },
                goods = {},
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _("scienceDescription-station", "Observatory"),
                general = "",
                history = "",
            },
            ["Valero"] = {
                weapon_available = {
                    Homing = random(1, 13) <= (8 - difficulty),
                    HVLI = random(1, 13) <= (9 - difficulty),
                    Mine = random(1, 13) <= (7 - difficulty),
                    Nuke = random(1, 13) <= (5 - difficulty),
                    EMP = random(1, 13) <= (6 - difficulty),
                },
                services = {
                    supplydrop = "friend",
                    reinforcements = "friend",
                    jumpsupplydrop = "friend",
                },
                service_cost = {
                    supplydrop = math.random(80, 120),
                    reinforcements = math.random(125, 175),
                    jumpsupplydrop = math.random(110, 140),
                },
                reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 2.0,
                },
                goods = {
                    luxury = {
                        quantity = 5,
                        cost = math.random(30, 80),
                    },
                },
                trade = {
                    food = false,
                    medicine = false,
                    luxury = false,
                },
                description = _("scienceDescription-station", "Resupply"),
                general = "",
                history = "",
            },
        },
        ["Sinister"] = {
            ["Aramanth"] = {
                goods = {},
                description = "",
                general = "",
                history = "",
            },
            ["Empok Nor"] = {
                goods = {},
                description = "",
                general = "",
                history = "",
            },
            ["Gandala"] = {
                goods = {},
                description = "",
                general = "",
                history = "",
            },
            ["Hassenstadt"] = {
                goods = {},
                description = "",
                general = "",
                history = "",
            },
            ["Kaldor"] = {
                goods = {},
                description = "",
                general = "",
                history = "",
            },
            ["Magenta Mesra"] = {
                goods = {},
                description = "",
                general = "",
                history = "",
            },
            ["Mos Eisley"] = {
                goods = {},
                description = "",
                general = "",
                history = "",
            },
            ["Questa Verde"] = {
                goods = {},
                description = "",
                general = "",
                history = "",
            },
            ["R'lyeh"] = {
                goods = {},
                description = "",
                general = "",
                history = "",
            },
            ["Scarlet Citadel"] = {
                goods = {},
                description = "",
                general = "",
                history = "",
            },
            ["Stahlstadt"] = {
                goods = {},
                description = "",
                general = "",
                history = "",
            },
            ["Ticonderoga"] = {
                goods = {},
                description = "",
                general = "",
                history = "",
            },
        },
    }
    local station_priority = {}
    table.insert(station_priority, "Science")
    table.insert(station_priority, "Alt Sci Fi")
    table.insert(station_priority, "Spec Sci Fi")
    table.insert(station_priority, "History")
    table.insert(station_priority, "Generic")
    for group, list in pairs(station_pool) do
        local already_inserted = false
        for _, previous_group in ipairs(station_priority) do
            if group == previous_group then
                already_inserted = true
                break
            end
        end
        if not already_inserted and group ~= "Sinister" then
            table.insert(station_priority, group)
        end
    end

    return station_pool, station_priority
end

return M
