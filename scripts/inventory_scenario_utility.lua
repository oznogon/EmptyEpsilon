-- Shared cargo inventory formatting for scenario ship logs and UI, used in
-- Planet Devourer, Doomed Outpost, Scurvy Scavenger, Allies and Enemies,
-- Defender Hunter, Shoreline, Borderline Fever, The Omicron Plague, Fermi 500,
-- and Capture the Flag.

local M = {}

function M.format(ship, options)
    options = options or {}
    local lines = {
        string.format(
            _("inventory-shipLog", "%s Current cargo:"),
            ship:getCallSign()
        ),
    }
    local empty = true
    if options.schema == "indexed" then
        local entries = options.goods and options.goods[ship] or {}
        for entry_index, entry in ipairs(entries) do
            local name, quantity = entry[1], entry[2]
            if not options.filter_zero or quantity > 0 then
                table.insert(
                    lines,
                    string.format(
                        _("inventory-shipLog", "     %s: %i"),
                        options.names and options.names[name] or name,
                        math.floor(quantity)
                    )
                )
                if quantity > 0 then
                    empty = false
                end
            end
        end
    else
        for name, quantity in pairs(ship.goods or {}) do
            if not options.filter_zero or quantity > 0 then
                table.insert(
                    lines,
                    string.format(
                        _("inventory-shipLog", "     %s: %i"),
                        options.names and options.names[name] or name,
                        math.floor(quantity)
                    )
                )
                if quantity > 0 then
                    empty = false
                end
            end
        end
    end
    if empty then
        table.insert(
            lines,
            options.empty_newline and _("inventory-shipLog", "     Empty\n")
                or _("inventory-shipLog", "     Empty")
        )
    end
    table.insert(
        lines,
        string.format(_("inventory-shipLog", "Available space: %i"), ship.cargo)
    )
    return lines
end

function M.render(ship, options)
    for line_index, line in ipairs(M.format(ship, options)) do
        ship:addToShipLog(line, "Yellow")
    end
end

function M.updateButtons(player_limit, render, options)
    options = options or {}
    for player_index = 1, player_limit do
        local ship = getPlayerShip(player_index)
        if ship ~= nil and ship:isValid() then
            local empty = true
            for good_index, quantity in pairs(ship.goods or {}) do
                if quantity ~= nil and quantity > 0 then
                    empty = false
                    break
                end
            end
            if not empty then
                if
                    ship:hasPlayerAtPosition("Relay")
                    and ship.inventoryButton == nil
                then
                    ship:addCustomButton(
                        "Relay",
                        "inventory" .. ship:getCallSign(),
                        _("inventory-buttonRelay", "Inventory"),
                        function()
                            render(ship)
                        end,
                        options.order or 2
                    )
                    ship.inventoryButton = true
                end
                if
                    ship:hasPlayerAtPosition("Operations")
                    and ship.inventoryButton == nil
                then
                    ship:addCustomButton(
                        "Operations",
                        "inventoryOp" .. ship:getCallSign(),
                        _("inventory-buttonOperations", "Inventory"),
                        function()
                            render(ship)
                        end,
                        options.order or 2
                    )
                    ship.inventoryButton = true
                end
            end
        end
    end
end

function M.indexedGoods(options)
    local function adjust(goods_type, delta)
        local cargo = options.registry()[options.owner()]
        for index = 1, #cargo do
            if cargo[index][1] == goods_type then
                cargo[index][2] = cargo[index][2] + delta
            end
        end
    end
    return {
        increment = function(goods_type)
            adjust(goods_type, 1)
        end,
        decrement = function(goods_type)
            adjust(goods_type, -1)
        end,
    }
end

function M.renderer(names)
    return function(ship)
        M.render(ship, { names = names() })
    end
end

function M.buttons(limit, renderer)
    return function()
        M.updateButtons(limit, renderer)
    end
end

return M
