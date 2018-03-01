-- * Code Block Module
--
--   Code blocks are the motivating object for Grimoire.  Perforce they
-- will do a lot of the heavy lifting.
--
-- From the compiler's perspective, Code, Structure, and Prose are the
-- three basic genres of Grimmorian text.  In this implementation,
-- you may think of Code as a clade diverged early from both Structure
-- and Prose, with some later convergence toward the former. 
-- 
-- 

local Node = require "peg/node"

local CB = setmetatable({}, Node)

CB.__index = CB

CB.__tostring = function() return "codeblock" end

local cb = {}

local function new(Codeblock, headline, linum)
    local codeblock = setmetatable({}, CB)
    codeblock.header = headline
    codeblock.line_first = linum
    codeblock.lines = {}

    return codeblock
end

cb["__call"] = new

return cb