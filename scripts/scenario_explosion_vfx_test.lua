-- Explosion VFX Test Scenario
-- This scenario demonstrates the merged ExplosionEffect system with bitwise render modes
--
-- Render Mode Flags:
--   0x01 (1)  = Basic     - Old-style textured sphere explosion
--   0x02 (2)  = Advanced  - Volumetric shader explosion
--   0x04 (4)  = Sprite    - Animated sprite sheet explosion
--   0x08 (8)  = Particles - Debris/spark particles
--   0x10 (16) = Flash     - Flash effect (for sprite mode)

time_since_explosion = 2.5
explosion_period = 2.5
explosion_index = 1

-- Bit operations helper (Lua 5.1 doesn't have bitwise operators)
function bitOr(a, b)
    return a + b
end

function init()
    print("=== Explosion VFX Test Scenario ===")
    print("Explosions will cycle every " .. explosion_period .. " seconds")
    print("")
    print("GM Functions available to spawn different explosion types:")

    -- GM Functions for Basic Explosions
    addGMFunction("Basic: Thermal", function()
        local e = ExplosionEffect():setPosition(1000, 0):setSize(100):setOnRadar(true)
        e.components.explosion_effect.render_mode = bitOr(0x01, 0x08) -- Basic | Particles
    end)

    addGMFunction("Basic: Electric", function()
        local e = ElectricExplosionEffect():setPosition(1000, 0):setSize(100):setOnRadar(true)
        e.components.explosion_effect.render_mode = bitOr(0x01, 0x08) -- Basic | Particles
    end)

    addGMFunction("Basic: Kinetic", function()
        local e = KineticExplosionEffect():setPosition(1000, 0):setSize(100):setOnRadar(true)
        e.components.explosion_effect.render_mode = bitOr(0x01, 0x08) -- Basic | Particles
    end)

    -- GM Functions for Advanced Explosions
    addGMFunction("Advanced: Thermal", function()
        local e = ExplosionEffect():setPosition(1000, 500):setSize(100):setOnRadar(true)
        e.components.explosion_effect.render_mode = bitOr(0x02, 0x08) -- Advanced | Particles
    end)

    addGMFunction("Advanced: Electric", function()
        local e = ElectricExplosionEffect():setPosition(1000, 500):setSize(100):setOnRadar(true)
        e.components.explosion_effect.render_mode = bitOr(0x02, 0x08) -- Advanced | Particles
    end)

    addGMFunction("Advanced: Kinetic", function()
        local e = KineticExplosionEffect():setPosition(1000, 500):setSize(100):setOnRadar(true)
        e.components.explosion_effect.render_mode = bitOr(0x02, 0x08) -- Advanced | Particles
    end)

    -- GM Functions for Sprite Explosions
    addGMFunction("Sprite: Default", function()
        local e = ExplosionEffect():setPosition(1500, 0):setSize(250):setOnRadar(true)
        local comp = e.components.explosion_effect
        comp.render_mode = bitOr(0x04, 0x10) -- Sprite | Flash
        comp.sprite_texture = "texture/explosion_sprite.png"
        comp.fps = 64.0
        comp.sprite_columns = 8
        comp.sprite_rows = 8
    end)

    addGMFunction("Sprite: Slow Motion", function()
        local e = ExplosionEffect():setPosition(1500, 500):setSize(300):setOnRadar(true)
        local comp = e.components.explosion_effect
        comp.render_mode = bitOr(0x04, 0x10) -- Sprite | Flash
        comp.sprite_texture = "texture/explosion_sprite.png"
        comp.fps = 30.0
        comp.sprite_columns = 8
        comp.sprite_rows = 8
    end)

    addGMFunction("Sprite: No Flash", function()
        local e = ExplosionEffect():setPosition(1500, -500):setSize(200):setOnRadar(true)
        local comp = e.components.explosion_effect
        comp.render_mode = 0x04 -- Sprite only (no flash)
        comp.sprite_texture = "texture/explosion_sprite.png"
        comp.fps = 64.0
        comp.sprite_columns = 8
        comp.sprite_rows = 8
    end)

    -- GM Functions for Combined Effects
    addGMFunction("Combo: Basic+Sprite", function()
        local e = ExplosionEffect():setPosition(2000, 0):setSize(150):setOnRadar(true)
        local comp = e.components.explosion_effect
        comp.render_mode = bitOr(bitOr(0x01, 0x04), bitOr(0x08, 0x10)) -- Basic | Sprite | Particles | Flash
        comp.sprite_texture = "texture/explosion_sprite.png"
        comp.fps = 64.0
    end)

    addGMFunction("Combo: Advanced+Sprite", function()
        local e = ExplosionEffect():setPosition(2000, 500):setSize(150):setOnRadar(true)
        local comp = e.components.explosion_effect
        comp.render_mode = bitOr(bitOr(0x02, 0x04), bitOr(0x08, 0x10)) -- Advanced | Sprite | Particles | Flash
        comp.sprite_texture = "texture/explosion_sprite.png"
        comp.fps = 64.0
    end)

    print("All GM functions added successfully!")
end

function update(delta)
    -- Cycle through different explosion types automatically
    time_since_explosion = time_since_explosion + delta

    if (time_since_explosion > explosion_period) then
        local y_offset = -1000

        -- Row 1: Basic explosions
        if explosion_index == 1 then
            print("Spawning Basic Explosions")

            -- Basic Thermal
            local e1 = ExplosionEffect():setPosition(-500, y_offset):setSize(100):setOnRadar(true)
            e1.components.explosion_effect.render_mode = bitOr(0x01, 0x08)

            -- Basic Electric
            local e2 = ElectricExplosionEffect():setPosition(0, y_offset):setSize(100):setOnRadar(true)
            e2.components.explosion_effect.render_mode = bitOr(0x01, 0x08)

            -- Basic Kinetic
            local e3 = KineticExplosionEffect():setPosition(500, y_offset):setSize(100):setOnRadar(true)
            e3.components.explosion_effect.render_mode = bitOr(0x01, 0x08)
        end

        -- Row 2: Advanced explosions
        if explosion_index == 2 then
            print("Spawning Advanced Explosions")

            -- Advanced Thermal
            local e1 = ExplosionEffect():setPosition(-500, y_offset):setSize(100):setOnRadar(true)
            e1.components.explosion_effect.render_mode = bitOr(0x02, 0x08)

            -- Advanced Electric
            local e2 = ElectricExplosionEffect():setPosition(0, y_offset):setSize(100):setOnRadar(true)
            e2.components.explosion_effect.render_mode = bitOr(0x02, 0x08)

            -- Advanced Kinetic
            local e3 = KineticExplosionEffect():setPosition(500, y_offset):setSize(100):setOnRadar(true)
            e3.components.explosion_effect.render_mode = bitOr(0x02, 0x08)
        end

        -- Row 3: Sprite explosions
        if explosion_index == 3 then
            print("Spawning Sprite Explosions")

            -- Sprite with flash
            local e1 = ExplosionEffect():setPosition(-500, y_offset):setSize(250):setOnRadar(true)
            local comp1 = e1.components.explosion_effect
            comp1.render_mode = bitOr(0x04, 0x10)
            comp1.sprite_texture = "texture/explosion_sprite.png"
            comp1.fps = 64.0

            -- Sprite without flash
            local e2 = ExplosionEffect():setPosition(0, y_offset):setSize(250):setOnRadar(true)
            local comp2 = e2.components.explosion_effect
            comp2.render_mode = 0x04
            comp2.sprite_texture = "texture/explosion_sprite.png"
            comp2.fps = 64.0

            -- Slow sprite
            local e3 = ExplosionEffect():setPosition(500, y_offset):setSize(250):setOnRadar(true)
            local comp3 = e3.components.explosion_effect
            comp3.render_mode = bitOr(0x04, 0x10)
            comp3.sprite_texture = "texture/explosion_sprite.png"
            comp3.fps = 30.0
        end

        -- Row 4: Combined effects
        if explosion_index == 4 then
            print("Spawning Combined Effect Explosions")

            -- Basic + Sprite
            local e1 = ExplosionEffect():setPosition(-500, y_offset):setSize(150):setOnRadar(true)
            local comp1 = e1.components.explosion_effect
            comp1.render_mode = bitOr(bitOr(0x01, 0x04), bitOr(0x08, 0x10))
            comp1.sprite_texture = "texture/explosion_sprite.png"

            -- Advanced + Sprite
            local e2 = ExplosionEffect():setPosition(0, y_offset):setSize(150):setOnRadar(true)
            local comp2 = e2.components.explosion_effect
            comp2.render_mode = bitOr(bitOr(0x02, 0x04), bitOr(0x08, 0x10))
            comp2.sprite_texture = "texture/explosion_sprite.png"
        end

        explosion_index = explosion_index + 1
        if explosion_index > 4 then
            explosion_index = 1
        end
        time_since_explosion = 0
    end
end
