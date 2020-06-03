# Epeg

Deprecated library used in various places in the Orb codebase, not worth
the hassle to remove at this time\.

```lua
local lpeg = require "lpeg"

local function makerange(first, second)
   local patts = {}
   local patt  = {}
   if (second) then
      if (string.len(first) == string.len(second)) then
         for i = 1, string.len(first) do
            patts[i] = lpeg.R(string.sub(first,i,i)..string.sub(second,i,i))
         end
         patt = patts[1]
         for i = 2, string.len(first) do
            patt = patt + patts[i]
         end
         return patt
      else
         error("Ranges must be of equal byte width")
         return {}
      end
   else
      return lpeg.R(first)
   end
end


local function num_bytes(str)
--returns the number of bytes in the next character in str
   local c = str:byte(1)
   if c >= 0x00 and c <= 0x7F then
      return 1
   elseif c >= 0xC2 and c <= 0xDF then
      return 2
   elseif c >= 0xE0 and c <= 0xEF then
      return 3
   elseif c >= 0xF0 and c <= 0xF4 then
      return 4
   end
end

local function Su (str)
--[[
   --convert a 'set' pattern to uniquely match the characters
   --in the range.
   local catch = {}
   local i = 0
   for i = 1, #str do
      catch[i]
   end
   --]]
end

local function spanner(first, last, str, root)
   local vals = {}
   vals.span = true
   vals.val = string.sub(str, first, last - 1)
   vals.first = first
   vals.last = last - 1
   if vals.last >= vals.first then
      return vals
   end
   -- If a capture contains nothing, we don't want a node for it
   return nil
end

local function Csp (patt)
   return lpeg.Cp()
      * lpeg.Cmt(patt, function() return true end)
      * lpeg.Cp()
      * lpeg.Carg(1)
      * lpeg.Carg(2) / spanner
end





local function split (s, sep)
  sep = lpeg.P(sep)
  local elem = lpeg.C((1 - sep)^0)
  local p = lpeg.Ct(elem * (sep * elem)^0)   -- make a table capture
  return lpeg.match(p, s)
end













local I = lpeg.Cp()

local function  anyP(p)
     return lpeg.P{ I * p * I + 1 * lpeg.V(1) }
end



local Ru = makerange


return { R = Ru,
      Csp = Csp,
      anyP = anyP,
      match = lpeg.match,
      split = split,
      spanner = spanner }

```