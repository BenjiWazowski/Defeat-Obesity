--!strict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local isZoomLocked = false
local isCursorUnlocked = false

-- Create a hidden UI with a Modal Button to force Roblox to free the mouse
local cursorGui = Instance.new("ScreenGui")
cursorGui.Name = "CursorUnlockGui"
cursorGui.ResetOnSpawn = false
cursorGui.Parent = player:WaitForChild("PlayerGui")

local modalButton = Instance.new("TextButton")
modalButton.Size = UDim2.new(0, 0, 0, 0)
modalButton.BackgroundTransparency = 1
modalButton.Text = ""
modalButton.Modal = true -- This is the magic property that frees the mouse
modalButton.Visible = false
modalButton.Parent = cursorGui

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	-- [[ 1. POV ZOOM LOCK (CTRL) ]]
	if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
		isZoomLocked = not isZoomLocked
		
		if isZoomLocked then
			-- Calculate exact current zoom distance
			local camera = Workspace.CurrentCamera
			local currentZoom = (camera.CFrame.Position - camera.Focus.Position).Magnitude
			
			-- Clamp it so it doesn't break if they are clipping through a wall
			currentZoom = math.clamp(currentZoom, 0.5, 400)
			
			player.CameraMinZoomDistance = currentZoom
			player.CameraMaxZoomDistance = currentZoom
			print("📷 POV Locked at " .. math.round(currentZoom) .. " studs.")
		else
			-- Reset to default Roblox zoom ranges
			player.CameraMinZoomDistance = 0.5
			player.CameraMaxZoomDistance = 400
			print("📷 POV Unlocked.")
		end
	end
	
	-- [[ 2. MANUAL CURSOR UNLOCK (LEFT ALT) ]]
	if input.KeyCode == Enum.KeyCode.LeftAlt then
		isCursorUnlocked = not isCursorUnlocked
		modalButton.Visible = isCursorUnlocked
		
		if isCursorUnlocked then
			print("🖱️ Cursor Unlocked.")
		else
			print("🖱️ Cursor Locked.")
		end
	end
end)