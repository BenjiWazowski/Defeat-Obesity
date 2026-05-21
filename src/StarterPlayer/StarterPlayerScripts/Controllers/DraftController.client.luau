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
local cardConnections = {} -- Securely stores click connections

DraftEvent.OnClientEvent:Connect(function(skillOptions: any)
	-- Listen for the Server forcing the menu closed on timeout
	if type(skillOptions) == "string" and skillOptions == "Close" then
		isDrafting = false
		draftHUD.Enabled = false
		return
	end
	
	if isDrafting then return end
	isDrafting = true
	
	-- Clear old connections securely
	for _, conn in ipairs(cardConnections) do
		conn:Disconnect()
	end
	table.clear(cardConnections)
	
	for i = 1, 3 do
		local skillData = skillOptions[i]
		local card = cards[i]
		
		local nameLabel = card:WaitForChild("SkillName") :: TextLabel
		local descLabel = card:WaitForChild("SkillDescription") :: TextLabel
		
		nameLabel.Text = skillData.Name
		descLabel.Text = skillData.Description
		nameLabel.TextColor3 = skillData.Rarity == "Epic" and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 255, 255)
		
		local conn = card.MouseButton1Click:Connect(function()
			if not isDrafting then return end
			isDrafting = false
			draftHUD.Enabled = false
			DraftEvent:FireServer(skillData.Name)
		end)
		table.insert(cardConnections, conn)
	end
	
	draftHUD.Enabled = true
end)

print("🃏 [DraftController] Ready to receive skills.")