





local Twig = require "orb:orb/metas/twig"
local Phrase = require "singletons:singletons/phrase"



local DocMetas = {}







local Doc_M = Twig:inherit "doc"
DocMetas.doc = Doc_M



function Doc_M.toMarkdown(doc, scroll)
   for _, block in ipairs(doc) do
      block:toMarkdown(scroll)
   end
end



local Section_M = Twig:inherit "section"
DocMetas.section = Section_M



function Section_M.toMarkdown(section, scroll)
   for _, block in ipairs(section) do
      block:toMarkdown(scroll)
   end
end



return DocMetas

