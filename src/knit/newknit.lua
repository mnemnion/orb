
































































































local Scroll = require "scroll:scroll"



local Knitter = {}
Knitter.__index = Knitter



function Knitter.knit(knitter, skein)
   local doc = skein.source.doc
   local knit
   if skein.knit then
      knit = skein.knit
   else
      skein.knit = {}
      knit = skein.knit
   end
   for section in doc:select "section" do
      -- iterate blocks
      for block in ipairs(section) do
         if section.id == "codeblock" then
            -- add codeblock to scroll:
            -- detect type
            -- create scroll(s) of type if necessary
            -- add scroll
         else
            -- for now:
            -- get number of lines in section
            -- add equivalent newlines to scrolls
         end
      end
   end
end



local function new()
   local knitter = setmetatable({}, Knitter)
   return knitter
end

Knitter.idEst = new



return new
