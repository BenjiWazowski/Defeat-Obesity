--!strict
local WeaponConfig = {
	["Desert Baegal"] = {
		Type = "SemiAuto", -- Click per shot
		Damage = 40,
		HeadshotMultiplier = 1.5,
		FireRate = 0.5, -- Seconds between shots
		AmmoCapacity = 7,
		ReloadSpeed = 1.8,
		Spread = 0.01, -- Extremely accurate
		ProjectileType = "Raycast"
	},
	["AK 67"] = {
		Type = "Auto", -- Hold to shoot
		Damage = 18,
		HeadshotMultiplier = 1.2,
		FireRate = 0.1, -- Fast firing
		AmmoCapacity = 30,
		ReloadSpeed = 2.2,
		Spread = 0.05, -- Medium accuracy
		ProjectileType = "Raycast"
	},
	["Explosive Poop"] = {
		Type = "AutoShotgun",
		Damage = 8, -- Per pellet
		PelletCount = 8,
		HeadshotMultiplier = 1.0,
		FireRate = 0.4,
		AmmoCapacity = 12,
		ReloadSpeed = 3.0,
		Spread = 0.15, -- Huge spread
		ProjectileType = "Raycast"
	},
    ["Squat"] = {
		Type = "SemiAuto",
		Damage = 100,
		HeadshotMultiplier = 1.0,
		FireRate = 1.5,
		AmmoCapacity = 1,
		ReloadSpeed = 3.5,
		Spread = 0,
		ProjectileType = "PhysicalObject", -- Shoots an actual rocket
        BlastRadius = 15
	}
}

return WeaponConfig