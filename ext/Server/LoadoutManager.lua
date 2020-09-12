class "LoadoutManager"

require ("__shared/kPMConfig")

function LoadoutManager:__init()
end

function LoadoutManager:IsKitAllowed(p_Player, p_SelectedKitName)
    -- Enable all kits with debug mode
    if kPMConfig.DebugMode then
        return true
    end

    -- Validate player
    if p_Player == nil then
        return false
    end

    local s_TeamId = p_Player.teamId
    local s_SquadId = p_Player.squadId

    -- You must be assigned a player team
    -- Spectators will be TeamNeutral I think
    if s_TeamId == TeamId.TeamNeutral then
        return false
    end

    
end

function LoadoutManager:OnPartitionLoaded(p_Partition)
end

return LoadoutManager()