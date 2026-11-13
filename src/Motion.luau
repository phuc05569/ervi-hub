-- One owner per instance. Replaced transitions cannot run stale completion callbacks.
-- Factory injection lets tests exercise real interruption semantics without Roblox.
local Motion = {}
function Motion.new(create)
 local active = {}
 local api = {reduced=false, speed=1, closed=false}
 local function release(node, settle)
  local entry=active[node]
  if not entry then return end
  active[node]=nil
  if entry.connection then entry.connection:Disconnect() end
  if entry.tween then entry.tween:Cancel() end
  if settle then
   for key,value in pairs(entry.goal) do node[key]=value end
   if entry.done then entry.done() end
  end
 end
 function api.cancel(node) release(node,false) end
 function api.to(node,goal,duration,done)
  if api.closed then return end
  local previous=active[node]
  -- Finish unrelated properties when replacing a combined transition.
  if previous then
   for key,value in pairs(previous.goal) do if goal[key]==nil then node[key]=value end end
  end
  release(node,false)
  local function immediate()
   for key,value in pairs(goal) do node[key]=value end
   if done then done() end
  end
  if api.reduced or not create or duration==0 then immediate();return end
  local ok,tween=pcall(create,node,(duration or 0.12)/api.speed,goal)
  if not ok or not tween then immediate();return end
  local entry={tween=tween,goal=goal,done=done}
  active[node]=entry
  entry.connection=tween.Completed:Connect(function()
   if active[node]~=entry then return end
   active[node]=nil
   entry.connection:Disconnect()
   if done then done() end
  end)
  tween:Play()
 end
 function api.configure(reduced,speed)
  api.speed=math.clamp(tonumber(speed) or 1,0.5,2)
  api.reduced=reduced==true
  if api.reduced then
   local nodes={};for node in pairs(active) do table.insert(nodes,node) end
   for _,node in ipairs(nodes) do release(node,true) end
  end
 end
 function api.close()
  api.closed=true
  local nodes={};for node in pairs(active) do table.insert(nodes,node) end
  for _,node in ipairs(nodes) do release(node,false) end
 end
 return api
end
return Motion
