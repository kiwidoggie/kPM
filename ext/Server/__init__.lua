class "kPMServer"

require ("__shared/kPMConfig")
require ("__shared/GameStates")
require ("__shared/Utils")

require ("Team")
require ("WeaponDefinitions")
require ("LoadoutManager")
require ("LoadoutDefinitions")
require ("Match")

function kPMServer:__init()
    print("server initialization")

    -- Register all of our needed events
    self:RegisterEvents()

    -- Hold gamestate information
    self.m_GameState = GameStates.None

    -- Create our team information
    self.m_Attackers = Team(TeamId.Team2, "Attackers", "") -- RUS
    self.m_Defenders = Team(TeamId.Team1, "Defenders", "") -- US

    -- Loadout manager
    self.m_LoadoutManager = LoadoutManager()

    -- Create a new match
    self.m_Match = Match(self, self.m_Attackers, self.m_Defenders, kPMConfig.MatchDefaultRounds, self.m_LoadoutManager)

    -- Ready up tick
    self.m_RupTick = 0.0

    -- Name update
    self.m_NameTick = 0.0

    -- Match management
    self.m_AllowedGuids = { }

    -- Callbacks
    self.m_MatchStateCallbacks = { }
end

function kPMServer:RegisterEvents()
    -- Engine tick
    self.m_EngineUpdateEvent = Events:Subscribe("Engine:Update", self, self.OnEngineUpdate)

    -- Player join/leave
    self.m_PlayerRequestJoinHook = Hooks:Install("Player:RequestJoin", 1, self, self.OnPlayerRequestJoin)

    self.m_PlayerJoiningEvent = Events:Subscribe("Player:Joining", self, self.OnPlayerJoining)
    self.m_PlayerLeaveEvent = Events:Subscribe("Player:Left", self, self.OnPlayerLeft)

    -- Team management
    self.m_PlayerFindBestSquadHook = Hooks:Install("Player:FindBestSquad", 1, self, self.OnPlayerFindBestSquad)
    self.m_PlayerSelectTeamHook = Hooks:Install("Player:SelectTeam", 1, self, self.OnPlayerSelectTeam)

    -- Round management
    
    -- Damage hooks
    self.m_SoldierDamageHook = Hooks:Install("Soldier:Damage", 1, self, self.OnSoldierDamage)
    
    -- Replaced by the vu.SuppressionMultiplier 0 server command
    -- should also use vu.SunFlareEnabled 0
    -- + vu.DestructionEnabled 0 too, IDK
    -- + vu.ColorCorrectionEnabled 0
    --self.m_ServerSuppressEnemies = Hooks:Install("Server:SupressEnemies", 1, self, self.OnServerSuppressEnemies)

    -- Events from the client
    self.m_ToggleRupEvent = NetEvents:Subscribe("kPM:ToggleRup", self, self.OnToggleRup)
    -- TODO: This is a debug only function
    self.m_ForceToggleRupEvent = NetEvents:Subscribe("kPM:ForceToggleRup", self, self.OnForceToggleRup)
    self.m_PlayerConnectedEvent = NetEvents:Subscribe("kPM:PlayerConnected", self, self.OnPlayerConnected)
    self.m_PlayerSetSelectedTeamEvent = NetEvents:Subscribe("kPM:PlayerSetSelectedTeam", self, self.OnPlayerSetSelectedTeam)
    self.m_PlayerSetSelectedKitEvent = NetEvents:Subscribe("kPM:PlayerSetSelectedKit", self, self.OnPlayerSetSelectedKit)

    -- Chat events
    self.m_PlayerChatEvent = Events:Subscribe("Player:Chat", self, self.OnPlayerChat)

    -- Partition events
    self.m_PartitionLoadedEvent = Events:Subscribe("Partition:Loaded", self, self.OnPartitionLoaded)

    -- Level destroyed event
    self.m_LevelDestroyedEvent = Events:Subscribe("Level:Destroy", self, self.OnLevelDestroyed)
end

function kPMServer:OnEngineUpdate(p_DeltaTime, p_SimulationDeltaTime)

    -- Update the match
    self.m_Match:OnEngineUpdate(self.m_GameState, p_DeltaTime)

    -- Check if the name
    if self.m_NameTick >= kPMConfig.MaxNameTick then
        -- Reset the name tick
        self.m_NameTick = 0.0

        local l_PingTable = {}

        -- Iterate all players
        local s_Players = PlayerManager:GetPlayers()
        for l_Index, l_Player in ipairs(s_Players) do
            -- Get the player team and name
            local l_Team = l_Player.teamId
            local l_Name = l_Player.name

            local l_ClanTag = ""
            if l_Team == self.m_Attackers:GetTeamId() then
                l_ClanTag = self.m_Attackers:GetClanTag()
            elseif l_Team == self.m_Defenders:GetTeamId() then
                l_ClanTag = self.m_Defenders:GetClanTag()
            end

            -- Check to make sure the clan tag min length is > 1
            if #l_ClanTag > kPMConfig.MinClanTagLength then
                -- Check if the player name already starts with the clan tag
                local l_Tag = "[" .. l_ClanTag .. "]"

                -- Check if the name starts with the class time
                if Utils.starts_with(l_Name, l_Tag) == false then
                    -- New name
                    local l_NewName = l_Tag .. " " .. l_Name

                    -- Update the player name
                    l_Player.name = l_NewName
                    print("updating " .. l_Name .. " to " .. l_NewName)
                end
            end

            l_PingTable[l_Player.id] = l_Player.ping
            NetEvents:Broadcast('Player:Ping', l_PingTable)
        end
    end
    self.m_NameTick = self.m_NameTick + p_DeltaTime
