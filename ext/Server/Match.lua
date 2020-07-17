class "Match"

function Match:__init(p_Team1, p_Team2, p_RoundCount)
    self.m_Team1 = p_Team1
    self.m_Team2 = p_Team2

    self.m_RoundCount = p_RoundCount

    -- Keep track of ready up status
    -- This uses the (PlayerId, bool) to prevent memory references
    self.m_ReadyUpState = { }
end

-- ==========
-- Engine Callbacks
-- ==========
function Match:OnUpdate(p_DeltaTime, p_SimulationDeltaTime)
end

-- ==========
-- Logic Update Callbacks
-- ==========

function Match:OnWarmup(p_DeltaTime)
    -- Iterate through all of the teams and check if everyone is rup'd
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

    -- Check to see if all players in-game have *some* kind of rup state
    if s_TotalPlayerCount ~= #self.m_ReadyUpState then
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