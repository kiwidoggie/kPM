local Match = class("Match")
require ("__shared/GameStates")


function Match:__init(p_Server, p_Team1, p_Team2, p_RoundCount)
    -- Save server reference
    self.m_Server = p_Server

    self.m_Attackers = p_Team1
    self.m_Defenders = p_Team2

    -- Number of rounds to play in total (divide by 2 for rounds per half)
    self.m_RoundCount = p_RoundCount

    -- The current round being played, starts at 1, value of 0 means invalid
    self.m_CurrentRound = 0

    -- Keep track of ready up status
    -- This uses the (PlayerId, bool) to prevent memory references
    self.m_ReadyUpPlayers = { }

    -- Last game state (so if we are going to timeout->gameplay we know which half we are in)
    self.m_CurrentState = GameStates.None
    self.m_LastState = GameStates.None

    -- State callbacks
    self.m_UpdateStates = { }
    self.m_UpdateStates[GameStates.Warmup] = self.OnWarmup
    self.m_UpdateStates[GameStates.WarmupToKnife] = self.OnWarmupToKnife

    -- State ticks
    self.m_UpdateTicks = { }

    -- Initialize all states to 0.0
    for i = 0, 1, GameStates.Max do
        self.m_UpdateTicks[i] = 0.0
    end
end

-- ==========
-- Logic Update Callbacks
-- ==========

function Match:OnEngineUpdate(p_GameState, p_DeltaTime)
    local s_Callback = self.m_UpdateStates[p_GameState]
    if s_Callback == nil then
        return
    end

    if self.m_CurrentState ~= p_GameState then
        if kPMConfig.DebugMode then
            print("transitioning from " .. self.m_LastState .. " to " .. p_GameState)
        end
        self.m_LastState = self.m_CurrentState
    end

    self.m_CurrentState = p_GameState

    s_Callback(p_DeltaTime)
end

function Match:OnWarmup(p_DeltaTime)
    -- Check to see if the current time is greater or equal than our max
    if self.m_UpdateTicks[GameStates.Warmup] >= kPMConfig.MaxRupTick then
        self.m_UpdateTicks[GameStates.Warmup] = 0.0

        -- Check if all players are readied up
        if self:IsAllPlayersRup() then
            -- First change the game state so we have no logic running
            self.m_Server:ChangeGameState(GameStates.None)
            ChatManager:Yell("All players have readied up, starting knife round...", 2.0)

            -- Handle resetting all players or spawning them
            self.m_Server:ChangeGameState(GameStates.KnifeRound)
        end

        -- Update status to all players
        local s_Players = PlayerManager:GetPlayers()
        for l_Index, l_Player in ipairs(s_Players) do
            -- Check if this specific player is readied up
            local l_PlayerRup = self:IsPlayerRup(l_Player.id)
            
            -- Send to client to update WebUI
            NetEvents:SendTo("kPM:RupStateChanged", l_Player, 1, l_PlayerRup)
        end
    end

    -- Add the delta time to our rup timer
    self.m_UpdateTicks[GameStates.Warmup] = self.m_UpdateTicks[GameStates.Warmup] + p_DeltaTime
end

function Match:OnWarmupToKnife(p_DeltaTime)
    -- TODO: Disable knife canned animations

    -- Kill all alive players
    local s_Players = PlayerManager:GetPlayers()
    for l_Index, l_Player in ipairs(s_Players) do
        -- Validate our player
        if l_Player == nil then
            goto _knife_continue_
        end

        -- Disable players ability to spawn
        l_Player.isAllowedToSpawn = false

        -- If the player is not alive skip on
        if not l_Player.alive then
            goto _knife_continue_
        end

        -- Get out soldier
        local l_Soldier = l_Player.soldier
        local l_Corpse = l_Player.corpse
        local l_Name = l_Player.name

        -- Validate our soldier
        if l_Soldier ~= nil then
            print("killing soldier " .. l_Name)
            l_Soldier:Kill()
        end

        -- If the player is a corpse force dead
        if l_Corpse ~= nil then
            print("killing corpse " .. l_Name)
            l_Corpse:ForceDead()
        end

        ::_knife_continue_::
    end


    -- If we have reached the maximum time here
    if self.m_UpdateTicks[GameStates.WarmupToKnife] >= kPMConfig.MaxTransititionTime then
        self.m_UpdateTicks[GameStates.WarmupToKnife] = 0.0

        -- TODO: Force all players to respawn with a knife only kit
        -- TODO: Transitition to the next game state
        self.m_Server:ChangeGameState(GameStates.KnifeRound)
    end

    -- Update the tick
    self.m_UpdateTicks[GameStates.WarmupToKnife] = self.m_UpdateTicks[GameStates.WarmupToKnife] + p_DeltaTime
end

