-- Shared continuum and reversion communication helpers used in Planet Devourer, Doomed Outpost, Borderline Fever, and The Omicron Plague.

local M = {}

function M.checkContinuum(delta)
    local continuum_count = 0
    for pidx = 1, 32 do
        local p = getPlayerShip(pidx)
        if p ~= nil and p:isValid() then
            if p.continuum_target then
                continuum_count = continuum_count + 1
                if p.continuum_timer == nil then
                    p.continuum_timer = delta + 30
                end
                p.continuum_timer = p.continuum_timer - delta
                if p.continuum_timer < 0 then
                    if
                        p.continuum_initiator ~= nil
                        and p.continuum_initiator:isValid()
                    then
                        if random(1, 100) < (30 + (difficulty * 4)) then
                            p:setSystemHealth(
                                "frontshield",
                                (p:getSystemHealth("frontshield") - 1) / 2
                            )
                        end
                        if random(1, 100) < (30 + (difficulty * 4)) then
                            p:setSystemHealth(
                                "rearshield",
                                (p:getSystemHealth("rearshield") - 1) / 2
                            )
                        end
                        if random(1, 100) < (30 + (difficulty * 4)) then
                            p:setSystemHealth(
                                "reactor",
                                (p:getSystemHealth("reactor") - 1) / 2
                            )
                        end
                        if random(1, 100) < (30 + (difficulty * 4)) then
                            p:setSystemHealth(
                                "maneuver",
                                (p:getSystemHealth("maneuver") - 1) / 2
                            )
                        end
                        if random(1, 100) < (30 + (difficulty * 4)) then
                            p:setSystemHealth(
                                "impulse",
                                (p:getSystemHealth("impulse") - 1) / 2
                            )
                        end
                        if random(1, 100) < (30 + (difficulty * 4)) then
                            p:setSystemHealth(
                                "beamweapons",
                                (p:getSystemHealth("beamweapons") - 1) / 2
                            )
                        end
                        if random(1, 100) < (30 + (difficulty * 4)) then
                            p:setSystemHealth(
                                "missilesystem",
                                (p:getSystemHealth("missilesystem") - 1) / 2
                            )
                        end
                        if random(1, 100) < (30 + (difficulty * 4)) then
                            p:setSystemHealth(
                                "warp",
                                (p:getSystemHealth("warp") - 1) / 2
                            )
                        end
                        if random(1, 100) < (30 + (difficulty * 4)) then
                            p:setSystemHealth(
                                "jumpdrive",
                                (p:getSystemHealth("jumpdrive") - 1) / 2
                            )
                        end
                        local ex, ey = p.continuum_initiator:getPosition()
                        p.continuum_initiator:destroy()
                        ExplosionEffect():setPosition(ex, ey):setSize(3000)
                        resetContinuum(p)
                    else
                        resetContinuum(p)
                    end
                else
                    local timer_display = string.format(
                        _("-tabRelay&Operations", "Disruption %i"),
                        math.floor(p.continuum_timer)
                    )
                    if p:hasPlayerAtPosition("Relay") then
                        p.continuum_timer_display = "continuum_timer_display"
                        p:addCustomInfo(
                            "Relay",
                            p.continuum_timer_display,
                            timer_display,
                            1
                        )
                    end
                    if p:hasPlayerAtPosition("Operations") then
                        p.continuum_timer_display_ops =
                            "continuum_timer_display_ops"
                        p:addCustomInfo(
                            "Operations",
                            p.continuum_timer_display_ops,
                            timer_display,
                            1
                        )
                    end
                end
            else
                resetContinuum(p)
            end
        end
    end
end

function M.resetContinuum(p)
    p.continuum_target = nil
    p.continuum_timer = nil
    p.continuum_initiator = nil
    if p.continuum_timer_display ~= nil then
        p:removeCustom("Relay", p.continuum_timer_display)
        p.continuum_timer_display = nil
    end
    if p.continuum_timer_display_ops ~= nil then
        p:removeCustom("Operations", p.continuum_timer_display_ops)
        p.continuum_timer_display_ops = nil
    end
