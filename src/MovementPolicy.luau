-- Data-only protocol validation. Server repeats every trust-boundary check.
local Policy={protocol="ErviStudioMovementV1",maxSpeed=120}
local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
local function vector(v)
 if type(v)~="table" then return false end
 for i=1,3 do if not finite(v[i]) or math.abs(v[i])>1.001 then return false end end
 return v[1]^2+v[2]^2+v[3]^2<=1.002001
end
function Policy.authorized(studio,approved,place,universe,protocol)
 return studio==true and approved==true and place==0 and universe==0 and protocol==Policy.protocol
end
function Policy.state(s)
 return type(s)=="table" and type(s.fly)=="boolean" and type(s.noclip)=="boolean" and finite(s.speed) and s.speed>=5 and s.speed<=Policy.maxSpeed
end
function Policy.control(direction,look)
 return vector(direction) and vector(look) and math.abs(look[2])<0.01 and look[1]^2+look[3]^2>=0.1
end
return Policy
