local Image={}
function Image.normalize(value)
 if type(value)~="string" or #value>300 or value:find("[%c]") then return nil,"Invalid image source" end
 value=value:match("^%s*(.-)%s*$")
 if value=="" then return "" end
 local id=value:match("^(%d+)$") or value:match("^rbxassetid://(%d+)$")
  or value:match("^https://www%.roblox%.com/asset/%?id=(%d+)$")
  or value:match("^https://www%.roblox%.com/asset%?id=(%d+)$")
  or value:match("^https://assetdelivery%.roblox%.com/v1/asset/%?id=(%d+)$")
 if id and tonumber(id) and tonumber(id)>0 and #id<=18 then return "rbxassetid://"..id end
 local thumb=value:match("^rbxthumb://type=Asset&id=(%d+)&w=420&h=420$")
 if thumb and tonumber(thumb)>0 and #thumb<=18 then return value end
 return nil,"Use a Roblox image asset ID or supported rbxthumb Asset URL; arbitrary HTTPS images are unsupported"
end
return Image
