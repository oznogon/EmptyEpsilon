-- Ship order and fleet/squad communication flows used in comms_ship_support.

local M = {}

local function prompt(context, text)
    return { context = context, text = text }
end

local default_labels = {
    assist = prompt("shipAssist-comms", "Assist me"),
    defend = prompt("shipAssist-comms", "Defend a waypoint"),
    fly = prompt("shipAssist-comms", "Go to waypoint. Attack enemies en route"),
    fly_blind = prompt("shipAssist-comms", "Go to waypoint, ignore enemies"),
    roam = prompt(
        "shipAssist-comms",
        "Attack all enemies. Start with the nearest."
    ),
    stand = prompt("shipAssist-comms", "Stop and defend your current location"),
    idle = prompt("shipAssist-comms", "Stop. Do nothing."),
    formation = prompt(
        "shipAssist-comms",
        "Other drones in squad form up on me"
    ),
}

local default_prompts = {
    defend = prompt("shipAssist-comms", "Which waypoint should we defend?"),
    fly = prompt("shipAssist-comms", "Which waypoint?"),
    fly_blind = prompt(
        "shipAssist-comms",
        "Which waypoint should we approach?"
    ),
}

local default_messages = {
    assist = prompt("shipAssist-comms", "Heading toward you to assist."),
    defend = prompt("shipAssist-comms", "We are heading to assist at WP %d."),
    fly = prompt(
        "shipAssist-comms",
        "Going to WP%d, watching for enemies en route"
    ),
    fly_blind = prompt(
        "shipAssist-comms",
        "We are heading to WP%d ignoring enemies."
    ),
    roam = prompt("shipAssist-comms", "Searching and destroying"),
    stand = prompt(
        "shipAssist-comms",
        "Stopping. Shooting any enemy that approaches"
    ),
    idle = prompt("shipAssist-comms", "Stopping. Doing nothing."),
}

local function localize(value)
    return _(value.context, value.text)
end

local function configured(config, values, key)
    if config[key] ~= nil then
        return config[key]
    end
    return values and values[key]
end

local function label(config, key)
    local value = configured(config, config.labels, key)
    if value == nil then
        value = default_labels[key]
    end
    if type(value) == "function" then
        return value()
    elseif type(value) == "string" then
        return value
    end
    return localize(value)
end

local function message(config, key, ...)
    local value = configured(config, config.messages, key)
    if value == nil then
        value = default_messages[key]
    end
    if type(value) == "function" then
        return value(...)
    elseif type(value) == "table" then
        value = localize(value)
    end
    return string.format(value, ...)
end

local function addBack(config)
    addCommsReply(_("Back"), config.main_menu)
end

local function source(config)
    return config.source()
end

local function members(config)
    local result = {}
    local values = config.members()
    if config.iterate == "pairs" then
        for _index, ship in pairs(values or {}) do
            if ship ~= nil and ship:isValid() then
                table.insert(result, ship)
            end
        end
    else
        for _index, ship in ipairs(values or {}) do
            if ship ~= nil and ship:isValid() then
                table.insert(result, ship)
            end
        end
    end
    return result
end

local function orderMethod(option)
    if option == "defend" then
        return "orderDefendLocation"
    elseif option == "fly" then
        return "orderFlyTowards"
    end
    return "orderFlyTowardsBlind"
end

local function waypointLabel(config, option, index, waypoint_id)
    local value = config.waypoint_labels and config.waypoint_labels[option]
    if value == nil then
        if option == "defend" then
            value = prompt("shipAssist-comms", "Defend WP %d")
        else
            value = prompt("shipAssist-comms", "Go to WP%d")
        end
    end
    if type(value) == "function" then
        return value(index, waypoint_id)
    elseif type(value) == "table" then
        value = localize(value)
    end
    return string.format(value, waypoint_id)
end

local function addWaypointOrder(config, option)
    addCommsReply(label(config, option), function()
        local comms_source = source(config)
        if comms_source:getWaypointCount() == 0 then
            setCommsMessage(
                _(
                    "shipAssist-comms",
                    "No waypoints set. Please set a waypoint first."
                )
            )
            addBack(config)
            return
        end
        local waypoint_prompt = configured(config, config.prompts, option)
        if waypoint_prompt == nil then
            waypoint_prompt = default_prompts[option]
        end
        setCommsMessage(localize(waypoint_prompt))
        local method = orderMethod(option)
        for index = 1, comms_source:getWaypointCount() do
            local waypoint_id = comms_source:getWaypointID(index)
            addCommsReply(
                waypointLabel(config, option, index, waypoint_id),
                function()
                    local x, y = comms_source:getWaypoint(index)
                    for _index, ship in ipairs(members(config)) do
                        ship[method](ship, x, y)
                    end
                    setCommsMessage(message(config, option, waypoint_id))
                    addBack(config)
                end
            )
        end
    end)
end

