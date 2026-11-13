local Game=require("Game")
local Attempt=require("MovementAttempt")
return function(hub,authority)
 local state=Attempt.new()
 local api={state=state,status="Idle",busy=false}
 local callback,epoch= nil,0
 local function finish()
  api.busy=false;api.status=state.status
  local done=callback;callback=nil
  if done then done(api.status) end
 end
 function api.cancel(reason)
  epoch+=1;state:cancel(reason);callback=nil;api.busy=false;api.status=state.status
 end
 function api.move(position,range,done)
  if api.busy or hub.closed then return false,"Movement pending or unloaded" end
  local char=Game.player.Character;local root=char and char:FindFirstChild("HumanoidRootPart")
  if not root or not Game.alive() then return false,"Wait for a living character" end
  if typeof(position)~="Vector3" or position.X~=position.X or position.Y~=position.Y or position.Z~=position.Z or math.max(math.abs(position.X),math.abs(position.Y),math.abs(position.Z))>1e7 then return false,"Invalid destination" end
  if range and (position-root.Position).Magnitude>range then return false,"Destination outside range" end
  if root.Anchored then return false,"Release position hold before moving" end
  callback=done;api.busy=true
  local token=epoch
  if authority and authority.available then
   local accepted=authority.request("teleport",{position=position,range=range or 500},function(result)
    if token~=epoch or hub.closed then return end
    api.busy=false;callback=nil
    api.status=result.ok and "Owned Studio server acknowledged teleport" or tostring(result.message or "Server rejected movement")
    if done then done(api.status) end
   end)
   if not accepted then api.busy=false;callback=nil;return false,"Server request pending" end
   api.status="Waiting for owned Studio server";return true
  end
  local ok,reason=state:begin(char,position,function() char:MoveTo(position) end)
  api.status=state.status
  if not ok then callback=nil;api.busy=false;return false,reason end
  return true
 end
 hub:connect(game:GetService("RunService").Heartbeat,function(dt)
  if not state.busy then return end
  local char=Game.player.Character;local root=char and char:FindFirstChild("HumanoidRootPart")
  state:step(dt,char,Game.alive(),root and (root.Position-state.destination).Magnitude or math.huge)
  api.status=state.status
  if not state.busy then finish() end
 end)
 hub:connect(Game.player.CharacterRemoving,function() api.cancel("Waiting for respawn") end)
 hub:add(function() api.cancel("Unloaded") end)
 return api
end
