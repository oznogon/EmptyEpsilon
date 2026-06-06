--- A Zone is a polygonal area of space defined by a series of coordinates.
--- Although a Zone is an entity, it isn't affected by physics and isn't rendered in 3D.
--- Zones are drawn on GM, comms, and long-range radar screens, can have a text label, and can return whether an entity is within their bounds.
--- New Zones can't be created via the exec.lua HTTP API.
--- Example:
--- -- Defines a blue rectangular 200sqU zone labeled "Home" around 0,0
--- zone = Zone():setColor(0,0,255):setPoints(-100000,100000, -100000,-100000, 100000,-100000, 100000,100000):setLabel("Home")
--- @type creation
function Zone()
    local e = createEntity()
    e.components = {
        transform = {},
        zone = {},
        never_radar_blocked = {},
    }
    return e
end

local Entity = getLuaEntityFunctionTable()
--- Sets the corners of this Zone n-gon to x_1, y_1, x_2, y_2, ... x_n, y_n.
--- Positive x coordinates are right/"east" of the origin, and positive y coordinates are down/"south" of the origin in space.
--- This also moves the Zone's Transform coordinates to the new centroid via setPosition().
--- Example: zone:setPoints(2000,0, 0,3000, -2000,0) -- defines a triangular zone
function Entity:setPoints(...)
    if self.components.zone then
        local coords = {...}
        local points = {}
        local sum_x, sum_y, count = 0, 0, 0
        for n = 1, #coords, 2 do
            local x, y = coords[n], coords[n+1]
            table.insert(points, {x, y})
            sum_x = sum_x + x
            sum_y = sum_y + y
            count = count + 1
        end
        if count > 0 then
            local center_x = sum_x / count
            local center_y = sum_y / count
            self:setPosition(center_x, center_y)
            local relative_points = {}
            for _, pt in ipairs(points) do
                table.insert(relative_points, {pt[1] - center_x, pt[2] - center_y})
            end
            self.components.zone.points = relative_points
        end
    end
    return self
end
--- Sets this Zone's color when drawn on radar.
--- Defaults to white (255,255,255).
--- Sets both the outline and fill color.
--- Example: zone:setColor(255,140,0)
function Entity:setColor(r, g, b)
    if self.components.zone then
        self.components.zone.color = {r, g, b, 255}
        self.components.zone.fill_color = {r, g, b, 64}
    end
    return self
end
--- Sets this Zone's fill color when drawn on radar. The fill color defaults to white with alpha 64.
--- If the fill alpha is 0, the filled area is not drawn.
--- Example: zone:setFillColor(0, 0, 255, 32) -- translucent blue fill
function Entity:setFillColor(r, g, b, a)
    if not a then a = 64 end
    if self.components.zone then self.components.zone.fill_color = {r, g, b, a} end
    return self
end
--- Sets this Zone's outline color when drawn on radar. The outline color defaults to white with alpha 255.
--- Also sets the label text color. If the outline alpha is 0, the outline and label are not drawn.
--- Example: zone:setOutlineColor(255, 0, 0, 192) -- semi-transparent red outline
function Entity:setOutlineColor(r, g, b, a)
    if not a then a = 255 end
    if self.components.zone then self.components.zone.color = {r, g, b, a} end
    return self
end
--- Sets this Zone's text label, rendered at the zone's center point.
--- Example: zone:setLabel("Hostile space")
function Entity:setLabel(label)
    if self.components.zone then self.components.zone.label = label end
    return self
end
--- Returns this Zone's text label.
--- Example: zone:getLabel()
function Entity:getLabel()
    if self.components.zone then return self.components.zone.label end
    return ""
end
--- Sets this Zone's local skybox. Optionally also sets this zone's skybox fade transition distance, which defaults to 0.
--- Examples:
---   zone:setLocalSkybox("purple", 250) -- sets this zone's local skybox to "purple" with a 0.25U transition distance
---   zone:setLocalSkybox("purple") -- sets the local skybox but doesn't modify the fade distance
function Entity:setLocalSkybox(skybox, transition)
    if self.components.zone then
        -- Values without corresponding image sets result in pink skyboxes!
        if skybox ~= "" then
            self.components.zone.skybox = skybox
        end

        transition = transition or self.components.zone.skybox_fade_distance
        if transition >= 0 then
            self.components.zone.skybox_fade_distance = transition
        end
    end
    return self
end
--- Returns whether the given entity is inside this Zone.
--- Example: zone:isInside(obj) -- returns true if `obj` is within the zone's bounds
function Entity:isInside(obj)
    local x, y = obj:getPosition()
    return isInsideZone(x, y, self)
end
