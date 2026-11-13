local Target=require("ClickTarget")
return {
 {"click targeting rejects missing nonfinite steep and over-range destinations",function(check)
  check(not Target.valid(nil,{0,1,0},10))
  check(not Target.valid({0/0,0,0},{0,1,0},10))
  check(not Target.valid({1,2,3},{0,0,1},10))
  check(not Target.valid({1,2,3},{0,1,0},501))
  check(Target.valid({1,2,3},{0,1,0},500))
  check(not Target.valid({1,2,3},{0,1,0},101,100))
  check(Target.valid({1,2,3},{0,1,0},100,100))
 end},
 {"click preview default binding is LeftControl and settings round trip",function(check,eq)
  local Settings=require("Settings")
  local p=Settings.defaults();eq(p.clickTPKey,"LeftControl");eq(p.clickTPEnabled,false)
  p.clickTPKey="T";p.clickTPSize=8;p.clickTPOpacity=0.4
  local store=Settings.newStore();Settings.put(store,"Default",p)
  local loaded=Settings.parse(Settings.serialize(store),{})
  eq(loaded.configs.Default.clickTPKey,"T")
  eq(loaded.configs.Default.clickTPSize,8)
  eq(loaded.configs.Default.clickTPOpacity,0.4)
 end},
}
