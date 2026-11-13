local Ui=require("Ui")
local Game=require("Game")
local P=require("PositionData")
return function(ctx)
 local hub=ctx.hub
 local function current()
  local char=Game.player.Character;local root=char and char:FindFirstChild("HumanoidRootPart")
  if not root then return nil end
  local v=root.Position;return P.point(game.PlaceId,v.X,v.Y,v.Z)
 end
 for i,zone in ipairs({"A","B"}) do
  local card=Ui.card(ctx.pages.safe.page,"Zone "..zone..(zone=="A" and " · Rollable" or " · Protected destination"),20+i,"Saved position is place-specific. Game roll/protection behavior requires independent verification.")
  local draft,fields={},{}
  for n,axis in ipairs({"X","Y","Z"}) do
   fields[n]=Ui.input(hub,card,axis,{order=n},function(value) draft[n]=tonumber(value) end)
   fields[n].Name="Zone"..zone.."_"..axis
  end
  local status=Ui.text(card,"",{order=9})
  Ui.button(hub,card,"Capture Current Position · "..zone,{order=4},function()
   local point=current()
   if not point then status.Text="Character unavailable";return end
   draft={point.x,point.y,point.z};for n,value in ipairs(draft) do fields[n].Text=tostring(value) end
   status.Text="Captured · Save Location to persist"
  end)
  Ui.button(hub,card,"Save Location · "..zone,{order=5},function()
   local p=P.point(game.PlaceId,draft[1],draft[2],draft[3])
   status.Text=p and ctx.safe.saveLocation(zone,p) and "Location saved" or "Enter finite X/Y/Z coordinates"
  end)
  Ui.button(hub,card,"Test Location · "..zone,{order=6},function() ctx.safe.select(zone,true) end)
  Ui.button(hub,card,"Reset Location · "..zone,{order=7},function() ctx.safe.saveLocation(zone,nil) end)
  Ui.button(hub,card,"Deactivate Zone · "..zone,{order=8},function() if ctx.safe.zone==zone then ctx.safe.setEnabled(false) end end)
  local saved=Ui.text(card,"",{order=10})
  ctx.onRefresh("safe","zone "..zone,function()
   local p=ctx.safe.saved(zone)
   Ui.set(saved,"Text",p and ("Saved: %.2f, %.2f, %.2f · place %d"):format(p.components[1],p.components[2],p.components[3],p.place) or "Destination missing for this place")
  end)
 end
 local emergency=Ui.text(ctx.pages.safe.page,"",{order=100})
 ctx.onRefresh("safe","emergency state",function() Ui.set(emergency,"Text","Emergency: "..ctx.safe.emergency.status.." · selected Zone "..ctx.safe.zone.." · "..ctx.safe.status) end)
 local card=Ui.card(ctx.pages.teleports.page,"Saved positions",15,"Save/copy coordinates only. These controls do not teleport.")
 local name="Position";local selected="Position";local rename=""
 local status=Ui.text(card,"",{order=10})
 Ui.input(hub,card,"Position name / selected name",{order=1},function(value) name=value;selected=value end)
 Ui.button(hub,card,"Save Current Position",{order=2},function()
  local point=current();local all=P.decode(ctx.prefs().savedPositions)
  if not P.name(name) or not point then status.Text="Valid name and character required";return end
  all[name]=point;local encoded=P.encode(all)
  if not encoded then status.Text="Position limit reached";return end
  ctx.prefs().savedPositions=encoded;ctx.save();status.Text="Saved "..name
 end)
 Ui.button(hub,card,"Copy Current Position",{order=3},function()
  local point=current();if not point then status.Text="Character unavailable";return end
  local expression=P.expression(point);local ok=Game.copy(expression);status.Text=ok and "Copied "..expression or expression
 end)
 Ui.input(hub,card,"Rename selected to",{order=4},function(value) rename=value end)
 Ui.button(hub,card,"Rename Position",{order=5},function()
  local all=P.decode(ctx.prefs().savedPositions)
  if not all[selected] or not P.name(rename) or all[rename] then status.Text="Select existing name and unused new name";return end
  all[rename]=all[selected];all[selected]=nil;selected=rename;name=rename
  ctx.prefs().savedPositions=P.encode(all);ctx.save();status.Text="Renamed"
 end)
 Ui.button(hub,card,"Delete Position",{order=6},function()
  local all=P.decode(ctx.prefs().savedPositions);all[selected]=nil;ctx.prefs().savedPositions=P.encode(all);ctx.save();status.Text="Deleted if present"
 end)
 local list=Ui.text(card,"",{order=9})
 ctx.onRefresh("teleports","saved coordinates",function()
  local rows={};for n,p in pairs(P.decode(ctx.prefs().savedPositions)) do table.insert(rows,n.." · "..P.expression(p).." · place "..p.place) end
  table.sort(rows);Ui.set(list,"Text",#rows>0 and table.concat(rows,"\n") or "No saved positions")
 end)
end
