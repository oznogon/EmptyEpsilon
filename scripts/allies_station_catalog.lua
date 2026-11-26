-- Allies and Enemies station catalog.

local M = {}

local function deepCopy(value, seen)
    if type(value) ~= "table" then
        return value
    end

    seen = seen or {}
    if seen[value] ~= nil then
        return seen[value]
    end

    local copy = {}
    seen[value] = copy
    for key, entry in pairs(value) do
        copy[deepCopy(key, seen)] = deepCopy(entry, seen)
    end
    return copy
end

local function appendAll(target, values)
    for _, value in ipairs(values or {}) do
        table.insert(target, value)
    end
end

local function resolveValue(value)
    if
        type(value) == "table"
        and #value == 2
        and type(value[1]) == "number"
        and type(value[2]) == "number"
    then
        return math.random(value[1], value[2])
    end
    return value
end

local function resolveGoods(goods)
    local resolved = {}
    for _, entry in ipairs(goods or {}) do
        table.insert(
            resolved,
            { entry[1], resolveValue(entry[2]), resolveValue(entry[3]) }
        )
    end
    return resolved
end

local function rollMatches(chance)
    if type(chance) == "number" then
        chance = { min = 1, max = 100, limit = chance, operator = "<" }
    end
    local value
    if chance.source == "math" then
        value = math.random(chance.min or 1, chance.max or 100)
    else
        value = random(chance.min or 1, chance.max or 100)
    end
    if chance.operator == "<=" then
        return value <= (chance.limit or 1)
    end
    if chance.operator == ">" then
        return value > (chance.limit or 0)
    end
    return value < (chance.limit or 0)
end

local function choiceMatches(choice, value)
    if choice.when_lt ~= nil and value >= choice.when_lt then
        return false
    end
    if choice.when_lte ~= nil and value > choice.when_lte then
        return false
    end
    if choice.when_gt ~= nil and value <= choice.when_gt then
        return false
    end
    if choice.when_gte ~= nil and value < choice.when_gte then
        return false
    end
    if choice.when_eq ~= nil and value ~= choice.when_eq then
        return false
    end
    return true
end

local function runRules(rules, station, faction, context, inherited_roll)
    for _, rule in ipairs(rules or {}) do
        local matches = true
        if rule.faction == "human" then
            matches = faction == "Human Navy"
        elseif rule.faction == "other" then
            matches = faction ~= "Human Navy"
        end
        if matches and inherited_roll ~= nil then
            matches = choiceMatches(rule, inherited_roll)
        end

        if matches then
            local chance_matches = true
            if rule.chance ~= nil then
                chance_matches = rollMatches(rule.chance)
            end
            if not chance_matches then
                runRules(
                    rule.otherwise,
                    station,
                    faction,
                    context,
                    inherited_roll
                )
            else
                local roll_value = inherited_roll
                if rule.roll ~= nil then
                    local roll_source = rule.roll.source == "math"
                            and math.random
                        or random
                    roll_value =
                        roll_source(rule.roll.min or 1, rule.roll.max or 100)
                    for _, choice in ipairs(rule.choices or {}) do
                        if choiceMatches(choice, roll_value) then
                            runRules(
                                choice.rules,
                                station,
                                faction,
                                context,
                                roll_value
                            )
                            break
                        end
                    end
                end
                if rule.goods ~= nil then
                    context.inventory.goods[station] = resolveGoods(rule.goods)
                end
                if rule.trade ~= nil and rule.trade ~= false then
                    context.inventory[rule.trade][station] = true
                end
                runRules(rule.rules, station, faction, context, roll_value)
            end
        end
    end
end

local function placeAsteroidsAround(context, hook, x, y)
    if context.place_random_around == nil then
        return
    end
    context.place_random_around(
        Asteroid,
        hook.amount,
        hook.distance_min,
        hook.distance_max,
        x,
        y
    )
end

local function placeAsteroidArcs(context, hook, x, y)
    local arcs = hook.arcs or hook
    local pos_axis = random(0, 360)
    local pos_distance =
        random(arcs.positive_distance[1], arcs.positive_distance[2])
    local neg_distance =
        random(arcs.negative_distance[1], arcs.negative_distance[2])
    local spread = random(arcs.spread[1], arcs.spread[2])
    local neg_axis = pos_axis + 180
    local pos_x, pos_y = context.vector_from_angle(pos_axis, pos_distance)
    local pos_end = random(arcs.positive_arc[1], arcs.positive_arc[2])
    local neg_end
    if not hook.negative_arc_after_first then
        neg_end = random(arcs.negative_arc[1], arcs.negative_arc[2])
    end
    context.create_random_along_arc(
        Asteroid,
        30 + pos_end,
        x + pos_x,
        y + pos_y,
        pos_distance,
        neg_axis,
        neg_axis + pos_end,
        spread
    )
    local neg_x, neg_y = context.vector_from_angle(neg_axis, neg_distance)
    if hook.negative_arc_after_first then
        neg_end = random(arcs.negative_arc[1], arcs.negative_arc[2])
    end
    context.create_random_along_arc(
        Asteroid,
        30 + neg_end,
        x + neg_x,
        y + neg_y,
        neg_distance,
        pos_axis,
        pos_axis + neg_end,
        spread
    )
end

local function runHook(context, hook, x, y)
    if hook.type == "asteroids_around" then
        placeAsteroidsAround(context, hook, x, y)
    elseif hook.type == "asteroid_arcs" then
        placeAsteroidArcs(context, hook, x, y)
    end
end

local function ensurePool(catalog)
    if catalog.pool ~= nil then
        return
    end

    local records = catalog.config.records
    if type(records) == "function" then
        catalog.pool = deepCopy(records())
    else
        catalog.pool = deepCopy(records or {})
    end
end

local function takeRecord(catalog, name)
    ensurePool(catalog)
    local record = catalog.pool[name]
    if record == nil then
        return nil
    end
    catalog.pool[name] = nil
    return record
end

function M.new(config, context)
    local instance = {
        config = deepCopy(config or {}),
        context = context or {},
        groups = deepCopy((config or {}).groups or {}),
    }
    setmetatable(instance, { __index = M })
    return instance
end

function M:group(name)
    return self.groups[name]
end

