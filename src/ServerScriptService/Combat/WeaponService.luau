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

-- Anti-cheat tracking
local PlayerCooldowns = {}

ShootEvent.OnServerEvent:Connect(function(player: Player, weaponName: string, origin: Vector3, direction: Vector3)
	local config = WeaponConfig[weaponName]
	if not config then return end -- Invalid weapon
	
	-- 1. ANTI-CHEAT: Check Fire Rate
	local lastShot = PlayerCooldowns[player.UserId] or 0
	if os.clock() - lastShot < config.FireRate then
		return -- Silently drop exploiter's request
	end
	PlayerCooldowns[player.UserId] = os.clock()
	
	-- Fetch the player's dynamic stats to boost gun damage
	local activeStats = StatManager.GetActiveStats(player)
	local totalDamage = config.Damage + (activeStats.GunDamage * 0.5) -- Gun damage stat adds 50% of its value to base gun damage
	
	-- 2. SERVER RAYCAST (Ground Truth)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {player.Character}
	
	-- Shoot the ray exactly 300 studs forward
	local raycastResult = Workspace:Raycast(origin, direction * 300, raycastParams)
	
	if raycastResult and raycastResult.Instance then
		local hitPart = raycastResult.Instance
		local enemyModel = hitPart:FindFirstAncestorWhichIsA("Model")
		
		if enemyModel then
			local monsterHumanoid = enemyModel:FindFirstChild("Humanoid") :: Humanoid
			if monsterHumanoid and monsterHumanoid.Health > 0 then
				
				-- 3. HEADSHOT MULTIPLIER
				if hitPart.Name == "Head" then
					totalDamage = totalDamage * config.HeadshotMultiplier
					-- print("🎯 HEADSHOT! Dealt " .. totalDamage .. " damage!")
				end
				
				monsterHumanoid:TakeDamage(totalDamage)
				
				-- 4. KILL / LOOT CHECK
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