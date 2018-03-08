require "pl.strict"
local pretty = require "pl.pretty"

lpeg = require "lpeg"
normalize = require "grym-fmt"
group = require "grym-group"

arguments = {}
arguments.tab_set = 3


local stanzas, phrase = normalize.norm("samples/headers.gm")

local stanzas = group.print_head(stanzas)

print(pretty.write(stanzas))

group.print_head(stanzas)

--io.write(phrase)
--[[
for _,v in ipairs(stanzas) do
   io.write (v.."\n")
end
--]]


--- Premise

