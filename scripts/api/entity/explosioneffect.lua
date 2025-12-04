--- An ExplosionEffect is a visual explosion used by nukes, ship destruction, and other similar events.
--- This is a cosmetic effect and does not deal damage on its own.
--- See also SmallExplosionEffect for smaller fiery explosions without impact shockwave or sparks, ElectricExplosionEffect for EMP missile effects, and KineticExplosionEffect for kinetic impacts.
--- Example: explosion = ExplosionEffect():setPosition(500,5000):setSize(20):setOnRadar(true)
function ExplosionEffect()
    local e = createEntity()
    e.components = {
        transform = {},
        explosion_effect = {size=1.0, radar=false, type="large_thermal"},
        sfx = {sound="sfx/explosion.wav"},
    }
    return e
end

--- A SmallExplosionEffect is a visual explosion used by homing missiles and other similar events.
--- Unlike ExplosionEffect, this explosion lacks an impact shockwave or sparks.
--- This is a cosmetic effect and does not deal damage on its own.
--- Example: small_explosion = SmallExplosionEffect():setPosition(500,5000):setSize(20):setOnRadar(true)
function SmallExplosionEffect()
    local e = createEntity()
    e.components = {
        transform = {},
        explosion_effect = {size=1.0, radar=false, type="small_thermal"},
        sfx = {sound="sfx/explosion.wav"},
    }
    return e
end

--- An ElectricExplosionEffect is a visual electrical explosion used by EMP missiles.
--- This is a cosmetic effect and does not deal damage on its own.
--- See also the ExplosionEffect class for conventional explosion effects.
--- Example: elec_explosion = ElectricExplosionEffect():setPosition(500,5000):setSize(20):setOnRadar(true)
function ElectricExplosionEffect()
    local e = createEntity()
    e.components = {
        transform = {},
        explosion_effect = {size=1.0, radar=false, type="electric"},
        sfx = {sound="sfx/emp_explosion.wav"},
    }
    return e
end

--- A KineticExplosionEffect is a visual kinetic impact used by HVLI missiles.
--- This is a cosmetic effect and does not deal damage on its own.
--- See also the ExplosionEffect class for conventional explosion effects.
--- Example: kinetic_explosion = KineticExplosionEffect():setPosition(500,5000):setSize(20):setOnRadar(true)
function KineticExplosionEffect()
    local e = createEntity()
    e.components = {
        transform = {},
        explosion_effect = {size=1.0, radar=false, type="kinetic"},
        sfx = {sound="sfx/explosion.wav"}, -- TODO: Kinetic impact sound
    }
    return e
end

--- A BillboardExplosion is a sprite sheet based explosion effect using the animated billboard shader.
--- This is a cosmetic effect and does not deal damage on its own.
--- It animates through frames of a sprite sheet texture and automatically destroys itself when the animation completes.
--- This function now creates an ExplosionEffect with sprite rendering mode enabled.
--- Example: explosion = BillboardExplosion():setPosition(500,5000):setSize(200):setExplosionLifetime(1.5)
function BillboardExplosion()
    local e = createEntity()
    e.components = {
        transform = {},
        explosion_effect = {
            size = 1000.0,
            radar = false,
            type = "large_thermal",
            render_mode = 0x14,  -- Sprite | Flash (0x04 | 0x10)
            fps = 64.0,
            sprite_columns = 8,
            sprite_rows = 8,
            sprite_texture = "texture/explosion_sprite.png",
            flash_texture = "",
            color = {1.0, 1.0, 1.0}
        },
        sfx = {sound="sfx/explosion.wav"},
    }
    return e
end

local Entity = getLuaEntityFunctionTable()
-- Defines whether to draw the ExplosionEffect on short-range radar.
-- Defaults to false.
-- Example: explosion:setOnRadar(true)
function Entity:setOnRadar(is_on_radar)
    if self.components.explosion_effect then self.components.explosion_effect.radar = is_on_radar end
    return self
end

--- Sets the animation speed in frames per second for sprite-based explosions.
--- Higher values make the explosion animate faster.
--- Example: explosion:setExplosionFPS(24.0)
function Entity:setExplosionFPS(fps)
    if self.components.explosion_effect then
        self.components.explosion_effect.fps = fps
    end
    return self
end

--- Sets the sprite sheet dimensions (columns and rows) for sprite-based explosions.
--- The texture should be organized as a grid with frames arranged left-to-right, top-to-bottom.
--- Example: explosion:setSpriteSheet(5, 5) -- for a 5x5 grid (25 frames)
function Entity:setSpriteSheet(columns, rows)
    if self.components.explosion_effect then
        self.components.explosion_effect.sprite_columns = columns
        self.components.explosion_effect.sprite_rows = rows
    end
    return self
end

--- Sets the color tint for the explosion.
--- Works for both sprite-based and traditional explosions.
--- Example: explosion:setExplosionColor(1.0, 0.5, 0.0) -- orange tint
function Entity:setExplosionColor(r, g, b)
    if self.components.explosion_effect then
        self.components.explosion_effect.color = {r, g, b}
    end
    return self
end

--- Sets the texture used for sprite-based explosions.
--- Example: explosion:setExplosionTexture("my_custom_explosion.png")
function Entity:setExplosionTexture(texture)
    if self.components.explosion_effect then
        self.components.explosion_effect.sprite_texture = texture
    end
    return self
end

--- Sets the render mode for the explosion effect using bitwise flags.
--- Flags: 0x01=Basic, 0x02=Advanced, 0x04=Sprite, 0x08=Particles, 0x10=Flash
--- Example: explosion:setExplosionRenderMode(0x14) -- Sprite | Flash
function Entity:setExplosionRenderMode(render_mode)
    if self.components.explosion_effect then
        self.components.explosion_effect.render_mode = render_mode
    end
    return self
end
