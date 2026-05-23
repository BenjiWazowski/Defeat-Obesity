--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

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
	-- Optional: We can add a sound effect here later!
end

local function CloseShop()
	menu.Visible = false
end

-- Connect the UI Buttons
openButton.MouseButton1Click:Connect(OpenShop)
closeButton.MouseButton1Click:Connect(CloseShop)

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