local Target={}
function Target.valid(position,normal,distance,limit)
 if type(position)~="table" or type(normal)~="table" then return false end
 for _,values in ipairs({position,normal}) do
  for i=1,3 do local v=values[i];if type(v)~="number" or v~=v or math.abs(v)==math.huge then return false end end
 end
 return type(distance)=="number" and distance==distance and distance>=0 and distance<=math.clamp(type(limit)=="number" and limit==limit and limit or 500,10,500) and normal[2]>=0.3
end
return Target
