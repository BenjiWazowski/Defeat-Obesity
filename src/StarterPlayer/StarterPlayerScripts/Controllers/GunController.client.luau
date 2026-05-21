--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local NetworkEvents = ReplicatedStorage:WaitForChild("NetworkEvents")
local ShootEvent = NetworkEvents:WaitForChild("ShootEvent") :: RemoteEvent
local ReloadEvent = NetworkEvents:WaitForChild("ReloadEvent") :: RemoteEvent
local WeaponConfig = require(ReplicatedStorage.GameConfig:WaitForChild("WeaponConfig"))

local isShooting = false
local isReloading = false
local lastShot = 0

-- [[ MATH ENGINE (Client Mirror) ]]
local function GetWeaponStats(weaponName: string, currentWave: number)
	local config = WeaponConfig[weaponName]
	local stats = {}
	local decayRate = 0.1
	
	stats.Damage = config.Damage.Base * math.pow(config.Damage.GrowthMult, currentWave - 1)
	
	-- SAFEGUARD: Only calculate ammo/reload if it's a gun!
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

local function DrawTracer(origin: Vector3, endPosition: Vector3)
	local distance = (endPosition - origin).Magnitude
	local tracer = Instance.new("Part")
	tracer.Anchored = true
	tracer.CanCollide = false
	tracer.Locked = true
	tracer.CastShadow = false
	tracer.Material = Enum.Material.Neon
	tracer.Color = Color3.fromRGB(255, 255, 100)
	tracer.Size = Vector3.new(0.1, 0.1, distance)
	tracer.CFrame = CFrame.lookAt(origin, endPosition) * CFrame.new(0, 0, -distance / 2)
	tracer.Parent = Workspace
	task.delay(0.05, function() tracer:Destroy() end)
end

local function FireWeapon(equippedTool: Tool, config: any)
	local handle = equippedTool:FindFirstChild("Handle") :: BasePart
	local muzzle = handle and handle:FindFirstChild("Muzzle") :: Attachment
	if not muzzle then return end
	
	local origin = muzzle.WorldPosition
	local targetPosition = mouse.Hit.Position
	local baseDirection = (targetPosition - origin).Unit
	
	local isExplosive = config.ProjectileType == "PhysicalObject" or config.ProjectileType == "PhysicalTrajectory"
	local isShotgun = config.PelletCount and config.PelletCount > 1
	
	if isExplosive then
		-- Explosives don't draw tracer lasers. The server will spawn the physical rocket.
		ShootEvent:FireServer(equippedTool.Name, origin, baseDirection)
		
	elseif isShotgun then
		-- Shotgun: Calculate 12-24 unique directions
		local pelletDirections = {}
		for i = 1, config.PelletCount do
			local spread = config.Spread
			local dir = Vector3.new(
				baseDirection.X + (math.random(-100, 100) / 100) * spread,
				baseDirection.Y + (math.random(-100, 100) / 100) * spread,
				baseDirection.Z + (math.random(-100, 100) / 100) * spread
			).Unit
			table.insert(pelletDirections, dir)
			DrawTracer(origin, origin + (dir * 300))
		end
		-- Send the array of directions to the server
		ShootEvent:FireServer(equippedTool.Name, origin, pelletDirections)
		
	else
		-- Standard Hitscan
		local spread = config.Spread
		local dir = Vector3.new(
			baseDirection.X + (math.random(-100, 100) / 100) * spread,
			baseDirection.Y + (math.random(-100, 100) / 100) * spread,
			baseDirection.Z + (math.random(-100, 100) / 100) * spread
		).Unit
		DrawTracer(origin, origin + (dir * 300))
		ShootEvent:FireServer(equippedTool.Name, origin, dir)
	end
	
	-- Local Ammo Prediction
	local currentAmmo = equippedTool:GetAttribute("CurrentAmmo")
	local reserveAmmo = equippedTool:GetAttribute("ReserveAmmo")
	
	if equippedTool.Name == "Glizzy shooter" then
		if reserveAmmo then equippedTool:SetAttribute("ReserveAmmo", reserveAmmo - 1) end
	else
		if currentAmmo then equippedTool:SetAttribute("CurrentAmmo", currentAmmo - 1) end
	end
end

local function StartShooting()
	local char = player.Character
	if not char then return end
	
	local equippedTool = char:FindFirstChildWhichIsA("Tool")
	local config = equippedTool and WeaponConfig[equippedTool.Name]
	if not equippedTool or not config then return end
	
	isShooting = true
	if isReloading then isReloading = false end
	
	local currentWave = Workspace:GetAttribute("CurrentWave") or 1
	local wStats = GetWeaponStats(equippedTool.Name, currentWave)
	
	while isShooting do
		if os.clock() - lastShot < wStats.FireRate then
			task.wait(0.01)
			if config.Type == "SemiAuto" then break end
			continue
		end
		
		local currentAmmo = equippedTool:GetAttribute("CurrentAmmo") or wStats.ClipSize
		local reserveAmmo = equippedTool:GetAttribute("ReserveAmmo") or wStats.TotalReserveAmmo
		
		if equippedTool.Name == "Glizzy shooter" then
			if reserveAmmo <= 0 then break end
		else
			if currentAmmo <= 0 then
				isShooting = false
				isReloading = true
				ReloadEvent:FireServer(equippedTool.Name)
				task.delay(wStats.ReloadSpeed, function() isReloading = false end)
				break
			end
		end
		
		lastShot = os.clock()
		FireWeapon(equippedTool, config)
		
		if config.Type == "SemiAuto" then break end
		
		currentWave = Workspace:GetAttribute("CurrentWave") or 1
		wStats = GetWeaponStats(equippedTool.Name, currentWave)
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		StartShooting()
	elseif input.KeyCode == Enum.KeyCode.R then
		local char = player.Character
		local equippedTool = char and char:FindFirstChildWhichIsA("Tool")
		if equippedTool and WeaponConfig[equippedTool.Name] and not isReloading then
			local currentAmmo = equippedTool:GetAttribute("CurrentAmmo") or 0
			local currentWave = Workspace:GetAttribute("CurrentWave") or 1
			local wStats = GetWeaponStats(equippedTool.Name, currentWave)
			
			if currentAmmo < wStats.ClipSize then
				isShooting = false
				isReloading = true
				ReloadEvent:FireServer(equippedTool.Name)
				task.delay(wStats.ReloadSpeed, function() isReloading = false end)
			end
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isShooting = false
	end
end)

-- [[ INITIALIZE AMMO ATTRIBUTES ]]
local function HookGunAttributes(char: Model)
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and WeaponConfig[child.Name] then
			local currentWave = Workspace:GetAttribute("CurrentWave") or 1
			local wStats = GetWeaponStats(child.Name, currentWave)
			
			if child:GetAttribute("CurrentAmmo") == nil then
				child:SetAttribute("CurrentAmmo", wStats.ClipSize)
			end
			if child:GetAttribute("ReserveAmmo") == nil then
				child:SetAttribute("ReserveAmmo", wStats.TotalReserveAmmo)
			end
		end
	end)
end

-- Catch the character if they already spawned before the script loaded!
if player.Character then HookGunAttributes(player.Character) end
player.CharacterAdded:Connect(HookGunAttributes)