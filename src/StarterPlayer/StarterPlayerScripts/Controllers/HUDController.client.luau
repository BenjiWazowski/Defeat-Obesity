--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- [[ 1. GENERATE THE GREYBOX UI ]]
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CombatHUD"
screenGui.ResetOnSpawn = false -- Keeps UI alive when player dies
screenGui.Parent = playerGui

-- Wave Counter (Top Center)
local waveLabel = Instance.new("TextLabel")
waveLabel.Size = UDim2.new(0, 300, 0, 50)
waveLabel.Position = UDim2.new(0.5, -150, 0, 20)
waveLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
waveLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
waveLabel.TextScaled = true
waveLabel.Font = Enum.Font.GothamBold
waveLabel.Text = "WAITING FOR WAVE..."
waveLabel.Parent = screenGui

-- Health Bar (Bottom Left)
local healthLabel = Instance.new("TextLabel")
healthLabel.Size = UDim2.new(0, 250, 0, 40)
healthLabel.Position = UDim2.new(0, 20, 1, -60)
healthLabel.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
healthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
healthLabel.TextScaled = true
healthLabel.Font = Enum.Font.GothamBold
healthLabel.Text = "HP: 100 / 100"
healthLabel.Parent = screenGui

-- Currency Counter (Top Right)
local sausageLabel = Instance.new("TextLabel")
sausageLabel.Size = UDim2.new(0, 200, 0, 40)
sausageLabel.Position = UDim2.new(1, -220, 0, 20)
sausageLabel.BackgroundColor3 = Color3.fromRGB(139, 69, 19)
sausageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
sausageLabel.TextScaled = true
sausageLabel.Font = Enum.Font.GothamBold
sausageLabel.Text = "🥩 Sausages: 0"
sausageLabel.Parent = screenGui

-- [[ 2. EVENT LISTENERS ]]

-- Listen for Wave Updates from the Server
Workspace:GetAttributeChangedSignal("CurrentWave"):Connect(function()
	local currentWave = Workspace:GetAttribute("CurrentWave") or 0
	waveLabel.Text = "🚨 WAVE " .. tostring(currentWave) .. " 🚨"
end)

-- Listen for Sausage Updates from the Server
player:GetAttributeChangedSignal("Sausages"):Connect(function()
	local sausages = player:GetAttribute("Sausages") or 0
	sausageLabel.Text = "🥩 Sausages: " .. tostring(sausages)
end)

-- Dynamically link to the player's health, even if they die and respawn
local function HookHealth(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	
	-- Update immediately
	healthLabel.Text = "HP: " .. math.floor(humanoid.Health) .. " / " .. math.floor(humanoid.MaxHealth)
	
	-- Update when damaged or healed
	humanoid.HealthChanged:Connect(function(health)
		healthLabel.Text = "HP: " .. math.floor(health) .. " / " .. math.floor(humanoid.MaxHealth)
	end)
end

-- Hook existing character if already spawned
if player.Character then
	HookHealth(player.Character)
end

-- Hook future characters (respawns)
player.CharacterAdded:Connect(HookHealth)

print("🖥️ [HUDController] Visual Interface Booted.")