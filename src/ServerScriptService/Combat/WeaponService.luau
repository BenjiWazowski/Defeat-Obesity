--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local WeaponService = {}

local WeaponConfig = require(ReplicatedStorage.GameConfig:WaitForChild("WeaponConfig"))
local StatManager = require(script.Parent.Parent.Core:WaitForChild("StatManager"))
local DataService = require(script.Parent.Parent.Core:WaitForChild("DataService"))

local DropService = require(script.Parent.Parent.Environment:WaitForChild("DropService"))

local NetworkEvents = ReplicatedStorage:FindFirstChild("NetworkEvents")
if not NetworkEvents then
	NetworkEvents = Instance.new("Folder")
	NetworkEvents.Name = "NetworkEvents"
	NetworkEvents.Parent = ReplicatedStorage
end

local ShootEvent = NetworkEvents:FindFirstChild("ShootEvent") or Instance.new("RemoteEvent")
ShootEvent.Name = "ShootEvent"
ShootEvent.Parent = NetworkEvents

local ReloadEvent = NetworkEvents:FindFirstChild("ReloadEvent") or Instance.new("RemoteEvent")
ReloadEvent.Name = "ReloadEvent"
ReloadEvent.Parent = NetworkEvents

local DraftEvent = NetworkEvents:FindFirstChild("DraftEvent") or Instance.new("RemoteEvent")
DraftEvent.Name = "DraftEvent"
DraftEvent.Parent = NetworkEvents

local PlayerCooldowns = {}
local ReloadingPlayers = {} 


-- [[ MATH ENGINE (Client Mirror) ]]
local function GetWeaponStats(weaponName: string, currentWave: number)
	local config = WeaponConfig[weaponName]
	local stats = {}
	local decayRate = 0.1
	
	stats.Damage = config.Damage.Base * math.pow(config.Damage.GrowthMult, currentWave - 1)
	
	if config.Type ~= "Melee" then
		stats.ClipSize = math.floor(config.ClipSize.Cap - ((config.ClipSize.Cap - config.ClipSize.Base) * math.pow(1 - decayRate, currentWave - 1)))
		stats.ReserveClips = math.floor(config.ReserveClips.Cap - ((config.ReserveClips.Cap - config.ReserveClips.Base) * math.pow(1 - decayRate, currentWave - 1)))
		stats.FireRate = config.FireRate.Cap - ((config.FireRate.Cap - config.FireRate.Base) * math.pow(1 - decayRate, currentWave - 1))
		stats.ReloadSpeed = config.ReloadSpeed.Cap - ((config.ReloadSpeed.Cap - config.ReloadSpeed.Base) * math.pow(1 - decayRate, currentWave - 1))
		
		stats.TotalReserveAmmo = stats.ClipSize * stats.ReserveClips
		if weaponName == "Glizzy shooter" then
			stats.TotalReserveAmmo = stats.ReserveClips 
		end
	end
	
	return stats
end

