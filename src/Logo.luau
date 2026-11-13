-- Owner-supplied geometric mark. Three vector polygons; native strips are static,
-- normalized geometry and have no image background/upload/custom-asset dependency.
local Logo={}
Logo.POLYGONS={{{73,0},{94,12},{10,61},{10,36}},{{71,57},{71,81},{20,111},{0,99}},{{130,78},{130,102},{65,138},{45,126}}}
local roots=setmetatable({},{__mode="k"})
local tint=Color3.new(1,1,1)
function Logo.refresh(background)
 local _,_,v=background:ToHSV()
 tint=v>0.65 and Color3.fromRGB(21,19,24) or Color3.new(1,1,1)
 for root,strips in pairs(roots) do if root.Parent then for _,strip in ipairs(strips) do strip.BackgroundColor3=tint end end end
end
function Logo.create(parent,size)
 local root=Instance.new("Frame");root.Name="ErviOfficialLogo";root.BackgroundTransparency=1;root.Size=size or UDim2.fromOffset(26,28);root.Parent=parent
 local aspect=Instance.new("UIAspectRatioConstraint");aspect.AspectRatio=130/138;aspect.Parent=root
 local strips={}
 local rows=128
 for _,polygon in ipairs(Logo.POLYGONS) do
  for row=0,rows-1 do
   local y=(row+0.5)*138/rows;local xs={}
   for i,a in ipairs(polygon) do
    local b=polygon[i%#polygon+1]
    if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then table.insert(xs,a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2])) end
   end
   table.sort(xs)
   if #xs>=2 then
    local strip=Instance.new("Frame");strip.BorderSizePixel=0;strip.BackgroundColor3=tint;strip:SetAttribute("FixedBackground",true)
    strip.Position=UDim2.fromScale(xs[1]/130,row/rows);strip.Size=UDim2.fromScale((xs[#xs]-xs[1])/130,1/rows+0.0001);strip.Parent=root
    table.insert(strips,strip)
   end
  end
 end
 roots[root]=strips;return root
end
return Logo
