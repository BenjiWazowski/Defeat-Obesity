--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Lobby check to isolate scripts from Arena environments
local isLobby = Workspace:FindFirstChild("MatchmakingElevator") ~= nil
if not isLobby then return end

local mainHUD = playerGui:WaitForChild("MainHUD")
local shopHUD = playerGui:WaitForChild("ShopHUD")

local menu = shopHUD:WaitForChild("Menu") :: Frame
local closeButton = menu:WaitForChild("CloseButton") :: TextButton
local openButton = mainHUD:WaitForChild("OpenShopButton") :: TextButton

local shopNPC = Workspace:WaitForChild("ShopNPC", 10)
local shopPrompt = shopNPC and shopNPC:FindFirstChildWhichIsA("ProximityPrompt", true) :: ProximityPrompt

local NetworkEvents = ReplicatedStorage:WaitForChild("NetworkEvents")
local ShopEvent = NetworkEvents:WaitForChild("ShopEvent") :: RemoteEvent

local function ToggleShop()
	menu.Visible = not menu.Visible
end

openButton.MouseButton1Click:Connect(function() menu.Visible = true end)
closeButton.MouseButton1Click:Connect(function() menu.Visible = false end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end 
	if input.KeyCode == Enum.KeyCode.E then
		ToggleShop()
	end
end)

if shopPrompt then
	shopPrompt.Triggered:Connect(function(playerWhoTriggered)
		if playerWhoTriggered == player then menu.Visible = true end
	end)
end

-- [[ INTERFACE INTERACTION HANDLERS ]]
-- Generic helper functions you can attach directly to UI click instances
local function RequestStatUpgrade(statName: string)
	ShopEvent:FireServer("UpgradeStat", statName)
end

local function RequestWeaponUpgrade(weaponName: string, statType: string)
	ShopEvent:FireServer("UpgradeWeapon", weaponName, statType)
end

local function SaveLoadoutSelection(className: string, w1: string, w2: string)
	ShopEvent:FireServer("SelectLoadout", className, w1, w2)
end

-- Listen for server validation updates to refresh lists dynamically
ShopEvent.OnClientEvent:Connect(function(actionType: string, updatedData: any)
	if actionType == "UpdateShopUI" then
		-- This is where we will hook up display changes to numbers/costs in the next phase!
		print("✨ Shop UI refreshed with latest data levels.")
	end
end)

print("🛒 [ShopController] Comprehensive shop systems initialized.")