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

-- Hidden button to automatically free the mouse when drafting
local draftModal = Instance.new("TextButton")
draftModal.Size = UDim2.new(0, 0, 0, 0)
draftModal.BackgroundTransparency = 1
draftModal.Text = ""
draftModal.Modal = true
draftModal.Visible = false
draftModal.Parent = draftHUD

local isDrafting = false
local cardConnections = {} 

DraftEvent.OnClientEvent:Connect(function(skillOptions: any)
	if type(skillOptions) == "string" and skillOptions == "Close" then
		isDrafting = false
		draftHUD.Enabled = false
		draftModal.Visible = false -- Lock the mouse again
		return
	end
	
	if isDrafting then return end
	isDrafting = true
	
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
			draftModal.Visible = false -- Lock the mouse again
			DraftEvent:FireServer(skillData.Name)
		end)
		table.insert(cardConnections, conn)
	end
	
	draftHUD.Enabled = true
	draftModal.Visible = true -- Free the mouse automatically!
end)

print("🃏 [DraftController] Ready to receive skills.")