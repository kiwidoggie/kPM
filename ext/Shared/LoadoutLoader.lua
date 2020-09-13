class "LoadoutLoader"

function LoadoutLoader:__init()
    -- Original references
    self.m_AttackerVeniceSoldierCustomizations = { }
    self.m_DefenderVeniceSoldierCustomizations = { }
    self.m_VeniceUnlockAssets = { }
    self.m_MpSoldierBlueprint = nil
end

function LoadoutLoader:GetSoldierBlueprint()
    return self.m_MpSoldierBlueprint
end

function LoadoutLoader:GetUnlockAssets()
    return self.m_VeniceUnlockAssets
end

function LoadoutLoader:GetAttackerSoldierCustomizations()
    return self.m_AttackerVeniceSoldierCustomizations
end

function LoadoutLoader:GetDefenderSoldierCustomizations()
    return self.m_DefenderVeniceSoldierCustomizations
end

function LoadoutLoader:OnPartitionLoaded(p_Partition)
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
                    print("MpSoldier Blueprint: " .. s_SoldierBlueprint.instanceGuid:ToString("N"))
                end

                -- Save our reference
                self.m_MpSoldierBlueprint = s_SoldierBlueprint
            end
        end

        -- Check if the primary instance is SoldierWeaponUnlockAsset
        if s_PrimaryInstance:Is("SoldierWeaponUnlockAsset") then
            local s_WeaponUnlockAsset = SoldierWeaponUnlockAsset(s_PrimaryInstance)

            -- Debug log
            if kPMConfig.DebugMode then
                print("saving unlock: " .. s_WeaponUnlockAsset.name)
            end

            -- Unlock asset
            table.insert(self.m_VeniceUnlockAssets, s_WeaponUnlockAsset)
        end

        -- Check if the primary instance is VeniceSoldierCustomizationAsset
        if s_PrimaryInstance:Is("VeniceSoldierCustomizationAsset") then
            local s_CustomizationAsset = VeniceSoldierCustomizationAsset(s_PrimaryInstance)
            local s_AssetName = s_CustomizationAsset.name

            local s_IsUS = Utils.contains(s_AssetName, "/US")
            local s_IsRU = Utils.contains(s_AssetName, "/RU")

            -- Check if both US and RU
            if s_IsUS and s_IsRU then
                print("err: can't be both us and ru: " .. s_AssetName)
                return
            end

            -- Check if neither US or RU
            if not s_IsUS and not s_IsRU then
                print("err: no team detected: " .. s_AssetName)
                return
            end

            -- Debug information
            if kPMConfig.DebugMode then
                print("saving customization: " .. s_AssetName)
            end

            -- insert into the table of original references
            if s_IsUS then
                table.insert(self.m_AttackerVeniceSoldierCustomizations, s_CustomizationAsset)
            elseif s_IsRU then
                table.insert(self.m_DefenderVeniceSoldierCustomizations, s_CustomizationAsset)
            end
        end
    end
end

function LoadoutLoader:OnLevelDestroyed()
    -- Remove MpSoldier blueprint
    self.m_MpSoldierBlueprint = nil

    -- Reset our found original references
    self.m_VeniceUnlockAssets = { }
    self.m_AttackerVeniceSoldierCustomizations = { }
    self.m_DefenderVeniceSoldierCustomizations = { }
end

return LoadoutLoader()