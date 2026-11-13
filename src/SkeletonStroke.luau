-- Presentation only: how a skeleton thickness preference is drawn with GUI Frames.
-- Studio check (2026-11-14): Frames thinner than 1 px are not drawn at all and fractional widths
-- above 1 px snap to whole pixels. Sub-pixel values therefore keep a 1 px line and convey the
-- thinner weight with coverage (opacity); 1 px and up round to whole pixels.
local SkeletonStroke = { MIN = 0.1, MAX = 3 }

-- -> coreWidth, coreTransparency, outlineWidth, outlineTransparency
function SkeletonStroke.resolve(thickness)
	local t = tonumber(thickness)
	if not t or t ~= t then
		t = 1
	end
	t = math.clamp(t, SkeletonStroke.MIN, SkeletonStroke.MAX)
	if t < 1 then
		-- The black outline fades with the core so it never outweighs a faint line.
		return 1, 1 - t, 3, 1 - t * 0.8
	end
	local width = math.floor(t + 0.5)
	return width, 0, width + 2, 0
end

function SkeletonStroke.describe(thickness)
	local t = math.clamp(tonumber(thickness) or 1, SkeletonStroke.MIN, SkeletonStroke.MAX)
	if t < 1 then
		return ("%.1f px"):format(t)
	end
	local width = math.floor(t + 0.5)
	return math.abs(t - width) < 0.05 and ("%.1f px"):format(t) or ("%.1f px · draws %d"):format(t, width)
end

return SkeletonStroke
