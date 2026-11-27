-- Shared, profile-driven station communication menus.

local Cartography = require("comms_station_cartography.lua")
local StationCore = require("comms_station_core.lua")

local M = {}

local function commsSource(profile)
    return StationCore.getSource(profile)
end

local RESTOCK_ORDER = {
    "Nuke",
    "EMP",
    "Homing",
    "Mine",
    "HVLI",
}
local ORDNANCE_LABELS = {
    Nuke = _("ammo-comms", "\n   Nuke"),
    EMP = _("ammo-comms", "\n   EMP"),
    Homing = _("ammo-comms", "\n   Homing"),
    Mine = _("ammo-comms", "\n   Mine"),
    HVLI = _("ammo-comms", "\n   HVLI"),
}
local TRADE_LABELS = {
    food = _("trade-comms", "Trade food for %s"),
    medicine = _("trade-comms", "Trade medicine for %s"),
    luxury = _("trade-comms", "Trade luxury for %s"),
}
local REPAIR_SYSTEMS = {
    {
        key = "probe_launch_repair",
        cost = "probe_launch_repair",
        prompt = _(
            "stationServices-comms",
            "Repair probe launch system (%s Rep)"
        ),
        success = _(
            "stationServices-comms",
            "Your probe launch system has been repaired"
        ),
        available = "getCanLaunchProbe",
        repair = "setCanLaunchProbe",
    },
    {
        key = "hack_repair",
        cost = "hack_repair",
        prompt = _("stationServices-comms", "Repair hacking system (%s Rep)"),
        success = _(
            "stationServices-comms",
            "Your hack system has been repaired"
        ),
        available = "getCanHack",
        repair = "setCanHack",
    },
    {
        key = "scan_repair",
        cost = "scan_repair",
        prompt = _("stationServices-comms", "Repair scanning system (%s Rep)"),
        success = _(
            "stationServices-comms",
            "Your scanners have been repaired"
        ),
        available = "getCanScan",
        repair = "setCanScan",
    },
    {
        key = "combat_maneuver_repair",
        cost = "combat_maneuver_repair",
        prompt = _("stationServices-comms", "Repair combat maneuver (%s Rep)"),
        success = _(
            "stationServices-comms",
            "Your combat maneuver has been repaired"
        ),
        available = "getCanCombatManeuver",
        repair = "setCanCombatManeuver",
        requires_capability = true,
    },
    {
        key = "self_destruct_repair",
        cost = "self_destruct_repair",
        prompt = _(
            "stationServices-comms",
            "Repair self destruct system (%s Rep)"
        ),
        success = _(
            "stationServices-comms",
            "Your self destruct system has been repaired"
        ),
        available = "getCanSelfDestruct",
        repair = "setCanSelfDestruct",
    },
    {
        key = "tube_slow_down_repair",
        cost = "tube_slow_down_repair",
        prompt = _(
            "stationServices-comms",
            "Repair slow tube loading (%s Rep)"
        ),
        success = _(
            "stationServices-comms",
            "Your tube load times have been returned to normal"
        ),
        available = function(source)
            if source.normal_tube_load_time == nil then
                return false
            end
            for index = 0, source:getWeaponTubeCount() - 1 do
                if
                    source.normal_tube_load_time[index] ~= nil
                    and source:getTubeLoadTime(index)
                        ~= source.normal_tube_load_time[index]
                then
                    return true
                end
            end
            return false
        end,
        repair = function(source)
            for index = 0, source:getWeaponTubeCount() - 1 do
                if source.normal_tube_load_time[index] ~= nil then
                    source:setTubeLoadTime(
                        index,
                        source.normal_tube_load_time[index]
                    )
                end
            end
        end,
    },
}

local function mainMenu(profile)
    return profile.main_menu or commsStation
end

local function addBack(profile)
    addCommsReply(_("Back"), mainMenu(profile))
end

local function goodsName(profile, good)
    if profile.goods_name ~= nil then
        return profile.goods_name(good)
    end
    return good
end

local function goodsQuantity(value)
    if type(value) == "table" then
        return value.quantity or 0
    end
    return value or 0
end

local function hasGood(profile, name)
    local source = commsSource(profile)
    return source.goods ~= nil and goodsQuantity(source.goods[name]) > 0
end

local function ensureDocked(profile)
    if
        profile.require_docked
        and not commsSource(profile):isDocked(comms_target)
    then
        setCommsMessage(
            _("station-comms", "You need to stay docked for that action.")
        )
        return false
    end
    return true
end

local function serviceAllowed(profile, service)
    local services = comms_target.comms_data.services or {}
    return services[service] ~= nil
        and StationCore.isAllowedTo(services[service], profile)
end

local function waypointID(profile, index)
    if profile.undocked.waypoint_id ~= nil then
        return profile.undocked.waypoint_id(index)
    end
    return commsSource(profile):getWaypointID(index)
end

local function restockHandler(profile)
    local handler
    if profile.docked.restock == "simple" then
        handler = StationCore.handleWeaponRestockSimple
    elseif profile.docked.restock == "alternate" then
        handler = StationCore.handleWeaponRestockAlternate
    else
        handler = StationCore.handleWeaponRestock
    end
    return function(weapon)
        handler(weapon, profile)
    end
end

local function sectionEnabled(profile, section)
    if
        section.friendly and not commsSource(profile):isFriendly(comms_target)
    then
        return false
    end
    if section.available ~= nil and not section.available() then
        return false
    end
    return true
end

function M.entrypoint(profile_getter)
    return function(source, target)
        if source ~= nil then
            comms_source = source
        end
        if target ~= nil then
            comms_target = target
        end
        local profile = profile_getter()
        return StationCore.commsStation({
            source = profile.source,
            data = profile.data,
            prepare = profile.prepare,
            preserve_rng = profile.preserve_rng,
            weapon_availability = profile.weapon_availability,
            under_attack = profile.under_attack,
            docked = function()
                M.docked(profile)
            end,
            undocked = function()
                M.undocked(profile)
            end,
        }, source, target)
    end
end

function M.greeting(profile)
    local message
    if type(profile.docked.greeting) == "function" then
        message = profile.docked.greeting()
    elseif commsSource(profile):isFriendly(comms_target) then
        if profile.docked.greeting == "fixed" then
            message = _(
                "station-comms",
                "Good day, officer!\nWhat can we do for you today?"
            )
        elseif comms_target.comms_data.friendlyness > 66 then
            message = string.format(
                _("station-comms", "Greetings %s!\nHow may we help you today?"),
                commsSource(profile):getCallSign()
            )
        elseif comms_target.comms_data.friendlyness > 33 then
            message = _(
                "station-comms",
                "Good day, officer!\nWhat can we do for you today?"
            )
        else
            message = _("station-comms", "Hello, may I help you?")
        end
    else
        message = _("station-comms", "Welcome to our lovely station.")
    end
    if comms_target:areEnemiesInRange(20000) then
        message = message
            .. _(
                "station-comms",
                "\nForgive us if we seem a little distracted. We are carefully monitoring the enemies nearby."
            )
    end
    if profile.docked.show_reputation then
        message = string.format(
            _("station-comms", "%s\n\nReputation: %i"),
            message,
            math.floor(commsSource(profile):getReputationPoints())
        )
    end
    setCommsMessage(message)
end

function M.undockedGreeting(profile)
    local message
    if profile.undocked.greeting ~= nil then
        if type(profile.undocked.greeting) == "function" then
            message = profile.undocked.greeting()
        else
            message = profile.undocked.greeting
        end
        setCommsMessage(message)
        return
    end
    if commsSource(profile):isFriendly(comms_target) then
        message = _(
            "station-comms",
            "Good day, officer.\nIf you need supplies, please dock with us first."
        )
    else
        message = _(
            "station-comms",
            "Greetings.\nIf you want to do business, please dock with us first."
        )
    end
    if comms_target:areEnemiesInRange(20000) then
        message = message
            .. _(
                "station-comms",
                "\nBe aware that if enemies in the area get much closer, we will be too busy to conduct business with you."
            )
    end
    setCommsMessage(message)
end

