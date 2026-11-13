-- Prefers the antialiased PNG rendered from LogoGeometry (UiImages); native scanlines are the
-- fallback when the executor cannot provide a local image asset.
local Geometry = require("LogoGeometry")
local UiImages = require("UiImages")
local Logo = { POLYGONS = Geometry.polygons }
local roots = setmetatable({}, { __mode = "k" })
local images = setmetatable({}, { __mode = "k" })
local tint = Color3.new(1, 1, 1)

function Logo.refresh(background)
	local _, _, value = background:ToHSV()
	tint = value > 0.65 and Color3.fromRGB(21, 19, 24) or Color3.new(1, 1, 1)
	for image in pairs(images) do
		image.ImageColor3 = tint
	end
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

	local imageId = UiImages.logo()
	if imageId then
		local image = Instance.new("ImageLabel")
		image.Name = "LogoImage"
		image.BackgroundTransparency = 1
		image.Size = UDim2.fromScale(1, 1)
		image.Image = imageId
		image.ImageColor3 = tint
		image.ScaleType = Enum.ScaleType.Fit
		image:SetAttribute("FixedBackground", true)
		image.Parent = root
		images[image] = true
		return root
	end

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
