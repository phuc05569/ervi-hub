-- Rarity rules mirrored from the game's AttackData.Tier (CONFIGURED, placeVersion 969 decompile).
-- Chance is the "1 in N" denominator: larger = rarer. Live tiers replace the fallback when AttackData loads.
local Rarity = {}

Rarity.FALLBACK_TIERS = {
	{ Max = 3, Name = "Common" },
	{ Max = 5, Name = "Uncommon" },
	{ Max = 8, Name = "Rare" },
	{ Max = 12, Name = "Epic" },
	{ Max = math.huge, Name = "Legendary" },
}

-- The game's own "You will lose X" confirm appears when the equipped Chance is above this.
Rarity.GAME_CONFIRM_ABOVE = 125

function Rarity.tierName(chance, tiers, style)
	if style and style.RarityColor and style.RarityName then
		return style.RarityName
	end
	tiers = tiers or Rarity.FALLBACK_TIERS
	if type(chance) ~= "number" then
		return "?"
	end
	for _, tier in ipairs(tiers) do
		if chance <= tier.Max then
			return tier.Name
		end
	end
	return tiers[#tiers].Name
end

-- target = { mode = "chance", min = N }  -> qualifies when chance >= N
-- target = { mode = "style", names = { [name] = true } } -> qualifies on exact name
function Rarity.validTarget(target)
	if type(target) ~= "table" then
		return false
	end
	if target.mode == "chance" then
		return type(target.min) == "number" and target.min >= 1
	elseif target.mode == "style" then
		return type(target.names) == "table" and next(target.names) ~= nil
	end
	return false
end

function Rarity.qualifies(target, name, chance)
	if type(name) ~= "string" then
		return false
	end
	if target.mode == "chance" then
		return type(chance) == "number" and chance >= target.min
	elseif target.mode == "style" then
		return target.names[name] == true
	end
	return false
end

function Rarity.describe(target)
	if target.mode == "chance" then
		return ("odds 1/%d or rarer (Chance >= %d)"):format(target.min, target.min)
	end
	local names = {}
	for name in pairs(target.names) do
		table.insert(names, name)
	end
	table.sort(names)
	return "exact style: " .. table.concat(names, ", ")
end

return Rarity
