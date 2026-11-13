-- Fixed local destination and gravity hold. No repeat teleports or correction bypass.
local State = require("SafeZoneState")
local Game = require("Game")
local Scope = require("Scope")
local Hold = require("PositionHold")
return function(hub)
 local feature = { enabled = false, status = "Off", onChanged = nil }
 local holding
 local function root()
  local char = Game.player.Character
  return char and char:FindFirstChild("HumanoidRootPart")
 end
 function feature.saved() return State.preset(game.PlaceId) end
 function feature.describe()
  local part = root()
  local ok, components = pcall(function() return {part.CFrame:GetComponents()} end)
  return State.describe(feature.saved(), ok and components or nil)
 end
 function feature.setEnabled(on)
  if hub.closed and on then return end
  if on == feature.enabled then return end
  if not on then
   feature.enabled = false
   if holding then holding:close(); holding = nil end
   feature.status = "Off · normal game movement restored"
  else
   local target, part = feature.saved(), root()
   if not target then
    feature.status = "Unavailable in this place"
   elseif not part or not Game.alive() then
    feature.status = "Wait for a living character, then turn Safe Zone on again"
   else
    local char = Game.player.Character
    local release, err = Hold.acquire(part, Vector3.new(0,0,0), function()
     local x,y,z = part.CFrame:GetComponents()
     local c = target.components
     char:PivotTo(char:GetPivot() + Vector3.new(c[1]-x,c[2]-y,c[3]-z))
    end)
    if release then
     holding = Scope.new("safe-zone-hold")
     holding:add(release) -- runs after event handlers disconnect
     feature.enabled = true
     feature.status = "Holding at Safe Zone · local physics; server acceptance unverified"
     local function stop(reason)
      feature.setEnabled(false)
      feature.status = reason
     end
     local humanoid = Game.humanoid()
     if humanoid then holding:connect(humanoid.Died,function() stop("Released · character died") end) end
     holding:connect(char.ChildRemoved,function(child)
      if child == part then stop("Released · character root removed") end
     end)
     holding:connect(part:GetPropertyChangedSignal("Anchored"),function()
      if not part.Anchored then stop("Released · external physics update") end
     end)
     holding:connect(part:GetPropertyChangedSignal("CFrame"),function()
      local x,y,z = part.CFrame:GetComponents()
      local c = target.components
      if math.abs(x-c[1])+math.abs(y-c[2])+math.abs(z-c[3])>0.5 then
       stop("Released · external position update; no retry")
      end
     end)
    else
     feature.status = "Move/hold failed · no retry: " .. tostring(err)
    end
   end
  end
  if feature.onChanged then feature.onChanged(feature.enabled) end
 end
 hub:connect(Game.player.CharacterRemoving,function() feature.setEnabled(false) end)
 hub:add(function() feature.setEnabled(false) end)
 function feature.keyAction() feature.setEnabled(not feature.enabled) end
 return feature
end
