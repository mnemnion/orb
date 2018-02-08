-- * Morphemes
--
-- Morphemes are the basic structures of any language.


local lpeg = require "lpeg"
local epeg = require "../peg/epeg"
local epnf = require "../peg/epnf"

local match = lpeg.match -- match a pattern against a string
local P = lpeg.P -- match a string literally
local S = lpeg.S  -- match anything in a set
local R = epeg.R  -- match anything in a range
local B = lpeg.B  -- match iff the pattern precedes the use of B
local C = lpeg.C  -- captures a match
local Csp = epeg.Csp -- captures start and end position of match
local Cg = lpeg.Cg -- named capture group (for **balanced highlighting**)
local Cb = lpeg.Cb -- Mysterious! TODO make not mysterious
local Cmt = lpeg.Cmt -- match-time capture
local Ct = lpeg.Ct -- a table with all captures from the pattern
local V = lpeg.V -- create a variable within a grammar

--   ** Morpheme module

local m = {}

m.letter = R"AZ" + R"az"

m.digit = R"09"

m._ = P" "

m.WS = m._^0

m.NL = P"\n"

m.__TAB__ = P"\t" -- First thing we do is just eliminate these

m.tar = P"*"

m.tars = P"*"^1

m.header = m.WS * m.tars * m._ * P(1)^1 

return m