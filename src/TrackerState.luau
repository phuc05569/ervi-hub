local State={}
local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
function State.sort(rows,mode)
 table.sort(rows,function(a,b)
  if mode=="Distance" then
   local ad=finite(a.distance) and a.distance or math.huge;local bd=finite(b.distance) and b.distance or math.huge
   if ad~=bd then return ad<bd end
  end
  local an,bn=string.lower(a.name),string.lower(b.name)
  if an~=bn then return an<bn end
  return a.id<b.id
 end)
end
function State.matches(row,query)
 local text=string.lower(row.name.." "..(row.display or ""))
 return text:find(string.lower(query or ""),1,true)~=nil
end
function State.health(health,maximum)
 if not finite(health) or not finite(maximum) or maximum<=0 then return {alive=false,fraction=0,text="Waiting for character"} end
 return {alive=health>0,fraction=math.clamp(health/maximum,0,1),text=health>0 and ("%.0f / %.0f HP"):format(health,maximum) or "Dead"}
end
return State