function M:place(x, y, name, faction, size)
    if x == nil or y == nil then
        return nil
    end

    local context = self.context
    local record = takeRecord(self, name)
    if record == nil then
        return nil
    end

    local hook = (self.config.hooks or {})[name]
    if hook ~= nil and hook.stage == "before_template" then
        runHook(context, hook, x, y)
    end

    local station = SpaceStation()
    if size ~= nil then
        station:setTemplate(size)
    end

    if faction == nil then
        faction = context.faction
    end
    if faction == nil then
        faction = stationFaction
    end
    if faction == nil then
        faction = "Independent"
    end
    station:setFaction(faction)

    if record.comms ~= false then
        local comms = context.comms or commsStation
        if comms ~= nil then
            station:setCommsScript(""):setCommsFunction(comms)
        end
    end
    station:setPosition(x, y):setCallSign(name)
    if record.description ~= nil then
        station:setDescription(record.description)
    end

    station.publicRelations = record.public_relations
    station.generalInformation = record.general_information
    station.stationHistory = record.history

    if hook ~= nil and hook.stage == "before_inventory" then
        runHook(context, hook, x, y)
    end
    runRules(record.rules, station, faction, context)
    if
        hook ~= nil
        and (hook.stage == "after_inventory" or hook.stage == "after_services")
    then
        runHook(context, hook, x, y)
    end
    return station
end

local function joinGoods(...)
    local joined = {}
    for _, goods in ipairs({ ... }) do
        appendAll(joined, goods)
    end
    return joined
end

local function tradeRules(specs)
    local rules = {}
    for _, spec in ipairs(specs or {}) do
        if type(spec) == "string" then
            table.insert(rules, { trade = spec })
        else
            local rule = deepCopy(spec)
            if type(rule.chance) == "number" then
                rule.chance =
                    { min = 1, max = 100, limit = rule.chance, operator = "<" }
            end
            table.insert(rules, rule)
        end
    end
    return rules
end

local function alliesRecord(config, rules)
    return {
        description = config.description,
        public_relations = config.public_relations,
        general_information = config.general_information,
        history = config.history,
        comms = config.comms,
        rules = rules,
    }
end

local function standardAlliesRecord(config)
    local rules = {}
    local base_goods = config.goods or {}
    local food_goods = { { "food", { 5, 10 }, 1 } }
    local food_medicine_goods =
        joinGoods(food_goods, { { "medicine", 5, 5 } }, base_goods)
    local food_base_goods = joinGoods(food_goods, base_goods)
    if config.human_goods ~= nil then
        table.insert(rules, { faction = "human", goods = config.human_goods })
    elseif config.human_medicine == false then
        table.insert(rules, { faction = "human", goods = food_base_goods })
    else
        local medicine_chance = config.human_medicine
            or { min = 1, max = 5, limit = 1, operator = "<=" }
        if type(medicine_chance) == "number" then
            medicine_chance =
                { min = 1, max = 5, limit = medicine_chance, operator = "<=" }
        end
        local otherwise = { { goods = food_base_goods } }
        appendAll(otherwise, tradeRules(config.human_failure_trade))
        local human_rule = {
            faction = "human",
            chance = medicine_chance,
            goods = food_medicine_goods,
            otherwise = otherwise,
            rules = tradeRules(config.human_success_trade),
        }
        table.insert(rules, human_rule)
    end
    table.insert(
        rules,
        { faction = "other", goods = config.default_goods or base_goods }
    )
    for _, rule in ipairs(tradeRules(config.default_trade)) do
        rule.faction = "other"
        table.insert(rules, rule)
    end
    appendAll(rules, tradeRules(config.trade))
    return alliesRecord(config, rules)
end

local function fixedAlliesRecord(config)
    return alliesRecord(config, { { goods = config.goods } })
end

local function choiceAlliesRecord(config)
    local choices = {}
    for index, goods in ipairs(config.choices) do
        table.insert(
            choices,
            { when_eq = index, rules = { { goods = goods } } }
        )
    end
    return alliesRecord(
        config,
        { { roll = { source = "math", min = 1, max = 3 }, choices = choices } }
    )
end

local function miningChoiceRules(choice, config)
    local food_goods = { { "food", { 5, 10 }, 1 } }
    local otherwise = { { goods = joinGoods(choice.goods, food_goods) } }
    appendAll(otherwise, tradeRules(config.human_failure_trade))
    local rules = {
        {
            faction = "human",
            chance = { min = 1, max = 5, limit = 1, operator = "<=" },
            goods = joinGoods(
                choice.goods,
                food_goods,
                { { "medicine", 5, 5 } }
            ),
            otherwise = otherwise,
        },
        { faction = "other", goods = choice.goods },
    }
    for _, rule in ipairs(tradeRules(config.default_trade)) do
        rule.faction = "other"
        table.insert(rules, rule)
    end
    return rules
end

local function miningAlliesRecord(config)
    config.mineral_choices = deepCopy(config.mineral_choices)
    local rules = tradeRules(config.leading_trade)
    table.insert(rules, {
        roll = { min = 1, max = 100 },
        choices = config.mineral_choices,
    })
    for _, choice in ipairs(config.mineral_choices) do
        choice.rules = miningChoiceRules(choice, config)
    end
    appendAll(rules, tradeRules(config.trade))
    return alliesRecord(config, rules)
end

local function mineralChoices(krik)
    local choices = {
        {
            when_lt = 10,
            goods = {
                { "nickel", 5, 20 },
                { "platinum", 5, 70 },
                { "tritanium", 5, 50 },
                { "dilithium", 5, 50 },
            },
        },
        {
            when_lt = 20,
            goods = {
                { "nickel", 5, 20 },
                { "platinum", 5, 70 },
                { "tritanium", 5, 50 },
            },
        },
        {
            when_lt = 30,
            goods = {
                { "nickel", 5, 20 },
                { "platinum", 5, 70 },
                { "dilithium", 5, 50 },
            },
        },
        {
            when_lt = 40,
            goods = {
                { "nickel", 5, 20 },
                { "tritanium", 5, 50 },
                { "dilithium", 5, 50 },
            },
        },
        {
            when_lt = 50,
            goods = { { "nickel", 5, 20 }, { "dilithium", 5, 50 } },
        },
        {
            when_lt = 60,
            goods = { { "nickel", 5, 20 }, { "platinum", 5, 70 } },
        },
        {
            when_lt = 70,
            goods = { { "nickel", 5, 20 }, { "tritanium", 5, 50 } },
        },
    }
    if krik then
        table.insert(choices, {
            when_lt = 80,
            goods = {
                { "platinum", 5, 70 },
                { "tritanium", 5, 50 },
                { "dilithium", 5, 50 },
            },
        })
        table.insert(choices, { goods = { { "nickel", 5, 20 } } })
    else
        table.insert(choices, {
            when_lt = 80,
            goods = {
                { "platinum", 5, 70 },
                { "tritanium", 5, 50 },
                { "dilithium", 5, 50 },
            },
        })
        table.insert(choices, { goods = { { "nickel", 5, 20 } } })
    end
    return choices
end

local function mineralGoodsRule(choices)
    for _, choice in ipairs(choices) do
        choice.rules = { { goods = choice.goods } }
        choice.goods = nil
    end
    return {
        roll = { min = 1, max = 100 },
        choices = choices,
    }
