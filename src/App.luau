-- Ervi Hub (RNG RollAttacks) entry point.
-- Lifecycle: one hub Scope owns every GUI, connection and thread; features own child scopes.
-- The window X calls stopHub(), which nothing else can disconnect (fixes the old diagnostic X bug).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Build = require("Build")
local BootLog = require("BootLog")
local Scope = require("Scope")
local Theme = require("Theme")
local Ui = require("Ui")
local Game = require("Game")
local Rarity = require("Rarity")
local AutoRoll = require("AutoRoll")
local makeAdapter = require("RollAdapter")
local makeSafeZone = require("SafeZone")
local makeTargets = require("Targets")
local makeM1 = require("M1")
local makeObserver = require("RollObserver")
local Settings = require("Settings")
local makeSession = require("Session")
local makePrompts = require("Prompts")
local makeExpansion = require("Expansion")
local Logo=require("Logo")
local makeStatusBar=require("StatusBar")

local HUB_NAME = "RNG_RollAttacks_Hub"
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Stop previous runs: this hub, baseline v1 and older diagnostics.
for _, key in ipairs({ "RNG_HUB_STOP", "RNG_CYBORG_V6_STOP", "RNG_DIAG_V5_STOP" }) do
	local stop = _G[key]
	if type(stop) == "function" then
		pcall(stop)
	end
end
for _, name in ipairs({ HUB_NAME, "RNG_Cyborg_M1_V6", "RNG_AttackDiagnostic_V5", "RNG_Hub_CombatHUD", "RNG_Hub_M1HUD", "Ervi_MinimizedStatus", "Ervi_MovementPanel", "Ervi_VisibleOverlays" }) do
	local old = playerGui:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end

local hub = Scope.new("hub")
local stopped = false
local onStop = {} -- feature cleanups, registered as features are created

-- Registered before anything can yield (e.g. requiring game data), so a second Run always
-- finds and stops this one, even mid-load. A run stopped mid-load disposes whatever it adds later.
local function stopHub()
	if stopped then
		return
	end
	stopped = true
	for i = #onStop, 1, -1 do
		pcall(onStop[i])
	end
	hub:close()
	if _G.RNG_HUB_STOP == stopHub then
		_G.RNG_HUB_STOP = nil
	end
	print("[Ervi Hub] Fully stopped and cleaned.")
end
_G.RNG_HUB_STOP = stopHub
Ui.bindMotion(hub)

local boot=BootLog.new(Build.id,os.clock,readfile,writefile)
local function bootStep(message) if not stopped then boot.step(message) end end
bootStep("Stop handle registered; prior instance cleanup finished")

local logs = {}

local function log(feature, msg, isError)
	table.insert(logs, 1, ("%s %s: %s"):format(os.date("%H:%M:%S"), feature, msg))
	if #logs > 60 then
		table.remove(logs)
	end
	(isError and warn or print)(("[Ervi Hub] %s: %s"):format(feature, msg))
end

local function safe(feature, fn)
	return function(...)
		local ok, err = xpcall(fn, debug.traceback, ...)
		if not ok then
			log(feature, tostring(err), true)
		end
	end
end

local function isKey(name)
	if name == "Unknown" or name == "Escape" then
		return false
	end
	local ok, kc = pcall(function()
		return Enum.KeyCode[name]
	end)
	return ok and kc ~= nil
end
local function inList(list)
	return function(name)
		return Theme.find(list, name) ~= nil
	end
end
local validators = {
	toggleKey = isKey,
	safeZoneKey = function(value) return value == "NONE" or isKey(value) end,
	theme = inList(Theme.PRESETS),
	accent = function(name)
		return name == "" or Theme.hex(name) ~= nil or Theme.find(Theme.ACCENTS, name) ~= nil
	end,
	font = inList(Theme.FONTS),
	textColor = function(name)
		return Theme.hex(name) ~= nil or Theme.find(Theme.TEXT_COLORS, name) ~= nil
	end,
	bgColor = function(name)
		return name == "" or Theme.hex(name) ~= nil
	end,
}

for _,spec in ipairs(require("FeatureSchema")) do
 if spec.kind=="key" then validators[spec.key]=function(value) return value=="NONE" or isKey(value) end end
end
validators.communityLink=function(value) return value=="" or (value:match("^https://")~=nil and #value<=300) end

-- Configs: the active config auto-saves every change; the autoload config (if set) is active at start.
local store = Settings.load(validators)
local activeName = store.autoloadGames[tostring(game.PlaceId)] or store.autoload or Settings.DEFAULT_NAME
if not store.configs[activeName] and activeName~=Settings.DEFAULT_NAME then activeName=Settings.DEFAULT_NAME end
if not store.configs[activeName] then
	Settings.put(store, activeName, Settings.defaults())
end
local prefs = store.configs[activeName]
bootStep("Settings loaded: "..activeName)
local syncs = {} -- each re-reads `prefs` into its control (after loading a config, a reset or a look change)
Ui.applyLook(prefs)
Ui.setOpacity(prefs.opacity, Settings.MIN_OPACITY)
local function savePrefs()
	local ok, err = Settings.save(store)
	if not ok and Settings.canPersist() then
		log("Settings", "could not save: " .. tostring(err), true)
	end
end

local metrics = { fps = 0, ping = 0 }
do
	local frames, since = 0, os.clock()
	hub:connect(RunService.Heartbeat, function()
		frames += 1
		local now = os.clock()
		if now - since >= 1 then
			metrics.fps = math.floor(frames / (now - since) + 0.5)
			frames, since = 0, now
			local ok, p = pcall(player.GetNetworkPing, player)
			metrics.ping = ok and math.floor(p * 1000 + 0.5) or 0
		end
	end)
end

-- ===================================================================== window
local gui = hub:add(Ui.new("ScreenGui", {
	Name = HUB_NAME,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 350,
	Parent = playerGui,
}))
Ui.root(gui)
local W, H, TH, SW = prefs.winW, prefs.winH, Theme.titleH, Theme.sidebarW -- W/H change with the resize grip
local HOME = UDim2.new(0.5, -W / 2, 0.5, -H / 2)
local window = Ui.new("CanvasGroup", {
 Name="ErviWindow",
	Size = UDim2.fromOffset(W, H),
	Position = HOME,
	BackgroundColor3 = Theme.bg,
	Parent = gui,
})
Ui.surface(window)
Ui.corner(window, 12)
Ui.stroke(window, Theme.stroke, 0.1)
Ui.new("UIGradient",{Color=ColorSequence.new(Color3.new(1,1,1),Color3.new(0.8,0.78,0.84)),Rotation=40,Parent=window})
local uiScale = Ui.new("UIScale", { Parent = window })

local titleBar = Ui.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, TH), Active = true, Parent = window })
local officialLogo=Logo.create(titleBar,UDim2.fromOffset(24,26));officialLogo.Position=UDim2.fromOffset(10,12)
-- Brand title: silver serif with a dark outline; keeps its font and colors whatever look is chosen.
local title = Ui.text(titleBar, "Ervi Hub", { size = UDim2.new(0, 110, 1, 0), font = Theme.brandFont, textSize = 19, color = Color3.new(1, 1, 1) })
title.Position = UDim2.fromOffset(40, 0)
title:SetAttribute("FixedTextColor", true)
Ui.new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(252, 252, 254), Color3.fromRGB(166, 168, 176)), Rotation = 90, Parent = title })
Ui.new("UIStroke", { Color = Color3.fromRGB(40, 40, 46), Thickness = 1.2, Parent = title }):SetAttribute("FixedBackground", true)
local subtitle=Ui.text(titleBar,"v"..Build.version,{size=UDim2.new(0,55,0,16),textSize=10,color=Theme.faint,font=Theme.mono})
subtitle.Position=UDim2.fromOffset(40,32)
local headerTitle=Ui.text(titleBar,"Home",{size=UDim2.new(0,170,0,22),font=Theme.fontBold})
headerTitle.Position=UDim2.fromOffset(SW+14,8)
local headerDesc=Ui.text(titleBar,"Your session at a glance",{size=UDim2.new(0,180,0,18),textSize=10,color=Theme.muted})
headerDesc.Position=UDim2.fromOffset(SW+14,30)

local function titleButton(text, x, danger)
	local b = Ui.new("TextButton", {
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, x, 0.5, 0),
		Size = UDim2.fromOffset(30, 26),
		BackgroundColor3 = Theme.surface2,
		Text = text,
		TextColor3 = Theme.muted,
		TextSize = 18,
		Font = Theme.fontBold,
		Parent = titleBar,
	})
	Ui.corner(b)
	hub:connect(b.MouseEnter, function()
		b.BackgroundColor3 = danger and Theme.bad or Theme.hover
		b.TextColor3 = Theme.text
	end)
	hub:connect(b.MouseLeave, function()
		b.BackgroundColor3 = Theme.surface2
		b.TextColor3 = Theme.muted
	end)
	return b
end
local closeBtn = titleButton("×", -10, true)
local minBtn = titleButton("–", -46)
closeBtn.Name="CloseButton";minBtn.Name="MinimizeButton"
local onWindowDragged
Ui.drag(hub, titleBar, window,function() if onWindowDragged then onWindowDragged(true) end end,function() if onWindowDragged then onWindowDragged(false) end end)

local body = Ui.new("Frame", { Name="Body", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, TH), Size = UDim2.new(1, 0, 1, -TH), Parent = window })
local sidebar=Ui.scroll(body,{Name="Navigation",Size=UDim2.new(0,SW,1,-120),ScrollBarThickness=2})
Ui.pad(sidebar,8,10,10,10);Ui.list(sidebar,4)
local settingsDock=Ui.new("Frame",{Name="SettingsDock",BackgroundTransparency=1,Size=UDim2.new(0,SW-20,0,36),Position=UDim2.new(0,10,1,-112),Parent=body})
local profile=Ui.new("Frame",{Size=UDim2.new(0,SW-20,0,64),Position=UDim2.new(0,10,1,-72),BackgroundColor3=Theme.surface2,Parent=body})
Ui.surface(profile);Ui.corner(profile,10);Ui.pad(profile,8)
Ui.text(profile,player.DisplayName or player.Name,{font=Theme.fontMedium,textSize=12,order=1})
local profileStatus=Ui.text(profile,"v"..Build.version.." · local tools",{textSize=10,color=Theme.muted,order=2})
Ui.list(profile,4)
local content = Ui.new("Frame", {
 Name="Content",
	BackgroundColor3 = Theme.surface,
	Position = UDim2.fromOffset(SW, 0),
	Size = UDim2.new(1, -SW - 10, 1, -10),
	ClipsDescendants = true,
	Parent = body,
})
Ui.surface(content)
Ui.corner(content, Theme.radius)

