local Registry=require("Registry")
local Overrides=require("PropertyOverrides")
local Policy=require("VisualPolicy")
local Settings=require("Settings")
local Schema=require("FeatureSchema")
local Locale=require("Locale")
local Boot=require("BootLog")
return {
 {"through-wall mode admits replicated occluded targets and still respects filters",function(check)
  local p=Settings.defaults();local c={alive=true,clearLine=false,distance=20,sameTeam=false}
  check(Policy.eligible(p,c));p.throughWalls=false;check(not Policy.eligible(p,c))
  p.throughWalls=true;c.alive=false;check(not Policy.eligible(p,c));c.alive=true;c.distance=99999;check(not Policy.eligible(p,c))
 end},
 {"tracers default white and skeleton core defaults one pixel",function(_,eq)
  local p=Settings.defaults();eq(p.tracerColor,"#FFFFFF");eq(p.skeletonThickness,1)
  local c=Settings.parse("[A]\ntracerColor=#12AB34\nskeletonThickness=0.5\n",{}).configs.A
  eq(c.tracerColor,"#12AB34");eq(c.skeletonThickness,0.5)
 end},
 {"Auto targets 60Hz and manual rates remain explicit",function(_,eq)
  eq(Policy.rate("Auto"),60)
  for _,v in ipairs({10,20,30,60}) do eq(Policy.rate(tostring(v)),v) end
 end},
 {"default chams white preserves custom relation colors",function(_,eq)
  local p=Settings.defaults();eq(Policy.chamsColor(p,{}),"#FFFFFF")
  p.enemyColor="#112233";eq(Policy.chamsColor(p,{}),"#112233")
 end},
 {"new speed defaults to Multiply and explicit saved mode is retained",function(_,eq)
  eq(Settings.defaults().speedMode,"Multiply")
  eq(Settings.parse("[A]\nspeedMode=Set\n",{}).configs.A.speedMode,"Set")
  eq(Settings.parse("[A]\nfreecam=true\nfreecamSpeed=8\n",{}).configs.A.freecam,nil)
 end},
 {"status bar position precision persists",function(_,eq)
  local s=Settings.newStore();local p=Settings.defaults();p.statusX=0.123456;p.statusY=0.654321;Settings.put(s,"A",p)
  local r=Settings.parse(Settings.serialize(s),{}).configs.A;eq(r.statusX,p.statusX);eq(r.statusY,p.statusY)
 end},
 {"normalized native property writes retain restoration and guard self events",function(check,eq)
  local value=1;local o=Overrides.new()
  local object=setmetatable({}, {__index=function() return value end,__newindex=function(_,_,v)
   local entry=o.entries.v;if entry then check(entry.writing,"self write must be marked") end
   value=math.floor(v+0.5)
  end})
  o:set("v",object,"Value",9.9);eq(o.entries.v.written,10);o:close();eq(value,1)
 end},
 {"boot report retains actual current and previous stages",function(check)
  local stored="prior crash stage";local clock=0
  local boot=Boot.new("test",function() return clock end,function() return stored end,function(_,text) stored=text end)
  clock=1;boot.step("Camera initialized")
  check(boot.text():find("Camera initialized",1,true));check(boot.text():find("prior crash stage",1,true));check(stored:find("+1.000s",1,true))
 end},
 {"boot history is bounded and file API failures are nonfatal",function(_,eq)
  local boot=Boot.new("test",function() return 0 end,function() error("no files") end,function() error("denied") end)
  for i=1,100 do boot.step(i) end;eq(#boot.lines,80)
 end},
 {"failed override update retains original restoration",function(check,eq)
  local value=1
  local object=setmetatable({}, {__index=function() return value end,__newindex=function(_,_,v) if v==9 then error("denied") end;value=v end})
  local o=Overrides.new();o:set("v",object,"Value",2)
  check(not pcall(function() o:set("v",object,"Value",9) end))
  o:close();eq(value,1)
 end},
 {"Russian labels and case folding remain searchable",function(_,eq)
  eq(Locale.text("World","RU"),"Мир");eq(Locale.text("API evidence","RU"),"API evidence")
  local r=Registry.new();r:add("world","Fullbright","",nil);eq(#r:search("ЯРКИЙ"),1)
 end},
 {"every catalog field survives nondefault config sharing",function(_,eq)
  local p=Settings.defaults()
  for _,d in ipairs(Schema) do
   if d.kind=="bool" then p[d.key]=not d.default
   elseif d.kind=="number" then p[d.key]=d.min
   elseif d.kind=="color" then p[d.key]="#112233"
   elseif d.kind=="choice" then p[d.key]=d.options[#d.options]
   elseif d.kind=="key" then p[d.key]="NONE" end
  end
  local restored=Settings.import(Settings.export(p),{})
  for _,d in ipairs(Schema) do eq(restored[d.key],p[d.key],d.key) end
 end},
 {"search indexes real controls and all query words",function(_,eq)
  local r=Registry.new();local live={Parent={}}
  r:add("player","Walk Speed","Local humanoid override",live,"Speed")
  r:add("world","Clock","Lighting time",live,"World")
  eq(#r:search("speed humanoid"),1);eq(r:search("clock")[1].page,"world");eq(#r:search("missing"),0)
 end},
 {"search skips removed controls and handles literal pattern characters",function(_,eq)
  local r=Registry.new();r:add("settings","A [key]","",{Parent={}});r:add("world","dead","",{Parent=nil})
  eq(#r:search("[key]"),1);eq(#r:search("dead"),0);eq(#r:search(""),0)
 end},
 {"search limit and exact ranking are stable",function(_,eq)
  local r=Registry.new();r:add("a","Clock time","",nil);r:add("a","Clock","",nil);r:add("a","Clock offset","",nil)
  local result=r:search("clock",2);eq(#result,2);eq(result[1].title,"Clock")
 end},
 {"owned properties restore only their original values",function(_,eq)
  local p={Brightness=1,Other=9};local o=Overrides.new();o:set("light",p,"Brightness",2);o:set("light",p,"Brightness",3)
  o:close();eq(p.Brightness,1);eq(p.Other,9)
 end},
 {"external game changes survive restoration",function(_,eq)
  local p={WalkSpeed=16};local o=Overrides.new();o:set("speed",p,"WalkSpeed",30);p.WalkSpeed=20;o:clear("speed");eq(p.WalkSpeed,20)
 end},
 {"new object restores old property ownership",function(_,eq)
  local a={Value=false};local b={Value=true};local o=Overrides.new();o:set("v",a,"Value",true);o:set("v",b,"Value",false)
  eq(a.Value,false);o:close();eq(b.Value,true)
 end},
 {"Visible Only rejects occluded players",function(check)
  local p=Settings.defaults();p.throughWalls=false;check(not Policy.eligible(p,{alive=true,clearLine=false,distance=10,sameTeam=false}))
  check(Policy.eligible(p,{alive=true,clearLine=true,distance=10,sameTeam=false}))
 end},
 {"distance team and dead filters are explicit",function(check)
  local p=Settings.defaults();check(not Policy.eligible(p,{alive=false,clearLine=true,distance=10}))
  check(not Policy.eligible(p,{alive=true,clearLine=true,distance=99999}))
  check(not Policy.eligible(p,{alive=true,clearLine=true,distance=10,sameTeam=true}));p.showTeammates=true
  check(Policy.eligible(p,{alive=true,clearLine=true,distance=10,sameTeam=true}))
 end},
 {"near and far redraws obey budgets",function(check)
  local p=Settings.defaults();p.fullRateTargets=2;p.skeletonBudget=1;p.farTargetRate=3
  local draw,bones=Policy.budget(p,1,1);check(draw and bones)
  draw,bones=Policy.budget(p,3,1);check(not draw and not bones)
  draw=Policy.budget(p,3,3);check(draw)
 end},
 {"friend colors take priority only when enabled",function(_,eq)
  local p=Settings.defaults();eq(Policy.color(p,{friend=true,sameTeam=false}),p.enemyColor);p.markFriends=true
  eq(Policy.color(p,{friend=true,sameTeam=true}),p.friendColor)
 end},
 {"data-only config sharing round trips new controls",function(check,eq)
  local p=Settings.defaults();p.enemyColor="#123456";p.timeOfDay=18.5;p.boxStyle="None";p.walkSpeed=45
  local imported,err=Settings.import(Settings.export(p),{});check(imported,err)
  eq(imported.enemyColor,"#123456");eq(imported.timeOfDay,18.5);eq(imported.boxStyle,"None");eq(imported.walkSpeed,45)
 end},
 {"config import rejects unsupported versions huge inputs and multiple slots",function(_,eq)
  eq(Settings.import("return os.execute('bad')"),nil);eq(Settings.import("ERVI_CONFIG_V2\n[A]\n"),nil)
  eq(Settings.import(string.rep("x",65537)),nil);eq(Settings.import("ERVI_CONFIG_V1\n[A]\n[B]\n"),nil)
 end},
 {"shared setting validation rejects invalid enums colors and infinity",function(_,eq)
  local p=Settings.parse("[A]\nboxStyle=Anything\nenemyColor=not-a-color\nwalkSpeed=1e999\n",{}).configs.A
  eq(p.boxStyle,"Corners");eq(p.enemyColor,Settings.DEFAULTS.enemyColor);eq(p.walkSpeed,16)
 end},
 {"autoload per game persists and deletion removes only matching slots",function(_,eq)
  local s=Settings.newStore();Settings.put(s,"A",Settings.defaults());Settings.put(s,"B",Settings.defaults())
  s.autoloadGames["1"]="A";s.autoloadGames["2"]="B"
  local r=Settings.parse(Settings.serialize(s),{});eq(r.autoloadGames["1"],"A");eq(r.autoloadGames["2"],"B")
  Settings.delete(r,"A");eq(r.autoloadGames["1"],nil);eq(r.autoloadGames["2"],"B")
 end},
 {"catalog has unique keys valid defaults and supported pages",function(check,eq)
  local found={};local p=Settings.defaults()
  for _,d in ipairs(Schema) do check(not found[d.key],d.key);found[d.key]=true;eq(p[d.key],d.default)
   if d.kind=="number" then check(d.min<=d.default and d.default<=d.max and d.step>0) end
  end
 end},
}
