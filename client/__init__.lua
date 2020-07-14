-- Start the client initialization
print("client initialization")

-- ==========
-- Console Commands
-- ==========

-- Register console commands for users to lerverage
g_PositionCommand = Console:Register("kpm_player_pos", "Displays the current player position", function(args)
    -- If we have any arguments, ignore them
    if #args != 0 then
        return "invalid command"
    end

    -- Get the local player
    local localPlayer = PlayerManager:GetLocalPlayer()
    if localPlayer == nil then
        return "invalid command"
    end

    -- Check to see if the player is alive
    if localPlayer.alive == false then
        return "invalid command"
    end

    -- Get the local soldier instance
    local localSoldier = localPlayer.soldier
    if localSoldier == nil then
        return "invalid command"
    end

    -- Get the soldier LinearTransform
    local soldierLinearTransform = localSoldier.worldTransform

    -- Get the position vector
    local position = soldierLinearTransform.trans

    -- Return the formatted string (x, y, z)
    return "(" .. position.x .. ", " .. position.y .. ", " .. position.z .. ")"
end)