local communityButton=Ui.button(hub,body,"Community ↗",{width=SW-20,height=30},function() if prefs.communityLink~="" then Game.copy(prefs.communityLink) end end)
communityButton.Position=UDim2.new(0,10,1,-150);communityButton.Visible=prefs.communityLink~=""
local function sidebarLayout()
 communityButton.Visible=prefs.communityLink~=""
 sidebar.Size=UDim2.new(0,SW,1,prefs.communityLink~="" and -158 or -120)
end
local userScale = prefs.scale
local mainX,mainY=0.5,0.5
local mainX,mainY=0.5,0.5 -- opening position is session-local, independent of legacy saved drag offsets
local searchBox, searchInput, expansionKeys, onSearchInput
local function fitPosition()
 local cam=workspace.CurrentCamera;local vp=cam and cam.ViewportSize or Vector2.new(1280,720)
 local scale=uiScale.Scale
 local availableX=math.max(0,vp.X/scale-W-16);local availableY=math.max(0,vp.Y/scale-H-48)
 window.Position=UDim2.fromOffset(availableX*mainX+8,availableY*mainY+24)
end
local function applyScale()
	Ui.cancelAnimation(uiScale)
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local fit = math.min((vp.X - 24) / W, (vp.Y - 24) / H)
	uiScale.Scale = math.max(0.2, math.min(userScale, fit))
    headerTitle.Visible=W>=760;headerDesc.Visible=W>=760
    fitPosition()
end
applyScale()
onWindowDragged=function(commit)
 local cam=workspace.CurrentCamera;local vp=cam and cam.ViewportSize or Vector2.new(1280,720)
 local x=window.Position.X.Scale*vp.X/uiScale.Scale+window.Position.X.Offset
 local y=window.Position.Y.Scale*vp.Y/uiScale.Scale+window.Position.Y.Offset
 mainX=math.clamp((x-8)/math.max(1,vp.X/uiScale.Scale-W-16),0,1)
 mainY=math.clamp((y-24)/math.max(1,vp.Y/uiScale.Scale-H-48),0,1)
 fitPosition()
end
local viewportScope
local function bindViewport()
 if viewportScope then viewportScope:close() end
 if hub.closed then return end
 viewportScope=Scope.new("main-viewport")
 if workspace.CurrentCamera then viewportScope:connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"),applyScale) end
 applyScale()
end
hub:connect(workspace:GetPropertyChangedSignal("CurrentCamera"),bindViewport)
hub:add(function() if viewportScope then viewportScope:close() end end)
bindViewport()

local minimized = false
local statusBar
local grip
local syncBlur
local function setMinimized(on)
 minimized=on
 Ui.cancelAnimation(window);Ui.cancelAnimation(uiScale)
 window.Size=UDim2.fromOffset(W,H)
 if statusBar then statusBar.show(on) end
 if grip then grip.Visible=not on end
 if on then
  Ui.animate(uiScale,{Scale=uiScale.Scale*0.97},0.22)
  Ui.animate(window,{GroupTransparency=1},0.22,function()
   if minimized then window.Visible=false;body.Visible=false end
  end)
 else
  window.Visible=true;body.Visible=true
  mainX,mainY=0.5,0.5
  applyScale()
  local target=uiScale.Scale
  uiScale.Scale=target*0.97
  Ui.animate(uiScale,{Scale=target},0.22)
  Ui.animate(window,{GroupTransparency=0},0.22)
 end
 if syncBlur then syncBlur() end
end

-- Resize grip in the bottom-right corner: drag to resize; the size is saved in the active config.
local MIN_W, MIN_H, MAX_W, MAX_H = 520, 360, 1100, 820
grip = Ui.new("TextButton", {
	AutoButtonColor = false,
	BackgroundTransparency = 1,
	Text = "",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -3, 1, -3),
	Size = UDim2.fromOffset(18, 18),
	ZIndex = 5,
	Parent = window,
})
grip:SetAttribute("ResizeGrip", true)
for i = 0, 2 do
	for j = 0, 2 - i do
		Ui.new("Frame", { Size = UDim2.fromOffset(2, 2), Position = UDim2.fromOffset(15 - 5 * i, 15 - 5 * j), BackgroundColor3 = Theme.faint, BorderSizePixel = 0, ZIndex = 5, Parent = grip })
	end
end
local function setWindowSize(w, h)
	W = math.clamp(math.floor(w), MIN_W, MAX_W)
	H = math.clamp(math.floor(h), MIN_H, MAX_H)
	if not minimized then
		window.Size = UDim2.fromOffset(W, H)
	end
end
do
	local resizing, startPos, startW, startH
	local function isPress(t)
		return t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch
	end
	hub:connect(grip.InputBegan, function(input)
		if isPress(input.UserInputType) then
			resizing, startPos, startW, startH = true, input.Position, W, H
		end
	end)
	hub:connect(UserInputService.InputChanged, function(input)
		local t = input.UserInputType
		if resizing and (t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch) then
			local s = uiScale.Scale -- mouse moves in screen pixels; the window is scaled
			setWindowSize(startW + (input.Position.X - startPos.X) / s, startH + (input.Position.Y - startPos.Y) / s)
		end
	end)
	hub:connect(UserInputService.InputEnded, function(input)
		if resizing and isPress(input.UserInputType) then
			resizing = false
			prefs.winW, prefs.winH = W, H
			savePrefs()
			applyScale()
		end
	end)
end
hub:connect(minBtn.Activated, function()
	setMinimized(not minimized)
end)
-- Toggle key. While `onKeyCaptured` is set, the next keyboard key is captured instead (Esc cancels).
local toggleKey = Enum.KeyCode[prefs.toggleKey]
local onKeyCaptured
local onSafeKey
local keyConflict
hub:connect(UserInputService.InputBegan, function(input, processed)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end
	if UserInputService:GetFocusedTextBox() then
  if onSearchInput then onSearchInput(input,processed) end
  return
 end
 if onKeyCaptured then
  local done=onKeyCaptured;onKeyCaptured=nil;done(input.KeyCode);return
 end
 if onSearchInput and onSearchInput(input,processed) then return end
 if prefs.safeZoneKey~="NONE" and input.KeyCode.Name==prefs.safeZoneKey and onSafeKey then onSafeKey();return end
 if processed then return end
 if expansionKeys and expansionKeys(input) then return end
 if input.KeyCode==toggleKey then setMinimized(not minimized) end
end)

bootStep("Main window and input handlers initialized")

-- ===================================================================== tabs
local pages, order, refreshers = {}, 0, {}
local NAV={roll=10,styles=20,dash=30,combat=40,visuals=50,player=60,world=70,safe=80,teleports=90,utility=100,config=110,settings=1000,diag=900,session=910}
local ICON={roll="↻",styles="✦",teleports="↗",dash="⌂",combat="◇",trigger="⊕",sounds="♪",friends="♧",visuals="◉",player="♙",world="☼",safe="↗",utility="ϟ",config="▣",settings="☷"}
local activePage
local navMarker=Ui.new("Frame",{Name="NavigationIndicator",BackgroundColor3=Theme.accent,Size=UDim2.fromOffset(3,18),ZIndex=4,Visible=false,Parent=body});Ui.corner(navMarker,2)
local function moveMarker()
 local selected=pages[activePage]
 if not selected then return end
 local button=selected.btn
 local factor=math.max(uiScale.Scale,0.2)
 local position=button.AbsolutePosition or Vector2.new()
 local origin=body.AbsolutePosition or Vector2.new()
 local scrollPosition=sidebar.AbsolutePosition or Vector2.new()
 local scrollSize=sidebar.AbsoluteSize or Vector2.new()
 local buttonSize=button.AbsoluteSize or Vector2.new()
 local offset=Vector2.new((position.X-origin.X)/factor,(position.Y-origin.Y)/factor)
 local within=button.Parent==settingsDock or (position.Y>=scrollPosition.Y and position.Y+buttonSize.Y<=scrollPosition.Y+scrollSize.Y)
 navMarker.Visible=within
 Ui.animate(navMarker,{Position=UDim2.fromOffset(offset.X,offset.Y+7)},0.18)
end
hub:connect(sidebar:GetPropertyChangedSignal("CanvasPosition"),moveMarker)
hub:connect(body:GetPropertyChangedSignal("AbsoluteSize"),moveMarker)
local function selectPage(id)
 local changed=activePage~=id
 activePage=id
 for key, p in pairs(pages) do
		local on = key == id
		p.page.Visible = on
        if p.preview then p.preview.Visible=on end
        if on then Ui.set(headerTitle,"Text",p.label);Ui.set(headerDesc,"Text",p.description) end
		p.ind.Visible = false
		p.btn:SetAttribute("Selected",on)
        Ui.animate(p.btn,{BackgroundTransparency=on and 0 or 1},0.16)
        Ui.animate(p.lbl,{TextColor3=on and Theme.text or Theme.muted},0.16)
        if on and changed then
         p.page.Position=UDim2.fromOffset(0,6)
         Ui.animate(p.page,{Position=UDim2.new()},0.2)
        end
		if on and p.onShow then
			p.onShow()
		end
	end
 moveMarker()
end

