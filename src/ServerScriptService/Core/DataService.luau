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
	
	-- Loadout selections
	EquippedClass = "Regular guy",
	EquippedWeapons = {"AK 67", "Basic Spatula"}, -- Default starting loadout slots
	
	-- Unlocks list
	UnlockedClasses = {"Regular guy"},
	Inventory = {"AK 67", "Basic Spatula"},
	
	-- PERMANENT META-UPGRADES (PHASE 9)
	MetaStats = {
		Health = 0,
		MeleeDamage = 0,
		MeleeRange = 0,
		MeleeSpeed = 0,
		GunDamage = 0,
		ReloadSpeed = 0,
		AmmoCapacity = 0,
		MovementSpeed = 0,
		Luck = 0
	},
	WeaponUpgrades = {
		-- Example structure filled dynamically: ["AK 67"] = { Damage = 0, Speed = 0, Capacity = 0, Range = 0 }
	}
}

-- Initialize the ProfileStore
local PlayerStore = ProfileStore.New(
	"PlayerData_v2", -- Incremented version to ensure fresh setup integration
	ProfileTemplate
)

local function PlayerAdded(player: Player)
	local profile = PlayerStore:StartSessionAsync("Player_" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile ~= nil then
		profile:AddUserId(player.UserId) 
		profile:Reconcile() -- Fills in missing variables from ProfileTemplate for older profiles smoothly
		
		-- Sync Sausages value to attribute for UI visibility immediately
		player:SetAttribute("Sausages", profile.Data.Sausages)
		
		-- ProfileStore uses OnSessionEnd instead of ListenToRelease
		profile.OnSessionEnd:Connect(function()
			DataService.Profiles[player] = nil
			if not player:GetAttribute("IsTeleporting") then
				player:Kick("Data session was terminated. Please rejoin.")
			end
		end)
		
		if player:IsDescendantOf(Players) == true then
			DataService.Profiles[player] = profile
			print("✅ Data successfully loaded for: " .. player.Name)
		else
			profile:EndSession()
		end
	else
		player:Kick("Failed to load data. The Roblox datastores might be experiencing issues. Please try again.") 
	end
end

local function PlayerRemoving(player: Player)
	local profile = DataService.Profiles[player]
	if profile ~= nil then
		profile:EndSession()
	end
end

function DataService.GetProfile(player: Player)
	return DataService.Profiles[player]
end

Players.PlayerAdded:Connect(PlayerAdded)
Players.PlayerRemoving:Connect(PlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(PlayerAdded, player)
end

return DataService