end

function kPMServer:OnPlayerRequestJoin(p_Hook, p_JoinMode, p_AccountGuid, p_PlayerGuid, p_PlayerName)
    -- TODO: Reject players if a match has started

    -- Ensure that spectators can join the server at will
    if p_JoinMode ~= "player" then
        p_Hook:Return(true)
        return
    end

    -- Handle player joining

    -- If we are in the warmup gamestate or the endgame gamestate then allow players that aren't on the whitelist to join
    if self.m_GameState == GameStates.Warmup or self.m_GameState == GameStates.EndGame or self.m_GameState == GameStates.None then
        p_Hook:Return(true)
        return
    end

    -- Handle players that are already in a match

    print("joinMode: " .. p_JoinMode)
    print("playerName: " .. p_PlayerName)

    --if p_PlayerName ~= "NoFaTe" then
    --    p_Hook:Return(false)
    --end
    for l_Index, l_Guid in ipairs(self.m_AllowedGuids) do
        -- Check if the guid is on the allow list
        if l_Guid == p_AccountGuid then
            -- Allow for reconnects if a player disconnects
            p_Hook:Return(true)
            return
        end
    end

    -- This means that we were not in warmup, endgame, or no gamestate
    -- And a player tried to join a match in progress that wasn't there at the beginning

    p_Hook:Return(false)
end

-- This function takes a snapshot of all players in the server and adds them to the allow list
function kPMServer:UpdateAllowedGuids()
    -- Clear our the previous guids
    self.m_AllowedGuids = { }

    -- Iterate through all players
    local s_Players = PlayerManager:GetPlayers()
    for l_Index, l_Player in ipairs(s_Players) do
        -- Validate the player
        if l_Player == nil then
            if kPMConfig.DebugMode then
                print("err: invalid player at index: " .. l_Index)
            end
            goto update_allowed_guids_continue
        end

        -- Add the account guid to the allowed guid
        table.insert(self.m_AllowedGuids, l_Player.accountGuid)

        -- Debug logging
        if kPMConfig.DebugMode then
            print("added player: " .. tostring(l_Player.name) .. " guid: " .. tostring(l_Player.accountGuid) .. " to the allow list.")
        end

        -- Lua does not have continue statement, so this hack is a workaround
        ::update_allowed_guids_continue::
    end
end

function kPMServer:OnPlayerJoining(p_Name, p_Guid, p_IpAddress, p_AccountGuid)
    -- Here we can send the event to whichever state we are running in
    print("info: player " .. p_Name .. " is joining the server")
end

function kPMServer:OnPlayerConnected(p_Player)
    if p_Player == nil then
        print("err: invalid player tried to connect.")
        return
    end

    -- Send out gamestate information if he reconnects
    NetEvents:SendTo("kPM:GameStateChanged", p_Player, GameStates.None, self.m_GameState)
end

function kPMServer:OnPlayerLeft(p_Player)
    print("info: player " .. p_Player.name .. " has left the server")
end

function kPMServer:OnPlayerSetSelectedTeam(p_Player, p_Team)
    if p_Player == nil or p_Team == nil then
        return
    end
    
    if self.m_GameState == GameStates.None or 
    self.m_GameState == GameStates.Warmup or 
    self.m_GameState == GameStates.NadeTraining or 
    p_Player.teamId == TeamId.TeamNeutral then
        print("info: player " .. p_Player.name .. " has selected " .. p_Team .." team")
        p_Player.teamId = p_Team;
    else
        print("info: player " .. p_Player.name .. " can't change team during the match")
    end
end

