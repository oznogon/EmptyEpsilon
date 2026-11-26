-- Mission and optional-order menus utility from Carrier and Fighters, Rescue, Planet Devourer, Unwanted Visitors, Allies and Enemies, Defender Hunter, Borderline Fever, The Omicron Plague, Defenders or Pirates, and Iris Siege.

local M = {}

function M.clearOptionalOrders()
    optionalOrders = ""
end

function M.clearOptionalOrdersSnakeCase()
    optional_orders = ""
end

function M.showCurrentOrders()
    setOptionalOrders()
    local optional = optionalOrders
    if optional == nil then
        optional = optional_orders or ""
    end
    ordMsg = primaryOrders .. "\n" .. secondaryOrders .. optional
    if playWithTimeLimit then
        ordMsg = ordMsg
            .. string.format(
                _("orders-comms", "\n   %i Minutes remain in game"),
                math.floor(gameTimeLimit / 60)
            )
    end
    setCommsMessage(ordMsg)
end

function M.setOptionalOrders()
    optional_orders = ""
    if
        comms_source.transport_mission ~= nil
        or comms_source.cargo_mission ~= nil
    then
        local optional_orders_header = {
            _("orders-comms", "\nOptional:"),
            _("orders-comms", "\nOptional orders:"),
            _("orders-comms", "\nThese orders are optional:"),
            _("orders-comms", "\nNot required:"),
        }
        optional_orders = tableRemoveRandom(optional_orders_header)
    end
    if comms_source.transport_mission ~= nil then
        if
            comms_source.transport_mission.destination ~= nil
            and comms_source.transport_mission.destination:isValid()
        then
            optional_orders = string.format(
                _("orders-comms", "%s\nTransport %s to %s station %s in %s"),
                optional_orders,
                comms_source.transport_mission.character.name,
                comms_source.transport_mission.destination:getFaction(),
                comms_source.transport_mission.destination_name,
                comms_source.transport_mission.destination:getSectorName()
            )
        else
            optional_orders = string.format(
                _("orders-comms", "%s\nTransport %s to station %s (defunct)"),
                optional_orders,
                comms_source.transport_mission.character.name,
                comms_source.transport_mission.destination_name
            )
        end
    end
    if comms_source.cargo_mission ~= nil then
        if comms_source.cargo_mission.loaded then
            if
                comms_source.cargo_mission.destination ~= nil
                and comms_source.cargo_mission.destination:isValid()
            then
                optional_orders = string.format(
                    _(
                        "orders-comms",
                        "%s\nDeliver cargo for %s to station %s in %s"
                    ),
                    optional_orders,
                    comms_source.cargo_mission.character.name,
                    comms_source.cargo_mission.destination_name,
                    comms_source.cargo_mission.destination:getSectorName()
                )
            else
                optional_orders = string.format(
                    _(
                        "orders-comms",
                        "%s\nDeliver cargo for %s to station %s (defunct)"
                    ),
                    optional_orders,
                    comms_source.cargo_mission.character.name,
                    comms_source.cargo_mission.destination_name
                )
            end
        else
            if
                comms_source.cargo_mission.origin ~= nil
                and comms_source.cargo_mission.origin:isValid()
            then
                optional_orders = string.format(
                    _(
                        "orders-comms",
                        "%s\nPick up cargo for %s at station %s in %s"
                    ),
                    optional_orders,
                    comms_source.cargo_mission.character.name,
                    comms_source.cargo_mission.origin_name,
                    comms_source.cargo_mission.origin:getSectorName()
                )
            else
                optional_orders = string.format(
                    _(
                        "orders-comms",
                        "%s\nPick up cargo for %s at station %s (defunct)"
                    ),
                    optional_orders,
                    comms_source.cargo_mission.character.name,
                    comms_source.cargo_mission.origin_name
                )
            end
        end
    end
    if comms_source.restoration_mission ~= nil then
        if comms_source.restoration_mission.achievement then
            if
                comms_source.restoration_mission.destination ~= nil
                and comms_source.restoration_mission.destination:isValid()
            then
                optional_orders = string.format(
                    "%s\n%s",
                    optional_orders,
                    comms_source.restoration_mission.optional_orders_second_half
                )
            else
                optional_orders = string.format(
                    _("orders-comms", "%s\n%s (defunct)"),
                    optional_orders,
                    comms_source.restoration_mission.optional_orders_second_half
                )
            end
        else
            if
                comms_source.restoration_mission.origin ~= nil
                and comms_source.restoration_mission.origin:isValid()
            then
                optional_orders = string.format(
                    "%s\n%s",
                    optional_orders,
                    comms_source.restoration_mission.optional_orders_first_half
                )
            else
                optional_orders = string.format(
                    _("orders-comms", "%s\n%s (defunct)"),
                    optional_orders,
                    comms_source.restoration_mission.optional_orders_first_half
                )
            end
        end
    end
