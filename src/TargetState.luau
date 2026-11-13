-- Read-only manual-combat selection. No movement, attacks, ESP or worker coroutine.
local Target = {}
Target.__index=Target
function Target.percent(health,maxHealth)
 if type(health)~="number" or type(maxHealth)~="number" or health~=health or maxHealth~=maxHealth
  or math.abs(health)==math.huge or math.abs(maxHealth)==math.huge or maxHealth<=0 then return nil end
 return math.clamp(health/maxHealth*100,0,100)
end
function Target.new() return setmetatable({state="Disabled"},Target) end
function Target:update(enabled,alive,hasSafe,threshold,candidates)
 local old=self.id
 self.id,self.name,self.hp=nil,nil,nil
 if not enabled then self.state="Disabled"; return end
 if not alive then self.state="Waiting for your character"; return end
 if not hasSafe then self.state="Safe Zone unavailable in this place"; return end
 local selected
 for _,c in ipairs(candidates) do
  local hp=Target.percent(c.health,c.maxHealth)
  if c.id and hp and hp>0 and hp<threshold then
   c.percent=hp
   if c.id==old then selected=c; break end
   if not selected or hp<selected.percent or (hp==selected.percent and c.id<selected.id) then selected=c end
  end
 end
 if selected then
  self.id,self.name,self.hp=selected.id,selected.name,selected.percent
  self.state="Manual combat · movement unavailable"
 else self.state="Waiting for an eligible player" end
end
return Target
