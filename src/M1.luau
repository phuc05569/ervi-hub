-- Candidate all-style cooldown HUD. No remotes, activation hooks or attack automation.
local Game = require("Game")
local State = require("M1State")
local Scope = require("Scope")
local Theme = require("Theme")
local Ui = require("Ui")
local RunService = game:GetService("RunService")

return function(hub, parent)
	local player = Game.player
	local state = State.new()
	local feature = { enabled = false }
	local character, charScope, overlayScope
	local blockedUntilSample = false
	local function styleName()
		local eq = Game.equipped()
		return eq and eq.name
	end
	local function equipped()
		local tool = character and state.style and character:FindFirstChild(state.style)
		return tool ~= nil and tool:IsA("Tool")
	end
	local function reset()
		state:reset(styleName())
		blockedUntilSample = true
	end
	local function sample()
		-- Only the player attribute is used: no guessed priority across conflicting owners.
		if equipped() and Game.alive() then
			state:observe(player:GetAttribute("AttackReadyAt"), Game.serverNow())
			blockedUntilSample = false
		end
	end
	local function bindCharacter(char)
		if charScope then charScope:close() end
		character = char
		reset()
		if hub.closed then return end
		charScope = Scope.new("m1-character")
		if not char then return end
		charScope:connect(char.ChildAdded, function(child)
			if child:IsA("Tool") then reset() end
		end)
		charScope:connect(char.ChildRemoved, function(child)
			if child:IsA("Tool") or child:IsA("Humanoid") then reset() end
		end)
		local function watchHumanoid(h)
			if h:IsA("Humanoid") then
				charScope:connect(h.Died, reset)
			end
		end
		local h = char:FindFirstChildOfClass("Humanoid")
		if h then watchHumanoid(h) end
		charScope:connect(char.ChildAdded, watchHumanoid)
	end
	bindCharacter(player.Character)
	-- Initial sample is allowed for the currently equipped Tool only.
	sample()
	hub:connect(player.CharacterAdded, bindCharacter)
	hub:connect(player.CharacterRemoving, function() bindCharacter(nil) end)
	hub:connect(player:GetAttributeChangedSignal("EquippedAttack"), reset)
	hub:connect(player:GetAttributeChangedSignal("AttackReadyAt"), sample)
	hub:add(function()
		if overlayScope then overlayScope:close() end
		if charScope then charScope:close() end
	end)

	function feature.snapshot()
		-- Death is also checked at render time in case the client omits Died.
		if not Game.alive() and not blockedUntilSample then reset() end
		return state:snapshot(Game.serverNow(), equipped(), Game.alive())
	end

	function feature.setEnabled(on)
		if hub.closed or on == feature.enabled then return end
		feature.enabled = on
		if overlayScope then overlayScope:close(); overlayScope = nil end
		if on then
			overlayScope = Scope.new("m1-overlay")
			local gui = overlayScope:add(Ui.new("ScreenGui", {
				Name = "RNG_Hub_M1HUD", ResetOnSpawn = false,
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 301, Parent = parent,
			}))
			Ui.root(gui)
			local frame = Ui.new("Frame", {
				Size = UDim2.fromOffset(310, 0), AutomaticSize = Enum.AutomaticSize.Y,
				Position = UDim2.new(0.5, -155, 0.55, 0), BackgroundColor3 = Theme.surface,
				BackgroundTransparency = 0.06, Active = true, Parent = gui,
			})
			Ui.surface(frame)
			Ui.corner(frame, Theme.radius)
			Ui.pad(frame, 10, 12)
			Ui.list(frame, 6)
			local title = Ui.text(frame, "M1", { order = 1, font = Theme.fontBold })
			Ui.drag(overlayScope, title, frame)
			local big = Ui.text(frame, "UNKNOWN", { order = 2, textSize = Theme.size.big })
			local note = Ui.text(frame, "", { order = 3, textSize = Theme.size.small, color = Theme.muted })
			Ui.button(overlayScope, frame, "Close M1 HUD", { order = 4 }, function() feature.setEnabled(false) end)
			local elapsed = 0
			local function render()
				local s = feature.snapshot()
				Ui.set(title, "Text", (s.style or "No style") .. "  M1")
				Ui.set(big, "Text", s.status == "COOLDOWN" and ("%.2fs"):format(s.remaining) or s.status)
				Ui.set(note, "Text", s.evidence)
			end
			render()
			overlayScope:connect(RunService.Heartbeat, function(dt)
				elapsed += dt
				if elapsed >= 0.1 then elapsed = 0; render() end
			end)
		end
		if feature.onChanged then feature.onChanged(on) end
	end
	return feature
end
