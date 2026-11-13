local SliderValue={}
function SliderValue.normalize(value,lo,hi,step,fallback)
 local n=tonumber(value)
 if not n or n~=n or math.abs(n)==math.huge then return fallback end
 n=math.clamp(n,lo,hi)
 return math.clamp(lo+math.floor((n-lo)/step+0.5)*step,lo,hi)
end
function SliderValue.format(value,step)
 if step>=1 then return ("%d"):format(math.floor(value+0.5)) end
 return ("%.3f"):format(value):gsub("0+$",""):gsub("%.$","")
end
return SliderValue
