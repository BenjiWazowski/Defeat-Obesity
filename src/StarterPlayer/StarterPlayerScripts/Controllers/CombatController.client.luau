--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local NetworkEvents = ReplicatedStorage:WaitForChild("NetworkEvents")
local MeleeSwingEvent = NetworkEvents:WaitForChild("MeleeSwingEvent") :: RemoteEvent

local function GetCooldown()
	-- Read the dynamically calculated speed from the server, default to 0.5 if missing
	return player:GetAttribute("MeleeSpeed") or 0.5
end

local canAttack = true

-- [[ ANIMATION SETUP ]]
local swingAnimation = Instance.new("Animation")
swingAnimation.AnimationId = "rbxassetid://0000000" 
local loadedAnim: AnimationTrack? = nil

mouse.Button1Down:Connect(function()
	if not canAttack then return end
	canAttack = false
	
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