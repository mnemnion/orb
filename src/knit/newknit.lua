
































































































local Scroll = require "scroll:scroll"
core = assert(core)



local Knitter = {}
Knitter.__index = Knitter



function Knitter.knit(knitter, skein)
   local doc = skein.source.doc
   local knit
   if skein.knit then
      knit = skein.knit
   else
      knit = {}
      skein.knit = knit
   end
   local scroll = Scroll()
   knit.scroll = scroll
   local line_count = 1
   for codebody in doc:select 'code_body' do
      -- retrieve line numbers
      local line_start, _ , line_end, _ = codebody:linePos()
      for i = line_count, line_start - 1 do
         scroll:add "\n"
      end
      scroll:add(codebody)
      line_count = line_end + 1
   end
end



local function new()
   local knitter = setmetatable({}, Knitter)
   return knitter
end

Knitter.idEst = new



return new
