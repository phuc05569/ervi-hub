-- Pure read-only interpretation of a candidate server-time AttackReadyAt deadline.
-- A matching Tool is required. A style/character change invalidates prior samples.
local M1State = {}
M1State.__index = M1State

local function finite(n)
	return type(n) == "number" and n == n and math.abs(n) < math.huge
end

function M1State.new()
	return setmetatable({}, M1State)
end

function M1State:reset(style)
	self.style = style
	self.deadline = nil
 self.duration = nil
	self.reason = "Waiting for a fresh AttackReadyAt sample"
end

function M1State:observe(value, now)
	self.deadline = nil
 self.duration = nil
	if not self.style or not finite(value) or value <= 0 or not finite(now) then
		self.reason = "AttackReadyAt missing or invalid"
	elseif math.abs(value - now) > 120 then
		self.reason = "AttackReadyAt clock unverified (outside 120 s window)"
	else
		self.deadline = value
  self.duration=math.max(0,value-now)
		self.reason = "Observed AttackReadyAt; server-time interpretation UNVERIFIED"
	end
end

function M1State:snapshot(now, equipped, alive)
	local state = { style = self.style, status = "UNKNOWN", evidence = self.reason }
	if not equipped then
		state.status, state.evidence = "UNEQUIPPED", "Equip the matching fighting-style Tool"
	elseif not alive then
		state.status, state.evidence = "UNAVAILABLE", "Waiting for a living character"
	elseif self.deadline and finite(now) then
		state.remaining = math.max(0, self.deadline - now)
		state.status = state.remaining > 0 and "COOLDOWN" or "READY"
  state.fraction=state.status=="READY" and 1 or math.clamp(state.remaining/math.max(0.001,self.duration or 0),0,1)
	end
	return state
end

return M1State
