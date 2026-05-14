--!strict
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")

local EnemyAIService = {}

-- Define the AI parameters
local PathingParams = {
	AgentRadius = 2,
	AgentHeight = 5,
	AgentCanJump = true,
}

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

function EnemyAIService.StartHunting(monsterModel: Model)
	local humanoid = monsterModel:FindFirstChildWhichIsA("Humanoid")
	local rootPart = monsterModel:FindFirstChild("HumanoidRootPart") :: BasePart

	-- DIAGNOSTIC PROBE: If the core components are missing, dump the anatomy to the console.
	if not humanoid or not rootPart then
		warn("❌ [EnemyAI] CRITICAL FAILURE: Monster missing Humanoid or RootPart!")
		warn("--> Target Object Name: " .. tostring(monsterModel.Name))
		warn("--> Target Object Class: " .. tostring(monsterModel.ClassName))
		warn("--> Contents found inside this object:")
		
		local children = monsterModel:GetChildren()
		if #children == 0 then
			warn("    [EMPTY] This object has absolutely nothing inside it.")
		else
			for _, child in ipairs(children) do
				warn("    - " .. child.Name .. " (" .. child.ClassName .. ")")
			end
		end
		return
	end

	local path = PathfindingService:CreatePath(PathingParams)
	local hunting = true

	humanoid.Died:Connect(function()
		hunting = false
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
					
					if waypoints[2] then
						humanoid:MoveTo(waypoints[2].Position)
						if waypoints[2].Action == Enum.PathWaypointAction.Jump then
							humanoid.Jump = true
						end
					end
				else
					humanoid:MoveTo(target.PrimaryPart.Position)
				end
			end
			task.wait(0.2)
		end
	end)
end

return EnemyAIService