local function addFormation(config)
    addCommsReply(label(config, "formation"), function()
        local comms_source = source(config)
        local squad = members(config)
        local lead = config.leader and config.leader() or comms_target
        local followers = {}
        for _index, ship in ipairs(squad) do
            if ship ~= lead then
                table.insert(followers, ship)
            end
        end
        lead:orderIdle()
        if #followers > 0 then
            local spacing = config.formation_spacing
            if type(spacing) == "function" then
                spacing = spacing()
            end
            for index, ship in ipairs(followers) do
                local x, y =
                    vectorFromAngle(360 / #followers * (index - 1), spacing)
                ship:orderFlyFormation(lead, x, y)
            end
        end
        setCommsMessage(message(config, "formation", config.name()))
        addBack(config)
    end)
end

function M.addOrder(config, option)
    if option == "defend" or option == "fly" or option == "fly_blind" then
        addWaypointOrder(config, option)
        return
    end
    if option == "formation" then
        addFormation(config)
        return
    end

    addCommsReply(label(config, option), function()
        local comms_source = source(config)
        local method = option
        if option == "roam" then
            method = "orderRoaming"
        elseif option == "stand" then
            method = "orderStandGround"
        elseif option == "idle" then
            method = "orderIdle"
        elseif option == "assist" then
            method = "orderDefendTarget"
        end
        for _index, ship in ipairs(members(config)) do
            if option == "assist" then
                ship[method](ship, comms_source)
            else
                ship[method](ship)
            end
        end
        if option == "idle" and config.idle_messages ~= nil then
            local values = config.idle_messages
            setCommsMessage(values[math.random(1, #values)])
        elseif option == "idle" and config.idle_activities ~= nil then
            local values = config.idle_activities
            setCommsMessage(
                string.format(
                    _("shipAssist-comms", "Stopping. Doing nothing except %s."),
                    values[math.random(1, #values)]
                )
            )
        else
            setCommsMessage(message(config, option, config.name()))
        end
        addBack(config)
    end)
end

local function addHullStatus(config)
    addCommsReply(
        _("shipAssist-comms", "Report hull and shield status"),
        function()
            local fleet_name = config.name()
            local text = string.format(
                _("shipAssist-comms", "Fleet %s status:"),
                fleet_name
            )
            for _index, ship in ipairs(members(config)) do
                text = string.format(
                    _("shipAssist-comms", "%s\n %s:"),
                    text,
                    ship:getCallSign()
                )
                text = string.format(
                    _("shipAssist-comms", "%s\n    Hull: %d%%"),
                    text,
                    math.floor(ship:getHull() / ship:getHullMax() * 100)
                )
                local shields = ship:getShieldCount()
                if shields == 1 then
                    text = string.format(
                        _("shipAssist-comms", "%s\n    Shield: %d%%"),
                        text,
                        math.floor(
                            ship:getShieldLevel(0) / ship:getShieldMax(0) * 100
                        )
                    )
                elseif shields == 2 then
                    text = string.format(
                        _("shipAssist-comms", "%s\n    Shields: "),
                        text
                    )
                    text = string.format(
                        _("shipAssist-comms", "%sFront: %d%% Rear: %d%%"),
                        text,
                        math.floor(
                            ship:getShieldLevel(0) / ship:getShieldMax(0) * 100
                        ),
                        math.floor(
                            ship:getShieldLevel(1) / ship:getShieldMax(1) * 100
                        )
                    )
                else
                    text = string.format(
                        _("shipAssist-comms", "%s\n    Shields: "),
                        text
                    )
                    for index = 0, shields - 1 do
                        text = string.format(
                            _("shipAssist-comms", "%s %d:%d%%"),
                            text,
                            index,
                            math.floor(
                                ship:getShieldLevel(index)
                                    / ship:getShieldMax(index)
                                    * 100
                            )
                        )
                    end
                end
            end
            setCommsMessage(text)
            addBack(config)
        end
    )
end

local function addMissileStatus(config)
    addCommsReply(_("shipAssist-comms", "Report missile status"), function()
        local fleet_name = config.name()
        local text = string.format(
            _("shipAssist-comms", "Fleet %s missile status:"),
            fleet_name
        )
        for _index, ship in ipairs(members(config)) do
            text = string.format(
                _("shipAssist-comms", "%s\n %s:"),
                text,
                ship:getCallSign()
            )
            local missile_text = ""
            for _index, missile_type in ipairs({
                "Homing",
                "Nuke",
                "Mine",
                "EMP",
                "HVLI",
            }) do
                if ship:getWeaponStorageMax(missile_type) > 0 then
                    missile_text = string.format(
                        _("shipAssist-comms", "%s\n      %s: %d/%d"),
                        missile_text,
                        missile_type,
                        math.floor(ship:getWeaponStorage(missile_type)),
                        math.floor(ship:getWeaponStorageMax(missile_type))
                    )
                end
            end
            if missile_text ~= "" then
                text = string.format(
                    _("shipAssist-comms", "%s\n    Missiles: %s"),
                    text,
                    missile_text
                )
            end
        end
        setCommsMessage(text)
        addBack(config)
    end)
end

function M.addMenu(config)
    if config.available ~= nil and not config.available() then
        return
    end
    addCommsReply(config.label(), function()
        setCommsMessage(config.message())
        if config.status then
            addHullStatus(config)
            addMissileStatus(config)
        end
        for _index, option in ipairs(config.commands or {}) do
            M.addOrder(config, option)
        end
    end)
end

return M