end

function M.revertWait(delta)
    revert_timer = revert_timer - delta
    if revert_timer < 0 then
        revert_timer = delta + revert_timer_interval
        plotRevert = revertCheck
    end
end

function M.revertCheck(delta)
    if enemy_reverts ~= nil then
        for _, enemy in ipairs(enemy_reverts) do
            if enemy ~= nil and enemy:isValid() then
                local expiration_chance = 0
                local enemy_faction = enemy:getFaction()
                if enemy.taunt_may_expire then
                    if enemy_faction == "Kraylor" then
                        expiration_chance = 4.5
                    elseif enemy_faction == "Arlenians" then
                        expiration_chance = 7
                    elseif enemy_faction == "Exuari" then
                        expiration_chance = 2.5
                    elseif enemy_faction == "Ghosts" then
                        expiration_chance = 8.5
                    elseif enemy_faction == "Ktlitans" then
                        expiration_chance = 5.5
                    elseif enemy_faction == "TSN" then
                        expiration_chance = 3
                    elseif enemy_faction == "USN" then
                        expiration_chance = 3.5
                    elseif enemy_faction == "CUF" then
                        expiration_chance = 4
                    else
                        expiration_chance = 6
                    end
                elseif enemy.amenability_may_expire then
                    local enemy_health = getEnemyHealth(enemy)
                    if enemy_faction == "Kraylor" then
                        expiration_chance = 2.5
                    elseif enemy_faction == "Arlenians" then
                        expiration_chance = 3.25
                    elseif enemy_faction == "Exuari" then
                        expiration_chance = 6.6
                    elseif enemy_faction == "Ghosts" then
                        expiration_chance = 3.2
                    elseif enemy_faction == "Ktlitans" then
                        expiration_chance = 4.8
                    elseif enemy_faction == "TSN" then
                        expiration_chance = 3.5
                    elseif enemy_faction == "USN" then
                        expiration_chance = 2.8
                    elseif enemy_faction == "CUF" then
                        expiration_chance = 3
                    else
                        expiration_chance = 4
                    end
                    expiration_chance = expiration_chance + enemy_health * 5
                end
                local expiration_roll = random(1, 100)
                if expiration_roll < expiration_chance then
                    local oo = enemy.original_order
                    local otx = enemy.original_target_x
                    local oty = enemy.original_target_y
                    local ot = enemy.original_target
                    if oo ~= nil then
                        if oo == "Attack" then
                            if ot ~= nil and ot:isValid() then
                                enemy:orderAttack(ot)
                            else
                                enemy:orderRoaming()
                            end
                        elseif oo == "Dock" then
                            if ot ~= nil and ot:isValid() then
                                enemy:orderDock(ot)
                            else
                                enemy:orderRoaming()
                            end
                        elseif oo == "Defend Target" then
                            if ot ~= nil and ot:isValid() then
                                enemy:orderDefendTarget(ot)
                            else
                                enemy:orderRoaming()
                            end
                        elseif oo == "Fly towards" then
                            if otx ~= nil and oty ~= nil then
                                enemy:orderFlyTowards(otx, oty)
                            else
                                enemy:orderRoaming()
                            end
                        elseif oo == "Defend Location" then
                            if otx ~= nil and oty ~= nil then
                                enemy:orderDefendLocation(otx, oty)
                            else
                                enemy:orderRoaming()
                            end
                        elseif oo == "Fly towards (ignore all)" then
                            if otx ~= nil and oty ~= nil then
                                enemy:orderFlyTowardsBlind(otx, oty)
                            else
                                enemy:orderRoaming()
                            end
                        else
                            enemy:orderRoaming()
                        end
                    else
                        enemy:orderRoaming()
                    end
                    if enemy.original_faction ~= nil then
                        enemy:setFaction(enemy.original_faction)
                    end
                    enemy.taunt_may_expire = false
                    enemy.amenability_may_expire = false
                end
            end
        end
    end
    plotRevert = revertWait