local function addPage(id, label, description)
	order += 1
	local btn = Ui.new("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = Theme.surface2,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 32),
		Text = "",
		LayoutOrder = NAV[id] or order,
		Parent = id=="settings" and settingsDock or sidebar,
	})
	btn.Name="Nav_"..id
 btn:SetAttribute("NavPage",id)
	Ui.corner(btn)
	local ind = Ui.new("Frame", { BackgroundColor3 = Theme.accent, Size = UDim2.fromOffset(3, 16), Position = UDim2.new(0, 0, 0.5, -8), Visible = false, Parent = btn })
	Ui.corner(ind, 2)
	local lbl = Ui.text(btn, label, { size = UDim2.new(1, -34, 1, 0), font = Theme.fontMedium, color = Theme.muted })
	lbl.Position = UDim2.fromOffset(30, 0)
    local icon=Ui.navIcon(btn,id)
    icon.Position=UDim2.fromOffset(6,7)
	local page = Ui.scroll(content, { Visible = false })
    page:SetAttribute("SearchPage",id)
    page.Name="ErviPage_"..id
	Ui.pad(page, 14, 16, 14, 14)
	Ui.list(page, 10)
	pages[id] = { page = page, btn = btn, ind = ind, lbl = lbl, label=label, description=description or "Ervi Hub · "..label }
    if id=="diag" or id=="session" then btn.Visible=false end
	hub:connect(btn.MouseEnter,function() if not btn:GetAttribute("Selected") then Ui.animate(btn,{BackgroundTransparency=0.45}) end end)
 hub:connect(btn.MouseLeave,function() Ui.animate(btn,{BackgroundTransparency=btn:GetAttribute("Selected") and 0 or 1}) end)
 hub:connect(btn.Activated, function() selectPage(id) end)
	return page, pages[id]
end

-- fn runs at 10 Hz while its page is visible; a refresher that errors is disabled after logging once.
local function onRefresh(id, name, fn)
	table.insert(refreshers, { id = id, name = name, fn = fn })
end

local function badge(ok, okText, badText)
	return ok and okText or badText, ok and Theme.good or Theme.bad
end

-- ===================================================================== features
local m1 = makeM1(hub, playerGui, function() return prefs end, savePrefs)
local safeZone = makeSafeZone(hub)
local targets = makeTargets(hub, function() return prefs end, safeZone)
local observer = makeObserver(hub, log)
local autoRoll = AutoRoll.new(makeAdapter(), { resumeAfterDeath = prefs.resumeAfterDeath })
table.insert(onStop, function()
	autoRoll:dispose()
end)
table.insert(onStop, function()
	observer.stop("hub closed")
end)
local session = makeSession(hub, log)
table.insert(onStop, session.stop)
session.setAntiAfk(prefs.antiAfk)
session.setReconnect(prefs.reconnect)
session.setAutoExec(prefs.autoExec)
local prompts = makePrompts(hub, log)
table.insert(onStop, function()
	prompts.set(false) -- restores the original hold times
end)
prompts.set(prefs.instantPrompts)
local runEndedAt

bootStep("Core features initialized")

