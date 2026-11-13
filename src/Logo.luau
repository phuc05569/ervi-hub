-- Native scanline rendering keeps the official mark usable without a hosted image asset.
local Geometry = require("LogoGeometry")
local Logo = { POLYGONS = Geometry.polygons }
local roots = setmetatable({}, { __mode = "k" })
local tint = Color3.new(1, 1, 1)

function Logo.refresh(background)
	local _, _, value = background:ToHSV()
	tint = value > 0.65 and Color3.fromRGB(21, 19, 24) or Color3.new(1, 1, 1)
	for root, strips in pairs(roots) do
		if root.Parent then
			for _, strip in ipairs(strips) do
				strip.BackgroundColor3 = tint
			end
		end
	end
end

function Logo.create(parent, size)
	local requested = size or UDim2.fromOffset(26, Geometry.heightForWidth(26))
	local root = Instance.new("Frame")
	root.Name = "ErviOfficialLogo"
	root.BackgroundTransparency = 1
	root.Size = UDim2.new(
		requested.X.Scale,
		requested.X.Offset,
		requested.X.Scale / Geometry.aspectRatio,
		requested.X.Offset / Geometry.aspectRatio
	)
	-- Offset dimensions are quantized by Roblox. Keep the rendered ratio exact,
	-- with width explicitly authoritative rather than the parent's height.
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = Geometry.aspectRatio
	aspect.DominantAxis = Enum.DominantAxis.Width
	aspect.AspectType = Enum.AspectType.ScaleWithParentSize
	aspect.Parent = root
	root.Parent = parent

	local strips = {}
	local displayWidth = math.max(1, requested.X.Offset)
	local rows = Geometry.rowsForWidth(displayWidth)
	for _, polygon in ipairs(Geometry.polygons) do
		for row = 0, rows - 1 do
			local y = (row + 0.5) * Geometry.height / rows
			local left, right = Geometry.spanAt(polygon, y)
			if left and right then
				local a, b, edge = Geometry.featherSpan(left, right, displayWidth)
				local strip = Instance.new("Frame")
				strip.BorderSizePixel = 0
				strip.BackgroundColor3 = tint
				strip:SetAttribute("FixedBackground", true)
				strip.Position = UDim2.fromScale(a / Geometry.width, row / rows)
				strip.Size = UDim2.fromScale((b - a) / Geometry.width, 1 / rows + 0.0001)
				local coverage = Instance.new("UIGradient")
				coverage.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(edge, 0),
					NumberSequenceKeypoint.new(1 - edge, 0),
					NumberSequenceKeypoint.new(1, 1),
				})
				coverage.Parent = strip
				strip.Parent = root
				strips[#strips + 1] = strip
			end
		end
	end
	roots[root] = strips
	return root
end

return Logo
