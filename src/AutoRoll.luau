-- AutoRoll: cancellable "roll until target" state machine. Pure logic; all game access goes through `adapter`.
--
-- Adapter contract (see RollAdapter.luau for the live game implementation):
--   now() -> seconds            wait(dt)                spawn(fn)
--   canRoll() -> ok, reason, recoverable (known temporary game gates may wait indefinitely)
--   readyAt() -> any             (RollReadyAt attribute; used to confirm the server started a new cooldown)
--   currentStyle() -> {name, chance} | nil
--   requestRoll() -> handle       handle.done / handle.name / handle.chance / handle.err filled asynchronously
--   chanceOf(name) -> number|nil  tierOf(name, chance) -> string
--
-- Invariants (covered by tests/AutoRoll.spec.luau):
--   * at most one roll request in flight, never retried automatically;
--   * a qualifying result (current, normal, late, or after Stop) ends the run with zero further requests;
--   * timeouts, empty results and unconfirmed cooldowns pause instead of rolling again.
local Rarity = require("Rarity")

local AutoRoll = {}
AutoRoll.__index = AutoRoll

local RUNNING = { Checking = true, WaitingReady = true, WaitingRespawn = true, Requesting = true, Confirming = true }

AutoRoll.DEFAULTS = {
	maxRolls = math.huge,
	requestTimeout = 12,
	readyTimeout = 180,
	acceptTimeout = 3,
	lateWatch = 60,
	pauseOnRare = false,
	rareAbove = Rarity.GAME_CONFIRM_ABOVE,
	requireCooldownAdvance = true,
	poll = 0.1,
	resumeAfterDeath = false,
}

local function styleLabel(name, chance)
	return ("%s (1/%s)"):format(tostring(name), chance and tostring(chance) or "?")
end

function AutoRoll.new(adapter, opts)
	local self = setmetatable({}, AutoRoll)
	self.a = adapter
	self.opts = {}
	for k, v in pairs(AutoRoll.DEFAULTS) do
		self.opts[k] = v
	end
	for k, v in pairs(opts or {}) do
		self.opts[k] = v
	end
	self.state, self.reason = "Idle", "Not started"
	self.gen = 0
	self.pending = nil
	self.history = {}
	self.listeners = {}
	self:resetStats()
	return self
end

function AutoRoll:resetStats()
	self.stats = { attempted = 0, confirmed = 0, startedAt = nil }
	self.last = nil
end

function AutoRoll:onChange(fn)
	table.insert(self.listeners, fn)
end

function AutoRoll:isRunning()
	return RUNNING[self.state] == true
end

function AutoRoll:_set(state, reason)
	if self.state == state and self.reason == reason then
		return
	end
	self.state, self.reason = state, reason or ""
	for _, fn in ipairs(self.listeners) do
		local ok, err = pcall(fn, self)
		if not ok then
			(warn or print)("[Ervi Hub] AutoRoll listener error: " .. tostring(err))
		end
	end
end

-- opts.acceptRare: user confirmed rolling away a rare current style. opts.keepStats: Continue after a pause.
function AutoRoll:start(target, opts)
	opts = opts or {}
	if self:isRunning() then
		return false, "Already running"
	end
	if self.pending and not self.pending.done then
		return false, "The previous roll has not answered yet; waiting for it first"
	end
	if not Rarity.validTarget(target) then
		return false, "Pick a valid target first"
	end
	self.gen += 1
	local gen = self.gen
	self.target = target
	if not opts.keepStats then
		self:resetStats()
	end
	self.stats.startedAt = self.stats.startedAt or self.a.now()
	self.a.spawn(function()
		self:_run(gen, opts.acceptRare == true)
	end)
	return true
end

function AutoRoll:stop(reason)
	if not self:isRunning() then
		return false
	end
	self.gen += 1
	self:_set("Idle", reason or "Stopped by user")
	return true
end

-- Hub closing: stop, drop UI listeners, and make any late-result watcher a no-op.
function AutoRoll:dispose()
	self:stop("Hub closed")
	self.disposed = true
	self.gen += 1
	self.listeners = {}
end

function AutoRoll:_live(gen)
	return self.gen == gen
end

function AutoRoll:_end(gen, state, reason)
	if self.gen == gen then
		self.gen += 1
		self:_set(state, reason)
	end
end

function AutoRoll:_found(text)
	self.gen += 1 -- kills any loop still running
	self:_set("Found", text)
end

-- Records a finished handle. Returns "found" | "ok" | "bad", message.
function AutoRoll:_evaluate(handle)
	if handle.err then
		return "bad", "Roll request failed: " .. tostring(handle.err)
	end
	local name, chance = handle.name, handle.chance
	if type(name) ~= "string" then
		return "bad", "Server returned no result (the game shows TRY AGAIN). Paused."
	end
	if type(chance) ~= "number" then
		chance = self.a.chanceOf(name)
	end
	self.stats.confirmed += 1
	self.last = {
		name = name,
		chance = chance,
		tier = self.a.tierOf(name, chance),
		at = self.a.now(),
		n = self.stats.attempted,
	}
	table.insert(self.history, 1, self.last)
	if #self.history > 50 then
		table.remove(self.history)
	end
	if Rarity.qualifies(self.target, name, chance) then
		return "found", ("Got %s on roll #%d - target met. Stopped; no further rolls."):format(
			styleLabel(name, chance),
			self.stats.attempted
		)
	end
	return "ok", nil
end

