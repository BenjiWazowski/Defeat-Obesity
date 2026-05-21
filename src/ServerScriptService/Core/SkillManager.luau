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
-- Helper function to make names safe for Roblox Attributes
local function GetSafeAttributeName(skillName: string)
	return "Skill_" .. string.gsub(skillName, " ", "")
end

function SkillManager.TriggerGlobalDraft()
	PlayersDrafting = 0
	
	for _, player in ipairs(Players:GetPlayers()) do
		local commons = {}
		local epics = {}
		
		-- Separate the skills by rarity
		for skillName, skillData in pairs(SkillConfig) do
			local attrName = GetSafeAttributeName(skillName)
			local currentStacks = player:GetAttribute(attrName) or 0
			local canDraft = true
			
			if currentStacks >= skillData.MaxStacks then canDraft = false end
			
			if skillData.WeaponGrant then
				local char = player.Character
				local backpack = player:FindFirstChild("Backpack")
				if (char and char:FindFirstChild(skillData.WeaponGrant)) or (backpack and backpack:FindFirstChild(skillData.WeaponGrant)) then
					canDraft = false
				end
			end
			
			if canDraft then
				if skillData.Rarity == "Common" then
					table.insert(commons, {Name = skillName, Data = skillData})
				else
					table.insert(epics, {Name = skillName, Data = skillData})
				end
			end
		end
		
		local choices = {}
		for i = 1, 3 do
			-- 90% chance for Common, 10% for Epic
			local isEpicRoll = math.random() <= 0.10
			local pool = (isEpicRoll and #epics > 0) and epics or commons
			if #pool == 0 then pool = (#commons > 0 and commons or epics) end -- Fallback if empty
			if #pool == 0 then break end
			
			local randIdx = math.random(1, #pool)
			local picked = pool[randIdx]
			
			table.insert(choices, {
				Name = picked.Name,
				Description = picked.Data.Description,
				Rarity = picked.Data.Data.Rarity
			})
			table.remove(pool, randIdx)
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
	
	local isValid = false
	for _, choice in ipairs(choices) do
		if choice.Name == skillName then isValid = true; break end
	end
	if not isValid then return end
	
	ActiveDrafts[player.UserId] = nil
	PlayersDrafting -= 1
	
	local attrName = GetSafeAttributeName(skillName)
	local currentStacks = player:GetAttribute(attrName) or 0
	player:SetAttribute(attrName, currentStacks + 1)
	print("🃏 " .. player.Name .. " drafted: [" .. skillName .. "] (Stack " .. (currentStacks + 1) .. ")")
	
	local skillData = SkillConfig[skillName]
	if skillData and skillData.WeaponGrant then
		local weaponFolder = ReplicatedStorage:FindFirstChild("Weapons")
		if weaponFolder then
			local weaponToGive = weaponFolder:FindFirstChild(skillData.WeaponGrant)
			if weaponToGive then
				weaponToGive:Clone().Parent = player:WaitForChild("Backpack")
			end
		end
	end
end)

-- [[ 3. AUTO-DRAFT TIMEOUT ]]
function SkillManager.ForceEndDraft()
	for userId, choices in pairs(ActiveDrafts) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			local randChoice = choices[math.random(1, #choices)]
			
			local attrName = GetSafeAttributeName(randChoice.Name)
			local currentStacks = player:GetAttribute(attrName) or 0
			player:SetAttribute(attrName, currentStacks + 1)
			print("🎲 " .. player.Name .. " auto-drafted: [" .. randChoice.Name .. "] (Timeout)")
			
			local skillData = SkillConfig[randChoice.Name]
			if skillData and skillData.WeaponGrant then
				local weaponFolder = ReplicatedStorage:FindFirstChild("Weapons")
				if weaponFolder then
					local weaponToGive = weaponFolder:FindFirstChild(skillData.WeaponGrant)
					if weaponToGive then
						weaponToGive:Clone().Parent = player:WaitForChild("Backpack")
					end
				end
			end
			DraftEvent:FireClient(player, "Close")
		end
	end
	ActiveDrafts = {}
	PlayersDrafting = 0
end
	
	-- Clear all locks
	ActiveDrafts = {}
	PlayersDrafting = 0
end

-- Clean up if a player leaves mid-draft so the wave doesn't pause forever
Players.PlayerRemoving:Connect(function(player)
	if ActiveDrafts[player.UserId] then
		ActiveDrafts[player.UserId] = nil
		PlayersDrafting -= 1
	end
end)

return SkillManager