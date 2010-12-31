local cache = require "loco.filecache"

require "loco.commands"

local pairs = pairs
local concat = table.concat
local insert = table.insert
local sub = string.sub
local unpack = unpack
local error = error

local print = print

module "loco"

local function locateLineStart(text, pos)
	for i = pos, 1, -1 do
		local c = sub(text, i, i)
		if c == '\n' then
			return i + 1
		end
	end
end

local function findDocLines(text, pos)
	local docLines = {}
	
	pos = locateLineStart(text, pos) -- token line
	
	while true do
		local docLine = locateLineStart(text, pos - 2)
		local line = text:match("[^\r\n]+", docLine)
		
		if line:match("^%s*%-%-") then
			docLines[#docLines + 1] = line
			
			if line:match("^%s*%-%-%-") then
				break
			end
			
		elseif not line:match("^%s*$") then
			return nil
		end
		
		pos = docLine - 1
	end

	return docLines
end

local commands = commands

local function parseDocLine(doc, line)
	line = line:match("^%-+%s*(.+)$")
	
	local cmdname, allArgs = line:match("^%s*@(%S+) (.-)$")

	local cmd = commands[cmdname or "description"]
	if not cmd then
		return nil, ("unknown command \"%s\""):format(cmdname)
	end

	local args, n = {}, 0
	for arg in (allArgs or line):gmatch("%S+") do
		if n < cmd.args then
			insert(args, arg)
			n = n + 1
		else
			break
		end
	end

	cmd.f(doc, unpack(args))
	return true
end

function parse(toks)
	for i = 1, #toks do
		local tok = toks[i]
		local text = cache.get(tok.filepath)
		local pos = tok.filepos

		local docLines = findDocLines(text, pos)
		if docLines then
			local doc = tok.docs or {}
			
			for i = #docLines, 1, -1 do
				local line = docLines[i]
				local succ, err = parseDocLine(doc, line)
				if not succ then
					error(("[Loco] %s:%d: %s"):format(tok.filepath, i, err), 2)
				end
			end

			tok.docs = doc
		end
	end
end

