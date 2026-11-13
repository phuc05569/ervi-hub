-- Instant proximity prompts: when Roblox shows you a prompt (or you start holding one), set its
-- HoldDuration to 0 and keep it there. Turning the feature off restores every prompt it changed.
-- Event-driven via ProximityPromptService - no workspace-wide scan or DescendantAdded listener.
local ProximityPromptService = game:GetService("ProximityPromptService")

return function(hubScope, log)
	local p = { enabled = false, changed = 0 }
	local scope, originals

	local function apply(prompt)
		if not originals or originals[prompt] ~= nil or not prompt:IsA("ProximityPrompt") then
			return
		end
		originals[prompt] = prompt.HoldDuration
		prompt.HoldDuration = 0
		p.changed += 1
		scope:connect(prompt:GetPropertyChangedSignal("HoldDuration"), function()
			if prompt.HoldDuration ~= 0 then
				originals[prompt] = prompt.HoldDuration -- the game's newest intended value
				prompt.HoldDuration = 0
			end
		end)
	end

	function p.set(on)
		if on == p.enabled then
			return
		end
		p.enabled = on
		if on then
			scope = hubScope:child("instant-prompts")
			originals = setmetatable({}, { __mode = "k" })
			scope:connect(ProximityPromptService.PromptShown, apply)
			scope:connect(ProximityPromptService.PromptButtonHoldBegan, apply)
			log("Prompts", "instant prompts on")
			return
		end
		scope:close() -- stop re-zeroing first, then restore
		scope = nil
		local restored = 0
		for prompt, hold in pairs(originals) do
			if prompt.Parent and pcall(function()
				prompt.HoldDuration = hold
			end) then
				restored += 1
			end
		end
		originals = nil
		log("Prompts", ("instant prompts off, %d restored"):format(restored))
	end

	return p
end
