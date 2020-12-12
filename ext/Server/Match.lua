local Match = class("Match")
require ("__shared/MapsConfig")
require ("__shared/GameStates")
require ("__shared/kPMConfig")
require ("LoadoutManager")
require ("LoadoutDefinitions")
require ("__shared/LevelNameHelper")

function Match:__init(p_Server, p_Team1, p_Team2, p_RoundCount, p_LoadoutManager)
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
    self.m_UpdateStates[GameStates.KnifeRound] = self.OnKnifeRound
    self.m_UpdateStates[GameStates.KnifeToFirst] = self.OnKnifeToFirst

    -- State ticks
    self.m_UpdateTicks = { }
    self.m_UpdateTicks[GameStates.None] = 0.0
    self.m_UpdateTicks[GameStates.Warmup] = 0.0
    self.m_UpdateTicks[GameStates.WarmupToKnife] = 0.0
    self.m_UpdateTicks[GameStates.KnifeRound] = 0.0
    self.m_UpdateTicks[GameStates.KnifeToFirst] = 0.0
    self.m_UpdateTicks[GameStates.FirstHalf] = 0.0
    self.m_UpdateTicks[GameStates.FirstToHalf] = 0.0
    self.m_UpdateTicks[GameStates.HalfTime] = 0.0
    self.m_UpdateTicks[GameStates.HalfToSecond] = 0.0
    self.m_UpdateTicks[GameStates.SecondHalf] = 0.0
    self.m_UpdateTicks[GameStates.Timeout] = 0.0
    self.m_UpdateTicks[GameStates.Strat] = 0.0
    self.m_UpdateTicks[GameStates.NadeTraining] = 0.0
    self.m_UpdateTicks[GameStates.EndGame] = 0.0

    self.m_LoadoutManager = p_LoadoutManager

    print("init: " .. self.m_UpdateTicks[GameStates.EndGame])
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

    s_Callback(self, p_DeltaTime)
end

function Match:OnWarmup(p_DeltaTime)
    -- Check to see if the current time is greater or equal than our max
    if self.m_UpdateTicks[GameStates.Warmup] >= kPMConfig.MaxRupTick then
        self.m_UpdateTicks[GameStates.Warmup] = 0.0

        -- Check if all players are readied up
        if self:IsAllPlayersRup() then
            -- First change the game state so we have no logic running
            self.m_Server:ChangeGameState(GameStates.None)
            --ChatManager:Yell("All players have readied up, starting knife round...", 2.0)

            -- Handle resetting all players or spawning them
            self.m_Server:ChangeGameState(GameStates.WarmupToKnife)
        end

        -- Update status to all players
        local s_Players = PlayerManager:GetPlayers()
        for l_Index, l_Player in ipairs(s_Players) do
            -- Check if this specific player is readied up
            local l_PlayerRup = self:IsPlayerRup(l_Player.id)
            
            -- Send to client to update WebUI
            NetEvents:SendTo("kPM:RupStateChanged", l_Player, self:GetPlayerNotRupCount(), l_PlayerRup)
        end
    end

    -- Add the delta time to our rup timer
    self.m_UpdateTicks[GameStates.Warmup] = self.m_UpdateTicks[GameStates.Warmup] + p_DeltaTime
end

function Match:OnWarmupToKnife(p_DeltaTime)
    -- TODO: Disable knife canned animations

    -- Kill all players disabling their ability to spawn
    self:KillAllPlayers(false)

    -- If we have reached the maximum time here
    if self.m_UpdateTicks[GameStates.WarmupToKnife] >= kPMConfig.MaxTransititionTime then
        self.m_UpdateTicks[GameStates.WarmupToKnife] = 0.0

        if kPMConfig.DebugMode then
            print("WarmupToKnife completed, switching to knife round")
        end

        self:SpawnAllPlayers(true)

        -- Tried this to remove the animated melee attack, not really working
        -- self:FireEventForSpecificEntity("ServerMeleeEntity", "DisableMeleeTarget")

        -- TODO: Force all players to respawn with a knife only kit
        -- TODO: Transitition to the next game state
        self.m_Server:ChangeGameState(GameStates.KnifeRound)
    end

    -- Update the tick
    self.m_UpdateTicks[GameStates.WarmupToKnife] = self.m_UpdateTicks[GameStates.WarmupToKnife] + p_DeltaTime
end

