-- Small component kit on raw Roblox instances (no third-party UI library, no loadstring).
local UserInputService = game:GetService("UserInputService")
local Theme = require("Theme")

local Ui = {}

-- Appearance state shared by every component (also ones built later):
--   opacity   -> BackgroundTransparency of registered surfaces (window, panels, cards, overlay)
--   textScale / textAlpha / outline -> every text object (outline "auto" = only below 60% opacity)
Ui.opacity = 1
Ui.textScale = 1
Ui.textAlpha = 0
Ui.outline = "auto"
local LOW_OPACITY = 0.6
local TEXT_STROKE = 0.55
local TEXT_CLASSES = { TextLabel = true, TextButton = true, TextBox = true }
local FONT_ROLES = { "fontBold", "fontMedium", "font", "mono" }
local surfaces = setmetatable({}, { __mode = "k" })
local roots = setmetatable({}, { __mode = "k" })

local function outlineOn()
	return Ui.outline == "on" or (Ui.outline == "auto" and Ui.opacity < LOW_OPACITY)
end

-- Size from the unscaled base (kept as an attribute), plus transparency and outline.
local function styleText(inst)
	local base = inst:GetAttribute("BaseTextSize")
	if not base then
		base = inst.TextSize
		inst:SetAttribute("BaseTextSize", base)
	end
	inst.TextSize = math.floor(base * Ui.textScale + 0.5)
	inst.TextTransparency = inst:GetAttribute("Disabled") and math.max(0.5, Ui.textAlpha) or Ui.textAlpha
	inst.TextStrokeTransparency = outlineOn() and TEXT_STROKE or 1
end

function Ui.new(class, props, children)
	local inst = Instance.new(class)
	local parent = props and props.Parent
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then
			inst[k] = v
		end
	end
	if TEXT_CLASSES[class] then
		for _, role in ipairs(FONT_ROLES) do
			if props and props.Font == Theme[role] then
				inst:SetAttribute("FontRole", role) -- lets a font change re-map this text later
				break
			end
		end
		styleText(inst)
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

-- Registers a ScreenGui whose contents follow look changes.
function Ui.root(gui)
	roots[gui] = true
	return gui
end

-- Registers a background surface so it follows the menu opacity.
function Ui.surface(inst)
	surfaces[inst] = true
	inst.BackgroundTransparency = 1 - Ui.opacity
	return inst
end

local function eachText(fn)
	for root in pairs(roots) do
		if root.Parent then
			for _, d in ipairs(root:GetDescendants()) do
				if TEXT_CLASSES[d.ClassName] then
					fn(d)
				end
			end
		end
	end
end

function Ui.setOpacity(o, minimum)
	o = math.clamp(o, minimum or 0, 1)
	local outlineBefore = outlineOn()
	Ui.opacity = o
	for inst in pairs(surfaces) do
		if inst.Parent then
			inst.BackgroundTransparency = 1 - o
		end
	end
	if outlineOn() ~= outlineBefore then
		eachText(styleText) -- only when "auto" outline flips, so dragging the slider stays cheap
	end
	return o
end

-- Applies a full look (design, accent, font, text color/size/transparency/outline) and repaints
-- everything already built. FixedBackground / FixedTextColor elements (color previews) keep theirs.
function Ui.applyLook(look)
	local map = Theme.apply(look)
	Ui.textScale, Ui.textAlpha, Ui.outline = look.textScale, look.textAlpha, look.outline
	local function remap(inst, prop)
		local c = inst[prop]
		local new = c and map[c:ToHex()]
		if new then
			inst[prop] = new
		end
	end
	for root in pairs(roots) do
		if root.Parent then
			for _, d in ipairs(root:GetDescendants()) do
				local isText = TEXT_CLASSES[d.ClassName]
				if d:IsA("GuiObject") and not d:GetAttribute("FixedBackground") then
					remap(d, "BackgroundColor3")
				end
				if d:IsA("UIStroke") then
					if not d:GetAttribute("FixedBackground") then
						remap(d, "Color")
					end
				elseif d:IsA("ScrollingFrame") then
					remap(d, "ScrollBarImageColor3")
				end
				if isText and not d:GetAttribute("FixedTextColor") then
					remap(d, "TextColor3")
					if d:IsA("TextBox") then
						remap(d, "PlaceholderColor3")
					end
				end
				if isText then
					local role = d:GetAttribute("FontRole")
					if role then
						d.Font = Theme[role]
					end
					styleText(d)
				end
			end
		end
	end
