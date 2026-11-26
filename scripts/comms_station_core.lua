-- Core shared station communication helpers.

local M = {}

function M.getSource(profile)
    if profile ~= nil and profile.source ~= nil then
        return profile.source()
    end
    return comms_source
end

function M.ensureWeaponAvailability(options)
    if options == nil then
        return
    end
    local data = comms_target.comms_data
    data.weapon_available = data.weapon_available or {}
    for weapon, threshold in pairs(options) do
        if weapon ~= "always" and data.weapon_available[weapon] == nil then
            local forced
            if options.always ~= nil then
                forced = options.always(weapon)
            end
            if forced ~= nil then
                data.weapon_available[weapon] = forced
            else
                data.weapon_available[weapon] = random(1, 10)
                    <= threshold - difficulty
            end
        end
    end
end

local function mergeStationDefaults()
    mergeTables(comms_target.comms_data, {
        friendlyness = random(0.0, 100.0),
        weapons = {
            Homing = "neutral",
            HVLI = "neutral",
            Mine = "neutral",
            Nuke = "friend",
            EMP = "friend",
        },
        weapon_cost = {
            Homing = math.random(1, 4),
            HVLI = math.random(1, 3),
            Mine = math.random(2, 5),
            Nuke = math.random(12, 18),
            EMP = math.random(7, 13),
        },
        services = {
            supplydrop = "friend",
            reinforcements = "friend",
            preorder = "friend",
            activatedefensefleet = "neutral",
        },
        service_cost = {
            supplydrop = math.random(80, 120),
            reinforcements = math.random(125, 175),
            activatedefensefleet = 20,
        },
        reputation_cost_multipliers = {
            friend = 1.0,
            neutral = 3.0,
        },
        max_weapon_refill_amount = {
            friend = 1.0,
            neutral = 0.5,
        },
    })
end

local function mergeStationDefaultsPreservingRng()
    local data = comms_target.comms_data
    local friendlyness = random(0.0, 100.0)
    if data.friendlyness == nil then
        data.friendlyness = friendlyness
    end
    if data.weapons == nil then
        data.weapons = {
            Homing = "neutral",
            HVLI = "neutral",
            Mine = "neutral",
            Nuke = "friend",
            EMP = "friend",
        }
    end
    if data.weapon_cost == nil then
        data.weapon_cost = {
            Homing = math.random(1, 4),
            HVLI = math.random(1, 3),
            Mine = math.random(2, 5),
            Nuke = math.random(12, 18),
            EMP = math.random(7, 13),
        }
    end
    if data.services == nil then
        data.services = {
            supplydrop = "friend",
            reinforcements = "friend",
            preorder = "friend",
            activatedefensefleet = "neutral",
        }
    end
    if data.service_cost == nil then
        data.service_cost = {
            supplydrop = math.random(80, 120),
            reinforcements = math.random(125, 175),
            activatedefensefleet = 20,
        }
    end
    if data.reputation_cost_multipliers == nil then
        data.reputation_cost_multipliers = {
            friend = 1.0,
            neutral = 3.0,
        }
    end
    if data.max_weapon_refill_amount == nil then
        data.max_weapon_refill_amount = {
            friend = 1.0,
            neutral = 0.5,
        }
    end
end

function M.commsStation(profile, source_argument, target_argument)
    profile = profile or {}
    if comms_source == nil and source_argument ~= nil then
        comms_source = source_argument
    end
    if comms_target == nil and target_argument ~= nil then
        comms_target = target_argument
    end
    if comms_target == nil then
        print("commsStation called without a comms target")
        return false
    end
    if comms_target.comms_data == nil then
        comms_target.comms_data = {}
    end
    if profile.data ~= nil then
        mergeTables(comms_target.comms_data, profile.data)
    end
    if profile.preserve_rng then
        mergeStationDefaultsPreservingRng()
    else
        mergeStationDefaults()
    end
    comms_data = comms_target.comms_data
    if profile.prepare ~= nil then
        profile.prepare()
    end
    M.ensureWeaponAvailability(profile.weapon_availability)
    local source = M.getSource(profile)
    if source:isEnemy(comms_target) then
        return false
    end
    local under_attack = profile.under_attack
    if under_attack == nil then
        under_attack = function()
            return comms_target:areEnemiesInRange(5000)
        end
    end
    if under_attack(source) then
        setCommsMessage(
            _("station-comms", "We are under attack! No time for chatting!")
        )
        return true
    end
    if profile.docked ~= nil and profile.undocked ~= nil then
        if not source:isDocked(comms_target) then
            profile.undocked()
        else
            profile.docked()
        end
    elseif not source:isDocked(comms_target) then
        handleUndockedState()
    else
        handleDockedState()
    end
    return true
end

local function immediateRepairCrew(relationship, options, profile)
    local source = M.getSource(profile)
    if options.available ~= nil and not options.available(relationship) then
        return
    end
    local hire_cost
    local max_repair_crew = source.maxRepairCrew or source.max_repair_crew
    if
        max_repair_crew == nil
        or source:getRepairCrewCount() < max_repair_crew
    then
        if relationship == "friendly" then
            hire_cost = math.random(30, 60)
        else
            hire_cost = math.random(45, 90)
        end
    else
        if relationship == "friendly" then
            hire_cost = math.random(45, 90)
        else
            hire_cost = math.random(60, 120)
        end
    end
    addCommsReply(
        string.format(
            _("trade-comms", "Recruit repair crew member for %i reputation"),
            hire_cost
        ),
        function()
            if not source:takeReputationPoints(hire_cost) then
                setCommsMessage(_("needRep-comms", "Insufficient reputation"))
            else
                source:setRepairCrewCount(source:getRepairCrewCount() + 1)
                if options.on_hire ~= nil then
                    options.on_hire(source, hire_cost)
                end
                setCommsMessage(_("trade-comms", "Repair crew member hired"))
            end
            if options.back ~= false then
                addCommsReply(_("Back"), commsStation)
            end
        end
    )
