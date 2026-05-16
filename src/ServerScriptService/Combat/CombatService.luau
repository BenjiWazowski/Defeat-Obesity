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

local MeleeSwingEvent = Instance.new("RemoteEvent")
MeleeSwingEvent.Name = "MeleeSwingEvent"
MeleeSwingEvent.Parent = NetworkEvents

local DataService = require(script.Parent.Parent.Core:WaitForChild("DataService"))
local StatManager = require(script.Parent.Parent.Core:WaitForChild("StatManager"))

local PlayerCooldowns = {}

MeleeSwingEvent.OnServerEvent:Connect(function(player: Player)
	local char = player.Character
	local playerRoot = char and char:FindFirstChild("HumanoidRootPart") :: BasePart
	if not playerRoot then return end
	
	-- 1. FETCH DYNAMIC STATS
	local activeStats = StatManager.GetActiveStats(player)
	
	-- 2. ANTI-CHEAT: Cooldown enforcement
	local lastSwing = PlayerCooldowns[player.UserId] or 0
	if os.clock() - lastSwing < activeStats.MeleeSpeed then
		return -- Silently drop the exploiter's request
	end
	PlayerCooldowns[player.UserId] = os.clock()
	
	-- 3. DEFINE THE HITBOX DYNAMICALLY
	local range = activeStats.MeleeRange
	local hitboxSize = Vector3.new(range, 5, range) 
	local hitboxCFrame = playerRoot.CFrame * CFrame.new(0, 0, -(range/2 + 1)) 
	
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {char} 
	
	local hitParts = Workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, overlapParams)
	local monstersHit = {}
	
	for _, part in ipairs(hitParts) do
		local enemyModel = part:FindFirstAncestorWhichIsA("Model")
		if enemyModel and not monstersHit[enemyModel] then
			local monsterHumanoid = enemyModel:FindFirstChild("Humanoid") :: Humanoid
			
			if monsterHumanoid and monsterHumanoid.Health > 0 then
				monstersHit[enemyModel] = true
				
				-- 4. APPLY DYNAMIC DAMAGE
				monsterHumanoid:TakeDamage(activeStats.MeleeDamage)
				
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