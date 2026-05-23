--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Hook into the UI elements
local mainHUD = playerGui:WaitForChild("MainHUD")
local shopHUD = playerGui:WaitForChild("ShopHUD")

local menu = shopHUD:WaitForChild("Menu") :: Frame
local closeButton = menu:WaitForChild("CloseButton") :: TextButton
local openButton = mainHUD:WaitForChild("OpenShopButton") :: TextButton

-- Hook into the Workspace NPC
local shopNPC = Workspace:WaitForChild("ShopNPC", 10)
local shopPrompt = shopNPC and shopNPC:FindFirstChildWhichIsA("ProximityPrompt", true) :: ProximityPrompt

local function OpenShop()
	menu.Visible = true
end

local function CloseShop()
	menu.Visible = false
end

local function ToggleShop()
	menu.Visible = not menu.Visible
end

-- Connect the UI Buttons
openButton.MouseButton1Click:Connect(OpenShop)
closeButton.MouseButton1Click:Connect(CloseShop)

-- Connect the Hotkey [E]
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- gameProcessed prevents the menu from opening if they are typing 'e' in the chat!
	if gameProcessed then return end 
	
	if input.KeyCode == Enum.KeyCode.E then
		ToggleShop()
	end
end)

-- Connect the NPC Proximity Prompt
if shopPrompt then
	shopPrompt.Triggered:Connect(function(playerWhoTriggered)
		if playerWhoTriggered == player then
			OpenShop()
		end
	end)
else
	warn("[ShopController] ShopPrompt not found on the ShopNPC!")
end

print("🛒 [ShopController] Shop interface wired and ready.")