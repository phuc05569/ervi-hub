-- One camera-relative input controller, paired with the explicitly authorized
-- Studio server. The client never writes character CFrames, collision or movers.
local Game=require("Game")
local Input=game:GetService("UserInputService")
local Run=game:GetService("RunService")
return function(hub,getPrefs,save,authority)
 if not authority.available then
  getPrefs().flyEnabled=false;getPrefs().noclipEnabled=false
  return require("LocalFlight")(hub,getPrefs,save)
 end
 local api={active=false,flying=false,noclip=false,available=authority.available,status=authority.status}
 local desired,lastRequest,elapsed,focused=nil,nil,0,true
 local cooldown=0
 local epoch,pending=0,false
 getPrefs().flyEnabled=false;getPrefs().noclipEnabled=false -- never resume physics on reload
 local function reset(reason)
  epoch+=1;pending=false;api.active=false;api.flying=false;api.noclip=false;lastRequest=nil
  getPrefs().flyEnabled=false;getPrefs().noclipEnabled=false;save();api.status=reason
 end
 function api.stop(reason)
  desired=nil
  if authority.release then authority.release() end
  reset(api.available and (reason or "Flight and Noclip off") or authority.status)
 end
 function api.apply()
  local p=getPrefs()
  if not api.available then api.status=authority.status;return end
  if (p.flyEnabled or p.noclipEnabled) and api.beforeStart then api.beforeStart() end
  desired={fly=p.flyEnabled,noclip=p.noclipEnabled,speed=p.flySpeed}
  if not desired.fly and not desired.noclip and (api.active or pending) then api.stop("Flight and Noclip off");return end
  local signature=tostring(desired.fly).."/"..tostring(desired.noclip).."/"..desired.speed
  if cooldown>0 or authority.busy or signature==lastRequest or (not desired.fly and not desired.noclip and not api.active) then return end
  local requested=desired;local token=epoch;pending=true
  cooldown=0.2;lastRequest=signature;api.status="Waiting for owned Studio server"
  authority.request("set",requested,function(result)
   if token~=epoch then authority.release();return end
   pending=false
   if result.ok then
    api.flying=result.fly==true;api.noclip=result.noclip==true;api.active=api.flying or api.noclip
    api.status=("Studio server · Fly %s · Noclip %s · speed %.0f"):format(api.flying and "ON" or "OFF",api.noclip and "ON" or "OFF",requested.speed)
    api.apply() -- reconcile a newer explicit setting only after a known response
   else api.stop(result.message or "Server rejected movement") end
  end)
 end
 function api.toggle(key)
  if not api.available then api.status=authority.status;return false end
  getPrefs()[key]=not getPrefs()[key];save();api.apply();return true
 end
 if not api.available then return api end
 if authority.changed then hub:connect(authority.changed,function(state)
  if type(state)=="table" and state.fly==false and state.noclip==false then reset("Studio server stopped: "..tostring(state.reason)) end
 end) end
 hub:connect(Run.Heartbeat,function(dt)
  cooldown=math.max(0,cooldown-dt)
  elapsed+=dt;if elapsed<1/20 then return end;elapsed=0
  if api.available then api.apply() end
  if not api.active or not authority.control then return end
  if not Game.alive() then api.stop("Character unavailable");return end
  local cam=workspace.CurrentCamera;if not cam then api.stop("Camera unavailable");return end
  local direction=Vector3.zero
  local function down(key) return Input:IsKeyDown(Enum.KeyCode[key]) and 1 or 0 end
  if api.flying and focused and not Input:GetFocusedTextBox() then
   direction=cam.CFrame.LookVector*(down("W")-down("S"))+cam.CFrame.RightVector*(down("D")-down("A"))+Vector3.new(0,down("Space")-down("LeftControl"),0)
   if direction.Magnitude>1 then direction=direction.Unit end
  end
  local look=Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z)
  if look.Magnitude<0.01 then look=Vector3.new(0,0,-1) else look=look.Unit end
  authority.control({direction.X,direction.Y,direction.Z},{look.X,0,look.Z})
 end)
 hub:connect(Input.WindowFocusReleased,function()
  focused=false
  if api.active and authority.control then authority.control({0,0,0},{0,0,-1}) end
 end)
 hub:connect(Input.WindowFocused,function() focused=true end)
 hub:connect(Game.player.CharacterRemoving,function() api.stop("Character removed") end)
 hub:add(function() if authority.release then authority.release() end end)
 return api
end
