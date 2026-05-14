--!strict
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WaveManager = {}

-- IMPORT THE SERVICES
local EnemyAIService = require(script.Parent:WaitForChild("EnemyAIService"))
local PartCache = require(ReplicatedStorage.SharedModules:WaitForChild("PartCache"))

-- [[ CONFIGURATION ]]
local MAX_ACTIVE_MONSTERS: number = 60
local BASE_MONSTERS: number = 10
local WAVE_MULTIPLIER: number = 1.25
local INTERMISSION_TIME: number = 10

-- [[ STATE ]]
local CurrentWave: number = 0
local TotalWaveQuota: number = 0
local MonstersSpawned: number = 0
local ActiveMonsters: number = 0
local WaveInProgress: boolean = false

-- [[ CACHE INITIALIZATION ]]
-- We will initialize this when the Arena boots up
local MonsterPool: any = nil 

local function SpawnMonster()
	ActiveMonsters += 1
	MonstersSpawned += 1
	
	-- Calculate a random spawn position around the center of the map (Assuming 0,0,0 is center)
	local randomAngle = math.rad(math.random(0, 360))
	local spawnRadius = 50 -- Spawn 50 studs away from center
	local spawnX = math.cos(randomAngle) * spawnRadius
	local spawnZ = math.sin(randomAngle) * spawnRadius
	local spawnPosition = CFrame.new(spawnX, 5, spawnZ) -- Drop from 5 studs high

	-- Pull from Object Pool
	local monster = MonsterPool:GetPart(spawnPosition)
	
	-- Connect Death Event
	local humanoid = monster:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		local deathConnection
		deathConnection = humanoid.Died:Connect(function()
			deathConnection:Disconnect()
			WaveManager.OnMonsterDeath(monster)
		end)
	end
	
	-- Command the AI to attack
	EnemyAIService.StartHunting(monster)
end

function WaveManager.OnMonsterDeath(monster: Model)
	ActiveMonsters -= 1
	
	-- Return the body to the Graveyard instead of Destroying it
	task.delay(2, function() -- Let the corpse lie there for 2 seconds before recycling
		MonsterPool:ReturnPart(monster)
	end)
	
	if ActiveMonsters <= 0 and MonstersSpawned >= TotalWaveQuota then
		WaveManager.EndWave()
	end
end

-- [[ CORE LOOP ]]
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
	
	print("\n🚨 WAVE " .. CurrentWave .. " STARTED 🚨 Quota: " .. TotalWaveQuota)
	
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
	print("⏳ Intermission: " .. INTERMISSION_TIME .. " seconds...")
	task.wait(INTERMISSION_TIME)
	WaveManager.StartWave()
end

function WaveManager.InitializeArena()
	if #Players:GetPlayers() == 0 then
		Players.PlayerAdded:Wait()
	end
	
	print("[WaveManager] Booting Arena Protocol...")
	
	-- Initialize the Object Pool with the dummy rig we placed in ReplicatedStorage
	local template = ReplicatedStorage:WaitForChild("ObesityMonster_Template") :: Model
	MonsterPool = PartCache.new(template, MAX_ACTIVE_MONSTERS, Workspace)
	
	-- Create a flat greyblock floor for testing if one doesn't exist
	if not Workspace:FindFirstChild("ArenaFloor") then
		local floor = Instance.new("Part")
		floor.Name = "ArenaFloor"
		floor.Size = Vector3.new(200, 1, 200)
		floor.Position = Vector3.new(0, -0.5, 0)
		floor.Anchored = true
		floor.BrickColor = BrickColor.new("Medium stone grey")
		floor.Parent = Workspace
	end
	
	task.wait(5)
	WaveManager.StartWave()
end

if game.PrivateServerId ~= "" or RunService:IsStudio() then
	task.spawn(WaveManager.InitializeArena)
end

return WaveManager