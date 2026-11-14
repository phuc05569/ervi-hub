-- Independent Auto Roll zone session and bounded emergency/manual B transaction.
-- All moves share Click TP's transport; physics hovering never anchors the root.
local State=require("SafeZoneState")
local Game=require("Game")
local Scope=require("Scope")
local Positions=require("PositionData")
local Emergency=require("EmergencyState")
local Hover=require("ZoneHover")
local makeTransport=require("MovementTransport")
local Run=game:GetService("RunService")
return function(hub,getPrefs)
 getPrefs=getPrefs or function() return {} end
 local feature={enabled=false,rollEnabled=false,zone="B",status="Off",rollStatus="Off",stabilizing=false}
 local transport=makeTransport(hub,nil);feature.transport=transport
 local emergency=Emergency.new();feature.emergency=emergency
 local active,session,block,healthScope,controller
 local leased=false
 local function root() local c=Game.player.Character;return c and c:FindFirstChild("HumanoidRootPart") end
 local function character()
  local c=Game.player.Character;local r=root();local h=Game.humanoid()
  if not c or not r or not h or h.Health<=0 or r.Anchored then return nil end
  return c,r,h
 end
 local function validReturn(point)
  if not point or point.place~=game.PlaceId or not Positions.point(point.place,point.x,point.y,point.z) then return false end
  return point.y>workspace.FallenPartsDestroyHeight+6
 end
 local function changed()
  if feature.onChanged then feature.onChanged(feature.enabled) end
  if feature.onRollChanged then feature.onRollChanged(feature.rollEnabled) end
 end
 function feature.saved(zone)
  zone=zone or "A"
  local point=Positions.decode(getPrefs().safeZoneLocations or "")[zone]
  if point then return point.place==game.PlaceId and {place=point.place,components={point.x,point.y,point.z}} or nil end
  return zone=="A" and State.preset(game.PlaceId) or zone=="B" and State.protectedPreset(game.PlaceId) or nil
 end
 local function destination(zone)
  local p=feature.saved(zone);local c=p and p.components
  return c and Vector3.new(c[1],c[2],c[3]) or nil
 end
 function feature.describe(zone)
  local r=root();local ok,cf=pcall(function() return {r.CFrame:GetComponents()} end)
  return State.describe(feature.saved(zone or feature.zone),ok and cf or nil)
 end
 function feature.setController(value)
  controller=value
  if leased then controller.suspend(feature) end
 end
 local function lease()
  if leased then return true end
  if controller and not controller.suspend(feature) then return false end
  leased=true;return true
 end
 local function release()
  if not leased then return end
  leased=false
  if controller then controller.resume(feature) end
 end
 local function closeHover(tx)
  if tx and tx.hover then tx.hover:close();tx.hover=nil end
  feature.stabilizing=false
 end
 local function cancel(reason,keepLease)
  local previous=active;active=nil
  closeHover(previous);transport.cancel(reason,feature)
  if not keepLease then release() end
 end
 local function condition()
  local p=getPrefs();if not p.emergencyEnabled then return false end
  local h=Game.humanoid()
  if not h or h.Health<=0 or h.MaxHealth<=0 then return nil end
  return h.Health/h.MaxHealth*100<=(p.emergencyHp or 30)
 end
 local startA
 local function fail(tx,reason)
  if active~=tx then return end
  cancel(reason,false)
  if tx.zone=="A" then
   block="correction";feature.rollStatus=reason.." · toggle OFF/ON or wait for respawn"
  elseif tx.zone=="return" then feature.rollStatus="Off · return failed: "..reason
  else feature.enabled=false;feature.status=reason end
  changed()
 end
 local function finishB(tx,status)
  if active~=tx then return end
  closeHover(tx);active=nil;feature.status="Zone B: "..status
  emergency.status=tx.emergency and feature.status or emergency.status
  if block=="emergency" and condition()==false then
   feature.enabled=false;block=nil
   if session then session.attemptedRoot=nil end
   if feature.rollEnabled then startA() end
  end
  if not active then release() end
  changed()
 end
 local function move(tx,phase)
  tx.phase=phase;tx.time=0;tx.moveDone=false
  local accepted,reason=transport.move(tx.point,nil,function(status,outcome)
   if active~=tx then return end
   if outcome~="observed" and outcome~="server-acknowledged" then fail(tx,status);return end
   tx.moveDone=true
   if tx.zone=="B" and phase=="final" then finishB(tx,status) end
  end,feature)
  if not accepted then fail(tx,tostring(reason)) end
 end
 local function transaction(zone,point,emergencyMove)
  local c,r=character();if not c then return false,"Waiting for a living, unanchored character" end
  if not lease() then return false,"Another movement controller owns stabilization" end
  local tx={zone=zone,point=point,char=c,root=r,phase="prepare",time=0,emergency=emergencyMove}
  active=tx;feature.zone=zone
  return true
 end
 startA=function()
  if not feature.rollEnabled or block or active or hub.closed then return end
  local point=destination("A")
  if not point then feature.rollStatus="Auto Roll Safe Zone unavailable in this place";return end
  local c,r=character()
  if not c then feature.rollStatus="Waiting for respawn / character readiness";return end
  if session.attemptedRoot==r then return end
  if not session.origin then
   session.origin=Positions.point(game.PlaceId,r.Position.X,r.Position.Y,r.Position.Z)
   if not session.origin then feature.rollStatus="Return position invalid; no move sent";return end
  end
  session.attemptedRoot=r
  local ok,reason=transaction("A",point,false)
  feature.rollStatus=ok and "Moving to Auto Roll Safe Zone" or reason
 end
 local function startB(isEmergency)
  local point=destination("B");local c=character()
  if not point or not c then feature.status=not point and "Zone B unavailable in this place" or "Waiting for a living character";return false end
  -- A newer explicit/emergency transaction supersedes the old observer, not
  -- an already delivered server command. ready() waits for that command first.
  cancel("Superseded by Zone B",true);transport.cancel("Zone B has movement priority")
  block=feature.rollEnabled and ((isEmergency or condition()==true) and "emergency" or "manual") or nil
  if feature.rollEnabled then feature.rollStatus="Suspended for Zone B" end
  local ok,reason=transaction("B",point,isEmergency)
  feature.enabled=ok;feature.status=ok and "Zone B: waiting to move" or reason
  if not ok then release() end
  changed();return ok
 end
 function feature.setRollEnabled(on,skipReturn)
  if hub.closed and on then return end
  if on==feature.rollEnabled then return end
  if on then
   feature.rollEnabled=true;session={};block=nil
   local _,r=character()
   if r then session.origin=Positions.point(game.PlaceId,r.Position.X,r.Position.Y,r.Position.Z) end
   if condition()==true then
    block="emergency";feature.rollStatus="Suspended for low-health emergency"
    if not (active and active.zone=="B") and not feature.enabled then startB(true) end
   else
    if feature.enabled or (active and active.zone~="A") then cancel("Switching to Auto Roll Safe Zone",true);feature.enabled=false end
    startA()
   end
  else
   feature.rollEnabled=false
   local origin=session and session.origin;session=nil;block=nil
   if active and active.zone=="A" then cancel("Auto Roll Safe Zone off",true) end
   feature.rollStatus="Off"
   if not skipReturn and validReturn(origin) and character() then
    if condition()==true then
     feature.rollStatus="Off · return suppressed during low-health emergency"
    else
     cancel("Return to Auto Roll Safe Zone activation origin",true);feature.enabled=false
     local point=Vector3.new(origin.x,origin.y,origin.z)
     local c,r=character()
     if lease() then active={zone="return",char=c,root=r,point=point,phase="prepare",time=0};feature.rollStatus="Returning to activation position"
     else feature.rollStatus="Off · movement controller busy; no return sent" end
    end
   elseif not skipReturn and origin then feature.rollStatus="Off · return position or character unavailable" end
   if not active then release() end
  end
  changed()
 end
 function feature.setEnabled(on)
  if on then if not feature.enabled then startB(false) end
  else
   if active and active.zone=="B" then cancel("Zone B disabled",true) end
   feature.enabled=false;feature.status="Off · remaining at current position"
   if block=="manual" then
    block=nil;if session then session.attemptedRoot=nil end;startA()
   end
   if not active then release() end
   changed()
  end
 end
 function feature.select(zone,on)
  if zone=="A" then feature.setRollEnabled(on)
  elseif zone=="B" then if on then startB(false) else feature.setEnabled(false) end end
 end
 function feature.checkEmergency()
  local p=getPrefs();local h=Game.humanoid()
  local ready=character()
  if emergency:evaluate(p.emergencyEnabled,feature.saved("B")~=nil,ready and h and h.Health,h and h.MaxHealth,p.emergencyHp or 30) then
   if startB(true) then emergency.status="Zone B emergency sequence active" end
  end
  if block=="emergency" and condition()==false and not (active and active.zone=="B") then
   block=nil;feature.enabled=false
   if session then session.attemptedRoot=nil end
  end
  startA()
 end
 -- A valid external Click TP suspends A without returning or losing its
 -- logical toggle/origin; it must not pull against the explicit move.
 transport.beforeMove=function(owner)
  if owner==feature then return end
  cancel("Superseded by explicit movement",false)
  feature.enabled=false
  if feature.rollEnabled then
   block="external";feature.rollStatus="Suspended by explicit movement · toggle OFF/ON to resume"
  end
  changed()
 end
 hub:connect(Run.Heartbeat,function(dt)
  local tx=active;if not tx then return end
  if not controller then return end -- Expansion must attach the existing adapter/controller first
  if Game.player.Character~=tx.char or root()~=tx.root or not Game.alive() then
   cancel("Waiting for respawn",false);feature.enabled=false
   if feature.rollEnabled then feature.rollStatus="Waiting for respawn" end
   changed();return
  end
  if tx.root.Anchored then fail(tx,"External anchor detected; stabilization released");return end
  tx.time+=dt
  if tx.phase=="prepare" then
   if transport.ready() then move(tx,"first")
   elseif tx.time>2 then fail(tx,"Previous movement still pending; no overlapping request") end
   return
  end
  if tx.zone=="return" then
   if tx.moveDone then active=nil;feature.rollStatus="Off · return observed locally";release()
   elseif tx.time>2 then fail(tx,"Return not confirmed; no retry") end
   return
  end
  local distance=(tx.root.Position-tx.point).Magnitude
  if tx.seen and distance>16 then fail(tx,"Position displaced; hover released without retry");return end
  if distance<=6 then tx.seen=true end
  if tx.phase=="first" then
   if tx.seen and not tx.hover and (tx.zone=="A" or tx.time>=0.1) then
    local hover,reason=Hover.acquire(tx.root,tx.root.Position)
    if not hover then fail(tx,tostring(reason));return end
    tx.hover=hover;tx.hoverTime=0;feature.stabilizing=true
   end
   if tx.hover then tx.hoverTime+=dt end
   if tx.zone=="A" and tx.moveDone and tx.hover then
    tx.phase="hover";feature.rollStatus="Auto Roll Safe Zone ON · hovering; rolling follows game readiness"
   elseif tx.zone=="B" and tx.hover and tx.hoverTime>=1 then
    closeHover(tx);tx.phase="final-ready";tx.time=0;feature.status="Zone B: hover released; preparing final move"
   elseif tx.time>2 and (not tx.hover or not tx.moveDone) then fail(tx,"Initial movement not confirmed; no hover or repeat move") end
  elseif tx.phase=="final-ready" then
   if tx.moveDone and transport.ready() then move(tx,"final")
   elseif tx.time>2 then fail(tx,"Initial move still unconfirmed; final move cancelled") end
  elseif tx.phase=="final" and tx.time>2 then fail(tx,"Final movement not confirmed; no retry") end
 end)
 local function lostCharacter()
  cancel("Character unavailable",false);feature.enabled=false
  if block~="emergency" then block=nil end
  if session then session.attemptedRoot=nil end
  if feature.rollEnabled then feature.rollStatus="Waiting for respawn / character readiness" end
  changed()
 end
 local function bindHealth(char)
  if active and active.char~=char then lostCharacter() end
  if block=="correction" then block=nil end
  if healthScope then healthScope:close() end
  healthScope=Scope.new("safe-zone-character");emergency:reset()
  local watchedHumanoid,watchedRoot
  local humanoidScope,rootScope
  healthScope:add(function()
   if humanoidScope then humanoidScope:close() end
   if rootScope then rootScope:close() end
  end)
  local function watch()
   if not char then return end
   local h=char:FindFirstChildOfClass("Humanoid");local r=char:FindFirstChild("HumanoidRootPart")
   if h and h~=watchedHumanoid then
    watchedHumanoid=h
    if humanoidScope then humanoidScope:close() end
    humanoidScope=Scope.new("zone-humanoid")
    humanoidScope:connect(h.HealthChanged,feature.checkEmergency)
    humanoidScope:connect(h:GetPropertyChangedSignal("MaxHealth"),feature.checkEmergency)
    humanoidScope:connect(h.Died,lostCharacter)
   end
   if r and r~=watchedRoot then
    watchedRoot=r
    if rootScope then rootScope:close() end
    rootScope=Scope.new("zone-root")
    rootScope:connect(r:GetPropertyChangedSignal("Anchored"),feature.checkEmergency)
   end
   feature.checkEmergency()
  end
  if char then
   healthScope:connect(char.ChildAdded,watch)
   healthScope:connect(char.ChildRemoved,function(child)
    if child==watchedHumanoid or child==watchedRoot then lostCharacter() end
   end)
   watch()
  end
 end
 hub:connect(Game.player.CharacterAdded,bindHealth)
 hub:connect(Game.player.CharacterRemoving,lostCharacter)
 hub:add(function()
  feature.rollEnabled=false;feature.enabled=false;session=nil;block=nil
  cancel("Unloaded",false)
  if healthScope then healthScope:close() end
 end)
 bindHealth(Game.player.Character)
 function feature.keyAction() feature.setEnabled(not feature.enabled) end
 return feature
end
