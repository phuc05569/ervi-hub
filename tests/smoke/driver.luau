-- Headless GUI + lifecycle smoke test. Drives the real hub bundle against MockEngine.
return function(API, makeEngine, hubFn, loaderFn)
	local env, ctl = makeEngine(API)
	local passed, failed = 0, 0
	local function check(cond, name, detail)
		if cond then
			passed += 1
			print("  PASS  " .. name)
		else
			failed += 1
			print("  FAIL  " .. name .. (detail and ("\n        " .. tostring(detail)) or ""))
		end
	end

	local function runHub()
		setfenv(hubFn, env)
		local stop
		ctl.task.spawn(function()
			stop = hubFn()
		end)
		return stop
	end
	local function find(root, class, text)
		for _, d in ipairs(root:GetDescendants()) do
			if d.ClassName == class and d.Text == text then
				return d
			end
		end
		return nil
	end
	local function click(btn)
		assert(btn, "button not found")
		btn.Activated:Fire()
	end
	local function hubGui()
		return ctl.pg:FindFirstChild("RNG_RollAttacks_Hub")
	end
	local function toggleRow(label)
		local l = find(hubGui(), "TextLabel", label)
		local p = l and l.Parent
		while p and p.ClassName ~= "TextButton" do
			p = p.Parent
		end
		return p
	end
	local function noErrors(name)
		check(#ctl.errors == 0, name .. ": no script errors", table.concat(ctl.errors, "\n"))
		ctl.errors = {}
		local bad = {}
		for _, w in ipairs(ctl.warnings) do
			if not w:find("cleanup error", 1, true) then
				table.insert(bad, w)
			end
		end
		check(#bad == 0, name .. ": no warnings", table.concat(bad, "\n"))
		ctl.warnings = {}
	end

	-- 1. boot
	local baseConns = ctl.conns
	local stop = runHub()
	ctl.run(0.5)
	check(hubGui() ~= nil, "hub GUI created")
	check(type(stop) == "function" and env._G.RNG_HUB_STOP == stop, "global stop registered")
	noErrors("boot")

	-- 2. every tab renders and refreshes
	for _, tab in ipairs({ "Dashboard", "Auto Roll", "Combat", "Styles", "Diagnostics", "Session", "Utility", "Settings" }) do
		click(find(hubGui(), "TextLabel", tab).Parent)
		ctl.run(0.5)
		noErrors("tab " .. tab)
	end
	click(find(hubGui(), "TextLabel", "Styles").Parent)
	ctl.run(0.2)
	check(find(hubGui(), "TextLabel", "Knockback Stick") ~= nil, "styles list shows game data")
	check(find(hubGui(), "TextLabel", "Secret  (unreleased)") and not find(hubGui(), "TextLabel", "Secret  (unreleased)").Parent.Visible, "unreleased hidden by default")
	check(find(hubGui(), "TextLabel", "Mythic") ~= nil, "RarityName override shown")

	-- 3. Auto Roll: 1/500 target, scripted server results
	click(find(hubGui(), "TextLabel", "Auto Roll").Parent)
	click(find(hubGui(), "TextButton", "1/500"))
	ctl.rollScript = { { "Punch", 3 }, { "Slap", 5 }, { "Knockback Stick", 750 } }
	click(find(hubGui(), "TextButton", "Start"))
	ctl.run(40)
	check(ctl.invokes == 3, "auto roll sent exactly 3 requests", ctl.invokes)
	check(find(hubGui(), "TextLabel", "FOUND") ~= nil, "state pill shows FOUND")
	check(ctl.player:GetAttribute("EquippedAttack") == "Knockback Stick", "qualifying style kept")
	ctl.run(60)
	check(ctl.invokes == 3, "zero further requests after Found", ctl.invokes)
	noErrors("auto roll")

	-- 3b. rare current style -> pause, Continue required
	click(find(hubGui(), "TextButton", "1/1000"))
	ctl.rollScript = { { "Punch", 3 } }
	click(find(hubGui(), "TextButton", "Start"))
	ctl.run(2)
	check(ctl.invokes == 3, "no roll while current style is rare (1/750 > 1/125)", ctl.invokes)
	check(find(hubGui(), "TextLabel", "PAUSED") ~= nil, "paused pending Continue")
	click(find(hubGui(), "TextButton", "Continue"))
	ctl.run(5) -- one roll + part of the 8 s cooldown
	check(ctl.invokes == 4, "Continue rolls once", ctl.invokes)
	click(find(hubGui(), "TextButton", "Stop"))
	ctl.run(20)
	check(ctl.invokes == 4, "Stop prevents further rolls", ctl.invokes)
	noErrors("auto roll pause/stop")

	-- 3c. death gates rolling
	ctl.set(ctl.char:FindFirstChildOfClass("Humanoid"), "Health", 0)
	ctl.rollScript = { { "Slap", 5 } }
	click(find(hubGui(), "TextButton", "Start"))
	ctl.run(15)
	check(ctl.invokes == 4, "no roll while dead", ctl.invokes)
	click(find(hubGui(), "TextButton", "Stop"))
	ctl.set(ctl.char:FindFirstChildOfClass("Humanoid"), "Health", 100)
	ctl.rollScript = {}
	noErrors("dead gate")

	-- 4. Cyborg tracker: equip, fire own Beam, check countdown; other player's beam ignored
	click(find(hubGui(), "TextLabel", "Combat").Parent)
	click(toggleRow("Show Cyborg M1 overlay"))
	ctl.run(0.2)
	local hud = ctl.pg:FindFirstChild("RNG_Hub_CombatHUD")
	check(hud ~= nil, "Cyborg overlay created")
	local tool = ctl.new("Tool", ctl.char)
	tool.Name = "Cyborg"
	local other = ctl.new("Model", env.workspace)
	local otherRoot = ctl.new("Part", other)
	otherRoot.Name = "HumanoidRootPart"
	local otherSmear = ctl.new("Folder", otherRoot)
	otherSmear.Name = "SmearFX"
	ctl.new("Beam", otherSmear).Name = "Beam"
	ctl.run(0.2)
	check(find(hud, "TextLabel", "WAITING") ~= nil, "other player's beam ignored")
	local smear = ctl.new("Folder")
	smear.Name = "SmearFX"
	ctl.new("Beam", smear).Name = "Beam"
	smear.Parent = ctl.root -- subtree insert, like the game's effect
	ctl.run(1)
	local big
	for _, d in ipairs(hud:GetDescendants()) do
		if d.ClassName == "TextLabel" and tostring(d.Text):match("^%d+%.%d%ds$") then
			big = d.Text
		end
	end
	check(big ~= nil, "countdown shown after own Beam", big)
	ctl.run(6)
	check(find(hud, "TextLabel", "READY") ~= nil, "READY after ~6.07s")
	click(find(hud, "TextButton", "×"))
	ctl.run(0.2)
	check(ctl.pg:FindFirstChild("RNG_Hub_CombatHUD") == nil, "overlay X closes overlay")
	check(hubGui() ~= nil, "overlay X leaves hub open")
	noErrors("cyborg")

	-- 5. Diagnostics: capture, copy, redaction
	click(find(hubGui(), "TextLabel", "Diagnostics").Parent)
	click(find(hubGui(), "TextButton", "Start capture"))
	ctl.player:SetAttribute("RollReadyAt", 1234)
	ctl.run(1)
	click(find(hubGui(), "TextButton", "Copy report"))
	ctl.run(0.2)
	local clip = ctl.clipboard or ""
	check(clip:find("RollReadyAt = 1234", 1, true) ~= nil, "report captured attribute change")
	check(clip:find("PlaceVersion=969", 1, true) ~= nil, "report has place version")
	check(clip:find("MockUserSecret", 1, true) == nil, "report excludes username")
	ctl.run(95)
	check(find(hubGui(), "TextLabel", "IDLE") ~= nil, "capture auto-stops at time limit")
	noErrors("diagnostics")

	-- 6. window controls
	click(find(hubGui(), "TextButton", "–"))
	ctl.run(0.2)
	check(find(hubGui(), "TextButton", "+") ~= nil, "minimize")
	click(find(hubGui(), "TextButton", "+"))
	local E = env.Enum
	local function press(key, processed)
		ctl.UIS.InputBegan:Fire({ KeyCode = E.KeyCode[key], UserInputType = E.UserInputType.Keyboard }, processed == true)
		ctl.run(0.1)
	end
	local function win()
		return hubGui():FindFirstChildOfClass("Frame")
	end
	press("RightShift")
	check(win().Visible == false, "RightShift hides")
	press("RightShift")
	check(win().Visible == true, "RightShift shows")
	press("RightShift", true)
	check(win().Visible == true, "key ignored while typing (gameProcessed)")
	ctl.focusedTextBox = win()
	press("RightShift")
	check(win().Visible == true, "key ignored while a TextBox is focused")
	ctl.focusedTextBox = nil
	noErrors("window")

	-- 6b. rebind toggle key
	click(find(hubGui(), "TextLabel", "Settings").Parent)
	ctl.run(0.2)
	click(find(hubGui(), "TextButton", "RightShift"))
	check(find(hubGui(), "TextButton", "Press a key… (Esc = cancel)") ~= nil, "key capture prompt shown")
	press("Escape")
	check(find(hubGui(), "TextButton", "RightShift") ~= nil, "Esc cancels capture")
	click(find(hubGui(), "TextButton", "RightShift"))
	press("F4")
	check(find(hubGui(), "TextButton", "F4") ~= nil, "new key shown on button")
	check(win().Visible == true, "capturing the key does not toggle the menu")
	press("RightShift")
	check(win().Visible == true, "old key no longer toggles")
	press("F4")
	check(win().Visible == false, "new key hides")
	press("F4")
	check(win().Visible == true, "new key shows")
	check((ctl.files["RNG_Hub_settings.txt"] or ""):find("toggleKey=F4", 1, true) ~= nil, "key saved to settings file")
	noErrors("rebind")

	-- 6c. opacity slider
	local function near(a, b)
		return type(a) == "number" and math.abs(a - b) < 1e-6
	end
	check(near(win().BackgroundTransparency, 0.05), "default opacity 95%", win().BackgroundTransparency)
	for _ = 1, 3 do
		click(find(hubGui(), "TextButton", "−"))
	end
	ctl.run(0.1)
	check(near(win().BackgroundTransparency, 0.2), "3 steps down -> 80% opacity", win().BackgroundTransparency)
	check(find(hubGui(), "TextLabel", "80%") ~= nil, "slider shows 80%")
	local card = find(hubGui(), "TextLabel", "CONTROLS").Parent
	check(near(card.BackgroundTransparency, 0.2), "cards follow opacity", card.BackgroundTransparency)
	for _ = 1, 20 do
		click(find(hubGui(), "TextButton", "−"))
	end
	ctl.run(0.1)
	check(near(win().BackgroundTransparency, 0.65), "opacity floor 35%", win().BackgroundTransparency)
	check(find(hubGui(), "TextLabel", "Menu opacity").TextStrokeTransparency < 1, "text outlined at low opacity")
	click(find(hubGui(), "TextButton", "+"))
	for _ = 1, 20 do
		click(find(hubGui(), "TextButton", "+"))
	end
	ctl.run(0.1)
	check(near(win().BackgroundTransparency, 0), "opacity ceiling 100%")
	check(find(hubGui(), "TextLabel", "Menu opacity").TextStrokeTransparency == 1, "outline removed at high opacity")
	for _ = 1, 4 do
		click(find(hubGui(), "TextButton", "−"))
	end
	ctl.run(0.1)
	check((ctl.files["RNG_Hub_settings.txt"] or ""):find("opacity=0.80", 1, true) ~= nil, "opacity saved", ctl.files["RNG_Hub_settings.txt"])
	noErrors("opacity")

	-- 6d. appearance: design, accent, font, text color/size/outline/transparency
	local rgb = env.Color3.fromRGB
	local function hex(c)
		return c and c:ToHex()
	end
	local function label(text)
		return find(hubGui(), "TextLabel", text)
	end
	local function sliderBtn(name, sym)
		for _, d in ipairs(label(name).Parent:GetChildren()) do
			if d.ClassName == "TextButton" and d.Text == sym then
				return d
			end
		end
	end
	local probe = "Show / hide menu key" -- a fontMedium, body-size label
	click(find(hubGui(), "TextButton", "Ocean"))
	ctl.run(0.1)
	check(hex(win().BackgroundColor3) == hex(rgb(9, 17, 28)), "design Ocean: window repainted", hex(win().BackgroundColor3))
	check(hex(label("CONTROLS").Parent.BackgroundColor3) == hex(rgb(18, 33, 52)), "design Ocean: cards repainted")
	check(hex(label(probe).TextColor3) == hex(rgb(230, 242, 255)), "design Ocean: text repainted")
	check(hex(find(hubGui(), "TextButton", "Save as").BackgroundColor3) == hex(rgb(62, 168, 240)), "design Ocean: default accent Sky")
	local ocean = find(hubGui(), "TextButton", "Ocean")
	ocean.MouseLeave:Fire()
	ctl.run(0.05)
	check(hex(ocean.BackgroundColor3) == hex(rgb(62, 168, 240)), "selected design stays highlighted after hover")
	local rose
	for _, d in ipairs(hubGui():GetDescendants()) do
		if d.ClassName == "TextButton" and d:GetAttribute("Swatch") and hex(d.BackgroundColor3) == hex(rgb(240, 98, 142)) then
			rose = d
		end
	end
	click(rose)
	ctl.run(0.1)
	check(hex(find(hubGui(), "TextButton", "Save as").BackgroundColor3) == hex(rgb(240, 98, 142)), "accent Rose applied")
	check(rose.Text == "✓" and hex(rose.BackgroundColor3) == hex(rgb(240, 98, 142)), "swatch keeps its color and shows a check")
	rose.MouseEnter:Fire()
	ctl.run(0.05)
	check(hex(rose.BackgroundColor3) == hex(rgb(240, 98, 142)), "swatch keeps its color on hover")
	click(find(hubGui(), "TextButton", "Arcade"))
	ctl.run(0.1)
	check(label(probe).Font == E.Font.Arcade, "font Arcade applied")
	check(find(hubGui(), "TextButton", "Roboto").Font == E.Font.Roboto, "font buttons keep their preview font")
	click(find(hubGui(), "TextButton", "Gotham"))
	click(find(hubGui(), "TextButton", "Gold"))
	ctl.run(0.1)
	check(hex(label(probe).TextColor3) == hex(rgb(255, 214, 120)), "text color Gold applied")
	check(hex(find(hubGui(), "TextButton", "White").TextColor3) == hex(rgb(250, 250, 250)), "color preview buttons keep their color")
	for _ = 1, 4 do
		click(sliderBtn("Text size", "+"))
	end
	ctl.run(0.1)
	check(label(probe).TextSize == 16, "text size 120%: 13 -> 16", label(probe).TextSize)
	click(find(hubGui(), "TextLabel", "Styles").Parent)
	ctl.run(0.2)
	local styleName = find(hubGui(), "TextLabel", "Knockback Stick")
	check(styleName and styleName.TextSize == 14, "text built later is scaled too (12 -> 14)", styleName and styleName.TextSize)
	click(find(hubGui(), "TextLabel", "Combat").Parent)
	click(toggleRow("Show Cyborg M1 overlay")) -- overlay is built now, after the size change
	ctl.run(0.2)
	local hudTitle = find(ctl.pg:FindFirstChild("RNG_Hub_CombatHUD"), "TextLabel", "CYBORG  M1")
	check(hudTitle and hudTitle.TextSize == 14, "newly built overlay text is scaled (12 -> 14)", hudTitle and hudTitle.TextSize)
	click(toggleRow("Show Cyborg M1 overlay"))
	click(find(hubGui(), "TextLabel", "Settings").Parent)
	click(find(hubGui(), "TextButton", "On"))
	ctl.run(0.1)
	check(label(probe).TextStrokeTransparency < 1, "outline On at 80% opacity")
	click(find(hubGui(), "TextButton", "Off"))
	ctl.run(0.1)
	check(label(probe).TextStrokeTransparency == 1, "outline Off")
	for _ = 1, 6 do
		click(sliderBtn("Text transparency", "+"))
	end
	ctl.run(0.1)
	check(near(label(probe).TextTransparency, 0.3), "text transparency 30%", label(probe).TextTransparency)
	local saved = ctl.files["RNG_Hub_settings.txt"] or ""
	check(saved:find("theme=Ocean", 1, true) and saved:find("accent=Rose", 1, true) and saved:find("textColor=Gold", 1, true) and saved:find("outline=off", 1, true), "look saved to the active config", saved)
	-- color circle: accent via the wheel, text via hex code, background via hex code
	local function customButtons()
		local out = {}
		for _, b in ipairs(hubGui():GetDescendants()) do
			if b.ClassName == "TextButton" and b.Text == "Custom" then
				table.insert(out, b)
			end
		end
		return out
	end
	local customs = customButtons()
	check(#customs == 3, "three Custom color buttons (accent, text, background)", #customs)
	local wheelGroup
	for _, g in ipairs(hubGui():GetDescendants()) do
		if g.ClassName == "CanvasGroup" then
			wheelGroup = g
		end
	end
	click(customs[1])
	ctl.run(0.1)
	check(wheelGroup.Parent.Parent.Visible == true, "Custom opens the color circle")
	ctl.set(wheelGroup, "AbsolutePosition", env.Vector2.new(100, 100))
	ctl.set(wheelGroup, "AbsoluteSize", env.Vector2.new(150, 150))
	wheelGroup.InputBegan:Fire({ UserInputType = E.UserInputType.MouseButton1, Position = env.Vector2.new(250, 175) })
	ctl.UIS.InputEnded:Fire({ UserInputType = E.UserInputType.MouseButton1 })
	ctl.run(0.1)
	local hexBox
	for _, t in ipairs(hubGui():GetDescendants()) do
		if t.ClassName == "TextBox" and t.PlaceholderText == "#RRGGBB" then
			hexBox = t
		end
	end
	check(hexBox.Text == "#F00000", "circle keeps the current brightness (94%)", hexBox.Text)
	click(sliderBtn("Brightness", "+"))
	click(sliderBtn("Brightness", "+"))
	ctl.run(0.1)
	check(hexBox.Text == "#FF0000", "right edge at 100% brightness = pure red", hexBox.Text)
	click(find(hubGui(), "TextButton", "Apply"))
	ctl.run(0.1)
	check(hex(find(hubGui(), "TextButton", "Save as").BackgroundColor3) == hex(rgb(255, 0, 0)), "custom accent applied from the circle")
	check(customs[1].BackgroundColor3 and hex(customs[1].BackgroundColor3) == hex(rgb(255, 0, 0)), "accent Custom button shows as selected")
	check((ctl.files["RNG_Hub_settings.txt"] or ""):find("accent=#FF0000", 1, true) ~= nil, "custom accent saved")
	click(customs[2])
	hexBox.Text = "88ccff"
	hexBox.FocusLost:Fire(true)
	ctl.run(0.1)
	click(find(hubGui(), "TextButton", "Apply"))
	ctl.run(0.1)
	check(hex(label(probe).TextColor3) == hex(rgb(136, 204, 255)), "custom text color from a typed hex code")
	click(customs[3])
	hexBox.Text = "#202830"
	hexBox.FocusLost:Fire(true)
	click(find(hubGui(), "TextButton", "Apply"))
	ctl.run(0.1)
	check(hex(win().BackgroundColor3) == hex(rgb(32, 40, 48)), "custom background color", hex(win().BackgroundColor3))
	check(hex(label("CONTROLS").Parent.BackgroundColor3) ~= hex(rgb(32, 40, 48)), "cards get a lighter shade of a custom background")
	click(find(hubGui(), "TextButton", "Reset appearance"))
	ctl.run(0.1)
	check(hex(win().BackgroundColor3) == hex(rgb(14, 15, 20)), "reset appearance: Midnight again")
	check(label(probe).TextSize == 13 and near(label(probe).TextTransparency, 0) and label(probe).Font == E.Font.GothamMedium, "reset appearance: text back to normal")
	noErrors("appearance")

	-- 7. close via X: full cleanup
	click(find(hubGui(), "TextButton", "×"))
	ctl.run(1)
	check(hubGui() == nil, "X removes hub GUI")
	check(ctl.conns == baseConns, "no leaked connections", ("%d live (baseline %d)"):format(ctl.conns, baseConns))
	check(ctl.pendingThreads() == 0, "no leaked threads", ctl.pendingThreads())
	check(env._G.RNG_HUB_STOP == nil, "global stop cleared")
	noErrors("close")

	-- 8. rerun twice: previous instance cleaned, single GUI
	runHub()
	ctl.run(0.3)
	runHub()
	ctl.run(0.3)
	local count = 0
	for _, c in ipairs(ctl.pg:GetChildren()) do
		if c.Name == "RNG_RollAttacks_Hub" then
			count += 1
		end
	end
	check(count == 1, "rerun keeps a single hub", count)
	check(find(hubGui(), "TextButton", "F4") ~= nil, "saved key restored after rerun")
	check(math.abs(hubGui():FindFirstChildOfClass("Frame").BackgroundTransparency - 0.2) < 1e-6, "saved opacity restored after rerun")
	env._G.RNG_HUB_STOP()
	ctl.run(0.5)
	check(ctl.conns == baseConns, "no leaks after reruns", ctl.conns - baseConns)
	noErrors("rerun")

	-- 9. double Run while the first is still loading (seen live at 08:06:22: two loads, one orphan)
	ctl.requireDelay = 0.2
	runHub()
	runHub()
	ctl.run(1)
	local loads = 0
	for _, p in ipairs(ctl.prints) do
		if p:find("loaded build", 1, true) then
			loads += 1
		end
	end
	ctl.prints = {}
	count = 0
	for _, c in ipairs(ctl.pg:GetChildren()) do
		if c.Name == "RNG_RollAttacks_Hub" then
			count += 1
		end
	end
	check(count == 1, "double Run: single hub GUI", count)
	check(type(env._G.RNG_HUB_STOP) == "function", "double Run: stop handle registered")
	env._G.RNG_HUB_STOP()
	ctl.run(0.5)
	check(ctl.conns == baseConns, "double Run: no orphaned connections", ctl.conns - baseConns)
	check(ctl.pendingThreads() == 0, "double Run: no orphaned threads", ctl.pendingThreads())
	noErrors("double run")

	-- 10. configs: save as, overwrite confirm, load, autoload across a rerun, delete
	ctl.requireDelay = nil
	runHub()
	ctl.run(0.5)
	click(find(hubGui(), "TextLabel", "Settings").Parent)
	ctl.run(0.2)
	local function rowOf(name)
		for _, d in ipairs(hubGui():GetDescendants()) do
			if d.ClassName == "TextLabel" and (d.Text == name or d.Text == name .. "  (active)") and d.Parent.ClassName == "Frame" then
				local btns = {}
				for _, b in ipairs(d.Parent:GetChildren()) do
					if b.ClassName == "TextButton" then
						btns[b.Text] = b
					end
				end
				if btns.Load then -- a config list row, not the "Active config" readout
					return d, btns
				end
			end
		end
	end
	local nameBox = find(hubGui(), "TextBox", "")
	for _, d in ipairs(hubGui():GetDescendants()) do
		if d.ClassName == "TextBox" and d.PlaceholderText == "New config name" then
			nameBox = d
		end
	end
	nameBox.Text = "PvP"
	click(find(hubGui(), "TextButton", "Save as"))
	ctl.run(0.1)
	check(label("PvP  (active)") ~= nil, "Save as creates and activates PvP")
	check((ctl.files["RNG_Hub_settings.txt"] or ""):find("[PvP]", 1, true) ~= nil, "PvP written to file")
	for _ = 1, 4 do
		click(find(hubGui(), "TextButton", "−")) -- opacity 80% -> 60% in PvP only
	end
	ctl.run(0.1)
	check(near(win().BackgroundTransparency, 0.4), "PvP opacity 60%")
	local _, defaultBtns = rowOf("Default")
	click(defaultBtns.Load)
	ctl.run(0.1)
	check(near(win().BackgroundTransparency, 0.2), "loading Default restores its 80% opacity")
	local _, pvpRow = rowOf("PvP")
	click(pvpRow.Overwrite)
	check(pvpRow.Overwrite.Text == "Sure?", "Overwrite asks once")
	click(pvpRow.Overwrite)
	ctl.run(0.1)
	check((ctl.files["RNG_Hub_settings.txt"] or ""):match("%[PvP%][^%[]*opacity=0%.80") ~= nil, "Overwrite copies current settings into PvP")
	local _, defRow = rowOf("Default")
	check(defRow.Overwrite and defRow.Load, "active row has its buttons")
	check(label("Default  (active)") ~= nil, "Default is active after Load")
	nameBox.Text = "PvP"
	click(find(hubGui(), "TextButton", "Save as"))
	check(find(hubGui(), "TextButton", "Overwrite?") ~= nil, "existing name asks before overwriting")
	click(find(hubGui(), "TextButton", "Overwrite?"))
	ctl.run(0.1)
	check(near(win().BackgroundTransparency, 0.2) and label("PvP  (active)") ~= nil, "overwrite saves current settings into PvP")
	for _ = 1, 2 do
		click(find(hubGui(), "TextButton", "−")) -- PvP now 70%
	end
	local _, pvpBtns = rowOf("PvP")
	click(pvpBtns.Auto)
	ctl.run(0.1)
	check((ctl.files["RNG_Hub_settings.txt"] or ""):find("autoload=PvP", 1, true) ~= nil, "autoload saved")
	runHub() -- simulates the next game join / autoexec
	ctl.run(0.5)
	check(near(win().BackgroundTransparency, 0.3), "autoload: PvP (70%) loaded at start", win().BackgroundTransparency)
	click(find(hubGui(), "TextLabel", "Settings").Parent)
	ctl.run(0.2)
	check(label("PvP  (active)") ~= nil, "autoload: PvP active at start")
	local _, dBtns = rowOf("Default")
	click(dBtns.Load)
	local _, pBtns = rowOf("PvP")
	click(pBtns.Delete)
	check(pBtns.Delete.Text == "Sure?", "delete asks once")
	click(pBtns.Delete)
	ctl.run(0.1)
	check(rowOf("PvP") == nil, "PvP deleted")
	check((ctl.files["RNG_Hub_settings.txt"] or ""):find("autoload=", 1, true) == nil, "deleting the autoload config clears autoload")
	env._G.RNG_HUB_STOP()
	ctl.run(0.5)
	check(ctl.conns == baseConns, "configs: no leaked connections", ctl.conns - baseConns)
	noErrors("configs")

	-- 11. resize grip and instant prompts
	runHub()
	ctl.run(0.5)
	local grip
	for _, d in ipairs(hubGui():GetDescendants()) do
		if d:GetAttribute("ResizeGrip") then
			grip = d
		end
	end
	local w0 = win().Size.X.Offset
	local h0 = win().Size.Y.Offset
	grip.InputBegan:Fire({ UserInputType = E.UserInputType.MouseButton1, Position = env.Vector2.new(500, 500) })
	ctl.UIS.InputChanged:Fire({ UserInputType = E.UserInputType.MouseMovement, Position = env.Vector2.new(600, 550) })
	ctl.UIS.InputEnded:Fire({ UserInputType = E.UserInputType.MouseButton1 })
	ctl.run(0.1)
	check(win().Size.X.Offset == w0 + 100 and win().Size.Y.Offset == h0 + 50, "corner grip resizes the window", ("%dx%d"):format(win().Size.X.Offset, win().Size.Y.Offset))
	check((ctl.files["RNG_Hub_settings.txt"] or ""):find(("winW=%d"):format(w0 + 100), 1, true) ~= nil, "new size saved")
	grip.InputBegan:Fire({ UserInputType = E.UserInputType.MouseButton1, Position = env.Vector2.new(500, 500) })
	ctl.UIS.InputChanged:Fire({ UserInputType = E.UserInputType.MouseMovement, Position = env.Vector2.new(-900, -900) })
	ctl.UIS.InputEnded:Fire({ UserInputType = E.UserInputType.MouseButton1 })
	ctl.run(0.1)
	check(win().Size.X.Offset == 520 and win().Size.Y.Offset == 360, "resize stops at the minimum size")
	click(find(hubGui(), "TextButton", "–"))
	check(grip.Visible == false, "grip hidden while minimized")
	click(find(hubGui(), "TextButton", "+"))
	runHub()
	ctl.run(0.5)
	check(win().Size.X.Offset == 520, "window size restored after rerun")

	local prompt = ctl.new("ProximityPrompt", env.workspace)
	prompt.HoldDuration = 2
	ctl.promptService.PromptShown:Fire(prompt)
	ctl.run(0.1)
	check(prompt.HoldDuration == 2, "prompts untouched while the toggle is off")
	click(find(hubGui(), "TextLabel", "Utility").Parent)
	ctl.run(0.2)
	click(toggleRow("Instant prompts"))
	ctl.promptService.PromptShown:Fire(prompt)
	ctl.run(0.1)
	check(prompt.HoldDuration == 0, "shown prompt becomes instant")
	prompt.HoldDuration = 1.5
	ctl.run(0.1)
	check(prompt.HoldDuration == 0, "game resetting the hold time is undone")
	check(find(hubGui(), "TextLabel", "On · prompts made instant this session: 1") ~= nil, "utility status counts prompts")
	click(toggleRow("Instant prompts"))
	ctl.run(0.1)
	check(prompt.HoldDuration == 1.5, "turning off restores the game's hold time", prompt.HoldDuration)
	prompt.HoldDuration = 3
	ctl.run(0.1)
	check(prompt.HoldDuration == 3, "no longer interfering after off")
	click(toggleRow("Instant prompts"))
	ctl.promptService.PromptShown:Fire(prompt)
	ctl.run(0.1)
	env._G.RNG_HUB_STOP()
	ctl.run(0.5)
	check(prompt.HoldDuration == 3, "closing the hub restores hold times too", prompt.HoldDuration)
	check(ctl.conns == baseConns, "prompts/grip: no leaked connections", ctl.conns - baseConns)
	noErrors("grip and prompts")

	-- 12. Session tab: anti-AFK, auto-reconnect, auto-execute (no autoexec file)
	runHub()
	ctl.run(0.5)
	click(find(hubGui(), "TextLabel", "Session").Parent)
	ctl.run(0.2)
	ctl.player.Idled:Fire(120)
	ctl.run(0.1)
	check(ctl.afkClicks == 0, "anti-AFK off: no input sent")
	click(toggleRow("Anti-AFK"))
	ctl.player.Idled:Fire(120)
	ctl.run(0.3)
	check(ctl.afkCaptures == 1 and ctl.afkClicks == 1, "anti-AFK on: one right-click per Idled", ctl.afkClicks)
	check(find(hubGui(), "TextLabel", "On · idle pulses sent: 1 · last 0s ago") ~= nil, "anti-AFK status shows the pulse")
	click(toggleRow("Anti-AFK"))
	ctl.player.Idled:Fire(120)
	ctl.run(0.1)
	check(ctl.afkClicks == 1, "anti-AFK off again: nothing sent")

	local function showErrorPrompt() -- Roblox names the prompt before parenting it
		local f = ctl.new("Frame")
		f.Name = "ErrorPrompt"
		f.Parent = ctl.promptOverlay
	end
	click(toggleRow("Auto-reconnect"))
	ctl.errorName = "DisconnectLuaKick"
	showErrorPrompt()
	ctl.run(1)
	check(ctl.teleports == 0, "no rejoin after a kick (267)")
	check(find(hubGui(), "TextLabel", "Status: not rejoining after DisconnectLuaKick") ~= nil, "kick reason shown")
	ctl.errorName = "DisconnectConnectionLost"
	showErrorPrompt()
	ctl.run(1)
	check(ctl.teleports == 1, "rejoin after connection lost (277)", ctl.teleports)
	ctl.run(10)
	check(ctl.teleports == 2, "retries 10 s later", ctl.teleports)
	click(toggleRow("Auto-reconnect"))
	ctl.run(60)
	check(ctl.teleports == 2, "turning reconnect off stops the retries", ctl.teleports)
	ctl.errorName = nil

	click(toggleRow("Auto-execute after teleport / rejoin"))
	ctl.run(0.2)
	check(#ctl.queued == 0, "auto-execute waits for Ervi_Hub.luau in the workspace")
	check(find(hubGui(), "TextLabel", "Status: unavailable: Ervi_Hub.luau is not in the executor workspace folder") ~= nil, "missing file explained")
	click(toggleRow("Auto-execute after teleport / rejoin"))
	ctl.files["Ervi_Hub.luau"] = "-- hub"
	click(toggleRow("Auto-execute after teleport / rejoin"))
	ctl.run(0.2)
	check(#ctl.queued == 1 and ctl.queued[1]:find('loadstring(readfile("Ervi_Hub.luau"))()', 1, true) ~= nil, "queued: loads Ervi_Hub.luau after teleport")
	check(ctl.files["Ervi_Hub_autoexec.txt"] == "on", "flag file on")
	click(toggleRow("Auto-execute after teleport / rejoin"))
	check(ctl.files["Ervi_Hub_autoexec.txt"] == "off", "flag file off (queued run will skip)")
	local saved2 = ctl.files["RNG_Hub_settings.txt"] or ""
	check(saved2:find("antiAfk=false", 1, true) and saved2:find("reconnect=false", 1, true) and saved2:find("autoExec=false", 1, true), "session toggles saved in the config")
	env._G.RNG_HUB_STOP()
	ctl.run(0.5)
	check(ctl.conns == baseConns, "session: no leaked connections", ctl.conns - baseConns)
	check(ctl.pendingThreads() == 0, "session: no leaked threads", ctl.pendingThreads())
	noErrors("session")


    -- Candidate all-style M1 HUD, driven through real instance signals and lifecycle.
    for _, child in ipairs(ctl.char:GetChildren()) do
        if child:IsA("Tool") then child:Destroy() end
    end
    ctl.player:SetAttribute("EquippedAttack", "Punch")
    ctl.player:SetAttribute("AttackReadyAt", nil)
    local m1Tool = ctl.new("Tool")
    m1Tool.Name = "Punch"
    m1Tool.Parent = ctl.char
    runHub()
    ctl.run(0.3)
    click(find(hubGui(), "TextLabel", "Combat").Parent)
    click(toggleRow("Show M1 cooldown HUD"))
    ctl.run(0.2)
    local m1hud = ctl.pg:FindFirstChild("RNG_Hub_M1HUD")
    check(m1hud ~= nil, "M1: overlay created")
    check(find(m1hud, "TextLabel", "Punch  M1") ~= nil, "M1: equipped style shown")
    check(find(m1hud, "TextLabel", "UNKNOWN") ~= nil, "M1: absent attribute is UNKNOWN")
    local function cooldownShown()
        for _, d in ipairs(m1hud:GetDescendants()) do
            if d.ClassName == "TextLabel" and d.Text:match("^%d+%.%d%ds$") then return true end
        end
        return false
    end
    ctl.player:SetAttribute("AttackReadyAt", env.workspace:GetServerTimeNow() + 0.7)
    ctl.run(0.2)
    check(cooldownShown(), "M1: Punch observed countdown")
    check(find(m1hud, "TextLabel", "Observed AttackReadyAt; server-time interpretation UNVERIFIED") ~= nil, "M1: uncertainty is visible")
    ctl.run(1)
    check(find(m1hud, "TextLabel", "READY") ~= nil, "M1: deadline transitions to READY")
    ctl.player:SetAttribute("EquippedAttack", "Slap")
    m1Tool:Destroy()
    m1Tool = ctl.new("Tool"); m1Tool.Name = "Slap"; m1Tool.Parent = ctl.char
    ctl.run(0.2)
    check(find(m1hud, "TextLabel", "UNKNOWN") ~= nil, "M1: style switch invalidates stale READY")
    ctl.player:SetAttribute("AttackReadyAt", env.workspace:GetServerTimeNow() + 3.5)
    ctl.run(0.2)
    check(cooldownShown(), "M1: Slap has its own cooldown duration")
    ctl.player:SetAttribute("AttackReadyAt", env.workspace:GetServerTimeNow() + 8)
    ctl.run(0.2)
    check(cooldownShown() and not find(m1hud, "TextLabel", "READY"), "M1: changed cooldown replaces prior deadline")
    m1Tool.Parent = nil
    ctl.run(0.2)
    check(find(m1hud, "TextLabel", "UNEQUIPPED") ~= nil, "M1: removing Tool hides countdown")
    m1Tool.Parent = ctl.char
    ctl.run(0.2)
    check(find(m1hud, "TextLabel", "UNKNOWN") ~= nil, "M1: re-equip waits for fresh attribute")
    ctl.player:SetAttribute("AttackReadyAt", env.workspace:GetServerTimeNow() + 2)
    ctl.run(0.2)
    local hum = ctl.char:FindFirstChildOfClass("Humanoid")
    ctl.set(hum, "Health", 0); hum.Died:Fire()
    ctl.run(0.2)
    check(find(m1hud, "TextLabel", "UNAVAILABLE") ~= nil, "M1: death blocks READY")
    ctl.player.CharacterRemoving:Fire(ctl.char)
    local newChar = ctl.new("Model", env.workspace)
    ctl.new("Humanoid", newChar)
    local newTool = ctl.new("Tool"); newTool.Name = "Slap"; newTool.Parent = newChar
    ctl.set(ctl.player, "Character", newChar)
    ctl.player.CharacterAdded:Fire(newChar)
    ctl.run(0.2)
    check(find(m1hud, "TextLabel", "UNKNOWN") ~= nil, "M1: respawn discards old character sample")
    ctl.player:SetAttribute("AttackReadyAt", env.workspace:GetServerTimeNow() + 1)
    ctl.run(0.2)
    check(cooldownShown(), "M1: delayed post-respawn sample recovers")
    ctl.player:SetAttribute("AttackReadyAt", nil)
    ctl.run(0.2)
    check(find(m1hud, "TextLabel", "UNKNOWN") ~= nil, "M1: removed attribute clears deadline")
    ctl.player:SetAttribute("AttackReadyAt", 99999999)
    ctl.run(0.2)
    check(find(m1hud, "TextLabel", "UNKNOWN") ~= nil, "M1: incompatible clock rejected")
    click(find(m1hud, "TextButton", "Close M1 HUD"))
    check(ctl.pg:FindFirstChild("RNG_Hub_M1HUD") == nil, "M1: close removes HUD only")
    click(toggleRow("Show M1 cooldown HUD"))
    runHub(); ctl.run(0.3)
    check(ctl.pg:FindFirstChild("RNG_Hub_M1HUD") == nil, "M1: rerun removes old overlay")
    env._G.RNG_HUB_STOP(); ctl.run(0.3)
    check(ctl.conns == baseConns, "M1: no leaked connections", ctl.conns - baseConns)
    check(ctl.pendingThreads() == 0, "M1: no leaked threads")
    noErrors("M1 lifecycle")


    -- Exercise the actual emitted loader wrapper with isolated globals, no network.
    local requests, messages = 0, {}
    local loaderEnv = setmetatable({
        _G = {}, game = { PlaceId = 119338513416973, HttpGet = function() requests += 1; error("unexpected HTTP") end },
        task = { wait = function() error("unexpected wait") end },
        warn = function(message) table.insert(messages, message) end,
    }, { __index = getfenv() })
    setfenv(loaderFn, loaderEnv)
    local wrapperOk, wrapperResult = pcall(loaderFn)
    check(wrapperOk and wrapperResult == nil, "loader wrapper: unconfigured template fails closed")
    check(requests == 0 and #messages == 1, "loader wrapper: unconfigured template performs no HTTP")
    loaderEnv.game.PlaceId = 1
    local wrongPlaceOk = pcall(loaderFn)
    check(wrongPlaceOk and requests == 0 and messages[2]:find("Unsupported PlaceId", 1, true), "loader wrapper: unsupported place rejected")
    loaderEnv._G.__ERVI_LOADER = "stale foreign value"
    check(pcall(loaderFn), "loader wrapper: non-table registry recovers")

	print(("%d passed, %d failed"):format(passed, failed))
	if failed > 0 then
		error("smoke test failed")
	end
end
