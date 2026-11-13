-- Mock-game tests for AutoRoll. A virtual clock drives waits; any roll request beyond the
-- scripted results raises "unexpected extra roll request", so "zero further rolls" is enforced.
local AutoRoll = require("AutoRoll")
local Rarity = require("Rarity")

local CHANCES = { Punch = 3, Slap = 5, Laser = 8, Cyborg = 195, Jackpot = 444, ["Knockback Stick"] = 750 }

local function fakeGame(script)
	local f = { t = 0, requests = 0, requestTimes = {}, readyAtV = 0, current = script.current, timers = {} }
	local adapter = {}
	function adapter.now()
		return f.t
	end
	function adapter.wait(dt)
		f.t += dt
		for i = #f.timers, 1, -1 do
			if f.timers[i].at <= f.t then
				table.remove(f.timers, i).fn()
			end
		end
		if f.t > 100000 then
			error("runaway loop")
		end
	end
	function adapter.spawn(fn)
		fn()
	end
	function adapter.canRoll()
		if script.deadUntil and f.t<script.deadUntil then return false,"Dead" end
		if script.canRoll then
			return script.canRoll(f)
		end
		if f.t + 0.05 < f.readyAtV then
			return false, "cooldown"
		end
		return true
	end
	function adapter.alive() return not script.deadUntil or f.t>=script.deadUntil end
	function adapter.readyAt()
		return f.readyAtV
	end
	function adapter.currentStyle()
		return f.current
	end
	function adapter.chanceOf(name)
		return CHANCES[name]
	end
	function adapter.tierOf(_, chance)
		return Rarity.tierName(chance)
	end
	function adapter.requestRoll()
		f.requests += 1
		f.requestTimes[f.requests] = f.t
		local r = script.results[f.requests]
		if r == nil then
			error("unexpected extra roll request #" .. f.requests)
		end
		local h = { done = false }
		local function resolve()
			h.done, h.name, h.err = true, r.name, r.err
			h.chance = r.chance or (r.name and CHANCES[r.name])
			if r.name and not r.noAdvance then
				f.readyAtV = f.t + 8
				f.current = { name = r.name, chance = h.chance }
			end
		end
		if script.onRequest then
			script.onRequest(f, f.requests)
		end
		if r.never then
			return h
		elseif r.delay then
			table.insert(f.timers, { at = f.t + r.delay, fn = resolve })
		else
			resolve()
		end
		return h
	end
	return f, adapter
end

local function names(list)
	local out = {}
	for _, n in ipairs(list) do
		table.insert(out, { name = n })
	end
	return out
end

local T500 = { mode = "chance", min = 500 }

