local Hold=require("PositionHold")
local zero={X=0,Y=0,Z=0}
return {
 {"hold cancels falling and anchors before movement",function(check,eq)
  local p={Anchored=false,AssemblyLinearVelocity={Y=-100},AssemblyAngularVelocity={Y=10}}
  local release=Hold.acquire(p,zero,function() check(p.Anchored); eq(p.AssemblyLinearVelocity,zero) end)
  check(release); check(p.Anchored); release(); eq(p.Anchored,false); eq(p.AssemblyLinearVelocity,zero)
 end},
 {"pre-existing anchored state is preserved",function(check)
  local p={Anchored=true}; local release=Hold.acquire(p,zero,function() end); release(); check(p.Anchored)
 end},
 {"movement error rolls back physics",function(_,eq)
  local p={Anchored=false}; local release=Hold.acquire(p,zero,function() error("movement denied") end)
  eq(release,nil); eq(p.Anchored,false); eq(p.AssemblyLinearVelocity,zero)
 end},
 {"release is idempotent",function(_,eq)
  local p={Anchored=false}; local release=Hold.acquire(p,zero,function() end); release()
  p.AssemblyLinearVelocity="new game velocity"; release(); eq(p.AssemblyLinearVelocity,"new game velocity")
 end},
 {"external unanchor is respected",function(_,eq)
  local p={Anchored=true}; local release=Hold.acquire(p,zero,function() end)
  p.Anchored=false; p.AssemblyLinearVelocity="server velocity"; release()
  eq(p.Anchored,false); eq(p.AssemblyLinearVelocity,"server velocity")
 end},
}
