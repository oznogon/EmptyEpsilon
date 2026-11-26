-- Shared cartography office station communication menus used in comms_station_menu.

local StationCore = require("comms_station_core.lua")

local M = {}

local main_menu = commsStation

local function addBack()
    addCommsReply(_("Back"), main_menu)
end

local function cartographerCost(service)
    local base_cost = 1
    if service == "apprentice" then
        base_cost = 5
    elseif service == "master" then
        base_cost = 10
    end
    return math.ceil(
        base_cost
            * comms_target.comms_data.reputation_cost_multipliers[StationCore.getFriendStatus()]
    )
end

function M.office(profile)
    main_menu = profile.main_menu or commsStation
    local ctd = comms_target.comms_data
    addCommsReply(
        _("cartographyOffice-comms", "Visit cartography office"),
        function()
            if comms_target.cartographer_description == nil then
                local clerk_choice = math.random(1, 3)
                if clerk_choice == 1 then
                    comms_target.cartographer_description = _(
                        "cartographyOffice-comms",
                        "The clerk behind the desk looks up briefly at you then goes back to filing her nails."
                    )
                elseif clerk_choice == 2 then
                    comms_target.cartographer_description = _(
                        "cartographyOffice-comms",
                        "The clerk behind the desk examines you then returns to grooming her tentacles."
                    )
                else
                    comms_target.cartographer_description = _(
                        "cartographyOffice-comms",
                        "The clerk behind the desk glances at you then returns to preening her feathers."
                    )
                end
            end
            setCommsMessage(
                string.format(
                    _(
                        "cartographyOffice-comms",
                        "%s\n\nYou can examine the brochure on the coffee table, talk to the apprentice cartographer or talk to the master cartographer.\n\nReputation: %i"
                    ),
                    comms_target.cartographer_description,
                    math.floor(comms_source:getReputationPoints())
                )
            )
            addCommsReply(
                _(
                    "cartographyOffice-comms",
                    "What's the difference between the apprentice and the master?"
                ),
                function()
                    setCommsMessage(
                        _(
                            "cartographyOffice-comms",
                            "The clerk responds in a bored voice, 'The apprentice knows the local area and is learning the broader area. The master knows the local and the broader area but can't be bothered with the local area'"
                        )
                    )
                    addBack()
                end
            )
            addCommsReply(
                string.format(
                    _("cartographyOffice-comms", "Examine brochure (%i rep)"),
                    cartographerCost()
                ),
                function()
                    if
                        comms_source:takeReputationPoints(cartographerCost())
                    then
                        setCommsMessage(
                            string.format(
                                _(
                                    "cartographyOffice-comms",
                                    "The brochure has a list of nearby stations and has a list of goods nearby.\n\nReputation: %i"
                                ),
                                math.floor(comms_source:getReputationPoints())
                            )
                        )
                        addCommsReply(
                            string.format(
                                _(
                                    "cartographyOffice-comms",
                                    "Examine station list (%i rep)"
                                ),
                                cartographerCost()
                            ),
                            function()
                                if
                                    comms_source:takeReputationPoints(
                                        cartographerCost()
                                    )
                                then
                                    local brochure_stations = ""
                                    local sx, sy = comms_target:getPosition()
                                    local nearby_objects =
                                        getObjectsInRadius(sx, sy, 30000)
                                    for i, obj in ipairs(nearby_objects) do
                                        if
                                            isObjectType(obj, "SpaceStation")
                                        then
                                            if
                                                not obj:isEnemy(comms_target)
                                            then
                                                if brochure_stations == "" then
                                                    brochure_stations =
                                                        string.format(
                                                            _(
                                                                "cartographyOffice-comms",
                                                                "%s %s %s"
                                                            ),
                                                            obj:getSectorName(),
                                                            obj:getFaction(),
                                                            obj:getCallSign()
                                                        )
                                                else
                                                    brochure_stations =
                                                        string.format(
                                                            _(
                                                                "cartographyOffice-comms",
                                                                "%s\n%s %s %s"
                                                            ),
                                                            brochure_stations,
                                                            obj:getSectorName(),
                                                            obj:getFaction(),
                                                            obj:getCallSign()
                                                        )
                                                end
                                            end
                                        end
                                    end
                                    setCommsMessage(brochure_stations)
                                else
                                    setCommsMessage(
                                        _(
                                            "needRep-comms",
                                            "Insufficient reputation"
                                        )
                                    )
                                end
                                addBack()
                            end
                        )
                        addCommsReply(
                            string.format(
                                _(
                                    "cartographyOffice-comms",
                                    "Examine goods list (%i rep)"
                                ),
                                cartographerCost()
                            ),
                            function()
                                if
                                    comms_source:takeReputationPoints(
                                        cartographerCost()
                                    )
                                then
                                    local brochure_goods = ""
                                    local sx, sy = comms_target:getPosition()
                                    local nearby_objects =
                                        getObjectsInRadius(sx, sy, 30000)
                                    for i, obj in ipairs(nearby_objects) do
                                        if
                                            isObjectType(obj, "SpaceStation")
                                        then
                                            if
                                                not obj:isEnemy(comms_target)
                                            then
                                                if
                                                    obj.comms_data.goods ~= nil
                                                then
                                                    for good, good_data in
                                                        pairs(
                                                            obj.comms_data.goods
                                                        )
                                                    do
                                                        if
                                                            brochure_goods == ""
                                                        then
                                                            brochure_goods =
                                                                string.format(
                                                                    _(
                                                                        "cartographyOffice-comms",
                                                                        "Good, quantity, cost, station:\n%s, %i, %i, %s"
                                                                    ),
                                                                    good,
                                                                    good_data["quantity"],
                                                                    good_data["cost"],
                                                                    obj:getCallSign()
                                                                )
                                                        else
                                                            brochure_goods =
                                                                string.format(
                                                                    _(
                                                                        "cartographyOffice-comms",
                                                                        "%s\n%s, %i, %i, %s"
                                                                    ),
                                                                    brochure_goods,
                                                                    good,
                                                                    good_data["quantity"],
                                                                    good_data["cost"],
                                                                    obj:getCallSign()
                                                                )
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                    setCommsMessage(brochure_goods)
                                else
                                    setCommsMessage(
                                        _(
                                            "needRep-comms",
                                            "Insufficient reputation"
                                        )
                                    )
                                end
                                addBack()
                            end
                        )
                        if ctd.character_brochure == nil then
                            local upgrade_stations = {}
                            local sx, sy = comms_target:getPosition()
                            local nearby_objects =
                                getObjectsInRadius(sx, sy, 30000)
                            for i, obj in ipairs(nearby_objects) do
                                if isObjectType(obj, "SpaceStation") then
                                    if not obj:isEnemy(comms_target) then
                                        if
                                            obj.comms_data.characterDescription
                                            ~= nil
                                        then
                                            if distance_diagnostic then
                                                print(
                                                    "distance_diagnostic 1",
                                                    obj,
                                                    sx,
                                                    sy
                                                )
                                            end
                                            local sd = distance(obj, sx, sy)
                                            if
                                                random(0, 1)
                                                < (1 - (sd / 30000))
                                            then
                                                table.insert(
                                                    upgrade_stations,
                                                    obj
                                                )
                                            end
                                        end
                                    end
                                end
                            end
                            ctd.character_brochure = upgrade_stations
                        end
                        if #ctd.character_brochure > 0 then
                            addCommsReply(
                                string.format(
                                    _(
                                        "cartographyOffice-comms",
                                        "Examine upgrades list (%i rep)"
                                    ),
                                    cartographerCost()
                                ),
                                function()
                                    if
                                        comms_source:takeReputationPoints(
                                            cartographerCost()
                                        )
                                    then
                                        local brochure_upgrades = ""
                                        for i = 1, #ctd.character_brochure do
                                            local upgrade_station =
                                                ctd.character_brochure[i]
                                            if brochure_upgrades == "" then
                                                brochure_upgrades =
                                                    string.format(
                                                        _(
                                                            "cartographyOffice-comms",
                                                            "%s: %s: %s"
                                                        ),
                                                        upgrade_station:getCallSign(),
                                                        upgrade_station.comms_data.character,
                                                        upgrade_station.comms_data.characterDescription
                                                    )
                                            else
                                                brochure_upgrades =
                                                    string.format(
                                                        _(
                                                            "cartographyOffice-comms",
                                                            "%s\n%s: %s: %s"
                                                        ),
                                                        brochure_upgrades,
                                                        upgrade_station:getCallSign(),
                                                        upgrade_station.comms_data.character,
                                                        upgrade_station.comms_data.characterDescription
                                                    )
                                            end
                                        end
                                        setCommsMessage(brochure_upgrades)
                                    else
                                        setCommsMessage(
                                            _(
                                                "needRep-comms",
                                                "Insufficient reputation"
                                            )
                                        )
                                    end
                                    addBack()
                                end
                            )
                        end
                    else
                        setCommsMessage(
                            _("needRep-comms", "Insufficient reputation")
                        )
                    end
                    addBack()
                end
            )
            addCommsReply(
                string.format(
                    _(
                        "cartographyOffice-comms",
                        "Talk to apprentice cartographer (%i rep)"
                    ),
                    cartographerCost("apprentice")
                ),
                function()
                    if comms_source:takeReputationPoints(1) then
                        if ctd.character_apprentice == nil then
                            local upgrade_stations = {}
                            local sx, sy = comms_target:getPosition()
                            local nearby_objects =
                                getObjectsInRadius(sx, sy, 30000)
                            for i, obj in ipairs(nearby_objects) do
                                if isObjectType(obj, "SpaceStation") then
                                    if not obj:isEnemy(comms_target) then
                                        if
                                            obj.comms_data.characterDescription
                                            ~= nil
                                        then
                                            table.insert(upgrade_stations, obj)
                                        end
                                    end
                                end
                            end
                            ctd.character_apprentice = upgrade_stations
                        end
                        if #ctd.character_apprentice > 0 then
                            setCommsMessage(
                                _(
                                    "cartographyOffice-comms",
                                    "Hi, would you like for me to locate a station, some goods or some upgrades for you?"
                                )
                            )
                        else
                            setCommsMessage(
                                _(
                                    "cartographyOffice-comms",
                                    "Hi, would you like for me to locate a station or some goods for you?"
                                )
                            )
                        end
                        addCommsReply(
                            _("cartographyOffice-comms", "Locate station"),
                            function()
                                setCommsMessage(
                                    _(
                                        "cartographyOffice-comms",
                                        "These are stations I have learned"
                                    )
                                )
                                local sx, sy = comms_target:getPosition()
                                local nearby_objects =
                                    getObjectsInRadius(sx, sy, 50000)
                                local stations_known = 0
                                for i, obj in ipairs(nearby_objects) do
                                    if isObjectType(obj, "SpaceStation") then
                                        if not obj:isEnemy(comms_target) then
                                            stations_known = stations_known + 1
                                            addCommsReply(
                                                obj:getCallSign(),
                                                function()
                                                    local station_details =
                                                        string.format(
                                                            _(
                                                                "cartographyOffice-comms",
                                                                "%s %s %s"
                                                            ),
                                                            obj:getSectorName(),
                                                            obj:getFaction(),
                                                            obj:getCallSign()
                                                        )
                                                    if
                                                        obj.comms_data.goods
                                                        ~= nil
                                                    then
                                                        station_details =
                                                            string.format(
                                                                _(
                                                                    "cartographyOffice-comms",
                                                                    "%s\nGood, quantity, cost"
                                                                ),
                                                                station_details
                                                            )
                                                        for good, good_data in
                                                            pairs(
                                                                obj.comms_data.goods
                                                            )
                                                        do
                                                            station_details =
                                                                string.format(
                                                                    _(
                                                                        "cartographyOffice-comms",
                                                                        "%s\n   %s, %i, %i"
                                                                    ),
                                                                    station_details,
                                                                    good,
                                                                    good_data["quantity"],
                                                                    good_data["cost"]
                                                                )
                                                        end
                                                    end
                                                    if
                                                        obj.comms_data.general
                                                        ~= nil
                                                    then
                                                        station_details =
                                                            string.format(
                                                                _(
                                                                    "stationGeneralInfo-comms",
                                                                    "%s\nGeneral Information:\n   %s"
                                                                ),
                                                                station_details,
                                                                obj.comms_data.general
                                                            )
                                                    end
                                                    if
                                                        obj.comms_data.history
                                                        ~= nil
                                                    then
                                                        station_details =
                                                            string.format(
                                                                _(
                                                                    "stationStory-comms",
                                                                    "%s\nHistory:\n   %s"
                                                                ),
                                                                station_details,
                                                                obj.comms_data.history
                                                            )
                                                    end
                                                    if
                                                        obj.comms_data.gossip
                                                        ~= nil
                                                    then
                                                        station_details =
                                                            string.format(
                                                                _(
                                                                    "gossip-comms",
                                                                    "%s\nGossip:\n   %s"
                                                                ),
                                                                station_details,
                                                                obj.comms_data.gossip
                                                            )
                                                    end
                                                    if
                                                        obj.comms_data.characterDescription
                                                        ~= nil
                                                    then
                                                        station_details =
                                                            string.format(
                                                                _(
                                                                    "cartographyOffice-comms",
                                                                    "%s\n%s:\n   %s"
                                                                ),
                                                                station_details,
                                                                obj.comms_data.character,
                                                                obj.comms_data.characterDescription
                                                            )
                                                    end
                                                    setCommsMessage(
                                                        station_details
                                                    )
                                                    addBack()
                                                end
                                            )
                                        end
                                    end
                                end
                                if stations_known == 0 then
                                    setCommsMessage(
                                        _(
                                            "cartographyOffice-comms",
                                            "I have learned of no stations yet"
                                        )
                                    )
                                end
                                addBack()
                            end
                        )
                        addCommsReply(
                            _("cartographyOffice-comms", "Locate goods"),
                            function()
                                setCommsMessage(
                                    _(
                                        "cartographyOffice-comms",
                                        "These are the goods I know about"
                                    )
                                )
                                local sx, sy = comms_target:getPosition()
                                local nearby_objects =
                                    getObjectsInRadius(sx, sy, 50000)
                                local button_count = 0
                                local by_goods = {}
                                for i, obj in ipairs(nearby_objects) do
                                    if isObjectType(obj, "SpaceStation") then
                                        if not obj:isEnemy(comms_target) then
                                            if obj.comms_data.goods ~= nil then
                                                for good, good_data in
                                                    pairs(obj.comms_data.goods)
                                                do
                                                    by_goods[good] = obj
                                                end
                                            end
                                        end
                                    end
                                end
                                for good, obj in pairs(by_goods) do
                                    addCommsReply(good, function()
                                        local station_details = string.format(
                                            _(
                                                "cartographyOffice-comms",
                                                "%s %s %s"
                                            ),
                                            obj:getSectorName(),
                                            obj:getFaction(),
                                            obj:getCallSign()
                                        )
                                        if obj.comms_data.goods ~= nil then
                                            station_details = string.format(
                                                _(
                                                    "cartographyOffice-comms",
                                                    "%s\nGood, quantity, cost"
                                                ),
                                                station_details
                                            )
                                            for good, good_data in
                                                pairs(obj.comms_data.goods)
                                            do
                                                station_details = string.format(
                                                    _(
                                                        "cartographyOffice-comms",
                                                        "%s\n   %s, %i, %i"
                                                    ),
                                                    station_details,
                                                    good,
                                                    good_data["quantity"],
                                                    good_data["cost"]
                                                )
                                            end
                                        end
                                        if obj.comms_data.general ~= nil then
                                            station_details = string.format(
                                                _(
                                                    "stationGeneralInfo-comms",
                                                    "%s\nGeneral Information:\n   %s"
                                                ),
                                                station_details,
                                                obj.comms_data.general
                                            )
                                        end
                                        if obj.comms_data.history ~= nil then
                                            station_details = string.format(
                                                _(
                                                    "stationStory-comms",
                                                    "%s\nHistory:\n   %s"
                                                ),
                                                station_details,
                                                obj.comms_data.history
                                            )
                                        end
                                        if obj.comms_data.gossip ~= nil then
                                            station_details = string.format(
                                                _(
                                                    "gossip-comms",
                                                    "%s\nGossip:\n   %s"
                                                ),
                                                station_details,
                                                obj.comms_data.gossip
                                            )
                                        end
                                        if
                                            obj.comms_data.characterDescription
                                            ~= nil
                                        then
                                            station_details = string.format(
                                                _(
                                                    "cartographyOffice-comms",
                                                    "%s\n%s:\n   %s"
                                                ),
                                                station_details,
                                                obj.comms_data.character,
                                                obj.comms_data.characterDescription
                                            )
                                        end
                                        setCommsMessage(station_details)
                                        addBack()
                                    end)
                                    button_count = button_count + 1
                                    if button_count >= 20 then
                                        break
                                    end
                                end
                                addBack()
                            end
                        )
                        if #ctd.character_apprentice > 0 then
                            addCommsReply(
                                _(
                                    "cartographyOffice-comms",
                                    "Locate upgrade station"
                                ),
                                function()
                                    setCommsMessage(
                                        _(
                                            "cartographyOffice-comms",
                                            "These are stations I have learned that have upgrades"
                                        )
                                    )
                                    local sx, sy = comms_target:getPosition()
                                    local nearby_objects =
                                        getObjectsInRadius(sx, sy, 50000)
                                    local stations_known = 0
                                    for i, obj in ipairs(nearby_objects) do
                                        if
                                            isObjectType(obj, "SpaceStation")
                                        then
                                            if
                                                not obj:isEnemy(comms_target)
                                            then
                                                if
                                                    obj.comms_data.characterDescription
                                                    ~= nil
                                                then
                                                    stations_known = stations_known
                                                        + 1
                                                    addCommsReply(
                                                        obj:getCallSign(),
                                                        function()
                                                            local station_details =
                                                                string.format(
                                                                    _(
                                                                        "cartographyOffice-comms",
                                                                        "%s %s %s"
                                                                    ),
                                                                    obj:getSectorName(),
                                                                    obj:getFaction(),
                                                                    obj:getCallSign()
                                                                )
                                                            if
                                                                obj.comms_data.goods
                                                                ~= nil
                                                            then
                                                                station_details =
                                                                    string.format(
                                                                        _(
                                                                            "cartographyOffice-comms",
                                                                            "%s\nGood, quantity, cost"
                                                                        ),
                                                                        station_details
                                                                    )
                                                                for
                                                                    good,
                                                                    good_data
                                                                in
                                                                    pairs(
                                                                        obj.comms_data.goods
                                                                    )
                                                                do
                                                                    station_details =
                                                                        string.format(
                                                                            _(
                                                                                "cartographyOffice-comms",
                                                                                "%s\n   %s, %i, %i"
                                                                            ),
                                                                            station_details,
                                                                            good,
                                                                            good_data["quantity"],
                                                                            good_data["cost"]
                                                                        )
                                                                end
                                                            end
                                                            if
                                                                obj.comms_data.general
                                                                ~= nil
                                                            then
                                                                station_details =
                                                                    string.format(
                                                                        _(
                                                                            "stationGeneralInfo-comms",
                                                                            "%s\nGeneral Information:\n   %s"
                                                                        ),
                                                                        station_details,
                                                                        obj.comms_data.general
                                                                    )
                                                            end
                                                            if
                                                                obj.comms_data.history
                                                                ~= nil
                                                            then
                                                                station_details =
                                                                    string.format(
                                                                        _(
                                                                            "stationStory-comms",
                                                                            "%s\nHistory:\n   %s"
                                                                        ),
                                                                        station_details,
                                                                        obj.comms_data.history
                                                                    )
                                                            end
                                                            if
                                                                obj.comms_data.gossip
                                                                ~= nil
                                                            then
                                                                station_details =
                                                                    string.format(
                                                                        _(
                                                                            "gossip-comms",
                                                                            "%s\nGossip:\n   %s"
                                                                        ),
                                                                        station_details,
                                                                        obj.comms_data.gossip
                                                                    )
                                                            end
                                                            if
                                                                obj.comms_data.characterDescription
                                                                ~= nil
                                                            then
                                                                station_details =
                                                                    string.format(
                                                                        _(
                                                                            "cartographyOffice-comms",
                                                                            "%s\n%s:\n   %s"
                                                                        ),
                                                                        station_details,
                                                                        obj.comms_data.character,
                                                                        obj.comms_data.characterDescription
                                                                    )
                                                            end
                                                            setCommsMessage(
                                                                station_details
                                                            )
                                                            addBack()
                                                        end
                                                    )
                                                end
                                            end
                                        end
                                    end
                                    if stations_known == 0 then
                                        setCommsMessage(
                                            _(
                                                "cartographyOffice-comms",
                                                "I have learned of no upgrade stations yet"
                                            )
                                        )
                                    end
                                end
                            )
                        end
                    else
                        setCommsMessage(
                            _("needRep-comms", "Insufficient reputation")
                        )
                    end
                    addBack()
                end
            )
            addCommsReply(
                string.format(
                    _(
                        "cartographyOffice-comms",
                        "Talk to master cartographer (%i rep)"
                    ),
                    cartographerCost("master")
                ),
                function()
                    if comms_source:getWaypointCount() >= 9 then
                        setCommsMessage(
                            _(
                                "cartographyOffice-comms",
                                "The clerk clears her throat:\n\nMy indicators show you have zero available waypoints. To get the most from the master cartographer, you should delete one or more so that he can update your systems appropriately.\n\nI just want you to get the maximum benefit for the time you spend with him"
                            )
                        )
                        addCommsReply(
                            _(
                                "cartographyOffice-comms",
                                "Continue to Master Cartographer"
                            ),
                            M.masterCartographer
                        )
                    else
                        M.masterCartographer()
                    end
                    addBack()
                end
            )
            addBack()
        end
    )
