--- Basic station comms.
--
-- Station comms that allow for buying ordnance and requesting supply drops or reinforcements.
-- Default script for any SpaceStation entity.
--
-- @script comms_station

-- uses `mergeTables`
require("utils.lua")

-- NOTE this could be imported
local MISSILE_TYPES = {
    "Homing",
    "Nuke",
    "Mine",
    "EMP",
    "HVLI"
}

--- Main menu of communication.
--
-- - Prepares `comms_data`.
-- - If the station is not an enemy and no enemies are nearby, the dialog is
--   provided by `commsStationUndocked` or `commsStationDocked`.
--   (Back buttons go to the main menu in order to check for enemies again.)
--
-- @tparam PlayerSpaceship comms_source
-- @tparam SpaceStation comms_target
function commsStationMainMenu(comms_source, comms_target)
    if comms_target.comms_data == nil then
        comms_target.comms_data = {}
    end
    mergeTables(
        comms_target.comms_data,
        {
            friendlyness = random(0.0, 100.0),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend"
            },
            weapon_cost = {
                Homing = 2,
                HVLI = 2,
                Mine = 2,
                Nuke = 15,
                EMP = 10
            },
            services = {
                supplydrop = "friend",
                reinforcements = "friend"
            },
            service_cost = {
                supplydrop = 100,
                reinforcements = {
                    hornet = 100,
                    amk3 = 100,
                    amk5 = 150,
                    amk8 = 200,
                    phobos = 300
                }
            },
            reinforcement_templates = {
                hornet = "MU52 Hornet",
                amk3 = "Adder MK3",
                amk5 = "Adder MK5",
                amk8 = "Adder MK8",
                phobos = "Phobos T3",
            },
            reputation_cost_multipliers = {
                friend = 1.0,
                neutral = 2.5
            },
            max_weapon_refill_amount = {
                friend = 1.0,
                neutral = 0.5
            }
        }
    )

    -- Hostile stations don't provide services.
    if comms_source:isEnemy(comms_target) then
        return false
    end

    -- Disrupt comms if hostile entities are in default short-range radar range.
    -- This triggers even when moving between comms replies in relaxed comms.
    if comms_target:areEnemiesInRange(5000) then
        setCommsMessage(_("station-comms", "We are under attack! No time for chatting!"))
        return true
    end

    if not comms_source:isDocked(comms_target) then
        commsStationUndocked(comms_source, comms_target)
    else
        commsStationDocked(comms_source, comms_target)
    end
    return true
end

--- Handle communications while docked with this station.
--
-- @tparam PlayerSpaceship comms_source
-- @tparam SpaceStation comms_target
function commsStationDocked(comms_source, comms_target)
    local message

    -- Greetings
    if comms_source:isFriendly(comms_target) then
        message = string.format(_("station-comms", "Good day, officer! Welcome to %s.\nWhat can we do for you today?"), comms_target:getCallSign())
    else
        message = string.format(_("station-comms", "Welcome to our lovely station %s."), comms_target:getCallSign())
    end
    setCommsMessage(message)

    -- Reply options
    local reply_messages = {
        ["Homing"] = _("ammo-comms", "Do you have spare homing missiles for us?"),
        ["HVLI"] = _("ammo-comms", "Can you restock us with HVLI?"),
        ["Mine"] = _("ammo-comms", "Please re-stock our mines."),
        ["Nuke"] = _("ammo-comms", "Can you supply us with some nukes?"),
        ["EMP"] = _("ammo-comms", "Please re-stock our EMP missiles.")
    }

    -- Actions
    for idx, missile_type in ipairs(MISSILE_TYPES) do
        if comms_source:getWeaponStorageMax(missile_type) > 0 then
            addCommsReply(
                string.format(_("ammo-comms", "%s (%d rep each)"), reply_messages[missile_type], getWeaponCost(comms_source, comms_target, missile_type)),
                function(comms_source, comms_target)
                    handleWeaponRestock(comms_source, comms_target, missile_type)
                end
            )
        end
    end
end

