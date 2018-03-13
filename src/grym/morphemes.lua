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

local m = {}

m.letter = R"AZ" + R"az"

m.digit = R"09"

m._ = P" "

m.WS = m._^0

m.NL = P"\n"

m.__TAB__ = P"\t" -- First thing we do is eliminate these

m.tar = P"*"
m.tars = P"*"^1
m.hax = P"#"
m.pat = P"@"
m.hep = P"-"
m.bar = P"|"
m.zap = P"!"
m.zaps = P"!"^1
m.fas = P"/"
m.fass = P"/"^1
m.dot = P"."

m.tagline_sys_p = #(m.WS * m.hax - (m.hax * m._))
m.tagline_user_p = #(m.WS * m.pat - (m.pat * m._))
m.tagline_p = m.tagline_sys_p + m.tagline_user_p

m.listline_base_p = #(m.WS * m.hep * m._)
m.listline_num_p = #(m.WS * m.digit^1 * m.dot)
m.listline_p = m.listline_base_p + m.listline_num_p


m.tableline_p = #(m.WS * m.bar)

m.codestart_p = #(m.WS * m.hax * m.zaps)
m.codefinish_p = #(m.WS * m.hax * m.fass)

m.codestart = m.WS * m.hax * m.zaps * P(1)^1
m.codefinish = m.WS * m.hax * m.fass * P(1)^1

m.header = m.WS * m.tars * m._ * P(1)^1 

m.symbol = m.letter * (m.letter + m.digit + m.hep)^0 
m.hashtag = m.hax * m.symbol
m.handle = m.pat * m.symbol

return m

