local I=require("ImageSource")
return {
 {"image sources normalize without fetching or execution",function(check,eq)
  eq(I.normalize("12345"),"rbxassetid://12345");eq(I.normalize("rbxassetid://12345"),"rbxassetid://12345")
  eq(I.normalize("https://www.roblox.com/asset/?id=123"),"rbxassetid://123")
  eq(I.normalize(""),"");eq(I.normalize("https://example.com/image.png"),nil)
  eq(I.normalize("rbxassetid://0"),nil);eq(I.normalize("https://www.roblox.com.evil/asset/?id=1"),nil)
  check(I.normalize("rbxthumb://type=Asset&id=1&w=420&h=420"))
 end},
}
