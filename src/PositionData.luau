-- Bounded, data-only storage; never evaluates coordinates or names as code.
local P={}
function P.name(name)
 return type(name)=="string" and #name>=1 and #name<=24 and not name:find("[^%w _%-]") and name or nil
end
function P.point(place,x,y,z)
 if type(place)~="number" or place<0 or place%1~=0 then return nil end
 for _,v in ipairs({x,y,z}) do if type(v)~="number" or v~=v or math.abs(v)>1e7 then return nil end end
 if x==nil or y==nil or z==nil then return nil end
 return {place=place,x=x,y=y,z=z}
end
function P.decode(text)
 local result={}
 if type(text)~="string" or #text>8192 then return result end
 local count=0
 for row in text:gmatch("[^;]+") do
  local name,place,x,y,z=row:match("^([%w _%-]+),([^,]+),([^,]+),([^,]+),([^,]+)$")
  local point=P.point(tonumber(place),tonumber(x),tonumber(y),tonumber(z))
  if not P.name(name) or not point or result[name] then return {} end
  count+=1;if count>64 then return {} end
  result[name]=point
 end
 return result
end
function P.encode(points)
 local keys={};for name in pairs(points) do table.insert(keys,name) end;table.sort(keys)
 if #keys>64 then return nil end
 local rows={}
 for _,name in ipairs(keys) do
  local p=points[name]
  if not P.name(name) or type(p)~="table" or not P.point(p.place,p.x,p.y,p.z) then return nil end
  table.insert(rows,("%s,%.0f,%.9g,%.9g,%.9g"):format(name,p.place,p.x,p.y,p.z))
 end
 return table.concat(rows,";")
end
function P.expression(p) return ("Vector3.new(%.9g, %.9g, %.9g)"):format(p.x,p.y,p.z) end
return P
