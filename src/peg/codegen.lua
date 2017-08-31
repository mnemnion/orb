--- Code Generator
--
-- Parsing Engine
-- Use (mock):
-- 
-- 		function (works) return if works and true or false end end
-- 


local file = require 'pl.file'

local transform = require "peg/transform"


local isrecursive = transform.isrecursive
local notrecursive = transform.notrecursive

--We start with pegylator.lua
-- Eventually all the imports are replaced with
-- require "pegylator"
-- but first we must write it. 
local prefix = [[ 
require 'pl.strict'

local lpeg = require "lpeg"
local clu = require "clu/prelude"
local util = require "util"
local epeg = require "peg/epeg"
local core = require "peg/core-rules"
local dump_ast = util.dump_ast
local clear = ansi.clear()
local epnf = require "peg/epnf"
local ast = require "peg/ast"
local grammar = require "peg/grammars"
local t = require "peg/transform"

local match = lpeg.match -- match a pattern against a string
local P = lpeg.P -- match a string literally
local S = lpeg.S  -- match anything in a set
local R = epeg.R  -- match anything in a range
local B = lpeg.B
local C = lpeg.C  -- captures a match
local Csp = epeg.Csp -- captures start and end position of match
local Ct = lpeg.Ct -- a table with all captures from the pattern
local V = lpeg.V -- create a variable within a grammar

local WS = P' ' + P'\n' + P',' + P'\09'

]]

-- @todo change to use a provided name, or default to the filename if
-- read from a file, or the start rule name if nothing else given.
local definer = [[
local _generator = function{}
  local function generated(_ENV)
]]

local end_definer = [[
  end
  return generated
end
]]

local caller = [[

local peg = epnf.define(_generator(),nil,false)
]]

local function local_rules(ast)
	local locals = ast:select(notrecursive)
	local phrase = ""
	for i = 1, #locals do
		phrase = phrase.."    "..locals[i]:flatten()
	end
	return phrase
end

local function cursive_rules(ast)
	local cursives = ast:select(isrecursive)
	local phrase  = ""
	for i = 1, #cursives do
		phrase = phrase.."  "..cursives[i]:flatten()
	end
	return phrase
end

local function write(str)
	return file.write("gen.lua",str)
end

local function build(ast)
	local phrase = prefix..ast:root().imports..
	             --local_rules(ast).."\n\n"..
				 definer..ast:root().start_rule..
				 --cursive_rules(ast)..end_definer
				 local_rules(ast)..end_definer..
				 caller
	write(phrase)
	return phrase
end

return { local_rules = local_rules,
		 cursive_rules = cursive_rules,
		 build = build }
















