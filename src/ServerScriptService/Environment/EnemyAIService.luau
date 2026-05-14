--!strict
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")

local EnemyAIService = {}

-- Define the AI parameters (High HP slow mob vs Fast mob)
local PathingParams = {
	AgentRadius = 2,
	AgentHeight = 5,
	AgentCanJump = true,
}

-- Helper function to find the closest living player
local function GetClosestPlayer(monsterPosition: Vector3): Model?
	local closestPlayer: Model? = nil
	local shortestDistance = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character and character:FindFirstChild("Humanoid") and character:FindFirstChild("HumanoidRootPart") then
			local humanoid = character.Humanoid :: Humanoid
			if humanoid.Health > 0 then
				local distance = (character.HumanoidRootPart.Position - monsterPosition).Magnitude
				if distance < shortestDistance then
					shortestDistance = distance
					closestPlayer = character
				end
			end
		end
	end

	return closestPlayer
end

-- The Core AI Loop
function EnemyAIService.StartHunting(monsterModel: Model)
	local humanoid = monsterModel:FindFirstChildWhichIsA("Humanoid")
	local rootPart = monsterModel:FindFirstChild("HumanoidRootPart") :: BasePart

	if not humanoid or not rootPart then
		warn("[EnemyAI] Monster missing Humanoid or RootPart!")
		return
	end

	local path = PathfindingService:CreatePath(PathingParams)
	local hunting = true

	-- Stop hunting if the monster dies
	humanoid.Died:Connect(function()
		hunting = false
		-- The WaveManager will handle returning it to the PartCache
	end)

	task.spawn(function()
		while hunting and monsterModel.Parent == game.Workspace do
			local target = GetClosestPlayer(rootPart.Position)
			
			if target and target.PrimaryPart then
				local success, errorMessage = pcall(function()
					path:ComputeAsync(rootPart.Position, target.PrimaryPart.Position)
				end)

				if success and path.Status == Enum.PathStatus.Success then
					local waypoints = path:GetWaypoints()
					
					-- Skip the first waypoint (current position) and move to the second
					if waypoints[2] then
						humanoid:MoveTo(waypoints[2].Position)
						
						-- Jump if the waypoint requires it
						if waypoints[2].Action == Enum.PathWaypointAction.Jump then
							humanoid.Jump = true
						end
					end
				else
					-- If pathing fails (no valid path), just walk straight towards them as a fallback
					humanoid:MoveTo(target.PrimaryPart.Position)
				end
			end
			-- Recalculate the path every 0.2 seconds to track moving players
			task.wait(0.2)
		end
	end)
end

return EnemyAIService