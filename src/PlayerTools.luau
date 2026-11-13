local Game=require("Game")
local Scope=require("Scope")
local Overrides=require("PropertyOverrides")
local makeWindow=require("FloatingWindow")
local Ui=require("Ui")
return function(hub,parent,getPrefs,save)
 local tools={status="Character waiting",walkActive=false}
 local owned=Overrides.new(); hub:add(owned)
 local charScope,panelScope,window,label,panelToggle,panelSlider,panelMultiplier,panelMode
 function tools.applySpeed()
  local h=Game.humanoid(); local p=getPrefs()
  if h and h.Health>0 and p.walkEnabled then
   local old=owned.entries.speed
   local base=old and old.object==h and old.original or h.WalkSpeed
   local value=p.speedMode=="Multiply" and base*p.speedMultiplier or p.walkSpeed
   local ok,err=pcall(function() owned:set("speed",h,"WalkSpeed",value) end)
   tools.requested=value;tools.walkActive=ok
   if ok then tools.status=("Local speed %.1f; no server-correction fallback"):format(value)
   else owned:clear("speed");p.walkEnabled=false;tools.status="WalkSpeed unavailable: "..tostring(err);save() end
  else owned:clear("speed"); tools.walkActive=false; tools.status=h and "Character OK · normal movement" or "Character waiting" end
 end
 local function bind(char)
  if charScope then charScope:close() end
  owned:clear("speed"); tools.walkActive=false;tools.status=char and "Character loading" or "Waiting for respawn"
  if tools.refreshStatus then tools.refreshStatus() end
  if hub.closed then return end
  charScope=Scope.new("player-tools-character")
  local watched
  local function watch(h)
   if not h:IsA("Humanoid") or watched==h then return end
   watched=h
   tools.applySpeed()
   charScope:connect(h.Died,function() owned:clear("speed"); tools.walkActive=false; tools.status="Waiting for respawn";tools.refreshStatus() end)
   charScope:connect(h:GetPropertyChangedSignal("WalkSpeed"),function()
    local e=owned.entries.speed
    if e and not e.writing and h.WalkSpeed~=e.written then owned:clear("speed");tools.walkActive=false;getPrefs().walkEnabled=false;save();tools.status="Game changed requested speed; disabled without retry";tools.refreshStatus() end
   end)
  end
  if char then
   local h=char:FindFirstChildOfClass("Humanoid"); if h then watch(h) end
   charScope:connect(char.ChildAdded,watch)
  end
 end
 local function panel()
  local p=getPrefs()
  if not p.movementPanel then if panelScope then panelScope:close();panelScope=nil;window=nil end; return end
  if panelScope then window.refresh();panelToggle.set(p.walkEnabled,true);panelSlider.set(p.walkSpeed,true);panelMultiplier.set(p.speedMultiplier,true);panelMode.set(p.speedMode,true);panelSlider.node.Visible=p.speedMode=="Set";panelMultiplier.node.Visible=p.speedMode=="Multiply"; return end
  if hub.closed then return end
  panelScope=Scope.new("movement-panel")
  window=makeWindow(panelScope,parent,"Ervi_MovementPanel",function()
   local c=getPrefs(); return {x=c.movementX,y=c.movementY,w=c.movementW*c.movementSize,h=c.movementH*c.movementSize}
  end,function(r)
   local c=getPrefs(); c.movementX,c.movementY,c.movementW,c.movementH=r.x,r.y,r.w/c.movementSize,r.h/c.movementSize;save()
  end)
  window.title.Text="Movement · Ervi Hub"
  label=Ui.text(window.body,"",{order=1})
  panelToggle=Ui.toggle(panelScope,window.body,"WalkSpeed",nil,p.walkEnabled,function(on) getPrefs().walkEnabled=on;tools.applySpeed();save() end,2)
  panelSlider=Ui.slider(panelScope,window.body,"Walk Speed",{min=0,max=100,step=1,value=p.walkSpeed,order=3},function(v) getPrefs().walkSpeed=v;tools.applySpeed();save() end)
  panelMultiplier=Ui.slider(panelScope,window.body,"Multiplier",{min=.25,max=4,step=.05,value=p.speedMultiplier,order=4},function(v) getPrefs().speedMultiplier=v;tools.applySpeed();save() end)
  panelMode=Ui.segment(panelScope,window.body,"Panel speed mode",{"Set","Multiply"},p.speedMode,function(v) getPrefs().speedMode=v;tools.apply();save() end,5)
  panelSlider.node.Visible=p.speedMode=="Set";panelMultiplier.node.Visible=p.speedMode=="Multiply"

 end
 function tools.refreshStatus()
  local char=Game.player.Character;local root=char and char:FindFirstChild("HumanoidRootPart")
  local ok,v=pcall(function() return root.AssemblyLinearVelocity end)
  tools.observed=ok and v and math.sqrt(v.X*v.X+v.Z*v.Z) or nil
  if label and label.Parent then Ui.set(label,"Text",tools.status..(tools.observed and (" · observed %.1f studs/s"):format(tools.observed) or " · observed speed unavailable")) end
 end
 function tools.apply() tools.applySpeed(); panel(); tools.refreshStatus() end
 bind(Game.player.Character)
 hub:connect(Game.player.CharacterAdded,bind)
 hub:connect(Game.player.CharacterRemoving,function() bind(nil) end)
 hub:add(function() if charScope then charScope:close() end; if panelScope then panelScope:close() end end)
 return tools
end