-- [[ 1. PROGRESSIVE RELOAD LOGIC ]]
ReloadEvent.OnServerEvent:Connect(function(player: Player, weaponName: string)
	local char = player.Character
	if not char or ReloadingPlayers[player.UserId] then return end
	
	local equippedTool = char:FindFirstChild(weaponName)
	if not equippedTool or not WeaponConfig[weaponName] then return end
	
	local currentWave = Workspace:GetAttribute("CurrentWave") or 1
	local wStats = GetWeaponStats(weaponName, currentWave)
	
	local currentAmmo = equippedTool:GetAttribute("CurrentAmmo")
	local reserveAmmo = equippedTool:GetAttribute("ReserveAmmo")
	if currentAmmo == nil then currentAmmo = wStats.ClipSize; equippedTool:SetAttribute("CurrentAmmo", currentAmmo) end
	if reserveAmmo == nil then reserveAmmo = wStats.TotalReserveAmmo; equippedTool:SetAttribute("ReserveAmmo", reserveAmmo) end
	
	if currentAmmo >= wStats.ClipSize or reserveAmmo <= 0 then return end 
	
	ReloadingPlayers[player.UserId] = true
	
	local config = WeaponConfig[weaponName]
	local isProgressive = config.PelletCount ~= nil
	local waitTime = isProgressive and (wStats.ReloadSpeed / wStats.ClipSize) or wStats.ReloadSpeed
	
	while ReloadingPlayers[player.UserId] do
		local cAmmo = equippedTool:GetAttribute("CurrentAmmo") or wStats.ClipSize
		local rAmmo = equippedTool:GetAttribute("ReserveAmmo") or wStats.TotalReserveAmmo
		
		if cAmmo >= wStats.ClipSize or rAmmo <= 0 then break end 
		
		task.wait(waitTime)
		
		if not ReloadingPlayers[player.UserId] or equippedTool.Parent ~= char then break end
		
		cAmmo = equippedTool:GetAttribute("CurrentAmmo") or wStats.ClipSize
		rAmmo = equippedTool:GetAttribute("ReserveAmmo") or wStats.TotalReserveAmmo
		
		if isProgressive then
			equippedTool:SetAttribute("CurrentAmmo", cAmmo + 1)
			equippedTool:SetAttribute("ReserveAmmo", rAmmo - 1)
		else
			local ammoNeeded = wStats.ClipSize - cAmmo
			local ammoToLoad = math.min(ammoNeeded, rAmmo)
			equippedTool:SetAttribute("CurrentAmmo", cAmmo + ammoToLoad)
			equippedTool:SetAttribute("ReserveAmmo", rAmmo - ammoToLoad)
			break 
		end
	end
	
	ReloadingPlayers[player.UserId] = nil
end)

