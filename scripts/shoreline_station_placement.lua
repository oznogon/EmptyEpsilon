-- Shoreline-specific station wrappers and map placement.

local catalog = require("shoreline_station_catalog.lua")

local M = {}

function M.new(options)
    options = options or {}
    local api = {}

    local function szt()
        --Randomly choose station size template
        if stationSize ~= nil then
            sizeTemplate = stationSize
            return sizeTemplate
        end
        stationSizeRandom = random(1, 100)
        if stationSizeRandom < 8 then
            sizeTemplate = "Huge Station" -- 8 percent huge
        elseif stationSizeRandom < 24 then
            sizeTemplate = "Large Station" --16 percent large
        elseif stationSizeRandom < 50 then
            sizeTemplate = "Medium Station" --26 percent medium
        else
            sizeTemplate = "Small Station" --50 percent small
        end
        return sizeTemplate
    end
    --neutral and friendly stations
    function api.placeVaiken()
        --Vaiken
        stationVaiken = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationVaiken
            :setPosition(psx, psy)
            :setCallSign("Vaiken")
            :setDescription(
                _(
                    "scienceDescription-station",
                    "Ship building and maintenance facility"
                )
            )
        stationVaiken.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = true,
                HVLI = true,
                Mine = true,
                Nuke = true,
                EMP = true,
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 2.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = {
                food = { quantity = 10, cost = 1 },
                medicine = { quantity = 5, cost = 5 },
            },
            trade = { food = false, medicine = false, luxury = false },
            public_relations = true,
            general_information = _(
                "stationGeneralInfo-comms",
                "Human Navy headquarters. Loss of this station would be devastating"
            ),
        }
        return stationVaiken
    end
    function api.placeZefram()
        --Zefram
        stationZefram = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationZefram
            :setPosition(psx, psy)
            :setCallSign("Zefram")
            :setDescription(
                _("scienceDescription-station", "Warp engine components")
            )
        stationZefram.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            weapon_cost = {
                Homing = 2,
                HVLI = math.random(3),
                Mine = math.random(4),
                Nuke = math.random(10, 15),
                EMP = 10,
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 2.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { warp = { quantity = 5, cost = 140 } },
            trade = { food = true, medicine = false, luxury = true },
            public_relations = true,
            general_information = _(
                "stationGeneralInfo-comms",
                "We specialize in the esoteric components necessary to make warp drives function properly"
            ),
            history = _(
                "stationStory-comms",
                "Zefram Cochrane constructed the first warp drive in human history. We named our station after him because of the specialized warp systems work we do"
            ),
        }
        if stationFaction == "Human Navy" then
            stationZefram.comms_data.goods.food =
                { quantity = math.random(5, 10), cost = 1 }
            if random(1, 5) <= 1 then
                stationZefram.comms_data.goods.medicine =
                    { quantity = 5, cost = 5 }
            else
                stationZefram.comms_data.trade.medicine = random(1, 100) < 27
            end
        else
            stationZefram.comms_data.trade.medicine = random(1, 100) < 27
            stationZefram.comms_data.trade.food = random(1, 100) < 16
        end
        return stationZefram
    end
    function api.placeMarconi()
        --Marconi
        stationMarconi = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationMarconi
            :setPosition(psx, psy)
            :setCallSign("Marconi")
            :setDescription(
                _("scienceDescription-station", "Energy Beam Components")
            )
        stationMarconi.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = f_n[math.random(2)],
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = f_n[math.random(2)],
                EMP = f_n[math.random(2)],
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 2.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { beam = { quantity = 5, cost = 80 } },
            trade = { food = true, medicine = false, luxury = true },
            public_relations = true,
            general_information = _(
                "stationGeneralInfo-comms",
                "We manufacture energy beam components"
            ),
            history = _(
                "stationStory-comms",
                "Station named after Guglielmo Marconi an Italian inventor from early 20th century Earth who, along with Nicolo Tesla, claimed to have invented a death ray or particle beam weapon"
            ),
        }
        if stationFaction == "Human Navy" then
            stationMarconi.comms_data.goods.food =
                { quantity = math.random(5, 10), cost = 1 }
            if random(1, 5) <= 1 then
                stationMarconi.comms_data.goods.medicine =
                    { quantity = 5, cost = 5 }
            else
                stationMarconi.comms_data.trade.medicine = true
            end
        else
            stationMarconi.comms_data.trade.luxury = true
            stationMarconi.comms_data.trade.food = true
        end
        return stationMarconi
    end
    function api.placeMuddville()
        --Muddville
        stationMudd = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationMudd
            :setPosition(psx, psy)
            :setCallSign("Muddville")
            :setDescription(_("scienceDescription-station", "Trading station"))
        stationMudd.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 2.5 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { luxury = { quantity = 10, cost = 60 } },
            trade = { food = false, medicine = false, luxury = false },
            public_relations = true,
            general_information = _(
                "stationGeneralInfo-comms",
                "Come to Muddvile for all your trade and commerce needs and desires"
            ),
            history = _(
                "stationStory-comms",
                "Upon retirement, Harry Mudd started this commercial venture using his leftover inventory and extensive connections obtained while he traveled the stars as a salesman"
            ),
        }
        if stationFaction == "Human Navy" then
            stationMudd.comms_data.goods.food =
                { quantity = math.random(5, 10), cost = 1 }
            if random(1, 5) <= 1 then
                stationMudd.comms_data.goods.medicine =
                    { quantity = 5, cost = 5 }
            end
        end
        return stationMudd
    end
    function api.placeAlcaleica()
        --Alcaleica
        stationAlcaleica = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationAlcaleica
            :setPosition(psx, psy)
            :setCallSign("Alcaleica")
            :setDescription(
                _("scienceDescription-station", "Optical Components")
            )
        stationAlcaleica.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { optic = { quantity = 5, cost = 66 } },
            trade = { food = false, medicine = false, luxury = false },
            buy = { [randomMineral()] = math.random(40, 200) },
            public_relations = true,
            general_information = _(
                "stationGeneralInfo-comms",
                "We make and supply optic components for various station and ship systems"
            ),
            history = _(
                "stationStory-comms",
                "This station continues the businesses from Earth based on the merging of several companies including Leica from Switzerland, the lens manufacturer and the Japanese advanced low carbon (ALCA) electronic and optic research and development company"
            ),
        }
        if stationFaction == "Human Navy" then
            stationAlcaleica.comms_data.goods.food =
                { quantity = math.random(5, 10), cost = 1 }
            if random(1, 5) <= 1 then
                stationAlcaleica.comms_data.goods.medicine =
                    { quantity = 5, cost = 5 }
            else
                stationAlcaleica.comms_data.trade.medicine = true
            end
        else
            stationAlcaleica.comms_data.trade.medicine = true
            stationAlcaleica.comms_data.trade.food = true
        end
        return stationAlcaleica
    end
    function api.placeCalifornia()
        --California
        stationCalifornia = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationCalifornia
            :setPosition(psx, psy)
            :setCallSign("California")
            :setDescription(_("scienceDescription-station", "Mining station"))
        stationCalifornia.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 2.5 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = {
                gold = { quantity = 5, cost = 90 },
                dilithium = { quantity = 2, cost = 25 },
            },
            trade = { food = false, medicine = false, luxury = false },
            buy = { [randomComponent()] = math.random(40, 200) },
        }
        if stationFaction == "Human Navy" then
            stationCalifornia.comms_data.goods.food =
                { quantity = math.random(5, 10), cost = 1 }
            if random(1, 5) <= 1 then
                stationCalifornia.comms_data.goods.medicine =
                    { quantity = 5, cost = 5 }
            end
        end
        return stationCalifornia
    end
    function api.placeOutpost15()
        --Outpost 15
        stationOutpost15 = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationOutpost15
            :setPosition(psx, psy)
            :setCallSign("Outpost-15")
            :setDescription(_("scienceDescription-station", "Mining and trade"))
        stationOutpost15.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { luxury = { quantity = 5, cost = 70 } },
            trade = { food = true, medicine = false, luxury = false },
        }
        local outpost15Goods = random(1, 100)
        if outpost15Goods < 20 then
            stationOutpost15.comms_data.goods.gold =
                { quantity = 5, cost = math.random(22, 30) }
            stationOutpost15.comms_data.goods.cobalt =
                { quantity = 4, cost = math.random(45, 55) }
        elseif outpost15Goods < 40 then
            stationOutpost15.comms_data.goods.gold =
                { quantity = 5, cost = math.random(22, 30) }
        elseif outpost15Goods < 60 then
            stationOutpost15.comms_data.goods.cobalt =
                { quantity = 4, cost = math.random(45, 55) }
        else
            stationOutpost15.comms_data.goods.platinum =
                { quantity = 4, cost = math.random(55, 65) }
        end
        if stationFaction == "Human Navy" then
            stationOutpost15.comms_data.goods.food =
                { quantity = math.random(5, 10), cost = 1 }
            if random(1, 5) <= 1 then
                stationOutpost15.comms_data.goods.medicine =
                    { quantity = 5, cost = 5 }
            else
                stationOutpost15.comms_data.trade.medicine = true
            end
        else
            stationOutpost15.comms_data.trade.food = true
        end
        placeRandomAroundPoint(Asteroid, 15, 1, 15000, psx, psy)
        return stationOutpost15
    end
    function api.placeOutpost21()
        --Outpost 21
        stationOutpost21 = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationOutpost21
            :setPosition(psx, psy)
            :setCallSign("Outpost-21")
            :setDescription(
                _("scienceDescription-station", "Mining and gambling")
            )
        stationOutpost21.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { luxury = { quantity = 5, cost = 70 } },
            trade = { food = false, medicine = false, luxury = true },
        }
        placeRandomAroundPoint(Asteroid, 15, 1, 15000, psx, psy)
        local outpost21Goods = random(1, 100)
        if outpost21Goods < 20 then
            stationOutpost21.comms_data.goods.gold =
                { quantity = 5, cost = math.random(22, 30) }
            stationOutpost21.comms_data.goods.cobalt =
                { quantity = 4, cost = math.random(45, 55) }
        elseif outpost21Goods < 40 then
            stationOutpost21.comms_data.goods.gold =
                { quantity = 5, cost = math.random(22, 30) }
        elseif outpost21Goods < 60 then
            stationOutpost21.comms_data.goods.cobalt =
                { quantity = 4, cost = math.random(45, 55) }
        else
            stationOutpost21.comms_data.goods.dilithium =
                { quantity = 4, cost = math.random(45, 55) }
        end
        if stationFaction == "Human Navy" then
            stationOutpost21.comms_data.goods.food =
                { quantity = math.random(5, 10), cost = 1 }
            if random(1, 5) <= 1 then
                stationOutpost21.comms_data.goods.medicine =
                    { quantity = 5, cost = 5 }
            else
                stationOutpost21.comms_data.trade.medicine = random(1, 100) < 50
            end
        else
            stationOutpost21.comms_data.trade.food = true
            stationOutpost21.comms_data.trade.medicine = random(1, 100) < 50
        end
        return stationOutpost21
    end
    function api.placeValero()
        --Valero
        stationValero = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationValero
            :setPosition(psx, psy)
            :setCallSign("Valero")
            :setDescription(_("scienceDescription-station", "Resupply"))
        stationValero.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 2.5 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { luxury = { quantity = 5, cost = 90 } },
            trade = { food = false, medicine = false, luxury = false },
        }
        return stationValero
    end
    function api.placeVactel()
        --Vactel
        stationVactel = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationVactel
            :setPosition(psx, psy)
            :setCallSign("Vactel")
            :setDescription(
                _(
                    "scienceDescription-station",
                    "Shielded Circuitry Fabrication"
                )
            )
        stationVactel.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { circuit = { quantity = 5, cost = 50 } },
            trade = { food = false, medicine = false, luxury = false },
            public_relations = true,
            general_information = _(
                "stationGeneralInfo-comms",
                "We specialize in circuitry shielded from external hacking suitable for ship systems"
            ),
            history = _(
                "stationStory-comms",
                "We started as an expansion from the lunar based chip manufacturer of Earth legacy Intel electronic chips"
            ),
        }
        if stationFaction == "Human Navy" then
            stationVactel.comms_data.goods.food =
                { quantity = math.random(5, 10), cost = 1 }
            if random(1, 5) <= 1 then
                stationVactel.comms_data.goods.medicine =
                    { quantity = 5, cost = 5 }
            end
        end
        return stationVactel
    end

    function api.placeArcher()
        --Archer
        stationArcher = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationArcher
            :setPosition(psx, psy)
            :setCallSign("Archer")
            :setDescription(
                _("scienceDescription-station", "Shield and Armor Research")
            )
        stationArcher.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { shield = { quantity = 5, cost = 90 } },
            trade = { food = false, medicine = false, luxury = true },
            buy = { [randomMineral()] = math.random(40, 200) },
            public_relations = true,
            general_information = _(
                "stationGeneralInfo-comms",
                "The finest shield and armor manufacturer in the quadrant"
            ),
            history = _(
                "stationStory-comms",
                "We named this station for the pioneering spirit of the 22nd century Starfleet explorer, Captain Jonathan Archer"
            ),
        }
        if stationFaction == "Human Navy" then
            stationArcher.comms_data.goods.food =
                { quantity = math.random(5, 10), cost = 1 }
            if random(1, 5) <= 1 then
                stationArcher.comms_data.goods.medicine =
                    { quantity = 5, cost = 5 }
            else
                stationArcher.comms_data.trade.medicine = true
            end
        else
            stationArcher.comms_data.trade.medicine = true
        end
        return stationArcher
    end
    function api.placeDeer()
        --Deer
        stationDeer = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationDeer:setPosition(psx, psy):setCallSign("Deer"):setDescription(
            _(
                "scienceDescription-station",
                "Repulsor and Tractor Beam Components"
            )
        )
        stationDeer.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = {
                tractor = { quantity = 5, cost = 90 },
                repulsor = { quantity = 5, cost = 95 },
            },
            trade = { food = true, medicine = false, luxury = true },
            buy = { [randomMineral()] = math.random(40, 200) },
            public_relations = true,
            general_information = _(
                "stationGeneralInfo-comms",
                "We can meet all your pushing and pulling needs with specialized equipment custom made"
            ),
            history = _(
                "stationStory-comms",
                "The station name comes from a short story by the 20th century author Clifford D. Simak as well as from the 19th century developer John Deere who inspired a company that makes the Earth bound equivalents of our products"
            ),
        }
        if stationFaction == "Human Navy" then
            stationDeer.comms_data.goods.food =
                { quantity = math.random(5, 10), cost = 1 }
            stationDeer.comms_data.goods.food.cost = 1
            if random(1, 5) <= 1 then
                stationDeer.comms_data.goods.medicine =
                    { quantity = 5, cost = 5 }
            else
                stationDeer.comms_data.trade.medicine = true
            end
        else
            stationDeer.comms_data.trade.medicine = true
            stationDeer.comms_data.trade.food = true
        end
        return stationDeer
    end
    function api.placeCavor()
        --Cavor
        stationCavor = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationCavor:setPosition(psx, psy):setCallSign("Cavor"):setDescription(
            _("scienceDescription-station", "Advanced Material components")
        )
        stationCavor.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { filament = { quantity = 5, cost = 42 } },
            trade = { food = false, medicine = false, luxury = false },
            public_relations = true,
            general_information = _(
                "stationGeneralInfo-comms",
                "We fabricate several different kinds of materials critical to various space industries like ship building, station construction and mineral extraction"
            ),
            history = _(
                "stationStory-comms",
                "We named our station after Dr. Cavor, the physicist that invented a barrier material for gravity waves - Cavorite"
            ),
        }
        if stationFaction == "Human Navy" then
            stationCavor.comms_data.goods.food =
                { quantity = math.random(5, 10), cost = 1 }
            if random(1, 5) <= 1 then
                stationCavor.comms_data.goods.medicine =
                    { quantity = 5, cost = 5 }
                stationCavor.comms_data.trade.luxury = random(1, 100) < 33
            else
                if random(1, 100) < 50 then
                    stationCavor.comms_data.trade.medicine = true
                else
                    stationCavor.comms_data.trade.luxury = true
                end
            end
        else
            local whatTrade = random(1, 100)
            if whatTrade < 33 then
                stationCavor.comms_data.trade.medicine = true
            elseif whatTrade > 66 then
                stationCavor.comms_data.trade.food = true
            else
                stationCavor.comms_data.trade.luxury = true
            end
        end
        return stationCavor
    end
    function api.placeEmory()
        --Emory
        stationEmory = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationEmory:setPosition(psx, psy):setCallSign("Emory"):setDescription(
            _("scienceDescription-station", "Transporter components")
        )
        stationEmory.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            weapon_cost = {
                Homing = math.random(3),
                HVLI = math.random(2),
                Mine = math.random(2, 4),
                Nuke = math.random(12, 18),
                EMP = math.random(7, 10),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { transporter = { quantity = 5, cost = 76 } },
            trade = { food = false, medicine = false, luxury = false },
        }
        if stationFaction == "Human Navy" then
            stationEmory.comms_data.goods.food =
                { quantity = math.random(5, 10), cost = 1 }
            if random(1, 5) <= 1 then
                stationEmory.comms_data.goods.medicine =
                    { quantity = 5, cost = 5 }
            else
                stationEmory.comms_data.trade.medicine = random(1, 100) < 34
            end
        else
            stationEmory.comms_data.trade.medicine = true
            stationEmory.comms_data.trade.food = random(1, 100) < 13
        end
        stationEmory.comms_data.trade.luxury = random(1, 100) < 43
        return stationEmory
    end
    function api.placeVeloquan()
        --Veloquan
        stationVeloquan = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationVeloquan
            :setPosition(psx, psy)
            :setCallSign("Veloquan")
            :setDescription(
                _("scienceDescription-station", "Sensor components")
            )
        stationVeloquan.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { sensor = { quantity = 5, cost = 68 } },
            trade = { food = false, medicine = false, luxury = false },
            public_relations = true,
            general_information = _(
                "stationGeneralInfo-comms",
                "We research and construct components for the most powerful and accurate sensors used aboard ships along with the software to make them easy to use"
            ),
            history = _(
                "stationStory-comms",
                "The Veloquan company has its roots in the manufacturing of LIDAR sensors in the early 21st century on Earth in the United States for autonomous ground-based vehicles. They expanded research and manufacturing operations to include various sensors for space vehicles. Veloquan was the result of numerous mergers and acquisitions of several companies including Velodyne and Quanergy"
            ),
        }
        if stationFaction == "Human Navy" then
            stationVeloquan.comms_data.goods.food =
                { quantity = math.random(5, 10), cost = 1 }
            if random(1, 5) <= 1 then
                stationVeloquan.comms_data.goods.medicine =
                    { quantity = 5, cost = 5 }
            else
                stationVeloquan.comms_data.trade.medicine = true
            end
        else
            stationVeloquan.comms_data.trade.medicine = true
            stationVeloquan.comms_data.trade.food = true
        end
        return stationVeloquan
    end
    function api.placeBarclay()
        --Barclay
        stationBarclay = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationBarclay
            :setPosition(psx, psy)
            :setCallSign("Barclay")
            :setDescription(
                _("scienceDescription-station", "Communication components")
            )
        stationBarclay.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { communication = { quantity = 5, cost = 58 } },
            trade = { food = false, medicine = false, luxury = false },
            buy = { [randomMineral()] = math.random(40, 200) },
            public_relations = true,
            general_information = _(
                "stationGeneralInfo-comms",
                "We provide a range of communication equipment and software for use aboard ships"
            ),
            history = _(
                "stationStory-comms",
                "The station is named after Reginald Barclay who established the first transgalactic com link through the creative application of a quantum singularity. Station personnel often refer to the station as the Broccoli station"
            ),
        }
        if stationFaction == "Human Navy" then
            stationBarclay.comms_data.goods.food =
                { quantity = math.random(5, 10), cost = 1 }
            if random(1, 5) <= 1 then
                stationBarclay.comms_data.goods.medicine =
                    { quantity = 5, cost = 5 }
            else
                stationBarclay.comms_data.trade.medicine = true
            end
        else
            stationBarclay.comms_data.trade.medicine = true
        end
        return stationBarclay
    end
    function api.placeLipkin()
        --Lipkin
        stationLipkin = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationLipkin
            :setPosition(psx, psy)
            :setCallSign("Lipkin")
            :setDescription(
                _("scienceDescription-station", "Autodoc components")
            )
        stationLipkin.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { autodoc = { quantity = 5, cost = 76 } },
            trade = { food = false, medicine = false, luxury = true },
            public_relations = true,
            general_information = _(
                "stationGeneralInfo-comms",
                "We build and repair and provide components and upgrades for automated facilities designed for ships where a doctor cannot be a crew member (commonly called autodocs)"
            ),
            history = _(
                "stationStory-comms",
                "The station is named after Dr. Lipkin who pioneered some of the research and application around robot assisted surgery in the area of partial nephrectomy for renal tumors in the early 21st century on Earth"
            ),
        }
        if stationFaction == "Human Navy" then
            stationLipkin.comms_data.goods.food =
                { quantity = math.random(5, 10), cost = 1 }
            if random(1, 5) <= 1 then
                stationLipkin.comms_data.goods.medicine =
                    { quantity = 5, cost = 5 }
            end
        else
            stationLipkin.comms_data.trade.food = true
        end
        return stationLipkin
    end
    function api.placeRipley()
        --Ripley
        stationRipley = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationRipley
            :setPosition(psx, psy)
            :setCallSign("Ripley")
            :setDescription(
                _("scienceDescription-station", "Load lifters and components")
            )
        stationRipley.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { lifter = { quantity = 5, cost = 82 } },
            trade = {
                food = false,
                medicine = false,
                luxury = random(1, 100) < 47,
            },
            public_relations = true,
            general_information = _(
                "stationGeneralInfo-comms",
                "We provide load lifters and components"
            ),
            history = _(
                "stationStory-comms",
                "The station is named after Ellen Ripley who made creative and effective use of one of our load lifters when defending her ship"
            ),
        }
        if stationFaction == "Human Navy" then
            stationRipley.comms_data.goods.food =
                { quantity = math.random(5, 10), cost = 1 }
            if random(1, 5) <= 1 then
                stationRipley.comms_data.goods.medicine =
                    { quantity = 5, cost = 5 }
            else
                stationRipley.comms_data.trade.medicine = true
            end
        else
            stationRipley.comms_data.trade.food = random(1, 100) < 17
            stationRipley.comms_data.trade.medicine = true
        end
        return stationRipley
    end
    function api.placeDeckard()
        --Deckard
        stationDeckard = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationDeckard
            :setPosition(psx, psy)
            :setCallSign("Deckard")
            :setDescription(
                _("scienceDescription-station", "Android components")
            )
        stationDeckard.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { android = { quantity = 5, cost = 73 } },
            trade = { food = false, medicine = false, luxury = true },
            public_relations = true,
            general_information = _(
                "stationGeneralInfo-comms",
                "Supplier of android components, programming and service"
            ),
            history = _(
                "stationStory-comms",
                "Named for Richard Deckard who inspired many of the sophisticated safety security algorithms now required for all androids"
            ),
        }
        if stationFaction == "Human Navy" then
            stationDeckard.comms_data.goods.food =
                { quantity = math.random(5, 10), cost = 1 }
            if random(1, 5) <= 1 then
                stationDeckard.comms_data.goods.medicine =
                    { quantity = 5, cost = 5 }
                stationDeckard.comms_data.goods.medicine.cost = 5
            end
        else
            stationDeckard.comms_data.trade.food = true
        end
        return stationDeckard
    end
    function api.placeConnor()
        --Connor
        stationConnor = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationConnor
            :setPosition(psx, psy)
            :setCallSign("Connor")
            :setDescription(
                _("scienceDescription-station", "Automated weapons systems")
            )
        stationConnor.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "neutral",
                EMP = "neutral",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            weapon_cost = {
                Homing = math.random(3),
                HVLI = math.random(2),
                Mine = math.random(2, 4),
                Nuke = math.random(12, 18),
                EMP = math.random(7, 10),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = {},
            trade = { food = false, medicine = false, luxury = false },
            public_relations = true,
            general_information = _(
                "stationGeneralInfo-comms",
                "We research and create automated weapons systems to improve ship combat capability"
            ),
        }
        local stationGoodChoice = math.random(1, 3)
        if stationGoodChoice == 1 then
            stationConnor.comms_data.goods.shield =
                { quantity = 5, cost = math.random(85, 94) }
        elseif stationGoodChoice == 2 then
            stationConnor.comms_data.goods.beam =
                { quantity = 5, cost = math.random(62, 75) }
        else
            stationConnor.comms_data.goods.lifter =
                { quantity = 5, cost = math.random(55, 89) }
        end
        return stationConnor
    end

    function api.placeAnderson()
        --Anderson
        stationAnderson = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationAnderson
            :setPosition(psx, psy)
            :setCallSign("Anderson")
            :setDescription(
                _(
                    "scienceDescription-station",
                    "Battery and software engineering"
                )
            )
        stationAnderson.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = {
                battery = { quantity = 5, cost = 66 },
                software = { quantity = 5, cost = 115 },
            },
            trade = { food = false, medicine = false, luxury = true },
            public_relations = true,
            general_information = _(
                "stationGeneralInfo-comms",
                "We provide high quality high capacity batteries and specialized software for all shipboard systems"
            ),
            history = _(
                "stationStory-comms",
                "The station is named after a fictional software engineer in a late 20th century movie depicting humanity unknowingly conquered by aliens and kept docile by software generated illusion"
            ),
        }
        if stationFaction == "Human Navy" then
            stationAnderson.comms_data.goods.food =
                { quantity = math.random(5, 10), cost = 1 }
            if random(1, 5) <= 1 then
                stationAnderson.comms_data.goods.medicine =
                    { quantity = 5, cost = 5 }
            end
        end
        return stationAnderson
    end
    function api.placeFeynman()
        --Feynman
        stationFeynman = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationFeynman
            :setPosition(psx, psy)
            :setCallSign("Feynman")
            :setDescription(
                _("scienceDescription-station", "Nanotechnology research")
            )
        stationFeynman.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = {
                software = { quantity = 5, cost = 115 },
                nanites = { quantity = 5, cost = 79 },
            },
            trade = { food = false, medicine = false, luxury = true },
            public_relations = true,
            general_information = _(
                "stationGeneralInfo-comms",
                "We provide nanites and software for a variety of ship-board systems"
            ),
            history = _(
                "stationStory-comms",
                "This station's name recognizes one of the first scientific researchers into nanotechnology, physicist Richard Feynman"
            ),
        }
        if stationFaction == "Human Navy" then
            stationFeynman.comms_data.goods.food =
                { quantity = math.random(5, 10), cost = 1 }
            if random(1, 5) <= 1 then
                stationFeynman.comms_data.goods.medicine =
                    { quantity = 5, cost = 5 }
            end
        else
            stationFeynman.comms_data.trade.medicine = true
            stationFeynman.comms_data.trade.food = random(1, 100) < 26
        end
        return stationFeynman
    end
    function api.placeMayo()
        --Mayo
        stationMayo = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationMayo
            :setPosition(psx, psy)
            :setCallSign("Mayo")
            :setDescription(_("scienceDescription-station", "Medical Research"))
        stationMayo.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = {
                autodoc = { quantity = 5, cost = 128 },
                food = { quantity = 5, cost = 1 },
                medicine = { quantity = 5, cost = 5 },
            },
            trade = { food = false, medicine = false, luxury = false },
            public_relations = true,
            general_information = _(
                "stationGeneralInfo-comms",
                "We research exotic diseases and other human medical conditions"
            ),
            history = _(
                "stationStory-comms",
                "We continue the medical work started by William Worrall Mayo in the late 19th century on Earth"
            ),
        }
        return stationMayo
    end
    function api.placeNefatha()
        --Nefatha
        stationNefatha = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationNefatha
            :setPosition(psx, psy)
            :setCallSign("Nefatha")
            :setDescription(
                _("scienceDescription-station", "Commerce and recreation")
            )
        stationNefatha.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { luxury = { quantity = 5, cost = 70 } },
            trade = { food = false, medicine = false, luxury = false },
        }
        return stationNefatha
    end
    function api.placeScience4()
        --Science 4
        stationScience4 = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationScience4
            :setPosition(psx, psy)
            :setCallSign("Science-4")
            :setDescription(_("scienceDescription-station", "Biotech research"))
        stationScience4.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = {},
            trade = { food = false, medicine = false, luxury = false },
        }
        local stationGoodChoice = math.random(1, 3)
        if stationGoodChoice == 1 then
            stationScience4.comms_data.goods.software =
                { quantity = 5, cost = math.random(85, 94) }
        elseif stationGoodChoice == 2 then
            stationScience4.comms_data.goods.circuit =
                { quantity = 5, cost = math.random(62, 75) }
        else
            stationScience4.comms_data.goods.battery =
                { quantity = 5, cost = math.random(55, 89) }
        end
        return stationScience4
    end
    function api.placeSpeculation4()
        --Speculation 4
        stationSpeculation4 = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationSpeculation4
            :setPosition(psx, psy)
            :setCallSign("Speculation 4")
            :setDescription(_("scienceDescription-station", "Trading post"))
        stationSpeculation4.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { luxury = { quantity = 5, cost = 60 } },
            trade = { food = false, medicine = false, luxury = false },
        }
        if stationFaction == "Human Navy" then
            stationSpeculation4.comms_data.goods.food =
                { quantity = math.random(5, 10), cost = 1 }
            if random(1, 5) <= 1 then
                stationSpeculation4.comms_data.goods.medicine =
                    { quantity = 5, cost = 5 }
            end
        end
        return stationSpeculation4
    end
    function api.placeTiberius()
        --Tiberius
        stationTiberius = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationTiberius
            :setPosition(psx, psy)
            :setCallSign("Tiberius")
            :setDescription(
                _("scienceDescription-station", "Logistics coordination")
            )
        stationTiberius.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { food = { quantity = 5, cost = 1 } },
            trade = { food = false, medicine = false, luxury = false },
            public_relations = true,
            general_information = _(
                "stationGeneralInfo-comms",
                "We support the stations and ships in the area with planning and communication services"
            ),
            history = _(
                "stationStory-comms",
                "We recognize the influence of Starfleet Captain James Tiberius Kirk in the 23rd century in our station name"
            ),
        }
        return stationTiberius
    end
    function api.placeResearch11()
        --Research-11
        stationResearch11 = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationResearch11
            :setPosition(psx, psy)
            :setCallSign("Research-11")
            :setDescription(
                _("scienceDescription-station", "Stress Psychology Research")
            )
        stationResearch11.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = {},
            trade = { food = false, medicine = false, luxury = false },
        }
        local stationGoodChoice = math.random(1, 3)
        if stationGoodChoice == 1 then
            stationResearch11.comms_data.goods.warp =
                { quantity = 5, cost = math.random(85, 120) }
        elseif stationGoodChoice == 2 then
            stationResearch11.comms_data.goods.repulsor =
                { quantity = 5, cost = math.random(62, 75) }
        else
            stationResearch11.comms_data.goods.robotic =
                { quantity = 5, cost = math.random(75, 89) }
        end
        return stationResearch11
    end
    function api.placeFreena()
        --Freena
        stationFreena = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationFreena
            :setPosition(psx, psy)
            :setCallSign("Freena")
            :setDescription(
                _(
                    "scienceDescription-station",
                    "Zero gravity sports and entertainment"
                )
            )
        stationFreena.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { luxury = { quantity = 5, cost = 70 } },
            trade = { food = false, medicine = false, luxury = false },
        }
        if stationFaction == "Human Navy" then
            stationFreena.comms_data.goods.food =
                { quantity = math.random(5, 10), cost = 1 }
            if random(1, 5) <= 1 then
                stationFreena.comms_data.goods.medicine =
                    { quantity = 5, cost = 5 }
            else
                stationFreena.comms_data.trade.medicine = true
            end
        else
            stationFreena.comms_data.trade.medicine = true
        end
        return stationFreena
    end
    function api.placeOutpost33()
        --Outpost 33
        stationOutpost33 = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationOutpost33
            :setPosition(psx, psy)
            :setCallSign("Outpost-33")
            :setDescription(_("scienceDescription-station", "Resupply"))
        stationOutpost33.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { luxury = { quantity = 5, cost = 75 } },
            trade = { food = false, medicine = false, luxury = false },
        }
        return stationOutpost33
    end

    function api.placeLando()
        --Lando
        stationLando = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationLando
            :setPosition(psx, psy)
            :setCallSign("Lando")
            :setDescription(
                _("scienceDescription-station", "Casino and Gambling")
            )
        stationLando.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { shield = { quantity = 5, cost = 90 } },
            trade = { food = false, medicine = false, luxury = false },
        }
        local stationGoodChoice = math.random(1, 3)
        if stationGoodChoice == 1 then
            stationLando.comms_data.goods.luxury =
                { quantity = 5, cost = math.random(68, 81) }
        elseif stationGoodChoice == 2 then
            stationLando.comms_data.goods.gold =
                { quantity = 5, cost = math.random(61, 77) }
        else
            stationLando.comms_data.goods.platinum =
                { quantity = 5, cost = math.random(65, 79) }
        end
        return stationLando
    end
    function api.placeKomov()
        --Komov
        stationKomov = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationKomov:setPosition(psx, psy):setCallSign("Komov"):setDescription(
            _("scienceDescription-station", "Xenopsychology training")
        )
        stationKomov.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { filament = { quantity = 5, cost = 46 } },
            trade = { food = false, medicine = false, luxury = false },
            public_relations = true,
            general_information = _(
                "stationGeneralInfo-comms",
                "We provide classes and simulation to help train diverse species in how to relate to each other"
            ),
            history = _(
                "stationStory-comms",
                "A continuation of the research initially conducted by Dr. Gennady Komov in the early 22nd century on Venus, supported by the application of these principles"
            ),
        }
        if stationFaction == "Human Navy" then
            stationKomov.comms_data.goods.food =
                { quantity = math.random(5, 10), cost = 1 }
            if random(1, 5) <= 1 then
                stationKomov.comms_data.goods.medicine =
                    { quantity = 5, cost = 5 }
            else
                stationKomov.comms_data.trade.medicine = random(1, 100) < 44
            end
        else
            stationKomov.comms_data.trade.medicine = random(1, 100) < 44
            stationKomov.comms_data.trade.food = random(1, 100) < 24
        end
        return stationKomov
    end
    function api.placeScience2()
        --Science 2
        stationScience2 = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationScience2
            :setPosition(psx, psy)
            :setCallSign("Science-2")
            :setDescription(
                _("scienceDescription-station", "Research Lab and Observatory")
            )
        stationScience2.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = {},
            trade = { food = false, medicine = false, luxury = false },
        }
        local stationGoodChoice = math.random(1, 3)
        if stationGoodChoice == 1 then
            stationScience2.comms_data.goods.autodoc =
                { quantity = 5, cost = math.random(85, 94) }
        elseif stationGoodChoice == 2 then
            stationScience2.comms_data.goods.android =
                { quantity = 5, cost = math.random(62, 75) }
        else
            stationScience2.comms_data.goods.nanites =
                { quantity = 5, cost = math.random(55, 89) }
        end
        return stationScience2
    end
    function api.placePrefect()
        --Prefect
        stationPrefect = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationPrefect
            :setPosition(psx, psy)
            :setCallSign("Prefect")
            :setDescription(
                _("scienceDescription-station", "Textiles and fashion")
            )
        stationPrefect.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { luxury = { quantity = 5, cost = 45 } },
            trade = { food = false, medicine = false, luxury = false },
        }
        local stationGoodChoice = math.random(1, 3)
        if stationGoodChoice == 1 then
            stationPrefect.comms_data.goods.luxury =
                { quantity = 5, cost = math.random(69, 75) }
        elseif stationGoodChoice == 2 then
            stationPrefect.comms_data.goods.cobalt =
                { quantity = 5, cost = math.random(55, 67) }
        else
            stationPrefect.comms_data.goods.dilithium =
                { quantity = 5, cost = math.random(61, 69) }
        end
        return stationPrefect
    end
    function api.placeOutpost7()
        --Outpost 7
        stationOutpost7 = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationOutpost7
            :setPosition(psx, psy)
            :setCallSign("Outpost-7")
            :setDescription(_("scienceDescription-station", "Resupply"))
        stationOutpost7.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { luxury = { quantity = 5, cost = 80 } },
            trade = { food = false, medicine = false, luxury = false },
        }
        return stationOutpost7
    end
    function api.placeOrgana()
        --Organa
        stationOrgana = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationOrgana
            :setPosition(psx, psy)
            :setCallSign("Organa")
            :setDescription(
                _("scienceDescription-station", "Diplomatic training")
            )
        stationOrgana.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { luxury = { quantity = 5, cost = 96 } },
            trade = { food = false, medicine = false, luxury = false },
            public_relations = true,
            general_information = _(
                "stationGeneralInfo-comms",
                "The premeire academy for leadership and diplomacy training in the region"
            ),
            history = _(
                "stationStory-comms",
                "Established by the royal family so critical during the political upheaval era"
            ),
        }
        return stationOrgana
    end
    function api.placeKrak()
        --Krak
        stationKrak = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationKrak
            :setPosition(psx, psy)
            :setCallSign("Krak")
            :setDescription(_("scienceDescription-station", "Mining station"))
        stationKrak.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { nickel = { quantity = 5, cost = 20 } },
            trade = {
                food = random(1, 100) < 50,
                medicine = true,
                luxury = random(1, 100) < 50,
            },
            buy = { [randomComponent()] = math.random(40, 200) },
        }
        local posAxisKrak = random(0, 360)
        local posKrak = random(10000, 60000)
        local negKrak = random(10000, 60000)
        local spreadKrak = random(4000, 7000)
        local negAxisKrak = posAxisKrak + 180
        local xPosAngleKrak, yPosAngleKrak =
            vectorFromAngle(posAxisKrak, posKrak)
        local posKrakEnd = random(30, 70)
        createRandomAsteroidAlongArc(
            30 + posKrakEnd,
            psx + xPosAngleKrak,
            psy + yPosAngleKrak,
            posKrak,
            negAxisKrak,
            negAxisKrak + posKrakEnd,
            spreadKrak
        )
        local xNegAngleKrak, yNegAngleKrak =
            vectorFromAngle(negAxisKrak, negKrak)
        local negKrakEnd = random(40, 80)
        createRandomAsteroidAlongArc(
            30 + negKrakEnd,
            psx + xNegAngleKrak,
            psy + yNegAngleKrak,
            negKrak,
            posAxisKrak,
            posAxisKrak + negKrakEnd,
            spreadKrak
        )
        local krakGoods = random(1, 100)
        if krakGoods < 10 then
            stationKrak.comms_data.goods.platinum = { quantity = 5, cost = 70 }
            stationKrak.comms_data.goods.tritanium = { quantity = 5, cost = 50 }
            stationKrak.comms_data.goods.dilithium = { quantity = 5, cost = 52 }
        elseif krakGoods < 20 then
            stationKrak.comms_data.goods.platinum = { quantity = 5, cost = 70 }
            stationKrak.comms_data.goods.tritanium = { quantity = 5, cost = 50 }
        elseif krakGoods < 30 then
            stationKrak.comms_data.goods.platinum = { quantity = 5, cost = 70 }
            stationKrak.comms_data.goods.dilithium = { quantity = 5, cost = 52 }
        elseif krakGoods < 40 then
            stationKrak.comms_data.goods.tritanium = { quantity = 5, cost = 50 }
            stationKrak.comms_data.goods.dilithium = { quantity = 5, cost = 52 }
        elseif krakGoods < 50 then
            stationKrak.comms_data.goods.dilithium = { quantity = 5, cost = 52 }
        elseif krakGoods < 60 then
            stationKrak.comms_data.goods.platinum = { quantity = 5, cost = 70 }
        elseif krakGoods < 70 then
            stationKrak.comms_data.goods.tritanium = { quantity = 5, cost = 50 }
        elseif krakGoods < 80 then
            stationKrak.comms_data.goods.gold = { quantity = 5, cost = 50 }
            stationKrak.comms_data.goods.tritanium = { quantity = 5, cost = 50 }
        elseif krakGoods < 90 then
            stationKrak.comms_data.goods.gold = { quantity = 5, cost = 50 }
            stationKrak.comms_data.goods.dilithium = { quantity = 5, cost = 52 }
        else
            stationKrak.comms_data.goods.gold = { quantity = 5, cost = 50 }
        end
        return stationKrak
    end
    function api.placeGrap()
        --Grap
        stationGrap = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationGrap
            :setPosition(psx, psy)
            :setCallSign("Grap")
            :setDescription(_("scienceDescription-station", "Mining station"))
        stationGrap.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { nickel = { quantity = 5, cost = 20 } },
            trade = {
                food = random(1, 100) < 50,
                medicine = true,
                luxury = random(1, 100) < 50,
            },
            buy = { [randomComponent()] = math.random(40, 200) },
        }
        local posAxisGrap = random(0, 360)
        local posGrap = random(10000, 60000)
        local negGrap = random(10000, 60000)
        local spreadGrap = random(4000, 7000)
        local negAxisGrap = posAxisGrap + 180
        local xPosAngleGrap, yPosAngleGrap =
            vectorFromAngle(posAxisGrap, posGrap)
        local posGrapEnd = random(30, 70)
        createRandomAsteroidAlongArc(
            30 + posGrapEnd,
            psx + xPosAngleGrap,
            psy + yPosAngleGrap,
            posGrap,
            negAxisGrap,
            negAxisGrap + posGrapEnd,
            spreadGrap
        )
        local xNegAngleGrap, yNegAngleGrap =
            vectorFromAngle(negAxisGrap, negGrap)
        local negGrapEnd = random(40, 80)
        createRandomAsteroidAlongArc(
            30 + negGrapEnd,
            psx + xNegAngleGrap,
            psy + yNegAngleGrap,
            negGrap,
            posAxisGrap,
            posAxisGrap + negGrapEnd,
            spreadGrap
        )
        local grapGoods = random(1, 100)
        if grapGoods < 10 then
            stationGrap.comms_data.goods.platinum = { quantity = 5, cost = 70 }
            stationGrap.comms_data.goods.tritanium = { quantity = 5, cost = 50 }
            stationGrap.comms_data.goods.dilithium = { quantity = 5, cost = 52 }
        elseif grapGoods < 20 then
            stationGrap.comms_data.goods.platinum = { quantity = 5, cost = 70 }
            stationGrap.comms_data.goods.tritanium = { quantity = 5, cost = 50 }
        elseif grapGoods < 30 then
            stationGrap.comms_data.goods.platinum = { quantity = 5, cost = 70 }
            stationGrap.comms_data.goods.dilithium = { quantity = 5, cost = 52 }
        elseif grapGoods < 40 then
            stationGrap.comms_data.goods.tritanium = { quantity = 5, cost = 50 }
            stationGrap.comms_data.goods.dilithium = { quantity = 5, cost = 52 }
        elseif grapGoods < 50 then
            stationGrap.comms_data.goods.dilithium = { quantity = 5, cost = 52 }
        elseif grapGoods < 60 then
            stationGrap.comms_data.goods.platinum = { quantity = 5, cost = 70 }
        elseif grapGoods < 70 then
            stationGrap.comms_data.goods.tritanium = { quantity = 5, cost = 50 }
        elseif grapGoods < 80 then
            stationGrap.comms_data.goods.gold = { quantity = 5, cost = 50 }
            stationGrap.comms_data.goods.tritanium = { quantity = 5, cost = 50 }
        elseif grapGoods < 90 then
            stationGrap.comms_data.goods.gold = { quantity = 5, cost = 50 }
            stationGrap.comms_data.goods.dilithium = { quantity = 5, cost = 52 }
        else
            stationGrap.comms_data.goods.gold = { quantity = 5, cost = 50 }
        end
        return stationGrap
    end
    function api.placeKruk()
        --Kruk
        stationKruk = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationKruk
            :setPosition(psx, psy)
            :setCallSign("Kruk")
            :setDescription(_("scienceDescription-station", "Mining station"))
        stationKruk.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { nickel = { quantity = 5, cost = math.random(25, 35) } },
            trade = {
                food = random(1, 100) < 50,
                medicine = random(1, 100) < 50,
                luxury = true,
            },
            buy = { [randomComponent()] = math.random(40, 200) },
        }
        local posAxisKruk = random(0, 360)
        local posKruk = random(10000, 60000)
        local negKruk = random(10000, 60000)
        local spreadKruk = random(4000, 7000)
        local negAxisKruk = posAxisKruk + 180
        local xPosAngleKruk, yPosAngleKruk =
            vectorFromAngle(posAxisKruk, posKruk)
        local posKrukEnd = random(30, 70)
        createRandomAsteroidAlongArc(
            30 + posKrukEnd,
            psx + xPosAngleKruk,
            psy + yPosAngleKruk,
            posKruk,
            negAxisKruk,
            negAxisKruk + posKrukEnd,
            spreadKruk
        )
        local xNegAngleKruk, yNegAngleKruk =
            vectorFromAngle(negAxisKruk, negKruk)
        local negKrukEnd = random(40, 80)
        createRandomAsteroidAlongArc(
            30 + negKrukEnd,
            psx + xNegAngleKruk,
            psy + yNegAngleKruk,
            negKruk,
            posAxisKruk,
            posAxisKruk + negKrukEnd,
            spreadKruk
        )
        local krukGoods = random(1, 100)
        if krukGoods < 10 then
            stationKruk.comms_data.goods.platinum =
                { quantity = 5, cost = math.random(65, 75) }
            stationKruk.comms_data.goods.tritanium =
                { quantity = 5, cost = math.random(45, 55) }
            stationKruk.comms_data.goods.dilithium =
                { quantity = 5, cost = math.random(45, 55) }
        elseif krukGoods < 20 then
            stationKruk.comms_data.goods.platinum =
                { quantity = 5, cost = math.random(65, 75) }
            stationKruk.comms_data.goods.tritanium =
                { quantity = 5, cost = math.random(45, 55) }
        elseif krukGoods < 30 then
            stationKruk.comms_data.goods.platinum =
                { quantity = 5, cost = math.random(65, 75) }
            stationKruk.comms_data.goods.dilithium =
                { quantity = 5, cost = math.random(45, 55) }
        elseif krukGoods < 40 then
            stationKruk.comms_data.goods.tritanium =
                { quantity = 5, cost = math.random(45, 55) }
            stationKruk.comms_data.goods.dilithium =
                { quantity = 5, cost = math.random(45, 55) }
        elseif krukGoods < 50 then
            stationKruk.comms_data.goods.dilithium =
                { quantity = 5, cost = math.random(45, 55) }
        elseif krukGoods < 60 then
            stationKruk.comms_data.goods.platinum =
                { quantity = 5, cost = math.random(65, 75) }
        elseif krukGoods < 70 then
            stationKruk.comms_data.goods.tritanium =
                { quantity = 5, cost = math.random(45, 55) }
        elseif krukGoods < 80 then
            stationKruk.comms_data.goods.gold =
                { quantity = 5, cost = math.random(45, 55) }
            stationKruk.comms_data.goods.tritanium =
                { quantity = 5, cost = math.random(45, 55) }
        elseif krukGoods < 90 then
            stationKruk.comms_data.goods.gold =
                { quantity = 5, cost = math.random(45, 55) }
            stationKruk.comms_data.goods.dilithium =
                { quantity = 5, cost = math.random(45, 55) }
        else
            stationKruk.comms_data.goods.gold =
                { quantity = 5, cost = math.random(45, 55) }
        end
        return stationKruk
    end
    function api.placeGrup()
        --Grup
        stationGrup = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationGrup
            :setPosition(psx, psy)
            :setCallSign("Grup")
            :setDescription(_("scienceDescription-station", "Mining station"))
        stationGrup.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { nickel = { quantity = 5, cost = math.random(25, 35) } },
            trade = {
                food = random(1, 100) < 50,
                medicine = random(1, 100) < 50,
                luxury = true,
            },
            buy = { [randomComponent()] = math.random(40, 200) },
        }
        local posAxisGrup = random(0, 360)
        local posGrup = random(30000, 60000)
        local negGrup = random(10000, 30000)
        local spreadGrup = random(5000, 8000)
        local negAxisGrup = posAxisGrup + 180
        local xPosAngleGrup, yPosAngleGrup =
            vectorFromAngle(posAxisGrup, posGrup)
        local posGrupEnd = random(30, 70)
        createRandomAsteroidAlongArc(
            30 + posGrupEnd,
            psx + xPosAngleGrup,
            psy + yPosAngleGrup,
            posGrup,
            negAxisGrup,
            negAxisGrup + posGrupEnd,
            spreadGrup
        )
        local xNegAngleGrup, yNegAngleGrup =
            vectorFromAngle(negAxisGrup, negGrup)
        local negGrupEnd = random(40, 80)
        createRandomAsteroidAlongArc(
            30 + negGrupEnd,
            psx + xNegAngleGrup,
            psy + yNegAngleGrup,
            negGrup,
            posAxisGrup,
            posAxisGrup + negGrupEnd,
            spreadGrup
        )
        local grupGoods = random(1, 100)
        if grupGoods < 10 then
            stationGrup.comms_data.goods.platinum =
                { quantity = 5, cost = math.random(65, 75) }
            stationGrup.comms_data.goods.tritanium =
                { quantity = 5, cost = math.random(45, 55) }
            stationGrup.comms_data.goods.dilithium =
                { quantity = 5, cost = math.random(45, 55) }
        elseif grupGoods < 20 then
            stationGrup.comms_data.goods.platinum =
                { quantity = 5, cost = math.random(65, 75) }
            stationGrup.comms_data.goods.tritanium =
                { quantity = 5, cost = math.random(45, 55) }
        elseif grupGoods < 30 then
            stationGrup.comms_data.goods.platinum =
                { quantity = 5, cost = math.random(65, 75) }
            stationGrup.comms_data.goods.dilithium =
                { quantity = 5, cost = math.random(45, 55) }
        elseif grupGoods < 40 then
            stationGrup.comms_data.goods.tritanium =
                { quantity = 5, cost = math.random(45, 55) }
            stationGrup.comms_data.goods.dilithium =
                { quantity = 5, cost = math.random(45, 55) }
        elseif grupGoods < 50 then
            stationGrup.comms_data.goods.dilithium =
                { quantity = 5, cost = math.random(45, 55) }
        elseif grupGoods < 60 then
            stationGrup.comms_data.goods.platinum =
                { quantity = 5, cost = math.random(65, 75) }
        elseif grupGoods < 70 then
            stationGrup.comms_data.goods.tritanium =
                { quantity = 5, cost = math.random(45, 55) }
        elseif grupGoods < 80 then
            stationGrup.comms_data.goods.gold =
                { quantity = 5, cost = math.random(45, 55) }
            stationGrup.comms_data.goods.tritanium =
                { quantity = 5, cost = math.random(45, 55) }
        elseif grupGoods < 90 then
            stationGrup.comms_data.goods.gold =
                { quantity = 5, cost = math.random(45, 55) }
            stationGrup.comms_data.goods.dilithium =
                { quantity = 5, cost = math.random(45, 55) }
        else
            stationGrup.comms_data.goods.gold =
                { quantity = 5, cost = math.random(45, 55) }
        end
        return stationGrup
    end

    function api.placeOutpost8()
        --Outpost 8
        stationOutpost8 = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationOutpost8:setPosition(psx, psy):setCallSign("Outpost-8")
        stationOutpost8.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = {},
            trade = { food = false, medicine = false, luxury = false },
        }
        local stationGoodChoice = math.random(1, 3)
        if stationGoodChoice == 1 then
            stationOutpost8.comms_data.goods.impulse =
                { quantity = 5, cost = math.random(69, 75) }
        elseif stationGoodChoice == 2 then
            stationOutpost8.comms_data.goods.tractor =
                { quantity = 5, cost = math.random(55, 67) }
        else
            stationOutpost8.comms_data.goods.beam =
                { quantity = 5, cost = math.random(61, 69) }
        end
        return stationOutpost8
    end
    function api.placeScience7()
        --Science 7
        stationScience7 = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationScience7
            :setPosition(psx, psy)
            :setCallSign("Science-7")
            :setDescription(_("scienceDescription-station", "Observatory"))
        stationScience7.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { food = { quantity = 2, cost = 1 } },
            trade = { food = false, medicine = false, luxury = false },
        }
        return stationScience7
    end
    function api.placeCyrus()
        --Cyrus
        stationCyrus = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationCyrus:setPosition(psx, psy):setCallSign("Cyrus"):setDescription(
            _("scienceDescription-station", "Impulse engine components")
        )
        stationCyrus.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { impulse = { quantity = 5, cost = 124 } },
            trade = {
                food = false,
                medicine = false,
                luxury = random(1, 100) < 78,
            },
            public_relations = true,
            general_information = _(
                "stationGeneralInfo-comms",
                "We supply high quality impulse engines and parts for use aboard ships"
            ),
            history = _(
                "stationStory-comms",
                "This station was named after the fictional engineer, Cyrus Smith created by 19th century author Jules Verne"
            ),
        }
        if stationFaction == "Human Navy" then
            stationCyrus.comms_data.goods.food =
                { quantity = math.random(5, 10), cost = 1 }
            if random(1, 5) <= 1 then
                stationCyrus.comms_data.goods.medicine =
                    { quantity = 5, cost = 5 }
            else
                stationCyrus.comms_data.trade.medicine = random(1, 100) < 34
            end
        else
            stationCyrus.comms_data.trade.medicine = random(1, 100) < 34
            stationCyrus.comms_data.trade.food = random(1, 100) < 13
        end
        return stationCyrus
    end
    function api.placeCalvin()
        --Calvin
        stationCalvin = SpaceStation()
            :setTemplate(szt())
            :setFaction(stationFaction)
            :setCommsScript("")
            :setCommsFunction(commsStation)
        stationCalvin
            :setPosition(psx, psy)
            :setCallSign("Calvin")
            :setDescription(_("scienceDescription-station", "Robotic research"))
        stationCalvin.comms_data = {
            friendlyness = random(0, 100),
            weapons = {
                Homing = "neutral",
                HVLI = "neutral",
                Mine = "neutral",
                Nuke = "friend",
                EMP = "friend",
            },
            weapon_available = {
                Homing = random(1, 10) <= (8 - difficulty),
                HVLI = random(1, 10) <= (9 - difficulty),
                Mine = random(1, 10) <= (7 - difficulty),
                Nuke = random(1, 10) <= (5 - difficulty),
                EMP = random(1, 10) <= (6 - difficulty),
            },
            service_cost = {
                supplydrop = math.random(80, 120),
                reinforcements = math.random(125, 175),
            },
            reputation_cost_multipliers = { friend = 1.0, neutral = 3.0 },
            max_weapon_refill_amount = { friend = 1.0, neutral = 0.5 },
            goods = { robotic = { quantity = 5, cost = 90 } },
            trade = { food = false, medicine = false, luxury = true },
            buy = { [randomComponent("robotic")] = math.random(40, 200) },
            public_relations = true,
            general_information = _(
                "stationGeneralInfo-comms",
                "We research and provide robotic systems and components"
            ),
            history = _(
                "stationStory-comms",
                "This station is named after Dr. Susan Calvin who pioneered robotic behavioral research and programming"
            ),
        }
        if stationFaction == "Human Navy" then
            stationCalvin.comms_data.goods.food =
                { quantity = math.random(5, 10), cost = 1 }
            if random(1, 5) <= 1 then
                stationCalvin.comms_data.goods.medicine =
                    { quantity = 5, cost = 5 }
            end
        else
            stationCalvin.comms_data.trade.food = random(1, 100) < 8
        end
        return stationCalvin
    end
    --enemy stations
    function api.placeGandala()
        --Gandala
        stationGanalda =
            SpaceStation():setTemplate(szt()):setFaction(stationFaction)
        stationGanalda:setPosition(psx, psy):setCallSign("Ganalda")
        return stationGanalda
    end
    function api.placeEmpok()
        --Empok Nor
        stationEmpok =
            SpaceStation():setTemplate(szt()):setFaction(stationFaction)
        stationEmpok:setPosition(psx, psy):setCallSign("Empok Nor")
        return stationEmpok
    end
    function api.placeTic()
        --Ticonderoga
        stationTic =
            SpaceStation():setTemplate(szt()):setFaction(stationFaction)
        stationTic:setPosition(psx, psy):setCallSign("Ticonderoga")
        return stationTic
    end
    function api.pickStation(name)
        if station_pool == nil then
            local pool, priority = catalog.build()
            station_pool = pool
            station_priority = priority
        end
        return pickStation(name, nil, nil, { set_template = false })
    end

    function api.placeBaseStation(x, y, name, faction, size)
        --x and y are the position of the station
        --name should be the name of the station or the name of the station group
        --    omit name to get random station from groups in priority order
        --faction is the faction of the station
        --    omit and stationFaction will be used
        --size is the name of the station template to use
        --    omit and station template will be chosen at random via szt function
        if x == nil then
            return nil
        end
        if y == nil then
            return nil
        end
        local group, station = api.pickStation(name)
        if group == nil then
            return nil
        end
        station:setPosition(x, y)
        if faction ~= nil then
            station:setFaction(faction)
        else
            if stationFaction ~= nil then
                station:setFaction(stationFaction)
            else
                station:setFaction("Independent")
            end
        end
        if size == nil then
            station:setTemplate(szt())
        else
            local function Set(list)
                local set = {}
                for _, item in ipairs(list) do
                    set[item] = true
                end
                return set
            end
            local station_size_templates = Set({
                "Small Station",
                "Medium Station",
                "Large Station",
                "Huge Station",
            })
            if station_size_templates[size] then
                station:setTemplate(size)
            else
                station:setTemplate(szt())
            end
        end
        local size_matters = 0
        local station_size = station:getTypeName()
        if station_size == "Medium Station" then
            size_matters = 20
        elseif station_size == "Large Station" then
            size_matters = 30
        elseif station_size == "Huge Station" then
            size_matters = 40
        end
        local faction_matters = 0
        if station:getFaction() == "Human Navy" then
            faction_matters = 20
        end
        station.comms_data.system_repair = {}
        station.comms_data.coolant_pump_repair = {}
        for _, system in ipairs(system_list) do
            local chance = 60 + size_matters
            local eval = random(1, 100)
            station.comms_data.system_repair[system] = eval <= chance
            eval = random(1, 100)
            station.comms_data.coolant_pump_repair[system] = eval <= chance
        end
        station.comms_data.probe_launch_repair = random(1, 100)
            <= (20 + size_matters + faction_matters)
        station.comms_data.scan_repair = random(1, 100)
            <= (30 + size_matters + faction_matters)
        station.comms_data.hack_repair = random(1, 100)
            <= (10 + size_matters + faction_matters)
        station.comms_data.combat_maneuver_repair = random(1, 100)
            <= (15 + size_matters + faction_matters)
        station.comms_data.self_destruct_repair = random(1, 100)
            <= (25 + size_matters + faction_matters)
        station.comms_data.jump_overcharge = random(1, 100)
            <= (5 + size_matters + faction_matters)
        station:setSharesEnergyWithDocked(
            random(1, 100) <= (50 + size_matters + faction_matters)
        )
        station:setRepairDocked(
            random(1, 100) <= (55 + size_matters + faction_matters)
        )
        station:setRestocksScanProbes(
            random(1, 100) <= (45 + size_matters + faction_matters)
        )
        return station
    end

    function api.placeStation(x, y, name, faction, size)
        return placeConfiguredStation(x, y, name, faction, size, {
            place_station = api.placeBaseStation,
            configure_service_chances = false,
            reset_system_repairs = false,
            asteroids_around_point = options.asteroids_around_point,
            asteroid_arc = options.asteroid_arc,
        })
    end

    function api.setStationsFromList()
        if patrol_plot_diagnostic then
            print("Patrol plot diagnostic. Set stations from list")
        end
        defensive_station_list = {}
        local faction_list =
            { "TSN", "CUF", "USN", "Arlenians", "Ghosts", "Exuari", "Ktlitans" }
        local tsn_names = { "Asimov", "Armstrong", "Broeck" }
        local usn_names = { "Coulomb", "Heyes", "Archimedes" }
        local cuf_names = { "Nexus-6", "Hossam", "Shawyer" }
        local arlenian_names = { "Skandar", "Tokra", "Impala" }
        local ghost_names = { "Okun", "Rubis", "Aramanth" }
        local exuari_names = { "Hassenstadt", "Kaldor", "Stahlstadt" }
        local ktlitan_names = { "R'lyeh", "Magenta Mesra", "Questa Verde" }
        local faction_name = {
            ["TSN"] = tsn_names,
            ["CUF"] = cuf_names,
            ["USN"] = usn_names,
            ["Arlenians"] = arlenian_names,
            ["Ghosts"] = ghost_names,
            ["Exuari"] = exuari_names,
            ["Ktlitans"] = ktlitan_names,
        }
        -- for name, list in pairs(faction_name) do
        --     print("faction name:",name,"list:",list)
        -- end
        local o_x = 0
        local o_y = 0
        local base_area_radius = 100000
        local compression_interval = 1000
        stationSize = nil
        for i = 1, 21 do
            if #faction_list < 1 then
                faction_list = {
                    "TSN",
                    "CUF",
                    "USN",
                    "Arlenians",
                    "Ghosts",
                    "Exuari",
                    "Ktlitans",
                }
            end
            stationFaction = tableRemoveRandom(faction_list)
            -- print("station faction:",stationFaction)
            local list_station_size = szt()
            local name_list = faction_name[stationFaction]
            -- print("faction:",stationFaction,"name list:",name_list)
            -- for _, name in ipairs(name_list) do
            --     print("name:",name)
            -- end
            local station_name = tableRemoveRandom(name_list)
            -- print("Station name:",station_name)
            local area_radius = base_area_radius
            repeat
                o_x, o_y =
                    vectorFromAngle(random(0, 360), random(0, area_radius))
                area_radius = area_radius + compression_interval
            until farEnough(
                    o_x,
                    o_y,
                    station_defend_dist[list_station_size] * 2
                )
            local pStation = api.placeStation(
                o_x,
                o_y,
                station_name,
                stationFaction,
                list_station_size
            )
            table.insert(place_space, {
                obj = pStation,
                dist = station_defend_dist[pStation:getTypeName()] * 2,
                shape = "circle",
            })
            table.insert(defensive_station_list, pStation)
            table.insert(transport_station_list, pStation)
        end
        resetPatrolDelay()
        patrolPlot = addPatrol
        patrol_group = {}
        patrol_depleted = {}
    end
    function api.setStations()
        local afd = 30 -- asteroid field density
        stationList = {}
        transport_station_list = {}
        place_space = {}
        station_dist = {
            [ST.SMALL_STATION] = 300,
            [ST.MEDIUM_STATION] = 1000,
            [ST.LARGE_STATION] = 1300,
            [ST.HUGE_STATION] = 1500,
        }
        station_defend_dist = {
            [ST.SMALL_STATION] = 2800,
            [ST.MEDIUM_STATION] = 4200,
            [ST.LARGE_STATION] = 4800,
            [ST.HUGE_STATION] = 5200,
        }
        totalStations = 0
        friendlyStations = 0
        neutralStations = 0
        stationFaction = "Human Navy"
        if difficulty < 1 then
            stationSize = "Huge Station"
        elseif difficulty > 1 then
            stationSize = "Medium Station"
        else
            stationSize = "Large Station"
        end
        psx = random(-10000, 5000)
        psy = random(5000, 9000)
        api.placeVaiken()
        table.insert(place_space, {
            obj = stationVaiken,
            dist = station_defend_dist[stationVaiken:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationVaiken)
        table.insert(transport_station_list, stationVaiken)
        friendlyStations = friendlyStations + 1
        stationSize = "Medium Station"
        psx = random(5000, 8000)
        psy = random(-8000, 9000)
        api.placeZefram()
        table.insert(place_space, {
            obj = stationZefram,
            dist = station_defend_dist[stationZefram:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationZefram)
        friendlyStations = friendlyStations + 1
        local marconiAngle = random(0, 360)
        stationFaction = "Independent"
        stationSize = "Small Station"
        psx, psy = vectorFromAngle(marconiAngle, random(12500, 15000))
        api.placeMarconi()
        table.insert(place_space, {
            obj = stationMarconi,
            dist = station_dist[stationMarconi:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationMarconi)
        table.insert(transport_station_list, stationMarconi)
        neutralStations = neutralStations + 1
        local muddAngle = marconiAngle + random(60, 180)
        stationSize = "Medium Station"
        psx, psy = vectorFromAngle(muddAngle, random(12500, 15000))
        api.placeMuddville()
        table.insert(place_space, {
            obj = stationMudd,
            dist = station_dist[stationMudd:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationMudd)
        table.insert(transport_station_list, stationMudd)
        neutralStations = neutralStations + 1
        local alcaleicaAngle = muddAngle + random(60, 120)
        stationSize = "Small Station"
        psx, psy = vectorFromAngle(alcaleicaAngle, random(12500, 15000))
        api.placeAlcaleica()
        table.insert(place_space, {
            obj = stationAlcaleica,
            dist = station_dist[stationAlcaleica:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationAlcaleica)
        table.insert(transport_station_list, stationAlcaleica)
        neutralStations = neutralStations + 1
        stationFaction = "Human Navy"
        psx = random(-90000, -70000)
        psy = random(-15000, 25000)
        api.placeCalifornia()
        table.insert(place_space, {
            obj = stationCalifornia,
            dist = station_dist[stationCalifornia:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationCalifornia)
        table.insert(transport_station_list, stationCalifornia)
        friendlyStations = friendlyStations + 1
        stationFaction = "Independent"
        psx = random(35000, 50000)
        psy = random(52000, 79000)
        api.placeOutpost15()
        table.insert(place_space, {
            obj = stationOutpost15,
            dist = station_dist[stationOutpost15:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationOutpost15)
        table.insert(transport_station_list, stationOutpost15)
        neutralStations = neutralStations + 1
        placeRandomAroundPoint(Asteroid, 25, 1, 15000, 60000, 75000)
        psx = random(50000, 75000)
        psy = random(52000, 61250)
        api.placeOutpost21()
        table.insert(place_space, {
            obj = stationOutpost21,
            dist = station_dist[stationOutpost21:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationOutpost21)
        table.insert(transport_station_list, stationOutpost21)
        neutralStations = neutralStations + 1
        if
            stationOutpost15.comms_data.goods.gold == nil
            and stationOutpost21.comms_data.goods.gold == nil
        then
            if random(1, 100) < 50 then
                stationOutpost21.comms_data.goods.gold =
                    { quantity = 5, cost = math.random(22, 30) }
            else
                stationOutpost15.comms_data.goods.gold =
                    { quantity = 5, cost = math.random(22, 30) }
            end
        end
        if
            stationOutpost15.comms_data.goods.cobalt == nil
            and stationOutpost21.comms_data.goods.cobalt == nil
        then
            if random(1, 100) < 50 then
                stationOutpost21.comms_data.goods.cobalt =
                    { quantity = 4, cost = math.random(45, 55) }
            else
                stationOutpost15.comms_data.goods.cobalt =
                    { quantity = 4, cost = math.random(45, 55) }
            end
        end
        psx = random(-88000, -65000)
        psy = random(36250, 40000)
        api.placeValero()
        table.insert(place_space, {
            obj = stationValero,
            dist = station_dist[stationValero:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationValero)
        table.insert(transport_station_list, stationValero)
        neutralStations = neutralStations + 1
        local vactelAngle = random(0, 360)
        psx, psy = vectorFromAngle(vactelAngle, random(50000, 61250))
        api.placeVactel()
        table.insert(place_space, {
            obj = stationVactel,
            dist = station_dist[stationVactel:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationVactel)
        table.insert(transport_station_list, stationVactel)
        neutralStations = neutralStations + 1
        local archerAngle = vactelAngle + random(60, 120)
        psx, psy = vectorFromAngle(archerAngle, random(50000, 61250))
        api.placeArcher()
        table.insert(place_space, {
            obj = stationArcher,
            dist = station_dist[stationArcher:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationArcher)
        table.insert(transport_station_list, stationArcher)
        neutralStations = neutralStations + 1
        local deerAngle = archerAngle + random(60, 120)
        psx, psy = vectorFromAngle(deerAngle, random(50000, 61250))
        api.placeDeer()
        table.insert(place_space, {
            obj = stationDeer,
            dist = station_dist[stationDeer:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationDeer)
        table.insert(transport_station_list, stationDeer)
        neutralStations = neutralStations + 1
        local cavorAngle = deerAngle + random(60, 90)
        psx, psy = vectorFromAngle(cavorAngle, random(50000, 61250))
        api.placeCavor()
        table.insert(place_space, {
            obj = stationCavor,
            dist = station_dist[stationCavor:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationCavor)
        table.insert(transport_station_list, stationCavor)
        neutralStations = neutralStations + 1
        stationFaction = "Human Navy"
        psx = random(72000, 85000)
        psy = random(-50000, -26000)
        api.placeEmory()
        table.insert(place_space, {
            obj = stationEmory,
            dist = station_dist[stationEmory:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationEmory)
        table.insert(transport_station_list, stationEmory)
        friendlyStations = friendlyStations + 1
        stationFaction = "Independent"
        psx = random(-25000, 15000)
        psy = random(27000, 40000)
        api.placeVeloquan()
        table.insert(place_space, {
            obj = stationVeloquan,
            dist = station_dist[stationVeloquan:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationVeloquan)
        table.insert(transport_station_list, stationVeloquan)
        neutralStations = neutralStations + 1
        psx = random(-20000, 0)
        psy = random(-45000, -25000)
        api.placeBarclay()
        table.insert(place_space, {
            obj = stationBarclay,
            dist = station_dist[stationBarclay:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationBarclay)
        table.insert(transport_station_list, stationBarclay)
        neutralStations = neutralStations + 1
        psx = random(20000, 45000)
        psy = random(-25000, -15000)
        api.placeLipkin()
        table.insert(place_space, {
            obj = stationLipkin,
            dist = station_dist[stationLipkin:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationLipkin)
        table.insert(transport_station_list, stationLipkin)
        neutralStations = neutralStations + 1
        psx = random(-75000, -30000)
        psy = random(55000, 62150)
        api.placeRipley()
        table.insert(place_space, {
            obj = stationRipley,
            dist = station_dist[stationRipley:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationRipley)
        table.insert(transport_station_list, stationRipley)
        neutralStations = neutralStations + 1
        psx = random(-45000, -25000)
        psy = random(-25000, -14000)
        api.placeDeckard()
        table.insert(place_space, {
            obj = stationDeckard,
            dist = station_dist[stationDeckard:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationDeckard)
        table.insert(transport_station_list, stationDeckard)
        neutralStations = neutralStations + 1
        psx = random(-10000, 15000)
        psy = random(15000, 27000)
        api.placeConnor()
        table.insert(place_space, {
            obj = stationConnor,
            dist = station_dist[stationConnor:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationConnor)
        table.insert(transport_station_list, stationConnor)
        neutralStations = neutralStations + 1
        psx = random(15000, 20000)
        psy = random(-25000, 48000)
        api.placeAnderson()
        table.insert(place_space, {
            obj = stationAnderson,
            dist = station_dist[stationAnderson:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationAnderson)
        table.insert(transport_station_list, stationAnderson)
        neutralStations = neutralStations + 1
        stationFaction = "Human Navy"
        psx = random(-90000, -55000)
        psy = random(25000, 36250)
        api.placeFeynman()
        table.insert(place_space, {
            obj = stationFeynman,
            dist = station_dist[stationFeynman:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationFeynman)
        table.insert(transport_station_list, stationFeynman)
        friendlyStations = friendlyStations + 1
        stationSize = "Large Station"
        psx = random(-45000, -30000)
        psy = random(-14000, 12500)
        api.placeMayo()
        table.insert(place_space, {
            obj = stationMayo,
            dist = station_dist[stationMayo:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationMayo)
        table.insert(transport_station_list, stationMayo)
        friendlyStations = friendlyStations + 1
        stationSize = "Medium Station"
        stationFaction = "Independent"
        psx = random(-10000, 12500)
        psy = random(-96000, -80000)
        api.placeNefatha()
        table.insert(place_space, {
            obj = stationNefatha,
            dist = station_dist[stationNefatha:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationNefatha)
        table.insert(transport_station_list, stationNefatha)
        neutralStations = neutralStations + 1
        psx = random(-60000, -40000)
        psy = random(47000, 55000)
        api.placeScience4()
        table.insert(place_space, {
            obj = stationScience4,
            dist = station_dist[stationScience4:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationScience4)
        table.insert(transport_station_list, stationScience4)
        neutralStations = neutralStations + 1
        stationSize = "Small Station"
        psx = random(-26000, -15000)
        psy = random(-10000, 27000)
        api.placeSpeculation4()
        table.insert(place_space, {
            obj = stationSpeculation4,
            dist = station_dist[stationSpeculation4:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationSpeculation4)
        table.insert(transport_station_list, stationSpeculation4)
        neutralStations = neutralStations + 1
        stationSize = "Medium Station"
        stationFaction = "Human Navy"
        psx = random(-30000, -26000)
        psy = random(-14000, 35000)
        api.placeTiberius()
        table.insert(place_space, {
            obj = stationTiberius,
            dist = station_dist[stationTiberius:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationTiberius)
        table.insert(transport_station_list, stationTiberius)
        friendlyStations = friendlyStations + 1
        stationSize = "Small Station"
        stationFaction = "Independent"
        psx = random(-75000, -55000)
        psy = random(-50000, -25000)
        api.placeResearch11()
        table.insert(place_space, {
            obj = stationResearch11,
            dist = station_dist[stationResearch11:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationResearch11)
        table.insert(transport_station_list, stationResearch11)
        neutralStations = neutralStations + 1
        psx = random(0, 15000)
        psy = random(-37500, -15000)
        api.placeFreena()
        table.insert(place_space, {
            obj = stationFreena,
            dist = station_dist[stationFreena:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationFreena)
        table.insert(transport_station_list, stationFreena)
        neutralStations = neutralStations + 1
        psx = random(15000, 65000)
        psy = random(-65000, -25000)
        api.placeOutpost33()
        table.insert(place_space, {
            obj = stationOutpost33,
            dist = station_dist[stationOutpost33:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationOutpost33)
        table.insert(transport_station_list, stationOutpost33)
        neutralStations = neutralStations + 1
        psx = random(-60000, -30000)
        psy = random(61250, 70000)
        api.placeLando()
        table.insert(place_space, {
            obj = stationLando,
            dist = station_dist[stationLando:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationLando)
        table.insert(transport_station_list, stationLando)
        neutralStations = neutralStations + 1
        psx = random(-55000, -30000)
        psy = random(70000, 80000)
        api.placeKomov()
        table.insert(place_space, {
            obj = stationKomov,
            dist = station_dist[stationKomov:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationKomov)
        table.insert(transport_station_list, stationKomov)
        neutralStations = neutralStations + 1
        stationSize = "Medium Station"
        psx = random(20000, 35000)
        psy = random(55000, 70000)
        api.placeScience2()
        table.insert(place_space, {
            obj = stationScience2,
            dist = station_dist[stationScience2:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationScience2)
        table.insert(transport_station_list, stationScience2)
        neutralStations = neutralStations + 1
        stationSize = "Small Station"
        psx = random(-65000, -60000)
        psy = random(36250, 55000)
        api.placePrefect()
        table.insert(place_space, {
            obj = stationPrefect,
            dist = station_dist[stationPrefect:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationPrefect)
        table.insert(stationList, stationPrefect)
        neutralStations = neutralStations + 1
        psx = random(35000, 45000)
        psy = random(-15000, 25000)
        api.placeOutpost7()
        table.insert(place_space, {
            obj = stationOutpost7,
            dist = station_dist[stationOutpost7:getTypeName()],
            shape = "circle",
        })
        table.insert(transport_station_list, stationOutpost7)
        neutralStations = neutralStations + 1
        psx = random(55000, 62000)
        psy = random(20000, 45000)
        api.placeOrgana()
        table.insert(place_space, {
            obj = stationOrgana,
            dist = station_dist[stationOrgana:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationOrgana)
        table.insert(transport_station_list, stationOrgana)
        neutralStations = neutralStations + 1
        psx = random(-60000, 15000)
        psy = random(-65000, -61250)
        api.placeGrap()
        table.insert(place_space, {
            obj = stationGrap,
            dist = station_dist[stationGrap:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationGrap)
        table.insert(transport_station_list, stationGrap)
        neutralStations = neutralStations + 1
        psx = random(-65000, -61250)
        psy = random(-25000, 25000)
        api.placeGrup()
        table.insert(place_space, {
            obj = stationGrup,
            dist = station_dist[stationGrup:getTypeName()],
            shape = "circle",
        })
        if
            stationGrap.comms_data.goods.nickel == nil
            and stationGrap.comms_data.goods.nickel == nil
        then
            if random(1, 100) < 50 then
                stationGrap.comms_data.goods.nickel =
                    { quantity = 5, cost = math.random(22, 30) }
            else
                stationGrup.comms_data.goods.nickel =
                    { quantity = 5, cost = math.random(22, 30) }
            end
        end
        if
            stationGrap.comms_data.goods.tritanium == nil
            and stationGrap.comms_data.goods.tritanium == nil
        then
            if random(1, 100) < 50 then
                stationGrap.comms_data.goods.tritanium =
                    { quantity = 5, cost = math.random(45, 60) }
            else
                stationGrup.comms_data.goods.tritanium =
                    { quantity = 5, cost = math.random(45, 60) }
            end
        end
        if
            stationGrap.comms_data.goods.dilithium == nil
            and stationGrap.comms_data.goods.dilithium == nil
        then
            if random(1, 100) < 50 then
                stationGrap.comms_data.goods.dilithium =
                    { quantity = 5, cost = math.random(45, 60) }
            else
                stationGrup.comms_data.goods.dilithium =
                    { quantity = 5, cost = math.random(45, 60) }
            end
        end
        if
            stationGrap.comms_data.goods.platinum == nil
            and stationGrap.comms_data.goods.platinum == nil
        then
            if random(1, 100) < 50 then
                stationGrap.comms_data.goods.platinum =
                    { quantity = 5, cost = math.random(65, 80) }
            else
                stationGrup.comms_data.goods.platinum =
                    { quantity = 5, cost = math.random(65, 80) }
            end
        end
        table.insert(stationList, stationGrup)
        table.insert(transport_station_list, stationGrup)
        neutralStations = neutralStations + 1
        psx = random(-65000, -40000)
        psy = random(-61250, -50000)
        api.placeOutpost8()
        table.insert(place_space, {
            obj = stationOutpost8,
            dist = station_dist[stationOutpost8:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationOutpost8)
        table.insert(transport_station_list, stationOutpost8)
        neutralStations = neutralStations + 1
        stationFaction = "Human Navy"
        psx = random(-25000, -20000)
        psy = random(-40000, -10000)
        api.placeScience7()
        table.insert(place_space, {
            obj = stationScience7,
            dist = station_dist[stationScience7:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationScience7)
        table.insert(transport_station_list, stationScience7)
        friendlyStations = friendlyStations + 1
        stationFaction = "Independent"
        psx = random(20000, 35000)
        psy = random(-15000, 40000)
        api.placeCyrus()
        table.insert(place_space, {
            obj = stationCyrus,
            dist = station_dist[stationCyrus:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationCyrus)
        table.insert(transport_station_list, stationCyrus)
        neutralStations = neutralStations + 1
        stationSize = "Medium Station"
        psx = random(40000, 86250)
        psy = random(45000, 51000)
        api.placeCalvin()
        table.insert(place_space, {
            obj = stationCalvin,
            dist = station_dist[stationCalvin:getTypeName()],
            shape = "circle",
        })
        table.insert(stationList, stationCalvin)
        table.insert(transport_station_list, stationCalvin)
        neutralStations = neutralStations + 1
        totalStations = neutralStations + friendlyStations
        originalStationList = stationList --save for statistics
        art1 = Artifact()
            :setModel("artifact4")
            :allowPickup(false)
            :setScanningParameters(2, 2)
            :setRadarSignatureInfo(
                random(0.20, 0.4),
                random(0.12, 0.2),
                random(0.13, 0.7)
            )
        art2 = Artifact()
            :setModel("artifact5")
            :allowPickup(false)
            :setScanningParameters(2, 3)
            :setRadarSignatureInfo(
                random(0.12, 0.2),
                random(0.13, 0.7),
                random(0.20, 0.4)
            )
        art3 = Artifact()
            :setModel("artifact6")
            :allowPickup(false)
            :setScanningParameters(3, 2)
            :setRadarSignatureInfo(
                random(0.13, 0.7),
                random(0.20, 0.4),
                random(0.12, 0.2)
            )
        art1:setPosition(random(-50000, 50000), random(-80000, -70000))
        art2:setPosition(random(-90000, -75000), random(-40000, -20000))
        art3:setPosition(random(50000, 75000), random(62500, 80000))
        table.insert(place_space, { obj = art1, dist = 300, shape = "circle" })
        table.insert(place_space, { obj = art2, dist = 300, shape = "circle" })
        table.insert(place_space, { obj = art3, dist = 300, shape = "circle" })
        local artChoice = math.random(6)
        if artChoice == 1 then
            art1:setDescriptions(
                _("scienceDescription-artifact", "Unusual object"),
                _(
                    "scienceDescription-artifact",
                    "Artifact with quantum biometric characteristics"
                )
            )
            art2:setDescriptions(
                _("scienceDescription-artifact", "Unusual object"),
                _(
                    "scienceDescription-artifact",
                    "Artifact with embedded chroniton particles"
                )
            )
            art3:setDescriptions(
                _("scienceDescription-artifact", "Unusual object"),
                _(
                    "scienceDescription-artifact",
                    "Artifact bridging two parallel universes"
                )
            )
            art1.quantum = true
            art2.chroniton = true
            art3.parallel = true
        elseif artChoice == 2 then
            art1:setDescriptions(
                _("scienceDescription-artifact", "Unusual object"),
                _(
                    "scienceDescription-artifact",
                    "Artifact with quantum biometric characteristics"
                )
            )
            art3:setDescriptions(
                _("scienceDescription-artifact", "Unusual object"),
                _(
                    "scienceDescription-artifact",
                    "Artifact with embedded chroniton particles"
                )
            )
            art2:setDescriptions(
                _("scienceDescription-artifact", "Unusual object"),
                _(
                    "scienceDescription-artifact",
                    "Artifact bridging two parallel universes"
                )
            )
            art1.quantum = true
            art3.chroniton = true
            art2.parallel = true
        elseif artChoice == 3 then
            art2:setDescriptions(
                _("scienceDescription-artifact", "Unusual object"),
                _(
                    "scienceDescription-artifact",
                    "Artifact with quantum biometric characteristics"
                )
            )
            art1:setDescriptions(
                _("scienceDescription-artifact", "Unusual object"),
                _(
                    "scienceDescription-artifact",
                    "Artifact with embedded chroniton particles"
                )
            )
            art3:setDescriptions(
                _("scienceDescription-artifact", "Unusual object"),
                _(
                    "scienceDescription-artifact",
                    "Artifact bridging two parallel universes"
                )
            )
            art2.quantum = true
            art1.chroniton = true
            art3.parallel = true
        elseif artChoice == 4 then
            art2:setDescriptions(
                _("scienceDescription-artifact", "Unusual object"),
                _(
                    "scienceDescription-artifact",
                    "Artifact with quantum biometric characteristics"
                )
            )
            art3:setDescriptions(
                _("scienceDescription-artifact", "Unusual object"),
                _(
                    "scienceDescription-artifact",
                    "Artifact with embedded chroniton particles"
                )
            )
            art1:setDescriptions(
                _("scienceDescription-artifact", "Unusual object"),
                _(
                    "scienceDescription-artifact",
                    "Artifact bridging two parallel universes"
                )
            )
            art2.quantum = true
            art3.chroniton = true
            art1.parallel = true
        elseif artChoice == 5 then
            art3:setDescriptions(
                _("scienceDescription-artifact", "Unusual object"),
                _(
                    "scienceDescription-artifact",
                    "Artifact with quantum biometric characteristics"
                )
            )
            art1:setDescriptions(
                _("scienceDescription-artifact", "Unusual object"),
                _(
                    "scienceDescription-artifact",
                    "Artifact with embedded chroniton particles"
                )
            )
            art2:setDescriptions(
                _("scienceDescription-artifact", "Unusual object"),
                _(
                    "scienceDescription-artifact",
                    "Artifact bridging two parallel universes"
                )
            )
            art3.quantum = true
            art1.chroniton = true
            art2.parallel = true
        else
            art3:setDescriptions(
                _("scienceDescription-artifact", "Unusual object"),
                _(
                    "scienceDescription-artifact",
                    "Artifact with quantum biometric characteristics"
                )
            )
            art2:setDescriptions(
                _("scienceDescription-artifact", "Unusual object"),
                _(
                    "scienceDescription-artifact",
                    "Artifact with embedded chroniton particles"
                )
            )
            art1:setDescriptions(
                _("scienceDescription-artifact", "Unusual object"),
                _(
                    "scienceDescription-artifact",
                    "Artifact bridging two parallel universes"
                )
            )
            art3.quantum = true
            art2.chroniton = true
            art1.parallel = true
        end
        ganaldaAngle = random(0, 360)
        stationFaction = "Kraylor"
        local gDist = random(120000, 150000)
        psx, psy = vectorFromAngle(ganaldaAngle, gDist)
        local nebula_list = {}
        table.insert(nebula_list, Nebula():setPosition(psx, psy))
        api.placeGandala()
        table.insert(place_space, {
            obj = stationGanalda,
            dist = station_dist[stationGanalda:getTypeName()],
            shape = "circle",
        })
        table.insert(transport_station_list, stationGanalda)
        local empokAngle = ganaldaAngle + random(60, 180)
        if empokAngle == nil then
            print("empokAngle is nil")
        end
        psx, psy = vectorFromAngle(empokAngle, random(120000, 150000))
        stationFaction = "Exuari"
        stationSize = "Large Station"
        api.placeEmpok()
        table.insert(place_space, {
            obj = stationEmpok,
            dist = station_dist[stationEmpok:getTypeName()],
            shape = "circle",
        })
        table.insert(transport_station_list, stationEmpok)
        ticAngle = empokAngle + random(60, 120)
        stationFaction = "Kraylor"
        stationSize = "Medium Station"
        psx, psy = vectorFromAngle(ticAngle, random(120000, 150000))
        api.placeTic()
        table.insert(place_space, {
            obj = stationTic,
            dist = station_dist[stationTic:getTypeName()],
            shape = "circle",
        })
        table.insert(transport_station_list, stationTic)
        local temp_list = options.create_random_along_arc(
            Nebula,
            15,
            100000,
            -100000,
            140000,
            100,
            170,
            25000
        )
        for i = 1, #temp_list do
            table.insert(nebula_list, temp_list[i])
        end
        temp_list = options.create_random_along_arc(
            Nebula,
            5,
            0,
            0,
            gDist,
            ganaldaAngle - 20,
            ganaldaAngle + 20,
            9000
        )
        for i = 1, #temp_list do
            table.insert(nebula_list, temp_list[i])
        end
        local nebula_index = 0
        for i = 1, #nebula_list do
            nebula_list[i].lose = false
            nebula_list[i].gain = false
        end
        coolant_nebula = {}
        local nebula_count = #nebula_list
        for i = 1, math.random(math.floor(nebula_count / 2)) do
            nebula_index = math.random(1, #nebula_list)
            table.insert(coolant_nebula, nebula_list[nebula_index])
            table.remove(nebula_list, nebula_index)
            if math.random(1, 100) < 50 then
                coolant_nebula[#coolant_nebula].lose = true
            else
                coolant_nebula[#coolant_nebula].gain = true
            end
        end
        alderaan = Planet()
            :setPosition(random(-27000, 32000), random(65500, 87500))
            :setPlanetRadius(3000)
            :setDistanceFromMovementPlane(-2000)
            :setCallSign("Alderaan")
        alderaan
            :setPlanetSurfaceTexture("planets/planet-1.png")
            :setPlanetCloudTexture("planets/clouds-1.png")
        alderaan
            :setPlanetAtmosphereTexture("planets/atmosphere.png")
            :setPlanetAtmosphereColor(0.2, 0.2, 1.0)
        alderaan:setAxialRotationTime(400.0):setDescription(
            _(
                "scienceDescription-planet",
                "Lush planet with only mild seasonal variations"
            )
        )
        table.insert(
            place_space,
            { obj = alderaan, dist = 3200, shape = "circle" }
        )
        grawp = BlackHole()
            :setPosition(random(67000, 90000), random(-21000, 40000))
            :setCallSign("Grawp")
        grawp.angle = random(0, 360)
        grawp.travel = random(1, 5)
        table.insert(place_space, {
            lo_x = 61000,
            hi_x = 96000,
            lo_y = -27000,
            hi_y = 46000,
            shape = "rectangle",
        })
        api.setStationsFromList()
    end
    return api
end

return M
