local cache = require "loco.filecache"

local assert = assert
local open = io.open
local error = error

local print = print

module "loco"

local function parseModule(line)
	local modname = line:match("[ \t]*module%s*%(?%s*\"([^\"]+)\"")
	if modname then
		return {type = "module", name = modname}
	end
end

local function parseFunctionArgs(textargs)
	local args = {}
	textargs:gsub("[^,]+", function(arg) args[#args + 1] = arg end)
	return args
end

local function parseFunction(line)
	local fullname, args = line:match("[ \t]*function%s+([^%(]+)%(([^%)]-)%)")
	if fullname then
		local obj, name = fullname:match("^([^:]+):(.+)$")
		return {type = "function", name = name or fullname, obj = obj, args = parseFunctionArgs(args), fullname = fullname} 
	end
end

local parsers = {parseModule, parseFunction}

local function findTokens(path, text)
	local elems = {}

	local pos = 1
	while true do
		local startpos, endpos, line = text:find("([^\r\n]+)", pos)
		if not startpos then
			break
		end

		for i = 1, #parsers do
			local elem = parsers[i](line)
			if elem then
				elem.filepath, elem.filepos = path, startpos
				elems[#elems + 1] = elem
				break
			end
		end

		pos = endpos + 1
	end
	
	return elems
end

function tokenize(path)
	local text = cache.get(path)

	local toks = findTokens(path, text)
	
	return toks
end