function AutoRoll:_watchLate(handle)
	local a = self.a
	a.spawn(function()
		local t0 = a.now()
		while not handle.done and a.now() - t0 < self.opts.lateWatch do
			a.wait(0.25)
		end
		if not handle.done or self.disposed then
			return
		end
		local verdict, text = self:_evaluate(handle)
		if verdict == "found" then
			self:_found(text .. " (late server response)")
		elseif verdict == "ok" and not self:isRunning() then
			self:_set(self.state, self.reason .. " | Late result: " .. styleLabel(self.last.name, self.last.chance))
		end
	end)
end

function AutoRoll:_run(gen, acceptRare)
	local a, o = self.a, self.opts

	self:_set("Checking", "Checking your current style")
	local cur = a.currentStyle()
	if cur and Rarity.qualifies(self.target, cur.name, cur.chance) then
		return self:_end(gen, "Found", ("Your current %s already meets the target. No roll sent."):format(styleLabel(cur.name, cur.chance)))
	end
	if cur and o.pauseOnRare and not acceptRare and type(cur.chance) == "number" and cur.chance > o.rareAbove then
		return self:_end(
			gen,
			"Paused",
			("Your current %s is rarer than 1/%d. Press Continue to roll it away."):format(styleLabel(cur.name, cur.chance), o.rareAbove)
		)
	end

	while self:_live(gen) do
		if self.stats.attempted >= o.maxRolls then
			return self:_end(gen, "Paused", ("Roll cap reached (%d). Raise it in options to continue."):format(o.maxRolls))
		end

		-- 1. Wait for the same preconditions the game's own roll button checks.
		local since = a.now()
		self:_set("WaitingReady", "Waiting for roll readiness")
		while true do
			if not self:_live(gen) then
				return
			end
			local ok, why, recoverable = a.canRoll()
			if ok then
				break
			end
			local dead = a.alive and not a.alive()
			if dead and not o.resumeAfterDeath then
				return self:_end(gen, "Paused", "Character died; enable Resume Auto Roll After Death to wait for respawn")
			end
			if dead then
				since = a.now() -- death does not consume the live-readiness timeout
				self:_set("WaitingRespawn", "Waiting for respawn; selected target retained")
			elseif recoverable then
				since = a.now() -- known temporary gates retain this run, without sending requests
			elseif a.now() - since >= o.readyTimeout then
				return self:_end(gen, "Paused", ("Not ready for %ds: %s"):format(o.readyTimeout, tostring(why)))
			end
			if not dead then self:_set("WaitingReady", "Waiting — rolling unavailable · " .. tostring(why or "Waiting")) end
			a.wait(o.poll)
		end

		-- Recheck replicated equipment after a long readiness/respawn wait.
		local current = a.currentStyle()
		if current and Rarity.qualifies(self.target, current.name, current.chance) then
			return self:_end(gen, "Found", "Current style meets the target after waiting; no roll sent")
		end
		if current and o.pauseOnRare and not acceptRare and type(current.chance) == "number" and current.chance > o.rareAbove then
			return self:_end(gen, "Paused", "Current style changed to a rare style; Continue required")
		end
		acceptRare = false

		-- 2. Exactly one request, awaited with a timeout and never retried.
		local readyBefore = a.readyAt()
		self:_set("Requesting", ("Preparing roll #%d"):format(self.stats.attempted + 1))
		if not self:_live(gen) then return end -- a listener may have requested Stop
		local handle = a.requestRoll()
		if handle.notSent then
			if not self:_live(gen) then return end
			if not handle.recoverable then return self:_end(gen, "Paused", handle.reason or "Roll unavailable") end
			self:_set("WaitingReady", "Waiting — rolling unavailable · " .. tostring(handle.reason))
			a.wait(o.poll)
			continue -- preflight refused locally; no request exists to retry
		end
		self.stats.attempted += 1
		self.pending = handle
		if self:_live(gen) then self:_set("Requesting", ("Roll #%d sent - waiting for the server result"):format(self.stats.attempted)) end
		local t0 = a.now()
		while not handle.done and a.now() - t0 < o.requestTimeout do
			a.wait(o.poll)
		end
		if not handle.done then
			self:_end(gen, "Paused", ("No server response after %ds. Not rolling again."):format(o.requestTimeout))
			return self:_watchLate(handle)
		end

		-- 3. Evaluate, even if Stop was pressed while waiting: a rare result must be reported.
		local verdict, text = self:_evaluate(handle)
		if verdict == "found" then
			return self:_found(text)
		elseif verdict == "bad" then
			return self:_end(gen, "Paused", text)
		end
		if not self:_live(gen) then
			return
		end

		-- 4. Confirm the server started a new cooldown before even considering another roll.
		if o.requireCooldownAdvance then
			self:_set("Confirming", "Confirming the server started the next cooldown")
			local t1 = a.now()
			while a.readyAt() == readyBefore and a.now() - t1 < o.acceptTimeout do
				if not self:_live(gen) then
					return
				end
				a.wait(o.poll)
			end
			if a.readyAt() == readyBefore then
				return self:_end(gen, "Paused", "Got a result but the roll cooldown did not restart (uncertain). Paused.")
			end
		end
		if not self:_live(gen) then
			return
		end

		local last = self.last
		if o.pauseOnRare and type(last.chance) == "number" and last.chance > o.rareAbove then
			return self:_end(
				gen,
				"Paused",
				("Got %s: rarer than 1/%d but below target. Kept it - press Continue to roll it away."):format(
					styleLabel(last.name, last.chance),
					o.rareAbove
				)
			)
		end
	end
end

return AutoRoll
