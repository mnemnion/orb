




local Twig = require "orb:orb/metas/twig"



local Header_M = {}



local Header = Twig:inherit "header"
Header_M.header = Header





function Header.toMarkdown(header, scroll, skein)
   local phrase = ("#"):rep(header:select("level")():len())
   scroll:add(phrase)
   for i = 2, #header do
      header[i]:toMarkdown(scroll, skein)
   end
end



return Header_M

