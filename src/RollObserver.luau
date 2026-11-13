-- Roll Observer: passive, bounded capture of what happens during 2-3 MANUAL rolls.
-- Reads attributes and the game's own roll UI text only. Never invokes or hooks remotes.
-- Report excludes username, UserId and JobId.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Game = require("Game")
local Build = require("Build")

local MAX_EVENTS = 400
local RELEVANT = { "Roll", "Equipped", "Unlocked", "Luck", "FFA", "Confirm", "Boss", "Attack" }

local function relevant(name)
	for _, key in ipairs(RELEVANT) do
		if name:find(key, 1, true) then
			return true
		end
	end
	return false
end

local function short(v)
	local s = typeof(v) == "string" and v or tostring(v)
	if #s > 200 then
		s = s:sub(1, 200) .. ("...(%d chars)"):format(#s)
	end
	return s
end

local function capabilities()
	-- Presence check only; none of these are called except identifyexecutor.
	local probe = {
		{ "setclipboard", setclipboard },
		{ "toclipboard", toclipboard },
		{ "gethui", gethui },
		{ "identifyexecutor", identifyexecutor },
		{ "writefile", writefile },
		{ "firesignal", firesignal },
		{ "getconnections", getconnections },
		{ "hookmetamethod", hookmetamethod },
		{ "decompile", decompile },
	}
	local out = {}
	for _, p in ipairs(probe) do
		table.insert(out, ("%s=%s"):format(p[1], type(p[2]) == "function" and "yes" or "no"))
	end
	local exec = "unknown"
	if type(identifyexecutor) == "function" then
		local ok, a, b = pcall(identifyexecutor)
		if ok then
			exec = tostring(a) .. (b and (" " .. tostring(b)) or "")
		end
	end
	return exec, table.concat(out, " ")
end

return function(hubScope, log)
	local obs = { running = false, events = {}, dropped = 0, startedAt = nil, endsAt = nil, onUpdate = nil, header = "" }
	local cs

	local function push(kind, a, b)
		if #obs.events >= MAX_EVENTS then
			table.remove(obs.events, 1)
			obs.dropped += 1
		end
		table.insert(obs.events, ("+%7.3fs  %-8s %s%s"):format(os.clock() - obs.startedAt, kind, a, b and ("  " .. b) or ""))
		if obs.onUpdate then
			obs.onUpdate()
		end
	end

	local function snapshot()
		local lines = {}
		local ad, adErr = Game.attackData()
		local exec, caps = capabilities()
		table.insert(lines, ("Ervi Hub %s | Roll Observer report"):format(Build.id))
		table.insert(lines, ("PlaceId=%d PlaceVersion=%d (hub data from %d)"):format(game.PlaceId, game.PlaceVersion, Game.KNOWN_PLACE_VERSION))
		table.insert(lines, ("executor=%s"):format(exec))
		table.insert(lines, "capabilities: " .. caps)
		table.insert(lines, ("AttackData=%s styles=%d RollCooldown=%s MinRollCooldown=%s"):format(
			ad and "loaded" or ("MISSING (" .. tostring(adErr) .. ")"),
			#Game.styles(),
			tostring(ad and ad.RollCooldown),
			tostring(ad and ad.MinRollCooldown)
		))
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		local rr = remotes and remotes:FindFirstChild("RollAttack")
		table.insert(lines, ("Remotes.RollAttack=%s ForcedRoll=%s"):format(rr and rr.ClassName or "MISSING", tostring(remotes and remotes:FindFirstChild("ForcedRoll") ~= nil)))
		local ui = Game.mainUI()
		table.insert(lines, ("MainUI=%s RollRevealRoot=%s RollCooldown=%s"):format(
			tostring(ui ~= nil),
			tostring(ui and ui:FindFirstChild("RollRevealRoot") ~= nil),
			tostring(ui and ui:FindFirstChild("RollCooldown") ~= nil)
		))
		local ok, why = Game.rollStatus()
		table.insert(lines, ("rollStatus=%s (%s) serverNow=%.3f"):format(tostring(ok), why, Game.serverNow()))
		local names = {}
		for name, value in pairs(Game.player:GetAttributes()) do
			table.insert(names, name)
			if relevant(name) then
				table.insert(lines, ("  attr %s = %s"):format(name, short(value)))
			end
		end
		table.sort(names)
		table.insert(lines, ("all player attribute names (%d): %s"):format(#names, table.concat(names, ", ")))
		return table.concat(lines, "\n")
	end
	obs.snapshot = snapshot

	function obs.stop(reason)
		if not obs.running then
			return
		end
		obs.running = false
		if cs then
			cs:close()
			cs = nil
		end
		push("STOP", reason or "stopped")
		log("Diagnostics", "roll observer stopped: " .. (reason or "stopped"))
	end

	function obs.start(duration)
		obs.stop("restart")
		obs.events, obs.dropped = {}, 0
		obs.startedAt = os.clock()
		obs.endsAt = obs.startedAt + duration
		obs.header = snapshot()
		obs.running = true
		cs = hubScope:child("roll-observer")

		cs:connect(Game.player.AttributeChanged, function(name)
			if not relevant(name) then
				return
			end
			local v = Game.player:GetAttribute(name)
			local extra = nil
			if name:find("ReadyAt", 1, true) and type(v) == "number" then
				extra = ("(serverNow%+.3f)"):format(v - Game.serverNow())
			end
			push("ATTR", name .. " = " .. short(v), extra)
		end)

		local ui = Game.mainUI()
		local function watchText(inst, label, normalize)
			if not inst then
				push("MISSING", label)
				return
			end
			local last
			local function emit()
				local t = inst.Text
				local key = normalize and t:gsub("%d", "#") or t
				if key ~= last then
					last = key
					push("UI", label .. " = " .. short(t))
				end
			end
			emit()
			cs:connect(inst:GetPropertyChangedSignal("Text"), emit)
		end
		local reveal = ui and ui:FindFirstChild("RollRevealRoot")
		local panel = reveal and reveal:FindFirstChild("Panel")
		local button = ui and ui:FindFirstChild("RollButton")
		if reveal then
			push("UI", "RollRevealRoot.Visible = " .. tostring(reveal.Visible))
			cs:connect(reveal:GetPropertyChangedSignal("Visible"), function()
				push("UI", "RollRevealRoot.Visible = " .. tostring(reveal.Visible))
			end)
		else
			push("MISSING", "MainUI.RollRevealRoot")
		end
		watchText(panel and panel:FindFirstChild("Header"), "Panel.Header")
		watchText(panel and panel:FindFirstChild("Rarity"), "Panel.Rarity")
		watchText(button and button:FindFirstChild("Label"), "RollButton.Label")
		watchText(ui and ui:FindFirstChild("RollCooldown"), "RollCooldown", true) -- digits masked to skip countdown spam

		local h = Game.humanoid()
		if h then
			cs:connect(h.Died, function()
				push("CHAR", "Humanoid.Died")
			end)
		end

		local timer = task.delay(duration, function()
			obs.stop(("time limit %ds reached"):format(duration))
		end)
		cs:add(function()
			if coroutine.status(timer) ~= "dead" then
				pcall(task.cancel, timer)
			end
		end)
		push("START", ("capture %ds, max %d events"):format(duration, MAX_EVENTS))
		log("Diagnostics", "roll observer started")
	end

	function obs.report()
		local body = table.concat(obs.events, "\n")
		return ("%s\n--- events (%d kept, %d dropped) ---\n%s\n--- end ---"):format(obs.header ~= "" and obs.header or snapshot(), #obs.events, obs.dropped, body)
	end

	return obs
end
