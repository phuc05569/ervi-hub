-- Own only the properties explicitly written. Restore only if still our value,
-- preserving later changes made by the game or another feature.
local Overrides={}; Overrides.__index=Overrides
function Overrides.new() return setmetatable({entries={}},Overrides) end
function Overrides:set(key,object,property,value)
 local e=self.entries[key]
 if e and e.object~=object then self:clear(key); e=nil end
 if not e then e={object=object,property=property,original=object[property]}; self.entries[key]=e end
 local previous=e.written
 e.written=value
 e.writing=true
 local ok,err=pcall(function() object[property]=value;e.written=object[property] end)
 e.writing=false
 if not ok then e.written=previous;error(err,0) end
end
function Overrides:clear(key)
 local e=self.entries[key]; if not e then return end
 self.entries[key]=nil
 pcall(function() if e.object[e.property]==e.written then e.object[e.property]=e.original end end)
end
function Overrides:close()
 local keys={}; for key in pairs(self.entries) do table.insert(keys,key) end
 for _,key in ipairs(keys) do self:clear(key) end
end
return Overrides
