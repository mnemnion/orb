
local lpeg = require "lpeg"
local epeg = require "epeg"

local match = lpeg.match -- match a pattern against a string
local P = lpeg.P -- match a string literally
local S = lpeg.S  -- match anything in a set
local R = epeg.R  -- match anything in a range
local B = lpeg.B
local C = lpeg.C  -- captures a match
local Csp = epeg.Csp -- captures start and end position of match
local Ct = lpeg.Ct -- a table with all captures from the pattern
local V = lpeg.V -- create a variable within a grammar
local Cmt = lpeg.Cmt

local group = {}


local asterisk = P"*"

local header_line = asterisk^1 + P(1)^0

function group.print_head(stanzas)
	for i, v in ipairs(stanzas) do
		if match(header_line,v) > 1 then
			io.write("matched!  "..v.."\n")
		else 
			io.write("nope: "..v.."\n")
		end
	end
end


return group 