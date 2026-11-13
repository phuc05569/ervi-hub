-- Observation state only. A local observation is never proof of server acceptance.
local Attempt={};Attempt.__index=Attempt
function Attempt.new()
 return setmetatable({busy=false,status="Idle"},Attempt)
end
function Attempt:begin(character,destination,move)
 if self.busy then return false,"Movement pending" end
 self.character=character;self.destination=destination;self.elapsed=0;self.seen=false
 self.busy=true;self.outcome="pending";self.status="Movement requested · observing position"
 local ok,err=pcall(move)
 if not ok then self.busy=false;self.outcome="failed";self.status="Movement failed: "..tostring(err);return false,self.status end
 return true
end
function Attempt:step(dt,character,alive,distance)
 if not self.busy then return end
 self.elapsed+=dt
 if character~=self.character or not alive then self:cancel("Character changed or died");return end
 if type(distance)~="number" or distance~=distance then self:cancel("Position unavailable");return end
 if distance<=6 then self.seen=true end
 if self.seen and distance>12 then self:cancel("Movement corrected or displaced · no retry");return end
 if self.elapsed>=0.8 then
  self.busy=false
  self.outcome=distance<=6 and "observed" or "rejected"
  self.status=distance<=6 and "Teleport observed locally · server/game acceptance unverified" or "Teleport rejected or not observed · no retry"
 end
end
function Attempt:cancel(reason)
 self.busy=false;self.outcome="cancelled";self.character=nil;self.destination=nil;self.status=reason or "Cancelled"
end
return Attempt
