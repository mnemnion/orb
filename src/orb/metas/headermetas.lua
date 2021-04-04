




local Twig = require "orb:orb/metas/twig"



local Header_M = {}



local Header = Twig:inherit "header"
Header_M.header = Header





function Header.toMarkdown(header, scroll)
   local phrase = ("#"):rep(header:select("level")():len())
   scroll:add(phrase)
   for i = 2, #header do
      header[i]:toMarkdown(scroll)
   end
end



return Header_M

