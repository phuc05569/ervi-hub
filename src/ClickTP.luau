-- A local targeting preview. No authorized movement adapter exists for this game.
local Scope=require("Scope")
local Game=require("Game")
local Target=require("ClickTarget")
local Motion=require("Motion")
local Input=game:GetService("UserInputService")
local Run=game:GetService("RunService")
return function(hub,parent,getPrefs,authority,moving)
 local feature={active=false,held=false,status="Off · targeting preview only",selected=nil,teleportAvailable=authority and authority.available==true}
 local scope,marker,lastCharacter,target,motion,boundKey
 local function hide()
  feature.held=false;target=nil
  if motion and marker then motion.cancel(marker) end
  if marker then marker.Parent=nil end
 end
 local function overGui(position)
  local ok,list=pcall(function()
   local inset=game:GetService("GuiService"):GetGuiInset()
   local guiPosition=position-inset
   return parent:GetGuiObjectsAtPosition(guiPosition.X,guiPosition.Y)
  end)
  if not ok then return true end -- refuse an unverified UI hit test
  for _,gui in ipairs(list) do
   if gui.Visible and (gui.Active or gui:IsA("GuiButton") or gui:IsA("TextBox")) then return true end
  end
  return false
 end
 function feature.stop()
  feature.active=false;hide();feature.selected=nil;feature.resultStatus=nil
  if scope then scope:close();scope=nil end
  marker=nil;lastCharacter=nil;boundKey=nil;feature.status="Off · targeting preview only"
 end
 function feature.apply()
  if not getPrefs().clickTPEnabled then feature.stop();return end
  if hub.closed then return end
  if feature.active then
   if boundKey~=getPrefs().clickTPKey then hide();boundKey=getPrefs().clickTPKey end
   return
  end
  boundKey=getPrefs().clickTPKey
  scope=Scope.new("click-target-preview")
  marker=scope:add(Instance.new("Part"));marker.Name="ErviClickTarget"
  marker.Shape=Enum.PartType.Cylinder;marker.Anchored=true;marker.CanCollide=false;marker.CanTouch=false;marker.CanQuery=false
  marker.Material=Enum.Material.Neon
  motion=Motion.new(function(node,duration,goal) return game:GetService("TweenService"):Create(node,TweenInfo.new(duration,Enum.EasingStyle.Linear),goal) end)
  scope:add(motion)
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.IgnoreWater=true
  local elapsed=0
  scope:connect(Run.Heartbeat,function(dt)
   if not feature.held then return end
   elapsed+=dt;if elapsed<1/30 then return end;elapsed=0
   if not Game.alive() or Input:GetFocusedTextBox() or (moving and moving()) then hide();return end
   local cam=workspace.CurrentCamera;if not cam then hide();return end
   local mouse=Input:GetMouseLocation()
   if overGui(mouse) then marker.Parent=nil;target=nil;return end
   if lastCharacter~=Game.player.Character then
    lastCharacter=Game.player.Character;params.FilterDescendantsInstances={lastCharacter,marker}
   end
   local ok,result=pcall(function()
    -- GetMouseLocation is raw viewport space. ScreenPointToRay would add the
    -- top-bar inset again and visibly shift the circle away from the pointer.
    local ray=cam:ViewportPointToRay(mouse.X,mouse.Y)
    return workspace:Raycast(ray.Origin,ray.Direction*getPrefs().clickTPRange,params)
   end)
   if not ok or not result then marker.Parent=nil;target=nil;feature.status="Aim at a valid world surface · preview only";return end
   local model=result.Instance:FindFirstAncestorOfClass("Model")
   if model and model:FindFirstChildOfClass("Humanoid") then marker.Parent=nil;target=nil;return end
   local pos,normal=result.Position,result.Normal
   if not Target.valid({pos.X,pos.Y,pos.Z},{normal.X,normal.Y,normal.Z},(pos-(Game.player.Character and Game.player.Character:FindFirstChild("HumanoidRootPart") and Game.player.Character.HumanoidRootPart.Position or cam.CFrame.Position)).Magnitude,getPrefs().clickTPRange) then marker.Parent=nil;target=nil;return end
   local p=getPrefs();target=pos
   marker.Size=Vector3.new(0.03,p.clickTPSize,p.clickTPSize)
   marker.Transparency=1-p.clickTPOpacity;marker.Color=Color3.fromHex(p.clickTPColor:sub(2))
   local tangent=math.abs(normal.Y)<0.99 and normal:Cross(Vector3.new(0,1,0)).Unit or Vector3.new(1,0,0)
   local destination=CFrame.fromMatrix(pos+normal*0.04,normal,tangent,normal:Cross(tangent))
   motion.configure(p.reduceAnimations,p.animationSpeed)
   if not marker.Parent then marker.CFrame=destination else motion.to(marker,{CFrame=destination},0.05) end
   marker.Parent=workspace
   feature.status=feature.teleportAvailable and (feature.resultStatus or "Owned Studio server ready · click to request teleport") or feature.selected and ("Selected preview (%.1f, %.1f, %.1f) · no server teleport"):format(feature.selected.X,feature.selected.Y,feature.selected.Z) or "Preview active · server teleport unavailable"
  end)
  scope:connect(Input.InputBegan,function(input,processed)
   if processed or input.UserInputType~=Enum.UserInputType.MouseButton1 or not feature.held or not target or Input:GetFocusedTextBox() then return end
   if overGui(Input:GetMouseLocation()) then return end
   feature.selected=target
   if feature.teleportAvailable then
    if moving and moving() then feature.status="Stop flight and noclip first";return end
    if authority.busy then feature.status="Server request pending";return end
    local selected=target;local owner=scope
    feature.resultStatus="Waiting for owned Studio server";feature.status=feature.resultStatus
    authority.request("teleport",{position=selected,range=getPrefs().clickTPRange},function(result)
     if not feature.active or scope~=owner then return end
     feature.resultStatus=result.ok and "Teleport confirmed by owned Studio server" or tostring(result.message or "Server rejected teleport");feature.status=feature.resultStatus
    end)
    return
   end
   feature.status=("Selected preview (%.1f, %.1f, %.1f); no server teleport performed"):format(target.X,target.Y,target.Z)
  end)
  scope:connect(Input.InputEnded,function(input) if input.KeyCode.Name==getPrefs().clickTPKey then hide() end end)
  scope:connect(Input.WindowFocusReleased,hide)
  scope:connect(Game.player.CharacterRemoving,function() hide();feature.selected=nil;feature.resultStatus=nil end)
  scope:connect(Game.player.CharacterAdded,function() hide();feature.selected=nil;feature.resultStatus=nil end)
  feature.active=true;feature.status=feature.teleportAvailable and "Owned Studio server ready · hold to aim" or "Preview ready · bind and hold a key; server teleport unavailable"
 end
 function feature.keyDown(input)
  if not feature.active or getPrefs().clickTPKey=="NONE" or input.KeyCode.Name~=getPrefs().clickTPKey or not Game.alive() then return false end
  feature.held=true;return true
 end
 function feature.snapshot()
  local point=feature.selected
  return {markerVisible=marker~=nil and marker.Parent==workspace,selected=point and {x=point.X,y=point.Y,z=point.Z} or nil}
 end
 hub:add(feature.stop)
 return feature
end
