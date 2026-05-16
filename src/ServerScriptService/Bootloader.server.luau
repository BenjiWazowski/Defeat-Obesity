--!strict
print("====================================")
print("[Bootstrapper] Igniting Server Service 1...")
print("====================================")

-- Require the modules to force their mainline code to execute
local DataService = require(script.Parent.Core:WaitForChild("DataService"))
local MatchmakingService = require(script.Parent.Core:WaitForChild("MatchmakingService"))
local WaveManager = require(script.Parent.Environment:WaitForChild("WaveManager"))

--!strict
print("====================================")
print("[Bootstrapper] Igniting Server Service 2...")
print("====================================")

local DataService = require(script.Parent.Core:WaitForChild("DataService"))
local MatchmakingService = require(script.Parent.Core:WaitForChild("MatchmakingService"))
local WaveManager = require(script.Parent.Environment:WaitForChild("WaveManager"))

-- IGNITE THE COMBAT ENGINE
local CombatService = require(script.Parent.Combat:WaitForChild("CombatService"))
-- START THE STAT MANAGER
local StatManager = require(script.Parent.Core:WaitForChild("StatManager"))

print("[Bootstrapper] All systems green. Server is live.")