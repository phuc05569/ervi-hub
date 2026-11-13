local Target=require("TargetState")
local function c(id,h,max) return {id=id,name="Player"..id,health=h,maxHealth=max or 100} end
return {
 {"25 percent qualifies and 50 does not at threshold 30",function(_,eq) local s=Target.new(); s:update(true,true,true,30,{c(1,50),c(2,25)}); eq(s.id,2); eq(s.hp,25) end},
 {"threshold is strict and zero health is dead",function(_,eq) local s=Target.new(); s:update(true,true,true,30,{c(1,30),c(2,0)}); eq(s.id,nil) end},
 {"invalid max health and nonfinite values are ignored",function(_,eq) for _,v in ipairs({0,-1,math.huge,0/0}) do eq(Target.percent(25,v),nil) end; eq(Target.percent(math.huge,100),nil) end},
 {"existing eligible target remains stable",function(_,eq) local s=Target.new(); s:update(true,true,true,30,{c(1,25)}); s:update(true,true,true,30,{c(2,10),c(1,24)}); eq(s.id,1) end},
 {"target death leaves and respawn clear stale target",function(_,eq) local s=Target.new(); s:update(true,true,true,30,{c(1,25)}); s:update(true,true,true,30,{c(1,0),c(2,20)}); eq(s.id,2); s:update(true,true,true,30,{}); eq(s.id,nil); s:update(true,true,true,30,{c(2,100)}); eq(s.id,nil) end},
 {"becoming ineligible selects another eligible target",function(_,eq) local s=Target.new(); s:update(true,true,true,30,{c(1,25)}); s:update(true,true,true,30,{c(1,50),c(2,29)}); eq(s.id,2) end},
 {"local death missing safe zone and disable stop selection",function(_,eq) local s=Target.new(); for _,flags in ipairs({{true,false,true},{true,true,false},{false,true,true}}) do s:update(flags[1],flags[2],flags[3],30,{c(1,25)}); eq(s.id,nil) end end},
 {"local respawn recovers with valid state",function(_,eq) local s=Target.new(); s:update(true,false,true,30,{c(1,25)}); s:update(true,true,true,30,{c(1,25)}); eq(s.id,1) end},
}
