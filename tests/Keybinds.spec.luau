local make=require("Keybinds")
return {
 {"Toggle, Hold, Always, unbound, focus loss and rebinding",function(check,eq)
  local events={ended={},focus={}};local input={InputEnded=events.ended,WindowFocusReleased=events.focus}
  local scope={connect=function(_,signal,fn) table.insert(signal,fn) end,add=function() end}
  local p={key="F",mode="Toggle"};local active=false
  local api=make(scope,input,function() return p end,{{key="key",mode="mode",get=function() return active end,set=function(on) active=on end}})
  local function up(name) for _,fn in ipairs(events.ended) do fn({KeyCode={Name=name}}) end end
  api.reconcile();check(api.press("F"));check(active);api.press("F");check(active);up("F");api.press("F");check(not active);up("F")
  p.mode="Hold";api.reconcile();api.press("F");check(active);up("F");check(not active)
  api.press("F");for _,fn in ipairs(events.focus) do fn() end;check(not active)
  api.press("F");p.key="G";api.reconcile();check(not active);check(not api.press("F"));api.press("G");check(active)
  p.mode="Always";api.reconcile();active=true;check(not api.press("G"));check(active)
  p.key="NONE";api.reconcile();active=true;check(not api.press("NONE"));check(active)
 end},
}
