-- Grimoire: A Metalanguage for Magic Spells.

require "pl.strict"
local pretty = require "pl.pretty"

-- localize all these
lpeg = require "lpeg"
normalize = require "grym-fmt"
-- /localize

arguments = {}
arguments.tab_set = 3


local stanzas, phrase = normalize.norm("samples/sample.gm")

print(pretty.write(stanzas))

--io.write(phrase)
--[[
for _,v in ipairs(stanzas) do
	io.write (v.."\n")
end
--]]


--- Premise
-- 
--  This is a multi-pass system. I need to get back into the swing of things,
--  and the best way to do so is to write some easy stuff first.


-- Stages

-- Normalization

-- We need to render whitespace consistently, removing tabs, stripping extra whitespace from all lines,
-- that sort of thing. 

-- normalize.format("filename"|io.stdin) does this. 


-- Ownership

-- The result of normalization is going to be a collection of lines, or a single large string.
-- 
-- Either way, ownership and chunking, which are one pass, break it into a tree that reflects the 
-- large-scale structure of the document. 

-- Parsing

-- Once we've established ownership, the various parsers go to town. 
-- Different parsers entirely for weaving and tangling. 
-- Specialized parsers for doing useful things with lists and tables. 

-- Runtime

-- This gets complex. By this point we'll want to be building Grimoire integration into some 
-- editors, but the fundamentals can be done using classic Unix pipes. LuaJIT is our underlying
-- language, we'll migrate over to it and set up a built environment that runs as a single binary.

-- Point being, the runtime modifies things like lists, tables, and the results of certain code blocks. 
-- We'll need hooks that let any programming language be wired into the runtime system, 

-- I may never get here, so this is where I stop ^_^
