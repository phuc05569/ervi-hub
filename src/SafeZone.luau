-- Owner-requested fixed destination. One local move on OFF -> ON; never retries,
-- fights server correction, changes physics, or automatically moves on respawn.
local State = require("SafeZoneState")
local Game = require("Game")
return function(hub)
 local feature = { enabled = false, status = "Off", onChanged = nil }
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
  if on == feature.enabled then return end
  if not on then
   feature.enabled, feature.status = false, "Off · normal game movement"
  else
   local target, part = feature.saved(), root()
   if not target then
    feature.status = "Unavailable in this place"
   elseif not part or not Game.alive() then
    feature.status = "Wait for a living character, then turn Safe Zone on again"
   else
    local ok, err = pcall(function()
     local x,y,z = part.CFrame:GetComponents()
     local c = target.components
     local char = Game.player.Character
     -- Translate the whole model by the root's displacement, preserving orientation.
     char:PivotTo(char:GetPivot() + Vector3.new(c[1]-x,c[2]-y,c[3]-z))
    end)
    feature.enabled = ok
    feature.status = ok and "Local move requested · server acceptance unverified" or ("Move failed · no retry: " .. tostring(err))
   end
  end
  if feature.onChanged then feature.onChanged(feature.enabled) end
 end
 hub:connect(Game.player.CharacterRemoving,function() feature.setEnabled(false) end)
 hub:add(function() feature.setEnabled(false) end)
 function feature.keyAction() feature.setEnabled(not feature.enabled) end
 return feature
end
