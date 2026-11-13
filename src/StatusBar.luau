-- Compact fixed-height status pill: intrinsic chip layout replaces a resize handle.
-- It stays independent of main-window visibility and never disables features.
local Ui=require("Ui")
local Theme=require("Theme")
local Logo=require("Logo")
local Input=game:GetService("UserInputService")
local Run=game:GetService("RunService")
return function(hub,parent,getPrefs,save,restore,navigate,getState)
 local gui=hub:add(Ui.new("ScreenGui",{Name="Ervi_MinimizedStatus",IgnoreGuiInset=true,ResetOnSpawn=false,DisplayOrder=401,Enabled=false,Parent=parent}))
 Ui.root(gui)
 local frame=Ui.new("TextButton",{Name="ErviStatusPill",Text="",BackgroundColor3=Theme.surface,BackgroundTransparency=1-getPrefs().statusOpacity,AutoButtonColor=false,ClipsDescendants=true,Parent=gui})
 Ui.corner(frame,20);Ui.stroke(frame,Theme.stroke,0.25)
 local mark=Logo.create(frame,UDim2.fromOffset(18,20));mark.Position=UDim2.fromOffset(8,9)
 local light=Ui.new("Frame",{Position=UDim2.fromOffset(32,16),Size=UDim2.fromOffset(6,6),BackgroundColor3=Theme.good,BorderSizePixel=0,Parent=frame});Ui.corner(light,3)
 local stats=Ui.text(frame,"",{size=UDim2.fromOffset(132,34),textSize=10,font=Theme.mono,align=Enum.TextXAlignment.Right})
 stats.AnchorPoint=Vector2.new(1,0);stats.Position=UDim2.new(1,-23,0,2)
 Ui.text(frame,"↗",{size=UDim2.fromOffset(18,38),align=Enum.TextXAlignment.Center,textSize=14}).Position=UDim2.new(1,-20,0,0)
 local chipButtons={};local chipTargets={}
 for i=1,3 do
  local index=i
  chipButtons[i]=Ui.button(hub,frame,"",{width=62,height=26,textSize=9},function() restore();navigate(chipTargets[index] or "dash") end)
  chipButtons[i].TextTruncate=Enum.TextTruncate.AtEnd;chipButtons[i].TextWrapped=false
  chipButtons[i].Position=UDim2.fromOffset(44+(i-1)*66,6)
 end
 local rect={};local dragging,pointer,start,travel;local lastDrag=-math.huge
 local function layout()
  local cam=workspace.CurrentCamera;local vp=cam and cam.ViewportSize or Vector2.new(1280,720)
  rect.w=math.max(80,math.min(420,vp.X-16));rect.h=math.min(38,vp.Y)
  rect.maxX=math.max(0,vp.X-rect.w);rect.maxY=math.max(0,vp.Y-rect.h)
  if not dragging then rect.x=rect.maxX*getPrefs().statusX;rect.y=rect.maxY*getPrefs().statusY end
  frame.Size=UDim2.fromOffset(rect.w,rect.h);frame.Position=UDim2.fromOffset(rect.x,rect.y)
 end
 local function update()
  layout()
  frame.BackgroundTransparency=1-math.clamp(getPrefs().statusOpacity or 0.7,0,1)
  local state=getState();local entries=state.features
  local capacity=math.clamp(math.floor((rect.w-206)/66),0,3)
  for i,button in ipairs(chipButtons) do
   button.Visible=i<=capacity and i<=#entries
   if button.Visible then
    local overflow=#entries>capacity and i==capacity
    local label=overflow and ("+"..(#entries-capacity+1)) or entries[i].label
    if button.Text~=Ui.localeText(label) then
     Ui.set(button,"Text",label);button.TextTransparency=0.65
     Ui.animate(button,{TextTransparency=Ui.textAlpha},0.16)
    end
    chipTargets[i]=overflow and "dash" or entries[i].page
   end
  end
  stats.Size=UDim2.fromOffset(math.min(132,math.max(50,rect.w-54)),34)
  Ui.set(stats,"Text",("%d FPS · %d ms\nRoll: %s"):format(state.fps,state.ping,state.rollState))
  frame:SetAttribute("AutoRollState",state.rollState)
 end
 hub:connect(frame.InputBegan,function(input)
  if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
   dragging=true;pointer=input.Position;start={x=rect.x,y=rect.y};travel=0
  end
 end)
 hub:connect(Input.InputChanged,function(input)
  if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
   local dx,dy=input.Position.X-pointer.X,input.Position.Y-pointer.Y;travel=math.abs(dx)+math.abs(dy)
   rect.x=math.clamp(start.x+dx,0,rect.maxX);rect.y=math.clamp(start.y+dy,0,rect.maxY)
   frame.Position=UDim2.fromOffset(rect.x,rect.y)
  end
 end)
 hub:connect(Input.InputEnded,function(input)
  if dragging and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then
   dragging=false
   if travel>3 then lastDrag=os.clock();local p=getPrefs();p.statusX=rect.maxX>0 and rect.x/rect.maxX or 0;p.statusY=rect.maxY>0 and rect.y/rect.maxY or 0;save() end
  end
 end)
 hub:connect(frame.Activated,function() if os.clock()-lastDrag>0.2 then restore() end end)
 local elapsed=0
 hub:connect(Run.Heartbeat,function(dt)
  if not gui.Enabled then return end
  elapsed+=dt;if elapsed>=0.25 then elapsed=0;update() end
 end)
 hub:connect(frame.MouseEnter,function() Ui.animate(frame,{BackgroundColor3=Theme.raised}) end)
 hub:connect(frame.MouseLeave,function() Ui.animate(frame,{BackgroundColor3=Theme.surface}) end)
 local scale=Ui.new("UIScale",{Parent=frame})
 hub:add(function() Ui.cancelAnimation(frame);Ui.cancelAnimation(scale) end)
 update()
 return {gui=gui,frame=frame,show=function(on)
  gui.Enabled=on
  if on then update();scale.Scale=0.96;Ui.animate(scale,{Scale=1},0.22) end
 end,refresh=update}
end
