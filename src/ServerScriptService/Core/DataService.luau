--!strict
local Players = game:GetService("Players")

-- WARNING: ProfileStore.luau MUST be located in the exact same folder as this script.
local ProfileStore = require(script.Parent:WaitForChild("ProfileStore"))

local DataService = {}
DataService.Profiles = {}

-- The strict data schema. New players will inherit this exact structure.
local ProfileTemplate = {
	Sausages = 0,
	Donuts = 0,
	Level = 1,
	Experience = 0,
	EquippedClass = "Regular guy",
	UnlockedClasses = {"Regular guy"},
	EquippedWeapons = {"Basic Spatula", "Empty Hand"}, -- The 2 selected weapons for the match
	Inventory = {"Basic Spatula"} -- Permanent unlocks
}

-- Initialize the ProfileStore
local PlayerStore = ProfileStore.New(
	"PlayerData_v1",
	ProfileTemplate
)

local function PlayerAdded(player: Player)
	-- ProfileStore uses StartSessionAsync instead of LoadProfileAsync
	local profile = PlayerStore:StartSessionAsync("Player_" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile ~= nil then
		profile:AddUserId(player.UserId) 
		profile:Reconcile() -- Fills in missing variables from ProfileTemplate for older players
		
		-- ProfileStore uses OnSessionEnd instead of ListenToRelease
		profile.OnSessionEnd:Connect(function()
			DataService.Profiles[player] = nil
			player:Kick("Data session was terminated. Please rejoin.")
		end)
		
		if player:IsDescendantOf(Players) == true then
			DataService.Profiles[player] = profile
			print("✅ Data successfully loaded for: " .. player.Name)
		else
			-- Edge Case: Player left the game before their data finished loading.
			profile:EndSession()
		end
	else
		-- Edge Case: Roblox Datastores are down or session is locked in another server.
		player:Kick("Failed to load data. The Roblox datastores might be experiencing issues. Please try again.") 
	end
end

local function PlayerRemoving(player: Player)
	local profile = DataService.Profiles[player]
	if profile ~= nil then
		profile:EndSession()
	end
end

-- Server API: Get a player's profile data safely
function DataService.GetProfile(player: Player)
	return DataService.Profiles[player]
end

Players.PlayerAdded:Connect(PlayerAdded)
Players.PlayerRemoving:Connect(PlayerRemoving)

-- Edge Case Catch: Handle players who loaded in before the script executed in Studio
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(PlayerAdded, player)
end

return DataService