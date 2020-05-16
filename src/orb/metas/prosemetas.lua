



local Twig = require "orb:orb/metas/twig"

local Phrase = require "singletons:singletons/phrase"



local function bookmaker(icon)
   return function(bookended, skein)
      local phrase = Phrase(icon)
      for i = 2, #bookended - 1 do
         phrase = phrase .. bookended[i]:toMarkdown(skein)
      end
      return phrase .. icon
   end
end



local bold_M = Twig:inherit "bold"
bold_M.toMarkdown = bookmaker "**"



local italic_M = Twig:inherit "italic"
italic_M.toMarkdown = bookmaker "*"



local literal_M = Twig:inherit "literal"
literal_M.toMarkdown = bookmaker "`"



local strike_M = Twig:inherit "strike"
strike_M.toMarkdown = bookmaker ""



local underline_M = Twig:inherit "underline"
underline_M.toMarkdown = bookmaker ""



local verbatim_M = Twig:inherit "verbatim"
verbatim_M.toMarkdown = bookmaker ""



local Prose_M = { bold = bold_M,
                  italic = italic_M,
                  literal = literal_M,
                  strike = strike_M,
                  underline = underline_M,
                  verbatim = verbatim_M, }




return Prose_M
