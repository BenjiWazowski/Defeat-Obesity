--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DataService = require(script.Parent:WaitForChild("DataService"))

local ShopService = {}

-- Safely find or create the NetworkEvents folder
local NetworkEvents = ReplicatedStorage:FindFirstChild("NetworkEvents")
if not NetworkEvents then
	NetworkEvents = Instance.new("Folder")
	NetworkEvents.Name = "NetworkEvents"
	NetworkEvents.Parent = ReplicatedStorage
end

-- Safely find or create the ShopEvent
local ShopEvent = NetworkEvents:FindFirstChild("ShopEvent")
if not ShopEvent then
	ShopEvent = Instance.new("RemoteEvent")
	ShopEvent.Name = "ShopEvent"
	ShopEvent.Parent = NetworkEvents
end

-- [[ COST CALCULATORS ]]
local function GetStatUpgradeCost(currentLevel: number): number
	return 10 + (currentLevel * 15)
end

local function GetWeaponUpgradeCost(currentLevel: number): number
	return 15 + (currentLevel * 20)
end

ShopEvent.OnServerEvent:Connect(function(player: Player, action: string, param1: any)
	local profile = DataService.GetProfile(player)
	if not profile then return end
	
	if action == "RequestData" then
		ShopEvent:FireClient(player, "UpdateShopUI", profile.Data)
		
	-- [[ 1. UPGRADE CHARACTER STATS ]]
	elseif action == "UpgradeStat" then
		local statName = param1
		if profile.Data.MetaStats[statName] == nil then return end
		
		local currentLevel = profile.Data.MetaStats[statName]
		local cost = GetStatUpgradeCost(currentLevel)
		
		if profile.Data.Sausages >= cost then
			profile.Data.Sausages -= cost
			profile.Data.MetaStats[statName] += 1
			player:SetAttribute("Sausages", profile.Data.Sausages)
			
			ShopEvent:FireClient(player, "UpdateShopUI", profile.Data)
		end
		
	-- [[ 2. WEAPON "STAR UP" (Level Up Overall Weapon) ]]
	elseif action == "UpgradeWeapon" then
		local weaponName = param1
		
		-- Convert to integer level logic
		if type(profile.Data.WeaponUpgrades[weaponName]) ~= "number" then
			profile.Data.WeaponUpgrades[weaponName] = 0
		end
		
		local currentLevel = profile.Data.WeaponUpgrades[weaponName]
		local cost = GetWeaponUpgradeCost(currentLevel)
		
		if profile.Data.Sausages >= cost then
			profile.Data.Sausages -= cost
			profile.Data.WeaponUpgrades[weaponName] = currentLevel + 1
			player:SetAttribute("Sausages", profile.Data.Sausages)
			
			ShopEvent:FireClient(player, "UpdateShopUI", profile.Data)
			print("⭐ " .. player.Name .. " Starred Up " .. weaponName .. " to Level " .. (currentLevel + 1))
		end
	end
end)

return ShopService