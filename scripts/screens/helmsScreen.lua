--- Helms Screen Definition
--- This screen can be customized by scenarios through hooks

local HelmsScreen = {}

-- Helper function to calculate angle from a 2D vector
local function vec2ToAngle(x, y)
    return math.deg(math.atan2(y, x))
end

-- Screen state
HelmsScreen.container = nil
HelmsScreen.radar = nil
HelmsScreen.heading_hint = nil
HelmsScreen.elements = {}

-- Hooks for customization
HelmsScreen.hooks = {
    onPreCreate = {},
    onPostCreate = {},
    onCreateRadar = {},
    onCreateControls = {},
}

-- Register a hook function
function HelmsScreen:registerHook(hook_name, func)
    if self.hooks[hook_name] then
        table.insert(self.hooks[hook_name], func)
    end
end

-- Call all registered hooks
function HelmsScreen:callHooks(hook_name, ...)
    if self.hooks[hook_name] then
        for _, func in ipairs(self.hooks[hook_name]) do
            local success, error = pcall(func, self, ...)
            if not success then
                print("Error in helms screen hook " .. hook_name .. ": " .. tostring(error))
            end
        end
    end
end

-- Initialize the screen
function HelmsScreen:init(container)
    self.container = container
    self.elements = {}

    self:callHooks("onPreCreate")
    self:createDefaults()
    self:callHooks("onPostCreate")

    return self
end

