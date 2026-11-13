-- Named configs, stored as one text file in the executor workspace when readfile/writefile exist:
--   autoload=PvP
--   [Default]
--   toggleKey=RightShift
--   ...
-- Every value is validated on load; unknown keys and bad values fall back to defaults.
-- A 2.1.x file (plain key=value lines, no sections) is read into the "Default" config.
local Schema = require("FeatureSchema")
local Settings = {}

Settings.FILE = "RNG_Hub_settings.txt"
Settings.MIN_OPACITY = 0
Settings.DEFAULT_NAME = "Default"
Settings.DEFAULTS = {
	toggleKey = "RightShift",
	opacity = 0.75, -- on the slider's 5% grid
	scale = 0.85,
	theme = "Midnight",
	accent = "Indigo", -- "" = the design's own accent
	font = "Gotham",
	textColor = "White",
	textScale = 1.4,
	outline = "auto", -- auto | on | off
	textAlpha = 0,
	bgColor = "", -- "" = the design's own background, or "#RRGGBB"
	antiAfk = false,
	reconnect = false,
	autoExec = false,
	instantPrompts = false,
	winW = 880, -- window size, changed with the corner grip
	winH = 580,
	winX = 0.5, winY = 0.5,
	statusX=0.5,statusY=0.93,
	statusOpacity=0.7,
	customN=500,
	communityLink = "",
	movementX=0.1, movementY=0.3, movementW=330, movementH=240,
	m1Enabled = false,
	m1X = 0.5, m1Y = 0.55, m1W = 330, m1H = 180,
	safeZoneKey = "NONE",
	targetEnabled = false, targetHp = 30,
	resumeAfterDeath = false, autoM1Requested = false,
}
local KEYS = { "toggleKey", "opacity", "scale", "theme", "accent", "font", "textColor", "textScale", "outline", "textAlpha", "bgColor", "antiAfk", "reconnect", "autoExec", "instantPrompts", "winW", "winH", "winX", "winY", "statusX", "statusY", "movementX", "movementY", "movementW", "movementH", "communityLink", "m1Enabled", "m1X", "m1Y", "m1W", "m1H", "safeZoneKey", "targetEnabled", "targetHp", "resumeAfterDeath", "autoM1Requested" }
local BOOLS = { antiAfk = true, reconnect = true, autoExec = true, instantPrompts = true, m1Enabled = true, targetEnabled = true, resumeAfterDeath = true, autoM1Requested = true }
local NUMBERS = { opacity = { 0, 1 }, scale = { 0.5, 1.5 }, textScale = { 0.8, 1.4 }, textAlpha = { 0, 0.6 }, winW = { 520, 1100 }, winH = { 360, 820 }, winX={0,1},winY={0,1},statusX={0,1},statusY={0,1},movementX={0,1},movementY={0,1},movementW={260,800},movementH={160,600}, m1X = {0,1}, m1Y = {0,1}, m1W = {260,800}, m1H = {160,600}, targetHp = {1,100} }

for _, d in ipairs(Schema) do
 Settings.DEFAULTS[d.key]=d.default
 table.insert(KEYS,d.key)
 if d.kind=="bool" then BOOLS[d.key]=true end
 if d.kind=="number" then NUMBERS[d.key]={d.min,d.max} end
end
local SCHEMA={}; for _,d in ipairs(Schema) do SCHEMA[d.key]=d end

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
	local spec=SCHEMA[key]
	if spec and spec.options and not table.find(spec.options,value) then return end
	if spec and spec.kind=="color" and not value:match("^#%x%x%x%x%x%x$") then return end
	if spec and spec.kind=="key" and value~="NONE" and (not value:match("^[A-Za-z][A-Za-z0-9]*$") or #value>24) then return end
	local range = NUMBERS[key]
	if range then
		local n = tonumber(value)
		if n and n == n and math.abs(n) < math.huge then
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
	elseif #value<=300 and not value:find("[%c]") and (not validate[key] or validate[key](value)) then
		cfg[key] = value
	end
end

function Settings.newStore()
	return { autoload = nil, autoloadGames = {}, configs = {}, order = {} }
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
	for place,slot in pairs(store.autoloadGames or {}) do if slot==name then store.autoloadGames[place]=nil end end
	if store.autoload == name then
		store.autoload = nil
	end
	return true
end

function Settings.parse(text, validate)
	local store = Settings.newStore()
	if type(text) ~= "string" or #text>1048576 then
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
				elseif key:match("^autoloadGame_%d+$") then
                    store.autoloadGames[key:match("%d+$")]=Settings.cleanName(value)
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
	for place,name in pairs(store.autoloadGames) do if not store.configs[name] then store.autoloadGames[place]=nil end end
	for _, cfg in pairs(store.configs) do
		if cfg.safeZoneKey == cfg.toggleKey then cfg.safeZoneKey = "NONE" end
        local used={[cfg.toggleKey]=true}
        for _,key in ipairs({"safeZoneKey","panicKey","walkKey","espKey"}) do
            if cfg[key]~="NONE" then if used[cfg[key]] then cfg[key]="NONE" else used[cfg[key]]=true end end
        end
	end
	if store.autoload and not store.configs[store.autoload] then
		store.autoload = nil
	end
	return store
end

function Settings.serialize(store)
	local out = {}
    local places={};for place in pairs(store.autoloadGames or {}) do table.insert(places,place) end;table.sort(places)
    for _,place in ipairs(places) do table.insert(out,"autoloadGame_"..place.."="..store.autoloadGames[place]) end
	if store.autoload then
		table.insert(out, "autoload=" .. store.autoload)
	end
	for _, name in ipairs(store.order) do
		local cfg = store.configs[name]
		table.insert(out, "[" .. name .. "]")
		for _, key in ipairs(KEYS) do
			local v = cfg[key]
			table.insert(out, key .. "=" .. (type(v) == "number" and (key:match("[XY]$") and ("%.6f"):format(v) or ("%.2f"):format(v)) or tostring(v)))
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

-- Share a single slot as a bounded data-only envelope; never loadstring config text.
function Settings.export(cfg)
 local one=Settings.newStore(); Settings.put(one,"Imported",cfg)
 return "ERVI_CONFIG_V1\n"..Settings.serialize(one)
end
function Settings.import(text,validate)
 if type(text)~="string" or #text>65536 then return nil,"Import is missing or larger than 64 KiB" end
 if text:sub(1,15)~="ERVI_CONFIG_V1\n" then return nil,"Unsupported config version" end
 local parsed=Settings.parse(text:sub(16),validate or {})
 if #parsed.order~=1 then return nil,"Import must contain exactly one slot" end
 return parsed.configs[parsed.order[1]]
end
return Settings
