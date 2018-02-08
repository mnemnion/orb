-- * Ownership module
--
--    Taking a multi-pass approach to this Grimoire instance will benefit us 
-- in a few ways. 
--
--    First, Grimoire itself is structured in a certain fashion. The 
-- straightforward thing is to mirror that fashion in code.
--
--    Second, the critical path right now is simple code generation from 
-- Grimoire documents. Parsing prose gets useful later, for now I simply
-- wish to unravel some existing code into Grimoire format and start working
-- on it accordingly. 

local L = require "lpeg"

local a = require "../lib/ansi"

local ast = require "peg/ast"

local own = {}

own.__error = false

-- Takes a string, returning a Forest with some enhancements.
function own.parse(str)

    for line in str:gmatch("[^\r\n]+") do
        local l, err = line:gsub("\t", "  ") -- tab filtration
        if err ~= 0 and own.__error then
            io.write(tostring(a.red)..tostring(err) 
                .. " TABS DETECTED WITHIN SYSTEM\n" .. tostring(a.clear))
        end


    end

end

return own