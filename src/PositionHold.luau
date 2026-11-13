-- Transactional local physics hold. Restores the pre-existing anchor state;
-- old falling velocity is cleared rather than replayed on release.
local Hold = {}
function Hold.acquire(part, zero, move)
 local originalAnchored = part.Anchored
 local released = false
 local function release()
  if released then return end
  released = true
  -- If another actor already unanchored it, leave their physics update alone.
  if part.Anchored then
   part.AssemblyLinearVelocity = zero
   part.AssemblyAngularVelocity = zero
   part.Anchored = originalAnchored
  end
 end
 local ok, err = pcall(function()
  part.Anchored = true
  part.AssemblyLinearVelocity = zero
  part.AssemblyAngularVelocity = zero
  move()
 end)
 if not ok then
  pcall(release)
  return nil, tostring(err)
 end
 return release
end
return Hold
