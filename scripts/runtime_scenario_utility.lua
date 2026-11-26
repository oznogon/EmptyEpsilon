-- Shared scenario runtime helpers.

local Runtime = {}

function Runtime.setGMButtons()
    mainGMButtons = mainGMButtonsDuringPause
    mainGMButtons()
end

function Runtime.protectedUpdate(inner, options)
    options = options or {}
    return function(delta)
        local status, error_message = pcall(inner, delta)
        if not status then
            print("script error : - ")
            print(error_message)
            local popup_mode = options.popup()
            if popup_mode == "once" or popup_mode == "always" then
                if popup_mode == "once" then
                    options.set_popup("never")
                end
                local prefix = options.message and options.message()
                    or _("stationReport-msgGM", "script error - \n")
                addGMMessage(prefix .. error_message)
            end
        end
    end
end

return Runtime
