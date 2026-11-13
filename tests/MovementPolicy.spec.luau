local Policy=require("MovementPolicy")
return {
 {"authority is confined to the unpublished owned Studio fixture",function(check)
  check(Policy.authorized(true,true,0,0,"ErviStudioMovementV1"))
  check(not Policy.authorized(false,true,0,0,"ErviStudioMovementV1"))
  check(not Policy.authorized(true,true,119338513416973,0,"ErviStudioMovementV1"))
  check(not Policy.authorized(true,true,0,1,"ErviStudioMovementV1"))
  check(not Policy.authorized(true,true,0,0,"other"))
 end},
 {"server rejects malformed, nonfinite and excessive controls",function(check)
  check(Policy.control({0,0,0},{0,0,-1}))
  check(Policy.control({0.5,0.5,0.5},{1,0,0}))
  for _,v in ipairs({{2,0,0},{1,1,1},{0/0,0,0},{math.huge,0,0}}) do check(not Policy.control(v,{0,0,-1})) end
  check(not Policy.control({0,0,0},{0,0,0}));check(not Policy.control({0,0,0},{0,1,0}))
  check(Policy.state({fly=true,noclip=false,speed=50}))
  check(not Policy.state({fly=1,noclip=false,speed=50}));check(not Policy.state({fly=true,noclip=true,speed=121}))
 end},
 {"movement speed, bindings and target range persist without overwriting explicit choices",function(check,eq)
  local Settings=require("Settings");local p=Settings.defaults()
  eq(p.flySpeed,50);eq(p.flyKey,"L");eq(p.noclipKey,"N");eq(p.clickTPKey,"LeftControl");eq(p.espTextSize,12);eq(p.updateRate,"Auto")
  local s=Settings.newStore();p.espTextSize=20;p.flySpeed=75;p.flyKey="F6";p.clickTPKey="NONE";Settings.put(s,"A",p)
  local loaded=Settings.parse(Settings.serialize(s),{}).configs.A
  eq(loaded.espTextSize,20);eq(loaded.flySpeed,75);eq(loaded.flyKey,"F6");eq(loaded.clickTPKey,"NONE")
  check(not Policy.state({fly=false,noclip=true,speed=0/0}))
 end},
}