return {
    { "default run can exceed old 250-roll cap",function(_,eq)
        local result={};for _=1,251 do table.insert(result,{name="Punch"}) end;table.insert(result,{name="Knockback Stick"})
        local f,a=fakeGame({current={name="Punch",chance=3},results=result})
        local m=AutoRoll.new(a);m:start(T500);eq(f.requests,252);eq(m.state,"Found")
    end },
    { "default run has no optional rare pause or roll cap",function(_,eq)
      local f,a=fakeGame({current={name="Cyborg",chance=195},results=names({"Cyborg","Knockback Stick"})})
      local m=AutoRoll.new(a);m:start(T500);eq(f.requests,2);eq(m.state,"Found");eq(m.opts.maxRolls,math.huge)
    end },
    { "death during a nonqualifying in-flight roll resumes only after normal cooldown", function(check,eq)
        local script={current={name="Punch",chance=3},results={{name="Slap",delay=0.2},{name="Knockback Stick"}}}
        script.onRequest=function(f,n) if n==1 then script.deadUntil=f.t+3 end end
        local f,a=fakeGame(script); local m=AutoRoll.new(a,{resumeAfterDeath=true})
        m:start(T500); eq(m.state,"Found"); eq(f.requests,2); check(f.requestTimes[2]>=8)
    end },
    { "qualifying in-flight result while dead stays terminal", function(_,eq)
        local script={current={name="Punch",chance=3},results={{name="Knockback Stick",delay=1}}}
        script.onRequest=function(f) script.deadUntil=f.t+20 end
        local f,a=fakeGame(script); local m=AutoRoll.new(a,{resumeAfterDeath=true}); m:start(T500)
        eq(m.state,"Found"); eq(f.requests,1)
    end },
    { "respawn preference cannot retry an uncertain in-flight request", function(_,eq)
        local script={current={name="Punch",chance=3},results={{never=true}}}
        script.onRequest=function(f) script.deadUntil=f.t+3 end
        local f,a=fakeGame(script); local m=AutoRoll.new(a,{resumeAfterDeath=true,requestTimeout=1,lateWatch=2}); m:start(T500)
        eq(m.state,"Paused"); eq(f.requests,1)
    end },
    { "resume preference waits through long death without a second worker", function(check,eq)
        local f,a=fakeGame({deadUntil=10,current={name="Punch",chance=3},results=names({"Knockback Stick"})})
        local m=AutoRoll.new(a,{resumeAfterDeath=true,readyTimeout=1})
        local original=a.wait
        local checked=false
        a.wait=function(dt)
            if not checked then checked=true; check(not m:start(T500),"duplicate start rejected during respawn") end
            original(dt)
        end
        m:start(T500); eq(f.requests,1); check(f.requestTimes[1]>=10); eq(m.state,"Found")
    end },
    { "disabled recovery pauses before requesting while dead", function(_,eq)
        local f,a=fakeGame({deadUntil=10,current={name="Punch",chance=3},results={}})
        local m=AutoRoll.new(a); m:start(T500); eq(m.state,"Paused"); eq(f.requests,0)
    end },
    { "Stop during respawn wait never resumes", function(_,eq)
        local f,a=fakeGame({deadUntil=10,current={name="Punch",chance=3},results={}})
        local m=AutoRoll.new(a,{resumeAfterDeath=true}); local wait=a.wait
        a.wait=function(dt) m:stop(); wait(dt) end
        m:start(T500); eq(m.state,"Idle"); eq(f.requests,0)
    end },
    { "qualifying style acquired during respawn is never rolled away", function(_,eq)
        local f,a=fakeGame({deadUntil=1,current={name="Punch",chance=3},results={}})
        local wait=a.wait
        a.wait=function(dt) wait(dt); if f.t>=1 then f.current={name="Knockback Stick",chance=750} end end
        local m=AutoRoll.new(a,{resumeAfterDeath=true}); m:start(T500); eq(f.requests,0); eq(m.state,"Found")
    end },
    { "rare replacement after waiting requires Continue", function(_,eq)
        local f,a=fakeGame({deadUntil=1,current={name="Punch",chance=3},results={}})
        local wait=a.wait
        a.wait=function(dt) wait(dt); if f.t>=1 then f.current={name="Cyborg",chance=195} end end
        local m=AutoRoll.new(a,{resumeAfterDeath=true,pauseOnRare=true}); m:start(T500); eq(f.requests,0); eq(m.state,"Paused")
    end },
	{ "stops on first qualifying result with zero further requests", function(check, eq)
		local f, a = fakeGame({ current = { name = "Punch", chance = 3 }, results = names({ "Punch", "Slap", "Knockback Stick" }) })
		local m = AutoRoll.new(a)
		check(m:start(T500))
		eq(m.state, "Found", "state")
		eq(f.requests, 3, "requests")
		eq(m.last.name, "Knockback Stick", "last")
		check(not m:isRunning())
	end },
	{ "never rolls away a current style that already qualifies", function(_, eq)
		local f, a = fakeGame({ current = { name = "Knockback Stick", chance = 750 }, results = {} })
		local m = AutoRoll.new(a)
		m:start(T500)
		eq(m.state, "Found", "state")
		eq(f.requests, 0, "requests")
	end },
	{ "repeated same-style results are each counted", function(_, eq)
		local f, a = fakeGame({ current = { name = "Slap", chance = 5 }, results = names({ "Punch", "Punch", "Punch", "Knockback Stick" }) })
		local m = AutoRoll.new(a)
		m:start(T500)
		eq(m.stats.confirmed, 4, "confirmed")
		eq(f.requests, 4, "requests")
		eq(#m.history, 4, "history")
	end },
	{ "respects cooldown: no request before readyAt", function(check)
		local f, a = fakeGame({ current = { name = "Punch", chance = 3 }, results = names({ "Punch", "Slap", "Knockback Stick" }) })
		AutoRoll.new(a):start(T500)
		check(f.requestTimes[2] >= f.requestTimes[1] + 8 - 0.05, "2nd waited for cooldown")
		check(f.requestTimes[3] >= f.requestTimes[2] + 8 - 0.05, "3rd waited for cooldown")
	end },
	{ "Stop during a request: non-qualifying result, no further rolls", function(_, eq)
		local m
		local f, a = fakeGame({
			current = { name = "Punch", chance = 3 },
			results = { { name = "Slap", delay = 1 } },
			onRequest = function() m:stop() end,
		})
		m = AutoRoll.new(a)
		m:start(T500)
		eq(m.state, "Idle", "state")
		eq(f.requests, 1, "requests")
		eq(m.last.name, "Slap", "result still recorded")
	end },
	{ "Stop during a request that turns out qualifying still reports Found", function(_, eq)
		local m
		local f, a = fakeGame({
			current = { name = "Punch", chance = 3 },
			results = { { name = "Knockback Stick", delay = 1 } },
			onRequest = function() m:stop() end,
		})
		m = AutoRoll.new(a)
		m:start(T500)
		eq(m.state, "Found", "state")
		eq(f.requests, 1, "requests")
	end },
	{ "timeout pauses; restart refused while pending; late qualifying result -> Found", function(check, eq)
		local f, a = fakeGame({ current = { name = "Punch", chance = 3 }, results = { { name = "Knockback Stick", delay = 20 } } })
		local m = AutoRoll.new(a)
		-- run the late watcher on our own schedule so we can try a restart mid-wait
		local deferred
		local realSpawn = a.spawn
		a.spawn = function(fn)
			if m.state == "Paused" then
				deferred = fn
			else
				realSpawn(fn)
			end
		end
		m:start(T500)
		eq(m.state, "Paused", "paused on timeout")
		local ok = m:start(T500)
		check(not ok, "restart refused while previous request pending")
		deferred()
		eq(m.state, "Found", "late result found")
		eq(f.requests, 1, "requests")
	end },
	{ "empty server result pauses without retry", function(_, eq)
		local f, a = fakeGame({ current = { name = "Punch", chance = 3 }, results = { { name = nil } } })
		local m = AutoRoll.new(a)
		m:start(T500)
		eq(m.state, "Paused", "state")
		eq(f.requests, 1, "requests")
	end },
	{ "request error pauses without retry", function(_, eq)
		local f, a = fakeGame({ current = { name = "Punch", chance = 3 }, results = { { err = "remote missing" } } })
		local m = AutoRoll.new(a)
		m:start(T500)
		eq(m.state, "Paused", "state")
		eq(f.requests, 1, "requests")
	end },
	{ "cooldown that never restarts is treated as uncertain", function(_, eq)
		local f, a = fakeGame({ current = { name = "Punch", chance = 3 }, results = { { name = "Slap", noAdvance = true } } })
		local m = AutoRoll.new(a)
		m:start(T500)
		eq(m.state, "Paused", "state")
		eq(f.requests, 1, "requests")
	end },
	{ "rare current style needs explicit Continue", function(_, eq)
		local f, a = fakeGame({ current = { name = "Cyborg", chance = 195 }, results = names({ "Knockback Stick" }) })
		local m = AutoRoll.new(a,{pauseOnRare=true})
		m:start(T500)
		eq(m.state, "Paused", "paused first")
		eq(f.requests, 0, "no roll before Continue")
		m:start(T500, { acceptRare = true, keepStats = true })
		eq(m.state, "Found", "found after Continue")
		eq(f.requests, 1, "one roll")
	end },
	{ "rare-but-below-target result is kept (pause)", function(_, eq)
		local f, a = fakeGame({ current = { name = "Punch", chance = 3 }, results = names({ "Jackpot" }) })
		local m = AutoRoll.new(a,{pauseOnRare=true})
		m:start({ mode = "chance", min = 1000 })
		eq(m.state, "Paused", "state")
		eq(f.requests, 1, "requests")
	end },
	{ "roll cap pauses", function(_, eq)
		local f, a = fakeGame({ current = { name = "Punch", chance = 3 }, results = names({ "Punch", "Punch" }) })
		local m = AutoRoll.new(a, { maxRolls = 2 })
		m:start(T500)
		eq(m.state, "Paused", "state")
		eq(f.requests, 2, "requests")
	end },
	{ "not ready for too long pauses without a request", function(_, eq)
		local f, a = fakeGame({
			current = { name = "Punch", chance = 3 },
			results = {},
			canRoll = function() return false, "Not in the arena (jump down to roll)" end,
		})
		local m = AutoRoll.new(a, { readyTimeout = 5 })
		m:start(T500)
		eq(m.state, "Paused", "state")
		eq(f.requests, 0, "requests")
	end },
	{ "style target changes mid-session use the new mapping", function(_, eq)
		local f, a = fakeGame({ current = { name = "Punch", chance = 3 }, results = names({ "Slap", "Cyborg" }) })
		local m = AutoRoll.new(a, { pauseOnRare = false })
		m:start({ mode = "style", names = { Cyborg = true } })
		eq(m.state, "Found", "state")
		eq(f.requests, 2, "requests")
	end },
	{ "double start is rejected while running", function(check)
		local m
		local second
		local _, a = fakeGame({
			current = { name = "Punch", chance = 3 },
			results = { { name = "Knockback Stick", delay = 1 } },
			onRequest = function() second = table.pack(m:start(T500)) end,
		})
		m = AutoRoll.new(a)
		m:start(T500)
		check(second[1] == false, "second start refused")
	end },
	{ "listener errors do not break the machine", function(_, eq)
		local _, a = fakeGame({ current = { name = "Punch", chance = 3 }, results = names({ "Knockback Stick" }) })
		local m = AutoRoll.new(a)
		m:onChange(function() error("ui exploded") end)
		m:start(T500)
		eq(m.state, "Found", "state")
	end },
	{ "dispose silences a late result arriving after hub close", function(_, eq)
		local f, a = fakeGame({ current = { name = "Punch", chance = 3 }, results = { { name = "Knockback Stick", delay = 20 } } })
		local m = AutoRoll.new(a)
		local deferred
		local realSpawn = a.spawn
		a.spawn = function(fn)
			if m.state == "Paused" then deferred = fn else realSpawn(fn) end
		end
		m:start(T500)
		local calls = 0
		m:onChange(function() calls += 1 end)
		m:dispose()
		deferred()
		eq(calls, 0, "no listener calls after dispose")
		eq(f.requests, 1, "requests")
	end },
}
