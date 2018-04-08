







local lpeg = require "lpeg"
local epeg = require "epeg"

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

m.number = m.digit^1 -- We will improve this

m._ = P" "

m.WS = P" "^0

m.NL = P"\n"

m.__TAB__ = P"\t" -- First thing we do is eliminate these










m.tar = P"*"
m.tars = P"*"^1
m.hax = P"#"
m.pat = P"@"
m.hep = P"-"
m.bar = P"|"

m.fas = P"/"
m.fass = P"/"^1


m.wut = P"?"
m.zap = P"!"
m.zaps = P"!"^1
m.dot = P"."
m.col = P":"
m.sem = P";"

m.sel = P"["
m.ser = P"]"
m.pal = P"("
m.par = P")"
m.kel = P"{"
m.ker = P"}"
m.gal = P"<"
m.gar = P">"





m.punctuation = m.zap + m.wut + m.dot + m.col + m.sem





m.symbol = m.letter * (m.letter + m.digit + m.hep + m.zap + m.wut)^0

m.hashtag = m.hax * m.symbol
m.handle = m.pat * m.symbol















m.tagline_hash_p = #(m.WS * m.hax - (m.hax * m._))
m.tagline_handle_p = #(m.WS * m.pat - (m.pat * m._))
m.tagline_p = m.tagline_hash_p + m.tagline_hash_p









m.listline_base_p = #(m.WS * m.hep * m._)
m.listline_num_p = #(m.WS * m.digit^1 * m.dot)
m.listline_p = m.listline_base_p + m.listline_num_p













m.tableline_p = #(m.WS * m.bar)

m.codestart_p = #(m.WS * m.hax * m.zaps)
m.codefinish_p = #(m.WS * m.hax * m.fass)

m.codestart = m.WS * m.hax * m.zaps * P(1)^1
m.codefinish = m.WS * m.hax * m.fass * P(1)^1

m.header = m.WS * m.tars * m._ * P(1)^1 











-- This is definitely not right at all
m.url = (m.letter + m.dot) * (m.symbol + m.dot + m.fas + m.col)^0 - m.ser

m.prose = (m.symbol + m._)^1 -- Or this
m.anchor_text = m.prose - m.ser -- accurate






m.url_link = m.sel * m.url * m.ser
m.anchor_link = m.sel * m.anchor_text * m.ser
m.link =  (m.sel * m.anchor_link * m.url_link * m.ser)
       +  (m.sel * m.url_link * m.ser)




return m