-- [[ 2. SHOOTING & PHYSICS LOGIC ]]
ShootEvent.OnServerEvent:Connect(function(player: Player, weaponName: string, origin: Vector3, directionData: any)
	local char = player.Character
	if not char then return end
	
	ReloadingPlayers[player.UserId] = nil 
	
	local equippedTool = char:FindFirstChild(weaponName)
	local config = WeaponConfig[weaponName]
	if not equippedTool or not config then return end
	
	local currentWave = Workspace:GetAttribute("CurrentWave") or 1
	local wStats = GetWeaponStats(weaponName, currentWave)
	local activeStats = StatManager.GetActiveStats(player)
	
	local currentAmmo = equippedTool:GetAttribute("CurrentAmmo")
	local reserveAmmo = equippedTool:GetAttribute("ReserveAmmo")
	if currentAmmo == nil then currentAmmo = wStats.ClipSize; equippedTool:SetAttribute("CurrentAmmo", currentAmmo) end
	if reserveAmmo == nil then reserveAmmo = wStats.TotalReserveAmmo; equippedTool:SetAttribute("ReserveAmmo", reserveAmmo) end
	
	if weaponName == "Glizzy shooter" then
		if reserveAmmo <= 0 then return end
	else
		if currentAmmo <= 0 then return end
	end
	
	local lastShot = PlayerCooldowns[player.UserId] or 0
	if os.clock() - lastShot < wStats.FireRate then return end
	PlayerCooldowns[player.UserId] = os.clock()
	
	if weaponName == "Glizzy shooter" then
		equippedTool:SetAttribute("ReserveAmmo", reserveAmmo - 1)
	else
		equippedTool:SetAttribute("CurrentAmmo", currentAmmo - 1)
	end
	
	local baseDamage = wStats.Damage * (1 + ((activeStats.GunDamage or 0) / 100))
	local isExplosive = config.ProjectileType == "PhysicalObject" or config.ProjectileType == "PhysicalTrajectory"
	
	-- [[ EXPLOSIVES BRANCH ]]
	if isExplosive then
		local dir = typeof(directionData) == "Vector3" and directionData or Vector3.new(0,0,-1)
		
		local proj = Instance.new("Part")
		proj.Name = "RocketProjectile"
		proj.Size = Vector3.new(0.5, 0.5, 1.5)
		proj.Color = Color3.fromRGB(50, 50, 50)
		proj.Material = Enum.Material.Metal
		proj.CFrame = CFrame.lookAt(origin, origin + dir)
		proj.CanCollide = false
		proj.Parent = Workspace
		
		local att = Instance.new("Attachment", proj)
		local vel = Instance.new("LinearVelocity", att)
		vel.Attachment0 = att
		vel.VectorVelocity = dir * (config.ProjectileType == "PhysicalTrajectory" and 100 or 200)
		vel.MaxForce = math.huge
		
		local exploded = false
		proj.Touched:Connect(function(hit)
			if exploded or hit:IsDescendantOf(char) then return end
			exploded = true
			
			local blastRadius = config.BlastRadius or 15
			
			local visualExp = Instance.new("Explosion")
			visualExp.Position = proj.Position
			visualExp.BlastRadius = blastRadius
			visualExp.BlastPressure = 0 
			visualExp.Parent = Workspace
			
			local partsInRadius = Workspace:GetPartBoundsInRadius(proj.Position, blastRadius)
			local hitTargets = {} 
			
			for _, p in ipairs(partsInRadius) do
				local model = p:FindFirstAncestorWhichIsA("Model")
				if model and not hitTargets[model] then
					hitTargets[model] = true
					local humanoid = model:FindFirstChild("Humanoid") :: Humanoid
					if humanoid and humanoid.Health > 0 then
						
						local pTarget = Players:GetPlayerFromCharacter(model)
						if pTarget == player then
							humanoid:TakeDamage(baseDamage * 0.3) 
						elseif string.find(humanoid.Parent.Name, "ObesityMonster") then
							humanoid:TakeDamage(baseDamage)
							
							if humanoid.Health <= 0 then
								if humanoid:GetAttribute("IsDead") then continue end
								humanoid:SetAttribute("IsDead", true)
								local profile = DataService.GetProfile(player)
								if profile then
									profile.Data.Sausages += 1
									player:SetAttribute("Sausages", profile.Data.Sausages)
								end
								DropService.RollForDrop(model.PrimaryPart.Position, player)
							end
						end
					end
				end
			end
			proj:Destroy()
		end)
		
		task.delay(5, function() if proj.Parent then proj:Destroy() end end)
		
	-- [[ HITSCAN & SHOTGUN BRANCH ]]
	else
		local directions = typeof(directionData) == "table" and directionData or {directionData}
		local maxRays = config.PelletCount or 1
		
		for i = 1, math.min(#directions, maxRays) do
			local dir = directions[i]
			
			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			raycastParams.FilterDescendantsInstances = {char}
			
			local raycastResult = Workspace:Raycast(origin, dir * 300, raycastParams)
			
			if raycastResult and raycastResult.Instance then
				local hitPart = raycastResult.Instance
				local enemyModel = hitPart:FindFirstAncestorWhichIsA("Model")
				
				if enemyModel and string.find(enemyModel.Name, "ObesityMonster") then
					local monsterHumanoid = enemyModel:FindFirstChild("Humanoid") :: Humanoid
					if monsterHumanoid and monsterHumanoid.Health > 0 then
						
						local finalDamage = baseDamage
						local isHeadshot = false
						if hitPart.Name == "Head" then
							finalDamage = finalDamage * config.HeadshotMultiplier
							isHeadshot = true
						end
						
						-- Deal Base Damage
						monsterHumanoid:TakeDamage(finalDamage)
						
						-- ==========================================
						-- [[ EPIC SKILLS: ON-HIT EFFECTS ]]
						-- ==========================================
						if monsterHumanoid.Health > 0 then
							local SkillConfig = require(ReplicatedStorage.GameConfig.SkillConfig)
							
							-- 1. THUNDER STRIKE
							local tsStacks = player:GetAttribute("Skill_ThunderStrike") or 0
							if tsStacks > 0 then
								local tMath = SkillConfig["Thunder Strike"].ThunderMath
								local chance = tMath.BaseProcChance + (tMath.ProcChancePerStack * (tsStacks - 1))
								
								if math.random() <= chance then
									local bolt = Instance.new("Part")
									bolt.Size = Vector3.new(1, 100, 1)
									bolt.Position = hitPart.Position + Vector3.new(0, 50, 0)
									bolt.Anchored = true
									bolt.CanCollide = false
									bolt.Material = Enum.Material.Neon
									bolt.BrickColor = BrickColor.new("New Yeller")
									bolt.Parent = Workspace
									task.delay(0.2, function() bolt:Destroy() end)
									
									monsterHumanoid:TakeDamage(monsterHumanoid.MaxHealth * tMath.NormalMobDamage)
								end
							end
							
							-- 2. INCENDIARY ROUNDS
							local irStacks = player:GetAttribute("Skill_IncendiaryRounds") or 0
							if irStacks > 0 and not monsterHumanoid:GetAttribute("OnFire") then
								monsterHumanoid:SetAttribute("OnFire", true)
								local fMath = SkillConfig["Incendiary Rounds"].FireMath
								
								local fire = Instance.new("Fire", hitPart)
								
								task.spawn(function()
									for _ = 1, fMath.DurationSeconds do
										task.wait(fMath.TickRate)
										if monsterHumanoid and monsterHumanoid.Health > 0 then
											monsterHumanoid:TakeDamage(monsterHumanoid.MaxHealth * fMath.NormalMobHPDamage)
										else
											break
										end
									end
									if monsterHumanoid then monsterHumanoid:SetAttribute("OnFire", nil) end
									if fire then fire:Destroy() end
								end)
							end
						end
						
						-- ==========================================
						-- [[ DEATH & EXPLODING HEADSHOTS ]]
						-- ==========================================
						if monsterHumanoid.Health <= 0 then
							if monsterHumanoid:GetAttribute("IsDead") then continue end
							monsterHumanoid:SetAttribute("IsDead", true)
							local profile = DataService.GetProfile(player)
							
							-- EPIC SKILL: Exploding Headshots
							local ehStacks = player:GetAttribute("Skill_ExplodingHeadshots") or 0
							if ehStacks > 0 and isHeadshot then
								local SkillConfig = require(ReplicatedStorage.GameConfig.SkillConfig)
								local expMath = SkillConfig["Exploding Headshots"].ExplosionMath
								
								local visualExp = Instance.new("Explosion")
								visualExp.Position = hitPart.Position
								visualExp.BlastRadius = expMath.BlastRadius
								visualExp.BlastPressure = 0
								visualExp.Parent = Workspace
								
								local explosionDamage = monsterHumanoid.MaxHealth * expMath.DamagePercent
								
								local partsInRadius = Workspace:GetPartBoundsInRadius(hitPart.Position, expMath.BlastRadius)
								local hitTargets = {} 
								for _, p in ipairs(partsInRadius) do
									local m = p:FindFirstAncestorWhichIsA("Model")
									if m and string.find(m.Name, "ObesityMonster") and not hitTargets[m] then
										hitTargets[m] = true
										local h = m:FindFirstChild("Humanoid") :: Humanoid
										if h and h.Health > 0 then
											h:TakeDamage(explosionDamage)
											if h.Health <= 0 and not h:GetAttribute("IsDead") then
												h:SetAttribute("IsDead", true)
												if profile then profile.Data.Sausages += expMath.BonusSausages end
												DropService.RollForDrop(m.PrimaryPart.Position, player)
											end
										end
									end
								end
							end
							
							if profile then
								profile.Data.Sausages += 1
								player:SetAttribute("Sausages", profile.Data.Sausages)
							end
							DropService.RollForDrop(hitPart.Position, player)
						end
						
					end
				end
			end
		end
	end
end)

return WeaponService