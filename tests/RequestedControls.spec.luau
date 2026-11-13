local Settings=require("Settings")
local Schema=require("FeatureSchema")
local Slider=require("SliderValue")
local Policy=require("VisualPolicy")
local TextStyle=require("VisualTextStyle")
local function field(key) for _,d in ipairs(Schema) do if d.key==key then return d end end end
return {
 {"status opacity is schema-backed, defaults valid, clamps and round trips",function(check,eq)
  local d=field("statusOpacity");check(d and d.kind=="number");eq(d.default,0.7);eq(Slider.normalize(-1,d.min,d.max,d.step,d.default),0);eq(Slider.normalize(2,d.min,d.max,d.step,d.default),1)
  local s=Settings.newStore();local p=Settings.defaults();p.statusOpacity=0.35;Settings.put(s,"A",p)
  eq(Settings.parse(Settings.serialize(s),{}).configs.A.statusOpacity,0.35)
  eq(Settings.parse("[Old]\ntoggleKey=F4\n",{}).configs.Old.statusOpacity,0.7)
 end},
 {"custom N slider and exact entry stay integer bounded and persistent",function(check,eq)
  local d=field("customN");check(d and d.kind=="number");eq(d.min,1);eq(d.max,5000)
  eq(Slider.normalize(1.7,d.min,d.max,d.step,500),2);eq(Slider.normalize(-5,d.min,d.max,d.step,500),1);eq(Slider.normalize(99999,d.min,d.max,d.step,500),5000)
  for _,raw in ipairs({"bad","1.5",""}) do local n=tonumber(raw);check(not (n and n==math.floor(n))) end
  local s=Settings.newStore();local p=Settings.defaults();p.customN=1234;Settings.put(s,"A",p);eq(Settings.parse(Settings.serialize(s),{}).configs.A.customN,1234)
  eq(Settings.parse("[Old]\nscale=1.2\n",{}).configs.Old.customN,500)
 end},
 {"supported ESP policy retains occlusion and live labels use high contrast",function(check,eq)
  local p={espNames=true,espDistance=true,maxDistance=100,maxTargets=8,visibilityMode=true}
  local target={alive=true,clearLine=true,distance=20,on=true,head={}}
  check(Policy.eligible(p,target));target.clearLine=false;check(not Policy.eligible(p,target))
  local label={};TextStyle.apply(label,"white","black")
  eq(label.TextColor3,"white");eq(label.TextStrokeColor3,"black");eq(label.TextStrokeTransparency,0)
 end},
}