-- ===================================================================== Dashboard
local dash = addPage("dash", "Home", "Your session at a glance")
do
	local c1 = Ui.card(dash, "Your style", 1)
	local sStyle, sOdds, sTier, sCd = Ui.kv(c1, "Equipped", 1), Ui.kv(c1, "Odds", 2), Ui.kv(c1, "Rarity", 3), Ui.kv(c1, "M1 cooldown (game config)", 4)

	local c2 = Ui.card(dash, "Rolling", 2)
	local setPill = Ui.pill(c2, 1)
	local sNext, sLuck, sAuto = Ui.kv(c2, "Status", 2), Ui.kv(c2, "Luck attributes", 3), Ui.kv(c2, "Auto Roll", 4)

	local c3 = Ui.card(dash, "Hub health", 3)
	local hData, hRemote, hUi, hVer, hCyb = Ui.kv(c3, "Style data (AttackData)", 1), Ui.kv(c3, "Roll request (RollAttack)", 2), Ui.kv(c3, "Game roll UI (MainUI)", 3), Ui.kv(c3, "Place version", 4), Ui.kv(c3, "M1 HUD", 5)

	local c4 = Ui.card(dash, "Performance", 4)
	local pFps, pPing = Ui.kv(c4, "FPS", 1), Ui.kv(c4, "Ping", 2)

	local c5 = Ui.card(dash, "Recent log", 5)
	local logText = Ui.text(c5, "", { textSize = Theme.size.tiny, font = Theme.mono, color = Theme.muted, order = 1 })

	onRefresh("dash", "dashboard", function()
		local eq = Game.equipped()
		local style = eq and Game.style(eq.name)
		sStyle(eq and eq.name or "none", eq and Game.tierColor(eq.name, eq.chance) or Theme.muted)
		sOdds(eq and eq.chance and ("1 in %d"):format(eq.chance) or "-")
		sTier(eq and Game.tierOf(eq.name, eq.chance) or "-")
		sCd(style and style.Cooldown and ("%ss"):format(tostring(style.Cooldown)) or "-")

		local ok, why = Game.rollStatus()
		setPill(ok and "Ready to roll" or "Not ready", ok and "good" or "warn")
		sNext(why, ok and Theme.good or Theme.text)
		sLuck(("Luck %s · Trait %s"):format(tostring(Game.attr("Luck") or "-"), tostring(Game.attr("TraitLuck") or "-")))
		sAuto(autoRoll.state, autoRoll:isRunning() and Theme.info or Theme.muted)

		local ad, adErr = Game.attackData()
		hData(badge(ad ~= nil, ("%d styles"):format(#Game.styles()), "missing: " .. tostring(adErr)))
		hRemote(badge(Game.rollRemote() ~= nil, "found", "missing"))
		hUi(badge(Game.mainUI() ~= nil, "found", "missing"))
		local same = game.PlaceVersion == Game.KNOWN_PLACE_VERSION
		hVer(("%d (data from %d)"):format(game.PlaceVersion, Game.KNOWN_PLACE_VERSION), same and Theme.good or Theme.warn)
		hCyb(m1.enabled and "on" or "off", m1.enabled and Theme.good or Theme.muted)
		pFps(tostring(metrics.fps), metrics.fps >= 50 and Theme.good or metrics.fps >= 30 and Theme.warn or Theme.bad)
		pPing(("%d ms"):format(metrics.ping))
		Ui.set(logText, "Text", #logs > 0 and table.concat(logs, "\n", 1, math.min(6, #logs)) or "No events yet.")
	end)
end

-- ===================================================================== Auto Roll
local rollPage = addPage("roll", "Auto Roll")
do
	local target = { mode = "chance", min = 500 }
	local styleNames = {}

	local cT = Ui.card(rollPage, "Target", 1, "Auto Roll stops before any further roll as soon as a result meets this target.")
	local modeRow = Ui.row(cT, 1)
	local chanceBox = Ui.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = cT })
	Ui.list(chanceBox, 6)
	local styleBox = Ui.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3, Visible = false, Parent = cT })
	Ui.list(styleBox, 6)
	local summary = Ui.text(cT, "", { textSize = Theme.size.small, color = Theme.info, order = 4 })

	local modeChance, modeStyle
	local presetButtons = {}
	local function refreshTarget()
		Ui.select(modeChance, target.mode == "chance")
		Ui.select(modeStyle, target.mode == "style")
		chanceBox.Visible = target.mode == "chance"
		styleBox.Visible = target.mode == "style"
		for n, b in pairs(presetButtons) do
			Ui.select(b, target.mode == "chance" and target.min == n)
		end
		local t = target.mode == "chance" and target or { mode = "style", names = styleNames }
		if not Rarity.validTarget(t) then
			summary.Text = "Pick a target."
			return
		end
		local released, hits = 0, 0
		for _, s in ipairs(Game.styles()) do
			if not s.Unreleased then
				released += 1
				if Rarity.qualifies(t, s.Name, s.Chance) then
					hits += 1
				end
			end
		end
		summary.Text = ("Target: %s.  %s"):format(
			Rarity.describe(t),
			released > 0 and ("%d of %d released styles qualify."):format(hits, released) or "(style data unavailable - result odds come from the server reply)"
		)
	end

	modeChance = Ui.button(hub, modeRow, "Odds threshold", { width = 140 }, function()
		target = { mode = "chance", min = target.min or 500 }
		refreshTarget()
	end)
	modeStyle = Ui.button(hub, modeRow, "Exact style", { width = 140 }, function()
		target = { mode = "style", names = styleNames, min = target.min }
		refreshTarget()
	end)

	Ui.text(chanceBox, "Stop on any style whose odds are 1 in N or rarer (game Chance >= N).", { textSize = Theme.size.small, color = Theme.muted, order = 1 })
	local presetRow = Ui.row(chanceBox, 2)
	for i, n in ipairs({ 100, 195, 500, 1000, 2500, 5000 }) do
		presetButtons[n] = Ui.button(hub, presetRow, "1/" .. n, { width = 66, order = i }, function()
			target = { mode = "chance", min = n }
			refreshTarget()
		end)
	end
	local customRow = Ui.row(chanceBox, 3)
	Ui.text(customRow, "Custom N:", { size = UDim2.new(0, 70, 1, 0), textSize = Theme.size.small, color = Theme.muted })
	local exactN
	local customN = Ui.slider(hub, customRow, "Custom N", {
		min = 1,
		max = 5000,
		step = 1,
		value = prefs.customN,
		order = 1,
		format = function(value)
			return ("%d"):format(value)
		end,
	}, function(value)
		prefs.customN = value
		if exactN then
			exactN.Text = tostring(value)
		end
		savePrefs()
		target = { mode = "chance", min = value }
		refreshTarget()
	end)
	customN.node.Name = "Setting_customN"
	customN.node:SetAttribute("SettingKey", "customN")
	exactN = Ui.input(hub, customRow, "Exact N", {
		width = 90,
		order = 2,
		text = tostring(prefs.customN),
	}, function(text)
		local value = tonumber(text)
		if value and value == math.floor(value) then
			value = math.clamp(value, 1, 5000)
			customN.set(value)
			prefs.customN = value
			exactN.Text = tostring(value)
			savePrefs()
			target = { mode = "chance", min = value }
			refreshTarget()
		end
	end)
	exactN.Name = "Input_customN"

	Ui.text(styleBox, "Stop only on these exact style names (comma separated, case-sensitive).", { textSize = Theme.size.small, color = Theme.muted, order = 1 })
	local styleCheck = Ui.text(styleBox, "", { textSize = Theme.size.small, color = Theme.warn, order = 3 })
	Ui.input(hub, styleBox, "e.g. Cyborg, Knockback Stick", { size = UDim2.new(1, 0, 0, Theme.rowH), order = 2 }, function(text)
		styleNames = {}
		local unknown = {}
		for raw in text:gmatch("[^,]+") do
			local name = raw:match("^%s*(.-)%s*$")
			if name ~= "" then
				styleNames[name] = true
				if #Game.styles() > 0 and not Game.style(name) then
					table.insert(unknown, name)
				end
			end
		end
		target = { mode = "style", names = styleNames }
		styleCheck.Text = #unknown > 0 and ("Not in the game's style list: " .. table.concat(unknown, ", ")) or ""
		refreshTarget()
	end)

	-- Run card
	local cR = Ui.card(rollPage, "Run", 2)
	local runRow = Ui.row(cR, 1, 32)
	local setStartEnabled, setStopEnabled, setContEnabled
	local setState = Ui.pill(cR, 2)
	local reason = Ui.text(cR, "", { textSize = Theme.size.small, order = 3 })
	local kRun, kSent, kGot, kLast, kReady = Ui.kv(cR, "Running for", 4), Ui.kv(cR, "Rolls sent", 5), Ui.kv(cR, "Results received", 6), Ui.kv(cR, "Last result", 7), Ui.kv(cR, "Readiness", 8)

	local function currentTarget()
		if target.mode == "style" then
			return { mode = "style", names = styleNames }
		end
		return target
	end
	local function startWith(opts)
		local ok, err = autoRoll:start(currentTarget(), opts)
		if not ok then
			reason.Text = err
		end
	end
	setStartEnabled = select(2, Ui.button(hub, runRow, "Start", { variant = "primary", width = 100 }, safe("AutoRoll", function()
		startWith(nil)
	end)))
	setStopEnabled = select(2, Ui.button(hub, runRow, "Stop", { variant = "danger", width = 100, order = 1 }, function()
		autoRoll:stop("Stopped by user")
	end))
	setContEnabled = select(2, Ui.button(hub, runRow, "Continue", { width = 120, order = 2 }, safe("AutoRoll", function()
		startWith({ acceptRare = true, keepStats = true })
	end)))

	local KIND = { Found = "good", Paused = "warn", Idle = "idle", Error = "bad" }
	local function syncRun()
		local running = autoRoll:isRunning()
		setState(autoRoll.state, KIND[autoRoll.state] or "info")
		reason.Text = autoRoll.reason
		setStartEnabled(not running)
		setStopEnabled(running)
		setContEnabled(autoRoll.state == "Paused")
		if not running and autoRoll.stats.startedAt and not runEndedAt then
			runEndedAt = os.clock()
		elseif running then
			runEndedAt = nil
		end
	end
	local loggedState
	autoRoll:onChange(function()
		syncRun()
		if autoRoll.state ~= loggedState then -- reason changes every tick while waiting; log states only
			loggedState = autoRoll.state
			log("AutoRoll", autoRoll.state .. " - " .. autoRoll.reason)
		end
	end)

	local cH = Ui.card(rollPage, "Recent results", 4)
	local histText = Ui.text(cH, "No rolls yet.", { textSize = Theme.size.small, font = Theme.mono, color = Theme.muted, order = 1 })

	local cN = Ui.card(rollPage, "How it works", 5)
	Ui.text(cN, table.concat({
		"• Sends the same no-argument roll request the game's own Roll button sends, only when the game itself would allow a roll (alive, in the arena, cooldown finished, no roll animation or confirm open).",
		"• One request at a time, never retried. Timeouts, empty results or uncertain cooldowns pause instead of rolling again.",
		"• A qualifying result is kept: zero further rolls. Your current style is checked before the first roll.",
		"• The game's roll animation does not play for hub rolls; the result shows here and on the Roll button.",
		"• Status: NOT LIVE TESTED in the game yet. Logic is mock-tested offline.",
	}, "\n"), { textSize = Theme.size.small, color = Theme.muted, order = 1 })

	onRefresh("roll", "autoroll", function()
		syncRun()
		local s = autoRoll.stats
		local endT = autoRoll:isRunning() and os.clock() or runEndedAt
		kRun(s.startedAt and endT and ("%ds"):format(math.floor(endT - s.startedAt)) or "-")
		kSent(tostring(s.attempted))
		kGot(tostring(s.confirmed))
		local last = autoRoll.last
		kLast(last and ("%s · 1/%s · %s"):format(last.name, tostring(last.chance or "?"), last.tier) or "-", last and Game.tierColor(last.name, last.chance) or nil)
		local _, why = Game.rollStatus()
		kReady(why)
		local lines = {}
		for i = 1, math.min(8, #autoRoll.history) do
			local h = autoRoll.history[i]
			table.insert(lines, ("#%-4d %-18s 1/%-6s %s"):format(h.n, h.name, tostring(h.chance or "?"), h.tier))
		end
		Ui.set(histText, "Text", #lines > 0 and table.concat(lines, "\n") or "No rolls yet.")
	end)
	pages.roll.onShow = refreshTarget
	refreshTarget()
	syncRun()
end

-- ===================================================================== Combat
do
    local card=Ui.card(pages.roll.page,"Respawn recovery",10,"Pauses while dead, then waits for normal arena and roll readiness. Safe Zone movement remains a separate manual toggle.")
    local toggle=Ui.toggle(hub,card,"Resume Auto Roll After Death",nil,prefs.resumeAfterDeath,function(on)
        prefs.resumeAfterDeath=on; autoRoll.opts.resumeAfterDeath=on; savePrefs()
    end,1)
    table.insert(syncs,function() toggle.set(prefs.resumeAfterDeath,true); autoRoll.opts.resumeAfterDeath=prefs.resumeAfterDeath end)
end
local combat = addPage("combat", "Combat")
do
    local card = Ui.card(combat, "M1 cooldown evidence", 0, "Candidate AttackReadyAt timing for any style. Server-time semantics need a live capture; UNKNOWN means no usable evidence. Missing or stale timing stays UNKNOWN.")
    local toggle = Ui.toggle(hub, card, "Show M1 cooldown HUD", "Drag the title; resize from the corner. Layout is saved in the active config.", prefs.m1Enabled, function(on) prefs.m1Enabled=on; m1.setEnabled(on); savePrefs() end, 1)
    m1.onChanged = function(on) toggle.set(on, true) end
    m1.setEnabled(prefs.m1Enabled)
    table.insert(syncs, function()
        toggle.set(prefs.m1Enabled, true); m1.setEnabled(prefs.m1Enabled)
        if m1.refreshLayout then m1.refreshLayout() end
    end)
    Ui.button(hub, card, "Reset M1 HUD layout", {order=5,width=180}, function()
        prefs.m1X,prefs.m1Y,prefs.m1W,prefs.m1H=0.5,0.55,330,180
        if m1.refreshLayout then m1.refreshLayout() end
        savePrefs()
    end)
    local setState = Ui.kv(card, "Observed M1 state", 2)
    local setEvidence = Ui.kv(card, "Timing evidence", 3)
    local setHealth = Ui.kv(card, "Your current health", 4)
    onRefresh("combat", "m1 evidence", function()
        local snapshot = m1.snapshot()
        setState((snapshot.style or "none") .. " · " .. (snapshot.remaining and ("%.2fs / "):format(snapshot.remaining) or "") .. snapshot.status)
        setEvidence(snapshot.evidence)
        local h = Game.humanoid()
        setHealth(h and h.MaxHealth > 0 and ("%.0f%%"):format(math.clamp(h.Health / h.MaxHealth * 100, 0, 100)) or "unavailable")
    end)
end
do
	local c2 = Ui.card(combat, "Equipped style (game config)", 2, "CONFIGURED values from the game's AttackData. Real server timing may differ.")
	local kKind, kDmg, kCd, kRange, kHp = Ui.kv(c2, "Kind", 1), Ui.kv(c2, "Damage", 2), Ui.kv(c2, "M1 cooldown", 3), Ui.kv(c2, "Range", 4), Ui.kv(c2, "Health / Speed", 5)
	local desc = Ui.text(c2, "", { textSize = Theme.size.small, color = Theme.muted, order = 6 })

	onRefresh("combat", "combat", function()
		local eq = Game.equipped()
		local s = eq and Game.style(eq.name)
		local function f(v, unit)
			return v ~= nil and (tostring(v) .. (unit or "")) or "-"
		end
		kKind(f(s and s.Kind))
		kDmg(f(s and s.Damage))
		kCd(f(s and s.Cooldown, "s"))
		kRange(f(s and s.Range))
		kHp(s and ("%s / %s"):format(f(s.Health), f(s.Speed)) or "-")
		Ui.set(desc, "Text", s and s.Description or (eq and "No game data for this style." or "No style equipped."))
	end)
end

local safeKeyButtons={}
local function syncSafeKeys()
 for _,button in ipairs(safeKeyButtons) do if button.Parent then Ui.set(button,"Text",prefs.safeZoneKey) end end
end
local function addSafeKeyControl(parent,order)
 local row=Ui.new("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=order or 5,Parent=parent})
 Ui.list(row,4)
 Ui.text(row,"Safe Zone toggle key",{font=Theme.fontMedium,order=0})
 local button
 button=Ui.button(hub,row,prefs.safeZoneKey,{size=UDim2.new(1,0,0,32),order=1},function()
  if onKeyCaptured then return end
  local focused=UserInputService:GetFocusedTextBox();if focused then focused:ReleaseFocus() end
  button.Text="Press a key · Backspace = NONE · Esc = cancel"
  onKeyCaptured=function(kc)
   if kc==Enum.KeyCode.Backspace then prefs.safeZoneKey="NONE";savePrefs()
   elseif kc~=Enum.KeyCode.Escape and isKey(kc.Name) then
    if keyConflict and keyConflict(kc.Name,"safeZoneKey") then safeZone.status="Key conflict: choose a different key"
    else prefs.safeZoneKey=kc.Name;savePrefs() end
   end
   syncSafeKeys()
  end
 end)
 button:SetAttribute("SettingKey","safeZoneKey");table.insert(safeKeyButtons,button)
 Ui.register(button,"Safe Zone toggle key","Bind, clear, or change Safe Zone key; works with main GUI hidden")
 Ui.text(row,"NONE = unbound. Backspace clears; Esc cancels. Ignored while typing.",{textSize=Theme.size.tiny,color=Theme.muted,order=2})
 return button
end
 table.insert(syncs,syncSafeKeys)

-- ===================================================================== Safe Zone
local safePage = addPage("safe", "Safe Zone", "Destination, return origin and keybind")
local teleportsPage=addPage("teleports","Teleports","Server travel")
do
    local card=Ui.card(safePage,"Fixed Safe Zone",1,"Destination: X 278.78 · Y -16.30 · Z 7.82. ON records your origin and holds you here. OFF returns you to that origin before releasing movement.")
    local toggle=Ui.toggle(hub,card,"Enable Safe Zone", "OFF returns once to your activation origin. Death and server corrections release without a return or retry.",false,safeZone.setEnabled,1)
    safeZone.onChanged=function(on) toggle.set(on,true) end
    local coords=Ui.text(card,"",{order=2,textSize=Theme.size.small})
    local status=Ui.text(card,"",{order=3,textSize=Theme.size.small,color=Theme.muted})
    local bind=Ui.text(card,"",{order=4,textSize=Theme.size.small})
    addSafeKeyControl(card,5)
    onSafeKey=safeZone.keyAction
    onRefresh("safe","safe zone",function()
        Ui.set(coords,"Text",safeZone.describe())
        Ui.set(status,"Text",safeZone.status)
        Ui.set(bind,"Text","Key: " .. prefs.safeZoneKey .. " · toggles Safe Zone ON/OFF. Assign a key in Settings; Backspace clears it.")
    end)
end

-- Manual-combat alternative while no authorized movement/attack API is known.
do
    local card=Ui.card(combat,"Auto Kill · manual combat",3,"Selects an eligible low-health player. Approach and attack manually. Safe Zone offers a local return and position hold; Auto M1 remains unavailable.")
    local enabled=Ui.toggle(hub,card,"Enable target selection",nil,prefs.targetEnabled,function(on)
        prefs.targetEnabled=on; targets.refresh(); savePrefs()
    end,1)
    local threshold=Ui.slider(hub,card,"Target HP threshold",{min=1,max=100,step=1,value=prefs.targetHp,order=2,format=function(v) return ("< %d%%"):format(v) end},function(v)
        prefs.targetHp=v; targets.refresh(); savePrefs()
    end)
    Ui.input(hub,card,"HP threshold: 1–100",{order=3},function(text)
        local n=tonumber(text)
        if n and n==n and math.abs(n)<math.huge then prefs.targetHp=math.clamp(math.floor(n),1,100); threshold.set(prefs.targetHp,true); targets.refresh(); savePrefs() end
    end)
    local auto=Ui.toggle(hub,card,"Auto M1 (request only)","ON records your preference; no automated attacks run without a supported game mechanic.",prefs.autoM1Requested,function(on)
        prefs.autoM1Requested=on; savePrefs()
    end,4)
    local state=Ui.kv(card,"State",5)
    local selected=Ui.kv(card,"Selected target",6)
    local hp=Ui.kv(card,"Target HP",7)
    local attacks=Ui.kv(card,"Auto M1 availability",8)
    table.insert(syncs,function()
        enabled.set(prefs.targetEnabled,true); threshold.set(prefs.targetHp,true); auto.set(prefs.autoM1Requested,true); targets.refresh()
    end)
    onRefresh("combat","target selection",function()
        state(targets.state.state); selected(targets.state.name or "none")
        hp(targets.state.hp and ("%.1f%%"):format(targets.state.hp) or "—")
        attacks(prefs.autoM1Requested and "ON requested · unsupported · no attacks sent" or "OFF · manual M1 and skills")
    end)
end

-- ===================================================================== Styles
local stylesPage, stylesEntry = addPage("styles", "Styles")
do
	local controls = Ui.row(stylesPage, 1, 32)
	local query, ownedOnly, showUnreleased = "", false, false
	local rows = {}
	local countText = Ui.text(stylesPage, "", { textSize = Theme.size.small, color = Theme.muted, order = 2 })
	local listCard = Ui.card(stylesPage, nil, 3)
	local built = false

	local function apply()
		local owned = Game.owned()
		local shown = 0
		for _, r in ipairs(rows) do
			local s = r.style
			local isOwned = owned ~= nil and owned[s.Name] == true
			r.own.Text = isOwned and "owned" or ""
			local vis = (showUnreleased or not s.Unreleased)
				and (not ownedOnly or isOwned)
				and (query == "" or s.Name:lower():find(query, 1, true) ~= nil)
			r.frame.Visible = vis
			if vis then
				shown += 1
			end
		end
		countText.Text = ("%d of %d styles shown%s"):format(shown, #rows, Game.owned() == nil and " · owned list unavailable" or "")
	end

	local function build()
		if built then
			return
		end
		built = true
		local list = table.clone(Game.styles())
		if #list == 0 then
			local _, err = Game.attackData()
			Ui.text(listCard, "Style data unavailable: " .. tostring(err), { color = Theme.warn })
			return
		end
		table.sort(list, function(a, b)
			return (a.Chance or 0) < (b.Chance or 0)
		end)
		for i, s in ipairs(list) do
			local f = Ui.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = i, Parent = listCard })
			local name = Ui.text(f, s.Name .. (s.Unreleased and "  (unreleased)" or ""), { size = UDim2.new(0.38, 0, 1, 0), font = Theme.fontMedium, textSize = Theme.size.small, color = Game.tierColor(s.Name, s.Chance) or Theme.text })
			name.TextTruncate = Enum.TextTruncate.AtEnd
			name.TextWrapped = false
			local function col(text, x, w, color)
				local l = Ui.text(f, text, { size = UDim2.new(w, 0, 1, 0), textSize = Theme.size.small, font = Theme.mono, color = color or Theme.muted })
				l.Position = UDim2.fromScale(x, 0)
				l.TextWrapped = false
				return l
			end
			col("1/" .. tostring(s.Chance), 0.38, 0.16, Theme.text)
			col(Game.tierOf(s.Name, s.Chance), 0.54, 0.18)
			col(s.Cooldown and ("cd %ss"):format(tostring(s.Cooldown)) or "", 0.72, 0.14)
			local own = col("", 0.86, 0.14, Theme.good)
			table.insert(rows, { frame = f, style = s, own = own })
		end
		apply()
	end

	Ui.input(hub, controls, "Search styles", { width = 170 }, function(text)
		query = text:lower()
		apply()
	end)
	local ownBtn, unrelBtn
	ownBtn = Ui.button(hub, controls, "Owned only", { width = 110, order = 1 }, function()
		ownedOnly = not ownedOnly
		ownBtn.BackgroundColor3 = ownedOnly and Theme.accent or Theme.raised
		apply()
	end)
	unrelBtn = Ui.button(hub, controls, "Unreleased", { width = 100, order = 2 }, function()
		showUnreleased = not showUnreleased
		unrelBtn.BackgroundColor3 = showUnreleased and Theme.accent or Theme.raised
		apply()
	end)
	stylesEntry.onShow = build
end

-- ===================================================================== Diagnostics
local diag = addPage("diag", "Diagnostics")
do
	local c1 = Ui.card(diag, "Roll observer (read-only)", 1, "1) Press Start capture.  2) Roll MANUALLY 3 times with the game's Roll button, waiting for each result.  3) Press Copy report and paste it into the chat. Records only roll attributes and roll UI text; max 90 s.")
	local row = Ui.row(c1, 1, 32)
	local setPill = Ui.pill(c1, 2)
	local kEv, kLeft = Ui.kv(c1, "Events captured", 3), Ui.kv(c1, "Time left", 4)
	local preview = Ui.input(hub, c1, "Report appears here. If Copy fails: click inside, Ctrl+A, Ctrl+C.", {
		size = UDim2.new(1, 0, 0, 140),
		multiline = true,
		font = Theme.mono,
		textSize = Theme.size.tiny,
		order = 5,
	})

	local function copyText(text, what)
		preview.Text = text
		local ok, err = Game.copy(text)
		log("Diagnostics", ok and (what .. " copied to clipboard") or (what .. " shown below - copy it manually (" .. tostring(err) .. ")"), not ok)
	end
	Ui.button(hub, row, "Start capture", { variant = "primary", width = 120 }, safe("Diagnostics", function()
		observer.start(90)
	end))
	Ui.button(hub, row, "Stop", { width = 80, order = 1 }, function()
		observer.stop("stopped by user")
	end)
	Ui.button(hub, row, "Copy report", { width = 110, order = 2 }, safe("Diagnostics", function()
		copyText(observer.report(), "report")
	end))

	local c2 = Ui.card(diag, "Environment snapshot", 2, "Place version, capability checks, roll-related attributes. No capture needed.")
	Ui.button(hub, c2, "Copy snapshot", { width = 130, order = 1 }, safe("Diagnostics", function()
		copyText(observer.snapshot(), "snapshot")
	end))

	local c3 = Ui.card(diag, "Hub log", 3)
	local logText = Ui.text(c3, "", { textSize = Theme.size.tiny, font = Theme.mono, color = Theme.muted, order = 1 })
	Ui.button(hub, c3, "Copy log", { width = 100, order = 2 }, function()
		copyText(table.concat(logs, "\n"), "log")
	end)

	onRefresh("diag", "diagnostics", function()
		setPill(observer.running and "Capturing" or "Idle", observer.running and "info" or "idle")
		kEv(tostring(#observer.events))
		kLeft(observer.running and ("%ds"):format(math.max(0, math.ceil(observer.endsAt - os.clock()))) or "-")
		Ui.set(logText, "Text", #logs > 0 and table.concat(logs, "\n", 1, math.min(15, #logs)) or "No events yet.")
	end)
end

-- ===================================================================== Session
local sessionPage = addPage("session", "Session")
do
	local function statusLine(card, order)
		return Ui.text(card, "", { textSize = Theme.size.small, color = Theme.muted, order = order })
	end
	local c1 = Ui.card(sessionPage, "Anti-AFK", 1, "Roblox disconnects you after about 20 minutes idle. When Roblox reports you idle (about every 2 minutes) this sends one harmless right-click so you stay connected - the widely used method. Needs executor permission for VirtualUser.")
	local tAfk = Ui.toggle(hub, c1, "Anti-AFK", nil, prefs.antiAfk, function(v)
		prefs.antiAfk = v
		session.setAntiAfk(v)
		savePrefs()
	end, 1)
	local afkLine = statusLine(c1, 2)

	local c2 = Ui.card(sessionPage, "Auto-reconnect", 2, "If Roblox shows a disconnect error, rejoin this game automatically (5 tries, 10 s apart). Only after connection and server errors - never after a kick, ban or security disconnect.")
	local tRc = Ui.toggle(hub, c2, "Auto-reconnect", nil, prefs.reconnect, function(v)
		prefs.reconnect = v
		session.setReconnect(v)
		savePrefs()
	end, 1)
	local rcLine = statusLine(c2, 2)

	local c3 = Ui.card(sessionPage, "Auto-execute", 3, "Runs Ervi Hub again by itself after teleports and rejoins (including auto-reconnect), using the executor's queue_on_teleport and Ervi_Hub.luau from its workspace folder. Nothing is added to Potassium's autoexec folder, so after starting Roblox fresh you still press Run once.")
	local tAe = Ui.toggle(hub, c3, "Auto-execute after teleport / rejoin", nil, prefs.autoExec, function(v)
		prefs.autoExec = v
		session.setAutoExec(v)
		savePrefs()
	end, 1)
	local aeLine = statusLine(c3, 2)

	table.insert(syncs, function()
		tAfk.set(prefs.antiAfk, true)
		tRc.set(prefs.reconnect, true)
		tAe.set(prefs.autoExec, true)
		session.setAntiAfk(prefs.antiAfk)
		session.setReconnect(prefs.reconnect)
		if prefs.autoExec ~= session.autoExec then
			session.setAutoExec(prefs.autoExec)
		end
	end)
	onRefresh("session", "session", function()
		local afk = "Off"
		if session.antiAfk then
			afk = ("On · idle pulses sent: %d"):format(session.afkPulses)
			if session.lastAfk then
				afk ..= (" · last %ds ago"):format(math.floor(os.clock() - session.lastAfk))
			end
		end
		Ui.set(afkLine, "Text", afk)
		Ui.set(rcLine, "Text", "Status: " .. session.reconnectStatus)
		Ui.set(aeLine, "Text", "Status: " .. session.autoExecStatus)
	end)
end

-- ===================================================================== Utility
local utilPage = addPage("utility", "Utility")
do
 local links=Ui.card(utilPage,"Diagnostics and session tools",0)
 Ui.button(hub,links,"Open Diagnostics",{order=1,width=220},function() selectPage("diag") end)
 Ui.button(hub,links,"Session management",{order=2,width=220},function() selectPage("session") end)
end
do
	local c1 = Ui.card(utilPage, "Instant proximity prompts", 1, "Interaction prompts (hold E) trigger instantly: when a prompt appears its hold time is set to 0. Turning this off, or closing the hub, restores every prompt's original hold time. A prompt already on screen when you turn this on switches when you start holding it.")
	local toggle = Ui.toggle(hub, c1, "Instant prompts", nil, prefs.instantPrompts, function(v)
		prefs.instantPrompts = v
		prompts.set(v)
		savePrefs()
	end, 1)
	local line = Ui.text(c1, "", { textSize = Theme.size.small, color = Theme.muted, order = 2 })
	table.insert(syncs, function()
		toggle.set(prefs.instantPrompts, true)
		prompts.set(prefs.instantPrompts)
	end)
	onRefresh("utility", "utility", function()
		Ui.set(line, "Text", prompts.enabled and ("On · prompts made instant this session: %d"):format(prompts.changed) or "Off")
	end)
end

-- ===================================================================== Settings
local configPage=addPage("config","Config","Slots, autoload and safe sharing")
local applyPrefs
local settings = addPage("settings", "Settings", "Interface and appearance")
do
	local function syncAll()
		for _, fn in ipairs(syncs) do
			fn()
		end
	end
	applyPrefs=function()
		toggleKey = Enum.KeyCode[prefs.toggleKey]
		Ui.applyLook(prefs)
		Ui.setOpacity(prefs.opacity, Settings.MIN_OPACITY)
		userScale = prefs.scale
		setWindowSize(prefs.winW, prefs.winH)
		applyScale()
        sidebarLayout()
		syncAll()
	end

	local c0 = Ui.card(settings, "Controls", 0)

	-- Toggle key: click the button, then press any key (Esc cancels).
	local keyRow = Ui.row(c0, 1, 32)
	Ui.text(keyRow, "Show / hide menu key", { size = UDim2.new(0, 170, 1, 0), font = Theme.fontMedium })
	local keyBtn
	keyBtn = Ui.button(hub, keyRow, toggleKey.Name, { width = 150, order = 1 }, function()
		if onKeyCaptured then
			return
		end
		Ui.select(keyBtn, true)
		keyBtn.Text = "Press a key… (Esc = cancel)"
		onKeyCaptured = function(kc)
			Ui.select(keyBtn, false)
			if kc ~= Enum.KeyCode.Escape and isKey(kc.Name) and (not keyConflict or not keyConflict(kc.Name,"toggleKey")) then
				toggleKey = kc
				prefs.toggleKey = kc.Name
				savePrefs()
				log("Settings", "menu key set to " .. kc.Name)
			end
			keyBtn.Text = toggleKey.Name
		end
	end)
	Ui.text(c0, "Ignored while you type in chat or a text box. Minimize with – in the title bar.", { textSize = Theme.size.small, color = Theme.faint, order = 2 })

    addSafeKeyControl(c0,6)

	local opacity = Ui.slider(hub, c0, "Menu opacity", {
		min = Settings.MIN_OPACITY,
		max = 1,
		step = 0.05,
		value = prefs.opacity,
		order = 3,
		format = function(v)
			return ("%d%%"):format(math.floor(v * 100 + 0.5))
		end,
	}, function(v)
		prefs.opacity = Ui.setOpacity(v, Settings.MIN_OPACITY)
		savePrefs()
	end)

	table.insert(syncs, function()
		keyBtn.Text = toggleKey.Name
		opacity.set(prefs.opacity, true)
	end)

 local scaleSlider=Ui.slider(hub,c0,"UI Scale",{min=0.5,max=1.5,step=0.05,value=prefs.scale,order=5,format=function(v) return ("%d%%"):format(math.floor(v*100+0.5)) end},function(v)
  prefs.scale=v;userScale=v;applyScale();savePrefs()
 end)
 table.insert(syncs,function() scaleSlider.set(prefs.scale,true) end)
	local resetRow = Ui.row(c0, 7)
	Ui.button(hub, resetRow, "Reset this config", { width = 150 }, function()
		for k, v in pairs(Settings.DEFAULTS) do
			prefs[k] = v
		end
		applyPrefs()
		savePrefs()
	end)
	Ui.button(hub, resetRow, "Reset position", { width = 130, order = 1 }, function()
		prefs.winX,prefs.winY=0.5,0.5;fitPosition();savePrefs()
		setMinimized(false)
	end)

	-- ---------------------------------------------------------------- Appearance
	local cA = Ui.card(settings, "Appearance", 1, "Changes apply instantly and save to the active config.")
	local function setLook(key, value)
		prefs[key] = value
		Ui.applyLook(prefs)
		savePrefs()
		syncAll()
	end
	local function pct(v)
		return ("%d%%"):format(math.floor(v * 100 + 0.5))
	end

	-- Color circle panel, shared by every "Custom" color button; opens right under the grid that asked.
	local pickPanel = Ui.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = false, Parent = cA })
	Ui.list(pickPanel, 8)
	local pickTitle = Ui.text(pickPanel, "", { font = Theme.fontMedium, order = 1 })
	local pickKey, preview, hexBox, brightness
	local function showPicked(c)
		preview.BackgroundColor3 = c
		hexBox.Text = "#" .. c:ToHex():upper()
	end
	local wheel = Ui.colorWheel(hub, pickPanel, 150, 2, function(c)
		showPicked(c)
	end)
	brightness = Ui.slider(hub, pickPanel, "Brightness", { min = 0, max = 1, step = 0.05, value = 1, order = 3, format = pct }, function(v)
		wheel.setValue(v)
		showPicked(wheel.get())
	end)
	local pickRow = Ui.row(pickPanel, 4, 32)
	preview = Ui.new("Frame", { Size = UDim2.fromOffset(44, 28), BackgroundColor3 = Color3.new(1, 1, 1), Parent = pickRow })
	preview:SetAttribute("FixedBackground", true)
	Ui.corner(preview)
	local function loadColor(c)
		wheel.set(c)
		local _, _, v = c:ToHSV()
		brightness.set(v, true)
		showPicked(wheel.get())
	end
	hexBox = Ui.input(hub, pickRow, "#RRGGBB", { width = 100, order = 1 }, function(text)
		local digits = text:gsub("[#%s]", "")
		local c = Theme.hex("#" .. digits)
		if c then
			loadColor(c)
		end
	end)
	hexBox:SetAttribute("AppearanceHex",true)
	Ui.button(hub, pickRow, "Apply", { variant = "primary", width = 80, order = 2 }, function()
		pickPanel.Visible = false
		setLook(pickKey, "#" .. wheel.get():ToHex():upper())
	end)
	Ui.button(hub, pickRow, "Cancel", { width = 80, order = 3 }, function()
		pickPanel.Visible = false
	end)
	local CURRENT = { accent = "accent", textColor = "text", bgColor = "bg" }
	local function openPicker(key, title, order)
		pickKey = key
		pickTitle.Text = title .. ": drag on the circle or type a hex code"
		pickPanel.LayoutOrder = order + 2
		loadColor(Theme[CURRENT[key]])
		pickPanel.Visible = true
	end

	-- Option grid. select(button, on) shows the current choice (default: accent highlight).
	-- An item with custom = true opens the color circle instead of applying a value.
	local function picker(title, order, cellW, items, key, decorate, select)
		Ui.text(cA, title, { font = Theme.fontMedium, order = order })
		local grid = Ui.grid(cA, cellW, 28, order + 1)
		local buttons = {}
		for i, item in ipairs(items) do
			local b = Ui.button(hub, grid, item.label, { order = i, textSize = Theme.size.small }, function()
				if item.custom then
					openPicker(key, title, order)
				else
					setLook(key, item.value)
				end
			end)
			if decorate then
				decorate(b, item)
			end
			buttons[item.custom and "#custom" or item.value] = b
		end
		table.insert(syncs, function()
			for value, b in pairs(buttons) do
				local on = (value == "#custom" and Theme.hex(prefs[key]) ~= nil) or prefs[key] == value
				local mark = select or Ui.select
				mark(b, on)
			end
		end)
	end
	local CUSTOM = { label = "Custom", custom = true }
	local function items(list, extra)
		local out = extra or {}
		for _, it in ipairs(list) do
			table.insert(out, { label = it.name, value = it.name, item = it })
		end
		return out
	end

	picker("Design", 10, 66, items(Theme.PRESETS), "theme")

	-- Accent swatches: fixed background color, a check mark shows the current one.
	local accentItems = items(Theme.ACCENTS, { { label = "Auto", value = "" } })
	table.insert(accentItems, CUSTOM)
	picker("Accent color", 20, 52, accentItems, "accent", function(b, it)
		if it.item then
			b.Text = ""
			b.BackgroundColor3 = it.item.color
			b:SetAttribute("FixedBackground", true)
			b:SetAttribute("Swatch", true)
		end
	end, function(b, on)
		if b:GetAttribute("Swatch") then
			b.Text = on and "✓" or ""
			b.TextColor3 = Theme.onAccent
		else
			Ui.select(b, on)
		end
	end)

	picker("Font", 30, 100, items(Theme.FONTS), "font", function(b, it)
		b.Font = it.item.regular -- preview in its own font
		b:SetAttribute("FontRole", nil)
	end)

	local textItems = items(Theme.TEXT_COLORS)
	table.insert(textItems, CUSTOM)
	picker("Text color", 40, 66, textItems, "textColor", function(b, it)
		if it.item and it.item.color then
			b.TextColor3 = it.item.color
			b:SetAttribute("FixedTextColor", true)
		end
	end)

	picker("Background", 45, 80, { { label = "Design", value = "" }, CUSTOM }, "bgColor")

	local textSize = Ui.slider(hub, cA, "Text size", { min = 0.8, max = 1.4, step = 0.05, value = prefs.textScale, order = 50, format = pct }, function(v)
		setLook("textScale", v)
	end)
	picker("Text outline", 60, 66, {
		{ label = "Auto", value = "auto" },
		{ label = "On", value = "on" },
		{ label = "Off", value = "off" },
	}, "outline")
	Ui.text(cA, "Auto outlines text only when menu opacity is below 60%.", { textSize = Theme.size.small, color = Theme.faint, order = 62 })
	local textAlpha = Ui.slider(hub, cA, "Text transparency", { min = 0, max = 0.6, step = 0.05, value = prefs.textAlpha, order = 70, format = pct }, function(v)
		setLook("textAlpha", v)
	end)
	table.insert(syncs, function()
		textSize.set(prefs.textScale, true)
		textAlpha.set(prefs.textAlpha, true)
	end)
	Ui.button(hub, cA, "Reset appearance", { width = 150, order = 80 }, function()
		for _, k in ipairs({ "theme", "accent", "font", "textColor", "textScale", "outline", "textAlpha", "bgColor" }) do
			prefs[k] = Settings.DEFAULTS[k]
		end
		Ui.applyLook(prefs)
		savePrefs()
		syncAll()
	end)

	-- ---------------------------------------------------------------- Configs
	local cC = Ui.card(configPage, "Configs", 2, "The active config saves every change automatically. Save a copy under a new name, load another one, or mark one to auto-load when the hub starts.")
	local kActive, kAuto = Ui.kv(cC, "Active config", 1), Ui.kv(cC, "Auto-loads on start", 2)
	local nameRow = Ui.row(cC, 3, 32)
	local saveBtn
	local pendingOverwrite
	local nameBox = Ui.input(hub, nameRow, "New config name", { width = 180 }, function()
		pendingOverwrite = nil
		saveBtn.Text = "Save as"
	end)
	local status = Ui.text(cC, "", { textSize = Theme.size.small, color = Theme.muted, order = 4 })
	Ui.text(cC, Settings.canPersist() and ("Stored in your executor workspace as %s."):format(Settings.FILE) or "This executor has no file access, so configs last until you close the hub.", {
		textSize = Theme.size.small,
		color = Settings.canPersist() and Theme.good or Theme.warn,
		order = 5,
	})
	local listFrame = Ui.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 6, Parent = cC })
	Ui.list(listFrame, 6)

	local listScope
	local rebuildList
	local function loadConfig(name)
		activeName = name
		prefs = store.configs[name]
		applyPrefs()
		rebuildList()
		status.Text = ("Loaded '%s'."):format(name)
		log("Settings", "loaded config " .. name)
	end
	rebuildList = function()
		if listScope then
			listScope:close()
		end
		listScope = hub:child("config-list")
		for i, name in ipairs(store.order) do
			local isActive = name == activeName
			local row = listScope:add(Ui.grid(listFrame,90,30,i))
			local label = Ui.text(row, name .. (isActive and "  (active)" or ""), { size = UDim2.new(0, 110, 1, 0), font = isActive and Theme.fontBold or Theme.font })
			label.TextTruncate = Enum.TextTruncate.AtEnd
			local _, setLoad = Ui.button(listScope, row, "Load", { width = 56, order = 1 }, function()
				loadConfig(name)
			end)
			setLoad(not isActive)
			-- Overwrite: replace this saved config with the current settings (asks once).
            local ow, setOw
            ow,setOw=Ui.confirmButton(listScope,row,"Overwrite",{width=84,order=2},"Replace '"..name.."' with the current settings?",function()
				Settings.put(store, name, table.clone(prefs))
				savePrefs()
				status.Text = ("Overwrote '%s' with the current settings."):format(name)
				rebuildList()
			end)
			setOw(not isActive) -- the active config already saves every change
			local auto = Ui.button(listScope, row, store.autoload == name and "Auto ✓" or "Auto", { width = 64, order = 3 }, function()
				store.autoload = store.autoload ~= name and name or nil
				savePrefs()
				rebuildList()
			end)
			Ui.select(auto, store.autoload == name)
            local del,setDel
            del,setDel=Ui.confirmButton(listScope,row,"Delete",{variant="danger",width=64,order=4},"Delete saved configuration '"..name.."'?",function()
				Settings.delete(store, name)
				savePrefs()
				status.Text = ("Deleted '%s'."):format(name)
				rebuildList()
			end)
			setDel(not isActive)
		end
		kActive(activeName)
		kAuto(store.autoload or ("none (starts with %s)"):format(Settings.DEFAULT_NAME))
	end
	saveBtn = Ui.button(hub, nameRow, "Save as", { variant = "primary", width = 110, order = 1 }, function()
		local name = Settings.cleanName(nameBox.Text)
		if not name then
			status.Text = "Name: 1–24 letters, digits, spaces, _ or -."
			return
		end
		if store.configs[name] and pendingOverwrite ~= name then
			pendingOverwrite = name
			saveBtn.Text = "Overwrite?"
			status.Text = ("'%s' already exists. Press Overwrite? to replace it with the current settings."):format(name)
			return
		end
		pendingOverwrite = nil
		saveBtn.Text = "Save as"
		Settings.put(store, name, table.clone(prefs))
		activeName = name
		prefs = store.configs[name]
		savePrefs()
		rebuildList()
		status.Text = ("Saved '%s' - it is now the active config."):format(name)
	end)
	rebuildList()

    local share=Ui.card(configPage,"Config sharing · schema v1",8,"Bounded data-only text; imported settings are validated and never executed.")
    local selected=activeName
    local selectedLabel=Ui.text(share,"Selected: "..selected,{order=0,textSize=Theme.size.small})
    local function selection(name) selected=name;selectedLabel.Text="Selected: "..selected end
    Ui.button(hub,share,"Select next slot",{order=1,width=180},function()
        local index=table.find(store.order,selected) or 0
        if #store.order>0 then selection(store.order[index%#store.order+1]) end
    end)
    Ui.button(hub,share,"Save selected slot",{order=2,width=180},function()
        if store.configs[selected] then Settings.put(store,selected,table.clone(prefs));savePrefs();rebuildList();status.Text="Saved "..selected end
    end)
    Ui.button(hub,share,"Load selected slot",{order=3,width=180},function() if store.configs[selected] then loadConfig(selected) end end)
    local autoGame=Ui.toggle(hub,share,"Autoload per game","Uses this PlaceId; legacy global autoload stays compatible.",store.autoloadGames[tostring(game.PlaceId)]~=nil,function(on)
        if on and store.configs[selected] then store.autoloadGames[tostring(game.PlaceId)]=selected else store.autoloadGames[tostring(game.PlaceId)]=nil end
        savePrefs()
    end,4)
    Ui.button(hub,share,"Set Selected As Autoload",{order=4,width=240},function()
        if store.configs[selected] then store.autoloadGames[tostring(game.PlaceId)]=selected;savePrefs();status.Text="Autoload for this game: "..selected end
    end)
    Ui.button(hub,share,"Turn Off Autoload",{order=5,width=200},function()
        store.autoloadGames[tostring(game.PlaceId)]=nil;store.autoload=nil;savePrefs();rebuildList();status.Text="Autoload off for this game"
    end)
    local rename=Ui.input(hub,share,"Rename selected slot",{order=6},function(name)
        name=Settings.cleanName(name)
        if not name or store.configs[name] or not store.configs[selected] then status.Text="Rename requires a unique valid name";return end
        local old=selected
        local data=store.configs[old];local wasAuto=store.autoload==old
        local places={};for place,value in pairs(store.autoloadGames) do if value==old then table.insert(places,place) end end
        Settings.delete(store,old);Settings.put(store,name,data)
        if activeName==old then activeName=name;prefs=data end
        if wasAuto then store.autoload=name end
        for _,place in ipairs(places) do store.autoloadGames[place]=name end
        selection(name);savePrefs();rebuildList()
    end)
    Ui.button(hub,share,"Copy Config To Clipboard",{order=7,width=240},function()
        local config=store.configs[selected] or prefs
        local ok,err=Game.copy(Settings.export(config));status.Text=ok and "Config copied (schema v1)" or tostring(err)
    end)
    local importBox=Ui.input(hub,share,"Paste ERVI_CONFIG_V1 text",{order=8,width=300},function() end)
    importBox.MultiLine=true;importBox.ClearTextOnFocus=false
    Ui.button(hub,share,"Apply Import",{order=9,width=180},function()
        local imported,err=Settings.import(importBox.Text,validators)
        if not imported then status.Text=err;return end
        store.configs[activeName]=imported;prefs=imported;applyPrefs();savePrefs();rebuildList();status.Text="Imported into "..activeName
    end)
    local autoStatus=Ui.text(share,"",{order=10,textSize=Theme.size.small})
    onRefresh("config","autoload status",function() autoGame.set(store.autoloadGames[tostring(game.PlaceId)]~=nil,true);Ui.set(autoStatus,"Text","This game's autoload: "..(store.autoloadGames[tostring(game.PlaceId)] or store.autoload or "none")) end)

	syncAll()

	local c2 = Ui.card(settings, "Emergency off", 3, "Stops Auto Roll, the roll observer and the M1 HUD, and removes every hub GUI. Same as the × button. From the console: _G.RNG_HUB_STOP()")
	Ui.button(hub, c2, "Unload hub", { variant = "danger", width = 130, order = 1 }, function()
		stopHub()
	end)

	local c3 = Ui.card(settings, "About", 4)
	Ui.text(c3, ("Build %s\nBaseline: Modular Hub v1 (Cyborg V6). Style data checked against place version %d."):format(Build.id, Game.KNOWN_PLACE_VERSION), { textSize = Theme.size.small, color = Theme.muted, order = 1 })
end

bootStep("Existing feature pages and configurations initialized")

-- ===================================================================== expansion
keyConflict=function(value,except)
 for _,key in ipairs({"toggleKey","safeZoneKey","walkKey","espKey","panicKey","clickTPKey","diagnosticKey","flyKey","noclipKey"}) do if key~=except and prefs[key]==value then return true end end
 return false
end
local function headerRefresh() if searchInput then searchInput.PlaceholderText=prefs.searchKey=="NONE" and "Search settings" or ("Search settings · Ctrl+"..prefs.searchKey) end end
local notify=Ui.notifications(hub,window,function() return prefs end)
local expansion=makeExpansion({notify=notify,hub=hub,parent=playerGui,prefs=function() return prefs end,save=savePrefs,pages=pages,addPage=addPage,onRefresh=onRefresh,syncs=syncs,content=content,
 width=function() return W end,isOpen=function() return window.Visible and not minimized end,metrics=metrics,build=Build,session=session,roll=autoRoll,safe=safeZone,stop=stopHub,applyPrefs=applyPrefs,
 headerRefresh=headerRefresh,statusBarRefresh=function() if statusBar then statusBar.refresh() end end,sidebarLayout=sidebarLayout,logs=function() return logs end,bootLog=boot.text,
 keyConflict=keyConflict,capture=function(fn) if onKeyCaptured then return false end;onKeyCaptured=fn;return true end})
expansionKeys=expansion.keyHandler
statusBar=makeStatusBar(hub,playerGui,function() return prefs end,savePrefs,function() setMinimized(false) end,selectPage,function()
 local features={}
 local function add(on,label,page) if on then table.insert(features,{label=label,page=page}) end end
 add(autoRoll:isRunning() or autoRoll.state=="Paused","Roll "..autoRoll.state,"roll")
 add(safeZone.enabled,"Safe Zone","safe");add(expansion.visuals.active,"Visuals","visuals")
 add(expansion.player.walkActive,"Speed","player");add(expansion.flight.flying,"Fly","player");add(expansion.flight.noclip,"Noclip","player");add(expansion.clickTP.active,"Click preview","teleports");add(m1.enabled,"M1","combat");add(session.antiAfk,"Anti AFK","utility")
 return {fps=metrics.fps,ping=metrics.ping,rollState=autoRoll.state,features=features}
end)

bootStep("Shared UI catalog and expansion features initialized")
syncBlur=function() expansion.world.setBlur(prefs.backgroundBlur and window.Visible and not minimized) end
hub:connect(window:GetPropertyChangedSignal("Visible"),function() minimized=not window.Visible;body.Visible=window.Visible;if grip then grip.Visible=window.Visible end;if statusBar then statusBar.show(not window.Visible) end;syncBlur() end)
hub:connect(body:GetPropertyChangedSignal("Visible"),syncBlur)
-- Search uses entries registered by actual shared controls, including legacy sections.
local resultsScope,focusScope
local searchPanel=Ui.new("Frame",{Name="ErviSearch",Visible=false,Position=UDim2.new(0,SW+8,0,TH+4),Size=UDim2.new(1,-SW-20,0,310),BackgroundColor3=Theme.surface2,ZIndex=20,Parent=window})
Ui.corner(searchPanel,10);Ui.pad(searchPanel,10)
local resultList=Ui.scroll(searchPanel,{Size=UDim2.new(1,0,1,-24),Position=UDim2.fromOffset(0,24)})
Ui.list(resultList,5)
local hint=Ui.text(searchPanel,"Search settings · ↑ ↓ select · Enter open · Esc close",{size=UDim2.new(1,0,0,20),textSize=10})
local selectedResult=1
local resultEntries={}
local resultButtons={}
local function openResult(index)
 local entry=resultEntries[index];if not entry or not pages[entry.page] then return end
 if focusScope then focusScope:close() end;focusScope=Scope.new("search-focus")
 local selection=focusScope
 selectPage(entry.page);setMinimized(false);searchPanel.Visible=false;searchInput:ReleaseFocus()
 local control=entry.control;local page=pages[entry.page].page
 if not control or not control.Parent then return end
 -- Reveal UI containers only; never activate a feature as a side effect of search.
 local ancestor=control
 while ancestor and ancestor~=page do
  if ancestor:IsA("GuiObject") then ancestor.Visible=true end
  ancestor=ancestor.Parent
 end
 control:SetAttribute("SearchFocused",true)
 selection:add(function() if control.Parent then control:SetAttribute("SearchFocused",nil) end end)
 local focusStroke=selection:add(Ui.stroke(control,Theme.accent,1))
 Ui.animate(focusStroke,{Transparency=0},0.18)
 selection:add(function() Ui.cancelAnimation(focusStroke) end)
 -- AutomaticSize/visibility layout must settle before AbsolutePosition is reliable.
 local frames=0;local listener
 listener=selection:connect(RunService.Heartbeat,function()
  frames+=1;if frames<2 then return end
  listener:Disconnect()
  if selection.closed or not page.Visible or not control.Parent then return end
  local node=control.Parent
  while node do
   if node:IsA("ScrollingFrame") then
    local ok=pcall(function()
     local current=node.CanvasPosition or Vector2.new()
     local offset=math.max(0,current.Y+control.AbsolutePosition.Y-node.AbsolutePosition.Y-16)
     Ui.animate(node,{CanvasPosition=Vector2.new(current.X,offset)},0.18)
     node:SetAttribute("SearchTargetOffset",offset)
    end)
    if ok then control:SetAttribute("SearchScrolled",true) end
   end
   if node==page then break end
   node=node.Parent
  end
 end)
end

local function searchResults()
 if resultsScope then resultsScope:close() end;resultsScope=Scope.new("search-results")
 resultEntries=Ui.registry:search(searchInput.Text,12);selectedResult=1;resultButtons={}
 searchPanel.Visible=searchInput.Text~=""
 for i,entry in ipairs(resultEntries) do
  local button=Ui.button(resultsScope,resultList,entry.title.." · "..pages[entry.page].label,{size=UDim2.new(1,0,0,30),order=i,textSize=12},function() openResult(i) end)
  resultsScope:add(button)
  table.insert(resultButtons,button);Ui.select(button,i==1)
 end
 if #resultEntries==0 and searchInput.Text~="" then resultsScope:add(Ui.text(resultList,"No matching registered setting",{textSize=12})) end
end
searchInput=Ui.input(hub,titleBar,"Search settings · Ctrl+K",{width=190},function(_,enter) if enter then openResult(selectedResult) end end)
searchInput.Name="SettingsSearch"
searchInput.Position=UDim2.new(1,-284,0,11);searchInput.ZIndex=21;searchInput.ClearTextOnFocus=false
hub:connect(searchInput:GetPropertyChangedSignal("Text"),searchResults)
onSearchInput=function(input,processed)
 local focused=UserInputService:GetFocusedTextBox()
 if focused==searchInput then
  if input.KeyCode==Enum.KeyCode.Escape then searchPanel.Visible=false;searchInput:ReleaseFocus();return true end
  if input.KeyCode==Enum.KeyCode.Return then openResult(selectedResult);return true end
  if input.KeyCode==Enum.KeyCode.Down or input.KeyCode==Enum.KeyCode.Up then
   selectedResult=math.clamp(selectedResult+(input.KeyCode==Enum.KeyCode.Down and 1 or -1),1,math.max(1,#resultEntries))
   for i,button in ipairs(resultButtons) do Ui.select(button,i==selectedResult) end
   return true
  end
 end
 local ok,ctrl=pcall(function() return UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) end)
 if not processed and not focused and ok and ctrl and input.KeyCode.Name==prefs.searchKey and prefs.searchKey~="NONE" then
  setMinimized(false);searchInput:CaptureFocus();searchResults();return true
 end
 return false
end
hub:add(function() if resultsScope then resultsScope:close() end;if focusScope then focusScope:close() end end)

-- ===================================================================== lifecycle
hub:connect(closeBtn.Activated, stopHub)

hub:add(task.spawn(function()
	while not stopped do
		task.wait(0.1)
		if window.Visible and not minimized then
			for _, r in ipairs(refreshers) do
				if not r.dead and pages[r.id].page.Visible then
					local ok, err = pcall(r.fn)
					if not ok then
						r.dead = true
						log(r.name, "refresh disabled after error: " .. tostring(err), true)
					end
				end
			end
		end
	end
end))

if stopped then
	return stopHub -- a newer run replaced this one while it was loading
end
window.GroupTransparency=1
setMinimized(false)
bootStep("Search initialized; Ready")
selectPage("dash")
log("Hub", ("loaded build %s (place version %d)"):format(Build.id, game.PlaceVersion))
return stopHub
