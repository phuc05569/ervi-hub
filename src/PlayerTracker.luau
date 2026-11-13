-- Embedded in the Player page. Event-cached discovery/characters/rows, four
-- refreshes per second while visible; no per-player frame loop or teleport write.
local Scope=require("Scope")
local State=require("TrackerState")
local Ui=require("Ui")
local Theme=require("Theme")
local Game=require("Game")
local Players=game:GetService("Players")
return function(hub,page,getPrefs,playerSource)
 local players=playerSource or Players
 local api={status="Tracker ready",selected=nil,active=false,rows=0}
 local card=Ui.card(page,"Player Tracker",90,"Client-visible player state · select a row to inspect · player teleport unavailable.")
 card.Name="PlayerTracker"
 local selected=Ui.text(card,"No player selected",{order=1,textSize=Theme.size.small})
 local search=Ui.input(hub,card,"Filter players",{order=2,size=UDim2.new(1,0,0,30)})
 search.Name="TrackerFilter"
 local scroll=Ui.scroll(card,{Name="TrackerRows",Size=UDim2.new(1,0,0,260),LayoutOrder=3});Ui.list(scroll,6)
 local teleport,enableTeleport=Ui.button(hub,card,"Player teleport unavailable",{order=4,width=220},function() end)
 teleport.Name="TrackerTeleport";enableTeleport(false)
 local info=Ui.text(card,"",{order=5,textSize=Theme.size.tiny})
 local records,ordered={},{};local scope,elapsed,dirty=nil,0,true
 local query=""
 local function drop(player)
  local r=records[player];if not r then return end
  if r.characterScope then r.characterScope:close() end;r.scope:close();records[player]=nil
  if api.selected==player.UserId then api.selected=nil end
  dirty=true
 end
 local function render()
  table.clear(ordered)
  local char=Game.player.Character;local localRoot=char and char:FindFirstChild("HumanoidRootPart")
  local count=0
  for _,r in pairs(records) do
   if r.dirty and r.character then
    r.humanoid=r.character:FindFirstChildOfClass("Humanoid");r.root=r.character:FindFirstChild("HumanoidRootPart");r.dirty=false
   end
   r.name=r.player.Name;r.display=r.player.DisplayName~="" and r.player.DisplayName or r.name
   r.distance=r.root and r.root.Parent and localRoot and (r.root.Position-localRoot.Position).Magnitude or nil
   r.health=State.health(r.humanoid and r.humanoid.Health,r.humanoid and r.humanoid.MaxHealth)
   if State.matches(r,query) then table.insert(ordered,r) end
   count+=1
  end
  State.sort(ordered,getPrefs().trackerSort)
  local visible={}
  for _,r in ipairs(ordered) do visible[r]=true end
  for _,r in pairs(records) do Ui.set(r.row,"Visible",visible[r]==true) end
  for index,r in ipairs(ordered) do
   Ui.set(r.row,"LayoutOrder",index)
   Ui.set(r.title,"Text",r.display..(r.display~=r.name and "  @"..r.name or ""))
   Ui.set(r.details,"Text",r.health.text.." · "..(r.distance and ("%.0f studs"):format(r.distance) or "distance unavailable").." · "..(r.health.alive and "Alive" or "Dead / loading"))
   r.healthBar.Size=UDim2.new(r.health.fraction,0,0,3)
   r.healthBar.BackgroundColor3=r.health.fraction>0.5 and Theme.good or r.health.fraction>0.2 and Theme.warn or Theme.bad
   Ui.select(r.row,api.selected==r.id)
  end
  local chosen
  for _,r in pairs(records) do if api.selected==r.id then chosen=r;break end end
  Ui.set(selected,"Text",chosen and ("Selected: "..chosen.display.." (@"..chosen.name..")") or "No player selected")
  api.rows=count;api.status=("%d / %d players · 4 Hz when visible · player teleport unavailable"):format(#ordered,count)
  Ui.set(info,"Text",api.status);dirty=false
 end
 local function start()
  scope=Scope.new("player-tracker-cache");api.active=true
  local function added(player)
   if player==Game.player or records[player] then return end
   local r={scope=Scope.new("tracker-player"),player=player,id=player.UserId,name=player.Name,display=player.DisplayName};records[player]=r
   r.row=r.scope:add(Ui.button(r.scope,scroll,"",{size=UDim2.new(1,-4,0,70)},function() api.selected=r.id;dirty=true;render() end))
   r.row.AutomaticSize=Enum.AutomaticSize.Y;r.row.Size=UDim2.new(1,-4,0,0);Ui.pad(r.row,10);Ui.list(r.row,4)
   r.row.Name="TrackerRow_"..r.id;r.row:SetAttribute("TrackerUserId",r.id)
   r.title=Ui.text(r.row,"",{size=UDim2.new(1,-20,0,0),textSize=Theme.size.body});r.title.AutomaticSize=Enum.AutomaticSize.Y;r.title.LayoutOrder=1
   r.details=Ui.text(r.row,"",{size=UDim2.new(1,-20,0,0),textSize=Theme.size.tiny});r.details.AutomaticSize=Enum.AutomaticSize.Y;r.details.LayoutOrder=2
   r.healthBar=Ui.new("Frame",{Name="TrackerHealth",LayoutOrder=3,Size=UDim2.new(0,0,0,3),BorderSizePixel=0,BackgroundColor3=Theme.good,Parent=r.row})
   local function bind(character)
    if r.characterScope then r.characterScope:close() end
    r.characterScope=Scope.new("tracker-character");r.character=character;r.humanoid=nil;r.root=nil;r.dirty=true;dirty=true
    if character then
     r.characterScope:connect(character.ChildAdded,function() r.dirty=true;dirty=true end)
     r.characterScope:connect(character.ChildRemoved,function() r.dirty=true;dirty=true end)
    end
   end
   bind(player.Character);r.scope:connect(player.CharacterAdded,bind);r.scope:connect(player.CharacterRemoving,function() bind(nil) end);dirty=true
  end
  for _,player in ipairs(players:GetPlayers()) do added(player) end
  scope:connect(players.PlayerAdded,added);scope:connect(players.PlayerRemoving,drop)
 end
 function api.stop()
  if scope then scope:close();scope=nil end
  for player in pairs(records) do drop(player) end
  api.active=false;api.rows=0;api.selected=nil;table.clear(ordered)
 end
 function api.apply()
  card.Visible=getPrefs().trackerEnabled
  if not getPrefs().trackerEnabled then api.stop();api.status="Tracker off";return end
  if not scope then start() end
  dirty=true;if page.Visible then render() end
 end
 hub:connect(search:GetPropertyChangedSignal("Text"),function() query=search.Text:sub(1,80);dirty=true end)
 hub:connect(game:GetService("RunService").Heartbeat,function(dt)
  if not api.active or not page.Visible then return end
  elapsed+=dt;if not dirty and elapsed<0.25 then return end
  elapsed=0;render()
 end)
 hub:add(api.stop)
 return api
end
