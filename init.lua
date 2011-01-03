require "loco.tokenize"
require "loco.docparse"
local lfs = require "lfs"

local setmetatable = setmetatable
local assert = assert
local pairs = pairs
local concat = table.concat
local getenv = os.getenv
local error = error
local setfenv = setfenv
local loadfile = loadfile
local open = io.open
local genmeta = {__index = _G}

--- Loco is a documentation generator for Lua.
module "loco"

local parser = {}
parser.__index = parser

--- Create a new parser
-- @param options table with options
-- @return new parse object
-- @see Options
function new(options)
	if not options then
		error("Options parameter is required.", 2)
	end
	
	return setmetatable({
		modules = {};
		outputdir = options.outputdir or error('"outputdir" option must be specified.', 2);
	}, parser)
end

--- Options table
-- @name Options
-- @type table
-- @field outputdir Directory to put documentation in.

--- Create a new generator
function generator(name)
	local locopath = getenv("loco")
	if not locopath then
		error('Could not find environment variable "loco", required to load generators. Set "loco" to any directory with a "generators" subdirectory, usually the Loco install directory.', 2)
	end
	
	local genpath = concat{locopath, "/generators/", name, ".lua"}
	
	local f = assert(loadfile(genpath))
	local env = setmetatable({}, genmeta)
	setfenv(f, env)
	f()
	
	return env
end

--- Parse source Lua script
-- @param path Path to file
function parser:feed(path)
	local tokens = tokenize(path)
	parse(tokens)

	local curmodule
	
	for i = 1, #tokens do
		local token = tokens[i]
		local name = token.name
		
		if token.type == "module" then
			self.modules[name] = self.modules[name] or {objects = {}, functions = {}}
			curmodule = self.modules[name]
			curmodule.description = token.docs.description
			
		elseif curmodule then
			if token.type == "function" then
				local obj, args = token.obj, token.args
				if obj then
					curmodule.objects[obj] = curmodule.objects[obj] or {methods = {}}
					curmodule.objects[obj].methods[name] = token
				else
					curmodule.functions[name] = token
				end
			end
		end
	end
end

function parser:generate(generator)
	lfs.mkdir(self.outputdir)
	
	for name, module in pairs(self.modules) do
		local path = concat{self.outputdir, "/", name, ".", generator.Extension}
		local sink, fhandle
		if generator.generator then
			sink = generator.generator(path)
		else
			fhandle = assert(open(path, "w+"))
			sink = function(...)
				for k, arg in pairs{...} do
					fhandle:write(arg)
				end
			end
		end
	
		generator.header(sink)
		generator.module(sink, name, module)
		
		for funcname, func in pairs(module.functions) do
			generator.method(sink, funcname, func)
		end

		for objname, obj in pairs(module.objects) do
			generator.object(sink, objname, obj)
		end
		
		generator.footer(sink)
		
		if fhandle then
			fhandle:close()
		end
	end
end
