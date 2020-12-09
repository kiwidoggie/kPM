local LevelNameHelper = class("LevelNameHelper")

function LevelNameHelper:GetLevelName()
    local l_LevelName = nil
    local l_tempLevelName = SharedUtils:GetLevelName()
    
    if l_tempLevelName == nil then
        return nil
    end

    for word in string.gmatch(l_tempLevelName, '([^/]+)') do
        l_LevelName = word
    end

    return l_LevelName
end

return LevelNameHelper
