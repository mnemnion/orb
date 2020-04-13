









local lua_knit = {}









lua_knit.code_type = "lua"









function lua_knit.pred(codeblock)
   local should_knit = false
   for tag in codeblock:select "hashtag" do
      if tag:span() == "#asLua" then
         should_knit = true
      end
   end

   return shoud_knit
end










function lua_knit.knit(codeblock, scroll)
   -- add one line for the header
   -- #todo add the linepos for header and footer
   scroll:add "\n"
   -- add the codeblock contents
   -- #todo add as Node
   scroll:add(codeblock:select("code_body")():span())
   -- add another line for the footer
   scroll:add "\n"
end














function lua_knit.pred_knit(codeblock, scroll)
   local name = codeblock:select "name"
   if name then
      name = name:select "handle" :span() :sub(2)
      -- #todo verify/coerce valid Lua symbol
      -- #todo look for =.=, modify header if found
   else
      -- #todo complain about this
      return
   end
   local header = "local " .. name .. " = [["
   scroll:add(header)
   scroll:add(codeblock:select("code_body")():span())
   scroll: add "]]"
   -- #todo search for =="]" "="* "]"== in code_body span and add more = if
   -- needful
end



return lua_knit
