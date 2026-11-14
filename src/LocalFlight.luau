-- Native character constraints, with local-only evidence. No correction bypass.
local Scope=require("Scope")
local Overrides=require("PropertyOverrides")
local Game=require("Game")
local Input=game:GetService("UserInputService")
local Run=game:GetService("RunService")
return function(hub,getPrefs,save)
 local api={available=true,active=false,flying=false,noclip=false,status="Off · native movement; replication unverified"}
 local collisionScope
 local flightScope
 local owner,char,hum,root,owned,velocity,orientation,attachment
 local parts={};local focused=true
 local function cleanup()
  if collisionScope then collisionScope:close();collisionScope=nil end
  if flightScope then flightScope:close();flightScope=nil end
  if owner then owner:close();owner=nil end
  char=nil;hum=nil;root=nil;owned=nil;velocity=nil;orientation=nil;attachment=nil;parts={}
  api.active=false;api.flying=false;api.noclip=false
 end
 function api.stop(reason)
  cleanup();local p=getPrefs();p.flyEnabled=false;p.noclipEnabled=false;save()
  api.status=reason or "Off · restored owned properties"
 end
 function api.suspend(by)
  if api.suspended and api.suspended~=by then return false end
  api.suspended=by;cleanup();api.status="Movement suspended for zone stabilization";return true
 end
 function api.resume(by)
  if api.suspended~=by then return end
  api.suspended=nil
  if not hub.closed then api.apply() end
 end
 local function part(node)
  if not api.noclip or not node:IsA("BasePart") or parts[node] then return end
  parts[node]=true;owned:set(node,node,"CanCollide",false)

 end
 function api.apply()
  if api.suspended then return end -- desired settings and held keys remain untouched
  local p=getPrefs()
  if not p.flyEnabled and not p.noclipEnabled then cleanup();return end
  if api.beforeStart then api.beforeStart() end
  local character=Game.player.Character;local h=Game.humanoid();local r=character and character:FindFirstChild("HumanoidRootPart")
  if not h or h.Health<=0 or not r or r.Anchored then api.stop("Character unavailable or position held");return end
  if not owner or char~=character then
   cleanup();owner=Scope.new("native-flight");char=character;hum=h;root=r;owned=owner:add(Overrides.new())
   owner:connect(h.Died,function() api.stop("Waiting for respawn") end)
   owner:connect(char.DescendantAdded,part)
   owner:connect(char.DescendantRemoving,function(node)
    if parts[node] then parts[node]=nil;owned:clear(node) end
   end)
   owner:connect(char.ChildRemoved,function(node) if node==root or node==hum then api.stop("Character changed") end end)
   owner:connect(root:GetPropertyChangedSignal("Anchored"),function() if root.Anchored then api.stop("Position held; movement stopped") end end)
  end
  if p.flyEnabled and not api.flying then
   flightScope=Scope.new("native-flight-constraints")
   flightScope:add(function() if root and root.Parent then root.AssemblyLinearVelocity=Vector3.new();root.AssemblyAngularVelocity=Vector3.new() end end)
   local ok,err=pcall(function()
    attachment=flightScope:add(Instance.new("Attachment"));attachment.Name="ErviFlightAttachment";attachment.Parent=root
    velocity=flightScope:add(Instance.new("LinearVelocity"));velocity.Name="ErviFlightVelocity";velocity.Attachment0=attachment;velocity.RelativeTo=Enum.ActuatorRelativeTo.World;velocity.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector;velocity.MaxForce=1e7;velocity.VectorVelocity=Vector3.new();velocity.Parent=root
    orientation=flightScope:add(Instance.new("AlignOrientation"));orientation.Name="ErviFlightOrientation";orientation.Attachment0=attachment;orientation.Mode=Enum.OrientationAlignmentMode.OneAttachment;orientation.MaxTorque=1e7;orientation.Responsiveness=25;orientation.CFrame=root.CFrame;orientation.Parent=root
    owned:set("platform",hum,"PlatformStand",true);owned:set("rotate",hum,"AutoRotate",false)
   end)
   if not ok then api.stop("Native constraints unavailable: "..tostring(err));return end
  elseif not p.flyEnabled and api.flying then
   if flightScope then flightScope:close();flightScope=nil end
   velocity=nil;orientation=nil;attachment=nil
   owned:clear("platform");owned:clear("rotate")
  end
  if p.noclipEnabled~=api.noclip then
   api.noclip=p.noclipEnabled
   if api.noclip then
    collisionScope=Scope.new("native-collision-step");for _,node in ipairs(char:GetDescendants()) do part(node) end
    -- Humanoid states can restore local collision flags during ordinary simulation.
    -- Maintain only cached local parts; never rewrite character position or server state.
    collisionScope:connect(Run.PreSimulation,function()
     for node in pairs(parts) do if node.Parent and node.CanCollide then owned:set(node,node,"CanCollide",false) end end
    end)
   else
    if collisionScope then collisionScope:close();collisionScope=nil end
    for node in pairs(parts) do owned:clear(node) end;parts={}
   end
  end
  api.flying=p.flyEnabled;api.active=api.flying or api.noclip
  api.status="Native local movement · Fly "..tostring(api.flying).." · Noclip "..tostring(api.noclip).." · replication/game acceptance unverified"
 end
 function api.toggle(key) getPrefs()[key]=not getPrefs()[key];api.apply();save();return true end
 hub:connect(Run.Heartbeat,function(dt)
  if not api.active then return end
  if not Game.alive() or not root or not root.Parent then api.stop("Character unavailable");return end
  if not api.flying then return end
  local camera=workspace.CurrentCamera;if not camera then return end
  local direction=Vector3.new()
  local function key(name) return Input:IsKeyDown(Enum.KeyCode[name]) and 1 or 0 end
  if focused and not Input:GetFocusedTextBox() then direction=camera.CFrame.LookVector*(key("W")-key("S"))+camera.CFrame.RightVector*(key("D")-key("A"))+Vector3.new(0,key("Space")-key("LeftControl"),0) end
  if direction.Magnitude>1 then direction=direction.Unit end
  local desired=direction*getPrefs().flySpeed;local alpha=1-math.exp(-20*math.min(dt,.1))
  velocity.VectorVelocity=velocity.VectorVelocity+(desired-velocity.VectorVelocity)*alpha
  local look=Vector3.new(camera.CFrame.LookVector.X,0,camera.CFrame.LookVector.Z)
  if look.Magnitude>.01 then orientation.CFrame=CFrame.lookAt(root.Position,root.Position+look) end
 end)
 hub:connect(Input.WindowFocusReleased,function()
  focused=false
  if velocity then velocity.VectorVelocity=Vector3.zero end
 end)
 hub:connect(Input.WindowFocused,function() focused=true end)
 hub:connect(Game.player.CharacterRemoving,function() api.stop("Waiting for respawn") end)
 hub:add(cleanup)
 return api
end
