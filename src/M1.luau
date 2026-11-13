-- Candidate all-style cooldown HUD. No remotes, activation hooks or attack automation.
local Game = require("Game")
local State = require("M1State")
local Scope = require("Scope")
local Theme = require("Theme")
local Ui = require("Ui")
local makeWindow = require("FloatingWindow")
local RunService = game:GetService("RunService")

return function(hub, parent, getPrefs, save)
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
		feature.refreshLayout = nil
		if on then
			overlayScope = Scope.new("m1-overlay")
			local floating = makeWindow(overlayScope, parent, "RNG_Hub_M1HUD", function()
				local p = getPrefs()
				return {x=p.m1X,y=p.m1Y,w=p.m1W,h=p.m1H}
			end, function(rect)
				local p = getPrefs()
				p.m1X,p.m1Y,p.m1W,p.m1H=rect.x,rect.y,rect.w,rect.h
				save()
			end)
			feature.refreshLayout = floating.refresh
			local title = floating.title
			local big = Ui.text(floating.body, "UNKNOWN", { order = 1, textSize = 20 })
			local note = Ui.text(floating.body, "", { order = 2, textSize = 9, color = Theme.muted })
			big.Name="M1Countdown";big.TextWrapped=false;big.TextTruncate=Enum.TextTruncate.AtEnd
            note.Name="M1Evidence"
            local bar=Ui.new("Frame",{Name="M1CooldownBar",Size=UDim2.new(1,0,0,6),LayoutOrder=2,BackgroundColor3=Theme.raised,BorderSizePixel=0,Parent=floating.body});Ui.corner(bar,3)
            note.LayoutOrder=3
            local fill=Ui.new("Frame",{Name="M1CooldownFill",Size=UDim2.fromScale(0,1),BorderSizePixel=0,BackgroundColor3=Theme.accent,Parent=bar});Ui.corner(fill,3)
            local function responsive()
             local z=floating.frame.Size
             local factor=math.clamp(math.min(z.X.Offset/330,z.Y.Offset/180),0.75,1.8)
             for _,pair in ipairs({{title,12,10,20},{big,20,14,32},{note,9,8,14}}) do
              local size=math.clamp(math.floor(pair[2]*factor+0.5),pair[3],pair[4])
              pair[1]:SetAttribute("ResponsiveTextSize",size);Ui.set(pair[1],"TextSize",size)
             end
            end
            overlayScope:connect(floating.frame:GetPropertyChangedSignal("Size"),responsive)
            responsive()
            local elapsed = 0
			local function render()
				local s = feature.snapshot()
				Ui.set(title, "Text", (s.style or "No style") .. "  M1")
				Ui.set(big, "Text", s.status == "COOLDOWN" and ("%.2fs"):format(s.remaining) or s.status)
				Ui.set(note, "Text", s.evidence)
                fill.Size=UDim2.fromScale(s.fraction or 0,1)
                fill.BackgroundColor3=s.status=="READY" and Theme.good or Theme.accent
                bar:SetAttribute("KnownCooldown",s.fraction~=nil)
                Ui.set(big,"TextColor3",s.status=="READY" and Theme.good or s.status=="COOLDOWN" and Theme.accent or Theme.muted)
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
