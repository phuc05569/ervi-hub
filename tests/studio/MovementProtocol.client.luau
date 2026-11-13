assert(game:GetService("RunService"):IsStudio() and game.PlaceId==0 and game.GameId==0)
local folder=game.ReplicatedStorage:WaitForChild("ErviStudioAuthority")
assert(folder:GetAttribute("ErviOwnedFixture"))
task.spawn(function()
 local results={};local request=folder.Request;local control=folder.Control
 local ok,err=xpcall(function()
  control:FireServer("release");task.wait(0.25)
  local character=game.Players.LocalPlayer.Character;local root=character.HumanoidRootPart;local hum=character.Humanoid
  local originalPlatform,originalRotate=hum.PlatformStand,hum.AutoRotate
  local originalGroups={};for _,p in character:GetDescendants() do if p:IsA("BasePart") then originalGroups[p]=p.CollisionGroup end end
  local invalid=request:InvokeServer("set",{fly=true,noclip=true,speed=121})
  assert(not invalid.ok,"Excessive speed must be rejected");results.invalidSpeed=invalid
  task.wait(0.2)
  local floor=workspace.TestFloor;local point=Vector3.new(12,floor.Position.Y+floor.Size.Y/2,0)
  local teleport=request:InvokeServer("teleport",{position=point,range=100})
  assert(teleport.ok,"Owned server teleport must succeed: "..tostring(teleport.message));task.wait(0.4)
  assert((root.Position-teleport.position).Magnitude<0.5,"Server teleport must replicate")
  results.teleport={ack={teleport.position.X,teleport.position.Y,teleport.position.Z},replicated={root.Position.X,root.Position.Y,root.Position.Z}}
  task.wait(0.2)
  local enabled=request:InvokeServer("set",{fly=true,noclip=true,speed=50});assert(enabled.ok)
  for _=1,5 do control:FireServer("control",{0,0,0},{0,0,-1});task.wait(0.1) end
  assert(root:FindFirstChild("ErviFlightVelocity") and hum.PlatformStand,"Modern constraints must replicate")
  local badGroups=0;for p in pairs(originalGroups) do if p.CollisionGroup~="ErviStudioGhost" then badGroups+=1 end end
  assert(badGroups==0,"Independent collision group must replicate")
  results.enabled={modernConstraint=true,platform=hum.PlatformStand,ghostPartsVerified=true}
  task.wait(1.8)
  assert(not root:FindFirstChild("ErviFlightVelocity"),"Missing input must release constraints")
  assert(hum.PlatformStand==originalPlatform and hum.AutoRotate==originalRotate,"Timeout restores humanoid properties")
  for p,group in pairs(originalGroups) do assert(p.CollisionGroup==group,"Timeout restores original collision groups") end
  results.timeout={moversRemoved=true,platformRestored=true,rotationRestored=true,groupsRestored=true}
  task.wait(0.2)
  enabled=request:InvokeServer("set",{fly=true,noclip=true,speed=50});assert(enabled.ok)
  control:FireServer("control",{2,0,0},{0,0,-1});task.wait(0.3)
  assert(not root:FindFirstChild("ErviFlightVelocity"),"Malformed controls release the controller")
  results.invalidControl={controllerReleased=true}
 end,debug.traceback)
 control:FireServer("release")
 results.passed=ok;results.error=not ok and tostring(err) or nil
 folder:SetAttribute("ErviQaProtocolResults",game:GetService("HttpService"):JSONEncode(results))
end)
return "Owned protocol tests started"