end

-- Assign only when changed: avoids needless property writes from the 10 Hz refresh loop.
function Ui.set(inst, prop, value)
	if inst[prop] ~= value then
		inst[prop] = value
	end
end

function Ui.corner(parent, r)
	return Ui.new("UICorner", { CornerRadius = UDim.new(0, r or Theme.radiusSm), Parent = parent })
end

function Ui.stroke(parent, color, transparency)
	return Ui.new("UIStroke", {
		Color = color or Theme.stroke,
		Transparency = transparency or 0,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

function Ui.pad(parent, t, r, b, l)
	return Ui.new("UIPadding", {
		PaddingTop = UDim.new(0, t),
		PaddingRight = UDim.new(0, r or t),
		PaddingBottom = UDim.new(0, b or t),
		PaddingLeft = UDim.new(0, l or r or t),
		Parent = parent,
	})
end

function Ui.list(parent, gap, horizontal, valign)
	return Ui.new("UIListLayout", {
		Padding = UDim.new(0, gap or Theme.gap),
		FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = valign or Enum.VerticalAlignment.Top,
		Parent = parent,
	})
end

-- Auto-height wrapped text.
function Ui.text(parent, text, opts)
	opts = opts or {}
	return Ui.new("TextLabel", {
		BackgroundTransparency = 1,
		Size = opts.size or UDim2.new(1, 0, 0, 0),
		AutomaticSize = opts.size and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
		Text = text,
		RichText = opts.rich or false,
		TextWrapped = true,
		TextColor3 = opts.color or Theme.text,
		TextSize = opts.textSize or Theme.size.body,
		Font = opts.font or Theme.font,
		TextXAlignment = opts.align or Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		LayoutOrder = opts.order or 0,
		Parent = parent,
	})
end

-- Theme token names (looked up at use time so looks can change) or fixed colors.
local VARIANTS = {
	primary = { bg = "accent", hover = "accentHover", fg = "onAccent" },
	secondary = { bg = "raised", hover = "hover", fg = "text" },
	danger = { bg = Color3.fromRGB(120, 38, 42), hover = Color3.fromRGB(150, 48, 52), fg = "text" },
	ghost = { bg = "surface2", hover = "raised", fg = "muted" },
}
local function color(c)
	return type(c) == "string" and Theme[c] or c
end

-- Returns the button plus setEnabled(bool). Disabled buttons ignore clicks and look dimmed.
function Ui.button(scope, parent, text, opts, onClick)
	opts = opts or {}
	local v = VARIANTS[opts.variant or "secondary"]
	local enabled = true
	local btn = Ui.new("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = color(v.bg),
		Size = opts.size or UDim2.new(0, opts.width or 110, 0, opts.height or Theme.rowH),
		Text = text,
		TextColor3 = color(v.fg),
		TextSize = opts.textSize or Theme.size.body,
		Font = Theme.fontMedium,
		LayoutOrder = opts.order or 0,
		Parent = parent,
	})
	Ui.corner(btn)
	scope:connect(btn.MouseEnter, function()
		if enabled and not btn:GetAttribute("FixedBackground") then
			btn.BackgroundColor3 = btn:GetAttribute("Selected") and Theme.accentHover or color(v.hover)
		end
	end)
	scope:connect(btn.MouseLeave, function()
		if btn:GetAttribute("FixedBackground") then
			return
		end
		btn.BackgroundColor3 = btn:GetAttribute("Selected") and Theme.accent or color(v.bg)
	end)
	if onClick then
		scope:connect(btn.Activated, function()
			if enabled then
				onClick()
			end
		end)
	end
	local function setEnabled(on)
		enabled = on
		btn:SetAttribute("Disabled", not on or nil)
		btn.BackgroundTransparency = on and 0 or 0.55
		btn.TextTransparency = on and Ui.textAlpha or math.max(0.5, Ui.textAlpha)
	end
	return btn, setEnabled
end

-- Wrapping grid of equal cells (for option pickers).
function Ui.grid(parent, cellW, cellH, order)
	local f = Ui.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order or 0,
		Parent = parent,
	})
	Ui.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(cellW, cellH),
		CellPadding = UDim2.fromOffset(6, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = f,
	})
	return f
end

