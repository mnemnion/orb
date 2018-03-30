









local lpeg = require "lpeg"
local epeg = setmetatable({}, {__index = lpeg})












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

function epeg.Csp (patt)
   return lpeg.Cp() 
      * lpeg.Cmt(patt, function() return true end) 
      * lpeg.Cp() 
      * lpeg.Carg(1) 
      * lpeg.Carg(2) / spanner
end

















return epeg
