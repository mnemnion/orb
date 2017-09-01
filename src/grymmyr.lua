--[[

Grimoire Grammar

]]

local lpeg = require "lpeg"
local epeg = require "peg/epeg"
local epnf = require "peg/epnf"

local match = lpeg.match -- match a pattern against a string
local P = lpeg.P -- match a string literally
local S = lpeg.S  -- match anything in a set
local R = epeg.R  -- match anything in a range
local B = lpeg.B
local C = lpeg.C  -- captures a match
local Csp = epeg.Csp -- captures start and end position of match
local Cg = lpeg.Cg -- named capture group (for **balanced highlighting**)
local Cb = lpeg.Cb -- Mysterious! TODO make not mysterious
local Cmt = lpeg.Cmt -- match-time capture
local Ct = lpeg.Ct -- a table with all captures from the pattern
local V = lpeg.V -- create a variable within a grammar

local letter = R"AZ" + R"az" 
local valid_sym = letter + P"-"  
local digit = R"09"
local sym = valid_sym + digit
local WS = P' ' + P',' + P'\09' -- Not accurate, refine (needs Unicode spaces)
local NL = P"\n"

local function equal_strings(s, i, a, b)
	-- Returns true if a and b are equal.
	-- s and i are not used, provided because expected by Cb.
	print ("measuring equality: a " .. a .. " b " .. b)
	return a == b
end

local function bookends(sigil)
	-- Returns a pair of patterns, _open and _close,
	-- which will match a brace of sigil.
	-- sigil must be a string. 
	local _open = Cg(C(P(sigil)^1), sigil .. "_init")
	local _close =  Cmt(C(P(sigil)^1) * Cb(sigil .. "_init"), equal_strings)
	return _open, _close
end

local _grym_fn = function ()
	local function grymmyr (_ENV)
		START "grym"
		SUPPRESS ("structure", "structured")

		local prose_word = (valid_sym^1 + digit^1)^1
		local prose_span = (prose_word + WS^1)^1
		local NEOL = NL + -P(1)

		grym      = V"section"^1 * EOF("Failed to reach end of file")

		section   = (V"header" * V"block"^0) + V"block"^1

		structure = V"blank_line" -- list, table, json, comment...

		header     = V"lead_ws" * V"lead_tar" * V"prose_line"
		lead_ws = Csp(WS^0)
		lead_tar   = Csp(P"*"^-6 * P" ")
		prose_line = Csp(prose_span * NEOL)

		block = (V"structure"^1 + V"prose"^1)^1 * #V"block_end"

		prose = (V"structured" + V"unstructured")^1
		unstructured = Csp(V"prose_line"^1 + prose_span)
		structured = V"bold" + V"italic"

		local bold_open, bold_close = bookends("*")
		bold = Csp(bold_open * prose_span * bold_close)
		local italic_open, italic_close = bookends("/")
		italic = Csp(italic_open * prose_span * italic_close)


		block_end = V"blank_line"^1 + -P(1) + #V"header"
		
		blank_line = Csp(WS^0 * NL)

	end
	return grymmyr
end

return epnf.define(_grym_fn(), nil, false)