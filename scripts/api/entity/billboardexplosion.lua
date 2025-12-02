--- A BillboardExplosion is a sprite sheet based explosion effect using the animated billboard shader.
--- This is a cosmetic effect and does not deal damage on its own.
--- It animates through frames of a sprite sheet texture and automatically destroys itself when the animation completes.
--- Example: explosion = BillboardExplosion():setPosition(500,5000):setSize(200):setExplosionLifetime(1.5)
function BillboardExplosion()
    local e = createEntity()
    e.components = {
        transform = {},
        billboard_explosion = {
            lifetime = 1.0,
            max_lifetime = 1.0,
            size = 1000.0,
            fps = 64.0,
            sprite_columns = 8,
            sprite_rows = 8,
            color = {1.0, 1.0, 1.0},
            texture = "texture/explosion_sprite.png",
            radar = false
        },
        sfx = {sound="sfx/explosion.wav"},
    }
    return e
end

local Entity = getLuaEntityFunctionTable()

--- Sets the lifetime (and max_lifetime) of the billboard explosion in seconds.
--- The explosion will play through the animation at the specified FPS and then destroy itself.
--- Example: explosion:setLifetime(2.0)
function Entity:setExplosionLifetime(lifetime)
    if self.components.billboard_explosion then
        self.components.billboard_explosion.lifetime = lifetime
        self.components.billboard_explosion.max_lifetime = lifetime
    end
    return self
end

--- Sets the animation speed in frames per second.
--- Higher values make the explosion animate faster.
--- Example: explosion:setExplosionFPS(24.0)
function Entity:setExplosionFPS(fps)
    if self.components.billboard_explosion then
        self.components.billboard_explosion.fps = fps
    end
    return self
end

--- Sets the sprite sheet dimensions (columns and rows).
--- The texture should be organized as a grid with frames arranged left-to-right, top-to-bottom.
--- Example: explosion:setSpriteSheet(5, 5) -- for a 5x5 grid (25 frames)
function Entity:setSpriteSheet(columns, rows)
    if self.components.billboard_explosion then
        self.components.billboard_explosion.sprite_columns = columns
        self.components.billboard_explosion.sprite_rows = rows
    end
    return self
end

--- Sets the color tint for the explosion.
--- Example: explosion:setExplosionColor(1.0, 0.5, 0.0) -- orange tint
function Entity:setExplosionColor(r, g, b)
    if self.components.billboard_explosion then
        self.components.billboard_explosion.color = {r, g, b}
    end
    return self
end

--- Sets the texture used for the sprite sheet.
--- Example: explosion:setExplosionTexture("my_custom_explosion.png")
function Entity:setExplosionTexture(texture)
    if self.components.billboard_explosion then
        self.components.billboard_explosion.texture = texture
    end
    return self
end

--- Defines whether to draw the BillboardExplosion on short-range radar.
--- Defaults to false.
--- Example: explosion:setExplosionOnRadar(true)
function Entity:setExplosionOnRadar(is_on_radar)
    if self.components.billboard_explosion then
        self.components.billboard_explosion.radar = is_on_radar
    end
    return self
end