--- Handle weapon restocking requests.
--
-- @tparam PlayerSpaceship comms_source
-- @tparam SpaceStation comms_target
-- @tparam string weapon the missile type
function handleWeaponRestock(comms_source, comms_target, weapon)
    if not comms_source:isDocked(comms_target) then
        setCommsMessage(_("station-comms", "You need to stay docked for that action."))
        return
    end

    -- Denials
    if not isAllowedTo(comms_source, comms_target, comms_target.comms_data.weapons[weapon]) then
        local message
        if weapon == "Nuke" then
            message = _("ammo-comms", "We do not deal in weapons of mass destruction.")
        elseif weapon == "EMP" then
            message = _("ammo-comms", "We do not deal in weapons of mass disruption.")
        else
            message = _("ammo-comms", "We do not deal in those weapons.")
        end
        setCommsMessage(message)
        return
    end

    -- Transactions
    local points_per_item = getWeaponCost(comms_source, comms_target, weapon)
    local item_amount = math.floor(comms_source:getWeaponStorageMax(weapon) * comms_target.comms_data.max_weapon_refill_amount[getFriendStatus(comms_source, comms_target)]) - comms_source:getWeaponStorage(weapon)
    if item_amount <= 0 then
        local message
        if weapon == "Nuke" then
            message = _("ammo-comms", "All nukes are charged and primed for destruction.")
        else
            message = _("ammo-comms", "Sorry, sir, but you are as fully stocked as I can allow.")
        end
        setCommsMessage(message)
        addCommsReply(_("Back"), commsStationMainMenu)
    else
        if not comms_source:takeReputationPoints(points_per_item * item_amount) then
            setCommsMessage(_("needRep-comms", "Not enough reputation."))
            return
        end
        comms_source:setWeaponStorage(weapon, comms_source:getWeaponStorage(weapon) + item_amount)
        local message
        if comms_source:getWeaponStorage(weapon) == comms_source:getWeaponStorageMax(weapon) then
            message = _("ammo-comms", "You are fully loaded and ready to explode things.")
        else
            message = _("ammo-comms", "We generously resupplied you with some weapon charges.\nPut them to good use.")
        end
        setCommsMessage(message)
        addCommsReply(_("Back"), commsStationMainMenu)
    end
end

--- Handle requests for reinforcements and supply ships.
--
-- @tparam PlayerSpaceship comms_source
-- @tparam SpaceStation comms_target
function handleShipRequests(comms_source, comms_target)
    -- Supply drop
    if isAllowedTo(comms_source, comms_target, comms_target.comms_data.services.supplydrop) then
        addCommsReply(
            string.format(_("stationAssist-comms", "Can you send a supply drop? (%d rep)"), getServiceCost(comms_source, comms_target, "supplydrop")),
            --
            commsStationSupplyDrop
        )
    end

    -- Reinforcements
    if isAllowedTo(comms_source, comms_target, comms_target.comms_data.services.reinforcements) then
        addCommsReply(
            string.format(_("stationAssist-comms", "Please send reinforcements! (%d+ rep)"), getReinforcementsCost(comms_source, comms_target, "reinforcements")),
            --
            commsStationReinforcements
        )
    end
end

--- Handle communications when we are not docked with the station.
--
-- @tparam PlayerSpaceship comms_source
-- @tparam SpaceStation comms_target
function commsStationUndocked(comms_source, comms_target)
    local message
    if comms_source:isFriendly(comms_target) then
        message = string.format(_("station-comms", "This is %s. Good day, officer.\nIf you need supplies, please dock with us first."), comms_target:getCallSign())
    else
        message = string.format(_("station-comms", "This is %s. Greetings.\nIf you want to do business, please dock with us first."), comms_target:getCallSign())
    end
    setCommsMessage(message)

    handleShipRequests(comms_source, comms_target)
end

--- Ask for a waypoint and deliver a supply drop to it.
--
-- Uses the script `supply_drop.lua`
--
-- @tparam PlayerSpaceship comms_source
-- @tparam SpaceStation comms_target
function commsStationSupplyDrop(comms_source, comms_target)
    if comms_source:getWaypointCount() < 1 then
        setCommsMessage(_("stationAssist-comms", "You need to set a waypoint before you can request supplies."))
    else
        setCommsMessage(_("stationAssist-comms", "To which waypoint should we deliver your supplies?"))
        for n = 1, comms_source:getWaypointCount() do
            addCommsReply(
                formatWaypoint(n),
                function(comms_source, comms_target)
                    local message
                    if comms_source:takeReputationPoints(getServiceCost(comms_source, comms_target, "supplydrop")) then
                        local position_x, position_y = comms_target:getPosition()
                        local target_x, target_y = comms_source:getWaypoint(n)
                        local script = Script()
                        script:setVariable("position_x", position_x):setVariable("position_y", position_y)
                        script:setVariable("target_x", target_x):setVariable("target_y", target_y)
                        script:setVariable("faction", comms_target:getFaction()):run("supply_drop.lua")
                        message = string.format(_("stationAssist-comms", "We have dispatched a supply ship toward %s."), formatWaypoint(n))
                    else
                        message = _("needRep-comms", "Not enough reputation!")
                    end
                    setCommsMessage(message)
                    addCommsReply(_("Back"), commsStationMainMenu)
                end
            )
        end
    end
    addCommsReply(_("Back"), commsStationMainMenu)
end

--- Offer reinforcement options to the player.
--
-- @tparam PlayerSpaceship comms_source
-- @tparam SpaceStation comms_target
function commsStationReinforcements(comms_source, comms_target)
	setCommsMessage(_("stationAssist-comms", "What kind of reinforcement ship would you like?"))
    -- List reinforcement options using localized ship template names
    local sorted_reinforcements = {}
    for key, value in pairs(comms_target.comms_data.reinforcement_templates) do
        sorted_reinforcements[#sorted_reinforcements + 1] = {
            key = key,
            template = value,
            cost = comms_target.comms_data.service_cost.reinforcements[key]
        }
    end

    -- Sort options by ascending reputation cost
    table.sort(sorted_reinforcements,
        function(a, b)
            return a.cost < b.cost
        end
    )

    -- Present options
    for i, value in ipairs(sorted_reinforcements) do
        addCommsReply(
            string.format(_("stationAssist-comms", "%s (%d rep)"), __ship_templates[comms_target.comms_data.reinforcement_templates[value.key]].typename.localized, getReinforcementsCost(comms_source, comms_target, value.key)),
            function(comms_source, comms_target)
                commsStationSpecificReinforcement(comms_source, comms_target, value.key)
            end
        )
    end
    addCommsReply(_("Back"), commsStationMainMenu)
