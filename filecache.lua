local open = io.open
local assert = assert

module "loco.filecache"

local cache = {}

function flush()
	cache = {}
end

function get(path)
	path = path:gsub("\\", "/")
	local cached = cache[path]
	if cached then
		return cached
	end
	
	local f = assert(open(path, "r"))
	local text = f:read("*a")
	f:close()
	
	cache[path] = text
	return text
end
