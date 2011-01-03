local loco = require "loco"
local parser = loco.new{outputdir = "gh-pages"}

parser:feed("init.lua")

local generator = loco.generator "markdown"
parser:generate(generator)