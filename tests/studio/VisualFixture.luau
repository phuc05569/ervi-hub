-- Run only through Studio MCP in the user's unpublished test place.
assert(game:GetService("RunService"):IsStudio() and game.PlaceId==0 and game.GameId==0)
local modules=game.Players.LocalPlayer.PlayerScripts.ErviUIHarness
local Scope=require(modules.Scope)
if _G.ERVI_VISUAL_QA then _G.ERVI_VISUAL_QA.close() end
local scope=Scope.new("owned-visual-fixture")
local folder=workspace:FindFirstChild("ErviVisualTest")
assert(folder and folder:GetAttribute("ErviOwnedFixture") and folder:GetAttribute("Ready"))
local added,removed=scope:add(Instance.new("BindableEvent")),scope:add(Instance.new("BindableEvent"))
local source={PlayerAdded=added.Event,PlayerRemoving=removed.Event,list={}}
function source:GetPlayers() return self.list end
for i,model in ipairs(folder:GetChildren()) do
 local ca,cr=scope:add(Instance.new("BindableEvent")),scope:add(Instance.new("BindableEvent"))
 table.insert(source.list,{Name=model.Name,DisplayName=model.Name,UserId=-i,Neutral=true,Character=model,CharacterAdded=ca.Event,CharacterRemoving=cr.Event,added=ca,removing=cr})
end
local prefs=require(modules.Settings).defaults()
prefs.espEnabled=true;prefs.skeleton=true;prefs.boxStyle="None";prefs.healthBar=false;prefs.teamCheck=false;prefs.espTextSize=12;prefs.updateRate="Auto"
local camera=workspace.CurrentCamera;local previousType,previousCF=camera.CameraType,camera.CFrame
camera.CameraType=Enum.CameraType.Scriptable;camera.CFrame=CFrame.lookAt(Vector3.new(0,11,35),Vector3.new(0,3,0))
scope:add(function() camera.CameraType=previousType;camera.CFrame=previousCF end)
local gui=game.Players.LocalPlayer.PlayerGui:FindFirstChild("RNG_RollAttacks_Hub")
if gui then gui.Enabled=false;scope:add(function() gui.Enabled=true end) end
local pivots={};for _,p in ipairs(source.list) do pivots[p]=p.Character:GetPivot() end
local t=0
scope:connect(game:GetService("RunService").PreSimulation,function(dt)
 t+=dt
 for _,p in ipairs(source.list) do
  if p.Character and p.Character.Parent then
   p.Character:PivotTo(pivots[p]*CFrame.new(math.sin(t)*0.75,0,0))
   for _,joint in ipairs(p.Character:GetDescendants()) do if joint:IsA("Motor6D") and joint.Name~="RootJoint" and joint.Name~="Root" then joint.Transform=CFrame.Angles(math.sin(t*2)*0.15,0,0) end end
  end
 end
end)
local api={prefs=prefs,source=source,results={}}
local renderer
function api.mode(name)
 if renderer then renderer.stop();renderer=nil end
 if name=="off" then return end
 renderer=require(name=="baseline" and modules.ErviBenchBaseline or modules.Visuals)(scope,game.Players.LocalPlayer.PlayerGui,function() return prefs end,source)
 renderer.apply();api.renderer=renderer
end
function api.measure(name)
 api.mode(name)
 task.spawn(function()
  task.wait(0.5)
  local frames={};local connection=game:GetService("RunService").RenderStepped:Connect(function(dt) table.insert(frames,dt*1000) end)
  task.wait(5);connection:Disconnect();table.sort(frames)
  local total=0;for _,v in ipairs(frames) do total+=v end
  local r=renderer
  api.results[name]={samples=#frames,meanFrameMs=total/math.max(1,#frames),p95FrameMs=frames[math.max(1,math.ceil(#frames*0.95))],drawn=r and r.drawn or 0,projections=r and r.projections or 0,rays=r and r.rays or 0,effectiveRate=r and r.effectiveRate or 0,updates=r and r.updates or nil,totalUpdateMs=r and r.totalMs or nil,maxUpdateMs=r and r.maxMs or nil,status=r and r.status or "disabled"}
 end)
end
function api.close() if renderer then renderer.stop() end;scope:close();_G.ERVI_VISUAL_QA=nil end
_G.ERVI_VISUAL_QA=api
api.measure("off")
return {started=true,rigs=#source.list}
