-- Test runner: executes every *.spec module bundled by `python build.py --test`.
local specs = { "SliderValue.spec", "Motion.spec", "AutoRoll.spec", "Rarity.spec", "Scope.spec", "Settings.spec", "M1State.spec", "Loader.spec", "WindowGeometry.spec", "SafeZoneState.spec", "TargetState.spec", "PositionHold.spec", "Expansion.spec" }
local passed, failed = 0, 0

local function check(cond, msg)
	if not cond then
		error(msg or "check failed", 2)
	end
end

local function eq(a, b, msg)
	if a ~= b then
		error(("%s: expected %s, got %s"):format(msg or "eq", tostring(b), tostring(a)), 2)
	end
end

for _, name in ipairs(specs) do
	local cases = require(name)
	for _, case in ipairs(cases) do
		local ok, err = pcall(case[2], check, eq)
		if ok then
			passed += 1
			print("  PASS  " .. name .. " :: " .. case[1])
		else
			failed += 1
			print("  FAIL  " .. name .. " :: " .. case[1] .. "\n        " .. tostring(err))
		end
	end
end

print(("%d passed, %d failed"):format(passed, failed))
if failed > 0 then
	error("tests failed")
end
