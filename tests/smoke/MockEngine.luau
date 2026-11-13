-- Headless mock of the Roblox client APIs the hub touches, validated against the real API dump:
-- unknown members, unknown classes/enums and writes to read-only properties raise errors.
-- Virtual clock: task.wait/delay/spawn/cancel and Heartbeat advance only via ctl.step().
return function(API)
	local ctl = {
		clock = 0,
		conns = 0,
		errors = {},
		warnings = {},
		prints = {},
		clipboard = nil,
		invokes = 0,
		rollScript = {},
		engineWrite = false,
		files = {},
		queued = {},
		afkCaptures = 0,
		afkClicks = 0,
		teleports = 0,
		focusedTextBox = nil,
	}
	local env = {}
	local data = setmetatable({}, { __mode = "k" })
	local kinds = setmetatable({}, { __mode = "k" }) -- value -> typeof name

	local function fail(msg)
		table.insert(ctl.errors, msg)
	end

	---------------------------------------------------------------- scheduler
	local queue = {}
	local function resume(co, ...)
		local ok, err = coroutine.resume(co, ...)
		if not ok then
			fail(debug.traceback(co, tostring(err)))
		end
	end
	local task = {}
	function task.spawn(fn, ...)
		local co = type(fn) == "thread" and fn or coroutine.create(fn)
		resume(co, ...)
		return co
	end
	function task.defer(fn, ...)
		local co = type(fn) == "thread" and fn or coroutine.create(fn)
		table.insert(queue, { at = ctl.clock, co = co, args = table.pack(...) })
		return co
	end
	function task.delay(dt, fn, ...)
		local co = coroutine.create(fn)
		table.insert(queue, { at = ctl.clock + (dt or 0), co = co, args = table.pack(...) })
		return co
	end
	function task.wait(dt)
		local co = coroutine.running()
		local start = ctl.clock
		table.insert(queue, { at = ctl.clock + (dt or 0), co = co, args = table.pack() })
		coroutine.yield()
		return ctl.clock - start
	end
	function task.cancel(co)
		for i = #queue, 1, -1 do
			if queue[i].co == co then
				table.remove(queue, i)
			end
		end
		if coroutine.status(co) == "running" then
			error("cannot cancel the running thread")
		end
		coroutine.close(co)
	end
	ctl.task = task
	function ctl.pendingThreads()
		local n = 0
		for _, e in ipairs(queue) do
			if coroutine.status(e.co) == "suspended" then
				n += 1
			end
		end
		return n
	end

	---------------------------------------------------------------- signals
	local Signal = {}
	Signal.__index = Signal
	local function newSignal()
		return setmetatable({ list = {} }, Signal)
	end
	function Signal:Connect(fn)
		assert(type(fn) == "function", "Connect expects a function")
		local conn = { Connected = true }
		kinds[conn] = "RBXScriptConnection"
		ctl.conns += 1
		local list = self.list
		function conn.Disconnect(c)
			if c.Connected then
				c.Connected = false
				ctl.conns -= 1
				for i, e in ipairs(list) do
					if e.conn == c then
						table.remove(list, i)
						break
					end
				end
			end
		end
		table.insert(list, { fn = fn, conn = conn })
		return conn
	end
	function Signal:Once(fn)
		local c
		c = self:Connect(function(...)
			c:Disconnect()
			fn(...)
		end)
		return c
	end
	function Signal:Fire(...)
		for _, e in ipairs(table.clone(self.list)) do
			if e.conn.Connected then
				task.spawn(e.fn, ...)
			end
		end
	end
	function Signal:DisconnectAll()
		for _, e in ipairs(table.clone(self.list)) do
			e.conn:Disconnect()
		end
	end

	---------------------------------------------------------------- datatypes
	local function typed(kind, t, mt)
		local v = setmetatable(t, mt)
		kinds[v] = kind
		return v
	end
	local UDim = {}
	function UDim.new(s, o)
		return typed("UDim", { Scale = s or 0, Offset = o or 0 })
	end
	local UDim2 = {}
	function UDim2.new(xs, xo, ys, yo)
		return typed("UDim2", { X = UDim.new(xs, xo), Y = UDim.new(ys, yo) })
	end
	function UDim2.fromOffset(x, y)
		return UDim2.new(0, x or 0, 0, y or 0)
	end
	function UDim2.fromScale(x, y)
		return UDim2.new(x or 0, 0, y or 0, 0)
	end
	local Color3 = {}
	local C3 = {
		__index = {
			ToHex = function(c)
				local function b(x)
					return math.floor(x * 255 + 0.5)
				end
				return ("%02X%02X%02X"):format(b(c.R), b(c.G), b(c.B))
			end,
			Lerp = function(a, b, t)
				return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
			end,
		},
		__eq = function(a, b)
			return a.R == b.R and a.G == b.G and a.B == b.B
		end,
	}
	function Color3.new(r, g, b)
		return typed("Color3", { R = r or 0, G = g or 0, B = b or 0 }, C3)
	end
	function Color3.fromRGB(r, g, b)
		return Color3.new((r or 0) / 255, (g or 0) / 255, (b or 0) / 255)
	end
	function Color3.fromHex(hex)
		local r, g, b = hex:gsub("#", ""):match("^(%x%x)(%x%x)(%x%x)$")
		assert(r, "bad hex " .. tostring(hex))
		return Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
	end
	function Color3.fromHSV(h, s, v)
		local i = math.floor(h * 6) % 6
		local f = h * 6 - math.floor(h * 6)
		local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
		local rgb = ({ { v, t, p }, { q, v, p }, { p, v, t }, { p, q, v }, { t, p, v }, { v, p, q } })[i + 1]
		return Color3.new(rgb[1], rgb[2], rgb[3])
	end
	C3.__index.ToHSV = function(c)
		local mx, mn = math.max(c.R, c.G, c.B), math.min(c.R, c.G, c.B)
		local d = mx - mn
		local h = 0
		if d > 0 then
			if mx == c.R then
				h = ((c.G - c.B) / d) % 6
			elseif mx == c.G then
				h = (c.B - c.R) / d + 2
			else
				h = (c.R - c.G) / d + 4
			end
			h /= 6
		end
		return h, mx == 0 and 0 or d / mx, mx
	end
	local ColorSequence = {
		new = function(a, b)
			return typed("ColorSequence", { Keypoints = type(a) == "table" and kinds[a] == nil and a or { a, b or a } })
		end,
	}
	local ColorSequenceKeypoint = {
		new = function(t, c)
			return typed("ColorSequenceKeypoint", { Time = t, Value = c })
		end,
	}
	local NumberSequence = {
		new = function(a, b)
			return typed("NumberSequence", { Keypoints = type(a) == "table" and kinds[a] == nil and a or { a, b or a } })
		end,
	}
	local NumberSequenceKeypoint = {
		new = function(t, value, envelope)
			assert(type(t) == "number" and t >= 0 and t <= 1)
			assert(type(value) == "number" and value == value)
			return typed("NumberSequenceKeypoint", { Time = t, Value = value, Envelope = envelope or 0 })
		end,
	}
	local V2 = {}
	V2.__index = V2
	V2.__sub = function(a, b)
		return env.Vector2.new(a.X - b.X, a.Y - b.Y)
	end
	local Vector2 = {
		new = function(x, y)
			return typed("Vector2", { X = x or 0, Y = y or 0 }, V2)
		end,
	}
	env.Vector2 = Vector2
    local Vector3={}
    local V3={}
    V3.__index=function(v,key)
        if key=="Cross" then return function(a,b) return Vector3.new(a.Y*b.Z-a.Z*b.Y,a.Z*b.X-a.X*b.Z,a.X*b.Y-a.Y*b.X) end end
        if key=="Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end
        if key=="Unit" then local n=v.Magnitude;return n>0 and Vector3.new(v.X/n,v.Y/n,v.Z/n) or Vector3.new() end
    end
    V3.__add=function(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
    V3.__sub=function(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
    V3.__mul=function(a,b) if type(a)=="number" then a,b=b,a end;return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
    Vector3.new=function(x,y,z) return typed("Vector3",{X=x or 0,Y=y or 0,Z=z or 0},V3) end
    env.Vector3=Vector3


	local enumCache = {}
	local Enum = setmetatable({}, {
		__index = function(_, enumName)
			local def = API.enums[enumName]
			if not def then
				error("Enum." .. tostring(enumName) .. " does not exist", 2)
			end
			enumCache[enumName] = enumCache[enumName]
				or setmetatable({}, {
					__index = function(t, item)
						if def[item] == nil then
							error(("Enum.%s.%s does not exist"):format(enumName, tostring(item)), 2)
						end
						local tok = typed("EnumItem", { Name = item, Value = def[item], EnumType = enumName })
						rawset(t, item, tok)
						return tok
					end,
				})
			return enumCache[enumName]
		end,
	})

	---------------------------------------------------------------- instances
	local function member(class, kind, name)
		local c = class
		while c and API.classes[c] do
			local v = API.classes[c][kind][name]
			if v ~= nil then
				return v
			end
			c = API.classes[c].super
		end
		return nil
	end
	local function isA(class, target)
		local c = class
		while c and API.classes[c] do
			if c == target then
				return true
			end
			c = API.classes[c].super
		end
		return false
	end

	local DEFAULTS = { Transparency=0, LocalTransparencyModifier=0, Anchored = false, Visible = true, Text = "", Enabled = true, Health = 100, MaxHealth = 100, TextSize = 14, WalkSpeed=16, UserId=0, DisplayName="", Neutral=true }
    DEFAULTS.TextBounds=Vector2.new(0,0)
    DEFAULTS.AbsolutePosition=Vector2.new(0,0);DEFAULTS.AbsoluteSize=Vector2.new(100,30)
	local new
	local METHODS = {}
	local Proxy = {}

	local function signalOf(d, key)
		d.signals[key] = d.signals[key] or newSignal()
		return d.signals[key]
	end
	local function fireIf(d, key, ...)
		if d.signals[key] then
			d.signals[key]:Fire(...)
		end
	end

	local function walk(inst, fn)
		for _, c in ipairs(data[inst].children) do
			fn(c)
			walk(c, fn)
		end
	end

	local function setParent(self, parent)
		local d = data[self]
		local oldParent = d.parent
		if d.destroyed then
			error("The Parent property of " .. d.props.Name .. " is locked", 3)
		end
		if d.parent then
			local siblings = data[d.parent].children
			for i, c in ipairs(siblings) do
				if c == self then
					table.remove(siblings, i)
					break
				end
			end
		end
		d.parent = parent
		if oldParent and oldParent ~= parent then
			fireIf(data[oldParent], "ChildRemoved", self)
			if d.class == "Player" and data[oldParent].class == "Players" then fireIf(data[oldParent], "PlayerRemoving", self) end
		end
		if parent then
			table.insert(data[parent].children, self)
			fireIf(data[parent], "ChildAdded", self)
			if oldParent ~= parent and d.class == "Player" and data[parent].class == "Players" then fireIf(data[parent], "PlayerAdded", self) end
			local a = parent
			while a do
				local ad = data[a]
				fireIf(ad, "DescendantAdded", self)
				walk(self, function(x)
					fireIf(ad, "DescendantAdded", x)
				end)
				a = ad.parent
			end
		end
		if d.propSignals.Parent then
			d.propSignals.Parent:Fire()
		end
	end

	Proxy.__index = function(self, key)
		local d = data[self]
        if key=="HttpGet" and d.class=="DataModel" then return function(_,url)
            ctl.lastHttp=url
            if ctl.httpBody then return ctl.httpBody end
            error("HTTP unavailable in mock")
        end end
		if key == "Parent" then
			return d.parent
		elseif key == "ClassName" then
			return d.class
		end
		if METHODS[key] and member(d.class, "methods", key) then
			return METHODS[key]
		end
		if member(d.class, "events", key) then
			return signalOf(d, key)
		end
		if member(d.class, "props", key) ~= nil then
            if key=="Position" and isA(d.class,"BasePart") then return d.props.CFrame and d.props.CFrame.Position or Vector3.new(0,0,0) end
			local v = d.props[key]
			if v == nil then
				v = DEFAULTS[key]
			end
			return v
		end
		for _, c in ipairs(d.children) do
			if data[c].props.Name == key then
				return c
			end
		end
		if member(d.class, "methods", key) then
			error("MOCK: method not implemented: " .. d.class .. ":" .. key, 2)
		end
		error(("%s is not a valid member of %s \"%s\""):format(tostring(key), d.class, tostring(d.props.Name)), 2)
	end
	Proxy.__newindex = function(self, key, value)
		local d = data[self]
		if key == "Parent" then
			return setParent(self, value)
		end
		local ro = member(d.class, "props", key)
		if ro == nil and type(value) == "function" and member(d.class, "methods", key) ~= nil then
			d.props[key] = value -- callback member such as BindableFunction.OnInvoke
			return
		end
		if ro == nil then
			error(("%s is not a valid member of %s"):format(tostring(key), d.class), 2)
		end
		if ro and not ctl.engineWrite then
			error(("Unable to assign read-only property %s.%s"):format(d.class, key), 2)
		end
		local old = d.props[key]
		d.props[key] = value
		if old ~= value and d.propSignals[key] then
			d.propSignals[key]:Fire()
		end
	end
	Proxy.__tostring = function(self)
		return data[self].props.Name
	end

	new = function(class, parent)
		local def = API.classes[class]
		if not def then
			error("Unable to create an Instance of type \"" .. tostring(class) .. "\"", 2)
		end
		local inst = setmetatable({}, Proxy)
		data[inst] = { class = class, props = { Name = class }, children = {}, attrs = {}, signals = {}, propSignals = {}, attrSignals = {} }
		kinds[inst] = "Instance"
		if parent then
			inst.Parent = parent
		end
		return inst
	end
	ctl.new = new

	function METHODS.Destroy(self)
		local d = data[self]
		if d.destroyed then
			return
		end
		for _, c in ipairs(table.clone(d.children)) do
			c:Destroy()
		end
		if d.parent then
			setParent(self, nil)
		end
		d.destroyed = true
		for _, s in pairs(d.signals) do
			s:DisconnectAll()
		end
		for _, s in pairs(d.propSignals) do
			s:DisconnectAll()
		end
		for _, s in pairs(d.attrSignals) do
			s:DisconnectAll()
		end
	end
	function METHODS.FindFirstChild(self, name, recursive)
		for _, c in ipairs(data[self].children) do
			if data[c].props.Name == name then
				return c
			end
		end
		if recursive then for _,c in ipairs(data[self].children) do local hit=METHODS.FindFirstChild(c,name,true);if hit then return hit end end end
		return nil
	end
	function METHODS.WaitForChild(self, name)
		local c = self:FindFirstChild(name)
		if not c then
			error("MOCK: WaitForChild would hang on " .. name)
		end
		return c
	end
	function METHODS.FindFirstChildOfClass(self, class)
		for _, c in ipairs(data[self].children) do
			if data[c].class == class then
				return c
			end
		end
		return nil
	end
	function METHODS.GetChildren(self)
		return table.clone(data[self].children)
	end
	function METHODS.GetDescendants(self)
		local out = {}
		walk(self, function(x)
			table.insert(out, x)
		end)
		return out
	end
	function METHODS.IsA(self, class)
		return isA(data[self].class, class)
	end
	function METHODS.IsDescendantOf(self, anc)
		local p = data[self].parent
		while p do
			if p == anc then
				return true
			end
			p = data[p].parent
		end
		return false
	end
	function METHODS.GetAttribute(self, name)
		return data[self].attrs[name]
	end
	function METHODS.GetAttributes(self)
		return table.clone(data[self].attrs)
	end
	function METHODS.SetAttribute(self, name, value)
		local d = data[self]
		local old = d.attrs[name]
		d.attrs[name] = value
		if old ~= value then
			fireIf(d, "AttributeChanged", name)
			if d.attrSignals[name] then
				d.attrSignals[name]:Fire()
			end
		end
	end
	function METHODS.GetPropertyChangedSignal(self, prop)
		local d = data[self]
		if member(d.class, "props", prop) == nil then
			error(prop .. " is not a valid property name.", 2)
		end
		d.propSignals[prop] = d.propSignals[prop] or newSignal()
		return d.propSignals[prop]
	end
	function METHODS.GetAttributeChangedSignal(self, name)
		local d = data[self]
		d.attrSignals[name] = d.attrSignals[name] or newSignal()
		return d.attrSignals[name]
	end
	local services = {}
	function METHODS.GetService(_, name)
		if not services[name] then
			error("MOCK: service not provided: " .. tostring(name), 2)
		end
		return services[name]
	end
	function METHODS.CaptureController()
		ctl.afkCaptures += 1
	end
	function METHODS.ClickButton2()
		ctl.afkClicks += 1
	end
	function METHODS.GetErrorCode()
		return Enum.ConnectionError[ctl.errorName or "OK"]
	end
	function METHODS.Teleport()
		ctl.teleports += 1
	end
	function METHODS.IsLoaded()
		return true
	end
	function METHODS.GetFocusedTextBox()
		return ctl.focusedTextBox
	end
	function METHODS.IsKeyDown(_,key) return ctl.keysDown and ctl.keysDown[key.Name]==true or false end
    function METHODS.CaptureFocus(self) ctl.focusedTextBox=self;self.Focused:Fire() end
    function METHODS.ReleaseFocus(self) if ctl.focusedTextBox==self then ctl.focusedTextBox=nil end end
    function METHODS.BindActionAtPriority(_,name,fn) ctl.boundActions=ctl.boundActions or {};ctl.boundActions[name]=fn end
    function METHODS.UnbindAction(_,name) if ctl.boundActions then ctl.boundActions[name]=nil end end
    function METHODS.TeleportToPlaceInstance(_,place,job) ctl.teleports+=1;ctl.lastJob=job end
	function METHODS.GetNetworkPing()
		return 0.042
	end
	function METHODS.GetPlayers(self)
		local out={}
		for _,child in ipairs(self:GetChildren()) do if child:IsA("Player") then table.insert(out,child) end end
		return out
	end
	function ctl.cframe(...)
        local values=table.pack(...)
        return setmetatable({GetComponents=function() return table.unpack(values,1,values.n) end}, {
            __index=function(_,key)
                if key=="Position" then return Vector3.new(values[1],values[2],values[3]) end
                if key=="ToOrientation" then return function() return 0,0,0 end end
                if key=="VectorToWorldSpace" then return function(_,v)
                    return Vector3.new(values[4]*v.X+values[5]*v.Y+values[6]*v.Z,values[7]*v.X+values[8]*v.Y+values[9]*v.Z,values[10]*v.X+values[11]*v.Y+values[12]*v.Z)
                end end
                if key=="PointToWorldSpace" then return function(cf,v) return cf.Position+cf:VectorToWorldSpace(v) end end
            end,
            __add=function(_,delta)
                local copy=table.clone(values);copy[1]+=delta.X;copy[2]+=delta.Y;copy[3]+=delta.Z
                return ctl.cframe(table.unpack(copy,1,copy.n))
            end,
            __mul=function(a,b)
                local pos=a:PointToWorldSpace(b.Position)
                local av,bv={a:GetComponents()},{b:GetComponents()};local out={pos.X,pos.Y,pos.Z}
                for r=0,2 do for c=1,3 do
                    local n=0;for k=1,3 do n+=av[3+r*3+k]*bv[3+(k-1)*3+c] end
                    table.insert(out,n)
                end end
                return ctl.cframe(table.unpack(out))
            end,
        })
    end
    local CFrame={}
    CFrame.new=function(x,y,z)
        if type(x)=="table" then x,y,z=x.X,x.Y,x.Z end
        return ctl.cframe(x or 0,y or 0,z or 0,1,0,0,0,1,0,0,0,1)
    end
    CFrame.fromOrientation=function(pitch,yaw,roll)
        local cp,sp,cy,sy=math.cos(pitch),math.sin(pitch),math.cos(yaw),math.sin(yaw)
        return ctl.cframe(0,0,0,cy,0,sy,sp*sy,cp,-sp*cy,-cp*sy,sp,cp*cy)
    end
    function METHODS.GetBoundingBox(self) return self:FindFirstChild("HumanoidRootPart").CFrame,Vector3.new(4,6,2) end
    function METHODS.WorldToViewportPoint(self,position)
        local delta=position-self.CFrame.Position
        local depth=-delta.Z
        local v=Vector3.new(self.ViewportSize.X/2+delta.X/math.max(0.1,depth)*400,self.ViewportSize.Y/2-delta.Y/math.max(0.1,depth)*400,depth)
        return v,depth>0 and v.X>=0 and v.X<=self.ViewportSize.X and v.Y>=0 and v.Y<=self.ViewportSize.Y
    end
    function METHODS.GetMouseLocation() return Vector2.new(400,300) end
    function METHODS.GetGuiInset() return Vector2.new(0,58),Vector2.new() end
    -- Mouse button state for drag gestures; ctl.mouseDown=false simulates a release the game never saw.
    function METHODS.IsMouseButtonPressed() return ctl.mouseDown ~= false end
    function METHODS.Invoke(self, ...)
        local callback = data[self].props.OnInvoke
        if not callback then error("OnInvoke is not set", 2) end
        return callback(...)
    end
    -- Image preload result for UiImages: ctl.assetStatus "Success"/"Failure" (nil = Success).
    function METHODS.PreloadAsync(_, list, callback) for _,item in ipairs(list) do if callback then callback(item,{Name=ctl.assetStatus or "Success"}) end end end
    function METHODS.GetGuiObjectsAtPosition(self,x,y) ctl.lastGuiHitPoint={x,y};return ctl.guiHits or {} end
    function METHODS.FindFirstAncestorOfClass(self,class)
        local p=self.Parent
        while p do if p:IsA(class) then return p end;p=p.Parent end
    end
    function METHODS.ScreenPointToRay(self) return {Origin=self.CFrame.Position,Direction=Vector3.new(0,-1,0)} end
    function METHODS.ViewportPointToRay(self,x,y) ctl.lastViewportRay={x,y};return {Origin=self.CFrame.Position,Direction=Vector3.new(0,-1,0)} end
    CFrame.fromMatrix=function(p,x,y,z) return ctl.cframe(p.X,p.Y,p.Z,x.X,y.X,z.X,x.Y,y.Y,z.Y,x.Z,y.Z,z.Z) end
    function METHODS.Raycast(self,origin,direction,params)
        ctl.lastRaycastParams=params
        ctl.raycasts=(ctl.raycasts or 0)+1
        return ctl.raycastResult or (ctl.occluded and {Instance=ctl.wall} or nil)
    end
    function METHODS.IsFriendsWith(_,id) return ctl.friendIds and ctl.friendIds[id]==true or false end
	function METHODS.GetPivot(self)
        return self:FindFirstChild("HumanoidRootPart").CFrame
    end
    function METHODS.PivotTo(self,cf)
        ctl.pivotCalls=(ctl.pivotCalls or 0)+1
        ctl.pivotAnchorHistory=ctl.pivotAnchorHistory or {};table.insert(ctl.pivotAnchorHistory,self:FindFirstChild("HumanoidRootPart").Anchored)
        if ctl.rejectPivot then error("Engine rejected local move") end
        self:FindFirstChild("HumanoidRootPart").CFrame=cf
    end
    function METHODS.MoveTo(self,position)
        ctl.moveToCalls=(ctl.moveToCalls or 0)+1
        local r=self:FindFirstChild("HumanoidRootPart")
        self:PivotTo(self:GetPivot()+(position-r.Position))
    end
	function METHODS.GetServerTimeNow()
		return 1000 + ctl.clock
	end
	function METHODS.JSONDecode(_, s)
        -- Structured API boundary: keep producer data for assertions; native JSON
        -- serialization is verified in Studio/live integration, not reimplemented.
        if s==ctl.httpBody and ctl.serverList then return ctl.serverList end
		error("MOCK JSONDecode: not JSON: " .. tostring(s))
	end
	function METHODS.JSONEncode(_, value) ctl.jsonEncoded=value;return "MOCK_JSON_ENCODED" end
	function METHODS.InvokeServer(self)
		ctl.invokes += 1
		local r = table.remove(ctl.rollScript, 1)
		if not r then
			fail("UNEXPECTED ROLL REQUEST #" .. ctl.invokes)
			return nil
		end
		task.wait(0.3) -- server latency
		local player = ctl.player
		player:SetAttribute("RollReadyAt", 1000 + ctl.clock + 8)
		player:SetAttribute("EquippedAttack", r[1])
		return r[1], r[2]
	end

	function ctl.set(inst, key, value)
        local prior=key=="Character" and inst.Character or nil
        if key=="Character" and prior and prior~=value then inst.CharacterRemoving:Fire(prior) end
		ctl.engineWrite = true
		inst[key] = value
		ctl.engineWrite = false
        if key=="Character" and prior~=value and value then inst.CharacterAdded:Fire(value) end
	end

	---------------------------------------------------------------- world
	local gameRoot = new("DataModel")
	ctl.set(gameRoot, "PlaceId", 119338513416973)
	ctl.set(gameRoot, "PlaceVersion", 969)
	ctl.set(gameRoot, "GameId", 10768634654)
    ctl.set(gameRoot,"JobId","mock-job-current")
	local function service(class)
		local s = new(class, gameRoot)
		services[class] = s
		return s
	end
	local Players = service("Players")
	local RunService = service("RunService")
	local UIS = service("UserInputService")
    local lighting=service("Lighting")
    lighting.Brightness=1;lighting.Ambient=Color3.fromRGB(80,80,80);lighting.OutdoorAmbient=Color3.fromRGB(90,90,90)
    lighting.FogStart=0;lighting.FogEnd=500;lighting.GlobalShadows=true;lighting.ClockTime=14
    ctl.lighting=lighting
    service("ContextActionService")
	local RS = service("ReplicatedStorage")
	service("HttpService")
	service("ContentProvider")
	service("VirtualUser")
	service("GuiService")
	service("TeleportService")
	ctl.promptService = service("ProximityPromptService")
	local coreGui = service("CoreGui")
	local promptGui = new("ScreenGui", coreGui)
	promptGui.Name = "RobloxPromptGui"
	local overlay = new("Frame", promptGui)
	overlay.Name = "promptOverlay"
	ctl.promptOverlay = overlay
	local workspace = service("Workspace")
	ctl.set(gameRoot, "Workspace", workspace)
	local cam = new("Camera", workspace)
	ctl.set(cam, "ViewportSize", Vector2.new(1920, 1080))
	ctl.set(workspace, "CurrentCamera", cam)
    cam.CFrame=CFrame.new(0,10,20);cam.CameraType=Enum.CameraType.Custom;UIS.MouseBehavior=Enum.MouseBehavior.Default
    ctl.wall=new("Part",workspace);ctl.wall.Name="Occluder"

	local player = new("Player", Players)
	player.Name = "MockUserSecret"
	ctl.set(Players, "LocalPlayer", player)
    ctl.set(player,"UserId",1);ctl.set(Players,"MaxPlayers",30)
	ctl.player = player
	local pg = new("PlayerGui", player)
	local main = new("ScreenGui", pg)
	main.Name = "MainUI"
	local reveal = new("Frame", main)
	reveal.Name = "RollRevealRoot"
	reveal.Visible = false
	local panel = new("Frame", reveal)
	panel.Name = "Panel"
	for _, n in ipairs({ "Header", "Rarity" }) do
		new("TextLabel", panel).Name = n
	end
	local rb = new("TextButton", main)
	rb.Name = "RollButton"
	new("TextLabel", rb).Name = "Label"
	local rc = new("TextLabel", main)
	rc.Name = "RollCooldown"

	local char = new("Model", workspace)
	char.Name = "MockUserSecret"
	new("Humanoid", char)
	local root = new("Part", char)
	root.Name = "HumanoidRootPart"
    root.CFrame=CFrame.new(0,0,0)
	ctl.set(player, "Character", char)
	ctl.char, ctl.root = char, root

	for k, v in pairs({ EquippedAttack = "Punch", RollReadyAt = 0, RollCooldownLen = 8, InFFA = true, Luck = 1, TraitLuck = 0.5, UnlockedAttacks = "Punch, Slap, Cyborg" }) do
		player:SetAttribute(k, v)
	end

	local adModule = new("ModuleScript", RS)
	adModule.Name = "AttackData"
	local remotes = new("Folder", RS)
	remotes.Name = "Remotes"
	new("RemoteFunction", remotes).Name = "RollAttack"
	new("RemoteEvent", remotes).Name = "ForcedRoll"

	local rgb = Color3.fromRGB
	local ATTACK_DATA = {
		List = {
			{ Name = "Punch", Chance = 3, Cooldown = 0.7, Kind = "Melee", Damage = 5, Health = 100, Speed = 16, Range = 5, Description = "A quick jab." },
			{ Name = "Slap", Chance = 5, Cooldown = 3.5, Kind = "Melee", Damage = 15 },
			{ Name = "Cyborg", Chance = 195, Cooldown = 6, Kind = "Melee" },
			{ Name = "Jackpot", Chance = 444, Cooldown = 1 },
			{ Name = "Knockback Stick", Chance = 750, Cooldown = 2 },
			{ Name = "Mythic X", Chance = 2000, RarityName = "Mythic", RarityColor = rgb(255, 0, 255) },
			{ Name = "Secret", Chance = 9999, Unreleased = true },
		},
		Tiers = {
			{ Max = 3, Name = "Common", Color = rgb(210, 210, 210) },
			{ Max = 5, Name = "Uncommon", Color = rgb(90, 225, 90) },
			{ Max = 8, Name = "Rare", Color = rgb(80, 160, 255) },
			{ Max = 12, Name = "Epic", Color = rgb(185, 95, 255) },
			{ Max = math.huge, Name = "Legendary", Color = rgb(255, 195, 40) },
		},
		RollCooldown = 8,
		MinRollCooldown = 3.5,
	}
	local function mockRequire(mod)
		if ctl.requireDelay then
			task.wait(ctl.requireDelay) -- an executor's require can yield
		end
		if mod == adModule then
			return ATTACK_DATA
		end
		error("MOCK: require of unexpected module " .. tostring(mod))
	end

	local renderBindings={}
    function METHODS.BindToRenderStep(_,name,priority,callback) renderBindings[name]={priority=priority,callback=callback} end
    function METHODS.UnbindFromRenderStep(_,name) renderBindings[name]=nil end
    ctl.renderBindings=renderBindings
	function ctl.step(dt)
		ctl.clock += dt
		RunService.Heartbeat:Fire(dt)
        RunService.RenderStepped:Fire(dt)
        for _,binding in pairs(table.clone(renderBindings)) do task.spawn(binding.callback,dt) end
		local due = {}
		for i = #queue, 1, -1 do
			if queue[i].at <= ctl.clock then
				table.insert(due, table.remove(queue, i))
			end
		end
		table.sort(due, function(a, b)
			return a.at < b.at
		end)
		for _, e in ipairs(due) do
			if coroutine.status(e.co) == "suspended" then
				resume(e.co, table.unpack(e.args, 1, e.args.n))
			end
		end
	end
	function ctl.run(seconds)
		local steps = math.floor(seconds / 0.05 + 0.5)
		for _ = 1, steps do
			ctl.step(0.05)
		end
	end
	ctl.UIS, ctl.pg = UIS, pg

	---------------------------------------------------------------- env
	local function typeofMock(v)
		return kinds[v] or typeof(v)
	end
	local G = {}
	for k, v in pairs({
		game = gameRoot,
		workspace = workspace,
		Instance = { new = function(class)
			return new(class)
		end },
		Enum = Enum,
		UDim = UDim,
		UDim2 = UDim2,
		Color3 = Color3,
		Vector2 = Vector2,
		ColorSequence = ColorSequence,
		ColorSequenceKeypoint = ColorSequenceKeypoint,
		NumberSequence = NumberSequence,
		NumberSequenceKeypoint = NumberSequenceKeypoint,
        Vector3 = Vector3,
        CFrame = CFrame,
        RaycastParams = {new=function() return {} end},
		queue_on_teleport = function(code)
			table.insert(ctl.queued, code)
		end,
		task = task,
		typeof = typeofMock,
		require = mockRequire,
		print = function(...)
			table.insert(ctl.prints, table.concat(table.pack(...), " "))
		end,
		warn = function(...)
			table.insert(ctl.warnings, table.concat(table.pack(...), " "))
		end,
		os = { clock = function()
			return ctl.clock
		end, date = os.date, time = os.time },
		_G = G,
		setclipboard = function(s)
			ctl.clipboard = s
		end,
		identifyexecutor = function()
			return "MockExec", "1.0"
		end,
		writefile = function(name, text)
			assert(type(text) == "string", "writefile expects text")
			ctl.writes = (ctl.writes or 0) + 1
			ctl.files[name] = text
		end,
		readfile = function(name)
			return ctl.files[name] or error("file not found: " .. tostring(name))
		end,
		isfile = function(name)
			return ctl.files[name] ~= nil
		end,
	}) do
		env[k] = v
	end
	for _, k in ipairs({ "math", "string", "table", "coroutine", "pairs", "ipairs", "next", "select", "type", "tostring", "tonumber", "error", "pcall", "xpcall", "setmetatable", "getmetatable", "rawget", "rawset", "rawequal", "debug", "utf8", "assert", "unpack" }) do
		env[k] = (getfenv(0) :: any)[k]
	end
	ctl.env = env
	return env, ctl
end