function Match:GetPlayerCounts()
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

    return s_AttackerAliveCount, s_AttackerDeadCount, s_AttackerTotalCount, s_DefenderAliveCount, s_DefenderDeadCount, s_DefenderTotalCount
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

    local s_AttackerId = self.m_Attackers:GetTeamId()
    local s_DefenderId = self.m_Defenders:GetTeamId()

    local s_AttackerAliveCount, s_AttackerDeadCount, s_AttackerTotalCount, s_DefenderAliveCount, s_DefenderDeadCount, s_DefenderTotalCount = self:GetPlayerCounts()

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
        self.m_Server:ChangeGameState(GameStates.KnifeToFirst)
        return
    end
end

function Match:OnKnifeToFirst(p_DeltaTime)
    -- Kill all players before the first round
    self:KillAllPlayers(false)

    if self.m_UpdateTicks[GameStates.KnifeToFirst] > kPMConfig.MaxTransititionTime then
        self.m_UpdateTicks[GameStates.KnifeToFirst] = 0.0

        -- Spawn all players with their respective loadouts
        self:SpawnAllPlayers(false)

        -- Tried this to remove the animated melee attack
        -- self:FireEventForSpecificEntity("ServerMeleeEntity", "EnableMeleeTarget")

        self.m_Server:ChangeGameState(GameStates.FirstHalf)
        return
    end

    self.m_UpdateTicks[GameStates.KnifeToFirst] = self.m_UpdateTicks[GameStates.KnifeToFirst] + p_DeltaTime
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
    -- Handle the case of when a round first starts, otherwise it will run "normal" code
    if self.m_UpdateTicks[GameStates.FirstHalf] == 0.0 then
        -- Switch to strat time for 5 seconds

        -- Kill all players
        self:KillAllPlayers(false)

        -- Respawn all players
        self:SpawnAllPlayers(false)
        
        -- Manually update the ticks
        self.m_UpdateTicks[GameStates.FirstHalf] = self.m_UpdateTicks[GameStates.FirstHalf] + p_DeltaTime

        -- Switch to strat time, do not touch the FirstHalf timer, this ensures that we pick up "normal" round
        self.m_Server:ChangeGameState(GameStates.Strat)
    end

    -- Get the player counts
    local s_AttackerAliveCount, s_AttackerDeadCount, s_AttackerTotalCount, s_DefenderAliveCount, s_DefenderDeadCount, s_DefenderTotalCount = self:GetPlayerCounts()

    -- The round is running as expected, check the ending conditions

    -- Which are if all attackers are dead
    if s_AttackerAliveCount == 0 then
        print("all attackers are dead, round is over")

        -- Give a round to the defenders
        self.m_Defenders:RoundWon(self.m_CurrentRound)

        -- Give a loss to the attackers
        self.m_Attackers:RoundLoss(self.m_CurrentRound)

        -- Update the round count
        self.m_CurrentRound = self.m_CurrentRound + 1

        -- Set this round to be over
        self.m_UpdateTicks[GameStates.FirstHalf] = kPMConfig.MaxRoundTime + 1.0
        return
    end
    
    -- TODO: If the objectives have been completed

    -- If all defenders are dead
    if s_DefenderAliveCount == 0 then
        print("all defenders are dead, round is over")

        -- Give a loss to the defenders
        self.m_Defenders:RoundLoss(self.m_CurrentRound)

        -- Give a win to the attackers
        self.m_Attackers:RoundWon(self.m_CurrentRound)
        return
    end



    -- If the round is over
    if self.m_UpdateTicks[GameStates.FirstHalf] >= kPMConfig.MaxRoundTime then
        self.m_UpdateTicks[GameStates.FirstHalf] = 0.0

        -- If the defenders have any players alive, they win, simple
        if s_DefenderAliveCount > 0 then
            self.m_Defenders:RoundWon(self.m_CurrentRound)
            self.m_Attackers:RoundLoss(self.m_CurrentRound)
        else
            self.m_Attackers:RoundWon(self.m_CurrentRound)
            self.m_Defenders:RoundLoss(self.m_CurrentRound)
        end

        -- Leave the timer at 0.0 in the same state, it will catch at the top
        -- of this function and enable strat mode
        return
    end

    -- Update the tick
    self.m_UpdateTicks[GameStates.FirstHalf] = self.m_UpdateTicks[GameStates.FirstHalf] + p_DeltaTime
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
        NetEvents:Broadcast('Player:ReadyUpPlayers', self.m_ReadyUpPlayers)
        return
    end

    -- Player has already been added, but has not readied up yet
    if self.m_ReadyUpPlayers[s_PlayerId] == false then
        self.m_ReadyUpPlayers[s_PlayerId] = true
        print("info: player " .. p_Player.name .. " ready up!")
        NetEvents:Broadcast('Player:ReadyUpPlayers', self.m_ReadyUpPlayers)
        return
    end

    -- If the player was previously readied and now is unready
    if self.m_ReadyUpPlayers[s_PlayerId] == true then
        self.m_ReadyUpPlayers[s_PlayerId] = false
        print("info: player " .. p_Player.name .. " unready up :(")
        NetEvents:Broadcast('Player:ReadyUpPlayers', self.m_ReadyUpPlayers)
        return
    end
