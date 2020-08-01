local Match = class("Match")
require ("__shared/GameStates")


function Match:__init(p_Server, p_Team1, p_Team2, p_RoundCount)
    self.m_Server = p_Server
    self.m_Team1 = p_Team1
    self.m_Team2 = p_Team2

    self.m_RoundCount = p_RoundCount

    --[[
        Ready Up
    --]]
    self.m_RupTick = 0.0

    -- Keep track of ready up status
    -- This uses the (PlayerId, bool) to prevent memory references
    self.m_ReadyUpState = { }

    -- Last game state (so if we are going to timeout->gameplay we know which half we are in)
    self.m_LastState = GameStates.None
end

-- ==========
-- Logic Update Callbacks
-- ==========

function Match:OnWarmup(p_DeltaTime)
    -- Check to see if the current time is greater or equal than our max
    if self.m_RupTick >= kPMConfig.MaxRupTick then
        self.m_RupTick = 0.0

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
    self.m_RupTick = self.m_RupTick + p_DeltaTime
end

function Match:OnKnifeRound(p_DeltaTime)
    -- Kill all alive players
    local s_Players = PlayerManager:GetPlayers()
    for l_Index, l_Player in ipairs(s_Players) do
        -- Validate our player
        if l_Player == nil then
            goto _knife_continue_
        end

        -- Disable players ability to spawn
        l_Player.isAllowedToSpawn = false

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

    -- Respawn player
    for l_Index, l_Player in ipairs(s_Players) do
    end
end

-- Shamelessly stolen and modified from https://github.com/BF3RM


function Match:OnFirstHalf(p_DeltaTime)
end

function Match:OnHalfTime(p_DeltaTime)
end

function Match:OnSecondHalf(p_DeltaTime)
end

function Match:OnTimeout(p_DeltaTime)
end

function Match:OnStrat(p_DeltaTime)
end

function Match:OnEndGame(p_DeltaTime)
end

function Match:ClearReadyUpState()
    -- Clear out all ready up state entries
    self.m_ReadyUpState = { }
end

function Match:CreateReadyUpState()
    -- Iterates through all players and ensures they have been added to the ready up state
    -- TODO: See if this is the bestt way to do this
end

function Match:OnPlayerRup(p_Player)
    if p_Player == nil then
        print("err: invalid player tried to rup.")
        return
    end

    -- Get the player id
    local s_PlayerId = p_Player.id

    -- Player does not exist in our ready up state yet
    if self.m_ReadyUpState[s_PlayerId] == nil then
        self.m_ReadyUpState[s_PlayerId] = true
        print("info: player " .. p_Player.name .. " ready up!")
        return
    end

    -- Player has already been added, but has not readied up yet
    if self.m_ReadyUpState[s_PlayerId] == false then
        self.m_ReadyUpState[s_PlayerId] = true
        print("info: player " .. p_Player.name .. " ready up!")
        return
    end

    -- If the player was previously readied and now is unready
    if self.m_ReadyUpState[s_PlayerId] == true then
        self.m_ReadyUpState[s_PlayerId] = false
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
        if self.m_ReadyUpState[l_PlayerId] == nil then
            return false
        end

        -- Is this player not readied up
        if self.m_ReadyUpState[l_PlayerId] == false then
            return false
        end
    end

    -- All conditions passed, all players are readied up
    return true
end

function Match:IsPlayerRup(p_PlayerId)
    local s_PlayerId = p_PlayerId

     -- Player does not exist in our ready up state yet
    if self.m_ReadyUpState[s_PlayerId] == nil then
        return false
    end

    -- Player has already been added, but has not readied up yet
    return self.m_ReadyUpState[s_PlayerId] == true
end


return Match