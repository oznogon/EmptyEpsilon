--- GUI API wrapper providing error-safe access to GUI creation functions
--- This module wraps the C++ GUI bindings with Lua-level error handling

-- Store original C++ functions
local _createOverlay = createOverlay
local _createLabel = createLabel
local _createSlider = createSlider
local _createButton = createButton
local _createImage = createImage
local _createElement = createElement
local _createCombatManeuver = createCombatManeuver
local _createRadar = createRadar
local _createCustomShipFunctions = createCustomShipFunctions
local _createAlertLevelOverlay = createAlertLevelOverlay
local _createKeyValueDisplay = createKeyValueDisplay
local _createDockingButton = createDockingButton
local _createImpulseControls = createImpulseControls
local _createWarpControls = createWarpControls
local _createJumpControls = createJumpControls
local _createEnergyDisplay = createEnergyDisplay
local _createHeadingDisplay = createHeadingDisplay
local _createVelocityDisplay = createVelocityDisplay

-- Helper function for safe GUI creation with error handling
local function safeCreate(name, func, ...)
    local success, result = pcall(func, ...)
    if not success then
        print(string.format("Error creating %s: %s", name, tostring(result)))
        return nil
    end
    return result
end

-- Wrapped creation functions with error handling
function createOverlay(container, id, color)
    return safeCreate("overlay '" .. id .. "'", _createOverlay, container, id, color or {r=0, g=0, b=0, a=255})
end

function createLabel(container, id, text, size)
    return safeCreate("label '" .. id .. "'", _createLabel, container, id, text or "", size or 30)
end

function createSlider(container, id, min, max, initial, callback)
    return safeCreate("slider '" .. id .. "'", _createSlider, container, id, min, max, initial, callback)
end

function createButton(container, id, text, callback)
    return safeCreate("button '" .. id .. "'", _createButton, container, id, text or "", callback)
end

function createImage(container, id, texture)
    return safeCreate("image '" .. id .. "'", _createImage, container, id, texture or "")
end

function createElement(container, id)
    return safeCreate("element '" .. id .. "'", _createElement, container, id)
end

function createCombatManeuver(container, id)
    return safeCreate("combat maneuver '" .. id .. "'", _createCombatManeuver, container, id)
end

function createRadar(container, id)
    return safeCreate("radar '" .. id .. "'", _createRadar, container, id)
end

function createCustomShipFunctions(container, position, name)
    return safeCreate("custom ship functions '" .. (name or position) .. "'", _createCustomShipFunctions, container, position, name or "")
end

function createAlertLevelOverlay(container)
    return safeCreate("alert level overlay", _createAlertLevelOverlay, container)
end

function createKeyValueDisplay(container, id, scale, key, value)
    return safeCreate("key-value display '" .. id .. "'", _createKeyValueDisplay, container, id, scale, key, value or "")
end

function createDockingButton(container, id)
    return safeCreate("docking button '" .. id .. "'", _createDockingButton, container, id)
end

function createImpulseControls(container, id)
    return safeCreate("impulse controls '" .. id .. "'", _createImpulseControls, container, id)
end

function createWarpControls(container, id)
    return safeCreate("warp controls '" .. id .. "'", _createWarpControls, container, id)
end

function createJumpControls(container, id)
    return safeCreate("jump controls '" .. id .. "'", _createJumpControls, container, id)
end

function createEnergyDisplay(container, id, scale)
    return safeCreate("energy display '" .. id .. "'", _createEnergyDisplay, container, id, scale)
end

function createHeadingDisplay(container, id, scale)
    return safeCreate("heading display '" .. id .. "'", _createHeadingDisplay, container, id, scale)
end

function createVelocityDisplay(container, id, scale)
    return safeCreate("velocity display '" .. id .. "'", _createVelocityDisplay, container, id, scale)
end

-- Export Alignment and GuiSize (already set by C++ bindings)
-- Alignment enum values: TopLeft, TopCenter, TopRight, CenterLeft, Center, CenterRight, BottomLeft, BottomCenter, BottomRight
-- GuiSize constants: SizeMax, SizeMatchHeight, SizeMatchWidth

-- Standalone GUI element manipulation functions
-- These work with light userdata elements (no metatable)

function guiSetSize(element, width, height)
    if not element then
        print("Warning: guiSetSize called with nil element")
        return nil
    end
    -- Call the C++ binding directly (registered in environment)
    local success, result = pcall(__guiSetSize, element, width, height)
    if not success then
        print("Error in guiSetSize: " .. tostring(result))
        return nil
    end
    return element
end

function guiSetPosition(element, x, y, alignment)
    if not element then
        print("Warning: guiSetPosition called with nil element")
        return nil
    end
    local success, result = pcall(__guiSetPosition, element, x, y, alignment or Alignment.TopLeft)
    if not success then
        print("Error in guiSetPosition: " .. tostring(result))
        return nil
    end
    return element
end

function guiSetVisible(element, visible)
    if not element then
        print("Warning: guiSetVisible called with nil element")
        return nil
    end
    local success, result = pcall(__guiSetVisible, element, visible)
    if not success then
        print("Error in guiSetVisible: " .. tostring(result))
        return nil
    end
    return element
end

function guiSetMargins(element, margin)
    if not element then
        print("Warning: guiSetMargins called with nil element")
        return nil
    end
    local success, result = pcall(__guiSetMargins, element, margin)
    if not success then
        print("Error in guiSetMargins: " .. tostring(result))
        return nil
    end
    return element
end

function guiDestroy(element)
    if not element then
        print("Warning: guiDestroy called with nil element")
        return
    end
    local success, result = pcall(__guiDestroy, element)
    if not success then
        print("Error in guiDestroy: " .. tostring(result))
    end
end

function guiSetAttribute(element, key, value)
    if not element then
        print("Warning: guiSetAttribute called with nil element")
        return nil
    end
    local success, result = pcall(__guiSetAttribute, element, key, value)
    if not success then
        print("Error in guiSetAttribute: " .. tostring(result))
        return nil
    end
    return element
end

function radarSetCallbacks(radar, onClick, onDrag, onRelease)
    if not radar then
        print("Warning: radarSetCallbacks called with nil radar")
        return nil
    end
    local success, result = pcall(__radarSetCallbacks, radar, onClick, onDrag, onRelease)
    if not success then
        print("Error in radarSetCallbacks: " .. tostring(result))
        return nil
    end
    return radar
end

function radarWorldToScreen(radar, world_x, world_y)
    if not radar then
        print("Warning: radarWorldToScreen called with nil radar")
        return 0, 0
    end
    local success, screen_x, screen_y = pcall(__radarWorldToScreen, radar, world_x, world_y)
    if not success then
        print("Error in radarWorldToScreen: " .. tostring(screen_x))
        return 0, 0
    end
    return screen_x, screen_y
end

function guiSetText(element, text)
    if not element then
        print("Warning: guiSetText called with nil element")
        return nil
    end
    local success, result = pcall(__guiSetText, element, text)
    if not success then
        print("Error in guiSetText: " .. tostring(result))
        return nil
    end
    return element
end

function guiSetLabelAlignment(element, alignment)
    if not element then
        print("Warning: guiSetLabelAlignment called with nil element")
        return nil
    end
    local success, result = pcall(__guiSetLabelAlignment, element, alignment)
    if not success then
        print("Error in guiSetLabelAlignment: " .. tostring(result))
        return nil
    end
    return element
end
