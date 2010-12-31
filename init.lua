require "loco.tokenize"
require "loco.docparse"

local setmetatable = setmetatable
local assert = assert
local pairs = pairs
local concat = table.concat

local print = print

--- Loco is a documentation generator for Lua.
-- this page is generated with Loco.
module "loco"

local generator = {}
generator.__index = generator

--- Create a new generator
-- @param options table with options
-- @return new generator object
-- @see Options
function new(options)
	return setmetatable({
		modules = {};
	}, generator)
end

--- Options table
-- @name Options
-- @type table
--
-- @field outputdir Directory to put documentation in.

--- Parse source Lua script
-- @param path Path to file
function generator:feed(path)
	local tokens = tokenize(path)
	parse(tokens)

	local curmodule
	
	for i = 1, #tokens do
		local token = tokens[i]
		local name = token.name
		
		if token.type == "module" then
			self.modules[name] = self.modules[name] or {objects = {}, functions = {}}
			curmodule = self.modules[name]

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

function generator:write(dirpath)
	for name, module in pairs(self.modules) do
		print(("module \"%s\", functions:"):format(name))
		for funcname, args in pairs(module.functions) do
			print(("\t%s(%s)"):format(funcname, concat(args, ", ")))
		end

		print(("\nmodule \"%s\", objects:"):format(name))
		for objname, obj in pairs(module.objects) do
			print(("\t\"%s\" object, methods:"):format(objname))
			
			for funcname, token in pairs(obj.methods) do
				print(("\t\t%s:%s(%s)"):format(objname, funcname, concat(token.args, ", ")))
			end
		end
	end
end

