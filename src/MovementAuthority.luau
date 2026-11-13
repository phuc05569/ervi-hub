-- Never discovers or invokes target-game movement remotes. This adapter exists
-- solely for the explicitly installed server in the owned unpublished Studio fixture.
local Policy=require("MovementPolicy")
local Run=game:GetService("RunService")
return function(hub)
 local api={available=false,busy=false,status="Unavailable · no permitted server movement API"}
 local folder=game:GetService("ReplicatedStorage"):FindFirstChild("ErviStudioAuthority")
 local ok,studio=pcall(function() return Run:IsStudio() end)
 local approved=folder and folder:GetAttribute("ErviOwnedFixture")==true
 if not Policy.authorized(ok and studio,approved,game.PlaceId,game.GameId,folder and folder:GetAttribute("Protocol")) then return api end
 local request,control,state=folder:FindFirstChild("Request"),folder:FindFirstChild("Control"),folder:FindFirstChild("State")
 if not (request and request:IsA("RemoteFunction") and control and control:IsA("RemoteEvent") and state and state:IsA("RemoteEvent")) then return api end
 api.available=true;api.status="Owned Studio server available";api.changed=state.OnClientEvent
 local worker,closed
 function api.request(action,payload,done)
  if closed or api.busy then return false end
  api.busy=true
  worker=task.spawn(function()
   local success,result=pcall(function() return request:InvokeServer(action,payload) end)
   if closed then return end
   api.busy=false;worker=nil
   if not success or type(result)~="table" or type(result.ok)~="boolean" then
    done({ok=false,message="Uncertain server response; no automatic retry"});return
   end
   done(result)
  end)
  return true
 end
 function api.control(direction,look) if not closed then control:FireServer("control",direction,look) end end
 function api.release() if not closed then control:FireServer("release") end end
 hub:add(function()
  api.release();closed=true
  if worker and coroutine.running()~=worker then pcall(task.cancel,worker) end
  worker=nil;api.busy=false
 end)
 return api
end
