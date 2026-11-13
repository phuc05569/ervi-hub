-- Fixed destination B and per-activation origin A. Explicit OFF returns to A
-- before releasing the hold. Death/corrections release without counter-movement.
local State=require("SafeZoneState")
local Game=require("Game")
local Scope=require("Scope")
local Hold=require("PositionHold")
local Positions=require("PositionData")
local Emergency=require("EmergencyState")
local makeTransport=require("MovementTransport")
return function(hub,getPrefs,save)
 local feature={enabled=false,status="Off",onChanged=nil,transitioning=false}
 local context
 local transport=makeTransport(hub,nil);feature.transport=transport;feature.zone="A"
 local emergency=Emergency.new();feature.emergency=emergency
 local healthScope
 getPrefs=getPrefs or function() return {} end;save=save or function() end
 local function root() local char=Game.player.Character;return char and char:FindFirstChild("HumanoidRootPart") end
 function feature.saved(zone)
  zone=zone or "A" -- preserve the legacy read-only target selector's reference
  local point=Positions.decode(getPrefs().safeZoneLocations or "")[zone]
  if point then return point.place==game.PlaceId and {place=point.place,components={point.x,point.y,point.z}} or nil end
  return zone=="A" and State.preset(game.PlaceId) or nil
 end
 function feature.saveLocation(zone,point)
  if zone~="A" and zone~="B" then return false end
  local all=Positions.decode(getPrefs().safeZoneLocations or "")
  all[zone]=point;local encoded=Positions.encode(all)
  if not encoded then return false end
  if feature.enabled and feature.zone==zone then feature.setEnabled(false,true) end
  getPrefs().safeZoneLocations=encoded;save();if feature.checkEmergency then feature.checkEmergency() end;return true
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
 local function matches(a,b)
  local av,bv={a:GetComponents()},{b:GetComponents()}
  for i=1,12 do if math.abs(av[i]-bv[i])>(i<=3 and 0.1 or 0.002) then return false end end
  return true
 end
 function feature.setEnabled(on,skipReturn)
  if feature.transitioning or (hub.closed and on) or on==feature.enabled then return end
  feature.transitioning=true
  if on and feature.beforeMove then feature.beforeMove() end
  if on and transport.busy then transport.cancel("Superseded by explicit Safe Zone activation") end
  if feature.zone=="B" then
   if not on then
    transport.cancel("Zone B off · remaining at current position",feature);feature.enabled=false;feature.status=transport.status
   else
    local destination=feature.saved("B")
    if not destination then feature.status="Zone B destination missing for this place"
    else
     local c=destination.components
     local accepted,reason=transport.move(Vector3.new(c[1],c[2],c[3]),nil,function(status,outcome)
      feature.status="Zone B: "..status.." · protection unverified"
      if outcome~="observed" and outcome~="server-acknowledged" then feature.enabled=false end
      if feature.onChanged then feature.onChanged(feature.enabled) end
     end,feature)
     feature.enabled=accepted;feature.status=accepted and "Zone B move requested · no protection claim" or reason
    end
   end
   feature.transitioning=false;if feature.onChanged then feature.onChanged(feature.enabled) end;return
  end
  if not on then
   feature.enabled=false
   local previous=context;context=nil
   if previous then
    previous.watchers:close() -- disconnect before our return CFrame write
    local returned,reason=false,"Return unavailable for this character"
    if not skipReturn and Game.player.Character==previous.char and root()==previous.root and Game.alive() then
     local ok,result=pcall(function()
      previous.char:PivotTo(previous.originPivot)
      return matches(previous.root.CFrame,previous.originRoot)
     end)
     returned=ok and result
     reason=returned and "Returned to activation origin locally; server acceptance unverified" or "Return failed or rejected locally; normal movement restored"
    elseif skipReturn then reason="Released without return after character/physics correction" end
    local released=pcall(previous.release)
    feature.status=released and reason or "Return/hold cleanup failed; character may have been removed"
   else feature.status="Off · no activation origin" end
  else
   local target,part=feature.saved(),root()
   if not target then feature.status="Unavailable in this place"
   elseif not part or not Game.alive() then feature.status="Wait for a living character, then turn Safe Zone on again"
   else
    local char=Game.player.Character
    local ok,originPivot,originRoot=pcall(function() return char:GetPivot(),part.CFrame end)
    local valid,encoded=pcall(function() local c={originPivot:GetComponents()};return ok and Positions.point(game.PlaceId,c[1],c[2],c[3]) end)
    if not valid or not encoded then
     feature.status="Activation origin is invalid; no move performed"
    else
     local release,err=Hold.acquire(part,Vector3.new(0,0,0),function()
      local x,y,z=part.CFrame:GetComponents();local c=target.components
      char:PivotTo(char:GetPivot()+Vector3.new(c[1]-x,c[2]-y,c[3]-z))
     end)
     if release then
      local watchers=Scope.new("safe-zone-observers")
      context={char=char,root=part,originPivot=originPivot,originRoot=originRoot,release=release,watchers=watchers}
      feature.enabled=true;feature.status="Local hold only · server position/protection unverified · OFF returns to origin"
      local function stop(reason) feature.setEnabled(false,true);feature.status=reason end
      local humanoid=Game.humanoid()
      if humanoid then watchers:connect(humanoid.Died,function() stop("Released · character died; origin cleared") end) end
      watchers:connect(char.ChildRemoved,function(child) if child==part then stop("Released · character root removed") end end)
      watchers:connect(part:GetPropertyChangedSignal("Anchored"),function() if not part.Anchored then stop("Released · external physics update") end end)
      watchers:connect(part:GetPropertyChangedSignal("CFrame"),function()
       local x,y,z=part.CFrame:GetComponents();local c=target.components
       if math.abs(x-c[1])+math.abs(y-c[2])+math.abs(z-c[3])>0.5 then stop("Released · external position update; no retry") end
      end)
     else feature.status="Move/hold failed · no retry: "..tostring(err) end
    end
   end
  end
  feature.transitioning=false
  if feature.onChanged then feature.onChanged(feature.enabled) end
 end
 function feature.checkEmergency()
  local p=getPrefs();local h=Game.humanoid()
  if emergency:evaluate(p.emergencyEnabled,feature.saved("B")~=nil,root() and h and h.Health,h and h.MaxHealth,p.emergencyHp or 30) then
   local destination=feature.saved("B");local part=root();local c=destination and destination.components
   if c and part and (part.Position-Vector3.new(c[1],c[2],c[3])).Magnitude<=6 then emergency.status="Already at configured Zone B · protection unverified";return end
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
   feature.checkEmergency()
  end
  if char then
   local h=char:FindFirstChildOfClass("Humanoid");if h then watch(h) end
   healthScope:connect(char.ChildAdded,function(child) watch(child);if child.Name=="HumanoidRootPart" then feature.checkEmergency() end end)
   healthScope:connect(char.ChildRemoved,function(child) if child.Name=="HumanoidRootPart" then feature.setEnabled(false,true);emergency.status="Waiting for character root" end end)
  end
 end
 bindHealth(Game.player.Character)
 hub:connect(Game.player.CharacterAdded,bindHealth)
 hub:add(function() if healthScope then healthScope:close() end end)
 hub:connect(Game.player.CharacterRemoving,function() feature.setEnabled(false,true) end)
 hub:add(function() feature.setEnabled(false) end)
 function feature.keyAction() feature.setEnabled(not feature.enabled) end
 return feature
end
