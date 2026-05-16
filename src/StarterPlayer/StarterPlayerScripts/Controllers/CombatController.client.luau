--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

print("[CombatController] 🟢 Active LocalScript successfully loaded into memory.")

local NetworkEvents = ReplicatedStorage:WaitForChild("NetworkEvents")
local MeleeHitEvent = NetworkEvents:WaitForChild("MeleeHitEvent") :: RemoteEvent

local COOLDOWN_TIME = 0.5
local canAttack = true

mouse.Button1Down:Connect(function()
	print("---------------------------------")
	print("🖱️ [Combat] Mouse Click Registered!")
	
	if not canAttack then 
		print("⏳ [Combat] Weapon is on cooldown.")
		return 
	end
	
	local target = mouse.Target
	if not target then 
		print("⚠️ [Combat] Clicked the sky or void.")
		return 
	end
	
	print("🎯 [Combat] Physical part clicked: " .. target.Name)
	
	-- ADVANCED TARGETING: Climb the entire hierarchy until we find a Model
	local enemyModel = target:FindFirstAncestorWhichIsA("Model")
	
	if enemyModel then
		local humanoid = enemyModel:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			print("✅ [Combat] Valid Enemy Model identified: " .. enemyModel.Name)
			print("📡 [Combat] Sending MeleeHitEvent to Server...")
			
			canAttack = false
			MeleeHitEvent:FireServer(enemyModel)
			
			task.wait(COOLDOWN_TIME)
			canAttack = true
		else
			print("❌ [Combat] The model clicked does not have a Humanoid brain.")
		end
	else
		print("❌ [Combat] The part clicked does not belong to a character Model.")
	end
end)