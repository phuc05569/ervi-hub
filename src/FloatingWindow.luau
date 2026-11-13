-- Shared contract for floating HUDs: themed, menu-controlled, clamped, persistent,
-- draggable title + corner resize; scroll content instead of clipping large fonts.
local Ui = require("Ui")
local Theme = require("Theme")
local Geometry = require("WindowGeometry")
local Scope = require("Scope")
local Input = game:GetService("UserInputService")
return function(scope, parent, name, getSaved, persist)
 local gui=scope:add(Ui.new("ScreenGui", {Name=name,ResetOnSpawn=false,DisplayOrder=301,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Parent=parent}))
 Ui.root(gui)
 local frame=Ui.new("Frame",{BackgroundColor3=Theme.surface,ClipsDescendants=true,Parent=gui})
 Ui.surface(frame); Ui.corner(frame,Theme.radius); Ui.stroke(frame,Theme.stroke,0.2)
 local title=Ui.text(frame,"M1",{size=UDim2.new(1,-24,0,34),font=Theme.fontBold})
 title.Position=UDim2.fromOffset(12,4); title.Active=true
 title.TextWrapped=false; title.TextTruncate=Enum.TextTruncate.AtEnd
 local body=Ui.scroll(frame,{Size=UDim2.new(1,-24,1,-62),Position=UDim2.fromOffset(12,40)})
 Ui.list(body,6)
 local grip=Ui.new("TextButton",{Text="◢",TextSize=18,Font=Theme.font,TextColor3=Theme.faint,BackgroundTransparency=1,AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-3,1,-3),Size=UDim2.fromOffset(20,20),Parent=frame})
 grip:SetAttribute("ResizeGrip",true)
 local rect, dragging, resizing, pointer, original
 local cameraScope
 local function draw()
  frame.Size=UDim2.fromOffset(rect.w,rect.h); frame.Position=UDim2.fromOffset(rect.x,rect.y)
 end
 local function viewport()
  local cam=workspace.CurrentCamera
  local size=cam and cam.ViewportSize
  return size and size.X or 800,size and size.Y or 600
 end
 local function refresh()
  dragging,resizing=false,false
  local vw,vh=viewport(); rect=Geometry.fit(getSaved(),vw,vh); draw()
 end
 local function commit() persist(Geometry.saved(rect)) end
 local function press(t) return t==Enum.UserInputType.MouseButton1 or t==Enum.UserInputType.Touch end
 scope:connect(title.InputBegan,function(input)
  if press(input.UserInputType) then dragging=true; pointer=input.Position; original=table.clone(rect) end
 end)
 scope:connect(grip.InputBegan,function(input)
  if press(input.UserInputType) then resizing=true; dragging=false; pointer=input.Position; original=table.clone(rect) end
 end)
 scope:connect(Input.InputChanged,function(input)
  if not dragging and not resizing then return end
  if input.UserInputType~=Enum.UserInputType.MouseMovement and input.UserInputType~=Enum.UserInputType.Touch then return end
  local dx,dy=input.Position.X-pointer.X,input.Position.Y-pointer.Y
  if dragging then Geometry.move(rect,original.x+dx,original.y+dy)
  else
   local vw,vh=viewport()
   rect=Geometry.fit({x=0,y=0,w=original.w+dx,h=original.h+dy},vw,vh)
   Geometry.move(rect,original.x,original.y)
  end
  draw()
 end)
 scope:connect(Input.InputEnded,function(input)
  if press(input.UserInputType) and (dragging or resizing) then dragging=false; resizing=false; commit() end
 end)
 local function bindCamera()
  dragging,resizing=false,false
  if cameraScope then cameraScope:close() end
  cameraScope=Scope.new("floating-camera")
  if workspace.CurrentCamera then cameraScope:connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"),function() refresh() end) end
  refresh()
 end
 scope:connect(workspace:GetPropertyChangedSignal("CurrentCamera"),bindCamera)
 scope:add(function() if cameraScope then cameraScope:close() end end)
 bindCamera()
 return {gui=gui,frame=frame,title=title,body=body,refresh=refresh}
end
