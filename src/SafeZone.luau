local State=require("SafeZoneState")
local Game=require("Game")
return function(getPrefs,save)
 local feature={status="Reference only; return and floating are unavailable"}
 local function root()
  local char=Game.player.Character
  return char and char:FindFirstChild("HumanoidRootPart")
 end
 function feature.saved() return State.decode(getPrefs().safeZone,game.PlaceId) end
 function feature.capture()
  local part=root()
  if not part or not Game.alive() then feature.status="Wait for a living character and root part"; return false end
  local ok,components=pcall(function() return {part.CFrame:GetComponents()} end)
  local text=ok and State.encode(game.PlaceId,components)
  if not text then feature.status="Character position is unavailable"; return false end
  getPrefs().safeZone=text; save(); feature.status="Saved position and orientation; no movement performed"; return true
 end
 function feature.clear() getPrefs().safeZone=""; save(); feature.status="Safe zone cleared" end
 function feature.describe()
  local part=root()
  local ok,components=pcall(function() return {part.CFrame:GetComponents()} end)
  return State.describe(feature.saved(),ok and components or nil)
 end
 function feature.keyAction() feature.status=feature.describe(); return feature.status end
 return feature
end
