local V=require("SliderValue")
local Settings=require("Settings")
return {
 {"numeric clamping and decimal increments",function(check,eq)
  eq(V.normalize(-99,0,1,0.05,0),0);eq(V.normalize(99,0,1,0.05,0),1)
  check(math.abs(V.normalize(0.326,0,1,0.05,0)-0.35)<0.00001)
  eq(V.normalize(0/0,0,1,0.05,0.4),0.4)
  eq(V.normalize(math.huge,0,1,0.05,0.4),0.4)
  eq(V.normalize("invalid",0,1,0.05,0.4),0.4)
  eq(V.format(0.35,0.05),"0.35");eq(V.format(12,1),"12")
 end},
 {"new motion preferences preserve legacy settings",function(_,eq)
  local store=Settings.parse("speedMode=Set\nscale=1.25\nreduceAnimations=true\nanimationSpeed=1.5",{})
  local c=store.configs.Default
  eq(c.speedMode,"Set");eq(c.scale,1.25);eq(c.reduceAnimations,true);eq(c.animationSpeed,1.5)
 end},
}
