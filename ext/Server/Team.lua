local Team = class("Team")

require ("__shared/kPMConfig")

function Team:__init(p_TeamId, p_TeamName, p_ClanTag)
    -- Check that we have a valid team
    if p_TeamId <= TeamId.TeamNeutral then
        print("err: invalid team id.")
        return
    end

    if p_TeamId >= TeamId.TeamIdCount then
        print("err: invalid team id.")
        return
    end

    if #p_TeamName == 0 or #p_TeamName > kPMConfig.MaxTeamNameLength then
        print("err: invalid team name")
        return
    end

    if #p_ClanTag > kPMConfig.MaxClanTagLength then
        print("err: invalid clantag length")
        return
    end

    -- Set our team information
    self.m_TeamId = p_TeamId
    self.m_Name = p_TeamName
    self.m_ClanTag = p_ClanTag

    self.m_RoundsWon = { }
    self.m_RoundsLost = { }
    self.m_RoundsPlayed = 0
end

function Team:GetClanTag()
    return self.m_ClanTag
end

function Team:GetTeamId()
    return self.m_TeamId
end

function Team:GetName()
    return self.m_Name
end

function Team:UpdateTeamId(p_TeamId)
    -- Check that we have a valid team
    if p_TeamId <= TeamId.TeamNeutral then
        print("err: invalid team id.")
        return
    end

    if p_TeamId >= TeamId.TeamIdCount then
        print("err: invalid team id.")
        return
    end

    -- Update the team id
    self.m_TeamId = p_TeamId

    -- Debugging information
    if kPMConfig.DebugMode then
        print("updated team: " .. self.m_Name .. " team id to " .. p_TeamId)
    end
end

function Team:RoundWon(p_RoundNumber)
    table.insert(self.m_RoundsWon, p_RoundNumber)
    self.m_RoundsPlayed = self.m_RoundsPlayed + 1
end

function Team:RoundLost(p_RoundNumber)
    table.insert(self.m_RoundsLost, p_RoundNumber)
    self.m_RoundsPlayed = self.m_RoundsPlayed + 1
end

function Team:RoundReset()
    self.m_RoundsLost = { }
    self.m_RoundsWon = { }
    self.m_RoundsPlayed = 0
end

return Team