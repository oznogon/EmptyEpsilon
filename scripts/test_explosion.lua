timer = 0.0

function init()
    PlayerSpaceship():setTemplate("Atlantis X23")
    ExplosionEffect():setSize(250)
end

function update(delta)
    timer = timer + delta
    if timer > 2.0 then
        ExplosionEffect():setSize(250)
	timer = 0.0
    end
end