end

local function buildAlliesRecords()
    local records = {}

    records.Alcaleica = standardAlliesRecord({
        description = _("scienceDescription-station", "Optical Components"),
        goods = { { "optic", 5, 66 } },
        human_failure_trade = { "medicine" },
        default_trade = { "food", "medicine" },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We make and supply optic components for various station and ship systems"
        ),
        history = _(
            "stationStory-comms",
            "This station continues the businesses from Earth based on the merging of several companies including Leica from Switzerland, the lens manufacturer and the Japanese advanced low carbon electronic and optic company"
        ),
    })
    records.Anderson = standardAlliesRecord({
        description = _(
            "scienceDescription-station",
            "Battery and software engineering"
        ),
        goods = { { "battery", 5, 65 }, { "software", 5, 115 } },
        trade = { "luxury" },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We provide high quality high capacity batteries and specialized software for all shipboard systems"
        ),
        history = _(
            "stationStory-comms",
            "The station is named after a fictional software engineer in a late 20th century movie depicting humanity unknowingly conquered by aliens and kept docile by software generated illusion"
        ),
    })
    records.Archer = standardAlliesRecord({
        description = _(
            "scienceDescription-station",
            "Shield and Armor Research"
        ),
        goods = { { "shield", 5, 90 } },
        human_failure_trade = { "medicine" },
        default_trade = { "medicine" },
        trade = { "luxury" },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "The finest shield and armor manufacturer in the quadrant"
        ),
        history = _(
            "stationStory-comms",
            "We named this station for the pioneering spirit of the 22nd century Starfleet explorer, Captain Jonathan Archer"
        ),
    })
    records.Archimedes = standardAlliesRecord({
        description = _(
            "scienceDescription-station",
            "Energy and particle beam components"
        ),
        goods = { { "beam", 5, 80 } },
        human_failure_trade = { "medicine" },
        default_trade = { "food" },
        trade = { "luxury" },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We fabricate general and specialized components for ship beam systems"
        ),
        history = _(
            "stationStory-comms",
            "This station was named after Archimedes who, according to legend, used a series of adjustable focal length mirrors to focus sunlight on a Roman naval fleet invading Syracuse, setting fire to it"
        ),
    })
    records.Armstrong = standardAlliesRecord({
        description = _(
            "scienceDescription-station",
            "Warp and Impulse engine manufacturing"
        ),
        goods = { { "repulsor", 5, 62 } },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We manufacture warp, impulse and jump engines for the human navy fleet as well as other independent clients on a contract basis"
        ),
        history = _(
            "stationStory-comms",
            "The station is named after the late 19th century astronaut as well as the fictionlized stations that followed. The station initially constructed entire space worthy vessels. In time, it transitioned into specializeing in propulsion systems."
        ),
    })
    records.Asimov = standardAlliesRecord({
        description = _(
            "scienceDescription-station",
            "Training and Coordination"
        ),
        goods = { { "tractor", 5, 48 } },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We train naval cadets in routine and specialized functions aboard space vessels and coordinate naval activity throughout the sector"
        ),
        history = _(
            "stationStory-comms",
            "The original station builders were fans of the late 20th century scientist and author Isaac Asimov. The station was initially named Foundation, but was later changed simply to Asimov. It started off as a stellar observatory, then became a supply stop and as it has grown has become an educational and coordination hub for the region"
        ),
    })
    records.Barclay = standardAlliesRecord({
        description = _(
            "scienceDescription-station",
            "Communication components"
        ),
        goods = { { "communication", 5, 58 } },
        human_failure_trade = { "medicine" },
        default_trade = { "medicine" },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We provide a range of communication equipment and software for use aboard ships"
        ),
        history = _(
            "stationStory-comms",
            "The station is named after Reginald Barclay who established the first transgalactic com link through the creative application of a quantum singularity. Station personnel often refer to the station as the Broccoli station"
        ),
    })
    records.Bethesda = fixedAlliesRecord({
        description = _("scienceDescription-station", "Medical research"),
        goods = {
            { "food", { 5, 10 }, 1 },
            { "medicine", 5, 5 },
            { "autodoc", 5, 36 },
        },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We research and treat exotic medical conditions"
        ),
        history = _(
            "stationStory-comms",
            "The station is named after the United States national medical research center based in Bethesda, Maryland on earth which was established in the mid 20th century"
        ),
    })
    records.Broeck = standardAlliesRecord({
        description = _("scienceDescription-station", "Warp drive components"),
        goods = { { "warp", 5, 130 } },
        human_failure_trade = { { trade = "medicine", chance = 53 } },
        default_trade = {
            { trade = "medicine", chance = 53 },
            { trade = "food", chance = 14 },
        },
        trade = { { trade = "luxury", chance = 62 } },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We provide warp drive engines and components"
        ),
        history = _(
            "stationStory-comms",
            "This station is named after Chris Van Den Broeck who did some initial research into the possibility of warp drive in the late 20th century on Earth"
        ),
    })
    records.California = standardAlliesRecord({
        description = _("scienceDescription-station", "Mining station"),
        goods = { { "gold", 5, 25 }, { "dilithium", 2, 25 } },
    })
    records.Calvin = standardAlliesRecord({
        description = _("scienceDescription-station", "Robotic research"),
        goods = { { "robotic", 5, 87 } },
        default_trade = { { trade = "food", chance = 8 } },
        trade = { "luxury" },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We research and provide robotic systems and components"
        ),
        history = _(
            "stationStory-comms",
            "This station is named after Dr. Susan Calvin who pioneered robotic behavioral research and programming"
        ),
    })
    records.Cavor = alliesRecord({
        description = _(
            "scienceDescription-station",
            "Advanced Material components"
        ),
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We fabricate several different kinds of materials critical to various space industries like ship building, station construction and mineral extraction"
        ),
        history = _(
            "stationStory-comms",
            "We named our station after Dr. Cavor, the physicist that invented a barrier material for gravity waves - Cavorite"
        ),
    }, {
        {
            faction = "human",
            chance = { min = 1, max = 5, limit = 1, operator = "<=" },
            goods = joinGoods(
                { { "food", { 5, 10 }, 1 } },
                { { "medicine", 5, 5 } },
                { { "filament", 5, 42 } }
            ),
            rules = { { trade = "luxury", chance = 33 } },
            otherwise = {
                {
                    goods = joinGoods(
                        { { "food", { 5, 10 }, 1 } },
                        { { "filament", 5, 42 } }
                    ),
                },
                {
                    roll = { min = 1, max = 100 },
                    choices = {
                        { when_lt = 50, rules = { { trade = "medicine" } } },
                        { rules = { { trade = "luxury" } } },
                    },
                },
            },
        },
        { faction = "other", goods = { { "filament", 5, 42 } } },
        {
            faction = "other",
            roll = { min = 1, max = 100 },
            choices = {
                { when_lt = 33, rules = { { trade = "medicine" } } },
                { when_gt = 66, rules = { { trade = "food" } } },
                { rules = { { trade = "luxury" } } },
            },
        },
    })
    records.Chatuchak = standardAlliesRecord({
        description = _("scienceDescription-station", "Trading station"),
        goods = { { "luxury", 5, 60 } },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "Only the largest market and trading location in twenty sectors. You can find your heart's desire here"
        ),
        history = _(
            "stationStory-comms",
            "Modeled after the early 21st century bazaar on Earth in Bangkok, Thailand. Designed and built with trade and commerce in mind"
        ),
    })
    records.Coulomb = standardAlliesRecord({
        description = _(
            "scienceDescription-station",
            "Shielded circuitry fabrication"
        ),
        goods = { { "circuit", 5, 50 } },
        human_failure_trade = { { trade = "medicine", chance = 27 } },
        default_trade = {
            { trade = "medicine", chance = 27 },
            { trade = "food", chance = 16 },
        },
        trade = { { trade = "luxury", chance = 82 } },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We make a large variety of circuits for numerous ship systems shielded from sensor detection and external control interference"
        ),
        history = _(
            "stationStory-comms",
            "Our station is named after the law which quantifies the amount of force with which stationary electrically charged particals repel or attact each other - a fundamental principle in the design of our circuits"
        ),
    })
    records.Cyrus = standardAlliesRecord({
        description = _(
            "scienceDescription-station",
            "Impulse engine components"
        ),
        goods = { { "impulse", 5, 124 } },
        human_failure_trade = { { trade = "medicine", chance = 34 } },
        default_trade = {
            { trade = "medicine", chance = 34 },
            { trade = "food", chance = 13 },
        },
        trade = { { trade = "luxury", chance = 78 } },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We supply high quality impulse engines and parts for use aboard ships"
        ),
        history = _(
            "stationStory-comms",
            "This station was named after the fictional engineer, Cyrus Smith created by 19th century author Jules Verne"
        ),
    })
    records.Deckard = standardAlliesRecord({
        description = _("scienceDescription-station", "Android components"),
        goods = { { "android", 5, 73 } },
        default_trade = { "food" },
        trade = { "luxury" },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "Supplier of android components, programming and service"
        ),
        history = _(
            "stationStory-comms",
            "Named for Richard Deckard who inspired many of the sophisticated safety security algorithms now required for all androids"
        ),
    })
    records.Deer = standardAlliesRecord({
        description = _(
            "scienceDescription-station",
            "Repulsor and Tractor Beam Components"
        ),
        goods = { { "tractor", 5, 90 }, { "repulsor", 5, 95 } },
        human_failure_trade = { "medicine" },
        default_trade = { "food", "medicine" },
        trade = { "luxury" },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We can meet all your pushing and pulling needs with specialized equipment custom made"
        ),
        history = _(
            "stationStory-comms",
            "The station name comes from a short story by the 20th century author Clifford D. Simak as well as from the 19th century developer John Deere who inspired a company that makes the Earth bound equivalents of our products"
        ),
    })
    records.Erickson = standardAlliesRecord({
        description = _("scienceDescription-station", "Transporter components"),
        goods = { { "transporter", 5, 63 } },
        human_failure_trade = { "medicine" },
        default_trade = { "food", "medicine" },
        trade = { "luxury" },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We provide transporters used aboard ships as well as the components for repair and maintenance"
        ),
        history = _(
            "stationStory-comms",
            "The station is named after the early 22nd century inventor of the transporter, Dr. Emory Erickson. This station is proud to have received the endorsement of Admiral Leonard McCoy"
        ),
    })
    records.Evondos = standardAlliesRecord({
        description = _("scienceDescription-station", "Autodoc components"),
        goods = { { "autodoc", 5, 56 } },
        human_failure_trade = { "medicine" },
        default_trade = { "medicine" },
        trade = { { trade = "luxury", chance = 41 } },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We provide components for automated medical machinery"
        ),
        history = _(
            "stationStory-comms",
            "The station is the evolution of the company that started automated pharmaceutical dispensing in the early 21st century on Earth in Finland"
        ),
    })
    records.Feynman = standardAlliesRecord({
        description = _(
            "scienceDescription-station",
            "Nanotechnology research"
        ),
        goods = { { "nanites", 5, 79 }, { "software", 5, 115 } },
        default_trade = { "food", { trade = "food", chance = 26 } },
        trade = { "luxury" },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We provide nanites and software for a variety of ship-board systems"
        ),
        history = _(
            "stationStory-comms",
            "This station's name recognizes one of the first scientific researchers into nanotechnology, physicist Richard Feynman"
        ),
    })

    local mining_choices = {
        {
            when_lt = 20,
            goods = {
                { "luxury", 5, 70 },
                { "gold", 5, 25 },
                { "cobalt", 4, 50 },
            },
        },
        { when_lt = 40, goods = { { "luxury", 5, 70 }, { "gold", 5, 25 } } },
        { when_lt = 60, goods = { { "luxury", 5, 70 }, { "cobalt", 4, 50 } } },
        { goods = { { "luxury", 5, 70 } } },
    }
    records.Grasberg = miningAlliesRecord({
        description = _("scienceDescription-station", "Mining"),
        mineral_choices = mining_choices,
        default_trade = { "food" },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We mine nearby asteroids for precious minerals and process them for sale"
        ),
        history = _(
            "stationStory-comms",
            "This station's name is inspired by a large gold mine on Earth in Indonesia. The station builders hoped to have a similar amount of minerals found amongst these asteroids"
        ),
    })
    records.Hayden = standardAlliesRecord({
        description = _(
            "scienceDescription-station",
            "Observatory and stellar mapping"
        ),
        goods = { { "nanites", 5, 65 } },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We study the cosmos and map stellar phenomena. We also track moving asteroids. Look out! Just kidding"
        ),
    })
    records.Heyes = standardAlliesRecord({
        description = _("scienceDescription-station", "Sensor components"),
        goods = { { "sensor", 5, 72 } },
        trade = { "luxury" },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We research and manufacture sensor components and systems"
        ),
        history = _(
            "stationStory-comms",
            "The station is named after Tony Heyes the inventor of some of the earliest electromagnetic sensors in the mid 20th century on Earth in the United Kingdom to assist blind human mobility"
        ),
    })
    records.Hossam = standardAlliesRecord({
        description = _("scienceDescription-station", "Nanite supplier"),
        goods = { { "nanites", 5, 48 } },
        human_failure_trade = { { trade = "medicine", chance = 44 } },
        default_trade = {
            { trade = "medicine", chance = 44 },
            { trade = "food", chance = 24 },
        },
        trade = { { trade = "luxury", chance = 63 } },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We provide nanites for various organic and non-organic systems"
        ),
        history = _(
            "stationStory-comms",
            "This station is named after the nanotechnologist Hossam Haick from the early 21st century on Earth in Israel"
        ),
    })
    records.Impala = miningAlliesRecord({
        description = _("scienceDescription-station", "Mining"),
        mineral_choices = mining_choices,
        leading_trade = { "food", "luxury" },
        default_trade = { "food" },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We mine nearby asteroids for precious minerals"
        ),
    })
    records.Komov = standardAlliesRecord({
        description = _(
            "scienceDescription-station",
            "Xenopsychology training"
        ),
        goods = { { "filament", 5, 46 } },
        human_failure_trade = { { trade = "medicine", chance = 44 } },
        default_trade = {
            { trade = "medicine", chance = 44 },
            { trade = "food", chance = 24 },
        },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We provide classes and simulation to help train diverse species in how to relate to each other"
        ),
        history = _(
            "stationStory-comms",
            "A continuation of the research initially conducted by Dr. Gennady Komov in the early 22nd century on Venus, supported by the application of these principles"
        ),
    })
    records.Krak = alliesRecord(
        { description = _("scienceDescription-station", "Mining station") },
        {
            { trade = "food", chance = 50 },
            { trade = "luxury", chance = 50 },
            mineralGoodsRule(mineralChoices(false)),
            { trade = "medicine" },
        }
    )
    records.Kruk = alliesRecord(
        { description = _("scienceDescription-station", "Mining station") },
        {
            mineralGoodsRule(mineralChoices(false)),
            { trade = "luxury" },
            { trade = "food", chance = 50 },
            { trade = "medicine", chance = 50 },
        }
    )
    records.Lipkin = standardAlliesRecord({
        description = _("scienceDescription-station", "Autodoc components"),
        goods = { { "autodoc", 5, 76 } },
        default_trade = { "food" },
        trade = { "luxury" },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We build and repair and provide components and upgrades for automated facilities designed for ships where a doctor cannot be a crew member (commonly called autodocs)"
        ),
        history = _(
            "stationStory-comms",
            "The station is named after Dr. Lipkin who pioneered some of the research and application around robot assisted surgery in the area of partial nephrectomy for renal tumors in the early 21st century on Earth"
        ),
    })
    records.Madison = standardAlliesRecord({
        description = _(
            "scienceDescription-station",
            "Zero gravity sports and entertainment"
        ),
        goods = { { "luxury", 5, 70 } },
        human_failure_trade = { "medicine" },
        default_trade = { "medicine" },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "Come take in a game or two or perhaps see a show"
        ),
        history = _(
            "stationStory-comms",
            "Named after Madison Square Gardens from 21st century Earth, this station was designed to serve similar purposes in space - a venue for sports and entertainment"
        ),
    })
    records.Maiman = standardAlliesRecord({
        description = _("scienceDescription-station", "Energy beam components"),
        goods = { { "beam", 5, 70 } },
        human_failure_trade = { "medicine" },
        default_trade = { "medicine" },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We research and manufacture energy beam components and systems"
        ),
        history = _(
            "stationStory-comms",
            "The station is named after Theodore Maiman who researched and built the first laser in the mid 20th centuryon Earth"
        ),
    })
    records.Marconi = standardAlliesRecord({
        description = _("scienceDescription-station", "Energy Beam Components"),
        goods = { { "beam", 5, 80 } },
        human_failure_trade = { "medicine" },
        default_trade = { "medicine", "food" },
        trade = { "luxury" },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We manufacture energy beam components"
        ),
        history = _(
            "stationStory-comms",
            "Station named after Guglielmo Marconi an Italian inventor from early 20th century Earth who, along with Nicolo Tesla, claimed to have invented a death ray or particle beam weapon"
        ),
    })
    records.Mayo = fixedAlliesRecord({
        description = _("scienceDescription-station", "Medical Research"),
        goods = {
            { "food", 5, 1 },
            { "medicine", 5, 5 },
            { "autodoc", 5, 128 },
        },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We research exotic diseases and other human medical conditions"
        ),
        history = _(
            "stationStory-comms",
            "We continue the medical work started by William Worrall Mayo in the late 19th century on Earth"
        ),
    })
    records.Miller = standardAlliesRecord({
        description = _("scienceDescription-station", "Exobiology research"),
        goods = { { "optic", 10, 60 } },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We study recently discovered life forms not native to Earth"
        ),
        history = _(
            "stationStory-comms",
            "This station was named after one the early exobiologists from mid 20th century Earth, Dr. Stanley Miller"
        ),
    })
    records.Muddville = standardAlliesRecord({
        description = _("scienceDescription-station", "Trading station"),
        goods = { { "luxury", 10, 60 } },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "Come to Muddvile for all your trade and commerce needs and desires"
        ),
        history = _(
            "stationStory-comms",
            "Upon retirement, Harry Mudd started this commercial venture using his leftover inventory and extensive connections obtained while he traveled the stars as a salesman"
        ),
    })
    records["Nexus-6"] = standardAlliesRecord({
        description = _("scienceDescription-station", "Android components"),
        goods = { { "android", 5, 93 } },
        human_failure_trade = { "medicine" },
        default_trade = { "medicine" },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We research and manufacture android components and systems. Our design our androids to maximize their likeness to humans"
        ),
        history = _(
            "stationStory-comms",
            "The station is named after the ground breaking model of android produced by the Tyrell corporation"
        ),
    })
    records["O'Brien"] = standardAlliesRecord({
        description = _("scienceDescription-station", "Transporter components"),
        goods = { { "transporter", 5, 76 } },
        human_failure_trade = { { trade = "medicine", chance = 34 } },
        default_trade = {
            "medicine",
            { trade = "food", chance = 13 },
            { trade = "medicine", chance = 34 },
        },
        trade = { { trade = "luxury", chance = 43 } },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We research and fabricate high quality transporters and transporter components for use aboard ships"
        ),
        history = _(
            "stationStory-comms",
            "Miles O'Brien started this business after his experience as a transporter chief"
        ),
    })
    records.Olympus = standardAlliesRecord({
        description = _("scienceDescription-station", "Optical components"),
        goods = { { "optic", 5, 66 } },
        human_failure_trade = { "medicine" },
        default_trade = { "food", "medicine" },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We fabricate optical lenses and related equipment as well as fiber optic cabling and components"
        ),
        history = _(
            "stationStory-comms",
            "This station grew out of the Olympus company based on earth in the early 21st century. It merged with Infinera, then bought several software comapnies before branching out into space based industry"
        ),
    })
    records.Organa = fixedAlliesRecord({
        description = _("scienceDescription-station", "Diplomatic training"),
        goods = { { "luxury", 5, 96 } },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "The premeire academy for leadership and diplomacy training in the region"
        ),
        history = _(
            "stationStory-comms",
            "Established by the royal family so critical during the political upheaval era"
        ),
    })
    records["Outpost-15"] = miningAlliesRecord({
        description = _("scienceDescription-station", "Mining and trade"),
        mineral_choices = mining_choices,
        leading_trade = { "food" },
        default_trade = { "food" },
    })
    records["Outpost-21"] = miningAlliesRecord({
        description = _("scienceDescription-station", "Mining and gambling"),
        mineral_choices = mining_choices,
        human_failure_trade = { { trade = "medicine", chance = 50 } },
        default_trade = { "food", { trade = "medicine", chance = 50 } },
        trade = { "luxury" },
    })
    records.Owen = standardAlliesRecord({
        description = _(
            "scienceDescription-station",
            "Load lifters and components"
        ),
        goods = { { "lifter", 5, 61 } },
        default_trade = { "food" },
        trade = { "luxury" },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We provide load lifters and components for various ship systems"
        ),
        history = _(
            "stationStory-comms",
            "The station is named after Lars Owen. After his extensive eperience with tempermental machinery on Tatooine, he used his subject matter expertise to expand into building and manufacturing the equipment adding innovations based on his years of experience using load lifters and their relative cousins, moisture vaporators"
        ),
    })
    records.Panduit = standardAlliesRecord({
        description = _("scienceDescription-station", "Optic components"),
        goods = { { "optic", 5, 79 } },
        human_failure_trade = { { trade = "medicine", chance = 33 } },
        default_trade = {
            { trade = "medicine", chance = 33 },
            { trade = "food", chance = 27 },
        },
        trade = { "luxury" },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We provide optic components for various ship systems"
        ),
        history = _(
            "stationStory-comms",
            "This station is an outgrowth of the Panduit corporation started in the mid 20th century on Earth in the United States"
        ),
    })
    records.Ripley = standardAlliesRecord({
        description = _(
            "scienceDescription-station",
            "Load lifters and components"
        ),
        goods = { { "lifter", 5, 82 } },
        human_failure_trade = { "medicine" },
        default_trade = { { trade = "food", chance = 17 }, "medicine" },
        trade = { { trade = "luxury", chance = 47 } },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We provide load lifters and components"
        ),
        history = _(
            "stationStory-comms",
            "The station is named after Ellen Ripley who made creative and effective use of one of our load lifters when defending her ship"
        ),
    })
    records.Rutherford = standardAlliesRecord({
        description = _(
            "scienceDescription-station",
            "Shield components and research"
        ),
        goods = { { "shield", 5, 90 } },
        human_failure_trade = { "medicine" },
        default_trade = { "medicine" },
        trade = { "medicine", { trade = "luxury", chance = 43 } },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We research and fabricate components for ship shield systems"
        ),
        history = _(
            "stationStory-comms",
            "This station was named after the national research institution Rutherford Appleton Laboratory in the United Kingdom which conducted some preliminary research into the feasability of generating an energy shield in the late 20th century"
        ),
    })
    records["Science-7"] = fixedAlliesRecord({
        description = _("scienceDescription-station", "Observatory"),
        goods = { { "food", 2, 1 } },
    })
    records.Shawyer = standardAlliesRecord({
        description = _(
            "scienceDescription-station",
            "Impulse engine components"
        ),
        goods = { { "impulse", 5, 100 } },
        human_failure_trade = { "medicine" },
        default_trade = { "medicine" },
        trade = { "luxury" },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We research and manufacture impulse engine components and systems"
        ),
        history = _(
            "stationStory-comms",
            "The station is named after Roger Shawyer who built the first prototype impulse engine in the early 21st century"
        ),
    })
    records.Shree = standardAlliesRecord({
        description = _(
            "scienceDescription-station",
            "Repulsor and tractor beam components"
        ),
        goods = { { "tractor", 5, 90 }, { "repulsor", 5, 95 } },
        human_failure_trade = { "medicine" },
        default_trade = { "medicine", "food" },
        trade = { "luxury" },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We make ship systems designed to push or pull other objects around in space"
        ),
        history = _(
            "stationStory-comms",
            "Our station is named Shree after one of many tugboat manufacturers in the early 21st century on Earth in India. Tugboats serve a similar purpose for ocean-going vessels on earth as tractor and repulsor beams serve for space-going vessels today"
        ),
    })
    records.Soong = standardAlliesRecord({
        description = _("scienceDescription-station", "Android components"),
        goods = { { "android", 5, 73 } },
        default_trade = { "food" },
        trade = { "luxury" },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We create androids and android components"
        ),
        history = _(
            "stationStory-comms",
            "The station is named after Dr. Noonian Soong, the famous android researcher and builder"
        ),
    })
    records.Tiberius = fixedAlliesRecord({
        description = _("scienceDescription-station", "Logistics coordination"),
        goods = { { "food", 5, 1 } },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We support the stations and ships in the area with planning and communication services"
        ),
        history = _(
            "stationStory-comms",
            "We recognize the influence of Starfleet Captain James Tiberius Kirk in the 23rd century in our station name"
        ),
    })
    records.Tokra = alliesRecord({
        description = _(
            "scienceDescription-station",
            "Advanced material components"
        ),
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We create multiple types of advanced material components. Our most popular products are our filaments"
        ),
        history = _(
            "stationStory-comms",
            "We learned several of our critical industrial processes from the Tokra race, so we honor our fortune by naming the station after them"
        ),
    }, {
        {
            roll = { min = 1, max = 100 },
            rules = {
                {
                    faction = "human",
                    chance = { min = 1, max = 5, limit = 1, operator = "<=" },
                    goods = joinGoods(
                        { { "food", { 5, 10 }, 1 } },
                        { { "medicine", 5, 5 } },
                        { { "filament", 5, 42 } }
                    ),
                    rules = { { trade = "luxury" } },
                    otherwise = {
                        {
                            goods = joinGoods(
                                { { "food", { 5, 10 }, 1 } },
                                { { "filament", 5, 42 } }
                            ),
                        },
                        { when_lt = 50, rules = { { trade = "medicine" } } },
                        { when_gte = 50, rules = { { trade = "luxury" } } },
                    },
                },
                { faction = "other", goods = { { "filament", 5, 42 } } },
                {
                    faction = "other",
                    when_lt = 33,
                    rules = { { trade = "food" } },
                },
                {
                    faction = "other",
                    when_gt = 66,
                    rules = { { trade = "medicine" } },
                },
                {
                    faction = "other",
                    when_gte = 33,
                    when_lte = 66,
                    rules = { { trade = "luxury" } },
                },
            },
        },
    })
    records.Toohie = standardAlliesRecord({
        description = _(
            "scienceDescription-station",
            "Shield and armor components and research"
        ),
        goods = { { "shield", 5, 90 } },
        human_failure_trade = { { trade = "medicine", chance = 25 } },
        default_trade = { { trade = "medicine", chance = 25 } },
        trade = { "luxury" },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We research and make general and specialized components for ship shield and ship armor systems"
        ),
        history = _(
            "stationStory-comms",
            "This station was named after one of the earliest researchers in shield technology, Alexander Toohie back when it was considered impractical to construct shields due to the physics involved."
        ),
    })
    records["Utopia Planitia"] = standardAlliesRecord({
        description = _(
            "scienceDescription-station",
            "Ship building and maintenance facility"
        ),
        goods = { { "warp", 5, 167 } },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We work on all aspects of naval ship building and maintenance. Many of the naval models are researched, designed and built right here on this station. Our design goals seek to make the space faring experience as simple as possible given the tremendous capabilities of the modern naval vessel"
        ),
    })
    records.Vactel = standardAlliesRecord({
        description = _(
            "scienceDescription-station",
            "Shielded Circuitry Fabrication"
        ),
        goods = { { "circuit", 5, 50 } },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We specialize in circuitry shielded from external hacking suitable for ship systems"
        ),
        history = _(
            "stationStory-comms",
            "We started as an expansion from the lunar based chip manufacturer of Earth legacy Intel electronic chips"
        ),
    })
    records.Veloquan = standardAlliesRecord({
        description = _("scienceDescription-station", "Sensor components"),
        goods = { { "sensor", 5, 68 } },
        human_failure_trade = { "medicine" },
        default_trade = { "medicine", "food" },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We research and construct components for the most powerful and accurate sensors used aboard ships along with the software to make them easy to use"
        ),
        history = _(
            "stationStory-comms",
            "The Veloquan company has its roots in the manufacturing of LIDAR sensors in the early 21st century on Earth in the United States for autonomous ground-based vehicles. They expanded research and manufacturing operations to include various sensors for space vehicles. Veloquan was the result of numerous mergers and acquisitions of several companies including Velodyne and Quanergy"
        ),
    })
    records.Zefram = standardAlliesRecord({
        description = _("scienceDescription-station", "Warp engine components"),
        goods = { { "warp", 5, 140 } },
        human_failure_trade = { { trade = "medicine", chance = 27 } },
        default_trade = {
            { trade = "medicine", chance = 27 },
            { trade = "food", chance = 16 },
        },
        trade = { "luxury" },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We specialize in the esoteric components necessary to make warp drives function properly"
        ),
        history = _(
            "stationStory-comms",
            "Zefram Cochrane constructed the first warp drive in human history. We named our station after him because of the specialized warp systems work we do"
        ),
    })

    records.Jabba = choiceAlliesRecord({
        description = _("scienceDescription-station", "Commerce and gambling"),
        choices = {
            { { "luxury", 5, { 68, 81 } } },
            { { "gold", 5, { 61, 77 } } },
            { { "platinum", 5, { 65, 79 } } },
        },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "Come play some games and shop. House take does not exceed 4 percent"
        ),
    })
    records.Krik = alliesRecord(
        { description = _("scienceDescription-station", "Mining station") },
        {
            { trade = "food" },
            { trade = "luxury", chance = 50 },
            { trade = "medicine" },
            mineralGoodsRule(mineralChoices(true)),
        }
    )
    records.Lando = choiceAlliesRecord({
        description = _("scienceDescription-station", "Casino and Gambling"),
        choices = {
            { { "luxury", 5, { 68, 81 } } },
            { { "gold", 5, { 61, 77 } } },
            { { "platinum", 5, { 65, 79 } } },
        },
    })
    records.Maverick = choiceAlliesRecord({
        description = _("scienceDescription-station", "Gambling and resupply"),
        choices = {
            { { "luxury", 5, { 68, 81 } } },
            { { "gold", 5, { 61, 77 } } },
            { { "tritanium", 5, { 65, 79 } } },
        },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "Relax and meet some interesting players"
        ),
    })
    records.Nefatha = fixedAlliesRecord({
        description = _(
            "scienceDescription-station",
            "Commerce and recreation"
        ),
        goods = { { "luxury", 5, 70 } },
    })
    records.Okun = choiceAlliesRecord({
        description = _(
            "scienceDescription-station",
            "Xenopsychology research"
        ),
        choices = {
            { { "optic", 5, { 52, 65 } } },
            { { "filament", 5, { 55, 67 } } },
            { { "lifter", 5, { 48, 69 } } },
        },
    })
    records["Outpost-7"] = fixedAlliesRecord({
        description = _("scienceDescription-station", "Resupply"),
        goods = { { "luxury", 5, 80 } },
    })
    records["Outpost-8"] = choiceAlliesRecord({
        choices = {
            { { "impulse", 5, { 69, 75 } } },
            { { "tractor", 5, { 55, 67 } } },
            { { "beam", 5, { 61, 69 } } },
        },
    })
    records["Outpost-33"] = fixedAlliesRecord({
        description = _("scienceDescription-station", "Resupply"),
        goods = { { "luxury", 5, 75 } },
    })
    records.Prada = choiceAlliesRecord({
        description = _("scienceDescription-station", "Textiles and fashion"),
        choices = {
            { { "luxury", 5, { 69, 75 } } },
            { { "cobalt", 5, { 55, 67 } } },
            { { "dilithium", 5, { 61, 69 } } },
        },
    })
    records["Research-11"] = choiceAlliesRecord({
        description = _(
            "scienceDescription-station",
            "Stress Psychology Research"
        ),
        choices = {
            { { "warp", 5, { 85, 120 } } },
            { { "repulsor", 5, { 62, 75 } } },
            { { "robotic", 5, { 75, 89 } } },
        },
    })
    records["Research-19"] = choiceAlliesRecord({
        description = _("scienceDescription-station", "Low gravity research"),
        choices = {
            { { "transporter", 5, { 85, 94 } } },
            { { "sensor", 5, { 62, 75 } } },
            { { "communication", 5, { 55, 89 } } },
        },
    })
    records.Rubis = fixedAlliesRecord({
        description = _("scienceDescription-station", "Resupply"),
        goods = { { "luxury", 5, 76 } },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "Get your energy here! Grab a drink before you go!"
        ),
    })
    records["Science-2"] = choiceAlliesRecord({
        description = _(
            "scienceDescription-station",
            "Research Lab and Observatory"
        ),
        choices = {
            { { "autodoc", 5, { 85, 94 } } },
            { { "android", 5, { 62, 75 } } },
            { { "nanites", 5, { 55, 89 } } },
        },
    })
    records["Science-4"] = choiceAlliesRecord({
        description = _("scienceDescription-station", "Biotech research"),
        choices = {
            { { "software", 5, { 85, 94 } } },
            { { "circuit", 5, { 62, 75 } } },
            { { "battery", 5, { 55, 89 } } },
        },
    })
    records.Skandar = fixedAlliesRecord({
        description = _(
            "scienceDescription-station",
            "Routine maintenance and entertainment"
        ),
        goods = { { "luxury", 5, 87 } },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "Stop by for repairs. Take in one of our juggling shows featuring the four-armed Skandars"
        ),
        history = _(
            "stationStory-comms",
            "The nomadic Skandars have set up at this station to practice their entertainment and maintenance skills as well as build a community where Skandars can relax"
        ),
    })
    records.Spot = choiceAlliesRecord({
        description = _("scienceDescription-station", "Observatory"),
        choices = {
            { { "optic", 5, { 85, 94 } } },
            { { "software", 5, { 62, 75 } } },
            { { "sensor", 5, { 55, 89 } } },
        },
    })
    records.Starnet = choiceAlliesRecord({
        description = _(
            "scienceDescription-station",
            "Automated weapons systems"
        ),
        choices = {
            { { "shield", 5, { 85, 94 } } },
            { { "beam", 5, { 62, 75 } } },
            { { "lifter", 5, { 55, 89 } } },
        },
        public_relations = true,
        general_information = _(
            "stationGeneralInfo-comms",
            "We research and create automated weapons systems to improve ship combat capability"
        ),
    })
    records.Tandon = choiceAlliesRecord({
        description = _("scienceDescription-station", "Biotechnology research"),
        choices = {
            { { "autodoc", 5, { 85, 94 } } },
            { { "robotic", 5, { 62, 75 } } },
            { { "android", 5, { 55, 89 } } },
        },
    })
    records.Vaiken = fixedAlliesRecord({
        description = _(
            "scienceDescription-station",
            "Ship building and maintenance facility"
        ),
        goods = { { "food", 10, 1 }, { "medicine", 5, 5 } },
    })
    records.Valero = fixedAlliesRecord({
        description = _("scienceDescription-station", "Resupply"),
        goods = { { "luxury", 5, 77 } },
    })

    for _, name in ipairs({
        "Aramanth",
        "Empok Nor",
        "Ganalda",
        "Hassenstadt",
        "Kaldor",
        "Magenta Mesra",
        "Mos Eisley",
        "Questa Verde",
        "R'lyeh",
        "Stahlstadt",
        "Ticonderoga",
    }) do
        records[name] = alliesRecord({ comms = false }, {})
    end
    records["Scarlet Citadel"] = alliesRecord({}, {})

    return records
