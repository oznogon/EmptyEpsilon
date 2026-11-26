-- Legacy indexed-cargo station trade menus and goods knowledge, used in Allies and Enemies, Fermi 500, and Capture the Flag.

local M = {}

local function goodsName(options, good)
    if options.names ~= nil then
        return options.names[good] or good
    end
    return good
end

function M.addTrade(options)
    options = options or {}
    local goods = options.goods or goods
    local source = options.source or comms_source
    local target = options.target or comms_target
    local back = options.back or commsStation
    local trade_food = options.trade_food or tradeFood
    local trade_medicine = options.trade_medicine or tradeMedicine
    local trade_luxury = options.trade_luxury or tradeLuxury
    local increment = options.increment or incrementPlayerGoods
    local decrement = options.decrement or decrementPlayerGoods
    local decrement_station = options.decrement_station or decrementStationGoods
    local name = function(good)
        return goodsName(options, good)
    end

    local station_cargo = goods[target]
    local player_cargo = goods[source]
    if station_cargo == nil then
        return
    end

    if options.explain ~= nil then
        options.explain(back)
    end

    addCommsReply(_("trade-comms", "Buy, sell, trade"), function()
        local report = string.format(
            _(
                "trade-comms",
                "Station %s:\nGoods or components available: quantity, cost in reputation\n"
            ),
            target:getCallSign()
        )
        for index = 1, #station_cargo do
            report = report
                .. string.format(
                    _("trade-comms", "     %s: %i, %i\n"),
                    name(station_cargo[index][1]),
                    station_cargo[index][2],
                    station_cargo[index][3]
                )
        end
        report = report .. _("trade-comms", "Current Cargo:\n")
        local cargo_hold_empty = true
        for index = 1, #player_cargo do
            if player_cargo[index][2] > 0 then
                report = report
                    .. string.format(
                        _("trade-comms", "     %s: %i\n"),
                        name(player_cargo[index][1]),
                        player_cargo[index][2]
                    )
                cargo_hold_empty = false
            end
        end
        if cargo_hold_empty then
            report = report .. _("trade-comms", "     Empty\n")
        end
        local reputation = math.floor(source:getReputationPoints())
        report = report
            .. string.format(
                _(
                    "trade-comms",
                    "Available Space: %i, Available Reputation: %i\n"
                ),
                source.cargo,
                reputation
            )
        setCommsMessage(report)

        for index = 1, #station_cargo do
            local good = station_cargo[index][1]
            local quantity = station_cargo[index][2]
            local cost = station_cargo[index][3]
            addCommsReply(
                string.format(
                    _("trade-comms", "Buy one %s for %i reputation"),
                    name(good),
                    cost
                ),
                function()
                    local message = string.format(
                        _("trade-comms", "Type: %s, Quantity: %i, Rep: %i"),
                        name(good),
                        quantity,
                        cost
                    )
                    if source.cargo < 1 then
                        message = message
                            .. _(
                                "trade-comms",
                                "\nInsufficient cargo space for purchase"
                            )
                    elseif cost > reputation then
                        message = message
                            .. _(
                                "needRep-comms",
                                "\nInsufficient reputation for purchase"
                            )
                    elseif quantity < 1 then
                        message = message
                            .. _(
                                "trade-comms",
                                "\nInsufficient station inventory"
                            )
                    else
                        if not source:takeReputationPoints(cost) then
                            message = message
                                .. _(
                                    "needRep-comms",
                                    "\nInsufficient reputation for purchase"
                                )
                        else
                            source.cargo = source.cargo - 1
                            decrement_station(good)
                            increment(good)
                            message = message .. _("trade-comms", "\npurchased")
                        end
                    end
                    setCommsMessage(message)
                    addCommsReply(_("Back"), back)
                end
            )
        end

        local function addTradeReplies(trade_good, trade_table)
            if trade_table == nil or trade_table[target] == nil then
                return
            end
            local quantity = 0
            for index = 1, #player_cargo do
                if player_cargo[index][1] == trade_good then
                    quantity = player_cargo[index][2]
                end
            end
            if quantity <= 0 then
                return
            end
            local label = ({
                food = _("trade-comms", "Trade food for %s"),
                medicine = _("trade-comms", "Trade medicine for %s"),
                luxury = _("trade-comms", "Trade luxury for %s"),
            })[trade_good]
            for index = 1, #station_cargo do
                local good = station_cargo[index][1]
                local good_quantity = station_cargo[index][2]
                addCommsReply(string.format(label, name(good)), function()
                    local message = string.format(
                        _("trade-comms", "Type: %s,  Quantity: %i"),
                        name(good),
                        good_quantity
                    )
                    if good_quantity < 1 then
                        message = message
                            .. _(
                                "trade-comms",
                                "\nInsufficient station inventory"
                            )
                    else
                        decrement_station(good)
                        increment(good)
                        decrement(trade_good)
                        message = message .. _("trade-comms", "\nTraded")
                    end
                    setCommsMessage(message)
                    addCommsReply(_("Back"), back)
                end)
            end
        end

        addTradeReplies("food", trade_food)
        addTradeReplies("luxury", trade_luxury)
        addTradeReplies("medicine", trade_medicine)
        addCommsReply(_("Back"), back)
    end)

    local cargo_hold_empty = true
    for index = 1, #player_cargo do
        if player_cargo[index][2] > 0 then
            cargo_hold_empty = false
        end
    end
    if not cargo_hold_empty then
        addCommsReply(_("trade-comms", "Jettison cargo"), function()
            setCommsMessage(
                string.format(
                    _(
                        "trade-comms",
                        "Available space: %i\nWhat would you like to jettison?"
                    ),
                    source.cargo
                )
            )
            for index = 1, #player_cargo do
                local good = player_cargo[index][1]
                if player_cargo[index][2] > 0 then
                    addCommsReply(name(good), function()
                        decrement(good)
                        source.cargo = source.cargo + 1
                        setCommsMessage(
                            string.format(
                                _("trade-comms", "One %s jettisoned"),
                                name(good)
                            )
                        )
                        addCommsReply(_("Back"), back)
                    end)
                end
            end
            addCommsReply(_("Back"), back)
        end)
    end
