





local Twig = require "orb:orb/metas/twig"
local Phrase = require "singletons:singletons/phrase"



local DocMetas = {}







local Doc_M = Twig:inherit "doc"
DocMetas.doc = Doc_M



function Doc_M.toMarkdown(doc)
   local phrase = Phrase ""
   for _, block in ipairs(doc) do
      phrase = phrase .. block:toMarkdown()
   end
   return phrase
end



return DocMetas
