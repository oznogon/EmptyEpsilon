-- Defensive ship communications utility from Carrier and Fighters, Borderline Fever, and Chaos of War.

local Defense = {}

local function prompt(context, text)
    return { context = context, text = text }
end

local default_message = prompt("shipEnemy-comms", "Mind your own business!")
local default_taunt = {
    option = prompt("shipEnemy-comms", "We will see to your destruction!"),
    success = prompt("shipEnemy-comms", "Your bloodline will end here!"),
    failure = prompt("shipEnemy-comms", "Your feeble threats are meaningless."),
}
local faction_prompts = {
    Kraylor = {
        message = prompt(
            "shipEnemy-comms",
            "Ktzzzsss.\nYou will DIEEee weaklingsss!"
        ),
    },
    Arlenians = {
        message = prompt(
            "shipEnemy-comms",
            "We wish you no harm, but will harm you if we must.\nEnd of transmission."
        ),
    },
    Exuari = {
        message = prompt(
            "shipEnemy-comms",
            "Stay out of our way, or your death will amuse us extremely!"
        ),
    },
    Ghosts = {
        message = prompt(
            "shipEnemy-comms",
            "One zero one.\nNo binary communication detected.\nSwitching to universal speech.\nGenerating appropriate response for target from human language archives.\n:Do not cross us:\nCommunication halted."
        ),
        taunt = {
            option = prompt("shipEnemy-comms", "EXECUTE: SELFDESTRUCT"),
            success = prompt(
                "shipEnemy-comms",
                "Rogue command received. Targeting source."
            ),
            failure = prompt("shipEnemy-comms", "External command ignored."),
        },
    },
    Ktlitans = {
        message = prompt(
            "shipEnemy-comms",
            "The hive suffers no threats. Opposition to any of us is opposition to us all.\nStand down or prepare to donate your corpses toward our nutrition."
        ),
        taunt = {
            option = prompt(
                "shipEnemy-comms",
                "<Transmit 'The Itsy-Bitsy Spider' on all wavelengths>"
            ),
            success = prompt(
                "shipEnemy-comms",
                "We do not need permission to pluck apart such an insignificant threat."
            ),
            failure = prompt(
                "shipEnemy-comms",
                "The hive has greater priorities than exterminating pests."
            ),
        },
    },
}

local function localize(value)
    return _(value.context, value.text)
end

function Defense.new(options)
    options = options or {}
    local function target()
        return options.target()
    end
    local function source()
        return options.source()
    end
    local function data()
        return options.data()
    end

    local function enemyDefendComms(comms_data)
        comms_data = comms_data or data()
        if comms_data.friendlyness > 50 then
            local comms_target = target()
            local profile = faction_prompts[comms_target:getFaction()] or {}
            local taunt = profile.taunt or default_taunt
            local taunt_option = localize(taunt.option)
            local taunt_success = localize(taunt.success)
            local taunt_failure = localize(taunt.failure)
            setCommsMessage(localize(profile.message or default_message))
            comms_data.friendlyness = comms_data.friendlyness - random(0, 10)
            addCommsReply(taunt_option, function()
                if random(0, 100) < 30 then
                    comms_target:orderAttack(source())
                    setCommsMessage(taunt_success)
                else
                    setCommsMessage(taunt_failure)
                end
            end)
            return true
        end
        return false
    end

    local function neutralDefendComms(comms_data)
        comms_data = comms_data or data()
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

    return {
        enemyDefendComms = enemyDefendComms,
        neutralDefendComms = neutralDefendComms,
    }
end

return Defense
