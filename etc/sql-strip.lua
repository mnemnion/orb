-- Let's write this in the language we actually use!
--
-- #NB: this was a good idea, but I didn't keep up using it, and
-- it's currently not the strategy for SQL statements.


local L = require "lpeg"
local C, P, R, match = L.C, L.P, L.R, L.match
local sub = string.sub

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
local match_head = ""
while true do
   local line
   ::start::
   line = file : read()
   if not line then break end

   local line_sem, semtype, captcha  = _chunkLine(line)
      if semtype == "header" then
      match_head = captcha
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
         -- Advance a line
         line = file : read()
         line_sem, semtype, captcha  = _chunkLine(line)
         local line_type = ""
         -- Capture different types of SQL command here.
         if sub(line, 1, 6) == "CREATE" then
            line_type = "create_"
         end
         write ("local " .. line_type .. match_head .. " = [[\n")
         write (line .. "\n")
         printing_codeblock = true
         goto start
      end
   else
      write(line .. "\n")
   end
end
--]]