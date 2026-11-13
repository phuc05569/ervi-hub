local E={};E.__index=E
function E.new() return setmetatable({latched=false,status="Off"},E) end
function E:evaluate(enabled,configured,health,maxHealth,threshold)
 local valid=type(health)=="number" and type(maxHealth)=="number" and health==health and maxHealth==maxHealth and health<math.huge and maxHealth<math.huge and maxHealth>0
 if valid and health/maxHealth*100>threshold then self.latched=false end
 if not enabled then self.status="Off";return false end
 if not configured then self.status="Destination missing";return false end
 if not valid or health<=0 then self.status="Waiting for respawn";return false end
 local percent=health/maxHealth*100
 if percent>threshold then self.latched=false;self.status="Ready";return false end
 if self.latched then return false end
 self.latched=true;self.status="Triggered";return true
end
function E:reset() self.latched=false;self.status="Waiting for respawn" end
return E
