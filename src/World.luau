local Overrides=require("PropertyOverrides")
local Scope=require("Scope")
local Game=require("Game")
return function(hub,getPrefs)
 local Lighting=game:GetService("Lighting")
 local Input=game:GetService("UserInputService")
 local Run=game:GetService("RunService")
 local world={status="Ready",freecamActive=false}
 local owned=Overrides.new(); hub:add(owned)
 local cameraScope,blur
 function world.setBlur(on)
  if on and not blur and not hub.closed then blur=Instance.new("BlurEffect");blur.Name="ErviBackgroundBlur";blur.Size=14;blur.Parent=Lighting
  elseif not on and blur then blur:Destroy();blur=nil end
 end
 hub:add(function() world.setBlur(false) end)
 local function option(key,on,object,property,value)
  local ok,err=pcall(function() if on then owned:set(key,object,property,value) else owned:clear(key) end end)
  if not ok then world.status=property.." unavailable: "..tostring(err) end
 end
 function world.stopCamera()
  world.freecamActive=false
  if cameraScope then cameraScope:close(); cameraScope=nil end
 end
 function world.startCamera()
  if world.freecamActive or hub.closed then return end
  local cam=workspace.CurrentCamera
  if not cam then world.status="Camera unavailable"; return end
  local scope=Scope.new("freecam"); cameraScope=scope
  local cameraOwned=Overrides.new(); scope:add(cameraOwned)
  local ok,err=pcall(function()
   local CAS=game:GetService("ContextActionService")
   local action="ErviFreecamMovement"
   CAS:BindActionAtPriority(action,function() return Enum.ContextActionResult.Sink end,false,3000,
    Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Q,Enum.KeyCode.E,Enum.KeyCode.Space)
   scope:add(function() CAS:UnbindAction(action) end)
   local original=cam.CFrame
   local position=original.Position
   local pitch,yaw=original:ToOrientation()
   local look=false
   cameraOwned:set("type",cam,"CameraType",Enum.CameraType.Scriptable)
   scope:connect(Input.InputBegan,function(input,processed)
    if not processed and not Input:GetFocusedTextBox() and input.UserInputType==Enum.UserInputType.MouseButton2 then
     look=true; cameraOwned:set("mouse",Input,"MouseBehavior",Enum.MouseBehavior.LockCurrentPosition)
    end
   end)
   scope:connect(Input.InputEnded,function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton2 then look=false; cameraOwned:clear("mouse") end
   end)
   scope:connect(Input.InputChanged,function(input)
    if look and input.UserInputType==Enum.UserInputType.MouseMovement then
     pitch=math.clamp(pitch-input.Delta.Y*0.003,-1.5,1.5); yaw-=input.Delta.X*0.003
    end
   end)
   scope:connect(Run.Heartbeat,function(dt)
    if not look or Input:GetFocusedTextBox() then return end
    local function down(key) return Input:IsKeyDown(Enum.KeyCode[key]) and 1 or 0 end
    local direction=Vector3.new(down("D")-down("A"),down("E")-down("Q"),down("S")-down("W"))
    local rotation=CFrame.fromOrientation(pitch,yaw,0)
    if direction.Magnitude>0 then position+=rotation:VectorToWorldSpace(direction.Unit)*math.min(dt,0.1)*60*getPrefs().freecamSpeed end
    cameraOwned:set("frame",cam,"CFrame",CFrame.new(position)*rotation)
   end)
  end)
  if not ok then scope:close(); cameraScope=nil; world.status="Freecam unavailable: "..tostring(err);getPrefs().freecam=false; return end
  world.freecamActive=true; world.status="Freecam: hold right mouse + WASD / Q E"
 end
 function world.resetCamera()
  world.stopCamera(); getPrefs().freecam=false
  local cam=workspace.CurrentCamera
  local h=Game.humanoid()
  if cam and h then cam.CameraType=Enum.CameraType.Custom; cam.CameraSubject=h; world.status="Camera reset to your character"
  else world.status="Wait for character/camera" end
 end
 function world.apply()
  local p=getPrefs()
  option("bright",p.fullbright,Lighting,"Brightness",2)
  option("ambient",p.fullbright,Lighting,"Ambient",Color3.new(1,1,1))
  option("outdoor",p.fullbright,Lighting,"OutdoorAmbient",Color3.new(1,1,1))
  option("fogStart",p.noFog,Lighting,"FogStart",1000000)
  option("fogEnd",p.noFog,Lighting,"FogEnd",1000000)
  option("shadows",p.noShadows,Lighting,"GlobalShadows",false)
  option("time",p.customTime,Lighting,"ClockTime",p.timeOfDay%24)
  local atmos=Lighting:FindFirstChildOfClass("Atmosphere")
  if atmos then option("density",p.noFog,atmos,"Density",0); option("haze",p.noFog,atmos,"Haze",0)
  else owned:clear("density"); owned:clear("haze") end
  if p.freecam then world.startCamera() else world.stopCamera() end
 end
 hub:connect(Lighting.ChildAdded,function(child) if child:IsA("Atmosphere") and getPrefs().noFog then world.apply() end end)
 hub:connect(workspace:GetPropertyChangedSignal("CurrentCamera"),function() world.stopCamera(); getPrefs().freecam=false end)
 hub:connect(Game.player.CharacterRemoving,function() world.stopCamera(); getPrefs().freecam=false end)
 hub:add(world.stopCamera)
 return world
end
