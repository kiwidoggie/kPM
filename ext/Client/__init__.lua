class "kPMClient"

require("ClientCommands")
require("Freecam")
require("__shared/GameStates")
require("__shared/kPMConfig")

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

    -- Ready-Up Inputs
    self.m_RupHeldTime = 0.0
    
    -- The current gamestate, this is read-only and should only be changed by the SERVER
    self.m_GameState = GameStates.None

    -- Freecamera
    self.m_FreeCam = FreeCam()
end

-- ==========
-- Extensions
-- ==========

function kPMClient:OnExtensionLoaded()
    -- Register all of the console variable commands
    self:RegisterCommands()

    -- Register all of the events
    self:RegisterEvents()

    -- Initialize the WebUI
    WebUI:Init()

    -- Show the WebUI
    WebUI:Call('Show')
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

    -- Install input hooks
    self.m_InputPreUpdateHook = Hooks:Install("Input:PreUpdate", 1, self, self.OnInputPreUpdate)

    -- Engine tick
    self.m_EngineUpdateEvent = Events:Subscribe("Engine:Update", self, self.OnEngineUpdate)
    

    -- Game State events
    self.m_GameStateChangedEvent = NetEvents:Subscribe("kPM:GameStateChanged", self, self.OnGameStateChanged)

    -- Ready Up State Update
    self.m_RupStateEvent = NetEvents:Subscribe("kPM:RupStateChanged", self, self.OnRupStateChanged)

    -- Player Events
    self.m_PlayerRespawnEvent = Events:Subscribe("Player:Respawn", self, self.OnPlayerRespawn)

    -- Level events
    self.m_LevelDestroyEvent = Events:Subscribe("Level:Destroy", self, self.OnLevelDestroyed)

    -- Client events
    self.m_ClientUpdateInputEvent = Events:Subscribe('Client:UpdateInput', self, self.OnUpdateInput)
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

    self.m_ReadyUpCommand = Console:Register("kpm_ready_up", "Toggles the ready up state", ClientCommands.ReadyUp)
end

function kPMClient:UnregisterCommands()
    print("unregistering commands")
end

function kPMClient:OnLevelDestroyed()
    -- Handle cleanup when level is destroyed
    if self.m_FreeCam ~= nil then
        self.m_FreeCam:OnLevelDestroy()
    end
end

function kPMClient:OnUpdateInput(p_DeltaTime)
    -- Update the freecam
    if self.m_FreeCam ~= nil then
        self.m_FreeCam:OnUpdateInput(p_DeltaTime)
    end

    -- Manually check for toggles
    if InputManager:WentKeyDown(InputDeviceKeys.IDK_F3) then
        print("enabling freecam movement")
        self.m_FreeCam:OnEnableFreeCamMovement()
    end

    if InputManager:WentKeyDown(InputDeviceKeys.IDK_F4) then

    end

    if InputManager:WentKeyDown(InputDeviceKeys.IDK_F5) then
        print("control start")
        self.m_FreeCam:OnControlStart()
    end

    if InputManager:WentKeyDown(InputDeviceKeys.IDK_F6) then
        print("control end")
        self.m_FreeCam:OnControlEnd()
    end
end

function kPMClient:OnInputPreUpdate(p_Hook, p_Cache, p_DeltaTime)
    -- Validate our cache
    if p_Cache == nil then
        print("err: invalid input cache.")
        return
    end

    -- Check to see if we are in the warmup state to get rup status
    if self.m_GameState == GameStates.Warmup then
        -- Get the interact level
        local s_InteractLevel = p_Cache:GetLevel(InputConceptIdentifiers.ConceptInteract)
        
        -- If the player is holding the interact key then update our variables and clear it for the next frame
        if s_InteractLevel > 0.0 then
            self.m_RupHeldTime = self.m_RupHeldTime + p_DeltaTime
            p_Cache:SetLevel(InputConceptIdentifiers.ConceptInteract, 0.0)
        else
            -- If the client isn't holding interact reset our time
            self.m_RupHeldTime = 0.0
        end

        -- Toggle the rup state
        if self.m_RupHeldTime >= kPMConfig.MaxReadyUpTime then
            -- Get the local player id
            local s_Player = PlayerManager:GetLocalPlayer()
            if s_Player == nil then
                print("err: could not get local player.")
                return
            end

            -- Get the local player id
            local s_PlayerId = s_Player.id

            -- Send the toggle event to the server
            NetEvents:Send("kPM:ToggleRup")

            print("rup status changed")

            -- Reset our rup timer
            self.m_RupHeldTime = 0.0
        end
    end

    -- Update the freecam
    if self.m_FreeCam ~= nil then
        self.m_FreeCam:OnUpdateInputHook(p_Hook, p_Cache, p_DeltaTime)
    end
end

function kPMClient:OnEngineUpdate(p_DeltaTime, p_SimulationDeltaTime)
    -- TODO: Implement time related functionaity

end

function kPMClient:OnRupStateChanged(p_WaitingOnPlayers, p_LocalRupStatus)
    if p_WaitingOnPlayers == nil then
        print("err: invalid waiting on player count.")
        return
    end

    if p_LocalRupStatus == nil then
        print("err: invalid local rup status.")
        return
    end

    WebUI:ExecuteJS("UpdateRupStatus(" .. p_WaitingOnPlayers.tostring() .. ", " .. p_LocalRupStatus.tostring() .. ");")
end

function kPMClient:OnGameStateChanged(p_OldGameState, p_GameState)
    -- Validate our gamestates
    if p_OldGameState == nil or p_GameState == nil then
        print("err: invalid gamestate from server")
        return
    end

    if p_OldGameState == p_GameState then
        print("warn: tried to transition to the same gamestate wtf?")
        return
    end

    print("info: gamestate " .. p_OldGameState .. " -> " .. p_GameState)
    self.m_GameState = p_GameState

    -- Update the WebUI
    WebUI:ExecuteJS("ChangeState(" .. self.m_GameState .. ");")
end

function kPMClient:OnPlayerRespawn(p_Player)
    -- Validate player
    if p_Player == nil then
        return
    end

end


return kPMClient()