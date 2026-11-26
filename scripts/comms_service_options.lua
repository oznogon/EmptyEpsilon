-- Service-Jonque repair and ordnance menu from Planet Devourer, Doomed Outpost, and The Omicron Plague.

local ShipComms = require("comms_ship_support.lua")
local StationCore = require("comms_station_core.lua")

local M = {}

function M.serviceJonque(options)
    return function()
        return ShipComms.serviceJonqueComms(options)
    end
end

function M.commonServiceOptions()
    addCommsReply(_("shipServices-comms", "Service options"), function()
        local offer_repair = false
        if not comms_source:getCanLaunchProbe() then
            offer_repair = true
        end
        if not offer_repair and not comms_source:getCanHack() then
            offer_repair = true
        end
        if not offer_repair and not comms_source:getCanScan() then
            offer_repair = true
        end
        if not offer_repair and not comms_source:getCanCombatManeuver() then
            offer_repair = true
        end
        if not offer_repair and not comms_source:getCanSelfDestruct() then
            offer_repair = true
        end
        if offer_repair then
            addCommsReply(
                _("shipServices-comms", "Repair ship system"),
                function()
                    setCommsMessage(
                        _(
                            "shipServices-comms",
                            "What system would you like repaired?"
                        )
                    )
                    if not comms_source:getCanLaunchProbe() then
                        addCommsReply(
                            _(
                                "shipServices-comms",
                                "Repair probe launch system"
                            ),
                            function()
                                if
                                    distance(comms_source, comms_target) < 5000
                                then
                                    comms_source:setCanLaunchProbe(true)
                                    setCommsMessage(
                                        _(
                                            "shipServices-comms",
                                            "Your probe launch system has been repaired"
                                        )
                                    )
                                else
                                    setCommsMessage(
                                        _(
                                            "shipServices-comms",
                                            "You need to stay close if you want me to fix your ship"
                                        )
                                    )
                                end
                                addCommsReply(_("Back"), commsServiceJonque)
                            end
                        )
                    end
                    if not comms_source:getCanHack() then
                        addCommsReply(
                            _("shipServices-comms", "Repair hacking system"),
                            function()
                                if
                                    distance(comms_source, comms_target) < 5000
                                then
                                    comms_source:setCanHack(true)
                                    setCommsMessage(
                                        _(
                                            "shipServices-comms",
                                            "Your hack system has been repaired"
                                        )
                                    )
                                else
                                    setCommsMessage(
                                        _(
                                            "shipServices-comms",
                                            "You need to stay close if you want me to fix your ship"
                                        )
                                    )
                                end
                                addCommsReply(_("Back"), commsServiceJonque)
                            end
                        )
                    end
                    if not comms_source:getCanScan() then
                        addCommsReply(
                            _("shipServices-comms", "Repair scanning system"),
                            function()
                                if
                                    distance(comms_source, comms_target) < 5000
                                then
                                    comms_source:setCanScan(true)
                                    setCommsMessage(
                                        _(
                                            "shipServices-comms",
                                            "Your scanners have been repaired"
                                        )
                                    )
                                else
                                    setCommsMessage(
                                        _(
                                            "shipServices-comms",
                                            "You need to stay close if you want me to fix your ship"
                                        )
                                    )
                                end
                                addCommsReply(_("Back"), commsServiceJonque)
                            end
                        )
                    end
                    if not comms_source:getCanCombatManeuver() then
                        addCommsReply(
                            _("shipServices-comms", "Repair combat maneuver"),
                            function()
                                if
                                    distance(comms_source, comms_target) < 5000
                                then
                                    comms_source:setCanCombatManeuver(true)
                                    setCommsMessage(
                                        _(
                                            "shipServices-comms",
                                            "Your combat maneuver has been repaired"
                                        )
                                    )
                                else
                                    setCommsMessage(
                                        _(
                                            "shipServices-comms",
                                            "You need to stay close if you want me to fix your ship"
                                        )
                                    )
                                end
                                addCommsReply(_("Back"), commsServiceJonque)
                            end
                        )
                    end
                    if not comms_source:getCanSelfDestruct() then
                        addCommsReply(
                            _(
                                "shipServices-comms",
                                "Repair self destruct system"
                            ),
                            function()
                                if
                                    distance(comms_source, comms_target) < 5000
                                then
                                    comms_source:setCanSelfDestruct(true)
                                    setCommsMessage(
                                        _(
                                            "shipServices-comms",
                                            "Your self destruct system has been repaired"
                                        )
                                    )
                                else
                                    setCommsMessage(
                                        _(
                                            "shipServices-comms",
                                            "You need to stay close if you want me to fix your ship"
                                        )
                                    )
                                end
                                addCommsReply(_("Back"), commsServiceJonque)
                            end
                        )
                    end
                    addCommsReply(_("Back"), commsServiceJonque)
                end
            )
        end
        local offer_hull_repair = false
        if comms_source:getHull() < comms_source:getHullMax() then
            offer_hull_repair = true
        end
        if offer_hull_repair then
            local full_repair = comms_source:getHullMax()
                - comms_source:getHull()
            local premium = 30
            if full_repair > 100 then
                premium = 100
            elseif full_repair > 50 then
                premium = 60
            end
            addCommsReply(
                string.format(
                    _("shipServices-comms", "Full hull repair (%i reputation)"),
                    math.floor(full_repair + premium)
                ),
                function()
                    if distance(comms_source, comms_target) < 5000 then
                        if
                            comms_source:takeReputationPoints(
                                math.floor(full_repair + premium)
                            )
                        then
                            comms_source:setHull(comms_source:getHullMax())
                            setCommsMessage(
                                _(
                                    "shipServices-comms",
                                    "All fixed up and ready to go"
                                )
                            )
                        else
                            setCommsMessage(
                                _("needRep-comms", "Insufficient reputation")
                            )
                        end
                    else
                        setCommsMessage(
                            _(
                                "shipServices-comms",
                                "You need to stay close if you want me to fix your ship"
                            )
                        )
                    end
                    addCommsReply(_("Back"), commsServiceJonque)
                end
            )
            addCommsReply(
                string.format(
                    _("shipServices-comms", "Add %i%% to hull (%i reputation)"),
                    math.floor(
                        full_repair / 2 / comms_source:getHullMax() * 100
                    ),
                    math.floor(full_repair / 2 + premium / 2)
                ),
                function()
                    if distance(comms_source, comms_target) < 5000 then
                        if
                            comms_source:takeReputationPoints(
                                math.floor(full_repair / 2 + premium / 2)
                            )
                        then
                            comms_source:setHull(
                                comms_source:getHull() + (full_repair / 2)
                            )
                            setCommsMessage(
                                _(
                                    "shipServices-comms",
                                    "Repairs completed as requested"
                                )
                            )
                        else
                            setCommsMessage(
                                _("needRep-comms", "Insufficient reputation")
                            )
                        end
                    else
                        setCommsMessage(
                            _(
                                "shipServices-comms",
                                "You need to stay close if you want me to fix your ship"
                            )
                        )
                    end
                    addCommsReply(_("Back"), commsServiceJonque)
                end
            )
            addCommsReply(
                string.format(
                    _("shipServices-comms", "Add %i%% to hull (%i reputation)"),
                    math.floor(
                        full_repair / 3 / comms_source:getHullMax() * 100
                    ),
                    math.floor(full_repair / 3)
                ),
                function()
                    if distance(comms_source, comms_target) < 5000 then
                        if
                            comms_source:takeReputationPoints(
                                math.floor(full_repair / 3)
                            )
                        then
                            comms_source:setHull(
                                comms_source:getHull() + (full_repair / 3)
                            )
                            setCommsMessage(
                                _(
                                    "shipServices-comms",
                                    "Repairs completed as requested"
                                )
                            )
                        else
                            setCommsMessage(
                                _("needRep-comms", "Insufficient reputation")
                            )
                        end
                    else
                        setCommsMessage(
                            _(
                                "shipServices-comms",
                                "You need to stay close if you want me to fix your ship"
                            )
                        )
                    end
                    addCommsReply(_("Back"), commsServiceJonque)
                end
            )
        end
        local offer_ordnance = false
        local ordnance_inventory = 0
        for ordnance_type, count in
            pairs(comms_target.comms_data.weapon_inventory)
        do
            ordnance_inventory = ordnance_inventory + count
        end
        local player_missile_types = {
            ["Homing"] = { shoots = false, max = 0, current = 0, need = 0 },
            ["Nuke"] = { shoots = false, max = 0, current = 0, need = 0 },
            ["Mine"] = { shoots = false, max = 0, current = 0, need = 0 },
            ["EMP"] = { shoots = false, max = 0, current = 0, need = 0 },
            ["HVLI"] = { shoots = false, max = 0, current = 0, need = 0 },
        }
        if ordnance_inventory > 0 then
            for missile_type, ord in pairs(player_missile_types) do
                ord.max = comms_source:getWeaponStorageMax(missile_type)
                if ord.max ~= nil and ord.max > 0 then
                    ord.shoots = true
                    ord.current = comms_source:getWeaponStorage(missile_type)
                    if ord.current < ord.max then
                        ord.need = ord.max - ord.current
                        if
                            comms_target.comms_data.weapon_inventory[missile_type]
                            > 0
                        then
                            offer_ordnance = true
                        end
                    end
                end
            end
        end
        if offer_ordnance then
            addCommsReply(_("ammo-comms", "Restock ordnance"), function()
                for missile_type, ord in pairs(player_missile_types) do
                    if
                        ord.current < ord.max
                        and comms_target.comms_data.weapon_inventory[missile_type]
                            > 0
                    then
                        comms_data = comms_target.comms_data
                        setCommsMessage(
                            _("ammo-comms", "What kind of ordnance?")
                        )
                        addCommsReply(
                            string.format(
                                _("ammo-comms", "%s (%i reputation each)"),
                                missile_type,
                                StationCore.getWeaponCost(missile_type)
                            ),
                            function()
                                if
                                    distance(comms_source, comms_target) < 5000
                                then
                                    if
                                        comms_target.comms_data.weapon_inventory[missile_type]
                                        >= ord.need
                                    then
                                        if
                                            comms_source:takeReputationPoints(
                                                StationCore.getWeaponCost(
                                                    missile_type
                                                )
                                                    * ord.need
                                            )
                                        then
                                            comms_source:setWeaponStorage(
                                                missile_type,
                                                ord.max
                                            )
                                            comms_target.comms_data.weapon_inventory[missile_type] = comms_target.comms_data.weapon_inventory[missile_type]
                                                - ord.need
                                            setCommsMessage(
                                                string.format(
                                                    _(
                                                        "ammo-comms",
                                                        "Restocked your %s type ordnance"
                                                    ),
                                                    missile_type
                                                )
                                            )
                                        else
                                            if
                                                comms_source:getReputationPoints()
                                                > StationCore.getWeaponCost(
                                                    missile_type
                                                )
                                            then
                                                setCommsMessage(
                                                    string.format(
                                                        _(
                                                            "needRep-comms",
                                                            "You don't have enough reputation to fully replenish your %s type ordnance. You need %i and you only have %i. How would you like to proceed?"
                                                        ),
                                                        missile_type,
                                                        StationCore.getWeaponCost(
                                                            missile_type
                                                        )
                                                            * ord.need,
                                                        math.floor(
                                                            comms_source:getReputationPoints()
                                                        )
                                                    )
                                                )
                                                addCommsReply(
                                                    string.format(
                                                        _(
                                                            "ammo-comms",
                                                            "Get one (%i reputation)"
                                                        ),
                                                        StationCore.getWeaponCost(
                                                            missile_type
                                                        )
                                                    ),
                                                    function()
                                                        if
                                                            distance(
                                                                comms_source,
                                                                comms_target
                                                            )
                                                            < 5000
                                                        then
                                                            if
                                                                comms_source:takeReputationPoints(
                                                                    StationCore.getWeaponCost(
                                                                        missile_type
                                                                    )
                                                                )
                                                            then
                                                                comms_source:setWeaponStorage(
                                                                    missile_type,
                                                                    comms_source:getWeaponStorage(
                                                                        missile_type
                                                                    )
                                                                        + 1
                                                                )
                                                                comms_target.comms_data.weapon_inventory[missile_type] = comms_target.comms_data.weapon_inventory[missile_type]
                                                                    - 1
                                                                setCommsMessage(
                                                                    string.format(
                                                                        _(
                                                                            "ammo-comms",
                                                                            "One %s provided"
                                                                        ),
                                                                        missile_type
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
                                                        else
                                                            setCommsMessage(
                                                                _(
                                                                    "ammo-comms",
                                                                    "You need to stay close if you want me to restock your ordnance"
                                                                )
                                                            )
                                                        end
                                                        addCommsReply(
                                                            _("Back"),
                                                            commsServiceJonque
                                                        )
                                                    end
                                                )
                                                if
                                                    comms_source:getReputationPoints()
                                                    > StationCore.getWeaponCost(
                                                            missile_type
                                                        )
                                                        * 2
                                                then
                                                    local max_afford = 0
                                                    local missile_count = 0
                                                    repeat
                                                        max_afford = max_afford
                                                            + StationCore.getWeaponCost(
                                                                missile_type
                                                            )
                                                        missile_count = missile_count
                                                            + 1
                                                    until max_afford
                                                            + StationCore.getWeaponCost(
                                                                missile_type
                                                            )
                                                        > comms_source:getReputationPoints()
                                                    addCommsReply(
                                                        string.format(
                                                            _(
                                                                "ammo-comms",
                                                                "Get %i (%i reputation)"
                                                            ),
                                                            missile_count,
                                                            max_afford
                                                        ),
                                                        function()
                                                            if
                                                                distance(
                                                                    comms_source,
                                                                    comms_target
                                                                )
                                                                < 5000
                                                            then
                                                                if
                                                                    comms_source:takeReputationPoints(
                                                                        StationCore.getWeaponCost(
                                                                            missile_type
                                                                        )
                                                                            * missile_count
                                                                    )
                                                                then
                                                                    comms_source:setWeaponStorage(
                                                                        missile_type,
                                                                        comms_source:getWeaponStorage(
                                                                            missile_type
                                                                        )
                                                                            + missile_count
                                                                    )
                                                                    comms_target.comms_data.weapon_inventory[missile_type] = comms_target.comms_data.weapon_inventory[missile_type]
                                                                        - missile_count
                                                                    setCommsMessage(
                                                                        string.format(
                                                                            _(
                                                                                "ammo-comms",
                                                                                "%i %ss provided"
                                                                            ),
                                                                            missile_count,
                                                                            missile_type
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
                                                            else
                                                                setCommsMessage(
                                                                    _(
                                                                        "ammo-comms",
                                                                        "You need to stay close if you want me to restock your ordnance"
                                                                    )
                                                                )
                                                            end
                                                            addCommsReply(
                                                                _("Back"),
                                                                commsServiceJonque
                                                            )
                                                        end
                                                    )
                                                end
                                            else
                                                setCommsMessage(
                                                    _(
                                                        "needRep-comms",
                                                        "Insufficient reputation"
                                                    )
                                                )
                                            end
                                        end
                                    else
                                        setCommsMessage(
                                            string.format(
                                                _(
                                                    "ammo-comms",
                                                    "I don't have enough %s type ordnance to fully restock you. How would you like to proceed?"
                                                ),
                                                missile_type
                                            )
                                        )
                                        addCommsReply(
                                            _(
                                                "ammo-comms",
                                                "We'll take all you've got"
                                            ),
                                            function()
                                                if
                                                    comms_source:takeReputationPoints(
                                                        StationCore.getWeaponCost(
                                                            missile_type
                                                        )
                                                            * comms_target.comms_data.weapon_inventory[missile_type]
                                                    )
                                                then
                                                    comms_source:setWeaponStorage(
                                                        missile_type,
                                                        comms_source:getWeaponStorage(
                                                            missile_type
                                                        )
                                                            + comms_target.comms_data.weapon_inventory[missile_type]
                                                    )
                                                    if
                                                        comms_target.comms_data.weapon_inventory[missile_type]
                                                        > 1
                                                    then
                                                        setCommsMessage(
                                                            string.format(
                                                                _(
                                                                    "ammo-comms",
                                                                    "%i %ss provided"
                                                                ),
                                                                missile_count,
                                                                missile_type
                                                            )
                                                        )
                                                    else
                                                        setCommsMessage(
                                                            string.format(
                                                                _(
                                                                    "ammo-comms",
                                                                    "One %s provided"
                                                                ),
                                                                missile_type
                                                            )
                                                        )
                                                    end
                                                    comms_target.comms_data.weapon_inventory[missile_type] =
                                                        0
                                                else
                                                    setCommsMessage(
                                                        string.format(
                                                            _(
                                                                "needRep-comms",
                                                                "You don't have enough reputation to get all of our %s type ordnance. You need %i and you only have %i. How would you like to proceed?"
                                                            ),
                                                            missile_type,
                                                            StationCore.getWeaponCost(
                                                                missile_type
                                                            )
                                                                * comms_target.comms_data.weapon_inventory[missile_type],
                                                            math.floor(
                                                                comms_source:getReputationPoints()
                                                            )
                                                        )
                                                    )
                                                    addCommsReply(
                                                        string.format(
                                                            _(
                                                                "ammo-comms",
                                                                "Get one (%i reputation)"
                                                            ),
                                                            StationCore.getWeaponCost(
                                                                missile_type
                                                            )
                                                        ),
                                                        function()
                                                            if
                                                                distance(
                                                                    comms_source,
                                                                    comms_target
                                                                )
                                                                < 5000
                                                            then
                                                                if
                                                                    comms_source:takeReputationPoints(
                                                                        StationCore.getWeaponCost(
                                                                            missile_type
                                                                        )
                                                                    )
                                                                then
                                                                    comms_source:setWeaponStorage(
                                                                        missile_type,
                                                                        comms_source:getWeaponStorage(
                                                                            missile_type
                                                                        )
                                                                            + 1
                                                                    )
                                                                    comms_target.comms_data.weapon_inventory[missile_type] = comms_target.comms_data.weapon_inventory[missile_type]
                                                                        - 1
                                                                    setCommsMessage(
                                                                        string.format(
                                                                            _(
                                                                                "ammo-comms",
                                                                                "One %s provided"
                                                                            ),
                                                                            missile_type
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
                                                            else
                                                                setCommsMessage(
                                                                    _(
                                                                        "ammo-comms",
                                                                        "You need to stay close if you want me to restock your ordnance"
                                                                    )
                                                                )
                                                            end
                                                            addCommsReply(
                                                                _("Back"),
                                                                commsServiceJonque
                                                            )
                                                        end
                                                    )
                                                    if
                                                        comms_source:getReputationPoints()
                                                        > StationCore.getWeaponCost(
                                                                missile_type
                                                            )
                                                            * 2
                                                    then
                                                        local max_afford = 0
                                                        local missile_count = 0
                                                        repeat
                                                            max_afford = max_afford
                                                                + StationCore.getWeaponCost(
                                                                    missile_type
                                                                )
                                                            missile_count = missile_count
                                                                + 1
                                                        until max_afford
                                                                + StationCore.getWeaponCost(
                                                                    missile_type
                                                                )
                                                            > comms_source:getReputationPoints()
                                                        addCommsReply(
                                                            string.format(
                                                                _(
                                                                    "ammo-comms",
                                                                    "Get %i (%i reputation)"
                                                                ),
                                                                missile_count,
                                                                max_afford
                                                            ),
                                                            function()
                                                                if
                                                                    distance(
                                                                        comms_source,
                                                                        comms_target
                                                                    )
                                                                    < 5000
                                                                then
                                                                    if
                                                                        comms_source:takeReputationPoints(
                                                                            StationCore.getWeaponCost(
                                                                                missile_type
                                                                            )
                                                                                * missile_count
                                                                        )
                                                                    then
                                                                        comms_source:setWeaponStorage(
                                                                            missile_type,
                                                                            comms_source:getWeaponStorage(
                                                                                missile_type
                                                                            )
                                                                                + missile_count
                                                                        )
                                                                        comms_target.comms_data.weapon_inventory[missile_type] = comms_target.comms_data.weapon_inventory[missile_type]
                                                                            - missile_count
                                                                        setCommsMessage(
                                                                            string.format(
                                                                                _(
                                                                                    "ammo-comms",
                                                                                    "%i %ss provided"
                                                                                ),
                                                                                missile_count,
                                                                                missile_type
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
                                                                else
                                                                    setCommsMessage(
                                                                        _(
                                                                            "ammo-comms",
                                                                            "You need to stay close if you want me to restock your ordnance"
                                                                        )
                                                                    )
                                                                end
                                                                addCommsReply(
                                                                    _("Back"),
                                                                    commsServiceJonque
                                                                )
                                                            end
                                                        )
                                                    end
                                                end
                                            end
                                        )
                                        addCommsReply(
                                            string.format(
                                                _(
                                                    "ammo-comms",
                                                    "Get one (%i reputation)"
                                                ),
                                                StationCore.getWeaponCost(
                                                    missile_type
                                                )
                                            ),
                                            function()
                                                if
                                                    distance(
                                                        comms_source,
                                                        comms_target
                                                    )
                                                    < 5000
                                                then
                                                    if
                                                        comms_source:takeReputationPoints(
                                                            StationCore.getWeaponCost(
                                                                missile_type
                                                            )
                                                        )
                                                    then
                                                        comms_source:setWeaponStorage(
                                                            missile_type,
                                                            comms_source:getWeaponStorage(
                                                                missile_type
                                                            )
                                                                + 1
                                                        )
                                                        comms_target.comms_data.weapon_inventory[missile_type] = comms_target.comms_data.weapon_inventory[missile_type]
                                                            - 1
                                                        setCommsMessage(
                                                            string.format(
                                                                _(
                                                                    "ammo-comms",
                                                                    "One %s provided"
                                                                ),
                                                                missile_type
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
                                                else
                                                    setCommsMessage(
                                                        _(
                                                            "ammo-comms",
                                                            "You need to stay close if you want me to restock your ordnance"
                                                        )
                                                    )
                                                end
                                                addCommsReply(
                                                    _("Back"),
                                                    commsServiceJonque
                                                )
                                            end
                                        )
                                    end
                                else
                                    setCommsMessage(
                                        _(
                                            "ammo-comms",
                                            "You need to stay close if you want me to restock your ordnance"
                                        )
                                    )
                                end
                                addCommsReply(_("Back"), commsServiceJonque)
                            end
                        )
                    end
                end
                addCommsReply(_("Back"), commsServiceJonque)
            end)
        end
        local offer_probes = false
        if
            comms_source:getScanProbeCount()
            < comms_source:getMaxScanProbeCount()
        then
            offer_probes = true
        end
        if offer_probes then
            addCommsReply(
                _("shipServices-comms", "Restock scan probes (5 reputation)"),
                function()
                    if distance(comms_source, comms_target) < 5000 then
                        if comms_source:takeReputationPoints(5) then
                            comms_source:setScanProbeCount(
                                comms_source:getMaxScanProbeCount()
                            )
                            setCommsMessage(
                                _(
                                    "shipServices-comms",
                                    "I replenished your probes for you."
                                )
                            )
                        else
                            setCommsMessage(
                                _("needRep-comms", "Insufficient reputation")
                            )
                        end
                    else
                        setCommsMessage(
                            _(
                                "shipServices-comms",
                                "You need to stay close if you want me to restock your probes"
                            )
                        )
                    end
                    addCommsReply(_("Back"), commsServiceJonque)
                end
            )
        end
        local offer_power = false
        if
            comms_source:getEnergyLevel()
            < comms_source:getEnergyLevelMax() / 2
        then
            offer_power = true
        end
        if offer_power then
            local power_charge = math.floor(
                (
                    comms_source:getEnergyLevelMax()
                    - comms_source:getEnergyLevel()
                ) / 3
            )
            addCommsReply(
                string.format(
                    _(
                        "shipServices-comms",
                        "Quick charge the main batteries (%i reputation)"
                    ),
                    power_charge
                ),
                function()
                    if distance(comms_source, comms_target) < 5000 then
                        if comms_source:takeReputationPoints(power_charge) then
                            comms_source:setEnergyLevel(
                                comms_source:getEnergyLevelMax()
                            )
                            comms_source:commandSetSystemPowerRequest(
                                "reactor",
                                1
                            )
                            comms_source:setSystemPower("reactor", 1)
                            comms_source:setSystemHeat("reactor", 2)
                            setCommsMessage(
                                _(
                                    "shipServices-comms",
                                    "Your batteries have been charged"
                                )
                            )
                        else
                            setCommsMessage(
                                _("needRep-comms", "Insufficient reputation")
                            )
                        end
                    else
                        setCommsMessage(
                            _(
                                "shipServices-comms",
                                "You need to stay close if you want your batteries charged quickly"
                            )
                        )
                    end
                    addCommsReply(_("Back"), commsServiceJonque)
                end
            )
        end
        if
            offer_hull_repair
            or offer_repair
            or offer_ordnance
            or offer_probes
            or offer_power
        then
            setCommsMessage(
                _(
                    "shipServices-comms",
                    "How can I help you get your ship in good running order?"
                )
            )
        else
            setCommsMessage(
                _(
                    "shipServices-comms",
                    "There's nothing on your ship that I can help you fix. Sorry."
                )
            )
        end
    end)
end

function M.friendlyServiceJonqueComms(comms_data)
    if comms_data.friendlyness < 20 then
        setCommsMessage(_("shipAssist-comms", "What do you want?"))
    else
        setCommsMessage(_("shipAssist-comms", "Sir, how can we assist?"))
    end
    addCommsReply(_("shipAssist-comms", "Defend a waypoint"), function()
        if comms_source:getWaypointCount() == 0 then
            setCommsMessage(
                _(
                    "shipAssist-comms",
                    "No waypoints set. Please set a waypoint first."
                )
            )
        else
            setCommsMessage(
                _("shipAssist-comms", "Which waypoint should we defend?")
            )
            for n = 1, comms_source:getWaypointCount() do
                addCommsReply(
                    string.format(
                        _("shipAssist-comms", "Defend WP %i"),
                        comms_source:getWaypointID(n)
                    ),
                    function()
                        comms_target:orderDefendLocation(
                            comms_source:getWaypoint(n)
                        )
                        setCommsMessage(
                            string.format(
                                _(
                                    "shipAssist-comms",
                                    "We are heading to assist at WP %i."
                                ),
                                comms_source:getWaypointID(n)
                            )
                        )
                        addCommsReply(_("Back"), commsServiceJonque)
                    end
                )
            end
        end
        addCommsReply(_("Back"), commsServiceJonque)
    end)
    if comms_data.friendlyness > 0.2 then
        addCommsReply(_("shipAssist-comms", "Assist me"), function()
            setCommsMessage(
                _("shipAssist-comms", "Heading toward you to assist.")
            )
            comms_target:orderDefendTarget(comms_source)
            addCommsReply(_("Back"), commsServiceJonque)
        end)
    end
    addCommsReply(_("shipAssist-comms", "Report status"), function()
        msg = string.format(
            _("shipAssist-comms", "Hull: %d%%\n"),
            comms_target:getHullPercentage()
        )
        local shields = comms_target:getShieldCount()
        if shields == 1 then
            msg = msg
                .. string.format(
                    _("shipAssist-comms", "Shield: %d%%\n"),
                    math.floor(
                        comms_target:getShieldLevel(0)
                            / comms_target:getShieldMax(0)
                            * 100
                    )
                )
        elseif shields == 2 then
            msg = msg
                .. string.format(
                    _("shipAssist-comms", "Front Shield: %d%%\n"),
                    math.floor(
                        comms_target:getShieldLevel(0)
                            / comms_target:getShieldMax(0)
                            * 100
                    )
                )
            msg = msg
                .. string.format(
                    _("shipAssist-comms", "Rear Shield: %d%%\n"),
                    math.floor(
                        comms_target:getShieldLevel(1)
                            / comms_target:getShieldMax(1)
                            * 100
                    )
                )
        else
            for n = 0, shields - 1 do
                msg = msg
                    .. string.format(
                        _("shipAssist-comms", "Shield %s: %d%%\n"),
                        n,
                        math.floor(
                            comms_target:getShieldLevel(n)
                                / comms_target:getShieldMax(n)
                                * 100
                        )
                    )
            end
        end
        setCommsMessage(msg)
        addCommsReply(_("Back"), commsServiceJonque)
    end)
    for index, obj in ipairs(comms_target:getObjectsInRange(5000)) do
        if
            isObjectType(obj, "SpaceStation") and not comms_target:isEnemy(obj)
        then
            addCommsReply(
                string.format(
                    _("shipAssist-comms", "Dock at %s"),
                    obj:getCallSign()
                ),
                function()
                    setCommsMessage(
                        string.format(
                            _("shipAssist-comms", "Docking at %s."),
                            obj:getCallSign()
                        )
                    )
                    comms_target:orderDock(obj)
                    addCommsReply(_("Back"), commsServiceJonque)
                end
            )
        end
    end
    if distance(comms_source, comms_target) < 5000 then
        M.commonServiceOptions()
    end
end

function M.neutralServiceJonqueComms(comms_data)
    if comms_data.friendlyness < 20 then
        setCommsMessage(_("shipAssist-comms", "What do you want?"))
    else
        setCommsMessage(_("shipAssist-comms", "Sir, how can we assist?"))
    end
    addCommsReply(_("shipAssist-comms", "How are you doing?"), function()
        msg = string.format(
            _("shipAssist-comms", "Hull: %d%%\n"),
            comms_target:getHullPercentage()
        )
        local shields = comms_target:getShieldCount()
        if shields == 1 then
            msg = msg
                .. string.format(
                    _("shipAssist-comms", "Shield: %d%%\n"),
                    math.floor(
                        comms_target:getShieldLevel(0)
                            / comms_target:getShieldMax(0)
                            * 100
                    )
                )
        elseif shields == 2 then
            msg = msg
                .. string.format(
                    _("shipAssist-comms", "Front Shield: %d%%\n"),
                    math.floor(
                        comms_target:getShieldLevel(0)
                            / comms_target:getShieldMax(0)
                            * 100
                    )
                )
            msg = msg
                .. string.format(
                    _("shipAssist-comms", "Rear Shield: %d%%\n"),
                    math.floor(
                        comms_target:getShieldLevel(1)
                            / comms_target:getShieldMax(1)
                            * 100
                    )
                )
        else
            for n = 0, shields - 1 do
                msg = msg
                    .. string.format(
                        _("shipAssist-comms", "Shield %s: %d%%\n"),
                        n,
                        math.floor(
                            comms_target:getShieldLevel(n)
                                / comms_target:getShieldMax(n)
                                * 100
                        )
                    )
            end
        end
        setCommsMessage(msg)
        addCommsReply(_("Back"), commsServiceJonque)
    end)
    M.commonServiceOptions()
end

return M
