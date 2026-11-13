-- Owner-authorized UI-only acceptance in the actual client. No attack or movement requests.
assert(game.PlaceId==119338513416973)
local pg=game.Players.LocalPlayer.PlayerGui
local g=assert(pg:FindFirstChild('RNG_RollAttacks_Hub'))
local win=g.ErviWindow
local report={method='Own UI callbacks in live client; not physical input',checks={},time=os.time()}
local function invoke(b)
 assert(b and b:IsA('GuiButton') and b:IsDescendantOf(pg))
 for _,c in ipairs(getconnections(b.Activated))do if c.Function then c.Function()end end
 task.wait(.03)
end
local function nav(id)invoke(g:FindFirstChild('Nav_'..id,true))end
local function label(text)
 for _,n in ipairs(g:GetDescendants())do if n:IsA('TextLabel')and n.Text==text then return n end end
end
local function step(row,target)
 for _=1,45 do
  local v=row:GetAttribute('Value');assert(type(v)=='number')
  if math.abs(v-target)<.001 then return end
  local b;for _,n in ipairs(row:GetChildren())do if n:IsA('TextButton')and n.Text==(v<target and '+' or '−')then b=n;break end end
  invoke(assert(b))
 end
 error('Slider did not reach target')
end
local originalScale,originalOpacity
local scaleRow,statusRow
local function rect()
 local p,z=win.AbsolutePosition,win.AbsoluteSize
 return {x=p.X,y=p.Y,w=z.X,h=z.Y,cx=p.X+z.X/2,cy=p.Y+z.Y/2}
end
local ok,err=xpcall(function()
 nav('settings');scaleRow=assert(label('UI Scale')).Parent
 statusRow=assert(g:FindFirstChild('Setting_statusOpacity',true))
 originalScale=scaleRow:GetAttribute('Value');originalOpacity=statusRow:GetAttribute('Value')
 report.checks.scales={}
 for _,value in ipairs({.5,.75,.85,1,1.25,1.5})do
  step(scaleRow,value);task.wait(.25)
  local r=rect();r.selected=value;table.insert(report.checks.scales,r)
 end
 step(scaleRow,originalScale)
 report.checks.statusOpacity={}
 local pill=pg.Ervi_MinimizedStatus.ErviStatusPill
 for _,value in ipairs({0,.25,.5,.75,1})do
  step(statusRow,value);invoke(g:FindFirstChild('MinimizeButton',true));task.wait(.3)
  table.insert(report.checks.statusOpacity,{value=value,transparency=pill.BackgroundTransparency,mainHidden=not win.Visible})
  invoke(pill);task.wait(.3)
 end
 step(statusRow,originalOpacity)
 nav('player')
 local filter=g:FindFirstChild('TrackerFilter',true)
 if filter then local old=filter.Text;filter.Text='__ervi_missing_player__';task.wait(.2);filter.Text=old;report.checks.trackerFilterRestored=filter.Text==old end
 nav('dash')
 report.checks.finalRect=rect()
 local b=g:FindFirstChild('ExportDiagnostics',true);invoke(b)
 local overlay=pg:FindFirstChild('Ervi_VisibleOverlays');local cores,outlines,labels=0,0,0
 if overlay then for _,n in ipairs(overlay:GetDescendants())do
  if n.Name=='SkeletonCore'and n.Visible then cores+=1 end
  if n.Name=='SkeletonOutline'and n.Visible then outlines+=1 end
  if n:IsA('TextLabel')and n.Visible and n.Text~=''then labels+=1 end
 end end
 report.checks.overlays={cores=cores,outlines=outlines,labels=labels,displayOrder=overlay and overlay.DisplayOrder}
end,debug.traceback)
pcall(function()if scaleRow and originalScale then step(scaleRow,originalScale)end;if statusRow and originalOpacity then step(statusRow,originalOpacity)end end)
report.completed=ok;report.error=not ok and tostring(err)or nil
writefile('Ervi_FinalAcceptance_Suite.json',game.HttpService:JSONEncode(report))
