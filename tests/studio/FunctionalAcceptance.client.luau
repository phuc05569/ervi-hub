-- Owned, unpublished fixture only. Does not read/write executor settings.
assert(game:GetService("RunService"):IsStudio() and game.PlaceId==0 and game.GameId==0)
local modules=game.Players.LocalPlayer.PlayerScripts.ErviUIHarness
local Scope=require(modules.Scope)
local Settings=require(modules.Settings)
local P=require(modules.PositionData)
local player=game.Players.LocalPlayer
local stop=player.PlayerGui:FindFirstChild("ErviHubStopSignal")
if stop then stop:Invoke() end
local scope=Scope.new("functional-acceptance")
local prefs=Settings.defaults()
local results={environment="owned unpublished Studio client",build=require(modules.Build).id,checks={}}
_G.ERVI_FUNCTIONAL_QA=results
task.spawn(function()
 local char=player.Character;local root=char:WaitForChild("HumanoidRootPart");local hum=char:WaitForChild("Humanoid")
 local origin=char:GetPivot();local health=hum.Health
 local function check(condition,name,detail)
  table.insert(results.checks,{name=name,passed=condition==true,detail=detail})
  assert(condition,name)
 end
 local ok,err=xpcall(function()
  local speed=require(modules.PlayerTools)(scope,player.PlayerGui,function() return prefs end,function() end)
  local original=hum.WalkSpeed;prefs.walkEnabled=true
  for _,value in ipairs({16,25,50,100}) do prefs.walkSpeed=value;speed.apply();check(hum.WalkSpeed==value,"Set speed "..value) end
  prefs.speedMode="Multiply";prefs.speedMultiplier=1.5;speed.apply();check(hum.WalkSpeed==original*1.5,"Multiply uses original base")
  hum.WalkSpeed=23;task.wait(.1);check(not prefs.walkEnabled and not speed.walkActive and hum.WalkSpeed==23,"External speed change releases ownership and enabled state")
  local flight=require(modules.LocalFlight)(scope,function() return prefs end,function() end)
  local platform,rotate=hum.PlatformStand,hum.AutoRotate
  prefs.flyEnabled=true;flight.apply();task.wait(.25)
  check(flight.flying and root:FindFirstChild("ErviFlightVelocity")~=nil,"Native LinearVelocity flight activates")
  prefs.noclipEnabled=true;flight.apply()
  local collision=true;for _,node in ipairs(char:GetDescendants()) do if node:IsA("BasePart") and node.CanCollide then collision=false end end
  check(collision,"Native Noclip sets local character collision")
  flight.stop();task.wait(.1)
  check(root:FindFirstChild("ErviFlightVelocity")==nil and hum.PlatformStand==platform and hum.AutoRotate==rotate,"Native flight restores owned properties")
  local transport=require(modules.MovementTransport)(scope,nil)
  local destination=root.Position+Vector3.new(8,0,0)
  results.nativeMove={target={destination.X,destination.Y,destination.Z},samples={}}
  local elapsed,last=0,0
  local trace=scope:connect(game:GetService("RunService").Heartbeat,function(dt)
   elapsed+=dt
   if elapsed-last>=.05 and #results.nativeMove.samples<24 then
    last=elapsed;table.insert(results.nativeMove.samples,{time=elapsed,distance=(root.Position-destination).Magnitude,state=hum:GetState().Name,position={root.Position.X,root.Position.Y,root.Position.Z}})
   end
  end)
  check(transport.move(destination,50),"Native MoveTo request accepted locally")
  check(not transport.move(destination,50),"Duplicate native request excluded")
  task.wait(1)
  trace:Disconnect()
  check(not transport.busy and transport.status:find("observed locally",1,true)~=nil,"Native MoveTo locally observed",transport.status)
  local safe=require(modules.SafeZone)(scope,function() return prefs end,function() end)
  prefs.emergencyEnabled=true;hum.Health=20;safe.checkEmergency();check(safe.emergency.status=="Destination missing","Emergency refuses missing B")
  local target=root.Position+Vector3.new(8,0,0)
  safe.saveLocation("B",P.point(0,target.X,target.Y,target.Z));task.wait(1)
  check(safe.zone=="B" and safe.enabled,"Emergency B activates once after configuration",safe.status)
  local before=root.Position;hum.Health=10;safe.checkEmergency();task.wait(.1)
  check((root.Position-before).Magnitude<2,"Continued low health does not issue another move")
  safe.setEnabled(false);check((root.Position-before).Magnitude<2,"B off does not return to danger")
  prefs.emergencyEnabled=false;hum.Health=health
  local authority=require(modules.MovementAuthority)(scope)
  check(authority.available,"Owned server fixture available")
  safe.transport.setAuthority(authority)
  safe.select("B",true);task.wait(1)
  check(safe.enabled and safe.transport.outcome=="server-acknowledged","Saved B root coordinates adapt to owned-server ground protocol",safe.status)
  safe.setEnabled(false)
  local ui=require(modules.Ui)
  local notify=ui.notifications(scope,player.PlayerGui,function() return prefs end)
  notify("Studio acceptance notification")
  local ng=player.PlayerGui:FindFirstChild("Ervi_Notifications")
  check(ng and ng.Parent==player.PlayerGui,"Notification lives in independent viewport GUI")
  task.wait(1.4)
  check(ng:FindFirstChild("Notification",true)==nil,"One-second notification expires with cleanup")
 end,debug.traceback)
 results.passed=ok;if not ok then results.error=tostring(err) end
 prefs.emergencyEnabled=false
 scope:close()
 pcall(function() hum.Health=health;char:PivotTo(origin) end)
 results.cleanup={movers=root:FindFirstChild("ErviFlightVelocity")==nil,notifications=player.PlayerGui:FindFirstChild("Ervi_Notifications")==nil}
 results.completed=true
 print("ERVI_FUNCTIONAL_ACCEPTANCE "..game:GetService("HttpService"):JSONEncode(results))
end)
return "Functional acceptance started"
