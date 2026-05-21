--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SkillManager = {}

local SkillConfig = require(ReplicatedStorage.GameConfig:WaitForChild("SkillConfig"))
local NetworkEvents = ReplicatedStorage:WaitForChild("NetworkEvents")
local DraftEvent = NetworkEvents:WaitForChild("DraftEvent") :: RemoteEvent

local ActiveDrafts = {}
local PlayersDrafting = 0

-- [[ 1. DRAFT GENERATOR ]]
function SkillManager.TriggerGlobalDraft()
	PlayersDrafting = 0
	
	for _, player in ipairs(Players:GetPlayers()) do
		local availableSkills = {}
		
		-- Filter out maxed skills and duplicate Legendary weapons
		for skillName, skillData in pairs(SkillConfig) do
			local currentStacks = player:GetAttribute("Skill_" .. skillName) or 0
			local canDraft = true
			
			if currentStacks >= skillData.MaxStacks then
				canDraft = false
			end
			
			-- Don't offer a legendary weapon if they already hold it
			if skillData.WeaponGrant then
				local char = player.Character
				local backpack = player:FindFirstChild("Backpack")
				if (char and char:FindFirstChild(skillData.WeaponGrant)) or (backpack and backpack:FindFirstChild(skillData.WeaponGrant)) then
					canDraft = false
				end
			end
			
			if canDraft then
				table.insert(availableSkills, {Name = skillName, Data = skillData})
			end
		end
		
		-- Shuffle and pick 3
		local choices = {}
		for i = 1, 3 do
			if #availableSkills == 0 then break end
			local randIdx = math.random(1, #availableSkills)
			local picked = availableSkills[randIdx]
			
			table.insert(choices, {
				Name = picked.Name,
				Description = picked.Data.Description,
				Rarity = picked.Data.Rarity
			})
			table.remove(availableSkills, randIdx)
		end
		
		if #choices > 0 then
			ActiveDrafts[player.UserId] = choices
			PlayersDrafting += 1
			DraftEvent:FireClient(player, choices)
		end
	end
end

-- Used by WaveManager to know when to unpause the game
function SkillManager.IsDraftComplete()
	return PlayersDrafting <= 0
end

-- [[ 2. DRAFT LISTENER ]]
DraftEvent.OnServerEvent:Connect(function(player: Player, skillName: string)
	local choices = ActiveDrafts[player.UserId]
	if not choices then return end
	
	-- Anti-Exploit: Verify they actually picked one of their 3 options
	local isValid = false
	for _, choice in ipairs(choices) do
		if choice.Name == skillName then isValid = true; break end
	end
	
	if not isValid then return end
	
	-- Lock their choice in
	ActiveDrafts[player.UserId] = nil
	PlayersDrafting -= 1
	
	local currentStacks = player:GetAttribute("Skill_" .. skillName) or 0
	player:SetAttribute("Skill_" .. skillName, currentStacks + 1)
	
	print("🃏 " .. player.Name .. " drafted: [" .. skillName .. "] (Stack " .. (currentStacks + 1) .. ")")
	
	-- [[ HANDLE EPIC WEAPON GRANTS ]]
	local skillData = SkillConfig[skillName]
	if skillData and skillData.WeaponGrant then
		-- We will store Legendary weapons in ReplicatedStorage.Weapons
		local weaponFolder = ReplicatedStorage:FindFirstChild("Weapons")
		if weaponFolder then
			local weaponToGive = weaponFolder:FindFirstChild(skillData.WeaponGrant)
			if weaponToGive then
				local clone = weaponToGive:Clone()
				clone.Parent = player:WaitForChild("Backpack")
			end
		end
	end
end)

-- Clean up if a player leaves mid-draft so the wave doesn't pause forever
Players.PlayerRemoving:Connect(function(player)
	if ActiveDrafts[player.UserId] then
		ActiveDrafts[player.UserId] = nil
		PlayersDrafting -= 1
	end
end)

return SkillManager