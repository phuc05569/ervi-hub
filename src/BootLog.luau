-- Actual initialization stages, bounded and optionally retained for the next run.
local Boot={};Boot.FILE="Ervi_Hub_boot.txt"
function Boot.new(build,now,read,write)
 local previous="Previous boot unavailable (no readable retained log)"
 if type(read)=="function" then local ok,text=pcall(read,Boot.FILE);if ok and type(text)=="string" then previous=text:sub(-32768) end end
 local self={lines={},started=now(),previous=previous}
 function self.step(message)
  table.insert(self.lines,("+%.3fs %s | %s"):format(now()-self.started,build,tostring(message):sub(1,500)))
  while #self.lines>80 do table.remove(self.lines,1) end
  if type(write)=="function" then pcall(write,Boot.FILE,table.concat(self.lines,"\n")) end
 end
 function self.text() return "Current boot\n"..table.concat(self.lines,"\n").."\n\nPrevious boot\n"..self.previous end
 return self
end
return Boot
