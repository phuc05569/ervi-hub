-- Named configs, stored as one text file in the executor workspace when readfile/writefile exist:
--   autoload=PvP
--   [Default]
--   toggleKey=RightShift
--   ...
-- Every value is validated on load; unknown keys and bad values fall back to defaults.
-- A 2.1.x file (plain key=value lines, no sections) is read into the "Default" config.
local Settings = {}

Settings.FILE = "RNG_Hub_settings.txt"
Settings.MIN_OPACITY = 0.35
Settings.DEFAULT_NAME = "Default"
Settings.DEFAULTS = {
	toggleKey = "RightShift",
	opacity = 0.95, -- on the slider's 5% grid
	scale = 1,
	theme = "Midnight",
	accent = "", -- "" = the design's own accent
	font = "Gotham",
	textColor = "Theme",
	textScale = 1,
	outline = "auto", -- auto | on | off
	textAlpha = 0,
	bgColor = "", -- "" = the design's own background, or "#RRGGBB"
	antiAfk = false,
	reconnect = false,
	autoExec = false,
	instantPrompts = false,
	winW = 660, -- window size, changed with the corner grip
	winH = 450,
}
local KEYS = { "toggleKey", "opacity", "scale", "theme", "accent", "font", "textColor", "textScale", "outline", "textAlpha", "bgColor", "antiAfk", "reconnect", "autoExec", "instantPrompts", "winW", "winH" }
local BOOLS = { antiAfk = true, reconnect = true, autoExec = true, instantPrompts = true }
local NUMBERS = { opacity = { 0.35, 1 }, scale = { 0.5, 1.5 }, textScale = { 0.8, 1.4 }, textAlpha = { 0, 0.6 }, winW = { 520, 1100 }, winH = { 360, 820 } }
local OUTLINE = { auto = true, on = true, off = true }

function Settings.defaults()
	return table.clone(Settings.DEFAULTS)
end

-- Config names: 1-24 chars of letters, digits, space, _ or -.
function Settings.cleanName(name)
	if type(name) ~= "string" then
		return nil
	end
	name = name:match("^%s*(.-)%s*$")
	if #name < 1 or #name > 24 or name:find("[^%w _%-]") then
		return nil
	end
	return name
end

-- validate[key](string) -> bool for the string-valued keys (injected so this stays testable).
local function setField(cfg, key, value, validate)
	if Settings.DEFAULTS[key] == nil then
		return
	end
	local range = NUMBERS[key]
	if range then
		local n = tonumber(value)
		if n then
			cfg[key] = math.max(range[1], math.min(range[2], n))
		end
	elseif BOOLS[key] then
		if value == "true" or value == "false" then
			cfg[key] = value == "true"
		end
	elseif key == "outline" then
		if OUTLINE[value] then
			cfg[key] = value
		end
	elseif not validate[key] or validate[key](value) then
		cfg[key] = value
	end
end

function Settings.newStore()
	return { autoload = nil, configs = {}, order = {} }
end

function Settings.put(store, name, cfg)
	if not store.configs[name] then
		table.insert(store.order, name)
	end
	store.configs[name] = cfg
end

function Settings.delete(store, name)
	if not store.configs[name] then
		return false
	end
	store.configs[name] = nil
	table.remove(store.order, table.find(store.order, name))
	if store.autoload == name then
		store.autoload = nil
	end
	return true
end

function Settings.parse(text, validate)
	local store = Settings.newStore()
	if type(text) ~= "string" then
		return store
	end
	local current, skipping = nil, false
	for line in (text .. "\n"):gmatch("([^\n]*)\n") do
		line = (line:gsub("\r$", ""))
		local section = line:match("^%[(.*)%]$")
		if section then
			local name = Settings.cleanName(section)
			skipping = name == nil
			if name and not store.configs[name] then
				Settings.put(store, name, Settings.defaults())
			end
			current = name and store.configs[name]
		else
			local key, value = line:match("^([%w_]+)=(.*)$")
			if key and not skipping then
				if current then
					setField(current, key, value, validate)
				elseif key == "autoload" then
					store.autoload = Settings.cleanName(value)
				else
					if not store.configs[Settings.DEFAULT_NAME] then
						Settings.put(store, Settings.DEFAULT_NAME, Settings.defaults())
					end
					setField(store.configs[Settings.DEFAULT_NAME], key, value, validate)
				end
			end
		end
	end
	if store.autoload and not store.configs[store.autoload] then
		store.autoload = nil
	end
	return store
end

function Settings.serialize(store)
	local out = {}
	if store.autoload then
		table.insert(out, "autoload=" .. store.autoload)
	end
	for _, name in ipairs(store.order) do
		local cfg = store.configs[name]
		table.insert(out, "[" .. name .. "]")
		for _, key in ipairs(KEYS) do
			local v = cfg[key]
			table.insert(out, key .. "=" .. (type(v) == "number" and ("%.2f"):format(v) or tostring(v)))
		end
	end
	return table.concat(out, "\n") .. "\n"
end

function Settings.canPersist()
	return type(readfile) == "function" and type(writefile) == "function"
end

function Settings.load(validate)
	if not Settings.canPersist() then
		return Settings.parse(nil, validate)
	end
	local ok, text = pcall(function()
		if type(isfile) == "function" and not isfile(Settings.FILE) then
			return nil
		end
		return readfile(Settings.FILE)
	end)
	return Settings.parse(ok and text or nil, validate)
end

function Settings.save(store)
	if not Settings.canPersist() then
		return false, "this executor has no file access"
	end
	return pcall(writefile, Settings.FILE, Settings.serialize(store))
end

return Settings
