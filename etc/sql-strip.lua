-- Let's write this in the language we actually use!

local L = require "lpeg"
local P, match = L.P, L.match

local file = io.open(os.getenv("HOME") .. "/Dropbox/br/orb/" .. arg[1], "r")

local headmatch = P"*"^1 * (P" ")
                  --* (-(P"\n") *P(1)^0) * (P"\n")

local function _chunkLine(line)
    if match(headmatch, line) then
      return line
   else
      return ""
   end

end

while true do
   local line = file : read()
   if not line then break end
   print (_chunkLine(line))
end
--]]