









local lua_knit = {}









lua_knit.code_type = "lua"









function lua_knit.pred(codeblock)
   local should_knit = false
   for tag in codeblock:select "hashtag" do
      if tag:span() == "#asLua" then
         should_knit = true
      end
   end

   return should_knit
end










function lua_knit.knit(codeblock, scroll, skein)
   local codebody = codeblock :select "code_body" ()
   local line_start, _ , line_end, _ = codebody:linePos()
   for i = scroll.line_count, line_start - 1 do
      scroll:add ""
   end
   scroll:add(codebody)
   scroll:add ""
   scroll.line_count = line_end + 1
end














local format, find, gsub = assert(string.format),
                           assert(string.find),
                           assert(string.gsub)

function lua_knit.pred_knit(codeblock, scroll, skein)
   local name = codeblock:select "name"()
   local header = ""
   if name then
      name = name:select "handle"() :span() :sub(2)
      name = gsub(name, "%-", "_")
      if not find(name, "%.") then
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
   scroll.line_count = line_end
   -- #todo search for =="]" "="* "]"== in code_body span and add more = if
   -- needful
end



return lua_knit
