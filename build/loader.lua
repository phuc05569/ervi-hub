-- Ervi Hub loader: unpublished template. Set URL after approving distribution.
local Loader = (function()
-- Transport-independent loader. Only downloads retry; compilation/execution happen once.
-- A pinned HTTPS commit URL + exact banner identifies a release; the banner is NOT a signature.
local Loader = {}

function Loader.run(api, config)
	if api.placeId ~= 119338513416973 then return nil, "Unsupported PlaceId" end
	local url, build = config.url, config.build
	if type(url) ~= "string" or type(build) ~= "string" or build == "" then
		return nil, "Loader release is not configured"
	end
	local commit, path = url:match("^https://raw%.githubusercontent%.com/[%w_.-]+/[%w_.-]+/([a-f0-9]+)/([%w_./-]+)$")
	if not commit or #commit ~= 40 then return nil, "Configure an HTTPS raw GitHub URL pinned to a full commit" end
	for part in path:gmatch("[^/]+") do
		if part == "." or part == ".." then return nil, "Release path cannot contain traversal segments" end
	end
	local registry = api.registry
	if registry.loading then return nil, "A load is already in progress" end
	if type(registry.stop) == "function" and api.currentStop() == registry.stop
		and registry.build == build and registry.url == url then
		return registry.stop, "Already running"
	end
	local previousStop = api.currentStop()
	registry.loading = true
	local ok, result = pcall(function()
		local source, reason
		for attempt = 1, 3 do
			local fetched, body = pcall(api.fetch, url)
			if fetched and type(body) == "string" and #body <= 2 * 1024 * 1024
				and body:sub(1, #("-- Ervi Hub | build " .. build .. "\n")) == "-- Ervi Hub | build " .. build .. "\n" then
				source = body
				break
			end
			reason = fetched and "Unexpected response size or release banner" or "HTTP request failed"
			if attempt < 3 then api.wait(attempt) end
		end
		if not source then error(reason .. " after 3 attempts", 0) end
		local chunk, compileError = api.compile(source, "Ervi_Hub/" .. build)
		if type(chunk) ~= "function" then error("Compilation failed: " .. tostring(compileError), 0) end
		-- The hub registers its stop handle early and owns unloading the previous hub.
		local executed, stop = pcall(chunk)
		if not executed then
			local partialStop = api.currentStop()
			if type(partialStop) == "function" and partialStop ~= previousStop then pcall(partialStop) end
			error("Hub execution failed: " .. tostring(stop), 0)
		end
		if type(stop) ~= "function" or api.currentStop() ~= stop then
			local partialStop = api.currentStop()
			if type(partialStop) == "function" and partialStop ~= previousStop then pcall(partialStop) end
			error("Hub did not register its stop handle", 0)
		end
		return stop
	end)
	registry.loading = false
	if not ok then return nil, tostring(result) end
	registry.stop, registry.build, registry.url = result, build, url
	return result, "Loaded " .. build
end

return Loader

end)()
local config = { url = "", build = "3.4.0+bc9c04ac65fb" }
local registryKey = "__ERVI_LOADER"
local registry = type(_G[registryKey]) == "table" and _G[registryKey] or {}
_G[registryKey] = registry
local stop, message = Loader.run({
 placeId = game.PlaceId, registry = registry,
 currentStop = function() return _G.RNG_HUB_STOP end,
 fetch = function(url) return game:HttpGet(url) end,
 compile = loadstring, wait = task.wait,
}, config)
if not stop then warn("[Ervi Hub loader] " .. message) end
return stop
