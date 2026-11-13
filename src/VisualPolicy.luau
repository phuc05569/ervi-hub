local Policy={}
function Policy.eligible(p,c)
 if not c.alive or not c.clearLine or c.distance>p.maxDistance then return false end
 if p.teamCheck and c.sameTeam and not p.showTeammates then return false end
 return true
end
function Policy.budget(p,rank,tick)
 local full=rank<=p.fullRateTargets
 return full or tick%p.farTargetRate==0,rank<=p.skeletonBudget
end
function Policy.color(p,c)
 return p.markFriends and c.friend and p.friendColor or c.sameTeam and p.teamColor or p.enemyColor
end
-- Keep legacy custom relation colors; only the former factory pink becomes white for chams.
function Policy.chamsColor(p,c)
 local tint=Policy.color(p,c)
 return tint=="#F0628E" and "#FFFFFF" or tint
end
return Policy
