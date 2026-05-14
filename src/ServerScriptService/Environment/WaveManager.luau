--!strict
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local WaveManager = {}

-- [[ CONFIGURATION ]]
local MAX_ACTIVE_MONSTERS: number = 60 -- The physics safety limit
local BASE_MONSTERS: number = 10
local WAVE_MULTIPLIER: number = 1.25 -- Exponential scaling
local INTERMISSION_TIME: number = 10 -- Seconds between waves

-- [[ STATE ]]
local CurrentWave: number = 0
local TotalWaveQuota: number = 0
local MonstersSpawned: number = 0
local ActiveMonsters: number = 0
local WaveInProgress: boolean = false

-- [[ TEMPORARY STUB: Will connect to EnemyAIService and PartCache next ]]
local function SpawnMonster()
	ActiveMonsters += 1
	MonstersSpawned += 1
	
	-- TODO in Phase 4.5: Pull monster from PartCache, set health based on CurrentWave math, and assign AI.
	-- For now, we simulate the spawn logging so you can see the engine working.
	-- print("[WaveManager] Spawned Monster. Active: " .. ActiveMonsters .. " | Total Spawned: " .. MonstersSpawned .. "/" .. TotalWaveQuota)
end

-- Call this function whenever an Enemy dies (We will hook this up in the Hitbox/Combat phase)
function WaveManager.OnMonsterDeath()
	ActiveMonsters -= 1
	
	-- Did we finish the entire wave?
	if ActiveMonsters <= 0 and MonstersSpawned >= TotalWaveQuota then
		WaveManager.EndWave()
	end
end

-- [[ CORE LOOP ]]
local function ProcessWaveQueue()
	-- If we haven't met the quota, and we are safely below the physics crash limit, spawn more.
	while WaveInProgress and ActiveMonsters < MAX_ACTIVE_MONSTERS and MonstersSpawned < TotalWaveQuota do
		SpawnMonster()
		task.wait(0.1) -- Stagger spawns slightly to prevent CPU spike
	end
end

function WaveManager.StartWave()
	if WaveInProgress then return end
	
	CurrentWave += 1
	WaveInProgress = true
	
	-- Calculate how many monsters belong in this wave
	TotalWaveQuota = math.floor(BASE_MONSTERS * (WAVE_MULTIPLIER ^ (CurrentWave - 1)))
	MonstersSpawned = 0
	ActiveMonsters = 0
	
	print("\n==================================")
	print("🚨 WAVE " .. CurrentWave .. " STARTED 🚨")
	print("Target Monster Quota: " .. TotalWaveQuota)
	print("==================================\n")
	
	-- Fire a RemoteEvent here later to tell the Client UI to show "WAVE X"
	
	-- Start the background loop to stream monsters in
	task.spawn(function()
		while WaveInProgress do
			ProcessWaveQueue()
			task.wait(1) -- Check the queue every second
		end
	end)
end

function WaveManager.EndWave()
	WaveInProgress = false
	print("✅ Wave " .. CurrentWave .. " Cleared!")
	
	-- Here we will trigger the Degenerate Guy's dice roll and give Sausages/Stats to everyone.
	
	-- Start Intermission
	print("⏳ Intermission: " .. INTERMISSION_TIME .. " seconds...")
	task.wait(INTERMISSION_TIME)
	WaveManager.StartWave()
end

-- [[ ARENA INITIALIZATION ]]
function WaveManager.InitializeArena()
	-- Wait for at least one player to fully load into the Arena before starting
	if #Players:GetPlayers() == 0 then
		Players.PlayerAdded:Wait()
	end
	
	print("[WaveManager] Players detected. Booting Arena Protocol...")
	task.wait(5) -- Give players 5 seconds to load their weapons/UI
	WaveManager.StartWave()
end

-- Only auto-start if we are actually in the Arena (Not the Hub)
-- We check this by seeing if the script is running in a reserved server or if we are testing locally.
if game.PrivateServerId ~= "" or RunService:IsStudio() then
	task.spawn(WaveManager.InitializeArena)
end

return WaveManager