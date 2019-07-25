-- Let's write this in the language we actually use!

local L = require "lpeg"
print(os.getenv("HOME") .. "/Dropbox/br/" .. arg[1])
print(io.open(os.getenv("HOME") .. "/Dropbox/br/orb/" .. arg[1], "r"):read())--(io.open(arg[1])):read()
---[[
local file = io.open(os.getenv("HOME") .. "/Dropbox/br/orb/" .. arg[1], "r")
while true do
   local line = file : read()
   if not line then break end
   print (line)
end
--]]