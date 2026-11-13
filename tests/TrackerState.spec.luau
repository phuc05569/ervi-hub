local Tracker=require("TrackerState")
return {
 {"sorts distances with missing characters last and stable name ties",function(check,eq)
  local rows={{id=3,name="Zoe",distance=nil},{id=2,name="Bob",distance=20},{id=1,name="Ann",distance=20},{id=4,name="Dan",distance=5}}
  Tracker.sort(rows,"Distance");eq(rows[1].id,4);eq(rows[2].id,1);eq(rows[4].id,3)
  Tracker.sort(rows,"Name");eq(rows[1].name,"Ann");eq(rows[4].name,"Zoe")
 end},
 {"data filtering is case insensitive and does not interpret patterns",function(check)
  check(Tracker.matches({name="Player[1]",display="Other"},"[1]"))
  check(Tracker.matches({name="abc",display="Some Name"},"SOME"))
  check(not Tracker.matches({name="abc",display="Other"},"."))
 end},
 {"health state handles death, missing humanoids and invalid values",function(check,eq)
  local s=Tracker.health(50,100);eq(s.alive,true);eq(s.fraction,0.5)
  s=Tracker.health(0,100);eq(s.alive,false);eq(s.text,"Dead")
  s=Tracker.health(nil,100);eq(s.text,"Waiting for character")
  s=Tracker.health(0/0,100);eq(s.fraction,0)
  s=Tracker.health(200,100);eq(s.fraction,1)
 end},
}
