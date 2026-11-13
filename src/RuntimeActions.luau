local Game=require("Game")
return function(hub,getPrefs)
 local actions={status="Ready",fpsStatus="Current cap unchanged",busy=false}
 actions.fpsSupported=type(setfpscap)=="function" and type(getfpscap)=="function"
 local previousCap,writtenCap
 local function fpsRestore()
  if previousCap~=nil and type(setfpscap)=="function" and type(getfpscap)=="function" then
   local ok,current=pcall(getfpscap)
   if ok and current==writtenCap then pcall(setfpscap,previousCap) end
  end
  previousCap,writtenCap=nil,nil
 end
 function actions.applyFPS()
  local requested=getPrefs().fpsCap
  if requested==0 then fpsRestore();actions.fpsStatus=actions.fpsSupported and "0 · leave existing/default cap unchanged" or "0 · unchanged; getfpscap + setfpscap unavailable";return end
  if type(setfpscap)~="function" or type(getfpscap)~="function" then actions.fpsStatus="Unsupported: getfpscap + setfpscap required for restoration";return end
  if previousCap==nil then local ok,value=pcall(getfpscap);if not ok or type(value)~="number" then actions.fpsStatus="Cannot read current cap";return end;previousCap=value end
  local ok,err=pcall(setfpscap,requested)
  if ok then
   local read,current=pcall(getfpscap);writtenCap=read and current or requested
   actions.fpsStatus="Cap "..tostring(writtenCap).." · prior cap retained for unload"
  else actions.fpsStatus=tostring(err) end
 end
 function actions.copyJob()
  if type(game.JobId)~="string" or game.JobId=="" then actions.status="Job ID unavailable";return end
  local ok,err=Game.copy(game.JobId);actions.status=ok and "Job ID copied" or tostring(err)
 end
 function actions.rejoin()
  local ok,err=pcall(function() game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId,game.JobId,Game.player) end)
  actions.status=ok and "Rejoin requested" or ("Rejoin failed: "..tostring(err))
 end
 function actions.serverHop()
  if actions.busy then return end
  actions.busy=true
  hub:add(task.spawn(function()
   local ok,err=pcall(function()
    local url=("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
    local data=game:GetService("HttpService"):JSONDecode(game:HttpGet(url))
    if hub.closed then return end
    if type(data)~="table" or type(data.data)~="table" then error("Invalid server list") end
    for _,server in ipairs(data.data) do
     if type(server.id)=="string" and server.id~=game.JobId and type(server.playing)=="number" and type(server.maxPlayers)=="number" and server.playing<server.maxPlayers then
      game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId,server.id,Game.player)
      actions.status="Server hop requested"; return
     end
    end
    actions.status="No different non-full server in first 100 results"
   end)
   if not ok then actions.status="Server hop unavailable: "..tostring(err) end
   actions.busy=false
  end))
 end
 function actions.capabilities()
  local probes={{"delfile",delfile},{"queue_on_teleport",queue_on_teleport or queueonteleport},{"getcustomasset",getcustomasset},{"gethui",gethui},{"setfpscap",setfpscap},{"getfpscap",getfpscap},{"getconnections",getconnections},{"firesignal",firesignal},{"require (bundle resolver)",require},{"clipboard",setclipboard or toclipboard},{"readfile",readfile},{"writefile",writefile}}
  local lines={}
  for _,probe in ipairs(probes) do table.insert(lines,probe[1]..": "..(type(probe[2])=="function" and "present (presence only)" or "unavailable")) end
  return table.concat(lines,"\n")
 end
 hub:add(fpsRestore)
 return actions
end