end

--- Validate that a waypoint exists and order reinforcements to defend a target waypoint.
--
-- @tparam PlayerSpaceship comms_source
-- @tparam SpaceStation comms_target
-- @tparam string reinforcement_type
function commsStationSpecificReinforcement(comms_source, comms_target, reinforcement_type)
    if comms_source:getWaypointCount() < 1 then
        setCommsMessage(_("stationAssist-comms", "You need to set a waypoint before you can request reinforcements."))
    else
        setCommsMessage(_("stationAssist-comms", "To which waypoint should we dispatch the reinforcements?"))
        for n = 1, comms_source:getWaypointCount() do
            addCommsReply(
                formatWaypoint(n),
                function(comms_source, comms_target)
                    local message
                    if comms_source:takeReputationPoints(getReinforcementsCost(comms_source, comms_target, reinforcement_type)) then
                        local ship = CpuShip():setFactionId(comms_target:getFactionId()):setPosition(comms_target:getPosition()):setTemplate(comms_target.comms_data.reinforcement_templates[reinforcement_type]):setScanned(true):orderDefendLocation(comms_source:getWaypoint(n))
                        message = string.format(_("stationAssist-comms", "We have dispatched %s %s to assist at %s."), __ship_templates[comms_target.comms_data.reinforcement_templates[reinforcement_type]].typename.localized, ship:getCallSign(), formatWaypoint(n))
                    else
                        message = _("needRep-comms", "Not enough reputation!")
                    end
                    setCommsMessage(message)
                    addCommsReply(_("Back"), commsStationMainMenu)
                end
            )
        end
    end
    addCommsReply(_("Back"), commsStationMainMenu)
end

--- Returns true if the player ship is allowed to do something.
--- For now this returns true if the player ship matches either valid passed
--- `state` of "friend" or "neutral", and false otherwise.
--
-- @tparam PlayerSpaceship comms_source
-- @tparam SpaceStation comms_target
-- @tparam string state
-- @treturn boolean true if allowed
function isAllowedTo(comms_source, comms_target, state)
    -- TODO reconsider the logic of these conditions
    if state == "friend" and comms_source:isFriendly(comms_target) then
        return true
    end
    if state == "neutral" and not comms_source:isEnemy(comms_target) then
        return true
    end
    return false
end

--- Return the number of reputation points that a specified weapon costs for the
-- current player.
--
-- @tparam PlayerSpaceship comms_source
-- @tparam SpaceStation comms_target
-- @tparam string weapon the missile type
-- @treturn integer the cost
function getWeaponCost(comms_source, comms_target, weapon)
    local relation = getFriendStatus(comms_source, comms_target)
    return math.ceil(comms_target.comms_data.weapon_cost[weapon] * comms_target.comms_data.reputation_cost_multipliers[relation])
end

--- Return the number of reputation points that a specified service costs for
-- the current player.
--
-- @tparam PlayerSpaceship comms_source
-- @tparam SpaceStation comms_target
-- @tparam string service the service
-- @treturn integer the cost
function getServiceCost(comms_source, comms_target, service)
    return math.ceil(comms_target.comms_data.service_cost[service])
end

--- Return the number of reputation points that a specified reinforcement type
-- costs for the current player.
--
-- @tparam PlayerSpaceship comms_source
-- @tparam SpaceStation comms_target
-- @tparam string service the reinforcement type
-- @treturn integer the cost
function getReinforcementsCost(comms_source, comms_target, service)
    -- If generically requesting reinforcements, return the lowest-value type.
    if service == "reinforcements" then
        local smallest = math.huge
        for _, value in pairs(comms_target.comms_data.service_cost.reinforcements) do
            if value < smallest and value > 0 then smallest = value end
        end
        return math.ceil(smallest)
    end
    return math.ceil(comms_target.comms_data.service_cost.reinforcements[service])
end

--- Return "friend" or "neutral".
--
-- @tparam PlayerSpaceship comms_source
-- @tparam SpaceStation comms_target
-- @treturn string the status
function getFriendStatus(comms_source, comms_target)
    if comms_source:isFriendly(comms_target) then
        return "friend"
    else
        return "neutral"
    end
end

--- Format integer i as "WP i".
--
-- @tparam integer i the index of the waypoint
-- @treturn string "WP i"
function formatWaypoint(i)
    return string.format(_("stationAssist-comms", "WP %d"), i)
end

-- `comms_source` and `comms_target` are global in comms script.
commsStationMainMenu(comms_source, comms_target)
