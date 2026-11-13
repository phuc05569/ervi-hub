-- One source for persistent feature settings, validation and registered controls.
local S = {}
local function add(key,page,section,title,kind,default,options,description)
 local d={key=key,page=page,section=section,title=title,kind=kind,default=default,description=description or ""}
 if kind=="number" then d.min,d.max,d.step=options[1],options[2],options[3] else d.options=options end
 table.insert(S,d)
end
add("movementPanel","player","Movement","Movement Panel","bool",false)
add("clickTPEnabled","teleports","Click TP","Click TP preview","bool",false,nil,"Targeting preview only. No permitted server teleport mechanism is established.")
add("clickTPKey","teleports","Click TP","Click TP hold key","key","NONE")
add("clickTPSize","teleports","Click TP","Target Circle Size","number",4,{1,20,0.5})
add("clickTPOpacity","teleports","Click TP","Target Circle Opacity","number",0.65,{0,1,0.05})
add("clickTPColor","teleports","Click TP","Target Circle Color","color","#F0628E")
add("movementSize","player","Movement","Panel Size","number",1,{0.8,1.5,0.05},"Scales the saved panel dimensions; the corner grip still resizes it.")
for _,d in ipairs({{"walkEnabled","WalkSpeed","bool",false},{"walkKey","WalkSpeed key","key","NONE"},{"speedMode","Speed Mode","choice","Multiply",{"Set","Multiply"}},{"walkSpeed","Walk Speed","number",16,{0,100,1}},{"speedMultiplier","Speed Multiplier","number",1.5,{0.25,4,0.05}}}) do add(d[1],"player","Speed",d[2],d[3],d[4],d[5],"Local Humanoid speed; no CFrame fallback or correction-fighting loop.") end
for _,d in ipairs({{"fullbright","Fullbright"},{"noFog","No Fog"},{"noShadows","No Shadows"},{"customTime","Custom Time"}}) do add(d[1],"world","Lighting",d[2],"bool",false) end
add("timeOfDay","world","Lighting","Time of Day","number",12,{0,24,0.25})
add("notificationsEnabled","settings","Notifications","Notifications","bool",true)
add("notificationDuration","settings","Notifications","Notification Duration","number",3,{1,8,0.5})
add("customN","roll","Stop Conditions","Custom N","number",500,{1,5000,1})
add("statusOpacity","settings","Status Bar","Status Bar Opacity","number",0.7,{0,1,0.05},"Opacity of the minimized status bar background.")
add("backgroundBlur","settings","Interface","Background Blur","bool",false)
add("reduceAnimations","settings","Motion","Reduce Animations","bool",false,nil,"Apply visual changes immediately without changing feature behavior.")
add("animationSpeed","settings","Motion","Animation Speed","number",1,{0.5,2,0.1},"Controls transition speed; features always respond immediately.")
add("searchKey","settings","Interface","Search shortcut key","key","K",nil,"Hold Ctrl + this key to focus global search.")
add("panicKey","settings","Interface","Panic key","key","End",nil,"Unload and restore owned state; ignored while typing.")
add("language","settings","Interface","Language","choice","EN",{"EN","RU"},"English/Russian interface labels. Player names, game values and diagnostic evidence remain verbatim.")
add("fpsCap","utility","Rendering","FPS Cap","number",0,{0,999,1},"0 leaves the existing cap unchanged. Positive values require both getfpscap and setfpscap, so the previous value can be restored.")
add("espEnabled","visuals","General","Enabled","bool",false,nil,"Visible players only; hidden players are not rendered.")
add("espKey","visuals","General","Visualization key","key","NONE")
add("boxStyle","visuals","Player Overlays","Box Style","choice","Corners",{"Box","Corners","None"})
for _,d in ipairs({{"healthBar","HealthBar",true},{"espNames","Names",true},{"espDistance","Distance",true},{"skeleton","Skeleton",false},{"headDot","Head Dot",false},{"chams","Chams",false},{"chamsEnemies","Chams: Enemies Only",true}}) do add(d[1],"visuals","Player Overlays",d[2],"bool",d[3]) end
add("chamsFill","visuals","Appearance","Chams Fill","number",0.6,{0,1,0.05},"1 hides the fill; uses Occluded depth mode.")
add("chamsOutline","visuals","Appearance","Chams Outline","number",0,{0,1,0.05})
add("tracers","visuals","Tracers","Tracers Enabled","bool",false)
add("tracerOrigin","visuals","Tracers","Origin","choice","Bottom",{"Bottom","Middle","Top"})
add("offscreenArrows","visuals","Tracers","Off-screen Arrows","bool",false,nil,"Only for unobstructed targets within the distance and target budgets.")
for _,d in ipairs({{"teamCheck","Team Check",true},{"showTeammates","Show Teammates",false},{"markFriends","Mark Friends",false}}) do add(d[1],"visuals","Filters",d[2],"bool",d[3]) end
for _,d in ipairs({{"enemyColor","Enemy","#F0628E"},{"teamColor","Team","#40C492"},{"friendColor","Friend","#70AFFF"},{"wallColor","Behind Wall (preview only)","#9294A3"}}) do add(d[1],"visuals","Appearance",d[2],"color",d[3],nil,"Hidden targets are never drawn; Behind Wall is used only in the sample preview.") end
add("updateRate","visuals","Performance","Update Rate","choice","Auto",{"Auto","10","20","30"})
add("cheapBoxes","visuals","Performance","Cheap Boxes","bool",true,nil,"2 projections from root/head instead of 8 bounding-box corners.")
for _,d in ipairs({{"maxTargets","Max Targets",24,1,48,1},{"skeletonBudget","Skeleton Budget",8,0,16,1},{"fullRateTargets","FullRate Targets",12,1,24,1},{"farTargetRate","Far Target Rate",2,1,6,1},{"maxDistance","Max Distance",1000,50,3000,50},{"espTextSize","Text Size",13,9,22,1},{"verticalOffset","Vertical Offset",0,-100,100,1}}) do add(d[1],"visuals",(d[1]=="espTextSize" or d[1]=="verticalOffset") and "Appearance" or "Performance",d[2],"number",d[3],{d[4],d[5],d[6]}) end
add("previewOccluded","visuals","Preview","Preview hidden target","bool",false,nil,"Sample only: demonstrates that live hidden targets are suppressed.")
return S
