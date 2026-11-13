local UiImages = require("UiImages")
local UiAssets = require("UiAssets")
local Geometry = require("LogoGeometry")
local Stroke = require("SkeletonStroke")
local Settings = require("Settings")
local SliderValue = require("SliderValue")
local Schema = require("FeatureSchema")

local function near(a, b) return math.abs(a - b) < 1e-6 end

return {
	{ "embedded PNGs decode to valid PNG signatures", function(check, eq)
		for _, data in ipairs({ UiAssets.iconsPng, UiAssets.logoPng }) do
			local bytes = UiImages.decode(data)
			eq(bytes:sub(1, 8), "\137PNG\r\n\26\n", "png signature")
			check(#bytes > 1000, "non-trivial image")
		end
		eq(UiImages.decode("TWFu"), "Man");eq(UiImages.decode("TWE="), "Ma");eq(UiImages.decode("TQ=="), "M")
	end },
	{ "every navigation section has its own atlas icon", function(check, eq)
		local seen = {}
		for _, id in ipairs({ "roll", "styles", "dash", "combat", "visuals", "player", "world", "safe", "teleports", "utility", "settings", "diag", "session" }) do
			local rect = UiImages.iconRects[id]
			check(rect ~= nil, "icon for " .. id)
			local key = rect[1] .. "," .. rect[2]
			check(not seen[key], "unique icon for " .. id)
			seen[key] = true
		end
		eq(UiImages.cell, 48)
		check(UiImages.iconRects.generic ~= nil, "fallback icon for added sections")
	end },
	{ "logo image keeps the exact LogoGeometry aspect ratio", function(check)
		local w, h = UiAssets.logoSize[1], UiAssets.logoSize[2]
		check(math.abs(w / h - Geometry.aspectRatio) < 0.005, "aspect")
	end },
	{ "image loading fails closed without executor file APIs", function(check)
		check(UiImages.logo() == nil and UiImages.icons() == nil, "no getcustomasset in tests -> native fallback")
		UiImages.resolver = function(name) return "rbxasset://ervi/" .. name end
		check(UiImages.logo() == "rbxasset://ervi/logo", "resolver hook")
		UiImages.resolver = nil
	end },
	{ "skeleton thickness: 0.1 steps, saved values kept, honest rendering", function(check, eq)
		local spec
		for _, d in ipairs(Schema) do if d.key == "skeletonThickness" then spec = d end end
		eq(spec.default, 1);eq(spec.min, 0.1);eq(spec.max, 3);eq(spec.step, 0.1)
		for _, v in ipairs({ 0.1, 0.2, 0.3, 0.4, 0.5, 1, 1.5, 2, 3 }) do
			check(near(SliderValue.normalize(v, spec.min, spec.max, spec.step, 1), v), "slider keeps " .. v)
			local store = Settings.newStore();local cfg = Settings.defaults();cfg.skeletonThickness = SliderValue.normalize(v, spec.min, spec.max, spec.step, 1)
			Settings.put(store, "A", cfg)
			check(near(Settings.parse(Settings.serialize(store), {}).configs.A.skeletonThickness, v), "round trip " .. v)
		end
		eq(SliderValue.normalize(0.3, 0.1, 3, 0.1, 1), 0.3, "no float noise")
		eq(Settings.parse("[A]\nskeletonThickness=0.05\n", {}).configs.A.skeletonThickness, 0.1, "clamped low")
		eq(Settings.parse("[A]\nskeletonThickness=0.50\n", {}).configs.A.skeletonThickness, 0.5, "legacy 0.5 kept")
		-- Sub-pixel: a drawable 1 px line whose opacity carries the weight; outline fades with it.
		local w, t, ow, ot = Stroke.resolve(0.3)
		eq(w, 1);check(near(t, 0.7));eq(ow, 3);check(ot > t, "outline lighter than core")
		local w2, t2 = Stroke.resolve(0.1);check(t2 > t and w2 == 1, "0.1 fainter than 0.3")
		w, t, ow, ot = Stroke.resolve(1);eq(w, 1);eq(t, 0);eq(ow, 3);eq(ot, 0)
		w = Stroke.resolve(2.4);eq(w, 2);w = Stroke.resolve(2.5);eq(w, 3)
		w, t = Stroke.resolve(0 / 0);eq(w, 1);eq(t, 0)
		eq(Stroke.describe(0.3), "0.3 px");eq(Stroke.describe(1), "1.0 px");eq(Stroke.describe(1.4), "1.4 px · draws 1")
	end },
	{ "autosave keeps the effective profile: per-game, then global, then Default", function(_, eq)
		local s = Settings.parse("autoloadGame_42=Game\nautoload=Global\n[Default]\n[Global]\n[Game]\n", {})
		eq(Settings.activeName(s, 42), "Game");eq(Settings.activeName(s, 7), "Global")
		s.autoload = nil;eq(Settings.activeName(s, 7), "Default")
		eq(Settings.activeName(Settings.parse("autoload=Ghost\n[DEFAULT]\n", {}), 7), "Default", "missing slot falls back")
		eq(Settings.activeName(Settings.parse("autoload=DEFAULT\n[DEFAULT]\nopacity=0.75\n", {}), 7), "DEFAULT", "owner's current file")
	end },
}
