--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent:WaitForChild("DataService"))

local LoadoutManager = {}

local weaponFolder = ReplicatedStorage:WaitForChild("Weapons")

local function InjectLoadout(player: Player, character: Model)
	local profile = DataService.GetProfile(player)
	if not profile then return end
	
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return end
	
	-- Clear out any existing weapons just in case
	backpack:ClearAllChildren()
	for _, tool in ipairs(character:GetChildren()) do
		if tool:IsA("Tool") then tool:Destroy() end
	end
	
	-- Grant the weapons they chose in the Lobby
	local equippedWeapons = profile.Data.EquippedWeapons
	for _, weaponName in ipairs(equippedWeapons) do
		local weaponTemplate = weaponFolder:FindFirstChild(weaponName)
		if weaponTemplate then
			local newWeapon = weaponTemplate:Clone()
			newWeapon.Parent = backpack
			print("🎒 Granted " .. weaponName .. " to " .. player.Name)
		else
			warn("⚠️ Weapon " .. weaponName .. " not found in ReplicatedStorage.Weapons!")
		end
	end
end

-- Listen for players spawning in to give them their gear
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		-- Wait a split second to ensure their Data Profile is fully loaded
		task.wait(0.5) 
		InjectLoadout(player, character)
	end)
end)

return LoadoutManager