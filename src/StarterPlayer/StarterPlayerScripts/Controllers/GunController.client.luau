--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local NetworkEvents = ReplicatedStorage:WaitForChild("NetworkEvents")
local ShootEvent = NetworkEvents:WaitForChild("ShootEvent") :: RemoteEvent
local WeaponConfig = require(ReplicatedStorage.GameConfig:WaitForChild("WeaponConfig"))

local canShoot = true

-- Visual Bullet Tracer Generator
local function DrawTracer(origin: Vector3, endPosition: Vector3)
	local distance = (endPosition - origin).Magnitude
	
	local tracer = Instance.new("Part")
	tracer.Anchored = true
	tracer.CanCollide = false
	tracer.Locked = true
	tracer.CastShadow = false
	tracer.Material = Enum.Material.Neon
	tracer.Color = Color3.fromRGB(255, 255, 100) -- Yellow bullet
	
	-- Make it a thin laser beam
	tracer.Size = Vector3.new(0.1, 0.1, distance)
	tracer.CFrame = CFrame.lookAt(origin, endPosition) * CFrame.new(0, 0, -distance / 2)
	tracer.Parent = Workspace
	
	-- Destroy the tracer after 0.05 seconds (creates a flash effect)
	task.delay(0.05, function()
		tracer:Destroy()
	end)
end

mouse.Button1Down:Connect(function()
	local char = player.Character
	if not char then return end
	
	-- Check if the player is holding a tool
	local equippedTool = char:FindFirstChildWhichIsA("Tool")
	if not equippedTool then return end
	
	local config = WeaponConfig[equippedTool.Name]
	if not config or not canShoot then return end
	
	local handle = equippedTool:FindFirstChild("Handle") :: BasePart
	if not handle then return end
	
	local muzzle = handle:FindFirstChild("Muzzle") :: Attachment
	if not muzzle then return end

	canShoot = false
	
	-- Calculate where the bullet is going
	local origin = muzzle.WorldPosition
	local targetPosition = mouse.Hit.Position
	local direction = (targetPosition - origin).Unit
	
	-- Add Spread (Accuracy)
	local spread = config.Spread
	direction = Vector3.new(
		direction.X + (math.random(-100, 100) / 100) * spread,
		direction.Y + (math.random(-100, 100) / 100) * spread,
		direction.Z + (math.random(-100, 100) / 100) * spread
	).Unit
	
	-- Draw the visual laser on the client immediately
	local visualEnd = origin + (direction * 300)
	DrawTracer(origin, visualEnd)
	
	-- Tell the server to do the actual damage math
	ShootEvent:FireServer(equippedTool.Name, origin, direction)
	
	task.wait(config.FireRate)
	canShoot = true
end)