end

function M.revertCheckAlternate(delta)
    if enemy_reverts ~= nil then
        for i, enemy in ipairs(enemy_reverts) do
            if enemy ~= nil and enemy:isValid() then
                local expiration_chance = 0
                local enemy_faction = enemy:getFaction()
                if enemy.taunt_may_expire then
                    if enemy_faction == "Kraylor" then
                        expiration_chance = 4.5
                    elseif enemy_faction == "Arlenians" then
                        expiration_chance = 7
                    elseif enemy_faction == "Exuari" then
                        expiration_chance = 2.5
                    elseif enemy_faction == "Ghosts" then
                        expiration_chance = 8.5
                    elseif enemy_faction == "Ktlitans" then
                        expiration_chance = 5.5
                    elseif enemy_faction == "TSN" then
                        expiration_chance = 3
                    elseif enemy_faction == "USN" then
                        expiration_chance = 3.5
                    elseif enemy_faction == "CUF" then
                        expiration_chance = 4
                    else
                        expiration_chance = 6
                    end
                elseif enemy.amenability_may_expire then
                    local enemy_health = getEnemyHealth(enemy)
                    if enemy_faction == "Kraylor" then
                        expiration_chance = 2.5
                    elseif enemy_faction == "Arlenians" then
                        expiration_chance = 3.25
                    elseif enemy_faction == "Exuari" then
                        expiration_chance = 6.6
                    elseif enemy_faction == "Ghosts" then
                        expiration_chance = 3.2
                    elseif enemy_faction == "Ktlitans" then
                        expiration_chance = 4.8
                    elseif enemy_faction == "TSN" then
                        expiration_chance = 3.5
                    elseif enemy_faction == "USN" then
                        expiration_chance = 2.8
                    elseif enemy_faction == "CUF" then
                        expiration_chance = 3
                    else
                        expiration_chance = 4
                    end
                    expiration_chance = expiration_chance + enemy_health * 5
                end
                local expiration_roll = random(1, 100)
                if expiration_roll < expiration_chance then
                    local oo = enemy.original_order
                    local otx = enemy.original_target_x
                    local oty = enemy.original_target_y
                    local ot = enemy.original_target
                    if oo ~= nil then
                        if oo == "Attack" then
                            if ot ~= nil and ot:isValid() then
                                enemy:orderAttack(ot)
                            else
                                enemy:orderRoaming()
                            end
                        elseif oo == "Dock" then
                            if ot ~= nil and ot:isValid() then
                                enemy:orderDock(ot)
                            else
                                enemy:orderRoaming()
                            end
                        elseif oo == "Defend Target" then
                            if ot ~= nil and ot:isValid() then
                                enemy:orderDefendTarget(ot)
                            else
                                enemy:orderRoaming()
                            end
                        elseif oo == "Fly towards" then
                            if otx ~= nil and oty ~= nil then
                                enemy:orderFlyTowards(otx, oty)
                            else
                                enemy:orderRoaming()
                            end
                        elseif oo == "Defend Location" then
                            if otx ~= nil and oty ~= nil then
                                enemy:orderDefendLocation(otx, oty)
                            else
                                enemy:orderRoaming()
                            end
                        elseif oo == "Fly towards (ignore all)" then
                            if otx ~= nil and oty ~= nil then
                                enemy:orderFlyTowardsBlind(otx, oty)
                            else
                                enemy:orderRoaming()
                            end
                        else
                            enemy:orderRoaming()
                        end
                    else
                        enemy:orderRoaming()
                    end
                    if enemy.original_faction ~= nil then
                        enemy:setFaction(enemy.original_faction)
                    end
                    enemy.taunt_may_expire = false
                    enemy.amenability_may_expire = false
                end
            end
        end
    end
    plotRevert = revertWait
end

return M
