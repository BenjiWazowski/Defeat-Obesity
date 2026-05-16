--!strict

local ClassModifiers = {
	["Regular guy"] = {
		Description = "CrossFit guy",
		BaseStats = {
			Health = 100,
			MeleeDamage = 20,
			MeleeRange = 5,
			MeleeSpeed = 0.5, -- Lower is faster
			GunDamage = 20,
			ReloadSpeed = 1.5,
			AmmoCapacity = 30,
			MovementSpeed = 16,
			Luck = 1.0,
			ReviveSpeedMultiplier = 1.10,
			HPRegenPerSecond = 0
		},
		LinearGrowth = {
			Health = 1.25,
			MeleeDamage = 1.25,
			GunDamage = 1.25,
			AmmoCapacity = 1.25,
			HPRegenPerSecond = 0
		},
		DiminishingCaps = {
			MeleeRange = 10, -- Will never exceed 10 studs
			MeleeSpeed = 0.25, -- Will never swing faster than every 0.25s
			ReloadSpeed = 0.5, 
			MovementSpeed = 24, -- Hard physics safety cap
			Luck = 2.5,
			ReviveSpeedMultiplier = 2.0
		}
	},
	
	["Medic guy"] = {
		Description = "Nutritionist",
		BaseStats = {
			Health = 120,
			MeleeDamage = 15,
			MeleeRange = 5,
			MeleeSpeed = 0.6,
			GunDamage = 15,
			ReloadSpeed = 1.5,
			AmmoCapacity = 30,
			MovementSpeed = 16,
			Luck = 1.0,
			ReviveSpeedMultiplier = 1.50,
			HPRegenPerSecond = 1.0 -- Base 1 HP/sec
		},
		LinearGrowth = {
			Health = 1.50,
			MeleeDamage = 1.0,
			GunDamage = 1.0,
			AmmoCapacity = 1.0,
			HPRegenPerSecond = 0.1 -- Infinite scaling at lowered rate
		},
		DiminishingCaps = {
			MeleeRange = 10,
			MeleeSpeed = 0.3,
			ReloadSpeed = 0.5,
			MovementSpeed = 24,
			Luck = 2.5,
			ReviveSpeedMultiplier = 3.0 -- Medics cap out at very fast revives
		}
	},
	
	["Melee guy"] = {
		Description = "Power lifter",
		BaseStats = {
			Health = 130,
			MeleeDamage = 35,
			MeleeRange = 6, 
			MeleeSpeed = 0.45,
			GunDamage = 0,
			ReloadSpeed = 0,
			AmmoCapacity = 0,
			MovementSpeed = 15,
			Luck = 1.0,
			ReviveSpeedMultiplier = 1.0,
			HPRegenPerSecond = 0
		},
		LinearGrowth = {
			Health = 1.50,
			MeleeDamage = 1.50,
			GunDamage = 0,
			AmmoCapacity = 0,
			HPRegenPerSecond = 0
		},
		DiminishingCaps = {
			MeleeRange = 12, -- Melee guy gets slightly longer max range
			MeleeSpeed = 0.2, -- Swings faster at cap
			ReloadSpeed = 0,
			MovementSpeed = 23,
			Luck = 2.5,
			ReviveSpeedMultiplier = 2.0
		}
	},
	
	["Guns guy"] = {
		Description = "Body Builder",
		BaseStats = {
			Health = 100,
			MeleeDamage = 0, 
			MeleeRange = 0,
			MeleeSpeed = 0,
			GunDamage = 35,
			ReloadSpeed = 1.2,
			AmmoCapacity = 45,
			MovementSpeed = 16,
			Luck = 1.0,
			ReviveSpeedMultiplier = 1.0,
			HPRegenPerSecond = 0
		},
		LinearGrowth = {
			Health = 1.0,
			MeleeDamage = 0,
			GunDamage = 1.50,
			AmmoCapacity = 1.50,
			HPRegenPerSecond = 0
		},
		DiminishingCaps = {
			MeleeRange = 0,
			MeleeSpeed = 0,
			ReloadSpeed = 0.25, -- Very fast reloads at cap
			MovementSpeed = 24,
			Luck = 2.5,
			ReviveSpeedMultiplier = 2.0
		}
	},
	
	["Gamble Guy"] = {
		Description = "Degenerate Guy",
		BaseStats = {
			Health = 100,
			MeleeDamage = 20,
			MeleeRange = 5,
			MeleeSpeed = 0.5,
			GunDamage = 20,
			ReloadSpeed = 1.5,
			AmmoCapacity = 30,
			MovementSpeed = 16,
			Luck = 1.5, -- Base luck is higher
			ReviveSpeedMultiplier = 1.0,
			HPRegenPerSecond = 0
		},
		LinearGrowth = {
			Health = 1.0,
			MeleeDamage = 1.0,
			GunDamage = 1.0,
			AmmoCapacity = 1.0,
			HPRegenPerSecond = 0
		},
		DiminishingCaps = {
			MeleeRange = 10,
			MeleeSpeed = 0.25,
			ReloadSpeed = 0.5,
			MovementSpeed = 24,
			Luck = 5.0, -- Degenerate gets absurd max luck potential
			ReviveSpeedMultiplier = 2.0
		}
	}
}

return ClassModifiers