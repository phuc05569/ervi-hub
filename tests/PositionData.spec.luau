local P=require("PositionData")
local E=require("EmergencyState")
return {
 {"position round trip is bounded and place scoped",function(check,eq)
  local a=P.point(123,1.25,-16.3,7.82);local decoded=P.decode(P.encode({A=a,B=P.point(456,0,0,0)}))
  eq(decoded.A.place,123);eq(decoded.A.y,-16.3);eq(P.expression(a),"Vector3.new(1.25, -16.3, 7.82)")
  eq(next(P.decode("A,1,nan,0,0")),nil);eq(P.point(1,0/0,0,0),nil);check(not P.name("a;code"))
 end},
 {"emergency triggers once per recovery cycle, inclusive threshold",function(check)
  local e=E.new();check(not e:evaluate(true,false,20,100,30));check(e:evaluate(true,true,30,100,30))
  check(not e:evaluate(true,true,10,100,30));check(not e:evaluate(false,true,10,100,30));check(not e:evaluate(true,true,10,100,30))
  check(not e:evaluate(true,true,40,100,30));check(e:evaluate(true,true,20,100,30))
  e:reset();check(not e:evaluate(true,true,0,100,30));check(e:evaluate(true,true,10,100,30))
 end},
}
