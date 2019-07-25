-- Let's write this in the language we actually use!

local L = require "lpeg"
local C, P, R, match = L.C, L.P, L.R, L.match

local file = io.open(os.getenv("HOME") .. "/Dropbox/br/orb/" .. arg[1], "r")

local headmatch = P"*"^1 * (P" ") * C(P(R"AZ" + R"az")^1)

local sql_start = P"#"^-1 * P"!"^1 * P"sql"

local sql_end = P"#"^-1 * P"/"^1 * P"sql"

local function _chunkLine(line)
    if match(headmatch, line) then
      return line, "header", match(headmatch, line)
   elseif match(sql_start, line) then
      return line, "sql_start"
   elseif match(sql_end, line) then
      return line, "sql_end"
   else
      return "", "~"
   end

end

local printing_codeblock = false
local write = io.write
while true do
   local line
   ::start::
   line = file : read()
   if not line then break end

   local line_sem, semtype  = _chunkLine(line)
   local match_head = ""
   if semtype == "header" then
      print("capture is!  " .. line_sem)
      match_head = line_sem
      write (line_sem)
   elseif semtype == "sql_start" then
      write ("#!lua" .. "\n")
      printing_codeblock = true
   elseif semtype == "sql_end" then
      write "]]\n"
      write ("#/lua" .. "\n")
      printing_codeblock = false
      goto start
   end
   if printing_codeblock then
      if not match(sql_start, line) then
         write (line .. "\n")
      end
      if semtype == "sql_start" then
         write ("local" .. match_head .. " = [[\n")
         match_head = ""
         printing_codeblock = true
      end
   elseif making_lua == true then
      write("---  " .. line .. "\n")
   else
      write(line .. "\n")
   end
end
--]]