

































































local c_noknit = require "orb:knit/predicator" "#asLua"






local c_knit = {}






c_knit.code_type = "c"











c_knit.pred = function() return false end

c_knit.knit_pred = function() return end







function c_knit.knit(codeblock, scroll, skein)
   if c_noknit(codeblock) then return end
   local codebody = codeblock :select "code_body" ()
   local line_start, _ , line_end, _ = codebody:linePos()
   for i = scroll.line_count, line_start - 1 do
      scroll:add "\n"
   end
   scroll:add(codebody)
   -- add an extra line and skip 2, to get a newline at EOF
   scroll:add "\n"
   scroll.line_count = line_end + 2
end



return c_knit