-- Marks a secondary button as the selected option of a group (survives hover).
function Ui.select(btn, on)
	btn:SetAttribute("Selected", on or nil)
	btn.BackgroundColor3 = on and Theme.accent or Theme.raised
end

-- Card: titled surface whose height follows its content.
function Ui.card(parent, title, order, subtitle)
	local card = Ui.new("Frame", {
		BackgroundColor3 = Theme.surface2,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order or 0,
		Parent = parent,
	})
	Ui.surface(card)
	Ui.corner(card, Theme.radius)
	Ui.stroke(card, Theme.stroke, 0.35)
	Ui.pad(card, Theme.pad)
	Ui.list(card, Theme.gap)
	if title then
		Ui.text(card, title:upper(), { font = Theme.fontBold, textSize = Theme.size.tiny, color = Theme.muted, order = -2 })
	end
	if subtitle then
		Ui.text(card, subtitle, { textSize = Theme.size.small, color = Theme.faint, order = -1 })
	end
	return card
end

-- Horizontal row container (fixed height) for button groups.
function Ui.row(parent, order, height)
	local row = Ui.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height or Theme.rowH),
		LayoutOrder = order or 0,
		Parent = parent,
	})
	Ui.list(row, 6, true, Enum.VerticalAlignment.Center)
	return row
end

-- Key/value line. Returns setter(text, color?).
function Ui.kv(parent, key, order)
	local row = Ui.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = order or 0, Parent = parent })
	Ui.text(row, key, { size = UDim2.new(0.42, 0, 1, 0), color = Theme.muted, textSize = Theme.size.small })
	local value = Ui.text(row, "-", { size = UDim2.new(0.58, 0, 1, 0), align = Enum.TextXAlignment.Right, font = Theme.fontMedium, textSize = Theme.size.small })
	value.Position = UDim2.fromScale(0.42, 0)
	value.TextTruncate = Enum.TextTruncate.AtEnd
	value.TextWrapped = false
	return function(text, color)
		Ui.set(value, "Text", text)
		Ui.set(value, "TextColor3", color or Theme.text)
	end
end

local PILL = { good = "good", warn = "warn", bad = "bad", info = "info", idle = "muted" }

-- Status pill. Returns setter(text, kind) where kind is good|warn|bad|info|idle.
function Ui.pill(parent, order)
	local pill = Ui.new("TextLabel", {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 0, 22),
		BackgroundColor3 = Theme.raised,
		Text = "",
		TextSize = Theme.size.tiny,
		Font = Theme.fontBold,
		TextColor3 = Theme.muted,
		LayoutOrder = order or 0,
		Parent = parent,
	})
	Ui.corner(pill, 11)
	Ui.pad(pill, 0, 10)
	return function(text, kind)
		Ui.set(pill, "Text", text:upper())
		Ui.set(pill, "TextColor3", Theme[PILL[kind or "idle"] or "muted"])
	end
end

-- Progress bar. Returns setter(fraction 0..1, color?).
function Ui.bar(parent, order, height)
	local track = Ui.new("Frame", {
		BackgroundColor3 = Theme.raised,
		Size = UDim2.new(1, 0, 0, height or 8),
		LayoutOrder = order or 0,
		Parent = parent,
	})
	Ui.corner(track, 4)
	local fill = Ui.new("Frame", { BackgroundColor3 = Theme.accent, Size = UDim2.fromScale(0, 1), Parent = track })
	Ui.corner(fill, 4)
	return function(frac, color)
		frac = math.clamp(frac, 0, 1)
		Ui.set(fill, "Size", UDim2.fromScale(frac, 1))
		Ui.set(fill, "Visible", frac > 0)
		if color then
			Ui.set(fill, "BackgroundColor3", color)
		end
	end
end

