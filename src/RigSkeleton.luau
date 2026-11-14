-- Cached canonical body links. Motor6D endpoints follow the animated rig's
-- actual joint position. Accessories, root joints and non-body motors are excluded.
local Rig={}
local pairs6={{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}
local pairs15={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
local names={}
for _,list in ipairs({pairs6,pairs15}) do for _,pair in ipairs(list) do names[pair[1]]=true;names[pair[2]]=true end end
function Rig.build(character,bodyParts)
 local parts,links={},{}
 for _,part in ipairs(character:GetChildren()) do if names[part.Name] and part:IsA("BasePart") then parts[part.Name]=part end end
 local owned={}
 for _,part in ipairs(bodyParts or {}) do
  owned[part]=true
  if names[part.Name] and not parts[part.Name] then parts[part.Name]=part end
 end
 local linked={}
 for _,joint in ipairs(character:GetDescendants()) do
  if joint:IsA("Motor6D") then
   local a,b=joint.Part0,joint.Part1
   if a and b and #links<32 and ((parts[a.Name]==a and parts[b.Name]==b) or
    (owned[a] and owned[b] and a.Name~="HumanoidRootPart" and b.Name~="HumanoidRootPart")) then
    table.insert(links,{a=a,b=b,joint=joint});linked[a.Name.."/"..b.Name]=true;linked[b.Name.."/"..a.Name]=true
   end
  end
 end
 -- Incomplete/custom rigs still get a proportionate center-to-center fallback.
 for _,pair in ipairs(parts.UpperTorso and pairs15 or pairs6) do
  if #links>=32 then break end
  local a,b=parts[pair[1]],parts[pair[2]]
  if a and b and not linked[pair[1].."/"..pair[2]] then table.insert(links,{a=a,b=b}) end
 end
 return links
end
return Rig
