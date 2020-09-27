




local Phrase = require "singletons:singletons/phrase"
local Twig = require "orb:orb/metas/twig"



local Header_M = {}



local Header = Twig:inherit "header"
Header_M.header = Header





function Header.toMarkdown(header, scroll)
   local phrase = Phrase (("#"):rep(header:select("level")():len()))
   scroll:add(phrase)
   local head_line = header :select "head_line"()
   if head_line then
      phrase = phrase .. head_line :toMarkdown(scroll)
   end
   return phrase
end



return Header_M
