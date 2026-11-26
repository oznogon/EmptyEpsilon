-- Shared ship communication support utilities.

local M = {}

function M.goodsOnShip(comms_target, comms_data, options)
    options = options or {}
    comms_data.goods = {}
    comms_data.goods[commonGoods[math.random(1, #commonGoods)]] =
        { quantity = 1, cost = random(20, 80) }
    local shipType = comms_target:getTypeName()
    if shipType:find("Freighter") ~= nil then
        if
            shipType:find("Goods") ~= nil
            or shipType:find("Equipment") ~= nil
        then
            local count_repeat_loop = 0
            local repeat_limit = options.unlimited and math.huge
                or (max_repeat_loop or 20)
            repeat
                comms_data.goods[commonGoods[math.random(1, #commonGoods)]] =
                    { quantity = 1, cost = random(20, 80) }
                local goodCount = 0
                for good, goodData in pairs(comms_data.goods) do
                    goodCount = goodCount + 1
                end
                count_repeat_loop = count_repeat_loop + 1
            until goodCount >= 3 or count_repeat_loop > repeat_limit
            if count_repeat_loop > repeat_limit then
                print(
                    "repeated too many times when setting up goods for freighter"
                )
            end
        end
    end
end

function M.goodsOnShipUnlimited(comms_target, comms_data)
    M.goodsOnShip(comms_target, comms_data, { unlimited = true })
end

function M.enemyComms(comms_data, options)
    options = options or {}
    local faction = comms_target:getFaction()
    local tauntable = false
    local amenable = false
    if comms_data.friendlyness >= 33 then --final: 33
        --taunt logic
        local taunt_option =
            _("shipEnemy-comms", "We will see to your destruction!")
        local taunt_success_reply =
            _("shipEnemy-comms", "Your bloodline will end here!")
        local taunt_failed_reply =
            _("shipEnemy-comms", "Your feeble threats are meaningless.")
        local taunt_threshold = 30 --base chance of being taunted
        local immolation_threshold = 5 --base chance that taunting will enrage to the point of revenge immolation
        if faction == "Kraylor" then
            taunt_threshold = 35
            immolation_threshold = 6
            setCommsMessage(
                _("shipEnemy-comms", "Ktzzzsss.\nYou will DIEEee weaklingsss!")
            )
            local kraylorTauntChoice = math.random(1, 3)
            if kraylorTauntChoice == 1 then
                taunt_option = _("shipEnemy-comms", "We will destroy you")
                taunt_success_reply = _(
                    "shipEnemy-comms",
                    "We think not. It is you who will experience destruction!"
                )
            elseif kraylorTauntChoice == 2 then
                taunt_option = _("shipEnemy-comms", "You have no honor")
                taunt_success_reply = _(
                    "shipEnemy-comms",
                    "Your insult has brought our wrath upon you. Prepare to die."
                )
                taunt_failed_reply = _(
                    "shipEnemy-comms",
                    "Your comments about honor have no meaning to us"
                )
            else
                taunt_option =
                    _("shipEnemy-comms", "We pity your pathetic race")
                taunt_success_reply = _(
                    "shipEnemy-comms",
                    "Pathetic? You will regret your disparagement!"
                )
                taunt_failed_reply =
                    _("shipEnemy-comms", "We don't care what you think of us")
            end
        elseif faction == "Arlenians" then
            taunt_threshold = 25
            immolation_threshold = 4
            setCommsMessage(
                _(
                    "shipEnemy-comms",
                    "We wish you no harm, but will harm you if we must.\nEnd of transmission."
                )
            )
        elseif faction == "Exuari" then
            taunt_threshold = 40
            immolation_threshold = 7
            setCommsMessage(
                _(
                    "shipEnemy-comms",
                    "Stay out of our way, or your death will amuse us extremely!"
                )
            )
        elseif faction == "Ghosts" then
            taunt_threshold = 20
            immolation_threshold = 3
            setCommsMessage(
                _(
                    "shipEnemy-comms",
                    "One zero one.\nNo binary communication detected.\nSwitching to universal speech.\nGenerating appropriate response for target from human language archives.\n:Do not cross us:\nCommunication halted."
                )
            )
            taunt_option = _("shipEnemy-comms", "EXECUTE: SELFDESTRUCT")
            taunt_success_reply = _(
                "shipEnemy-comms",
                "Rogue command received. Targeting source."
            )
            taunt_failed_reply =
                _("shipEnemy-comms", "External command ignored.")
        elseif faction == "Ktlitans" then
            setCommsMessage(
                _(
                    "shipEnemy-comms",
                    "The hive suffers no threats. Opposition to any of us is opposition to us all.\nStand down or prepare to donate your corpses toward our nutrition."
                )
            )
            taunt_option = _(
                "shipEnemy-comms",
                "<Transmit 'The Itsy-Bitsy Spider' on all wavelengths>"
            )
            taunt_success_reply = _(
                "shipEnemy-comms",
                "We do not need permission to pluck apart such an insignificant threat."
            )
            taunt_failed_reply = _(
                "shipEnemy-comms",
                "The hive has greater priorities than exterminating pests."
            )
        elseif faction == "TSN" then
            taunt_threshold = 15
            immolation_threshold = 2
            setCommsMessage(_("shipEnemy-comms", "State your business"))
        elseif faction == "USN" then
            taunt_threshold = 15
            immolation_threshold = 2
            setCommsMessage(
                _("shipEnemy-comms", "What do you want? (not that we care)")
            )
        elseif faction == "CUF" then
            taunt_threshold = 15
            immolation_threshold = 2
            setCommsMessage(_("shipEnemy-comms", "Don't waste our time"))
        else
            setCommsMessage(_("shipEnemy-comms", "Mind your own business!"))
        end
        comms_data.friendlyness = comms_data.friendlyness - random(0, 10) --reduce friendlyness after each interaction
        addCommsReply(taunt_option, function()
            if random(0, 100) <= taunt_threshold then
                local current_order = comms_target:getOrder()
                -- print("order: " .. current_order)
                --Possible order strings returned:
                --Roaming
                --Fly towards
                --Attack
                --Stand Ground
                --Idle
                --Defend Location
                --Defend Target
                --Fly Formation (?)
                --Fly towards (ignore all)
                --Dock
                if comms_target.original_order == nil then
                    comms_target.original_faction = faction
                    comms_target.original_order = current_order
                    if
                        current_order == "Fly towards"
                        or current_order == "Defend Location"
                        or current_order == "Fly towards (ignore all)"
                    then
                        comms_target.original_target_x, comms_target.original_target_y =
                            comms_target:getOrderTargetLocation()
                        --print(string.format("Target_x: %f, Target_y: %f",comms_target.original_target_x,comms_target.original_target_y))
                    end
                    if
                        current_order == "Attack"
                        or current_order == "Dock"
                        or current_order == "Defend Target"
                    then
                        local original_target = comms_target:getOrderTarget()
                        --print("target:")
                        --print(original_target)
                        --print(original_target:getCallSign())
                        comms_target.original_target = original_target
                    end
                    comms_target.taunt_may_expire = true --change to conditional in future refactoring
                    if enemy_reverts ~= nil then
                        table.insert(enemy_reverts, comms_target)
                    end
                end
                comms_target:orderAttack(comms_source) --consider alternative options besides attack in future refactoring
                setCommsMessage(taunt_success_reply)
            else
                --possible alternative consequences when taunt fails
                if
                    options.continuum ~= false
                    and random(1, 100) < (immolation_threshold + difficulty)
                then --final: immolation_threshold (set to 100 for testing)
                    setCommsMessage(
                        _(
                            "shipEnemy-comms",
                            "Subspace and time continuum disruption authorized"
                        )
                    )
                    comms_source.continuum_target = true
                    comms_source.continuum_initiator = comms_target
                    plotContinuum = checkContinuum
                else
                    setCommsMessage(taunt_failed_reply)
                end
            end
        end)
        tauntable = true
    end
    local enemy_health = M.getEnemyHealth(comms_target)
    if change_enemy_order_diagnostic then
        print(string.format("   enemy health:    %.2f", enemy_health))
    end
    if change_enemy_order_diagnostic then
        print(
            string.format("   friendliness:    %.1f", comms_data.friendlyness)
        )
    end
    if comms_data.friendlyness >= 66 or enemy_health < 0.5 then --final: 66, .5
        --amenable logic
        local amenable_chance = comms_data.friendlyness / 3
            + (1 - enemy_health) * 30
        if change_enemy_order_diagnostic then
            print(string.format("   amenability:     %.1f", amenable_chance))
        end
        addCommsReply(_("shipEnemy-comms", "Stop your actions"), function()
            local amenable_roll = random(1, 100)
            if change_enemy_order_diagnostic then
                print(string.format("   amenable roll:   %.1f", amenable_roll))
            end
            if amenable_roll < amenable_chance then
                local current_order = comms_target:getOrder()
                if comms_target.original_order == nil then
                    comms_target.original_order = current_order
                    comms_target.original_faction = faction
                    if
                        current_order == "Fly towards"
                        or current_order == "Defend Location"
                        or current_order == "Fly towards (ignore all)"
                    then
                        comms_target.original_target_x, comms_target.original_target_y =
                            comms_target:getOrderTargetLocation()
                        --print(string.format("Target_x: %f, Target_y: %f",comms_target.original_target_x,comms_target.original_target_y))
                    end
                    if
                        current_order == "Attack"
                        or current_order == "Dock"
                        or current_order == "Defend Target"
                    then
                        local original_target = comms_target:getOrderTarget()
                        --print("target:")
                        --print(original_target)
                        --print(original_target:getCallSign())
                        comms_target.original_target = original_target
                    end
                    if enemy_reverts ~= nil then
                        table.insert(enemy_reverts, comms_target)
                    end
                end
                comms_target.amenability_may_expire = true --set up conditional in future refactoring
                comms_target:orderIdle()
                comms_target:setFaction("Independent")
                setCommsMessage(
                    _(
                        "shipEnemy-comms",
                        "Just this once, we'll take your advice"
                    )
                )
            else
                setCommsMessage(_("shipEnemy-comms", "No"))
            end
        end)
        comms_data.friendlyness = comms_data.friendlyness - random(0, 10) --reduce friendlyness after each interaction
        amenable = true
    end
    if tauntable or amenable then
        return true
    else
        return false
    end
end

function M.getEnemyHealth(enemy)
    local enemy_health = 0
    local enemy_shield = 0
    local enemy_shield_count = enemy:getShieldCount()
    local faction = enemy:getFaction()
    if change_enemy_order_diagnostic then
        print(string.format("%s statistics:", enemy:getCallSign()))
    end
    if change_enemy_order_diagnostic then
        print(string.format("   shield count:    %i", enemy_shield_count))
    end
    if enemy_shield_count > 0 then
        local total_shield_level = 0
        local max_shield_level = 0
        for i = 1, enemy_shield_count do
            total_shield_level = total_shield_level
                + enemy:getShieldLevel(i - 1)
            max_shield_level = max_shield_level + enemy:getShieldMax(i - 1)
        end
        enemy_shield = total_shield_level / max_shield_level
    else
        enemy_shield = 1
    end
    if change_enemy_order_diagnostic then
        print(string.format("   shield health:   %.1f", enemy_shield))
    end
    local enemy_hull = enemy:getHull() / enemy:getHullMax()
    if change_enemy_order_diagnostic then
        print(string.format("   hull health:     %.1f", enemy_hull))
    end
    local enemy_reactor = enemy:getSystemHealth("reactor")
    if change_enemy_order_diagnostic then
        print(string.format("   reactor health:  %.1f", enemy_reactor))
    end
    local enemy_maneuver = enemy:getSystemHealth("maneuver")
    if change_enemy_order_diagnostic then
        print(string.format("   maneuver health: %.1f", enemy_maneuver))
    end
    local enemy_impulse = enemy:getSystemHealth("impulse")
    if change_enemy_order_diagnostic then
        print(string.format("   impulse health:  %.1f", enemy_impulse))
    end
    local enemy_beam = 0
    if enemy:getBeamWeaponRange(0) > 0 then
        enemy_beam = enemy:getSystemHealth("beamweapons")
        if change_enemy_order_diagnostic then
            print(string.format("   beam health:     %.1f", enemy_beam))
        end
    else
        enemy_beam = 1
        if change_enemy_order_diagnostic then
            print(
                string.format("   beam health:     %.1f (no beams)", enemy_beam)
            )
        end
    end
    local enemy_missile = 0
    if enemy:getWeaponTubeCount() > 0 then
        enemy_missile = enemy:getSystemHealth("missilesystem")
        if change_enemy_order_diagnostic then
            print(string.format("   missile health:  %.1f", enemy_missile))
        end
    else
        enemy_missile = 1
        if change_enemy_order_diagnostic then
            print(
                string.format(
                    "   missile health:  %.1f (no missile system)",
                    enemy_missile
                )
            )
        end
    end
    local enemy_warp = 0
    if enemy:hasWarpDrive() then
        enemy_warp = enemy:getSystemHealth("warp")
        if change_enemy_order_diagnostic then
            print(string.format("   warp health:     %.1f", enemy_warp))
        end
    else
        enemy_warp = 1
        if change_enemy_order_diagnostic then
            print(
                string.format(
                    "   warp health:     %.1f (no warp drive)",
                    enemy_warp
                )
            )
        end
    end
    local enemy_jump = 0
    if enemy:hasJumpDrive() then
        enemy_jump = enemy:getSystemHealth("jumpdrive")
        if change_enemy_order_diagnostic then
            print(string.format("   jump health:     %.1f", enemy_jump))
        end
    else
        enemy_jump = 1
        if change_enemy_order_diagnostic then
            print(
                string.format(
                    "   jump health:     %.1f (no jump drive)",
                    enemy_jump
                )
            )
        end
    end
    if change_enemy_order_diagnostic then
        print(string.format("   faction:         %s", faction))
    end
    if faction == "Kraylor" then
        enemy_health = enemy_shield * 0.3
            + enemy_hull * 0.4
            + enemy_reactor * 0.1
            + enemy_maneuver * 0.03
            + enemy_impulse * 0.03
            + enemy_beam * 0.04
            + enemy_missile * 0.04
            + enemy_warp * 0.03
            + enemy_jump * 0.03
    elseif faction == "Arlenians" then
        enemy_health = enemy_shield * 0.35
            + enemy_hull * 0.45
            + enemy_reactor * 0.05
            + enemy_maneuver * 0.03
            + enemy_impulse * 0.04
            + enemy_beam * 0.02
            + enemy_missile * 0.02
            + enemy_warp * 0.02
            + enemy_jump * 0.02
    elseif faction == "Exuari" then
        enemy_health = enemy_shield * 0.2
            + enemy_hull * 0.3
            + enemy_reactor * 0.2
            + enemy_maneuver * 0.05
            + enemy_impulse * 0.05
            + enemy_beam * 0.05
            + enemy_missile * 0.05
            + enemy_warp * 0.05
            + enemy_jump * 0.05
    elseif faction == "Ghosts" then
        enemy_health = enemy_shield * 0.25
            + enemy_hull * 0.25
            + enemy_reactor * 0.25
            + enemy_maneuver * 0.04
            + enemy_impulse * 0.05
            + enemy_beam * 0.04
            + enemy_missile * 0.04
            + enemy_warp * 0.04
            + enemy_jump * 0.04
    elseif faction == "Ktlitans" then
        enemy_health = enemy_shield * 0.2
            + enemy_hull * 0.3
            + enemy_reactor * 0.1
            + enemy_maneuver * 0.05
            + enemy_impulse * 0.05
            + enemy_beam * 0.05
            + enemy_missile * 0.05
            + enemy_warp * 0.1
            + enemy_jump * 0.1
    elseif faction == "TSN" then
        enemy_health = enemy_shield * 0.35
            + enemy_hull * 0.35
            + enemy_reactor * 0.08
            + enemy_maneuver * 0.01
            + enemy_impulse * 0.02
            + enemy_beam * 0.02
            + enemy_missile * 0.01
            + enemy_warp * 0.08
            + enemy_jump * 0.08
    elseif faction == "USN" then
        enemy_health = enemy_shield * 0.38
            + enemy_hull * 0.38
            + enemy_reactor * 0.05
            + enemy_maneuver * 0.02
            + enemy_impulse * 0.03
            + enemy_beam * 0.02
            + enemy_missile * 0.02
            + enemy_warp * 0.05
            + enemy_jump * 0.05
    elseif faction == "CUF" then
        enemy_health = enemy_shield * 0.35
            + enemy_hull * 0.38
            + enemy_reactor * 0.05
            + enemy_maneuver * 0.03
            + enemy_impulse * 0.03
            + enemy_beam * 0.03
            + enemy_missile * 0.03
            + enemy_warp * 0.06
            + enemy_jump * 0.04
    else
        enemy_health = enemy_shield * 0.3
            + enemy_hull * 0.4
            + enemy_reactor * 0.06
            + enemy_maneuver * 0.03
            + enemy_impulse * 0.05
            + enemy_beam * 0.03
            + enemy_missile * 0.03
            + enemy_warp * 0.05
            + enemy_jump * 0.05
    end
    return enemy_health
end

function M.availableForComms(p)
    if not p:isCommsInactive() then
        return false
    end
    if p:isCommsOpening() then
        return false
    end
    if p:isCommsBeingHailed() then
        return false
    end
    if p:isCommsBeingHailedByGM() then
        return false
    end
    if p:isCommsChatOpen() then
        return false
    end
    if p:isCommsChatOpenToGM() then
        return false
    end
    if p:isCommsChatOpenToPlayer() then
        return
    end
    if p:isCommsScriptOpen() then
        return false
    end
    return true
end

function M.enemyCommsSimple(comms_data, comms_source)
    comms_source = comms_source or _G.comms_source
    if comms_data.friendlyness > 50 then
        local faction = comms_target:getFaction()
        local taunt_option =
            _("shipEnemy-comms", "We will see to your destruction!")
        local taunt_success_reply =
            _("shipEnemy-comms", "Your bloodline will end here!")
        local taunt_failed_reply =
            _("shipEnemy-comms", "Your feeble threats are meaningless.")
        if faction == "Kraylor" then
            setCommsMessage(
                _("shipEnemy-comms", "Ktzzzsss.\nYou will DIEEee weaklingsss!")
            )
        elseif faction == "Arlenians" then
            setCommsMessage(
                _(
                    "shipEnemy-comms",
                    "We wish you no harm, but will harm you if we must.\nEnd of transmission."
                )
            )
        elseif faction == "Exuari" then
            setCommsMessage(
                _(
                    "shipEnemy-comms",
                    "Stay out of our way, or your death will amuse us extremely!"
                )
            )
        elseif faction == "Ghosts" then
            setCommsMessage(
                _(
                    "shipEnemy-comms",
                    "One zero one.\nNo binary communication detected.\nSwitching to universal speech.\nGenerating appropriate response for target from human language archives.\n:Do not cross us:\nCommunication halted."
                )
            )
            taunt_option = _("shipEnemy-comms", "EXECUTE: SELFDESTRUCT")
            taunt_success_reply = _(
                "shipEnemy-comms",
                "Rogue command received. Targeting source."
            )
            taunt_failed_reply =
                _("shipEnemy-comms", "External command ignored.")
        elseif faction == "Ktlitans" then
            setCommsMessage(
                _(
                    "shipEnemy-comms",
                    "The hive suffers no threats. Opposition to any of us is opposition to us all.\nStand down or prepare to donate your corpses toward our nutrition."
                )
            )
            taunt_option = _(
                "shipEnemy-comms",
                "<Transmit 'The Itsy-Bitsy Spider' on all wavelengths>"
            )
            taunt_success_reply = _(
                "shipEnemy-comms",
                "We do not need permission to pluck apart such an insignificant threat."
            )
            taunt_failed_reply = _(
                "shipEnemy-comms",
                "The hive has greater priorities than exterminating pests."
            )
        else
            setCommsMessage(_("shipEnemy-comms", "Mind your own business!"))
        end
        comms_data.friendlyness = comms_data.friendlyness - random(0, 10)
        addCommsReply(taunt_option, function()
            if random(0, 100) < 30 then
                comms_target:orderAttack(comms_source)
                setCommsMessage(taunt_success_reply)
            else
                setCommsMessage(taunt_failed_reply)
            end
        end)
        return true
    end
    return false
end

function M.enemyCommsAlternate()
    if comms_target.comms_data.friendlyness > 50 then
        local faction = comms_target:getFaction()
        local taunt_option =
            _("shipEnemy-comms", "We will see to your destruction!")
        local taunt_success_reply =
            _("shipEnemy-comms", "Your bloodline will end here!")
        local taunt_failed_reply =
            _("shipEnemy-comms", "Your feeble threats are meaningless.")
        if faction == "Kraylor" then
            setCommsMessage(
                _("shipEnemy-comms", "Ktzzzsss.\nYou will DIEEee weaklingsss!")
            )
        elseif faction == "Arlenians" then
            setCommsMessage(
                _(
                    "shipEnemy-comms",
                    "We wish you no harm, but will harm you if we must.\nEnd of transmission."
                )
            )
        elseif faction == "Exuari" then
            setCommsMessage(
                _(
                    "shipEnemy-comms",
                    "Stay out of our way, or your death will amuse us extremely!"
                )
            )
        elseif faction == "Ghosts" then
            setCommsMessage(
                _(
                    "shipEnemy-comms",
                    "One zero one.\nNo binary communication detected.\nSwitching to universal speech.\nGenerating appropriate response for target from human language archives.\n:Do not cross us:\nCommunication halted."
                )
            )
            taunt_option = _("shipEnemy-comms", "EXECUTE: SELFDESTRUCT")
            taunt_success_reply = _(
                "shipEnemy-comms",
                "Rogue command received. Targeting source."
            )
            taunt_failed_reply =
                _("shipEnemy-comms", "External command ignored.")
        elseif faction == "Ktlitans" then
            setCommsMessage(
                _(
                    "shipEnemy-comms",
                    "The hive suffers no threats. Opposition to any of us is opposition to us all.\nStand down or prepare to donate your corpses toward our nutrition."
                )
            )
            taunt_option = _(
                "shipEnemy-comms",
                "<Transmit 'The Itsy-Bitsy Spider' on all wavelengths>"
            )
            taunt_success_reply = _(
                "shipEnemy-comms",
                "We do not need permission to pluck apart such an insignificant threat."
            )
            taunt_failed_reply = _(
                "shipEnemy-comms",
                "The hive has greater priorities than exterminating pests."
            )
        else
            setCommsMessage(_("shipEnemy-comms", "Mind your own business!"))
        end
        comms_target.comms_data.friendlyness = comms_target.comms_data.friendlyness
            - random(0, 10)
        addCommsReply(taunt_option, function()
            if random(0, 100) < 30 then
                comms_target:orderAttack(comms_source)
                setCommsMessage(taunt_success_reply)
            else
                setCommsMessage(taunt_failed_reply)
            end
        end)
        return true
    end
    return false
end

local MISSILE_TYPES = { "Homing", "Nuke", "Mine", "EMP", "HVLI" }
local Group = require("comms_ship_group.lua")

local DEFAULT_FRIENDLY_OPTIONS = {
    "defend",
    "assist",
    "status",
    "dock",
    "trade",
}

local function mainMenu(profile)
    return profile.main_menu or commsShip
end

local function source(profile)
    if profile.source ~= nil then
        return profile.source()
    end
    return comms_source
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

local function inventory(profile, owner, comms_data)
    if profile.inventory ~= nil then
        return profile.inventory(owner, comms_data)
    end
    if owner == comms_target then
        return comms_data.goods or {}
    end
    return owner.goods or {}
end

local function inventoryEntries(profile, owner, comms_data)
    local values = inventory(profile, owner, comms_data) or {}
    local entries = {}
    if profile.inventory_format == "array" or type(values[1]) == "table" then
        for _index, record in ipairs(values or {}) do
            table.insert(entries, {
                name = record[1],
                quantity = record[2] or 0,
                cost = record[3] or 0,
                record = record,
            })
        end
    else
        for good, data in pairs(values or {}) do
            if type(data) == "table" then
                table.insert(entries, {
                    name = good,
                    quantity = data.quantity or 0,
                    cost = data.cost or 0,
                    record = data,
                })
            else
                table.insert(entries, {
                    name = good,
                    quantity = data or 0,
                    cost = 0,
                    record = data,
                })
            end
        end
    end
    return entries
end

local function inventoryQuantity(profile, owner, good, comms_data)
    for _index, entry in ipairs(inventoryEntries(profile, owner, comms_data)) do
        if entry.name == good then
            return entry.quantity
        end
    end
    return 0
end

local function adjustInventory(profile, owner, good, amount, comms_data)
    if profile.adjust_inventory ~= nil then
        return profile.adjust_inventory(owner, good, amount, comms_data)
    end
    local values = inventory(profile, owner, comms_data) or {}
    if profile.inventory_format == "array" or type(values[1]) == "table" then
        for _index, entry in
            ipairs(inventoryEntries(profile, owner, comms_data))
        do
            if entry.name == good then
                entry.record[2] = entry.quantity + amount
                return
            end
        end
        table.insert(values, { good, amount, 0 })
    end
    if values[good] == nil then
        if owner == comms_target then
            values[good] = { quantity = amount, cost = 0 }
        else
            values[good] = amount
        end
    end
    if type(values[good]) == "table" then
        values[good].quantity = (values[good].quantity or 0) + amount
    else
        values[good] = (values[good] or 0) + amount
    end
end

local function addCargoQuery(profile, comms_data, with_back)
    addCommsReply(
        _("trade-comms", "Do you have cargo you might sell?"),
        function()
            local good_count = 0
            local text = _("trade-comms", "We've got ")
            for _index, entry in
                ipairs(inventoryEntries(profile, comms_target, comms_data))
            do
                if entry.quantity > 0 then
                    if good_count > 0 then
                        text = text .. _("trade-comms", ", ")
                    end
                    text = text .. goodsName(profile, entry.name)
                end
                good_count = good_count + entry.quantity
            end
            if good_count == 0 then
                text = text .. _("trade-comms", "nothing")
            end
            setCommsMessage(text)
            if with_back then
                addBack(profile)
            end
        end
    )
end

local function addJettison(profile, comms_data)
    local comms_source = source(profile)
    local entries = inventoryEntries(profile, comms_source, comms_data)
    if #entries == 0 then
        return
    end
    addCommsReply(_("trade-comms", "Jettison cargo"), function()
        setCommsMessage(
            string.format(
                _(
                    "trade-comms",
                    "Available space: %i\nWhat would you like to jettison?"
                ),
                comms_source.cargo
            )
        )
        for _index, entry in ipairs(entries) do
            if entry.quantity > 0 then
                local name = goodsName(profile, entry.name)
                addCommsReply(name, function()
                    adjustInventory(
                        profile,
                        comms_source,
                        entry.name,
                        -1,
                        comms_data
                    )
                    comms_source.cargo = comms_source.cargo + 1
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

local function addLuxuryTrade(profile, comms_data, trade)
    local comms_source = source(profile)
    if inventoryQuantity(profile, comms_source, "luxury", comms_data) <= 0 then
        return
    end
    for _index, entry in
        ipairs(inventoryEntries(profile, comms_target, comms_data))
    do
        if entry.quantity > 0 and entry.name ~= "luxury" then
            local name = goodsName(profile, entry.name)
            addCommsReply(
                string.format(_("trade-comms", "Trade luxury for %s"), name),
                function()
                    if
                        trade.check_inventory
                        and inventoryQuantity(
                                profile,
                                comms_target,
                                entry.name,
                                comms_data
                            )
                            < 1
                    then
                        setCommsMessage(
                            _(
                                "trade-comms",
                                "Insufficient inventory on freighter for trade"
                            )
                        )
                    else
                        if trade.luxury_consumes_stock ~= false then
                            adjustInventory(
                                profile,
                                comms_target,
                                entry.name,
                                -1,
                                comms_data
                            )
                        end
                        adjustInventory(
                            profile,
                            comms_source,
                            entry.name,
                            1,
                            comms_data
                        )
                        adjustInventory(
                            profile,
                            comms_source,
                            "luxury",
                            -1,
                            comms_data
                        )
                        if trade.luxury_message ~= nil then
                            setCommsMessage(trade.luxury_message(name))
                        else
                            setCommsMessage(
                                string.format(
                                    _("trade-comms", "Traded luxury for %s"),
                                    name
                                )
                            )
                        end
                    end
                    addBack(profile)
                end
            )
        end
    end
end

local function addPurchase(
    profile,
    comms_data,
    trade,
    entry,
    multiplier,
    charge_multiplier
)
    local comms_source = source(profile)
    local name = goodsName(profile, entry.name)
    local cost = entry.cost * charge_multiplier
    addCommsReply(
        string.format(
            _("trade-comms", "Buy one %s for %i reputation"),
            name,
            math.floor(entry.cost * multiplier)
        ),
        function()
            if comms_source.cargo < 1 then
                setCommsMessage(
                    trade.insufficient_cargo_message
                        or _(
                            "trade-comms",
                            "Insufficient cargo space for purchase"
                        )
                )
            elseif
                trade.check_inventory
                and inventoryQuantity(
                        profile,
                        comms_target,
                        entry.name,
                        comms_data
                    )
                    < 1
            then
                setCommsMessage(
                    _("trade-comms", "Insufficient inventory on freighter")
                )
            elseif not comms_source:takeReputationPoints(cost) then
                setCommsMessage(
                    _("needRep-comms", "Insufficient reputation for purchase")
                )
            else
                adjustInventory(
                    profile,
                    comms_target,
                    entry.name,
                    -1,
                    comms_data
                )
                adjustInventory(
                    profile,
                    comms_source,
                    entry.name,
                    1,
                    comms_data
                )
                comms_source.cargo = comms_source.cargo - 1
                if trade.purchase_message ~= nil then
                    setCommsMessage(trade.purchase_message(name))
                else
                    setCommsMessage(
                        string.format(
                            _("trade-comms", "Purchased %s from %s"),
                            name,
                            comms_target:getCallSign()
                        )
                    )
                end
            end
            addBack(profile)
        end
    )
end

function M.arrayTradeMultiplier(relationship, comms_data, goods_freighter)
    if comms_data.friendlyness > 66 then
        return 1
    elseif comms_data.friendlyness > 33 then
        return goods_freighter and 1 or 2
    end
    return goods_freighter and 2 or nil
end

function M.standardTradeMultiplier(relationship, comms_data, goods_freighter)
    if relationship == "friendly" then
        if comms_data.friendlyness > 66 then
            return 1
        elseif comms_data.friendlyness > 33 then
            return goods_freighter and 1 or 2
        end
        return goods_freighter and 2 or nil
    end
    if comms_data.friendlyness > 66 then
        return goods_freighter and 1 or 2
    elseif comms_data.friendlyness > 33 then
        return goods_freighter and 2 or 3
    end
    return goods_freighter and 3 or nil
end

local function freighterTrade(profile, comms_data, relationship)
    local trade = profile.trade or {}
    local comms_source = source(profile)
    local range = trade.range or 5000
    if distance(comms_source, comms_target) >= range then
        if relationship == "friendly" and trade.far_cargo_query ~= false then
            addCargoQuery(profile, comms_data, true)
        end
        return
    end
    if profile.before_trade ~= nil then
        profile.before_trade()
    end
    local allow_jettison = trade.jettison ~= false
    if trade.jettison_mode ~= nil then
        allow_jettison = trade.jettison_mode(relationship, comms_data)
    end
    if allow_jettison then
        addJettison(profile, comms_data)
    end
    local ship_type = comms_target:getTypeName()
    local goods_freighter = ship_type:find("Goods") ~= nil
        or ship_type:find("Equipment") ~= nil
    local luxury_allowed = goods_freighter
        and comms_data.friendlyness > 66
        and (relationship == "friendly" or trade.luxury_neutral)
    if trade.luxury_mode ~= nil then
        luxury_allowed =
            trade.luxury_mode(relationship, comms_data, goods_freighter)
    end
    if luxury_allowed then
        addLuxuryTrade(profile, comms_data, trade)
        if trade.luxury_replaces_purchase and goods_freighter then
            return
        end
    end
    if trade.require_cargo ~= false and comms_source.cargo <= 0 then
        return
    end
    local multiplier
    if trade.multiplier ~= nil then
        multiplier = trade.multiplier(relationship, comms_data, goods_freighter)
    else
        multiplier =
            M.standardTradeMultiplier(relationship, comms_data, goods_freighter)
    end
    if multiplier == nil then
        return
    end
    local charge_multiplier = multiplier
    if trade.charge_multiplier ~= nil then
        charge_multiplier = trade.charge_multiplier(
            relationship,
            comms_data,
            goods_freighter,
            multiplier
        )
    end
    for _index, entry in
        ipairs(inventoryEntries(profile, comms_target, comms_data))
    do
        if entry.quantity > 0 then
            addPurchase(
                profile,
                comms_data,
                trade,
                entry,
                multiplier,
                charge_multiplier
            )
        end
    end
end

local function orderConfig(profile)
    return {
        source = function()
            return source(profile)
        end,
        members = function()
            return { comms_target }
        end,
        leader = function()
            return comms_target
        end,
        name = function()
            return comms_target:getCallSign()
        end,
        main_menu = mainMenu(profile),
        labels = profile.order_labels,
        prompts = profile.order_prompts,
        messages = profile.order_messages,
        waypoint_labels = profile.waypoint_labels,
        idle_messages = profile.idle_messages,
        idle_activities = profile.idle_activities,
    }
end

local function addStatus(profile)
    addCommsReply(_("shipAssist-comms", "Report status"), function()
        local text = string.format(
            _("shipAssist-comms", "Hull: %d%%\n"),
            comms_target:getHullPercentage()
        )
        local shields = comms_target:getShieldCount()
        if shields == 1 then
            text = text
                .. string.format(
                    _("shipAssist-comms", "Shield: %d%%\n"),
                    math.floor(
                        comms_target:getShieldLevel(0)
                            / comms_target:getShieldMax(0)
                            * 100
                    )
                )
        elseif shields == 2 then
            text = text
                .. string.format(
                    _("shipAssist-comms", "Front Shield: %d%%\n"),
                    math.floor(
                        comms_target:getShieldLevel(0)
                            / comms_target:getShieldMax(0)
                            * 100
                    )
                )
            text = text
                .. string.format(
                    _("shipAssist-comms", "Rear Shield: %d%%\n"),
                    math.floor(
                        comms_target:getShieldLevel(1)
                            / comms_target:getShieldMax(1)
                            * 100
                    )
                )
        else
            for index = 0, shields - 1 do
                text = text
                    .. string.format(
                        _("shipAssist-comms", "Shield %s: %d%%\n"),
                        index,
                        math.floor(
                            comms_target:getShieldLevel(index)
                                / comms_target:getShieldMax(index)
                                * 100
                        )
                    )
            end
        end
        for _index, missile_type in ipairs(MISSILE_TYPES) do
            if comms_target:getWeaponStorageMax(missile_type) > 0 then
                text = text
                    .. string.format(
                        _("shipAssist-comms", "%s Missiles: %d/%d\n"),
                        missile_type,
                        math.floor(comms_target:getWeaponStorage(missile_type)),
                        math.floor(
                            comms_target:getWeaponStorageMax(missile_type)
                        )
                    )
            end
        end
        if profile.friendly_status_destination then
            local docked_with = comms_target:getDockedWith()
            if docked_with ~= nil then
                text = string.format(
                    _("shipAssist-comms", "%s\nDocked with %s"),
                    text,
                    docked_with:getCallSign()
                )
            elseif string.find("Dock", comms_target:getOrder()) then
                local transport_target = comms_target:getOrderTarget()
                if transport_target ~= nil and transport_target:isValid() then
                    text = string.format(
                        _(
                            "shipAssist-comms",
                            "%s\nHeading for %s station %s in %s"
                        ),
                        text,
                        transport_target:getFaction(),
                        transport_target:getCallSign(),
                        transport_target:getSectorName()
                    )
                end
            end
        end
        if profile.status_jump_charge and comms_target:hasJumpDrive() then
            text = string.format(
                _("shipAssist-comms", "%sJump drive charge: %s"),
                text,
                comms_target:getJumpDriveCharge()
            )
        end
        setCommsMessage(text)
        addBack(profile)
    end)
end

local function addDock(profile)
    for _index, object in ipairs(comms_target:getObjectsInRange(5000)) do
        local eligible = isObjectType(object, "SpaceStation")
            and not comms_target:isEnemy(object)
        if profile.dock_filter ~= nil then
            eligible = profile.dock_filter(object)
        elseif eligible and profile.can_dock ~= nil then
            eligible = profile.can_dock(object)
        end
        if eligible then
            addCommsReply(
                string.format(
                    _("shipAssist-comms", "Dock at %s"),
                    object:getCallSign()
                ),
                function()
                    setCommsMessage(
                        string.format(
                            _("shipAssist-comms", "Docking at %s."),
                            object:getCallSign()
                        )
                    )
                    comms_target:orderDock(object)
                    addBack(profile)
                end
            )
        end
    end
end

function M.friendlyComms(profile, comms_data)
    local comms_source = source(profile)
    if comms_data.friendlyness < 20 then
        setCommsMessage(_("shipAssist-comms", "What do you want?"))
    else
        setCommsMessage(_("shipAssist-comms", "Sir, how can we assist?"))
    end
    local config = orderConfig(profile)
    for _index, option in
        ipairs(profile.friendly_options or DEFAULT_FRIENDLY_OPTIONS)
    do
        if option == "assist" then
            if comms_data.friendlyness > 0.2 then
                Group.addOrder(config, option)
            end
        elseif option == "status" then
            addStatus(profile)
        elseif option == "dock" then
            addDock(profile)
        elseif option == "trade" then
            if comms_target:getTypeName():find("Freighter") ~= nil then
                freighterTrade(profile, comms_data, "friendly")
            end
        elseif option == "group" then
            if profile.group ~= nil then
                Group.addMenu(profile.group)
            end
        elseif option == "extra" then
            if profile.friendly_extra ~= nil then
                profile.friendly_extra(comms_data)
            end
        else
            Group.addOrder(config, option)
        end
    end
    return true
end

local function isTrader(profile)
    local ship_type = comms_target:getTypeName()
    for _index, marker in ipairs(profile.trader_types or { "Freighter" }) do
        if ship_type:find(marker) ~= nil then
            return true
        end
    end
    return false
end

local function addCloseDestination(profile)
    addCommsReply(_("shipAssist-comms", "Where are you going?"), function()
        local docked_with = comms_target:getDockedWith()
        local text = string.format(
            _("shipAssist-comms", "Hi %s,"),
            source(profile):getCallSign()
        )
        if docked_with ~= nil then
            text = string.format(
                _("shipAssist-comms", "%s\nDocked with %s"),
                text,
                docked_with:getCallSign()
            )
        elseif string.find("Dock", comms_target:getOrder()) then
            local transport_target = comms_target:getOrderTarget()
            if transport_target ~= nil and transport_target:isValid() then
                text = string.format(
                    _(
                        "shipAssist-comms",
                        "%s\nHeading for %s station %s in sector %s"
                    ),
                    text,
                    transport_target:getFaction(),
                    transport_target:getCallSign(),
                    transport_target:getSectorName()
                )
            end
        end
        setCommsMessage(text)
        addBack(profile)
    end)
end

local function addPaidDestination(profile, comms_data)
    local comms_source = source(profile)
    if comms_data.friendlyness > 66 then
        addCommsReply(_("trade-comms", "Where are you headed?"), function()
            setCommsMessage(comms_target.target:getCallSign())
            addBack(profile)
        end)
    elseif comms_data.friendlyness > 33 then
        local cost = random(1, 5)
        addCommsReply(
            string.format(
                _(
                    "trade-comms",
                    profile.neutral_destination_cost_format
                        or "Where are you headed? (cost: %.1f reputation)"
                ),
                cost
            ),
            function()
                if not comms_source:takeReputationPoints(cost) then
                    setCommsMessage(
                        _("needRep-comms", "Insufficient reputation")
                    )
                else
                    setCommsMessage(comms_target.target:getCallSign())
                end
                addBack(profile)
            end
        )
    end
end

function M.freighterNeutralMessage(comms_data)
    if comms_data.friendlyness > 66 then
        return _("trade-comms", "Yes?")
    elseif comms_data.friendlyness > 33 then
        return _("shipAssist-comms", "What do you want?")
    end
    return _("trade-comms", "Why are you bothering me?")
end

function M.neutralComms(profile, comms_data)
    local comms_source = source(profile)
    if profile.neutral_before ~= nil then
        profile.neutral_before(comms_data)
    end
    if not isTrader(profile) then
        if comms_data.friendlyness > 50 then
            setCommsMessage(
                _(
                    "ship-comms",
                    "Sorry, we have no time to chat with you.\nWe are on an important mission."
                )
            )
        else
            setCommsMessage(
                _("ship-comms", "We have nothing for you.\nGood day.")
            )
        end
        return true
    end
    if profile.neutral_message ~= nil then
        setCommsMessage(profile.neutral_message(comms_data))
    else
        setCommsMessage(_("trade-comms", "Yes?"))
    end
    if profile.neutral_after_message ~= nil then
        profile.neutral_after_message(comms_data)
    end
    if profile.neutral_cargo_query ~= false then
        addCargoQuery(profile, comms_data, false)
    end
    local destination = profile.neutral_destination_query
    if destination == "free" and comms_data.friendlyness > 66 then
        addPaidDestination(profile, comms_data)
    elseif destination == "paid" then
        addPaidDestination(profile, comms_data)
    elseif
        destination
        and distance(comms_source, comms_target)
            < (profile.trade and profile.trade.range or 5000)
    then
        addCloseDestination(profile)
    end
    if
        distance(comms_source, comms_target)
        < (profile.trade and profile.trade.range or 5000)
    then
        freighterTrade(profile, comms_data, "neutral")
    end
    return true
end

function M.commsShipGetter(profile)
    return function()
        if type(profile) == "function" then
            return M.commsShip(profile())
        end
        return M.commsShip(profile)
    end
end

function M.commsShip(profile)
    profile = profile or {}
    if comms_target.comms_data == nil then
        comms_target.comms_data = { friendlyness = random(0.0, 100.0) }
    end
    comms_data = comms_target.comms_data
    if profile.init_goods ~= nil then
        profile.init_goods(comms_target, comms_data)
    elseif comms_data.goods == nil then
        M.goodsOnShip(comms_target, comms_data)
    end
    if profile.before_comms ~= nil then
        profile.before_comms()
    end
    local comms_source = source(profile)
    if comms_source:isFriendly(comms_target) then
        if profile.friendly ~= nil then
            return profile.friendly(comms_data)
        end
        return M.friendlyComms(profile, comms_data)
    end
    if
        comms_source:isEnemy(comms_target)
        and comms_target:isFriendOrFoeIdentifiedBy(comms_source)
    then
        if profile.enemy ~= nil then
            return profile.enemy(comms_data)
        end
        return M.enemyCommsSimple(comms_data, comms_source)
    end
    if profile.neutral ~= nil then
        return profile.neutral(comms_data)
    end
    return M.neutralComms(profile, comms_data)
end

function M.serviceJonqueComms(handlers)
    if comms_target.comms_data == nil then
        comms_target.comms_data = { friendlyness = random(0.0, 100.0) }
    end
    comms_data = comms_target.comms_data
    if comms_source:isFriendly(comms_target) then
        return handlers.friendly(comms_data)
    end
    if
        comms_source:isEnemy(comms_target)
        and comms_target:isFriendOrFoeIdentifiedBy(comms_source)
    then
        return handlers.enemy(comms_data)
    end
    return handlers.neutral(comms_data)
end

return M