end

function M.scenarioMissionsUndocked()
    local accessible_warp_jammers = {}
    if comms_target.warp_jammer_list ~= nil then
        for index, wj in ipairs(comms_target.warp_jammer_list) do
            if wj ~= nil and wj:isValid() then
                table.insert(accessible_warp_jammers, wj)
            end
        end
    end
    for i, wj in ipairs(warp_jammer_list) do
        if wj ~= nil and wj:isValid() then
            local already_accessible = false
            for j, awj in ipairs(accessible_warp_jammers) do
                if awj == wj then
                    already_accessible = true
                end
            end
            if not already_accessible then
                if distance_diagnostic then
                    print(
                        "distance_diagnostic 15: comms_target,wj: scenario missions undocked, warp jammer:",
                        comms_target:getCallSign(),
                        wj:getCallSign()
                    )
                end
                if distance(comms_target, wj) < 30000 then
                    if
                        wj:isFriendly(comms_source)
                        or wj:isFriendly(comms_target)
                    then
                        table.insert(accessible_warp_jammers, wj)
                    elseif
                        not wj:isEnemy(comms_source)
                        or not wj:isEnemy(comms_target)
                    then
                        table.insert(accessible_warp_jammers, wj)
                    end
                end
            end
        end
    end
    if #accessible_warp_jammers > 0 then
        addCommsReply(_("station-comms", "Connect to warp jammer"), function()
            setCommsMessage(
                _("station-comms", "Which one would you like to connect to?")
            )
            local pay_rep = false
            for index, wj in ipairs(accessible_warp_jammers) do
                local wj_rep = 0
                if wj:isFriendly(comms_target) then
                    if wj:isFriendly(comms_source) then
                        wj_rep = 0
                    else
                        if wj:isEnemy(comms_source) then
                            wj_rep = 10
                            pay_rep = true
                        else
                            wj_rep = 5
                            pay_rep = true
                        end
                    end
                elseif wj:isEnemy(comms_target) then
                    if wj:isFriendly(comms_source) then
                        wj_rep = 15
                        pay_rep = true
                    else
                        if wj:isEnemy(comms_source) then
                            wj_rep = 100
                            pay_rep = true
                        else
                            wj_rep = 20
                            pay_rep = true
                        end
                    end
                else
                    if wj:isFriendly(comms_source) then
                        wj_rep = 10
                        pay_rep = true
                    else
                        if wj:isEnemy(comms_source) then
                            wj_rep = 25
                            pay_rep = true
                        else
                            wj_rep = 20
                            pay_rep = true
                        end
                    end
                end
                local reputation_prompt = ""
                if wj_rep > 0 then
                    reputation_prompt = string.format(
                        _("station-comms", "(%i reputation)"),
                        wj_rep
                    )
                end
                addCommsReply(
                    string.format("%s %s", wj.identifier, reputation_prompt),
                    function()
                        if comms_source:takeReputationPoints(wj_rep) then
                            setCommsMessage(
                                string.format(
                                    _(
                                        "station-comms",
                                        "%s Automated warp jammer access menu"
                                    ),
                                    wj:getCallSign()
                                )
                            )
                            addCommsReply(
                                _(
                                    "station-comms",
                                    "Reduce range to 1 unit for 1 minute"
                                ),
                                function()
                                    wj:setRange(1000)
                                    wj.reset_time = getScenarioTime() + 60
                                    setCommsMessage(
                                        _(
                                            "station-comms",
                                            "Acknowledged. Range adjusted. Reset timer engaged."
                                        )
                                    )
                                    addCommsReply(_("Back"), commsStation)
                                end
                            )
                            addCommsReply(
                                _(
                                    "station-comms",
                                    "Reduce range by 50% for 2 minutes"
                                ),
                                function()
                                    wj:setRange(wj.range / 2)
                                    wj.reset_time = getScenarioTime() + 120
                                    setCommsMessage(
                                        _(
                                            "station-comms",
                                            "Acknowledged. Range adjusted. Reset timer engaged."
                                        )
                                    )
                                    addCommsReply(_("Back"), commsStation)
                                end
                            )
                            addCommsReply(
                                _(
                                    "station-comms",
                                    "Reduce range by 25% for 3 minutes"
                                ),
                                function()
                                    wj:setRange(wj.range * 0.75)
                                    wj.reset_time = getScenarioTime() + 180
                                    setCommsMessage(
                                        _(
                                            "station-comms",
                                            "Acknowledged. Range adjusted. Reset timer engaged."
                                        )
                                    )
                                    addCommsReply(_("Back"), commsStation)
                                end
                            )
                        else
                            setCommsMessage(
                                _("needRep-comms", "Insufficient reputation")
                            )
                        end
                    end
                )
            end
            if pay_rep then
                addCommsReply(
                    _(
                        "station-comms",
                        "Why do I have to pay reputation to log in to some of these warp jammers?"
                    ),
                    function()
                        setCommsMessage(
                            string.format(
                                _(
                                    "station-comms",
                                    "It's complicated. It depends on the relationships between the warp jammer owner, us, station %s and you, %s. The farther apart the relationship, the more reputation it costs to gain access. Do you want more details?"
                                ),
                                comms_target:getCallSign(),
                                comms_source:getCallSign()
                            )
                        )
                        addCommsReply(
                            _(
                                "station-comms",
                                "Yes, please provide more details"
                            ),
                            function()
                                local out = _(
                                    "station-comms",
                                    "These are the cases and their reputation costs:"
                                )
                                out = string.format(
                                    _(
                                        "station-comms",
                                        "%s\n    WJ friendly to %s and WJ is friendly to %s = no reputation."
                                    ),
                                    out,
                                    comms_target:getCallSign(),
                                    comms_source:getCallSign()
                                )
                                out = string.format(
                                    _(
                                        "station-comms",
                                        "%s\n    WJ friendly to %s and WJ is neutral to %s = 5 reputation."
                                    ),
                                    out,
                                    comms_target:getCallSign(),
                                    comms_source:getCallSign()
                                )
                                out = string.format(
                                    _(
                                        "station-comms",
                                        "%s\n    WJ friendly to %s and WJ is enemy to %s = 10 reputation."
                                    ),
                                    out,
                                    comms_target:getCallSign(),
                                    comms_source:getCallSign()
                                )
                                out = string.format(
                                    _(
                                        "station-comms",
                                        "%s\n    WJ neutral to %s and WJ is friendly to %s = 10 reputation."
                                    ),
                                    out,
                                    comms_target:getCallSign(),
                                    comms_source:getCallSign()
                                )
                                out = string.format(
                                    _(
                                        "station-comms",
                                        "%s\n    WJ enemy to %s and WJ is friendly to %s = 15 reputation."
                                    ),
                                    out,
                                    comms_target:getCallSign(),
                                    comms_source:getCallSign()
                                )
                                out = string.format(
                                    _(
                                        "station-comms",
                                        "%s\n    WJ neutral to %s and WJ is neutral to %s = 20 reputation."
                                    ),
                                    out,
                                    comms_target:getCallSign(),
                                    comms_source:getCallSign()
                                )
                                out = string.format(
                                    _(
                                        "station-comms",
                                        "%s\n    WJ enemy to %s and WJ is neutral to %s = 20 reputation."
                                    ),
                                    out,
                                    comms_target:getCallSign(),
                                    comms_source:getCallSign()
                                )
                                out = string.format(
                                    _(
                                        "station-comms",
                                        "%s\n    WJ neutral to %s and WJ is enemy to %s = 25 reputation."
                                    ),
                                    out,
                                    comms_target:getCallSign(),
                                    comms_source:getCallSign()
                                )
                                out = string.format(
                                    _(
                                        "station-comms",
                                        "%s\n    WJ enemy to %s and WJ is enemy to %s = 100 reputation."
                                    ),
                                    out,
                                    comms_target:getCallSign(),
                                    comms_source:getCallSign()
                                )
                                setCommsMessage(out)
                                addCommsReply(_("Back"), commsStation)
                            end
                        )
                        addCommsReply(_("Back"), commsStation)
                    end
                )
            end
            addCommsReply(_("Back"), commsStation)
        end)
    end
end

return M