end

function Match:ForceAllPlayerRup()
    for index, l_Player in pairs(PlayerManager:GetPlayers()) do
		self.m_ReadyUpPlayers[l_Player.id] = true
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

function Match:GetPlayerNotRupCount()
    local l_Count = 0;
    local s_Players = PlayerManager:GetPlayers()
    for l_Index, l_Player in ipairs(s_Players) do
        -- Check that the player is valid
        if l_Player == nil then
            print("err: invalid player in player manager.")
            return 0
        end

        local l_PlayerId = l_Player.id

        if self.m_ReadyUpPlayers[l_PlayerId] == nil or self.m_ReadyUpPlayers[l_PlayerId] == false then
            l_Count = l_Count + 1
        end
    end

    return l_Count
end

function Match:KillAllPlayers(p_IsAllowedToSpawn)
    -- Kill all alive players
    local s_Players = PlayerManager:GetPlayers()
    for l_Index, l_Player in ipairs(s_Players) do
        -- Validate our player
        if l_Player == nil then
            goto _knife_continue_
        end

        -- Kill the player
        self:KillPlayer(l_Player, p_IsAllowedToSpawn)

        ::_knife_continue_::
    end
end

function Match:KillPlayer(p_Player, p_IsAllowedToSpawn)
    if p_Player == nil then
        return
    end

     -- Disable players ability to spawn
     p_Player.isAllowedToSpawn = p_IsAllowedToSpawn

     -- If the player is not alive skip on
     if not p_Player.alive then
         return
     end

     -- Get out soldier
     local l_Soldier = p_Player.soldier
     local l_Corpse = p_Player.corpse
     local l_Name = p_Player.name

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
end

function Match:SpawnAllPlayers(p_KnifeOnly)
    if p_KnifeOnly == nil then
        p_KnifeOnly = false
    end

    self:Cleanup();

    local l_SoldierBlueprint = ResourceManager:SearchForDataContainer('Characters/Soldiers/MpSoldier')

    local s_Players = PlayerManager:GetPlayers()
    for l_Index, l_Player in ipairs(s_Players) do
        -- Validate our player
        if l_Player == nil then
            goto _knife_continue_
        end

        self:SpawnPlayer(
            l_Player, 
            self:GetRandomSpawnpoint(l_Player), 
            CharacterPoseType.CharacterPoseType_Stand, 
            l_SoldierBlueprint, 
            p_KnifeOnly,
            self.m_LoadoutManager:GetPlayerLoadout(l_Player)
        )

        ::_knife_continue_::
    end
end

