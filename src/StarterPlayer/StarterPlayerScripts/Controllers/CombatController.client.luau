--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local NetworkEvents = ReplicatedStorage:WaitForChild("NetworkEvents")
-- We are changing the event name to reflect the new architecture
local MeleeSwingEvent = NetworkEvents:WaitForChild("MeleeSwingEvent") :: RemoteEvent

local COOLDOWN_TIME = 0.5
local canAttack = true

-- [[ ANIMATION SETUP ]]
-- Note: Replace "rbxassetid://0000000" with your actual animation ID later.
local swingAnimation = Instance.new("Animation")
swingAnimation.AnimationId = "rbxassetid://0000000" 
local loadedAnim: AnimationTrack? = nil

mouse.Button1Down:Connect(function()
	if not canAttack then return end
	canAttack = false
	
	-- 1. Play the arm movement animation (Will only work once you add a valid ID above)
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
	
	task.wait(COOLDOWN_TIME)
	canAttack = true
end)