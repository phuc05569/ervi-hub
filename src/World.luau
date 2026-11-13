local Overrides=require("PropertyOverrides")
local Game=require("Game")
return function(hub,getPrefs)
 local Lighting=game:GetService("Lighting")
 local world={status="Ready"}
 local owned=Overrides.new();hub:add(owned)
 local blur
 function world.setBlur(on)
  if on and not blur and not hub.closed then blur=Instance.new("BlurEffect");blur.Name="ErviBackgroundBlur";blur.Size=14;blur.Parent=Lighting
  elseif not on and blur then blur:Destroy();blur=nil end
 end
 hub:add(function() world.setBlur(false) end)
 local function option(key,on,object,property,value)
  local ok,err=pcall(function() if on then owned:set(key,object,property,value) else owned:clear(key) end end)
  if not ok then world.status=property.." unavailable: "..tostring(err) end
 end
 function world.resetCamera()
  local cam=workspace.CurrentCamera;local h=Game.humanoid()
  if cam and h then cam.CameraType=Enum.CameraType.Custom;cam.CameraSubject=h;world.status="Camera reset to your character"
  else world.status="Wait for character/camera" end
 end
 function world.apply()
  local p=getPrefs()
  option("bright",p.fullbright,Lighting,"Brightness",2)
  option("ambient",p.fullbright,Lighting,"Ambient",Color3.new(1,1,1))
  option("outdoor",p.fullbright,Lighting,"OutdoorAmbient",Color3.new(1,1,1))
  option("fogStart",p.noFog,Lighting,"FogStart",1000000);option("fogEnd",p.noFog,Lighting,"FogEnd",1000000)
  option("shadows",p.noShadows,Lighting,"GlobalShadows",false);option("time",p.customTime,Lighting,"ClockTime",p.timeOfDay%24)
  local atmos=Lighting:FindFirstChildOfClass("Atmosphere")
  if atmos then option("density",p.noFog,atmos,"Density",0);option("haze",p.noFog,atmos,"Haze",0)
  else owned:clear("density");owned:clear("haze") end
 end
 hub:connect(Lighting.ChildAdded,function(child) if child:IsA("Atmosphere") and getPrefs().noFog then world.apply() end end)
 return world
end
