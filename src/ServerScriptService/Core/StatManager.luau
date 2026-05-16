--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DataService = require(script.Parent:WaitForChild("DataService"))
local ClassModifiers = require(ReplicatedStorage.GameConfig:WaitForChild("ClassModifiers"))

local StatManager = {}

-- [[ CONFIGURATION ]]
-- 10% gap closure per wave for capped stats
local DECAY_RATE = 0.1 

-- We cache the calculated stats per player per wave to save CPU power.
-- We do not want to recalculate the math 60 times a second during combat.
local PlayerStatCache = {}

-- [[ CORE CALCULATOR ]]
function StatManager.CalculateStats(player: Player, currentWave: number)
	local profile = DataService.GetProfile(player)
	
	-- Fallback to "Regular guy" if they haven't picked a class in the Hub yet
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
	
	-- 3. UNCHANGED BASE STATS (Catch-all)
	for statName, baseValue in pairs(config.BaseStats) do
		if activeStats[statName] == nil then
			activeStats[statName] = baseValue
		end
	end
	
	-- 4. DEGENERATE GUY OVERRIDE (The Gamble)
	if className == "Gamble Guy" then
		local multiplier = math.random(80, 200) / 100 -- Rolls a random number between 0.8x and 2.0x
		print("🎲 [StatManager] " .. player.Name .. " rolled a " .. multiplier .. "x stat multiplier for Wave " .. currentWave .. "!")
		
		for statName, value in pairs(activeStats) do
			-- We don't multiply HP Regen or base speeds, just the core combat scaling
			if statName == "MeleeDamage" or statName == "GunDamage" or statName == "Health" or statName == "Luck" then
				activeStats[statName] = value * multiplier
			end
		end
	end
	
	-- Save to memory
	PlayerStatCache[player.UserId] = activeStats
	return activeStats
end

-- [[ THE FETCH API ]]
function StatManager.GetActiveStats(player: Player)
	-- If they don't have stats cached yet, calculate them for Wave 1
	if not PlayerStatCache[player.UserId] then
		return StatManager.CalculateStats(player, 1)
	end
	return PlayerStatCache[player.UserId]
end

-- [[ PHYSICAL INJECTION ]]
-- This physically alters the player's Roblox avatar (Health bars, run speed)
function StatManager.ApplyPhysicalStats(player: Player)
	local char = player.Character
	local humanoid = char and char:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then return end
	
	local stats = StatManager.GetActiveStats(player)
	
	-- Set Roblox Engine Stats
	humanoid.MaxHealth = stats.Health
	humanoid.Health = humanoid.MaxHealth -- Heal to full when stats are applied
	humanoid.WalkSpeed = stats.MovementSpeed
	
	print("💪 [StatManager] Physical stats injected for " .. player.Name .. " (Max HP: " .. math.floor(stats.Health) .. ", Speed: " .. string.format("%.1f", stats.MovementSpeed) .. ")")
end

return StatManager