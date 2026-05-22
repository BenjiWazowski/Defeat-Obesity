--!strict
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local MatchmakingService = {}

-- [[ CONFIGURATION ]]
local ARENA_PLACE_ID = 125170709894675
local REQUIRED_PLAYERS = 1
local MAX_PLAYERS = 4
local COUNTDOWN_TIME = 15

-- [[ STATE ]]
local Queue: {Player} = {}
local CountdownActive: boolean = false
local Teleporting: boolean = false

-- Locate the Floating Text on the Pad
local elevator = Workspace:WaitForChild("MatchmakingElevator")
local queuePad = elevator:WaitForChild("QueuePad") :: BasePart
local billboard = queuePad:WaitForChild("BillboardGui")
local statusText = billboard:WaitForChild("TextLabel") :: TextLabel

local function UpdateUI()
	-- Update the floating text directly!
	statusText.Text = #Queue .. "/" .. MAX_PLAYERS
	statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
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
		CountdownActive = false
		UpdateUI()
		return
	end

	Teleporting = true
	statusText.Text = "Teleporting..."
	statusText.TextColor3 = Color3.fromRGB(100, 255, 100)

	local success, errorMessage = pcall(function()
		local reservedServerCode = TeleportService:ReserveServer(ARENA_PLACE_ID)
		
		local DataService = require(script.Parent:WaitForChild("DataService"))
		for _, player in ipairs(Queue) do
			-- TAG THE PLAYER SO THEY DON'T GET KICKED
			player:SetAttribute("IsTeleporting", true)
			
			local profile = DataService.GetProfile(player)
			if profile then profile:EndSession() end
		end
		
		local teleportOptions = Instance.new("TeleportOptions")
		teleportOptions.ReservedServerAccessCode = reservedServerCode
		TeleportService:TeleportAsync(ARENA_PLACE_ID, Queue, teleportOptions)
	end)

	if not success then
		warn("[Matchmaking] Teleport failed: " .. tostring(errorMessage))
		Teleporting = false
		-- Remove the tag if the teleport fails
		for _, player in ipairs(Queue) do
			player:SetAttribute("IsTeleporting", nil)
		end
		Queue = {} 
		statusText.Text = "Failed!"
		statusText.TextColor3 = Color3.fromRGB(255, 100, 100)
		task.wait(3)
		UpdateUI()
	end
end

local function StartCountdown()
	if CountdownActive or Teleporting then return end
	CountdownActive = true

	task.spawn(function()
		for i = COUNTDOWN_TIME, 1, -1 do
			if #Queue == 0 then
				CountdownActive = false
				UpdateUI()
				return
			end
			statusText.Text = "Starting in " .. i
			statusText.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold countdown
			task.wait(1)
		end
		ExecuteTeleport()
	end)
end

-- [[ THE QUEUE PAD LOGIC ]]
local function InitializeQueuePad()
	local debounce = {}

	queuePad.Touched:Connect(function(hit: BasePart)
		if Teleporting then return end

		local character = hit.Parent
		if not character then return end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		if debounce[player.UserId] or table.find(Queue, player) then return end
		if #Queue >= MAX_PLAYERS then return end

		debounce[player.UserId] = true
		table.insert(Queue, player)
		UpdateUI()
		StartCountdown()

		task.wait(1)
		debounce[player.UserId] = nil
	end)
end

Players.PlayerRemoving:Connect(function(player: Player)
	RemovePlayerFromQueue(player)
end)

task.spawn(InitializeQueuePad)
return MatchmakingService