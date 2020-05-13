
























local Peg = require "espalier:espalier/peg"
local subGrammar = require "espalier:espalier/subgrammar"
local Phrase = require "singletons:singletons/phrase"

local fragments = require "orb:orb/fragments"
local Twig = require "orb:orb/metas/twig"



local code_str = [[
    codeblock  ←  code-start code-body  code-end
   code-start  ←  start-mark code-type? (WS name)* rest* NL
   start-mark  ←  "#" "!"+
           NL  ←  "\n"
           WS  ←  " "+
    code-body  ←  (!code-end 1)+
     code-end  ←  end-mark code-type? execute* (!"\n" 1)* line-end
               /  -1
     end-mark  ←  "#" "/"+
    code-type  ←  symbol
    line-end   ←  ("\n\n" "\n"* / "\n")* (-1)
         name  ←  handle
      execute  ←  "(" " "* ")"
       `rest`  ←  (handle / hashtag / raw)+
         raw   ←  (!handle !hashtag !"\n" 1)+
]] .. fragments.symbol .. fragments.handle .. fragments.hashtag



local Code_M = Twig :inherit "codeblock"



function Code_M.toMarkdown(codeblock, skein)
   local phrase = Phrase "```"
   phrase = phrase .. codeblock :select "code_type"() :span() .. "\n"
   phrase = phrase .. codeblock :select "code_body"() :span()
   local code_end = codeblock :select "code_end"()
   local line_end
   if not code_end[1] then
      line_end = "\n"
      -- might be a missing newline
      if not tostring(phrase):sub(-1) == "\n" then
         phrase = phrase .. "\n"
      end
   else
      line_end = code_end :select "line_end"() :span()
   end
   return phrase .. "```" .. line_end
end



local code_peg = Peg(code_str, { Twig, codeblock = Code_M })





return subGrammar(code_peg.parse, nil, "code-nomatch")
