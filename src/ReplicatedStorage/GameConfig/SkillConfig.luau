--!strict

local SkillConfig = {
	-- ==========================================
	-- COMMON SKILLS (Stat Multipliers)
	-- ==========================================
	["Damage Increase"] = {
		Rarity = "Common",
		Description = "Increases Gun and Melee Damage by 5%.",
		MaxStacks = 999, -- Infinite
		Effects = {
			MeleeDamage = 5, -- Adds +5 to the player's stat (which is +5%)
			GunDamage = 5
		}
	},
	["HP Increase"] = {
		Rarity = "Common",
		Description = "Increases Max HP by 10%.",
		MaxStacks = 999, 
		Effects = {
			Health = 10 -- We will calculate this as a % increase in the StatManager
		}
	},
	["Move Speed Increase"] = {
		Rarity = "Common",
		Description = "Increases Movement Speed by 3%.",
		MaxStacks = 15, 
		Effects = {
			MovementSpeed = 3
		}
	},
	["Hands Speed Increase"] = {
		Rarity = "Common",
		Description = "Increases Swing Speed and Reload Speed by 4%.",
		MaxStacks = 15,
		Effects = {
			MeleeSpeed = -4, -- Negative because lower time is faster
			ReloadSpeed = -4
		}
	},
	["Melee Range Increase"] = {
		Rarity = "Common",
		Description = "Increases Melee Hitbox size by 10%.",
		MaxStacks = 50,
		Effects = {
			MeleeRange = 10
		}
	},
	["Clip Size Increase"] = {
		Rarity = "Common",
		Description = "Increases Ammo Capacity by 10%.",
		MaxStacks = 50,
		Effects = {
			AmmoCapacity = 10
		}
	},

	-- ==========================================
	-- EPIC SKILLS (Game Changers & Weapons)
	-- ==========================================
	["Get Bench"] = {
		Rarity = "Epic",
		Description = "Equip the legendary Sniper Rifle: Bench.",
		MaxStacks = 1,
		WeaponGrant = "Bench"
	},
	["Get Squat"] = {
		Rarity = "Epic",
		Description = "Equip the legendary Rocket Launcher: Squat.",
		MaxStacks = 1,
		WeaponGrant = "Squat"
	},
	["Get Deadlift"] = {
		Rarity = "Epic",
		Description = "Equip the legendary Grenade Launcher: Deadlift.",
		MaxStacks = 1,
		WeaponGrant = "Deadlift"
	},
	
	-- [[ CHANGE THESE NUMBERS TO BALANCE YOUR STATUS EFFECTS ]]
	["Incendiary Rounds"] = {
		Rarity = "Epic",
		Description = "Weapons deal fire damage over time.",
		MaxStacks = 1,
		FireMath = {
			DurationSeconds = 3, 
			TickRate = 1, 
			NormalMobHPDamage = 0.10, 
			EliteBossHPDamage = 0.04,
			ProcChance = 0.15,             -- 15% chance to ignite on bullet hit
			DamageIncreasePerStack = 0.01  -- +1% Max HP damage per extra stack
		}
	},
	["Thunder Strike"] = {
		Rarity = "Epic",
		Description = "Attacks have a chance to summon a Thunder strike.",
		MaxStacks = 999, -- Infinite. Each stack increases proc chance
		ThunderMath = {
			BaseProcChance = 0.8, -- 8% chance to strike
			ProcChancePerStack = 0.02, -- +2% chance per extra time you pick this skill
			NormalMobDamage = 1.00, -- 100% Max HP (Instakill)
			EliteDamage = 0.20, -- 20% Max HP
			BossDamage = 0.10 -- 10% Max HP
		}
	},
	["Exploding Headshots"] = {
		Rarity = "Epic",
		Description = "Headshot kills cause the enemy to explode, dealing AoE damage and dropping sausages.",
		MaxStacks = 1,
		ExplosionMath = {
			BlastRadius = 15, -- Studs
			DamagePercent = 0.55, -- Deals 55% of the dead enemy's max HP
			BonusSausages = 2 -- Extra sausage per enemy killed in the blast
		}
	},
	["Damage Increase ++"] = {
		Rarity = "Epic",
		Description = "Greatly increases Gun and Melee Damage by 45%.",
		MaxStacks = 999,
		Effects = {
			MeleeDamage = 45,
			GunDamage = 45
		}
	}
}

return SkillConfig