-- Design tokens and the selectable looks. Theme is mutated in place by Theme.apply(), so code
-- that reads Theme.* at use time follows the current look; Ui.applyLook() repaints what was
-- already built by mapping each old token color to its new value (tokens are distinct per preset).
local rgb = Color3.fromRGB

local Theme = {
	font = Enum.Font.Gotham,
	fontMedium = Enum.Font.GothamMedium,
	fontBold = Enum.Font.GothamBold,
	mono = Enum.Font.Code,
	brandFont = Enum.Font.Merriweather, -- "Ervi Hub" title; never changed by the font picker

	-- neutrals + accent: replaced by the preset (initial values = Midnight)
	bg = rgb(14, 15, 20),
	surface = rgb(21, 23, 30),
	surface2 = rgb(28, 31, 40),
	raised = rgb(37, 41, 53),
	hover = rgb(46, 51, 66),
	stroke = rgb(50, 55, 70),
	text = rgb(236, 238, 244),
	muted = rgb(152, 158, 175),
	faint = rgb(100, 106, 124),
	accent = rgb(112, 140, 255),
	accentHover = rgb(134, 160, 255),

	-- fixed across looks so status always reads the same
	onAccent = rgb(255, 255, 255),
	good = rgb(78, 208, 128),
	warn = rgb(245, 186, 72),
	bad = rgb(238, 88, 88),
	info = rgb(96, 172, 255),

	size = { title = 16, h2 = 14, body = 13, small = 12, tiny = 11, big = 30 },
	radius = 10,
	radiusSm = 6,
	pad = 12,
	gap = 8,
	rowH = 30,
	windowW = 660,
	windowH = 450,
	sidebarW = 150,
	titleH = 42,
}

local NEUTRALS = { "bg", "surface", "surface2", "raised", "hover", "stroke", "text", "muted", "faint" }
Theme.TOKENS = { "bg", "surface", "surface2", "raised", "hover", "stroke", "text", "muted", "faint", "accent", "accentHover" }

Theme.PRESETS = {
	{ name = "Midnight", accent = "Indigo", bg = rgb(14, 15, 20), surface = rgb(21, 23, 30), surface2 = rgb(28, 31, 40), raised = rgb(37, 41, 53), hover = rgb(46, 51, 66), stroke = rgb(50, 55, 70), text = rgb(236, 238, 244), muted = rgb(152, 158, 175), faint = rgb(100, 106, 124) },
	{ name = "Graphite", accent = "Cyan", bg = rgb(18, 18, 19), surface = rgb(26, 26, 28), surface2 = rgb(34, 34, 37), raised = rgb(45, 45, 49), hover = rgb(56, 56, 61), stroke = rgb(61, 61, 66), text = rgb(241, 241, 242), muted = rgb(161, 161, 167), faint = rgb(111, 111, 118) },
	{ name = "Ocean", accent = "Sky", bg = rgb(9, 17, 28), surface = rgb(13, 25, 40), surface2 = rgb(18, 33, 52), raised = rgb(26, 45, 68), hover = rgb(34, 57, 84), stroke = rgb(38, 62, 90), text = rgb(230, 242, 255), muted = rgb(140, 165, 190), faint = rgb(92, 116, 142) },
	{ name = "Crimson", accent = "Rose", bg = rgb(20, 10, 12), surface = rgb(29, 15, 18), surface2 = rgb(38, 20, 24), raised = rgb(52, 28, 33), hover = rgb(64, 35, 41), stroke = rgb(72, 40, 46), text = rgb(250, 236, 238), muted = rgb(185, 150, 156), faint = rgb(132, 100, 106) },
	{ name = "Forest", accent = "Mint", bg = rgb(11, 17, 13), surface = rgb(16, 25, 19), surface2 = rgb(22, 33, 26), raised = rgb(31, 45, 35), hover = rgb(40, 57, 45), stroke = rgb(44, 62, 49), text = rgb(234, 246, 236), muted = rgb(150, 175, 156), faint = rgb(100, 124, 106) },
	{ name = "Light", accent = "Indigo", bg = rgb(232, 235, 241), surface = rgb(244, 246, 250), surface2 = rgb(252, 252, 254), raised = rgb(222, 226, 234), hover = rgb(208, 213, 224), stroke = rgb(196, 202, 214), text = rgb(24, 26, 32), muted = rgb(86, 92, 108), faint = rgb(128, 134, 148) },
}

Theme.ACCENTS = {
	{ name = "Indigo", color = rgb(112, 140, 255) },
	{ name = "Violet", color = rgb(166, 112, 255) },
	{ name = "Rose", color = rgb(240, 98, 142) },
	{ name = "Sky", color = rgb(62, 168, 240) },
	{ name = "Cyan", color = rgb(42, 198, 210) },
	{ name = "Mint", color = rgb(64, 196, 146) },
	{ name = "Amber", color = rgb(236, 164, 46) },
}

