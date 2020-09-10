









local predicator = require "orb:knit/predicator"



local lua_knit = {}









lua_knit.code_type = "lua"









lua_knit.pred = predicator "#asLua"










function lua_knit.knit(codeblock, scroll, skein)
   local codebody = codeblock :select "code_body" ()
   local line_start, _ , line_end, _ = codebody:linePos()
   for i = scroll.line_count, line_start - 1 do
      scroll:add ""
   end
   scroll:add(codebody)
   -- add an extra line and skip 2, to get a newline at EOF
   scroll:add ""
   scroll.line_count = line_end + 2
end














local format, find, gsub = assert(string.format),
                           assert(string.find),
                           assert(string.gsub)

function lua_knit.pred_knit(codeblock, scroll, skein)
   local name = codeblock:select "name"()
   local header = ""
   if name then
      -- stringify and drop "#"
      name = name:select "handle"() :span() :sub(2)
      -- normalize - to _
      name = gsub(name, "%-", "_")
      -- two forms: =local name= or (=name.field=, name[field])
      if not (find(name, "%.") or find(name, "%[")) then
         header = "local "
      end
   else
      local linum = codeblock :select "code_start"() :linePos()
      error (format("an #asLua block must have a name, line: %d", linum))
   end
   local codebody = codeblock :select "code_body" ()
   local line_start, _ , line_end, _ = codebody:linePos()
   for i = scroll.line_count, line_start - 2 do
      scroll:add ""
   end

   header = header .. name .. " = [["
   scroll:add(header)
   scroll:add(codebody)
   scroll:add("]]")
   scroll.line_count = line_end + 2
   -- #todo search for =="]" "="* "]"== in code_body span and add more = if
   -- needful
end



return lua_knit
