class "kPMServer"

require ("__shared/kPMConfig")
require ("__shared/GameStates")
require ("__shared/Utils")

require ("Team")

require ("Match")

function kPMServer:__init()
    print("server initialization")

    -- Register all of our needed events
    self:RegisterEvents()

    -- Hold gamestate information
    self.m_GameState = GameStates.None

    -- Create our team information
    self.m_Team1 = Team(TeamId.Team1, "Attackers", "nK")
    self.m_Team2 = Team(TeamId.Team2, "Defenders", "mTw")

    -- Create a new match
    self.m_Match = Match(self, self.m_Team1, self.m_Team2, kPMConfig.MatchDefaultRounds)

    -- Ready up tick
    self.m_RupTick = 0.0

    -- Name update
    self.m_NameTick = 0.0

    -- Loadout manager
    self.m_LoadoutManager = LoadoutManager()
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
    self.m_ServerSuppressEnemies = Hooks:Install("Server:SupressEnemies", 1, self, self.OnServerSuppressEnemies)

    -- Events from the client
    self.m_ToggleRupEvent = NetEvents:Subscribe("kPM:ToggleRup", self, self.OnToggleRup)

    -- Chat events
    self.m_PlayerChatEvent = Events:Subscribe("Player:Chat", self, self.OnPlayerChat)

    -- Partition events
    self.m_PartitionLoadedEvent = Events:Subscribe("Partition:Loaded", self, self.OnPartitionLoaded)

    -- Level destroyed event
    self.m_LevelDestroyedEvent = Events:Subscribe("Level:Destroy", self, self.OnLevelDestroyed)
end

function kPMServer:OnEngineUpdate(p_DeltaTime, p_SimulationDeltaTime)
    -- TODO: Implement time related functionaity
    if self.m_GameState == GameStates.Warmup then
        self.m_Match:OnWarmup(p_DeltaTime)
    elseif self.m_GameState == GameStates.EndGame then
    end

    -- Check if the name
    if self.m_NameTick >= kPMConfig.MaxNameTick then
        -- Reset the name tick
        self.m_NameTick = 0.0

        -- Iterate all players
        local s_Players = PlayerManager:GetPlayers()
        for l_Index, l_Player in ipairs(s_Players) do
            -- Get the player team and name
            local l_Team = l_Player.teamId
            local l_Name = l_Player.name

            local l_ClanTag = ""
            if l_Team == TeamId.Team1 then
                l_ClanTag = self.m_Team1:GetClanTag()
            elseif l_Team == TeamId.Team2 then
                l_ClanTag = self.m_Team2:GetClanTag()
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

    p_Hook:Return(true)
end

function kPMServer:OnPlayerJoining(p_Name, p_Guid, p_IpAddress, p_AccountGuid)
    -- Here we can send the event to whichever state we are running in
    print("info: player " .. p_Name .. " is joining the server")
end

function kPMServer:OnPlayerLeft(p_Player)
    print("info: player " .. p_Player.name .. " has left the server")
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

    -- If we are in warmup, then disable damage of all kind
    if self.m_GameState == GameStates.None or self.m_GameState == GameStates.Warmup then
        p_Info.damage = 0.0
        p_Hook:Pass(p_Soldier, p_Info, p_GiverInfo)
    end
end

function kPMServer:OnServerSuppressEnemies(p_Hook, p_SupressionMultiplier)
    -- Man if you don't get this bullshit outa here
    p_SupressionMultiplier = 0.0
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
    if Utils.starts_with(p_Message, "!rup") then
    end

    if Utils.starts_with(p_Message, "!warmup") then
        self:ChangeGameState(GameStates.Warmup)
    end

    if Utils.starts_with(p_Message, "!first") then
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

    NetEvents:Broadcast("kPM:GameStateChanged", s_OldGameState, p_GameState)
end

function kPMServer:SpawnPlayer(p_Player)
    -- Validate our player
    if p_Player == nil then
        return
    end
end

return kPMServer()