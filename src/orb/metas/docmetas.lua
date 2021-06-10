





local Twig = require "orb:orb/metas/twig"
local Phrase = require "singletons:singletons/phrase"



local DocMetas = {}







local Doc_M = Twig:inherit "doc"
DocMetas.doc = Doc_M



function Doc_M.toMarkdown(doc, scroll, skein)
   for _, block in ipairs(doc) do
      block:toMarkdown(scroll, skein)
   end
end








local Skein;
function Doc_M.toSkein(doc)
   Skein = Skein or require "orb:orb/skein"
end



local Section_M = Twig:inherit "section"
DocMetas.section = Section_M



function Section_M.toMarkdown(section, scroll, skein)
   for _, block in ipairs(section) do
      block:toMarkdown(scroll, skein)
   end
end



return DocMetas

