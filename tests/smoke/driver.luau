-- Headless GUI + lifecycle smoke test. Drives the real hub bundle against MockEngine.
return function(API, makeEngine, hubFn, loaderFn, schema)
	local env, ctl = makeEngine(API)
    -- Existing saved appearance must remain stable despite revised fresh-config defaults.
    ctl.files["RNG_Hub_settings.txt"]="[Default]\nopacity=0.95\nscale=1\ntheme=Bloom\naccent=\ntextColor=Theme\ntextScale=1\nthroughWalls=false\n"
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
	local function nav(label)
        local root=ctl.pg:FindFirstChild("RNG_RollAttacks_Hub")
        if label=="Diagnostics" or label=="Session" then
            for _,d in ipairs(root:GetDescendants()) do if d.ClassName=="TextButton" and d:GetAttribute("NavPage")=="utility" then d.Activated:Fire() end end
            return find(root,"TextButton",label=="Diagnostics" and "Open Diagnostics" or "Session management")
        end
        for _,d in ipairs(root:GetDescendants()) do
            if d.ClassName=="TextButton" and d:GetAttribute("NavPage") and find(d,"TextLabel",label) then return d end
        end
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
	local function sliderBtn(name, sym)
		for _, d in ipairs(find(hubGui(), "TextLabel", name).Parent:GetChildren()) do
			if d.ClassName == "TextButton" and d.Text == sym then
				return d
			end
		end
	end
	-- Settings writes are debounced (App SAVE_DELAY); let the pending write land before reading.
	local function savedSettings()
		ctl.run(0.4)
		return ctl.files["RNG_Hub_settings.txt"] or ""
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

    local exportButton=find(hubGui(),"TextButton","Export diagnostics")
    check(exportButton~=nil,"Diagnostics: export is integrated into the existing hub")
    if exportButton then
        click(nav("Utility"))
        click(exportButton)
        ctl.run(0.2)
        local exported=ctl.files["Ervi_Hub_diagnostics.json"]
        local errorText=""
        for _,n in ipairs(hubGui():GetDescendants()) do if n.ClassName=="TextLabel" and n.Text:find("Diagnostic export failed",1,true) then errorText=n.Text end end
        check(type(exported)=="string" and ctl.jsonEncoded and type(ctl.jsonEncoded.build)=="string" and #ctl.jsonEncoded.controls<=300,"Diagnostics: user action exports bounded runtime data",errorText)
    end
    local liveSearch=hubGui():FindFirstChild("SettingsSearch",true)
    liveSearch.Text="status";liveSearch.Text="status bar opacity";liveSearch.Text="zzzz-no-matching-control-zzzz"
    local liveResults=hubGui():FindFirstChild("ErviSearch",true):FindFirstChildOfClass("ScrollingFrame")
    local staleSearchRows=0
    for _,n in ipairs(liveResults:GetChildren()) do if n.ClassName=="TextButton" then staleSearchRows+=1 end end
    check(staleSearchRows==0,"Search: changing the query destroys obsolete result rows",staleSearchRows)
    liveSearch.Text=""

	-- 2. every tab renders and refreshes
	for _, tab in ipairs({ "Home", "Auto Roll", "Combat", "Styles", "Diagnostics", "Session", "Utility", "Settings" }) do
		click(nav(tab))
		ctl.run(0.5)
		noErrors("tab " .. tab)
	end
	click(nav("Styles"))
	ctl.run(0.2)
	check(find(hubGui(), "TextLabel", "Knockback Stick") ~= nil, "styles list shows game data")
	check(find(hubGui(), "TextLabel", "Secret  (unreleased)") and not find(hubGui(), "TextLabel", "Secret  (unreleased)").Parent.Visible, "unreleased hidden by default")
	check(find(hubGui(), "TextLabel", "Mythic") ~= nil, "RarityName override shown")

	-- 3. Auto Roll: 1/500 target, scripted server results
	click(nav("Auto Roll"))
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

	-- Optional rare-result pause and roll-cap UI were removed at the owner's request.
	click(find(hubGui(), "TextButton", "1/1000"))
	ctl.rollScript = { { "Punch", 3 } }
	click(find(hubGui(), "TextButton", "Start"));ctl.run(2)
	check(ctl.invokes==4,"rare current style no longer requires Continue")
	check(find(hubGui(),"TextLabel","SAFETY OPTIONS")==nil,"optional Safety options removed")
	click(find(hubGui(),"TextButton","Stop"));ctl.run(20)
	check(ctl.invokes==4,"Stop prevents further rolls")
	noErrors("auto roll optional-pause removal")

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

	-- The universal HUD replaces the standalone Cyborg UI.
	check(find(hubGui(), "TextLabel", "Show Cyborg M1 overlay") == nil, "no obsolete Cyborg controls")
	check(ctl.pg:FindFirstChild("RNG_Hub_CombatHUD") == nil, "no duplicate Cyborg HUD")

	-- 5. Diagnostics: capture, copy, redaction
	click(nav("Diagnostics"))
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
	click(hubGui():FindFirstChild("MinimizeButton", true))
	ctl.run(0.2)
	check(ctl.pg:FindFirstChild("Ervi_MinimizedStatus").Enabled,"minimize shows independent status bar")
	click(ctl.pg:FindFirstChild("Ervi_MinimizedStatus"):FindFirstChildOfClass("TextButton"))
	local E = env.Enum
	local function press(key, processed)
		ctl.UIS.InputBegan:Fire({ KeyCode = E.KeyCode[key], UserInputType = E.UserInputType.Keyboard }, processed == true)
		ctl.run(0.1)
	end
	local function win()
		return hubGui():FindFirstChild("ErviWindow")
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
	click(nav("Settings"))
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
 local centered=win().Position
 win().Position=env.UDim2.fromOffset(1,1)
 press("F4");press("F4")
 check(win().Position.X.Offset==centered.X.Offset and win().Position.Y.Offset==centered.Y.Offset,"main window recenters after displaced hide/reopen")
	check(savedSettings():find("toggleKey=F4", 1, true) ~= nil, "key saved to settings file")
	noErrors("rebind")

	-- 6c. opacity slider
	local function near(a, b)
		return type(a) == "number" and math.abs(a - b) < 1e-6
	end
	check(near(win().BackgroundTransparency, 0.05), "default opacity 95%", win().BackgroundTransparency)
	for _ = 1, 3 do
		click(sliderBtn("Menu opacity", "−"))
	end
	ctl.run(0.1)
	check(near(win().BackgroundTransparency, 0.2), "3 steps down -> 80% opacity", win().BackgroundTransparency)
	check(find(hubGui(), "TextBox", "80%") ~= nil, "slider shows 80%")
	local readout = find(hubGui(), "TextBox", "80%")
	readout.Focused:Fire()
	check(readout.Text == "80", "numeric readout edits the shown percent", readout.Text)
	readout.Text = "55"
	readout.FocusLost:Fire(true)
	ctl.run(0.1)
	check(near(win().BackgroundTransparency, 0.45) and readout.Text == "55%", "typed 55 sets 55% opacity", win().BackgroundTransparency)
	readout.Focused:Fire()
	readout.Text = "80"
	readout.FocusLost:Fire(true)
	ctl.run(0.1)
	check(near(win().BackgroundTransparency, 0.2), "typed 80 restores 80% opacity")
	local card = find(hubGui(), "TextLabel", "CONTROLS").Parent
	check(near(card.BackgroundTransparency, 0.2), "cards follow opacity", card.BackgroundTransparency)
	for _ = 1, 20 do
		click(sliderBtn("Menu opacity", "−"))
	end
	ctl.run(0.1)
	check(near(win().BackgroundTransparency, 1), "opacity floor 0%", win().BackgroundTransparency)
	check(find(hubGui(), "TextLabel", "Menu opacity").TextStrokeTransparency < 1, "text outlined at low opacity")
	click(sliderBtn("Menu opacity", "+"))
	for _ = 1, 20 do
		click(sliderBtn("Menu opacity", "+"))
	end
	ctl.run(0.1)
	check(near(win().BackgroundTransparency, 0), "opacity ceiling 100%")
	check(find(hubGui(), "TextLabel", "Menu opacity").TextStrokeTransparency == 1, "outline removed at high opacity")
	for _ = 1, 4 do
		click(sliderBtn("Menu opacity", "−"))
	end
	ctl.run(0.1)
	check(savedSettings():find("opacity=0.80", 1, true) ~= nil, "opacity saved", ctl.files["RNG_Hub_settings.txt"])
	noErrors("opacity")

	-- 6d. appearance: design, accent, font, text color/size/outline/transparency
	local rgb = env.Color3.fromRGB
	local function hex(c)
		return c and c:ToHex()
	end
	local function label(text)
		return find(hubGui(), "TextLabel", text)
	end

	local probe = "Show / hide menu key" -- a fontMedium, body-size label
	click(find(hubGui(), "TextButton", "Ocean"))
	ctl.run(0.1)
	check(hex(win().BackgroundColor3) == hex(rgb(9, 17, 28)), "design Ocean: window repainted", hex(win().BackgroundColor3))
	check(hex(label("CONTROLS").Parent.BackgroundColor3) == hex(rgb(18, 33, 52)), "design Ocean: cards repainted")
	check(hex(label(probe).TextColor3) == hex(rgb(230, 242, 255)), "design Ocean: text repainted")
	check(hex(find(hubGui(), "TextButton", "Apply").BackgroundColor3) == hex(rgb(62, 168, 240)), "design Ocean: default accent Sky")
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
	check(hex(find(hubGui(), "TextButton", "Apply").BackgroundColor3) == hex(rgb(240, 98, 142)), "accent Rose applied")
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
	click(nav("Styles"))
	ctl.run(0.2)
	local styleName = find(hubGui(), "TextLabel", "Knockback Stick")
	check(styleName and styleName.TextSize == 14, "text built later is scaled too (12 -> 14)", styleName and styleName.TextSize)
	click(nav("Combat"))
	click(toggleRow("Show M1 cooldown HUD")) -- overlay is built now, after the size change
	ctl.run(0.2)
	local hudTitle = find(ctl.pg:FindFirstChild("RNG_Hub_M1HUD"), "TextLabel", "Punch  M1")
	check(hudTitle and hudTitle.TextSize == 12, "newly built HUD uses compact resize-responsive title", hudTitle and hudTitle.TextSize)
	click(toggleRow("Show M1 cooldown HUD"))
	click(nav("Settings"))
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
	local saved = savedSettings()
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
		if t.ClassName == "TextBox" and t.PlaceholderText == "#RRGGBB" and t:GetAttribute("AppearanceHex") then
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
	check(hex(find(hubGui(), "TextButton", "Apply").BackgroundColor3) == hex(rgb(255, 0, 0)), "custom accent applied from the circle")
	check(customs[1].BackgroundColor3 and hex(customs[1].BackgroundColor3) == hex(rgb(255, 0, 0)), "accent Custom button shows as selected")
	check(savedSettings():find("accent=#FF0000", 1, true) ~= nil, "custom accent saved")
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
	check(hex(win().BackgroundColor3) == hex(rgb(14, 15, 20)), "reset appearance: owner Midnight default")
	check(label(probe).TextSize == 18 and near(label(probe).TextTransparency, 0) and label(probe).Font == E.Font.GothamMedium, "reset appearance: text back to normal")
	noErrors("appearance")

	-- 7. close via X: full cleanup
	click(hubGui():FindFirstChild("CloseButton", true))
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
	check(math.abs(win().BackgroundTransparency - 0.2) < 1e-6, "saved opacity restored after rerun")
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

	-- 9b. an executor attached twice runs the hub in two contexts: separate _G, shared Instances
	-- (seen live 2026-11-14: two status pills, two M1 HUDs, two autosave writers).
	runHub();ctl.run(0.5)
	local contextB = setmetatable({ _G = {} }, { __index = env })
	setfenv(hubFn, contextB)
	ctl.task.spawn(function() hubFn() end)
	setfenv(hubFn, env)
	ctl.run(0.5)
	local function countGui(name)
		local n = 0
		for _, c in ipairs(ctl.pg:GetChildren()) do if c.Name == name then n += 1 end end
		return n
	end
	check(countGui("RNG_RollAttacks_Hub") == 1 and countGui("Ervi_MinimizedStatus") == 1 and countGui("ErviHubStopSignal") == 1, "second context: exactly one hub, status pill and stop signal",
		("%d/%d/%d"):format(countGui("RNG_RollAttacks_Hub"), countGui("Ervi_MinimizedStatus"), countGui("ErviHubStopSignal")))
	check(env._G.RNG_HUB_STOP == nil and type(contextB._G.RNG_HUB_STOP) == "function", "second context: first context's hub was stopped through the shared signal")
	contextB._G.RNG_HUB_STOP();ctl.run(0.5)
	check(countGui("ErviHubStopSignal") == 0 and countGui("Ervi_MinimizedStatus") == 0, "second context: unload removes the stop signal and GUIs")
	check(ctl.conns == baseConns and ctl.pendingThreads() == 0, "second context: no orphaned connections or threads", ctl.conns - baseConns)
	noErrors("second context")

	-- 10. autosave: no Config page; the effective profile saves itself (debounced, flushed on
	-- unload); other named profiles and autoload bindings are preserved; one-time backup.
	ctl.requireDelay = nil
	if env._G.RNG_HUB_STOP then env._G.RNG_HUB_STOP() end
	ctl.run(0.5)
	local before10 = ctl.files["RNG_Hub_settings.txt"]
	local legacy = "autoload=PvP\n[Default]\nopacity=0.80\n[PvP]\nopacity=0.70\ntheme=Ocean\n[Other]\nopacity=0.40\n"
	ctl.files["RNG_Hub_settings.txt"] = legacy
	ctl.files["RNG_Hub_settings.pre-autosave-backup.txt"] = nil
	runHub()
	ctl.run(0.5)
	check(near(win().BackgroundTransparency, 0.3), "autosave: effective autoload profile (PvP 70%) is active", win().BackgroundTransparency)
	check(nav("Config") == nil and hubGui():FindFirstChild("ErviPage_config", true) == nil, "autosave: Config page and slot manager removed")
	check(ctl.files["RNG_Hub_settings.pre-autosave-backup.txt"] == legacy, "autosave: original settings file backed up before the first write")
	click(nav("Settings"))
	ctl.run(0.2)
	local writesBefore = ctl.writes or 0
	for _ = 1, 4 do
		click(sliderBtn("Menu opacity", "−")) -- 70% -> 50%, four changes inside the debounce window
	end
	check((ctl.files["RNG_Hub_settings.txt"] or ""):match("%[PvP%][^%[]*opacity=0%.70") ~= nil, "autosave: rapid changes are debounced, not written per step")
	ctl.run(0.5)
	local saved10 = ctl.files["RNG_Hub_settings.txt"] or ""
	check(saved10:match("%[PvP%][^%[]*opacity=0%.50") ~= nil, "autosave: change persisted to the active profile", saved10)
	check((ctl.writes or 0) - writesBefore == 1, "autosave: one coalesced write for four slider steps", (ctl.writes or 0) - writesBefore)
	check(saved10:match("%[Other%][^%[]*opacity=0%.40") ~= nil and saved10:match("%[Default%][^%[]*opacity=0%.80") ~= nil, "autosave: other named profiles left untouched")
	check(saved10:find("autoload=PvP", 1, true) ~= nil, "autosave: legacy autoload binding kept for older builds")
	check(label("Saved automatically") ~= nil, "autosave: save status shown in the sidebar")
	click(sliderBtn("Menu opacity", "+")) -- 55%, then unload before the debounce fires
	env._G.RNG_HUB_STOP()
	check((ctl.files["RNG_Hub_settings.txt"] or ""):match("%[PvP%][^%[]*opacity=0%.55") ~= nil, "autosave: pending change flushed on unload")
	ctl.run(0.5)
	ctl.files["RNG_Hub_settings.txt"] = "[Default]\nopacity=0.90\n"
	runHub()
	ctl.run(0.5)
	check(ctl.files["RNG_Hub_settings.pre-autosave-backup.txt"] == legacy, "autosave: an existing backup is never overwritten")
	ctl.files["RNG_Hub_settings.txt"] = legacy:sub(#"autoload=PvP" + 2)
	runHub()
	ctl.run(0.5)
	check(near(win().BackgroundTransparency, 0.2), "autosave: Default profile is active without an autoload binding", win().BackgroundTransparency)
	env._G.RNG_HUB_STOP()
	ctl.run(0.5)
	check(ctl.conns == baseConns, "autosave: no leaked connections", ctl.conns - baseConns)
	noErrors("autosave")
	ctl.files["RNG_Hub_settings.txt"] = before10 -- later sections continue from the earlier preferences

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
    local resizeScale=win():FindFirstChildOfClass("UIScale").Scale
    local resizedW=math.min(1100,math.floor(w0+100/resizeScale));local resizedH=math.min(820,math.floor(h0+50/resizeScale))
	grip.InputBegan:Fire({ UserInputType = E.UserInputType.MouseButton1, Position = env.Vector2.new(500, 500) })
	ctl.UIS.InputChanged:Fire({ UserInputType = E.UserInputType.MouseMovement, Position = env.Vector2.new(600, 550) })
	ctl.UIS.InputEnded:Fire({ UserInputType = E.UserInputType.MouseButton1 })
	ctl.run(0.1)
	check(win().Size.X.Offset == resizedW and win().Size.Y.Offset == resizedH, "corner grip resizes the window", ("%dx%d"):format(win().Size.X.Offset, win().Size.Y.Offset))
	check(savedSettings():find(("winW=%d"):format(resizedW), 1, true) ~= nil, "new size saved")
	grip.InputBegan:Fire({ UserInputType = E.UserInputType.MouseButton1, Position = env.Vector2.new(500, 500) })
	ctl.UIS.InputChanged:Fire({ UserInputType = E.UserInputType.MouseMovement, Position = env.Vector2.new(-900, -900) })
	ctl.UIS.InputEnded:Fire({ UserInputType = E.UserInputType.MouseButton1 })
	ctl.run(0.1)
	check(win().Size.X.Offset == 520 and win().Size.Y.Offset == 360, "resize stops at the minimum size")
	click(hubGui():FindFirstChild("MinimizeButton", true))
	check(grip.Visible == false, "grip hidden while minimized")
	click(ctl.pg:FindFirstChild("Ervi_MinimizedStatus"):FindFirstChildOfClass("TextButton"))
	runHub()
	ctl.run(0.5)
	check(win().Size.X.Offset == 520, "window size restored after rerun")

	local prompt = ctl.new("ProximityPrompt", env.workspace)
	prompt.HoldDuration = 2
	ctl.promptService.PromptShown:Fire(prompt)
	ctl.run(0.1)
	check(prompt.HoldDuration == 2, "prompts untouched while the toggle is off")
	click(nav("Utility"))
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
	click(nav("Session"))
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
	local saved2 = savedSettings()
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
    click(nav("Combat"))
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
    check(find(m1hud, "TextButton", "Close M1 HUD") == nil, "M1: no standalone Close button")
    click(toggleRow("Show M1 cooldown HUD"))
    check(ctl.pg:FindFirstChild("RNG_Hub_M1HUD") == nil, "M1: menu disables HUD")
    click(toggleRow("Show M1 cooldown HUD"))
    runHub(); ctl.run(0.3)
    check(ctl.pg:FindFirstChild("RNG_Hub_M1HUD") ~= nil and ctl.pg:FindFirstChild("RNG_Hub_M1HUD") ~= m1hud, "M1: rerun restores one persisted overlay")
    env._G.RNG_HUB_STOP(); ctl.run(0.3)
    check(ctl.conns == baseConns, "M1: no leaked connections", ctl.conns - baseConns)
    check(ctl.pendingThreads() == 0, "M1: no leaked threads")
    noErrors("M1 lifecycle")


    -- New persistent HUD geometry and integrated safe reference / manual targets.
    runHub(); ctl.run(0.3)
    click(nav("Combat"))
    local layoutHud=ctl.pg:FindFirstChild("RNG_Hub_M1HUD")
    if not layoutHud then click(toggleRow("Show M1 cooldown HUD")); layoutHud=ctl.pg:FindFirstChild("RNG_Hub_M1HUD") end
    local hudFrame=layoutHud:FindFirstChildOfClass("Frame")
    local hudGrip
    for _,child in ipairs(hudFrame:GetChildren()) do if child:GetAttribute("ResizeGrip") then hudGrip=child end end
    check(hudGrip~=nil,"M1 layout: corner resize handle")
    local hudTitle=find(layoutHud,"TextLabel","Slap  M1")
    local initialW=hudFrame.Size.X.Offset
    local function gesture(handle,dx,dy)
        handle.InputBegan:Fire({UserInputType=env.Enum.UserInputType.MouseButton1,Position=env.Vector2.new(0,0)})
        ctl.UIS.InputChanged:Fire({UserInputType=env.Enum.UserInputType.MouseMovement,Position=env.Vector2.new(dx,dy)})
        ctl.UIS.InputEnded:Fire({UserInputType=env.Enum.UserInputType.MouseButton1})
    end
    local countdown=layoutHud:FindFirstChild("M1Countdown",true)
    local smallText=countdown.TextSize
    gesture(hudGrip,80,60)
    check(countdown.TextSize>smallText,"M1 layout: enlarging the HUD enlarges text")
    check(layoutHud:FindFirstChild("M1CooldownBar",true)~=nil,"M1 layout: cooldown progress bar exists")
    check(hudFrame.Size.X.Offset==initialW+80,"M1 layout: corner gesture resizes")
    gesture(hudTitle,-10000,-10000)
    check(hudFrame.Position.X.Offset==0 and hudFrame.Position.Y.Offset==0,"M1 layout: drag clamped on screen")
    local layoutSaved=savedSettings()
    check(layoutSaved:find("m1X=0.000000",1,true) and layoutSaved:find("m1W=410.00",1,true),"M1 layout: dimensions and position saved")
    local cam=env.workspace.CurrentCamera
    ctl.set(cam,"ViewportSize",env.Vector2.new(320,240))
    check(hudFrame.Size.X.Offset<=304 and hudFrame.Size.Y.Offset<=192,"M1 layout: viewport shrink keeps HUD visible")
    ctl.set(cam,"ViewportSize",env.Vector2.new(1920,1080))
    check(hudFrame.Size.X.Offset==410,"M1 layout: viewport enlargement restores preference")
    local content=hudFrame:FindFirstChildOfClass("ScrollingFrame")
    check(content and content.Size.Y.Offset==-62,"M1 layout: scrolling content reserves title and grip space")

    -- Fixed Safe Zone with scoped gravity hold; default key NONE.
    local activeChar=ctl.player.Character
    local activeHum=activeChar:FindFirstChildOfClass("Humanoid")
    local activeRoot=ctl.new("Part",activeChar); activeRoot.Name="HumanoidRootPart"
    activeRoot.CFrame=ctl.cframe(10,20,30,0,0,1,0,1,0,-1,0,0)
    local originalFrame=activeRoot.CFrame
    activeRoot.AssemblyLinearVelocity=env.Vector3.new(0,-100,0)
    activeRoot.AssemblyAngularVelocity=env.Vector3.new(0,5,0)
    click(nav("Safe Zone"))
    check(find(hubGui(),"TextButton","Set Current Position as Safe Zone")==nil and find(hubGui(),"TextButton","Clear Safe Zone")==nil,"Safe Zone: setup controls removed")
    check((ctl.pivotCalls or 0)==0,"Safe Zone: loading does not move character")
    click(toggleRow("Enable Safe Zone")); ctl.run(0.2)
    local moved={activeRoot.CFrame:GetComponents()}
    check(math.abs(moved[1]-278.78)<1e-6 and math.abs(moved[2]+16.3)<1e-6 and math.abs(moved[3]-7.82)<1e-6,"Safe Zone: activation moves root to fixed coordinates", table.concat(moved,","))
    check(moved[4]==0 and moved[6]==1 and moved[10]==-1,"Safe Zone: facing preserved")
    check(activeRoot.Anchored==true,"Safe Zone hold: root anchored against gravity")
    check(activeRoot.AssemblyLinearVelocity.Y==0 and activeRoot.AssemblyAngularVelocity.Y==0,"Safe Zone hold: falling and spin velocities cleared")
    local moves=ctl.pivotCalls or 0
    ctl.run(2)
    check(ctl.pivotCalls==moves,"Safe Zone hold: no repeated teleports or polling loop")
    activeRoot.CFrame=originalFrame; ctl.run(1)
    check(activeRoot.CFrame==originalFrame and ctl.pivotCalls==moves,"Safe Zone: does not fight server correction")
    check(activeRoot.Anchored==false,"Safe Zone hold: external position update releases physics")
    click(toggleRow("Enable Safe Zone")); moves=ctl.pivotCalls
    click(toggleRow("Enable Safe Zone"))
    check(ctl.pivotCalls==moves+1,"Safe Zone: OFF makes one return move")
    moves=ctl.pivotCalls
    check(activeRoot.CFrame==originalFrame,"Safe Zone: OFF returns exact activation orientation and position")
    check(activeRoot.Anchored==false and activeRoot.AssemblyLinearVelocity.Y==0,"Safe Zone hold: OFF restores movement without old falling velocity")
    activeRoot.CFrame=originalFrame
    ctl.set(activeHum,"Health",0)
    click(toggleRow("Enable Safe Zone")); ctl.run(0.2)
    check(ctl.pivotCalls==moves,"Safe Zone: dead character rejected without deferred move")
    ctl.set(activeHum,"Health",100)
    ctl.set(env.game,"PlaceId",1)
    click(toggleRow("Enable Safe Zone")); ctl.run(0.2)
    check(ctl.pivotCalls==moves,"Safe Zone: wrong place rejected")
    ctl.set(env.game,"PlaceId",119338513416973)
    ctl.rejectPivot=true
    click(toggleRow("Enable Safe Zone")); ctl.run(0.2)
    check(ctl.pivotCalls==moves+1 and activeRoot.CFrame==originalFrame,"Safe Zone: failed local move is not retried")
    check(activeRoot.Anchored==false,"Safe Zone hold: failed move rolls back anchoring")
    ctl.rejectPivot=false
    activeRoot.Anchored=true
    click(toggleRow("Enable Safe Zone")); click(toggleRow("Enable Safe Zone"))
    check(activeRoot.Anchored==true,"Safe Zone hold: preserves a pre-existing game anchor")
    activeRoot.Anchored=false
    click(toggleRow("Enable Safe Zone"))
    ctl.set(activeHum,"Health",0); activeHum.Died:Fire()
    check(activeRoot.Anchored==false,"Safe Zone hold: death releases physics immediately")
    ctl.set(activeHum,"Health",100)
    click(toggleRow("Enable Safe Zone")); activeRoot.Anchored=false
    check(activeRoot.Anchored==false,"Safe Zone hold: external unanchor is not counteracted")
    local afterUnanchor=ctl.pivotCalls
    click(toggleRow("Enable Safe Zone"))
    check(ctl.pivotCalls==afterUnanchor+1,"Safe Zone hold: external unanchor resets toggle OFF")
    click(toggleRow("Enable Safe Zone"))
    click(nav("Settings"))
    local function safeKeyButton(page)
        for _,d in ipairs(hubGui():FindFirstChild("ErviPage_"..page,true):GetDescendants()) do
            if d:GetAttribute("SettingKey")=="safeZoneKey" then return d end
        end
    end
    check(safeKeyButton("settings").Size.X.Scale==1,"Safe Zone binding: full-width control avoids clipping")
    check(safeKeyButton("safe")~=nil,"Safe Zone binding: present in its own tab")
    check(safeKeyButton("settings").Text=="NONE","Safe Zone key: default NONE")
    click(safeKeyButton("settings")); press("F4")
    check(safeKeyButton("settings").Text=="NONE","Safe Zone key: GUI key conflict rejected")
    click(safeKeyButton("settings")); press("F8",true)
    check(savedSettings():find("safeZoneKey=F8",1,true),"Safe Zone key: rebinding persisted")
    click(find(hubGui(),"TextButton","F4")); press("F8",true)
    check(find(hubGui(),"TextButton","F4")~=nil,"GUI key: Safe Zone key conflict rejected")
    moves=ctl.pivotCalls
    win().Visible=false; ctl.focusedTextBox={}; press("F8",true)
    check(win().Visible==false and ctl.pivotCalls==moves,"Safe Zone key: ignored while typing")
    ctl.focusedTextBox=nil; press("F8",true); ctl.run(0.2)
    check(ctl.pivotCalls==moves+1 and win().Visible==false,"Safe Zone key: moves once without opening menu")
    check(activeRoot.Anchored==true,"Safe Zone hold: key enables holding")
    press("F8",true); ctl.run(0.2)
    check(ctl.pivotCalls==moves+2,"Safe Zone key: second press returns to activation origin")
    check(activeRoot.Anchored==false,"Safe Zone hold: key releases holding")
    win().Visible=true
    click(safeKeyButton("settings")); press("Backspace")
    check(safeKeyButton("settings").Text=="NONE" and savedSettings():find("safeZoneKey=NONE",1,true),"Safe Zone key: clearing saves NONE")
    moves=ctl.pivotCalls; press("F8",true)
    check(ctl.pivotCalls==moves,"Safe Zone key: unbound key no longer activates")

    click(nav("Safe Zone"))
    click(toggleRow("Enable Safe Zone")); ctl.run(0.2)
    moves=ctl.pivotCalls
    ctl.player.CharacterRemoving:Fire(activeChar)
    ctl.player.CharacterAdded:Fire(activeChar); ctl.run(0.2)
    check(ctl.pivotCalls==moves,"Safe Zone: character replacement does not repeat a move")
    check(activeRoot.Anchored==false,"Safe Zone hold: character removal releases old root")
    click(toggleRow("Enable Safe Zone")); ctl.run(0.2)
    check(ctl.pivotCalls==moves+1,"Safe Zone: character replacement resets toggle OFF")
    click(toggleRow("Enable Safe Zone"))

    click(toggleRow("Enable Safe Zone"))
    env._G.RNG_HUB_STOP(); ctl.run(0.2)
    check(activeRoot.Anchored==false,"Safe Zone hold: unloading restores root physics")
    check(ctl.conns==baseConns,"Safe Zone hold: unloading disconnects hold listeners")
    runHub(); ctl.run(0.3)
    click(nav("Safe Zone"))
    click(toggleRow("Enable Safe Zone"))
    runHub(); ctl.run(0.3)
    check(activeRoot.Anchored==false,"Safe Zone hold: rerunning releases old hold")

    click(nav("Combat"))
    click(toggleRow("Enable target selection")); ctl.run(0.3)
    check(find(hubGui(),"TextLabel","Waiting for an eligible player")~=nil,"Targets: fixed safe reference requires no setup")
    local enemy=ctl.new("Player",env.game:GetService("Players")); enemy.Name="ManualTarget"; ctl.set(enemy,"UserId",2)
    local enemyChar=ctl.new("Model",env.workspace)
    local enemyHum=ctl.new("Humanoid",enemyChar); ctl.set(enemyHum,"Health",25)
    ctl.set(enemy,"Character",enemyChar)
    click(nav("Combat")); ctl.run(0.4)
    check(find(hubGui(),"TextLabel","ManualTarget")~=nil,"Targets: health threshold selects eligible player")
    check(find(hubGui(),"TextLabel","25.0%")~=nil,"Targets: correct HP percentage")
    local hpInput
    for _,d in ipairs(hubGui():GetDescendants()) do
        if d.ClassName=="TextBox" and d.PlaceholderText=="HP threshold: 1–100" then hpInput=d end
    end
    hpInput.Text="20"; hpInput.FocusLost:Fire(true); ctl.run(0.4)
    check(find(hubGui(),"TextLabel","Waiting for an eligible player")~=nil,"Targets: numeric threshold applies immediately")
    hpInput.Text="30"; hpInput.FocusLost:Fire(true); ctl.run(0.4)
    ctl.set(enemyHum,"MaxHealth",0); ctl.run(0.4)
    check(find(hubGui(),"TextLabel","Waiting for an eligible player")~=nil,"Targets: invalid maximum health ignored")
    ctl.set(enemyHum,"MaxHealth",100); ctl.run(0.4)
    ctl.set(enemyHum,"Health",50); ctl.run(0.4)
    check(find(hubGui(),"TextLabel","Waiting for an eligible player")~=nil,"Targets: health recovery invalidates target")
    ctl.set(enemyHum,"Health",25); ctl.run(0.4)
    ctl.set(enemyHum,"Health",0); ctl.run(0.4)
    check(find(hubGui(),"TextLabel","Waiting for an eligible player")~=nil,"Targets: death clears target")
    local respawnChar=ctl.new("Model",env.workspace)
    local respawnHum=ctl.new("Humanoid",respawnChar)
    ctl.set(enemy,"Character",respawnChar); ctl.run(0.4)
    check(find(hubGui(),"TextLabel","Waiting for an eligible player")~=nil,"Targets: healthy respawn does not retain target")
    ctl.set(respawnHum,"Health",20); ctl.run(0.4)
    check(find(hubGui(),"TextLabel","ManualTarget")~=nil,"Targets: new eligible character can be selected")
    enemy.Parent=nil; ctl.run(0.4)
    check(find(hubGui(),"TextLabel","Waiting for an eligible player")~=nil,"Targets: leaving server clears target")
    enemy.Parent=env.game:GetService("Players"); ctl.run(0.4)
    ctl.set(activeHum,"Health",0); activeHum.Died:Fire(); ctl.run(0.4)
    check(find(hubGui(),"TextLabel","Waiting for your character")~=nil,"Targets: local death suspends selection")
    ctl.set(activeHum,"Health",100); ctl.run(0.4)
    check(find(hubGui(),"TextLabel","ManualTarget")~=nil,"Targets: local recovery resumes observation")
    click(toggleRow("Auto M1 (request only)")); ctl.run(0.2)
    check(find(hubGui(),"TextLabel","ON requested · unsupported · no attacks sent")~=nil,"Auto M1: unsupported request is explicit")
    click(toggleRow("Enable target selection")); ctl.run(0.3)
    check(find(hubGui(),"TextLabel","Disabled")~=nil,"Targets: menu disable stops selection")

    -- One Auto Roll worker survives death and resumes through ordinary readiness.
    click(nav("Auto Roll"))
    click(toggleRow("Resume Auto Roll After Death"))
    ctl.player:SetAttribute("EquippedAttack","Punch")
    ctl.player:SetAttribute("RollReadyAt",0)
    ctl.player:SetAttribute("InFFA",true)
    ctl.set(activeHum,"Health",0); activeHum.Died:Fire()
    local beforeRequests=ctl.invokes
    ctl.rollScript={{"Knockback Stick",750}}
    click(find(hubGui(),"TextButton","1/500"))
    click(find(hubGui(),"TextButton","Start")); ctl.run(2)
    check(ctl.invokes==beforeRequests,"Auto Roll recovery: no request while dead")
    check(find(hubGui(),"TextLabel","WAITINGRESPAWN")~=nil,"Auto Roll recovery: waiting status")
    local revived=ctl.new("Model",env.workspace)
    ctl.new("Humanoid",revived)
    ctl.player.CharacterRemoving:Fire(activeChar)
    ctl.set(ctl.player,"Character",revived); ctl.player.CharacterAdded:Fire(revived)
    ctl.run(2)
    check(ctl.invokes==beforeRequests+1,"Auto Roll recovery: exactly one request after respawn")
    check(find(hubGui(),"TextLabel","FOUND")~=nil,"Auto Roll recovery: selected rarity target retained")
    ctl.run(12)
    check(ctl.invokes==beforeRequests+1,"Auto Roll recovery: zero further requests after qualifying result")
    local persisted=savedSettings()
    check(persisted:find("resumeAfterDeath=true",1,true) and persisted:find("autoM1Requested=true",1,true),"Recovery and Auto M1 preference persist")
    env._G.RNG_HUB_STOP(); ctl.run(0.3)
    check(ctl.conns==baseConns and ctl.pendingThreads()==0,"Integrated features: unload leaves no listeners or workers",ctl.conns-baseConns)
    noErrors("integrated features")

    -- 3.0 screenshot expansion: navigation, registry search, world/camera, overlays.
    runHub();ctl.run(0.4)
    for _,tab in ipairs({"Auto Roll","Styles","Home","Combat","Visuals","Player","World","Safe Zone","Teleports","Utility","Settings"}) do
        click(nav(tab));ctl.run(0.15)
        check(nav(tab)~=nil,"3.0 navigation: "..tab)
    end
    for _,spec in ipairs(schema) do
        local page=hubGui():FindFirstChild("ErviPage_"..spec.page,true)
        local control
        if page then for _,d in ipairs(page:GetDescendants()) do if d:GetAttribute("SettingKey")==spec.key then control=d end end end
        check(control~=nil,"Catalog setting mounted: "..spec.key)
    end
    -- Unsupported movement remains disabled in the real target-place integration.
    local flyRow=hubGui():FindFirstChild("Setting_flyEnabled",true)
    local noclipRow=hubGui():FindFirstChild("Setting_noclipEnabled",true)
    check(flyRow:GetAttribute("Disabled") and noclipRow:GetAttribute("Disabled"),"Movement: target game lacks authorized movement; toggles disabled")
    click(flyRow);click(noclipRow)
    check(not flyRow:GetAttribute("Value") and not noclipRow:GetAttribute("Value"),"Movement: disabled controls cannot create fake active state")
    press("L");press("N");ctl.run(0.1)
    check(not flyRow:GetAttribute("Value") and not noclipRow:GetAttribute("Value"),"Movement: unsupported keys never modify physics")
    -- A correctly initialized PlayerAdded fixture verifies cached tracker rows.
    local trackedPlayer=ctl.new("Player");trackedPlayer.Name="TrackerSample";ctl.set(trackedPlayer,"UserId",901);trackedPlayer.DisplayName="Tracker Display"
    local trackedCharacter=ctl.new("Model",env.workspace)
    local trackedHumanoid=ctl.new("Humanoid",trackedCharacter);trackedHumanoid.Health=75
    local trackedRoot=ctl.new("Part",trackedCharacter);trackedRoot.Name="HumanoidRootPart";trackedRoot.CFrame=env.CFrame.new(10,0,0)
    ctl.set(trackedPlayer,"Character",trackedCharacter);trackedPlayer.Parent=env.game:GetService("Players")
    click(nav("Player"));ctl.run(0.3)
    local trackerRow=hubGui():FindFirstChild("TrackerRow_901",true)
    check(trackerRow and find(trackerRow,"TextLabel","Tracker Display  @TrackerSample")~=nil,"Tracker: joining player creates named cached row")
    local visibilityWrites=0
    local visibilityConnection=trackerRow:GetPropertyChangedSignal("Visible"):Connect(function() visibilityWrites+=1 end)
    ctl.run(1);visibilityConnection:Disconnect()
    check(visibilityWrites==0,"Tracker: ordinary refresh never hides unchanged rows or cancels a pressed button")
    local trackerHealth=trackerRow and trackerRow:FindFirstChild("TrackerHealth")
    check(trackerHealth and near(trackerHealth.Size.X.Scale,0.75),"Tracker: health fraction is accurate")
    click(trackerRow);ctl.run(0.3)
    check(find(hubGui(),"TextLabel","Selected: Tracker Display (@TrackerSample)")~=nil,"Tracker: row selection updates embedded details")
    trackedHumanoid.Health=0;ctl.run(0.3)
    check(trackerRow==hubGui():FindFirstChild("TrackerRow_901",true) and trackerHealth.Size.X.Scale==0,"Tracker: health/death updates reuse the existing row")
    local filter=hubGui():FindFirstChild("TrackerFilter",true);filter.Text="no-such-player";ctl.run(0.1)
    check(not trackerRow.Visible,"Tracker: name filter hides unmatched rows")
    filter.Text="tracker";ctl.run(0.1);check(trackerRow.Visible,"Tracker: case-insensitive filter restores row")
    local playerTeleport=hubGui():FindFirstChild("TrackerTeleport",true)
    check(playerTeleport:GetAttribute("Disabled"),"Tracker: unsupported player teleport is disabled")
    trackedPlayer:Destroy();ctl.run(0.3)
    check(hubGui():FindFirstChild("TrackerRow_901",true)==nil,"Tracker: player removal destroys its cached row")
    -- Slider input and shared visual preferences: real mounted controls, mock engine.
    click(nav("Player"))
    local speedRow=find(hubGui(),"TextLabel","Walk Speed").Parent
    local track=speedRow:FindFirstChild("SliderTrack")
    ctl.set(track:FindFirstChildOfClass("Frame"),"AbsoluteSize",env.Vector2.new(200,6))
    ctl.set(track:FindFirstChildOfClass("Frame"),"AbsolutePosition",env.Vector2.new(100,100))
    track.InputBegan:Fire({UserInputType=E.UserInputType.MouseButton1,Position=env.Vector2.new(999,100)})
    ctl.UIS.InputEnded:Fire({UserInputType=E.UserInputType.MouseButton1})
    check(speedRow:GetAttribute("Value")==100,"Slider: track click clamps upper bound")
    track.InputBegan:Fire({UserInputType=E.UserInputType.Keyboard,KeyCode=E.KeyCode.Left})
    check(speedRow:GetAttribute("Value")==99,"Slider: arrow key uses one increment")
    track.InputBegan:Fire({UserInputType=E.UserInputType.MouseButton1,Position=env.Vector2.new(-999,100)})
    ctl.UIS.InputEnded:Fire({UserInputType=E.UserInputType.MouseButton1})
    check(speedRow:GetAttribute("Value")==0,"Slider: track click clamps lower bound")
    click(sliderBtn("Walk Speed","+"))
    check(savedSettings():find("walkSpeed=1",1,true)~=nil,"Slider: value persisted")
    for _=1,15 do click(sliderBtn("Walk Speed","+")) end
    click(nav("Settings"))
    check(nav("Settings").Parent.Name=="SettingsDock","Navigation: Settings anchored outside scrolling list")
    click(toggleRow("Reduce Animations"))
    check(savedSettings():find("reduceAnimations=true",1,true)~=nil,"Motion: reduced preference persisted")
    click(toggleRow("Reduce Animations"))
    local scaleBefore=win():FindFirstChildOfClass("UIScale").Scale
    click(sliderBtn("UI Scale","−"))
    check(win():FindFirstChildOfClass("UIScale").Scale<scaleBefore,"Scale slider: applies layout immediately")
    click(sliderBtn("UI Scale","+"))
    local visualBefore=toggleRow("Enabled"):GetAttribute("Value")
    for _=1,20 do click(toggleRow("Enabled")) end
    check(toggleRow("Enabled"):GetAttribute("Value")==visualBefore,"Toggle: rapid changes preserve final state")
    click(nav("Home"))
    click(find(hubGui(),"TextButton","Copy Boot Log"))
    check(ctl.clipboard:find("Current boot",1,true) and ctl.clipboard:find("Search initialized; Ready",1,true),"Boot log: copies actual initialized stages")
    check((ctl.files["Ervi_Hub_boot.txt"] or ""):find("Ready",1,true)~=nil,"Boot log: retains last boot for next run")
    check(find(hubGui(),"TextButton","Unsupported")~=nil,"Unsupported operations are not enabled fake toggles")
    local mainGrip
    for _,d in ipairs(win():GetChildren()) do if d:GetAttribute("ResizeGrip") then mainGrip=d end end
    local scale=win():FindFirstChildOfClass("UIScale").Scale
    gesture(mainGrip,(880-win().Size.X.Offset)*scale,(580-win().Size.Y.Offset)*scale)
    check(win().Size.X.Offset==880 and win().Size.Y.Offset==580,"3.0 main window: resize uses responsive dimensions")
    ctl.keysDown={LeftControl=true};press("K");ctl.keysDown={}
    local search
    for _,d in ipairs(hubGui():GetDescendants()) do if d.ClassName=="TextBox" and d.PlaceholderText=="Search settings · Ctrl+K" then search=d end end
    check(ctl.focusedTextBox==search,"Search: Ctrl+K focuses the field")
    local worldScroll=hubGui():FindFirstChild("ErviPage_world",true)
    local shadowRow=toggleRow("No Shadows")
    ctl.set(worldScroll,"AbsolutePosition",env.Vector2.new(100,100));worldScroll.CanvasPosition=env.Vector2.new(0,0)
    ctl.set(shadowRow,"AbsolutePosition",env.Vector2.new(100,700))
    shadowRow.Parent.Visible=false
    search.Text="No Shadows";ctl.run(0.1)
    local result=find(hubGui(),"TextButton","No Shadows · World")
    check(result~=nil,"Search: finds an actual registered toggle across tabs")
    click(result);ctl.run(0.1)
    check(hubGui():FindFirstChild("ErviPage_world",true).Visible,"Search: result navigates to World")
    local focused=false
    for _,d in ipairs(hubGui():GetDescendants()) do if d:GetAttribute("SearchFocused") then focused=true end end
    check(focused,"Search: matching control highlighted")
    check(shadowRow.Parent.Visible,"Search: reveals a hidden containing section")
    check(worldScroll.CanvasPosition.Y==584,"Search: scrolls to actual matching control after layout settles")
    check(shadowRow:GetAttribute("SearchScrolled")==true,"Search: completes deferred navigation")
    search.Text="no matching control 999";ctl.run(0.1)
    check(find(hubGui(),"TextLabel","No matching registered setting")~=nil,"Search: no-results feedback")
    search.Text="";ctl.focusedTextBox=nil
    local lighting=ctl.lighting
    local brightness,ambient,shadows,time=lighting.Brightness,lighting.Ambient,lighting.GlobalShadows,lighting.ClockTime
    click(nav("World"))
    click(toggleRow("Fullbright"))
    check(lighting.Brightness==2 and lighting.Ambient==env.Color3.new(1,1,1),"World: Fullbright changes only owned light properties")
    click(toggleRow("No Shadows"));check(lighting.GlobalShadows==false,"World: No Shadows applies")
    click(toggleRow("Custom Time"));check(lighting.ClockTime==12,"World: custom time starts at selected hour")
    click(sliderBtn("Time of Day","+"));check(lighting.ClockTime==12.25,"World: time slider applies immediately")
    click(toggleRow("No Fog"))
    local atmos=ctl.new("Atmosphere");atmos.Density=0.4;atmos.Haze=1;atmos.Parent=lighting
    check(lighting.FogEnd==1000000 and atmos.Density==0,"World: No Fog handles late Atmosphere")
    click(toggleRow("No Fog"));check(lighting.FogEnd==500 and atmos.Density==0.4 and atmos.Haze==1,"World: fog and atmosphere restore")
    click(toggleRow("Fullbright"));check(lighting.Brightness==brightness and lighting.Ambient==ambient,"World: Fullbright restores original values")
    click(toggleRow("No Shadows"));click(toggleRow("Custom Time"))
    check(lighting.GlobalShadows==shadows and lighting.ClockTime==time,"World: time and shadows restore independently")
    click(toggleRow("Fullbright"));lighting.Brightness=3;click(toggleRow("Fullbright"))
    check(lighting.Brightness==3,"World: external game lighting change is preserved")
    lighting.Brightness=brightness
    local currentCamera=env.workspace.CurrentCamera
    local originalCamera,originalType,originalMouse=currentCamera.CFrame,currentCamera.CameraType,ctl.UIS.MouseBehavior
    check(find(hubGui(),"TextLabel","Freecam")==nil and find(hubGui(),"TextLabel","Freecam Speed")==nil,"Freecam controls removed")
    click(find(hubGui(),"TextButton","Reset Camera"))
    check(currentCamera.CameraType==env.Enum.CameraType.Custom and currentCamera.CameraSubject==ctl.player.Character:FindFirstChildOfClass("Humanoid"),"Reset Camera preserves normal camera support")
    click(nav("Settings"));click(toggleRow("Background Blur"))
    check(lighting:FindFirstChild("ErviBackgroundBlur")~=nil,"Interface: own blur effect when open")
    win().Visible=false;check(lighting:FindFirstChild("ErviBackgroundBlur")==nil,"Interface: hiding window removes owned blur")
    win().Visible=true;click(toggleRow("Background Blur"))
    -- Player speed and movement panel restoration across actual character replacement.
    click(nav("Player"))
    local localCharacter=ctl.player.Character
    local localHum=localCharacter:FindFirstChildOfClass("Humanoid")
    local baseSpeed=localHum.WalkSpeed
    click(find(hubGui(),"TextButton","Set"))
    click(toggleRow("WalkSpeed"));click(sliderBtn("Walk Speed","+"))
    check(localHum.WalkSpeed==17,"Player: local Set speed applies")
    click(find(hubGui(),"TextButton","Multiply"))
    check(localHum.WalkSpeed==baseSpeed*1.5,"Player: Multiply uses original base, not its own override")
    click(toggleRow("WalkSpeed"));check(localHum.WalkSpeed==baseSpeed,"Player: disabling restores original speed")
    click(toggleRow("Movement Panel"))
    local movement=ctl.pg:FindFirstChild("Ervi_MovementPanel")
    check(movement~=nil,"Player: floating movement panel exists")
    local movementFrame=movement:FindFirstChildOfClass("Frame");local movementGrip
    for _,d in ipairs(movementFrame:GetChildren()) do if d:GetAttribute("ResizeGrip") then movementGrip=d end end
    gesture(movementGrip,50,30)
    check(savedSettings():find("movementW=380.00",1,true),"Player: movement-panel size persists")
    click(toggleRow("Movement Panel"));check(ctl.pg:FindFirstChild("Ervi_MovementPanel")==nil,"Player: menu removes floating panel")
    -- Render visible players, enforce occlusion, exercise budgets and cleanup.
    local visiblePlayer=ctl.new("Player",env.game:GetService("Players"));visiblePlayer.Name="VisibleSample";ctl.set(visiblePlayer,"UserId",55)
    local visibleChar=ctl.new("Model",env.workspace);ctl.new("Humanoid",visibleChar)
    local visibleRoot=ctl.new("Part",visibleChar);visibleRoot.Name="HumanoidRootPart";visibleRoot.CFrame=env.CFrame.new(2,0,0)
    local visibleHead=ctl.new("Part",visibleChar);visibleHead.Name="Head";visibleHead.CFrame=env.CFrame.new(2,3,0)
    ctl.set(visiblePlayer,"Character",visibleChar)
    click(nav("Visuals"));ctl.run(0.2)
    click(toggleRow("Enabled"));ctl.run(0.3)
    local overlay=ctl.pg:FindFirstChild("Ervi_VisibleOverlays")
    check(overlay~=nil,"Visuals: native overlay root created")
    check(overlay.DisplayOrder>hubGui().DisplayOrder,"Visuals: graphics render above the hub")
    local passiveRoot=overlay:FindFirstChild("ErviPlayerOverlay")
    check(passiveRoot and not passiveRoot.Active and not passiveRoot.Interactable,"Visuals: overlay root is noninteractive")
    check(find(overlay,"TextLabel","VisibleSample · 23 studs")~=nil or (function() for _,d in ipairs(overlay:GetDescendants()) do if d.ClassName=="TextLabel" and d.Text:find("VisibleSample",1,true) then return true end end return false end)(),"Visuals: visible target name and distance drawn")
    local espLabel
    for _,d in ipairs(overlay:GetDescendants()) do if d.ClassName=="TextLabel" and d.Text:find("VisibleSample",1,true) then espLabel=d;break end end
    check(espLabel and espLabel.TextWrapped==false,"Visuals: name is unwrapped")
    check(espLabel and hex(espLabel.TextColor3)==hex(rgb(255,255,255)),"Visuals: labels use white text")
    check(espLabel and hex(espLabel.TextStrokeColor3)==hex(rgb(0,0,0)) and espLabel.TextStrokeTransparency==0,"Visuals: labels use visible black outline")
    local distanceLabel
    for _,d in ipairs(overlay:GetDescendants()) do if d.ClassName=="TextLabel" and d.Text:find("studs",1,true) then distanceLabel=d;break end end
    check(espLabel.Text=="VisibleSample" and distanceLabel and distanceLabel.Position.Y.Offset>espLabel.Position.Y.Offset,"Visuals: name above head and distance below feet")
    check(espLabel.TextSize==12 and distanceLabel.TextSize==12,"Visuals: factory labels are 12px")
    local render=ctl.renderBindings["ErviVisibleOverlays"].callback
    local oldX=espLabel.Position.X.Offset;local rays=ctl.raycasts
    visibleHead.CFrame=env.CFrame.new(4,3,0);visibleRoot.CFrame=env.CFrame.new(4,0,0)
    render(0)
    check(espLabel.Position.X.Offset~=oldX,"Visuals: current transforms presented between visibility ticks")
    check(ctl.raycasts==rays,"Visuals: intermediate presentation performs no additional raycasts")
    visibleHead.Transparency=1;render(0)
    check(not espLabel.Parent.Visible,"Visuals: invisible head suppressed before next expensive update")
    visibleHead.Transparency=0;visibleHead.CFrame=env.CFrame.new(2,3,0);visibleRoot.CFrame=env.CFrame.new(2,0,0)
    visibleHead.Transparency=1;ctl.run(0.3)
    check(#overlay:GetChildren()==0,"Visuals: invisible head does not reveal a hidden character")
    visibleHead.Transparency=0;ctl.run(0.3)
    click(toggleRow("Chams"));ctl.run(0.3)
    local highlight=overlay:FindFirstChildOfClass("Highlight")
    check(highlight and highlight.DepthMode==env.Enum.HighlightDepthMode.Occluded and highlight.Enabled,"Visuals: Visible Only chams use Occluded depth")
    local retainedOverlay=overlay:FindFirstChild("ErviPlayerOverlay")
    ctl.occluded=true;ctl.run(0.3)
    check(overlay:FindFirstChildOfClass("Highlight")==nil,"Visuals: fully occluded target resources removed")
    click(toggleRow("Through Walls"));ctl.run(0.3)
    check(overlay:FindFirstChild("ErviPlayerOverlay")~=nil,"Visuals: Through Walls retains replicated occluded players")
    local wallHighlight=overlay:FindFirstChildOfClass("Highlight")
    check(wallHighlight and wallHighlight.DepthMode==env.Enum.HighlightDepthMode.AlwaysOnTop,"Visuals: Through Walls chams use AlwaysOnTop")
    click(toggleRow("Through Walls"));ctl.run(0.3)
    check(overlay:FindFirstChild("ErviPlayerOverlay")==nil,"Visuals: turning Through Walls off reapplies occlusion")
    ctl.occluded=false;ctl.run(0.3)
    check(overlay:FindFirstChild("ErviPlayerOverlay")==retainedOverlay,"Visuals: temporary occlusion reuses the bounded drawing record")
    click(toggleRow("Skeleton"));click(toggleRow("Head Dot"));click(toggleRow("Tracers Enabled"));ctl.run(0.3)
    check(ctl.raycasts>0,"Visuals: line-of-sight queries actually executed")
    visiblePlayer.Parent=nil;ctl.run(0.3)
    check(#overlay:GetChildren()==0,"Visuals: leaving player removes drawing resources")
    click(toggleRow("Enabled"));check(ctl.pg:FindFirstChild("Ervi_VisibleOverlays")==nil,"Visuals: disable removes every overlay")
    -- Click TP is a held targeting preview, never a simulated server move.
    click(nav("Teleports"))
    local clickKey=hubGui():FindFirstChild("Setting_clickTPKey",true)
    click(clickKey);ctl.UIS.InputBegan:Fire({UserInputType=env.Enum.UserInputType.Keyboard,KeyCode=env.Enum.KeyCode.T},false)
    click(toggleRow("Click TP preview"))
    local previewRoot=ctl.player.Character:FindFirstChild("HumanoidRootPart")
    if not previewRoot then previewRoot=ctl.new("Part",ctl.player.Character);previewRoot.Name="HumanoidRootPart" end
    local previewOrigin=previewRoot.CFrame
    ctl.raycastResult={Instance=ctl.wall,Position=env.Vector3.new(10,0,-5),Normal=env.Vector3.new(0,1,0)}
    ctl.UIS.InputBegan:Fire({UserInputType=env.Enum.UserInputType.Keyboard,KeyCode=env.Enum.KeyCode.T},false);ctl.run(0.1)
    local marker=env.workspace:FindFirstChild("ErviClickTarget")
    check(marker and not marker.CanCollide and not marker.CanQuery,"Click preview: one non-interactive world circle appears while held")
    check(ctl.lastViewportRay and ctl.lastViewportRay[1]==400 and ctl.lastViewportRay[2]==300,"Click preview: raw mouse coordinates use viewport rays without a second GUI inset")
    check(ctl.lastGuiHitPoint and ctl.lastGuiHitPoint[1]==400 and ctl.lastGuiHitPoint[2]==242,"Click preview: GUI hit tests remove the top-bar inset from raw mouse coordinates")
    ctl.UIS.InputBegan:Fire({UserInputType=env.Enum.UserInputType.MouseButton1},false);ctl.run(0.1)
    check(ctl.player.Character:FindFirstChild("HumanoidRootPart").CFrame==previewOrigin,"Click preview: selecting does not modify the character or pretend to teleport")
    ctl.guiHits={clickKey};ctl.run(0.1)
    check(env.workspace:FindFirstChild("ErviClickTarget")==nil,"Click preview: GUI controls suppress the world indicator")
    ctl.guiHits={};ctl.run(0.1)
    check(env.workspace:FindFirstChild("ErviClickTarget")==marker,"Click preview: indicator is reused after GUI suppression")
    ctl.UIS.InputEnded:Fire({UserInputType=env.Enum.UserInputType.Keyboard,KeyCode=env.Enum.KeyCode.T})
    check(env.workspace:FindFirstChild("ErviClickTarget")==nil,"Click preview: key release hides its circle")
    click(toggleRow("Click TP preview"));click(toggleRow("Click TP preview"))
    ctl.UIS.InputBegan:Fire({UserInputType=env.Enum.UserInputType.Keyboard,KeyCode=env.Enum.KeyCode.T},false);ctl.run(0.1)
    check(ctl.lastRaycastParams and ctl.lastRaycastParams.FilterDescendantsInstances and ctl.lastRaycastParams.FilterDescendantsInstances[1]==ctl.player.Character,"Click preview: re-enabling rebuilds the local-character ray exclusion")
    click(clickKey);ctl.UIS.InputBegan:Fire({UserInputType=env.Enum.UserInputType.Keyboard,KeyCode=env.Enum.KeyCode.Backspace},false);ctl.run(0.1)
    check(env.workspace:FindFirstChild("ErviClickTarget")==nil,"Click preview: clearing a held binding immediately hides its indicator")
    click(toggleRow("Click TP preview"));ctl.raycastResult=nil;ctl.guiHits=nil
    check(marker and marker.Parent==nil,"Click preview: disabling releases its marker")
    noErrors("click targeting preview")
    -- Existing session controls + new actions; raw HTTP failure reports a status.
    click(nav("Utility"));local beforeTeleport=ctl.teleports
    local utilityPage=hubGui():FindFirstChild("ErviPage_utility",true)
    click(find(utilityPage,"TextButton","Rejoin"))
    check(ctl.teleports==beforeTeleport+1 and ctl.lastJob==env.game.JobId,"Utility: Rejoin requests this exact server")
    click(find(utilityPage,"TextButton","Copy Job ID"));check(ctl.clipboard==env.game.JobId,"Utility: Copy Job ID")
    click(find(utilityPage,"TextButton","Server Hop"));ctl.run(0.1)
    check(ctl.teleports==beforeTeleport+1,"Utility: failed server listing never invents a teleport")
    check(find(hubGui(),"TextLabel","0 · unchanged; getfpscap + setfpscap unavailable")~=nil,"Utility: FPS cap compatibility is explicit")
    click(nav("World"));click(toggleRow("No Shadows"))
    click(nav("World"));click(toggleRow("No Shadows"));ctl.run(0.25)
    local notice=hubGui():FindFirstChild("Notification",true)
    check(notice and near(notice.BackgroundTransparency,0.28),"Notifications: surface remains translucent")
    local noticeText
    if notice then for _,d in ipairs(notice:GetDescendants()) do if d.ClassName=="TextLabel" then noticeText=d;break end end end
    check(notice and notice.Size.Y.Offset==48 and noticeText and noticeText.TextSize==15,"Notifications: compact dimensions and readable text")
    click(nav("Settings"))
    click(find(hubGui(),"TextButton","RU"));ctl.run(0.2)
    check(find(hubGui(),"TextLabel","Настройки")~=nil,"Language: Russian interface labels apply")
    click(find(hubGui(),"TextButton","EN"));ctl.run(0.2)
    check(nav("Settings")~=nil,"Language: English interface labels restore")
    press("End");ctl.run(0.3)
    check(hubGui()==nil,"Panic key unloads the hub")
    check(lighting.GlobalShadows==shadows and currentCamera.CameraType==env.Enum.CameraType.Custom,"Unload restores lighting and camera")
    check(ctl.conns==baseConns and ctl.pendingThreads()==0,"3.0 features leave no listeners or workers",ctl.conns-baseConns)
    noErrors("3.0 expansion")

    -- Supported FPS readback, successful server-list selection and rendering budgets.
    local currentCap=240
    env.getfpscap=function() return currentCap end
    env.setfpscap=function(value) currentCap=value end
    runHub();ctl.run(0.3)
    local function setToggle(name,value)
        local row=toggleRow(name)
        if row:GetAttribute("Value")~=value then click(row) end
    end
    click(nav("Utility"))
    click(sliderBtn("FPS Cap","+"))
    check(currentCap==1,"FPS cap: supported setter applies slider value")
    click(sliderBtn("FPS Cap","−"))
    check(currentCap==240,"FPS cap: zero restores prior/default cap")
    click(sliderBtn("FPS Cap","+"))
    ctl.httpBody="mock-server-list"
    ctl.serverList={data={{id=env.game.JobId,playing=1,maxPlayers=30},{id="full",playing=30,maxPlayers=30},{id="available",playing=12,maxPlayers=30}}}
    utilityPage=hubGui():FindFirstChild("ErviPage_utility",true)
    beforeTeleport=ctl.teleports
    click(find(utilityPage,"TextButton","Server Hop"));ctl.run(0.1)
    check(ctl.teleports==beforeTeleport+1 and ctl.lastJob=="available","Server Hop: skips current/full servers and selects available server")
    check(ctl.lastHttp:find("limit=100",1,true)~=nil,"Server Hop: request is bounded to 100 results")
    ctl.httpBody=nil;ctl.serverList=nil
    click(nav("Visuals"))
    setToggle("Chams",true);setToggle("Skeleton",true);setToggle("Tracers Enabled",false);setToggle("HealthBar",false)
    local samplePlayers={}
    for i=1,3 do
        local sample=ctl.new("Player",env.game:GetService("Players"));sample.Name="Budget"..i;ctl.set(sample,"UserId",70+i)
        local char=ctl.new("Model",env.workspace);ctl.new("Humanoid",char)
        for _,part in ipairs({{"HumanoidRootPart",0},{"Head",3},{"Torso",1},{"Left Arm",1}}) do
            local limb=ctl.new("Part",char);limb.Name=part[1];limb.CFrame=env.CFrame.new(i*2,part[2],0)
        end
        ctl.set(sample,"Character",char);table.insert(samplePlayers,sample)
    end
    setToggle("Enabled",true);ctl.run(0.3)
    overlay=ctl.pg:FindFirstChild("Ervi_VisibleOverlays")
    local function overlayCount()
        local n=0
        for _,d in ipairs(overlay:GetChildren()) do if d.Name=="ErviPlayerOverlay" then n+=1 end end
        return n
    end
    check(overlayCount()==3,"Visual budgets: three visible players render")
    for _=1,23 do click(sliderBtn("Max Targets","−")) end
    ctl.run(0.3)
    check(overlayCount()==1,"Visual budgets: Max Targets hard cap removes excess resources")
    setToggle("Cheap Boxes",false);ctl.run(0.3)
    check(overlayCount()==1,"Visual budgets: full bounding boxes respect same cap")
    setToggle("Mark Friends",true);ctl.friendIds={[71]=true}
    -- Cache began before the fixture map changed; toggling renderer refreshes cache.
    setToggle("Enabled",false);setToggle("Enabled",true);ctl.run(0.3)
    overlay=ctl.pg:FindFirstChild("Ervi_VisibleOverlays")
    highlight=overlay:FindFirstChildOfClass("Highlight")
    check(highlight and highlight.FillColor==env.Color3.fromHex("70AFFF"),"Visuals: cached Roblox friend status applies friend color")
    local team=ctl.new("Team")
    ctl.set(ctl.player,"Neutral",false);ctl.set(ctl.player,"Team",team)
    for _,sample in ipairs(samplePlayers) do ctl.set(sample,"Neutral",false);ctl.set(sample,"Team",team) end
    ctl.run(0.3)
    check(overlayCount()==0,"Visuals: Team Check suppresses teammates")
    setToggle("Show Teammates",true);ctl.run(0.3)
    check(overlayCount()==1,"Visuals: Show Teammates permits them within cap")
    highlight=overlay:FindFirstChildOfClass("Highlight")
    check(highlight and not highlight.Enabled,"Visuals: Chams Enemies Only suppresses teammate highlight")
    ctl.set(ctl.player,"Neutral",true)
    click(find(hubGui(),"TextButton","None"));ctl.run(0.2)
    for _=1,8 do click(sliderBtn("Skeleton Budget","−")) end
    ctl.run(0.3)
    local function visibleLines()
        local n=0;for _,d in ipairs(overlay:GetDescendants()) do if d.Name=="SkeletonCore" and d.Visible then n+=1 end end;return n
    end
    check(visibleLines()==0,"Visual budgets: zero Skeleton Budget disables bone projections")
    click(sliderBtn("Skeleton Budget","+"));ctl.run(0.3)
    check(visibleLines()>0,"Visual budgets: skeleton renders within a positive budget")
    local limbLines=visibleLines()
    local allWhite=true
    for _,node in ipairs(overlay:GetDescendants()) do if node.Name=="SkeletonCore" and node.Visible and node.BackgroundColor3~=env.Color3.new(1,1,1) then allWhite=false end end
    check(allWhite,"Skeleton: white lines are independent of friend/team/enemy palette")
    local outlines,cores=0,0;local correct=true
    for _,node in ipairs(overlay:GetDescendants()) do
     if node.Name=="SkeletonOutline" and node.Visible then outlines+=1;if node.BackgroundColor3~=env.Color3.new(0,0,0) or node.Size.Y.Offset~=3 then correct=false end end
     if node.Name=="SkeletonCore" and node.Visible then cores+=1;if node.Size.Y.Offset~=1 then correct=false end end
    end
    check(correct and outlines==cores and cores>0,"Skeleton: thin white cores have matching black outline segments")
    local arm=samplePlayers[1].Character:FindFirstChild("Left Arm")
    local oldArm=arm.CFrame;arm.CFrame=env.CFrame.new(0,0,100);ctl.run(0.3)
    check(visibleLines()<limbLines,"Skeleton: behind-camera limb cannot mirror into oversized line")
    arm.CFrame=oldArm;ctl.run(0.3)
    check(visibleLines()==limbLines,"Skeleton: limb returns without stationary artifact")
    check(ctl.renderBindings.ErviVisibleOverlays~=nil,"Skeleton: one shared manager is bound after the camera")
    for i,sample in ipairs(samplePlayers) do
        sample.Character:FindFirstChild("HumanoidRootPart").CFrame=env.CFrame.new(100+i,0,0)
        sample.Character:FindFirstChild("Head").CFrame=env.CFrame.new(100+i,3,0)
    end
    ctl.run(0.3)
    check(overlayCount()==0,"Visuals: off-screen targets hidden when arrows are off")
    setToggle("Off-screen Arrows",true);ctl.run(0.3)
    local arrow=find(overlay,"TextLabel","▲")
    check(arrow and arrow.Visible and arrow.Position.X.Offset>1800,"Visuals: clear-line off-screen arrow clamps near screen edge")
    for _=1,19 do click(sliderBtn("Max Distance","−")) end
    ctl.run(0.3)
    check(overlayCount()==0,"Visual budgets: distance limit removes far targets")
    click(sliderBtn("Max Distance","+"));click(sliderBtn("Max Distance","+"));ctl.run(0.3)
    check(overlayCount()==1,"Visual budgets: raising distance restores at most the target cap")
    setToggle("Preview hidden target",true);ctl.run(0.2)
    check(find(hubGui(),"TextLabel","Hidden: overlay suppressed")~=nil,"Preview: hidden-target setting responds without revealing real occluded players")
    ctl.occluded=true;ctl.run(0.3)
    check(overlayCount()==0,"Visuals: all occluded targets remain suppressed with every option enabled")
    ctl.occluded=false
    click(nav("Player"));setToggle("WalkSpeed",true)
    click(nav("World"));setToggle("No Shadows",true);setToggle("Fullbright",true)
    ctl.run(0.3)
    check(currentCamera.CameraType==env.Enum.CameraType.Custom and lighting.GlobalShadows==false,"Multiple active features: lighting and visuals preserve normal camera")
    env._G.RNG_HUB_STOP();ctl.run(0.3)
    check(currentCap==240,"FPS cap: unload restores original value")
    check(next(ctl.renderBindings)==nil,"Visuals: unload releases shared render binding")
    check(ctl.pg:FindFirstChild("Ervi_VisibleOverlays")==nil and currentCamera.CameraType==env.Enum.CameraType.Custom,"Multiple active features: rendering/camera cleanup")
    check(ctl.conns==baseConns and ctl.pendingThreads()==0,"Multiple active features: no leaked workers or connections",ctl.conns-baseConns)
    noErrors("supported APIs and budgets")
    runHub();ctl.run(0.3)
    currentCap=123
    local oldCamera=env.workspace.CurrentCamera
    local newCamera=ctl.new("Camera",env.workspace)
    newCamera.CFrame=env.CFrame.new(0,10,20);newCamera.CameraType=env.Enum.CameraType.Custom
    ctl.set(newCamera,"ViewportSize",env.Vector2.new(1280,720))
    ctl.set(env.workspace,"CurrentCamera",newCamera);ctl.run(0.2)
    check(oldCamera.CameraType==env.Enum.CameraType.Custom and newCamera.CameraType==env.Enum.CameraType.Custom,"Camera replacement remains under normal game control")
    local previousCharacter=ctl.player.Character
    ctl.player.CharacterRemoving:Fire(previousCharacter)
    local replacement=ctl.new("Model",env.workspace);local replacementHum=ctl.new("Humanoid",replacement);replacementHum.WalkSpeed=18
    ctl.set(ctl.player,"Character",replacement);ctl.player.CharacterAdded:Fire(replacement);ctl.run(0.2)
    check(replacementHum.WalkSpeed==27,"Player: respawn Multiply uses new character's base speed")
    replacementHum.WalkSpeed=25;ctl.run(0.2)
    check(replacementHum.WalkSpeed==25,"Player: server speed correction is not fought in a loop")
    env._G.RNG_HUB_STOP();ctl.run(0.2)
    check(currentCap==123,"FPS cap: preserve later external cap changes")
    check(ctl.conns==baseConns and ctl.pendingThreads()==0,"Final supported-API run leaves no resources")
    noErrors("external cap restoration")

    -- Compact bar and origin-return regression cases, independent of legacy tab helpers.
    runHub();ctl.run(0.3)
    local barGui=ctl.pg:FindFirstChild("Ervi_MinimizedStatus")
    local bar=barGui:FindFirstChildOfClass("TextButton")
    local navItems={}
    for _,d in ipairs(hubGui():GetDescendants()) do
        if d.ClassName=="TextButton" and d:GetAttribute("NavPage") and d.Visible then table.insert(navItems,d) end
    end
    table.sort(navItems,function(a,b) return a.LayoutOrder<b.LayoutOrder end)
    local expected={"roll","styles","dash","combat","visuals","player","world","safe","teleports","utility","settings"}
    check(#navItems==#expected,"Navigation: only the eleven requested primary entries (Config removed)")
    local ordered=true;for i,id in ipairs(expected) do if not navItems[i] or navItems[i]:GetAttribute("NavPage")~=id then ordered=false end end
    check(ordered,"Navigation: primary game tools first, Settings last")
    check(nav("Friends")==nil and nav("Sounds")==nil and nav("Triggerbot")==nil,"Navigation: unwanted tabs removed")
    check(hubGui():FindFirstChild("ErviOfficialLogo",true)~=nil,"Official logo: native transparent geometry mounted")
    local mainLogo=hubGui():FindFirstChild("ErviOfficialLogo",true)
    local statusLogo=bar:FindFirstChild("ErviOfficialLogo",true)
    check(mainLogo and math.abs(mainLogo.Size.X.Offset/mainLogo.Size.Y.Offset-130/138)<0.001,"Official logo: main mark keeps the exact aspect ratio")
    check(statusLogo and math.abs(statusLogo.Size.X.Offset/statusLogo.Size.Y.Offset-130/138)<0.001,"Official logo: status mark keeps the exact aspect ratio")
    click(hubGui():FindFirstChild("MinimizeButton", true));ctl.run(0.3)
    check(not win().Visible and barGui.Enabled,"Status bar: minimize hides entire main window")
    check(bar:GetAttribute("AutoRollState")~=nil,"Status bar: reports Auto Roll state while hidden")
    local beforeX=bar.Position.X.Offset
    bar.InputBegan:Fire({UserInputType=E.UserInputType.MouseButton1,Position=env.Vector2.new(100,100)})
    ctl.UIS.InputChanged:Fire({UserInputType=E.UserInputType.MouseMovement,Position=env.Vector2.new(-10000,-10000)})
    click(bar)
    check(not win().Visible,"Status bar: Activated before global release cannot open after drag")
    ctl.UIS.InputEnded:Fire({UserInputType=E.UserInputType.MouseButton1})
    ctl.run(0.5);click(bar)
    check(not win().Visible,"Status bar: delayed drag-release activation stays suppressed")
    check(bar.Position.X.Offset==0 and bar.Position.Y.Offset==0,"Status bar: dragging remains on screen")
    check(savedSettings():find("statusX=0.000000",1,true),"Status bar: position persists")
    -- Live 3.4 defect: a press whose release never reached the game left the gesture armed; later
    -- mouse movement and the next click anywhere saved a new pill position.
    local savedX=savedSettings():match("statusX=([%d%.]+)")
    bar.InputBegan:Fire({UserInputType=E.UserInputType.MouseButton1,Position=env.Vector2.new(0,0)})
    ctl.mouseDown=false
    ctl.UIS.InputChanged:Fire({UserInputType=E.UserInputType.MouseMovement,Position=env.Vector2.new(400,300)})
    ctl.mouseDown=nil
    ctl.UIS.InputEnded:Fire({UserInputType=E.UserInputType.MouseButton1})
    check(bar.Position.X.Offset==0 and savedSettings():match("statusX=([%d%.]+)")==savedX,"Status bar: missed release cancels the drag without moving or saving")
    bar.InputBegan:Fire({UserInputType=E.UserInputType.MouseButton1,Position=env.Vector2.new(0,0)})
    barGui.Enabled=false
    ctl.UIS.InputChanged:Fire({UserInputType=E.UserInputType.MouseMovement,Position=env.Vector2.new(400,300)})
    ctl.UIS.InputEnded:Fire({UserInputType=E.UserInputType.MouseButton1})
    barGui.Enabled=true
    check(bar.Position.X.Offset==0 and savedSettings():match("statusX=([%d%.]+)")==savedX,"Status bar: hidden pill ignores movement and never saves")
    check(bar:FindFirstChildOfClass("UIStroke") and bar:FindFirstChildOfClass("UIStroke"):FindFirstChildOfClass("UIGradient"),"Status bar: liquid-glass rim")
    bar.InputBegan:Fire({UserInputType=E.UserInputType.MouseButton1,Position=env.Vector2.new(0,0)})
    ctl.UIS.InputEnded:Fire({UserInputType=E.UserInputType.MouseButton1})
    click(bar);ctl.run(0.1)
    check(win().Visible and not barGui.Enabled,"Status bar: click restores full GUI")
    press("F4");check(not win().Visible and barGui.Enabled,"Status bar: GUI key minimizes")
    press("F4");check(win().Visible and not barGui.Enabled,"Status bar: GUI key restores")
    click(nav("Settings"))
    click(sliderBtn("Status Bar Opacity","+"));ctl.run(0.2)
    check(near(bar.BackgroundTransparency,0.25),"Status bar opacity slider immediately changes visible pill",bar.BackgroundTransparency)
    check(savedSettings():find("statusOpacity=0.75",1,true)~=nil,"Status bar opacity persists")
    check(find(hubGui(),"TextBox","75%")~=nil,"Status bar opacity is displayed as percent")
    click(nav("Combat"));click(toggleRow("Show M1 cooldown HUD"));click(nav("Settings"))
    local function stepStatusOpacity(plus)
        local label=find(hubGui(),"TextLabel","Status Bar Opacity")
        for _,child in ipairs(label.Parent:GetChildren()) do
            if child.ClassName=="TextButton" and ((plus and child.Text=="+") or (not plus and child.Text~="+")) then click(child);return end
        end
    end
    for _=1,15 do stepStatusOpacity(false) end
    press("F4")
    local chip=find(bar,"TextButton","M1")
    local pillStroke=bar:FindFirstChildOfClass("UIStroke")
    check(bar.BackgroundTransparency==1 and pillStroke and pillStroke.Transparency==1,"Status bar 0% removes pill fill and border")
    check(chip and chip.BackgroundTransparency==1,"Status bar 0% removes chip fill while preserving its label",chip and tostring(chip.BackgroundTransparency) or "missing")
    press("F4")
    for _=1,20 do stepStatusOpacity(true) end
    press("F4")
    check(bar.BackgroundTransparency==0 and pillStroke and math.abs(pillStroke.Transparency-0.25)<0.001,"Status bar 100% shows pill surface and subtle border")
    check(chip and math.abs(chip.BackgroundTransparency-0.55)<0.001,"Status bar 100% keeps chips translucent",chip and tostring(chip.BackgroundTransparency) or "missing")
    press("F4")
    click(nav("Combat"));click(toggleRow("Show M1 cooldown HUD"))
    click(nav("Auto Roll"))
    local nBox
    for _,d in ipairs(hubGui():GetDescendants()) do if d.ClassName=="TextBox" and d.Name=="Input_customN" then nBox=d end end
    local nSlider=hubGui():FindFirstChild("Setting_customN",true)
    check(nSlider~=nil and nBox~=nil,"Custom N slider and exact input mounted")
    click(sliderBtn("Custom N","+"));ctl.run(0.1)
    check(nBox.Text=="501" and savedSettings():find("customN=501.00",1,true)~=nil,"Custom N slider synchronizes exact input and persists")
    nBox.Text="1200";nBox.FocusLost:Fire(true)
    check(nBox.Text=="1200" and nSlider:GetAttribute("Value")==1200,"Custom N exact entry updates slider")
    nBox.Text="999999";nBox.FocusLost:Fire(true)
    check(nBox.Text=="5000" and nSlider:GetAttribute("Value")==5000,"Custom N exact entry clamps maximum")
    nBox.Text="0";nBox.FocusLost:Fire(true)
    check(nBox.Text=="1" and nSlider:GetAttribute("Value")==1,"Custom N exact entry clamps minimum")
    nBox.Text="5000";nBox.FocusLost:Fire(true)
    nBox.Text="1.5";nBox.FocusLost:Fire(true)
    check(nSlider:GetAttribute("Value")==5000,"Custom N rejects decimal entry without changing selected value")
    nBox.Text="invalid";nBox.FocusLost:Fire(true)
    check(nSlider:GetAttribute("Value")==5000,"Custom N ignores invalid entry")
    local targetSummary
    for _,d in ipairs(hubGui():GetDescendants()) do if d.ClassName=="TextLabel" and d.Text:find("Target:",1,true) then targetSummary=d;break end end
    check(targetSummary and targetSummary.Text:find("Chance >= 5000",1,true),"Custom N selection reaches Auto Roll target logic")
    click(nav("Safe Zone"))
    local character=ctl.player.Character
    local h=character:FindFirstChildOfClass("Humanoid");ctl.set(h,"Health",100)
    local r=character:FindFirstChild("HumanoidRootPart")
    if not r then r=ctl.new("Part",character);r.Name="HumanoidRootPart" end
    local origin=ctl.cframe(100,15,-25,0,0,1,0,1,0,-1,0,0)
    r.CFrame=origin;r.Anchored=false
    click(toggleRow("Enable Safe Zone"));ctl.run(0.1)
    click(toggleRow("Enable Safe Zone"));ctl.run(0.1)
    check(r.CFrame==origin and not r.Anchored,"Safe Zone return: exact activation origin and orientation restored")
    check(ctl.pivotAnchorHistory[#ctl.pivotAnchorHistory]==true,"Safe Zone return: return move precedes hold release")
    local changedOrigin=ctl.cframe(-10,20,50,1,0,0,0,1,0,0,0,1);r.CFrame=changedOrigin
    for _=1,3 do click(toggleRow("Enable Safe Zone"));click(toggleRow("Enable Safe Zone")) end
    check(r.CFrame==changedOrigin and not r.Anchored,"Safe Zone return: rapid toggles capture fresh origin without drift")
    click(toggleRow("Enable Safe Zone"));ctl.rejectPivot=true
    click(toggleRow("Enable Safe Zone"));ctl.rejectPivot=false
    check(not r.Anchored,"Safe Zone return: rejection releases physics and does not retry")
    r.CFrame=changedOrigin;click(toggleRow("Enable Safe Zone"))
    env._G.RNG_HUB_STOP();ctl.run(0.2)
    check(r.CFrame==changedOrigin and not r.Anchored,"Safe Zone return: unload returns before release")
    check(ctl.pg:FindFirstChild("Ervi_MinimizedStatus")==nil,"Unload: compact status bar removed")
    check(ctl.conns==baseConns and ctl.pendingThreads()==0,"3.1 UI and return workflow leave no resources",ctl.conns-baseConns)
    noErrors("3.1 status and return")

    -- 3.4 images: the bundle carries its own PNGs, writes them to the workspace and uses them only
    -- after the engine confirms the load; a failed load keeps the native logo/icons.
    local assetCalls = {}
    env.getcustomasset = function(path) table.insert(assetCalls, path); return "rbxasset://mock/" .. path end
    ctl.assetStatus = "Success"
    runHub();ctl.run(0.5)
    local logoFile, iconFile
    for name, data in pairs(ctl.files) do
        if name:match("^Ervi_Hub_ui%-logo%-.+%.png$") then logoFile = data end
        if name:match("^Ervi_Hub_ui%-icons%-.+%.png$") then iconFile = data end
    end
    check(logoFile and logoFile:sub(1, 8) == "\137PNG\r\n\26\n" and iconFile and iconFile:sub(1, 8) == "\137PNG\r\n\26\n", "Images: embedded PNGs written to the workspace by the bundle itself")
    local logoImage = hubGui():FindFirstChild("LogoImage", true)
    check(logoImage and logoImage.Image:find("Ervi_Hub_ui%-logo") ~= nil, "Images: verified logo uses the local asset", logoImage and logoImage.Image)
    local rollIcon = hubGui():FindFirstChild("Icon_roll", true)
    check(rollIcon and rollIcon.ClassName == "ImageLabel" and rollIcon.ImageRectSize.X == 48, "Images: verified atlas icon uses the local asset")
    env._G.RNG_HUB_STOP();ctl.run(0.2)
    ctl.assetStatus = "Failure"
    runHub();ctl.run(0.5)
    check(hubGui():FindFirstChild("LogoImage", true) == nil and #hubGui():FindFirstChild("ErviOfficialLogo", true):GetChildren() > 10, "Images: failed load falls back to the native logo")
    rollIcon = hubGui():FindFirstChild("Icon_roll", true)
    check(rollIcon and rollIcon.ClassName == "Frame", "Images: failed load falls back to native icons")
    env._G.RNG_HUB_STOP();ctl.run(0.2)
    env.getcustomasset = function() error("executor asset API failed") end
    runHub();ctl.run(0.5)
    check(hubGui():FindFirstChild("Icon_roll", true).ClassName == "Frame", "Images: erroring getcustomasset falls back to native icons")
    env._G.RNG_HUB_STOP();ctl.run(0.2)
    env.getcustomasset = nil;ctl.assetStatus = nil
    check(ctl.conns==baseConns and ctl.pendingThreads()==0,"Images: no leaked resources",ctl.conns-baseConns)
    noErrors("images")

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
