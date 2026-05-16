--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local CombatService = {}

-- [[ NETWORK INITIALIZATION ]]
-- We dynamically create the RemoteEvent folder on boot so Rojo doesn't delete it
local NetworkEvents = ReplicatedStorage:FindFirstChild("NetworkEvents")
if not NetworkEvents then
	NetworkEvents = Instance.new("Folder")
	NetworkEvents.Name = "NetworkEvents"
	NetworkEvents.Parent = ReplicatedStorage
end

local MeleeHitEvent = Instance.new("RemoteEvent")
MeleeHitEvent.Name = "MeleeHitEvent"
MeleeHitEvent.Parent = NetworkEvents

-- [[ COMBAT CONFIGURATION ]]
local MAX_MELEE_RANGE = 12 -- The anti-cheat distance limit (Studs)
local GREYBOX_DAMAGE = 35

-- Import DataService to award Sausages
local DataService = require(script.Parent.Parent.Core:WaitForChild("DataService"))

-- [[ THE GROUND TRUTH VALIDATOR ]]
MeleeHitEvent.OnServerEvent:Connect(function(player: Player, targetModel: any)
	-- 1. Validate the target exists and is a character
	if not targetModel or typeof(targetModel) ~= "Instance" then return end
	
	local monsterRoot = targetModel:FindFirstChild("HumanoidRootPart") :: BasePart
	local monsterHumanoid = targetModel:FindFirstChild("Humanoid") :: Humanoid
	if not monsterRoot or not monsterHumanoid or monsterHumanoid.Health <= 0 then return end
	
	-- 2. Validate the player exists and is alive
	local char = player.Character
	local playerRoot = char and char:FindFirstChild("HumanoidRootPart") :: BasePart
	if not playerRoot then return end
	
	-- 3. SANITY CHECK: Calculate exact physical distance
	local distance = (playerRoot.Position - monsterRoot.Position).Magnitude
	
	if distance <= MAX_MELEE_RANGE then
		-- VALID HIT: Apply damage
		monsterHumanoid:TakeDamage(GREYBOX_DAMAGE)
		
		-- Check if this specific hit killed the monster
		if monsterHumanoid.Health <= 0 then
			local profile = DataService.GetProfile(player)
			if profile then
				profile.Data.Sausages += 1
				print("🥩 " .. player.Name .. " looted a Sausage! Total: " .. profile.Data.Sausages)
			end
		end
	else
		-- INVALID HIT: Player is too far away. Ignore the hit.
		-- warn("[Anti-Cheat] " .. player.Name .. " attempted to hit a monster from " .. math.floor(distance) .. " studs away!")
	end
end)

return CombatService