local Geometry = require("LogoGeometry")

return {
	{"logo sampling follows its display width within bounded limits", function(check, eq)
		eq(Geometry.rowsForWidth(18), 39)
		eq(Geometry.rowsForWidth(24), 51)
		eq(Geometry.rowsForWidth(0), 32)
		eq(Geometry.rowsForWidth(10000), Geometry.rows)
		check(Geometry.rowsForWidth(48) > Geometry.rowsForWidth(24))
	end},
	{"logo edge coverage preserves the polygon and orders alpha stops", function(check)
		for _, width in ipairs({18, 24, 48, 96}) do
			for _, span in ipairs({0.01, 1, 40}) do
				local left, right, fraction = Geometry.featherSpan(10, 10 + span, width)
				check(left < 10 and right > 10 + span)
				check(fraction > 0 and fraction < 0.5)
				check(math.abs((10 - left) * width / Geometry.width - 0.65) < 1e-8)
			end
		end
	end},
	{"logo keeps the official three-segment viewbox", function(check, eq)
		eq(#Geometry.polygons, 3)
		eq(Geometry.width, 130)
		eq(Geometry.height, 138)
		eq(Geometry.rows, 276)
		check(math.abs(Geometry.aspectRatio - 130 / 138) < 1e-9)
	end},
	{"logo source vertices remain inside the normalized viewbox", function(check)
		for _, polygon in ipairs(Geometry.polygons) do
			check(#polygon >= 3)
			for _, point in ipairs(polygon) do
				check(point[1] >= 0 and point[1] <= Geometry.width)
				check(point[2] >= 0 and point[2] <= Geometry.height)
			end
		end
	end},
	{"logo scan conversion returns ordered positive spans at each segment", function(check)
		local spans = 0
		for _, polygon in ipairs(Geometry.polygons) do
			for row = 0, Geometry.rows - 1 do
				local y = (row + 0.5) * Geometry.height / Geometry.rows
				local left, right = Geometry.spanAt(polygon, y)
				if left then
					spans += 1
					check(left >= 0 and right <= Geometry.width and left < right)
				end
			end
		end
		check(spans > 150, "all three segments should cover enough scanlines")
	end},
	{"logo requested height derives from exact official aspect ratio", function(check)
		for _, width in ipairs({18, 24, 48, 96}) do
			check(math.abs(width / Geometry.heightForWidth(width) - Geometry.aspectRatio) < 1e-9)
		end
	end},
}
