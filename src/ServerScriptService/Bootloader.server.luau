--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. CREATE NETWORK EVENTS BEFORE ANYTHING ELSE LOADS
local NetworkEvents = ReplicatedStorage:FindFirstChild("NetworkEvents")
if not NetworkEvents then
	NetworkEvents = Instance.new("Folder")
	NetworkEvents.Name = "NetworkEvents"
	NetworkEvents.Parent = ReplicatedStorage
end

local function EnsureEventExists(eventName: string)
	local event = NetworkEvents:FindFirstChild(eventName) or Instance.new("RemoteEvent")
	event.Name = eventName
	event.Parent = NetworkEvents
end

EnsureEventExists("ShootEvent")
EnsureEventExists("ReloadEvent")
EnsureEventExists("DraftEvent")
EnsureEventExists("MeleeSwingEvent")

print("====================================")
print("[Bootstrapper] Igniting Server Services...")
print("====================================")

local DataService = require(script.Parent.Core:WaitForChild("DataService"))
local MatchmakingService = require(script.Parent.Core:WaitForChild("MatchmakingService"))
local WaveManager = require(script.Parent.Environment:WaitForChild("WaveManager"))
local CombatService = require(script.Parent.Combat:WaitForChild("CombatService"))
local StatManager = require(script.Parent.Core:WaitForChild("StatManager"))
local WeaponService = require(script.Parent.Combat:WaitForChild("WeaponService"))
local DropService = require(script.Parent.Environment:WaitForChild("DropService"))

print("[Bootstrapper] All systems green. Server is live.")