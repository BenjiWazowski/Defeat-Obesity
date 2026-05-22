--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local DropService = require(script.Parent.Parent.Environment:WaitForChild("DropService"))

local CombatService = {}

local NetworkEvents = ReplicatedStorage:FindFirstChild("NetworkEvents")
if not NetworkEvents then
	NetworkEvents = Instance.new("Folder")
	NetworkEvents.Name = "NetworkEvents"
	NetworkEvents.Parent = ReplicatedStorage
end

local MeleeSwingEvent = Instance.new("RemoteEvent")
MeleeSwingEvent.Name = "MeleeSwingEvent"
MeleeSwingEvent.Parent = NetworkEvents

local DataService = require(script.Parent.Parent.Core:WaitForChild("DataService"))
local StatManager = require(script.Parent.Parent.Core:WaitForChild("StatManager"))

local PlayerCooldowns = {}

MeleeSwingEvent.OnServerEvent:Connect(function(player: Player)
	local char = player.Character
	local playerRoot = char and char:FindFirstChild("HumanoidRootPart") :: BasePart
	if not playerRoot then return end
	
	-- 1. FETCH DYNAMIC STATS
	local activeStats = StatManager.GetActiveStats(player)
	
	-- 2. ANTI-CHEAT: Cooldown enforcement
	local lastSwing = PlayerCooldowns[player.UserId] or 0
	if os.clock() - lastSwing < activeStats.MeleeSpeed then
		return -- Silently drop the exploiter's request
	end
	PlayerCooldowns[player.UserId] = os.clock()
	
	-- 3. DEFINE THE HITBOX DYNAMICALLY
	local range = activeStats.MeleeRange
	local hitboxSize = Vector3.new(range, 5, range) 
	local hitboxCFrame = playerRoot.CFrame * CFrame.new(0, 0, -(range/2 + 1)) 
	
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {char} 
	
	local hitParts = Workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, overlapParams)
	local monstersHit = {}
	
	for _, part in ipairs(hitParts) do
		local enemyModel = part:FindFirstAncestorWhichIsA("Model")
		if enemyModel and not monstersHit[enemyModel] then
			local monsterHumanoid = enemyModel:FindFirstChild("Humanoid") :: Humanoid
			
			if monsterHumanoid and monsterHumanoid.Health > 0 then
				monstersHit[enemyModel] = true
				
				-- 4. APPLY DYNAMIC DAMAGE (Multiplier Math)
				local baseMeleeDamage = 35 
				local finalDamage = baseMeleeDamage * (1 + ((activeStats.MeleeDamage or 0) / 100))
				
				monsterHumanoid:TakeDamage(finalDamage)
				
				-- ==========================================
				-- [[ EPIC SKILLS: ON-HIT EFFECTS ]]
				-- ==========================================
				if monsterHumanoid.Health > 0 then
					local SkillConfig = require(ReplicatedStorage.GameConfig.SkillConfig)
					
					-- 1. THUNDER STRIKE
					local tsStacks = player:GetAttribute("Skill_ThunderStrike") or 0
					if tsStacks > 0 then
						local tMath = SkillConfig["Thunder Strike"].ThunderMath
						local chance = tMath.BaseProcChance + (tMath.ProcChancePerStack * (tsStacks - 1))
						
						if math.random() <= chance then
							-- Visual Lightning Bolt
							local bolt = Instance.new("Part")
							bolt.Size = Vector3.new(1, 100, 1)
							bolt.Position = part.Position + Vector3.new(0, 50, 0)
							bolt.Anchored = true
							bolt.CanCollide = false
							bolt.Material = Enum.Material.Neon
							bolt.BrickColor = BrickColor.new("New Yeller")
							bolt.Parent = Workspace
							task.delay(0.2, function() bolt:Destroy() end)
							
							monsterHumanoid:TakeDamage(monsterHumanoid.MaxHealth * tMath.NormalMobDamage)
						end
					end
					
					-- 2. INCENDIARY ROUNDS
					local irStacks = player:GetAttribute("Skill_IncendiaryRounds") or 0
					if irStacks > 0 and not monsterHumanoid:GetAttribute("OnFire") then
						monsterHumanoid:SetAttribute("OnFire", true)
						local fMath = SkillConfig["Incendiary Rounds"].FireMath
						
						local fire = Instance.new("Fire", part)
						
						task.spawn(function()
							for _ = 1, fMath.DurationSeconds do
								task.wait(fMath.TickRate)
								if monsterHumanoid and monsterHumanoid.Health > 0 then
									monsterHumanoid:TakeDamage(monsterHumanoid.MaxHealth * fMath.NormalMobHPDamage)
								else
									break
								end
							end
							if monsterHumanoid then monsterHumanoid:SetAttribute("OnFire", nil) end
							if fire then fire:Destroy() end
						end)
					end
				end
				
				-- ==========================================
				-- [[ DEATH LOGIC ]]
				-- ==========================================
				if monsterHumanoid.Health <= 0 then
					if monsterHumanoid:GetAttribute("IsDead") then continue end
					monsterHumanoid:SetAttribute("IsDead", true)
					
					local profile = DataService.GetProfile(player)
					if profile then
						profile.Data.Sausages += 1
						player:SetAttribute("Sausages", profile.Data.Sausages)
					end
					DropService.RollForDrop(enemyModel.PrimaryPart.Position, player)
				end
				
			end
		end
	end
end)

return CombatService