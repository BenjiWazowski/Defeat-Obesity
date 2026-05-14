--!strict
local PartCache = {}
PartCache.__index = PartCache

-- [[ TYPE DEFINITIONS ]]
export type Cache = {
	Template: Model,
	CacheParent: Instance,
	Available: {Model},
	InUse: {[Model]: boolean},
	FarAway: CFrame,
	
	GetPart: (self: Cache, spawnCFrame: CFrame) -> Model,
	ReturnPart: (self: Cache, part: Model) -> ()
}

-- [[ CONSTRUCTOR ]]
function PartCache.new(template: Model, capacity: number, cacheParent: Instance?): Cache
	local self = setmetatable({}, PartCache) :: any
	
	self.Template = template
	self.CacheParent = cacheParent or game:GetService("Workspace")
	self.Available = {}
	self.InUse = {}

	-- The "Graveyard": We park inactive models deep in the void to freeze their physics
	self.FarAway = CFrame.new(0, -50000, 0)

	print("[PartCache] Initializing memory pool with capacity: " .. capacity)

	-- Pre-allocate the memory
	for i = 1, capacity do
		local clone = template:Clone()
		clone.Name = template.Name .. "_Cached_" .. i
		clone.Parent = self.CacheParent
		
		-- Immediately send to the Graveyard
		clone:PivotTo(self.FarAway)
		table.insert(self.Available, clone)
	end

	return self
end

-- [[ CORE METHODS ]]
function PartCache:GetPart(spawnCFrame: CFrame): Model
	local part = table.remove(self.Available)
	
	if not part then
		warn("[PartCache] CRITICAL: Pool exhausted! Physics cap breached. Instantiating overflow model.")
		part = self.Template:Clone()
		part.Parent = self.CacheParent
	end

	-- Teleport to the requested location on the surface
	part:PivotTo(spawnCFrame)
	self.InUse[part] = true
	
	-- If it's a humanoid monster, ensure its health is reset upon waking up
	local humanoid = part:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		humanoid.Health = humanoid.MaxHealth
	end
	
	return part
end

function PartCache:ReturnPart(part: Model)
	if not part then return end
	
	self.InUse[part] = nil
	table.insert(self.Available, part)
	
	-- Send back to the Graveyard, effectively "killing" it without destroying the memory
	part:PivotTo(self.FarAway)
end

return PartCache