end

function M.masterCartographer()
    local ctd = comms_target.comms_data
    if comms_source:takeReputationPoints(cartographerCost("master")) then
        if ctd.character_master == nil then
            local upgrade_stations = {}
            local nearby_objects = getAllObjects()
            local station_distance = 0
            for i, obj in ipairs(nearby_objects) do
                if isObjectType(obj, "SpaceStation") then
                    if not obj:isEnemy(comms_target) then
                        if distance_diagnostic then
                            print("distance_diagnostic 2", comms_target, obj)
                        end
                        station_distance = distance(comms_target, obj)
                        if station_distance > 50000 then
                            if obj.comms_data.characterDescription ~= nil then
                                table.insert(upgrade_stations, obj)
                            end
                        end
                    end
                end
            end
            ctd.character_master = upgrade_stations
        end
        if #ctd.character_master > 0 then
            setCommsMessage(
                _(
                    "cartographyOffice-comms",
                    "Greetings,\nMay I help you find a station, goods or an upgrade?"
                )
            )
        else
            setCommsMessage(
                _(
                    "cartographyOffice-comms",
                    "Greetings,\nMay I help you find a station or goods?"
                )
            )
        end
        addCommsReply(_("cartographyOffice-comms", "Find station"), function()
            setCommsMessage(_("cartographyOffice-comms", "What station?"))
            local nearby_objects = getAllObjects()
            local stations_known = 0
            local station_distance = 0
            for i, obj in ipairs(nearby_objects) do
                if isObjectType(obj, "SpaceStation") then
                    if not obj:isEnemy(comms_target) then
                        if distance_diagnostic then
                            print("distance_diagnostic 3", comms_target, obj)
                        end
                        station_distance = distance(comms_target, obj)
                        if station_distance > 50000 then
                            stations_known = stations_known + 1
                            addCommsReply(obj:getCallSign(), function()
                                local station_details = string.format(
                                    _(
                                        "cartographyOffice-comms",
                                        "%s %s %s Distance:%.1fU"
                                    ),
                                    obj:getSectorName(),
                                    obj:getFaction(),
                                    obj:getCallSign(),
                                    station_distance / 1000
                                )
                                if obj.comms_data.goods ~= nil then
                                    station_details = string.format(
                                        _(
                                            "cartographyOffice-comms",
                                            "%s\nGood, quantity, cost"
                                        ),
                                        station_details
                                    )
                                    for good, good_data in
                                        pairs(obj.comms_data.goods)
                                    do
                                        station_details = string.format(
                                            _(
                                                "cartographyOffice-comms",
                                                "%s\n   %s, %i, %i"
                                            ),
                                            station_details,
                                            good,
                                            good_data["quantity"],
                                            good_data["cost"]
                                        )
                                    end
                                end
                                if obj.comms_data.general ~= nil then
                                    station_details = string.format(
                                        _(
                                            "stationGeneralInfo-comms",
                                            "%s\nGeneral Information:\n   %s"
                                        ),
                                        station_details,
                                        obj.comms_data.general
                                    )
                                end
                                if obj.comms_data.history ~= nil then
                                    station_details = string.format(
                                        _(
                                            "stationStory-comms",
                                            "%s\nHistory:\n   %s"
                                        ),
                                        station_details,
                                        obj.comms_data.history
                                    )
                                end
                                if obj.comms_data.gossip ~= nil then
                                    station_details = string.format(
                                        _("gossip-comms", "%s\nGossip:\n   %s"),
                                        station_details,
                                        obj.comms_data.gossip
                                    )
                                end
                                if
                                    obj.comms_data.characterDescription ~= nil
                                then
                                    station_details = string.format(
                                        _(
                                            "cartographyOffice-comms",
                                            "%s\n%s:\n   %s"
                                        ),
                                        station_details,
                                        obj.comms_data.character,
                                        obj.comms_data.characterDescription
                                    )
                                end
                                local dsx, dsy = obj:getPosition()
                                comms_source:commandAddWaypoint(dsx, dsy)
                                station_details = string.format(
                                    _(
                                        "cartographyOffice-comms",
                                        "%s\nAdded waypoint %i to your navigation system for %s"
                                    ),
                                    station_details,
                                    comms_source:getWaypointID(
                                        comms_source:getWaypointCount()
                                    ),
                                    obj:getCallSign()
                                )
                                setCommsMessage(station_details)
                                addBack()
                            end)
                        end
                    end
                end
            end
            if stations_known == 0 then
                setCommsMessage(
                    _(
                        "cartographyOffice-comms",
                        "Try the apprentice, I'm tired"
                    )
                )
            end
            addBack()
        end)
        addCommsReply(_("cartographyOffice-comms", "Find Goods"), function()
            setCommsMessage(
                _("cartographyOffice-comms", "What goods are you looking for?")
            )
            local nearby_objects = getAllObjects()
            local by_goods = {}
            for i, obj in ipairs(nearby_objects) do
                if isObjectType(obj, "SpaceStation") then
                    if not obj:isEnemy(comms_target) then
                        if distance_diagnostic then
                            print("distance_diagnostic 4", comms_target, obj)
                        end
                        local station_distance = distance(comms_target, obj)
                        if station_distance > 50000 then
                            if obj.comms_data.goods ~= nil then
                                for good, good_data in
                                    pairs(obj.comms_data.goods)
                                do
                                    by_goods[good] = obj
                                end
                            end
                        end
                    end
                end
            end
            for good, obj in pairs(by_goods) do
                addCommsReply(good, function()
                    if distance_diagnostic then
                        print("distance_diagnostic 5", comms_target, obj)
                    end
                    local station_distance = distance(comms_target, obj)
                    local station_details = string.format(
                        _("cartographyOffice-comms", "%s %s %s Distance:%.1fU"),
                        obj:getSectorName(),
                        obj:getFaction(),
                        obj:getCallSign(),
                        station_distance / 1000
                    )
                    if obj.comms_data.goods ~= nil then
                        station_details = string.format(
                            _(
                                "cartographyOffice-comms",
                                "%s\nGood, quantity, cost"
                            ),
                            station_details
                        )
                        for good, good_data in pairs(obj.comms_data.goods) do
                            station_details = string.format(
                                _(
                                    "cartographyOffice-comms",
                                    "%s\n   %s, %i, %i"
                                ),
                                station_details,
                                good,
                                good_data["quantity"],
                                good_data["cost"]
                            )
                        end
                    end
                    if obj.comms_data.general ~= nil then
                        station_details = string.format(
                            _(
                                "stationGeneralInfo-comms",
                                "%s\nGeneral Information:\n   %s"
                            ),
                            station_details,
                            obj.comms_data.general
                        )
                    end
                    if obj.comms_data.history ~= nil then
                        station_details = string.format(
                            _("stationStory-comms", "%s\nHistory:\n   %s"),
                            station_details,
                            obj.comms_data.history
                        )
                    end
                    if obj.comms_data.gossip ~= nil then
                        station_details = string.format(
                            _("gossip-comms", "%s\nGossip:\n   %s"),
                            station_details,
                            obj.comms_data.gossip
                        )
                    end
                    if obj.comms_data.characterDescription ~= nil then
                        station_details = string.format(
                            _("cartographyOffice-comms", "%s\n%s:\n   %s"),
                            station_details,
                            obj.comms_data.character,
                            obj.comms_data.characterDescription
                        )
                    end
                    local dsx, dsy = obj:getPosition()
                    comms_source:commandAddWaypoint(dsx, dsy)
                    station_details = string.format(
                        _(
                            "cartographyOffice-comms",
                            "%s\nAdded waypoint %i to your navigation system for %s"
                        ),
                        station_details,
                        comms_source:getWaypointID(
                            comms_source:getWaypointCount()
                        ),
                        obj:getCallSign()
                    )
                    setCommsMessage(station_details)
                    addBack()
                end)
            end
            addBack()
        end)
        if #ctd.character_master > 0 then
            addCommsReply(
                _("cartographyOffice-comms", "Find Upgrade Station"),
                function()
                    setCommsMessage(
                        _("cartographyOffice-comms", "What station?")
                    )
                    for i = 1, #ctd.character_master do
                        local obj = ctd.character_master[i]
                        if distance_diagnostic then
                            print("distance_diagnostic 6", comms_target, obj)
                        end
                        station_distance = distance(comms_target, obj)
                        addCommsReply(obj:getCallSign(), function()
                            local station_details = string.format(
                                _(
                                    "cartographyOffice-comms",
                                    "%s %s %s Distance:%.1fU"
                                ),
                                obj:getSectorName(),
                                obj:getFaction(),
                                obj:getCallSign(),
                                station_distance / 1000
                            )
                            if obj.comms_data.goods ~= nil then
                                station_details = string.format(
                                    _(
                                        "cartographyOffice-comms",
                                        "%s\nGood, quantity, cost"
                                    ),
                                    station_details
                                )
                                for good, good_data in
                                    pairs(obj.comms_data.goods)
                                do
                                    station_details = string.format(
                                        _(
                                            "cartographyOffice-comms",
                                            "%s\n   %s, %i, %i"
                                        ),
                                        station_details,
                                        good,
                                        good_data["quantity"],
                                        good_data["cost"]
                                    )
                                end
                            end
                            if obj.comms_data.general ~= nil then
                                station_details = string.format(
                                    _(
                                        "stationGeneralInfo-comms",
                                        "%s\nGeneral Information:\n   %s"
                                    ),
                                    station_details,
                                    obj.comms_data.general
                                )
                            end
                            if obj.comms_data.history ~= nil then
                                station_details = string.format(
                                    _(
                                        "stationStory-comms",
                                        "%s\nHistory:\n   %s"
                                    ),
                                    station_details,
                                    obj.comms_data.history
                                )
                            end
                            if obj.comms_data.gossip ~= nil then
                                station_details = string.format(
                                    _("gossip-comms", "%s\nGossip:\n   %s"),
                                    station_details,
                                    obj.comms_data.gossip
                                )
                            end
                            if obj.comms_data.characterDescription ~= nil then
                                station_details = string.format(
                                    _(
                                        "cartographyOffice-comms",
                                        "%s\n%s:\n   %s"
                                    ),
                                    station_details,
                                    obj.comms_data.character,
                                    obj.comms_data.characterDescription
                                )
                            end
                            local dsx, dsy = obj:getPosition()
                            comms_source:commandAddWaypoint(dsx, dsy)
                            station_details = string.format(
                                _(
                                    "cartographyOffice-comms",
                                    "%s\nAdded waypoint %i to your navigation system for %s"
                                ),
                                station_details,
                                comms_source:getWaypointID(
                                    comms_source:getWaypointCount()
                                ),
                                obj:getCallSign()
                            )
                            setCommsMessage(station_details)
                            addBack()
                        end)
                    end
                end
            )
        end
    else
        setCommsMessage(_("needRep-comms", "Insufficient Reputation"))
    end
end
return M
