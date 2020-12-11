class "kPMShared"

require("__shared/MapsConfig")
require ("__shared/LevelNameHelper")

function kPMShared:__init()
    print("shared initialization")

    self.m_ExtensionLoadedEvent = Events:Subscribe("Extension:Loaded", self, self.OnExtensionLoaded)
    self.m_ExtensionUnloadedEvent = Events:Subscribe("Extension:Unloaded", self, self.OnExtensionUnloaded)
end

function kPMShared:OnExtensionLoaded()
    -- Register all of the events
    self:RegisterEvents()

    -- Register all of the hooks
    self:RegisterHooks()
end

function kPMShared:OnExtensionUnloaded()
    self:UnregisterEvents()
    self:UnregisterHooks()
end

-- ==========
-- Events
-- ==========
function kPMShared:RegisterEvents()
    print("registering events")

    -- Level events
    self.m_LevelLoadedEvent = Events:Subscribe("Level:Loaded", self, self.OnLevelLoaded)
    self.m_PartitionLoaded = Events:Subscribe("Partition:Loaded", self, self.OnPartitionLoaded)
end

function kPMShared:UnregisterEvents()
    print("unregistering events")
end

function kPMShared:OnLevelLoaded(p_LevelName, p_GameMode)
    print("spawn map specific stuff")
    
    self:SpawnPlants(LevelNameHelper:GetLevelName())
end

function kPMShared:OnPartitionLoaded(partition)
    local l_LevelName = LevelNameHelper:GetLevelName()

    if l_LevelName ~= nil then
        if partition.guid == MapsConfig[l_LevelName]["EFFECTS_WORLD_PART_DATA"]["PARTITION"] then
            for _, instance in pairs(partition.instances) do
                if instance.instanceGuid == MapsConfig[l_LevelName]["EFFECTS_WORLD_PART_DATA"]["INSTANCE"] then
                    local l_EffectsWorldData = WorldPartData(instance)
                    for _, object in pairs(l_EffectsWorldData.objects) do
                        if object:Is("EffectReferenceObjectData") then
                            local effectReferenceObjectData = EffectReferenceObjectData(object)
                            effectReferenceObjectData:MakeWritable()
                            effectReferenceObjectData.excluded = true
                        end
                    end
                end
            end
        end
    end
end

-- ==========
-- Hooks
-- ==========
function kPMShared:RegisterHooks()
    print("registering hooks")
end

function kPMShared:UnregisterHooks()
    print("unregistering hooks")
end

-- ==========
-- kPM Specific functions
-- ==========
function kPMShared:SpawnPlants(p_LevelName)
    if p_LevelName == nil then
        return
    end
    
    self:SpawnPlant(MapsConfig[p_LevelName]["PLANT_A"]["POS"], "A")
    self:SpawnPlant(MapsConfig[p_LevelName]["PLANT_B"]["POS"], "B")
end

function kPMShared:SpawnPlant(p_Trans, p_Id)
    -- TODO: Need to spawn the plant point models and markers to the map!
    -- self:SpawnBarrels(p_Trans)
end

function kPMShared:SpawnBarrels(p_Trans)
    -- TODO: Need to finish this, DieselBarrelPallet_01 is not really good, you can destory it with a grenade... :(
    local l_PlantBp = ResourceManager:SearchForDataContainer('Objects/DieselBarrelPallet_01/DieselBarrelPallet_01')

	if l_PlantBp == nil then
		error('err: could not find the plant blueprint.')
		return
    end
    
	local l_Params = EntityCreationParams()
	l_Params.transform.trans = p_Trans.trans
	l_Params.networked = false

    local l_Bus = EntityManager:CreateEntitiesFromBlueprint(l_PlantBp, l_Params)


    if l_Bus ~= nil then
        for _, entity in pairs(l_Bus.entities) do
            entity:Init(Realm.Realm_ClientAndServer, true)
        end
    else
		error('err: could not spawn plant.')
		return
	end
end

return kPMShared()
