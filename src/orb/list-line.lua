




local subGrammar = require "espalier:espalier/subgrammar"
local Peg = require "espalier:espalier/peg"
local Twig = require "orb:orb/metas/twig"
local anterm = require "anterm:anterm"



local listline_str = [[
     list-line  ←  depth number* sep WS
                   (cookie / radio)*
                   (key colon val / text) cookie* list-end*
         depth  ←  " "*
        number  ←  [0-9]+
           sep  ←  "-" / "."
        cookie  ←  "[" (!"]" 1)+ "]"
         radio  ←  "(" 1 ")" ; this should be one utf-8 character
           key  ←  (!":" 1)+
         colon  ←  ":"
           val  ←  ws+ (!WS 1) 1+
          text  ←  (!cookie 1)+ "[" (!"]" 1)+ "]" !list-end (!cookie 1)+
                /  (!cookie 1)+
            WS  ←  ws
          `ws`  ←  { \n}+
      list-end  ←  "\n"+
]]



local listline_grammar = Peg(listline_str).parse




local Listline = Twig:inherit "list_line"

function Listline.strExtra(list_line)
   return  anterm.magenta(tostring(list_line.indent))
end




local function listline_fn(t)
   local match = listline_grammar(t.str, t.first, t.last)
   if match then
       if match.last == t. last then
         -- label the match according to the rule
         match.id = t.id or "list_line"
         match.indent = match:select"sep"().last - match.first + 2
         return setmetatable(match, Listline)
       else
         match.id = t.id .. "_INCOMPLETE"
         return match
       end
   end
   -- if error:
   t.id = "listline_nomatch"
   return setmetatable(t, Twig)
end



return listline_fn
