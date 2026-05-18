--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Grab the UI you built in Studio (synced via Rojo)
local mainHUD = playerGui:WaitForChild("MainHUD")

-- Hook into the specific labels
local waveLabel = mainHUD:WaitForChild("WaveText") :: TextLabel
local sausageLabel = mainHUD:WaitForChild("SausageText") :: TextLabel
local healthBar = mainHUD:WaitForChild("HealthText") :: TextLabel

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

print("🖥️ [HUDController] Visual Interface Booted & Connected.")