-- iOS-style switch with label and description. Returns { set(bool, silent), get() }.
function Ui.toggle(scope, parent, label, desc, initial, onChange, order)
	local row = Ui.new("TextButton", {
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order or 0,
		Parent = parent,
	})
	local textCol = Ui.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -56, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = row })
	Ui.list(textCol, 2)
	Ui.text(textCol, label, { font = Theme.fontMedium })
	if desc then
		Ui.text(textCol, desc, { textSize = Theme.size.small, color = Theme.faint, order = 1 })
	end
	local track = Ui.new("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 2),
		Size = UDim2.fromOffset(42, 22),
		BackgroundColor3 = Theme.raised,
		Parent = row,
	})
	Ui.corner(track, 11)
	local knob = Ui.new("Frame", { Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = Theme.muted, Parent = track })
	Ui.corner(knob, 8)
	local value = false
	local api = {}
	function api.set(on, silent)
		value = on == true
		track.BackgroundColor3 = value and Theme.accent or Theme.raised
		knob.BackgroundColor3 = value and Theme.onAccent or Theme.muted
		knob.Position = UDim2.fromOffset(value and 23 or 3, 3)
		if not silent and onChange then
			onChange(value)
		end
	end
	function api.get()
		return value
	end
	api.set(initial, true)
	scope:connect(row.Activated, function()
		api.set(not value)
	end)
	return api
end

function Ui.input(scope, parent, placeholder, opts, onCommit)
	opts = opts or {}
	local box = Ui.new("TextBox", {
		BackgroundColor3 = Theme.surface,
		Size = opts.size or UDim2.new(0, opts.width or 160, 0, Theme.rowH),
		ClearTextOnFocus = false,
		PlaceholderText = placeholder,
		PlaceholderColor3 = Theme.faint,
		Text = opts.text or "",
		TextColor3 = Theme.text,
		TextSize = opts.textSize or Theme.size.body,
		Font = opts.font or Theme.font,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = opts.multiline or false,
		MultiLine = opts.multiline or false,
		TextYAlignment = opts.multiline and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
		LayoutOrder = opts.order or 0,
		Parent = parent,
	})
	Ui.corner(box)
	local stroke = Ui.stroke(box, Theme.stroke)
	Ui.pad(box, opts.multiline and 8 or 0, 10)
	scope:connect(box.Focused, function()
		stroke.Color = Theme.accent
	end)
	scope:connect(box.FocusLost, function(enter)
		stroke.Color = Theme.stroke
		if onCommit then
			onCommit(box.Text, enter)
		end
	end)
	return box
end

-- Drag `target` by `handle` (mouse or touch). Replaces the deprecated Frame.Draggable.
function Ui.drag(scope, handle, target)
	local dragging, startInput, startPos
	scope:connect(handle.InputBegan, function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
			dragging, startInput, startPos = true, input.Position, target.Position
		end
	end)
	scope:connect(UserInputService.InputEnded, function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	scope:connect(UserInputService.InputChanged, function(input)
		if not dragging then
			return
		end
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
			local d = input.Position - startInput
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

-- Vertical scrolling page that grows with content.
function Ui.scroll(parent, props)
	local sf = Ui.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.stroke,
		Parent = parent,
	})
	for k, v in pairs(props or {}) do
		sf[k] = v
	end
	return sf
end

