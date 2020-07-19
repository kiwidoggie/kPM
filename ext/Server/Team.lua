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
end

function Team:GetClanTag()
    return self.m_ClanTag
end

return Team