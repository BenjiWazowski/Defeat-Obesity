--!strict
print("====================================")
print("[Bootstrapper] Igniting Server Services...")
print("====================================")

local DataService = require(script.Parent.Core:WaitForChild("DataService"))
local MatchmakingService = require(script.Parent.Core:WaitForChild("MatchmakingService"))
local WaveManager = require(script.Parent.Environment:WaitForChild("WaveManager"))
local CombatService = require(script.Parent.Combat:WaitForChild("CombatService"))
local StatManager = require(script.Parent.Core:WaitForChild("StatManager"))
local WeaponService = require(script.Parent.Combat:WaitForChild("WeaponService"))

print("[Bootstrapper] All systems green. Server is live.")