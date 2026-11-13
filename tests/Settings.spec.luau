local Settings = require("Settings")

local function oneOf(list)
	local set = {}
	for _, v in ipairs(list) do
		set[v] = true
	end
	return function(v)
		return set[v] == true
	end
end
local V = {
	toggleKey = oneOf({ "RightShift", "F4", "K" }),
	theme = oneOf({ "Midnight", "Ocean" }),
	accent = oneOf({ "", "Rose" }),
	font = oneOf({ "Gotham", "Arcade" }),
	textColor = oneOf({ "Theme", "Gold" }),
	bgColor = function(v)
		return v == "" or v:match("^#%x%x%x%x%x%x$") ~= nil
	end,
}

return {
	{ "missing file gives an empty store", function(check, eq)
		local s = Settings.parse(nil, V)
		eq(#s.order, 0, "no configs")
		check(s.autoload == nil, "no autoload")
	end },
	{ "round trip keeps every config, order and autoload", function(_, eq)
		local s = Settings.newStore()
		local a = Settings.defaults()
		a.toggleKey, a.opacity, a.theme, a.accent, a.font, a.textScale, a.outline, a.textAlpha = "F4", 0.6, "Ocean", "Rose", "Arcade", 1.2, "on", 0.3
		Settings.put(s, "Default", Settings.defaults())
		Settings.put(s, "PvP", a)
		s.autoload = "PvP"
		local r = Settings.parse(Settings.serialize(s), V)
		eq(table.concat(r.order, ","), "Default,PvP", "order")
		eq(r.autoload, "PvP", "autoload")
		local p = r.configs.PvP
		eq(p.toggleKey, "F4", "key")
		eq(p.opacity, 0.6, "opacity")
		eq(p.theme, "Ocean", "theme")
		eq(p.accent, "Rose", "accent")
		eq(p.font, "Arcade", "font")
		eq(p.textScale, 1.2, "text size")
		eq(p.outline, "on", "outline")
		eq(p.textAlpha, 0.3, "text transparency")
		eq(r.configs.Default.accent, "", "empty accent survives")
	end },
	{ "bad values fall back or clamp", function(_, eq)
		local r = Settings.parse("[A]\ntoggleKey=NotAKey\nopacity=0.01\nscale=9\ntheme=Hacker\noutline=maybe\ntextAlpha=5\njunk\n", V)
		local a = r.configs.A
		eq(a.toggleKey, "RightShift", "unknown key ignored")
		eq(a.opacity, Settings.MIN_OPACITY, "opacity clamped")
		eq(a.scale, 1.5, "scale clamped")
		eq(a.theme, "Midnight", "unknown theme ignored")
		eq(a.outline, "auto", "bad outline ignored")
		eq(a.textAlpha, 0.6, "text transparency clamped")
	end },
	{ "2.1.x single-config file migrates into Default", function(_, eq)
		local r = Settings.parse("toggleKey=F4\r\nopacity=0.80\r\nscale=1.00\r\n", V)
		eq(table.concat(r.order, ","), "Default", "one config")
		eq(r.configs.Default.toggleKey, "F4", "key kept")
		eq(r.configs.Default.opacity, 0.8, "opacity kept")
	end },
	{ "autoload pointing at a missing config is dropped", function(check)
		check(Settings.parse("autoload=Ghost\n[Default]\n", V).autoload == nil)
	end },
	{ "invalid section names are skipped with their lines", function(_, eq)
		local r = Settings.parse("[../evil]\ntoggleKey=F4\n[Ok]\ntoggleKey=K\n", V)
		eq(table.concat(r.order, ","), "Ok", "only valid section")
		eq(r.configs.Ok.toggleKey, "K", "valid section parsed")
	end },
	{ "names: trimmed, length and character limits", function(check, eq)
		eq(Settings.cleanName("  My PvP-1 "), "My PvP-1", "trim")
		check(Settings.cleanName("") == nil, "empty")
		check(Settings.cleanName(("x"):rep(25)) == nil, "too long")
		check(Settings.cleanName("a/b") == nil, "slash")
		check(Settings.cleanName("a]b") == nil, "bracket")
	end },
	{ "delete removes config and clears its autoload", function(check, eq)
		local s = Settings.newStore()
		Settings.put(s, "A", Settings.defaults())
		Settings.put(s, "B", Settings.defaults())
		s.autoload = "B"
		check(Settings.delete(s, "B"))
		eq(table.concat(s.order, ","), "A", "order")
		check(s.autoload == nil, "autoload cleared")
		check(not Settings.delete(s, "B"), "second delete is a no-op")
	end },
	{ "put overwrites in place without duplicating", function(_, eq)
		local s = Settings.newStore()
		Settings.put(s, "A", Settings.defaults())
		local c = Settings.defaults()
		c.opacity = 0.5
		Settings.put(s, "A", c)
		eq(#s.order, 1, "no duplicate")
		eq(s.configs.A.opacity, 0.5, "overwritten")
	end },
	{ "booleans and custom colors round trip; junk ignored", function(check, eq)
		local s = Settings.newStore()
		local c = Settings.defaults()
		c.antiAfk, c.reconnect, c.autoExec, c.bgColor = true, false, true, "#1A2B3C"
		Settings.put(s, "A", c)
		local r = Settings.parse(Settings.serialize(s), V).configs.A
		check(r.antiAfk == true and r.reconnect == false and r.autoExec == true, "booleans")
		eq(r.bgColor, "#1A2B3C", "bg color")
		local j = Settings.parse("[B]\nantiAfk=yes\nbgColor=red\n", V).configs.B
		check(j.antiAfk == false, "bad boolean ignored")
		eq(j.bgColor, "", "bad color ignored")
	end },
	{ "window size and instant prompts round trip and clamp", function(check, eq)
		local s = Settings.newStore()
		local c = Settings.defaults()
		c.winW, c.winH, c.instantPrompts = 800, 520, true
		Settings.put(s, "A", c)
		local r = Settings.parse(Settings.serialize(s), V).configs.A
		eq(r.winW, 800, "width")
		eq(r.winH, 520, "height")
		check(r.instantPrompts == true, "instant prompts")
		local j = Settings.parse("[B]\nwinW=5\nwinH=99999\n", V).configs.B
		eq(j.winW, 520, "width clamped up")
		eq(j.winH, 820, "height clamped down")
	end },
	{ "defaults are never mutated", function(_, eq)
		local c = Settings.defaults()
		c.toggleKey = "F4"
		Settings.parse("[X]\ntoggleKey=F4\n", V)
		eq(Settings.DEFAULTS.toggleKey, "RightShift", "defaults intact")
	end },
}
