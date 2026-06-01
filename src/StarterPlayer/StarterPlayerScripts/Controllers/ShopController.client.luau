--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- FIX: Wait for the 3D map to load before checking for the Lobby!
local elevator = Workspace:WaitForChild("MatchmakingElevator", 5)
if not elevator then 
	print("⚔️ [ShopController] Not in Lobby. Shop disabled.")
	return 
end

local mainHUD = playerGui:WaitForChild("MainHUD")
local shopHUD = playerGui:WaitForChild("ShopHUD")

local menu = shopHUD:WaitForChild("Menu") :: Frame
local closeButton = menu:WaitForChild("CloseButton") :: TextButton
local backButton = menu:WaitForChild("BackButton") :: TextButton
local openButton = mainHUD:WaitForChild("OpenShopButton") :: TextButton

local homePanel = menu:WaitForChild("HomePanel") :: Frame
local statsBtn = homePanel:WaitForChild("CharacterStatsBtn") :: TextButton
local weaponsBtn = homePanel:WaitForChild("WeaponsBtn") :: TextButton

local statsPanel = menu:WaitForChild("StatsPanel") :: ScrollingFrame
local weaponsPanel = menu:WaitForChild("WeaponsPanel") :: ScrollingFrame
local weaponTemplate = weaponsPanel:WaitForChild("WeaponTemplate") :: Frame

local shopNPC = Workspace:WaitForChild("ShopNPC", 10)
local shopPrompt = shopNPC and shopNPC:FindFirstChildWhichIsA("ProximityPrompt", true) :: ProximityPrompt

local NetworkEvents = ReplicatedStorage:WaitForChild("NetworkEvents")
local ShopEvent = NetworkEvents:WaitForChild("ShopEvent") :: RemoteEvent
local WeaponConfig = require(ReplicatedStorage.GameConfig:WaitForChild("WeaponConfig"))

local function getStatCost(level: number) return 10 + (level * 15) end
local function getWeaponCost(level: number) return 15 + (level * 20) end

local favoriteWeapons = {} 

-- [[ 1. PAGE NAVIGATION LOGIC ]]
local function ShowPage(page: string)
	homePanel.Visible = (page == "Home")
	statsPanel.Visible = (page == "Stats")
	weaponsPanel.Visible = (page == "Weapons")
	backButton.Visible = (page ~= "Home")
end

statsBtn.MouseButton1Click:Connect(function() ShowPage("Stats") end)
weaponsBtn.MouseButton1Click:Connect(function() ShowPage("Weapons") end)
backButton.MouseButton1Click:Connect(function() ShowPage("Home") end)

-- [[ 2. AUTO-GENERATE WEAPONS LIST ]]
for weaponName, _ in pairs(WeaponConfig) do
	local newCard = weaponTemplate:Clone()
	newCard.Name = weaponName
	newCard.Visible = true
	newCard.Parent = weaponsPanel
	
	local title = newCard:WaitForChild("Title") :: TextLabel
	local upgBtn = newCard:WaitForChild("UpgradeBtn") :: TextButton
	local favBtn = newCard:WaitForChild("FavoriteBtn") :: TextButton
	
	title.Text = weaponName
	newCard.LayoutOrder = 1 
	
	upgBtn.MouseButton1Click:Connect(function()
		ShopEvent:FireServer("UpgradeWeapon", weaponName)
	end)
	
	favBtn.MouseButton1Click:Connect(function()
		favoriteWeapons[weaponName] = not favoriteWeapons[weaponName]
		-- Favorites jump to the top (LayoutOrder -1)
		newCard.LayoutOrder = favoriteWeapons[weaponName] and -1 or 1
		favBtn.TextColor3 = favoriteWeapons[weaponName] and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 255, 255)
	end)
end

-- [[ 3. WIRE STAT BUTTONS ]]
for _, statFrame in ipairs(statsPanel:GetChildren()) do
	if statFrame:IsA("Frame") then
		local upgBtn = statFrame:WaitForChild("UpgradeBtn") :: TextButton
		upgBtn.MouseButton1Click:Connect(function()
			ShopEvent:FireServer("UpgradeStat", statFrame.Name)
		end)
	end
end

-- [[ 4. DYNAMIC DATA UPDATES ]]
ShopEvent.OnClientEvent:Connect(function(actionType: string, updatedData: any)
	if actionType == "UpdateShopUI" then
		-- Update Stats
		for _, statFrame in ipairs(statsPanel:GetChildren()) do
			if statFrame:IsA("Frame") then
				local lvl = updatedData.MetaStats[statFrame.Name] or 0
				local levelText = statFrame:FindFirstChild("LevelText") :: TextLabel
				local costText = statFrame:FindFirstChild("CostText") :: TextLabel
				if levelText then levelText.Text = "Lvl " .. lvl end
				if costText then costText.Text = getStatCost(lvl) .. " Sausages" end
			end
		end
		
		-- Update Weapons
		for _, weaponFrame in ipairs(weaponsPanel:GetChildren()) do
			if weaponFrame:IsA("Frame") and weaponFrame.Name ~= "WeaponTemplate" then
				local wData = updatedData.WeaponUpgrades[weaponFrame.Name]
				local lvl = (type(wData) == "number") and wData or 0
				
				local levelText = weaponFrame:FindFirstChild("LevelText") :: TextLabel
				local costText = weaponFrame:FindFirstChild("CostText") :: TextLabel
				if levelText then levelText.Text = "⭐ " .. lvl end
				if costText then costText.Text = getWeaponCost(lvl) .. " Sausages" end
			end
		end
	end
end)

-- [[ 5. SHOP TOGGLE LOGIC ]]
local dataLoaded = false
local function ToggleShop()
	menu.Visible = not menu.Visible
	if menu.Visible then
		ShowPage("Home")
		if not dataLoaded then
			ShopEvent:FireServer("RequestData")
			dataLoaded = true
		end
	end
end

openButton.MouseButton1Click:Connect(ToggleShop)
closeButton.MouseButton1Click:Connect(function() menu.Visible = false end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end 
	if input.KeyCode == Enum.KeyCode.E then ToggleShop() end
end)

if shopPrompt then
	shopPrompt.Triggered:Connect(function(p) if p == player then ToggleShop() end end)
end

print("🛒 [ShopController] Shop interface wired and ready.")