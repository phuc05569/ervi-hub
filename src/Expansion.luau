local Ui=require("Ui")
local Theme=require("Theme")
local Schema=require("FeatureSchema")
local Game=require("Game")
local makeWorld=require("World")
local makePlayer=require("PlayerTools")
local makeActions=require("RuntimeActions")
local makeVisuals=require("Visuals")
local makePreview=require("VisualPreview")
local Logo=require("Logo")
return function(ctx)
 local hub=ctx.hub
 local world=makeWorld(hub,ctx.prefs)
 local playerTools=makePlayer(hub,ctx.parent,ctx.prefs,ctx.save)
 local actions=makeActions(hub,ctx.prefs)
 local visuals=makeVisuals(hub,ctx.parent,ctx.prefs)
 local pages=ctx.pages
 local new={}
 for _,tab in ipairs({{"visuals","Visuals","Visible player overlays and preview"},{"player","Player","Local speed and movement panel"},{"world","World","Lighting and camera"}}) do
  new[tab[1]]=ctx.addPage(tab[1],tab[2],tab[3])
 end
 local refreshControls={}
 local pageRefresh={}
 local function apply()
  if hub.closed then return end
  Ui.setLanguage(ctx.prefs().language)
  Ui.configureMotion(ctx.prefs())
  ctx.headerRefresh()
  if ctx.statusBarRefresh then ctx.statusBarRefresh() end
  world.apply();world.setBlur(ctx.prefs().backgroundBlur and ctx.isOpen());playerTools.apply();actions.applyFPS();visuals.apply()
  for _,fn in ipairs(refreshControls) do fn(true) end
 end
 local function changed(key,value)
  ctx.prefs()[key]=value;ctx.save();apply()
  if type(value)=="boolean" and ctx.notify then local title=key;for _,d in ipairs(Schema) do if d.key==key then title=d.title;break end end;ctx.notify(Ui.localeText(title).." · "..(value and "ON" or "OFF")) end
 end
 local groups={}
 local groupCount=0
 for _,d in ipairs(Schema) do
  local page=new[d.page] or pages[d.page].page
  local group=d.page.."/"..d.section
  local card=groups[group]
  if not card then groupCount+=1;card=Ui.card(page,d.section,50+groupCount);groups[group]=card end
  local key=d.key
  local control
  if d.kind=="bool" then
   control=Ui.toggle(hub,card,d.title,d.description,ctx.prefs()[key],function(v) changed(key,v) end,1)
  elseif d.kind=="number" then
   control=Ui.slider(hub,card,d.title,{min=d.min,max=d.max,step=d.step,value=ctx.prefs()[key],order=2,description=d.description,format=function(v) if key=="chamsFill" or key=="chamsOutline" or key=="statusOpacity" then return ("%d%%"):format(math.floor(v*100+0.5)) end;return require("SliderValue").format(v,d.step) end},function(v) changed(key,v) end)
  elseif d.kind=="choice" then
   local component=#d.options<=3 and Ui.segment or Ui.dropdown
   control=component(hub,card,d.title,d.options,ctx.prefs()[key],function(v) changed(key,v) end,2)
  elseif d.kind=="color" then
   local row=Ui.card(card,d.title,3,d.description)
   local grid=Ui.grid(row,35,25,1)
   local swatches={"#F0628E","#FF9BC7","#FFB340","#40C492","#42C6D2","#FFFFFF","#70AFFF"}
   local buttons={}
   for i,hex in ipairs(swatches) do
    local b=Ui.button(hub,grid,"",{order=i},function() changed(key,hex) end)
    b.BackgroundColor3=Color3.fromHex(hex:sub(2));b:SetAttribute("FixedBackground",true);buttons[hex]=b
   end
   local input=Ui.input(hub,row,"#RRGGBB",{order=2},function(text) if Theme.hex(text) then changed(key,text:upper()) end end)
   Ui.register(input,d.title,d.description)
   control={node=row,set=function(v) if input.Text~=v then input.Text=v end; for hex,b in pairs(buttons) do b.Text=hex==v and "✓" or "" end end}
  else
   local row=Ui.row(card,3,32)
   Ui.text(row,d.title,{size=UDim2.new(0.55,0,1,0),textSize=Theme.size.small})
   local button
   button=Ui.button(hub,row,ctx.prefs()[key],{width=145,order=1},function()
    if not ctx.capture(function(kc)
     if kc==Enum.KeyCode.Escape then button.Text=ctx.prefs()[key];return end
     local value=kc==Enum.KeyCode.Backspace and "NONE" or kc.Name
     if value~="NONE" and ctx.keyConflict(value,key) then button.Text="Key conflict";return end
     changed(key,value);button.Text=ctx.prefs()[key]
    end) then return end
    button.Text="Press key / ⌫ clears"
   end)
   Ui.tooltip(hub,button,d.description~="" and d.description or "Esc cancels; Backspace unbinds")
   Ui.register(button,d.title,d.description)
   control={node=button,set=function(v) button.Text=v end}
  end
  if control and control.node then control.node.Name="Setting_"..key;control.node:SetAttribute("SettingKey",key) end
  if key=="fpsCap" and control.setEnabled then control.setEnabled(actions.fpsSupported) end
  if control then
   local last=ctx.prefs()[key]
   local refresh=function(force) local value=ctx.prefs()[key];if force or value~=last then control.set(value,true);last=value end end
   table.insert(refreshControls,refresh)
   pageRefresh[d.page]=pageRefresh[d.page] or {};table.insert(pageRefresh[d.page],refresh)
  end
 end
 for page,list in pairs(pageRefresh) do ctx.onRefresh(page,"registered control state",function() for _,fn in ipairs(list) do fn() end end) end
 -- Unsupported settings are explicit informational rows, never enabled mock controls.
 local function unsupported(page,title,description)
  local card=Ui.card(page,title,80,description)
  local button,setEnabled=Ui.button(hub,card,"Unsupported",{width=160},function() end);setEnabled(false)
  Ui.register(button,title,description)
 end
 unsupported(new.player,"CFrame Speed / Noclip / Fly","No game-authorized movement/collision API is established. No CFrame correction fallback, collision bypass, fly or infinite-jump control is enabled. Requested Fly key, Velocity/CFrame mode and speed remain unsupported.")
 unsupported(new.visuals,"Mobile Renderer / Dim Behind Walls","All overlays already use native GUI objects, including mobile. Fully hidden players are suppressed, not dimmed. Behind Wall color and hidden-target preview are sample-only; no wallhack or AlwaysOnTop chams is installed.")
 local preview=makePreview(new.visuals)
 pages.visuals.preview=preview.frame
 local function previewLayout()
  local wide=ctx.width()>=820
  if wide then
   preview.frame.Parent=ctx.content;preview.frame.Position=UDim2.new(0.64,4,0,14);preview.frame.Size=UDim2.new(0.36,-20,0,0)
   new.visuals.Size=UDim2.new(0.64,-4,1,0)
  else
   preview.frame.Parent=new.visuals;preview.frame.Position=UDim2.new();preview.frame.Size=UDim2.new(1,0,0,0)
   new.visuals.Size=UDim2.fromScale(1,1)
  end
  preview.frame.Visible=new.visuals.Visible
 end
 ctx.onRefresh("visuals","visual preview",function() previewLayout();preview.render(ctx.prefs(),visuals.status) end)
 local visualStatus=Ui.text(new.visuals,"",{order=100,textSize=Theme.size.small})
 ctx.onRefresh("visuals","visual statistics",function() Ui.set(visualStatus,"Text",visuals.status) end)
 local playerStatus=Ui.text(new.player,"",{order=100,textSize=Theme.size.small})
 ctx.onRefresh("player","player status",function() playerTools.refreshStatus();Ui.set(playerStatus,"Text",playerTools.status) end)
 Ui.button(hub,Ui.card(new.world,"Camera",75),"Reset Camera",{order=20,width=180},function() world.resetCamera();apply() end)
 local cameraStatus=Ui.text(new.world,"",{order=100,textSize=Theme.size.small})
 ctx.onRefresh("world","world status",function() Ui.set(cameraStatus,"Text",world.status) end)
 -- Reuse actions across Home, Utility and the Teleports section.
 local function quick(page,order)
  local card=Ui.card(page,"Session actions",order)
  local grid=Ui.grid(card,145,34,1)
  for i,action in ipairs({{"Rejoin",actions.rejoin},{"Server Hop",actions.serverHop},{"Copy Job ID",actions.copyJob}}) do Ui.button(hub,grid,action[1],{order=i},action[2]) end
  Ui.button(hub,card,"Check Reinjection",{order=2,width=190},function() local ok,reason=ctx.session.autoExecSupport();actions.status=(ok and "Reinjection prerequisites present: " or "Reinjection unavailable: ")..reason end)
  local status=Ui.text(card,"",{order=3,textSize=Theme.size.small})
  return function() Ui.set(status,"Text",actions.status) end
 end
 local homeQuick=quick(pages.dash.page,-7)
 local utilityQuick=quick(pages.utility.page,20)
 local teleQuick=quick(pages.teleports.page,20)
 ctx.onRefresh("dash","home actions",homeQuick);ctx.onRefresh("utility","utility actions",function() utilityQuick();end)
 ctx.onRefresh("teleports","teleport actions",teleQuick)
 local fpsStatus=Ui.text(groups["utility/Rendering"],"",{order=5,textSize=Theme.size.small})
 ctx.onRefresh("utility","FPS cap status",function() Ui.set(fpsStatus,"Text",actions.fpsStatus) end)
 -- Welcome and performance use native shapes rather than borrowed art.
 local welcome=Ui.card(pages.dash.page,"Welcome · Ervi Hub",-10)
 local identity=Ui.new("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,60),Parent=welcome})
 local avatar=Ui.new("ImageLabel",{Image="",BackgroundTransparency=1,Size=UDim2.fromOffset(44,44),Position=UDim2.fromOffset(0,4),Parent=identity});Ui.corner(avatar,22)
 if type(Game.player.UserId)=="number" and Game.player.UserId>0 then avatar.Image=("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(Game.player.UserId) end
 Ui.text(identity,"Welcome back, "..(Game.player.DisplayName or Game.player.Name),{size=UDim2.new(1,-60,0,24),font=Theme.fontBold,textSize=18}).Position=UDim2.fromOffset(56,2)
 local info=Ui.text(identity,"",{size=UDim2.new(1,-60,0,30),textSize=Theme.size.small,color=Theme.muted});info.Position=UDim2.fromOffset(56,26)
 local ring=Ui.new("Frame",{BackgroundColor3=Theme.surface,Size=UDim2.new(1,0,0,54),LayoutOrder=3,Parent=welcome});Ui.corner(ring,8)
 local arcs={}
 local fps=Ui.text(ring,"0 FPS",{size=UDim2.new(0.5,-16,1,0),font=Theme.fontBold,textSize=20});fps.Position=UDim2.fromOffset(12,0)
 local latency=Ui.text(ring,"",{size=UDim2.new(0.5,-16,1,0),font=Theme.mono,textSize=14,align=Enum.TextXAlignment.Right,color=Theme.muted});latency.Position=UDim2.new(0.5,0,0,0)
 local gameInfo=Ui.card(pages.dash.page,"Game and server",-9)
 local gameIcon=Ui.new("ImageLabel",{Image="",Size=UDim2.fromOffset(56,56),BackgroundTransparency=1,LayoutOrder=0,Parent=gameInfo});Ui.corner(gameIcon,10)
 if type(game.GameId)=="number" and game.GameId>0 then gameIcon.Image=("rbxthumb://type=GameIcon&id=%d&w=150&h=150"):format(game.GameId) end
 gameIcon.Visible=type(game.GameId)=="number" and game.GameId>0
 local server=Ui.text(gameInfo,"",{order=1,textSize=Theme.size.small})
 local active=Ui.card(pages.dash.page,"Active now · click to disable",-6)
 local chipGrid=Ui.grid(active,135,28,1)
 local chips={}
 for i,entry in ipairs({{"M1 HUD","m1Enabled"},{"Anti AFK","antiAfk"},{"WalkSpeed","walkEnabled"},{"Visuals","espEnabled"},{"Movement Panel","movementPanel"},{"Auto Roll","roll"},{"Safe Zone","safe"},{"Fullbright","fullbright"},{"No Fog","noFog"},{"No Shadows","noShadows"},{"Custom Time","customTime"},{"Blur","backgroundBlur"},{"Reconnect","reconnect"},{"Auto-execute","autoExec"},{"Instant prompts","instantPrompts"},{"Target selection","targetEnabled"}}) do
  local key=entry[2]
  chips[key]=Ui.button(hub,chipGrid,entry[1],{order=i},function()
   if key=="roll" then ctx.roll:stop() elseif key=="safe" then ctx.safe.setEnabled(false) else changed(key,false);ctx.applyPrefs() end
  end)
 end
 local none=Ui.text(active,"No active optional features",{order=2,textSize=Theme.size.small,color=Theme.muted})
 local community=Ui.card(pages.dash.page,"Ervi Hub community",-8,"Only a link configured by you is used. No third-party invitation or RPC.")
 local communityText=Ui.text(community,"No community link configured",{order=1,textSize=Theme.size.small})
 Ui.button(hub,community,"Copy configured link",{order=2,width=200},function() if ctx.prefs().communityLink~="" then Game.copy(ctx.prefs().communityLink) end end)
 local link=Ui.input(hub,pages.settings.page,"Optional Ervi Hub community URL",{order=100},function(value)
  if value=="" or (value:match("^https://") and #value<=300 and not value:find("[%c]")) then ctx.prefs().communityLink=value;ctx.save();ctx.sidebarLayout() end
 end)
 link.Text=ctx.prefs().communityLink
 local started=os.clock()
 ctx.onRefresh("dash","expanded dashboard",function()
  local metrics=ctx.metrics
  Ui.set(info,"Text",("%s · Ervi Hub %s · %.0fm in this hub session"):format(game.PlaceId==119338513416973 and "RNG RollAttacks" or tostring(game.PlaceId),ctx.build.version,(os.clock()-started)/60))
  Ui.set(fps,"Text",metrics.fps.." FPS");Ui.set(latency,"Text",metrics.ping.." ms")
  for i,arc in ipairs(arcs) do Ui.set(arc,"BackgroundTransparency",i/32<=math.clamp(metrics.fps/240,0,1) and 0 or 0.85) end
  Ui.set(server,"Text",("Players %d/%s · %d ms · Job %s"):format(#game:GetService("Players"):GetPlayers(),tostring(game:GetService("Players").MaxPlayers or "?"),metrics.ping,tostring(game.JobId or "unavailable")))
  local any=false
  for key,chip in pairs(chips) do
   local on=key=="roll" and ctx.roll:isRunning() or key=="safe" and ctx.safe.enabled or key=="walkEnabled" and playerTools.walkActive or key=="espEnabled" and visuals.active or (key~="roll" and key~="safe" and key~="walkEnabled" and key~="espEnabled" and ctx.prefs()[key]==true)
   chip.Visible=on==true;any=any or on==true
  end
  none.Visible=not any
  community.Visible=ctx.prefs().communityLink~=""
  Ui.set(communityText,"Text",ctx.prefs().communityLink~="" and ctx.prefs().communityLink or "No community link configured")
 end)
 local diagnostic=Ui.card(pages.dash.page,"Compatibility · presence checks",100)
 Ui.text(diagnostic,actions.capabilities(),{order=1,textSize=Theme.size.tiny,font=Theme.mono})
 Ui.button(hub,diagnostic,"Copy Logs",{order=2,width=160},function() Game.copy(table.concat(ctx.logs(),"\n")) end)
 Ui.button(hub,diagnostic,"Copy Boot Log",{order=3,width=160},function() Game.copy(ctx.bootLog()) end)
 Ui.button(hub,diagnostic,"Clear diagnostic output",{order=4,width=220},function() table.clear(ctx.logs()) end)
 local function keyHandler(input)
  local p=ctx.prefs();local name=input.KeyCode.Name
  if p.panicKey~="NONE" and name==p.panicKey then ctx.stop();return true end
  if p.walkKey~="NONE" and name==p.walkKey then changed("walkEnabled",not p.walkEnabled);return true end
  if p.espKey~="NONE" and name==p.espKey then changed("espEnabled",not p.espEnabled);return true end
  return false
 end
 table.insert(ctx.syncs,apply)
 apply();previewLayout()
 return {apply=apply,keyHandler=keyHandler,actions=actions,world=world,visuals=visuals,player=playerTools}
end
