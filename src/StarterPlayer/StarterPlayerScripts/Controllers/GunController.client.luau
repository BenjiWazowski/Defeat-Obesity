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
-- This calculates the exact same stats as the server so the Client knows the true FireRate
local function GetWeaponStats(weaponName: string, currentWave: number)
	local config = WeaponConfig[weaponName]
	local stats = {}
	local decayRate = 0.1
	
	stats.Damage = config.Damage.Base * math.pow(config.Damage.GrowthMult, currentWave - 1)
	stats.ClipSize = math.floor(config.ClipSize.Cap - ((config.ClipSize.Cap - config.ClipSize.Base) * math.pow(1 - decayRate, currentWave - 1)))
	stats.ReserveClips = math.floor(config.ReserveClips.Cap - ((config.ReserveClips.Cap - config.ReserveClips.Base) * math.pow(1 - decayRate, currentWave - 1)))
	stats.FireRate = config.FireRate.Cap - ((config.FireRate.Cap - config.FireRate.Base) * math.pow(1 - decayRate, currentWave - 1))
	stats.ReloadSpeed = config.ReloadSpeed.Cap - ((config.ReloadSpeed.Cap - config.ReloadSpeed.Base) * math.pow(1 - decayRate, currentWave - 1))
	
	stats.TotalReserveAmmo = stats.ClipSize * stats.ReserveClips
	if weaponName == "Glizzy shooter" then
		stats.TotalReserveAmmo = stats.ReserveClips 
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
	local direction = (targetPosition - origin).Unit
	
	local spread = config.Spread
	direction = Vector3.new(
		direction.X + (math.random(-100, 100) / 100) * spread,
		direction.Y + (math.random(-100, 100) / 100) * spread,
		direction.Z + (math.random(-100, 100) / 100) * spread
	).Unit
	
	local visualEnd = origin + (direction * 300)
	DrawTracer(origin, visualEnd)
	ShootEvent:FireServer(equippedTool.Name, origin, direction)
	
	-- Local Ammo Prediction for instant UI updates
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
	if not char or isReloading then return end
	
	local equippedTool = char:FindFirstChildWhichIsA("Tool")
	local config = equippedTool and WeaponConfig[equippedTool.Name]
	if not equippedTool or not config then return end
	
	isShooting = true
	
	local currentWave = Workspace:GetAttribute("CurrentWave") or 1
	local wStats = GetWeaponStats(equippedTool.Name, currentWave)
	
	while isShooting and not isReloading do
		-- 1. FIRE RATE ENFORCEMENT
		if os.clock() - lastShot < wStats.FireRate then
			task.wait(0.01)
			-- If SemiAuto, holding the mouse shouldn't shoot once cooldown ends. Force them to click again.
			if config.Type == "SemiAuto" then break end
			continue
		end
		
		local currentAmmo = equippedTool:GetAttribute("CurrentAmmo") or wStats.ClipSize
		local reserveAmmo = equippedTool:GetAttribute("ReserveAmmo") or wStats.TotalReserveAmmo
		
		-- 2. AUTO-RELOAD LOGIC
		if equippedTool.Name == "Glizzy shooter" then
			if reserveAmmo <= 0 then break end
		else
			if currentAmmo <= 0 then
				isShooting = false
				isReloading = true
				ReloadEvent:FireServer(equippedTool.Name)
				task.wait(wStats.ReloadSpeed)
				isReloading = false
				break
			end
		end
		
		-- 3. FIRE
		lastShot = os.clock()
		FireWeapon(equippedTool, config)
		
		if config.Type == "SemiAuto" then break end
		
		-- Update stats mid-spray just in case the wave changes
		currentWave = Workspace:GetAttribute("CurrentWave") or 1
		wStats = GetWeaponStats(equippedTool.Name, currentWave)
	end
end

-- [[ INPUT HANDLING ]]
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		StartShooting()
	elseif input.KeyCode == Enum.KeyCode.R then
		local char = player.Character
		local equippedTool = char and char:FindFirstChildWhichIsA("Tool")
		if equippedTool and WeaponConfig[equippedTool.Name] and not isReloading then
			local currentWave = Workspace:GetAttribute("CurrentWave") or 1
			local wStats = GetWeaponStats(equippedTool.Name, currentWave)
			
			isShooting = false
			isReloading = true
			ReloadEvent:FireServer(equippedTool.Name)
			task.wait(wStats.ReloadSpeed)
			isReloading = false
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isShooting = false
	end
end)

-- Initialize Tool Ammo Attributes so HUD displays properly on Equip
player.CharacterAdded:Connect(function(char)
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
end)