end

M.alliesGroups = {
    friendly = {
        "Alcaleica",
        "Anderson",
        "Archer",
        "Archimedes",
        "Armstrong",
        "Asimov",
        "Barclay",
        "Bethesda",
        "Broeck",
        "California",
        "Calvin",
        "Cavor",
        "Chatuchak",
        "Coulomb",
        "Cyrus",
        "Deckard",
        "Deer",
        "Erickson",
        "Evondos",
        "Feynman",
        "Grasberg",
        "Hayden",
        "Heyes",
        "Hossam",
        "Impala",
        "Komov",
        "Krak",
        "Kruk",
        "Lipkin",
        "Madison",
        "Maiman",
        "Marconi",
        "Mayo",
        "Miller",
        "Muddville",
        "Nexus-6",
        "O'Brien",
        "Olympus",
        "Organa",
        "Outpost-15",
        "Outpost-21",
        "Owen",
        "Panduit",
        "Ripley",
        "Rutherford",
        "Science-7",
        "Shawyer",
        "Shree",
        "Soong",
        "Tiberius",
        "Tokra",
        "Toohie",
        "Utopia Planitia",
        "Vactel",
        "Veloquan",
        "Zefram",
    },
    generic = {
        "Jabba",
        "Krik",
        "Lando",
        "Maverick",
        "Nefatha",
        "Okun",
        "Outpost-7",
        "Outpost-8",
        "Outpost-33",
        "Prada",
        "Research-11",
        "Research-19",
        "Rubis",
        "Science-2",
        "Science-4",
        "Skandar",
        "Spot",
        "Starnet",
        "Tandon",
        "Vaiken",
        "Valero",
    },
    enemy = {
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
    },
}

