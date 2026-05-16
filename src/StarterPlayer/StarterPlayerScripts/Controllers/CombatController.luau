--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local NetworkEvents = ReplicatedStorage:WaitForChild("NetworkEvents")
local MeleeHitEvent = NetworkEvents:WaitForChild("MeleeHitEvent") :: RemoteEvent

local COOLDOWN_TIME = 0.5
local canAttack = true

mouse.Button1Down:Connect(function()
	if not canAttack then return end
	
	-- Determine what the player clicked on
	local target = mouse.Target
	if target and target.Parent then
		-- Check if the parent of the clicked part has a Humanoid (Meaning it's a monster)
		local humanoid = target.Parent:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			canAttack = false
			
			-- Ask the server to validate the hit
			MeleeHitEvent:FireServer(target.Parent)
			
			-- Client-side cooldown to prevent spamming the network
			task.wait(COOLDOWN_TIME)
			canAttack = true
		end
	end
end)