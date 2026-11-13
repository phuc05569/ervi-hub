local Ui=require("Ui")
local Scope=require("Scope")
local Source=require("ImageSource")
return function(hub,parent,getPrefs)
 local api={status="Background image off"}
 local image=hub:add(Ui.new("ImageLabel",{Name="ErviBackgroundImage",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=0,Active=false,Interactable=false,Visible=false,ScaleType=Enum.ScaleType.Crop,Parent=parent}));Ui.corner(image,16)
 image:SetAttribute("FixedBackground",true)
 local last,owner
 function api.apply()
  local p=getPrefs();image.ImageTransparency=1-p.backgroundImageOpacity*p.opacity
  if p.backgroundImage==last then return end
  last=p.backgroundImage
  if owner then owner:close() end
  owner=Scope.new("background-load");image.Visible=false
  local source,reason=Source.normalize(last)
  if not source then api.status=reason;return end
  if source=="" then api.status="Background image off";return end
  local request=owner;api.status="Loading Roblox image"
  image.Image=source
  local pending=true
  owner:add(task.delay(3,function() if pending and owner==request then pending=false;api.status="Image load timed out · default background retained";request:close() end end))
  owner:add(task.spawn(function()
   local loaded=false
   local ok=pcall(function() game:GetService("ContentProvider"):PreloadAsync({image},function(_,status) loaded=status==Enum.AssetFetchStatus.Success end) end)
   if hub.closed or request.closed or owner~=request or not pending then return end
   pending=false;image.Visible=ok and loaded
   api.status=image.Visible and "Roblox image loaded" or "Image unavailable · default background retained"
  end))
 end
 hub:add(function() if owner then owner:close() end end)
 return api
end
