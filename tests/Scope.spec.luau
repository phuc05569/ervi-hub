local Scope = require("Scope")

return {
	{ "closes in reverse order, exactly once", function(_, eq)
		local s, order = Scope.new("t"), {}
		s:add(function() table.insert(order, 1) end)
		s:add(function() table.insert(order, 2) end)
		s:close()
		s:close()
		eq(table.concat(order, ","), "2,1", "order")
	end },
	{ "child scope closes with parent; parent survives child close", function(check, eq)
		local s = Scope.new("parent")
		local c = s:child("child")
		local hits = 0
		c:add(function() hits += 1 end)
		c:close()
		eq(hits, 1, "child closed")
		check(not s.closed, "parent still open")
		s:close()
		eq(hits, 1, "not disposed twice")
	end },
	{ "items added after close are disposed immediately", function(_, eq)
		local s = Scope.new("t")
		s:close()
		local hits = 0
		s:add(function() hits += 1 end)
		eq(hits, 1, "disposed")
	end },
	{ "one failing cleanup does not block the rest", function(_, eq)
		local s, hits = Scope.new("t"), 0
		s:add(function() hits += 1 end)
		s:add(function() error("boom") end)
		s:close()
		eq(hits, 1, "other item still cleaned")
	end },
	{ "connection-like tables are disconnected", function(check)
		local s = Scope.new("t")
		local conn = { Connected = true }
		function conn:Disconnect() self.Connected = false end
		s:add(conn)
		s:close()
		check(conn.Connected == false)
	end },
}
