-- Let's write this in the language we actually use!

local L = require "lpeg"
local P, match = L.P, L.match

local file = io.open(os.getenv("HOME") .. "/Dropbox/br/orb/" .. arg[1], "r")

local headmatch = P"*"^1 * (P" ")

local sql_start = P"#"^-1 * P"!"^1 * P"sql"

local sql_end = P"#"^-1 * P"/"^1 * P"sql"

local function _chunkLine(line)
    if match(headmatch, line) then
      return line, "header"
   elseif match(sql_start, line) then
      return line, "sql_start"
   elseif match(sql_end, line) then
      return line, "sql_end"
   else
      return "", "~"
   end

end

local printing_codeblock = false
while true do
   local line, line_sem, semtype
   ::start::
   if semtype == "sql_start" then
      line = file : read()
      goto start
   else
      line = file : read()
   end
   if not line then break end

   local line_sem, semtype  = _chunkLine(line)
   if semtype == "header" then
      print (line_sem .. " " .. semtype)
   elseif semtype == "sql_start" then
      print ("#!lua" .. " " .. semtype)
      printing_codeblock = true
   elseif semtype == "sql_end" then
      print ("#/lua" .. " " .. semtype)
      printing_codeblock = false
      goto start
   end
   if printing_codeblock then
      if not match(sql_start, line) then
         print (line .. " " .. semtype)
      end
      if semtype == "sql_start" then
         printing_codeblock = true
      end
   end
end
--]]