-- Scope: owns cleanup for connections, instances, threads, callbacks and child scopes.
-- close() is idempotent and disposes in reverse order; anything added after close is disposed at once.
local Scope = {}
Scope.__index = Scope

local log = warn or print

function Scope.new(name)
	return setmetatable({ name = name or "scope", items = {}, closed = false }, Scope)
end

local function dispose(item)
	local kind = typeof(item)
	if kind == "RBXScriptConnection" then
		item:Disconnect()
	elseif kind == "Instance" then
		item:Destroy()
	elseif kind == "function" then
		item()
	elseif kind == "thread" then
		if coroutine.running() == item then
			return -- a thread cannot cancel itself; it ends on its own once its scope is closed
		end
		if task then
			pcall(task.cancel, item)
		else
			pcall(coroutine.close, item)
		end
	elseif kind == "table" then
		if item.close then
			item:close()
		elseif item.Disconnect then
			item:Disconnect()
		elseif item.Destroy then
			item:Destroy()
		end
	end
end

function Scope:add(item)
	if self.closed then
		pcall(dispose, item)
		return item
	end
	table.insert(self.items, item)
	return item
end

function Scope:connect(signal, fn)
	return self:add(signal:Connect(fn))
end

function Scope:child(name)
	return self:add(Scope.new(name))
end

function Scope:close()
	if self.closed then
		return
	end
	self.closed = true
	local items = self.items
	self.items = {}
	for i = #items, 1, -1 do
		local ok, err = pcall(dispose, items[i])
		if not ok then
			log(("[Ervi Hub] cleanup error in %s: %s"):format(self.name, tostring(err)))
		end
	end
end

return Scope
