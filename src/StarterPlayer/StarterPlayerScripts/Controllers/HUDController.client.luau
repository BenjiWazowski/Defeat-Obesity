--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local mainHUD = playerGui:WaitForChild("MainHUD")

-- Hook into the base labels (Names MUST match the Studio Explorer exactly)
local waveLabel = mainHUD:WaitForChild("WaveCounter") :: TextLabel
local countdownLabel = mainHUD:WaitForChild("CountdownText") :: TextLabel
local sausageLabel = mainHUD:WaitForChild("SausageText") :: TextLabel
local skillsText = mainHUD:WaitForChild("SkillsText") :: TextLabel
local healthContainer = mainHUD:WaitForChild("HealthBarContainer") :: Frame
local healthFill = healthContainer:WaitForChild("HealthFill") :: Frame
local healthBar = healthContainer:WaitForChild("HealthText") :: TextLabel

-- Hook into the Stats Window & the 9 Stat Labels
local statsWindow = mainHUD:WaitForChild("StatsWindow") :: Frame
local statLabels = {
	Health = statsWindow:WaitForChild("MaxHPText") :: TextLabel,
	MeleeDamage = statsWindow:WaitForChild("MeleeDamageText") :: TextLabel,
	GunDamage = statsWindow:WaitForChild("GunDamageText") :: TextLabel,
	MovementSpeed = statsWindow:WaitForChild("MovementSpeedText") :: TextLabel,
	MeleeRange = statsWindow:WaitForChild("MeleeRangeText") :: TextLabel,
	AmmoCapacity = statsWindow:WaitForChild("ClipSizeText") :: TextLabel,
	Luck = statsWindow:WaitForChild("LuckText") :: TextLabel,
	MeleeSpeed = statsWindow:WaitForChild("MeleeSpeedText") :: TextLabel,
	ReloadSpeed = statsWindow:WaitForChild("ReloadSpeedText") :: TextLabel,
}

game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

-- [[ UI TOGGLE & UPDATE LOGIC ]]
local function UpdateStatsWindow()
	statLabels.Health.Text = "Max HP\n" .. math.floor(player:GetAttribute("Stat_Health") or 0)
	statLabels.MeleeDamage.Text = "Melee Damage\n" .. math.floor(player:GetAttribute("Stat_MeleeDamage") or 0)
	statLabels.GunDamage.Text = "Gun Damage\n" .. math.floor(player:GetAttribute("Stat_GunDamage") or 0)
	statLabels.MovementSpeed.Text = "Movement Speed\n" .. string.format("%.1f", player:GetAttribute("Stat_MovementSpeed") or 0)
	statLabels.MeleeRange.Text = "Melee Range\n" .. string.format("%.1f", player:GetAttribute("Stat_MeleeRange") or 0)
	statLabels.AmmoCapacity.Text = "Clip Size\n" .. math.floor(player:GetAttribute("Stat_AmmoCapacity") or 0)
	statLabels.Luck.Text = "Luck\n" .. string.format("%.2f", player:GetAttribute("Stat_Luck") or 0)
	statLabels.MeleeSpeed.Text = "Melee Speed\n" .. string.format("%.2fs", player:GetAttribute("Stat_MeleeSpeed") or 0)
	statLabels.ReloadSpeed.Text = "Reload Speed\n" .. string.format("%.2fs", player:GetAttribute("Stat_ReloadSpeed") or 0)
end

local function ToggleStatsWindow()
	statsWindow.Visible = not statsWindow.Visible
	if statsWindow.Visible then
		UpdateStatsWindow()
	end
end

-- Input Listeners for the Stats Window
skillsText.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		ToggleStatsWindow()
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end 
	if input.KeyCode == Enum.KeyCode.Z then
		ToggleStatsWindow()
	end
end)

-- [[ EVENT LISTENERS ]]
Workspace:GetAttributeChangedSignal("CurrentWave"):Connect(function()
	local currentWave = Workspace:GetAttribute("CurrentWave") or 0
	waveLabel.Text = "WAVE " .. tostring(currentWave)
end)

-- Countdown Logic
Workspace:GetAttributeChangedSignal("WaveState"):Connect(function()
	if Workspace:GetAttribute("WaveState") == "Active" then
		countdownLabel.Visible = false
	else
		countdownLabel.Visible = true
	end
end)

Workspace:GetAttributeChangedSignal("IntermissionTime"):Connect(function()
	countdownLabel.Text = "Starting in " .. tostring(Workspace:GetAttribute("IntermissionTime") or 0)
end)

player:GetAttributeChangedSignal("Sausages"):Connect(function()
	local sausages = player:GetAttribute("Sausages") or 0
	sausageLabel.Text = "" .. tostring(sausages)
end)

-- Update HookHealth to this:
local function HookHealth(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	
	local function UpdateHealthDisplay()
		local currentHealth = math.floor(humanoid.Health)
		local maxHealth = math.floor(humanoid.MaxHealth)
		
		healthBar.Text = "HP: " .. currentHealth .. " / " .. maxHealth
		
		-- Shrinks the X Scale based on percentage (0.0 to 1.0)
		local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
		healthFill.Size = UDim2.new(healthPercent, 0, 1, 0)
	end
	
	UpdateHealthDisplay()
	humanoid.HealthChanged:Connect(UpdateHealthDisplay)
end

if player.Character then HookHealth(player.Character) end
player.CharacterAdded:Connect(HookHealth)

-- [[ AMMO COUNTER LOGIC ]]
local ammoLabel = mainHUD:WaitForChild("AmmoText") :: TextLabel
local WeaponConfig = require(game:GetService("ReplicatedStorage").GameConfig:WaitForChild("WeaponConfig"))

local function UpdateAmmoUI()
	local currentAmmo = player:GetAttribute("CurrentAmmo") or 0
	local reserveAmmo = player:GetAttribute("ReserveAmmo") or 0
	
	local char = player.Character
	local tool = char and char:FindFirstChildWhichIsA("Tool")
	
	if not tool or not WeaponConfig[tool.Name] then
		ammoLabel.Text = "" 
	elseif tool.Name == "Glizzy shooter" then
		ammoLabel.Text = tostring(reserveAmmo) -- LMG only shows total pool
	else
		ammoLabel.Text = currentAmmo .. " / " .. reserveAmmo
	end
end

local function HookAmmoEvents(char: Model)
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and WeaponConfig[child.Name] then
			
			local function SyncAmmo()
				player:SetAttribute("CurrentAmmo", child:GetAttribute("CurrentAmmo") or 0)
				player:SetAttribute("ReserveAmmo", child:GetAttribute("ReserveAmmo") or 0)
				UpdateAmmoUI()
			end
			
			child:GetAttributeChangedSignal("CurrentAmmo"):Connect(SyncAmmo)
			child:GetAttributeChangedSignal("ReserveAmmo"):Connect(SyncAmmo)
			
			-- Wait a split second to ensure GunController sets the initial numbers first
			task.wait(0.05)
			SyncAmmo()
		end
	end)
	
	char.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			ammoLabel.Text = ""
		end
	end)
end

-- Catch the character if they already spawned
if player.Character then HookAmmoEvents(player.Character) end
player.CharacterAdded:Connect(HookAmmoEvents)

print("🖥️ [HUDController] Visual Interface Booted & Connected.")