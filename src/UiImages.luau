-- Crisp logo/icon images without a published asset: the PNGs are embedded in the bundle (UiAssets),
-- written to the executor workspace at start and loaded with getcustomasset, so a GitHub-loaded
-- bundle needs no extra files. Any missing API, error or failed load returns nil and callers keep
-- their native fallback. Nothing is downloaded.
local Data = require("UiAssets")
local UiImages = { resolver = nil, cell = Data.cell, iconRects = Data.icons, logoSize = Data.logoSize }

local ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local LOOKUP = {}
for i = 1, #ALPHABET do
	LOOKUP[ALPHABET:byte(i)] = i - 1
end

function UiImages.decode(text)
	local out, bits, count = table.create(#text * 3 // 4), 0, 0
	for i = 1, #text do
		local v = LOOKUP[text:byte(i)]
		if v then
			bits = bits * 64 + v
			count += 6
			if count >= 8 then
				count -= 8
				local byte = bits // 2 ^ count
				out[#out + 1] = string.char(byte)
				bits -= byte * 2 ^ count
			end
		end
	end
	return table.concat(out)
end

local cache = {}
local function load(name, base64)
	if UiImages.resolver then
		return UiImages.resolver(name)
	end
	if cache[name] ~= nil then
		return cache[name] or nil
	end
	cache[name] = false
	if type(getcustomasset) ~= "function" or type(writefile) ~= "function" then
		return nil
	end
	local ok, id = pcall(function()
		-- Root of the workspace (no folder API needed). Rewritten every start, so a partial or
		-- stale file heals itself; the PNG bytes always come from this bundle, never from disk.
		local file = ("Ervi_Hub_ui-%s-%s.png"):format(name, Data.version)
		writefile(file, UiImages.decode(base64))
		return getcustomasset(file)
	end)
	if ok and type(id) == "string" and id ~= "" and UiImages.loaded(id) then
		cache[name] = id
		return id
	end
	return nil
end

-- True only when the engine confirms it can draw the image; otherwise callers fall back to the
-- native logo/icons instead of showing an empty ImageLabel. Bounded wait (~3 s worst case).
function UiImages.loaded(id)
	local okService, provider = pcall(function() return game:GetService("ContentProvider") end)
	if not okService or not provider then
		return false
	end
	local status
	task.spawn(function()
		local fine = pcall(function()
			provider:PreloadAsync({ id }, function(_, result) status = result end)
		end)
		if status == nil then status = fine and "none" or "error" end
	end)
	for _ = 1, 180 do
		if status ~= nil then break end
		task.wait()
	end
	local okName, name = pcall(function() return status.Name end)
	return okName and name == "Success"
end

function UiImages.icons() return load("icons", Data.iconsPng) end
function UiImages.logo() return load("logo", Data.logoPng) end

return UiImages
