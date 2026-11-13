-- Session helpers, each off by default and toggled from the Session tab:
--   Anti-AFK        When Roblox reports you idle (Player.Idled, roughly every 2 minutes while idle),
--                   send one harmless right-click through VirtualUser - the widely used method.
--                   VirtualUser needs executor permission (LocalUserSecurity).
--   Auto-reconnect  When Roblox shows a disconnect error, rejoin this place (up to 5 tries, 10 s apart).
--                   Only for connection / server errors - never after a kick, ban or security disconnect.
--                   Watches both the error event and the on-screen error prompt, because an idle drop
--                   may not raise the event (DevForum report).
--   Re-run after teleport  queue_on_teleport runs Ervi_Hub.luau from the executor workspace after
--                   teleports and rejoins while the flag file says "on". Nothing goes in autoexec.
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")

local HUB_FILE = "Ervi_Hub.luau"
local FLAG_FILE = "Ervi_Hub_autoexec.txt"

local RECONNECT_ON = {
	DisconnectErrors = true,
	DisconnectTimeout = true,
	DisconnectConnectionLost = true,
	DisconnectIdle = true,
	DisconnectRaknetErrors = true,
	DisconnectReceivePacketError = true,
	DisconnectReceivePacketStreamError = true,
	DisconnectSendPacketError = true,
	DisconnectEvicted = true,
	DisconnectDevMaintenance = true,
	DisconnectRobloxMaintenance = true,
	ReplicatorTimeout = true,
}

local function queueFn()
	if type(queue_on_teleport) == "function" then
		return queue_on_teleport
	elseif type(queueonteleport) == "function" then
		return queueonteleport
	end
	return nil
end

local function fileExists(name)
	if type(isfile) ~= "function" then
		return false
	end
	local ok, exists = pcall(isfile, name)
	return ok and exists == true
end

return function(hubScope, log)
	local player = Players.LocalPlayer
	local s = {
		HUB_FILE = HUB_FILE,
		QUEUED = ('if isfile and readfile and isfile("%s") and readfile("%s") == "on" and isfile("%s") then loadstring(readfile("%s"))() end'):format(
			FLAG_FILE,
			FLAG_FILE,
			HUB_FILE,
			HUB_FILE
		),
		antiAfk = false,
		reconnect = false,
		autoExec = false,
		afkPulses = 0,
		lastAfk = nil,
		reconnectStatus = "off",
		autoExecStatus = "off",
	}
	local afkScope, rcScope

	function s.setAntiAfk(on)
		if on == s.antiAfk then
			return
		end
		s.antiAfk = on
		if afkScope then
			afkScope:close()
			afkScope = nil
		end
		if not on then
			return
		end
		afkScope = hubScope:child("anti-afk")
		local ok, vu = pcall(game.GetService, game, "VirtualUser")
		if not ok or not vu then
			log("AntiAFK", "VirtualUser unavailable: " .. tostring(vu), true)
			return
		end
		afkScope:connect(player.Idled, function()
			local sent, err = pcall(function()
				vu:CaptureController()
				vu:ClickButton2(Vector2.new())
			end)
			if sent then
				s.afkPulses += 1
				s.lastAfk = os.clock()
			else
				log("AntiAFK", "could not send input: " .. tostring(err), true)
			end
		end)
	end

	function s.setReconnect(on)
		if on == s.reconnect then
			return
		end
		s.reconnect = on
		if rcScope then
			rcScope:close()
			rcScope = nil
		end
		s.reconnectStatus = on and "watching for disconnects" or "off"
		if not on then
			return
		end
		local scope = hubScope:child("reconnect")
		rcScope = scope
		local busy = false
		local function onError()
			if busy or scope.closed then
				return
			end
			local ok, code = pcall(GuiService.GetErrorCode, GuiService)
			local name = ok and code and code.Name or "unknown"
			if name == "OK" then
				return
			end
			if not RECONNECT_ON[name] then
				s.reconnectStatus = "not rejoining after " .. name
				log("Reconnect", s.reconnectStatus)
				return
			end
			busy = true
			scope:add(task.spawn(function()
				for attempt = 1, 5 do
					s.reconnectStatus = ("%s - rejoining (try %d/5)"):format(name, attempt)
					log("Reconnect", s.reconnectStatus)
					local sent, err = pcall(TeleportService.Teleport, TeleportService, game.PlaceId, player)
					if not sent then
						log("Reconnect", "teleport failed: " .. tostring(err), true)
					end
					task.wait(10)
				end
				s.reconnectStatus = "gave up after 5 tries"
				busy = false
			end))
		end
		local evOk = pcall(function()
			scope:connect(GuiService.ErrorMessageChanged, onError)
		end)
		local promptOk, overlay = pcall(function()
			return game:GetService("CoreGui").RobloxPromptGui.promptOverlay
		end)
		if promptOk and overlay then
			scope:connect(overlay.ChildAdded, function(child)
				if child.Name == "ErrorPrompt" then
					task.wait(0.5) -- let Roblox set the error code first
					onError()
				end
			end)
		end
		if not evOk and not (promptOk and overlay) then
			s.reconnectStatus = "cannot watch disconnects in this executor"
			log("Reconnect", s.reconnectStatus, true)
		end
	end

	-- ok, reason
	function s.autoExecSupport()
		if not queueFn() then
			return false, "this executor has no queue_on_teleport"
		end
		if type(writefile) ~= "function" or type(readfile) ~= "function" then
			return false, "this executor has no file access"
		end
		if not fileExists(HUB_FILE) then
			return false, HUB_FILE .. " is not in the executor workspace folder"
		end
		return true, "ready"
	end

	function s.setAutoExec(on)
		s.autoExec = on
		if type(writefile) == "function" then
			pcall(writefile, FLAG_FILE, on and "on" or "off")
		end
		if not on then
			s.autoExecStatus = "off"
			return
		end
		local ok, why = s.autoExecSupport()
		if not ok then
			s.autoExecStatus = "unavailable: " .. why
			return
		end
		local queued, err = pcall(queueFn(), s.QUEUED)
		s.autoExecStatus = queued and "on - Ervi Hub re-runs after the next teleport or rejoin" or ("queue failed: " .. tostring(err))
	end

	function s.stop()
		s.setAntiAfk(false)
		s.setReconnect(false)
	end

	return s
end
