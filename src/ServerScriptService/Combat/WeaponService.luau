--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local WeaponService = {}

local WeaponConfig = require(ReplicatedStorage.GameConfig:WaitForChild("WeaponConfig"))
local StatManager = require(script.Parent.Parent.Core:WaitForChild("StatManager"))
local DataService = require(script.Parent.Parent.Core:WaitForChild("DataService"))

local NetworkEvents = ReplicatedStorage:WaitForChild("NetworkEvents")

local ShootEvent = NetworkEvents:WaitForChild("ShootEvent") :: RemoteEvent
local ReloadEvent = NetworkEvents:WaitForChild("ReloadEvent") :: RemoteEvent

local PlayerCooldowns = {}
local ReloadingPlayers = {} 

-- Helper function to calculate a weapon's current wave stats dynamically
local function GetWeaponStats(weaponName: string, currentWave: number)
	local config = WeaponConfig[weaponName]
	local stats = {}
	local decayRate = 0.1
	
	-- Exponential Damage Growth
	stats.Damage = config.Damage.Base * math.pow(config.Damage.GrowthMult, currentWave - 1)
	
	-- Diminishing Caps for everything else
	stats.ClipSize = math.floor(config.ClipSize.Cap - ((config.ClipSize.Cap - config.ClipSize.Base) * math.pow(1 - decayRate, currentWave - 1)))
	stats.ReserveClips = math.floor(config.ReserveClips.Cap - ((config.ReserveClips.Cap - config.ReserveClips.Base) * math.pow(1 - decayRate, currentWave - 1)))
	stats.FireRate = config.FireRate.Cap - ((config.FireRate.Cap - config.FireRate.Base) * math.pow(1 - decayRate, currentWave - 1))
	stats.ReloadSpeed = config.ReloadSpeed.Cap - ((config.ReloadSpeed.Cap - config.ReloadSpeed.Base) * math.pow(1 - decayRate, currentWave - 1))
	
	stats.TotalReserveAmmo = stats.ClipSize * stats.ReserveClips
	if weaponName == "Glizzy shooter" then
		stats.TotalReserveAmmo = stats.ReserveClips -- LMG uses raw numbers instead of clips
	end
	
	return stats
end

-- [[ 1. RELOAD LOGIC ]]
ReloadEvent.OnServerEvent:Connect(function(player: Player, weaponName: string)
	local char = player.Character
	if not char or ReloadingPlayers[player.UserId] then return end
	
	local equippedTool = char:FindFirstChild(weaponName)
	if not equippedTool or not WeaponConfig[weaponName] then return end
	
	local currentWave = Workspace:GetAttribute("CurrentWave") or 1
	local wStats = GetWeaponStats(weaponName, currentWave)
	
	local currentAmmo = equippedTool:GetAttribute("CurrentAmmo")
	local reserveAmmo = equippedTool:GetAttribute("ReserveAmmo")
	
	-- Initialize if nil
	if currentAmmo == nil then currentAmmo = wStats.ClipSize end
	if reserveAmmo == nil then reserveAmmo = wStats.TotalReserveAmmo end
	
	-- Stop if clip is full or no reserve ammo left
	if currentAmmo >= wStats.ClipSize or reserveAmmo <= 0 then return end 
	
	ReloadingPlayers[player.UserId] = true
	task.wait(wStats.ReloadSpeed)
	
	-- Calculate how much ammo we actually need
	local ammoNeeded = wStats.ClipSize - currentAmmo
	local ammoToLoad = math.min(ammoNeeded, reserveAmmo)
	
	if equippedTool.Parent == char then 
		equippedTool:SetAttribute("CurrentAmmo", currentAmmo + ammoToLoad)
		equippedTool:SetAttribute("ReserveAmmo", reserveAmmo - ammoToLoad)
	end
	
	ReloadingPlayers[player.UserId] = nil
end)

-- [[ 2. SHOOTING LOGIC ]]
ShootEvent.OnServerEvent:Connect(function(player: Player, weaponName: string, origin: Vector3, direction: Vector3)
	local char = player.Character
	if not char or ReloadingPlayers[player.UserId] then return end
	
	local equippedTool = char:FindFirstChild(weaponName)
	local config = WeaponConfig[weaponName]
	if not equippedTool or not config then return end
	
	local currentWave = Workspace:GetAttribute("CurrentWave") or 1
	local wStats = GetWeaponStats(weaponName, currentWave)
	local activeStats = StatManager.GetActiveStats(player)
	
	-- AMMO CHECK & INITIALIZATION
	local currentAmmo = equippedTool:GetAttribute("CurrentAmmo")
	local reserveAmmo = equippedTool:GetAttribute("ReserveAmmo")
	
	if currentAmmo == nil then 
		currentAmmo = wStats.ClipSize 
		equippedTool:SetAttribute("CurrentAmmo", currentAmmo)
	end
	if reserveAmmo == nil then 
		reserveAmmo = wStats.TotalReserveAmmo 
		equippedTool:SetAttribute("ReserveAmmo", reserveAmmo)
	end
	
	-- Check for empty
	if weaponName == "Glizzy shooter" then
		if reserveAmmo <= 0 then return end -- LMG checks reserve
	else
		if currentAmmo <= 0 then return end -- Normal guns check clip
	end
	
	-- FIRE RATE ANTI-CHEAT
	local lastShot = PlayerCooldowns[player.UserId] or 0
	if os.clock() - lastShot < wStats.FireRate then return end
	
	PlayerCooldowns[player.UserId] = os.clock()
	
	-- DECREMENT AMMO
	if weaponName == "Glizzy shooter" then
		equippedTool:SetAttribute("ReserveAmmo", reserveAmmo - 1)
	else
		equippedTool:SetAttribute("CurrentAmmo", currentAmmo - 1)
	end
	
	-- NEW DYNAMIC DAMAGE CALCULATION
	local totalDamage = wStats.Damage + (activeStats.GunDamage * 0.5)
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {char}
	
	local raycastResult = Workspace:Raycast(origin, direction * 300, raycastParams)
	
	if raycastResult and raycastResult.Instance then
		local hitPart = raycastResult.Instance
		local enemyModel = hitPart:FindFirstAncestorWhichIsA("Model")
		
		if enemyModel then
			local monsterHumanoid = enemyModel:FindFirstChild("Humanoid") :: Humanoid
			if monsterHumanoid and monsterHumanoid.Health > 0 then
				
				-- HEADSHOT MULTIPLIER
				if hitPart.Name == "Head" then
					totalDamage = totalDamage * config.HeadshotMultiplier
				end
				
				monsterHumanoid:TakeDamage(totalDamage)
				
				-- KILL / LOOT CHECK
				if monsterHumanoid.Health <= 0 then
					local profile = DataService.GetProfile(player)
					if profile then
						profile.Data.Sausages += 1
						player:SetAttribute("Sausages", profile.Data.Sausages)
					end
				end
			end
		end
	end
end)

return WeaponService