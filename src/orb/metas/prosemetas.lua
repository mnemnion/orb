



local Twig = require "orb:orb/metas/twig"

local Phrase = require "singletons:singletons/phrase"



local function bookmaker(icon)
   return function(bookended, scroll, skein)
      scroll:add(icon)
      for i = 2, #bookended - 1 do
         bookended[i]:toMarkdown(scroll, skein)
      end
      scroll:add(icon)
   end
end



local bold_M = Twig:inherit "bold"
bold_M.toMarkdown = bookmaker "**"



local italic_M = Twig:inherit "italic"
italic_M.toMarkdown = bookmaker "*"







local literal_M = Twig:inherit "literal"

local find, rep = assert(string.find), assert(string.rep)

function literal_M.toMarkdown(literal, scroll, skein)
   local span = literal :select "body"() :span()
   local ends = "`"
   local head, tail = find(span, "%`+")
   if head then
      ends = rep("`", tail + 2 - head)
   end
   scroll:add(ends .. span .. ends)
end



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

