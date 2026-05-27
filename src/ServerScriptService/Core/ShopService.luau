--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DataService = require(script.Parent:WaitForChild("DataService"))

local ShopService = {}

local NetworkEvents = ReplicatedStorage:FindFirstChild("NetworkEvents")
if not NetworkEvents then
	NetworkEvents = Instance.new("Folder")
	NetworkEvents.Name = "NetworkEvents"
	NetworkEvents.Parent = ReplicatedStorage
end

local ShopEvent = NetworkEvents:FindFirstChild("ShopEvent") or Instance.new("RemoteEvent")
ShopEvent.Name = "ShopEvent"
ShopEvent.Parent = NetworkEvents

-- [[ COST CALCULATORS ]]
-- Formulas that scale higher with every level they buy
local function GetStatUpgradeCost(currentLevel: number): number
	return 10 + (currentLevel * 15) -- Level 0->1 costs 10, Level 1->2 costs 25, etc.
end

local function GetWeaponUpgradeCost(currentLevel: number): number
	return 15 + (currentLevel * 20) -- Level 0->1 costs 15, Level 1->2 costs 35, etc.

    ShopEvent.OnServerEvent:Connect(function(player: Player, action: string, param1: any, param2: any)
	local profile = DataService.GetProfile(player)
	if not profile then return end
	
	-- [[ 1. UPGRADE CHARACTER STATS ]]
	if action == "UpgradeStat" then
		local statName = param1
		if profile.Data.MetaStats[statName] == nil then return end
		
		local currentLevel = profile.Data.MetaStats[statName]
		local cost = GetStatUpgradeCost(currentLevel)
		
		if profile.Data.Sausages >= cost then
			profile.Data.Sausages -= cost
			profile.Data.MetaStats[statName] += 1
			player:SetAttribute("Sausages", profile.Data.Sausages)
			
			-- Fire event back to update client text displays instantly
			ShopEvent:FireClient(player, "UpdateShopUI", profile.Data)
			print("🛒 " .. player.Name .. " upgraded stat " .. statName .. " to Level " .. profile.Data.MetaStats[statName])
		end
		
	-- [[ 2. UPGRADE WEAPON BASE STATS ]]
	elseif action == "UpgradeWeapon" then
		local weaponName = param1
		local statType = param2 -- "Damage", "Speed", "Capacity", or "Range"
		
		if not profile.Data.WeaponUpgrades[weaponName] then
			profile.Data.WeaponUpgrades[weaponName] = { Damage = 0, Speed = 0, Capacity = 0, Range = 0 }
		end
		
		local currentLevel = profile.Data.WeaponUpgrades[weaponName][statType] or 0
		local cost = GetWeaponUpgradeCost(currentLevel)
		
		if profile.Data.Sausages >= cost then
			profile.Data.Sausages -= cost
			profile.Data.WeaponUpgrades[weaponName][statType] = currentLevel + 1
			player:SetAttribute("Sausages", profile.Data.Sausages)
			
			ShopEvent:FireClient(player, "UpdateShopUI", profile.Data)
			print("🛒 " .. player.Name .. " upgraded " .. weaponName .. " " .. statType .. " to Level " .. currentLevel + 1)
		end
		
	-- [[ 3. CHOOSE CLASS AND WEAPONS LOADOUT ]]
	elseif action == "SelectLoadout" then
		local classChoice = param1
		local weapon1 = param2
		local weapon2 = param3
		
		profile.Data.EquippedClass = classChoice
		profile.Data.EquippedWeapons = {weapon1, weapon2}
		print("🎒 " .. player.Name .. " locked in loadout: Class [" .. classChoice .. "] Weapons: [" .. weapon1 .. ", " .. weapon2 .. "]")
	end
end)

return ShopService