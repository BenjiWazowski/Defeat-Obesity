--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local NetworkEvents = ReplicatedStorage:WaitForChild("NetworkEvents")
local MeleeSwingEvent = NetworkEvents:WaitForChild("MeleeSwingEvent") :: RemoteEvent

local WeaponConfig = require(ReplicatedStorage.GameConfig:WaitForChild("WeaponConfig"))

local function GetCooldown()
	-- Read the dynamically calculated speed from the server, default to 0.5 if missing
	return player:GetAttribute("MeleeSpeed") or 0.5
end

local canAttack = true

-- [[ ANIMATION SETUP ]]
local swingAnimation = Instance.new("Animation")
swingAnimation.AnimationId = "rbxassetid://507777451" 
local loadedAnim: AnimationTrack? = nil

mouse.Button1Down:Connect(function()
	if not canAttack then return end
	canAttack = false

	local char = player.Character
	if not char then return end
	
	-- Stop melee if the player is holding a gun
	local equippedTool = char:FindFirstChildWhichIsA("Tool")
	if equippedTool and WeaponConfig[equippedTool.Name] then 
		canAttack = true
		return 
	end
	
	-- 1. Play the arm movement animation
	local char = player.Character
	local humanoid = char and char:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		if not loadedAnim then
			loadedAnim = humanoid:LoadAnimation(swingAnimation)
		end
		loadedAnim:Play()
	end
	
	-- 2. Tell the server to project the hitbox
	print("⚔️ [Combat] Swung weapon! Projecting hitbox...")
	MeleeSwingEvent:FireServer()
	
	-- 3. Dynamic cooldown based on Stats
	task.wait(GetCooldown())
	canAttack = true
end)