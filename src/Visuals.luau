-- Native GUI overlays, strictly clear-line players only. Highlight is always Occluded.
local Scope=require("Scope")
local Game=require("Game")
local Policy=require("VisualPolicy")
local TextStyle=require("VisualTextStyle")
local Ui=require("Ui")
local Theme=require("Theme")
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Rig=require("RigSkeleton")
local Geometry=require("SkeletonGeometry")
local function color(hex) return Color3.fromHex(hex:sub(2)) end
local function line(parent)
 return Ui.new("Frame",{Name="OverlayLine",BorderSizePixel=0,BackgroundColor3=Theme.accent,AnchorPoint=Vector2.new(0.5,0.5),Visible=false,Parent=parent})
end
local function segment(frame,a,b,tint,thickness)
 local dx,dy=b.X-a.X,b.Y-a.Y
 frame.Position=UDim2.fromOffset((a.X+b.X)/2,(a.Y+b.Y)/2)
 frame.Size=UDim2.fromOffset(math.sqrt(dx*dx+dy*dy),thickness or 1)
 frame.Rotation=math.deg(math.atan2(dy,dx));frame.BackgroundColor3=tint;frame.Visible=true
end
return function(hub,parent,getPrefs,playerSource)
 local playerService=playerSource or Players
 local visuals={status="Off · visible players only",active=false,drawn=0,projections=0,rays=0}
 local scope,gui
 local records,friends={},{}
 local tracked,candidates,kept={},{},{}
 local params
 local lastCharacter,friendMode
 local tick,elapsed=0,0
 local renderName="ErviVisibleOverlays"
 local function closeTracked(player)
  local c=tracked[player]
  if c then if c.characterScope then c.characterScope:close() end;c.scope:close();tracked[player]=nil end
 end
 local function drop(player,leaving)
  if records[player] then records[player].scope:close();records[player]=nil end
  if leaving then friends[player]=nil end
 end
 function visuals.stop()
  visuals.active=false;visuals.drawn=0;visuals.cached=0
  if scope then scope:close();scope=nil end
  for player in pairs(records) do drop(player) end
  for player in pairs(tracked) do closeTracked(player) end
  records={};friends={};tracked={};table.clear(candidates);table.clear(kept);params=nil;lastCharacter=nil;friendMode=nil;elapsed=0;tick=0
 end
 local function project(cam,position)
  visuals.projections+=1
  local v,on=cam:WorldToViewportPoint(position)
  return Vector2.new(v.X,v.Y),on,v.Z
 end
 local function clearLine(cam,position,char,params)
  visuals.rays+=1
  local hit=workspace:Raycast(cam.CFrame.Position,position-cam.CFrame.Position,params)
  return not hit or hit.Instance:IsDescendantOf(char)
 end
 local function record(player)
  if records[player] then
   local r=records[player];r.root.Parent=gui;r.highlight.Parent=gui;return r
  end
  local owned=Scope.new("visual-player")
  local r={scope=owned,lines={},bones={},boneCache={}}
  r.root=owned:add(Ui.new("Frame",{Name="ErviPlayerOverlay",Size=UDim2.fromScale(1,1),ClipsDescendants=true,BackgroundTransparency=1,Visible=false,Parent=gui}))
  for _=1,8 do table.insert(r.lines,line(r.root)) end
  r.tracer=line(r.root);r.health=line(r.root)
  r.name=Ui.text(r.root,"",{size=UDim2.fromOffset(500,30),align=Enum.TextXAlignment.Center})
  r.name.AnchorPoint=Vector2.new(0.5,1)
  r.dot=Ui.new("Frame",{Size=UDim2.fromOffset(5,5),AnchorPoint=Vector2.new(0.5,0.5),BorderSizePixel=0,Parent=r.root});Ui.corner(r.dot,3)
  r.arrow=Ui.text(r.root,"▲",{size=UDim2.fromOffset(20,20),textSize=20});r.arrow.AnchorPoint=Vector2.new(0.5,0.5)
  r.highlight=owned:add(Ui.new("Highlight",{Name="ErviVisibleHighlight",DepthMode=Enum.HighlightDepthMode.Occluded,Enabled=false,Parent=gui}))
  records[player]=r;return r
 end
 local function update()
  local p=getPrefs();local cam=workspace.CurrentCamera
  if not cam then return end
  tick+=1;visuals.projections=0;visuals.rays=0
  if lastCharacter~=Game.player.Character then
   lastCharacter=Game.player.Character
   params.FilterDescendantsInstances=lastCharacter and {lastCharacter} or {}
  end
  table.clear(candidates)
  for player,candidate in pairs(tracked) do
   if player~=Game.player then
    local char=candidate.char
    if char and candidate.dirty then
     candidate.hum=char:FindFirstChildOfClass("Humanoid");candidate.root=char:FindFirstChild("HumanoidRootPart");candidate.head=char:FindFirstChild("Head")
     candidate.links=Rig.build(char);candidate.dirty=false
    end
    local h,root,head=candidate.hum,candidate.root,candidate.head
    if h and h.Health>0 and h.MaxHealth>0 and root and head and head.Transparency<1 and head.LocalTransparencyModifier<1 then
     local distance=(root.Position-cam.CFrame.Position).Magnitude
     local sameTeam=not Game.player.Neutral and not player.Neutral and Game.player.Team~=nil and player.Team==Game.player.Team
     if distance<=p.maxDistance and (not p.teamCheck or not sameTeam or p.showTeammates) then
      local point,on,depth=project(cam,head.Position)
      candidate.player,candidate.char,candidate.hum,candidate.root,candidate.head=player,char,h,root,head
      candidate.distance,candidate.sameTeam,candidate.friend=distance,sameTeam,friends[player]==true
      candidate.point,candidate.on,candidate.depth,candidate.alive=point,on,depth,true
      table.insert(candidates,candidate)
     end
    end
   end
  end
  table.sort(candidates,function(a,b) if a.on~=b.on then return a.on end;return a.distance<b.distance end)
  table.clear(kept);local drawn=0
  for rank,c in ipairs(candidates) do
   if drawn>=p.maxTargets then break end
   c.clearLine=clearLine(cam,c.head.Position,c.char,params)
   if Policy.eligible(p,c) and (c.on or p.offscreenArrows) then
    local r=record(c.player);kept[c.player]=true;drawn+=1
    local redraw,bones=Policy.budget(p,drawn,tick)
    if r.character~=c.char then redraw=true;r.character=c.char end
    if redraw or not r.root.Visible then
     r.root.Visible=true
     local tint=color(Policy.color(p,c));r.highlight.Enabled=false
     for _,l in ipairs(r.lines) do l.Visible=false end
     for _,l in ipairs(r.bones) do l.Visible=false end
     r.tracer.Visible=false;r.health.Visible=false;r.dot.Visible=false;r.name.Visible=false;r.arrow.Visible=false
     if not c.on then
      local vp=cam.ViewportSize;local dx,dy=c.point.X-vp.X/2,c.point.Y-vp.Y/2
      if c.depth<0 then dx,dy=-dx,-dy end
      if math.abs(dx)+math.abs(dy)<0.0001 then dy=1 end
      local factor=math.min((vp.X/2-24)/math.max(math.abs(dx),1),(vp.Y/2-24)/math.max(math.abs(dy),1))
      r.arrow.Position=UDim2.fromOffset(vp.X/2+dx*factor,vp.Y/2+dy*factor)
      r.arrow.Rotation=math.deg(math.atan2(dy,dx))+90;r.arrow.TextColor3=tint;r.arrow.Visible=true
     else
      local top=c.point
      local bottom=project(cam,c.root.Position-Vector3.new(0,3,0))
      local left,right,yTop,yBottom
      if p.cheapBoxes then
       local height=math.max(8,math.abs(bottom.Y-top.Y));left=top.X-height*0.3;right=top.X+height*0.3;yTop=top.Y-4;yBottom=bottom.Y
      else
       local cf,size=c.char:GetBoundingBox();left=math.huge;right=-math.huge;yTop=math.huge;yBottom=-math.huge
       for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
        local v,_,depth=project(cam,cf:PointToWorldSpace(Vector3.new(x*size.X/2,y*size.Y/2,z*size.Z/2)))
        if depth>0.05 then
         local vx=math.clamp(v.X,-cam.ViewportSize.X,cam.ViewportSize.X*2)
         local vy=math.clamp(v.Y,-cam.ViewportSize.Y,cam.ViewportSize.Y*2)
         left=math.min(left,vx);right=math.max(right,vx);yTop=math.min(yTop,vy);yBottom=math.max(yBottom,vy)
        end
       end end end
      end
      if left==math.huge then left=top.X-5;right=top.X+5;yTop=top.Y;yBottom=top.Y+10 end
      yTop+=p.verticalOffset;yBottom+=p.verticalOffset
      local a,b,d,e=Vector2.new(left,yTop),Vector2.new(right,yTop),Vector2.new(right,yBottom),Vector2.new(left,yBottom)
      if p.boxStyle=="Box" then
       segment(r.lines[1],a,b,tint);segment(r.lines[2],b,d,tint);segment(r.lines[3],d,e,tint);segment(r.lines[4],e,a,tint)
      elseif p.boxStyle=="Corners" then
       local w,h=(right-left)*0.25,(yBottom-yTop)*0.25
       local points={{a,Vector2.new(left+w,yTop)},{a,Vector2.new(left,yTop+h)},{b,Vector2.new(right-w,yTop)},{b,Vector2.new(right,yTop+h)},{d,Vector2.new(right-w,yBottom)},{d,Vector2.new(right,yBottom-h)},{e,Vector2.new(left+w,yBottom)},{e,Vector2.new(left,yBottom-h)}}
       for i,pair in ipairs(points) do segment(r.lines[i],pair[1],pair[2],tint) end
      end
      if p.healthBar then segment(r.health,Vector2.new(left-4,yBottom),Vector2.new(left-4,yBottom-(yBottom-yTop)*math.clamp(c.hum.Health/c.hum.MaxHealth,0,1)),Theme.good,3) end
      local texts={};if p.espNames then table.insert(texts,c.player.DisplayName~="" and c.player.DisplayName or c.player.Name) end
      if p.espDistance then table.insert(texts,("%.0f studs"):format(c.distance)) end
      r.name.Text=table.concat(texts," · ");r.name.Position=UDim2.fromOffset((left+right)/2,yTop-3);TextStyle.apply(r.name,Color3.new(1,1,1),Color3.new(0,0,0));r.name.TextSize=p.espTextSize;r.name.Size=UDim2.fromOffset(math.min(cam.ViewportSize.X,math.max(220,r.name.TextBounds.X+16)),p.espTextSize*1.5);r.name.Visible=#texts>0
      r.dot.Position=UDim2.fromOffset(top.X,top.Y+p.verticalOffset);r.dot.BackgroundColor3=tint;r.dot.Visible=p.headDot
      if p.tracers then
       local vp=cam.ViewportSize;local origin=p.tracerOrigin=="Top" and 0 or p.tracerOrigin=="Middle" and vp.Y/2 or vp.Y
       segment(r.tracer,Vector2.new(vp.X/2,origin),Vector2.new(bottom.X,bottom.Y+p.verticalOffset),tint)
      end
      if p.skeleton and bones then
       local links=c.links or {}
       while #r.bones<#links*2 do table.insert(r.bones,line(r.root)) end
       local cache=r.boneCache;table.clear(cache)
       local function point(part)
        if cache[part]~=nil then return cache[part] end
        if not part.Parent or part.Transparency>=1 or part.LocalTransparencyModifier>=1 or not clearLine(cam,part.Position,c.char,params) then cache[part]=false;return false end
        local v,_,z=project(cam,part.Position);local value={v.X,v.Y+p.verticalOffset,z};cache[part]=value;return value
       end
       local function bone(index,a,b)
        if not a or not b then return end
        local clippedA,clippedB=Geometry.clip(a,b,cam.ViewportSize.X,cam.ViewportSize.Y)
        if clippedA then segment(r.bones[index],Vector2.new(clippedA[1],clippedA[2]),Vector2.new(clippedB[1],clippedB[2]),Color3.new(1,1,1),1.5) end
       end
       for i,link in ipairs(links) do
        local a,b=point(link.a),point(link.b)
        if link.joint and link.joint.Parent and link.joint.Enabled then
         local world=link.b.CFrame:PointToWorldSpace(link.joint.C1.Position)
         if a and b and clearLine(cam,world,c.char,params) then
          local v,_,z=project(cam,world);local joint={v.X,v.Y+p.verticalOffset,z}
          bone(i*2-1,a,joint);bone(i*2,joint,b)
         end
        elseif not link.joint then bone(i*2-1,a,b) end
       end
      end
      if p.chams and (not p.chamsEnemies or not c.sameTeam) then
       r.highlight.Adornee=c.char;r.highlight.FillColor=tint;r.highlight.OutlineColor=tint
       r.highlight.FillTransparency=p.chamsFill;r.highlight.OutlineTransparency=p.chamsOutline;r.highlight.Enabled=true
      end
     end
    end
   end
  end
  local allocated=0
  for _ in pairs(records) do allocated+=1 end
  for player,r in pairs(records) do
   if not kept[player] then
    r.root.Visible=false;r.highlight.Enabled=false;r.root.Parent=nil;r.highlight.Parent=nil
    if not tracked[player] or allocated>p.maxTargets then drop(player);allocated-=1 end
   end
  end
  visuals.cached=allocated
  visuals.drawn=drawn;visuals.status=("Visible targets %d/%d · projections %d · rays %d per update"):format(drawn,p.maxTargets,visuals.projections,visuals.rays)
 end
 function visuals.apply()
  local p=getPrefs()
  if not p.espEnabled then visuals.stop();visuals.status="Off · visible players only";return end
  if visuals.active or hub.closed then return end
  local supported=pcall(function() assert(RaycastParams.new());assert(type(workspace.Raycast)=="function") end)
  if not supported then p.espEnabled=false;visuals.status="Unsupported: native raycast API unavailable";return end
  scope=Scope.new("visible-overlays");gui=scope:add(Ui.new("ScreenGui",{Name="Ervi_VisibleOverlays",IgnoreGuiInset=true,ResetOnSpawn=false,DisplayOrder=200,Parent=parent}))
  -- Friend checks are cached and performed once per player, only when explicitly requested.
  local function friend(player)
   if player==Game.player or not getPrefs().markFriends or friends[player]~=nil then return end
   friends[player]=false
   local owner=scope
   owner:add(task.spawn(function()
    local ok,value=pcall(function() return Game.player:IsFriendsWith(player.UserId) end)
    if scope==owner and not owner.closed and ok then friends[player]=value==true end
   end))
  end
  params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
  local function added(player)
   if player==Game.player or tracked[player] then return end
   local c={scope=Scope.new("visual-character-cache"),dirty=true};tracked[player]=c
   local function bind(char)
    if c.characterScope then c.characterScope:close() end
    c.characterScope=Scope.new("visual-rig");c.char=char;c.hum=nil;c.head=nil;c.root=nil;c.links=nil;c.dirty=true
    drop(player)
    if char then
     local function dirty() c.dirty=true end
     c.characterScope:connect(char.DescendantAdded,dirty);c.characterScope:connect(char.DescendantRemoving,dirty)
    end
   end
   bind(player.Character)
   c.scope:connect(player.CharacterAdded,bind);c.scope:connect(player.CharacterRemoving,function() bind(nil) end)
   friend(player)
  end
  for _,player in ipairs(playerService:GetPlayers()) do added(player) end
  scope:connect(playerService.PlayerAdded,added)
  scope:connect(playerService.PlayerRemoving,function(player) closeTracked(player);drop(player,true) end)
  Run:BindToRenderStep(renderName,Enum.RenderPriority.Camera.Value+1,function(dt)
   elapsed+=dt
   local cam=workspace.CurrentCamera
   local rate=getPrefs().updateRate=="Auto" and 30 or tonumber(getPrefs().updateRate)
   if elapsed<1/rate then return end;elapsed=math.min(elapsed-1/rate,1/rate)
   if friendMode~=getPrefs().markFriends then
    friendMode=getPrefs().markFriends
    if friendMode then for player in pairs(tracked) do friend(player) end end
   end
   local started=os.clock();local ok,err=pcall(update)
   local ms=(os.clock()-started)*1000;visuals.updates=(visuals.updates or 0)+1;visuals.totalMs=(visuals.totalMs or 0)+ms;visuals.maxMs=math.max(visuals.maxMs or 0,ms)
   visuals.effectiveRate=rate
   if not ok then visuals.stop();getPrefs().espEnabled=false;visuals.status="Rendering disabled: "..tostring(err) end
  end)
  scope:add(function() Run:UnbindFromRenderStep(renderName) end)
  visuals.active=true
 end
 hub:add(visuals.stop)
 return visuals
end
