local Attempt=require("MovementAttempt")
return {
 {"one movement per in-flight attempt and local evidence only",function(check,eq)
  local a=Attempt.new();local calls=0
  check(a:begin("char","dest",function() calls+=1 end));check(not a:begin("char","dest",function() calls+=1 end));eq(calls,1)
  a:step(.1,"char",true,0);check(a.busy);a:step(.71,"char",true,0)
  check(not a.busy);check(a.status:find("server/game acceptance unverified",1,true))
 end},
 {"correction and respawn cancel without retries",function(check,eq)
  local a=Attempt.new();local calls=0
  a:begin(1,2,function() calls+=1 end);a:step(.1,1,true,0);a:step(.1,1,true,20);check(not a.busy);check(a.status:find("corrected",1,true));eq(calls,1)
  a:begin(1,2,function() end);a:step(.1,2,true,0);check(not a.busy)
 end},
 {"missing movement observation and errors never report success",function(check)
  local a=Attempt.new();a:begin(1,2,function() end);a:step(1,1,true,99);check(a.status:find("not observed",1,true))
  check(not a:begin(1,2,function() error("denied") end));check(not a.busy)
 end},
}