local standard_arcs = {
    positive_distance = { 10000, 60000 },
    negative_distance = { 10000, 60000 },
    spread = { 4000, 7000 },
    positive_arc = { 30, 70 },
    negative_arc = { 40, 80 },
}
local krik_arcs = {
    positive_distance = { 30000, 80000 },
    negative_distance = { 20000, 60000 },
    spread = { 5000, 8000 },
    positive_arc = { 40, 90 },
    negative_arc = { 30, 60 },
}

local allies_asteroids = {
    type = "asteroids_around",
    amount = 15,
    distance_min = 1,
    distance_max = 15000,
}
M.alliesHooks = {
    ["Grasberg"] = {
        stage = "before_template",
        type = allies_asteroids.type,
        amount = allies_asteroids.amount,
        distance_min = allies_asteroids.distance_min,
        distance_max = allies_asteroids.distance_max,
    },
    ["Impala"] = {
        stage = "before_template",
        type = allies_asteroids.type,
        amount = allies_asteroids.amount,
        distance_min = allies_asteroids.distance_min,
        distance_max = allies_asteroids.distance_max,
    },
    ["Outpost-15"] = {
        stage = "after_inventory",
        type = allies_asteroids.type,
        amount = allies_asteroids.amount,
        distance_min = allies_asteroids.distance_min,
        distance_max = allies_asteroids.distance_max,
    },
    ["Outpost-21"] = {
        stage = "before_inventory",
        type = allies_asteroids.type,
        amount = allies_asteroids.amount,
        distance_min = allies_asteroids.distance_min,
        distance_max = allies_asteroids.distance_max,
    },
    ["Krak"] = {
        stage = "before_inventory",
        type = "asteroid_arcs",
        arcs = standard_arcs,
        negative_arc_after_first = true,
    },
    ["Kruk"] = {
        stage = "before_inventory",
        type = "asteroid_arcs",
        arcs = standard_arcs,
        negative_arc_after_first = true,
    },
    ["Krik"] = {
        stage = "before_inventory",
        type = "asteroid_arcs",
        arcs = krik_arcs,
        negative_arc_after_first = true,
    },
}

function M.alliesConfig()
    return {
        records = buildAlliesRecords,
        groups = M.alliesGroups,
        hooks = M.alliesHooks,
    }
end

return M
