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

-- Update the Player Attributes for the HUD
local function SyncAmmoToHUD(equippedTool: Tool?)
	if not equippedTool then
		player:SetAttribute("CurrentAmmo", 0)
		player:SetAttribute("MaxAmmo", 0)
		return
	end
	
	local maxAmmo = player:GetAttribute("Stat_AmmoCapacity") or WeaponConfig[equippedTool.Name].AmmoCapacity
	local currentAmmo = equippedTool:GetAttribute("CurrentAmmo")
	if currentAmmo == nil then currentAmmo = maxAmmo end
	
	player:SetAttribute("CurrentAmmo", currentAmmo)
	player:SetAttribute("MaxAmmo", maxAmmo)
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
	
	-- Local Ammo Prediction for UI responsiveness
	local currentAmmo = equippedTool:GetAttribute("CurrentAmmo") or config.AmmoCapacity
	equippedTool:SetAttribute("CurrentAmmo", currentAmmo - 1)
end

local function StartShooting()
	local char = player.Character
	if not char or isReloading then return end
	
	local equippedTool = char:FindFirstChildWhichIsA("Tool")
	local config = equippedTool and WeaponConfig[equippedTool.Name]
	if not equippedTool or not config then return end
	
	isShooting = true
	
	while isShooting and not isReloading do
		local currentAmmo = equippedTool:GetAttribute("CurrentAmmo")
		
		-- Auto-Reload if empty
		if currentAmmo and currentAmmo <= 0 then
			isShooting = false
			ReloadEvent:FireServer(equippedTool.Name)
			isReloading = true
			task.wait(player:GetAttribute("Stat_ReloadSpeed") or config.ReloadSpeed)
			isReloading = false
			break
		end
		
		FireWeapon(equippedTool, config)
		
		task.wait(config.FireRate)
		
		-- Break loop if it's a SemiAuto weapon (must click again)
		if config.Type == "SemiAuto" then break end
		
		-- Re-verify they are still holding the tool
		if not char:FindFirstChild(equippedTool.Name) then break end
	end
end

-- Mouse Control
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		StartShooting()
	elseif input.KeyCode == Enum.KeyCode.R then
		local char = player.Character
		local equippedTool = char and char:FindFirstChildWhichIsA("Tool")
		if equippedTool and WeaponConfig[equippedTool.Name] and not isReloading then
			isShooting = false
			isReloading = true
			ReloadEvent:FireServer(equippedTool.Name)
			task.wait(player:GetAttribute("Stat_ReloadSpeed") or WeaponConfig[equippedTool.Name].ReloadSpeed)
			isReloading = false
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isShooting = false
	end
end)

-- Hook Tool Equip/Unequip to the HUD
player.CharacterAdded:Connect(function(char)
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and WeaponConfig[child.Name] then
			SyncAmmoToHUD(child)
			child:GetAttributeChangedSignal("CurrentAmmo"):Connect(function()
				SyncAmmoToHUD(child)
			end)
		end
	end)
	char.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			SyncAmmoToHUD(nil)
		end
	end)
end)