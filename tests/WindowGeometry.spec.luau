local Geometry=require("WindowGeometry")
return {
 {"main window scale preserves centered anchor and usable viewport bounds",function(check,eq)
  for _,scale in ipairs({0.5,0.75,1,1.25,1.5}) do
   local x,y=Geometry.mainAnchor(880,580,scale,1920,1022,0.5,0.5)
   eq(x,0.5);eq(y,0.5)
   local ax,ay=Geometry.mainAnchor(880,580,scale,1920,1022,0,1)
   check(ax*1920>=880*scale/2 and ay*1022+580*scale/2<=1022)
  end
 end},
 {"fits a persisted HUD inside a smaller viewport",function(check)
  local r=Geometry.fit({w=800,h=600,x=1,y=1},320,240)
  check(r.x>=0 and r.y>=0 and r.x+r.w<=r.vw and r.y+r.h<=r.vh)
 end},
 {"drag cannot leave the screen",function(_,eq)
  local r=Geometry.fit({w=330,h=180,x=0.5,y=0.5},1920,1080)
  Geometry.move(r,-10000,10000); eq(r.x,0); eq(r.y+r.h,r.vh)
 end},
 {"normalized layout round trips without drift",function(check)
  local r=Geometry.fit({w=500,h=260,x=0.12345,y=0.98765},1920,1080)
  local copy=Geometry.fit(Geometry.saved(r),1920,1080)
  check(math.abs(r.x-copy.x)<0.001 and math.abs(r.y-copy.y)<0.001)
 end},
 {"minimum dimensions prevent overlapping content",function(_,eq)
  local r=Geometry.fit({w=1,h=1,x=0,y=0},1920,1080); eq(r.w,260); eq(r.h,160)
 end},
 {"tiny viewport has no negative dimensions or positions",function(check)
  local r=Geometry.fit({w=330,h=180,x=1,y=1},10,10)
  check(r.w>0 and r.h>0 and r.x==0 and r.y==0)
 end},
}