function kPMServer:OnPlayerSetSelectedKit(p_Player, p_Data)
    if p_Player == nil or p_Data == nil then
        return
    end

    local l_Data = json.decode(p_Data)

    if Kits[l_Data["class"]] == nil then
        print("err: invalid kit.")
        return
    end
    
    self.m_LoadoutManager:SetPlayerLoadout(p_Player, l_Data)

    if self.m_GameState == GameStates.Warmup or self.m_GameState == GameStates.None or self.m_GameState == GameStates.Strat then
        -- If the current gamestate is Warmup or None we can switch kit instantly
        local l_SoldierBlueprint = ResourceManager:SearchForDataContainer('Characters/Soldiers/MpSoldier')

        if p_Player.soldier ~= nil then
            self.m_Match:KillPlayer(p_Player, false)
        end

        self.m_Match:AddPlayerToSpawnQueue(
            p_Player, 
            self.m_Match:GetRandomSpawnpoint(p_Player), 
            CharacterPoseType.CharacterPoseType_Stand, 
            l_SoldierBlueprint, 
            false,
            self.m_LoadoutManager:GetPlayerLoadout(p_Player)
        )
    end
end

function kPMServer:OnPlayerFindBestSquad(p_Hook, p_Player)
    -- TODO: Force squad
end

function kPMServer:OnPlayerSelectTeam(p_Hook, p_Player, p_Team)
    -- p_Team is R/W
    -- p_Player is RO
end

function kPMServer:OnPartitionLoaded(p_Partition)
    -- Validate our partition
    if p_Partition == nil then
        return
    end

    -- Send event to the loadout manager
    self.m_LoadoutManager:OnPartitionLoaded(p_Partition)
end

function kPMServer:OnSoldierDamage(p_Hook, p_Soldier, p_Info, p_GiverInfo)
    if p_Soldier == nil then
        return
    end

    if p_Info == nil then
        return
    end

    -- TODO: Fixme
    -- If we are in warmup, then disable damage of all kind
    if self.m_GameState == GameStates.None or self.m_GameState == GameStates.Warmup then
        if p_GiverInfo.giver == nil or p_GiverInfo.damageType == DamageType.Suicide then
            return
        end

        p_Info.damage = 0.0
        p_Hook:Pass(p_Soldier, p_Info, p_GiverInfo)
    end
end

function kPMServer:OnToggleRup(p_Player)
    -- Check to see if we have a valid player
    if p_Player == nil then
        print("err: invalid player tried to rup.")
        return
    end

    -- Get the player information
    local s_PlayerName = p_Player.name
    local s_PlayerId = p_Player.id

    -- We only care if we are in warmup state, otherwise rups mean nothing
    if self.m_GameState ~= GameStates.Warmup then
        print("err: player " .. s_PlayerName .. " tried to rup in non-warmup?")
        return
    end

    -- Update the match information
    self.m_Match:OnPlayerRup(p_Player)
end

-- TODO: This is a debug only function
function kPMServer:OnForceToggleRup(p_Player)
    if p_Player == nil then
        print("err: invalid player.")
        return
    end

    local s_PlayerName = p_Player.name
    local s_PlayerId = p_Player.id

    if self.m_GameState ~= GameStates.Warmup then
        return
    end

    self.m_Match:ForceAllPlayerRup()
end

function kPMServer:OnPlayerChat(p_Player, p_RecipientMask, p_Message)
    -- Check the player
    if p_Player == nil then
        return
    end

    -- Check the message
    if p_Message == nil then
        return
    end

    -- Check the length of the message
    if #p_Message <= 0 then
        return
    end

    -- Check for ready up state
    if Utils.starts_with(p_Message, "!warmup") then
        self:ChangeGameState(GameStates.Warmup)
    end

    if Utils.starts_with(p_Message, "!warmuptoknife") then

    end
end

function kPMServer:OnLevelDestroyed()
    -- Forward event to loadout mananager
    self.m_LoadoutManager:OnLevelDestroyed()
end

-- Helper functions
function kPMServer:ChangeGameState(p_GameState)
    if p_GameState < GameStates.None or p_GameState > GameStates.EndGame then
        print("err: attempted to switch to an invalid gamestate.")
        return
    end

    local s_OldGameState = self.m_GameState
    self.m_GameState = p_GameState

    -- Call UpdateAllowedGuids when Warmup ends
    if p_GameState ~= GameStates.Warmup and s_OldGameState == GameStates.Warmup then
        self:UpdateAllowedGuids()
    end

    NetEvents:Broadcast("kPM:GameStateChanged", s_OldGameState, p_GameState)
end

function kPMServer:SetClientTimer(p_Time)
    if p_Time == nil then
        print("err: no time to send to the clients")
        return
    end

    NetEvents:Broadcast("kPM:StartWebUITimer", p_Time)
end

function kPMServer:SetRoundEndInfoBox(p_WinnerTeamId)
    if p_WinnerTeamId == nil then
        print("err: no winner to send to the clients")
        return
    end

    NetEvents:Broadcast("kPM:SetRoundEndInfoBox", p_WinnerTeamId)
end

function kPMServer:SetGameEnd(p_WinnerTeamId)
    -- Watch out, this can be nil if the game is draw
    NetEvents:Broadcast("kPM:SetGameEnd", p_WinnerTeamId)
end

return kPMServer()
