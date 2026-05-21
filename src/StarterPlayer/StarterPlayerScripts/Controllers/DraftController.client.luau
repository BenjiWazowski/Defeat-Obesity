--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local NetworkEvents = ReplicatedStorage:WaitForChild("NetworkEvents")
local DraftEvent = NetworkEvents:WaitForChild("DraftEvent") :: RemoteEvent

local draftHUD = playerGui:WaitForChild("DraftHUD") :: ScreenGui
local background = draftHUD:WaitForChild("Background")
local cardContainer = background:WaitForChild("CardContainer")
local cards = {
	cardContainer:WaitForChild("Card1") :: TextButton,
	cardContainer:WaitForChild("Card2") :: TextButton,
	cardContainer:WaitForChild("Card3") :: TextButton
}

local isDrafting = false

-- Opens the menu and populates the 3 cards
DraftEvent.OnClientEvent:Connect(function(skillOptions: {any})
	if isDrafting then return end
	isDrafting = true
	
	-- Populate the UI
	for i = 1, 3 do
		local skillData = skillOptions[i]
		local card = cards[i]
		
		local nameLabel = card:WaitForChild("SkillName") :: TextLabel
		local descLabel = card:WaitForChild("SkillDescription") :: TextLabel
		
		nameLabel.Text = skillData.Name
		descLabel.Text = skillData.Description
		
		-- Color code by rarity
		if skillData.Rarity == "Epic" then
			nameLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
		else
			nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White
		end
		
		-- Clean up old connections if they exist
		for _, conn in ipairs(card:GetConnections("MouseButton1Click")) do
			conn:Disconnect()
		end
		
		-- Listen for player choice
		card.MouseButton1Click:Connect(function()
			if not isDrafting then return end
			isDrafting = false
			draftHUD.Enabled = false
			
			-- Tell the server which skill we picked
			DraftEvent:FireServer(skillData.Name)
		end)
	end
	
	draftHUD.Enabled = true
end)

print("🃏 [DraftController] Ready to receive skills.")