function M.addOrdnanceRestock(profile)
    local options = profile.docked.ordnance or {}
    local group_label = type(options.label) == "string" and options.label
        or _("ammo-comms", "I need ordnance restocked")
    local available = comms_target.comms_data.weapon_available or {}
    local inventory = comms_target.comms_data.weapon_inventory
    local order = options.order or RESTOCK_ORDER
    local handle_restock = restockHandler(profile)
    local function inStock(missile_type)
        if inventory == nil or inventory.Unlimited then
            return true
        end
        return (inventory[missile_type] or 0) > 0
    end
    local offer_restock = false
    for missile_index, missile_type in ipairs(order) do
        if
            (options.ignore_availability or available[missile_type])
            and commsSource(profile):getWeaponStorageMax(missile_type) > 0
            and inStock(missile_type)
        then
            offer_restock = true
            break
        end
    end
    if not offer_restock then
        if options.always and options.group ~= false then
            addCommsReply(group_label, function()
                setCommsMessage(
                    options.empty_message
                        or _(
                            "ammo-comms",
                            "We have no ordnance available for restock"
                        )
                )
                if options.back then
                    addBack(profile)
                end
            end)
        elseif options.group == false then
            setCommsMessage(
                options.empty_message
                    or _(
                        "ammo-comms",
                        "We have no ordnance available for restock"
                    )
            )
            if options.back then
                addBack(profile)
            end
        end
        return
    end
    local function showRestock()
        if options.on_open ~= nil then
            options.on_open()
        end
        if options.group ~= false then
            local prompt = options.prompt
            if type(prompt) == "function" then
                prompt = prompt()
            end
            if prompt ~= nil then
                setCommsMessage(prompt)
            elseif options.show_reputation == false then
                setCommsMessage(_("ammo-comms", "What type of ordnance?"))
            else
                setCommsMessage(
                    string.format(
                        _(
                            "ammo-comms",
                            "What type of ordnance?\n\nReputation: %i"
                        ),
                        math.floor(commsSource(profile):getReputationPoints())
                    )
                )
            end
        end
        for missile_index, missile_type in ipairs(order) do
            if
                (options.ignore_availability or available[missile_type])
                and commsSource(profile):getWeaponStorageMax(missile_type) > 0
                and inStock(missile_type)
            then
                if options.label ~= nil then
                    addCommsReply(options.label(missile_type), function()
                        handle_restock(missile_type)
                    end)
                else
                    local prompt_options = options.prompts
                        and options.prompts[missile_type]
                    local prompt
                    if prompt_options ~= nil and #prompt_options > 0 then
                        prompt = prompt_options[math.random(1, #prompt_options)]
                    elseif options.prompt_prefix ~= nil then
                        prompt = options.prompt_prefix(missile_type)
                    elseif missile_type == "Nuke" then
                        if math.random(1, 10) <= 5 then
                            prompt = _(
                                "ammo-comms",
                                "Can you supply us with some nukes? ("
                            )
                        else
                            prompt =
                                _("ammo-comms", "We really need some nukes (")
                        end
                    elseif missile_type == "EMP" then
                        if math.random(1, 10) <= 5 then
                            prompt = _(
                                "ammo-comms",
                                "Please re-stock our EMP missiles. ("
                            )
                        else
                            prompt = _("ammo-comms", "Got any EMPs? (")
                        end
                    elseif missile_type == "Homing" then
                        if math.random(1, 10) <= 5 then
                            prompt = _(
                                "ammo-comms",
                                "Do you have spare homing missiles for us? ("
                            )
                        else
                            prompt = _(
                                "ammo-comms",
                                "Do you have extra homing missiles? ("
                            )
                        end
                    elseif missile_type == "Mine" then
                        if math.random(1, 10) <= 5 then
                            prompt =
                                _("ammo-comms", "We could use some mines. (")
                        else
                            prompt = _("ammo-comms", "How about mines? (")
                        end
                    else
                        if math.random(1, 10) <= 5 then
                            prompt = _("ammo-comms", "What about HVLI? (")
                        else
                            prompt =
                                _("ammo-comms", "Could you provide HVLI? (")
                        end
                    end
                    if options.on_prompt ~= nil then
                        options.on_prompt(missile_type, prompt)
                    end
                    local label
                    local availability = ""
                    if inventory ~= nil and not inventory.Unlimited then
                        availability = string.format(
                            _("ammo-comms", ", %i avail"),
                            math.floor(inventory[missile_type] or 0)
                        )
                    end
                    if options.prompt_format ~= nil then
                        label = string.format(
                            options.prompt_format,
                            prompt,
                            StationCore.getWeaponCost(missile_type, profile),
                            availability
                        )
                    elseif inventory ~= nil and not inventory.Unlimited then
                        label = string.format(
                            _("ammo-comms", "%s (%i rep each%s)"),
                            prompt,
                            StationCore.getWeaponCost(missile_type, profile),
                            availability
                        )
                    else
                        label = string.format(
                            _("ammo-comms", "%s%d rep each)"),
                            prompt,
                            StationCore.getWeaponCost(missile_type, profile)
                        )
                    end
                    addCommsReply(label, function()
                        handle_restock(missile_type)
                    end)
                end
            end
        end
        if options.back then
            addBack(profile)
        end
    end
    if options.group == false then
        showRestock()
    else
        addCommsReply(group_label, showRestock)
    end
end

function M.dockingStatus(profile, category, repair_failure_typo)
    local header
    if category == "primary" then
        header = _(
            "stationServices-comms",
            "Station %s primary docking services status:"
        )
    elseif category == "secondary" then
        header = _(
            "stationServices-comms",
            "Station %s docking repair services status:"
        )
    else
        header =
            _("stationServices-comms", "Station %s docking services status:")
    end
    local status = string.format(header, comms_target:getCallSign())
    if category ~= "secondary" then
        if comms_target:getRestocksScanProbes() then
            status = string.format(
                _("stationServices-comms", "%s\nReplenish scan probes."),
                status
            )
        else
            if comms_target.probe_fail_reason == nil then
                local reasons = {
                    _(
                        "stationServices-comms",
                        "Cannot replenish scan probes due to fabrication unit failure."
                    ),
                    _(
                        "stationServices-comms",
                        "Parts shortage prevents scan probe replenishment."
                    ),
                    _(
                        "stationServices-comms",
                        "Station management has curtailed scan probe replenishment for cost cutting reasons."
                    ),
                }
                comms_target.probe_fail_reason =
                    reasons[math.random(1, #reasons)]
            end
            status =
                string.format("%s\n%s", status, comms_target.probe_fail_reason)
        end
        if comms_target:getRepairDocked() then
            status = string.format(
                _("stationServices-comms", "%s\nShip hull repair."),
                status
            )
        else
            if comms_target.repair_fail_reason == nil then
                local maintenance_message
                if repair_failure_typo then
                    maintenance_message = _(
                        "stationServices-comms",
                        "Hull repair automation unavailable whie it is undergoing maintenance."
                    )
                else
                    maintenance_message = _(
                        "stationServices-comms",
                        "Hull repair automation unavailable while it is undergoing maintenance."
                    )
                end
                local reasons = {
                    _(
                        "stationServices-comms",
                        "We're out of the necessary materials and supplies for hull repair."
                    ),
                    maintenance_message,
                    _(
                        "stationServices-comms",
                        "All hull repair technicians quarantined to quarters due to illness."
                    ),
                }
                comms_target.repair_fail_reason =
                    reasons[math.random(1, #reasons)]
            end
            status =
                string.format("%s\n%s", status, comms_target.repair_fail_reason)
        end
        if comms_target:getSharesEnergyWithDocked() then
            status = string.format(
                _("stationServices-comms", "%s\nRecharge ship energy stores."),
                status
            )
        else
            if comms_target.energy_fail_reason == nil then
                local reasons = {
                    _(
                        "stationServices-comms",
                        "A recent reactor failure has put us on auxiliary power, so we cannot recharge ships."
                    ),
                    _(
                        "stationServices-comms",
                        "A damaged power coupling makes it too dangerous to recharge ships."
                    ),
                    _(
                        "stationServices-comms",
                        "An asteroid strike damaged our solar cells and we are short on power, so we can't recharge ships right now."
                    ),
                }
                comms_target.energy_fail_reason =
                    reasons[math.random(1, #reasons)]
            end
            status =
                string.format("%s\n%s", status, comms_target.energy_fail_reason)
        end
    end
    if category ~= "primary" then
        local comms_data = comms_target.comms_data
        if comms_data.jump_overcharge then
            status = string.format(
                _("stationServices-comms", "%s\nMay overcharge jump drive"),
                status
            )
        end
        if comms_data.probe_launch_repair then
            status = string.format(
                _("stationServices-comms", "%s\nMay repair probe launch system"),
                status
            )
        end
        if comms_data.hack_repair then
            status = string.format(
                _("stationServices-comms", "%s\nMay repair hacking system"),
                status
            )
        end
        if comms_data.scan_repair then
            status = string.format(
                _("stationServices-comms", "%s\nMay repair scanners"),
                status
            )
        end
        if comms_data.combat_maneuver_repair then
            status = string.format(
                _("stationServices-comms", "%s\nMay repair combat maneuver"),
                status
            )
        end
        if comms_data.self_destruct_repair then
            status = string.format(
                _(
                    "stationServices-comms",
                    "%s\nMay repair self destruct system"
                ),
                status
            )
        end
        if comms_data.tube_slow_down_repair then
            status = string.format(
                _("stationServices-comms", "%s\nMay repair slow loading tubes"),
                status
            )
        end
    end
    return status
end

function M.dockingStatusDetailed(profile, options)
    options = options or {}
    local repair_failure_typo = options.repair_failure_typo
    local systems = options.systems
        or {
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
    local status = string.format(
        _("stationServices-comms", "Station %s docking services status:"),
        comms_target:getCallSign()
    )
    if comms_target:getRestocksScanProbes() then
        status = string.format(
            _("stationServices-comms", "%s\nReplenish scan probes."),
            status
        )
    else
        if comms_target.probe_fail_reason == nil then
            local reasons = {
                _(
                    "stationServices-comms",
                    "Cannot replenish scan probes due to fabrication unit failure."
                ),
                _(
                    "stationServices-comms",
                    "Parts shortage prevents scan probe replenishment."
                ),
                _(
                    "stationServices-comms",
                    "Station management has curtailed scan probe replenishment for cost cutting reasons."
                ),
            }
            comms_target.probe_fail_reason = reasons[math.random(1, #reasons)]
        end
        status = string.format("%s\n%s", status, comms_target.probe_fail_reason)
    end
    if comms_target:getRepairDocked() then
        status = string.format(
            _("stationServices-comms", "%s\nShip hull repair."),
            status
        )
    else
        if comms_target.repair_fail_reason == nil then
            local maintenance_message
            if repair_failure_typo then
                maintenance_message = _(
                    "stationServices-comms",
                    "Hull repair automation unavailable whie it is undergoing maintenance."
                )
            else
                maintenance_message = _(
                    "stationServices-comms",
                    "Hull repair automation unavailable while it is undergoing maintenance."
                )
            end
            local reasons = {
                _(
                    "stationServices-comms",
                    "We're out of the necessary materials and supplies for hull repair."
                ),
                maintenance_message,
                _(
                    "stationServices-comms",
                    "All hull repair technicians quarantined to quarters due to illness."
                ),
            }
            comms_target.repair_fail_reason = reasons[math.random(1, #reasons)]
        end
        status =
            string.format("%s\n%s", status, comms_target.repair_fail_reason)
    end
    if comms_target:getSharesEnergyWithDocked() then
        status = string.format(
            _("stationServices-comms", "%s\nRecharge ship energy stores."),
            status
        )
    else
        if comms_target.energy_fail_reason == nil then
            local reasons = {
                _(
                    "stationServices-comms",
                    "A recent reactor failure has put us on auxiliary power, so we cannot recharge ships."
                ),
                _(
                    "stationServices-comms",
                    "A damaged power coupling makes it too dangerous to recharge ships."
                ),
                _(
                    "stationServices-comms",
                    "An asteroid strike damaged our solar cells and we are short on power, so we can't recharge ships right now."
                ),
            }
            comms_target.energy_fail_reason = reasons[math.random(1, #reasons)]
        end
        status =
            string.format("%s\n%s", status, comms_target.energy_fail_reason)
    end
    if comms_target.comms_data.jump_overcharge then
        status = string.format(
            _("stationServices-comms", "%s\nMay overcharge jump drive"),
            status
        )
    end
    local comms_data = comms_target.comms_data
    status = string.format(
        _(
            "stationServices-comms",
            "%s\nMay repair the following primary systems:"
        ),
        status
    )
    local line_item_count = 0
    for index, system in ipairs(systems) do
        if comms_data.system_repair[system] then
            if line_item_count == 0 or line_item_count >= 3 then
                status = status .. _("stationServices-comms", "\n    ")
                line_item_count = 0
            end
            status = status .. system .. "  "
            line_item_count = line_item_count + 1
        end
    end
    local coolant_header
    if options.coolant_label == "cooling pump" then
        coolant_header = _(
            "stationServices-comms",
            "%s\nMay repair the cooling pump for the following primary systems:"
        )
    else
        coolant_header = _(
            "stationServices-comms",
            "%s\nMay repair the coolant pump on the following primary systems:"
        )
    end
    status = string.format(coolant_header, status)
    line_item_count = 0
    for index, system in ipairs(systems) do
        if comms_data.coolant_pump_repair[system] then
            if line_item_count == 0 or line_item_count >= 3 then
                status = status .. _("stationServices-comms", "\n    ")
                line_item_count = 0
            end
            status = status .. system .. "  "
            line_item_count = line_item_count + 1
        end
    end
    status = string.format(
        _(
            "stationServices-comms",
            "%s\nMay repair the following secondary systems:"
        ),
        status
    )
    line_item_count = 0
    if comms_data.probe_launch_repair then
        if line_item_count == 0 or line_item_count >= 3 then
            status = status .. _("stationServices-comms", "\n    ")
            line_item_count = 0
        end
        status = string.format(
            _("stationServices-comms", "%sprobe launch system   "),
            status
        )
        line_item_count = line_item_count + 1
    end
    if comms_data.hack_repair then
        if line_item_count == 0 or line_item_count >= 3 then
            status = status .. _("stationServices-comms", "\n    ")
            line_item_count = 0
        end
        status = string.format(
            _("stationServices-comms", "%shacking system   "),
            status
        )
        line_item_count = line_item_count + 1
    end
    if comms_data.scan_repair then
        if line_item_count == 0 or line_item_count >= 3 then
            status = status .. _("stationServices-comms", "\n    ")
            line_item_count = 0
        end
        status =
            string.format(_("stationServices-comms", "%sscanners   "), status)
        line_item_count = line_item_count + 1
    end
    if comms_data.combat_maneuver_repair then
        if line_item_count == 0 or line_item_count >= 3 then
            status = status .. _("stationServices-comms", "\n    ")
            line_item_count = 0
        end
        status = string.format(
            _("stationServices-comms", "%scombat maneuver   "),
            status
        )
        line_item_count = line_item_count + 1
    end
    if comms_data.self_destruct_repair then
        if line_item_count == 0 or line_item_count >= 3 then
            status = status .. _("stationServices-comms", "\n    ")
        end
        status = string.format(
            _("stationServices-comms", "%sself destruct system   "),
            status
        )
    end
    return status
end

function M.addDockingStatus(profile, mode, repair_failure_typo, options)
    options = options or {}
    addCommsReply(
        _("stationServices-comms", "Docking services status"),
        function()
            if mode == "detailed" then
                options.repair_failure_typo = repair_failure_typo
                setCommsMessage(M.dockingStatusDetailed(profile, options))
            elseif mode == "categorized" then
                local prompt
                if profile.upgrades ~= nil then
                    prompt = _(
                        "stationServices-comms",
                        "Which docking service category do you want a status for?\n    Primary services:\n        Charge battery, repair hull, replenish probes\n    Secondary systems repair:\n        Scanners, hacking, probe launch, combat maneuver, self destruct\n    Upgrade ship systems:\n        Beam, missile, shield, hull, impulse, ftl, sensors"
                    )
                else
                    prompt = _(
                        "stationServices-comms",
                        "Which docking service category do you want a status for?\n    Primary services:\n        Charge battery, repair hull, replenish probes\n    Secondary systems repair:\n        Scanners, hacking, probe launch, combat maneuver, self destruct"
                    )
                end
                setCommsMessage(prompt)
                addCommsReply(
                    _("stationServices-comms", "Primary services"),
                    function()
                        setCommsMessage(
                            M.dockingStatus(
                                profile,
                                "primary",
                                repair_failure_typo
                            )
                        )
                        addBack(profile)
                    end
                )
                addCommsReply(
                    _("stationServices-comms", "Secondary systems repair"),
                    function()
                        setCommsMessage(
                            M.dockingStatus(
                                profile,
                                "secondary",
                                repair_failure_typo
                            )
                        )
                        addBack(profile)
                    end
                )
                if profile.upgrades ~= nil then
                    addCommsReply(
                        _("upgrade-comms", "Upgrade ship systems"),
                        function()
                            M.setUpgradeStatus(profile, profile.upgrades)
                            if profile.upgrades.explain ~= nil then
                                addCommsReply(
                                    _(
                                        "upgrade-comms",
                                        "Explain ship upgrade categories"
                                    ),
                                    profile.upgrades.explain
                                )
                            end
                            addBack(profile)
                        end
                    )
                end
            else
                setCommsMessage(
                    M.dockingStatus(profile, "combined", repair_failure_typo)
                )
            end
            addBack(profile)
        end
    )
end

function M.addJumpOvercharge(profile)
    if
        not comms_target.comms_data.jump_overcharge
        or not commsSource(profile):hasJumpDrive()
    then
        return
    end
    local options = profile.docked.jump_overcharge or {}
    local max_charge = commsSource(profile).max_jump_range or 50000
    if commsSource(profile):getJumpDriveCharge() < max_charge then
        return
    end
    local function overcharge()
        if not ensureDocked(profile) then
            return
        end
        if commsSource(profile):takeReputationPoints(10) then
            commsSource(profile):setJumpDriveCharge(
                commsSource(profile):getJumpDriveCharge() + max_charge
            )
            if options.on_overcharge ~= nil then
                options.on_overcharge()
            end
            setCommsMessage(
                string.format(
                    _(
                        "stationServices-comms",
                        "Your jump drive has been overcharged to %ik"
                    ),
                    math.floor(commsSource(profile):getJumpDriveCharge() / 1000)
                )
            )
        else
            setCommsMessage(_("needRep-comms", "Insufficient reputation"))
        end
        addBack(profile)
    end
    addCommsReply(
        _("stationServices-comms", "Overcharge Jump Drive (10 Rep)"),
        function()
            if
                options.safety_limit ~= nil
                and commsSource(profile):getJumpDriveCharge() / 1000
                    > options.safety_limit
            then
                setCommsMessage(options.safety_message)
                addCommsReply(options.confirm_label, overcharge)
                if options.explanation_label ~= nil then
                    addCommsReply(options.explanation_label, function()
                        setCommsMessage(options.explanation_message)
                        addBack(profile)
                    end)
                end
            else
                overcharge()
            end
        end
    )
end

local function repairSystems(profile)
    return profile.docked.repair_systems or REPAIR_SYSTEMS
end

local function repairAvailable(profile, system)
    if system.key ~= nil and not comms_target.comms_data[system.key] then
        return false
    end
    local source = commsSource(profile)
    if type(system.available) == "function" then
        return system.available(source, profile)
    end
    if system.requires_capability and profile.combat_maneuver_capable then
        if not source.combat_maneuver_capable then
            return false
        end
    end
    return not source[system.available](source)
end

local function repairCost(profile, system)
    if profile.docked.repair_cost ~= nil then
        return profile.docked.repair_cost(system, profile)
    end
    if type(system.cost) == "function" then
        return system.cost(profile, system)
    end
    if type(system.cost) == "number" then
        return system.cost
    end
    return comms_target.comms_data.service_cost[system.cost]
end

local function repairPrompt(system, cost)
    local prompt = system.prompt
    if type(prompt) == "function" then
        return prompt(cost)
    end
    return string.format(prompt, cost)
end

local function repairSuccess(system)
    local success = system.success
    if type(success) == "function" then
        return success()
    end
    return success
end

function M.addRepairShipSystem(profile)
    local primary_options = profile.docked.repair_primary
    local repair_cost = profile.docked.repair_cost
    local primary_systems = {
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
    if primary_options ~= nil and primary_options.systems ~= nil then
        primary_systems = primary_options.systems
    end
    local primary_cost = 5
    if primary_options ~= nil and primary_options.cost ~= nil then
        primary_cost = primary_options.cost
    end
    local primary_repair = comms_target.comms_data.system_repair or {}
    local coolant_repair = comms_target.comms_data.coolant_pump_repair or {}
    local normal_coolant = comms_source.normal_coolant_rate or {}
    local function primary_needs_repair()
        for index, system in ipairs(primary_systems) do
            if
                primary_repair[system]
                and comms_source:getSystemHealthMax(system) < 1
            then
                return true
            end
            if
                coolant_repair[system]
                and comms_source:getSystemCoolantRate(system)
                    < normal_coolant[system]
            then
                return true
            end
        end
        return false
    end

    local offer_repair = false
    for system_index, system in ipairs(repairSystems(profile)) do
        if repairAvailable(profile, system) then
            offer_repair = true
            break
        end
    end
    if primary_options ~= nil and primary_needs_repair() then
        offer_repair = true
    end
    if not offer_repair then
        return
    end
    addCommsReply(_("stationServices-comms", "Repair ship system"), function()
        setCommsMessage(
            string.format(
                _(
                    "stationServices-comms",
                    "What system would you like repaired?\n\nReputation: %i"
                ),
                math.floor(commsSource(profile):getReputationPoints())
            )
        )
        if primary_options ~= nil then
            for index, system in ipairs(primary_systems) do
                if repair_system_diagnostic then
                    print("offer repair system:", system)
                end
                if
                    primary_repair[system]
                    and comms_source:getSystemHealthMax(system) < 1
                then
                    addCommsReply(
                        string.format(
                            _(
                                "stationServices-comms",
                                "Repair %s (current max is %i%%) (%i Rep)"
                            ),
                            system,
                            math.floor(
                                comms_source:getSystemHealthMax(system) * 100
                            ),
                            primary_cost
                        ),
                        function()
                            if
                                comms_source:takeReputationPoints(primary_cost)
                            then
                                comms_source:setSystemHealthMax(system, 1)
                                comms_source:setSystemHealth(system, 1)
                                setCommsMessage(
                                    string.format(
                                        _(
                                            "stationServices-comms",
                                            "%s has been repaired"
                                        ),
                                        system
                                    )
                                )
                            else
                                setCommsMessage(
                                    _(
                                        "needRep-comms",
                                        "Insufficient reputation"
                                    )
                                )
                            end
                            addBack(profile)
                        end
                    )
                end
                if
                    coolant_repair[system]
                    and comms_source:getSystemCoolantRate(system)
                        < normal_coolant[system]
                then
                    addCommsReply(
                        string.format(
                            _(
                                "stationServices-comms",
                                "Repair %s coolant pump (%i Rep)"
                            ),
                            system,
                            primary_cost
                        ),
                        function()
                            if
                                comms_source:takeReputationPoints(primary_cost)
                            then
                                comms_source:setSystemCoolantRate(
                                    system,
                                    normal_coolant[system]
                                )
                                setCommsMessage(
                                    string.format(
                                        _(
                                            "stationServices-comms",
                                            "%s coolant pump has been repaired"
                                        ),
                                        system
                                    )
                                )
                            else
                                setCommsMessage(
                                    _(
                                        "needRep-comms",
                                        "Insufficient reputation"
                                    )
                                )
                            end
                            addBack(profile)
                        end
                    )
                end
            end
        end
        for system_index, system in ipairs(repairSystems(profile)) do
            if repairAvailable(profile, system) then
                local cost = repairCost(profile, system)
                addCommsReply(repairPrompt(system, cost), function()
                    if not ensureDocked(profile) then
                        return
                    end
                    local source = commsSource(profile)
                    if source:takeReputationPoints(cost) then
                        if type(system.repair) == "function" then
                            system.repair(source, profile)
                        else
                            source[system.repair](source, true)
                        end
                        setCommsMessage(repairSuccess(system))
                    else
                        setCommsMessage(
                            _("needRep-comms", "Insufficient reputation")
                        )
                    end
                    addBack(profile)
                end)
            end
        end
        addBack(profile)
    end)
end

function M.addUpgrade(profile, options)
    local ship_type = commsSource(profile):getTypeName()
    if comms_target.comms_data.upgrade_path == nil then
        return
    end
    if comms_target.comms_data.upgrade_path[ship_type] == nil then
        return
    end
    addCommsReply(_("upgrade-comms", "Upgrade ship"), function()
        local upgrade_count = 0
        for upgrade_type, max_level in
            pairs(comms_target.comms_data.upgrade_path[ship_type])
        do
            local current_level =
                commsSource(profile).upgrade_path[upgrade_type]
            if max_level > current_level then
                upgrade_count = upgrade_count + 1
                local cost = math.ceil(
                    base_upgrade_cost + (current_level + 1) * upgrade_price
                )
                addCommsReply(
                    string.format(
                        _("upgrade-comms", "%s: %s (%s)"),
                        upgrade_type,
                        upgrade_path[ship_type][upgrade_type][current_level + 1].desc,
                        cost
                    ),
                    function()
                        if not ensureDocked(profile) then
                            return
                        end
                        if commsSource(profile):takeReputationPoints(cost) then
                            options.apply(commsSource(profile), upgrade_type)
                            setCommsMessage(
                                _("upgrade-comms", "Upgrade complete")
                            )
                        else
                            setCommsMessage(
                                _("needRep-comms", "Insufficient reputation")
                            )
                        end
                        addBack(profile)
                    end
                )
            end
        end
        if upgrade_count > 0 then
            setCommsMessage(
                _(
                    "upgrade-comms",
                    "What kind of upgrade are you interested in? We can provide the following upgrades\nsystem: description (reputation cost)"
                )
            )
        else
            setCommsMessage(
                _(
                    "upgrade-comms",
                    "Alas, we cannot upgrade any of your systems"
                )
            )
        end
        addBack(profile)
    end)
end

function M.setUpgradeStatus(profile, options)
    local status = string.format(
        _("upgrade-comms", "Station %s docking upgrade services:"),
        comms_target:getCallSign()
    )
    if comms_target.comms_data.upgrade_path ~= nil then
        local ship_type = commsSource(profile):getTypeName()
        if comms_target.comms_data.upgrade_path[ship_type] ~= nil then
            local upgrade_count = 0
            local out = _(
                "upgrade-comms",
                "We can provide the following upgrades:\n    system: description (reputation cost)"
            )
            for upgrade_type, max_level in
                pairs(comms_target.comms_data.upgrade_path[ship_type])
            do
                local current_level =
                    commsSource(profile).upgrade_path[upgrade_type]
                if max_level > current_level then
                    upgrade_count = upgrade_count + 1
                    out = string.format(
                        _("upgrade-comms", "%s\n        %s: %s (%s)"),
                        out,
                        upgrade_type,
                        upgrade_path[ship_type][upgrade_type][current_level + 1].desc,
                        math.ceil(
                            base_upgrade_cost
                                + (current_level + 1) * upgrade_price
                        )
                    )
                end
            end
            if upgrade_count > 0 then
                status = out
            else
                status = _(
                    "upgrade-comms",
                    "No more ship upgrades available for your ship"
                )
            end
        else
            status =
                _("upgrade-comms", "No ship upgrades available for your ship")
        end
    else
        status = _("upgrade-comms", "No ship upgrades available")
    end
    setCommsMessage(status)
end

function M.addGoods(profile)
    if profile.goods ~= nil and profile.goods.menu ~= nil then
        profile.goods.menu()
        return
    end
    local station_goods = comms_target.comms_data.goods or {}
    local good_count = 0
    for _ in pairs(station_goods) do
        good_count = good_count + 1
    end
    if good_count == 0 then
        return
    end
    addCommsReply(_("trade-comms", "Buy, sell, trade"), function()
        local report = string.format(
            _(
                "trade-comms",
                "Station %s:\nGoods or components available for sale: quantity, cost in reputation\n"
            ),
            comms_target:getCallSign()
        )
        for good, good_data in pairs(station_goods) do
            report = report
                .. string.format(
                    _("trade-comms", "     %s: %i, %i\n"),
                    goodsName(profile, good),
                    good_data.quantity,
                    good_data.cost
                )
        end
        if comms_target.comms_data.buy ~= nil then
            report = report
                .. _(
                    "trade-comms",
                    "Goods or components station will buy: price in reputation\n"
                )
            for good, price in pairs(comms_target.comms_data.buy) do
                report = report
                    .. string.format(
                        _("trade-comms", "     %s: %i\n"),
                        goodsName(profile, good),
                        price
                    )
            end
        end
        report = report
            .. string.format(
                _("trade-comms", "Current cargo aboard %s:\n"),
                commsSource(profile):getCallSign()
            )
        local player_good_count = 0
        if commsSource(profile).goods ~= nil then
            for good, quantity in pairs(commsSource(profile).goods) do
                player_good_count = player_good_count + 1
                report = report
                    .. string.format(
                        _("trade-comms", "     %s: %i\n"),
                        goodsName(profile, good),
                        goodsQuantity(quantity)
                    )
            end
        end
        if player_good_count < 1 then
            report = report .. _("trade-comms", "     Empty\n")
        end
        report = report
            .. string.format(
                _(
                    "trade-comms",
                    "Available Space: %i, Available Reputation: %i\n"
                ),
                commsSource(profile).cargo,
                math.floor(commsSource(profile):getReputationPoints())
            )
        setCommsMessage(report)
        for good, good_data in pairs(station_goods) do
            local name = goodsName(profile, good)
            addCommsReply(
                string.format(
                    _("trade-comms", "Buy one %s for %i reputation"),
                    name,
                    good_data.cost
                ),
                function()
                    if not ensureDocked(profile) then
                        return
                    end
                    local message = string.format(
                        _("trade-comms", "Type: %s, Quantity: %i, Rep: %i"),
                        name,
                        good_data.quantity,
                        good_data.cost
                    )
                    if commsSource(profile).cargo < 1 then
                        message = message
                            .. _(
                                "trade-comms",
                                "\nInsufficient cargo space for purchase"
                            )
                    elseif
                        good_data.cost
                        > math.floor(commsSource(profile):getReputationPoints())
                    then
                        message = message
                            .. _(
                                "needRep-comms",
                                "\nInsufficient reputation for purchase"
                            )
                    elseif good_data.quantity < 1 then
                        message = message
                            .. _(
                                "trade-comms",
                                "\nInsufficient station inventory"
                            )
                    elseif
                        commsSource(profile):takeReputationPoints(
                            good_data.cost
                        )
                    then
                        commsSource(profile).cargo = commsSource(profile).cargo
                            - 1
                        good_data.quantity = good_data.quantity - 1
                        if commsSource(profile).goods == nil then
                            commsSource(profile).goods = {}
                        end
                        commsSource(profile).goods[good] = goodsQuantity(
                            commsSource(profile).goods[good]
                        ) + 1
                        message = message .. _("trade-comms", "\npurchased")
                    else
                        message = message
                            .. _(
                                "needRep-comms",
                                "\nInsufficient reputation for purchase"
                            )
                    end
                    setCommsMessage(message)
                    addBack(profile)
                end
            )
        end
        if comms_target.comms_data.buy ~= nil then
            for good, price in pairs(comms_target.comms_data.buy) do
                if hasGood(profile, good) then
                    local name = goodsName(profile, good)
                    addCommsReply(
                        string.format(
                            _("trade-comms", "Sell one %s for %i reputation"),
                            name,
                            price
                        ),
                        function()
                            if not ensureDocked(profile) then
                                return
                            end
                            local message = string.format(
                                _(
                                    "trade-comms",
                                    "Type: %s,  Reputation price: %i"
                                ),
                                name,
                                price
                            )
                            commsSource(profile).goods[good] = goodsQuantity(
                                commsSource(profile).goods[good]
                            ) - 1
                            commsSource(profile):addReputationPoints(price)
                            message = message .. _("trade-comms", "\nOne sold")
                            commsSource(profile).cargo = commsSource(profile).cargo
                                + 1
                            setCommsMessage(message)
                            addBack(profile)
                        end
                    )
                end
            end
        end
        local trade = comms_target.comms_data.trade or {}
        for trade_index, trade_good in ipairs({ "food", "medicine", "luxury" }) do
            if trade[trade_good] and hasGood(profile, trade_good) then
                for good, good_data in pairs(station_goods) do
                    local name = goodsName(profile, good)
                    addCommsReply(
                        string.format(TRADE_LABELS[trade_good], name),
                        function()
                            if not ensureDocked(profile) then
                                return
                            end
                            local message = string.format(
                                _("trade-comms", "Type: %s,  Quantity: %i"),
                                name,
                                good_data.quantity
                            )
                            if good_data.quantity < 1 then
                                message = message
                                    .. _(
                                        "trade-comms",
                                        "\nInsufficient station inventory"
                                    )
                            else
                                good_data.quantity = good_data.quantity - 1
                                if commsSource(profile).goods == nil then
                                    commsSource(profile).goods = {}
                                end
                                commsSource(profile).goods[good] = goodsQuantity(
                                    commsSource(profile).goods[good]
                                ) + 1
                                commsSource(profile).goods[trade_good] = goodsQuantity(
                                    commsSource(profile).goods[trade_good]
                                ) - 1
                                message = message
                                    .. _("trade-comms", "\nTraded")
                            end
                            setCommsMessage(message)
                            addBack(profile)
                        end
                    )
                end
            end
        end
        if profile.goods ~= nil and profile.goods.transfer ~= nil then
            profile.goods.transfer()
        end
        addBack(profile)
    end)
    local player_good_count = 0
    if commsSource(profile).goods ~= nil then
        for _ in pairs(commsSource(profile).goods) do
            player_good_count = player_good_count + 1
        end
    end
    local goods_options = profile.goods or {}
    local offer_jettison = player_good_count > 0
    if goods_options.jettison == false then
        offer_jettison = false
    elseif goods_options.jettison_when == "full" then
        offer_jettison = comms_source.cargo < 1
    end
    if offer_jettison then
        addCommsReply(_("trade-comms", "Jettison cargo"), function()
            if goods_options.jettison_prompt ~= nil then
                setCommsMessage(goods_options.jettison_prompt)
            else
                setCommsMessage(
                    string.format(
                        _(
                            "trade-comms",
                            "Available space: %i\nWhat would you like to jettison?"
                        ),
                        commsSource(profile).cargo
                    )
                )
            end
            for good, quantity in pairs(commsSource(profile).goods) do
                if goodsQuantity(quantity) > 0 then
                    local name = goodsName(profile, good)
                    addCommsReply(name, function()
                        commsSource(profile).goods[good] = goodsQuantity(
                            commsSource(profile).goods[good]
                        ) - 1
                        commsSource(profile).cargo = commsSource(profile).cargo
                            + 1
                        setCommsMessage(
                            string.format(
                                _("trade-comms", "One %s jettisoned"),
                                name
                            )
                        )
                        addBack(profile)
                    end)
                end
            end
            addBack(profile)
        end)
    end
    if profile.goods == nil or profile.goods.explain ~= false then
        M.explainGoods(profile)
    end
end

function M.explainGoods(profile)
    addCommsReply(
        _("explainGoods-comms", "No tutorial covered goods or cargo. Explain"),
        function()
            setCommsMessage(
                _(
                    "explainGoods-comms",
                    "Different types of cargo or goods may be obtained from stations, freighters or other sources. They go by one word descriptions such as dilithium, optic, warp, etc. Certain mission goals may require a particular type or types of cargo. Each player ship differs in cargo carrying capacity. Goods may be obtained by spending reputation points or by trading other types of cargo (typically food, medicine or luxury)"
                )
            )
            addBack(profile)
        end
    )
end

function M.enemyWarning(profile, options)
    options = options or {}
    addCommsReply(
        _("helpfullWarning-comms", "See any enemies in your area?"),
        function()
            if commsSource(profile):isFriendly(comms_target) then
                local enemies_in_range = 0
                for _, obj in
                    ipairs(
                        comms_target:getObjectsInRange(options.range or 30000)
                    )
                do
                    if obj:isEnemy(commsSource(profile)) then
                        enemies_in_range = enemies_in_range + 1
                    end
                end
                if enemies_in_range > 1 then
                    setCommsMessage(
                        string.format(
                            _(
                                "helpfullWarning-comms",
                                "Yes, we see %i enemies within 30U"
                            ),
                            enemies_in_range
                        )
                    )
                elseif enemies_in_range == 1 then
                    setCommsMessage(
                        _(
                            "helpfullWarning-comms",
                            "Yes, we see one enemy within 30U"
                        )
                    )
                else
                    setCommsMessage(
                        _("helpfullWarning-comms", "No enemies within 30U")
                    )
                end
                if enemies_in_range > 0 then
                    commsSource(profile):addReputationPoints(
                        options.enemy_reward or 2
                    )
                else
                    commsSource(profile):addReputationPoints(
                        options.clear_reward or 1
                    )
                end
            else
                setCommsMessage(_("helpfullWarning-comms", "Not really"))
                commsSource(profile):addReputationPoints(
                    options.neutral_reward or 1
                )
            end
            addBack(profile)
        end
    )
end

function M.generalInformation(profile)
    local message = comms_target.comms_data.general
    if message == nil or message == "" then
        return
    end
    addCommsReply(
        _("stationGeneralInfo-comms", "General station information"),
        function()
            setCommsMessage(message)
            addBack(profile)
        end
    )
end

function M.addCargo(profile, options)
    options = options or {}
    local has_cargo = false
    for _, quantity in pairs(commsSource(profile).goods or {}) do
        if goodsQuantity(quantity) > 0 then
            has_cargo = true
            break
        end
    end
    if has_cargo then
        addCommsReply(_("trade-comms", "Jettison cargo"), function()
            setCommsMessage(
                string.format(
                    _(
                        "trade-comms",
                        "Available space: %i\nWhat would you like to jettison?"
                    ),
                    commsSource(profile).cargo
                )
            )
            for good, quantity in pairs(commsSource(profile).goods) do
                if goodsQuantity(quantity) > 0 then
                    local name = goodsName(profile, good)
                    addCommsReply(name, function()
                        commsSource(profile).goods[good] = goodsQuantity(
                            commsSource(profile).goods[good]
                        ) - 1
                        commsSource(profile).cargo = commsSource(profile).cargo
                            + 1
                        setCommsMessage(
                            string.format(
                                _("trade-comms", "One %s jettisoned"),
                                name
                            )
                        )
                        addBack(profile)
                    end)
                end
            end
            addBack(profile)
        end)
        if options.transfer ~= nil then
            options.transfer()
        end
    end
    if options.explain then
        M.explainGoods(profile)
    end
end

function M.addResources(profile)
    local resources = profile.resources or {}
    if resources.prompt then
        setCommsMessage(
            _("station-comms", "Which of the following are you interested in?")
        )
    end
    local relationship = "neutral"
    if commsSource(profile):isFriendly(comms_target) then
        relationship = "friendly"
    end
    if resources.recruitment ~= false then
        StationCore.getRepairCrewFromStation(
            relationship,
            resources.recruitment,
            profile
        )
    end
    if resources.coolant ~= false then
        StationCore.getCoolantFromStation(
            relationship,
            resources.coolant,
            profile
        )
    end
    if resources.after_recruitment ~= nil then
        resources.after_recruitment()
    end
    if resources.before_goods ~= nil then
        resources.before_goods()
    end
    if resources.goods ~= false then
        M.addGoods(profile)
    end
    if resources.after_goods ~= nil then
        resources.after_goods()
    end
end

function M.addServices(profile)
    if profile.docked.service_prompt ~= false then
        setCommsMessage(
            _("station-comms", "What station service are you interested in?")
        )
    end
    local sections = profile.docked.service_sections
    if sections == nil then
        if profile.upgrades ~= nil then
            M.addUpgrade(profile, profile.upgrades)
        end
        M.addOrdnanceRestock(profile)
        M.addDockingStatus(
            profile,
            "combined",
            profile.docked.status_repair_typo
        )
        M.addJumpOvercharge(profile)
        M.addRepairShipSystem(profile)
        return
    end
    for _, section in ipairs(sections) do
        if type(section) == "string" then
            section = { kind = section }
        end
        if section.kind == "callback" then
            section.callback()
        elseif section.kind == "ordnance" then
            M.addOrdnanceRestock(profile)
        elseif section.kind == "docking_status" then
            M.addDockingStatus(
                profile,
                section.mode or "combined",
                section.status_repair_typo or profile.docked.status_repair_typo,
                section
            )
        elseif section.kind == "jump_overcharge" then
            M.addJumpOvercharge(profile)
        elseif section.kind == "repair" then
            M.addRepairShipSystem(profile)
        elseif section.kind == "upgrade" then
            if profile.upgrades ~= nil then
                M.addUpgrade(profile, profile.upgrades)
            end
        elseif section.kind == "defense_fleet" then
            M.addDefenseFleet(profile)
        else
            error("Unknown station service section: " .. tostring(section.kind))
        end
    end
end

function M.docked(profile)
    M.greeting(profile)
    if profile.docked.before ~= nil then
        profile.docked.before()
    end
    if profile.docked.group_services then
        addCommsReply(
            profile.docked.service_label
                or _("station-comms", "Station services"),
            function()
                M.addServices(profile)
            end
        )
    else
        M.addServices(profile)
    end
    if profile.docked.after_services ~= nil then
        profile.docked.after_services()
    end
    if profile.docked.information ~= nil then
        M.information(profile, profile.docked.information)
    end
    if profile.docked.before_resources ~= nil then
        profile.docked.before_resources()
    end
    if profile.docked.group_resources then
        addCommsReply(
            _("station-comms", "Resources (repair crew, coolant, goods)"),
            function()
                M.addResources(profile)
            end
        )
    else
        M.addResources(profile)
    end
    if profile.docked.after_resources ~= nil then
        profile.docked.after_resources()
    end
end

function M.warpJammerExplanation(profile, variant)
    local label
    if variant == "all" then
        label = _("station-comms", "What's with all the warp jammers?")
    else
        label = _("station-comms", "What's with the warp jammers?")
    end
    addCommsReply(label, function()
        setCommsMessage(
            _(
                "station-comms",
                "When factions in various stations in the area started attacking each other, there was a particularly nasty tactic employed where warp or jump ships would ambush a station. Stations could not maintain defensive patrols indefinitely due to the expense. Putting in a warp jammer gives the station a chance to scramble their defense fleet when an enemy approaches. Of course, it slows friendly traffic, commercial or military, too. So, most warp jammers are controlled by nearby factions to allow them to enable or disable them upon request to facilitate the flow of ships. You can't connect to the warp jammer while docked because you're clearly not yet ready to traverse the controlled area. Destroying a warp jammer may have undesired indirect consequences, but there's no official rule against it."
            )
        )
        addBack(profile)
    end)
end

function M.sensorJammerExplanation(profile)
    addCommsReply(_("station-comms", "Explain sensor jammers"), function()
        setCommsMessage(
            _(
                "station-comms",
                "You mean those things that have a call sign that starts with SJ"
            )
        )
        addCommsReply(_("station-comms", "Yes. Why so many?"), function()
            setCommsMessage(
                _(
                    "station-comms",
                    "They were made during a big technological arms race. All the factions tried to make them to hinder their enemies as they approached. Most ships have got ways around them now, but nobody has gone out to clean up the leftovers. The closest thing to clean up done by the factions is to give them all SJ call signs to make ships aware of the potential navigation hazard."
                )
            )
            addBack(profile)
        end)
        addCommsReply(_("station-comms", "Yes. What do they do?"), function()
            setCommsMessage(
                _(
                    "station-comms",
                    "The sensor jammers reduce your long range sensor range. The degree and range of effectiveness varies with each one. They're also designed to be booby traps. If you don't disable the trap, they'll fry your scanners if you pick them up to neutralize them."
                )
            )
            addBack(profile)
        end)
        addCommsReply(
            _("station-comms", "Yes. How do I get rid of them?"),
            function()
                setCommsMessage(
                    _(
                        "station-comms",
                        "Just pick them up. You'll want to scan them first if you don't want your scanners fried."
                    )
                )
                addBack(profile)
            end
        )
        addBack(profile)
    end)
end

function M.gossip(profile, options)
    options = options or {}
    local has_gossip
    if options.defer_roll then
        has_gossip = true
    else
        has_gossip = random(1, 100) < (100 - (30 * (difficulty - 0.5)))
    end
    local comms_data = comms_target.comms_data
    if
        (comms_data.general ~= nil and comms_data.general ~= "")
        or (comms_data.history ~= nil and comms_data.history ~= "")
        or (
            not options.no_gossip
            and commsSource(profile):isFriendly(comms_target)
            and comms_data.gossip ~= nil
            and comms_data.gossip ~= ""
            and has_gossip
        )
    then
        addCommsReply(
            _("station-comms", "Tell me more about your station"),
            function()
                setCommsMessage(
                    _("station-comms", "What would you like to know?")
                )
                if comms_data.general ~= nil and comms_data.general ~= "" then
                    addCommsReply(
                        _("stationGeneralInfo-comms", "General information"),
                        function()
                            setCommsMessage(comms_data.general)
                            addBack(profile)
                        end
                    )
                end
                if comms_data.history ~= nil and comms_data.history ~= "" then
                    addCommsReply(
                        _("stationStory-comms", "Station history"),
                        function()
                            setCommsMessage(comms_data.history)
                            addBack(profile)
                        end
                    )
                end
                if
                    not options.no_gossip
                    and commsSource(profile):isFriendly(comms_target)
                    and comms_data.gossip ~= nil
                    and comms_data.gossip ~= ""
                then
                    local gossip_available
                    if options.defer_roll then
                        gossip_available = random(1, 100)
                            < (100 - (30 * (difficulty - 0.5)))
                    else
                        gossip_available = has_gossip
                    end
                    if options.gossip_roll == "half" then
                        gossip_available = random(1, 100) < 50
                    end
                    if gossip_available then
                        addCommsReply(_("gossip-comms", "Gossip"), function()
                            setCommsMessage(comms_data.gossip)
                            addBack(profile)
                        end)
                    end
                end
                if options.back ~= false then
                    addBack(profile)
                end
            end
        )
    end
end

function M.currentOrders(profile, callback)
    addCommsReply(_("orders-comms", "What are my current orders?"), function()
        callback()
        addBack(profile)
    end)
end

function M.location(profile)
    local comms_distance = distance(comms_target, commsSource(profile))
    if comms_distance > average_station_circle_distance then
        addCommsReply(_("station-comms", "Where am I?"), function()
            local station_x, station_y = comms_target:getPosition()
            local player_x, player_y = commsSource(profile):getPosition()
            local bearing =
                angleFromVectorNorth(player_x, player_y, station_x, station_y)
            setCommsMessage(
                string.format(
                    _(
                        "station-comms",
                        "Based on triangulation and signal strength, our communications software says you're on a bearing of %.1f from us at a distance of %.1f units"
                    ),
                    bearing,
                    comms_distance / 1000
                )
            )
            addBack(profile)
        end)
    end
end

function M.ordnanceInfo(profile)
    addCommsReply(
        _("ammo-comms", "What ordnance do you have available for restock?"),
        function()
            local count = 0
            local message = ""
            local available = comms_target.comms_data.weapon_available or {}
            for missile_index, missile_type in ipairs(RESTOCK_ORDER) do
                if available[missile_type] then
                    count = count + 1
                    message = message .. ORDNANCE_LABELS[missile_type]
                end
            end
            if count == 0 then
                message =
                    _("ammo-comms", "We have no ordnance available for restock")
            elseif count == 1 then
                message = string.format(
                    _(
                        "ammo-comms",
                        "We have the following type of ordnance available for restock:%s"
                    ),
                    message
                )
            else
                message = string.format(
                    _(
                        "ammo-comms",
                        "We have the following types of ordnance available for restock:%s"
                    ),
                    message
                )
            end
            setCommsMessage(message)
            addBack(profile)
        end
    )
end

function M.goodsAvailable(profile)
    local available = false
    for good, good_data in pairs(comms_target.comms_data.goods or {}) do
        if good_data.quantity > 0 then
            available = true
            break
        end
    end
    if not available then
        return
    end
    addCommsReply(
        _("trade-comms", "What goods do you have available for sale or trade?"),
        function()
            local message = string.format(
                _(
                    "trade-comms",
                    "Station %s:\nGoods or components available: quantity, cost in reputation"
                ),
                comms_target:getCallSign()
            )
            for good, good_data in pairs(comms_target.comms_data.goods) do
                message = message
                    .. string.format(
                        _("trade-comms", "\n   %14s: %2i, %3i"),
                        goodsName(profile, good),
                        good_data.quantity,
                        good_data.cost
                    )
            end
            setCommsMessage(message)
            addBack(profile)
        end
    )
end

function M.goodsKnowledge(profile)
    local options = profile.goods_knowledge or {}
    local knowledge_key = options.key or "goodsKnowledge"
    local stations = options.stations or station_list or {}
    if type(stations) == "function" then
        stations = stations()
    end
    stations = stations or {}
    local knowledge_max = options.max or 10
    addCommsReply(
        _("trade-comms", "Where can I find particular goods?"),
        function()
            local message = _(
                "trade-comms",
                "Friendly stations often have food or medicine or both. Neutral stations may trade their goods for food, medicine or luxury."
            )
            if comms_target.comms_data[knowledge_key] == nil then
                comms_target.comms_data[knowledge_key] = {}
                local knowledge_count = 0
                for station_index, station in ipairs(stations) do
                    if
                        station ~= nil
                        and station:isValid()
                        and (
                            options.exclude_enemies == false
                            or not station:isEnemy(commsSource(profile))
                        )
                    then
                        local chance = 60
                        if distance_diagnostic then
                            print(
                                "distance_diagnostic 7",
                                comms_target,
                                station
                            )
                        end
                        if distance(comms_target, station) > 75000 then
                            chance = 20
                        end
                        for good, good_data in
                            pairs(station.comms_data.goods or {})
                        do
                            if random(1, 100) <= chance then
                                comms_target.comms_data[knowledge_key][good] = {
                                    station = station:getCallSign(),
                                    sector = station:getSectorName(),
                                    cost = good_data.cost,
                                }
                                knowledge_count = knowledge_count + 1
                                if knowledge_count >= knowledge_max then
                                    break
                                end
                            end
                        end
                    end
                    if knowledge_count >= knowledge_max then
                        break
                    end
                end
            end
            local knowledge_count = 0
            for good, knowledge in pairs(comms_target.comms_data[knowledge_key]) do
                knowledge_count = knowledge_count + 1
                addCommsReply(goodsName(profile, good), function()
                    setCommsMessage(
                        string.format(
                            _(
                                "trade-comms",
                                "Station %s in sector %s has %s for %i reputation"
                            ),
                            knowledge.station,
                            knowledge.sector,
                            goodsName(profile, good),
                            knowledge.cost
                        )
                    )
                    addBack(profile)
                end)
            end
            if knowledge_count > 0 then
                message = message
                    .. _(
                        "trade-comms",
                        "\n\nWhat goods are you interested in?\nI've heard about these:"
                    )
            else
                message = message
                    .. _(
                        "trade-comms",
                        " Beyond that, I have no knowledge of specific stations"
                    )
            end
            setCommsMessage(message)
            addBack(profile)
        end
    )
end

function M.goodsInformation(profile)
    addCommsReply(
        string.format(
            _("station-comms", "Goods information at %s or near %s"),
            comms_target:getCallSign(),
            comms_target:getCallSign()
        ),
        function()
            setCommsMessage(_("station-comms", "Always good to get some goods"))
            M.goodsAvailable(profile)
            M.goodsKnowledge(profile)
        end
    )
end

function M.character(profile, options)
    options = options or {}
    local comms_data = comms_target.comms_data
    if comms_data.character == nil then
        return
    end
    if not options.always and random(1, 100) >= (70 - (20 * difficulty)) then
        return
    end
    addCommsReply(
        string.format(
            _("characterInfo-comms", "Tell me about %s"),
            comms_data.character
        ),
        function()
            if comms_data.characterDescription ~= nil then
                setCommsMessage(comms_data.characterDescription)
            else
                if comms_data.characterDeadEnd == nil then
                    if options.dead_ends ~= nil then
                        local responses = options.dead_ends()
                        comms_data.characterDeadEnd =
                            responses[math.random(1, #responses)]
                    else
                        local choice = math.random(1, 5)
                        if choice == 1 then
                            comms_data.characterDeadEnd = string.format(
                                _("characterInfo-comms", "Never heard of %s"),
                                comms_data.character
                            )
                        elseif choice == 2 then
                            comms_data.characterDeadEnd = string.format(
                                _(
                                    "characterInfo-comms",
                                    "%s died last week. The funeral was yesterday"
                                ),
                                comms_data.character
                            )
                        elseif choice == 3 then
                            comms_data.characterDeadEnd = string.format(
                                _(
                                    "characterInfo-comms",
                                    "%s? Who's %s? There's nobody here named %s"
                                ),
                                comms_data.character,
                                comms_data.character,
                                comms_data.character
                            )
                        elseif choice == 4 then
                            comms_data.characterDeadEnd = string.format(
                                _(
                                    "characterInfo-comms",
                                    "We don't talk about %s. They are gone and good riddance"
                                ),
                                comms_data.character
                            )
                        else
                            comms_data.characterDeadEnd = string.format(
                                _(
                                    "characterInfo-comms",
                                    "I think %s moved away"
                                ),
                                comms_data.character
                            )
                        end
                    end
                end
                setCommsMessage(comms_data.characterDeadEnd)
            end
            if options.on_character ~= nil then
                options.on_character()
            end
            if options.back ~= false then
                addBack(profile)
            end
        end
    )
end

function M.reportStatus(profile)
    addCommsReply(_("stationAssist-comms", "Report status"), function()
        local message = string.format(
            _("stationAssist-comms", "Hull: %d%%\n"),
            comms_target:getHullPercentage()
        )
        local shields = comms_target:getShieldCount()
        if shields == 1 then
            message = message
                .. string.format(
                    _("stationAssist-comms", "Shield: %d%%\n"),
                    math.floor(
                        comms_target:getShieldLevel(0)
                            / comms_target:getShieldMax(0)
                            * 100
                    )
                )
        else
            for index = 0, shields - 1 do
                message = message
                    .. string.format(
                        _("stationAssist-comms", "Shield %s: %d%%\n"),
                        index,
                        math.floor(
                            comms_target:getShieldLevel(index)
                                / comms_target:getShieldMax(index)
                                * 100
                        )
                    )
            end
        end
        setCommsMessage(message)
        addBack(profile)
    end)
end

function M.serviceInformation(profile, options)
    addCommsReply(options.label, function()
        setCommsMessage(
            _(
                "station-comms",
                "We offer a variety of services when you dock with us."
            )
        )
        M.ordnanceInfo(profile)
        M.addDockingStatus(profile, "categorized", options.status_repair_typo)
    end)
end

function M.informationSection(profile, section)
    if type(section) == "string" then
        section = { kind = section }
    end
    if not sectionEnabled(profile, section) then
        return
    end
    local kind = section.kind
    if kind == "callback" then
        section.callback()
    elseif kind == "orders" then
        M.currentOrders(profile, section.callback)
    elseif kind == "warp_jammer" then
        M.warpJammerExplanation(profile, section.variant)
    elseif kind == "sensor_jammer" then
        M.sensorJammerExplanation(profile)
    elseif kind == "gossip" then
        M.gossip(profile, section)
    elseif kind == "location" then
        M.location(profile)
    elseif kind == "ordnance" then
        M.ordnanceInfo(profile)
    elseif kind == "docking_status" then
        M.addDockingStatus(
            profile,
            section.mode or "combined",
            section.status_repair_typo,
            section
        )
    elseif kind == "service_information" then
        M.serviceInformation(profile, section)
    elseif kind == "goods_information" then
        M.goodsInformation(profile)
    elseif kind == "goods_available" then
        M.goodsAvailable(profile)
    elseif kind == "goods_knowledge" then
        M.goodsKnowledge(profile)
    elseif kind == "goods_explain" then
        M.explainGoods(profile)
    elseif kind == "enemy_warning" then
        M.enemyWarning(profile, section)
    elseif kind == "general_information" then
        M.generalInformation(profile)
    elseif kind == "character" then
        M.character(profile, section)
    elseif kind == "status" then
        M.reportStatus(profile)
    else
        error("Unknown station communication section: " .. tostring(kind))
    end
end

function M.information(profile, options)
    addCommsReply(_("station-comms", "I need information"), function()
        if type(options.prompt) == "function" then
            setCommsMessage(options.prompt())
        else
            setCommsMessage(options.prompt)
        end
        for section_index, section in ipairs(options.sections) do
            M.informationSection(profile, section)
        end
    end)
end

local WARP_DETAIL_FORMATS = {
    friendly_friendly = _(
        "station-comms",
        "%s\n    WJ friendly to %s and WJ is friendly to %s = no reputation."
    ),
    friendly_neutral = _(
        "station-comms",
        "%s\n    WJ friendly to %s and WJ is neutral to %s = 5 reputation."
    ),
    friendly_enemy = _(
        "station-comms",
        "%s\n    WJ friendly to %s and WJ is enemy to %s = 10 reputation."
    ),
    neutral_friendly = _(
        "station-comms",
        "%s\n    WJ neutral to %s and WJ is friendly to %s = 10 reputation."
    ),
    enemy_friendly = _(
        "station-comms",
        "%s\n    WJ enemy to %s and WJ is friendly to %s = 15 reputation."
    ),
    neutral_neutral = _(
        "station-comms",
        "%s\n    WJ neutral to %s and WJ is neutral to %s = 20 reputation."
    ),
    enemy_neutral = _(
        "station-comms",
        "%s\n    WJ enemy to %s and WJ is neutral to %s = 20 reputation."
    ),
    neutral_enemy = _(
        "station-comms",
        "%s\n    WJ neutral to %s and WJ is enemy to %s = 25 reputation."
    ),
    enemy_enemy = _(
        "station-comms",
        "%s\n    WJ enemy to %s and WJ is enemy to %s = 100 reputation."
    ),
}

local function addWarpJammerDetails(profile)
    local context = profile.undocked.warp_jammer_details_context
        or "station-comms"
    addCommsReply(
        _(
            context,
            "Why do I have to pay reputation to log in to some of these warp jammers?"
        ),
        function()
            setCommsMessage(
                string.format(
                    _(
                        context,
                        "It's complicated. It depends on the relationships between the warp jammer owner, us, station %s and you, %s. The farther apart the relationship, the more reputation it costs to gain access. Do you want more details?"
                    ),
                    comms_target:getCallSign(),
                    commsSource(profile):getCallSign()
                )
            )
            addCommsReply(
                _("station-comms", "Yes, please provide more details"),
                function()
                    local out = _(
                        "station-comms",
                        "These are the cases and their reputation costs:"
                    )
                    for detail_index, key in
                        ipairs(profile.undocked.warp_jammer_detail_order)
                    do
                        out = string.format(
                            WARP_DETAIL_FORMATS[key],
                            out,
                            comms_target:getCallSign(),
                            commsSource(profile):getCallSign()
                        )
                    end
                    setCommsMessage(out)
                    addBack(profile)
                end
            )
            addBack(profile)
        end
    )
end

function M.addWarpJammers(profile)
    local accessible = {}
    if comms_target.warp_jammer_list ~= nil then
        for jammer_index, jammer in ipairs(comms_target.warp_jammer_list) do
            if jammer ~= nil and jammer:isValid() then
                table.insert(accessible, jammer)
            end
        end
    end
    for jammer_index, jammer in ipairs(warp_jammer_list or {}) do
        if jammer ~= nil and jammer:isValid() then
            local already_accessible = false
            for candidate_index, candidate in ipairs(accessible) do
                if candidate == jammer then
                    already_accessible = true
                    break
                end
            end
            if
                not already_accessible
                and distance(comms_target, jammer) < 30000
            then
                if
                    jammer:isFriendly(commsSource(profile))
                    or jammer:isFriendly(comms_target)
                    or not jammer:isEnemy(commsSource(profile))
                    or not jammer:isEnemy(comms_target)
                then
                    table.insert(accessible, jammer)
                end
            end
        end
    end
    if #accessible == 0 then
        return
    end
    addCommsReply(_("station-comms", "Connect to warp jammer"), function()
        setCommsMessage(
            _("station-comms", "Which one would you like to connect to?")
        )
        local pay_reputation = false
        for jammer_index, jammer in ipairs(accessible) do
            local cost = 0
            if jammer:isFriendly(comms_target) then
                if not jammer:isFriendly(commsSource(profile)) then
                    if jammer:isEnemy(commsSource(profile)) then
                        cost = 10
                    else
                        cost = 5
                    end
                end
            elseif jammer:isEnemy(comms_target) then
                if jammer:isFriendly(commsSource(profile)) then
                    cost = 15
                elseif jammer:isEnemy(commsSource(profile)) then
                    cost = 100
                else
                    cost = 20
                end
            elseif jammer:isFriendly(commsSource(profile)) then
                cost = 10
            elseif jammer:isEnemy(commsSource(profile)) then
                cost = 25
            else
                cost = 20
            end
            if cost > 0 then
                pay_reputation = true
            end
            local reputation_prompt = ""
            if cost > 0 then
                reputation_prompt =
                    string.format(_("station-comms", "(%i reputation)"), cost)
            end
            addCommsReply(
                string.format("%s %s", jammer:getCallSign(), reputation_prompt),
                function()
                    if commsSource(profile):takeReputationPoints(cost) then
                        setCommsMessage(
                            string.format(
                                _(
                                    "station-comms",
                                    "%s Automated warp jammer access menu"
                                ),
                                jammer:getCallSign()
                            )
                        )
                        addCommsReply(
                            _(
                                "station-comms",
                                "Reduce range to 1 unit for 1 minute"
                            ),
                            function()
                                jammer:setRange(1000)
                                jammer.reset_time = getScenarioTime() + 60
                                setCommsMessage(
                                    _(
                                        "station-comms",
                                        "Acknowledged. Range adjusted. Reset timer engaged."
                                    )
                                )
                                addBack(profile)
                            end
                        )
                        addCommsReply(
                            _(
                                "station-comms",
                                "Reduce range by 50% for 2 minutes"
                            ),
                            function()
                                jammer:setRange(jammer.range / 2)
                                jammer.reset_time = getScenarioTime() + 120
                                setCommsMessage(
                                    _(
                                        "station-comms",
                                        "Acknowledged. Range adjusted. Reset timer engaged."
                                    )
                                )
                                addBack(profile)
                            end
                        )
                        addCommsReply(
                            _(
                                "station-comms",
                                "Reduce range by 25% for 3 minutes"
                            ),
                            function()
                                jammer:setRange(jammer.range * 0.75)
                                jammer.reset_time = getScenarioTime() + 180
                                setCommsMessage(
                                    _(
                                        "station-comms",
                                        "Acknowledged. Range adjusted. Reset timer engaged."
                                    )
                                )
                                addBack(profile)
                            end
                        )
                    else
                        setCommsMessage(
                            _("needRep-comms", "Insufficient reputation")
                        )
                    end
                    if profile.undocked.warp_jammer_back then
                        addBack(profile)
                    end
                end
            )
        end
        if pay_reputation and profile.undocked.warp_jammer_details then
            addWarpJammerDetails(profile)
        end
        addBack(profile)
    end)
end

function M.cleanWarpJammers()
    local count_repeat_loop = 0
    repeat
        local deleted = false
        if warp_jammer_list ~= nil and #warp_jammer_list > 0 then
            for index, jammer in ipairs(warp_jammer_list) do
                if jammer == nil or not jammer:isValid() then
                    warp_jammer_list[index] =
                        warp_jammer_list[#warp_jammer_list]
                    warp_jammer_list[#warp_jammer_list] = nil
                    deleted = true
                    break
                end
            end
        end
        count_repeat_loop = count_repeat_loop + 1
    until not deleted or count_repeat_loop > max_repeat_loop
    if count_repeat_loop > max_repeat_loop then
        print("repeated too many times when cleaning warp jammer list")
    end
end

function M.supplyDrop(profile)
    if not serviceAllowed(profile, "supplydrop") then
        return
    end
    local options = profile.undocked.supply_drop or {}
    addCommsReply(
        string.format(
            options.label
                or _(
                    "stationAssist-comms",
                    "Can you send a supply drop? (%d rep)"
                ),
            StationCore.getServiceCost("supplydrop")
        ),
        function()
            if commsSource(profile):getWaypointCount() < 1 then
                setCommsMessage(
                    options.no_waypoint_message
                        or _(
                            "stationAssist-comms",
                            "You need to set a waypoint before you can request backup."
                        )
                )
            else
                setCommsMessage(
                    _(
                        "stationAssist-comms",
                        "To which waypoint should we deliver your supplies?"
                    )
                )
                for index = 1, commsSource(profile):getWaypointCount() do
                    local waypoint_id = waypointID(profile, index)
                    addCommsReply(
                        string.format(
                            options.waypoint_label
                                or _("stationAssist-comms", "WP %d"),
                            waypoint_id
                        ),
                        function()
                            if
                                commsSource(profile):takeReputationPoints(
                                    StationCore.getServiceCost("supplydrop")
                                )
                            then
                                local position_x, position_y =
                                    comms_target:getPosition()
                                local target_x, target_y =
                                    commsSource(profile):getWaypoint(index)
                                local script = Script()
                                script
                                    :setVariable("position_x", position_x)
                                    :setVariable("position_y", position_y)
                                    :setVariable("target_x", target_x)
                                    :setVariable("target_y", target_y)
                                    :setVariable(
                                        "faction_id",
                                        comms_target:getFactionId()
                                    )
                                if options.configure_script ~= nil then
                                    options.configure_script(script)
                                end
                                script:run("supply_drop.lua")
                                setCommsMessage(
                                    string.format(
                                        options.dispatch_message
                                            or _(
                                                "stationAssist-comms",
                                                "We have dispatched a supply ship toward WP %d"
                                            ),
                                        waypoint_id
                                    )
                                )
                            else
                                setCommsMessage(
                                    options.insufficient_message
                                        or _(
                                            "needRep-comms",
                                            "Not enough reputation!"
                                        )
                                )
                            end
                            addBack(profile)
                        end
                    )
                end
            end
            addBack(profile)
        end
    )
end

function M.reinforcements(profile)
    local definitions = profile.undocked.reinforcements
        or {
            {
                service = "reinforcements",
                label = _(
                    "stationAssist-comms",
                    "Please send reinforcements! (%d rep)"
                ),
            },
        }
    for definition_index, definition in ipairs(definitions) do
        local service = definition.service or "reinforcements"
        if serviceAllowed(profile, definition.permission or service) then
            addCommsReply(
                string.format(
                    definition.label
                        or _(
                            "stationAssist-comms",
                            "Please send reinforcements! (%d rep)"
                        ),
                    StationCore.getServiceCost(service)
                ),
                function()
                    if commsSource(profile):getWaypointCount() < 1 then
                        setCommsMessage(
                            definition.no_waypoint_message
                                or _(
                                    "stationAssist-comms",
                                    "You need to set a waypoint before you can request reinforcements."
                                )
                        )
                    else
                        setCommsMessage(
                            definition.prompt
                                or _(
                                    "stationAssist-comms",
                                    "To which waypoint should we dispatch the reinforcements?"
                                )
                        )
                        for index = 1, commsSource(profile):getWaypointCount() do
                            local waypoint_id = waypointID(profile, index)
                            addCommsReply(
                                string.format(
                                    definition.waypoint_label
                                        or _("stationAssist-comms", "WP %d"),
                                    waypoint_id
                                ),
                                function()
                                    local blocked_message
                                    if definition.waypoint_check ~= nil then
                                        blocked_message =
                                            definition.waypoint_check(index)
                                    end
                                    if blocked_message ~= nil then
                                        setCommsMessage(blocked_message)
                                    elseif
                                        commsSource(profile):takeReputationPoints(
                                            StationCore.getServiceCost(service)
                                        )
                                    then
                                        local ship
                                        if definition.spawn ~= nil then
                                            ship = definition.spawn(index)
                                        else
                                            ship = CpuShip()
                                                :setPosition(
                                                    comms_target:getPosition()
                                                )
                                                :setTemplate(
                                                    definition.template
                                                        or ST.ADDER_MK5
                                                )
                                                :setScanned(true)
                                                :orderDefendLocation(
                                                    commsSource(profile):getWaypoint(
                                                        index
                                                    )
                                                )
                                            ship:setFactionId(
                                                comms_target:getFactionId()
                                            )
                                            if
                                                definition.call_sign ~= false
                                            then
                                                ship:setCallSign(
                                                    generateCallSign(
                                                        nil,
                                                        "Human Navy"
                                                    )
                                                )
                                            end
                                            if definition.comms ~= false then
                                                ship:setCommsScript("")
                                                    :setCommsFunction(commsShip)
                                            end
                                            if
                                                definition.destruction ~= false
                                            then
                                                ship:onDestruction(
                                                    definition.destruction
                                                        or friendlyVesselDestroyed
                                                )
                                            end
                                            if definition.on_spawn ~= nil then
                                                definition.on_spawn(ship)
                                            end
                                        end
                                        setCommsMessage(
                                            string.format(
                                                definition.success_message
                                                    or _(
                                                        "stationAssist-comms",
                                                        "We have dispatched %s to assist at WP %d"
                                                    ),
                                                ship:getCallSign(),
                                                waypoint_id
                                            )
                                        )
                                    else
                                        setCommsMessage(
                                            definition.insufficient_message
                                                or _(
                                                    "needRep-comms",
                                                    "Not enough reputation!"
                                                )
                                        )
                                    end
                                    addBack(profile)
                                end
                            )
                        end
                    end
                    addBack(profile)
                end
            )
        end
    end
end

local function serviceJonqueData()
    return {
        friendlyness = random(0.0, 100.0),
        weapons = {
            Homing = comms_target.comms_data.weapons.Homing,
            HVLI = comms_target.comms_data.weapons.HVLI,
            Mine = comms_target.comms_data.weapons.Mine,
            Nuke = comms_target.comms_data.weapons.Nuke,
            EMP = comms_target.comms_data.weapons.EMP,
        },
        weapon_cost = {
            Homing = comms_target.comms_data.weapon_cost.Homing * 2,
            HVLI = comms_target.comms_data.weapon_cost.HVLI * 2,
            Mine = comms_target.comms_data.weapon_cost.Mine * 2,
            Nuke = comms_target.comms_data.weapon_cost.Nuke * 2,
            EMP = comms_target.comms_data.weapon_cost.EMP * 2,
        },
        weapon_inventory = {
            Homing = 40,
            HVLI = 40,
            Mine = 20,
            Nuke = 10,
            EMP = 10,
        },
        weapon_inventory_max = {
            Homing = 40,
            HVLI = 40,
            Mine = 20,
            Nuke = 10,
            EMP = 10,
        },
        reputation_cost_multipliers = {
            friend = comms_target.comms_data.reputation_cost_multipliers.friend,
            neutral = math.max(
                comms_target.comms_data.reputation_cost_multipliers.friend,
                comms_target.comms_data.reputation_cost_multipliers.neutral / 2
            ),
        },
    }
end

function M.serviceJonque(profile)
    if not serviceAllowed(profile, "servicejonque") then
        return
    end
    addCommsReply(
        _("stationAssist-comms", "Please send a service jonque for repairs"),
        function()
            local out = string.format(
                _(
                    "stationAssist-comms",
                    "Would you like the service jonque to come to you directly or would you prefer to set up a rendezvous via a waypoint? Either way, you will need %.1f reputation."
                ),
                StationCore.getServiceCost("servicejonque")
            )
            addCommsReply("Direct", function()
                if
                    commsSource(profile):takeReputationPoints(
                        StationCore.getServiceCost("servicejonque")
                    )
                then
                    local ship = serviceJonque(comms_target:getFaction())
                        :setPosition(comms_target:getPosition())
                        :setCallSign(
                            generateCallSign(nil, comms_target:getFaction())
                        )
                        :setScanned(true)
                        :orderDefendTarget(commsSource(profile))
                    ship.comms_data = serviceJonqueData()
                    setCommsMessage(
                        string.format(
                            _(
                                "stationAssist-comms",
                                "We have dispatched %s to come to you to help with repairs"
                            ),
                            ship:getCallSign()
                        )
                    )
                else
                    setCommsMessage(
                        _("needRep-comms", "Not enough reputation!")
                    )
                end
            end)
            if commsSource(profile):getWaypointCount() < 1 then
                out = out
                    .. _(
                        "stationAssist-comms",
                        "\n\nNote: if you want to use a waypoint, you will have to back out and set one and come back."
                    )
            else
                for index = 1, commsSource(profile):getWaypointCount() do
                    local waypoint_id = waypointID(profile, index)
                    addCommsReply(
                        string.format(
                            _(
                                "stationAssist-comms",
                                "Rendezvous at waypoint %d"
                            ),
                            waypoint_id
                        ),
                        function()
                            if
                                commsSource(profile):takeReputationPoints(
                                    StationCore.getServiceCost("servicejonque")
                                )
                            then
                                local ship =
                                    serviceJonque(comms_target:getFaction())
                                        :setPosition(comms_target:getPosition())
                                        :setCallSign(
                                            generateCallSign(
                                                nil,
                                                comms_target:getFaction()
                                            )
                                        )
                                        :setScanned(true)
                                        :orderDefendLocation(
                                            commsSource(profile):getWaypoint(
                                                index
                                            )
                                        )
                                ship.comms_data = serviceJonqueData()
                                setCommsMessage(
                                    string.format(
                                        _(
                                            "stationAssist-comms",
                                            "We have dispatched %s to rendezvous at waypoint %d"
                                        ),
                                        ship:getCallSign(),
                                        waypoint_id
                                    )
                                )
                            else
                                setCommsMessage(
                                    _("needRep-comms", "Not enough reputation!")
                                )
                            end
                            addBack(profile)
                        end
                    )
                end
            end
            setCommsMessage(out)
            addBack(profile)
        end
    )
end

function M.addDefenseFleet(profile)
    local options = profile.docked.defense_fleet or {}
    local service = options.service or "activatedefensefleet"
    local fleet = comms_target.comms_data.idle_defense_fleet
    if not serviceAllowed(service) or fleet == nil then
        return
    end
    local fleet_count = 0
    for _ in pairs(fleet) do
        fleet_count = fleet_count + 1
    end
    if fleet_count == 0 then
        return
    end
    local label = options.label
    if label == nil then
        label = "Activate station defense fleet ("
            .. StationCore.getServiceCost(service)
            .. " rep)"
    end
    addCommsReply(label, function()
        if
            comms_source:takeReputationPoints(
                StationCore.getServiceCost(service)
            )
        then
            local out =
                string.format("%s defense fleet\n", comms_target:getCallSign())
            for name, template in pairs(fleet) do
                local script = Script()
                local position_x, position_y = comms_target:getPosition()
                local station_name = comms_target:getCallSign()
                script
                    :setVariable("position_x", position_x)
                    :setVariable("position_y", position_y)
                script:setVariable("station_name", station_name)
                script:setVariable("name", name)
                script:setVariable("template", template)
                script:setVariable("faction_id", comms_target:getFactionId())
                script:run(options.script_name or "border_defend_station.lua")
                out = out .. " " .. name
                fleet[name] = nil
            end
            out = out .. "\nactivated"
            setCommsMessage(out)
        else
            setCommsMessage(_("needRep-comms", "Insufficient reputation"))
        end
        addBack(profile)
    end)
end

function M.cartography(profile)
    Cartography.office(profile)
end

function M.assistance(profile)
    M.supplyDrop(profile)
    M.reinforcements(profile)
    M.serviceJonque(profile)
end

function M.undocked(profile)
    M.undockedGreeting(profile)
    if profile.undocked.before_information ~= nil then
        profile.undocked.before_information()
    end
    if profile.undocked.cleanup_warp_jammers then
        M.cleanWarpJammers()
    end
    if profile.undocked.warp_jammers ~= false then
        M.addWarpJammers(profile)
    end
    if profile.undocked.information ~= nil then
        M.information(profile, profile.undocked.information)
    end
    if profile.undocked.after_information ~= nil then
        profile.undocked.after_information()
    end
    if profile.undocked.before_assistance ~= nil then
        profile.undocked.before_assistance()
    end
    if type(profile.undocked.assistance) == "function" then
        profile.undocked.assistance()
    elseif profile.undocked.assistance then
        M.assistance(profile)
    end
    if profile.undocked.after_assistance ~= nil then
        profile.undocked.after_assistance()
    end
end

return M
