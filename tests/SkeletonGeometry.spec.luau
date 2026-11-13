local Geometry=require("SkeletonGeometry")
return {
 {"clips projected limbs to the viewport",function(check,eq)
  local a,b=Geometry.clip({-50,50,2},{150,50,2},100,100)
  check(a and b);eq(a[1],0);eq(b[1],100);eq(a[2],50)
 end},
 {"rejects behind-camera, invalid and fully offscreen segments",function(check)
  for _,pair in ipairs({{{10,10,-2},{20,20,3}},{{10,10,0},{20,20,3}},{{0/0,2,2},{20,20,3}},{{150,50,2},{200,50,2}}}) do check(not Geometry.clip(pair[1],pair[2],100,100)) end
 end},
 {"preserves finite on-screen geometry and clips vertical edges",function(check,eq)
  local a,b=Geometry.clip({20,30,1},{40,60,1},100,100);eq(a[1],20);eq(b[2],60)
  a,b=Geometry.clip({40,-50,1},{40,150,1},100,100);check(a and b);eq(a[2],0);eq(b[2],100)
 end},
}
