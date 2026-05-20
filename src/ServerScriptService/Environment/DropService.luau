--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local DropService = {}

local StatManager = require(script.Parent.Parent.Core:WaitForChild("StatManager"))
local WeaponConfig = require(ReplicatedStorage.GameConfig:WaitForChild("WeaponConfig"))

local BASE_DROP_CHANCE = 0.07 -- 7% base chance

local DROP_SIZES = {
	Small = { Weight = 70, HealthPct = 0.25, AmmoPct = 0.30, Color = Color3.fromRGB(100, 255, 100) },
	Medium = { Weight = 25, HealthPct = 0.45, AmmoPct = 0.70, Color = Color3.fromRGB(50, 150, 255) },
	Large = { Weight = 5, HealthPct = 0.70, AmmoPct = 1.00, Color = Color3.fromRGB(255, 215, 0) } -- Gold for Max/Large
}

-- Roll for a specific size based on weights (70/25/5)
local function GetRandomSize()
	local roll = math.random(1, 100)
	if roll <= DROP_SIZES.Small.Weight then return "Small", DROP_SIZES.Small
	elseif roll <= DROP_SIZES.Small.Weight + DROP_SIZES.Medium.Weight then return "Medium", DROP_SIZES.Medium
	else return "Large", DROP_SIZES.Large end
end

-- Generates the physical item in the world
local function SpawnPhysicalDrop(position: Vector3, dropCategory: string, sizeName: string, sizeData: any)
	local dropPart = Instance.new("Part")
	dropPart.Name = sizeName .. dropCategory .. "Drop"
	dropPart.Size = Vector3.new(2, 2, 2)
	dropPart.Position = position + Vector3.new(0, 3, 0) -- Floats 3 studs off the ground
	dropPart.Anchored = true
	dropPart.CanCollide = false
	dropPart.Material = Enum.Material.Neon
	
	-- Green for Health, Blue for Ammo (with Gold for Max)
	if dropCategory == "Health" then
		dropPart.Color = sizeName == "Large" and sizeData.Color or Color3.fromRGB(50, 200, 50)
	else
		dropPart.Color = sizeName == "Large" and sizeData.Color or Color3.fromRGB(50, 100, 255)
	end
	
	dropPart.Parent = Workspace
	
	-- Slowly rotate it for visual flair
	task.spawn(function()
		while dropPart.Parent do
			dropPart.CFrame = dropPart.CFrame * CFrame.Angles(0, math.rad(2), 0)
			task.wait(0.03)
		end
	end)
	
	-- Despawn after 20 seconds to prevent lag
	task.delay(20, function()
		if dropPart.Parent then dropPart:Destroy() end
	end)
	
	-- [[ PICKUP LOGIC (GLOBAL EFFECT) ]]
	local db = false
	dropPart.Touched:Connect(function(hit)
		if db then return end
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			db = true
			dropPart:Destroy()
			
			print("🎁 " .. player.Name .. " picked up a " .. sizeName .. " " .. dropCategory .. " Pack! Sharing with team...")
			
			-- Apply to ALL players
			for _, teamPlayer in ipairs(Players:GetPlayers()) do
				local char = teamPlayer.Character
				if not char then continue end
				
				if dropCategory == "Health" then
					local humanoid = char:FindFirstChild("Humanoid") :: Humanoid
					if humanoid and humanoid.Health > 0 then
						local healAmount = humanoid.MaxHealth * sizeData.HealthPct
						humanoid.Health = math.min(humanoid.Health + healAmount, humanoid.MaxHealth)
					end
					
				elseif dropCategory == "Ammo" then
					-- Restore ammo for ALL weapons in their Backpack AND Character
					local items = {}
					for _, v in ipairs(char:GetChildren()) do table.insert(items, v) end
					for _, v in ipairs(teamPlayer:WaitForChild("Backpack"):GetChildren()) do table.insert(items, v) end
					
					for _, tool in ipairs(items) do
						if tool:IsA("Tool") and WeaponConfig[tool.Name] then
							local config = WeaponConfig[tool.Name]
							-- We use base max for simplicity, or re-calculate via their current stat
							local currentWave = Workspace:GetAttribute("CurrentWave") or 1
							local decayRate = 0.1
							local maxReserveClips = math.floor(config.ReserveClips.Cap - ((config.ReserveClips.Cap - config.ReserveClips.Base) * math.pow(1 - decayRate, currentWave - 1)))
							local clipSize = math.floor(config.ClipSize.Cap - ((config.ClipSize.Cap - config.ClipSize.Base) * math.pow(1 - decayRate, currentWave - 1)))
							
							local totalMaxReserve = maxReserveClips * clipSize
							if tool.Name == "Glizzy shooter" then totalMaxReserve = maxReserveClips end
							
							local currentReserve = tool:GetAttribute("ReserveAmmo") or totalMaxReserve
							local ammoToGive = math.floor(totalMaxReserve * sizeData.AmmoPct)
							
							tool:SetAttribute("ReserveAmmo", math.min(currentReserve + ammoToGive, totalMaxReserve))
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
	
	-- Did a drop happen?
	if math.random() <= finalChance then
		-- 50/50 split between Health and Ammo
		local dropCategory = math.random() > 0.5 and "Health" or "Ammo"
		local sizeName, sizeData = GetRandomSize()
		
		SpawnPhysicalDrop(monsterPosition, dropCategory, sizeName, sizeData)
	end
end

return DropService