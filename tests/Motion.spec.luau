local Motion=require("Motion")
local function fixture()
 local tweens={}
 local motion=Motion.new(function(node,duration,goal)
  local callback
  local t={duration=duration,goal=goal}
  t.Completed={Connect=function(_,fn) callback=fn;return {Disconnect=function() t.disconnected=true end} end}
  function t:Play() end
  function t:Cancel() self.cancelled=true end
  function t:finish() if not self.cancelled then for k,v in pairs(goal) do node[k]=v end end;callback() end
  table.insert(tweens,t);return t
 end)
 return motion,tweens
end
return {
 {"rapid replacement ignores cancelled completions",function(check,eq)
  local m,t=fixture();local node={x=0};local calls=0
  m.to(node,{x=1},0.2,function() calls+=10 end)
  m.to(node,{x=0},0.2,function() calls+=1 end)
  check(t[1].cancelled and t[1].disconnected);t[1]:finish();eq(calls,0)
  t[2]:finish();eq(calls,1);eq(node.x,0);check(t[2].disconnected)
 end},
 {"reduced motion settles current work and future changes immediately",function(_,eq)
  local m,t=fixture();local node={x=0};local calls=0
  m.to(node,{x=4},0.2,function() calls+=1 end);m.configure(true,1)
  eq(node.x,4);eq(calls,1);t[1]:finish();eq(calls,1)
  m.to(node,{x=8},0.2);eq(node.x,8);eq(#t,1)
 end},
 {"scope close cancels all work without completion",function(check,eq)
  local m,t=fixture();local node={x=0};local calls=0
  m.to(node,{x=4},0.2,function() calls+=1 end);m.close();t[1]:finish()
  check(t[1].cancelled);eq(calls,0);m.to(node,{x=9});eq(node.x,0)
 end},
 {"speed bounded and failed service falls back",function(_,eq)
  local m,t=fixture();m.configure(false,99);m.to({},{x=1},0.2);eq(t[1].duration,0.1)
  local fallback=Motion.new(function() error("unavailable") end);local n={}
  fallback.to(n,{x=3},0.2);eq(n.x,3)
 end},
}
