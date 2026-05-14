--!strict
print("====================================")
print("[Bootstrapper] Igniting Server Services...")
print("====================================")

-- Require the modules to force their mainline code to execute
local DataService = require(script.Parent.Core:WaitForChild("DataService"))
local MatchmakingService = require(script.Parent.Core:WaitForChild("MatchmakingService"))
local WaveManager = require(script.Parent.Environment:WaitForChild("WaveManager"))

print("[Bootstrapper] All systems green. Server is live.")