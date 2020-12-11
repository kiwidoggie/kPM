class "kPMClient"

require("ClientCommands")
require("Freecam")
require("UICleanup")
require("__shared/GameStates")
require("__shared/kPMConfig")
require("__shared/MapsConfig")
require("__shared/LevelNameHelper")

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

    -- Plant Inputs
    self.m_PlantHeldTime = 0.0

    -- Tab / Scoreboard Inputs
    self.m_TabHeldTime = 0.0
    self.m_ScoreboardActive = false
    
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
    WebUI:Show()
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

    -- Update ping table
    self.m_PlayerPing = NetEvents:Subscribe('Player:Ping', self, self.OnPlayerPing)
    self.m_PingTable = {}

    self.m_PlayerReadyUpPlayers = NetEvents:Subscribe('Player:ReadyUpPlayers', self, self.OnReadyUpPlayers)
    self.m_PlayerReadyUpPlayersTable = {}

    self.m_UIPushScreen = Hooks:Install('UI:PushScreen', 1, self, self.OnUIPushScreen)

    -- Player Events
    self.m_PlayerRespawnEvent = Events:Subscribe("Player:Respawn", self, self.OnPlayerRespawn)
    self.m_PlayerKilledEvent = Events:Subscribe("Player:Killed", self, self.OnPlayerKilled)
    self.m_PlayerDeletedEvent = Events:Subscribe("Player:Deleted", self, self.OnPlayerDeleted)

    -- Level events
    self.m_LevelDestroyEvent = Events:Subscribe("Level:Destroy", self, self.OnLevelDestroyed)
    self.m_LevelLoadedEvent = Events:Subscribe("Level:Loaded", self, self.OnLevelLoaded)

    -- Client events
    self.m_ClientUpdateInputEvent = Events:Subscribe('Client:UpdateInput', self, self.OnUpdateInput)

    -- WebUI
    self.m_SetSelectedTeamEvent = Events:Subscribe("WebUISetSelectedTeam", self, self.OnSetSelectedTeam)
    self.m_SetSelectedLoadoutEvent = Events:Subscribe("WebUISetSelectedLoadout", self, self.OnSetSelectedLoadout)

    self.m_FirstSpawn = false

    -- Cleanup Events
    self.m_CleanupEvent = NetEvents:Subscribe("kPM:Cleanup", self, self.OnCleanup)
end

function kPMClient:UnregisterEvents()
    print("unregistering events")
end

function kPMClient:OnSetSelectedTeam(p_Team)
    if p_Team == nil then
        return
    end

    print("client selected a team")
    NetEvents:Send("kPM:PlayerSetSelectedTeam", p_Team)
end

function kPMClient:OnSetSelectedLoadout(p_Data)
    if p_Data == nil then
        return
    end

    -- If the player never spawned we should force him to pick a team and a loadout first
    if self.m_FirstSpawn == false then
        self.m_FirstSpawn = true
    end

    print("client selected a loadout")
    NetEvents:Send("kPM:PlayerSetSelectedKit", p_Data)
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

function kPMClient:OnLevelLoaded()
    NetEvents:Send("kPM:PlayerConnected")
    WebUI:ExecuteJS("OpenCloseTeamMenu();")
end

