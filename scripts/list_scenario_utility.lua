-- Shared list maintenance utilities, used in Defenders or Pirates and
-- Iris Siege.

local List = {}

function List.clean(list)
    if #list == 0 then
        return true
    end
    for index, entry in ipairs(list) do
        if entry == nil or not entry:isValid() then
            list[index] = list[#list]
            list[#list] = nil
            return false
        end
    end
    return true
end

return List
