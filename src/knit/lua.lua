









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