-- Only fonts present in Enum.Font (checked against the Roblox API dump).
Theme.FONTS = {
	{ name = "Gotham", regular = Enum.Font.Gotham, medium = Enum.Font.GothamMedium, bold = Enum.Font.GothamBold },
	{ name = "Source Sans", regular = Enum.Font.SourceSans, medium = Enum.Font.SourceSansSemibold, bold = Enum.Font.SourceSansBold },
	{ name = "Arial", regular = Enum.Font.Arial, medium = Enum.Font.Arial, bold = Enum.Font.ArialBold },
	{ name = "Roboto", regular = Enum.Font.Roboto, medium = Enum.Font.Roboto, bold = Enum.Font.RobotoCondensed },
	{ name = "Ubuntu", regular = Enum.Font.Ubuntu, medium = Enum.Font.Ubuntu, bold = Enum.Font.Ubuntu },
	{ name = "Nunito", regular = Enum.Font.Nunito, medium = Enum.Font.Nunito, bold = Enum.Font.Nunito },
	{ name = "Fredoka", regular = Enum.Font.FredokaOne, medium = Enum.Font.FredokaOne, bold = Enum.Font.FredokaOne },
	{ name = "Arcade", regular = Enum.Font.Arcade, medium = Enum.Font.Arcade, bold = Enum.Font.Arcade },
}

-- "Theme" keeps the preset's own text color. Values avoid the fixed status colors.
Theme.TEXT_COLORS = {
	{ name = "Theme" },
	{ name = "White", color = rgb(250, 250, 250) },
	{ name = "Gold", color = rgb(255, 214, 120) },
	{ name = "Cyan", color = rgb(150, 230, 255) },
	{ name = "Pink", color = rgb(255, 170, 210) },
	{ name = "Mint", color = rgb(170, 250, 205) },
}

function Theme.find(list, name)
	for _, item in ipairs(list) do
		if item.name == name then
			return item
		end
	end
	return nil
end

-- "#RRGGBB" -> Color3, anything else -> nil.
function Theme.hex(s)
	if type(s) == "string" and s:match("^#%x%x%x%x%x%x$") then
		return Color3.fromHex(s)
	end
	return nil
end

local WHITE = Color3.new(1, 1, 1)
local LIGHT = Theme.PRESETS[6]

-- look: { theme, accent ("" | name | "#hex"), font, textColor (name | "#hex"), bgColor ("" | "#hex") }.
-- Mutates Theme and returns { [oldHex] = newColor } for repainting existing UI.
function Theme.apply(look)
	local preset = Theme.find(Theme.PRESETS, look.theme) or Theme.PRESETS[1]
	local font = Theme.find(Theme.FONTS, look.font) or Theme.FONTS[1]

	local new = {}
	for _, k in ipairs(NEUTRALS) do
		new[k] = preset[k]
	end
	-- Custom background: panels are progressively lighter shades of it; light backgrounds get dark text.
	local bg = Theme.hex(look.bgColor)
	if bg then
		new.bg = bg
		new.surface = bg:Lerp(WHITE, 0.04)
		new.surface2 = bg:Lerp(WHITE, 0.08)
		new.raised = bg:Lerp(WHITE, 0.15)
		new.hover = bg:Lerp(WHITE, 0.22)
		new.stroke = bg:Lerp(WHITE, 0.27)
		local _, _, value = bg:ToHSV()
		local textSource = value > 0.7 and LIGHT or Theme.PRESETS[1]
		new.text, new.muted, new.faint = textSource.text, textSource.muted, textSource.faint
	end
	local textColor = Theme.find(Theme.TEXT_COLORS, look.textColor)
	new.text = Theme.hex(look.textColor) or (textColor and textColor.color) or new.text
	local accent = Theme.find(Theme.ACCENTS, look.accent ~= "" and look.accent or preset.accent) or Theme.ACCENTS[1]
	new.accent = Theme.hex(look.accent) or accent.color
	new.accentHover = new.accent:Lerp(WHITE, 0.18)

	-- Repainting maps colors by value, so every token must be unique and differ from the fixed
	-- status colors. A clash is nudged by one RGB step (invisible).
	local used = {}
	for _, k in ipairs({ "onAccent", "good", "warn", "bad", "info" }) do
		used[Theme[k]:ToHex()] = true
	end
	for _, k in ipairs(Theme.TOKENS) do
		local c = new[k]
		local step = 0
		while used[c:ToHex()] do
			step += 1
			local r = math.floor(c.R * 255 + 0.5)
			c = Color3.fromRGB(r >= 128 and r - step or r + step, math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
		end
		used[c:ToHex()] = true
		new[k] = c
	end

	local map = {}
	for _, k in ipairs(Theme.TOKENS) do
		map[Theme[k]:ToHex()] = new[k]
		Theme[k] = new[k]
	end
	Theme.font, Theme.fontMedium, Theme.fontBold = font.regular, font.medium, font.bold
	return map
end

return Theme
