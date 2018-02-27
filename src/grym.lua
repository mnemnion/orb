-- Grimoire, a metalanguage for magic spells

require "pl.strict"

local verbose = false

local ast = require "peg/ast"
local pl_file = require "pl.file"
local pl_dir = require "pl.dir"
local getfiles = pl_dir.getfiles
local read = pl_file.read
local write = pl_file.write

local P_grym = require "grym/grymmyr" 

local function parse(str) 
    return ast.parse(P_grym, str)
end

samples = getfiles("samples")

local own = require "grym/own"


-- Run the samples and make dotfiles
for _,v in ipairs(samples) do
    if v:match("~") == nil then
        if verbose then io.write(v) end
        local sample = read(v)
        io.write(v.."\n")
        local doc = own.parse(sample)
        write("../org/dot/" .. v .. ".dot", doc:dot())
    end
end
