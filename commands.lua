local insert = table.insert

module "loco"

commands = {
	description = {args = 0,
		f = function(doc, line)
			doc.description = doc.description or {}
			insert(doc.description, line)
		end
	};
	
	param = {args = 1,
		f = function(doc, parameter, desc)
			doc.args = doc.args or {}
			doc.args[parameter] = doc.args[parameter] or {}
			
			insert(doc.args[parameter], desc)
		end
	};
	
	["return"] = {args = 0,
		f = function(doc, desc)
			doc["return"] = desc
		end
	};
	
	["see"] = {args = 0,
		f = function(doc, seealso)
			doc.see = doc.see or {}
			insert(doc.see, seealso)
		end
	},
}
