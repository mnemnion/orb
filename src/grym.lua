-- Grimoire, a metalanguage for magic spells

require "pl.strict"

local ast = require "peg/ast"
local pl_file = require "pl.file"
local pl_dir = require "pl.dir"
local getfiles = pl_dir.getfiles
local read = pl_file.read

local P_grym = require "grym/grymmyr" 

local function parse(str) 
    return ast.parse(P_grym, str)
end

local samples = getfiles("samples")

local own = require "grym/own"
















-- Check samples for basic parse integrity
for _,v in ipairs(samples) do
    if v:match("~") == nil then
        io.write(v)
        local sample = read(v)
        local tree = parse(sample)
        local flat = ast.flatten(tree)
        assert(sample == flat, "flattened ast is missing values:\n" .. sample 
            .. "\n\n!!!\n\n" .. flat)
        io.write(" ☑️" .. "\n")
    end
end
