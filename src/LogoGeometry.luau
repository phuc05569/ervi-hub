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
