-- Pixel layout with normalized top-left placement; survives viewport changes.
local Geometry = {}
function Geometry.fit(saved: {w:number,h:number,x:number,y:number}, vw:number, vh:number)
 vw = math.max(1, vw - 16)
 vh = math.max(1, vh - 48)
 local w = math.clamp(saved.w, math.min(260, vw), math.min(800, vw))
 local h = math.clamp(saved.h, math.min(160, vh), math.min(600, vh))
 return { w=w, h=h, x=math.clamp(saved.x,0,1)*math.max(0,vw-w), y=math.clamp(saved.y,0,1)*math.max(0,vh-h), vw=vw, vh=vh }
end
function Geometry.move(rect, x, y)
 rect.x=math.clamp(x,0,math.max(0,rect.vw-rect.w)); rect.y=math.clamp(y,0,math.max(0,rect.vh-rect.h))
 return rect
end
function Geometry.saved(rect)
 return {w=rect.w,h=rect.h,x=rect.vw>rect.w and rect.x/(rect.vw-rect.w) or 0,y=rect.vh>rect.h and rect.y/(rect.vh-rect.h) or 0}
end
return Geometry
