-- Read-only access to client-visible game state. Every lookup is nil-safe: if the game
-- renames something, features report "missing" instead of erroring.
-- Paths/attributes come from the game's own client UI code (UIController, placeVersion 969).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Rarity = require("Rarity")

local Game = {}
local player = Players.LocalPlayer
Game.player = player
Game.KNOWN_PLACE_VERSION = 969

local attackData -- nil = not tried, false = failed, table = loaded
local attackDataError

function Game.attackData()
	if attackData == nil then
		local mod = ReplicatedStorage:FindFirstChild("AttackData")
		if mod and mod:IsA("ModuleScript") then
			-- Same cached table the game's own UI already required; it is static data.
			local ok, data = pcall(require, mod)
			if ok and type(data) == "table" and type(data.List) == "table" then
				attackData = data
			else
				attackData, attackDataError = false, ok and "unexpected format" or tostring(data)
			end
		else
			attackData, attackDataError = false, "ReplicatedStorage.AttackData not found"
		end
	end
	return attackData or nil, attackDataError
end

function Game.styles()
	local ad = Game.attackData()
	return ad and ad.List or {}
end

function Game.style(name)
	if type(name) ~= "string" then
		return nil
	end
	for _, s in ipairs(Game.styles()) do
		if s.Name == name then
			return s
		end
	end
	return nil
end

function Game.tiers()
	local ad = Game.attackData()
	return ad and type(ad.Tiers) == "table" and ad.Tiers or Rarity.FALLBACK_TIERS
end

function Game.chanceOf(name)
	local s = Game.style(name)
	return s and s.Chance
end

function Game.tierOf(name, chance)
	return Rarity.tierName(chance, Game.tiers(), Game.style(name))
end

function Game.tierColor(name, chance)
	local s = Game.style(name)
	if s and s.RarityColor then
		return s.RarityColor
	end
	for _, t in ipairs(Game.tiers()) do
		if type(chance) == "number" and chance <= t.Max then
			return t.Color
		end
	end
	return nil
end

function Game.attr(name)
	return player:GetAttribute(name)
end

function Game.serverNow()
	return workspace:GetServerTimeNow()
end

function Game.humanoid()
	local char = player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

function Game.alive()
	local h = Game.humanoid()
	return h ~= nil and h.Health > 0
end

function Game.equipped()
	local name = Game.attr("EquippedAttack")
	if type(name) ~= "string" or name == "" then
		return nil
	end
	return { name = name, chance = Game.chanceOf(name) }
end

function Game.rollReadyIn()
	return (Game.attr("RollReadyAt") or 0) - Game.serverNow()
end

function Game.mainUI()
	local pg = player:FindFirstChildOfClass("PlayerGui")
	return pg and pg:FindFirstChild("MainUI")
end

function Game.rollRemote()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local r = remotes and remotes:FindFirstChild("RollAttack")
	return (r and r:IsA("RemoteFunction")) and r or nil
end

-- The game's own roll reveal is on screen (a manual roll or ForcedRoll is animating).
function Game.gameRollBusy()
	local ui = Game.mainUI()
	local reveal = ui and ui:FindFirstChild("RollRevealRoot")
	return (reveal and reveal.Visible) or Game.attr("RollConfirmOpen") == true
end

-- Same gate as the game's doRoll(): alive, in the FFA arena, cooldown <= 0.05 s.
-- Plus: never overlap with the game's own roll animation or "You will lose X" confirm.
function Game.rollStatus()
	if not Game.alive() then
		return false, "Dead - no rolling (waiting for respawn)", true
	end
	local inArena=Game.attr("InFFA")
	if type(inArena)~="boolean" then
		return false, "Arena readiness attribute unavailable (InFFA)", false
	end
	if not inArena then
		return false, "Not in the arena - jump down to roll", true
	end
	local left = Game.rollReadyIn()
	if left > 0.05 then
		return false, ("Next roll in %.1fs"):format(left), true
	end
	if Game.gameRollBusy() then
		return false, "Game roll animation or confirm dialog is open", true
	end
	return true, "Ready"
end

-- UnlockedAttacks format is not documented: try JSON, then comma list. INFERRED.
function Game.owned()
	local raw = Game.attr("UnlockedAttacks")
	if type(raw) ~= "string" or raw == "" then
		return nil
	end
	local set = {}
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
	if ok and type(decoded) == "table" then
		for k, v in pairs(decoded) do
			set[type(k) == "string" and k or tostring(v)] = true
		end
	else
		for name in raw:gmatch("[^,;|]+") do
			set[name:match("^%s*(.-)%s*$")] = true
		end
	end
	return set
end

function Game.copy(text)
	-- Executor-provided globals; plain nil when absent.
	local fn = (type(setclipboard) == "function" and setclipboard) or (type(toclipboard) == "function" and toclipboard) or nil
	if not fn then
		return false, "clipboard function not available"
	end
	local ok, err = pcall(fn, text)
	return ok, err
end

return Game