function Match:SpawnPlayer(p_Player, p_Transform, p_Pose, p_SoldierBp, p_KnifeOnly, p_SelectedKit)
    if p_Player == nil then
        return
    end

    if p_Player.alive then
        return
    end

    if p_Player.soldier ~= nil then
		p_Player.soldier:Kill()
    end

    if p_SelectedKit == nil then
        return
    end

    local l_SoldierAsset = nil
    local l_Appearance = nil
    if p_Player.teamId == TeamId.Team1 then
        -- US
        l_SoldierAsset = ResourceManager:SearchForDataContainer(Kits[p_SelectedKit["Class"]]["DEFENDER"]["KIT"])
        l_Appearance = ResourceManager:SearchForDataContainer(Kits[p_SelectedKit["Class"]]["DEFENDER"]["APPEARANCE"])
    else
        -- RUS
        l_SoldierAsset = ResourceManager:SearchForDataContainer(Kits[p_SelectedKit["Class"]]["ATTACKER"]["KIT"])
        l_Appearance = ResourceManager:SearchForDataContainer(Kits[p_SelectedKit["Class"]]["ATTACKER"]["APPEARANCE"])
    end
    if l_SoldierAsset == nil or l_Appearance == nil then
        return
    end

    if p_KnifeOnly then
        local knife = ResourceManager:SearchForDataContainer('Weapons/Knife/U_Knife')
        p_Player:SelectWeapon(WeaponSlot.WeaponSlot_0, knife, {})
    else
        local l_Loadout = p_SelectedKit.Weapons
        if l_Loadout == nil then
            print("err: something is really wrong here, spawn with a knife then...")
            local knife = ResourceManager:SearchForDataContainer('Weapons/Knife/U_Knife')
            p_Player:SelectWeapon(WeaponSlot.WeaponSlot_0, knife, {})
        end

        local l_WeaponIndex = 0;
        for l_Index, l_LoadoutItem in ipairs(l_Loadout) do
            if l_LoadoutItem == nil then
                goto _weapon_continue_
            end

            local l_Attachments = {}
            if l_WeaponIndex == 0 then
                l_Attachments = p_SelectedKit.Attachments
            end

            p_Player:SelectWeapon(l_WeaponIndex, l_LoadoutItem, l_Attachments)
    
            l_WeaponIndex = l_WeaponIndex + 1;

            ::_weapon_continue_::
        end
    end
    
    p_Player:SelectUnlockAssets(l_SoldierAsset, { l_Appearance })

    local l_SpawnedSoldier = p_Player:CreateSoldier(p_SoldierBp, p_Transform)
    
	p_Player:SpawnSoldierAt(l_SpawnedSoldier, p_Transform, p_Pose)
	p_Player:AttachSoldier(l_SpawnedSoldier)

    return l_SpawnedSoldier
end

function Match:GetRandomSpawnpoint(p_Player)
    if p_Player == nil then
        print("err: no player?")
        return
    end

    local l_LevelName = LevelNameHelper:GetLevelName()
    if l_LevelName == nil then
        print("err: no level??")
        return
    end

    -- TODO: Don't spawn on an already taken spawnpoint
    
    local l_SpawnTrans = nil;
    if p_Player.teamId == TeamId.Team1 then
        l_SpawnTrans = MapsConfig[l_LevelName]["DEF_SPAWNS"][ math.random( #MapsConfig[l_LevelName]["DEF_SPAWNS"] ) ]
    else
        l_SpawnTrans = MapsConfig[l_LevelName]["ATK_SPAWNS"][  math.random( #MapsConfig[l_LevelName]["ATK_SPAWNS"] ) ]
    end

    if l_SpawnTrans == nil then
        return
    end

    return l_SpawnTrans
end

function Match:Cleanup()
    self:CleanupSpecificEntity("ServerPickupEntity")
    NetEvents:Broadcast("kPM:Cleanup", "ClientPickupEntity")

    self:CleanupSpecificEntity("ServerMedicBagEntity")
    self:CleanupSpecificEntity("ServerMedicBagHealingSphereEntity")
    NetEvents:Broadcast("kPM:Cleanup", "ClientMedicBagEntity")
    NetEvents:Broadcast("kPM:Cleanup", "ClientMedicBagHealingSphereEntity")

    self:CleanupSpecificEntity("ServerSupplySphereEntity")
    NetEvents:Broadcast("kPM:Cleanup", "ClientSupplySphereEntity")

    self:CleanupSpecificEntity("ServerExplosionEntity")
    self:CleanupSpecificEntity("ServerExplosionPackEntity")
    NetEvents:Broadcast("kPM:Cleanup", "ClientExplosionEntity")
    NetEvents:Broadcast("kPM:Cleanup", "ClientExplosionPackEntity")

    self:CleanupSpecificEntity("ServerGrenadeEntity")
    NetEvents:Broadcast("kPM:Cleanup", "ClientGrenadeEntity")
end

function Match:CleanupSpecificEntity(p_EntityType)
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

function Match:FireEventForSpecificEntity(p_EntityType, p_EventString)
    if p_EntityType == nil then
        return
    end

    local l_Entities = {}

    local l_Iterator = EntityManager:GetIterator(p_EntityType)
    local l_Entity = l_Iterator:Next()
    while l_Entity do
        l_Entities[#l_Entities+1] = Entity(l_Entity)
        l_Entity = l_Iterator:Next()
    end

    for _, l_Entity in pairs(l_Entities) do
        if l_Entity ~= nil then
            l_Entity:FireEvent(p_EventString)
        end
    end
end

return Match
