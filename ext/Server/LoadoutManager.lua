class "LoadoutManager"

require ("__shared/kPMConfig")
require ("__shared/LoadoutLoader")

function LoadoutManager:__init()
    -- Created custom customizations
    self.m_AttackerSoldierCustomizationAssault = nil
    self.m_AttackerSoldierCustomizationSmg = nil
    self.m_AttackerSoldierCustomizationDemo = nil
    self.m_AttackerSoldierCustomizationRecon = nil

    self.m_DefenderSoldierCustomizationAssault = nil
    self.m_DefenderSoldierCustomizationSmg = nil
    self.m_DefenderSoldierCustomizationDemo = nil
    self.m_DefenderSoldierCustomizationRecon = nil

    self.m_DebugSoldierCustomization = nil

    -- Loader
    self.m_LoadoutLoader = LoadoutLoader()
end

function LoadoutManager:OnPartitionLoaded(p_Partition)
    if p_Partition == nil then
        return
    end

    -- Forward event to loadout loader
    self.m_LoadoutLoader:OnPartitionLoaded(p_Partition)
end

function LoadoutManager:OnLevelDestroyed()

    -- Remove all custom customizations
    self.m_AttackerSoldierCustomizationAssault = nil
    self.m_AttackerSoldierCustomizationSmg = nil
    self.m_AttackerSoldierCustomizationDemo = nil
    self.m_AttackerSoldierCustomizationRecon = nil

    self.m_DefenderSoldierCustomizationAssault = nil
    self.m_DefenderSoldierCustomizationSmg = nil
    self.m_DefenderSoldierCustomizationDemo = nil
    self.m_DefenderSoldierCustomizationRecon = nil

    self.m_DebugSoldierCustomization = nil

    -- Update the loadout loader
    self.m_LoadoutLoader:OnLevelDestroyed()
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

return LoadoutManager()