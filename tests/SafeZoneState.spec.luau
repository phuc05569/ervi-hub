local Safe=require("SafeZoneState")
local cf={10,20,30,0,0,1,0,1,0,-1,0,0}
return {
 {"preset exactly matches owner coordinates and is place scoped",function(_,eq)
  local p=Safe.preset(119338513416973); eq(p.components[1],278.78); eq(p.components[2],-16.3); eq(p.components[3],7.82); eq(Safe.preset(1),nil)
 end},
 {"position orientation and place survive serialization",function(_,eq)
  local s=Safe.decode(Safe.encode(119338513416973,cf),119338513416973)
  for i,v in ipairs(cf) do eq(s.components[i],v) end
 end},
 {"references cannot cross places",function(_,eq) eq(Safe.decode(Safe.encode(1,cf),2),nil) end},
 {"malformed references are rejected",function(_,eq)
  for _,s in ipairs({"","1,2,3","NaN","1,2,3,4,0,0,0,0,0,0,0,0,0",string.rep("x",301)}) do eq(Safe.decode(s),nil) end
 end},
 {"nonfinite coordinates are rejected",function(_,eq) local c=table.clone(cf); c[1]=math.huge; eq(Safe.encode(1,c),nil); c[1]=0/0; eq(Safe.encode(1,c),nil) end},
 {"saved coordinates can be replaced and distance is read only",function(check)
  local s=Safe.decode(Safe.encode(1,cf),1); check(Safe.describe(s,{10,20,40}):find("10.0 studs",1,true))
 end},
 {"missing reference has a useful status",function(check) check(Safe.describe(nil):find("No safe zone",1,true)) end},
}
