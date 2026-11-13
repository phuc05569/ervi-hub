-- Original native-UI mannequin; no third-party character art or asset downloads.
local Ui=require("Ui")
local Theme=require("Theme")
local TextStyle=require("VisualTextStyle")
local Stroke=require("SkeletonStroke")
return function(parent)
 local frame=Ui.card(parent,"Visualization preview",0,"Native sample · Visibility Mode filters live targets")
 local canvas=Ui.new("Frame",{Size=UDim2.new(1,0,0,270),BackgroundColor3=Color3.fromRGB(21,25,35),LayoutOrder=1,Parent=frame})
 canvas:SetAttribute("FixedBackground",true);Ui.corner(canvas,10)
 local center=Ui.new("Frame",{Size=UDim2.fromOffset(150,210),Position=UDim2.new(0.5,-75,0,26),BackgroundTransparency=1,Parent=canvas})
 local function block(name,x,y,w,h,tint)
  local obj=Ui.new("Frame",{Name=name,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundColor3=tint,BorderSizePixel=0,Parent=center})
  obj:SetAttribute("FixedBackground",true);Ui.corner(obj,4);return obj
 end
 local skin=Color3.fromRGB(231,208,188);local cloth=Color3.fromRGB(66,77,101)
 block("Head",59,20,32,32,skin);block("Torso",48,56,54,65,cloth)
 block("LeftArm",22,56,22,65,skin);block("RightArm",106,56,22,65,skin)
 block("LeftLeg",48,125,24,65,cloth);block("RightLeg",78,125,24,65,cloth)
 local box=Ui.new("Frame",{Position=UDim2.fromOffset(18,16),Size=UDim2.fromOffset(114,180),BackgroundTransparency=1,Parent=center})
 local boxStroke=Ui.stroke(box,Theme.accent,0)
 local corners={}
 for _,p in ipairs({{18,16,25,2},{18,16,2,25},{107,16,25,2},{130,16,2,25},{18,194,25,2},{18,171,2,25},{107,194,25,2},{130,171,2,25}}) do table.insert(corners,block("Corner",p[1],p[2],p[3],p[4],Theme.accent)) end
 local health=block("Health",12,54,3,142,Theme.good)
 local head=block("HeadDot",72,33,6,6,Theme.accent)
 local bones={};local outlines={};local boneRects={}
 for _,p in ipairs({{74,36,2,148},{32,66,86,2},{32,66,2,45},{116,66,2,45},{59,123,2,61},{89,123,2,61},{59,122,32,2}}) do
  local o=block("BoneOutline",p[1]-1,p[2]-1,p[3]+2,p[4]+2,Color3.new(0,0,0));o.ZIndex=1
  local b=block("Bone",p[1],p[2],p[3],p[4],Color3.new(1,1,1));b.ZIndex=2
  table.insert(outlines,o);table.insert(bones,b);table.insert(boneRects,p)
 end
 local name=Ui.text(canvas,"Sample player",{size=UDim2.new(1,0,0,22),textSize=12,align=Enum.TextXAlignment.Center})
 local distance=Ui.text(canvas,"58 studs",{size=UDim2.new(1,0,0,22),textSize=11,align=Enum.TextXAlignment.Center});distance.Position=UDim2.new(0,0,1,-25)
 local tracer=Ui.new("Frame",{Position=UDim2.new(0.5,0,0,0),Size=UDim2.fromOffset(1,40),BorderSizePixel=0,Parent=canvas})
 local arrow=Ui.text(canvas,"▲",{size=UDim2.fromOffset(20,20),textSize=20});arrow.Position=UDim2.new(1,-24,0.5,0)
 local fill=Ui.new("Frame",{Position=UDim2.fromOffset(48,56),Size=UDim2.fromOffset(54,65),BorderSizePixel=0,Parent=center})
 fill:SetAttribute("FixedBackground",true)
 local fillStroke=Ui.stroke(fill,Theme.accent,0)
 local state=Ui.text(frame,"",{order=2,textSize=Theme.size.tiny,color=Theme.muted})
 return {frame=frame,render=function(p,status)
  local tint=Color3.fromHex(p.enemyColor:sub(2))
  local visible=true
  box.Visible=visible and p.boxStyle=="Box";boxStroke.Color=tint
  for _,c in ipairs(corners) do c.Visible=visible and p.boxStyle=="Corners";c.BackgroundColor3=tint end
  health.Visible=p.healthBar and visible;head.Visible=p.headDot and visible;head.BackgroundColor3=tint
  for i,b in ipairs(bones) do
   local coreW,coreT,outlineW,outlineT=Stroke.resolve(p.skeletonThickness)
   local rect=boneRects[i];local w=rect[3]<=2 and coreW or rect[3];local h=rect[4]<=2 and coreW or rect[4]
   local ow=rect[3]<=2 and outlineW or rect[3]+2;local oh=rect[4]<=2 and outlineW or rect[4]+2
   b.Size=UDim2.fromOffset(w,h);b.BackgroundTransparency=coreT;outlines[i].Size=UDim2.fromOffset(ow,oh);outlines[i].BackgroundTransparency=outlineT
   b.Position=UDim2.fromOffset(rect[1]+(rect[3]<=2 and (rect[3]-w)/2 or 0),rect[2]+(rect[4]<=2 and (rect[4]-h)/2 or 0))
   outlines[i].Position=UDim2.fromOffset(rect[1]+(rect[3]<=2 and (rect[3]-ow)/2 or -1),rect[2]+(rect[4]<=2 and (rect[4]-oh)/2 or -1))
   b.Visible=p.skeleton and visible;b.BackgroundColor3=Color3.new(1,1,1);outlines[i].Visible=b.Visible
  end
  TextStyle.apply(name,Color3.new(1,1,1),Color3.new(0,0,0));TextStyle.apply(distance,Color3.new(1,1,1),Color3.new(0,0,0))
  name.Visible=p.espNames;name.TextSize=p.espTextSize;name.Text="Sample player"
  distance.Visible=p.espDistance;distance.TextSize=p.espTextSize
  center.Position=UDim2.new(0.5,-75,0,26+p.verticalOffset)
  fill.Visible=p.chams and visible;fill.BackgroundColor3=p.enemyColor=="#F0628E" and Color3.new(1,1,1) or tint;fill.BackgroundTransparency=p.chamsFill
  boxStroke.Transparency=0;fillStroke.Color=tint;fillStroke.Transparency=p.chamsOutline
  tracer.Visible=p.tracers and visible;tracer.BackgroundColor3=Color3.fromHex(p.tracerColor:sub(2))
  tracer.Position=UDim2.new(0.5,0,p.tracerOrigin=="Top" and 0 or p.tracerOrigin=="Middle" and 0.5 or 1,p.tracerOrigin=="Bottom" and -40 or 0)
  arrow.Visible=p.offscreenArrows;arrow.TextColor3=tint
  state.Text=(p.espEnabled and "ON requested" or "OFF").." · "..status
 end}
end
