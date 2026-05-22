--!strict
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WaveManager = {}

local EnemyAIService = require(script.Parent:WaitForChild("EnemyAIService"))
local PartCache = require(ReplicatedStorage.SharedModules:WaitForChild("PartCache"))
local StatManager = require(script.Parent.Parent.Core:WaitForChild("StatManager"))
local SkillManager = require(script.Parent.Parent.Core:WaitForChild("SkillManager"))

local MAX_ACTIVE_MONSTERS: number = 60
local BASE_MONSTERS: number = 1
local WAVE_MULTIPLIER: number = 1
local INTERMISSION_TIME: number = 5

local CurrentWave: number = 0
local TotalWaveQuota: number = 0
local MonstersSpawned: number = 0
local ActiveMonsters: number = 0
local WaveInProgress: boolean = false

local MonsterPool: any = nil 

local function SpawnMonster()
	ActiveMonsters += 1
	MonstersSpawned += 1
	
	local randomAngle = math.rad(math.random(0, 360))
	local spawnRadius = 50 
	local spawnX = math.cos(randomAngle) * spawnRadius
	local spawnZ = math.sin(randomAngle) * spawnRadius
	local spawnPosition = CFrame.new(spawnX, 5, spawnZ) 

	local monster = MonsterPool:GetPart(spawnPosition)
	
	local humanoid = monster:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		-- Monsters gain +15% compound health per wave
		-- [[ WAVE MATH: Monster HP Scaling ]]
		-- Monsters gain +10% compound health per wave
		local hpMultiplier = math.pow(1.10, CurrentWave - 1)
		humanoid.MaxHealth = 100 * hpMultiplier
		humanoid.Health = humanoid.MaxHealth
		
		local deathConnection
		deathConnection = humanoid.Died:Connect(function()
			deathConnection:Disconnect()
			WaveManager.OnMonsterDeath(monster)
		end)
	end
	
	EnemyAIService.StartHunting(monster)
end

function WaveManager.OnMonsterDeath(monster: Model)
	ActiveMonsters -= 1
	
	task.delay(2, function() 
		MonsterPool:ReturnPart(monster)
	end)
	
	if ActiveMonsters <= 0 and MonstersSpawned >= TotalWaveQuota then
		WaveManager.EndWave()
	end
end

local function ProcessWaveQueue()
	while WaveInProgress and ActiveMonsters < MAX_ACTIVE_MONSTERS and MonstersSpawned < TotalWaveQuota do
		SpawnMonster()
		task.wait(0.1)
	end
end

function WaveManager.StartWave()
	if WaveInProgress then return end
	
	CurrentWave += 1
	WaveInProgress = true
	
	TotalWaveQuota = math.floor(BASE_MONSTERS * (WAVE_MULTIPLIER ^ (CurrentWave - 1)))
	MonstersSpawned = 0
	ActiveMonsters = 0

	-- Tell the UI to hide the countdown
	Workspace:SetAttribute("WaveState", "Active")

	-- Recalculate and inject player stats for the new wave
	for _, player in ipairs(Players:GetPlayers()) do
		StatManager.CalculateStats(player, CurrentWave)
		StatManager.ApplyPhysicalStats(player)
	end
	
	print("\n🚨 WAVE " .. CurrentWave .. " STARTED 🚨 Quota: " .. TotalWaveQuota)
	Workspace:SetAttribute("CurrentWave", CurrentWave)
	
	task.spawn(function()
		while WaveInProgress do
			ProcessWaveQueue()
			task.wait(1)
		end
	end)
end

function WaveManager.EndWave()
	WaveInProgress = false
	print("✅ Wave " .. CurrentWave .. " Cleared!")
	Workspace:SetAttribute("WaveState", "Intermission")
	
	Workspace:SetAttribute("CurrentWave", CurrentWave + 1)

	-- 1. Three seconds of pure cooldown after the last monster dies
	Workspace:SetAttribute("IntermissionTime", 0)
	print("⏳ Wave cleared. 3 second cooldown...")
	task.wait(3)
	
	-- 2. NOW we begin the Draft or the Standard Countdown
	if CurrentWave > 0 and CurrentWave % 2 == 0 then
		print("🃏 WAVE PAUSED: Skill Draft Initiated!")
		SkillManager.TriggerGlobalDraft()
		
		-- 25 Second Timeout Loop
		local draftTime = 25
		while not SkillManager.IsDraftComplete() and draftTime > 0 do
			Workspace:SetAttribute("IntermissionTime", draftTime)
			task.wait(1)
			draftTime -= 1
		end
		
		if not SkillManager.IsDraftComplete() then
			print("⏰ Draft time expired! Auto-selecting skills...")
			SkillManager.ForceEndDraft()
		end
		
		print("🃏 Skill Draft Complete. Resuming sequence...")
		task.wait(1) 
	else
		-- Standard 15 second intermission
		for i = INTERMISSION_TIME, 1, -1 do
			Workspace:SetAttribute("IntermissionTime", i)
			task.wait(1)
		end
	end
	
	WaveManager.StartWave()
end

function WaveManager.InitializeArena()
	if #Players:GetPlayers() == 0 then
		Players.PlayerAdded:Wait()
	end
	
	print("[WaveManager] Booting Arena Protocol...")
	
	local template = ReplicatedStorage:WaitForChild("ObesityMonster_Template") :: Model
	MonsterPool = PartCache.new(template, MAX_ACTIVE_MONSTERS, Workspace)
	
	if not Workspace:FindFirstChild("ArenaFloor") then
		local floor = Instance.new("Part")
		floor.Name = "ArenaFloor"
		floor.Size = Vector3.new(200, 1, 200)
		floor.Position = Vector3.new(0, -0.5, 0)
		floor.Anchored = true
		floor.BrickColor = BrickColor.new("Medium stone grey")
		floor.Parent = Workspace
	end
	
	-- Initial boot countdown
	Workspace:SetAttribute("WaveState", "Intermission")
	Workspace:SetAttribute("CurrentWave", 1)
	for i = 5, 1, -1 do
		Workspace:SetAttribute("IntermissionTime", i)
		task.wait(1)
	end
	
	WaveManager.StartWave()
end

if game.PrivateServerId ~= "" or RunService:IsStudio() then
	task.spawn(WaveManager.InitializeArena)
end

return WaveManager