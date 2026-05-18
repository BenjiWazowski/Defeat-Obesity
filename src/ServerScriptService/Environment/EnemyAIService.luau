--!strict
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")

local EnemyAIService = {}

local PathingParams = {
	AgentRadius = 2,
	AgentHeight = 5,
	AgentCanJump = true,
}

local ATTACK_RANGE = 4.5
local ATTACK_DAMAGE = 10
local ATTACK_COOLDOWN = 1.2

-- Default Mob Swing Animation
local mobAttackAnim = Instance.new("Animation")
mobAttackAnim.AnimationId = "rbxassetid://507777826"

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
	if not humanoid or not rootPart then return end
	
	-- Ensure the mob has an Animator to play animations
	local animator = humanoid:FindFirstChildWhichIsA("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	
	local loadedAttackAnim = animator:LoadAnimation(mobAttackAnim)
	local path = PathfindingService:CreatePath(PathingParams)
	local hunting = true
	local onCooldown = false

	humanoid.Died:Connect(function()
		hunting = false
	end)

	task.spawn(function()
		while hunting and monsterModel.Parent == game.Workspace do
			local target = GetClosestPlayer(rootPart.Position)
			
			if target and target.PrimaryPart then
				local distance = (rootPart.Position - target.PrimaryPart.Position).Magnitude
				
				if distance <= ATTACK_RANGE then
					-- [[ COMBAT STATE ]]
					-- 1. Stop moving immediately
					humanoid:MoveTo(rootPart.Position)
					
					-- 2. Attack if not on cooldown
					if not onCooldown then
						onCooldown = true
						loadedAttackAnim:Play()
						
						local targetHumanoid = target:FindFirstChildWhichIsA("Humanoid")
						if targetHumanoid and targetHumanoid.Health > 0 then
							targetHumanoid:TakeDamage(ATTACK_DAMAGE)
						end
						
						task.wait(ATTACK_COOLDOWN)
						onCooldown = false
					else
						task.wait(0.1) -- Wait for cooldown to end while staying near player
					end
				else
					-- [[ PATHFINDING STATE ]]
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
					task.wait(0.2)
				end
			else
				task.wait(0.5) -- Idle if no players alive
			end
		end
	end)
end

return EnemyAIService