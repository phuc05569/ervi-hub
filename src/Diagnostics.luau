-- User-triggered bounded data export for live debugging; never executes input.
local Game=require("Game")
local Schema=require("FeatureSchema")
local Http=game:GetService("HttpService")
local JsonText=require("JsonText")
return function(ctx,features)
 local api={status="Diagnostics ready",file="Ervi_Hub_diagnostics.json"}
 local function bounds(node)
  local p,s=node.AbsolutePosition,node.AbsoluteSize
  local r={x=p.X,y=p.Y,w=s.X,h=s.Y};local visible=true;local ancestor=node
  while ancestor do
   if ancestor:IsA("GuiObject") then
    if not ancestor.Visible or (ancestor:IsA("CanvasGroup") and ancestor.GroupTransparency>=0.999) then visible=false end
    if ancestor~=node and ancestor.ClipsDescendants then
     local a,b=ancestor.AbsolutePosition,ancestor.AbsoluteSize
     local right,bottom=math.min(r.x+r.w,a.X+b.X),math.min(r.y+r.h,a.Y+b.Y)
     r.x,r.y=math.max(r.x,a.X),math.max(r.y,a.Y);r.w,r.h=math.max(0,right-r.x),math.max(0,bottom-r.y)
    end
   elseif ancestor:IsA("ScreenGui") and not ancestor.Enabled then visible=false end
   ancestor=ancestor.Parent
  end
  local inset=game:GetService("GuiService"):GetGuiInset();r.x+=inset.X;r.y+=inset.Y
  return r,visible and r.w>0 and r.h>0
 end
 function api.snapshot()
  local cam=workspace.CurrentCamera;local p=ctx.prefs()
  local result={build=ctx.build.id,placeId=game.PlaceId,universeId=game.GameId,controls={},settings={},features={},guis={},metrics={fps=ctx.metrics.fps,ping=ctx.metrics.ping}}
  result.viewport=cam and {w=cam.ViewportSize.X,h=cam.ViewportSize.Y} or nil
  local mouse=game:GetService("UserInputService"):GetMouseLocation()
  local inset=game:GetService("GuiService"):GetGuiInset()
  result.pointer={x=mouse.X,y=mouse.Y,insetX=inset.X,insetY=inset.Y,hits={}}
  for i,hit in ipairs(ctx.parent:GetGuiObjectsAtPosition(mouse.X-inset.X,mouse.Y-inset.Y)) do
   if i>12 then break end
   local top=hit;while top.Parent and top.Parent~=ctx.parent do top=top.Parent end
   table.insert(result.pointer.hits,{name=hit.Name,kind=hit.ClassName,root=top.Name,order=top:IsA("ScreenGui") and top.DisplayOrder or nil,active=hit.Active})
  end
  local char=Game.player.Character;local root=char and char:FindFirstChild("HumanoidRootPart")
  result.rootAnchored=root and root.Anchored or false
  for _,d in ipairs(Schema) do result.settings[d.key]=p[d.key] end
  for _,key in ipairs({"toggleKey","opacity","scale","textScale","winW","winH","statusX","statusY"}) do result.settings[key]=p[key] end
  for name,feature in pairs(features) do result.features[name]={active=feature.active,status=feature.status} end
  local important,other={},{}
  for _,gui in ipairs(ctx.parent:GetChildren()) do
   if gui.Name=="RNG_RollAttacks_Hub" or gui.Name=="RNG_Hub_M1HUD" or gui.Name:match("^Ervi_") then
    local state={enabled=gui.Enabled}
    local window=gui:FindFirstChild("ErviWindow") or gui:FindFirstChild("ErviStatusPill")
    if window then
     state.visible=window.Visible;state.rect=bounds(window);state.backgroundTransparency=window.BackgroundTransparency
     local mark=window:FindFirstChild("ErviOfficialLogo",true)
     if mark then state.logo={w=mark.AbsoluteSize.X,h=mark.AbsoluteSize.Y,descendants=#mark:GetDescendants()} end
    end
    result.guis[gui.Name]=state
    for _,node in ipairs(gui:GetDescendants()) do
     if #important+#other>=2000 then break end
     if node:IsA("GuiButton") or node:IsA("TextBox") or node:GetAttribute("SettingKey") then
      local rect,visible=bounds(node)
      local names={};local part=node;local setting
      while part and part~=gui do table.insert(names,1,part.Name);setting=setting or part:GetAttribute("SettingKey");part=part.Parent end
      local entry={name=node.Name,path=gui.Name.."/"..table.concat(names,"/"),setting=setting,text=node:IsA("GuiButton") and node.Text:sub(1,100) or nil,kind=node.ClassName,rect=rect,visible=visible,value=node:GetAttribute("Value")}
      if node.Name=="MinimizeButton" then result.minimizeTextBytes={node.Text:byte(1,12)} end
      local priority=setting or node.Name:match("^Nav_") or node.Name=="SettingsSearch" or node.Name=="MinimizeButton" or node.Name=="CloseButton" or node.Name=="Input_customN" or node.Name=="ExportDiagnostics"
      table.insert(priority and important or other,entry)
     end
    end
   end
  end
  for _,list in ipairs({important,other}) do for _,entry in ipairs(list) do if #result.controls<300 then table.insert(result.controls,entry) end end end
  return result
 end
 function api.export()
  local ok,value=pcall(function()
   local text=JsonText.ascii(Http:JSONEncode(api.snapshot()))
   assert(#text<=262144,"Diagnostic export exceeded its limit")
   if type(writefile)=="function" then writefile(api.file,text);return "Saved "..api.file end
   assert(Game.copy(text),"No file or clipboard export available");return "Diagnostics copied"
  end)
  api.status=ok and value or "Diagnostic export failed: "..tostring(value)
  return ok
 end
 return api
end
