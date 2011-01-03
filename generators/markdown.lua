Name = "stdout"
Description = "Markdown output to stdout."
Extension = "md"

function header(sink)
end

function module(sink, name, mod)
	sink(name, "\n")
	sink("======\n")
	for k, line in pairs(mod.description) do
		sink(line, "\n")
	end
	sink("\n")
end

function method(sink, name, func)
	sink(("function %s(%s)\n"):format(name, table.concat(func.args, ", ")))
	sink("------\n")
	if func.docs.description then
		sink(func.docs.description[1], "\n")
	end
	
	sink("\n")
	
	if func.docs.args then
		for argname, desc in pairs(func.docs.args) do
			sink((" * _%s_ = %s\n"):format(argname, desc[1]))
		end
	end
	
	sink("\n")
	
	if func.docs["return"] then
		sink("Returns ", func.docs["return"], "\n")
	end
	
	if func.docs.see then
		sink(("See also %s\n"):format(table.concat(func.docs.see, ", ")))
	end
	
	sink("\n")
end

function object(sink, objname, obj)
	for name, func in pairs(obj.methods) do
		method(sink, func.fullname, func)
	end
end

function footer(sink)
	sink("* * *\n")
	sink("_Generated with Loco,_ ",os.date(), "\n")
end