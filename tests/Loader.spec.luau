local Loader = require("Loader")
local function fixture()
 local f = { calls = 0, runs = 0, waits = 0, compiles = 0, cleanups = 0 }
 local config = { url = "https://raw.githubusercontent.com/example/ervi-release/" .. string.rep("a", 40) .. "/Ervi_Hub.luau", build = "2.5.0+test" }
 f.body = "-- Ervi Hub | build " .. config.build .. "\nreturn stop"
 local api = { placeId = 119338513416973, registry = {} }
 api.currentStop = function() return f.stop end
 api.fetch = function() f.calls += 1; return f.body end
 api.wait = function() f.waits += 1 end
 api.compile = function()
   f.compiles += 1
   return function() f.runs += 1; f.stop = function() f.cleanups += 1; f.stop = nil end; return f.stop end
 end
 return f, api, config
end
return {
 { "traversal cannot escape a pinned commit", function(_,eq) local f,a,c=fixture(); c.url=c.url:gsub("/Ervi_Hub.luau", "/../main/Ervi_Hub.luau"); eq(Loader.run(a,c),nil); eq(f.calls,0) end },
 { "a new release is not mistaken for a duplicate", function(check,eq) local f,a,c=fixture(); check(Loader.run(a,c)); c.build="2.5.1+new"; f.body="-- Ervi Hub | build " .. c.build .. "\nreturn stop"; check(Loader.run(a,c)); eq(f.runs,2); eq(a.registry.build,c.build) end },
 { "bad stop handles clean up a partially registered hub", function(_,eq) local f,a,c=fixture(); a.compile=function() return function() f.stop=function() f.cleanups+=1; f.stop=nil end; return nil end end; eq(Loader.run(a,c),nil); eq(f.cleanups,1) end },
 { "failure before registration preserves a previous hub", function(_,eq) local f,a,c=fixture(); local old=function() f.cleanups+=1 end; f.stop=old; a.compile=function() return function() error("early boot") end end; eq(Loader.run(a,c),nil); eq(f.cleanups,0); eq(f.stop,old) end },
 { "wrong place performs no HTTP", function(_, eq) local f,a,c=fixture(); a.placeId=1; eq(Loader.run(a,c), nil); eq(f.calls,0) end },
 { "unset release and branch URLs are rejected", function(_, eq) local f,a,c=fixture(); for _,url in ipairs({"", "http://raw.githubusercontent.com/a/b/" .. string.rep("a",40) .. "/x", "https://raw.githubusercontent.com/a/b/main/x"}) do c.url=url; eq(Loader.run(a,c),nil) end; eq(f.calls,0) end },
 { "loads a pinned matching release once", function(check,eq) local f,a,c=fixture(); check(type(Loader.run(a,c))=="function"); eq(f.runs,1); eq(f.calls,1); eq(a.registry.loading,false) end },
 { "duplicate execution returns current stop without requests", function(_,eq) local f,a,c=fixture(); local stop=Loader.run(a,c); eq(Loader.run(a,c),stop); eq(f.runs,1); eq(f.calls,1) end },
 { "download errors retry exactly three times", function(_,eq) local f,a,c=fixture(); a.fetch=function() f.calls+=1; error("HTTP 404") end; eq(Loader.run(a,c),nil); eq(f.calls,3); eq(f.waits,2); eq(f.runs,0); eq(a.registry.loading,false) end },
 { "transient download error recovers before execution", function(check,eq) local f,a,c=fixture(); a.fetch=function() f.calls+=1; if f.calls==1 then error("HTTP 503") end; return f.body end; check(Loader.run(a,c)); eq(f.calls,2); eq(f.runs,1) end },
 { "HTML and wrong versions never execute", function(_,eq) local f,a,c=fixture(); for _,body in ipairs({"<html>404</html>","-- Ervi Hub | build wrong\n",string.rep("x",2*1024*1024+1)}) do f.body=body; eq(Loader.run(a,c),nil) end; eq(f.runs,0); eq(f.compiles,0) end },
 { "compile errors are not retried and keep old hub", function(_,eq) local f,a,c=fixture(); local old=function() end; f.stop=old; a.compile=function() return nil,"syntax" end; eq(Loader.run(a,c),nil); eq(f.calls,1); eq(f.stop,old) end },
 { "runtime errors clean partial hub and never retry execution", function(_,eq) local f,a,c=fixture(); a.compile=function() return function() f.runs+=1; f.stop=function() f.cleanups+=1; f.stop=nil end; error("boot") end end; eq(Loader.run(a,c),nil); eq(f.runs,1); eq(f.cleanups,1); eq(a.registry.loading,false) end },
 { "nested calls are blocked while HTTP yields", function(_,eq) local f,a,c=fixture(); local fetch=a.fetch; a.fetch=function(url) eq(Loader.run(a,c),nil); return fetch(url) end; Loader.run(a,c); eq(f.calls,1); eq(f.runs,1) end },
 { "manual unload permits a fresh run", function(_,eq) local f,a,c=fixture(); local stop=Loader.run(a,c); stop(); Loader.run(a,c); eq(f.runs,2) end },
 { "missing stop handle is reported", function(_,eq) local f,a,c=fixture(); a.compile=function() return function() return nil end end; eq(Loader.run(a,c),nil); eq(a.registry.loading,false) end },
}