function Match:OnKnifeRound(p_DeltaTime)
    if self.m_Attackers == nil then
        print("could not find attackers")
        return
    end

    if self.m_Defenders == nil then
        print("could not find defenders")
        return
    end

    local s_AttackerAliveCount = 0
    local s_DefenderAliveCount = 0

    local s_AttackerTotalCount = 0
    local s_DefenderTotalCount = 0

    local s_AttackerDeadCount = 0
    local s_DefenderDeadCount = 0

    -- Get the attacker and defender team ids
    local s_AttackerId = self.m_Attackers:GetTeamId()
    local s_DefenderId = self.m_Defenders:GetTeamId()

    -- Iterate and check alive status
    local s_Players = PlayerManager:GetPlayers()
    for l_Index, l_Player in ipairs(s_Players) do
        -- Validate player
        if l_Player == nil then
            goto _on_knife_round_continue_
        end

        local s_Team = l_Player.teamId

        if not l_Player.alive then
            if s_Team == s_AttackerId then
                s_AttackerDeadCount = s_AttackerDeadCount + 1
            elseif s_Team == s_DefenderId then
                s_DefenderDeadCount = s_DefenderDeadCount + 1
            end
        else
            if s_Team == s_AttackerId then
                s_AttackerAliveCount = s_AttackerAliveCount + 1
            elseif s_Team == s_DefenderId then
                s_DefenderAliveCount = s_DefenderAliveCount + 1
            end
        end

        if s_Team == s_AttackerId then
            s_AttackerTotalCount = s_AttackerTotalCount + 1
        elseif s_Team == s_DefenderId then
            s_DefenderTotalCount = s_DefenderTotalCount + 1
        end
        ::_on_knife_round_continue_::
    end

    -- Check the round state
    local s_Winner = TeamId.TeamNeutral
    if s_AttackerTotalCount > 0 and s_AttackerAliveCount == 0 then
        -- If all attackers have been eliminated
        s_Winner = s_DefenderId
    elseif s_DefenderTotalCount > 0 and s_DefenderAliveCount == 0 then
        -- All defenders have been eliminated
        s_Winner = s_AttackerId
    end

    -- Check to see if we have triggered a round end
    if self.m_UpdateTicks[GameStates.KnifeRound] > kPMConfig.MaxKnifeRoundTime then
        self.m_UpdateTicks[GameStates.KnifeRound] = 0.0

        -- Trigger
        if s_Winner == TeamId.TeamNeutral then
            print("no team won? this is probably an error")
            return
        end

        -- Change the game state to the first half
        self.m_Server:ChangeGameState(GameStates.FirstHalf)
        return
    end

    if s_AttackerAliveCount > s_DefenderAliveCount then
        print("attackers win")
    end
end

-- Shamelessly stolen and modified from https://github.com/BF3RM

function Match:SwitchTeams()
    -- Save and swap the attackers and defenders
    local s_OldAttackers = self.m_Attackers
    local s_OldDefenders = self.m_Defenders

    self.m_Attackers = s_OldDefenders
    self.m_Defenders = s_OldAttackers

    print("switched teams")
end

function Match:OnFirstHalf(p_DeltaTime)
end

function Match:OnHalfTime(p_DeltaTime)
end

function Match:OnSecondHalf(p_DeltaTime)
end

function Match:OnTimeout(p_DeltaTime)
end

function Match:OnStrat(p_DeltaTime)
    if self.m_UpdateTicks[GameStates.Strat] > kPMConfig.MaxStratTime then
        self.m_UpdateTicks[GameStates.Strat] = 0.0

        -- Check the previous state
        local s_LastState = self.m_LastState
        if s_LastState ~= GameStates.KnifeToFirst and s_LastState ~= GameStates.HalfToSecond and s_LastState ~= GameStates.FirstHalf and s_LastState ~= GameStates.SecondHalf then
            print("ERROR coming from invalid state: " .. s_LastState)
            return
        end

        self.m_Server:ChangeGameState(s_LastState)
        return
    end

    -- Update the strat tick counter
    self.m_UpdateTicks[GameStates.Strat] = self.m_UpdateTicks[GameStates.Strat] + p_DeltaTime
end

function Match:OnEndGame(p_DeltaTime)
end

function Match:ClearReadyUpState()
    -- Clear out all ready up state entries
    self.m_ReadyUpPlayers = { }
end

function Match:OnPlayerRup(p_Player)
    if p_Player == nil then
        print("err: invalid player tried to rup.")
        return
    end

    -- Get the player id
    local s_PlayerId = p_Player.id

    -- Player does not exist in our ready up state yet
    if self.m_ReadyUpPlayers[s_PlayerId] == nil then
        self.m_ReadyUpPlayers[s_PlayerId] = true
        print("info: player " .. p_Player.name .. " ready up!")
        return
    end

    -- Player has already been added, but has not readied up yet
    if self.m_ReadyUpPlayers[s_PlayerId] == false then
        self.m_ReadyUpPlayers[s_PlayerId] = true
        print("info: player " .. p_Player.name .. " ready up!")
        return
    end

    -- If the player was previously readied and now is unready
    if self.m_ReadyUpPlayers[s_PlayerId] == true then
        self.m_ReadyUpPlayers[s_PlayerId] = false
        print("info: player " .. p_Player.name .. " unready up :(")
        return
    end
end

function Match:IsAllPlayersRup()
    -- Get the player count
    local s_TotalPlayerCount = PlayerManager:GetPlayerCount()

    -- Check to make sure that we have enough players to start
    if s_TotalPlayerCount < kPMConfig.MinPlayerCount then
        return false
    end

    -- Get all players in the server
    local s_Players = PlayerManager:GetPlayers()

    -- Iterate over all players and check the rup state
    for l_Index, l_Player in ipairs(s_Players) do
        -- Check that the player is valid
        if l_Player == nil then
            print("err: invalid player in player manager.")
            return false
        end

        -- Get the player id
        local l_PlayerId = l_Player.id

        -- Check to see if this player has *any* rup state
        if self.m_ReadyUpPlayers[l_PlayerId] == nil then
            return false
        end

        -- Is this player not readied up
        if self.m_ReadyUpPlayers[l_PlayerId] == false then
            return false
        end
    end

    -- All conditions passed, all players are readied up
    return true
end

function Match:IsPlayerRup(p_PlayerId)
    local s_PlayerId = p_PlayerId

     -- Player does not exist in our ready up state yet
    if self.m_ReadyUpPlayers[s_PlayerId] == nil then
        return false
    end

    -- Player has already been added, but has not readied up yet
    return self.m_ReadyUpPlayers[s_PlayerId] == true
end


return Match