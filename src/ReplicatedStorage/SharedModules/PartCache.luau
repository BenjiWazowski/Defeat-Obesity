--!strict
local PhysicsService = game:GetService("PhysicsService")
local PartCache = {}
PartCache.__index = PartCache

export type Cache = {
	Template: Model,
	CacheParent: Instance,
	Available: {Model},
	InUse: {[Model]: boolean},
	FarAway: CFrame,
	GetPart: (self: Cache, spawnCFrame: CFrame) -> Model,
	ReturnPart: (self: Cache, part: Model) -> ()
}

-- [[ COLLISION GROUP SETUP ]]
pcall(function()
	PhysicsService:RegisterCollisionGroup("MobSwarm")
	PhysicsService:CollisionGroupSetCollidable("MobSwarm", "MobSwarm", false)
end)

function PartCache.new(template: Model, capacity: number, cacheParent: Instance?): Cache
	local self = setmetatable({}, PartCache) :: any
	self.Template = template
	self.CacheParent = cacheParent or game:GetService("Workspace")
	self.Available = {}
	self.InUse = {}
	self.FarAway = CFrame.new(0, 10000, 0)

	print("[PartCache] Initializing memory pool with capacity: " .. capacity)

	for i = 1, capacity do
		local clone = template:Clone()
		clone.Name = template.Name .. "_Cached_" .. i
		clone.Parent = self.CacheParent
		
		-- Inject Collision Group so mobs don't stack on each other
		for _, desc in ipairs(clone:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.CollisionGroup = "MobSwarm"
			end
		end
		
		local root = clone:FindFirstChild("HumanoidRootPart") :: BasePart
		if root then root.Anchored = true end
		
		clone:PivotTo(self.FarAway)
		table.insert(self.Available, clone)
	end

	return self
end

function PartCache:GetPart(spawnCFrame: CFrame): Model
	local part = table.remove(self.Available)
	if not part then
		part = self.Template:Clone()
		part.Parent = self.CacheParent
	end

	part:PivotTo(spawnCFrame)
	self.InUse[part] = true
	
	local root = part:FindFirstChild("HumanoidRootPart") :: BasePart
	if root then root.Anchored = false end
	
	return part
end

function PartCache:ReturnPart(part: Model)
	if not part then return end
	self.InUse[part] = nil
	part:Destroy()
	
	local freshClone = self.Template:Clone()
	freshClone.Name = self.Template.Name .. "_Cached_" .. tostring(math.random(1000, 9999))
	freshClone.Parent = self.CacheParent
	
	for _, desc in ipairs(freshClone:GetDescendants()) do
		if desc:IsA("BasePart") then desc.CollisionGroup = "MobSwarm" end
	end
	
	local root = freshClone:FindFirstChild("HumanoidRootPart") :: BasePart
	if root then root.Anchored = true end
	
	freshClone:PivotTo(self.FarAway)
	table.insert(self.Available, freshClone)
end

return PartCache