-- Color circle: hue = angle, saturation = distance from the centre (brightness comes from a
-- separate slider via setValue). Built from rotated gradient bars clipped to a circle - no assets.
-- Returns { set(color), setValue(v), get() -> Color3, wheel }. onPick(color) fires while picking.
function Ui.colorWheel(scope, parent, size, order, onPick)
	local holder = Ui.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, size), LayoutOrder = order or 0, Parent = parent })
	local wheel = Ui.new("CanvasGroup", { Size = UDim2.fromOffset(size, size), BackgroundColor3 = Color3.new(1, 1, 1), Active = true, Parent = holder })
	wheel:SetAttribute("FixedBackground", true)
	Ui.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = wheel })
	for i = 0, 89 do
		local angle = i * 2
		local bar = Ui.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, 0, 0, 5),
			Rotation = angle,
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Parent = wheel,
		})
		bar:SetAttribute("FixedBackground", true)
		Ui.new("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHSV(((angle + 180) % 360) / 360, 1, 1)),
				ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(1, Color3.fromHSV(angle / 360, 1, 1)),
			}),
			Parent = bar,
		})
	end
	local shade = Ui.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Parent = wheel })
	shade:SetAttribute("FixedBackground", true)
	local marker = Ui.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1, Parent = holder })
	Ui.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = marker })
	local ring = Ui.new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2, Parent = marker })
	ring:SetAttribute("FixedBackground", true)

	local h, s, v = 0, 0, 1
	local api = { wheel = wheel }
	local function render()
		local a = h * 2 * math.pi
		marker.Position = UDim2.fromOffset(size / 2 + math.cos(a) * s * size / 2, size / 2 + math.sin(a) * s * size / 2)
		shade.BackgroundTransparency = v
	end
	function api.get()
		return Color3.fromHSV(h, s, v)
	end
	function api.set(c)
		h, s, v = c:ToHSV()
		render()
	end
	function api.setValue(value)
		v = value
		render()
	end
	local function pick(x, y)
		local pos, sz = wheel.AbsolutePosition, wheel.AbsoluteSize
		local r = sz.X / 2
		if r <= 0 then
			return
		end
		local dx, dy = x - (pos.X + r), y - (pos.Y + r)
		h = (math.deg(math.atan2(dy, dx)) % 360) / 360
		s = math.min(math.sqrt(dx * dx + dy * dy) / r, 1)
		render()
		if onPick then
			onPick(api.get())
		end
	end
	local dragging = false
	scope:connect(wheel.InputBegan, function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
			dragging = true
			pick(input.Position.X, input.Position.Y)
		end
	end)
	scope:connect(UserInputService.InputChanged, function(input)
		local t = input.UserInputType
		if dragging and (t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch) then
			pick(input.Position.X, input.Position.Y)
		end
	end)
	scope:connect(UserInputService.InputEnded, function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	render()
	return api
end

-- Horizontal slider with − / + step buttons (usable without dragging). Returns { set(v, silent), get() }.
-- opts: min, max, step, value, format(v) -> string, order
function Ui.slider(scope, parent, label, opts, onChange)
	local lo, hi, step = opts.min, opts.max, opts.step
	local row = Ui.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 48), LayoutOrder = opts.order or 0, Parent = parent })
	Ui.text(row, label, { size = UDim2.new(1, -70, 0, 18), font = Theme.fontMedium })
	local valueText = Ui.text(row, "", { size = UDim2.new(0, 70, 0, 18), align = Enum.TextXAlignment.Right, font = Theme.mono, textSize = Theme.size.small })
	valueText.Position = UDim2.new(1, -70, 0, 0)
	local function stepButton(text, pos)
		local b = Ui.new("TextButton", {
			AutoButtonColor = true,
			BackgroundColor3 = Theme.raised,
			Position = pos,
			Size = UDim2.fromOffset(26, 22),
			Text = text,
			TextColor3 = Theme.text,
			TextSize = 16,
			Font = Theme.fontBold,
			Parent = row,
		})
		Ui.corner(b)
		return b
	end
	local minus = stepButton("−", UDim2.fromOffset(0, 24))
	local plus = stepButton("+", UDim2.new(1, -26, 0, 24))
	local track = Ui.new("Frame", { BackgroundColor3 = Theme.raised, Position = UDim2.new(0, 36, 0, 32), Size = UDim2.new(1, -72, 0, 6), Active = true, Parent = row })
	Ui.corner(track, 3)
	local fill = Ui.new("Frame", { BackgroundColor3 = Theme.accent, Size = UDim2.fromScale(0, 1), Parent = track })
	Ui.corner(fill, 3)
	local knob = Ui.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Theme.text, Parent = track })
	Ui.corner(knob, 7)

	local value
	local api = {}
	function api.set(v, silent)
		v = math.clamp(lo + math.floor((v - lo) / step + 0.5) * step, lo, hi)
		if v == value then
			return
		end
		value = v
		local frac = (v - lo) / (hi - lo)
		fill.Size = UDim2.fromScale(frac, 1)
		knob.Position = UDim2.fromScale(frac, 0.5)
		valueText.Text = opts.format and opts.format(v) or tostring(v)
		if not silent and onChange then
			onChange(v)
		end
	end
	function api.get()
		return value
	end
	local function fromX(x)
		local width = track.AbsoluteSize.X
		if width > 0 then
			api.set(lo + (x - track.AbsolutePosition.X) / width * (hi - lo))
		end
	end
	local dragging = false
	scope:connect(track.InputBegan, function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
			dragging = true
			fromX(input.Position.X)
		end
	end)
	scope:connect(UserInputService.InputChanged, function(input)
		local t = input.UserInputType
		if dragging and (t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch) then
			fromX(input.Position.X)
		end
	end)
	scope:connect(UserInputService.InputEnded, function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	scope:connect(minus.Activated, function()
		api.set(value - step)
	end)
	scope:connect(plus.Activated, function()
		api.set(value + step)
	end)
	api.set(opts.value, true)
	return api
end

return Ui
