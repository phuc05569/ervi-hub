-- Fixed destination and coordinate formatting; legacy CFrame serialization utilities.
local SafeZone = {}
SafeZone.PLACE_ID = 119338513416973
function SafeZone.preset(place)
 if place ~= SafeZone.PLACE_ID then return nil end
 -- Established owner destinations, recovered from the active settings profile.
 -- Explicit place-scoped settings still take precedence; no runtime editor.
 return {place=place,components={350.647675,-435.796021,26.535965}}
end
function SafeZone.protectedPreset(place)
 if place~=SafeZone.PLACE_ID then return nil end
 return {place=place,components={296.613495,59.0999985,-100.878853}}
end
local function finite(n) return type(n)=="number" and n==n and math.abs(n)<math.huge end
function SafeZone.encode(place, components)
 if not finite(place) or place<=0 or place%1~=0 or #components~=12 then return nil end
 local out={tostring(place)}
 for i,n in ipairs(components) do
  if not finite(n) or math.abs(n)>(i<=3 and 1e7 or 1.001) then return nil end
  table.insert(out,("%.9g"):format(n))
 end
 for r=0,2 do
  local norm=0
  for c=1,3 do norm+=components[3+r*3+c]^2 end
  if math.abs(norm-1)>0.01 then return nil end
  for other=0,r-1 do
   local dot=0
   for c=1,3 do dot+=components[3+r*3+c]*components[3+other*3+c] end
   if math.abs(dot)>0.01 then return nil end
  end
 end
 local c=components
 local determinant=c[4]*(c[8]*c[12]-c[9]*c[11])-c[5]*(c[7]*c[12]-c[9]*c[10])+c[6]*(c[7]*c[11]-c[8]*c[10])
 if math.abs(determinant-1)>0.01 then return nil end
 return table.concat(out,",")
end
function SafeZone.decode(text, place)
 if type(text)~="string" or #text>300 then return nil end
 local nums={}
 for part in (text..","):gmatch("(.-),") do
  local n=tonumber(part); if not finite(n) then return nil end
  table.insert(nums,n)
 end
 if #nums~=13 then return nil end
 local savedPlace=table.remove(nums,1)
 if not SafeZone.encode(savedPlace,nums) or (place and savedPlace~=place) then return nil end
 return {place=savedPlace,components=nums}
end
function SafeZone.describe(saved, position)
 if not saved then return "No safe zone saved for this place" end
 local c=saved.components
 local text=("X %.2f · Y %.2f · Z %.2f"):format(c[1],c[2],c[3])
 if position then
  local d=math.sqrt((position[1]-c[1])^2+(position[2]-c[2])^2+(position[3]-c[3])^2)
  text..=(" · %.1f studs away"):format(d)
 end
 return text
end
return SafeZone
