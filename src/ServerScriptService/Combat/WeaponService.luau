--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local WeaponService = {}

local WeaponConfig = require(ReplicatedStorage.GameConfig:WaitForChild("WeaponConfig"))
local StatManager = require(script.Parent.Parent.Core:WaitForChild("StatManager"))
local DataService = require(script.Parent.Parent.Core:WaitForChild("DataService"))

local NetworkEvents = ReplicatedStorage:WaitForChild("NetworkEvents")

local ShootEvent = Instance.new("RemoteEvent")
ShootEvent.Name = "ShootEvent"
ShootEvent.Parent = NetworkEvents

local ReloadEvent = Instance.new("RemoteEvent")
ReloadEvent.Name = "ReloadEvent"
ReloadEvent.Parent = NetworkEvents

local PlayerCooldowns = {}
local ReloadingPlayers = {} -- Tracks who is currently reloading so they can't spam it

-- [[ 1. RELOAD LOGIC ]]
ReloadEvent.OnServerEvent:Connect(function(player: Player, weaponName: string)
	local char = player.Character
	if not char or ReloadingPlayers[player.UserId] then return end
	
	local equippedTool = char:FindFirstChild(weaponName)
	local config = WeaponConfig[weaponName]
	if not equippedTool or not config then return end
	
	local activeStats = StatManager.GetActiveStats(player)
	
	ReloadingPlayers[player.UserId] = true
	-- Simulate reload time (modified by their ReloadSpeed stat)
	task.wait(activeStats.ReloadSpeed)
	
	-- Refill the tool's ammo attribute
	if equippedTool.Parent == char then -- Ensure they are still holding it
		equippedTool:SetAttribute("CurrentAmmo", activeStats.AmmoCapacity)
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
	
	local activeStats = StatManager.GetActiveStats(player)
	
	-- AMMO CHECK
	local currentAmmo = equippedTool:GetAttribute("CurrentAmmo")
	if currentAmmo == nil then 
		currentAmmo = activeStats.AmmoCapacity 
		equippedTool:SetAttribute("CurrentAmmo", currentAmmo)
	end
	
	if currentAmmo <= 0 then return end -- Empty clip
	
	-- FIRE RATE ANTI-CHEAT
	local lastShot = PlayerCooldowns[player.UserId] or 0
	if os.clock() - lastShot < config.FireRate then return end
	
	PlayerCooldowns[player.UserId] = os.clock()
	
	-- Decrement Ammo
	equippedTool:SetAttribute("CurrentAmmo", currentAmmo - 1)
	
	local totalDamage = config.Damage + (activeStats.GunDamage * 0.5)
	
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
				
				if hitPart.Name == "Head" then
					totalDamage = totalDamage * config.HeadshotMultiplier
				end
				
				monsterHumanoid:TakeDamage(totalDamage)
				
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