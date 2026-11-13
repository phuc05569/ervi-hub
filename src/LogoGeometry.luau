-- Source geometry for the three-segment Ervi mark.
local Geometry = {
	width = 130,
	height = 138,
	rows = 276,
	polygons = {
		{{ 73, 0 }, { 94, 12 }, { 10, 61 }, { 10, 36 }},
		{{ 71, 57 }, { 71, 81 }, { 20, 111 }, { 0, 99 }},
		{{ 130, 78 }, { 130, 102 }, { 65, 138 }, { 45, 126 }},
	},
}

Geometry.aspectRatio = Geometry.width / Geometry.height

function Geometry.heightForWidth(width)
	return width / Geometry.aspectRatio
end

function Geometry.rowsForWidth(width)
	return math.clamp(math.ceil(math.max(0, width) / Geometry.aspectRatio * 2), 32, Geometry.rows)
end

function Geometry.featherSpan(left, right, displayWidth)
	local edge = Geometry.width * 0.65 / math.max(1, displayWidth)
	return left - edge, right + edge, edge / (right - left + 2 * edge)
end

function Geometry.spanAt(polygon, y)
	local intersections = {}
	for i, a in ipairs(polygon) do
		local b = polygon[i % #polygon + 1]
		if (a[2] <= y and b[2] > y) or (b[2] <= y and a[2] > y) then
			intersections[#intersections + 1] = a[1] + (y - a[2]) * (b[1] - a[1]) / (b[2] - a[2])
		end
	end
	table.sort(intersections)
	if #intersections < 2 then
		return nil
	end
	return intersections[1], intersections[#intersections]
end

return Geometry
