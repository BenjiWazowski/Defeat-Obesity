--!strict
-- [[ WEAPON SCALING ARCHITECTURE ]]
-- Damage scales exponentially to match monster health.
-- ClipSize, ReserveClips, ReloadSpeed, and FireRate use Diminishing Caps (like player stats).

local WeaponConfig = {
	["Dual meatBALLS shooters"] = {
		Type = "SemiAuto",
		Damage = { Base = 20, GrowthMult = 1.14 }, -- Slightly slower than monster HP growth
		FireRate = { Base = 0.5, Cap = 0.1 },
		ClipSize = { Base = 20, Cap = 200 },
		ReserveClips = { Base = 4, Cap = 6 },
		ReloadSpeed = { Base = 2.0, Cap = 0.2 },
		Spread = 0.03,
		HeadshotMultiplier = 1.5,
		ProjectileType = "Raycast"
	},
	["Desert Bagel"] = {
		Type = "SemiAuto",
		Damage = { Base = 50, GrowthMult = 1.13 },
		FireRate = { Base = 0.8, Cap = 0.4 },
		ClipSize = { Base = 6, Cap = 36 },
		ReserveClips = { Base = 4, Cap = 6 },
		ReloadSpeed = { Base = 2.5, Cap = 0.4 },
		Spread = 0.01,
		HeadshotMultiplier = 2.0,
		ProjectileType = "Raycast"
	},
	["AK 67"] = {
		Type = "Auto",
		Damage = { Base = 25, GrowthMult = 1.135 },
		FireRate = { Base = 0.2, Cap = 0.1 },
		ClipSize = { Base = 25, Cap = 300 },
		ReserveClips = { Base = 4, Cap = 6 },
		ReloadSpeed = { Base = 2.2, Cap = 0.2 },
		Spread = 0.02, -- Will implement dynamic inaccuracy later
		HeadshotMultiplier = 1.5,
		ProjectileType = "Raycast"
	},
	["MP 67"] = {
		Type = "Auto",
		Damage = { Base = 21, GrowthMult = 1.13 },
		FireRate = { Base = 0.15, Cap = 0.08 },
		ClipSize = { Base = 30, Cap = 400 },
		ReserveClips = { Base = 4, Cap = 6 },
		ReloadSpeed = { Base = 2.0, Cap = 0.15 },
		Spread = 0.005, -- Laser beam
		HeadshotMultiplier = 1.4,
		ProjectileType = "Raycast"
	},
	["Explosive Poop"] = {
		Type = "AutoShotgun",
		Damage = { Base = 10, GrowthMult = 1.14 },
		PelletCount = 12,
		FireRate = { Base = 0.6, Cap = 0.25 },
		ClipSize = { Base = 8, Cap = 48 },
		ReserveClips = { Base = 4, Cap = 6 },
		ReloadSpeed = { Base = 6.0, Cap = 1.0 }, -- Total reload time
		Spread = 0.15,
		HeadshotMultiplier = 1.0,
		ProjectileType = "Raycast"
	},
	["Sprinkle Sesame"] = {
		Type = "SemiAuto", -- Pump
		Damage = { Base = 7, GrowthMult = 1.15 },
		PelletCount = 24,
		FireRate = { Base = 0.05, Cap = 0.05 }, -- Shoots as fast as you click
		ClipSize = { Base = 2, Cap = 2 },
		ReserveClips = { Base = 4, Cap = 6 },
		ReloadSpeed = { Base = 1.4, Cap = 0.8 }, -- 0.7s to 0.4s per bullet (x2 for full clip)
		Spread = 0.2,
		HeadshotMultiplier = 1.0,
		ProjectileType = "Raycast"
	},
	["Glizzy shooter"] = {
		Type = "LMG",
		Damage = { Base = 15, GrowthMult = 1.135 },
		FireRate = { Base = 0.3, Cap = 0.05 }, -- Spin up
		ClipSize = { Base = 0, Cap = 0 }, -- Doesn't use clips
		ReserveClips = { Base = 200, Cap = 2500 }, -- Raw ammo count
		ReloadSpeed = { Base = 0, Cap = 0 },
		Spread = 0.06,
		HeadshotMultiplier = 1.5,
		ProjectileType = "Raycast"
	},
	["Bench"] = {
		Type = "SemiAuto",
		Damage = { Base = 80, GrowthMult = 1.145 },
		FireRate = { Base = 1.5, Cap = 0.8 },
		ClipSize = { Base = 4, Cap = 20 },
		ReserveClips = { Base = 2, Cap = 5 },
		ReloadSpeed = { Base = 4.0, Cap = 1.0 },
		Spread = 0.0,
		HeadshotMultiplier = 3.0, -- Boss killer
		ProjectileType = "Raycast"
	},
	["Squat"] = {
		Type = "SemiAuto",
		Damage = { Base = 90, GrowthMult = 1.145 },
		FireRate = { Base = 1.5, Cap = 0.8 },
		ClipSize = { Base = 3, Cap = 16 },
		ReserveClips = { Base = 2, Cap = 5 },
		ReloadSpeed = { Base = 4.0, Cap = 1.0 },
		Spread = 0.0,
		HeadshotMultiplier = 1.0,
		ProjectileType = "PhysicalObject",
		BlastRadius = 15
	},
	["Deadlift"] = {
		Type = "SemiAuto",
		Damage = { Base = 75, GrowthMult = 1.14 },
		FireRate = { Base = 0.6, Cap = 0.3 },
		ClipSize = { Base = 8, Cap = 40 },
		ReserveClips = { Base = 2, Cap = 5 },
		ReloadSpeed = { Base = 3.0, Cap = 0.5 },
		Spread = 0.0,
		HeadshotMultiplier = 1.0,
		ProjectileType = "PhysicalTrajectory",
		BlastRadius = 10
	}
}

return WeaponConfig