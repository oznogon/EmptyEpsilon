-- Shared station transport and cargo mission menus from Doomed Outpost.

local M = {}

function M.docked()
    local mission_character = nil
    local mission_type = nil
    if comms_source.transport_mission ~= nil then
        if
            comms_source.transport_mission.destination ~= nil
            and comms_source.transport_mission.destination:isValid()
        then
            if comms_source.transport_mission.destination == comms_target then
                addCommsReply(
                    string.format(
                        _("station-comms", "Deliver %s to %s"),
                        comms_source.transport_mission.character,
                        comms_target:getCallSign()
                    ),
                    function()
                        if not comms_source:isDocked(comms_target) then
                            setCommsMessage(
                                _(
                                    "station-comms",
                                    "You need to stay docked for that action."
                                )
                            )
                            return
                        end
                        setCommsMessage(
                            string.format(
                                _(
                                    "station-comms",
                                    "%s disembarks at %s and thanks you"
                                ),
                                comms_source.transport_mission.character,
                                comms_target:getCallSign()
                            )
                        )
                        comms_source:addReputationPoints(
                            comms_source.transport_mission.reward
                        )
                        if comms_target.residents == nil then
                            comms_target.residents = {}
                        end
                        table.insert(
                            comms_target.residents,
                            comms_source.transport_mission.character
                        )
                        comms_source.transport_mission = nil
                        addCommsReply(_("Back"), commsStation)
                    end
                )
            end
        else
            comms_source:addToShipLog(
                string.format(
                    _(
                        "shipLog",
                        "%s disembarks at %s because %s has been destroyed. You receive %s reputation for your efforts"
                    ),
                    comms_source.transport_mission.character,
                    comms_target:getCallSign(),
                    comms_source.transport_mission.destination_name,
                    comms_source.transport_mission.reward / 2
                ),
                "Yellow"
            )
            comms_source:addReputationPoints(
                comms_source.transport_mission.reward / 2
            )
            if comms_target.residents == nil then
                comms_target.residents = {}
            end
            table.insert(
                comms_target.residents,
                comms_source.transport_mission.character
            )
            comms_source.transport_mission = nil
        end
    else
        if comms_target.transport_mission == nil then
            mission_character = tableRemoveRandom(character_names)
            local mission_target = nil
            if mission_character ~= nil then
                mission_type = random(1, 100)
                local destination_pool = {}
                if mission_type < 20 then
                    for station_index, station in ipairs(circle_stations) do
                        if
                            station ~= nil
                            and station:isValid()
                            and station ~= comms_target
                            and not comms_source:isEnemy(station)
                            and not comms_source:isFriendly(station)
                        then
                            table.insert(destination_pool, station)
                        end
                    end
                    mission_target = tableRemoveRandom(destination_pool)
                    if mission_target ~= nil then
                        comms_target.transport_mission = {
                            ["destination"] = mission_target,
                            ["destination_name"] = mission_target:getCallSign(),
                            ["reward"] = 40,
                            ["character"] = mission_character,
                        }
                    else
                        for station_index, station in ipairs(circle_stations) do
                            if
                                station ~= nil
                                and station:isValid()
                                and station ~= comms_target
                                and comms_source:isFriendly(station)
                            then
                                table.insert(destination_pool, station)
                            end
                        end
                        mission_target = tableRemoveRandom(destination_pool)
                        if mission_target ~= nil then
                            comms_target.transport_mission = {
                                ["destination"] = mission_target,
                                ["destination_name"] = mission_target:getCallSign(),
                                ["reward"] = 30,
                                ["character"] = mission_character,
                            }
                        else
                            for station_index, station in ipairs(inner_circle) do
                                if
                                    station ~= nil
                                    and station:isValid()
                                    and station ~= comms_target
                                then
                                    table.insert(destination_pool, station)
                                end
                            end
                            mission_target = tableRemoveRandom(destination_pool)
                            if mission_target ~= nil then
                                comms_target.transport_mission = {
                                    ["destination"] = mission_target,
                                    ["destination_name"] = mission_target:getCallSign(),
                                    ["reward"] = 20,
                                    ["character"] = mission_character,
                                }
                            end
                        end
                    end
                elseif mission_type < 50 then
                    for station_index, station in ipairs(circle_stations) do
                        if
                            station ~= nil
                            and station:isValid()
                            and station ~= comms_target
                            and comms_source:isFriendly(station)
                        then
                            table.insert(destination_pool, station)
                        end
                    end
                    mission_target = tableRemoveRandom(destination_pool)
                    if mission_target ~= nil then
                        comms_target.transport_mission = {
                            ["destination"] = mission_target,
                            ["destination_name"] = mission_target:getCallSign(),
                            ["reward"] = 30,
                            ["character"] = mission_character,
                        }
                    else
                        for station_index, station in ipairs(inner_circle) do
                            if
                                station ~= nil
                                and station:isValid()
                                and station ~= comms_target
                            then
                                table.insert(destination_pool, station)
                            end
                        end
                        mission_target = tableRemoveRandom(destination_pool)
                        if mission_target ~= nil then
                            comms_target.transport_mission = {
                                ["destination"] = mission_target,
                                ["destination_name"] = mission_target:getCallSign(),
                                ["reward"] = 20,
                                ["character"] = mission_character,
                            }
                        else
                            for station_index, station in
                                ipairs(circle_stations)
                            do
                                if
                                    station ~= nil
                                    and station:isValid()
                                    and station ~= comms_target
                                    and not comms_source:isEnemy(station)
                                    and not comms_source:isFriendly(station)
                                then
                                    table.insert(destination_pool, station)
                                end
                            end
                            mission_target = tableRemoveRandom(destination_pool)
                            if mission_target ~= nil then
                                comms_target.transport_mission = {
                                    ["destination"] = mission_target,
                                    ["destination_name"] = mission_target:getCallSign(),
                                    ["reward"] = 40,
                                    ["character"] = mission_character,
                                }
                            end
                        end
                    end
                else
                    for station_index, station in ipairs(inner_circle) do
                        if
                            station ~= nil
                            and station:isValid()
                            and station ~= comms_target
                        then
                            table.insert(destination_pool, station)
                        end
                    end
                    mission_target = tableRemoveRandom(destination_pool)
                    if mission_target ~= nil then
                        comms_target.transport_mission = {
                            ["destination"] = mission_target,
                            ["destination_name"] = mission_target:getCallSign(),
                            ["reward"] = 20,
                            ["character"] = mission_character,
                        }
                    else
                        for station_index, station in ipairs(circle_stations) do
                            if
                                station ~= nil
                                and station:isValid()
                                and station ~= comms_target
                                and not comms_source:isEnemy(station)
                            then
                                table.insert(destination_pool, station)
                            end
                        end
                        mission_target = tableRemoveRandom(destination_pool)
                        if mission_target ~= nil then
                            local reward = 40
                            if mission_target:isFriendly(comms_source) then
                                reward = 30
                            end
                            comms_target.transport_mission = {
                                ["destination"] = mission_target,
                                ["destination_name"] = mission_target:getCallSign(),
                                ["reward"] = reward,
                                ["character"] = mission_character,
                            }
                        end
                    end
                end
            end
        else
            if not comms_target.transport_mission.destination:isValid() then
                if comms_target.residents == nil then
                    comms_target.residents = {}
                end
                table.insert(
                    comms_target.residents,
                    comms_target.transport_mission.character
                )
                comms_target.transport_mission = nil
            end
        end
        if comms_target.transport_mission ~= nil then
            -- print("comms target transport mission",comms_target.transport_mission)
            -- print("comms target transport mission character",comms_target.transport_mission.character)
            -- print("comms target transport mission destination",comms_target.transport_mission.destination,"name:",comms_target.transport_mission.destination_name)
            addCommsReply(_("station-comms", "Transport Passenger"), function()
                -- local out = string.format("%s",comms_target.transport_mission.character)
                -- out = string.format(_("station-comms","%s wishes to be transported to %s"),out,comms_target.transport_mission.destination:getFaction())
                -- out = string.format(_("station-comms","%s station %s"),out,comms_target.transport_mission.destination_name)
                -- local sector_name = comms_target.transport_mission.destination:getSectorName()
                -- out = string.format(_("station-comms","%s in sector %s"),out,comms_target.transport_mission.destination:getSectorName())
                -- out = string.format(_("station-comms","%s. Your reputation would increase by %s"),out,comms_target.transport_mission.reward)
                -- out = string.format(_("station-comms","%s if you agree to transport %s."),out,comms_target.transport_mission.character)
                local out = string.format(
                    _(
                        "station-comms",
                        "%s wishes to be transported to %s station %s in sector %s."
                    ),
                    comms_target.transport_mission.character,
                    comms_target.transport_mission.destination:getFaction(),
                    comms_target.transport_mission.destination_name,
                    comms_target.transport_mission.destination:getSectorName()
                )
                out = string.format(
                    _(
                        "station-comms",
                        "%s Transporting %s would increase your reputation by %s."
                    ),
                    out,
                    comms_target.transport_mission.character,
                    comms_target.transport_mission.reward
                )
                setCommsMessage(out)
                -- setCommsMessage(string.format("%s wishes to be transported to %s station %s in sector %s. Your reputation would go up by %s if you agree to transport %s.",comms_target.transport_mission.character,comms_target.transport_mission.destination:getFaction().comms_target.transport_mission.destination_name,comms_target.transport_mission.destination:getSectorName(),comms_target.transport_mission.reward,comms_target.transport_mission.character))
                addCommsReply(
                    string.format(
                        _(
                            "station-comms",
                            "Agree to transport %s to %s station %s"
                        ),
                        comms_target.transport_mission.character,
                        comms_target.transport_mission.destination:getFaction(),
                        comms_target.transport_mission.destination_name
                    ),
                    function()
                        if not comms_source:isDocked(comms_target) then
                            setCommsMessage(
                                _(
                                    "station-comms",
                                    "You need to stay docked for that action."
                                )
                            )
                            return
                        end
                        comms_source.transport_mission =
                            comms_target.transport_mission
                        comms_target.transport_mission = nil
                        setCommsMessage(
                            string.format(
                                _(
                                    "station-comms",
                                    "You direct %s to guest quarters and say, 'Welcome aboard the %s'"
                                ),
                                comms_source.transport_mission.character,
                                comms_source:getCallSign()
                            )
                        )
                        addCommsReply(_("Back"), commsStation)
                    end
                )
                addCommsReply(
                    _("station-comms", "Decline transportation request"),
                    function()
                        if random(1, 5) <= 1 then
                            setCommsMessage(
                                string.format(
                                    _(
                                        "station-comms",
                                        "You tell %s that you cannot take on any transportation missions at this time. The offer disappears from the message board."
                                    ),
                                    comms_target.transport_mission.character
                                )
                            )
                            comms_target.transport_mission = nil
                        else
                            setCommsMessage(
                                string.format(
                                    _(
                                        "station-comms",
                                        "You tell %s that you cannot take on any transportation missions at this time."
                                    ),
                                    comms_target.transport_mission.character
                                )
                            )
                        end
                        addCommsReply(_("Back"), commsStation)
                    end
                )
                addCommsReply(_("Back"), commsStation)
            end)
        end
    end
    mission_character = nil
    if comms_source.cargo_mission ~= nil then
        if comms_source.cargo_mission.loaded then
            if
                comms_source.cargo_mission.destination ~= nil
                and comms_source.cargo_mission.destination:isValid()
            then
                if comms_source.cargo_mission.destination == comms_target then
                    addCommsReply(
                        string.format(
                            _("station-comms", "Deliver cargo to %s on %s"),
                            comms_source.cargo_mission.character,
                            comms_target:getCallSign()
                        ),
                        function()
                            if not comms_source:isDocked(comms_target) then
                                setCommsMessage(
                                    _(
                                        "station-comms",
                                        "You need to stay docked for that action."
                                    )
                                )
                                return
                            end
                            setCommsMessage(
                                string.format(
                                    _(
                                        "station-comms",
                                        "%s thanks you for retrieving the cargo"
                                    ),
                                    comms_source.cargo_mission.character
                                )
                            )
                            comms_source:addReputationPoints(
                                comms_source.cargo_mission.reward
                            )
                            comms_source.cargo_mission = nil
                            addCommsReply(_("Back"), commsStation)
                        end
                    )
                end
            else
                comms_source:addToShipLog(
                    string.format(
                        _(
                            "shipLog",
                            "Automated systems on %s have informed you of the destruction of station %s. Your mission to deliver cargo for %s to %s is no longer valid. You unloaded the cargo and requested the station authorities handle it for the family of %s. You received %s reputation for your efforts. The mission has been removed from your mission log."
                        ),
                        comms_target:getCallSign(),
                        comms_source.cargo_mission.destination_name,
                        comms_source.cargo_mission.character,
                        comms_source.cargo_mission.destination_name,
                        comms_source.cargo_mission.character,
                        comms_source.cargo_mission.reward / 2
                    ),
                    "Yellow"
                )
                comms_source:addReputationPoints(
                    comms_source.cargo_mission.reward / 2
                )
                comms_source.cargo_mission = nil
            end
        else
            if
                comms_source.cargo_mission.origin ~= nil
                and comms_source.cargo_mission.origin:isValid()
            then
                if comms_source.cargo_mission.origin == comms_target then
                    addCommsReply(
                        string.format(
                            _("station-comms", "Pick up cargo for %s"),
                            comms_source.cargo_mission.character
                        ),
                        function()
                            if not comms_source:isDocked(comms_target) then
                                setCommsMessage(
                                    _(
                                        "station-comms",
                                        "You need to stay docked for that action."
                                    )
                                )
                                return
                            end
                            setCommsMessage(
                                string.format(
                                    _(
                                        "station-comms",
                                        "The cargo for %s has been loaded on %s"
                                    ),
                                    comms_source.cargo_mission.character,
                                    comms_source:getCallSign()
                                )
                            )
                            comms_source.cargo_mission.loaded = true
                            addCommsReply(_("Back"), commsStation)
                        end
                    )
                end
            else
                comms_source:addToShipLog(
                    string.format(
                        _(
                            "shipLog",
                            "Automated systems on %s have informed you of the destruction of station %s. Your mission to retrieve cargo for %s from %s is no longer valid and has been removed from your mission log."
                        ),
                        comms_target:getCallSign(),
                        comms_source.cargo_mission.origin_name,
                        comms_source.cargo_mission.character,
                        comms_source.cargo_mission.origin_name
                    ),
                    "Yellow"
                )
                if comms_source.cargo_mission.destination:isValid() then
                    table.insert(
                        comms_source.cargo_mission.destination.residents,
                        comms_source.cargo_mission.character
                    )
                end
                comms_source.cargo_mission = nil
            end
        end
    else
        if comms_target.cargo_mission == nil then
            if comms_target.residents ~= nil then
                mission_character = tableRemoveRandom(comms_target.residents)
                local mission_origin = nil
                if mission_character ~= nil then
                    mission_type = random(1, 100)
                    local origin_pool = {}
                    if mission_type < 20 then
                        for station_index, station in ipairs(circle_stations) do
                            if
                                station ~= nil
                                and station:isValid()
                                and station ~= comms_target
                                and not comms_source:isEnemy(station)
                                and not comms_source:isFriendly(station)
                            then
                                table.insert(origin_pool, station)
                            end
                        end
                        mission_origin = tableRemoveRandom(origin_pool)
                        if mission_origin ~= nil then
                            comms_target.cargo_mission = {
                                ["origin"] = mission_origin,
                                ["origin_name"] = mission_origin:getCallSign(),
                                ["destination"] = comms_target,
                                ["destination_name"] = comms_target:getCallSign(),
                                ["reward"] = 50,
                                ["character"] = mission_character,
                            }
                        else
                            for station_index, station in
                                ipairs(circle_stations)
                            do
                                if
                                    station ~= nil
                                    and station:isValid()
                                    and station ~= comms_target
                                    and comms_source:isFriendly(station)
                                then
                                    table.insert(origin_pool, station)
                                end
                            end
                            mission_origin = tableRemoveRandom(origin_pool)
                            if mission_origin ~= nil then
                                comms_target.cargo_mission = {
                                    ["origin"] = mission_origin,
                                    ["origin_name"] = mission_origin:getCallSign(),
                                    ["destination"] = comms_target,
                                    ["destination_name"] = comms_target:getCallSign(),
                                    ["reward"] = 40,
                                    ["character"] = mission_character,
                                }
                            else
                                for station_index, station in
                                    ipairs(inner_circle)
                                do
                                    if
                                        station ~= nil
                                        and station:isValid()
                                        and station ~= comms_target
                                    then
                                        table.insert(origin_pool, station)
                                    end
                                end
                                mission_origin = tableRemoveRandom(origin_pool)
                                if mission_origin ~= nil then
                                    comms_target.cargo_mission = {
                                        ["origin"] = mission_origin,
                                        ["origin_name"] = mission_origin:getCallSign(),
                                        ["destination"] = comms_target,
                                        ["destination_name"] = comms_target:getCallSign(),
                                        ["reward"] = 30,
                                        ["character"] = mission_character,
                                    }
                                end
                            end
                        end
                    elseif mission_type < 50 then
                        for station_index, station in ipairs(circle_stations) do
                            if
                                station ~= nil
                                and station:isValid()
                                and station ~= comms_target
                                and comms_source:isFriendly(station)
                            then
                                table.insert(origin_pool, station)
                            end
                        end
                        mission_origin = tableRemoveRandom(origin_pool)
                        if mission_origin ~= nil then
                            comms_target.cargo_mission = {
                                ["origin"] = mission_origin,
                                ["origin_name"] = mission_origin:getCallSign(),
                                ["destination"] = comms_target,
                                ["destination_name"] = comms_target:getCallSign(),
                                ["reward"] = 40,
                                ["character"] = mission_character,
                            }
                        else
                            for station_index, station in ipairs(inner_circle) do
                                if
                                    station ~= nil
                                    and station:isValid()
                                    and station ~= comms_target
                                then
                                    table.insert(origin_pool, station)
                                end
                            end
                            mission_origin = tableRemoveRandom(origin_pool)
                            if mission_origin ~= nil then
                                comms_target.cargo_mission = {
                                    ["origin"] = mission_origin,
                                    ["origin_name"] = mission_origin:getCallSign(),
                                    ["destination"] = comms_target,
                                    ["destination_name"] = comms_target:getCallSign(),
                                    ["reward"] = 30,
                                    ["character"] = mission_character,
                                }
                            else
                                for station_index, station in
                                    ipairs(circle_stations)
                                do
                                    if
                                        station ~= nil
                                        and station:isValid()
                                        and station ~= comms_target
                                        and not comms_source:isEnemy(station)
                                        and not comms_source:isFriendly(station)
                                    then
                                        table.insert(origin_pool, station)
                                    end
                                end
                                mission_origin = tableRemoveRandom(origin_pool)
                                if mission_origin ~= nil then
                                    comms_target.cargo_mission = {
                                        ["origin"] = mission_origin,
                                        ["origin_name"] = mission_origin:getCallSign(),
                                        ["destination"] = comms_target,
                                        ["destination_name"] = comms_target:getCallSign(),
                                        ["reward"] = 50,
                                        ["character"] = mission_character,
                                    }
                                end
                            end
                        end
                    else
                        for station_index, station in ipairs(inner_circle) do
                            if
                                station ~= nil
                                and station:isValid()
                                and station ~= comms_target
                            then
                                table.insert(origin_pool, station)
                            end
                        end
                        mission_origin = tableRemoveRandom(origin_pool)
                        if mission_origin ~= nil then
                            comms_target.cargo_mission = {
                                ["origin"] = mission_origin,
                                ["origin_name"] = mission_origin:getCallSign(),
                                ["destination"] = comms_target,
                                ["destination_name"] = comms_target:getCallSign(),
                                ["reward"] = 30,
                                ["character"] = mission_character,
                            }
                        else
                            for station_index, station in
                                ipairs(circle_stations)
                            do
                                if
                                    station ~= nil
                                    and station:isValid()
                                    and station ~= comms_target
                                    and not comms_source:isEnemy(station)
                                then
                                    table.insert(origin_pool, station)
                                end
                            end
                            mission_origin = tableRemoveRandom(origin_pool)
                            if mission_origin ~= nil then
                                local reward = 50
                                if mission_origin:isFriendly(comms_source) then
                                    reward = 40
                                end
                                comms_target.cargo_mission = {
                                    ["origin"] = mission_origin,
                                    ["origin_name"] = mission_origin:getCallSign(),
                                    ["destination"] = comms_target,
                                    ["destination_name"] = comms_target:getCallSign(),
                                    ["reward"] = reward,
                                    ["character"] = mission_character,
                                }
                            end
                        end
                    end
                end
            end
        else
            if not comms_target.cargo_mission.origin:isValid() then
                table.insert(
                    comms_target.residents,
                    comms_target.cargo_mission.character
                )
                comms_target.cargo_mission = nil
            end
        end
        if comms_target.cargo_mission ~= nil then
            addCommsReply(_("station-comms", "Retrieve Cargo"), function()
                -- local out = string.format("%s",comms_target.cargo_mission.character)
                -- out = string.format(_("station-comms","%s wishes you to pick up cargo from %s"),out,comms_target.cargo_mission.origin:getFaction())
                -- out = string.format(_("station-comms","%s station %s"),out,comms_target.cargo_mission.origin_name)
                -- local sector_name = comms_target.cargo_mission.destination:getSectorName()
                -- out = string.format(_("station-comms","%s in sector %s and deliver it here"),out,comms_target.cargo_mission.origin:getSectorName())
                -- out = string.format(_("station-comms","%s. Your reputation would increase by %s"),out,comms_target.cargo_mission.reward)
                -- out = string.format(_("station-comms","%s if you agree to retrieve this cargo for %s."),out,comms_target.cargo_mission.character)
                local out = string.format(
                    _(
                        "station-comms",
                        "%s wishes you to pick up cargo from %s station %s in sector %s and deliver it here."
                    ),
                    comms_target.cargo_mission.character,
                    comms_target.cargo_mission.origin:getFaction(),
                    comms_target.cargo_mission.origin_name,
                    comms_target.cargo_mission.origin:getSectorName()
                )
                out = string.format(
                    _(
                        "station-comms",
                        "%s Retrieving and delivering this cargo for %s would increase your reputation by %s."
                    ),
                    out,
                    comms_target.cargo_mission.character,
                    comms_target.cargo_mission.reward
                )
                setCommsMessage(out)
                addCommsReply(
                    string.format(
                        _("station-comms", "Agree to retrieve cargo for %s"),
                        comms_target.cargo_mission.character
                    ),
                    function()
                        if not comms_source:isDocked(comms_target) then
                            setCommsMessage(
                                _(
                                    "station-comms",
                                    "You need to stay docked for that action."
                                )
                            )
                            return
                        end
                        comms_source.cargo_mission = comms_target.cargo_mission
                        comms_source.cargo_mission.loaded = false
                        comms_target.cargo_mission = nil
                        setCommsMessage(
                            string.format(
                                _(
                                    "station-comms",
                                    "%s thanks you and contacts station %s to let them know that %s will be picking up the cargo."
                                ),
                                comms_source.cargo_mission.character,
                                comms_source.cargo_mission.origin_name,
                                comms_source:getCallSign()
                            )
                        )
                        addCommsReply(_("Back"), commsStation)
                    end
                )
                addCommsReply(
                    _("station-comms", "Decline cargo retrieval request"),
                    function()
                        if random(1, 5) <= 1 then
                            setCommsMessage(
                                string.format(
                                    _(
                                        "station-comms",
                                        "You tell %s that you cannot take on any cargo retrieval missions at this time. The offer disappears from the message board."
                                    ),
                                    comms_target.cargo_mission.character
                                )
                            )
                            comms_target.cargo_mission = nil
                        else
                            setCommsMessage(
                                string.format(
                                    _(
                                        "station-comms",
                                        "You tell %s that you cannot take on any cargo retrieval missions at this time."
                                    ),
                                    comms_target.cargo_mission.character
                                )
                            )
                        end
                        addCommsReply(_("Back"), commsStation)
                    end
                )
                addCommsReply(_("Back"), commsStation)
            end)
        end
    end
end

return M
