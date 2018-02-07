local lpeg = require "lpeg"

require "pl.strict"

-- local util = require "util"

local ansi = require "../lib/ansi"
local Node = require "peg/node"
local epeg = require "peg/epeg"
local core = require "peg/core-rules"
local epnf = require "peg/epnf"
local ast = require "peg/ast"
local grammar = require "peg/pegs/grammars"
local highlight = require "peg/highlight"
local transform = require "peg/transform"
local codegen = require "peg/codegen"


local pl_file = require "pl.file"
local pl_dir = require "pl.dir"
local getfiles = pl_dir.getfiles
local read = pl_file.read

local P_grym = require "grym/grymmyr" 

local function parse(str) 
    return ast.parse(P_grym, str)
end

local samples = getfiles("samples")

-- epnf.dumpast(header_ast)

-- print(header_ast)
-- print(header_ast:dot())

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
