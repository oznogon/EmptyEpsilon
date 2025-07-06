-- Name: Faction test
-- Description: Test factions
-- Type: Development

--- Scenario
-- @script scenario_98_factiontest

function init()
	ECS = false
	if createEntity then
		ECS = true
	end

	local factions = { "Independent", "Human Navy", "Kraylor", "Arlenians", "Exuari", "Ghosts", "Ktlitans", "TSN", "USN", "CUF" }
	local players = {}
	local cpus = {}
	local stations = {}
	local gap = 300

	for i, faction in ipairs(factions) do
		players[i] = PlayerSpaceship():setFaction(faction):setTemplate("Atlantis"):setPosition(gap * i, gap * i)
		cpus[i] = CpuShip():setFaction(faction):setTemplate("Atlantis X23"):setPosition(-gap * i, -gap * i):orderIdle()
		stations[i] = SpaceStation():setFaction(faction):setTemplate("Small Station"):setPosition(-gap * i, gap * i)
	end
end

function update(delta)
	-- No victory condition
end