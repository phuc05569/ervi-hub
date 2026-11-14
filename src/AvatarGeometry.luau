-- Character-owned geometry only: never associates NPCs/world models by name.
-- Cached parts cover nested/replacement rigs without requiring a visible Head.
local Avatar={}
local body={Head=true,Torso=true,UpperTorso=true,LowerTorso=true,HumanoidRootPart=true,
 ["Left Arm"]=true,["Right Arm"]=true,["Left Leg"]=true,["Right Leg"]=true,
 LeftUpperArm=true,LeftLowerArm=true,LeftHand=true,RightUpperArm=true,RightLowerArm=true,RightHand=true,
 LeftUpperLeg=true,LeftLowerLeg=true,LeftFoot=true,RightUpperLeg=true,RightLowerLeg=true,RightFoot=true}
local function visible(part) return part and part.Parent and part.Transparency<1 and part.LocalTransparencyModifier<1 end
local function bodyPart(part,char)
 if not part:IsA("BasePart") then return false end
 local parent=part.Parent
 while parent and parent~=char do
  if parent:IsA("Accessory") or parent:IsA("Tool") or parent.Name=="SmearFX" or parent.Name=="VFX" then return false end
  parent=parent.Parent
 end
 return parent==char
end
function Avatar.inspect(c)
 local char=c.char
 c.hum=char:FindFirstChildOfClass("Humanoid") or char:FindFirstChildWhichIsA("Humanoid",true)
 c.root=char:FindFirstChild("HumanoidRootPart") or (c.hum and c.hum.RootPart) or char.PrimaryPart
 c.head=char:FindFirstChild("Head");c.parts={};c.custom=false;c.bounds=nil
 for _,part in ipairs(char:GetDescendants()) do
  if #c.parts<96 and bodyPart(part,char) then
   table.insert(c.parts,part)
   if not body[part.Name] or part.Parent~=char then c.custom=true end
   if not c.root and part.Name=="HumanoidRootPart" then c.root=part end
   if not c.head and part.Name=="Head" then c.head=part end
  end
 end
 c.root=c.root or c.parts[1]
 if c.root and (not c.root:IsA("BasePart") or not c.root:IsDescendantOf(char)) then c.root=nil end
 if c.head and not c.head:IsA("BasePart") then c.head=nil end
 if c.root then Avatar.sample(c) end
end
function Avatar.sample(c)
 if not c.root or not c.root.Parent then return end
 c.fallback=c.custom or not visible(c.head)
 if not c.fallback then c.bounds=nil;return end
 local lo,hi=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
 local base=c.root.CFrame
 for _,part in ipairs(c.parts) do
  -- Bound cosmetic geometry as well as work per avatar; giant effect parts
  -- must not turn a player's labels/box into a map-sized overlay.
  if visible(part) and (part.Position-c.root.Position).Magnitude<=128 and part.Size.Magnitude<=256 then
   local cf=base:ToObjectSpace(part.CFrame);local x,y,z,a,b,d,e,f,g,h,i,j=cf:GetComponents()
   local s=part.Size*0.5
   local extent=Vector3.new(math.abs(a)*s.X+math.abs(b)*s.Y+math.abs(d)*s.Z,math.abs(e)*s.X+math.abs(f)*s.Y+math.abs(g)*s.Z,math.abs(h)*s.X+math.abs(i)*s.Y+math.abs(j)*s.Z)
   local p=Vector3.new(x,y,z);lo=lo:Min(p-extent);hi=hi:Max(p+extent)
  end
 end
 c.bounds=lo.X<math.huge and {center=(lo+hi)*0.5,size=hi-lo} or nil
end
function Avatar.points(c)
 local root=c.root;if not root or not root.Parent then return nil end
 if not c.custom and visible(c.head) then return c.head.Position,root.Position-Vector3.new(0,3,0),c.head.Position,c.head.Position end
 local bounds=c.bounds
 if not bounds then return root.Position+Vector3.new(0,2.5,0),root.Position-Vector3.new(0,3,0),root.Position,root.Position+Vector3.new(0,2,0) end
 local cf=root.CFrame;local center=cf:PointToWorldSpace(bounds.center)
 local s=bounds.size*0.5
 local height=math.max(1,math.abs(cf.RightVector.Y)*s.X+math.abs(cf.UpVector.Y)*s.Y+math.abs(cf.LookVector.Y)*s.Z)
 local top=center+Vector3.new(0,height,0)
 return top,center-Vector3.new(0,height,0),center,visible(c.head) and c.head.Position or top
end
return Avatar
