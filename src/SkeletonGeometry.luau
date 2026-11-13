-- Liang-Barsky viewport clipping. Near-plane segments are hidden rather than
-- allowing mirrored projections to draw oversized lines across the screen.
local Geometry={}
local function finite(n) return type(n)=="number" and n==n and math.abs(n)<math.huge end
function Geometry.clip(a,b,width,height)
 for _,v in ipairs({a[1],a[2],a[3],b[1],b[2],b[3],width,height}) do if not finite(v) then return nil end end
 if a[3]<=0.05 or b[3]<=0.05 or width<=0 or height<=0 then return nil end
 local dx,dy=b[1]-a[1],b[2]-a[2];local lo,hi=0,1
 local function edge(p,q)
  if p==0 then return q>=0 end
  local t=q/p
  if p<0 then if t>hi then return false end;lo=math.max(lo,t)
  else if t<lo then return false end;hi=math.min(hi,t) end
  return true
 end
 if not (edge(-dx,a[1]) and edge(dx,width-a[1]) and edge(-dy,a[2]) and edge(dy,height-a[2])) then return nil end
 return {a[1]+lo*dx,a[2]+lo*dy},{a[1]+hi*dx,a[2]+hi*dy}
end
return Geometry
