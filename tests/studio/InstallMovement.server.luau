assert(game:GetService("RunService"):IsStudio() and game.PlaceId==0 and game.GameId==0)
local modules=game.StarterPlayer.StarterPlayerScripts:WaitForChild("ErviUIHarness")
local server=require(modules:WaitForChild("StudioMovementServer"))()
_G.ERVI_MOVEMENT_QA=server
script.Destroying:Connect(function() server.close();_G.ERVI_MOVEMENT_QA=nil end)
