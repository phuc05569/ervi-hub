local Game=require("Game")
local Attempt=require("MovementAttempt")
return function(hub,authority)
 local state=Attempt.new()
 local api={state=state,status="Idle",busy=false}
 local callback,epoch= nil,0
 local function finish()
  api.busy=false;api.status=state.status;api.outcome=state.outcome
  local done=callback;callback=nil
  if done then done(api.status,api.outcome) end
 end
 function api.setAuthority(adapter) authority=adapter end
 function api.ready() return not api.busy and not (authority and authority.busy) and not hub.closed end
 function api.cancel(reason,owner)
  if owner and api.owner~=owner then return end
  epoch+=1;state:cancel(reason);callback=nil;api.busy=false;api.status=state.status
 end
 function api.move(position,range,done,owner,surface)
  if api.busy or hub.closed then return false,"Movement pending or unloaded" end
  local char=Game.player.Character;local root=char and char:FindFirstChild("HumanoidRootPart")
  if not root or not Game.alive() then return false,"Wait for a living character" end
  if typeof(position)~="Vector3" or position.X~=position.X or position.Y~=position.Y or position.Z~=position.Z or math.max(math.abs(position.X),math.abs(position.Y),math.abs(position.Z))>1e7 then return false,"Invalid destination" end
  if range and (position-root.Position).Magnitude>range then return false,"Destination outside range" end
  if api.beforeMove then api.beforeMove(owner) end
  if Game.player.Character~=char or not root.Parent or not Game.alive() then return false,"Character changed before movement" end
  if root.Anchored then return false,"Release position hold before moving" end
  callback=done;api.busy=true;api.owner=owner
  local token=epoch
  if authority and authority.available then
   -- The owned fixture's protocol takes a ground hit, while saved positions
   -- and native MoveTo use a character position. The server validates it again.
   if not surface then
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={char};params.IgnoreWater=true
    local hit=workspace:Raycast(position+Vector3.new(0,6,0),Vector3.new(0,-24,0),params)
    surface=hit and hit.Position
   end
   if not surface then api.busy=false;callback=nil;return false,"No landing surface for owned Studio server" end
   local accepted=authority.request("teleport",{position=surface,range=math.clamp(range or 500,10,500)},function(result)
    if token~=epoch or hub.closed then return end
    api.busy=false;callback=nil
    api.status=result.ok and "Owned Studio server acknowledged teleport" or tostring(result.message or "Server rejected movement")
    api.outcome=result.ok and "server-acknowledged" or "rejected"
    if done then done(api.status,api.outcome) end
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
