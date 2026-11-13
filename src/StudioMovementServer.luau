-- Install explicitly in the owned, unpublished Studio test place. Never runs
-- from the client bundle. No target-game adapter or collision bypass is provided.
local Scope=require("Scope")
local Overrides=require("PropertyOverrides")
local Policy=require("MovementPolicy")
local Target=require("ClickTarget")
return function()
 local Run=game:GetService("RunService")
 assert(Run:IsServer() and Run:IsStudio() and game.PlaceId==0 and game.GameId==0,"Unpublished owned Studio server only")
 local storage=game:GetService("ReplicatedStorage")
 assert(not storage:FindFirstChild("ErviStudioAuthority"),"Authority already installed")
 local scope=Scope.new("owned-studio-movement")
 -- WorldRoot on current engines; older Studio builds forward through PhysicsService.
 local groups=workspace
 local modern=pcall(function() assert(type(groups.RegisterCollisionGroup)=="function") end)
 if not modern then groups=game:GetService("PhysicsService") end
 local ghost="ErviStudioGhost"
 assert(not groups:IsCollisionGroupRegistered(ghost),"Fixture collision group already exists")
 groups:RegisterCollisionGroup(ghost)
 for _,group in ipairs(groups:GetRegisteredCollisionGroups()) do groups:CollisionGroupSetCollidable(ghost,group.name,false) end
 scope:add(function() groups:UnregisterCollisionGroup(ghost) end)
 local folder=scope:add(Instance.new("Folder"));folder.Name="ErviStudioAuthority"
 folder:SetAttribute("Protocol",Policy.protocol);folder:SetAttribute("ErviOwnedFixture",true)
 local request=Instance.new("RemoteFunction");request.Name="Request";request.Parent=folder
 local control=Instance.new("RemoteEvent");control.Name="Control";control.Parent=folder
 local stateEvent=Instance.new("RemoteEvent");stateEvent.Name="State";stateEvent.Parent=folder
 local states,requests,teleports={},{},{}
 local api={states=states}
 local function releaseFly(s)
  if s.flight then s.flight:close();s.flight=nil end
  s.fly=false;s.velocity=Vector3.zero;s.direction=Vector3.zero
 end
 local function releaseNoclip(s)
  if s.collision then s.collision:close();s.collision=nil end
  s.noclip=false
 end
 local function stop(player,reason)
  local s=states[player];if not s then return end
  states[player]=nil;releaseFly(s);releaseNoclip(s);s.scope:close()
  if player.Parent then stateEvent:FireClient(player,{fly=false,noclip=false,reason=reason}) end
 end
 local function alive(player)
  local char=player.Character;local root=char and char:FindFirstChild("HumanoidRootPart")
  local hum=char and char:FindFirstChildOfClass("Humanoid")
  if not (root and hum and hum.Health>0 and root:IsDescendantOf(workspace)) then return nil end
  return char,root,hum
 end
 local function getState(player)
  local char,root,hum=alive(player);if not char or root.Anchored then return nil end
  local s=states[player]
  if s and s.character~=char then stop(player,"Character replaced");s=nil end
  if s then return s end
  s={scope=Scope.new("studio-character-movement"),character=char,root=root,hum=hum,fly=false,noclip=false,direction=Vector3.zero,velocity=Vector3.zero,look=Vector3.new(0,0,-1),speed=50,deadline=os.clock()+1.5,lastInput=-math.huge}
  states[player]=s
  s.scope:connect(hum.Died,function() stop(player,"Death") end)
  s.scope:connect(player.CharacterRemoving,function() stop(player,"Character removed") end)
  s.scope:connect(root.AncestryChanged,function() if not root:IsDescendantOf(char) then stop(player,"Root removed") end end)
  s.scope:connect(root:GetPropertyChangedSignal("Anchored"),function() if root.Anchored then stop(player,"External anchor") end end)
  return s
 end
 local function flight(s)
  if s.fly then return end
  local owner=Scope.new("studio-flight");s.flight=owner
  local properties=owner:add(Overrides.new())
  properties:set("platform",s.hum,"PlatformStand",true);properties:set("rotate",s.hum,"AutoRotate",false)
  local wasAuto=s.root:GetNetworkOwnershipAuto();local priorOwner=s.root:GetNetworkOwner()
  s.root:SetNetworkOwner(nil)
  owner:add(function()
   if s.root.Parent then
    s.root.AssemblyLinearVelocity=Vector3.zero;s.root.AssemblyAngularVelocity=Vector3.zero
    if wasAuto then s.root:SetNetworkOwnershipAuto() else s.root:SetNetworkOwner(priorOwner) end
   end
  end)
  local attachment=owner:add(Instance.new("Attachment"));attachment.Name="ErviFlightAttachment";attachment.Parent=s.root
  local velocity=owner:add(Instance.new("LinearVelocity"));velocity.Name="ErviFlightVelocity";velocity.Attachment0=attachment
  velocity.RelativeTo=Enum.ActuatorRelativeTo.World;velocity.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector
  velocity.ForceLimitsEnabled=true;velocity.ForceLimitMode=Enum.ForceLimitMode.Magnitude
  velocity.MaxForce=math.clamp(s.root.AssemblyMass*(workspace.Gravity*6+1200),1000,2000000)
  velocity.VectorVelocity=Vector3.zero;velocity.Parent=s.root
  local orientation=owner:add(Instance.new("AlignOrientation"));orientation.Name="ErviFlightOrientation";orientation.Attachment0=attachment
  orientation.Mode=Enum.OrientationAlignmentMode.OneAttachment;orientation.RigidityEnabled=false;orientation.Responsiveness=15
  orientation.MaxTorque=math.clamp(s.root.AssemblyMass*20000,1000,2000000);orientation.MaxAngularVelocity=10
  orientation.CFrame=CFrame.lookAt(Vector3.zero,s.look);orientation.Parent=s.root
  s.linear=velocity;s.orientation=orientation;s.fly=true
 end
 local function noclip(s)
  if s.noclip then return end
  local owner=Scope.new("studio-collision");s.collision=owner
  local properties=owner:add(Overrides.new())
  local function part(node) if node:IsA("BasePart") then properties:set(node,node,"CollisionGroup",ghost) end end
  for _,node in ipairs(s.character:GetDescendants()) do part(node) end
  owner:connect(s.character.DescendantAdded,part)
  owner:connect(s.character.DescendantRemoving,function(node) properties:clear(node) end)
  s.noclip=true
 end
 local function deny(message) return {ok=false,message=message} end
 request.OnServerInvoke=function(player,action,payload)
  -- Authorization is server context + sender's own character; never a client-supplied player.
  if not player:IsDescendantOf(game.Players) then return deny("Invalid sender") end
  if action=="set" and Policy.state(payload) and not payload.fly and not payload.noclip then stop(player,"Disabled");return {ok=true,fly=false,noclip=false} end
  local now=os.clock()
  if now-(requests[player] or -math.huge)<0.15 then return deny("Request rate limit") end
  requests[player]=now
  if action=="set" then
   if not Policy.state(payload) then return deny("Invalid movement state") end
   local s=getState(player);if not s then return deny("Alive unanchored character required") end
   s.speed=payload.speed;s.deadline=now+1.5
   local ok,err=pcall(function()
    if payload.fly then flight(s) else releaseFly(s) end
    if payload.noclip then noclip(s) else releaseNoclip(s) end
   end)
   if not ok then stop(player,"Controller initialization failed");return deny(tostring(err)) end
   return {ok=true,fly=s.fly,noclip=s.noclip,speed=s.speed}
  elseif action=="teleport" then
   if type(payload)~="table" or typeof(payload.position)~="Vector3" or type(payload.range)~="number" or payload.range~=payload.range or payload.range<10 or payload.range>500 then return deny("Invalid destination") end
   if states[player] then return deny("Stop flight and noclip before teleport") end
   local char,root,hum=alive(player);if not char or root.Anchored then return deny("Alive unanchored character required") end
   if now-(teleports[player] or -math.huge)<1 then return deny("Teleport cooldown") end
   local pos=payload.position
   if not Target.valid({pos.X,pos.Y,pos.Z},{0,1,0},(pos-root.Position).Magnitude,payload.range) then return deny("Destination out of range") end
   local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={char};params.IgnoreWater=true
   local hit=workspace:Raycast(pos+Vector3.new(0,6,0),Vector3.new(0,-12,0),params)
   if not hit or hit.Normal.Y<0.3 or (hit.Position-pos).Magnitude>1 or not hit.Instance.CanCollide then return deny("Invalid landing surface") end
   local model=hit.Instance:FindFirstAncestorOfClass("Model")
   if model and model:FindFirstChildOfClass("Humanoid") then return deny("Character destination rejected") end
   local height=math.max(3,hum.HipHeight+root.Size.Y/2)
   local destination=hit.Position+Vector3.new(0,height+0.15,0)
   local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Exclude;overlap.FilterDescendantsInstances={char}
   for _,part in ipairs(workspace:GetPartBoundsInBox(CFrame.new(destination),Vector3.new(3,5,3),overlap)) do
    if part.CanCollide then return deny("Landing area obstructed") end
   end
   teleports[player]=now
   char:PivotTo(char:GetPivot()+(destination-root.Position));root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
   return {ok=true,position=root.Position,message="Owned Studio server moved the character"}
  end
  return deny("Unknown action")
 end
 scope:add(function() request.OnServerInvoke=nil end)
 scope:connect(control.OnServerEvent,function(player,action,direction,look)
  if action=="release" then stop(player,"Client release");return end
  local s=states[player];if not s or action~="control" then return end
  if not Policy.control(direction,look) then stop(player,"Invalid input");return end
  local now=os.clock();if now-s.lastInput<1/40 then return end
  s.lastInput=now;s.deadline=now+1.5;s.direction=Vector3.new(direction[1],direction[2],direction[3]);s.look=Vector3.new(look[1],0,look[3]).Unit
 end)
 scope:connect(Run.Heartbeat,function(dt)
  for player,s in pairs(states) do
   if os.clock()>s.deadline then stop(player,"Input timeout")
   elseif not alive(player) then stop(player,"Character unavailable")
   elseif s.fly then
    s.velocity=s.velocity:Lerp(s.direction*s.speed,1-math.exp(-math.min(dt,0.1)*10))
    s.linear.VectorVelocity=s.velocity;s.orientation.CFrame=CFrame.lookAt(Vector3.zero,s.look)
   end
  end
 end)
 scope:connect(game.Players.PlayerRemoving,function(player) stop(player,"Player left");requests[player]=nil;teleports[player]=nil end)
 function api.close() for player in pairs(states) do stop(player,"Server fixture stopped") end;scope:close() end
 folder.Parent=storage
 return api
end
