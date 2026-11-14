-- Scoped physics hover, separate from the user's Fly controller. No anchoring,
-- CFrame maintenance, network ownership changes or server-acceptance claim.
-- https://create.roblox.com/docs/reference/engine/classes/AlignPosition
local Scope=require("Scope")
local Hover={}
function Hover.acquire(part,position)
 if not part.Parent or part.Anchored or (part.Position-position).Magnitude>6 then return nil,"Hover requires a nearby unanchored root" end
 local owner=Scope.new("zone-physics-hover")
 local ok,reason=pcall(function()
  local attachment=owner:add(Instance.new("Attachment"));attachment.Name="ErviZoneHoverAttachment";attachment.Parent=part
  local align=owner:add(Instance.new("AlignPosition"));align.Name="ErviZoneHover"
  align.Attachment0=attachment;align.Mode=Enum.PositionAlignmentMode.OneAttachment
  align.Position=position;align.ApplyAtCenterOfMass=true;align.RigidityEnabled=false
  align.ReactionForceEnabled=false;align.ForceLimitMode=Enum.ForceLimitMode.Magnitude
  align.MaxForce=math.clamp(part.AssemblyMass*(math.max(0,workspace.Gravity)*6+1200),1000,2000000)
  align.MaxVelocity=12;align.Responsiveness=12;align.Parent=part
  part.AssemblyLinearVelocity=Vector3.zero;part.AssemblyAngularVelocity=Vector3.zero
 end)
 if not ok then owner:close();return nil,tostring(reason) end
 return owner
end
return Hover
