class 'StratVision'

function StratVision:__init()
    self.m_StatVision = nil
    
    Events:Subscribe('Extension:Unloading', function()
        self:RemoveStratVision()
    end)
end

function StratVision:SetStratVision()
    if self.m_StatVision ~= nil then
        return
    end

    local s_StratVisionData = VisualEnvironmentEntityData()
    s_StratVisionData.enabled = true
    s_StratVisionData.visibility = 1.0
    s_StratVisionData.priority = 999999

    local s_ColorCorrection = ColorCorrectionComponentData()
    s_ColorCorrection.enable = true
    s_ColorCorrection.brightness = Vec3(1.0, 1.0, 1.0)
    s_ColorCorrection.contrast = Vec3(1.0, 1.0, 1.0)
    s_ColorCorrection.saturation = Vec3(0.0, 0.0, 0.0)
    s_ColorCorrection.hue = 0.0

    s_StratVisionData.components:add(s_ColorCorrection)
    s_StratVisionData.runtimeComponentCount = s_StratVisionData.runtimeComponentCount + 1

    self.m_StatVision = EntityManager:CreateEntity(s_StratVisionData, LinearTransform())

    if self.m_StatVision ~= nil then
        self.m_StatVision:Init(Realm.Realm_Client, true)
    end
end

function StratVision:RemoveStratVision()
    if self.m_StatVision ~= nil then
        self.m_StatVision:Destroy()
        self.m_StatVision = nil
    end
end

return StratVision()