function kPMClient:OnUpdateInput(p_DeltaTime)
    -- Update the freecam
    if self.m_FreeCam ~= nil then
        self.m_FreeCam:OnUpdateInput(p_DeltaTime)
    end

    -- Open Team menu
    if InputManager:WentKeyDown(InputDeviceKeys.IDK_F9) then
        -- If the player never spawned we should force him to pick a team and a loadout first
        if self.m_FirstSpawn then
            WebUI:ExecuteJS("OpenCloseTeamMenu();")
        end
    end

    -- Open Loadout menu
    if InputManager:WentKeyDown(InputDeviceKeys.IDK_F10) then
        -- If the player never spawned we should force him to pick a team and a loadout first
        if self.m_FirstSpawn then
            WebUI:ExecuteJS("OpenCloseLoadoutMenu();")
        end
    end

    -- Manually check for toggles
    if InputManager:WentKeyDown(InputDeviceKeys.IDK_F4) then
        print("enabling freecam movement")
        self.m_FreeCam:OnEnableFreeCamMovement()
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

    -- Tab held or not
    self:IsTabHeld(p_Hook, p_Cache, p_DeltaTime)

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

        WebUI:ExecuteJS("RupInteractProgress(" .. tostring(self.m_RupHeldTime) ..", " .. tostring(kPMConfig.MaxReadyUpTime) .. ");")

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
    elseif self:IsPlayerInsideThePlantZone() and (self.m_GameState == GameStates.FirstHalf or self.m_GameState == GameStates.SecondHalf) then
        -- Get the interact level
        local s_InteractLevel = p_Cache:GetLevel(InputConceptIdentifiers.ConceptInteract)

        -- If the player is holding the interact key then update our variables and clear it for the next frame
        if s_InteractLevel > 0.0 then
            self.m_PlantHeldTime = self.m_PlantHeldTime + p_DeltaTime
            p_Cache:SetLevel(InputConceptIdentifiers.ConceptInteract, 0.0)
        else
            -- If the client isn't holding interact reset our time
            self.m_PlantHeldTime = 0.0
        end

        WebUI:ExecuteJS("PlantInteractProgress(" .. tostring(self.m_PlantHeldTime) ..", " .. tostring(kPMConfig.PlantTime) .. ");")

        -- Toggle the rup state
        if self.m_PlantHeldTime >= kPMConfig.PlantTime then
            -- Get the local player id
            local s_Player = PlayerManager:GetLocalPlayer()
            if s_Player == nil then
                print("err: could not get local player.")
                return
            end

            -- Get the local player id
            local s_PlayerId = s_Player.id

            -- Send the toggle event to the server
            --NetEvents:Send("kPM:ToggleRup")

            print("client planted")

            -- Reset our rup timer
            self.m_PlantHeldTime = 0.0
        end
    end

    -- Update the freecam
    if self.m_FreeCam ~= nil then
        self.m_FreeCam:OnUpdateInputHook(p_Hook, p_Cache, p_DeltaTime)
    end
end

function kPMClient:IsTabHeld(p_Hook, p_Cache, p_DeltaTime)
    -- Get the interact level
    local s_InteractLevel = p_Cache:GetLevel(InputConceptIdentifiers.ConceptScoreboard)

    local l_ScoreboardActive = self.m_ScoreboardActive

    local l_Player = PlayerManager:GetLocalPlayer()

    -- If the player is holding the interact key then update our variables and clear it for the next frame
    if s_InteractLevel > 0.0 then
        l_ScoreboardActive = true
        self.m_TabHeldTime = self.m_TabHeldTime + p_DeltaTime
        p_Cache:SetLevel(InputConceptIdentifiers.ConceptScoreboard, 0.0)
    else
        self.m_TabHeldTime = 0.0
        l_ScoreboardActive = false
    end

    if self.m_TabHeldTime >= 2.0 then
        self:OnUpdateScoreboard(l_Player)

        -- Reset our timer
        self.m_TabHeldTime = 0.0
    end


    if self.m_ScoreboardActive ~= l_ScoreboardActive then
        self.m_ScoreboardActive = l_ScoreboardActive

        if l_ScoreboardActive == true then
            self:OnUpdateScoreboard(l_Player)
        end

        WebUI:ExecuteJS("OpenCloseScoreboard()")
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

    WebUI:ExecuteJS("UpdateRupStatus(" .. tostring(p_WaitingOnPlayers) .. ", " .. tostring(p_LocalRupStatus) .. ");")
end

function kPMClient:OnUIPushScreen(hook, screen, graphPriority, parentGraph)
    local screen = UIGraphAsset(screen)
    if screen.name == 'UI/Flow/Screen/Scoreboards/ScoreboardTwoTeamsScreen' or
        screen.name == 'UI/Flow/Screen/Scoreboards/ScoreboardTwoTeamsHUD32Screen'
    then
        hook:Return(nil)
        return
    end
end

function kPMClient:OnPlayerPing(p_PingTable)
    self.m_PingTable = p_PingTable
end

function kPMClient:OnReadyUpPlayers(p_ReadyUpPlayers)
    self.m_PlayerReadyUpPlayersTable = p_ReadyUpPlayers
end

function kPMClient:OnGameStateChanged(p_OldGameState, p_GameState)
    -- Validate our gamestates
    if p_OldGameState == nil or p_GameState == nil then
        print("err: invalid gamestate from server")
        return
    end

    if p_OldGameState == p_GameState then
        -- Removed the warning, on first connect it tries to update the local GameState to GameState.None, 
        -- later on when the player reconnects the local GameState going to change for him
        return
    end

    print("info: gamestate " .. p_OldGameState .. " -> " .. p_GameState)
    self.m_GameState = p_GameState

    -- Update the WebUI
    WebUI:ExecuteJS("ChangeState(" .. self.m_GameState .. ");")
end

