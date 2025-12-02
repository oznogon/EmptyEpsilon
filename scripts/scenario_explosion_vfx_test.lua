-- Explosion Test
-- This scenario tests ExplosionEffect

-- player = PlayerSpaceship():setTemplate("Phobos M3P"):setFaction("Human Navy"):setCallSign("Demo"):setPosition(1000, 0)
time_since_explosion = 2.5
explosion_period = 2.5
explosion_index = 1

function init()
    -- Add GM functions to spawn different types of explosions
    addGMFunction("Explosion", function()
        ExplosionEffect():setPosition(1000, 0):setSize(100):setOnRadar(true)
    end)
    addGMFunction("Small Explosion", function()
        SmallExplosionEffect():setPosition(1000, 0):setSize(100):setOnRadar(true)
    end)
    addGMFunction("Elec Explosion", function()
        ElectricExplosionEffect():setPosition(1000, 0):setSize(100):setOnRadar(true)
    end)
    addGMFunction("Kin Explosion", function()
        KineticExplosionEffect():setPosition(1000, 0):setSize(100):setOnRadar(true)
    end)

end

function update(delta)
    -- Spawn VFX explosions periodically at origin
    time_since_explosion = time_since_explosion + delta
    if (time_since_explosion > explosion_period) then
        BillboardExplosion():setSize(250):setPosition(1500,0)
        if explosion_index > 4 then explosion_index = 1 end
        if explosion_index == 1 then ExplosionEffect():setPosition(0, 0):setSize(100):setOnRadar(true) end
        if explosion_index == 2 then SmallExplosionEffect():setPosition(0, 0):setSize(100):setOnRadar(true) end
        if explosion_index == 3 then ElectricExplosionEffect():setPosition(0, 0):setSize(100):setOnRadar(true) end
        if explosion_index == 4 then KineticExplosionEffect():setPosition(0, 0):setSize(100):setOnRadar(true) end
        explosion_index = explosion_index + 1
        time_since_explosion = 0
    end
end
