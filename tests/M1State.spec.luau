local State = require("M1State")
local function state(style, value, now)
 local s = State.new(); s:reset(style); s:observe(value, now or 100); return s
end
return {
 {"cooldown bar uses each observed duration and clears on reset",function(_,eq)
  local s=state("Punch",104);eq(s:snapshot(102,true,true).fraction,0.5)
  eq(s:snapshot(105,true,true).fraction,1)
  s:reset("Slap");eq(s:snapshot(105,true,true).fraction,nil)
  s:observe(112,105);eq(s:snapshot(108.5,true,true).fraction,0.5)
 end},
 { "missing signal never implies READY", function(_, eq) eq(state("Punch", nil):snapshot(100, true, true).status, "UNKNOWN") end },
 { "Punch deadline counts down in server time", function(_, eq) local s = state("Punch", 100.7); eq(s:snapshot(100.2, true, true).remaining, 0.5) end },
 { "Slap supports a different duration and transitions to READY", function(_, eq) local s = state("Slap", 103.5); eq(s:snapshot(100, true, true).remaining, 3.5); eq(s:snapshot(104, true, true).status, "READY") end },
 { "a changed deadline immediately replaces the prior cooldown", function(_, eq) local s = state("Punch", 101); s:observe(108, 100); eq(s:snapshot(100, true, true).remaining, 8) end },
 { "style changes invalidate the old deadline", function(_, eq) local s = state("Punch", 101); s:reset("Slap"); eq(s:snapshot(100, true, true).status, "UNKNOWN") end },
 { "unequipping never reports readiness", function(_, eq) eq(state("Punch", 101):snapshot(102, false, true).status, "UNEQUIPPED") end },
 { "dead characters never report readiness", function(_, eq) eq(state("Punch", 101):snapshot(102, true, false).status, "UNAVAILABLE") end },
 { "respawn reset waits for fresh evidence", function(_, eq) local s = state("Punch", 101); s:reset("Punch"); eq(s:snapshot(105, true, true).status, "UNKNOWN") end },
 { "NaN infinity zero strings and implausible clocks are rejected", function(_, eq)
   for _, v in ipairs({0/0, math.huge, -math.huge, 0, -1, "101", 10000, 1}) do eq(state("Punch", v, 1000):snapshot(1000, true, true).status, "UNKNOWN") end
 end },
 { "removed attributes clear the countdown", function(_, eq) local s = state("Punch", 101); s:observe(nil, 100); eq(s:snapshot(100, true, true).status, "UNKNOWN") end },
 { "evidence explicitly labels unverified clock semantics", function(check) check(state("Punch", 101):snapshot(100, true, true).evidence:find("UNVERIFIED", 1, true)) end },
 { "fresh samples recover after delayed replication", function(_, eq) local s = state("Punch", nil); s:observe(102, 101); eq(s:snapshot(101, true, true).remaining, 1) end },
}
