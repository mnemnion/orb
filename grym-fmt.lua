-- Formatting


--[[
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
--]]

grymfmt = {}


local function rtrim(s)
  local n = #s
  while n > 0 and s:find("^%s", n) do n = n - 1 end
  return s:sub(1, n)
end

-- Algorithm:

-- Open a file, given the handle

-- Iterate through the lines: 

local function under_print(s)
	local phrase = string.gsub(s," ","→")
	io.write(phrase..'\n')
end

function grymfmt.norm(filename)
	local stanzas = {}
	local phrase = ""
	local iter = 1 -- must be a better way
	local tab_set = 4
	if arguments["tab_set"] then 
		tab_set = arguments["tab_set"]       
	end
	for line in io.lines(filename) do	
		-- substitute four spaces for tabs
		stanzas[iter] = string.gsub(line, "\t", (" "):rep(tab_set))
		-- trim trailing whitespace
		stanzas[iter] = rtrim(stanzas[iter])
	    --under_print(stanzas[iter])
		phrase = phrase..stanzas[iter].."\n"
		iter = iter + 1 
	end
	return stanzas, phrase
end
-- Replace all tabs with four spaces (configurable (much) later)
     
-- Strip all trailing whitespace
        
-- Return table of lines
  
return grymfmt