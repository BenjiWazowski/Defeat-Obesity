--!strict
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local MatchmakingService = {}

-- [[ CONFIGURATION ]]
-- WARNING: You MUST replace this ID with the actual Place ID of your Arena
local ARENA_PLACE_ID = 125170709894675 
local REQUIRED_PLAYERS = 1
local MAX_PLAYERS = 4
local COUNTDOWN_TIME = 15

-- [[ STATE ]]
local Queue: {Player} = {}
local CountdownActive: boolean = false
local Teleporting: boolean = false

-- [[ HELPER FUNCTIONS ]]
local function UpdateUI()
	-- In the future, we will fire a RemoteEvent here to update a GUI 
	-- showing "Queue: 2/4 | Starting in 10s"
	print("[Matchmaking] Queue Size: " .. #Queue)
end

local function RemovePlayerFromQueue(player: Player)
	local index = table.find(Queue, player)
	if index then
		table.remove(Queue, index)
		print("[Matchmaking] " .. player.Name .. " left the queue.")
		UpdateUI()
	end
end

local function ExecuteTeleport()
	if #Queue < REQUIRED_PLAYERS then
		print("[Matchmaking] Not enough players to start.")
		CountdownActive = false
		return
	end

	Teleporting = true
	print("[Matchmaking] Reserving server and teleporting players...")

	-- Wrap in a pcall (protected call) to prevent the server script from crashing if Roblox API goes down
	local success, errorMessage = pcall(function()
		-- 1. Create a unique, private instance of the Arena
		local reservedServerCode = TeleportService:ReserveServer(ARENA_PLACE_ID)
		
		-- 2. Teleport the specific array of queued players to that instance
		local teleportOptions = Instance.new("TeleportOptions")
		teleportOptions.ReservedServerAccessCode = reservedServerCode
		
		TeleportService:TeleportAsync(ARENA_PLACE_ID, Queue, teleportOptions)
	end)

	if not success then
		warn("[Matchmaking] Teleport failed: " .. tostring(errorMessage))
		-- Reset state so players aren't soft-locked forever
		Teleporting = false
		Queue = {} 
	end
end

local function StartCountdown()
	if CountdownActive or Teleporting then return end
	CountdownActive = true

	task.spawn(function()
		for i = COUNTDOWN_TIME, 1, -1 do
			if #Queue == 0 then
				print("[Matchmaking] Queue empty. Countdown aborted.")
				CountdownActive = false
				return
			end
			-- print("[Matchmaking] Teleporting in " .. i .. " seconds...")
			task.wait(1)
		end
		ExecuteTeleport()
	end)
end

-- [[ THE QUEUE PAD LOGIC ]]
local function InitializeQueuePad()
	-- Look for a part named "QueuePad" in the Workspace
	local queuePad = Workspace:WaitForChild("QueuePad", 10) :: BasePart
	if not queuePad then
		warn("[Matchmaking] QueuePad not found in Workspace! Matchmaking disabled.")
		return
	end

	-- Debounce dictionary to prevent the Touched event from firing 1000 times a second
	local debounce = {}

	queuePad.Touched:Connect(function(hit: BasePart)
		if Teleporting then return end

		local character = hit.Parent
		if not character then return end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		-- Check debounce and queue limits
		if debounce[player.UserId] or table.find(Queue, player) then return end
		if #Queue >= MAX_PLAYERS then return end

		-- Add to queue
		debounce[player.UserId] = true
		table.insert(Queue, player)
		print("[Matchmaking] " .. player.Name .. " joined the queue.")
		UpdateUI()

		-- Start timer if not already running
		StartCountdown()

		-- Release debounce after a short cooldown
		task.wait(1)
		debounce[player.UserId] = nil
	end)
end

-- Cleanup if a player disconnects while in the queue
Players.PlayerRemoving:Connect(function(player: Player)
	RemovePlayerFromQueue(player)
end)

-- Start the system
task.spawn(InitializeQueuePad)

return MatchmakingService