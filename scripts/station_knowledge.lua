-- Shared station goods-knowledge generation, used in Close the Gaps, Rescue,
-- Unwanted Visitors, Allies and Enemies, Escape, Defender Hunter, and
-- Capture the Flag.

local M = {}

function M.nearStations(obj, stations)
    local remaining = {}
    local closest_distance = 9999999
    local closest = nil
    for index, station in ipairs(stations) do
        if
            station ~= nil
            and station:isValid()
            and station:getCallSign() ~= obj:getCallSign()
        then
            table.insert(remaining, station)
            local current_distance = distance(obj, station)
            if current_distance < closest_distance then
                closest = station
                closest_distance = current_distance
            end
        end
    end
    if closest == nil then
        return nil, remaining
    end
    for index = 1, #remaining do
        if remaining[index]:getCallSign() == closest:getCallSign() then
            table.remove(remaining, index)
            break
        end
    end
    return closest, remaining
end

function M.randomNearStations(obj, stations, count, random_fn)
    local candidates = {}
    local remaining = stations
    for index = 1, count do
        local closest
        closest, remaining = M.nearStations(obj, remaining)
        if closest ~= nil then
            table.insert(candidates, closest)
        end
    end
    if #candidates == 0 then
        return nil
    end
    local random = random_fn or _G.irandom or math.random
    return candidates[random(1, #candidates)]
end

function M.fill(stations, options)
    options = options or {}
    local target = options.target or comms_target
    local goods = options.goods or goods
    local trade_medicine = options.trade_medicine or tradeMedicine
    local trade_food = options.trade_food or tradeFood
    local trade_luxury = options.trade_luxury or tradeLuxury
    local knowledge_max = options.max or 10
    local near_range = options.near_range or 75000

    target.goodsKnowledge = {}
    target.goodsKnowledgeSector = {}
    target.goodsKnowledgeType = {}
    target.goodsKnowledgeTrade = {}
    local knowledge_count = 0

    for station_index = 1, #stations do
        local station = stations[station_index]
        if station ~= nil and station:isValid() then
            local brain_check = distance(target, station) < near_range and 3
                or 1
            for good_index = 1, #goods[station] do
                if random(1, 10) <= brain_check then
                    table.insert(target.goodsKnowledge, station:getCallSign())
                    table.insert(
                        target.goodsKnowledgeSector,
                        station:getSectorName()
                    )
                    table.insert(
                        target.goodsKnowledgeType,
                        goods[station][good_index][1]
                    )
                    local trade_string = ""
                    local station_trades = false
                    if trade_medicine[station] ~= nil then
                        trade_string =
                            _("trade-comms", " and will trade it for medicine")
                        station_trades = true
                    end
                    if trade_food[station] ~= nil then
                        if station_trades then
                            trade_string = trade_string
                                .. _("trade-comms", " or food")
                        else
                            trade_string = trade_string
                                .. _(
                                    "trade-comms",
                                    " and will trade it for food"
                                )
                            station_trades = true
                        end
                    end
                    if trade_luxury[station] ~= nil then
                        if station_trades then
                            trade_string = trade_string
                                .. _("trade-comms", " or luxury")
                        else
                            trade_string = trade_string
                                .. _(
                                    "trade-comms",
                                    " and will trade it for luxury"
                                )
                        end
                    end
                    table.insert(target.goodsKnowledgeTrade, trade_string)
                    knowledge_count = knowledge_count + 1
                    if knowledge_count >= knowledge_max then
                        return
                    end
                end
            end
        end
    end
end

return M