end

local function legacyRepairCrew(relationship, options)
    if options.available ~= nil and not options.available(relationship) then
        return
    end
    local hire_cost
    if relationship == "friendly" then
        hire_cost = math.random(45, 90)
        if comms_source:getRepairCrewCount() < comms_source.maxRepairCrew then
            hire_cost = math.random(30, 60)
        end
    else
        hire_cost = math.random(60, 120)
        if comms_source:getRepairCrewCount() < comms_source.maxRepairCrew then
            hire_cost = math.random(45, 90)
        end
    end
    addCommsReply(
        string.format(
            _("trade-comms", "Recruit repair crew member for %i reputation"),
            hire_cost
        ),
        function()
            if not comms_source:takeReputationPoints(hire_cost) then
                setCommsMessage(_("needRep-comms", "Insufficient reputation"))
            else
                comms_source:setRepairCrewCount(
                    comms_source:getRepairCrewCount() + 1
                )
                setCommsMessage(_("trade-comms", "Repair crew member hired"))
            end
            if options.back ~= false then
                addCommsReply(_("Back"), commsStation)
            end
        end
    )
end

function M.getRepairCrewFromStation(relationship, options, profile)
    local source = M.getSource(profile)
    if options ~= nil and options.mode == "immediate" then
        immediateRepairCrew(relationship, options, profile)
        return
    end
    if options ~= nil and options.mode == "legacy" then
        legacyRepairCrew(relationship, options)
        return
    end
    addCommsReply(_("trade-comms", "Recruit repair crew member"), function()
        if comms_target.comms_data.available_repair_crew == nil then
            comms_target.comms_data.available_repair_crew = math.random(0, 3)
        end
        if comms_target.comms_data.available_repair_crew > 0 then --station has repair crew available
            if comms_target.comms_data.crew_available_delay == nil then
                comms_target.comms_data.crew_available_delay = 0
            end
            if
                getScenarioTime() > comms_target.comms_data.crew_available_delay
            then --no delay in progress
                if random(1, 5) <= (3 - difficulty) then --repair crew available
                    local hire_cost = math.random(45, 90)
                    if relationship ~= "friendly" then
                        hire_cost = math.random(60, 120)
                    end
                    if source:getRepairCrewCount() < source.maxRepairCrew then
                        hire_cost = math.random(30, 60)
                        if relationship ~= "friendly" then
                            hire_cost = math.random(45, 90)
                        end
                    end
                    setCommsMessage(
                        _(
                            "trade-comms",
                            "We have a repair crew candidate for you to consider"
                        )
                    )
                    addCommsReply(
                        string.format(
                            _(
                                "trade-comms",
                                "Recruit repair crew member for %i reputation"
                            ),
                            hire_cost
                        ),
                        function()
                            if not source:isDocked(comms_target) then
                                setCommsMessage(
                                    _(
                                        "station-comms",
                                        "You need to stay docked for that action."
                                    )
                                )
                                return
                            end
                            if not source:takeReputationPoints(hire_cost) then
                                setCommsMessage(
                                    _(
                                        "needRep-comms",
                                        "Insufficient reputation"
                                    )
                                )
                            else
                                source:setRepairCrewCount(
                                    source:getRepairCrewCount() + 1
                                )
                                if options.on_hire ~= nil then
                                    options.on_hire(source, hire_cost)
                                end
                                comms_target.comms_data.available_repair_crew = comms_target.comms_data.available_repair_crew
                                    - 1
                                if
                                    comms_target.comms_data.available_repair_crew
                                    <= 0
                                then
                                    comms_target.comms_data.new_repair_crew_delay = getScenarioTime()
                                        + random(200, 500)
                                end
                                setCommsMessage(
                                    _("trade-comms", "Repair crew member hired")
                                )
                            end
                            addCommsReply(_("Back"), commsStation)
                        end
                    )
                else --repair crew delayed
                    local delay_reason = {
                        _(
                            "trade-comms",
                            "A possible repair recruit is awaiting final certification. They should be available in "
                        ),
                        _(
                            "trade-comms",
                            "There's one repair crew candidate completing their license application. They should be available in "
                        ),
                        _(
                            "trade-comms",
                            "One repair crew should be getting here from their medical checkout in "
                        ),
                    }
                    local delay_seconds = math.random(10, 30)
                    comms_target.comms_data.crew_available_delay = getScenarioTime()
                        + delay_seconds
                    comms_target.comms_data.crew_available_delay_reason =
                        delay_reason[math.random(1, #delay_reason)]
                    setCommsMessage(
                        string.format(
                            _("trade-comms", "%s %i seconds"),
                            comms_target.comms_data.crew_available_delay_reason,
                            delay_seconds
                        )
                    )
                end
            else --delay in progress
                local delay_seconds = math.floor(
                    comms_target.comms_data.crew_available_delay
                        - getScenarioTime()
                )
                if delay_seconds > 1 then
                    setCommsMessage(
                        string.format(
                            _("trade-comms", "%s %i seconds"),
                            comms_target.comms_data.crew_available_delay_reason,
                            delay_seconds
                        )
                    )
                else
                    setCommsMessage(
                        string.format(
                            _("trade-comms", "%s a second"),
                            comms_target.comms_data.crew_available_delay_reason
                        )
                    )
                end
            end
        else --station does not have repair crew available
            if comms_target.comms_data.new_repair_crew_delay == nil then
                comms_target.comms_data.new_repair_crew_delay = 0
            end
            if
                getScenarioTime()
                > comms_target.comms_data.new_repair_crew_delay
            then
                comms_target.comms_data.available_repair_crew =
                    math.random(1, 3)
                local delay_reason = {
                    _(
                        "trade-comms",
                        "A possible repair recruit is awaiting final certification. They should be available in "
                    ),
                    _(
                        "trade-comms",
                        "There's one repair crew candidate completing their license application. They should be available in "
                    ),
                    _(
                        "trade-comms",
                        "One repair crew should be getting here from their medical checkout in "
                    ),
                }
                local delay_seconds = math.random(10, 30)
                comms_target.comms_data.crew_available_delay = getScenarioTime()
                    + delay_seconds
                comms_target.comms_data.crew_available_delay_reason =
                    delay_reason[math.random(1, #delay_reason)]
                setCommsMessage(
                    string.format(
                        _(
                            "trade-comms",
                            "Several arrived on station earlier. %s %i seconds"
                        ),
                        comms_target.comms_data.crew_available_delay_reason,
                        delay_seconds
                    )
                )
            else
                local delay_time = math.floor(
                    comms_target.comms_data.new_repair_crew_delay
                        - getScenarioTime()
                )
                local delay_minutes = math.floor(delay_time / 60)
                local delay_seconds = math.floor(delay_time % 60)
                local delay_status =
                    string.format(_("trade-comms", "%i seconds"), delay_seconds)
                if delay_seconds == 1 then
                    delay_status = string.format(
                        _("trade-comms", "%i second"),
                        delay_seconds
                    )
                end
                if delay_minutes > 0 then
                    if delay_minutes > 1 then
                        delay_status = string.format(
                            _("trade-comms", "%i minutes and %s"),
                            delay_minutes,
                            delay_status
                        )
                    else
                        delay_status = string.format(
                            _("trade-comms", "%i minute and %s"),
                            delay_minutes,
                            delay_status
                        )
                    end
                end
                setCommsMessage(
                    string.format(
                        _(
                            "trade-comms",
                            "There are some repair crew recruits in route for %s. Travel time remaining is %s."
                        ),
                        comms_target:getCallSign(),
                        delay_status
                    )
                )
            end
        end
        addCommsReply(_("Back"), commsStation)
    end)
end

local function immediateCoolant(relationship, options, profile)
    local source = M.getSource(profile)
    if source.initialCoolant == nil then
        return
    end
    if options.available ~= nil and not options.available(relationship) then
        return
    end
    local coolant_cost
    if relationship == "friendly" then
        coolant_cost = math.random(45, 90)
    else
        coolant_cost = math.random(60, 120)
    end
    if source:getMaxCoolant() < source.initialCoolant then
        if relationship == "friendly" then
            coolant_cost = math.random(30, 60)
        else
            coolant_cost = math.random(45, 90)
        end
    end
    local amount = 2
    if options.amount ~= nil then
        amount = options.amount(relationship)
    end
    addCommsReply(
        string.format(
            _("trade-comms", "Purchase coolant for %i reputation"),
            coolant_cost
        ),
        function()
            if not source:takeReputationPoints(coolant_cost) then
                setCommsMessage(_("needRep-comms", "Insufficient reputation"))
            else
                source:setMaxCoolant(source:getMaxCoolant() + amount)
                if options.on_purchase ~= nil then
                    options.on_purchase(source, coolant_cost, amount)
                end
                setCommsMessage(
                    _("trade-comms", "Additional coolant purchased")
                )
            end
            if options.back ~= false then
                addCommsReply(_("Back"), commsStation)
            end
        end
    )
end

local function legacyCoolant(relationship, options)
    if comms_source.initialCoolant == nil then
        return
    end
    if options.available ~= nil and not options.available(relationship) then
        return
    end
    local coolant_cost
    if relationship == "friendly" then
        coolant_cost = math.random(45, 90)
        if comms_source:getMaxCoolant() < comms_source.initialCoolant then
            coolant_cost = math.random(30, 60)
        end
    else
        coolant_cost = math.random(60, 120)
        if comms_source:getMaxCoolant() < comms_source.initialCoolant then
            coolant_cost = math.random(45, 90)
        end
    end
    addCommsReply(
        string.format(
            _("trade-comms", "Purchase coolant for %i reputation"),
            coolant_cost
        ),
        function()
            if not comms_source:takeReputationPoints(coolant_cost) then
                setCommsMessage(_("needRep-comms", "Insufficient reputation"))
            else
                comms_source:setMaxCoolant(comms_source:getMaxCoolant() + 2)
                setCommsMessage(
                    _("trade-comms", "Additional coolant purchased")
                )
            end
            if options.back ~= false then
                addCommsReply(_("Back"), commsStation)
            end
        end
    )
end

function M.getCoolantFromStation(relationship, options, profile)
    local source = M.getSource(profile)
    if options ~= nil and options.mode == "immediate" then
        immediateCoolant(relationship, options, profile)
        return
    end
    if options ~= nil and options.mode == "legacy" then
        legacyCoolant(relationship, options)
        return
    end
    if source.initialCoolant ~= nil then
        addCommsReply(_("trade-comms", "Purchase Coolant"), function()
            if comms_target.comms_data.coolant_inventory == nil then
                comms_target.comms_data.coolant_inventory = math.random(0, 3)
                    * 2
            end
            if comms_target.comms_data.coolant_inventory > 0 then --station has coolant
                if comms_target.comms_data.coolant_packaging_delay == nil then
                    comms_target.comms_data.coolant_packaging_delay = 0
                end
                if
                    getScenarioTime()
                    > comms_target.comms_data.coolant_packaging_delay
                then --no delay
                    if math.random(1, 5) <= (3 - difficulty) then
                        local coolantCost = math.random(45, 90)
                        if relationship ~= "friendly" then
                            coolantCost = math.random(60, 120)
                        end
                        if source:getMaxCoolant() < source.initialCoolant then
                            coolantCost = math.random(30, 60)
                            if relationship ~= "friendly" then
                                coolantCost = math.random(45, 90)
                            end
                        end
                        setCommsMessage(
                            _(
                                "trade-comms",
                                "We've got some coolant available for you"
                            )
                        )
                        addCommsReply(
                            string.format(
                                _(
                                    "trade-comms",
                                    "Purchase coolant for %i reputation"
                                ),
                                coolantCost
                            ),
                            function()
                                if not source:isDocked(comms_target) then
                                    setCommsMessage(
                                        _(
                                            "station-comms",
                                            "You need to stay docked for that action."
                                        )
                                    )
                                    return
                                end
                                if
                                    not source:takeReputationPoints(coolantCost)
                                then
                                    setCommsMessage(
                                        _(
                                            "needRep-comms",
                                            "Insufficient reputation"
                                        )
                                    )
                                else
                                    source:setMaxCoolant(
                                        source:getMaxCoolant() + 2
                                    )
                                    comms_target.comms_data.coolant_inventory = comms_target.comms_data.coolant_inventory
                                        - 2
                                    if
                                        comms_target.comms_data.coolant_inventory
                                        <= 0
                                    then
                                        comms_target.comms_data.coolant_inventory_delay = getScenarioTime()
                                            + random(60, 300)
                                    end
                                    setCommsMessage(
                                        _(
                                            "trade-comms",
                                            "Additional coolant purchased"
                                        )
                                    )
                                end
                                addCommsReply(_("Back"), commsStation)
                            end
                        )
                    else
                        local delay_seconds = math.random(3, 20)
                        comms_target.comms_data.coolant_packaging_delay = getScenarioTime()
                            + delay_seconds
                        setCommsMessage(
                            string.format(
                                _(
                                    "trade-comms",
                                    "The coolant preparation facility is having difficulty packaging the coolant for transport. They say they should have it working in about %i seconds"
                                ),
                                delay_seconds
                            )
                        )
                    end
                else --delay in progress
                    local delay_seconds = math.floor(
                        comms_target.comms_data.coolant_packaging_delay
                            - getScenarioTime()
                    )
                    if delay_seconds > 1 then
                        setCommsMessage(
                            string.format(
                                _(
                                    "trade-comms",
                                    "The coolant preparation facility is having difficulty packaging the coolant for transport. They say they should have it working in about %i seconds"
                                ),
                                delay_seconds
                            )
                        )
                    else
                        setCommsMessage(
                            _(
                                "trade-comms",
                                "The coolant preparation facility is having difficulty packaging the coolant for transportation. They say they should have it working in a second"
                            )
                        )
                    end
                end
            else --station is out of coolant
                if comms_target.comms_data.coolant_inventory_delay == nil then
                    comms_target.comms_data.coolant_inventory_delay = 0
                end
                if
                    getScenarioTime()
                    > comms_target.comms_data.coolant_inventory_delay
                then
                    comms_target.comms_data.coolant_inventory = math.random(
                        1,
                        3
                    ) * 2
                    local delay_seconds = math.random(3, 20)
                    comms_target.comms_data.coolant_packaging_delay = getScenarioTime()
                        + delay_seconds
                    setCommsMessage(
                        string.format(
                            _(
                                "trade-comms",
                                "Our coolant production facility just made some, but it's not quite ready to be transported. The preparation facility says it should take about %i seconds"
                            ),
                            delay_seconds
                        )
                    )
                else
                    local delay_time = math.floor(
                        comms_target.comms_data.coolant_inventory_delay
                            - getScenarioTime()
                    )
                    local delay_minutes = math.floor(delay_time / 60)
                    local delay_seconds = math.floor(delay_time % 60)
                    local delay_status = string.format(
                        _("trade-comms", "%i seconds"),
                        delay_seconds
                    )
                    if delay_seconds == 1 then
                        delay_status = string.format(
                            _("trade-comms", "%i second"),
                            delay_seconds
                        )
                    end
                    if delay_minutes > 0 then
                        if delay_minutes > 1 then
                            delay_status = string.format(
                                _("trade-comms", "%i minutes and %s"),
                                delay_minutes,
                                delay_status
                            )
                        else
                            delay_status = string.format(
                                _("trade-comms", "%i minute and %s"),
                                delay_minutes,
                                delay_status
                            )
                        end
                    end
                    setCommsMessage(
                        string.format(
                            _(
                                "trade-comms",
                                "Our coolant production facility is making more right now. Coolant manufacturing time remaining is %s."
                            ),
                            delay_status
                        )
                    )
                end
            end
            addCommsReply(_("Back"), commsStation)
        end)
    end
end

function M.isAllowedTo(state, profile)
    local source = M.getSource(profile)
    if state == "friend" and source:isFriendly(comms_target) then
        return true
    end
    if state == "neutral" and not source:isEnemy(comms_target) then
        return true
    end
    return false
end

local function ordnanceOptions(profile)
    if profile ~= nil and profile.docked ~= nil then
        return profile.docked.ordnance or {}
    end
    return {}
end

local function restockScale(profile)
    local options = ordnanceOptions(profile)
    if options.refill_scale ~= nil then
        return options.refill_scale()
    end
    return 1
end

local function restockSuffix(profile)
    local options = ordnanceOptions(profile)
    if options.suffix ~= nil then
        return options.suffix() or ""
    end
    return ""
end

local function inventoryAvailable(weapon)
    local inventory = comms_data.weapon_inventory
    if inventory == nil or inventory.Unlimited then
        return nil
    end
    return math.floor(inventory[weapon] or 0)
end

local function inventoryStatus(weapon)
    local inventory = comms_data.weapon_inventory
    if inventory == nil or inventory.Unlimited then
        return ""
    end
    return string.format(
        _("ammo-comms", "\nStation inventory of %s type weapons reduced to %i"),
        weapon,
        math.floor(inventory[weapon] or 0)
    )
end

local function adjustInventory(weapon, amount)
    local inventory = comms_data.weapon_inventory
    if inventory ~= nil and not inventory.Unlimited then
        inventory[weapon] = math.max(0, (inventory[weapon] or 0) - amount)
    end
end

local function cannotRestockMessage(weapon, suffix)
    if weapon == "Nuke" then
        return _(
            "ammo-comms",
            "All nukes are charged and primed for destruction."
        ) .. suffix
    end
    return _(
        "ammo-comms",
        "Sorry, sir, but you are as fully stocked as I can allow."
    ) .. suffix
end

local function restockedMessage(source, weapon, suffix)
    if
        source:getWeaponStorage(weapon) == source:getWeaponStorageMax(weapon)
    then
        return _(
            "ammo-comms",
            "You are fully loaded and ready to explode things."
        ) .. suffix
    end
    return _(
        "ammo-comms",
        "We generously resupplied you with some weapon charges.\nPut them to good use."
    ) .. suffix
end

function M.handleWeaponRestock(weapon, profile)
    local source = M.getSource(profile)
    if not source:isDocked(comms_target) then
        setCommsMessage(
            _("station-comms", "You need to stay docked for that action.")
        )
        return
    end
    if not M.isAllowedTo(comms_data.weapons[weapon], profile) then
        if weapon == "Nuke" then
            setCommsMessage(
                _(
                    "ammo-comms",
                    "We do not deal in weapons of mass destruction."
                )
            )
        elseif weapon == "EMP" then
            setCommsMessage(
                _("ammo-comms", "We do not deal in weapons of mass disruption.")
            )
        else
            setCommsMessage(_("ammo-comms", "We do not deal in those weapons."))
        end
        return
    end
    local suffix = restockSuffix(profile)
    local points_per_item = M.getWeaponCost(weapon, profile)
    local requested = math.floor(
        source:getWeaponStorageMax(weapon)
            * comms_data.max_weapon_refill_amount[M.getFriendStatus(profile)]
            * restockScale(profile)
    ) - source:getWeaponStorage(weapon)
    local available = inventoryAvailable(weapon)
    local item_amount = requested
    if available ~= nil then
        item_amount = math.min(item_amount, available)
    end
    if item_amount <= 0 then
        setCommsMessage(cannotRestockMessage(weapon, suffix))
        addCommsReply(_("Back"), commsStation)
        return
    end
    local can_afford = source:getReputationPoints()
        > points_per_item * item_amount
    local stock_sufficient = available == nil or available >= requested
    if can_afford and stock_sufficient then
        if not source:takeReputationPoints(points_per_item * item_amount) then
            setCommsMessage(_("needRep-comms", "Not enough reputation."))
            return
        end
        source:setWeaponStorage(
            weapon,
            source:getWeaponStorage(weapon) + item_amount
        )
        adjustInventory(weapon, item_amount)
        setCommsMessage(
            restockedMessage(source, weapon, suffix) .. inventoryStatus(weapon)
        )
        addCommsReply(_("Back"), commsStation)
        return
    end
    if source:getReputationPoints() > points_per_item and item_amount > 0 then
        setCommsMessage(
            _("ammo-comms", "You can't afford as much as I'd like to give you")
        )
        addCommsReply(_("ammo-comms", "Get just one"), function()
            if source:takeReputationPoints(points_per_item) then
                source:setWeaponStorage(
                    weapon,
                    source:getWeaponStorage(weapon) + 1
                )
                adjustInventory(weapon, 1)
                setCommsMessage(
                    restockedMessage(source, weapon, suffix)
                        .. inventoryStatus(weapon)
                )
            else
                setCommsMessage(_("needRep-comms", "Not enough reputation."))
            end
            return
        end)
        addCommsReply(_("Back"), commsStation)
        return
    end
    setCommsMessage(_("needRep-comms", "Not enough reputation."))
end

function M.getWeaponCost(weapon, profile)
    return math.ceil(
        comms_data.weapon_cost[weapon]
            * comms_data.reputation_cost_multipliers[M.getFriendStatus(profile)]
    )
end

function M.getCartographerCost(service)
    local base_cost = 1
    if service == "apprentice" then
        base_cost = 5
    elseif service == "master" then
        base_cost = 10
    end
    return math.ceil(
        base_cost * comms_data.reputation_cost_multipliers[M.getFriendStatus()]
    )
end

function M.getServiceCost(service)
    -- Return the number of reputation points that a specified service costs for
    -- the current player.
    return math.ceil(comms_data.service_cost[service])
end

function M.getFriendStatus(profile)
    local source = M.getSource(profile)
    if source:isFriendly(comms_target) then
        return "friend"
    else
        return "neutral"
    end
end

function M.handleWeaponRestockSimple(weapon, profile)
    local source = M.getSource(profile)
    if not source:isDocked(comms_target) then
        setCommsMessage(
            _("station-comms", "You need to stay docked for that action.")
        )
        return
    end
    if not M.isAllowedTo(comms_data.weapons[weapon], profile) then
        if weapon == "Nuke" then
            setCommsMessage(
                _(
                    "ammo-comms",
                    "We do not deal in weapons of mass destruction."
                )
            )
        elseif weapon == "EMP" then
            setCommsMessage(
                _("ammo-comms", "We do not deal in weapons of mass disruption.")
            )
        else
            setCommsMessage(_("ammo-comms", "We do not deal in those weapons."))
        end
        return
    end
    local suffix = restockSuffix(profile)
    local points_per_item = M.getWeaponCost(weapon, profile)
    local item_amount = math.floor(
        source:getWeaponStorageMax(weapon)
            * comms_data.max_weapon_refill_amount[M.getFriendStatus(profile)]
            * restockScale(profile)
    ) - source:getWeaponStorage(weapon)
    local available = inventoryAvailable(weapon)
    if available ~= nil then
        item_amount = math.min(item_amount, available)
    end
    if item_amount <= 0 then
        setCommsMessage(cannotRestockMessage(weapon, suffix))
        addCommsReply(_("Back"), commsStation)
    else
        if not source:takeReputationPoints(points_per_item * item_amount) then
            setCommsMessage(_("needRep-comms", "Not enough reputation."))
            return
        end
        source:setWeaponStorage(
            weapon,
            source:getWeaponStorage(weapon) + item_amount
        )
        adjustInventory(weapon, item_amount)
        setCommsMessage(
            restockedMessage(source, weapon, suffix) .. inventoryStatus(weapon)
        )
        addCommsReply(_("Back"), commsStation)
    end
end

function M.handleWeaponRestockAlternate(weapon, profile)
    local source = M.getSource(profile)
    if not source:isDocked(comms_target) then
        setCommsMessage(
            _("station-comms", "You need to stay docked for that action.")
        )
        return
    end
    if not M.isAllowedTo(comms_target.comms_data.weapons[weapon], profile) then
        if weapon == "Nuke" then
            setCommsMessage(
                _(
                    "ammo-comms",
                    "We do not deal in weapons of mass destruction."
                )
            )
        elseif weapon == "EMP" then
            setCommsMessage(
                _("ammo-comms", "We do not deal in weapons of mass disruption.")
            )
        else
            setCommsMessage(_("ammo-comms", "We do not deal in those weapons."))
        end
        return
    end
    local suffix = restockSuffix(profile)
    local points_per_item = M.getWeaponCost(weapon, profile)
    local item_amount = math.floor(
        source:getWeaponStorageMax(weapon)
            * comms_target.comms_data.max_weapon_refill_amount[M.getFriendStatus(
                profile
            )]
            * restockScale(profile)
    ) - source:getWeaponStorage(weapon)
    local available = inventoryAvailable(weapon)
    if available ~= nil then
        item_amount = math.min(item_amount, available)
    end
    if item_amount <= 0 then
        setCommsMessage(cannotRestockMessage(weapon, suffix))
        addCommsReply(_("Back"), commsStation)
    else
        if not source:takeReputationPoints(points_per_item * item_amount) then
            setCommsMessage(_("needRep-comms", "Not enough reputation."))
            return
        end
        source:setWeaponStorage(
            weapon,
            source:getWeaponStorage(weapon) + item_amount
        )
        adjustInventory(weapon, item_amount)
        setCommsMessage(
            restockedMessage(source, weapon, suffix) .. inventoryStatus(weapon)
        )
        addCommsReply(_("Back"), commsStation)
    end
end

function M.addStationToDatabase(station)
    -- Assumes all player ships will be the same faction
    local player_faction = "Human Navy"
    local stations_key = _("scienceDB", "Stations")
    local stations_db = queryScienceDatabase(stations_key)
    if stations_db == nil then
        stations_db = ScienceDatabase():setName(stations_key)
    end
    local station_db = nil
    local station_key = station:getCallSign()
    local temp_artifact = Artifact():setFaction(player_faction)
    local first_time_entry = false
    if station:isFriendly(temp_artifact) then
        local friendly_key = _("scienceDB", "Friendly")
        local friendly_db = queryScienceDatabase(stations_key, friendly_key)
        if friendly_db == nil then
            stations_db:addEntry(friendly_key)
            friendly_db = queryScienceDatabase(stations_key, friendly_key)
            friendly_db:setLongDescription(
                _(
                    "scienceDB",
                    "Friendly stations share their short range telemetry with your ship on the Relay and Strategic Map consoles. These are the known friendly stations."
                )
            )
        end
        station_db =
            queryScienceDatabase(stations_key, friendly_key, station_key)
        if station_db == nil then
            friendly_db:addEntry(station_key)
            station_db =
                queryScienceDatabase(stations_key, friendly_key, station_key)
            first_time_entry = true
        end
    elseif not station:isEnemy(temp_artifact) then
        local neutral_key = "Neutral"
        local neutral_db = queryScienceDatabase(stations_key, neutral_key)
        if neutral_db == nil then
            stations_db:addEntry(neutral_key)
            neutral_db = queryScienceDatabase(stations_key, neutral_key)
            neutral_db:setLongDescription(
                _(
                    "scienceDB",
                    "Neutral stations don't share their short range telemetry with your ship, but they do allow for docking. These are the known neutral stations."
                )
            )
        end
        station_db =
            queryScienceDatabase(stations_key, neutral_key, station_key)
        if station_db == nil then
            neutral_db:addEntry(station_key)
            station_db =
                queryScienceDatabase(stations_key, neutral_key, station_key)
            first_time_entry = true
        end
    end
    if first_time_entry then
        local out = ""
        if station:getDescription() ~= nil then
            out = station:getDescription()
        end
        if station.comms_data ~= nil then
            if
                station.comms_data.general ~= nil
                and station.comms_data.general ~= ""
            then
                out = string.format(
                    _("scienceDB", "%s\n\nGeneral Information: %s"),
                    out,
                    station.comms_data.general
                )
            end
            if
                station.comms_data.history ~= nil
                and station.comms_data.history ~= ""
            then
                out = string.format(
                    _("scienceDB", "%s\n\nHistory: %s"),
                    out,
                    station.comms_data.history
                )
            end
        end
        if out ~= "" then
            station_db:setLongDescription(out)
        end
        local station_type = station:getTypeName()
        local size_value = ""
        local small_station_key = _("scienceDB", "Small Station")
        local medium_station_key = _("scienceDB", "Medium Station")
        local large_station_key = _("scienceDB", "Large Station")
        local huge_station_key = _("scienceDB", "Huge Station")
        if station_type == small_station_key then
            size_value = _("scienceDB", "Small")
            local small_db =
                queryScienceDatabase(stations_key, small_station_key)
            if small_db ~= nil then
                station_db:setImage(small_db:getImage())
            end
            station_db:setModelDataName("space_station_4")
        elseif station_type == medium_station_key then
            size_value = _("scienceDB", "Medium")
            local medium_db =
                queryScienceDatabase(stations_key, medium_station_key)
            if medium_db ~= nil then
                station_db:setImage(medium_db:getImage())
            end
            station_db:setModelDataName("space_station_3")
        elseif station_type == large_station_key then
            size_value = _("scienceDB", "Large")
            local large_db =
                queryScienceDatabase(stations_key, large_station_key)
            if large_db ~= nil then
                station_db:setImage(large_db:getImage())
            end
            station_db:setModelDataName("space_station_2")
        elseif station_type == huge_station_key then
            size_value = _("scienceDB", "Huge")
            local huge_db = queryScienceDatabase(stations_key, huge_station_key)
            if huge_db ~= nil then
                station_db:setImage(huge_db:getImage())
            end
            station_db:setModelDataName("space_station_1")
        end
        if size_value ~= "" then
            local size_key = _("scienceDB", "Size")
            station_db:setKeyValue(size_key, size_value)
        end
        local location_key = _("scienceDB", "Location, Faction")
        station_db:setKeyValue(
            location_key,
            string.format(
                "%s, %s",
                station:getSectorName(),
                station:getFaction()
            )
        )
    end
    local dock_service = ""
    local service_count = 0
    if station:getSharesEnergyWithDocked() then
        dock_service = _("scienceDB", "share energy")
        service_count = service_count + 1
    end
    if station:getRepairDocked() then
        if dock_service == "" then
            dock_service = _("scienceDB", "repair hull")
        else
            dock_service =
                string.format(_("scienceDB", "%s, repair hull"), dock_service)
        end
        service_count = service_count + 1
    end
    if station:getRestocksScanProbes() then
        if dock_service == "" then
            dock_service = _("scienceDB", "replenish probes")
        else
            dock_service = string.format(
                _("scienceDB", "%s, replenish probes"),
                dock_service
            )
        end
        service_count = service_count + 1
    end
    if service_count > 0 then
        local docking_services_key = _("scienceDB", "Docking Services")
        if service_count == 1 then
            docking_services_key = _("scienceDB", "Docking Service")
        end
        station_db:setKeyValue(docking_services_key, dock_service)
    end
    if station.comms_data ~= nil then
        if station.comms_data.weapon_available ~= nil then
            if station.comms_data.weapon_cost == nil then
                station.comms_data.weapon_cost = {
                    Homing = math.random(1, 4),
                    HVLI = math.random(1, 3),
                    Mine = math.random(2, 5),
                    Nuke = math.random(12, 18),
                    EMP = math.random(7, 13),
                }
            end
            if station.comms_data.reputation_cost_multipliers == nil then
                station.comms_data.reputation_cost_multipliers = {
                    friend = 1.0,
                    neutral = 3.0,
                }
            end
            local station_missiles = {
                { name = "Homing", key = _("scienceDB", "Restock Homing") },
                { name = "HVLI", key = _("scienceDB", "Restock HVLI") },
                { name = "Mine", key = _("scienceDB", "Restock Mine") },
                { name = "Nuke", key = _("scienceDB", "Restock Nuke") },
                { name = "EMP", key = _("scienceDB", "Restock EMP") },
            }
            for i, sm in ipairs(station_missiles) do
                if station.comms_data.weapon_available[sm.name] then
                    if station.comms_data.weapon_cost[sm.name] ~= nil then
                        local val = string.format(
                            _("scienceDB", "%i reputation each"),
                            math.ceil(
                                station.comms_data.weapon_cost[sm.name]
                                    * station.comms_data.reputation_cost_multipliers["friend"]
                            )
                        )
                        station_db:setKeyValue(sm.key, val)
                    end
                end
            end
        end
        local secondary_system_repair = {
            { name = "scan_repair", key = _("scienceDB", "Repair scanners") },
            {
                name = "combat_maneuver_repair",
                key = _("scienceDB", "Repair combat maneuver"),
            },
            { name = "hack_repair", key = _("scienceDB", "Repair hacking") },
            {
                name = "probe_launch_repair",
                key = _("scienceDB", "Repair probe launch"),
            },
            {
                name = "tube_slow_down_repair",
                key = _("scienceDB", "Repair slow tube"),
            },
            {
                name = "self_destruct_repair",
                key = _("scienceDB", "Repair scanners"),
            },
        }
        for i, ssr in ipairs(secondary_system_repair) do
            if station.comms_data[ssr.name] then
                if station.comms_data.service_cost[ssr.name] ~= nil then
                    local val = string.format(
                        _("scienceDB", "%s reputation"),
                        station.comms_data.service_cost[ssr.name]
                    )
                    station_db:setKeyValue(ssr.key, val)
                end
            end
        end
        if station.comms_data.system_repair ~= nil then
            local primary_system_repair = {
                { name = "reactor", key = _("scienceDB", "Repair reactor") },
                {
                    name = "beamweapons",
                    key = _("scienceDB", "Repair beam weapons"),
                },
                {
                    name = "missilesystem",
                    key = _("scienceDB", "Repair missile weapons"),
                },
                {
                    name = "maneuver",
                    key = _("scienceDB", "Repair maneuvering"),
                },
                { name = "impulse", key = _("scienceDB", "Repair impulse") },
                { name = "warp", key = _("scienceDB", "Repair warp drive") },
                {
                    name = "jumpdrive",
                    key = _("scienceDB", "Repair jump drive"),
                },
                {
                    name = "frontshield",
                    key = _("scienceDB", "Repair front shield"),
                },
                {
                    name = "rearshield",
                    key = _("scienceDB", "Repair rear shield"),
                },
            }
            for i, psr in ipairs(primary_system_repair) do
                if station.comms_data.system_repair[psr.name] ~= nil then
                    if station.comms_data.system_repair[psr.name].avail then
                        local val = string.format(
                            _("scienceDB", "%s reputation, up to %.1f%% max"),
                            station.comms_data.system_repair[psr.name].cost,
                            station.comms_data.system_repair[psr.name].max * 100
                        )
                        station_db:setKeyValue(psr.key, val)
                    end
                end
            end
        end
        if station.comms_data.service_available ~= nil then
            local general_service = {
                {
                    name = "supplydrop",
                    key = _("scienceDB", "Drop supplies"),
                },
                {
                    name = "reinforcements",
                    key = _("scienceDB", "Standard reinforcements"),
                },
                {
                    name = "hornet_reinforcements",
                    key = _("scienceDB", "Hornet reinforcements"),
                },
                {
                    name = "phobos_reinforcements",
                    key = _("scienceDB", "Phobos reinforcements"),
                },
                {
                    name = "amk3_reinforcements",
                    key = _("scienceDB", "Adder3 reinforcements"),
                },
                {
                    name = "amk8_reinforcements",
                    key = _("scienceDB", "Adder8 reinforcements"),
                },
                {
                    name = "shield_overcharge",
                    key = _("scienceDB", "Shield overcharge"),
                },
            }
            for i, gs in ipairs(general_service) do
                if station.comms_data.service_available[gs.name] then
                    if station.comms_data.service_cost[gs.name] ~= nil then
                        local val = string.format(
                            _("scienceDB", "%s reputation"),
                            station.comms_data.service_cost[gs.name]
                        )
                        station_db:setKeyValue(gs.key, val)
                    end
                end
            end
        end
        if station.comms_data.characterFunction ~= nil then
            station_db:setKeyValue(
                station.comms_data.character,
                station.comms_data.characterShort
            )
        end
        if station.comms_data.goods ~= nil then
            for good, details in pairs(station.comms_data.goods) do
                if details.quantity > 0 then
                    local sell_key =
                        string.format(_("scienceDB", "Sells %s"), good)
                    local sell_value = string.format(
                        _("scienceDB", "for %s reputation each"),
                        details.cost
                    )
                    station_db:setKeyValue(sell_key, sell_value)
                end
            end
        end
    end
    temp_artifact:destroy()
end

return M
