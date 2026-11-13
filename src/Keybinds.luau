-- One keyboard dispatcher; mouse combinations remain in ClickTP.
return function(scope,input,getPrefs,bindings)
 local held,signatures={},{}
 local api={}
 local function release(binding)
  if held[binding.key] and held[binding.key].mode=="Hold" then binding.set(false) end
  held[binding.key]=nil
 end
 function api.reconcile()
  local p=getPrefs()
  for _,b in ipairs(bindings) do
   local signature=tostring(p[b.key]).."/"..tostring(p[b.mode])
   if signatures[b.key] and signatures[b.key]~=signature then release(b) end
   signatures[b.key]=signature
   if p[b.mode]=="Hold" and p[b.key]~="NONE" and not held[b.key] and b.get() then b.set(false) end
  end
 end
 function api.press(name)
  local p=getPrefs()
  if name=="NONE" or name=="Unknown" then return false end
  for _,b in ipairs(bindings) do
   if p[b.key]==name then
    local mode=p[b.mode] or "Toggle"
    if mode=="Always" then return false end
    if held[b.key] then return true end
    held[b.key]={name=name,mode=mode}
    if mode=="Hold" then b.set(true) else b.set(not b.get()) end
    return true
   end
  end
  return false
 end
 scope:connect(input.InputEnded,function(event)
  if not event.KeyCode then return end
  local name=event.KeyCode.Name
  for _,b in ipairs(bindings) do local h=held[b.key];if h and h.name==name then release(b) end end
 end)
 scope:connect(input.WindowFocusReleased,function() for _,b in ipairs(bindings) do release(b) end end)
 scope:add(function() for _,b in ipairs(bindings) do release(b) end end)
 return api
end
