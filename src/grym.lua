local lpeg = require "lpeg"

require "pl.strict"

-- local util = require "util"

local ansi = require "lib/ansi"
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
local read = pl_file.read

local grym = require "grymmyr"

local header_gm = read "samples/headers.gm"

local parse = ast.parse

local header_ast = parse(grym, header_gm)

-- epnf.dumpast(header_ast)

print(header_ast)

-- must capture all spans
assert(header_gm == ast.flatten(header_ast))