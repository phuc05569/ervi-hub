local Locale=require("Locale")
local Registry={}
Registry.__index=Registry
function Registry.new() return setmetatable({entries={},serial=0},Registry) end
function Registry:prune()
 local alive={}
 for _,entry in ipairs(self.entries) do if not entry.control or entry.control.Parent then table.insert(alive,entry) end end
 self.entries=alive
end
function Registry:add(page,title,description,control,section)
 if self.serial%64==0 then self:prune() end
 self.serial+=1
 local e={page=page,title=title,description=description or "",control=control,section=section or title,id=self.serial}
 table.insert(self.entries,e); return e
end
function Registry:search(query,limit)
 self:prune()
 query=Locale.fold(query or ""):match("^%s*(.-)%s*$")
 if query=="" then return {} end
 local results={}
 for _,e in ipairs(self.entries) do
  if not e.control or e.control.Parent then
   local text=Locale.fold(e.title.." "..e.description.." "..e.section.." "..Locale.text(e.title,"RU"))
   local match=true
   for word in query:gmatch("%S+") do if not text:find(word,1,true) then match=false; break end end
   if match then table.insert(results,e) end
  end
 end
 table.sort(results,function(a,b)
  local aExact=Locale.fold(a.title)==query; local bExact=Locale.fold(b.title)==query
  if aExact~=bExact then return aExact end
  return a.id<b.id
 end)
 while #results>(limit or 12) do table.remove(results) end
 return results
end
return Registry
