-- Reads replicated health at 4 Hz only while enabled. No target-processing workers.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Game=require("Game")
local Target=require("TargetState")
return function(hub,getPrefs,safeZone)
 local state=Target.new()
 local elapsed=0
 local function update()
  local prefs=getPrefs()
  local candidates={}
  if prefs.targetEnabled and Game.alive() and safeZone.saved() then
   for _,player in ipairs(Players:GetPlayers()) do
    if player~=Game.player then
     local char=player.Character
     local h=char and char:FindFirstChildOfClass("Humanoid")
     if h then table.insert(candidates,{id=player.UserId,name=player.Name,health=h.Health,maxHealth=h.MaxHealth}) end
    end
   end
  end
  state:update(prefs.targetEnabled,Game.alive(),safeZone.saved()~=nil,prefs.targetHp,candidates)
 end
 hub:connect(RunService.Heartbeat,function(dt)
  elapsed+=dt
  if elapsed>=0.25 then elapsed=0; if getPrefs().targetEnabled or state.state~="Disabled" then update() end end
 end)
 return {state=state,refresh=update}
end
