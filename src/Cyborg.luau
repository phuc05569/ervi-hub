-- Cyborg M1 cooldown tracker, V6 logic (USER-VERIFIED in baseline v1):
--   own Beam named "Beam" under <character>.HumanoidRootPart.SmearFX, Cyborg Tool equipped,
--   0.5 s debounce, estimated 6.07 s cooldown from the effect (an effect proxy, not server truth).
-- Change vs baseline: listens on the local HumanoidRootPart instead of all of workspace
-- (same matches, far fewer events) and rebinds on respawn / root replacement.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Theme = require("Theme")
local Ui = require("Ui")

local COOLDOWN = 6.07
local DEBOUNCE = 0.5
local TOOL_NAME = "Cyborg"

local player = Players.LocalPlayer

local function equippedCyborg()
	local char = player.Character
	local tool = char and char:FindFirstChild(TOOL_NAME)
	return tool ~= nil and tool:IsA("Tool")
end

local function isOwnAttackBeam(obj)
	if not obj:IsA("Beam") or obj.Name ~= "Beam" then
		return false
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local smear = root and root:FindFirstChild("SmearFX")
	return smear ~= nil and obj:IsDescendantOf(smear)
end

return function(hubScope, overlayParent, metrics, log)
	local feature = { enabled = false, count = 0, lastEffect = nil, lastInterval = nil, onChanged = nil }
	local fs -- feature scope, alive while enabled

	function feature.remaining()
		if not feature.lastEffect then
			return nil
		end
		return math.max(0, COOLDOWN - (os.clock() - feature.lastEffect))
	end

	local function onFx(obj)
		if not isOwnAttackBeam(obj) or not equippedCyborg() then
			return
		end
		local now = os.clock()
		if feature.lastEffect and now - feature.lastEffect < DEBOUNCE then
			return
		end
		if feature.lastEffect then
			feature.lastInterval = now - feature.lastEffect
			log("Cyborg", ("attack interval %.3fs"):format(feature.lastInterval))
		end
		feature.lastEffect = now
		feature.count += 1
	end

	local function bindCharacter(scope, char)
		local cs = scope:child("cyborg-character")
		local rs
		local function bindRoot(root)
			if rs then
				rs:close()
			end
			rs = cs:child("cyborg-root")
			rs:connect(root.DescendantAdded, onFx)
		end
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then
			bindRoot(root)
		end
		cs:connect(char.ChildAdded, function(child)
			if child.Name == "HumanoidRootPart" then
				bindRoot(child)
			end
		end)
		return cs
	end

	local function buildOverlay(scope)
		local gui = scope:add(Ui.new("ScreenGui", {
			Name = "RNG_Hub_CombatHUD",
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			DisplayOrder = 300,
			Parent = overlayParent,
		}))
		Ui.root(gui)
		local frame = Ui.new("Frame", {
			Size = UDim2.fromOffset(250, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Position = UDim2.new(0.5, -125, 0.72, 0),
			BackgroundColor3 = Theme.surface,
			BackgroundTransparency = 0.06,
			Parent = gui,
		})
		Ui.surface(frame) -- follows the menu opacity setting
		Ui.corner(frame, Theme.radius)
		Ui.stroke(frame, Theme.stroke, 0.2)
		Ui.pad(frame, 10, 12)
		Ui.list(frame, 6)

		local head = Ui.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), Active = true, Parent = frame })
		Ui.text(head, "CYBORG  M1", { size = UDim2.new(1, -30, 1, 0), font = Theme.fontBold, textSize = Theme.size.small, color = Theme.muted })
		local close = Ui.new("TextButton", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.fromOffset(22, 22),
			BackgroundColor3 = Theme.raised,
			Text = "×",
			TextColor3 = Theme.muted,
			TextSize = 16,
			Font = Theme.fontBold,
			AutoButtonColor = true,
			Parent = head,
		})
		Ui.corner(close)
		Ui.drag(scope, head, frame)

		local big = Ui.text(frame, "WAITING", { size = UDim2.new(1, 0, 0, 36), font = Theme.fontBold, textSize = Theme.size.big, align = Enum.TextXAlignment.Center, order = 1 })
		local setBar = Ui.bar(frame, 2, 8)
		local status = Ui.text(frame, "", { textSize = Theme.size.small, color = Theme.muted, align = Enum.TextXAlignment.Center, order = 3 })
		local footer = Ui.text(frame, "", { textSize = Theme.size.tiny, color = Theme.faint, font = Theme.mono, align = Enum.TextXAlignment.Center, order = 4 })

		scope:connect(close.Activated, function()
			feature.setEnabled(false)
		end)

		local lastFooter = 0
		scope:connect(RunService.Heartbeat, function()
			if not equippedCyborg() then
				Ui.set(big, "Text", "UNEQUIPPED")
				Ui.set(big, "TextColor3", Theme.muted)
				Ui.set(status, "Text", "Equip Cyborg with key 1")
				setBar(0)
			elseif not feature.lastEffect then
				Ui.set(big, "Text", "WAITING")
				Ui.set(big, "TextColor3", Theme.text)
				Ui.set(status, "Text", "Use M1 to detect first attack")
				setBar(0)
			else
				local left = feature.remaining()
				if left > 0 then
					Ui.set(big, "Text", ("%.2fs"):format(left))
					Ui.set(big, "TextColor3", Theme.warn)
					Ui.set(status, "Text", "Estimated M1 cooldown")
					setBar(left / COOLDOWN, Theme.warn)
				else
					Ui.set(big, "Text", "READY")
					Ui.set(big, "TextColor3", Theme.good)
					Ui.set(status, "Text", "Estimated cooldown complete")
					setBar(0)
				end
			end
			local now = os.clock()
			if now - lastFooter >= 0.25 then
				lastFooter = now
				Ui.set(footer, "Text", ("hits %d · est %.2fs · %d fps · %d ms"):format(feature.count, COOLDOWN, metrics.fps, metrics.ping))
			end
		end)
	end

	function feature.setEnabled(on)
		if on == feature.enabled then
			return
		end
		feature.enabled = on
		if on then
			fs = hubScope:child("cyborg")
			local charScope
			local function onChar(char)
				if charScope then
					charScope:close()
				end
				charScope = bindCharacter(fs, char)
			end
			if player.Character then
				onChar(player.Character)
			end
			fs:connect(player.CharacterAdded, onChar)
			buildOverlay(fs)
			log("Cyborg", "tracker enabled")
		else
			if fs then
				fs:close()
				fs = nil
			end
			log("Cyborg", "tracker disabled")
		end
		if feature.onChanged then
			feature.onChanged(on)
		end
	end

	feature.COOLDOWN = COOLDOWN
	feature.equipped = equippedCyborg
	return feature
end
