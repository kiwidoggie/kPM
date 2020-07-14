class "kPMClient"

require("ClientCommands")

function kPMClient:__init()
    -- Start the client initialization
    print("client initialization")

    --  Console commands
    self.m_PositionCommand = nil

    -- Extension events
    self.m_ExtensionLoadedEvent = nil
    self.m_ExtensionUnloadedEvent = nil

    self.m_PartitionLoadedEvent = nil
    self.m_PlayerChatEvent = nil

    -- These are the specific events that are required to kick everything else off
    self.m_ExtensionLoadedEvent = Events:Subscribe("Extension:Loaded", self, self.OnExtensionLoaded)
    self.m_ExtensionUnloadedEvent = Events:Subscribe("Extension:Unloaded", self, self.OnExtensionUnloaded)
end

-- ==========
-- Extensions
-- ==========

function kPMClient:OnExtensionLoaded()
    -- Register all of the console variable commands
    self:RegisterCommands()

    -- Register all of the events
    self:RegisterEvents()
end

function kPMClient:OnExtensionUnloaded()
    self:UnregisterCommands()

    self:UnregisterEvents()
end

-- ==========
-- Events
-- ==========
function kPMClient:RegisterEvents()
    print("registering events")

end

function kPMClient:UnregisterEvents()
    print("unregistering events")
end

-- ==========
-- Console Commands
-- ==========
function kPMClient:RegisterCommands()
    print("registering commands")
    -- Register console commands for users to leverage
    self.m_PositionCommand = Console:Register("kpm_player_pos", "Displays the current player position", ClientCommands.PlayerPosition)
end

function kPMClient:UnregisterCommands()
    print("unregistering commands")
end

return kPMClient()