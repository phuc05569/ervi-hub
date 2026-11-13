-- Fixed destination B and per-activation origin A. Explicit OFF returns to A
-- before releasing the hold. Death/corrections release without counter-movement.
local State=require("SafeZoneState")
local Game=require("Game")
local Scope=require("Scope")
local Hold=require("PositionHold")
return function(hub)
 local feature={enabled=false,status="Off",onChanged=nil,transitioning=false}
 local context
 local function root() local char=Game.player.Character;return char and char:FindFirstChild("HumanoidRootPart") end
 function feature.saved() return State.preset(game.PlaceId) end
 function feature.describe()
  local part=root();local ok,cf=pcall(function() return {part.CFrame:GetComponents()} end)
  return State.describe(feature.saved(),ok and cf or nil)
 end
 local function matches(a,b)
  local av,bv={a:GetComponents()},{b:GetComponents()}
  for i=1,12 do if math.abs(av[i]-bv[i])>(i<=3 and 0.1 or 0.002) then return false end end
  return true
 end
 function feature.setEnabled(on,skipReturn)
  if feature.transitioning or (hub.closed and on) or on==feature.enabled then return end
  feature.transitioning=true
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
    local valid,encoded=pcall(function() return ok and State.encode(game.PlaceId,{originPivot:GetComponents()}) end)
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
      feature.enabled=true;feature.status="Holding at Safe Zone · OFF returns to activation origin"
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
 hub:connect(Game.player.CharacterRemoving,function() feature.setEnabled(false,true) end)
 hub:add(function() feature.setEnabled(false) end)
 function feature.keyAction() feature.setEnabled(not feature.enabled) end
 return feature
end
