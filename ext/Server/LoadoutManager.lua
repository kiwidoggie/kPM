class "LoadoutManager"

require ("__shared/kPMConfig")

function LoadoutManager:__init()

    -- Game engine references
    self.m_MpSoldierBlueprint = nil

    -- Soldier customization
    self.m_AttackerSoldierCustomization = nil
    self.m_DefenderSoldierCustomization = nil
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
    -- Hold our primary instance
    local s_PrimaryInstance = p_Partition.primaryInstance

    -- Validate primary instance
    if s_PrimaryInstance ~= nil then
        -- Check the primary instance if we have a SoldierBlueprint
        if self.m_MpSoldierBlueprint == nil and s_PrimaryInstance:Is("SoldierBlueprint") then
            local s_SoldierBlueprint = SoldierBlueprint(s_PrimaryInstance)
            if s_SoldierBlueprint.name == "Characters/Soldiers/MpSoldier" then
                -- Print out information in debug mode
                if kPMConfig.DebugMode then
                    print("MpSoldier Blueprint: " .. s_SoldierBlueprint.instanceGuid)
                end

                -- Save our reference
                self.m_MpSoldierBlueprint = s_SoldierBlueprint
            end
        end

        -- Check if the primary instance is VeniceSoldierCustomizationAsset
        if s_PrimaryInstance:Is("VeniceSoldierCustomizationAsset") then
            local s_CustomizationAsset = VeniceSoldierCustomizationAsset(s_PrimaryInstance)
            --[[
                Example Names:
                Gameplay/Kits/USSupport_XP4
                Gameplay/Kits/USAssault
                Gameplay/Kits/RUAssault_XP4
            ]]--
            local s_AssetName = s_CustomizationAsset.name

            if s_CustomizationAsset.labelSid == "M_ID_RECON" then
            elseif s_CustomizationAsset.labelSid == "M_ID_ENGINEER" then
            elseif s_CustomizationAsset.labelSid == "M_ID_ASSAULT" then
            elseif s_CustomizationAsset.labelSid == "ID_M_SUPPORT" then
            end
        end
    end

    -- Check if we have the correct primary instance

end

function LoadoutManager:OnLevelDestroyed()
    -- TODO: Remove all bindings/creations

    -- Remove MpSoldier blueprint
    self.m_MpSoldierBlueprint = nil
end

return LoadoutManager()