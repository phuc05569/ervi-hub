-- Live adapter for AutoRoll. The roll request is the same zero-argument
-- RollAttack:InvokeServer() the game's own Roll button sends (UIController doRoll),
-- issued at most once per server cooldown. Nothing is forged or replayed.
local Game = require("Game")

return function()
	local adapter = {}

	adapter.now = os.clock
	adapter.wait = task.wait
	adapter.spawn = task.spawn
	adapter.canRoll = Game.rollStatus
	adapter.alive = Game.alive
	adapter.chanceOf = Game.chanceOf
	adapter.tierOf = Game.tierOf

	function adapter.readyAt()
		return Game.attr("RollReadyAt")
	end

	function adapter.currentStyle()
		return Game.equipped()
	end

	function adapter.requestRoll()
		-- Readiness can change between the worker's poll and this call. A refusal
		-- here is known not to have reached the server, unlike a missing reply.
		local ready, why, recoverable = Game.rollStatus()
		if not ready then return {done=true,notSent=true,reason=why,recoverable=recoverable} end
		local handle = { done = false }
		local remote = Game.rollRemote()
		if not remote then
			handle.done, handle.err = true, "RollAttack RemoteFunction not found (game updated?)"
			return handle
		end
		task.spawn(function()
			local ok, name, chance = pcall(remote.InvokeServer, remote)
			if ok then
				handle.name, handle.chance = name, chance
			else
				handle.err = tostring(name)
			end
			handle.done = true
		end)
		return handle
	end

	return adapter
end
