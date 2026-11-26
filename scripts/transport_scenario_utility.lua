-- Shared transport selection and commerce helpers, used in Cadet Patrol,
-- Planet Devourer, Doomed Outpost, The Omicron Plague, Defenders or Pirates,
-- and Iris Siege.

local M = {}

function M.warpJammerMaintenance(next_plot)
    return function()
        if #warp_jammer_list > 0 then
            for wj_index, wj in ipairs(warp_jammer_list) do
                if wj ~= nil and wj:isValid() then
                    if wj.reset_time ~= nil then
                        if getScenarioTime() > wj.reset_time then
                            wj:setRange(wj.range)
                            wj.reset_time = nil
                        end
                    end
                else
                    warp_jammer_list[wj_index] =
                        warp_jammer_list[#warp_jammer_list]
                    warp_jammer_list[#warp_jammer_list] = nil
                    break
                end
            end
        end
        maintenancePlot = next_plot()
    end
end

function M.transportCommerceMaintenance(delta)
    if #transport_list > 0 then
        local s_time = getScenarioTime()
        for transport_index, transport in ipairs(transport_list) do
            if transport ~= nil and transport:isValid() then
                local temp_faction = transport:getFaction()
                local docked_with = transport:getDockedWith()
                local transport_target = nil
                if docked_with ~= nil then
                    if transport.undock_timer == nil then
                        transport.undock_timer = s_time + random(10, 25)
                    elseif transport.undock_timer < s_time then
                        transport.undock_timer = nil
                        transport_target = M.pickTransportTarget(transport)
                        if transport_target ~= nil then
                            transport:setFaction("Independent")
                            transport:orderDock(transport_target)
                            transport:setFaction(temp_faction)
                        end
                    end
                else
                    if string.find("Dock", transport:getOrder()) then
                        transport_target = transport:getOrderTarget()
                        if
                            transport_target == nil
                            or not transport_target:isValid()
                        then
                            transport_target = M.pickTransportTarget(transport)
                            if transport_target ~= nil then
                                transport:setFaction("Independent")
                                transport:orderDock(transport_target)
                                transport:setFaction(temp_faction)
                            end
                        end
                    else
                        transport_target = M.pickTransportTarget(transport)
                        if transport_target ~= nil then
                            transport:setFaction("Independent")
                            transport:orderDock(transport_target)
                            transport:setFaction(temp_faction)
                        end
                    end
                end
            else
                transport_list[transport_index] =
                    transport_list[#transport_list]
                transport_list[#transport_list] = nil
                break
            end
        end
    end
    maintenancePlot = warpJammerMaintenance
end

function M.pickTransportTarget(transport)
    local transport_target = nil
    if #station_list > 0 then
        local count_repeat_loop = 0
        repeat
            -- transport_target = transport_stations[math.random(1,#transport_stations)]
            transport_target = station_list[math.random(1, #station_list)]
            count_repeat_loop = count_repeat_loop + 1
        until count_repeat_loop > max_repeat_loop
            or (
                transport_target ~= nil
                and transport_target:isValid()
                and not transport:isEnemy(transport_target)
            )
        if count_repeat_loop > max_repeat_loop then
            print("repeated too many times when picking a transport target")
        end
    end
    return transport_target
end

function M.randomTransportTypeBasic()
    local transport_type =
        { "Personnel", "Goods", "Garbage", "Equipment", "Fuel" }
    local freighter_engine = "Freighter"
    local freighter_size = math.random(1, 5)
    if random(1, 100) < 30 then
        freighter_engine = "Jump Freighter"
        freighter_size = math.random(3, 5)
    end
    local transport_template = string.format(
        "%s %s %i",
        tableSelectRandom(transport_type),
        freighter_engine,
        freighter_size
    )
    return CpuShip()
        :setTemplate(transport_template)
        :setCommsScript("")
        :setCommsFunction(commsShip),
        freighter_size
end

function M.randomTransportTypeExtended()
    local transport_type =
        { "Personnel", "Goods", "Garbage", "Equipment", "Fuel" }
    local freighter_engine = "Freighter"
    local freighter_size = math.random(1, 5)
    if random(1, 100) < 30 then
        freighter_engine = "Jump Freighter"
        freighter_size = math.random(3, 5)
    end
    return CpuShip()
        :setTemplate(
            string.format(
                "%s %s %i",
                transport_type[math.random(1, #transport_type)],
                freighter_engine,
                freighter_size
            )
        )
        :setCommsScript("")
        :setCommsFunction(commsShip),
        freighter_size
end

return M
