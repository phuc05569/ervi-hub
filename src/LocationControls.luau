-- Read-only established destinations. Coordinate editing and named positions
-- were removed at the owner's request; underlying place-scoped data is retained.
local Ui=require("Ui")
local Game=require("Game")
return function(ctx)
 for i,zone in ipairs({"B"}) do
  local card=Ui.card(ctx.pages.safe.page,"Zone B · Protected destination",20+i,
   "Two bounded movement attempts with a temporary one-second physics hover between them. Protection is provided by the game.")
  Ui.button(ctx.hub,card,"Teleport to Zone "..zone,{order=1},function() ctx.safe.select(zone,true) end)
  Ui.button(ctx.hub,card,"Deactivate Zone "..zone,{order=2},function() if ctx.safe.zone==zone then ctx.safe.setEnabled(false) end end)
  local status=Ui.text(card,"",{order=3})
  ctx.onRefresh("safe","zone "..zone,function()
   local saved=ctx.safe.saved(zone)
   Ui.set(status,"Text",saved and ("Established destination · place %d"):format(saved.place) or "Destination unavailable in this place")
  end)
 end
 local status=Ui.text(ctx.pages.safe.page,"",{order=100})
 ctx.onRefresh("safe","emergency state",function()
  local ready,why=Game.rollStatus()
  Ui.set(status,"Text","Emergency: "..ctx.safe.emergency.status.." · selected Zone "..ctx.safe.zone.." · "..ctx.safe.status..
   (ctx.safe.stabilizing and " · physics hover active" or "").."\nRoll: "..(ready and "Ready" or tostring(why)))
 end)
end
