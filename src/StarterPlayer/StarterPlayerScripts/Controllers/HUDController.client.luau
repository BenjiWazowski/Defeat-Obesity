--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CombatHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- [[ WAVE COUNTER (Top Center - Smaller) ]]
local waveLabel = Instance.new("TextLabel")
waveLabel.AnchorPoint = Vector2.new(0.5, 0)
waveLabel.Size = UDim2.new(0, 150, 0, 30)
waveLabel.Position = UDim2.new(0.5, 0, 0, 10)
waveLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
waveLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
waveLabel.TextScaled = true
waveLabel.Font = Enum.Font.GothamBold
waveLabel.Text = "WAVE --"
waveLabel.Parent = screenGui

-- [[ SAUSAGES (Top Right - Icon + Number only) ]]
local sausageLabel = Instance.new("TextLabel")
sausageLabel.AnchorPoint = Vector2.new(1, 0)
sausageLabel.Size = UDim2.new(0, 100, 0, 30)
sausageLabel.Position = UDim2.new(1, -20, 0, 10)
sausageLabel.BackgroundTransparency = 1 -- Transparent background looks cleaner
sausageLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
sausageLabel.TextScaled = true
sausageLabel.Font = Enum.Font.GothamBold
sausageLabel.Text = "🥩 0"
sausageLabel.TextXAlignment = Enum.TextXAlignment.Right
sausageLabel.Parent = screenGui

-- [[ (A) PLAYER STATS (Bottom Left) ]]
local healthBar = Instance.new("TextLabel")
healthBar.AnchorPoint = Vector2.new(0, 1)
healthBar.Size = UDim2.new(0, 250, 0, 30)
healthBar.Position = UDim2.new(0, 20, 1, -60)
healthBar.BackgroundColor3 = Color3.fromRGB(40, 150, 80) -- Action RPG Green
healthBar.TextColor3 = Color3.fromRGB(255, 255, 255)
healthBar.TextScaled = true
healthBar.Font = Enum.Font.GothamBold
healthBar.Text = "HP: 100 / 100"
healthBar.Parent = screenGui

-- [[ (B) COUNTDOWN (Top Middle - Hidden initially) ]]
local countdownLabel = Instance.new("TextLabel")
countdownLabel.AnchorPoint = Vector2.new(0.5, 0)
countdownLabel.Size = UDim2.new(0, 300, 0, 40)
countdownLabel.Position = UDim2.new(0.5, 0, 0, 60)
countdownLabel.BackgroundTransparency = 1
countdownLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
countdownLabel.TextScaled = true
countdownLabel.Font = Enum.Font.GothamBlack
countdownLabel.Text = ""
countdownLabel.Parent = screenGui

-- [[ (C) CONTROLS BINDINGS (Middle-Bottom Right) ]]
local controlsLabel = Instance.new("TextLabel")
controlsLabel.AnchorPoint = Vector2.new(1, 0.5)
controlsLabel.Size = UDim2.new(0, 150, 0, 80)
controlsLabel.Position = UDim2.new(1, -20, 0.75, 0)
controlsLabel.BackgroundTransparency = 1
controlsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
controlsLabel.TextSize = 18
controlsLabel.Font = Enum.Font.GothamBold
controlsLabel.Text = "ATTACK [L-Click]\nDASH [Q]\nJUMP [Space]"
controlsLabel.TextXAlignment = Enum.TextXAlignment.Right
controlsLabel.Parent = screenGui

-- [[ (D) AMMO / WEAPON INFO (Bottom Right) ]]
local ammoLabel = Instance.new("TextLabel")
ammoLabel.AnchorPoint = Vector2.new(1, 1)
ammoLabel.Size = UDim2.new(0, 150, 0, 40)
ammoLabel.Position = UDim2.new(1, -20, 1, -20)
ammoLabel.BackgroundTransparency = 1
ammoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ammoLabel.TextScaled = true
ammoLabel.Font = Enum.Font.GothamBold
ammoLabel.Text = "30 / 30"
ammoLabel.TextXAlignment = Enum.TextXAlignment.Right
ammoLabel.Parent = screenGui

-- [[ (E) ITEMS / INVENTORY (Middle Left) ]]
local itemsLabel = Instance.new("TextLabel")
itemsLabel.AnchorPoint = Vector2.new(0, 0.5)
itemsLabel.Size = UDim2.new(0, 60, 0, 60)
itemsLabel.Position = UDim2.new(0, 20, 0.5, 0)
itemsLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
itemsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
itemsLabel.TextSize = 14
itemsLabel.Font = Enum.Font.GothamBold
itemsLabel.Text = "ITEMS\n[ I ]"
itemsLabel.Parent = screenGui


-- [[ EVENT LISTENERS ]]
Workspace:GetAttributeChangedSignal("CurrentWave"):Connect(function()
	local currentWave = Workspace:GetAttribute("CurrentWave") or 0
	waveLabel.Text = "WAVE " .. tostring(currentWave)
end)

player:GetAttributeChangedSignal("Sausages"):Connect(function()
	local sausages = player:GetAttribute("Sausages") or 0
	sausageLabel.Text = "🥩 " .. tostring(sausages)
end)

local function HookHealth(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	healthBar.Text = "HP: " .. math.floor(humanoid.Health) .. " / " .. math.floor(humanoid.MaxHealth)
	
	humanoid.HealthChanged:Connect(function(health)
		healthBar.Text = "HP: " .. math.floor(health) .. " / " .. math.floor(humanoid.MaxHealth)
	end)
end

if player.Character then HookHealth(player.Character) end
player.CharacterAdded:Connect(HookHealth)