--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CombatService = {}

local NetworkEvents = ReplicatedStorage:FindFirstChild("NetworkEvents")
if not NetworkEvents then
	NetworkEvents = Instance.new("Folder")
	NetworkEvents.Name = "NetworkEvents"
	NetworkEvents.Parent = ReplicatedStorage
end

-- Update Event Name
local MeleeSwingEvent = Instance.new("RemoteEvent")
MeleeSwingEvent.Name = "MeleeSwingEvent"
MeleeSwingEvent.Parent = NetworkEvents

local GREYBOX_DAMAGE = 35
local DataService = require(script.Parent.Parent.Core:WaitForChild("DataService"))

MeleeSwingEvent.OnServerEvent:Connect(function(player: Player)
	local char = player.Character
	local playerRoot = char and char:FindFirstChild("HumanoidRootPart") :: BasePart
	if not playerRoot then return end
	
	-- 1. DEFINE THE HITBOX
	local hitboxSize = Vector3.new(5, 5, 5) -- A 5x5x5 invisible box
	-- Project the box exactly 3 studs in front of the player's facing direction
	local hitboxCFrame = playerRoot.CFrame * CFrame.new(0, 0, -3) 
	
	-- 2. CONFIGURE OVERLAP PARAMS
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {char} -- Don't hit yourself
	
	-- 3. SCAN FOR TARGETS
	local hitParts = Workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, overlapParams)
	
	-- We use a dictionary to ensure we don't damage the same monster twice 
	-- (e.g. if the box touches their left arm AND right arm)
	local monstersHit = {}
	
	for _, part in ipairs(hitParts) do
		local enemyModel = part:FindFirstAncestorWhichIsA("Model")
		if enemyModel and not monstersHit[enemyModel] then
			local monsterHumanoid = enemyModel:FindFirstChild("Humanoid") :: Humanoid
			
			if monsterHumanoid and monsterHumanoid.Health > 0 then
				monstersHit[enemyModel] = true
				monsterHumanoid:TakeDamage(GREYBOX_DAMAGE)
				
				if monsterHumanoid.Health <= 0 then
					local profile = DataService.GetProfile(player)
					if profile then
						profile.Data.Sausages += 1
						print("🥩 " .. player.Name .. " looted a Sausage! Total: " .. profile.Data.Sausages)
					end
				end
			end
		end
	end
end)

return CombatService