function kPMClient:OnUpdateScoreboard(player)
    print("OnUpdateScoreboard")

    local l_DefendersId = TeamId.Team1
    local l_AttackersId = TeamId.Team2

    local l_PlayerListDefenders = PlayerManager:GetPlayersByTeam(l_DefendersId)
    local l_PlayerListAttackers = PlayerManager:GetPlayersByTeam(l_AttackersId)

    table.sort(l_PlayerListDefenders, function(a, b) 
		return a.score > b.score
    end)
    
    table.sort(l_PlayerListAttackers, function(a, b) 
		return a.score > b.score
    end)

    local playersObject = {}
    playersObject[l_DefendersId] = {}
    playersObject[l_AttackersId] = {}
    
    for index, player in pairs(l_PlayerListDefenders) do
		local ping = "0"
		if self.m_PingTable[player.id] ~= nil and self.m_PingTable[player.id] >= 0 and self.m_PingTable[player.id] < 999 then
			ping = self.m_PingTable[player.id]
        end

        local ready = false
        if self.m_PlayerReadyUpPlayersTable[player.id] ~= nil then
            ready = self.m_PlayerReadyUpPlayersTable[player.id]
        end
        
		table.insert(playersObject[l_DefendersId], {
            ["id"] = player.id,
            ["name"] = player.name,
            ["ping"] = ping,
            ["kill"] = player.kills,
            ["death"] = player.deaths,
            ["isDead"] = not player.alive,
            ["ready"] = ready,
        })
    end


    for index, player in pairs(l_PlayerListAttackers) do
		local ping = "0"
		if self.m_PingTable[player.id] ~= nil and self.m_PingTable[player.id] >= 0 and self.m_PingTable[player.id] < 999 then
			ping = self.m_PingTable[player.id]
        end

        local ready = false
        if self.m_PlayerReadyUpPlayersTable[player.id] ~= nil then
            ready = self.m_PlayerReadyUpPlayersTable[player.id]
        end
        
		table.insert(playersObject[l_AttackersId], {
            ["id"] = player.id,
            ["name"] = player.name,
            ["ping"] = ping,
            ["kill"] = player.kills,
            ["death"] = player.deaths,
            ["isDead"] = not player.alive,
            ["ready"] = ready,
        })
    end
    
    WebUI:ExecuteJS(string.format("UpdatePlayers(%s)", json.encode(playersObject)))
end

function kPMClient:OnCleanup(p_EntityType)
    if p_EntityType == nil then
        return
    end

    print('Cleaning up: ' ..p_EntityType)

    local l_Entities = {}

    local l_Iterator = EntityManager:GetIterator(p_EntityType)
    local l_Entity = l_Iterator:Next()
    while l_Entity do
        l_Entities[#l_Entities+1] = Entity(l_Entity)
        l_Entity = l_Iterator:Next()
    end

    for _, l_Entity in pairs(l_Entities) do
        if l_Entity ~= nil then
            print('Destroying: ' ..p_EntityType)
            l_Entity:Destroy()
        end
    end
end

function kPMClient:OnPlayerRespawn(p_Player)
    -- Validate player
    if p_Player == nil then
        return
    end

end

function kPMClient:OnPlayerKilled(p_Player)
    -- Validate player
    if p_Player == nil then
        return
    end
    
    print('OnPlayerKilled')
end

function kPMClient:OnPlayerDeleted(p_Player)
    -- Validate player
    if p_Player == nil then
        return
    end

    print('OnPlayerDeleted')
end

function kPMClient:IsPlayerInsideThePlantZone()
    local l_LevelName = LevelNameHelper:GetLevelName()
    if l_LevelName == nil then
        return false
    end

    local localPlayer = PlayerManager:GetLocalPlayer()
    if localPlayer == nil then
        return false
    end

    -- Check to see if the player is alive
    if localPlayer.alive == false then
        return false
    end

    -- Get the local soldier instance
    local localSoldier = localPlayer.soldier
    if localSoldier == nil then
        return false
    end

    -- Get the soldier LinearTransform
    local soldierLinearTransform = localSoldier.worldTransform

    -- Get the position vector
    local position = soldierLinearTransform.trans

    -- print("A: " .. position:Distance(MapsConfig[l_LevelName]["PLANT_A"]["POS"].trans))
    -- print("B: " .. position:Distance(MapsConfig[l_LevelName]["PLANT_B"]["POS"].trans))

    if position:Distance(MapsConfig[l_LevelName]["PLANT_A"]["POS"].trans) <= MapsConfig[l_LevelName]["PLANT_A"]["RADIUS"] or
    position:Distance(MapsConfig[l_LevelName]["PLANT_B"]["POS"].trans) <= MapsConfig[l_LevelName]["PLANT_A"]["RADIUS"] then
        return true
    end
end

return kPMClient()