-- Create the default Helms screen layout
function HelmsScreen:createDefaults()
    if not self.container then
        print("Error: No container provided to HelmsScreen")
        return
    end

    -- Background gradient
    local gradient = createImage(self.container, "BACKGROUND_GRADIENT", "gui/background/gradient.png")
    if gradient then
        guiSetPosition(gradient, 0, 0, Alignment.Center)
        guiSetSize(gradient, 1200, 900)
        self.elements.background_gradient = gradient
    end

    -- Background crosses
    -- Note: Tiled textures require setTextureTiled() method which is not yet bound
    -- TODO: Add binding for setTextureTiled()
    -- local crosses = createOverlay(self.container, "BACKGROUND_CROSSES", {r=255, g=255, b=255, a=255})
    -- if crosses then
    --     self.elements.background_crosses = crosses
    -- end

    -- Alert level overlay
    local alert_overlay = createAlertLevelOverlay(self.container)
    if alert_overlay then
        self.elements.alert_overlay = alert_overlay
    end

    -- Radar view (centered, circular)
    -- TODO: Radar configuration methods (setStyle, setRangeIndicatorStepSize, etc.)
    self:callHooks("onCreateRadar")
    self.radar = createRadar(self.container, "HELMS_RADAR")
    if self.radar then
        guiSetPosition(self.radar, 0, 0, Alignment.Center)
        guiSetSize(self.radar, GuiSize.SizeMatchHeight, 800)
        -- Radar configuration uses C++ defaults:
        -- - Circular style
        -- - 5km range
        -- - Ghost dots, waypoints, callsigns, heading indicators
        -- - Missile tube indicators
        self.elements.radar = self.radar
    end

    -- Heading hint label (shown when clicking on radar)
    self.heading_hint = createLabel(self.container, "HEADING_HINT", "", 30)
    if self.heading_hint then
        guiSetLabelAlignment(self.heading_hint, Alignment.Center)
        guiSetSize(self.heading_hint, 0, 0)
        guiSetVisible(self.heading_hint, false)
        self.elements.heading_hint = self.heading_hint
    end

    -- Set up radar click callbacks for heading control
    if self.radar and self.heading_hint then
        radarSetCallbacks(self.radar,
            -- onClick: Calculate angle and set target rotation
            function(x, y)
                local player = getPlayerShip(-2)
                if player and player:isValid() then
                    local px, py = player:getPosition()
                    local angle = vec2ToAngle(x - px, y - py)
                    player:commandTargetRotation(angle)

                    -- Show heading hint near click location
                    local heading = (angle + 90) % 360
                    guiSetText(self.heading_hint, string.format("%.1f", heading))

                    -- Convert world coordinates to screen coordinates
                    local screen_x, screen_y = radarWorldToScreen(self.radar, x, y)
                    -- Don't specify alignment, let it use the element's default (TopLeft)
                    guiSetPosition(self.heading_hint, screen_x, screen_y - 35)
                    guiSetVisible(self.heading_hint, true)
                end
            end,
            -- onDrag: Same as onClick
            function(x, y)
                local player = getPlayerShip(-2)
                if player and player:isValid() then
                    local px, py = player:getPosition()
                    local angle = vec2ToAngle(x - px, y - py)
                    player:commandTargetRotation(angle)

                    -- Show heading hint near click location
                    local heading = (angle + 90) % 360
                    guiSetText(self.heading_hint, string.format("%.1f", heading))

                    -- Convert world coordinates to screen coordinates
                    local screen_x, screen_y = radarWorldToScreen(self.radar, x, y)
                    -- Don't specify alignment, let it use the element's default (TopLeft)
                    guiSetPosition(self.heading_hint, screen_x, screen_y - 35)
                    guiSetVisible(self.heading_hint, true)
                end
            end,
            -- onRelease: Hide heading hint
            function(x, y)
                guiSetVisible(self.heading_hint, false)
            end
        )
    end

    -- Combat maneuver indicator (bottom right)
    local combat_maneuver = createCombatManeuver(self.container, "COMBAT_MANEUVER")
    if combat_maneuver then
        guiSetPosition(combat_maneuver, -20, -20, Alignment.BottomRight)
        guiSetSize(combat_maneuver, 280, 215)
        self.elements.combat_maneuver = combat_maneuver
    end

    -- Info displays (top left)
    local energy_display = createEnergyDisplay(self.container, "ENERGY_DISPLAY", 0.45)
    if energy_display then
        guiSetPosition(energy_display, 20, 100, Alignment.TopLeft)
        guiSetSize(energy_display, 240, 40)
        self.elements.energy_display = energy_display
    end

    local heading_display = createHeadingDisplay(self.container, "HEADING_DISPLAY", 0.45)
    if heading_display then
        guiSetPosition(heading_display, 20, 140, Alignment.TopLeft)
        guiSetSize(heading_display, 240, 40)
        self.elements.heading_display = heading_display
    end

    local velocity_display = createVelocityDisplay(self.container, "VELOCITY_DISPLAY", 0.45)
    if velocity_display then
        guiSetPosition(velocity_display, 20, 180, Alignment.TopLeft)
        guiSetSize(velocity_display, 240, 40)
        self.elements.velocity_display = velocity_display
    end

    -- Engine controls layout (bottom left)
    self:callHooks("onCreateControls")
    local engine_layout = createElement(self.container, "ENGINE_LAYOUT")
    if engine_layout then
        guiSetPosition(engine_layout, 20, -100, Alignment.BottomLeft)
        guiSetSize(engine_layout, GuiSize.SizeMax, 300)
        guiSetAttribute(engine_layout, "layout", "horizontal")
        self.elements.engine_layout = engine_layout

        -- Impulse controls
        local impulse = createImpulseControls(engine_layout, "IMPULSE")
        if impulse then
            guiSetSize(impulse, 100, GuiSize.SizeMax)
            self.elements.impulse_controls = impulse
        end

        -- Warp controls
        local warp = createWarpControls(engine_layout, "WARP")
        if warp then
            guiSetSize(warp, 100, GuiSize.SizeMax)
            self.elements.warp_controls = warp
        end

        -- Jump controls
        local jump = createJumpControls(engine_layout, "JUMP")
        if jump then
            guiSetSize(jump, 100, GuiSize.SizeMax)
            self.elements.jump_controls = jump
        end
    end

    -- Docking button (bottom left)
    local docking = createDockingButton(self.container, "DOCKING")
    if docking then
        guiSetPosition(docking, 20, -20, Alignment.BottomLeft)
        guiSetSize(docking, 280, 50)
        self.elements.docking_button = docking
    end

    -- Custom ship functions (top right)
    local custom_functions = createCustomShipFunctions(self.container, "Helms", "")
    if custom_functions then
        guiSetPosition(custom_functions, -20, 120, Alignment.TopRight)
        guiSetSize(custom_functions, 250, GuiSize.SizeMax)
        self.elements.custom_functions = custom_functions
    end
end

-- Hot reload: destroy all elements and recreate
function HelmsScreen:reload()
    print("Reloading Helms screen...")

    -- Destroy all elements
    for name, element in pairs(self.elements) do
        if element and element.destroy then
            pcall(element.destroy, element)
        end
    end

    self.elements = {}
    self.radar = nil
    self.heading_hint = nil

    -- Recreate defaults
    self:createDefaults()
    self:callHooks("onPostCreate")

    print("Helms screen reloaded")
end

-- Get an element by name (for customization)
function HelmsScreen:getElement(name)
    return self.elements[name]
end

-- Remove an element by name
function HelmsScreen:removeElement(name)
    local element = self.elements[name]
    if element and element.destroy then
        pcall(element.destroy, element)
        self.elements[name] = nil
        return true
    end
    return false
end

-- Add a custom element
function HelmsScreen:addElement(name, element)
    self.elements[name] = element
end

return HelmsScreen
