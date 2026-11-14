-- A and B share Click TP's one-attempt transport. Only B has a bounded hold.
local State=require("SafeZoneState")
local Game=require("Game")
local Scope=require("Scope")
local Hold=require("PositionHold")
local Positions=require("PositionData")
local Emergency=require("EmergencyState")
local makeTransport=require("MovementTransport")
local Run=game:GetService("RunService")
return function(hub,getPrefs,save)
 local feature={enabled=false,status="Off",onChanged=nil,transitioning=false,zone="A",stabilizing=false}
 local context,zoneScope,healthScope
 local generation=0
 local transport=makeTransport(hub,nil);feature.transport=transport
 local emergency=Emergency.new();feature.emergency=emergency
 getPrefs=getPrefs or function() return {} end;save=save or function() end
 local function root() local char=Game.player.Character;return char and char:FindFirstChild("HumanoidRootPart") end
 local function notify() if feature.onChanged then feature.onChanged(feature.enabled) end end
 local function cleanup()
  if zoneScope then zoneScope:close();zoneScope=nil end
  feature.stabilizing=false
 end
 function feature.saved(zone)
  zone=zone or "A"
  local point=Positions.decode(getPrefs().safeZoneLocations or "")[zone]
  if point then return point.place==game.PlaceId and {place=point.place,components={point.x,point.y,point.z}} or nil end
  return zone=="A" and State.preset(game.PlaceId) or zone=="B" and State.protectedPreset(game.PlaceId) or nil
 end
 function feature.select(zone,on)
  if zone~="A" and zone~="B" then return end
  if feature.enabled then feature.setEnabled(false,true) end
  feature.zone=zone
  if on then feature.setEnabled(true) end
 end
 function feature.describe()
  local part=root();local ok,cf=pcall(function() return {part.CFrame:GetComponents()} end)
  return State.describe(feature.saved(feature.zone),ok and cf or nil)
 end
 local function watchB(char,part,destination,token)
  zoneScope=Scope.new("zone-b-stabilization")
  local lockScope,lockPosition,remaining
  local arrived,armed=false,false
  local elapsed=0
  local function release()
   local old=lockScope;lockScope=nil;lockPosition=nil;remaining=nil;feature.stabilizing=false
   if old then old:close() end
  end
  zoneScope:add(release)
  local function lock()
   if lockScope or part.Anchored then return end
   local acquired,reason=Hold.acquire(part,Vector3.zero,function() end)
   if not acquired then feature.status="Zone B stabilization unavailable: "..tostring(reason);return end
   lockPosition=part.Position;remaining=2;feature.stabilizing=true;armed=false
   lockScope=Scope.new("zone-b-two-second-hold");lockScope:add(acquired)
   -- Observe external correction rather than counter-teleporting it.
   lockScope:connect(part:GetPropertyChangedSignal("CFrame"),function()
    if lockPosition and (part.Position-lockPosition).Magnitude>0.5 then
     feature.setEnabled(false,true);feature.status="Zone B released after external position update; no retry"
    end
   end)
   lockScope:connect(part:GetPropertyChangedSignal("Anchored"),function()
    if not part.Anchored then
     feature.setEnabled(false,true);feature.status="Zone B released after external physics update; no retry"
    end
   end)
  end
  zoneScope:connect(Run.Heartbeat,function(dt)
   if token~=generation or not feature.enabled or feature.zone~="B" then return end
   if Game.player.Character~=char or root()~=part or not Game.alive() then
    feature.setEnabled(false,true);return
   end
   elapsed+=dt
   local distance=(part.Position-destination).Magnitude
   if distance>12 and arrived then
    feature.setEnabled(false,true);feature.status="Left Zone B; stabilization released";return
   end
   if not arrived then
    if distance<=6 then arrived=true;lock()
    elseif elapsed>1.5 and not transport.busy then
     feature.setEnabled(false,true);feature.status="Zone B arrival not observed; no lock or retry"
    end
    return
   end
   if lockScope then
    remaining-=dt
    if remaining<=0 then release() end
    return
   end
   local speed=part.AssemblyLinearVelocity.Magnitude
   -- Edge-trigger only while still near B. A continuing force cannot create
   -- an endless series of holds; a calm observation must first rearm it.
   if distance<=6 and speed<20 then armed=true end
   if armed and distance<=12 and speed>60 then lock() end
  end)
 end
 function feature.setEnabled(on,skipReturn)
  if feature.transitioning or (hub.closed and on) or on==feature.enabled then return end
  feature.transitioning=true;generation+=1
  local token=generation
  if not on then
   feature.enabled=false
   local previous=context;context=nil
   cleanup();transport.cancel("Safe Zone off",feature)
   feature.status="Off · normal movement restored"
   if previous and previous.zone=="A" and not skipReturn and not hub.closed and
      Game.player.Character==previous.char and root()==previous.root and Game.alive() then
    if feature.beforeMove then feature.beforeMove() end
    local accepted,reason=transport.move(previous.origin,nil,function(status)
     if token==generation then feature.status="Zone A return: "..status end
    end,feature)
    feature.status=accepted and "Returning once to Zone A activation origin" or tostring(reason)
   end
  else
   local destination=feature.saved(feature.zone);local part=root()
   if not destination then feature.status="Destination missing for this place"
   elseif not part or not Game.alive() then feature.status="Wait for a living character, then enable again"
   else
    if feature.beforeMove then feature.beforeMove() end
    cleanup();transport.cancel("Superseded by Safe Zone activation")
    local char=Game.player.Character;local zone=feature.zone
    local c=destination.components;local point=Vector3.new(c[1],c[2],c[3])
    local origin=part.Position
    local function completed(status,outcome)
     if token~=generation then return end
     feature.status="Zone "..zone..": "..status
     if outcome~="observed" and outcome~="server-acknowledged" then
      feature.enabled=false;context=nil;cleanup()
     end
     notify()
    end
    local alreadyB=zone=="B" and (origin-point).Magnitude<=6
    local accepted,reason=true,nil
    if not alreadyB then accepted,reason=transport.move(point,nil,completed,feature) end
    feature.enabled=accepted
    feature.status=alreadyB and "Already at Zone B · stabilization armed without another move" or
     accepted and ("Zone "..zone.." move requested · game roll/protection rules unchanged") or tostring(reason)
    if accepted then
     context={char=char,root=part,zone=zone,origin=origin}
     if zone=="B" then watchB(char,part,point,token) end
    end
   end
  end
  feature.transitioning=false;notify()
 end
 -- A later successful Click TP releases the zone's properties and activation
 -- state before its own move. Invalid/busy clicks do not discard the zone.
 transport.beforeMove=function(owner)
  if owner~=feature and feature.enabled then feature.setEnabled(false,true) end
 end
 function feature.checkEmergency()
  local p=getPrefs();local h=Game.humanoid()
  if emergency:evaluate(p.emergencyEnabled,feature.saved("B")~=nil,root() and h and h.Health,h and h.MaxHealth,p.emergencyHp or 30) then
   local destination=feature.saved("B");local part=root();local c=destination and destination.components
   if c and part and (part.Position-Vector3.new(c[1],c[2],c[3])).Magnitude<=6 then
    emergency.status="Already at configured Zone B"
    if not feature.enabled or feature.zone~="B" then feature.select("B",true) end
    return
   end
   feature.select("B",true);emergency.status=feature.status
  end
 end
 local function bindHealth(char)
  if healthScope then healthScope:close() end
  healthScope=Scope.new("emergency-health");emergency:reset()
  local watched
  local function watch(h)
   if not h:IsA("Humanoid") or watched==h then return end
   watched=h
   healthScope:connect(h.HealthChanged,feature.checkEmergency)
   healthScope:connect(h:GetPropertyChangedSignal("MaxHealth"),feature.checkEmergency)
   healthScope:connect(h.Died,function() feature.setEnabled(false,true) end)
   feature.checkEmergency()
  end
  if char then
   local h=char:FindFirstChildOfClass("Humanoid");if h then watch(h) end
   healthScope:connect(char.ChildAdded,function(child) watch(child);if child.Name=="HumanoidRootPart" then feature.checkEmergency() end end)
   healthScope:connect(char.ChildRemoved,function(child)
    if child.Name=="HumanoidRootPart" or child==watched then feature.setEnabled(false,true);emergency.status="Waiting for character" end
   end)
  end
 end
 bindHealth(Game.player.Character)
 hub:connect(Game.player.CharacterAdded,bindHealth)
 hub:connect(Game.player.CharacterRemoving,function() feature.setEnabled(false,true) end)
 hub:add(function()
  generation+=1;feature.enabled=false;context=nil;cleanup();transport.cancel("Unloaded",feature)
  if healthScope then healthScope:close() end
 end)
 function feature.keyAction() feature.setEnabled(not feature.enabled) end
 return feature
end
