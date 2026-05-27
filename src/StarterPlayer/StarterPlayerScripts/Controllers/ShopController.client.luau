--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local isLobby = Workspace:FindFirstChild("MatchmakingElevator") ~= nil
if not isLobby then return end

local mainHUD = playerGui:WaitForChild("MainHUD")
local shopHUD = playerGui:WaitForChild("ShopHUD")

local menu = shopHUD:WaitForChild("Menu") :: Frame
local closeButton = menu:WaitForChild("CloseButton") :: TextButton
local statsWindow = mainHUD:WaitForChild("StatsWindow")
local openButton = statsWindow:WaitForChild("OpenShopButton") :: TextButton

local shopNPC = Workspace:WaitForChild("ShopNPC", 10)
local shopPrompt = shopNPC and shopNPC:FindFirstChildWhichIsA("ProximityPrompt", true) :: ProximityPrompt

local NetworkEvents = ReplicatedStorage:WaitForChild("NetworkEvents")
local ShopEvent = NetworkEvents:WaitForChild("ShopEvent") :: RemoteEvent

-- [[ DYNAMIC UI WIRING ]]
local statsPanel = menu:WaitForChild("StatsPanel") :: ScrollingFrame

local function getStatCost(level: number) return 10 + (level * 15) end

-- 1. Automatically wire every upgrade button in the panel
for _, statFrame in ipairs(statsPanel:GetChildren()) do
	if statFrame:IsA("Frame") then
		local statName = statFrame.Name -- e.g., "Health", "MeleeDamage"
		local upgradeBtn = statFrame:WaitForChild("UpgradeBtn") :: TextButton
		
		upgradeBtn.MouseButton1Click:Connect(function()
			ShopEvent:FireServer("UpgradeStat", statName)
		end)
	end
end

-- 2. Update the text labels when the server sends new purchase data
ShopEvent.OnClientEvent:Connect(function(actionType: string, updatedData: any)
	if actionType == "UpdateShopUI" then
		for _, statFrame in ipairs(statsPanel:GetChildren()) do
			if statFrame:IsA("Frame") then
				local statName = statFrame.Name
				local lvl = updatedData.MetaStats[statName] or 0
				local cost = getStatCost(lvl)
				
				local levelText = statFrame:FindFirstChild("LevelText") :: TextLabel
				local costText = statFrame:FindFirstChild("CostText") :: TextLabel
				
				if levelText then levelText.Text = "Lvl " .. lvl end
				if costText then costText.Text = cost .. " Sausages" end
			end
		end
		print("✨ Shop UI refreshed with latest data levels.")
	end
end)

-- [[ SHOP TOGGLE LOGIC ]]
local dataLoaded = false

local function OpenShop()
	menu.Visible = true
	-- Fetch the player's saved levels the very first time they open the menu
	if not dataLoaded then
		ShopEvent:FireServer("RequestData")
		dataLoaded = true
	end
end

local function CloseShop() menu.Visible = false end
local function ToggleShop()
	if menu.Visible then CloseShop() else OpenShop() end
end

openButton.MouseButton1Click:Connect(OpenShop)
closeButton.MouseButton1Click:Connect(CloseShop)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end 
	if input.KeyCode == Enum.KeyCode.E then ToggleShop() end
end)

if shopPrompt then
	shopPrompt.Triggered:Connect(function(p) if p == player then OpenShop() end end)
end

print("🛒 [ShopController] Shop interface wired and ready.")