end

function M.addAvailability(options)
    options = options or {}
    local goods = options.goods or goods
    local target = options.target or comms_target
    local back = options.back or commsStation
    local name = function(good)
        return goodsName(options, good)
    end
    local quantity_available = 0
    local station_cargo = goods[target]
    if station_cargo == nil then
        return
    end
    for index = 1, #station_cargo do
        if station_cargo[index][2] > 0 then
            quantity_available = quantity_available + station_cargo[index][2]
        end
    end
    if quantity_available <= 0 then
        return
    end
    addCommsReply(
        _("trade-comms", "What goods do you have available for sale or trade?"),
        function()
            local message = string.format(
                _(
                    "trade-comms",
                    "Station %s:\nGoods or components available: quantity, cost in reputation\n"
                ),
                target:getCallSign()
            )
            for index = 1, #station_cargo do
                message = message
                    .. string.format(
                        _("trade-comms", "   %14s: %2i, %3i\n"),
                        name(station_cargo[index][1]),
                        station_cargo[index][2],
                        station_cargo[index][3]
                    )
            end
            setCommsMessage(message)
            addCommsReply(_("Back"), back)
        end
    )
end

function M.addKnowledge(options)
    options = options or {}
    local target = options.target or comms_target
    local back = options.back or commsStation
    local name = function(good)
        return goodsName(options, good)
    end

    addCommsReply(
        _("trade-comms", "Where can I find particular goods?"),
        function()
            local message = _(
                "trade-comms",
                "Friendly stations generally have food or medicine or both. Neutral stations often trade their goods for food, medicine or luxury."
            )
            if target.goodsKnowledge == nil then
                message = message
                    .. _(
                        "trade-comms",
                        " Beyond that, I have no knowledge of specific stations.\n\nCheck back later, someone else may have better knowledge"
                    )
                setCommsMessage(message)
                addCommsReply(_("Back"), back)
                if options.fill ~= nil then
                    options.fill()
                end
                return
            end
            if #target.goodsKnowledge == 0 then
                message = message
                    .. _(
                        "trade-comms",
                        " Beyond that, I have no knowledge of specific stations"
                    )
            else
                message = message
                    .. _(
                        "trade-comms",
                        "\n\nWhat goods are you interested in?\nI've heard about these:"
                    )
                for index = 1, #target.goodsKnowledge do
                    local good = target.goodsKnowledgeType[index]
                    addCommsReply(name(good), function()
                        setCommsMessage(
                            string.format(
                                _(
                                    "trade-comms",
                                    "Station %s in sector %s has %s%s"
                                ),
                                target.goodsKnowledge[index],
                                target.goodsKnowledgeSector[index],
                                name(good),
                                target.goodsKnowledgeTrade[index]
                            )
                        )
                        addCommsReply(_("Back"), back)
                    end)
                end
            end
            setCommsMessage(message)
            addCommsReply(_("Back"), back)
        end
    )
end

return M
