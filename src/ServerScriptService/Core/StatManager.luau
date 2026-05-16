--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DataService = require(script.Parent:WaitForChild("DataService"))
local ClassModifiers = require(ReplicatedStorage.GameConfig:WaitForChild("ClassModifiers"))

local StatManager = {}

local DECAY_RATE = 0.1 
local PlayerStatCache = {}

function StatManager.CalculateStats(player: Player, currentWave: number)
	local profile = DataService.GetProfile(player)
	
	local className = profile and profile.Data.Class or "Regular guy"
	local config = ClassModifiers[className]
	
	if not config then 
		warn("[StatManager] Class " .. className .. " not found! Defaulting to Regular guy.")
		config = ClassModifiers["Regular guy"]
	end
	
	local activeStats = {}
	
	-- 1. LINEAR GROWTH (Infinite)
	for statName, growthRate in pairs(config.LinearGrowth) do
		activeStats[statName] = config.BaseStats[statName] + (growthRate * (currentWave - 1))
	end
	
	-- 2. DIMINISHING RETURNS (Asymptotic Curve)
	for statName, capValue in pairs(config.DiminishingCaps) do
		local baseValue = config.BaseStats[statName]
		activeStats[statName] = capValue - ((capValue - baseValue) * math.pow(1 - DECAY_RATE, currentWave - 1))
	end
	
	-- 3. UNCHANGED BASE STATS
	for statName, baseValue in pairs(config.BaseStats) do
		if activeStats[statName] == nil then
			activeStats[statName] = baseValue
		end
	end
	
	-- 4. DEGENERATE GUY OVERRIDE (The Gamble)
	if className == "Gamble Guy" then
		local multiplier = math.random(80, 200) / 100 
		print("🎲 [StatManager] " .. player.Name .. " rolled a " .. multiplier .. "x stat multiplier for Wave " .. currentWave .. "!")
		
		for statName, value in pairs(activeStats) do
			if statName == "MeleeDamage" or statName == "GunDamage" or statName == "Health" or statName == "Luck" then
				activeStats[statName] = value * multiplier
			end
		end
	end
	
	PlayerStatCache[player.UserId] = activeStats
	return activeStats
end

function StatManager.GetActiveStats(player: Player)
	if not PlayerStatCache[player.UserId] then
		return StatManager.CalculateStats(player, 1)
	end
	return PlayerStatCache[player.UserId]
end

function StatManager.ApplyPhysicalStats(player: Player)
	local char = player.Character
	local humanoid = char and char:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then return end
	
	local stats = StatManager.GetActiveStats(player)
	
	humanoid.MaxHealth = stats.Health
	humanoid.Health = humanoid.MaxHealth 
	humanoid.WalkSpeed = stats.MovementSpeed
	
	-- Broadcast the MeleeSpeed to the Client for cooldowns
	player:SetAttribute("MeleeSpeed", stats.MeleeSpeed)
	
	print("💪 [StatManager] Physical stats injected for " .. player.Name .. " (Max HP: " .. math.floor(stats.Health) .. ", Speed: " .. string.format("%.1f", stats.MovementSpeed) .. ")")
end

-- Automatically re-apply stats if the player dies and respawns mid-wave
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(0.5) -- Wait a split second for Roblox to finish building the character
		StatManager.ApplyPhysicalStats(player)
	end)
end)

return StatManager