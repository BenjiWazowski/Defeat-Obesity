--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local DropService = {}

local StatManager = require(script.Parent.Parent.Core:WaitForChild("StatManager"))
local WeaponConfig = require(ReplicatedStorage.GameConfig:WaitForChild("WeaponConfig"))

local BASE_DROP_CHANCE = 0.06 -- 6% base chance

-- Consolidated Loot Table out of 100%
local LOOT_TABLE = {
	{ Name = "Small Health", Category = "Health", Weight = 35, ValuePct = 0.25, Color = Color3.fromRGB(100, 255, 100) },
	{ Name = "Small Ammo", Category = "Ammo", Weight = 35, ValuePct = 0.30, Color = Color3.fromRGB(100, 150, 255) },
	{ Name = "Medium Health", Category = "Health", Weight = 10, ValuePct = 0.45, Color = Color3.fromRGB(50, 200, 50) },
	{ Name = "Medium Ammo", Category = "Ammo", Weight = 15, ValuePct = 0.70, Color = Color3.fromRGB(50, 100, 255) },
	{ Name = "Large Health", Category = "Health", Weight = 2, ValuePct = 0.70, Color = Color3.fromRGB(255, 215, 0) },
	{ Name = "Max Ammo", Category = "Ammo", Weight = 3, ValuePct = 1.00, Color = Color3.fromRGB(255, 215, 0) }
}

local function GetRandomDrop()
	local roll = math.random(1, 100)
	local currentWeight = 0
	for _, dropData in ipairs(LOOT_TABLE) do
		currentWeight += dropData.Weight
		if roll <= currentWeight then
			return dropData
		end
	end
	return LOOT_TABLE[1] -- Fallback
end

local function SpawnPhysicalDrop(position: Vector3, dropData: any)
	local dropPart = Instance.new("Part")
	dropPart.Name = string.gsub(dropData.Name, " ", "") .. "Drop"
	dropPart.Size = Vector3.new(2, 2, 2)
	dropPart.Position = position + Vector3.new(0, 3, 0) 
	dropPart.Anchored = true
	dropPart.CanCollide = false
	dropPart.Material = Enum.Material.Neon
	dropPart.Color = dropData.Color
	
	dropPart.Parent = Workspace
	
	task.spawn(function()
		while dropPart.Parent do
			dropPart.CFrame = dropPart.CFrame * CFrame.Angles(0, math.rad(2), 0)
			task.wait(0.03)
		end
	end)
	
	task.delay(20, function()
		if dropPart.Parent then dropPart:Destroy() end
	end)
	
	local db = false
	dropPart.Touched:Connect(function(hit)
		if db then return end
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			db = true
			dropPart:Destroy()
			
			print("\n🎁 " .. player.Name .. " picked up a [" .. dropData.Name .. "]! Sharing with team...")
			
			for _, teamPlayer in ipairs(Players:GetPlayers()) do
				local char = teamPlayer.Character
				if char then
					if dropData.Category == "Health" then
						local humanoid = char:FindFirstChild("Humanoid") :: Humanoid
						if humanoid and humanoid.Health > 0 then
							local healAmount = humanoid.MaxHealth * dropData.ValuePct
							local previousHealth = humanoid.Health
							humanoid.Health = math.min(humanoid.Health + healAmount, humanoid.MaxHealth)
							print("   -> 🟢 Healed " .. teamPlayer.Name .. " for " .. math.floor(humanoid.Health - previousHealth) .. " HP")
						end
						
					elseif dropData.Category == "Ammo" then
						local items = {}
						for _, v in ipairs(char:GetChildren()) do table.insert(items, v) end
						for _, v in ipairs(teamPlayer:WaitForChild("Backpack"):GetChildren()) do table.insert(items, v) end
						
						for _, tool in ipairs(items) do
							if tool:IsA("Tool") and WeaponConfig[tool.Name] then
								local config = WeaponConfig[tool.Name]
								local currentWave = Workspace:GetAttribute("CurrentWave") or 1
								local decayRate = 0.1
								local maxReserveClips = math.floor(config.ReserveClips.Cap - ((config.ReserveClips.Cap - config.ReserveClips.Base) * math.pow(1 - decayRate, currentWave - 1)))
								local clipSize = math.floor(config.ClipSize.Cap - ((config.ClipSize.Cap - config.ClipSize.Base) * math.pow(1 - decayRate, currentWave - 1)))
								
								local totalMaxReserve = maxReserveClips * clipSize
								if tool.Name == "Glizzy shooter" then totalMaxReserve = maxReserveClips end
								
								local currentReserve = tool:GetAttribute("ReserveAmmo") or totalMaxReserve
								local ammoToGive = math.floor(totalMaxReserve * dropData.ValuePct)
								
								local newReserve = math.min(currentReserve + ammoToGive, totalMaxReserve)
								tool:SetAttribute("ReserveAmmo", newReserve)
								
								print("   -> 🔵 Restored " .. (newReserve - currentReserve) .. " reserve ammo for " .. teamPlayer.Name .. "'s " .. tool.Name)
							end
						end
					end
				end
			end
		end
	end)
end

function DropService.RollForDrop(monsterPosition: Vector3, player: Player)
	local luckStat = player:GetAttribute("Stat_Luck") or 1.0
	local finalChance = BASE_DROP_CHANCE * luckStat
	
	if math.random() <= finalChance * 100 / 100 then -- Math.random() is 0 to 1, finalChance is 0.06
		local dropData = GetRandomDrop()
		SpawnPhysicalDrop(monsterPosition, dropData)
	end
end

return DropService