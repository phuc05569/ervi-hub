local Rarity = require("Rarity")

return {
	{ "tier boundaries follow the game's Tier table", function(_, eq)
		eq(Rarity.tierName(3), "Common", "3")
		eq(Rarity.tierName(4), "Uncommon", "4")
		eq(Rarity.tierName(8), "Rare", "8")
		eq(Rarity.tierName(12), "Epic", "12")
		eq(Rarity.tierName(13), "Legendary", "13")
		eq(Rarity.tierName(5000), "Legendary", "5000")
	end },
	{ "per-style RarityName override only applies with RarityColor (like the game)", function(_, eq)
		eq(Rarity.tierName(195, nil, { RarityName = "Mythic" }), "Legendary", "no color")
		eq(Rarity.tierName(195, nil, { RarityName = "Mythic", RarityColor = true }), "Mythic", "with color")
	end },
	{ "chance threshold is inclusive and larger is rarer", function(check)
		local t = { mode = "chance", min = 500 }
		check(Rarity.qualifies(t, "X", 500))
		check(Rarity.qualifies(t, "X", 750))
		check(not Rarity.qualifies(t, "X", 444))
		check(not Rarity.qualifies(t, "X", nil), "unknown chance never qualifies")
	end },
	{ "style mode matches exact names only", function(check)
		local t = { mode = "style", names = { Cyborg = true } }
		check(Rarity.qualifies(t, "Cyborg", nil))
		check(not Rarity.qualifies(t, "cyborg", 195))
		check(not Rarity.qualifies(t, "Super Punch", 50))
	end },
	{ "invalid targets are rejected", function(check)
		check(not Rarity.validTarget(nil))
		check(not Rarity.validTarget({ mode = "chance", min = 0 }))
		check(not Rarity.validTarget({ mode = "style", names = {} }))
		check(Rarity.validTarget({ mode = "chance", min = 100 }))
	end },
}
